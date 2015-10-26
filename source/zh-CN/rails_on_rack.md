Rails on Rack
==============

本文介绍 Rails 和 Rack 的集成，以及与其他 Rack 组件的配合。

读完本文，你将学到：

* 如何在 Rails 程序中使用中间件；
* Action Pack 内建的中间件；
* 如何编写中间件；

--------------------------------------------------------------------------------

WARNING: 阅读本文之前需要了解 Rack 协议及相关概念，如中间件、URL 映射和 `Rack::Builder`。

Rack 简介
---------

Rack 为使用 Ruby 开发的网页程序提供了小型模块化，适应性极高的接口。Rack 尽量使用最简单的方式封装 HTTP 请求和响应，为服务器、框架和二者之间的软件（中间件）提供了统一的 API，只要调用一个简单的方法就能完成一切操作。

- [Rack API 文档](http://rack.rubyforge.org/doc/)

详细解说 Rack 不是本文的目的，如果不知道 Rack 基础知识，可以阅读“[参考资源](#resources)”一节。

Rails on Rack
-------------

### Rails 程序中的 Rack 对象

`ApplicationName::Application` 是 Rails 程序中最主要的 Rack 程序对象。任何支持 Rack 的服务器都应该使用 `ApplicationName::Application` 对象服务 Rails 程序。`Rails.application` 也指向 `ApplicationName::Application` 对象。

### `rails server`

`rails server` 命令会创建 `Rack::Server` 对象并启动服务器。

`rails server` 创建 `Rack::Server` 实例的方法如下：

```ruby
Rails::Server.new.tap do |server|
  require APP_PATH
  Dir.chdir(Rails.application.root)
  server.start
end
```

`Rails::Server` 继承自 `Rack::Server`，使用下面的方式调用 `Rack::Server#start` 方法：

```ruby
class Server < ::Rack::Server
  def start
    ...
    super
  end
end
```

`Rails::Server` 加载中间件的方式如下：

```ruby
def middleware
  middlewares = []
  middlewares << [Rails::Rack::Debugger] if options[:debugger]
  middlewares << [::Rack::ContentLength]
  Hash.new(middlewares)
end
```

`Rails::Rack::Debugger` 基本上只在开发环境中有用。下表说明了加载的各中间件的用途：

| 中间件                  | 用途                                                          |
| ----------------------- | ------------------------------------------------------------- |
| `Rails::Rack::Debugger` | 启用调试功能                                                  |
| `Rack::ContentLength`   | 计算响应的长度，单位为字节，然后设置 HTTP Content-Length 报头 |

### `rackup`

如果想用 `rackup` 代替 `rails server` 命令，可以在 Rails 程序根目录下的 `config.ru` 文件中写入下面的代码：

```ruby
# Rails.root/config.ru
require ::File.expand_path('../config/environment', __FILE__)

use Rails::Rack::Debugger
use Rack::ContentLength
run Rails.application
```

然后使用下面的命令启动服务器：

```bash
$ rackup config.ru
```

查看 `rackup` 的其他选项，可以执行下面的命令：

```bash
$ rackup --help
```

Action Dispatcher 中间件
-----------------------

Action Dispatcher 中的很多组件都以 Rack 中间件的形式实现。`Rails::Application` 通过 `ActionDispatch::MiddlewareStack` 把内部和外部的中间件组合在一起，形成一个完整的 Rails Rack 程序。

NOTE: 在 Rails 中，`ActionDispatch::MiddlewareStack` 的作用和 `Rack::Builder` 一样，不过前者更灵活，也为满足 Rails 的需求加入了更多功能。

### 查看使用的中间件

Rails 提供了一个 rake 任务，用来查看使用的中间件：

```bash
$ rake middleware
```

在新建的 Rails 程序中，可能会输出如下结果：

```ruby
use Rack::Sendfile
use ActionDispatch::Static
use Rack::Lock
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
use ActionDispatch::ParamsParser
use Rack::Head
use Rack::ConditionalGet
use Rack::ETag
run MyApp::Application.routes
```

这里列出的各中间件在“[内部中间件](#internal-middleware-stack)”一节有详细介绍。

### 设置中间件

Rails 在 `application.rb` 或 `environments/<environment>.rb` 文件中提供了一个简单的设置项 `config.middleware`，可以在middleware堆栈中添加，修改和删除中间件 。

#### 添加新中间件

使用下面列出的任何一种方法都可以添加新中间件：

* `config.middleware.use(new_middleware, args)`：把新中间件添加到列表末尾；
* `config.middleware.insert_before(existing_middleware, new_middleware, args)`：在 `existing_middleware` 之前添加新中间件；
* `config.middleware.insert_after(existing_middleware, new_middleware, args)`：在 `existing_middleware` 之后添加新中间件；

```ruby
# config/application.rb

# Push Rack::BounceFavicon at the bottom
config.middleware.use Rack::BounceFavicon

# Add Lifo::Cache after ActiveRecord::QueryCache.
# Pass { page_cache: false } argument to Lifo::Cache.
config.middleware.insert_after ActiveRecord::QueryCache, Lifo::Cache, page_cache: false
```

#### 替换中间件

使用 `config.middleware.swap` 可以替换middleware堆栈中的中间件：

```ruby
# config/application.rb

# Replace ActionDispatch::ShowExceptions with Lifo::ShowExceptions
config.middleware.swap ActionDispatch::ShowExceptions, Lifo::ShowExceptions
```

#### 删除中间件

在程序的设置文件中加入下面的代码：

```ruby
# config/application.rb
config.middleware.delete "Rack::Lock"
```

现在查看所用的中间件，会发现 `Rack::Lock` 不在输出结果中。

```bash
$ rake middleware
(in /Users/lifo/Rails/blog)
use ActionDispatch::Static
use #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x00000001c304c8>
use Rack::Runtime
...
run Blog::Application.routes
```

如果想删除会话相关的中间件，可以这么做：

```ruby
# config/application.rb
config.middleware.delete "ActionDispatch::Cookies"
config.middleware.delete "ActionDispatch::Session::CookieStore"
config.middleware.delete "ActionDispatch::Flash"
```

删除浏览器相关的中间件：

```ruby
# config/application.rb
config.middleware.delete "Rack::MethodOverride"
```

### 内部中间件

Action Controller 的很多功能都以中间件的形式实现。下面解释个中间件的作用。

**`Rack::Sendfile`**：设置服务器上的 X-Sendfile 报头。通过 `config.action_dispatch.x_sendfile_header` 选项设置。

**`ActionDispatch::Static`**：用来服务静态资源文件。如果选项 `config.serve_static_assets` 为 `false`，则禁用这个中间件。

**`Rack::Lock`**：把 `env["rack.multithread"]` 旗标设为 `false`，程序放入互斥锁中。

**`ActiveSupport::Cache::Strategy::LocalCache::Middleware`**：在内存中保存缓存，非线程安全。

**`Rack::Runtime`**：设置 X-Runtime 报头，即执行请求的时长，单位为秒。

**`Rack::MethodOverride`**：如果指定了 `params[:_method]` 参数，会覆盖所用的请求方法。这个中间件实现了 PUT 和 DELETE 方法。

**`ActionDispatch::RequestId`**：在响应中设置一个唯一的 X-Request-Id 报头，并启用 `ActionDispatch::Request#uuid` 方法。

**`Rails::Rack::Logger`**：请求开始时提醒日志，请求完成后写入日志。

**`ActionDispatch::ShowExceptions`**：补救程序抛出的所有异常，调用处理异常的程序，使用特定的格式显示给用户。

**`ActionDispatch::DebugExceptions`**：如果在本地开发，把异常写入日志，并显示一个调试页面。

**`ActionDispatch::RemoteIp`**：检查欺骗攻击的 IP。

**`ActionDispatch::Reloader`**：提供“准备”和“清理”回调，协助开发环境中的代码重新加载功能。

**`ActionDispatch::Callbacks`**：在处理请求之前调用“准备”回调。

**`ActiveRecord::Migration::CheckPending`**：检查是否有待运行的迁移，如果有就抛出 `ActiveRecord::PendingMigrationError` 异常。

**`ActiveRecord::ConnectionAdapters::ConnectionManagement`**：请求处理完成后，清理活跃的连接，除非在发起请求的环境中把 `rack.test` 设为 `true`。

**`ActiveRecord::QueryCache`**：启用 Active Record 查询缓存。

**`ActionDispatch::Cookies`**：设置请求的 cookies。

**`ActionDispatch::Session::CookieStore`**：负责把会话存储在 cookies 中。

**`ActionDispatch::Flash`**：设置 Flash 消息的键。只有设定了 `config.action_controller.session_store` 选项时才可用。

**`ActionDispatch::ParamsParser`**：把请求中的参数出入 `params`。

**`ActionDispatch::Head`**：把 HEAD 请求转换成 GET 请求，并处理。

**`Rack::ConditionalGet`**：添加对“条件 GET”的支持，如果页面未修改，就不响应。

**`Rack::ETag`**：为所有字符串类型的主体添加 ETags 报头。ETags 用来验证缓存。

TIP: 设置 Rack 时可使用上述任意一个中间件。

参考资源
-------

### 学习

* [Rack 官网](http://rack.github.io)
* [Rack 简介](http://chneukirchen.org/blog/archive/2007/02/introducing-rack.html)
* [Ruby on Rack #1 - Hello Rack!](http://m.onkey.org/ruby-on-rack-1-hello-rack)
* [Ruby on Rack #2 - The Builder](http://m.onkey.org/ruby-on-rack-2-the-builder)

### 理解中间件

* [Railscast 介绍 Rack 中间件的视频](http://railscasts.com/episodes/151-rack-middleware)
