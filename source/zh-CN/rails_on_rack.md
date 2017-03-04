Rails on Rack
=============

本文简介 Rails 与 Rack 的集成，以及与其他 Rack 组件的配合。

读完本文后，您将学到：

- 如何在 Rails 应用中使用 Rack 中间件；

- Action Pack 内部的中间件栈；

- 如何自定义中间件栈。

WARNING: 本文假定你对 Rack 协议和相关概念有一定了解，例如中间件、URL 映射和 `Rack::Builder`。

--------------------------------------------------------------------------------

Rack 简介
---------

Rack 为使用 Ruby 开发的 Web 应用提供最简单的模块化接口，而且适应性强。Rack 使用最简单的方式包装 HTTP 请求和响应，从而抽象了 Web 服务器、Web 框架，以及二者之间的软件（称为中间件）的 API，统一成一个方法调用。

- [Rack API 文档](http://rack.github.io/)

本文不详尽说明 Rack。如果你不了解 Rack 的基本概念，请参阅 [资源](#资源)。

Rails on Rack
-------------

### Rails 应用的 Rack 对象

`Rails.application` 是 Rails 应用的主 Rack 应用对象。任何兼容 Rack 的 Web 服务器都应该使用 `Rails.application` 对象伺服 Rails 应用。

### `rails server`

`rails server` 负责创建 `Rack::Server` 对象和启动 Web 服务器。

`rails server` 创建 `Rack::Server` 实例的方式如下：

```ruby
Rails::Server.new.tap do |server|
  require APP_PATH
  Dir.chdir(Rails.application.root)
  server.start
end
```

`Rails::Server` 继承自 `Rack::Server`，像下面这样调用 `Rack::Server#start` 方法：

```ruby
class Server < ::Rack::Server
  def start
    ...
    super
  end
end
```

### `rackup`

如果不想使用 Rails 提供的 `rails server` 命令，而是使用 `rackup`，可以把下述代码写入 Rails 应用根目录中的 `config.ru` 文件里：

```ruby
# Rails.root/config.ru
require ::File.expand_path('../config/environment', __FILE__)
run Rails.application
```

然后使用下述命令启动服务器：

```sh
$ rackup config.ru
```

`rackup` 命令的各个选项可以通过下述命令查看：

```sh
$ rackup --help
```

### 开发和自动重新加载

中间件只加载一次，不会监视变化。若想让改动生效，必须重启服务器。

Action Dispatcher 中间件栈
--------------------------

Action Dispatcher 的内部组件很多都实现为 Rack 中间件。`Rails::Application` 使用 `ActionDispatch::MiddlewareStack` 把不同的内部和外部中间件组合在一起，构成完整的 Rails Rack 中间件。

NOTE: Rails 中的 `ActionDispatch::MiddlewareStack` 相当于 `Rack::Builder`，但是为了满足 Rails 的需求，前者更灵活，而且功能更多。

### 审查中间件栈

Rails 提供了一个方便的任务，用于查看在用的中间件栈：

```sh
$ bin/rails middleware
```

在新生成的 Rails 应用中，上述命令可能会输出下述内容：

    use Rack::Sendfile
    use ActionDispatch::Static
    use ActionDispatch::Executor
    use #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x000000029a0838>
    use Rack::Runtime
    use Rack::MethodOverride
    use ActionDispatch::RequestId
    use Rails::Rack::Logger
    use ActionDispatch::ShowExceptions
    use ActionDispatch::DebugExceptions
    use ActionDispatch::RemoteIp
    use ActionDispatch::Reloader
    use ActionDispatch::Callbacks
    use ActiveRecord::Migration::CheckPending
    use ActiveRecord::ConnectionAdapters::ConnectionManagement
    use ActiveRecord::QueryCache
    use ActionDispatch::Cookies
    use ActionDispatch::Session::CookieStore
    use ActionDispatch::Flash
    use Rack::Head
    use Rack::ConditionalGet
    use Rack::ETag
    run Rails.application.routes

这里列出的默认中间件（以及其他一些）在 [内部中间件栈](#内部中间件栈)概述。

### 配置中间件栈

Rails 提供了一个简单的配置接口，`config.middleware`，用于在 `application.rb` 或针对环境的配置文件 `environments/<environment>.rb` 中添加、删除和修改中间件栈。

#### 添加中间件

可以通过下述任意一种方法向中间件栈里添加中间件：

- `config.middleware.use(new_middleware, args)`：在中间件栈的末尾添加一个中间件。

- `config.middleware.insert_before(existing_middleware, new_middleware, args)`：在中间件栈里指定现有中间件的前面添加一个中间件。

- `config.middleware.insert_after(existing_middleware, new_middleware, args)`：在中间件栈里指定现有中间件的后面添加一个中间件。

```ruby
# config/application.rb

# 把 Rack::BounceFavicon 放在默认
config.middleware.use Rack::BounceFavicon

# 在 ActiveRecord::QueryCache 后面添加 Lifo::Cache
# 把 { page_cache: false } 参数传给 Lifo::Cache.
config.middleware.insert_after ActiveRecord::QueryCache, Lifo::Cache, page_cache: false
```

#### 替换中间件

可以使用 `config.middleware.swap` 替换中间件栈里的现有中间件：

```ruby
# config/application.rb

# 把 ActionDispatch::ShowExceptions 换成 Lifo::ShowExceptions
config.middleware.swap ActionDispatch::ShowExceptions, Lifo::ShowExceptions
```

#### 删除中间件

在应用的配置文件中添加下面这行代码：

```ruby
# config/application.rb
config.middleware.delete Rack::Runtime
```

然后审查中间件栈，你会发现没有 `Rack::Runtime` 了：

```sh
$ bin/rails middleware
(in /Users/lifo/Rails/blog)
use ActionDispatch::Static
use #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x00000001c304c8>
use Rack::Runtime
...
run Rails.application.routes
```

若想删除会话相关的中间件，这么做：

```ruby
# config/application.rb
config.middleware.delete ActionDispatch::Cookies
config.middleware.delete ActionDispatch::Session::CookieStore
config.middleware.delete ActionDispatch::Flash
```

若想删除浏览器相关的中间件，这么做：

```ruby
# config/application.rb
config.middleware.delete Rack::MethodOverride
```

### 内部中间件栈

Action Controller 的大部分功能都实现成中间件。下面概述它们的作用。

`Rack::Sendfile`  
在服务器端设定 X-Sendfile 首部。通过 `config.action_dispatch.x_sendfile_header` 选项配置。

`ActionDispatch::Static`  
用于伺服 public 目录中的静态文件。如果把 `config.public_file_server.enabled` 设为 `false`，禁用这个中间件。

`Rack::Lock`  
把 `env["rack.multithread"]` 设为 `false`，把应用包装到 Mutex 中。

`ActionDispatch::Executor`  
用于在开发环境中以线程安全方式重新加载代码。

`ActiveSupport::Cache::Strategy::LocalCache::Middleware`  
用于缓存内存。这个缓存对线程不安全。

`Rack::Runtime`  
设定 X-Runtime 首部，包含执行请求的用时（单位为秒）。

`Rack::MethodOverride`  
如果设定了 `params[:_method]`，允许覆盖请求方法。`PUT` 和 `DELETE` 两个 HTTP 方法就是通过这个中间件提供支持的。

`ActionDispatch::RequestId`  
在响应中设定唯一的 `X-Request-Id` 首部，并启用 `ActionDispatch::Request#request_id` 方法。

`Rails::Rack::Logger`  
通知日志，请求开始了。请求完毕后，清空所有相关日志。

`ActionDispatch::ShowExceptions`  
拯救应用返回的所有异常，调用处理异常的应用，把异常包装成对终端用户友好的格式。

`ActionDispatch::DebugExceptions`  
如果是本地请求，负责在日志中记录异常，并显示调试页面。

`ActionDispatch::RemoteIp`  
检查 IP 欺骗攻击。

`ActionDispatch::Reloader`  
提供准备和清理回调，目的是在开发环境中协助重新加载代码。

`ActionDispatch::Callbacks`  
提供回调，在分派请求前后执行。

`ActiveRecord::Migration::CheckPending`  
检查有没有待运行的迁移，如果有，抛出 `ActiveRecord::PendingMigrationError`。

`ActiveRecord::ConnectionAdapters::ConnectionManagement`  
如果没在请求环境中把 `rack.test` 键设为 `true`，每次请求后清理活跃连接。

`ActiveRecord::QueryCache`  
启用 Active Record 查询缓存。

`ActionDispatch::Cookies`  
为请求设定 cookie。

`ActionDispatch::Session::CookieStore`  
负责把会话存储在 cookie 中。

`ActionDispatch::Flash`  
设置闪现消息的键。仅当为 `config.action_controller.session_store` 设定值时才启用。

`Rack::Head`  
把 HEAD 请求转换成 GET 请求，然后伺服 GET 请求。

`Rack::ConditionalGet`  
支持“条件 GET 请求”，如果页面没变，服务器不做响应。

`Rack::ETag`  
为所有字符串主体添加 ETag 首部。ETag 用于验证缓存。

TIP: 在自定义的 Rack 栈中可以使用上述任何一个中间件。

资源
----

### 学习 Rack

- [Rack 官方网站](http://rack.github.io/)

- [Introducing Rack](http://chneukirchen.org/blog/archive/2007/02/introducing-rack.html)

### 理解中间件

- [Railscast 中讲解 Rack 中间件的视频](http://railscasts.com/episodes/151-rack-middleware)
