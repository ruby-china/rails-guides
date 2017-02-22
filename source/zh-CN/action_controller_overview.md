Action Controller 概览
======================

本文介绍控制器的工作原理，以及控制器在应用请求周期中扮演的角色。

读完本文后，您将学到：

- 请求如何进入控制器；

- 如何限制传入控制器的参数；

- 为什么以及如何把数据存储在会话或 cookie 中；

- 处理请求时，如何使用过滤器执行代码；

- 如何使用 Action Controller 内置的 HTTP 身份验证功能；

- 如何把数据流直接发送给用户的浏览器；

- 如何过滤敏感信息，不写入应用的日志；

- 如何处理请求过程中可能出现的异常。

控制器的作用
------------

Action Controller 是 MVC 中的 C（控制器）。路由决定使用哪个控制器处理请求后，控制器负责解析请求，生成相应的输出。Action Controller 会代为处理大多数底层工作，使用智能的约定，让整个过程清晰明了。

在大多数按照 [REST](http://en.wikipedia.org/wiki/Representational_state_transfer) 架构开发的应用中，控制器会接收请求（开发者不可见），从模型中获取数据，或把数据写入模型，再通过视图生成 HTML。如果控制器需要做其他操作，也没问题，以上只不过是控制器的主要作用。

因此，控制器可以视作模型和视图的中间人，让模型中的数据可以在视图中使用，把数据显示给用户，再把用户提交的数据保存或更新到模型中。

NOTE: 路由的处理细节参阅[Rails 路由全解](routing.html)。

控制器命名约定
--------------

Rails 控制器的命名约定是，最后一个单词使用复数形式，但也有例外，比如 `ApplicationController`。例如：用 `ClientsController`，而不是 `ClientController`；用 `SiteAdminsController`，而不是 `SiteAdminController` 或 `SitesAdminsController`。

遵守这一约定便可享用默认的路由生成器（例如 `resources` 等），无需再指定 `:path` 或 `:controller` 选项，而且 URL 和路径的辅助方法也能保持一致性。详情参阅[Rails 布局和视图渲染](layouts_and_rendering.html)。

NOTE: 控制器的命名约定与模型不同，模型的名字习惯使用单数形式。

方法和动作
----------

一个控制器是一个 Ruby 类，继承自 `ApplicationController`，和其他类一样，定义了很多方法。应用接到请求时，路由决定运行哪个控制器和哪个动作，然后 Rails 创建该控制器的实例，运行与动作同名的方法。

```ruby
class ClientsController < ApplicationController
  def new
  end
end
```

例如，用户访问 `/clients/new` 添加新客户，Rails 会创建一个 `ClientsController` 实例，然后调用 `new` 方法。注意，在上面这段代码中，即使 `new` 方法是空的也没关系，因为 Rails 默认会渲染 `new.html.erb` 视图，除非动作指定做其他操作。在 `new` 方法中，可以声明在视图中使用的 `@client` 实例变量，创建一个新的 `Client` 实例：

```ruby
def new
  @client = Client.new
end
```

详情参阅[Rails 布局和视图渲染](layouts_and_rendering.html)。

`ApplicationController` 继承自 `ActionController::Base`。后者定义了许多有用的方法。本文会介绍部分方法，如果想知道定义了哪些方法，可查阅 API 文档或源码。

只有公开方法才作为动作调用。所以最好减少对外可见的方法数量（使用 `private` 或 `protected`），例如辅助方法和过滤器方法。

参数
----

在控制器的动作中，往往需要获取用户发送的数据或其他参数。在 Web 应用中参数分为两类。第一类随 URL 发送，叫做“查询字符串参数”，即 URL 中 `?` 符号后面的部分。第二类经常称为“POST 数据”，一般来自用户填写的表单。之所以叫做“POST 数据”，是因为这类数据只能随 HTTP POST 请求发送。Rails 不区分这两种参数，在控制器中都可通过 `params` 散列获取：

```ruby
class ClientsController < ApplicationController
  # 这个动作使用查询字符串参数，因为它响应的是 HTTP GET 请求
  # 但是，访问参数的方式没有不同
  # 列出激活客户的 URL 可能是这样的：/clients?status=activated
  def index
    if params[:status] == "activated"
      @clients = Client.activated
    else
      @clients = Client.inactivated
    end
  end

  # 这个动作使用 POST 参数
  # 这种参数最常来自用户提交的 HTML 表单
  # 在 REST 式架构中，这个动作响应的 URL 是“/clients”
  # 数据在请求主体中发送
  def create
    @client = Client.new(params[:client])
    if @client.save
      redirect_to @client
    else
      # 这一行代码覆盖默认的渲染行为
      # 默认渲染的是“create”视图
      render "new"
    end
  end
end
```

### 散列和数组参数

`params` 散列不局限于只能使用一维键值对，其中可以包含数组和嵌套的散列。若想发送数组，要在键名后加上一对空方括号（`[]`）：

    GET /clients?ids[]=1&ids[]=2&ids[]=3

NOTE: “\[”和“\]”这两个符号不允许出现在 URL 中，所以上面的地址会被编码成 `/clients?ids%5b%5d=1&ids%5b%5d=2&ids%5b%5d=3`。多数情况下，无需你费心，浏览器会代为编码，接收到这样的请求后，Rails 也会自动解码。如果你要手动向服务器发送这样的请求，就要留心了。

此时，`params[:ids]` 的值是 `["1", "2", "3"]`。注意，参数的值始终是字符串，Rails 不会尝试转换类型。

NOTE: 默认情况下，基于安全考虑，参数中的 `[nil]` 和 `[nil, nil, …​]` 会替换成 `[]`。详情参见 [Ruby on Rails 安全指南](security.html#unsafe-query-generation)。

若想发送一个散列，要在方括号内指定键名：

```html
<form accept-charset="UTF-8" action="/clients" method="post">
  <input type="text" name="client[name]" value="Acme" />
  <input type="text" name="client[phone]" value="12345" />
  <input type="text" name="client[address][postcode]" value="12345" />
  <input type="text" name="client[address][city]" value="Carrot City" />
</form>
```

提交这个表单后，`params[:client]` 的值是 `{ "name" => "Acme", "phone" => "12345", "address" => { "postcode" => "12345", "city" => "Carrot City" } }`。注意 `params[:client][:address]` 是个嵌套散列。

`params` 对象的行为类似于散列，但是键可以混用符号和字符串。

### JSON 参数

开发 Web 服务应用时，你会发现，接收 JSON 格式的参数更容易处理。如果请求的 `Content-Type` 首部是 `application/json`，Rails 会自动将其转换成 `params` 散列，这样就可以按照常规的方式使用了。

例如，如果发送如下的 JSON 内容：

```json
{ "company": { "name": "acme", "address": "123 Carrot Street" } }
```

控制器收到的 `params[:company]` 是 `{ "name" => "acme", "address" => "123 Carrot Street" }`。

如果在初始化脚本中开启了 `config.wrap_parameters` 选项，或者在控制器中调用了 `wrap_parameters` 方法，可以放心地省去 JSON 参数中的根元素。此时，Rails 会以控制器名新建一个键，复制参数，将其存入这个键名下。因此，上面的参数可以写成：

```json
{ "name": "acme", "address": "123 Carrot Street" }
```

假设把上述数据发给 `CompaniesController`，那么参数会存入 `:company` 键名下：

```json
{ name: "acme", address: "123 Carrot Street", company: { name: "acme", address: "123 Carrot Street" } }
```

如果想修改默认使用的键名，或者把其他参数存入其中，请参阅 [API 文档](http://api.rubyonrails.org/classes/ActionController/ParamsWrapper.html)。

NOTE: 解析 XML 格式参数的功能现已抽出，制成了 gem，名为 `actionpack-xml_parser`。

### 路由参数

`params` 散列始终有 `:controller` 和 `:action` 两个键，但获取这两个值应该使用 `controller_name` 和 `action_name` 方法。路由中定义的参数，例如 `:id`，也可通过 `params` 散列获取。例如，假设有个客户列表，可以列出激活和未激活的客户。我们可以定义一个路由，捕获下面这个 URL 中的 `:status` 参数：

```ruby
get '/clients/:status' => 'clients#index', foo: 'bar'
```

此时，用户访问 `/clients/active` 时，`params[:status]` 的值是 `"active"`。同时，`params[:foo]` 的值会被设为 `"bar"`，就像通过查询字符串传入的一样。控制器还会收到 `params[:action]`，其值为 `"index"`，以及 `params[:controller]`，其值为 `"clients"`。

### `default_url_options`

在控制器中定义名为 `default_url_options` 的方法，可以设置所生成的 URL 中都包含的参数。这个方法必须返回一个散列，其值为所需的参数值，而且键必须使用符号：

```ruby
class ApplicationController < ActionController::Base
  def default_url_options
    { locale: I18n.locale }
  end
end
```

这个方法定义的只是预设参数，可以被 `url_for` 方法的参数覆盖。

如果像上面的代码那样在 `ApplicationController` 中定义 `default_url_options`，设定的默认参数会用于生成所有的 URL。`default_url_options` 也可以在具体的控制器中定义，此时只影响与该控制器有关的 URL。

其实，不是生成的每个 URL 都会调用这个方法。为了提高性能，返回的散列会缓存，因此一次请求至少会调用一次。

### 健壮参数

加入健壮参数功能后，Action Controller 的参数禁止在 Avtive Model 中批量赋值，除非参数在白名单中。也就是说，你要明确选择哪些属性可以批量更新，以防不小心允许用户更新模型中敏感的属性。

此外，还可以标记哪些参数是必须传入的，如果没有收到，会交由预定义的 `raise/rescue` 流程处理，返回“400 Bad Request”。

```ruby
class PeopleController < ActionController::Base
  # 这会导致 ActiveModel::ForbiddenAttributes 异常抛出
  # 因为没有明确指明允许赋值的属性就批量更新了
  def create
    Person.create(params[:person])
  end

  # 只要参数中有 person 键，这个动作就能顺利执行
  # 否则，抛出 ActionController::ParameterMissing 异常
  # ActionController::Base 会捕获这个异常，返回 400 Bad Request 响应
  def update
    person = current_account.people.find(params[:id])
    person.update!(person_params)
    redirect_to person
  end

  private
    # 在一个私有方法中封装允许的参数是个好做法
    # 这样可以在 create 和 update 动作中复用
    # 此外，可以细化这个方法，针对每个用户检查允许的属性
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

若 `params` 中有 `:id` 键，且 `:id` 是标量值，就可以通过白名单检查；否则 `:id` 会被过滤掉。因此，不能传入数组、散列或其他对象。

允许使用的标量类型有：`String`、`Symbol`、`NilClass`、`Numeric`、`TrueClass`、`FalseClass`、`Date`、`Time`、`DateTime`、`StringIO`、`IO`、`ActionDispatch::Http::UploadedFile` 和 `Rack::Test::UploadedFile`。

若想指定 `params` 中的值必须为标量数组，可以把键对应的值设为空数组：

```ruby
params.permit(id: [])
```

若想允许传入整个参数散列，可以使用 `permit!` 方法：

```ruby
params.require(:log_entry).permit!
```

此时，允许传入整个 `:log_entry` 散列及嵌套散列。使用 `permit!` 时要特别注意，因为这么做模型中所有现有的属性及后续添加的属性都允许进行批量赋值。

#### 嵌套参数

也可以允许传入嵌套参数，例如：

```ruby
params.permit(:name, { emails: [] },
              friends: [ :name,
                         { family: [ :name ], hobbies: [] }])
```

此时，允许传入 `name`、`emails` 和 `friends` 属性。其中，`emails` 是标量数组；`friends` 是一个由资源组成的数组：应该有个 `name` 属性（任何允许使用的标量值），有个 `hobbies` 属性，其值是标量数组，以及一个 `family` 属性，其值只能包含 `name` 属性（也是任何允许使用的标量值）。

#### 更多示例

你可能还想在 `new` 动作中限制允许传入的属性。不过，此时无法在根键上调用 `require` 方法，因为调用 `new` 时根键还不存在：

```ruby
# 使用 `fetch` 可以提供一个默认值
# 这样就可以使用健壮参数了
params.fetch(:blog, {}).permit(:title, :author)
```

使用模型的类方法 `accepts_nested_attributes_for` 可以更新或销毁关联的记录。这个方法基于 `id` 和 `_destroy` 参数：

```ruby
# 允许 :id 和 :_destroy
params.require(:author).permit(:name, books_attributes: [:title, :id, :_destroy])
```

如果散列的键是数字，处理方式有所不同。此时可以把属性作为散列的直接子散列。`accepts_nested_attributes_for` 和 `has_many` 关联同时使用时会得到这种参数：

```ruby
# 为下面这种数据添加白名单：
# {"book" => {"title" => "Some Book",
#             "chapters_attributes" => { "1" => {"title" => "First Chapter"},
#                                        "2" => {"title" => "Second Chapter"}}}}

params.require(:book).permit(:title, chapters_attributes: [:title])
```

#### 不用健壮参数

健壮参数的目的是为了解决常见问题，不是万用良药。不过，你可以很方便地与自己的代码结合，解决复杂需求。

假设有个参数包含产品名称和一个由任意数据组成的产品附加信息散列，你想过滤产品名称和整个附加数据散列。健壮参数不能过滤由任意键组成的嵌套散列，不过可以使用嵌套散列的键定义过滤规则：

```ruby
def product_params
  params.require(:product).permit(:name, data: params[:product][:data].try(:keys))
end
```

会话
----

应用中的每个用户都有一个会话（session），用于存储少量数据，在多次请求中永久存储。会话只能在控制器和视图中使用，可以通过以下几种存储机制实现：

- `ActionDispatch::Session::CookieStore`：所有数据都存储在客户端

- `ActionDispatch::Session::CacheStore`：数据存储在 Rails 缓存里

- `ActionDispatch::Session::ActiveRecordStore`：使用 Active Record 把数据存储在数据库中（需要使用 `activerecord-session_store` gem）

- `ActionDispatch::Session::MemCacheStore`：数据存储在 Memcached 集群中（这是以前的实现方式，现在应该改用 CacheStore）

所有存储机制都会用到一个 cookie，存储每个会话的 ID（必须使用 cookie，因为 Rails 不允许在 URL 中传递会话 ID，这么做不安全）。

多数存储机制都会使用这个 ID 在服务器中查询会话数据，例如在数据库中查询。不过有个例外，即默认也是推荐使用的存储方式——CookieStore。这种机制把所有会话数据都存储在 cookie 中（如果需要，还是可以访问 ID）。CookieStore 的优点是轻量，而且在新应用中使用会话也不用额外的设置。cookie 中存储的数据会使用密令签名，以防篡改。cookie 还会被加密，因此任何能访问 cookie 的人都无法读取其内容。（如果修改了 cookie，Rails 会拒绝使用。）

CookieStore 可以存储大约 4KB 数据，比其他几种存储机制少很多，但一般也够用了。不管使用哪种存储机制，都不建议在会话中存储大量数据。尤其要避免在会话中存储复杂的对象（Ruby 基本对象之外的一切对象，最常见的是模型实例），因为服务器可能无法在多次请求中重组数据，从而导致错误。

如果用户会话中不存储重要的数据，或者不需要持久存储（例如存储闪现消息），可以考虑使用 `ActionDispatch::Session::CacheStore`。这种存储机制使用应用所配置的缓存方式。CacheStore 的优点是，可以直接使用现有的缓存方式存储会话，不用额外设置。不过缺点也很明显：会话存在时间很短，随时可能消失。

关于会话存储的更多信息，参阅[Ruby on Rails 安全指南](security.html)。

如果想使用其他会话存储机制，可以在 `config/initializers/session_store.rb` 文件中修改：

```ruby
# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails g active_record:session_migration")
# Rails.application.config.session_store :active_record_store
```

签署会话数据时，Rails 会用到会话的键（cookie 的名称）。这个值可以在 `config/initializers/session_store.rb` 中修改：

```ruby
# Be sure to restart your server when you modify this file.
Rails.application.config.session_store :cookie_store, key: '_your_app_session'
```

还可以传入 `:domain` 键，指定可使用此 cookie 的域名：

```ruby
# Be sure to restart your server when you modify this file.
Rails.application.config.session_store :cookie_store, key: '_your_app_session', domain: ".example.com"
```

Rails 为 CookieStore 提供了一个密钥，用于签署会话数据。这个密钥可以在 `config/secrets.yml` 文件中修改：

```yaml
# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rails secret` to generate a secure secret key.

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

NOTE: 使用 `CookieStore` 时，如果修改了密钥，之前所有的会话都会失效。

### 访问会话

在控制器中，可以通过实例方法 `session` 访问会话。

NOTE: 会话是惰性加载的。如果在动作中不访问，不会自动加载。因此任何时候都无需禁用会话，不访问即可。

会话中的数据以键值对的形式存储，与散列类似：

```ruby
class ApplicationController < ActionController::Base

  private

  # 使用会话中 :current_user_id  键存储的 ID 查找用户
  # Rails 应用经常这样处理用户登录
  # 登录后设定这个会话值，退出后删除这个会话值
  def current_user
    @_current_user ||= session[:current_user_id] &&
      User.find_by(id: session[:current_user_id])
  end
end
```

若想把数据存入会话，像散列一样，给键赋值即可：

```ruby
class LoginsController < ApplicationController
  # “创建”登录，即“登录用户”
  def create
    if user = User.authenticate(params[:username], params[:password])
      # 把用户的 ID 存储在会话中，以便后续请求使用
      session[:current_user_id] = user.id
      redirect_to root_url
    end
  end
end
```

若想从会话中删除数据，把键的值设为 `nil` 即可：

```ruby
class LoginsController < ApplicationController
  # “删除”登录，即“退出用户”
  def destroy
    # 从会话中删除用户的 ID
    @_current_user = session[:current_user_id] = nil
    redirect_to root_url
  end
end
```

若想重设整个会话，使用 `reset_session` 方法。

### 闪现消息

闪现消息是会话的一个特殊部分，每次请求都会清空。也就是说，其中存储的数据只能在下次请求时使用，因此可用于传递错误消息等。

闪现消息的访问方式与会话差不多，类似于散列。（闪现消息是 [FlashHash](http://api.rubyonrails.org/classes/ActionDispatch/Flash/FlashHash.html) 实例。）

下面以退出登录为例。控制器可以发送一个消息，在下次请求时显示：

```ruby
class LoginsController < ApplicationController
  def destroy
    session[:current_user_id] = nil
    flash[:notice] = "You have successfully logged out."
    redirect_to root_url
  end
end
```

注意，重定向也可以设置闪现消息。可以指定 `:notice`、`:alert` 或者常规的 `:flash`：

```ruby
redirect_to root_url, notice: "You have successfully logged out."
redirect_to root_url, alert: "You're stuck here!"
redirect_to root_url, flash: { referral_code: 1234 }
```

上例中，`destroy` 动作重定向到应用的 `root_url`，然后显示那个闪现消息。注意，只有下一个动作才能处理前一个动作设置的闪现消息。一般会在应用的布局中加入显示警告或提醒消息的代码：

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

闪现消息不局限于警告和提醒，可以设置任何可在会话中存储的内容：

```erb
<% if flash[:just_signed_up] %>
  <p class="welcome">Welcome to our site!</p>
<% end %>
```

如果希望闪现消息保留到其他请求，可以使用 `keep` 方法：

```ruby
class MainController < ApplicationController
  # 假设这个动作对应 root_url，但是想把针对这个
  # 动作的请求都重定向到 UsersController#index。
  # 如果是从其他动作重定向到这里的，而且那个动作
  # 设定了闪现消息，通常情况下，那个闪现消息会丢失。
  # 但是我们可以使用 keep 方法，将其保留到下一个请求。
  def index
    # 持久存储所有闪现消息
    flash.keep

    # 还可以指定一个键，只保留某种闪现消息
    # flash.keep(:notice)
    redirect_to users_url
  end
end
```

#### `flash.now`

默认情况下，闪现消息中的内容只在下一次请求中可用，但有时希望在同一个请求中使用。例如，`create` 动作没有成功保存资源时，会直接渲染 `new` 模板，这并不是一个新请求，但却希望显示一个闪现消息。针对这种情况，可以使用 `flash.now`，其用法和常规的 `flash` 一样：

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

cookies
-------

应用可以在客户端存储少量数据（称为 cookie），在多次请求中使用，甚至可以用作会话。在 Rails 中可以使用 `cookies` 方法轻易访问 cookie，用法和 `session` 差不多，就像一个散列：

```ruby
class CommentsController < ApplicationController
  def new
    # 如果 cookie 中存有评论者的名字，自动填写
    @comment = Comment.new(author: cookies[:commenter_name])
  end

  def create
    @comment = Comment.new(params[:comment])
    if @comment.save
      flash[:notice] = "Thanks for your comment!"
      if params[:remember_name]
        # 记住评论者的名字
        cookies[:commenter_name] = @comment.author
      else
        # 从 cookie 中删除评论者的名字（如果有的话）
        cookies.delete(:commenter_name)
      end
      redirect_to @comment.article
    else
      render action: "new"
    end
  end
end
```

注意，删除会话中的数据是把键的值设为 `nil`，但若想删除 cookie 中的值，要使用 `cookies.delete(:key)` 方法。

Rails 还提供了签名 cookie 和加密 cookie，用于存储敏感数据。签名 cookie 会在 cookie 的值后面加上一个签名，确保值没被修改。加密 cookie 除了做签名之外，还会加密，让终端用户无法读取。详情参阅 [API 文档](http://api.rubyonrails.org/classes/ActionDispatch/Cookies.html)。

这两种特殊的 cookie 会序列化签名后的值，生成字符串，读取时再反序列化成 Ruby 对象。

序列化所用的方式可以指定：

```ruby
Rails.application.config.action_dispatch.cookies_serializer = :json
```

新应用默认的序列化方式是 `:json`。为了兼容旧应用的 cookie，如果没设定 `cookies_serializer` 选项，会使用 `:marshal`。

这个选项还可以设为 `:hybrid`，读取时，Rails 会自动反序列化使用 `Marshal` 序列化的 cookie，写入时使用 `JSON` 格式。把现有应用迁移到使用 `:json` 序列化方式时，这么设定非常方便。

序列化方式还可以使用其他方式，只要定义了 `load` 和 `dump` 方法即可：

```ruby
Rails.application.config.action_dispatch.cookies_serializer = MyCustomSerializer
```

使用 `:json` 或 `:hybrid` 方式时，要知道，不是所有 Ruby 对象都能序列化成 JSON。例如，`Date` 和 `Time` 对象序列化成字符串，而散列的键会变成字符串。

```ruby
class CookiesController < ApplicationController
  def set_cookie
    cookies.encrypted[:expiration_date] = Date.tomorrow # => Thu, 20 Mar 2014
    redirect_to action: 'read_cookie'
  end

  def read_cookie
    cookies.encrypted[:expiration_date] # => "2014-03-20"
  end
end
```

建议只在 cookie 中存储简单的数据（字符串和数字）。如果不得不存储复杂的对象，在后续请求中要自行负责转换。

如果使用 cookie 存储会话，`session` 和 `flash` 散列也是如此。

渲染 XML 和 JSON 数据
---------------------

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

过滤器（filter）是一种方法，在控制器动作运行之前、之后，或者前后运行。

过滤器会继承，如果在 `ApplicationController` 中定义了过滤器，那么应用的每个控制器都可使用。

前置过滤器有可能会终止请求循环。前置过滤器经常用于确保动作运行之前用户已经登录。这种过滤器可以像下面这样定义：

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

如果用户没有登录，这个方法会在闪现消息中存储一个错误消息，然后重定向到登录表单页面。如果前置过滤器渲染了页面或者做了重定向，动作就不会运行。如果动作上还有后置过滤器，也不会运行。

在上面的例子中，过滤器在 `ApplicationController` 中定义，所以应用中的所有控制器都会继承。此时，应用中的所有页面都要求用户登录后才能访问。很显然（这样用户根本无法登录），并不是所有控制器或动作都要做这种限制。如果想跳过某个动作，可以使用 `skip_before_action`：

```ruby
class LoginsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
end
```

此时，`LoginsController` 的 `new` 动作和 `create` 动作就不需要用户先登录。`:only` 选项的意思是只跳过这些动作。此外，还有个 `:except` 选项，用法类似。定义过滤器时也可使用这些选项，指定只在选中的动作上运行。

### 后置过滤器和环绕过滤器

除了前置过滤器之外，还可以在动作运行之后，或者在动作运行前后执行过滤器。

后置过滤器类似于前置过滤器，不过因为动作已经运行了，所以可以获取即将发送给客户端的响应数据。显然，后置过滤器无法阻止运行动作。

环绕过滤器会把动作拉入（yield）过滤器中，工作方式类似 Rack 中间件。

假如网站的改动需要经过管理员预览，然后批准。可以把这些操作定义在一个事务中：

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

注意，环绕过滤器还包含了渲染操作。在上面的例子中，视图本身是从数据库中读取出来的（例如，通过作用域），读取视图的操作在事务中完成，然后提供预览数据。

也可以不拉入动作，自己生成响应，不过此时动作不会运行。

### 过滤器的其他用法

一般情况下，过滤器的使用方法是定义私有方法，然后调用相应的 `*_action` 方法添加过滤器。不过过滤器还有其他两种用法。

第一种，直接在 `*_action` 方法中使用代码块。代码块接收控制器作为参数。使用这种方式，前面的 `require_login` 过滤器可以改写成：

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

注意，此时在过滤器中使用的是 `send` 方法，因为 `logged_in?` 是私有方法，而过滤器和控制器不在同一个作用域内。定义 `require_login` 过滤器不推荐使用这种方式，但是比较简单的过滤器可以这么做。

第二种，在类（其实任何能响应正确方法的对象都可以）中定义过滤器。这种方式用于实现复杂的过滤器，使用前面的两种方式无法保证代码可读性和重用性。例如，可以在一个类中定义前面的 `require_login` 过滤器：

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

这种方式也不是定义 `require_login` 过滤器的理想方式，因为与控制器不在同一作用域，要把控制器作为参数传入。定义过滤器的类，必须有一个和过滤器种类同名的方法。对于 `before_action` 过滤器，类中必须定义 `before` 方法。其他类型的过滤器以此类推。`around` 方法必须调用 `yield` 方法执行动作。

请求伪造防护
------------

跨站请求伪造（Cross-Site Request Forgery，CSRF）是一种攻击方式，A 网站的用户伪装成 B 网站的用户发送请求，在 B 站中添加、修改或删除数据，而 B 站的用户浑然不知。

防止这种攻击的第一步是，确保所有破坏性动作（`create`、`update` 和 `destroy`）只能通过 GET 之外的请求方法访问。如果遵从 REST 架构，已经做了这一步。不过，恶意网站还是可以轻易地发起非 GET 请求，这时就要用到其他跨站攻击防护措施了。

防止跨站攻击的方式是，在各个请求中添加一个只有服务器才知道的难以猜测的令牌。如果请求中没有正确的令牌，服务器会拒绝访问。

如果使用下面的代码生成一个表单：

```erb
<%= form_for @user do |f| %>
  <%= f.text_field :username %>
  <%= f.text_field :password %>
<% end %>
```

会看到 Rails 自动添加了一个隐藏字段，用于设定令牌：

```html
<form accept-charset="UTF-8" action="/users/1" method="post">
<input type="hidden"
       value="67250ab105eb5ad10851c00a5621854a23af5489"
       name="authenticity_token"/>
<!-- fields -->
</form>
```

使用[表单辅助方法](form_helpers.xml#action-view-form-helpers)生成的所有表单都有这样一个令牌，因此多数时候你都无需担心。如果想自己编写表单，或者基于其他原因想添加令牌，可以使用 `form_authenticity_token` 方法。

`form_authenticity_token` 会生成一个有效的令牌。在 Rails 没有自动添加令牌的地方（例如 Ajax）可以使用这个方法。

[Ruby on Rails 安全指南](security.html)将更为深入地说明请求伪造防护措施，还有一些开发 Web 应用需要知道的其他安全隐患。

请求和响应对象
--------------

在每个控制器中都有两个存取方法，分别用于获取当前请求循环的请求对象和响应对象。`request` 方法的返回值是一个 `ActionDispatch::Request` 实例，`response` 方法的返回值是一个响应对象，表示回送客户端的数据。

### `request` 对象

`request` 对象中有很多客户端请求的有用信息。可用方法的完整列表参阅 [API 文档](http://api.rubyonrails.org/classes/ActionDispatch/Request.html)。下面说明部分属性：

| request 对象的属性 | 作用 |
|---------------|----|
| host | 请求的主机名 |
| domain(n=2) | 主机名的前 n 个片段，从顶级域名的右侧算起 |
| format | 客户端请求的内容类型 |
| method | 请求使用的 HTTP 方法 |
| get?, post?, patch?, put?, delete?, head? | 如果 HTTP 方法是 GET/POST/PATCH/PUT/DELETE/HEAD，返回 true |
| headers | 返回一个散列，包含请求的首部 |
| port | 请求的端口号（整数） |
| protocol | 返回所用的协议外加 "://"，例如 "http://" |
| query_string | URL 中的查询字符串，即 ? 后面的全部内容 |
| remote_ip | 客户端的 IP 地址 |
| url | 请求的完整 URL |

#### `path_parameters`、`query_parameters` 和 `request_parameters`

不管请求中的参数通过查询字符串发送，还是通过 POST 主体提交，Rails 都会把这些参数存入 `params` 散列中。`request` 对象有三个存取方法，用于获取各种类型的参数。`query_parameters` 散列中的参数来自查询参数；`request_parameters` 散列中的参数来自 POST 主体；`path_parameters` 散列中的参数来自路由，传入相应的控制器和动作。

### `response` 对象

`response` 对象通常不直接使用。`response` 对象在动作的执行过程中构建，把渲染的数据回送给用户。不过有时可能需要直接访问响应，比如在后置过滤器中。`response` 对象上的方法有些可以用于赋值。

| response 对象的属性 | 作用 |
|----------------|----|
| body | 回送客户端的数据，字符串格式。通常是 HTML。 |
| status | 响应的 HTTP 状态码，例如，请求成功时是 200，文件未找到时是 404。 |
| location | 重定向的 URL（如果重定向的话）。 |
| content_type | 响应的内容类型。 |
| charset | 响应使用的字符集。默认是 "utf-8"。 |
| headers | 响应的首部。 |

#### 设置自定义首部

如果想设置自定义首部，可以使用 `response.headers` 方法。`headers` 属性是一个散列，键为首部名，值为首部的值。Rails 会自动设置一些首部。如果想添加或者修改首部，赋值给 `response.headers` 即可，例如：

```ruby
response.headers["Content-Type"] = "application/pdf"
```

注意，上面这段代码直接使用 `content_type=` 方法更合理。

HTTP 身份验证
-------------

Rails 内置了两种 HTTP 身份验证机制：

- 基本身份验证

- 摘要身份验证

### HTTP 基本身份验证

大多数浏览器和 HTTP 客户端都支持 HTTP 基本身份验证。例如，在浏览器中如果要访问只有管理员才能查看的页面，会出现一个对话框，要求输入用户名和密码。使用内置的这种身份验证非常简单，只要使用一个方法，即 `http_basic_authenticate_with`。

```ruby
class AdminsController < ApplicationController
  http_basic_authenticate_with name: "humbaba", password: "5baa61e4"
end
```

添加 `http_basic_authenticate_with` 方法后，可以创建具有命名空间的控制器，继承自 `AdminsController`，`http_basic_authenticate_with` 方法会在这些控制器的所有动作运行之前执行，启用 HTTP 基本身份验证。

### HTTP 摘要身份验证

HTTP 摘要身份验证比基本验证高级，因为客户端不会在网络中发送明文密码（不过在 HTTPS 中基本验证是安全的）。在 Rails 中使用摘要验证非常简单，只需使用一个方法，即 `authenticate_or_request_with_http_digest`。

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

如上面的代码所示，`authenticate_or_request_with_http_digest` 方法的块只接受一个参数，用户名，返回值是密码。如果 `authenticate_or_request_with_http_digest` 返回 `false` 或 `nil`，表明身份验证失败。

数据流和文件下载
----------------

有时不想渲染 HTML 页面，而是把文件发送给用户。在所有的控制器中都可以使用 `send_data` 和 `send_file` 方法。这两个方法都会以数据流的方式发送数据。`send_file` 方法很方便，只要提供磁盘中文件的名称，就会用数据流发送文件内容。

若想把数据以流的形式发送给客户端，使用 `send_data` 方法：

```ruby
require "prawn"
class ClientsController < ApplicationController
  # 使用客户信息生成一份 PDF 文档
  # 然后返回文档，让用户下载
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

在上面的代码中，`download_pdf` 动作调用一个私有方法，生成 PDF 文档，然后返回字符串形式。返回的字符串会以数据流的形式发送给客户端，并为用户推荐一个文件名。有时发送文件流时，并不希望用户下载这个文件，比如嵌在 HTML 页面中的图像。若想告诉浏览器文件不是用来下载的，可以把 `:disposition` 选项设为 `"inline"`。这个选项的另外一个值，也是默认值，是 `"attachment"`。

### 发送文件

如果想发送磁盘中已经存在的文件，可以使用 `send_file` 方法。

```ruby
class ClientsController < ApplicationController
  # 以流的形式发送磁盘中现有的文件
  def download_pdf
    client = Client.find(params[:id])
    send_file("#{Rails.root}/files/clients/#{client.id}.pdf",
              filename: "#{client.name}.pdf",
              type: "application/pdf")
  end
end
```

`send_file` 一次只发送 4kB，而不是把整个文件都写入内存。如果不想使用数据流方式，可以把 `:stream` 选项设为 `false`。如果想调整数据块大小，可以设置 `:buffer_size` 选项。

如果没有指定 `:type` 选项，Rails 会根据 `:filename` 的文件扩展名猜测。如果没有注册扩展名对应的文件类型，则使用 `application/octet-stream`。

WARNING: 要谨慎处理用户提交数据（参数、cookies 等）中的文件路径，这有安全隐患，可能导致不该下载的文件被下载了。

TIP: 不建议通过 Rails 以数据流的方式发送静态文件，你可以把静态文件放在服务器的公共文件夹中。使用 Apache 或其他 Web 服务器下载效率更高，因为不用经由整个 Rails 栈处理。

### REST 式下载

虽然可以使用 `send_data` 方法发送数据，但是在 REST 架构的应用中，单独为下载文件操作写个动作有些多余。在 REST 架构下，上例中的 PDF 文件可以视作一种客户资源。Rails 提供了一种更符合 REST 架构的文件下载方法。下面这段代码重写了前面的例子，把下载 PDF 文件的操作放到 `show` 动作中，不使用数据流：

```ruby
class ClientsController < ApplicationController
  # 用户可以请求接收 HTML 或 PDF 格式的资源
  def show
    @client = Client.find(params[:id])

    respond_to do |format|
      format.html
      format.pdf { render pdf: generate_pdf(@client) }
    end
  end
end
```

为了让这段代码能顺利运行，要把 PDF 的 MIME 类型加入 Rails。在 `config/initializers/mime_types.rb` 文件中加入下面这行代码即可：

```ruby
Mime::Type.register "application/pdf", :pdf
```

NOTE: 配置文件不会在每次请求中都重新加载，为了让改动生效，需要重启服务器。

现在，如果用户想请求 PDF 版本，只要在 URL 后加上 `".pdf"` 即可：

```ruby
GET /clients/1.pdf
```

### 任意数据的实时流

在 Rails 中，不仅文件可以使用数据流的方式处理，在响应对象中，任何数据都可以视作数据流。`ActionController::Live` 模块可以和浏览器建立持久连接，随时随地把数据传送给浏览器。

#### 使用实时流

把 `ActionController::Live` 模块引入控制器中后，所有的动作都可以处理数据流。你可以像下面这样引入那个模块：

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

关于这段代码有一些注意事项。必须关闭响应流。如果忘记关闭，套接字就会一直处于打开状态。发送数据流之前，还要把内容类型设为 `text/event-stream`。这是因为在响应流上调用 `write` 或 `commit` 发送响应后（`response.committed?` 返回真值）就无法设置首部了。

#### 使用举例

假设你在制作一个卡拉 OK 机，用户想查看某首歌的歌词。每首歌（`Song`）都有很多行歌词，每一行歌词都要花一些时间（`num_beats`）才能唱完。

如果按照卡拉 OK 机的工作方式，等上一句唱完才显示下一行，可以像下面这样使用 `ActionController::Live`：

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

#### 使用数据流的注意事项

以数据流的方式发送任意数据是个强大的功能，如前面几个例子所示，你可以选择何时发送什么数据。不过，在使用时，要注意以下事项：

- 每次以数据流形式发送响应都会新建一个线程，然后把原线程中的局部变量复制过来。线程中有太多局部变量会降低性能。而且，线程太多也会影响性能。

- 忘记关闭响应流会导致套接字一直处于打开状态。使用响应流时一定要记得调用 `close` 方法。

- WEBrick 会缓冲所有响应，因此引入 `ActionController::Live` 也不会有任何效果。你应该使用不自动缓冲响应的服务器。

日志过滤
--------

Rails 在 `log` 文件夹中为每个环境都准备了一个日志文件。这些文件在调试时特别有用，但是线上应用并不用把所有信息都写入日志。

### 参数过滤

若想过滤特定的请求参数，禁止写入日志文件，可以在应用的配置文件中设置 `config.filter_parameters` 选项。过滤掉的参数在日志中显示为 `[FILTERED]`。

```ruby
config.filter_parameters << :password
```

NOTE: 指定的参数通过部分匹配正则表达式过滤掉。Rails 默认在相应的初始化脚本（`initializers/filter_parameter_logging.rb`）中过滤 `:password`，以及应用中常见的 `password` 和 `password_confirmation` 参数。

### 重定向过滤

有时需要从日志文件中过滤掉一些重定向的敏感数据，此时可以设置 `config.filter_redirect` 选项：

```ruby
config.filter_redirect << 's3.amazonaws.com'
```

过滤规则可以使用字符串、正则表达式，或者一个数组，包含字符串或正则表达式：

```ruby
config.filter_redirect.concat ['s3.amazonaws.com', /private_path/]
```

匹配的 URL 会显示为 `'[FILTERED]'`。

异常处理
--------

应用很有可能出错，错误发生时会抛出异常，这些异常是需要处理的。例如，如果用户访问一个链接，但数据库中已经没有对应的资源了，此时 Active Record 会抛出 `ActiveRecord::RecordNotFound` 异常。

在 Rails 中，异常的默认处理方式是显示“500 Server Error”消息。如果应用在本地运行，出错后会显示一个精美的调用跟踪，以及其他附加信息，让开发者快速找到出错的地方，然后修正。如果应用已经上线，Rails 则会简单地显示“500 Server Error”消息；如果是路由错误或记录不存在，则显示“404 Not Found”。有时你可能想换种方式捕获错误，以不同的方式显示报错信息。在 Rails 中，有很多层异常处理，详解如下。

### 默认的 500 和 404 模板

默认情况下，生产环境中的应用出错时会显示 404 或 500 错误消息，在开发环境中则抛出未捕获的异常。错误消息在 `public` 文件夹里的静态 HTML 文件中，分别是 `404.html` 和 `500.html`。你可以修改这两个文件，添加其他信息和样式，不过要记住，这两个是静态文件，不能使用 ERB、SCSS、CoffeeScript 或布局。

### `rescue_from`

捕获错误后如果想做更详尽的处理，可以使用 `rescue_from`。`rescue_from` 可以处理整个控制器及其子类中的某种（或多种）异常。

异常发生时，会被 `rescue_from` 捕获，异常对象会传入处理程序。处理程序可以是方法，也可以是 `Proc` 对象，由 `:with` 选项指定。也可以不用 `Proc` 对象，直接使用块。

下面的代码使用 `rescue_from` 截获所有 `ActiveRecord::RecordNotFound` 异常，然后做些处理。

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

    def record_not_found
      render plain: "404 Not Found", status: 404
    end
end
```

这段代码对异常的处理并不详尽，比默认的处理方式也没好多少。不过只要你能捕获异常，就可以做任何想做的处理。例如，可以新建一个异常类，当用户无权查看页面时抛出：

```ruby
class ApplicationController < ActionController::Base
  rescue_from User::NotAuthorized, with: :user_not_authorized

  private

    def user_not_authorized
      flash[:error] = "You don't have access to this section."
      redirect_back(fallback_location: root_path)
    end
end

class ClientsController < ApplicationController
  # 检查是否授权用户访问客户信息
  before_action :check_authorization

  # 注意，这个动作无需关心任何身份验证操作
  def edit
    @client = Client.find(params[:id])
  end

  private

    # 如果用户没有授权，抛出异常
    def check_authorization
      raise User::NotAuthorized unless current_user.admin?
    end
end
```

WARNING: 如果没有特别的原因，不要使用 `rescue_from Exception` 或 `rescue_from StandardError`，因为这会导致严重的副作用（例如，在开发环境中看不到异常详情和调用跟踪）。

NOTE: 在生产环境中，所有 `ActiveRecord::RecordNotFound` 异常都会导致渲染 404 错误页面。如果不想定制这一行为，无需处理这个异常。

NOTE: 某些异常只能在 `ApplicationController` 类中捕获，因为在异常抛出前控制器还没初始化，动作也没执行。

强制使用 HTTPS 协议
-------------------

有时，基于安全考虑，可能希望某个控制器只能通过 HTTPS 协议访问。为了达到这一目的，可以在控制器中使用 `force_ssl` 方法：

```ruby
class DinnerController
  force_ssl
end
```

与过滤器类似，也可指定 `:only` 或 `:except` 选项，设置只在某些动作上强制使用 HTTPS：

```ruby
class DinnerController
  force_ssl only: :cheeseburger
  # 或者
  force_ssl except: :cheeseburger
end
```

注意，如果你在很多控制器中都使用了 `force_ssl`，或许你想让整个应用都使用 HTTPS。此时，你可以在环境配置文件中设定 `config.force_ssl` 选项。
