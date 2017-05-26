# 使用 Rails 开发只提供 API 的应用

在本文中您将学到：

*   Rails 对只提供 API 的应用的支持；
*   如何配置 Rails，不使用任何针对浏览器的功能；
*   如何决定使用哪些中间件；
*   如何决定在控制器中使用哪些模块。

-----------------------------------------------------------------------------

<a class="anchor" id="what-is-an-api-application-questionmark"></a>

## 什么是 API 应用？

人们说把 Rails 用作“API”，通常指的是在 Web 应用之外提供一份可通过编程方式访问的 API。例如，GitHub 提供了 [API](http://developer.github.com/)，供你在自己的客户端中使用。

随着客户端框架的出现，越来越多的开发者使用 Rails 构建后端，在 Web 应用和其他原生应用之间共享。

例如，Twitter 使用自己的[公开 API](https://dev.twitter.com/) 构建 Web 应用，而文档网站是一个静态网站，消费 JSON 资源。

很多人不再使用 Rails 生成 HTML，通过表单和链接与服务器通信，而是把 Web 应用当做 API 客户端，分发包含 JavaScript 的 HTML，消费 JSON API。

本文说明如何构建伺服 JSON 资源的 Rails 应用，供 API 客户端（包括客户端框架）使用。

<a class="anchor" id="why-use-rails-for-json-apis-questionmark"></a>

## 为什么使用 Rails 构建 JSON API？

提到使用 Rails 构建 JSON API，多数人想到的第一个问题是：“使用 Rails 生成 JSON 是不是有点大材小用了？使用 Sinatra 这样的框架是不是更好？”

对特别简单的 API 来说，确实如此。然而，对大量使用 HTML 的应用来说，应用的逻辑大都在视图层之外。

多数人使用 Rails 的原因是，Rails 提供了一系列默认值，开发者能快速上手，而不用做些琐碎的决定。

下面是 Rails 提供的一些开箱即用的功能，这些功能在 API 应用中也适用。

在中间件层处理的功能：

*   重新加载：Rails 应用支持简单明了的重新加载机制。即使应用变大，每次请求都重启服务器变得不切实际，这一机制依然适用。
*   开发模式：Rails 应用自带智能的开发默认值，使得开发过程很愉快，而且不会破坏生产环境的效率。
*   测试模式：同开发模式。
*   日志：Rails 应用会在日志中记录每次请求，而且为不同环境设定了合适的详细等级。在开发环境中，Rails 记录的信息包括请求环境、数据库查询和基本的性能信息。
*   安全性：Rails 能检测并防范 [IP 欺骗攻击](https://en.wikipedia.org/wiki/IP_address_spoofing)，还能处理[时序攻击](http://en.wikipedia.org/wiki/Timing_attack)中的加密签名。不知道 IP 欺骗攻击和时序攻击是什么？这就对了。
*   参数解析：想以 JSON 的形式指定参数，而不是 URL 编码字符串形式？没问题。Rails 会代为解码 JSON，存入 `params` 中。想使用嵌套的 URL 编码参数？也没问题。
*   条件 GET 请求：Rails 能处理条件 `GET` 请求相关的首部（`ETag` 和 `Last-Modified`），然后返回正确的响应首部和状态码。你只需在控制器中使用 [`stale?`](http://api.rubyonrails.org/classes/ActionController/ConditionalGet.html#method-i-stale-3F) 做检查，剩下的 HTTP 细节都由 Rails 处理。
*   HEAD 请求：Rails 会把 `HEAD` 请求转换成 `GET` 请求，只返回首部。这样 `HEAD` 请求在所有 Rails API 中都可靠。

虽然这些功能可以使用 Rack 中间件实现，但是上述列表的目的是说明 Rails 默认提供的中间件栈提供了大量有价值的功能，即便“只是生成 JSON”也用得到。

在 Action Pack 层处理的功能：

*   资源式路由：如果构建的是 REST 式 JSON API，你会想用 Rails 路由器的。按照约定以简明的方式把 HTTP 映射到控制器上能节省很多时间，不用再从 HTTP 方面思考如何建模 API。
*   URL 生成：路由的另一面是 URL 生成。基于 HTTP 的优秀 API 包含 URL（比如 [GitHub Gist API](http://developer.github.com/v3/gists/)）。
*   首部和重定向响应：`head :no_content` 和 `redirect_to user_url(current_user)` 用着很方便。当然，你可以自己动手添加相应的响应首部，但是为什么要费这事呢？
*   缓存：Rails 提供了页面缓存、动作缓存和片段缓存。构建嵌套的 JSON 对象时，片段缓存特别有用。
*   基本身份验证、摘要身份验证和令牌身份验证：Rails 默认支持三种 HTTP 身份验证。
*   监测程序：Rails 提供了监测 API，在众多事件发生时触发注册的处理程序，例如处理动作、发送文件或数据、重定向和数据库查询。各个事件的载荷中包含相关的信息（对动作处理事件来说，载荷中包括控制器、动作、参数、请求格式、请求方法和完整的请求路径）。
*   生成器：通常生成一个资源就能把模型、控制器、测试桩件和路由在一个命令中通通创建出来，然后再做调整。迁移等也有生成器。
*   插件：有很多第三方库支持 Rails，这样不必或很少需要花时间设置及把库与 Web 框架连接起来。插件可以重写默认的生成器、添加 Rake 任务，而且继续使用 Rails 选择的处理方式（如日志记录器和缓存后端）。

当然，Rails 启动过程还是要把各个注册的组件连接起来。例如，Rails 启动时会使用 `config/database.yml` 文件配置 Active Record。

简单来说，你可能没有想过去掉视图层之后要把 Rails 的哪些部分保留下来，不过答案是，多数都要保留。

<a class="anchor" id="the-basic-configuration"></a>

## 基本配置

如果你构建的 Rails 应用主要用作 API，可以从较小的 Rails 子集开始，然后再根据需要添加功能。

<a class="anchor" id="creating-a-new-application"></a>

### 新建应用

生成 Rails API 应用使用下述命令：

```sh
$ rails new my_api --api
```

这个命令主要做三件事：

*   配置应用，使用有限的中间件（比常规应用少）。具体而言，不含默认主要针对浏览器应用的中间件（如提供 cookie 支持的中间件）。
*   让 `ApplicationController` 继承 `ActionController::API`，而不继承 `ActionController::Base`。与中间件一样，这样做是为了去除主要针对浏览器应用的  Action Controller 模块。
*   配置生成器，生成资源时不生成视图、辅助方法和静态资源。

<a class="anchor" id="changing-an-existing-application"></a>

### 修改现有应用

如果你想把现有的应用改成 API 应用，请阅读下述步骤。

在 `config/application.rb` 文件中，把下面这行代码添加到 `Application` 类定义的顶部：

```ruby
config.api_only = true
```

在 `config/environments/development.rb` 文件中，设定 `config.debug_exception_response_format` 选项，配置在开发环境中出现错误时响应使用的格式。

如果想使用 HTML 页面渲染调试信息，把值设为 `:default`：

```ruby
config.debug_exception_response_format = :default
```

如果想使用响应所用的格式渲染调试信息，把值设为 `:api`：

```ruby
config.debug_exception_response_format = :api
```

默认情况下，`config.api_only` 的值为 `true` 时，`config.debug_exception_response_format` 的值是 `:api`。

最后，在 `app/controllers/application_controller.rb` 文件中，把下述代码

```ruby
class ApplicationController < ActionController::Base
end
```

改为

```ruby
class ApplicationController < ActionController::API
end
```

<a class="anchor" id="choosing-middleware"></a>

## 选择中间件

API 应用默认包含下述中间件：

*   `Rack::Sendfile`
*   `ActionDispatch::Static`
*   `ActionDispatch::Executor`
*   `ActiveSupport::Cache::Strategy::LocalCache::Middleware`
*   `Rack::Runtime`
*   `ActionDispatch::RequestId`
*   `Rails::Rack::Logger`
*   `ActionDispatch::ShowExceptions`
*   `ActionDispatch::DebugExceptions`
*   `ActionDispatch::RemoteIp`
*   `ActionDispatch::Reloader`
*   `ActionDispatch::Callbacks`
*   `ActiveRecord::Migration::CheckPending`
*   `Rack::Head`
*   `Rack::ConditionalGet`
*   `Rack::ETag`

各个中间件的作用参见 [内部中间件栈](rails_on_rack.html#internal-middleware-stack)。

其他插件，包括 Active Record，可能会添加额外的中间件。一般来说，这些中间件对要构建的应用类型一无所知，可以在只提供 API 的 Rails 应用中使用。

可以通过下述命令列出应用中的所有中间件：

```sh
$ rails middleware
```

<a class="anchor" id="using-the-cache-middleware"></a>

### 使用缓存中间件

默认情况下，Rails 会根据应用的配置提供一个缓存存储器（默认为 memcache）。因此，内置的 HTTP 缓存依靠这个中间件。

例如，使用 `stale?` 方法：

```ruby
def show
  @post = Post.find(params[:id])

  if stale?(last_modified: @post.updated_at)
    render json: @post
  end
end
```

上述 `stale?` 调用比较请求中的 `If-Modified-Since` 首部和 `@post.updated_at`。如果首部的值比最后修改时间晚，这个动作返回“304 未修改”响应；否则，渲染响应，并且设定 `Last-Modified` 首部。

通常，这个机制会区分客户端。缓存中间件支持跨客户端共享这种缓存机制。跨客户端缓存可以在调用 `stale?` 时启用：

```ruby
def show
  @post = Post.find(params[:id])

  if stale?(last_modified: @post.updated_at, public: true)
    render json: @post
  end
end
```

这表明，缓存中间件会在 Rails 缓存中存储 URL 的 `Last-Modified` 值，而且为后续对同一个 URL 的入站请求添加 `If-Modified-Since` 首部。

可以把这种机制理解为使用 HTTP 语义的页面缓存。

<a class="anchor" id="using-rack-sendfile"></a>

### 使用 Rack::Sendfile

在 Rails 控制器中使用 `send_file` 方法时，它会设定 `X-Sendfile` 首部。`Rack::Sendfile` 负责发送文件。

如果前端服务器支持加速发送文件，`Rack::Sendfile` 会把文件交给前端服务器发送。

此时，可以在环境的配置文件中设定 `config.action_dispatch.x_sendfile_header` 选项，为前端服务器指定首部的名称。

关于如何在流行的前端服务器中使用 `Rack::Sendfile`，参见 [`Rack::Sendfile` 的文档](http://rubydoc.info/github/rack/rack/master/Rack/Sendfile)。

下面是两个流行的服务器的配置。这样配置之后，就能支持加速文件发送功能了。

```ruby
# Apache 和 lighttpd
config.action_dispatch.x_sendfile_header = "X-Sendfile"

# Nginx
config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"
```

请按照 `Rack::Sendfile` 文档中的说明配置你的服务器。

<a class="anchor" id="using-actiondispatch-request"></a>

### 使用 ActionDispatch::Request

`ActionDispatch::Request#params` 获取客户端发来的 JSON 格式参数，将其存入 `params`，可在控制器中访问。

为此，客户端要发送 JSON 编码的参数，并把 `Content-Type` 设为 `application/json`。

下面以 jQuery 为例：

```js
jQuery.ajax({
  type: 'POST',
  url: '/people',
  dataType: 'json',
  contentType: 'application/json',
  data: JSON.stringify({ person: { firstName: "Yehuda", lastName: "Katz" } }),
  success: function(json) { }
});
```

`ActionDispatch::Request` 检查 `Content-Type` 后，把参数转换成：

```ruby
{ :person => { :firstName => "Yehuda", :lastName => "Katz" } }
```

<a class="anchor" id="other-middleware"></a>

### 其他中间件

Rails 自带的其他中间件在 API 应用中可能也会用到，尤其是 API 客户端包含浏览器时：

*   `Rack::MethodOverride`
*   `ActionDispatch::Cookies`
*   `ActionDispatch::Flash`
*   管理会话

    *   `ActionDispatch::Session::CacheStore`
    *   `ActionDispatch::Session::CookieStore`
    *   `ActionDispatch::Session::MemCacheStore`



这些中间件可通过下述方式添加：

```ruby
config.middleware.use Rack::MethodOverride
```

<a class="anchor" id="removing-middleware"></a>

### 删除中间件

如果默认的 API 中间件中有不需要使用的，可以通过下述方式将其删除：

```ruby
config.middleware.delete ::Rack::Sendfile
```

注意，删除中间件后 Action Controller 的特定功能就不可用了。

<a class="anchor" id="choosing-controller-modules"></a>

## 选择控制器模块

API 应用（使用 `ActionController::API`）默认有下述控制器模块：

*   `ActionController::UrlFor`：提供 `url_for` 等辅助方法。
*   `ActionController::Redirecting`：提供 `redirect_to`。
*   `AbstractController::Rendering` 和 `ActionController::ApiRendering`：提供基本的渲染支持。
*   `ActionController::Renderers::All`：提供 `render :json` 等。
*   `ActionController::ConditionalGet`：提供 `stale?`。
*   `ActionController::BasicImplicitRender`：如果没有显式响应，确保返回一个空响应。
*   `ActionController::StrongParameters`：结合 Active Model 批量赋值，提供参数白名单过滤功能。
*   `ActionController::ForceSSL`：提供 `force_ssl`。
*   `ActionController::DataStreaming`：提供 `send_file` 和 `send_data`。
*   `AbstractController::Callbacks`：提供 `before_action` 等方法。
*   `ActionController::Rescue`：提供 `rescue_from`。
*   `ActionController::Instrumentation`：提供 Action Controller 定义的监测钩子（详情参见 [Action Controller](active_support_instrumentation.html#action-controller)）。
*   `ActionController::ParamsWrapper`：把参数散列放到一个嵌套散列中，这样在发送 POST 请求时无需指定根元素。

其他插件可能会添加额外的模块。`ActionController::API` 引入的模块可以在 Rails 控制台中列出：

```sh
$ bin/rails c
>> ActionController::API.ancestors - ActionController::Metal.ancestors
=> [ActionController::API,
    ActiveRecord::Railties::ControllerRuntime,
    ActionDispatch::Routing::RouteSet::MountedHelpers,
    ActionController::ParamsWrapper,
    ... ,
    AbstractController::Rendering,
    ActionView::ViewPaths]
```

<a class="anchor" id="adding-other-modules"></a>

### 添加其他模块

所有 Action Controller 模块都知道它们所依赖的模块，因此在控制器中可以放心引入任何模块，所有依赖都会自动引入。

可能想添加的常见模块有：

*   `AbstractController::Translation`：提供本地化和翻译方法 `l` 和 `t`。
*   `ActionController::HttpAuthentication::Basic`（或 `Digest` 或 `Token`）：提供基本、摘要或令牌 HTTP 身份验证。
*   `ActionView::Layouts`：渲染时支持使用布局。
*   `ActionController::MimeResponds`：提供 `respond_to`。
*   `ActionController::Cookies`：提供 `cookies`，包括签名和加密 cookie。需要 cookies 中间件支持。

模块最好添加到 `ApplicationController` 中，不过也可以在各个控制器中添加。
