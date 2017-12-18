# 配置 Rails 应用

本文涵盖 Rails 应用可用的配置和初始化功能。

读完本文后，您将学到：

*   如何调整 Rails 应用的行为；
*   如何增加额外代码，在应用启动时运行。

-----------------------------------------------------------------------------

<a class="anchor" id="locations-for-initialization-code"></a>

## 初始化代码的存放位置

Rails 为初始化代码提供了四个标准位置：

*   `config/application.rb`
*   针对各环境的配置文件
*   初始化脚本
*   后置初始化脚本

<a class="anchor" id="running-code-before-rails"></a>

## 在 Rails 之前运行代码

虽然在加载 Rails 自身之前运行代码很少见，但是如果想这么做，可以把代码添加到 `config/application.rb` 文件中 `require 'rails/all'` 的前面。

<a class="anchor" id="configuring-rails-components"></a>

## 配置 Rails 组件

一般来说，配置 Rails 的意思是配置 Rails 的组件和 Rails 自身。传给各个组件的设置在 `config/application.rb` 配置文件或者针对各环境的配置文件（如 `config/environments/production.rb`）中指定。

例如，`config/application.rb` 文件中有下述设置：

```ruby
config.time_zone = 'Central Time (US & Canada)'
```

这是针对 Rails 自身的设置。如果想把设置传给某个 Rails 组件，依然是在 `config/application.rb` 文件中通过 `config` 对象去做：

```ruby
config.active_record.schema_format = :ruby
```

Rails 会使用这个设置配置 Active Record。

<a class="anchor" id="rails-general-configuration"></a>

### Rails 的一般性配置

这些配置方法在 `Rails::Railtie` 对象上调用，例如 `Rails::Engine` 或 `Rails::Application` 的子类。

*   `config.after_initialize` 接受一个块，在 Rails 初始化应用之后运行。初始化过程包括初始化框架自身、引擎和 `config/initializers` 目录中的全部初始化脚本。注意，这个块会被 Rake 任务运行。可用于配置其他初始化脚本设定的值：

    ```ruby
    config.after_initialize do
      ActionView::Base.sanitized_allowed_tags.delete 'div'
    end
    ```


*   `config.asset_host` 设定静态资源文件的主机名。使用 CDN 贮存静态资源文件，或者想绕开浏览器对同一域名的并发连接数的限制时可以使用这个选项。这是 `config.action_controller.asset_host` 的简短版本。
*   `config.autoload_once_paths` 接受一个路径数组，告诉 Rails 自动加载常量后不在每次请求中都清空。如果 `config.cache_classes` 的值为 `false`（开发环境的默认值），这个选项有影响。否则，都只自动加载一次。这个数组的全部元素都要在 `autoload_paths` 中。默认值为一个空数组。
*   `config.autoload_paths` 接受一个路径数组，让 Rails 自动加载里面的常量。默认值是 `app` 目录中的全部子目录。
*   `config.cache_classes` 控制每次请求是否重新加载应用的类和模块。在开发环境中默认为 `false`，在测试和生产环境中默认为 `true`。
*   `config.action_view.cache_template_loading` 控制每次请求是否重新加载模板。默认值为 `config.cache_classes` 的值。
*   `config.beginning_of_week` 设定一周从周几开始。可接受的值是有效的周几符号（如 `:monday`）。
*   `config.cache_store` 配置 Rails 缓存使用哪个存储器。可用的选项有：`:memory_store`、`:file_store`、`:mem_cache_store`、`:null_store`，或者实现了缓存 API 的对象。默认值为 `:file_store`。
*   `config.colorize_logging` 指定在日志中记录信息时是否使用 ANSI 颜色代码。默认值为 `true`。
*   `config.consider_all_requests_local` 是一个旗标。如果设为 `true`，发生任何错误都会把详细的调试信息转储到 HTTP 响应中，而且 `Rails::Info` 控制器会在 `/rails/info/properties` 中显示应用的运行时上下文。开发和测试环境中默认为 `true`，生产环境默认为 `false`。如果想精细控制，把这个选项设为 `false`，然后在控制器中实现 `local_request?` 方法，指定哪些请求应该在出错时显示调试信息。
*   `config.console` 设定 `rails console` 命令所用的控制台类。最好在 `console` 块中运行：

    ```ruby
    console do
      # 这个块只在运行控制台时运行
      # 因此可以安全引入 pry
      require "pry"
      config.console = Pry
    end
    ```


*   `config.eager_load` 设为 `true` 时，及早加载注册的全部 `config.eager_load_namespaces`。包括应用、引擎、Rails 框架和注册的其他命名空间。
*   `config.eager_load_namespaces` 注册命名空间，当 `config.eager_load` 为 `true` 时及早加载。这里列出的所有命名空间都必须响应 `eager_load!` 方法。
*   `config.eager_load_paths` 接受一个路径数组，如果启用类缓存，启动 Rails 时会及早加载。默认值为 `app` 目录中的全部子目录。
*   `config.enable_dependency_loading` 设为 `true` 时，即便应用及早加载了，而且把 `config.cache_classes` 设为 `true`，也自动加载。默认值为 `false`。
*   `config.encoding` 设定应用全局编码。默认为 UTF-8。
*   `config.exceptions_app` 设定出现异常时 ShowException 中间件调用的异常应用。默认为 `ActionDispatch::PublicExceptions.new(Rails.public_path)`。
*   `config.debug_exception_response_format` 设定开发环境中出错时响应的格式。只提供 API 的应用默认值为 `:api`，常规应用的默认值为 `:default`。
*   `config.file_watcher` 指定一个类，当 `config.reload_classes_only_on_change` 设为 `true` 时用于检测文件系统中文件的变动。Rails 提供了 `ActiveSupport::FileUpdateChecker`（默认）和 `ActiveSupport::EventedFileUpdateChecker`（依赖 [listen](https://github.com/guard/listen) gem）。自定义的类必须符合 `ActiveSupport::FileUpdateChecker` API。
*   `config.filter_parameters` 用于过滤不想记录到日志中的参数，例如密码或信用卡卡号。默认，Rails 把 `Rails.application.config.filter_parameters += [:password]` 添加到 `config/initializers/filter_parameter_logging.rb` 文件中，过滤密码。过滤的参数部分匹配正则表达式。
*   `config.force_ssl` 强制所有请求经由 `ActionDispatch::SSL` 中间件处理，即通过 HTTPS 伺服，而且把 `config.action_mailer.default_url_options` 设为 `{ protocol: 'https' }`。SSL 通过设定 `config.ssl_options` 选项配置，详情参见 [`ActionDispatch::SSL` 的文档](http://api.rubyonrails.org/classes/ActionDispatch/SSL.html)。
*   `config.log_formatter` 定义 Rails 日志记录器的格式化程序。这个选项的默认值在所有环境中都是 `ActiveSupport::Logger::SimpleFormatter` 的实例。如果为 `config.logger` 设定了值，必须在包装到 `ActiveSupport::TaggedLogging` 实例中之前手动把格式化程序的值传给日志记录器，Rails 不会为你代劳。
*   `config.log_level` 定义 Rails 日志记录器的详细程度。在所有环境中，这个选项的默认值都是 `:debug`。可用的日志等级有 `:debug`、`:info`、`:warn`、`:error`、`:fatal` 和 `:unknown`。
*   `config.log_tags` 的值可以是一组 `request` 对象响应的方法，可以是一个接受 `request` 对象的 `Proc`，也可以是能响应 `to_s` 方法的对象。这样便于为包含调试信息的日志行添加标签，例如二级域名和请求 ID——二者对调试多用户应用十分有用。
*   `config.logger` 指定 `Rails.logger` 和与 Rails 有关的其他日志（`ActiveRecord::Base.logger`）所用的日志记录器。默认值为 `ActiveSupport::TaggedLogging` 实例，包装 `ActiveSupport::Logger` 实例，把日志存储在 `log/` 目录中。你可以提供自定义的日志记录器，但是为了完全兼容，必须遵照下述指导方针：

    *   为了支持格式化程序，必须手动把 `config.log_formatter` 指定的格式化程序赋值给日志记录器。
    *   为了支持日志标签，日志实例必须使用 `ActiveSupport::TaggedLogging` 包装。
    *   为了支持静默，日志记录器必须引入 `LoggerSilence` 和 `ActiveSupport::LoggerThreadSafeLevel` 模块。`ActiveSupport::Logger` 类已经引入这两个模块。
    
        ```ruby
        class MyLogger < ::Logger
          include ActiveSupport::LoggerThreadSafeLevel
          include LoggerSilence
        end
        
        mylogger           = MyLogger.new(STDOUT)
        mylogger.formatter = config.log_formatter
        config.logger      = ActiveSupport::TaggedLogging.new(mylogger)
        ```
    
    


*   `config.middleware` 用于配置应用的中间件。详情参见 [配置中间件](#configuring-middleware)。
*   `config.reload_classes_only_on_change` 设定仅在跟踪的文件有变化时是否重新加载类。默认跟踪自动加载路径中的一切文件，这个选项的值为 `true`。如果把 `config.cache_classes` 设为 `true`，这个选项将被忽略。
*   `secrets.secret_key_base` 用于指定一个密钥，检查应用的会话，防止篡改。`secrets.secret_key_base` 的值一开始是个随机的字符串，存储在 `config/secrets.yml` 文件中。
*   `config.public_file_server.enabled` 配置 Rails 从 public 目录中伺服静态文件。这个选项的默认值是 `false`，但在生产环境中设为 `false`，因为应该使用运行应用的服务器软件（如 NGINX 或 Apache）伺服静态文件。在生产环境中如果使用 WEBrick 运行或测试应用（不建议在生产环境中使用 WEBrick），把这个选项设为 `true`。否则无法使用页面缓存，也无法请求 public 目录中的文件。
*   `config.session_store` 指定使用哪个类存储会话。可用的值有 `:cookie_store`（默认值）、`:mem_cache_store` 和 `:disabled`。最后一个值告诉 Rails 不处理会话。cookie 存储器中的会话键默认使用应用的名称。也可以指定自定义的会话存储器：

    ```ruby
    config.session_store :my_custom_store
    ```
    
    这个自定义的存储器必须定义为 `ActionDispatch::Session::MyCustomStore`。


*   `config.time_zone` 设定应用的默认时区，并让 Active Record 知道。

<a class="anchor" id="configuring-assets"></a>

### 配置静态资源

*   `config.assets.enabled` 是个旗标，控制是否启用 Asset Pipeline。默认值为 `true`。
*   `config.assets.raise_runtime_errors` 设为 `true` 时启用额外的运行时错误检查。推荐在 `config/environments/development.rb` 中设定，以免部署到生产环境时遇到意料之外的错误。
*   `config.assets.css_compressor` 定义所用的 CSS 压缩程序。默认设为 `sass-rails`。目前唯一的另一个值是 `:yui`，使用 `yui-compressor` gem 压缩。
*   `config.assets.js_compressor` 定义所用的 JavaScript 压缩程序。可用的值有 `:closure`、`:uglifier` 和 `:yui`，分别使用 `closure-compiler`、`uglifier` 和 `yui-compressor` gem。
*   `config.assets.gzip` 是一个旗标，设定在静态资源的常规版本之外是否创建 gzip 版本。默认为 `true`。
*   `config.assets.paths` 包含查找静态资源的路径。在这个配置选项中追加的路径，会在里面寻找静态资源。
*   `config.assets.precompile` 设定运行 `rake assets:precompile` 任务时要预先编译的其他静态资源（除 `application.css` 和 `application.js` 之外）。
*   `config.assets.unknown_asset_fallback` 在使用 sprockets-rails 3.2.0 或以上版本时用于修改 Asset Pipeline 找不到静态资源时的行为。默认为 `true`。
*   `config.assets.prefix` 定义伺服静态资源的前缀。默认为 `/assets`。
*   `config.assets.manifest` 定义静态资源预编译器使用的清单文件的完整路径。默认为 `public` 文件夹中 `config.assets.prefix` 设定的目录中的 `manifest-<random>.json`。
*   `config.assets.digest` 设定是否在静态资源的名称中包含 SHA256 指纹。默认为 `true`。
*   `config.assets.debug` 禁止拼接和压缩静态文件。在 `development.rb` 文件中默认设为 `true`。

`config.assets.version` 是在生成 SHA256 哈希值过程中使用的一个字符串。修改这个值可以强制重新编译所有文件。

*   `config.assets.compile` 是一个旗标，设定在生产环境中是否启用实时 Sprockets  编译。
*   `config.assets.logger` 接受一个符合 Log4r 接口的日志记录器，或者默认的 Ruby `Logger` 类。默认值与 `config.logger` 相同。如果设为 `false`，不记录对静态资源的伺服。
*   `config.assets.quiet` 禁止在日志中记录对静态资源的请求。在 `development.rb` 文件中默认设为 `true`。

<a class="anchor" id="configuring-generators"></a>

### 配置生成器

Rails 允许通过 `config.generators` 方法调整生成器的行为。这个方法接受一个块：

```ruby
config.generators do |g|
  g.orm :active_record
  g.test_framework :test_unit
end
```

在这个块中可以使用的全部方法如下：

*   `assets` 指定在生成脚手架时是否创建静态资源。默认为 `true`。
*   `force_plural` 指定模型名是否允许使用复数。默认为 `false`。
*   `helper` 指定是否生成辅助模块。默认为 `true`。
*   `integration_tool` 指定使用哪个集成工具生成集成测试。默认为 `:test_unit`。
*   `javascripts` 启用生成器中的 JavaScript 文件钩子。在 Rails 中供 `scaffold` 生成器使用。默认为 `true`。
*   `javascript_engine` 配置生成静态资源时使用的脚本引擎（如 coffee）。默认为 `:js`。
*   `orm` 指定使用哪个 ORM。默认为 `false`，即使用 Active Record。
*   `resource_controller` 指定 `rails generate resource` 使用哪个生成器生成控制器。默认为 `:controller`。
*   `resource_route` 指定是否生成资源路由。默认为 `true`。
*   `scaffold_controller` 与 `resource_controller` 不同，它指定 `rails generate scaffold` 使用哪个生成器生成脚手架中的控制器。默认为 `:scaffold_controller`。
*   `stylesheets` 启用生成器中的样式表钩子。在 Rails 中供 `scaffold` 生成器使用，不过也可以供其他生成器使用。默认为 `true`。
*   `stylesheet_engine` 配置生成静态资源时使用的样式表引擎（如 sass）。默认为 `:css`。
*   `scaffold_stylesheet` 生成脚手架中的资源时创建 `scaffold.css`。默认为 `true`。
*   `test_framework` 指定使用哪个测试框架。默认为 `false`，即使用 Minitest。
*   `template_engine` 指定使用哪个模板引擎，例如 ERB 或 Haml。默认为 `:erb`。

<a class="anchor" id="configuring-middleware"></a>

### 配置中间件

每个 Rails 应用都自带一系列中间件，在开发环境中按下述顺序使用：

*   `ActionDispatch::SSL` 强制使用 HTTPS 伺服每个请求。`config.force_ssl` 设为 `true` 时启用。传给这个中间件的选项通过 `config.ssl_options` 配置。
*   `ActionDispatch::Static` 用于伺服静态资源。`config.public_file_server.enabled` 设为 `false` 时禁用。如果静态资源目录的索引文件不是 `index`，使用 `config.public_file_server.index_name` 指定。例如，请求目录时如果想伺服 `main.html`，而不是 `index.html`，把 `config.public_file_server.index_name` 设为 `"main"`。
*   `ActionDispatch::Executor` 以线程安全的方式重新加载代码。`onfig.allow_concurrency` 设为 `false` 时禁用，此时加载 `Rack::Lock`。`Rack::Lock` 把应用包装在 mutex 中，因此一次只能被一个线程调用。
*   `ActiveSupport::Cache::Strategy::LocalCache` 是基本的内存后端缓存。这个缓存对线程不安全，只应该用作单线程的临时内存缓存。
*   `Rack::Runtime` 设定 `X-Runtime` 首部，包含执行请求的时间（单位为秒）。
*   `Rails::Rack::Logger` 通知日志请求开始了。请求完成后，清空相关日志。
*   `ActionDispatch::ShowExceptions` 拯救应用抛出的任何异常，在本地或者把 `config.consider_all_requests_local` 设为 `true` 时渲染精美的异常页面。如果把 `config.action_dispatch.show_exceptions` 设为 `false`，异常总是抛出。
*   `ActionDispatch::RequestId` 在响应中添加 `X-Request-Id` 首部，并且启用 `ActionDispatch::Request#uuid` 方法。
*   `ActionDispatch::RemoteIp` 检查 IP 欺骗攻击，从请求首部中获取有效的 `client_ip`。可通过 `config.action_dispatch.ip_spoofing_check` 和 `config.action_dispatch.trusted_proxies` 配置。
*   `Rack::Sendfile` 截获从文件中伺服内容的响应，将其替换成服务器专属的 `X-Sendfile` 首部。可通过 `config.action_dispatch.x_sendfile_header` 配置。
*   `ActionDispatch::Callbacks` 在伺服请求之前运行准备回调。
*   `ActionDispatch::Cookies` 为请求设定 cookie。
*   `ActionDispatch::Session::CookieStore` 负责把会话存储在 cookie 中。可以把 `config.action_controller.session_store` 改为其他值，换成其他中间件。此外，可以使用 `config.action_controller.session_options` 配置传给这个中间件的选项。
*   `ActionDispatch::Flash` 设定 `flash` 键。仅当为 `config.action_controller.session_store` 设定值时可用。
*   `Rack::MethodOverride` 在设定了 `params[:_method]` 时允许覆盖请求方法。这是支持 PATCH、PUT 和 DELETE HTTP 请求的中间件。
*   `Rack::Head` 把 HEAD 请求转换成 GET 请求，然后以 GET 请求伺服。

除了这些常规中间件之外，还可以使用 `config.middleware.use` 方法添加：

```ruby
config.middleware.use Magical::Unicorns
```

上述代码把 `Magical::Unicorns` 中间件添加到栈的末尾。如果想把中间件添加到另一个中间件的前面，可以使用 `insert_before`：

```ruby
config.middleware.insert_before Rack::Head, Magical::Unicorns
```

也可以使用索引把中间件插入指定的具体位置。例如，若想把 `Magical::Unicorns` 中间件插入栈顶，可以这么做：

```ruby
config.middleware.insert_before 0, Magical::Unicorns
```

此外，还有 `insert_after`。它把中间件添加到另一个中间件的后面：

```ruby
config.middleware.insert_after Rack::Head, Magical::Unicorns
```

中间件也可以完全替换掉：

```ruby
config.middleware.swap ActionController::Failsafe, Lifo::Failsafe
```

还可以从栈中移除：

```ruby
config.middleware.delete Rack::MethodOverride
```

<a class="anchor" id="configuring-i18n"></a>

### 配置 i18n

这些配置选项都委托给 `I18n` 库。

*   `config.i18n.available_locales` 设定应用可用的本地化白名单。默认为在本地化文件中找到的全部本地化键，在新应用中通常只有 `:en`。
*   `config.i18n.default_locale` 设定供 i18n 使用的默认本地化。默认为 `:en`。
*   `config.i18n.enforce_available_locales` 确保传给 i18n 的本地化必须在 `available_locales` 声明的列表中，否则抛出 `I18n::InvalidLocale` 异常。默认为 `true`。除非有特别的原因，否则不建议禁用这个选项，因为这是一项安全措施，能防止用户输入无效的本地化。
*   `config.i18n.load_path` 设定 Rails 寻找本地化文件的路径。默认为 `config/locales/*.{yml,rb}`。
*   `config.i18n.fallbacks` 设定没有翻译时的回落行为。下面是这个选项的单个使用示例：

    *   设为 `true`，回落到默认区域设置：
    
        ```ruby
        config.i18n.fallbacks = true
        ```
    
    
    *   设为一个区域设置数据：
    
        ```ruby
        config.i18n.fallbacks = [:tr, :en]
        ```
    
    
    *   还可以为各个区域设置设定不同的回落语言。例如，如果想把 `:tr` 作为 `:az` 的回落语言，把 `:de` 和 :en` 作为 `:da` 的回落语言，可以这么做：
    
        ```ruby
        config.i18n.fallbacks = { az: :tr, da: [:de, :en] }
        # 或
        config.i18n.fallbacks.map = { az: :tr, da: [:de, :en] }
        ```
    
    
    



<a class="anchor" id="configuring-active-record"></a>

### 配置 Active Record

`config.active_record` 包含众多配置选项：

*   `config.active_record.logger` 接受符合 Log4r 接口的日志记录器，或者默认的 Ruby `Logger` 类，然后传给新的数据库连接。可以在 Active Record 模型类或实例上调用 `logger` 方法获取日志记录器。设为 `nil` 时禁用日志。
*   `config.active_record.primary_key_prefix_type` 用于调整主键列的名称。默认情况下，Rails 假定主键列名为 `id`（无需配置）。此外有两个选择：

    *   设为 `:table_name` 时，`Customer` 类的主键为 `customerid`。
    *   设为 `:table_name_with_underscore` 时，`Customer` 类的主键为 `customer_id`。


*   `config.active_record.table_name_prefix` 设定一个全局字符串，放在表名前面。如果设为 `northwest_`，`Customer` 类对应的表是 `northwest_customers`。默认为空字符串。
*   `config.active_record.table_name_suffix` 设定一个全局字符串，放在表名后面。如果设为 `_northwest`，`Customer` 类对应的表是 `customers_northwest`。默认为空字符串。
*   `config.active_record.schema_migrations_table_name` 设定模式迁移表的名称。
*   `config.active_record.pluralize_table_names` 指定 Rails 在数据库中寻找单数还是复数表名。如果设为 `true`（默认），那么 `Customer` 类使用 `customers` 表。如果设为 `false`，`Customer` 类使用 `customer` 表。
*   `config.active_record.default_timezone` 设定从数据库中检索日期和时间时使用 `Time.local`（设为 `:local` 时）还是 `Time.utc`（设为 `:utc` 时）。默认为 `:utc`。
*   `config.active_record.schema_format` 控制把数据库模式转储到文件中时使用的格式。可用的值有：`:ruby`（默认），与所用的数据库无关；`:sql`，转储 SQL 语句（可能与数据库有关）。
*   `config.active_record.error_on_ignored_order_or_limit` 指定批量查询时如果忽略顺序是否抛出错误。设为 `true` 时抛出错误，设为 `false` 时发出提醒。默认为 `false`。
*   `config.active_record.timestamped_migrations` 控制迁移使用整数还是时间戳编号。默认为 `true`，使用时间戳。如果有多个开发者共同开发同一个应用，建议这么设置。
*   `config.active_record.lock_optimistically` 控制 Active Record 是否使用乐观锁。默认为 `true`。
*   `config.active_record.cache_timestamp_format` 控制缓存键中时间戳的格式。默认为 `:nsec`。
*   `config.active_record.record_timestamps` 是个布尔值选项，控制 `create` 和 `update` 操作是否更新时间戳。默认值为 `true`。
*   `config.active_record.partial_writes` 是个布尔值选项，控制是否使用部分写入（partial write，即更新时是否只设定有变化的属性）。注意，使用部分写入时，还应该使用乐观锁（`config.active_record.lock_optimistically`），因为并发更新可能写入过期的属性。默认值为 `true`。
*   `config.active_record.maintain_test_schema` 是个布尔值选项，控制 Active Record 是否应该在运行测试时让测试数据库的模式与 `db/schema.rb`（或 `db/structure.sql`）保持一致。默认为 `true`。
*   `config.active_record.dump_schema_after_migration` 是个旗标，控制运行迁移后是否转储模式（`db/schema.rb` 或 `db/structure.sql`）。生成 Rails 应用时，`config/environments/production.rb` 文件中把它设为 `false`。如果不设定这个选项，默认为 `true`。
*   `config.active_record.dump_schemas` 控制运行 `db:structure:dump` 任务时转储哪些数据库模式。可用的值有：`:schema_search_path`（默认），转储 `schema_search_path` 列出的全部模式；`:all`，不考虑 `schema_search_path`，始终转储全部模式；以逗号分隔的模式字符串。
*   `config.active_record.belongs_to_required_by_default` 是个布尔值选项，控制没有 `belongs_to` 关联时记录的验证是否失败。
*   `config.active_record.warn_on_records_fetched_greater_than` 为查询结果的数量设定一个提醒阈值。如果查询返回的记录数量超过这一阈值，在日志中记录一个提醒。可用于标识可能导致内存泛用的查询。
*   `config.active_record.index_nested_attribute_errors` 让嵌套的 `has_many` 关联错误显示索引。默认为 `false`。
*   `config.active_record.use_schema_cache_dump` 设为 `true` 时，用户可以从 `db/schema_cache.yml` 文件中获取模式缓存信息，而不用查询数据库。默认为 `true`。

MySQL 适配器添加了一个配置选项：

*   `ActiveRecord::ConnectionAdapters::Mysql2Adapter.emulate_booleans` 控制 Active Record 是否把 `tinyint(1)` 类型的列当做布尔值。默认为 `true`。

模式转储程序添加了一个配置选项：

*   `ActiveRecord::SchemaDumper.ignore_tables` 指定一个表数组，不包含在生成的模式文件中。如果 `config.active_record.schema_format` 的值不是 `:ruby`，这个设置会被忽略。

<a class="anchor" id="configuring-action-controller"></a>

### 配置 Action Controller

`config.action_controller` 包含众多配置选项：

*   `config.action_controller.asset_host` 设定静态资源的主机。不使用应用自身伺服静态资源，而是通过 CDN 伺服时设定。
*   `config.action_controller.perform_caching` 配置应用是否使用 Action Controller 组件提供的缓存功能。默认在开发环境中为 `false`，在生产环境中为 `true`。
*   `config.action_controller.default_static_extension` 配置缓存页面的扩展名。默认为 `.html`。
*   `config.action_controller.include_all_helpers` 配置视图辅助方法在任何地方都可用，还是只在相应的控制器中可用。如果设为 `false`，`UsersHelper` 模块中的方法只在 `UsersController` 的视图中可用。如果设为 `true`，`UsersHelper` 模块中的方法在任何地方都可用。默认的行为（不明确设为 `true` 或 `false`）是视图辅助方法在每个控制器中都可用。
*   `config.action_controller.logger` 接受符合 Log4r 接口的日志记录器，或者默认的 Ruby `Logger` 类，用于记录 Action Controller 的信息。设为 `nil` 时禁用日志。
*   `config.action_controller.request_forgery_protection_token` 设定请求伪造的令牌参数名称。调用 `protect_from_forgery` 默认把它设为 `:authenticity_token`。
*   `config.action_controller.allow_forgery_protection` 启用或禁用 CSRF 防护。在测试环境中默认为 `false`，其他环境默认为 `true`。
*   `config.action_controller.forgery_protection_origin_check` 配置是否检查 HTTP `Origin` 首部与网站的源一致，作为一道额外的 CSRF 防线。
*   `config.action_controller.per_form_csrf_tokens` 控制 CSRF 令牌是否只在生成它的方法（动作）中有效。
*   `config.action_controller.relative_url_root` 用于告诉 Rails 你把应用[部署到子目录中](#deploy-to-a-subdirectory-relative-url-root)。默认值为 `ENV['RAILS_RELATIVE_URL_ROOT']`。
*   `config.action_controller.permit_all_parameters` 设定默认允许批量赋值全部参数。默认值为 `false`。
*   `config.action_controller.action_on_unpermitted_parameters` 设定在发现没有允许的参数时记录日志还是抛出异常。设为 `:log` 或 `:raise` 时启用。开发和测试环境的默认值是 `:log`，其他环境的默认值是 `false`。
*   `config.action_controller.always_permitted_parameters` 设定一组默认允许传入的参数白名单。默认值为 `['controller', 'action']`。
*   `config.action_controller.enable_fragment_cache_logging` 指明是否像下面这样在日志中详细记录片段缓存的读写操作：

    ```
    Read fragment views/v1/2914079/v1/2914079/recordings/70182313-20160225015037000000/d0bdf2974e1ef6d31685c3b392ad0b74 (0.6ms)
    Rendered messages/_message.html.erb in 1.2 ms [cache hit]
    Write fragment views/v1/2914079/v1/2914079/recordings/70182313-20160225015037000000/3b4e249ac9d168c617e32e84b99218b5 (1.1ms)
    Rendered recordings/threads/_thread.html.erb in 1.5 ms [cache miss]
    Rendered messages/_message.html.erb in 1.2 ms [cache hit]
    Rendered recordings/threads/_thread.html.erb in 1.5 ms [cache miss]
    ```



<a class="anchor" id="configuring-action-dispatch"></a>

### 配置 Action Dispatch

*   `config.action_dispatch.session_store` 设定存储会话数据的存储器。默认为 `:cookie_store`；其他有效的值包括 `:active_record_store`、`:mem_cache_store` 或自定义类的名称。
*   `config.action_dispatch.default_headers` 的值是一个散列，设定每个响应默认都有的 HTTP 首部。默认定义的首部有：

    ```ruby
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff'
    }
    ```


*   `config.action_dispatch.default_charset` 指定渲染时使用的默认字符集。默认为 `nil`。
*   `config.action_dispatch.tld_length` 设定应用的 TLD（top-level domain，顶级域名）长度。默认为 `1`。
*   `config.action_dispatch.ignore_accept_header` 设定是否忽略请求中的 Accept 首部。默认为 `false`。
*   `config.action_dispatch.x_sendfile_header` 指定服务器具体使用的 X-Sendfile 首部。通过服务器加速发送文件时用得到。例如，使用 Apache 时设为 'X-Sendfile'。
*   `config.action_dispatch.http_auth_salt` 设定 HTTP Auth 的盐值。默认为 `'http authentication'`。
*   `config.action_dispatch.signed_cookie_salt` 设定签名 cookie 的盐值。默认为 `'signed cookie'`。
*   `config.action_dispatch.encrypted_cookie_salt` 设定加密 cookie 的盐值。默认为 `'encrypted cookie'`。
*   `config.action_dispatch.encrypted_signed_cookie_salt` 设定签名加密 cookie 的盐值。默认为 `'signed encrypted cookie'`。
*   `config.action_dispatch.perform_deep_munge` 配置是否在参数上调用 `deep_munge` 方法。详情参见 [生成不安全的查询](security.html#unsafe-query-generation)。默认为 `true`。
*   `config.action_dispatch.rescue_responses` 设定异常与 HTTP 状态的对应关系。其值为一个散列，指定异常和状态之间的映射。默认的定义如下：

    ```ruby
    config.action_dispatch.rescue_responses = {
      'ActionController::RoutingError'               => :not_found,
      'AbstractController::ActionNotFound'           => :not_found,
      'ActionController::MethodNotAllowed'           => :method_not_allowed,
      'ActionController::UnknownHttpMethod'          => :method_not_allowed,
      'ActionController::NotImplemented'             => :not_implemented,
      'ActionController::UnknownFormat'              => :not_acceptable,
      'ActionController::InvalidAuthenticityToken'   => :unprocessable_entity,
      'ActionController::InvalidCrossOriginRequest'  => :unprocessable_entity,
      'ActionDispatch::Http::Parameters::ParseError' => :bad_request,
      'ActionController::BadRequest'                 => :bad_request,
      'ActionController::ParameterMissing'           => :bad_request,
      'Rack::QueryParser::ParameterTypeError'        => :bad_request,
      'Rack::QueryParser::InvalidParameterError'     => :bad_request,
      'ActiveRecord::RecordNotFound'                 => :not_found,
      'ActiveRecord::StaleObjectError'               => :conflict,
      'ActiveRecord::RecordInvalid'                  => :unprocessable_entity,
      'ActiveRecord::RecordNotSaved'                 => :unprocessable_entity
    }
    ```
    
    没有配置的异常映射为 500 Internal Server Error。


*   `ActionDispatch::Callbacks.before` 接受一个代码块，在请求之前运行。
*   `ActionDispatch::Callbacks.to_prepare` 接受一个块，在 `ActionDispatch::Callbacks.before` 之后、请求之前运行。在开发环境中每个请求都会运行，但在生产环境或 `cache_classes` 设为 `true` 的环境中只运行一次。
*   `ActionDispatch::Callbacks.after` 接受一个代码块，在请求之后运行。

<a class="anchor" id="configuring-action-view"></a>

### 配置 Action View

`config.action_view` 有一些配置选项：

*   `config.action_view.field_error_proc` 提供一个 HTML 生成器，用于显示 Active Model 抛出的错误。默认为：

    ```ruby
    Proc.new do |html_tag, instance|
      %Q(<div class="field_with_errors">#{html_tag}</div>).html_safe
    end
    ```


*   `config.action_view.default_form_builder` 告诉 Rails 默认使用哪个表单构造器。默认为 `ActionView::Helpers::FormBuilder`。如果想在初始化之后加载表单构造器类，把值设为一个字符串。
*   `config.action_view.logger` 接受符合 Log4r 接口的日志记录器，或者默认的 Ruby `Logger` 类，用于记录 Action View 的信息。设为 `nil` 时禁用日志。
*   `config.action_view.erb_trim_mode` 让 ERB 使用修剪模式。默认为 `'-'`，使用 `<%= -%>` 或 `<%= =%>` 时裁掉尾部的空白和换行符。详情参见 [Erubis 的文档](http://www.kuwata-lab.com/erubis/users-guide.06.html#topics-trimspaces)。
*   `config.action_view.embed_authenticity_token_in_remote_forms` 设定具有 `remote: true` 选项的表单中 `authenticity_token` 的默认行为。默认设为 `false`，即远程表单不包含 `authenticity_token`，对表单做片段缓存时可以这么设。远程表单从 `meta` 标签中获取真伪令牌，因此除非要支持没有 JavaScript 的浏览器，否则不应该内嵌在表单中。如果想支持没有 JavaScript 的浏览器，可以在表单选项中设定 `authenticity_token: true`，或者把这个配置设为 `true`。
*   `config.action_view.prefix_partial_path_with_controller_namespace` 设定渲染嵌套在命名空间中的控制器时是否在子目录中寻找局部视图。例如，`Admin::ArticlesController` 渲染这个模板：

    ```erb
    <%= render @article %>
    ```
    
    默认设置是 `true`，使用局部视图 `/admin/articles/_article.erb`。设为 `false` 时，渲染 `/articles/_article.erb`——这与渲染没有放入命名空间中的控制器一样，例如 `ArticlesController`。


*   `config.action_view.raise_on_missing_translations` 设定缺少翻译时是否抛出错误。
*   `config.action_view.automatically_disable_submit_tag` 设定点击提交按钮（`submit_tag`）时是否自动将其禁用。默认为 `true`。
*   `config.action_view.debug_missing_translation` 设定是否把缺少的翻译键放在 `<span>` 标签中。默认为 `true`。
*   `config.action_view.form_with_generates_remote_forms` 指明 `form_with` 是否生成远程表单。默认为 `true`。

<a class="anchor" id="configuring-action-mailer"></a>

### 配置 Action Mailer

`config.action_mailer` 有一些配置选项：

*   `config.action_mailer.logger` 接受符合 Log4r 接口的日志记录器，或者默认的 Ruby `Logger` 类，用于记录 Action Mailer 的信息。设为 `nil` 时禁用日志。
*   `config.action_mailer.smtp_settings` 用于详细配置 `:smtp` 发送方法。值是一个选项散列，包含下述选项：

    *   `:address`：设定远程邮件服务器的地址。默认为 localhost。
    *   `:port`：如果邮件服务器不在 25 端口上（很少发生），可以修改这个选项。
    *   `:domain`：如果需要指定 HELO 域名，通过这个选项设定。
    *   `:user_name`：如果邮件服务器需要验证身份，通过这个选项设定用户名。
    *   `:password`：如果邮件服务器需要验证身份，通过这个选项设定密码。
    *   `:authentication`：如果邮件服务器需要验证身份，要通过这个选项设定验证类型。这个选项的值是一个符号，可以是 `:plain`、`:login` 或 `:cram_md5`。
    *   `:enable_starttls_auto`：检测 SMTP 服务器是否启用了 STARTTLS，如果启用就使用。默认为 `true`。
    *   `:openssl_verify_mode`：使用 TLS 时可以设定 OpenSSL 检查证书的方式。需要验证自签名或通配证书时用得到。值为 `:none` 或 `:peer`，或相应的常量 OpenSSL::SSL::VERIFY_NONE` 或 `OpenSSL::SSL::VERIFY_PEER`。
    *   `:ssl/:tls`：通过 SMTP/TLS 连接 SMTP。


*   `config.action_mailer.sendmail_settings` 用于详细配置 `sendmail` 发送方法。值是一个选项散列，包含下述选项：

    *   `:location`：sendmail 可执行文件的位置。默认为 `/usr/sbin/sendmail`。
    *   `:arguments`：命令行参数。默认为 `-i`。


*   `config.action_mailer.raise_delivery_errors` 指定无法发送电子邮件时是否抛出错误。默认为 `true`。
*   `config.action_mailer.delivery_method` 设定发送方法，默认为 `:smtp`。详情参见 [配置 Action Mailer](action_mailer_basics.html#action-mailer-configuration)。
*   `config.action_mailer.perform_deliveries` 指定是否真的发送邮件，默认为 `true`。测试时建议设为 `false`。
*   `config.action_mailer.default_options` 配置 Action Mailer 的默认值。用于为每封邮件设定 `from` 或 `reply_to` 等选项。设定的默认值为：

    ```ruby
    mime_version:  "1.0",
    charset:       "UTF-8",
    content_type: "text/plain",
    parts_order:  ["text/plain", "text/enriched", "text/html"]
    ```
    
    若想设定额外的选项，使用一个散列：
    
    ```ruby
    config.action_mailer.default_options = {
      from: "noreply@example.com"
    }
    ```


*   `config.action_mailer.observers` 注册观测器（observer），发送邮件时收到通知。

    ```ruby
    config.action_mailer.observers = ["MailObserver"]
    ```


*   `config.action_mailer.interceptors` 注册侦听器（interceptor），在发送邮件前调用。

    ```ruby
    config.action_mailer.interceptors = ["MailInterceptor"]
    ```


*   `config.action_mailer.preview_path` 指定邮件程序预览的位置。

    ```ruby
    config.action_mailer.preview_path = "#{Rails.root}/lib/mailer_previews"
    ```


*   `config.action_mailer.show_previews` 启用或禁用邮件程序预览。开发环境默认为 `true`。

    ```ruby
    config.action_mailer.show_previews = false
    ```


*   `config.action_mailer.deliver_later_queue_name` 设定邮件程序的队列名称。默认为 `mailers`。
*   `config.action_mailer.perform_caching` 指定是否片段缓存邮件模板。在所有环境中默认为 `false`。

<a class="anchor" id="configuring-active-support"></a>

### 配置 Active Support

Active Support 有一些配置选项：

*   `config.active_support.bare` 指定在启动 Rails 时是否加载 `active_support/all`。默认为 `nil`，即加载 `active_support/all`。
*   `config.active_support.test_order` 设定执行测试用例的顺序。可用的值是 `:random` 和 `:sorted`。默认为 `:random`。
*   `config.active_support.escape_html_entities_in_json` 指定在 JSON 序列化中是否转义 HTML 实体。默认为 `true`。
*   `config.active_support.use_standard_json_time_format` 指定是否把日期序列化成 ISO 8601 格式。默认为 `true`。
*   `config.active_support.time_precision` 设定 JSON 编码的时间值的精度。默认为 `3`。
*   `ActiveSupport::Logger.silencer` 设为 `false` 时静默块的日志。默认为 `true`。
*   `ActiveSupport::Cache::Store.logger` 指定缓存存储操作使用的日志记录器。
*   `ActiveSupport::Deprecation.behavior` 的作用与 `config.active_support.deprecation` 相同，用于配置 Rails 弃用提醒的行为。
*   `ActiveSupport::Deprecation.silence` 接受一个块，块里的所有弃用提醒都静默。
*   `ActiveSupport::Deprecation.silenced` 设定是否显示弃用提醒。

<a class="anchor" id="configuring-active-job"></a>

### 配置 Active Job

`config.active_job` 提供了下述配置选项：

*   `config.active_job.queue_adapter` 设定队列后端的适配器。默认的适配器是 `:async`。最新的内置适配器参见 [`ActiveJob::QueueAdapters` 的 API 文档](http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html)。

    ```ruby
    # 要把适配器的 gem 写入 Gemfile
    # 请参照适配器的具体安装和部署说明
    config.active_job.queue_adapter = :sidekiq
    ```


*   `config.active_job.default_queue_name` 用于修改默认的队列名称。默认为 `"default"`。

    ```ruby
    config.active_job.default_queue_name = :medium_priority
    ```


*   `config.active_job.queue_name_prefix` 用于为所有作业设定队列名称的前缀（可选）。默认为空，不使用前缀。

    做下述配置后，在生产环境中运行时把指定作业放入 `production_high_priority` 队列中：
    
    ```ruby
    config.active_job.queue_name_prefix = Rails.env
    ```
    
    ```ruby
    class GuestsCleanupJob < ActiveJob::Base
      queue_as :high_priority
      #....
    end
    ```


*   `config.active_job.queue_name_delimiter` 的默认值是 `'_'`。如果设定了 `queue_name_prefix`，使用 `queue_name_delimiter` 连接前缀和队列名。

    下述配置把指定作业放入 `video_server.low_priority` 队列中：
    
    ```ruby
    # 设定了前缀才会使用分隔符
    config.active_job.queue_name_prefix = 'video_server'
    config.active_job.queue_name_delimiter = '.'
    ```
    
    ```ruby
    class EncoderJob < ActiveJob::Base
      queue_as :low_priority
      #....
    end
    ```


*   `config.active_job.logger` 接受符合 Log4r 接口的日志记录器，或者默认的 Ruby `Logger` 类，用于记录 Action Job 的信息。在 Active Job 类或实例上调用 `logger` 方法可以获取日志记录器。设为 `nil` 时禁用日志。

<a class="anchor" id="configuring-action-cable"></a>

### 配置 Action Cable

*   `config.action_cable.url` 的值是一个 URL 字符串，指定 Action Cable 服务器的地址。如果 Action Cable 服务器与主应用的服务器不同，可以使用这个选项。
*   `config.action_cable.mount_path` 的值是一个字符串，指定把 Action Cable 挂载在哪里，作为主服务器进程的一部分。默认为 `/cable`。可以设为 `nil`，不把 Action Cable 挂载为常规 Rails 服务器的一部分。

<a class="anchor" id="configuring-a-database"></a>

### 配置数据库

几乎所有 Rails 应用都要与数据库交互。可以通过环境变量 `ENV['DATABASE_URL']` 或 `config/database.yml` 配置文件中的信息连接数据库。

在 `config/database.yml` 文件中可以指定访问数据库所需的全部信息：

```yml
development:
  adapter: postgresql
  database: blog_development
  pool: 5
```

此时使用 `postgresql` 适配器连接名为 `blog_development` 的数据库。这些信息也可以存储在一个 URL 中，然后通过环境变量提供，如下所示：

```
> puts ENV['DATABASE_URL']
postgresql://localhost/blog_development?pool=5
```

`config/database.yml` 文件分成三部分，分别对应 Rails 默认支持的三个环境：

*   `development` 环境在开发（本地）电脑中使用，手动与应用交互。
*   `test` 环境用于运行自动化测试。
*   `production` 环境在把应用部署到线上时使用。

如果愿意，可以在 `config/database.yml` 文件中指定连接 URL：

```yml
development:
  url: postgresql://localhost/blog_development?pool=5
```

`config/database.yml` 文件中可以包含 ERB 标签 `<%= %>`。这个标签中的内容作为 Ruby 代码执行。可以使用这个标签从环境变量中获取数据，或者执行计算，生成所需的连接信息。

TIP: 无需自己动手更新数据库配置。如果查看应用生成器的选项，你会发现其中一个名为 `--database`。通过这个选项可以从最常使用的关系数据库中选择一个。甚至还可以重复运行这个生成器：`cd .. && rails new blog --database=mysql`。同意重写 `config/database.yml` 文件后，应用的配置会针对 MySQL 更新。常见的数据库连接示例参见下文。


<a class="anchor" id="connection-preference"></a>

### 连接配置的优先级

因为有两种配置连接的方式（使用 `config/database.yml` 文件或者一个环境变量），所以要明白二者之间的关系。

如果 `config/database.yml` 文件为空，而 `ENV['DATABASE_URL']` 有值，那么 Rails 使用环境变量连接数据库：

```sh
$ cat config/database.yml

$ echo $DATABASE_URL
postgresql://localhost/my_database
```

如果在 `config/database.yml` 文件中做了配置，而 `ENV['DATABASE_URL']` 没有值，那么 Rails 使用这个文件中的信息连接数据库：

```sh
$ cat config/database.yml
development:
  adapter: postgresql
  database: my_database
  host: localhost

$ echo $DATABASE_URL
```

如果 `config/database.yml` 文件中做了配置，而且 `ENV['DATABASE_URL']` 有值，Rails 会把二者合并到一起。为了更好地理解，必须看些示例。

如果连接信息有重复，环境变量中的信息优先级高：

```sh
$ cat config/database.yml
development:
  adapter: sqlite3
  database: NOT_my_database
  host: localhost

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ bin/rails runner 'puts ActiveRecord::Base.configurations'
{"development"=>{"adapter"=>"postgresql", "host"=>"localhost", "database"=>"my_database"}}
```

可以看出，适配器、主机和数据库与 `ENV['DATABASE_URL']` 中的信息匹配。

如果信息无重复，都是唯一的，遇到冲突时还是环境变量中的信息优先级高：

```sh
$ cat config/database.yml
development:
  adapter: sqlite3
  pool: 5

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ bin/rails runner 'puts ActiveRecord::Base.configurations'
{"development"=>{"adapter"=>"postgresql", "host"=>"localhost", "database"=>"my_database", "pool"=>5}}
```

`ENV['DATABASE_URL']` 没有提供连接池数量，因此从文件中获取。而两处都有 `adapter`，因此 `ENV['DATABASE_URL']` 中的连接信息胜出。

如果不想使用 `ENV['DATABASE_URL']` 中的连接信息，唯一的方法是使用 `"url"` 子键指定一个 URL：

```sh
$ cat config/database.yml
development:
  url: sqlite3:NOT_my_database

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ bin/rails runner 'puts ActiveRecord::Base.configurations'
{"development"=>{"adapter"=>"sqlite3", "database"=>"NOT_my_database"}}
```

这里，`ENV['DATABASE_URL']` 中的连接信息被忽略了。注意，适配器和数据库名称不同了。

因为在 `config/database.yml` 文件中可以内嵌 ERB，所以最好明确表明使用 `ENV['DATABASE_URL']` 连接数据库。这在生产环境中特别有用，因为不应该把机密信息（如数据库密码）提交到源码控制系统中（如 Git）。

```sh
$ cat config/database.yml
production:
  url: <%= ENV['DATABASE_URL'] %>
```

现在的行为很明确，只使用 `<%= ENV['DATABASE_URL'] %>` 中的连接信息。

<a class="anchor" id="configuring-an-sqlite3-database"></a>

#### 配置 SQLite3 数据库

Rails 内建支持 [SQLite3](http://www.sqlite.org/)，这是一个轻量级无服务器数据库应用。SQLite 可能无法负担生产环境，但是在开发和测试环境中用着很好。新建 Rails 项目时，默认使用 SQLite 数据库，不过之后可以随时更换。

下面是默认配置文件（`config/database.yml`）中开发环境的连接信息：

```yml
development:
  adapter: sqlite3
  database: db/development.sqlite3
  pool: 5
  timeout: 5000
```

NOTE: Rails 默认使用 SQLite3 存储数据，因为它无需配置，立即就能使用。Rails 还原生支持 MySQL（含 MariaDB）和 PostgreSQL，此外还有针对其他多种数据库系统的插件。在生产环境中使用的数据库，基本上都有相应的 Rails 适配器。


<a class="anchor" id="configuring-a-mysql-or-mariadb-database"></a>

#### 配置 MySQL 或 MariaDB 数据库

如果选择使用 MySQL 或 MariaDB，而不是 SQLite3，`config/database.yml` 文件的内容稍有不同。下面是开发环境的连接信息：

```yml
development:
  adapter: mysql2
  encoding: utf8
  database: blog_development
  pool: 5
  username: root
  password:
  socket: /tmp/mysql.sock
```

如果开发数据库使用 root 用户，而且没有密码，这样配置就行了。否则，要相应地修改 `development` 部分的用户名和密码。

<a class="anchor" id="configuring-a-postgresql-database"></a>

#### 配置 PostgreSQL 数据库

如果选择使用 PostgreSQL，`config/database.yml` 文件会针对 PostgreSQL 数据库定制：

```yml
development:
  adapter: postgresql
  encoding: unicode
  database: blog_development
  pool: 5
```

PostgreSQL 默认启用预处理语句（prepared statement）。若想禁用，把 `prepared_statements` 设为 `false`：

```yml
production:
  adapter: postgresql
  prepared_statements: false
```

如果启用，Active Record 默认最多为一个数据库连接创建 1000 个预处理语句。若想修改，可以把 `statement_limit` 设定为其他值：

```yml
production:
  adapter: postgresql
  statement_limit: 200
```

预处理语句的数量越多，数据库消耗的内存越多。如果 PostgreSQL 数据库触及内存上限，尝试降低 `statement_limit` 的值，或者禁用预处理语句。

<a class="anchor" id="configuring-an-sqlite3-database-for-jruby-platform"></a>

#### 为 JRuby 平台配置 SQLite3 数据库

如果选择在 JRuby 中使用 SQLite3，`config/database.yml` 文件的内容稍有不同。下面是 `development` 部分：

```yaml
development:
  adapter: jdbcsqlite3
  database: db/development.sqlite3
```

<a class="anchor" id="configuring-a-mysql-or-mariadb-database-for-jruby-platform"></a>

#### 为 JRuby 平台配置 MySQL 或 MariaDB 数据库

如果选择在 JRuby 中使用 MySQL 或 MariaDB，`config/database.yml` 文件的内容稍有不同。下面是 `development` 部分：

```yml
development:
  adapter: jdbcmysql
  database: blog_development
  username: root
  password:
```

<a class="anchor" id="configuring-a-postgresql-database-for-jruby-platform"></a>

#### 为 JRuby 平台配置 PostgreSQL 数据库

如果选择在 JRuby 中使用 PostgreSQL，`config/database.yml` 文件的内容稍有不同。下面是 `development` 部分：

```yml
development:
  adapter: jdbcpostgresql
  encoding: unicode
  database: blog_development
  username: blog
  password:
```

请根据需要修改 `development` 部分的用户名和密码。

<a class="anchor" id="creating-rails-environments"></a>

### 创建 Rails 环境

Rails 默认提供三个环境：开发环境、测试环境和生产环境。多数情况下，这就够用了，但有时可能需要更多环境。

比如说想要一个服务器，镜像生产环境，但是只用于测试。这样的服务器通常称为“交付准备服务器”。如果想为这个服务器创建名为“staging”的环境，只需创建 `config/environments/staging.rb` 文件。请参照 `config/environments` 目录中的现有文件，根据需要修改。

自己创建的环境与默认的没有区别，启动服务器使用 `rails server -e staging`，启动控制台使用 `rails console staging`，`Rails.env.staging?` 也能正常使用，等等。

<a class="anchor" id="deploy-to-a-subdirectory-relative-url-root"></a>

### 部署到子目录（URL 相对于根路径）

默认情况下，Rails 预期应用在根路径（即 `/`）上运行。本节说明如何在目录中运行应用。

假设我们想把应用部署到“/app1”。Rails 要知道这个目录，这样才能生成相应的路由：

```ruby
config.relative_url_root = "/app1"
```

此外，也可以设定 `RAILS_RELATIVE_URL_ROOT` 环境变量。

现在生成链接时，Rails 会在前面加上“/app1”。

<a class="anchor" id="using-passenger"></a>

#### 使用 Passenger

使用 Passenger 在子目录中运行应用很简单。相关配置参阅 [Passenger 手册](https://www.phusionpassenger.com/library/deploy/apache/deploy/ruby/#deploying-an-app-to-a-sub-uri-or-subdirectory)。

<a class="anchor" id="using-a-reverse-proxy"></a>

#### 使用反向代理

使用反向代理部署应用比传统方式有明显的优势：对服务器有更好的控制，因为应用所需的组件可以分层。

有很多现代的 Web 服务器可以用作代理服务器，用来均衡第三方服务器，如缓存服务器或应用服务器。

[Unicorn](http://unicorn.bogomips.org/) 就是这样的应用服务器，在反向代理后面运行。

此时，要配置代理服务器（NGINX、Apache，等等），让它接收来自应用服务器（Unicorn）的连接。Unicorn 默认监听 8080 端口上的 TCP 连接，不过可以更换端口，或者换用套接字。

详情参阅 [Unicorn 的自述文件](http://unicorn.bogomips.org/README.html)，还可以了解[背后的哲学](http://unicorn.bogomips.org/PHILOSOPHY.html)。

配置好应用服务器之后，还要相应配置 Web 服务器，把请求代理过去。例如，NGINX 的配置可能包含：

```nginx
upstream application_server {
  server 0.0.0.0:8080
}

server {
  listen 80;
  server_name localhost;

  root /root/path/to/your_app/public;

  try_files $uri/index.html $uri.html @app;

  location @app {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_pass http://application_server;
  }

  # 其他配置
}
```

最新的信息参阅 [NGINX 的文档](http://nginx.org/en/docs/)。

<a class="anchor" id="rails-environment-settings"></a>

## Rails 环境设置

Rails 的某些部分还可以通过环境变量在外部配置。Rails 能识别下述几个环境变量：

*   `ENV["RAILS_ENV"]` 定义在哪个环境（生产环境、开发环境、测试环境，等等）中运行 Rails。
*   `ENV["RAILS_RELATIVE_URL_ROOT"]` 在[部署到子目录](#deploy-to-a-subdirectory-relative-url-root)中时供路由代码识别 URL。
*   `ENV["RAILS_CACHE_ID"]` 和 `ENV["RAILS_APP_VERSION"]` 供 Rails 的缓存代码生成扩张的缓存键。这样可以在同一个应用中使用多个单独的缓存。

<a class="anchor" id="using-initializer-files"></a>

## 使用初始化脚本文件

加载完框架和应用依赖的 gem 之后，Rails 开始加载初始化脚本。初始化脚本是 Ruby 文件，存储在应用的 `config/initializers` 目录中。可以在初始化脚本中存放应该于加载完框架和 gem 之后设定的配置，例如配置各部分的设置项目的选项。

NOTE: 如果愿意，可以使用子文件夹组织初始化脚本，Rails 会自上而下查找整个文件夹层次结构。


TIP: 如果初始化脚本有顺序要求，可以通过名称控制加载顺序。初始化脚本文件按照路径的字母表顺序加载。例如，`01_critical.rb` 在 `02_normal.rb` 前面加载。


<a class="anchor" id="initialization-events"></a>

## 初始化事件

Rails 有 5 个初始化事件（按运行顺序列出）：

*   `before_configuration`：在应用常量继承 `Rails::Application` 时立即运行。`config` 调用在此之前执行。
*   `before_initialize`：直接在应用初始化过程之前运行，与 Rails 初始化过程靠近开头的 `:bootstrap_hook` 初始化脚本一起运行。
*   `to_prepare`：在所有 Railtie（包括应用自身）的初始化脚本运行结束之后、及早加载和构架中间件栈之前运行。更重要的是，在开发环境中每次请求都运行，而在生产和测试环境只运行一次（在启动过程中）。
*   `before_eager_load`：在及早加载之前直接运行。这是生产环境的默认行为，开发环境则不然。
*   `after_initialize`：在应用初始化之后、`config/initializers` 中的初始化脚本都运行完毕后直接运行。

若想为这些钩子定义事件，在 `Rails::Application`、`Rails::Railtie` 或 `Rails::Engine` 子类中使用块句法：

```ruby
module YourApp
  class Application < Rails::Application
    config.before_initialize do
      # 在这编写初始化代码
    end
  end
end
```

此外，还可以通过 `Rails.application` 对象的 `config` 方法定义：

```ruby
Rails.application.config.before_initialize do
  # 在这编写初始化代码
end
```

WARNING: 调用 `after_initialize` 块时，应用的某些部分，尤其是路由，尚不可用。


<a class="anchor" id="rails-railtie-initializer"></a>

### `Rails::Railtie#initializer`

有几个在启动时运行的 Rails 初始化脚本使用 `Rails::Railtie` 对象的 `initializer` 方法定义。下面以 Action Controller 中的 `set_helpers_path` 初始化脚本为例：

```ruby
initializer "action_controller.set_helpers_path" do |app|
  ActionController::Helpers.helpers_path = app.helpers_paths
end
```

`initializer` 方法接受三个参数，第一个是初始化脚本的名称，第二个是选项散列（上例中没有），第三个是一个块。选项散列的 `:before` 键指定在哪个初始化脚本之前运行，`:after` 键指定在哪个初始化脚本之后运行。

`initializer` 方法定义的初始化脚本按照定义的顺序运行，除非指定了 `:before` 或 `:after` 键。

WARNING: 只要符合逻辑，可以设定一个初始化脚本在另一个之前或之后运行。假如有四个初始化脚本，名称分别为“one”到“four”（按照这个顺序定义）。如果定义“four”在“four”之前、“three”之后运行就不合逻辑，Rails 无法确定初始化脚本的执行顺序。


`initializer` 方法的块参数是应用自身的实例，因此可以像示例中那样使用 `config` 方法访问配置。

因为 `Rails::Application`（间接）继承自 `Rails::Railtie`，所以可以在 `config/application.rb` 文件中使用 `initializer` 方法为应用定义初始化脚本。

<a class="anchor" id="initializers"></a>

### 初始化脚本

下面按定义顺序（因此以此顺序运行，除非另行说明）列出 Rails 中的全部初始化脚本：

*   `load_environment_hook`：一个占位符，让 `:load_environment_config` 在此之前运行。
*   `load_active_support`：引入 `active_support/dependencies`，设置 Active Support 的基本功能。如果 `config.active_support.bare` 为假值（默认），引入 `active_support/all`。
*   `initialize_logger`：初始化应用的日志记录器（一个 `ActiveSupport::Logger` 对象），可通过 `Rails.logger` 访问。假定在此之前的初始化脚本没有定义 `Rails.logger`。
*   `initialize_cache`：如果没有设置 `Rails.cache`，使用 `config.cache_store` 的值初始化缓存，把结果存储为 `Rails.cache`。如果这个对象响应 `middleware` 方法，它的中间件插入 `Rack::Runtime` 之前。
*   `set_clear_dependencies_hook`：这个初始化脚本（仅当 `cache_classes` 设为 `false` 时运行）使用 `ActionDispatch::Callbacks.after` 从对象空间中删除请求过程中引用的常量，以便在后续请求中重新加载。
*   `initialize_dependency_mechanism`：如果 `config.cache_classes` 为真，配置 `ActiveSupport::Dependencies.mechanism` 使用 `require` 引入依赖，而不使用 `load`。
*   `bootstrap_hook`：运行配置的全部 `before_initialize` 块。
*   `i18n.callbacks`：在开发环境中设置一个 `to_prepare` 回调，如果自上次请求后本地化有变，调用 `I18n.reload!`。在生产环境，这个回调只在第一次请求时运行。
*   `active_support.deprecation_behavior`：设定各个环境报告弃用的方式，在开发环境中默认为 `:log`，在生产环境中默认为 `:notify`，在测试环境中默认为 `:stderr`。如果没为 `config.active_support.deprecation` 设定一个值，这个初始化脚本提示用户在当前环境的配置文件（`config/environments` 目录里）中设定。可以设为一个数组。
*   `active_support.initialize_time_zone`：根据 `config.time_zone` 设置为应用设定默认的时区。默认为“UTC”。
*   `active_support.initialize_beginning_of_week`：根据 `config.beginning_of_week` 设置为应用设定一周从哪一天开始。默认为 `:monday`。
*   `active_support.set_configs`：使用 `config.active_support` 设置 Active Support，把方法名作为设值方法发给 `ActiveSupport`，并传入选项的值。
*   `action_dispatch.configure`：配置 `ActionDispatch::Http::URL.tld_length`，设为 `config.action_dispatch.tld_length` 的值。
*   `action_view.set_configs`：使用 `config.action_view` 设置 Action View，把方法名作为设值方法发给 `ActionView::Base`，并传入选项的值。
*   `action_controller.assets_config`：如果没有明确配置，把 `config.actions_controller.assets_dir` 设为应用的 `public` 目录。
*   `action_controller.set_helpers_path`：把 Action Controller 的 `helpers_path` 设为应用的 `helpers_path`。
*   `action_controller.parameters_config`：为 `ActionController::Parameters` 配置健壮参数选项。
*   `action_controller.set_configs`：使用 `config.action_controller` 设置 Action Controller，把方法名作为设值方法发给 `ActionController::Base`，并传入选项的值。
*   `action_controller.compile_config_methods`：初始化指定的配置选项，得到方法，以便快速访问。
*   `active_record.initialize_timezone`：把 `ActiveRecord::Base.time_zone_aware_attributes` 设为 `true`，并把 `ActiveRecord::Base.default_timezone` 设为 UTC。从数据库中读取属性时，转换成 `Time.zone` 指定的时区。
*   `active_record.logger`：把 `ActiveRecord::Base.logger` 设为 `Rails.logger`（如果还未设定）。
*   `active_record.migration_error`：配置中间件，检查待运行的迁移。
*   `active_record.check_schema_cache_dump`：如果配置了，而且有缓存，加载模式缓存转储。
*   `active_record.warn_on_records_fetched_greater_than`：查询返回大量记录时启用提醒。
*   `active_record.set_configs`：使用 `config.active_record` 设置 Active Record，把方法名作为设值方法发给 `ActiveRecord::Base`，并传入选项的值。
*   `active_record.initialize_database`：从 `config/database.yml` 中加载数据库配置，并在当前环境中连接数据库。
*   `active_record.log_runtime`：引入 `ActiveRecord::Railties::ControllerRuntime`，把 Active Record 调用的耗时记录到日志中。
*   `active_record.set_reloader_hooks`：如果 `config.cache_classes` 设为 `false`，还原所有可重新加载的数据库连接。
*   `active_record.add_watchable_files`：把 `schema.rb` 和 `structure.sql` 添加到可监视的文件列表中。
*   `active_job.logger`：把 `ActiveJob::Base.logger` 设为 `Rails.logger`（如果还未设定）。
*   `active_job.set_configs`：使用 `config.active_job` 设置 Active Job，把方法名作为设值方法发给 `ActiveJob::Base`，并传入选项的值。
*   `action_mailer.logger`：把 `ActionMailer::Base.logger` 设为 `Rails.logger`（如果还未设定）。
*   `action_mailer.set_configs`：使用 `config.action_mailer` 设定 Action Mailer，把方法名作为设值方法发给 `ActionMailer::Base`，并传入选项的值。
*   `action_mailer.compile_config_methods`：初始化指定的配置选项，得到方法，以便快速访问。
*   `set_load_path`：在 `bootstrap_hook` 之前运行。把 `config.load_paths` 指定的路径和所有自动加载路径添加到 `$LOAD_PATH` 中。
*   `set_autoload_paths`：在 `bootstrap_hook` 之前运行。把 `app` 目录中的所有子目录，以及 `config.autoload_paths`、`config.eager_load_paths` 和 `config.autoload_once_paths` 指定的路径添加到 `ActiveSupport::Dependencies.autoload_paths` 中。
*   `add_routing_paths`：加载所有的 `config/routes.rb` 文件（应用和 Railtie 中的，包括引擎），然后设置应用的路由。
*   `add_locales`：把（应用、Railtie 和引擎的）`config/locales` 目录中的文件添加到 `I18n.load_path` 中，让那些文件中的翻译可用。
*   `add_view_paths`：把应用、Railtie 和引擎的 `app/views` 目录添加到应用查找视图文件的路径中。
*   `load_environment_config`：加载 `config/environments` 目录中针对当前环境的配置文件。
*   `prepend_helpers_path`：把应用、Railtie 和引擎中的 `app/helpers` 目录添加到应用查找辅助方法的路径中。
*   `load_config_initializers`：加载应用、Railtie 和引擎中 `config/initializers` 目录里的全部 Ruby 文件。这个目录中的文件可用于存放应该在加载完全部框架之后设定的设置。
*   `engines_blank_point`：在初始化过程中提供一个点，以便在加载引擎之前做些事情。在这一点之后，运行所有 Railtie 和引擎初始化脚本。
*   `add_generator_templates`：寻找应用、Railtie 和引擎中 `lib/templates` 目录里的生成器模板，把它们添加到 `config.generators.templates` 设置中，供所有生成器引用。
*   `ensure_autoload_once_paths_as_subset`：确保 `config.autoload_once_paths` 只包含 `config.autoload_paths` 中的路径。如果有额外路径，抛出异常。
*   `add_to_prepare_blocks`：把应用、Railtie 或引擎中的每个 `config.to_prepare` 调用都添加到 Action Dispatch 的 `to_prepare` 回调中。这些回调在开发环境中每次请求都运行，在生产环境中只在第一次请求之前运行。
*   `add_builtin_route`：如果应用在开发环境中运行，把针对 `rails/info/properties` 的路由添加到应用的路由中。这个路由在 Rails 应用的 `public/index.html` 文件中提供一些详细信息，例如 Rails 和 Ruby 的版本。
*   `build_middleware_stack`：为应用构建中间件栈，返回一个对象，它有一个 `call` 方法，参数是请求的 Rack 环境对象。
*   `eager_load!`：如果 `config.eager_load` 为 `true`，运行 `config.before_eager_load` 钩子，然后调用 `eager_load!`，加载全部 `config.eager_load_namespaces`。
*   `finisher_hook`：在应用初始化过程结束的位置提供一个钩子，并且运行应用、Railtie 和引擎的所有 `config.after_initialize` 块。
*   `set_routes_reloader_hook`：让 Action Dispatch 使用 `ActionDispatch::Callbacks.to_prepare` 重新加载路由文件。
*   `disable_dependency_loading`：如果 `config.eager_load` 为 `true`，禁止自动加载依赖。

<a class="anchor" id="database-pooling"></a>

## 数据库池

Active Record 数据库连接由 `ActiveRecord::ConnectionAdapters::ConnectionPool` 管理，确保连接池的线程访问量与有限个数据库连接数同步。这一限制默认为 5，可以在 `database.yml` 文件中配置。

```yml
development:
  adapter: sqlite3
  database: db/development.sqlite3
  pool: 5
  timeout: 5000
```

连接池默认在 Active Record 内部处理，因此所有应用服务器（Thin、Puma、Unicorn，等等）的行为应该一致。数据库连接池一开始是空的，随着连接数的增加，会不断创建，直至连接池上限。

每个请求在首次访问数据库时会检出连接，请求结束再检入连接。这样，空出的连接位置就可以提供给队列中的下一个请求使用。

如果连接数超过可用值，Active Record 会阻塞，等待池中有空闲的连接。如果无法获得连接，会抛出类似下面的超时错误。

```
ActiveRecord::ConnectionTimeoutError - could not obtain a database connection within 5.000 seconds (waited 5.000 seconds)
```

如果出现上述错误，可以考虑增加连接池的数量，即在 `database.yml` 文件中增加 `pool` 选项的值。

NOTE: 如果是多线程环境，有可能多个线程同时访问多个连接。因此，如果请求量很大，极有可能发生多个线程争夺有限个连接的情况。


<a class="anchor" id="custom-configuration"></a>

## 自定义配置

我们可以通过 Rails 配置对象为自己的代码设定配置。如下所示：

```ruby
config.payment_processing.schedule = :daily
config.payment_processing.retries  = 3
config.super_debugger = true
```

这些配置选项可通过配置对象访问：

```ruby
Rails.configuration.payment_processing.schedule # => :daily
Rails.configuration.payment_processing.retries  # => 3
Rails.configuration.super_debugger              # => true
Rails.configuration.super_debugger.not_set      # => nil
```

还可以使用 `Rails::Application.config_for` 加载整个配置文件：

```yml
# config/payment.yml:
production:
  environment: production
  merchant_id: production_merchant_id
  public_key:  production_public_key
  private_key: production_private_key
development:
  environment: sandbox
  merchant_id: development_merchant_id
  public_key:  development_public_key
  private_key: development_private_key
```

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    config.payment = config_for(:payment)
  end
end
```

```ruby
Rails.configuration.payment['merchant_id'] # => production_merchant_id or development_merchant_id
```

<a class="anchor" id="search-engines-indexing"></a>

## 搜索引擎索引

有时，你可能不想让应用中的某些页面出现在搜索网站中，如 Google、Bing、Yahoo 或 Duck Duck Go。索引网站的机器人首先分析 `http://your-site.com/robots.txt` 文件，了解允许它索引哪些页面。

Rails 为你创建了这个文件，在 `/public` 文件夹中。默认情况下，允许搜索引擎索引应用的所有页面。如果不想索引应用的任何页面，使用下述内容：

```
User-agent: *
Disallow: /
```

若想禁止索引指定的页面，需要使用更复杂的句法。详情参见[官方文档](http://www.robotstxt.org/robotstxt.html)。

<a class="anchor" id="evented-file-system-monitor"></a>

## 事件型文件系统监控程序

如果加载了 listen gem，而且 `config.cache_classes` 为 `false`，Rails 使用一个事件型文件系统监控程序监测变化：

```ruby
group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
end
```

否则，每次请求 Rails 都会遍历应用树，检查有没有变化。

在 Linux 和 macOS 中无需额外的 gem，[*BSD](https://github.com/guard/listen#on-bsd) 和 [Windows](https://github.com/guard/listen#on-windows) 可能需要。

注意，[某些设置不支持](https://github.com/guard/listen#issues--limitations)。
