Action Controller 简介
======================

本文介绍控制器的工作原理，以及控制器在程序请求周期内扮演的角色。

读完本文，你将学到：

* 请求如何进入控制器；
* 如何限制传入控制器的参数；
* 为什么以及如何把数据存储在会话或 cookie 中；
* 处理请求时，如何使用过滤器执行代码；
* 如何使用 Action Controller 內建的 HTTP 身份认证功能；
* 如何把数据流直发送给用户的浏览器；
* 如何过滤敏感信息，不写入程序的日志；
* 如何处理请求过程中可能出现的异常；

--------------------------------------------------------------------------------

控制器的作用
-----------

Action Controller 是 MVC 中的 C（控制器）。路由决定使用哪个控制器处理请求后，控制器负责解析请求，生成对应的请求。Action Controller 会代为处理大多数底层工作，使用易懂的约定，让整个过程清晰明了。

在大多数按照 [REST](http://en.wikipedia.org/wiki/Representational_state_transfer) 规范开发的程序中，控制器会接收请求（开发者不可见），从模型中获取数据，或把数据写入模型，再通过视图生成 HTML。如果控制器需要做其他操作，也没问题，以上只不过是控制器的主要作用。

因此，控制器可以视作模型和视图的中间人，让模型中的数据可以在视图中使用，把数据显示给用户，再把用户提交的数据保存或更新到模型中。

NOTE: 路由的处理细节请查阅 [Rails Routing From the Outside In](routing.html)。

控制器命名约定
------------

Rails 控制器的命名习惯是，最后一个单词使用**复数形式**，但也是有例外，比如 `ApplicationController`。例如：用 `ClientsController`，而不是 `ClientController`；用 `SiteAdminsController`，而不是 `SiteAdminController` 或 `SitesAdminsController`。

遵守这一约定便可享用默认的路由生成器（例如 `resources` 等），无需再指定 `:path` 或 `:controller`，URL 和路径的帮助方法也能保持一致性。详情参阅 [Layouts & Rendering Guide](layouts_and_rendering.html)。

NOTE: 控制器的命名习惯和模型不同，模型的名字习惯使用单数形式。

方法和动作
---------

控制器是一个类，继承自 `ApplicationController`，和其他类一样，定义了很多方法。程序接到请求时，路由决定运行哪个控制器和哪个动作，然后创建该控制器的实例，运行和动作同名的方法。

```ruby
class ClientsController < ApplicationController
  def new
  end
end
```

例如，用户访问 `/clients/new` 新建客户，Rails 会创建一个 `ClientsController` 实例，运行 `new` 方法。注意，在上面这段代码中，即使 `new` 方法是空的也没关系，因为默认会渲染 `new.html.erb` 视图，除非指定执行其他操作。在 `new` 方法中，声明可在视图中使用的 `@client` 实例变量，创建一个新的 `Client` 实例：

```ruby
def new
  @client = Client.new
end
```

详情参阅 [Layouts & Rendering Guide](layouts_and_rendering.html)。

`ApplicationController` 继承自 `ActionController::Base`。`ActionController::Base` 定义了很多实用方法。本文会介绍部分方法，如果想知道定义了哪些方法，可查阅 API 文档或源码。

只有公开方法才被视为动作。所以最好减少对外可见的方法数量，例如辅助方法和过滤器方法。

参数
----

在控制器的动作中，往往需要获取用户发送的数据，或其他参数。在网页程序中参数分为两类。第一类随 URL 发送，叫做“请求参数”，即 URL 中 `?` 符号后面的部分。第二类经常成为“POST 数据”，一般来自用户填写的表单。之所以叫做“POST 数据”是因为，只能随 HTTP POST 请求发送。Rails 不区分这两种参数，在控制器中都可通过 `params` Hash 获取：

```ruby
class ClientsController < ApplicationController
  # This action uses query string parameters because it gets run
  # by an HTTP GET request, but this does not make any difference
  # to the way in which the parameters are accessed. The URL for
  # this action would look like this in order to list activated
  # clients: /clients?status=activated
  def index
    if params[:status] == "activated"
      @clients = Client.activated
    else
      @clients = Client.inactivated
    end
  end

  # This action uses POST parameters. They are most likely coming
  # from an HTML form which the user has submitted. The URL for
  # this RESTful request will be "/clients", and the data will be
  # sent as part of the request body.
  def create
    @client = Client.new(params[:client])
    if @client.save
      redirect_to @client
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new"
    end
  end
end
```

### Hash 和数组参数

`params` Hash 不局限于只能使用一维键值对，其中可以包含数组和嵌套的 Hash。要发送数组，需要在键名后加上一对空方括号（`[]`）：

```
GET /clients?ids[]=1&ids[]=2&ids[]=3
```

NOTE: “[”和“]”这两个符号不允许出现在 URL 中，所以上面的地址会被编码成 `/clients?ids%5b%5d=1&ids%5b%5d=2&ids%5b%5d=3`。大多数情况下，无需你费心，浏览器会为你代劳编码，接收到这样的请求后，Rails 也会自动解码。如果你要手动向服务器发送这样的请求，就要留点心了。

此时，`params[:ids]` 的值是 `["1", "2", "3"]`。注意，参数的值始终是字符串，Rails 不会尝试转换类型。

NOTE: 默认情况下，基于安全考虑，参数中的 `[]`、`[nil]` 和 `[nil, nil, ...]` 会替换成 `nil`。详情参阅[安全指南](security.html#unsafe-query-generation)。

要发送嵌套的 Hash 参数，需要在方括号内指定键名：

```html
<form accept-charset="UTF-8" action="/clients" method="post">
  <input type="text" name="client[name]" value="Acme" />
  <input type="text" name="client[phone]" value="12345" />
  <input type="text" name="client[address][postcode]" value="12345" />
  <input type="text" name="client[address][city]" value="Carrot City" />
</form>
```

提交这个表单后，`params[:client]` 的值是 `{ "name" => "Acme", "phone" => "12345", "address" => { "postcode" => "12345", "city" => "Carrot City" } }`。注意 `params[:client][:address]` 是个嵌套 Hash。

注意，`params` Hash 其实是 `ActiveSupport::HashWithIndifferentAccess` 的实例，虽和普通的 Hash 一样，但键名使用 Symbol 和字符串的效果一样。

### JSON 参数

开发网页服务程序时，你会发现，接收 JSON 格式的参数更容易处理。如果请求的 `Content-Type` 报头是 `application/json`，Rails 会自动将其转换成 `params` Hash，按照常规的方法使用：

例如，如果发送如下的 JSON 格式内容：

```json
{ "company": { "name": "acme", "address": "123 Carrot Street" } }
```

得到的是 `params[:company]` 就是 `{ "name" => "acme", "address" => "123 Carrot Street" }`。

如果在初始化脚本中开启了 `config.wrap_parameters` 选项，或者在控制器中调用了 `wrap_parameters` 方法，可以放心的省去 JSON 格式参数中的根键。Rails 会以控制器名新建一个键，复制参数，将其存入这个键名下。因此，上面的参数可以写成：

```json
{ "name": "acme", "address": "123 Carrot Street" }
```

假设数据传送给 `CompaniesController`，那么参数会存入 `:company` 键名下：

```ruby
{ name: "acme", address: "123 Carrot Street", company: { name: "acme", address: "123 Carrot Street" } }
```

如果想修改默认使用的键名，或者把其他参数存入其中，请参阅 [API 文档](http://api.rubyonrails.org/classes/ActionController/ParamsWrapper.html)。

NOTE: 解析 XML 格式参数的功能现已抽出，制成了 gem，名为 `actionpack-xml_parser`。

### 路由参数

`params` Hash 总有 `:controller` 和 `:action` 两个键，但获取这两个值应该使用 `controller_name` 和 `action_name` 方法。路由中定义的参数，例如 `:id`，也可通过 `params` Hash 获取。例如，假设有个客户列表，可以列出激活和禁用的客户。我们可以定义一个路由，捕获下面这个 URL 中的 `:status` 参数：

```ruby
get '/clients/:status' => 'clients#index', foo: 'bar'
```

在这个例子中，用户访问 `/clients/active` 时，`params[:status]` 的值是 `"active"`。同时，`params[:foo]` 的值也会被设为 `"bar"`，就像通过请求参数传入的一样。`params[:action]` 也是一样，其值为 `"index"`。

### `default_url_options`

在控制器中定义名为 `default_url_options` 的方法，可以设置所生成 URL 中都包含的参数。这个方法必须返回一个 Hash，其值为所需的参数值，而且键必须使用 Symbol：

```ruby
class ApplicationController < ActionController::Base
  def default_url_options
    { locale: I18n.locale }
  end
end
```

这个方法定义的只是预设参数，可以被 `url_for` 方法的参数覆盖。

如果像上面的代码一样，在 `ApplicationController` 中定义 `default_url_options`，则会用于所有生成的 URL。`default_url_options` 也可以在具体的控制器中定义，只影响和该控制器有关的 URL。

### 健壮参数

加入健壮参数功能后，Action Controller 的参数禁止在 Avtive Model 中批量赋值，除非参数在白名单中。也就是说，你要明确选择那些属性可以批量更新，避免意外把不该暴露的属性暴露了。

而且，还可以标记哪些参数是必须传入的，如果没有收到，会交由 `raise/rescue` 处理，返回“400 Bad Request”。

```ruby
class PeopleController < ActionController::Base
  # This will raise an ActiveModel::ForbiddenAttributes exception
  # because it's using mass assignment without an explicit permit
  # step.
  def create
    Person.create(params[:person])
  end

  # This will pass with flying colors as long as there's a person key
  # in the parameters, otherwise it'll raise a
  # ActionController::ParameterMissing exception, which will get
  # caught by ActionController::Base and turned into that 400 Bad
  # Request reply.
  def update
    person = current_account.people.find(params[:id])
    person.update!(person_params)
    redirect_to person
  end

  private
    # Using a private method to encapsulate the permissible parameters
    # is just a good pattern since you'll be able to reuse the same
    # permit list between create and update. Also, you can specialize
    # this method with per-user checking of permissible attributes.
    def person_params
      params.require(:person).permit(:name, :age)
    end
end
```

#### 允许使用的标量值

假如允许传入 `:id`：

```ruby
params.permit(:id)
```

若 `params` 中有 `:id`，且 `:id` 是标量值，就可以通过白名单检查，否则 `:id` 会被过滤掉。因此不能传入数组、Hash 或其他对象。

允许使用的标量类型有：`String`、`Symbol`、`NilClass`、`Numeric`、`TrueClass`、`FalseClass`、`Date`、`Time`、`DateTime`、`StringIO`、`IO`、`ActionDispatch::Http::UploadedFile` 和 `Rack::Test::UploadedFile`。

要想指定 `params` 中的值必须为数组，可以把键对应的值设为空数组：

```ruby
params.permit(id: [])
```

要想允许传入整个参数 Hash，可以使用 `permit!` 方法：

```ruby
params.require(:log_entry).permit!
```

此时，允许传入整个 `:log_entry` Hash 及嵌套 Hash。使用 `permit!` 时要特别注意，因为这么做模型中所有当前属性及后续添加的属性都允许进行批量赋值。

#### 嵌套参数

也可以允许传入嵌套参数，例如：

```ruby
params.permit(:name, { emails: [] },
              friends: [ :name,
                         { family: [ :name ], hobbies: [] }])
```

此时，允许传入 `name`，`emails` 和 `friends` 属性。其中，`emails` 必须是数组；`friends` 必须是一个由资源组成的数组：应该有个 `name` 属性，还要有 `hobbies` 属性，其值是由标量组成的数组，以及一个 `family` 属性，其值只能包含 `name` 属性（任何允许使用的标量值）。

#### 更多例子

你可能还想在 `new` 动作中限制允许传入的属性。不过此时无法再根键上调用 `require` 方法，因为此时根键还不存在：

```ruby
# using `fetch` you can supply a default and use
# the Strong Parameters API from there.
params.fetch(:blog, {}).permit(:title, :author)
```

使用 `accepts_nested_attributes_for` 方法可以更新或销毁响应的记录。这个方法基于 `id` 和 `_destroy` 参数：

```ruby
# permit :id and :_destroy
params.require(:author).permit(:name, books_attributes: [:title, :id, :_destroy])
```

如果 Hash 的键是数字，处理方式有所不同，此时可以把属性作为 Hash 的直接子 Hash。`accepts_nested_attributes_for` 和 `has_many` 关联同时使用时会得到这种参数：

```ruby
# To whitelist the following data:
# {"book" => {"title" => "Some Book",
#             "chapters_attributes" => { "1" => {"title" => "First Chapter"},
#                                        "2" => {"title" => "Second Chapter"}}}}

params.require(:book).permit(:title, chapters_attributes: [:title])
```

#### 不用健壮参数

健壮参数的目的是为了解决常见问题，不是万用良药。不过，可以很方便的和自己的代码结合，解决复杂需求。

假设有个参数包含产品的名字和一个由任意数据组成的产品附加信息 Hash，希望过滤产品名和整个附加数据 Hash。健壮参数不能过滤由任意键值组成的嵌套 Hash，不过可以使用嵌套 Hash 的键定义过滤规则：

```ruby
def product_params
  params.require(:product).permit(:name, data: params[:product][:data].try(:keys))
end
```

会话
----

程序中的每个用户都有一个会话（session），可以存储少量数据，在多次请求中永久存储。会话只能在控制器和视图中使用，可以通过以下几种存储机制实现：

* `ActionDispatch::Session::CookieStore`：所有数据都存储在客户端
* `ActionDispatch::Session::CacheStore`：数据存储在 Rails 缓存里
* `ActionDispatch::Session::ActiveRecordStore`：使用 Active Record 把数据存储在数据库中（需要使用 `activerecord-session_store` gem）
* `ActionDispatch::Session::MemCacheStore`：数据存储在 Memcached 集群中（这是以前的实现方式，现在请改用 CacheStore）

所有存储机制都会用到一个 cookie，存储每个会话的 ID（必须使用 cookie，因为 Rails 不允许在 URL 中传递会话 ID，这么做不安全）。

大多数存储机制都会使用这个 ID 在服务商查询会话数据，例如在数据库中查询。不过有个例外，即默认也是推荐使用的存储方式 CookieStore。CookieStore 把所有会话数据都存储在 cookie 中（如果需要，还是可以使用 ID）。CookieStore 的优点是轻量，而且在新程序中使用会话也不用额外的设置。cookie 中存储的数据会使用密令签名，以防篡改。cookie 会被加密，任何有权访问的人都无法读取其内容。（如果修改了 cookie，Rails 会拒绝使用。）

CookieStore 可以存储大约 4KB 数据，比其他几种存储机制都少很多，但一般也足够用了。不过使用哪种存储机制，都不建议在会话中存储大量数据。应该特别避免在会话中存储复杂的对象（Ruby 基本对象之外的一切对象，最常见的是模型实例），服务器可能无法在多次请求中重组数据，最终导致错误。

如果会话中没有存储重要的数据，或者不需要持久存储（例如使用 Falsh 存储消息），可以考虑使用 `ActionDispatch::Session::CacheStore`。这种存储机制使用程序所配置的缓存方式。CacheStore 的优点是，可以直接使用现有的缓存方式存储会话，不用额外的设置。不过缺点也很明显，会话存在时间很多，随时可能消失。

关于会话存储的更多内容请参阅[安全指南](security.html)

如果想使用其他的会话存储机制，可以在 `config/initializers/session_store.rb` 文件中设置：

```ruby
# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails g active_record:session_migration")
# YourApp::Application.config.session_store :active_record_store
```

签署会话数据时，Rails 会用到会话的键（cookie 的名字），这个值可以在 `config/initializers/session_store.rb` 中修改：

```ruby
# Be sure to restart your server when you modify this file.
YourApp::Application.config.session_store :cookie_store, key: '_your_app_session'
```

还可以传入 `:domain` 键，指定可使用此 cookie 的域名：

```ruby
# Be sure to restart your server when you modify this file.
YourApp::Application.config.session_store :cookie_store, key: '_your_app_session', domain: ".example.com"
```

Rails 为 CookieStore 提供了一个密令，用来签署会话数据。这个密令可以在 `config/secrets.yml` 文件中修改：

```ruby
# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure the secrets in this file are kept private
# if you're sharing your code publicly.

development:
  secret_key_base: a75d...

test:
  secret_key_base: 492f...

# Do not keep production secrets in the repository,
# instead read values from the environment.
production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
```

NOTE: 使用 CookieStore 时，如果修改了密令，之前所有的会话都会失效。

### 获取会话

在控制器中，可以使用实例方法 `session` 获取会话。

NOTE: 会话是惰性加载的，如果不在动作中获取，不会自动加载。因此无需禁用会话，不获取即可。

会话中的数据以键值对的形式存储，类似 Hash：

```ruby
class ApplicationController < ActionController::Base

  private

  # Finds the User with the ID stored in the session with the key
  # :current_user_id This is a common way to handle user login in
  # a Rails application; logging in sets the session value and
  # logging out removes it.
  def current_user
    @_current_user ||= session[:current_user_id] &&
      User.find_by(id: session[:current_user_id])
  end
end
```

要想把数据存入会话，像 Hash 一样，给键赋值即可：

```ruby
class LoginsController < ApplicationController
  # "Create" a login, aka "log the user in"
  def create
    if user = User.authenticate(params[:username], params[:password])
      # Save the user ID in the session so it can be used in
      # subsequent requests
      session[:current_user_id] = user.id
      redirect_to root_url
    end
  end
end
```

要从会话中删除数据，把键的值设为 `nil` 即可：

```ruby
class LoginsController < ApplicationController
  # "Delete" a login, aka "log the user out"
  def destroy
    # Remove the user id from the session
    @_current_user = session[:current_user_id] = nil
    redirect_to root_url
  end
end
```

要重设整个会话，请使用 `reset_session` 方法。

### Flash 消息

Flash 是会话的一个特殊部分，每次请求都会清空。也就是说，其中存储的数据只能在下次请求时使用，可用来传递错误消息等。

Flash 消息的获取方式和会话差不多，类似 Hash。Flash 消息是 [FlashHash](http://api.rubyonrails.org/classes/ActionDispatch/Flash/FlashHash.html) 实例。

下面以退出登录为例。控制器可以发送一个消息，在下一次请求时显示：

```ruby
class LoginsController < ApplicationController
  def destroy
    session[:current_user_id] = nil
    flash[:notice] = "You have successfully logged out."
    redirect_to root_url
  end
end
```

注意，Flash 消息还可以直接在转向中设置。可以指定 `:notice`、`:alert` 或者常规的 `:flash`：

```ruby
redirect_to root_url, notice: "You have successfully logged out."
redirect_to root_url, alert: "You're stuck here!"
redirect_to root_url, flash: { referral_code: 1234 }
```

上例中，`destroy` 动作转向程序的 `root_url`，然后显示 Flash 消息。注意，只有下一个动作才能处理前一个动作中设置的 Flash 消息。一般都会在程序的布局中加入显示警告或提醒 Flash 消息的代码：


```erb
<html>
  <!-- <head/> -->
  <body>
    <% flash.each do |name, msg| -%>
      <%= content_tag :div, msg, class: name %>
    <% end -%>

    <!-- more content -->
  </body>
</html>
```

如此一來，如果动作中设置了警告或提醒消息，就会出现在布局中。

Flash 不局限于警告和提醒，可以设置任何可在会话中存储的内容：

```erb
<% if flash[:just_signed_up] %>
  <p class="welcome">Welcome to our site!</p>
<% end %>
```

如果希望 Flash 消息保留到其他请求，可以使用 `keep` 方法：

```ruby
class MainController < ApplicationController
  # Let's say this action corresponds to root_url, but you want
  # all requests here to be redirected to UsersController#index.
  # If an action sets the flash and redirects here, the values
  # would normally be lost when another redirect happens, but you
  # can use 'keep' to make it persist for another request.
  def index
    # Will persist all flash values.
    flash.keep

    # You can also use a key to keep only some kind of value.
    # flash.keep(:notice)
    redirect_to users_url
  end
end
```

#### `flash.now`

默认情况下，Flash 中的内容只在下一次请求中可用，但有时希望在同一个请求中使用。例如，`create` 动作没有成功保存资源时，会直接渲染 `new` 模板，这并不是一个新请求，但却希望希望显示一个 Flash 消息。针对这种情况，可以使用 `flash.now`，用法和 `flash` 一样：

```ruby
class ClientsController < ApplicationController
  def create
    @client = Client.new(params[:client])
    if @client.save
      # ...
    else
      flash.now[:error] = "Could not save client"
      render action: "new"
    end
  end
end
```

Cookies
--------

程序可以在客户端存储少量数据（称为 cookie），在多次请求中使用，甚至可以用作会话。在 Rails 中可以使用 `cookies` 方法轻松获取 cookies，用法和 `session` 差不多，就像一个 Hash：

```ruby
class CommentsController < ApplicationController
  def new
    # Auto-fill the commenter's name if it has been stored in a cookie
    @comment = Comment.new(author: cookies[:commenter_name])
  end

  def create
    @comment = Comment.new(params[:comment])
    if @comment.save
      flash[:notice] = "Thanks for your comment!"
      if params[:remember_name]
        # Remember the commenter's name.
        cookies[:commenter_name] = @comment.author
      else
        # Delete cookie for the commenter's name cookie, if any.
        cookies.delete(:commenter_name)
      end
      redirect_to @comment.article
    else
      render action: "new"
    end
  end
end
```

注意，删除会话中的数据是把键的值设为 `nil`，但要删除 cookie 中的值，要使用 `cookies.delete(:key)` 方法。

Rails 还提供了签名 cookie 和加密 cookie，用来存储敏感数据。签名 cookie 会在 cookie 的值后面加上一个签名，确保值没被修改。加密 cookie 除了会签名之外，还会加密，让终端用户无法读取。详细信息请参阅 [API 文档](http://api.rubyonrails.org/classes/ActionDispatch/Cookies.html)。

这两种特殊的 cookie 会序列化签名后的值，生成字符串，读取时再反序列化成 Ruby 对象。

序列化所用的方式可以指定：

```ruby
Rails.application.config.action_dispatch.cookies_serializer = :json
```

新程序默认使用的序列化方法是 `:json`。为了兼容以前程序中的 cookie，如果没设定 `cookies_serializer`，就会使用 `:marshal`。

这个选项还可以设为 `:hybrid`，读取时，Rails 会自动返序列化使用 `Marshal` 序列化的 cookie，写入时使用 `JSON` 格式。把现有程序迁移到使用 `:json` 序列化方式时，这么设定非常方便。

序列化方式还可以使用其他方式，只要定义了 `load` 和 `dump` 方法即可：

```ruby
Rails.application.config.action_dispatch.cookies_serializer = MyCustomSerializer
```

渲染 XML 和 JSON 数据
--------------------

在 `ActionController` 中渲染 `XML` 和 `JSON` 数据非常简单。使用脚手架生成的控制器如下所示：

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @users}
      format.json { render json: @users}
    end
  end
end
```

你可能注意到了，在这段代码中，我们使用的是 `render xml: @users` 而不是 `render xml: @users.to_xml`。如果不是字符串对象，Rails 会自动调用 `to_xml` 方法。

过滤器
------

过滤器（filter）是一些方法，在控制器动作运行之前、之后，或者前后运行。

过滤器会继承，如果在 `ApplicationController` 中定义了过滤器，那么程序的每个控制器都可使用。

前置过滤器有可能会终止请求循环。前置过滤器经常用来确保动作运行之前用户已经登录。这种过滤器的定义如下：

```ruby
class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def require_login
    unless logged_in?
      flash[:error] = "You must be logged in to access this section"
      redirect_to new_login_url # halts request cycle
    end
  end
end
```

如果用户没有登录，这个方法会在 Flash 中存储一个错误消息，然后转向登录表单页面。如果前置过滤器渲染了页面或者做了转向，动作就不会运行。如果动作上还有后置过滤器，也不会运行。

在上面的例子中，过滤器在 `ApplicationController` 中定义，所以程序中的所有控制器都会继承。程序中的所有页面都要求用户登录后才能访问。很显然（这样用户根本无法登录），并不是所有控制器或动作都要做这种限制。如果想跳过某个动作，可以使用 `skip_before_action`：

```ruby
class LoginsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
end
```

此时，`LoginsController` 的 `new` 动作和 `create` 动作就不需要用户先登录。`:only` 选项的意思是只跳过这些动作。还有个 `:except` 选项，用法类似。定义过滤器时也可使用这些选项，指定只在选中的动作上运行。

### 后置过滤器和环绕过滤器

除了前置过滤器之外，还可以在动作运行之后，或者在动作运行前后执行过滤器。

后置过滤器类似于前置过滤器，不过因为动作已经运行了，所以可以获取即将发送给客户端的响应数据。显然，后置过滤器无法阻止运行动作。

环绕过滤器会把动作拉入（yield）过滤器中，工作方式类似 Rack 中间件。

例如，网站的改动需要经过管理员预览，然后批准。可以把这些操作定义在一个事务中：

```ruby
class ChangesController < ApplicationController
  around_action :wrap_in_transaction, only: :show

  private

  def wrap_in_transaction
    ActiveRecord::Base.transaction do
      begin
        yield
      ensure
        raise ActiveRecord::Rollback
      end
    end
  end
end
```

注意，环绕过滤器还包含了渲染操作。在上面的例子中，视图本身是从数据库中读取出来的（例如，通过作用域（scope）），读取视图的操作在事务中完成，然后提供预览数据。

也可以不拉入动作，自己生成响应，不过这种情况不会运行动作。

### 过滤器的其他用法

一般情况下，过滤器的使用方法是定义私有方法，然后调用相应的 `*_action` 方法添加过滤器。不过过滤器还有其他两种用法。

第一种，直接在 `*_action` 方法中使用代码块。代码块接收控制器作为参数。使用这种方法，前面的 `require_login` 过滤器可以改写成：

```ruby
class ApplicationController < ActionController::Base
  before_action do |controller|
    unless controller.send(:logged_in?)
      flash[:error] = "You must be logged in to access this section"
      redirect_to new_login_url
    end
  end
end
```

注意，此时在过滤器中使用的是 `send` 方法，因为 `logged_in?` 是私有方法，而且过滤器和控制器不在同一作用域内。定义 `require_login` 过滤器不推荐使用这种方法，但比较简单的过滤器可以这么用。

第二种，在类（其实任何能响应正确方法的对象都可以）中定义过滤器。这种方法用来实现复杂的过滤器，使用前面的两种方法无法保证代码可读性和重用性。例如，可以在一个类中定义前面的 `require_login` 过滤器：

```ruby
class ApplicationController < ActionController::Base
  before_action LoginFilter
end

class LoginFilter
  def self.before(controller)
    unless controller.send(:logged_in?)
      controller.flash[:error] = "You must be logged in to access this section"
      controller.redirect_to controller.new_login_url
    end
  end
end
```

这种方法也不是定义 `require_login` 过滤器的理想方式，因为和控制器不在同一作用域，要把控制器作为参数传入。定义过滤器的类，必须有一个和过滤器种类同名的方法。对于 `before_action` 过滤器，类中必须定义 `before` 方法。其他类型的过滤器以此类推。`around` 方法必须调用 `yield` 方法执行动作。

防止请求伪造
-----------

跨站请求伪造（CSRF）是一种攻击方式，A 网站的用户伪装成 B 网站的用户发送请求，在 B 站中添加、修改或删除数据，而 B 站的用户绝然不知。

防止这种攻击的第一步是，确保所有析构动作（`create`，`update` 和 `destroy`）只能通过 GET 之外的请求方法访问。如果遵从 REST 架构，已经完成了这一步。不过，恶意网站还是可以很轻易地发起非 GET 请求，这时就要用到其他防止跨站攻击的方法了。

我们添加一个只有自己的服务器才知道的难以猜测的令牌。如果请求中没有该令牌，就会禁止访问。

如果使用下面的代码生成一个表单：

```erb
<%= form_for @user do |f| %>
  <%= f.text_field :username %>
  <%= f.text_field :password %>
<% end %>
```

会看到 Rails 自动添加了一个隐藏字段：

```html
<form accept-charset="UTF-8" action="/users/1" method="post">
<input type="hidden"
       value="67250ab105eb5ad10851c00a5621854a23af5489"
       name="authenticity_token"/>
<!-- username & password fields -->
</form>
```

所有使用[表单帮助方法](form_helpers.html)生成的表单，都有会添加这个令牌。如果想自己编写表单，或者基于其他原因添加令牌，可以使用 `form_authenticity_token` 方法。

`form_authenticity_token` 会生成一个有效的令牌。在 Rails 没有自动添加令牌的地方（例如 Ajax）可以使用这个方法。

[安全指南](security.html)一文更深入的介绍了请求伪造防范措施，还有一些开发网页程序需要知道的安全隐患。

`request` 和 `response` 对象
----------------------------

在每个控制器中都有两个存取器方法，分别用来获取当前请求循环的请求对象和响应对象。`request` 方法的返回值是 `AbstractRequest` 对象的实例；`response` 方法的返回值是一个响应对象，表示回送客户端的数据。

### `request` 对象

`request` 对象中有很多发自客户端请求的信息。可用方法的完整列表参阅 [API 文档](http://api.rubyonrails.org/classes/ActionDispatch/Request.html)。其中部分方法说明如下：

| `request` 对象的属性                      | 作用                                                        |
| ----------------------------------------- | ----------------------------------------------------------- |
| host                                      | 请求发往的主机名                                            |
| domain(n=2)                               | 主机名的前 `n` 个片段，从顶级域名的右侧算起                 |
| format                                    | 客户端发起请求时使用的内容类型                              |
| method                                    | 请求使用的 HTTP 方法                                        |
| get?, post?, patch?, put?, delete?, head? | 如果 HTTP 方法是 GET/POST/PATCH/PUT/DELETE/HEAD，返回 `true`|
| headers                                   | 返回一个 Hash，包含请求的报头                               |
| port                                      | 请求发往的端口，整数类型                                    |
| protocol                                  | 返回所用的协议外加 `"://"`，例如 `"http://"`                |
| query_string                              | URL 中包含的请求参数，`?` 后面的字符串                      |
| remote_ip                                 | 客户端的 IP 地址                                            |
| url                                       | 请求发往的完整 URL                                          |

#### `path_parameters`，`query_parameters` 和 `request_parameters`

不过请求中的参数随 URL 而来，而是通过表单提交，Rails 都会把这些参数存入 `params` Hash 中。`request` 对象中有三个存取器，用来获取各种类型的参数。`query_parameters` Hash 中的参数来自 URL；`request_parameters` Hash 中的参数来自提交的表单；`path_parameters` Hash 中的参数来自路由，传入相应的控制器和动作。

### `response` 对象

一般情况下不会直接使用 `response` 对象。`response` 对象在动作中渲染，把数据回送给客户端。不过有时可能需要直接获取响应，比如在后置过滤器中。`response` 对象上的方法很多都可以用来赋值。

| `response` 对象的数学   | 作用                                               |
| ---------------------- | ---------------------------------------------------|
| body                   | 回送客户端的数据，字符串格式。大多数情况下是 HTML       |
| status                 | 响应的 HTTP 状态码，例如，请求成功时是 200，文件未找到时是 404 |
| location               | 转向地址（如果转向的话）                              |
| content_type           | 响应的内容类型                                       |
| charset                | 响应使用的字符集。默认是 `"utf-8"`                    |
| headers                | 响应报头                                            |

#### 设置自定义报头

如果想设置自定义报头，可以使用 `response.headers` 方法。报头是一个 Hash，键为报头名，值为报头的值。Rails 会自动设置一些报头，如果想添加或者修改报头，赋值给 `response.headers` 即可，例如：

```ruby
response.headers["Content-Type"] = "application/pdf"
```

注意，上面这段代码直接使用 `content_type=` 方法更直接。

HTTP 身份认证
-------------

Rails 内建了两种 HTTP 身份认证方式：

* 基本认证
* 摘要认证

### HTTP 基本身份认证

大多数浏览器和 HTTP 客户端都支持 HTTP 基本身份认证。例如，在浏览器中如果要访问只有管理员才能查看的页面，就会出现一个对话框，要求输入用户名和密码。使用内建的身份认证非常简单，只要使用一个方法，即 `http_basic_authenticate_with`。

```ruby
class AdminsController < ApplicationController
  http_basic_authenticate_with name: "humbaba", password: "5baa61e4"
end
```

添加 `http_basic_authenticate_with` 方法后，可以创建具有命名空间的控制器，继承自 `AdminsController`，`http_basic_authenticate_with` 方法会在这些控制器的所有动作运行之前执行，启用 HTTP 基本身份认证。

### HTTP 摘要身份认证

HTTP 摘要身份认证比基本认证高级，因为客户端不会在网络中发送明文密码（不过在 HTTPS 中基本认证是安全的）。在 Rails 中使用摘要认证非常简单，只需使用一个方法，即 `authenticate_or_request_with_http_digest`。

```ruby
class AdminsController < ApplicationController
  USERS = { "lifo" => "world" }

  before_action :authenticate

  private

    def authenticate
      authenticate_or_request_with_http_digest do |username|
        USERS[username]
      end
    end
end
```

如上面的代码所示，`authenticate_or_request_with_http_digest` 方法的块只接受一个参数，用户名，返回值是密码。如果 `authenticate_or_request_with_http_digest` 返回 `false` 或 `nil`，表明认证失败。

数据流和文件下载
--------------

有时不想渲染 HTML 页面，而要把文件发送给用户。在所有的控制器中都可以使用 `send_data` 和 `send_file` 方法。这两个方法都会以数据流的方式发送数据。`send_file` 方法很方便，只要提供硬盘中文件的名字，就会用数据流发送文件内容。

要想把数据以数据流的形式发送给客户端，可以使用 `send_data` 方法：

```ruby
require "prawn"
class ClientsController < ApplicationController
  # Generates a PDF document with information on the client and
  # returns it. The user will get the PDF as a file download.
  def download_pdf
    client = Client.find(params[:id])
    send_data generate_pdf(client),
              filename: "#{client.name}.pdf",
              type: "application/pdf"
  end

  private

    def generate_pdf(client)
      Prawn::Document.new do
        text client.name, align: :center
        text "Address: #{client.address}"
        text "Email: #{client.email}"
      end.render
    end
end
```

在上面的代码中，`download_pdf` 动作调用私有方法 `generate_pdf`。`generate_pdf` 才是真正生成 PDF 的方法，返回值字符串形式的文件内容。返回的字符串会以数据流的形式发送给客户端，并为用户推荐一个文件名。有时发送文件流时，并不希望用户下载这个文件，比如嵌在 HTML 页面中的图片。告诉浏览器文件不是用来下载的，可以把 `:disposition` 选项设为 `"inline"`。这个选项的另外一个值，也是默认值，是 `"attachment"`。

### 发送文件

如果想发送硬盘上已经存在的文件，可以使用 `send_file` 方法。

```ruby
class ClientsController < ApplicationController
  # Stream a file that has already been generated and stored on disk.
  def download_pdf
    client = Client.find(params[:id])
    send_file("#{Rails.root}/files/clients/#{client.id}.pdf",
              filename: "#{client.name}.pdf",
              type: "application/pdf")
  end
end
```

`send_file` 一次只发送 4kB，而不是一次把整个文件都写入内存。如果不想使用数据流方式，可以把 `:stream` 选项设为 `false`。如果想调整数据块大小，可以设置 `:buffer_size` 选项。

如果没有指定 `:type` 选项，Rails 会根据 `:filename` 中的文件扩展名猜测。如果没有注册扩展名对应的文件类型，则使用 `application/octet-stream`。

WARNING: 要谨慎处理用户提交数据（参数，cookies 等）中的文件路径，有安全隐患，你可能并不想让别人下载这个文件。

TIP: 不建议通过 Rails 以数据流的方式发送静态文件，你可以把静态文件放在服务器的公共文件夹中，使用 Apache 或其他服务器下载效率更高，因为不用经由整个 Rails 处理。

### 使用 REST 的方式下载文件

虽然可以使用 `send_data` 方法发送数据，但是在 REST 架构的程序中，单独为下载文件操作写个动作有些多余。在 REST 架构下，上例中的 PDF 文件可以视作一种客户端资源。Rails 提供了一种更符合 REST 架构的文件下载方法。下面这段代码重写了前面的例子，把下载 PDF 文件的操作放在 `show` 动作中，不使用数据流：

```ruby
class ClientsController < ApplicationController
  # The user can request to receive this resource as HTML or PDF.
  def show
    @client = Client.find(params[:id])

    respond_to do |format|
      format.html
      format.pdf { render pdf: generate_pdf(@client) }
    end
  end
end
```

为了让这段代码能顺利运行，要把 PDF MIME 加入 Rails。在 `config/initializers/mime_types.rb` 文件中加入下面这行代码即可：

```ruby
Mime::Type.register "application/pdf", :pdf
```

NOTE: 设置文件不会在每次请求中都重新加载，所以为了让改动生效，需要重启服务器。

现在客户端请求 PDF 版本，只要在 URL 后加上 `".pdf"` 即可：

```bash
GET /clients/1.pdf
```

### 任意数据的实时流

在 Rails 中，不仅文件可以使用数据流的方式处理，在响应对象中，任何数据都可以视作数据流。`ActionController::Live` 模块可以和浏览器建立持久连接，随时随地把数据传送给浏览器。

#### 使用实时流

把 `ActionController::Live` 模块引入控制器中后，所有的动作都可以处理数据流。

```ruby
class MyController < ActionController::Base
  include ActionController::Live

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    100.times {
      response.stream.write "hello world\n"
      sleep 1
    }
  ensure
    response.stream.close
  end
end
```

上面的代码会和浏览器建立持久连接，每秒一次，共发送 100 次 `"hello world\n"`。

关于这段代码有一些注意事项。必须关闭响应数据流。如果忘记关闭，套接字就会一直处于打开状态。发送数据流之前，还要把内容类型设为 `text/event-stream`。因为响应发送后（`response.committed` 返回真值后）就无法设置报头了。

#### 使用举例

架设你在制作一个卡拉 OK 机，用户想查看某首歌的歌词。每首歌（`Song`）都有很多行歌词，每一行歌词都要花一些时间（`num_beats`）才能唱完。

如果按照卡拉 OK 机的工作方式，等上一句唱完才显示下一行，就要使用 `ActionController::Live`：

```ruby
class LyricsController < ActionController::Base
  include ActionController::Live

  def show
    response.headers['Content-Type'] = 'text/event-stream'
    song = Song.find(params[:id])

    song.each do |line|
      response.stream.write line.lyrics
      sleep line.num_beats
    end
  ensure
    response.stream.close
  end
end
```

在这段代码中，只有上一句唱完才会发送下一句歌词。

#### 使用数据流时的注意事项

以数据流的方式发送任意数据是个强大的功能，如前面几个例子所示，你可以选择何时发送什么数据。不过，在使用时，要注意以下事项：

* 每次以数据流形式发送响应时都会新建一个线程，然后把原线程中的本地变量复制过来。线程中包含太多的本地变量会降低性能。而且，线程太多也会影响性能。
* 忘记关闭响应流会导致套接字一直处于打开状态。使用响应流时一定要记得调用 `close` 方法。
* WEBrick 会缓冲所有响应，因此引入 `ActionController::Live` 也不会有任何效果。你应该使用不自动缓冲响应的服务器。

过滤日志
--------

Rails 在 `log` 文件夹中为每个环境都准备了一个日志文件。这些文件在调试时特别有用，但上线后的程序并不用把所有信息都写入日志。

### 过滤参数

要想过滤特定的请求参数，禁止写入日志文件，可以在程序的设置文件中设置 `config.filter_parameters` 选项。过滤掉得参数在日志中会显示为 `[FILTERED]`。

```ruby
config.filter_parameters << :password
```

### 过滤转向

有时需要从日志文件中过滤掉一些程序转向的敏感数据，此时可以设置 `config.filter_redirect` 选项：

```ruby
config.filter_redirect << 's3.amazonaws.com'
```

可以使用字符串，正则表达式，或者一个数组，包含字符串或正则表达式：

```ruby
config.filter_redirect.concat ['s3.amazonaws.com', /private_path/]
```

匹配的 URL 会显示为 `'[FILTERED]'`。

异常处理
--------

程序很有可能有错误，错误发生时会抛出异常，这些异常是需要处理的。例如，如果用户访问一个连接，但数据库中已经没有对应的资源了，此时 Active Record 会抛出 `ActiveRecord::RecordNotFound` 异常。

在 Rails 中，异常的默认处理方式是显示“500 Internal Server Error”消息。如果程序在本地运行，出错后会显示一个精美的调用堆栈，以及其他附加信息，让开发者快速找到错误的地方，然后修正。如果程序已经上线，Rails 则会简单的显示“500 Server Error”消息，如果是路由错误或记录不存在，则显示“404 Not Found”。有时你可能想换种方式捕获错误，以及如何显示报错信息。在 Rails 中，有很多层异常处理，详解如下。

### 默认的 500 和 404 模板

默认情况下，如果程序错误，会显示 404 或者 500 错误消息。错误消息在 `public` 文件夹中的静态 HTML 文件中，分别是 `404.html` 和 `500.html`。你可以修改这两个文件，添加其他信息或布局，不过要记住，这两个是静态文件，不能使用 RHTML，只能写入纯粹的 HTML。

### `rescue_from`

捕获错误后如果想做更详尽的处理，可以使用 `rescue_form`。`rescue_from` 可以处理整个控制器及其子类中的某种（或多种）异常。

异常发生时，会被 `rescue_from` 捕获，异常对象会传入处理代码。处理异常的代码可以是方法，也可以是 `Proc` 对象，由 `:with` 选项指定。也可以不用 `Proc` 对象，直接使用块。

下面的代码使用 `rescue_from` 截获所有 `ActiveRecord::RecordNotFound` 异常，然后做相应的处理。

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

    def record_not_found
      render plain: "404 Not Found", status: 404
    end
end
```

这段代码对异常的处理并不详尽，比默认的处理也没好多少。不过只要你能捕获异常，就可以做任何想做的处理。例如，可以新建一个异常类，用户无权查看页面时抛出：

```ruby
class ApplicationController < ActionController::Base
  rescue_from User::NotAuthorized, with: :user_not_authorized

  private

    def user_not_authorized
      flash[:error] = "You don't have access to this section."
      redirect_to :back
    end
end

class ClientsController < ApplicationController
  # Check that the user has the right authorization to access clients.
  before_action :check_authorization

  # Note how the actions don't have to worry about all the auth stuff.
  def edit
    @client = Client.find(params[:id])
  end

  private

    # If the user is not authorized, just throw the exception.
    def check_authorization
      raise User::NotAuthorized unless current_user.admin?
    end
end
```

NOTE: 某些异常只能在 `ApplicationController` 中捕获，因为在异常抛出前控制器还没初始化，动作也没执行。详情参见 [Pratik Naik 的文章](http://m.onkey.org/2008/7/20/rescue-from-dispatching)。

强制使用 HTTPS 协议
------------------

有时，基于安全考虑，可能希望某个控制器只能通过 HTTPS 协议访问。为了达到这个目的，可以在控制器中使用 `force_ssl` 方法：

```ruby
class DinnerController
  force_ssl
end
```

和过滤器类似，也可指定 `:only` 或 `:except` 选项，设置只在某些动作上强制使用 HTTPS：

```ruby
class DinnerController
  force_ssl only: :cheeseburger
  # or
  force_ssl except: :cheeseburger
end
```

注意，如果你在很多控制器中都使用了 `force_ssl`，或许你想让整个程序都使用 HTTPS。此时，你可以在环境设置文件中设置 `config.force_ssl` 选项。
