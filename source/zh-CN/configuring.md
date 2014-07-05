---
layout: docs
title: 设置 Rails 程序
prev_section: debugging_rails_applications
next_section: command_line
---

本文介绍 Rails 程序的设置和初始化。读完本文后，你将学到：

* 如何调整 Rails 程序的表现；
* 如何在程序启动时运行其他代码；

---

## 初始化代码的存放位置 {#locations-for-initialization-code}

Rails 的初始化代码存放在四个标准位置：

* `config/application.rb` 文件
* 针对特定环境的设置文件；
* 初始化脚本；
* 后置初始化脚本；

## 加载 Rails 前运行代码 {#running-code-before-rails}

如果想在加载 Rails 之前运行代码，可以把代码添加到 `config/application.rb` 文件的 `require 'rails/all'` 之前。

## 设置 Rails 组件 {#configuring-rails-components}

总的来说，设置 Rails 的工作包括设置 Rails 的组件以及 Rails 本身。在设置文件 `config/application.rb` 和针对特定环境的设置文件（例如 `config/environments/production.rb`）中可以指定传给各个组件的不同设置项目。

例如，在文件 `config/application.rb` 中有下面这个设置：

{:lang="ruby"}
~~~
config.autoload_paths += %W(#{config.root}/extras)
~~~

这是针对 Rails 本身的设置项目。如果想设置单独的 Rails 组件，一样可以在 `config/application.rb` 文件中使用同一个 `config` 对象：

{:lang="ruby"}
~~~
config.active_record.schema_format = :ruby
~~~

Rails 会使用指定的设置配置 Active Record。

### 常规选项 {#rails-general-configuration}

下面这些设置方法在 `Rails::Railtie` 对象上调用，例如 `Rails::Engine` 或 `Rails::Application` 的子类。

*   `config.after_initialize`：接受一个代码块，在 Rails 初始化程序之后执行。初始化的过程包括框架本身，引擎，以及 `config/initializers` 文件夹中所有的初始化脚本。注意，Rake 任务也会执行代码块中的代码。常用于设置初始化脚本用到的值。

    {:lang="ruby"}
    ~~~
    config.after_initialize do
      ActionView::Base.sanitized_allowed_tags.delete 'div'
    end
    ~~~

*   `config.asset_host`：设置静态资源的主机。可用于设置静态资源所用的 CDN，或者通过不同的域名绕过浏览器对并发请求数量的限制。是 `config.action_controller.asset_host` 的简化。

*   `config.autoload_once_paths`：一个由路径组成的数组，Rails 从这些路径中自动加载常量，且在多次请求之间一直可用。只有 `config.cache_classes` 为 `false`（开发环境中的默认值）时才有效。如果为 `true`，所有自动加载的代码每次请求时都会重新加载。这个数组中的路径必须出现在 `autoload_paths` 设置中。默认为空数组。

*   `config.autoload_paths`：一个由路径组成的数组，Rails 从这些路径中自动加载常量。默认值为 `app` 文件夹中的所有子文件夹。

*   `config.cache_classes`：决定程序中的类和模块在每次请求中是否要重新加载。在开发环境中的默认值是 `false`，在测试环境和生产环境中的默认值是 `true`。调用 `threadsafe!` 方法的作用和设为 `true` 一样。

*   `config.action_view.cache_template_loading`：决定模板是否要在每次请求时重新加载。默认值等于 `config.cache_classes` 的值。

*   `config.beginning_of_week`：设置一周从哪天开始。可使用的值是一周七天名称的符号形式，例如 `:monday`。

*   `config.cache_store`：设置 Rails 缓存的存储方式。可选值有：`:memory_store`，`:file_store`，`:mem_cache_store`，`:null_store`，以及实现了缓存 API 的对象。如果文件夹 `tmp/cache` 存在，默认值为 `:file_store`，否则为 `:memory_store`。

*   `config.colorize_logging`：设定日志信息是否使用 ANSI 颜色代码。默认值为 `true`。

*   `config.consider_all_requests_local`：如果设为 `true`，在 HTTP 响应中会显示详细的调试信息，而且 `Rails::Info` 控制器会在地址 `/rails/info/properties` 上显示程序的运行时上下文。在开发环境和测试环境中默认值为 `true`，在生产环境中默认值为 `false`。要想更精确的控制，可以把这个选项设为 `false`，然后在控制器中实现 `local_request?` 方法，指定哪些请求要显示调试信息。

*   `config.console`：设置执行 `rails console` 命令时使用哪个类实现控制台，最好在 `console` 代码块中设置：

    {:lang="ruby"}
    ~~~
    console do
      # this block is called only when running console,
      # so we can safely require pry here
      require "pry"
      config.console = Pry
    end
    ~~~

*   `config.dependency_loading`：设为 `false` 时禁止自动加载常量。只有 `config.cache_classes` 为 `true`（生产环境的默认值）时才有效。`config.threadsafe!` 为 `true` 时，这个选项为 `false`。

*   `config.eager_load`：设为 `true` 是按需加载 `config.eager_load_namespaces` 中的所有命名空间，包括程序本身、引擎、Rails 框架和其他注册的命名空间。

*   `config.eager_load_namespaces`：注册命名空间，`config.eager_load` 为 `true` 时按需加载。所有命名空间都要能响应 `eager_load!` 方法。

*   `config.eager_load_paths`：一个由路径组成的数组，`config.cache_classes` 为 `true` 时，Rails 启动时按需加载对应的代码。

*   `config.encoding`：设置程序全局编码，默认为 UTF-8。

*   `config.exceptions_app`：设置抛出异常后中间件 ShowException 调用哪个异常处理程序。默认为 `ActionDispatch::PublicExceptions.new(Rails.public_path)`。

*   `config.file_watcher`：设置监视文件系统上文件变化使用的类，`config.reload_classes_only_on_change` 为 `true` 时才有效。指定的类必须符合 `ActiveSupport::FileUpdateChecker` API。

*   `config.filter_parameters`：过滤不想写入日志的参数，例如密码，信用卡卡号。把 `config.filter_parameters+=[:password]` 加入文件 `config/initializers/filter_parameter_logging.rb`，可以过滤密码。

*   `config.force_ssl`：强制所有请求使用 HTTPS 协议，通过 `ActionDispatch::SSL` 中间件实现。

*   `config.log_formatter`：设置 Rails 日志的格式化工具。在生产环境中默认值为 `Logger::Formatter`，其他环境默认值为 `ActiveSupport::Logger::SimpleFormatter`。

*   `config.log_level`：设置 Rails 日志等级。在生产环境中默认值为 `:info`，其他环境默认值为 `:debug`。

*   `config.log_tags`：一组可响应 `request` 对象的方法。可在日志消息中加入更多信息，例如二级域名和请求 ID，便于调试多用户程序。

*   `config.logger`：接受一个实现了 Log4r 接口的类，或者使用默认的 `Logger` 类。默认值为 `ActiveSupport::Logger`，在生产环境中关闭了自动冲刷功能。

*   `config.middleware`：设置程序使用的中间件。详情参阅“[设置中间件](#configuring-middleware)”一节。

*   `config.reload_classes_only_on_change`：只当监视的文件变化时才重新加载。默认值为 `true`，监视 `autoload_paths` 中所有路径。如果 `config.cache_classes` 为 `true`，忽略这个设置。

*   `secrets.secret_key_base`：
指定一个密令，和已知的安全密令比对，防止篡改会话。新建程序时会生成一个随机密令，保存在文件 `config/secrets.yml` 中。

*   `config.serve_static_assets`：让 Rails 伺服静态资源文件。默认值为 `true`，但在生产环境中为 `false`，因为应该使用服务器软件（例如 Nginx 或 Apache）伺服静态资源文件。  如果测试程序，或者在生产环境中使用 WEBrick（极力不推荐），应该设为 `true`，否则无法使用页面缓存，请求 `public` 文件夹中的文件时也会经由 Rails 处理。

*   `config.session_store`：一般在 `config/initializers/session_store.rb` 文件中设置，指定使用什么方式存储会话。可用值有：`:cookie_store`（默认），`:mem_cache_store` 和 `:disabled`。`:disabled` 指明不让 Rails 处理会话。当然也可指定自定义的会话存储：

    {:lang="ruby"}
    ~~~
    config.session_store :my_custom_store
    ~~~

    这个自定义的存储方式必须定义为 `ActionDispatch::Session::MyCustomStore`。

*   `config.time_zone`：设置程序使用的默认时区，也让 Active Record 使用这个时区。

### 设置静态资源 {#configuring-assets}

*   `config.assets.enabled`：设置是否启用 Asset Pipeline。默认启用。

*   `config.assets.raise_runtime_errors`：设为 `true`，启用额外的运行时错误检查。建议在 `config/environments/development.rb` 中设置，这样可以尽量减少部署到生产环境后的异常表现。

*   `config.assets.compress`：是否压缩编译后的静态资源文件。在 `config/environments/production.rb` 中为 `true`。

*   `config.assets.css_compressor`：设定使用的 CSS 压缩程序，默认为 `sass-rails`。目前，唯一可用的另一个值是 `:yui`，使用 `yui-compressor` gem 压缩文件。

*   `config.assets.js_compressor`：设定使用的 JavaScript 压缩程序。可用值有：`:closure`，`:uglifier` 和 `:yui`。分别需要安装 `closure-compiler`，`uglifier` 和 `yui-compressor` 这三个 gem。

*   `config.assets.paths`：查找静态资源文件的路径。Rails 会在这个选项添加的路径中查找静态资源文件。

*   `config.assets.precompile`：指定执行 `rake assets:precompile` 任务时除 `application.css` 和 `application.js` 之外要编译的其他资源文件。

*   `config.assets.prefix`：指定伺服静态资源文件时使用的地址前缀，默认为 `/assets`。

*   `config.assets.digest`：在静态资源文件名中加入 MD5 指纹。在 `production.rb` 中默认设为 `true`。

*   `config.assets.debug`：禁止合并和压缩静态资源文件。在 `development.rb` 中默认设为 `true`。

*   `config.assets.cache_store`：设置 Sprockets 使用的缓存方式，默认使用文件存储。

*   `config.assets.version`：生成 MD5 哈希时用到的一个字符串。可用来强制重新编译所有文件。

*   `config.assets.compile`：布尔值，用于在生产环境中启用 Sprockets 实时编译功能。

*   `config.assets.logger`：接受一个实现了 Log4r 接口的类，或者使用默认的 `Logger` 类。默认值等于 `config.logger` 选项的值。把 `config.assets.logger` 设为 `false`，可以关闭静态资源相关的日志。

### 设置生成器 {#configuring-generators}

Rails 允许使用 `config.generators` 方法设置使用的生成器。这个方法接受一个代码块：

{:lang="ruby"}
~~~
config.generators do |g|
  g.orm :active_record
  g.test_framework :test_unit
end
~~~

在代码块中可用的方法如下所示：

* `assets`：是否允许脚手架创建静态资源文件，默认为 `true`。
* `force_plural`：是否允许使用复数形式的模型名，默认为 `false`。
* `helper`：是否生成帮助方法文件，默认为 `true`。
* `integration_tool`：设置使用哪个集成工具，默认为 `nil`。
* `javascripts`：是否允许脚手架创建 JavaScript 文件，默认为 `true`。
* `javascript_engine`：设置生成静态资源文件时使用的预处理引擎（例如 CoffeeScript），默认为 `nil`。
* `orm`：设置使用哪个 ORM。默认为 `false`，使用 Active Record。
* `resource_controller`：设定执行 `rails generate resource` 命令时使用哪个生成器生成控制器，默认为 `:controller`。
* `scaffold_controller`：和 `resource_controller` 不同，设定执行 `rails generate scaffold` 命令时使用哪个生成器生成控制器，默认为 `:scaffold_controller`。
* `stylesheets`：是否启用生成器中的样式表文件钩子，在执行脚手架时使用，也可用于其他生成器，默认值为 `true`。
* `stylesheet_engine`：设置生成静态资源文件时使用的预处理引擎（例如 Sass），默认为 `:css`。
* `test_framework`：设置使用哪个测试框架，默认为 `false`，使用 Test::Unit。
* `template_engine`：设置使用哪个模板引擎，例如 ERB 或 Haml，默认为 `:erb`。

### 设置中间件 {#configuring-middleware}

每个 Rails 程序都使用了一组标准的中间件，在开发环境中的加载顺序如下：

* `ActionDispatch::SSL`：强制使用 HTTPS 协议处理每个请求。`config.force_ssl` 设为 `true` 时才可用。`config.ssl_options` 选项的值会传给这个中间件。
* `ActionDispatch::Static`：用来伺服静态资源文件。如果 `config.serve_static_assets` 设为 `false`，则不会使用这个中间件。
* `Rack::Lock`：把程序放入互斥锁中，一次只能在一个线程中运行。`config.cache_classes` 设为 `false` 时才会使用这个中间件。
* `ActiveSupport::Cache::Strategy::LocalCache`：使用内存存储缓存。这种存储方式对线程不安全，而且只能在单个线程中做临时存储。
* `Rack::Runtime`：设定 `X-Runtime` 报头，其值为处理请求花费的时间，单位为秒。
* `Rails::Rack::Logger`：开始处理请求时写入日志，请求处理完成后冲刷所有日志。
* `ActionDispatch::ShowExceptions`：捕获程序抛出的异常，如果在本地处理请求，或者 `config.consider_all_requests_local` 设为 `true`，会渲染一个精美的异常页面。如果 `config.action_dispatch.show_exceptions` 设为 `false`，则会直接抛出异常。
* `ActionDispatch::RequestId`：在响应中加入一个唯一的 `X-Request-Id` 报头，并启用 `ActionDispatch::Request#uuid` 方法。
* `ActionDispatch::RemoteIp`：从请求报头中获取正确的 `client_ip`，检测 IP 地址欺骗攻击。通过 `config.action_dispatch.ip_spoofing_check` 和 `config.action_dispatch.trusted_proxies` 设置。
* `Rack::Sendfile`：响应主体为一个文件，并设置 `X-Sendfile` 报头。通过 `config.action_dispatch.x_sendfile_header` 设置。
* `ActionDispatch::Callbacks`：处理请求之前运行指定的回调。
* `ActiveRecord::ConnectionAdapters::ConnectionManagement`：每次请求后都清理可用的连接，除非把在请求环境变量中把 `rack.test` 键设为 `true`。
* `ActiveRecord::QueryCache`：缓存请求中使用的 `SELECT` 查询。如果用到了 `INSERT` 或 `UPDATE` 语句，则清除缓存。
* `ActionDispatch::Cookies`：设置请求的 cookie。
* `ActionDispatch::Session::CookieStore`：把会话存储在 cookie 中。`config.action_controller.session_store` 设为其他值时则使用其他中间件。`config.action_controller.session_options` 的值会传给这个中间件。
* `ActionDispatch::Flash`：设定 `flash` 键。必须为 `config.action_controller.session_store` 设置一个值，才能使用这个中间件。
* `ActionDispatch::ParamsParser`：解析请求中的参数，生成 `params`。
* `Rack::MethodOverride`：如果设置了 `params[:_method]`，则使用相应的方法作为此次请求的方法。这个中间件提供了对 PATCH、PUT 和 DELETE 三个 HTTP 请求方法的支持。
* `ActionDispatch::Head`：把 HEAD 请求转换成 GET 请求，并处理请求。

除了上述标准中间件之外，还可使用 `config.middleware.use` 方法添加其他中间件：

{:lang="ruby"}
~~~
config.middleware.use Magical::Unicorns
~~~

上述代码会把中间件 `Magical::Unicorns` 放入中间件列表的最后。如果想在某个中间件之前插入中间件，可以使用 `insert_before`：

{:lang="ruby"}
~~~
config.middleware.insert_before ActionDispatch::Head, Magical::Unicorns
~~~

如果想在某个中间件之后插入中间件，可以使用 `insert_after`：

{:lang="ruby"}
~~~
config.middleware.insert_after ActionDispatch::Head, Magical::Unicorns
~~~

中间件还可替换成其他中间件：

{:lang="ruby"}
~~~
config.middleware.swap ActionController::Failsafe, Lifo::Failsafe
~~~

也可从中间件列表中删除：

{:lang="ruby"}
~~~
config.middleware.delete "Rack::MethodOverride"
~~~

### 设置 i18n {#configuring-i18n}

下述设置项目都针对 `I18n` 代码库。

* `config.i18n.available_locales`：设置程序可用本地语言的白名单。默认值为可在本地化文件中找到的所有本地语言，在新建程序中一般是 `:en`。

* `config.i18n.default_locale`：设置程序的默认本地化语言，默认值为 `:en`。

* `config.i18n.enforce_available_locales`：确保传给 i18n 的本地语言在 `available_locales` 列表中，否则抛出 `I18n::InvalidLocale` 异常。默认值为 `true`。除非特别需要，不建议禁用这个选项，因为这是一项安全措施，能防止用户提供不可用的本地语言。

* `config.i18n.load_path`：设置 Rails 搜寻本地化文件的路径。默认为 config/locales/*.{yml,rb}`。

### 设置 Active Record {#configuring-active-record}

`config.active_record` 包含很多设置项：

* `config.active_record.logger`：接受一个实现了 Log4r 接口的类，或者使用默认的 `Logger` 类，然后传给新建的数据库连接。在 Active Record 模型类或模型实例上调用 `logger` 方法可以获取这个日志类。设为 `nil` 禁用日志。

* `config.active_record.primary_key_prefix_type`：调整主键的命名方式。默认情况下，Rails 把主键命名为 `id`（无需设置这个选项）。除此之外还有另外两个选择：
    * `:table_name`：`Customer` 模型的主键为 `customerid`；
    * `:table_name_with_underscore`： `Customer` 模型的主键为 `customer_id`；

* `config.active_record.table_name_prefix`：设置一个全局字符串，作为数据表名的前缀。如果设为 `northwest_`，那么 `Customer` 模型对应的表名为 `northwest_customers`。默认为空字符串。

* `config.active_record.table_name_suffix`：设置一个全局字符串，作为数据表名的后缀。如果设为 `_northwest`，那么 `Customer` 模型对应的表名为 `customers_northwest`。默认为空字符串。

* `config.active_record.schema_migrations_table_name`：设置模式迁移数据表的表名。

* `config.active_record.pluralize_table_names`：设置 Rails 在数据库中要寻找单数形式还是复数形式的数据表。如果设为 `true`（默认值），`Customer` 类对应的数据表是 `customers`。如果设为 `false`，`Customer` 类对应的数据表是 `customer`。

* `config.active_record.default_timezone`：从数据库中查询日期和时间时使用 `Time.local`（设为 `:local` 时）还是 `Time.utc`（设为 `:utc` 时）。默认为 `:utc`。

* `config.active_record.schema_format`：设置导出数据库模式到文件时使用的格式。可选项包括：`:ruby`，默认值，根据迁移导出模式，与数据库种类无关；`:sql`，导出为 SQL 语句，受数据库种类影响。

* `config.active_record.timestamped_migrations`：设置迁移编号使用连续的数字还是时间戳。默认值为 `true`，使用时间戳。如果有多名开发者协作，建议使用时间戳。

* `config.active_record.lock_optimistically`：设置 Active Record 是否使用乐观锁定，默认使用。

* `config.active_record.cache_timestamp_format`：设置缓存键中使用的时间戳格式，默认为 `:number`。

* `config.active_record.record_timestamps`：设置是否记录 `create` 和 `update` 动作的时间戳。默认为 `true`。

* `config.active_record.partial_writes`： 布尔值，设置是否局部写入（例如，只更新有变化的属性）。注意，如果使用局部写入，还要使用乐观锁定，因为并发更新写入的数据可能已经过期。默认值为 `true`。

* `config.active_record.attribute_types_cached_by_default`：设置读取时 `ActiveRecord::AttributeMethods` 缓存的字段类型。默认值为 `[:datetime, :timestamp, :time, :date]`。

* `config.active_record.maintain_test_schema`：设置运行测试时 Active Record 是否要保持测试数据库的模式和 `db/schema.rb` 文件（或 `db/structure.sql`）一致，默认为 `true`。

* `config.active_record.dump_schema_after_migration`：设置运行迁移后是否要导出数据库模式到文件 `db/schema.rb` 或 `db/structure.sql` 中。这项设置在 Rails 生成的 `config/environments/production.rb` 文件中为 `false`。如果不设置这个选项，则值为 `true`。

MySQL 适配器添加了一项额外设置：

* `ActiveRecord::ConnectionAdapters::MysqlAdapter.emulate_booleans`：设置 Active Record 是否要把 MySQL 数据库中 `tinyint(1)` 类型的字段视为布尔值，默认为 `true`。

模式导出程序添加了一项额外设置：

* `ActiveRecord::SchemaDumper.ignore_tables`：指定一个由数据表组成的数组，导出模式时不会出现在模式文件中。仅当 `config.active_record.schema_format == :ruby` 时才有效。

### 设置 Action Controller {#configuring-action-controller}

`config.action_controller` 包含以下设置项：

* `config.action_controller.asset_host`：设置静态资源的主机，不用程序的服务器伺服静态资源，而使用 CDN。

* `config.action_controller.perform_caching`：设置程序是否要缓存。在开发模式中为 `false`，生产环境中为 `true`。

* `config.action_controller.default_static_extension`：设置缓存文件的扩展名，默认为 `.html`。

* `config.action_controller.default_charset`：设置默认字符集，默认为 `utf-8`。

* `config.action_controller.logger`：接受一个实现了 Log4r 接口的类，或者使用默认的 `Logger` 类，用于写 Action Controller 中的日志消息。设为 `nil` 禁用日志。

* `config.action_controller.request_forgery_protection_token`：设置请求伪造保护的权标参数名。默认情况下调用 `protect_from_forgery` 方法，将其设为 `:authenticity_token`。

* `config.action_controller.allow_forgery_protection`：是否启用跨站请求伪造保护功能。在测试环境中默认为 `false`，其他环境中默认为 `true`。

* `config.action_controller.relative_url_root`：用来告知 Rails 程序[部署在子目录中](#deploy-to-a-subdirectory-relative-url-root)。默认值为 `ENV['RAILS_RELATIVE_URL_ROOT']`。

* `config.action_controller.permit_all_parameters`：设置默认允许在批量赋值中使用的参数，默认为 `false`。

* `config.action_controller.action_on_unpermitted_parameters`：发现禁止使用的参数时，写入日志还是抛出异常（分别设为 `:log` 和 `:raise`）。在开发环境和测试环境中的默认值为 `:log`，在其他环境中的默认值为 `false`。

### 设置 Action Dispatch {#configuring-action-dispatch}

*   `config.action_dispatch.session_store`：设置存储会话的方式，默认为 `:cookie_store`，其他可用值有：`:active_record_store`，`:mem_cache_store`，以及自定义类的名字。

*   `config.action_dispatch.default_headers`：一个 Hash，设置响应的默认报头。默认设定的报头为：

    {:lang="ruby"}
    ~~~
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff'
    }
    ~~~

*   `config.action_dispatch.tld_length`：设置顶级域名（top-level domain，简称 TLD）的长度，默认为 `1`。

*   `config.action_dispatch.http_auth_salt`：设置 HTTP Auth 认证的加盐值，默认为 `'http authentication'`。

*   `config.action_dispatch.signed_cookie_salt`：设置签名 cookie 的加盐值，默认为 `'signed cookie'`。

*   `config.action_dispatch.encrypted_cookie_salt`：设置加密 cookie 的加盐值，默认为 `'encrypted cookie'`。

*  `config.action_dispatch.encrypted_signed_cookie_salt`：设置签名加密 cookie 的加盐值，默认为 `'signed encrypted cookie'`。

*   `config.action_dispatch.perform_deep_munge`：设置是否在参数上调用 `deep_munge` 方法。详情参阅“[Rails 安全指南]({{ site.baseurl }}/security.html#unsafe-query-generation)”一文。默认值为 `true`。

*   `ActionDispatch::Callbacks.before`：设置在处理请求前运行的代码块。

*   `ActionDispatch::Callbacks.to_prepare`：设置在 `ActionDispatch::Callbacks.before` 之后、处理请求之前运行的代码块。这个代码块在开发环境中的每次请求中都会运行，但在生产环境或 `cache_classes` 设为 `true` 的环境中只运行一次。

*   `ActionDispatch::Callbacks.after`：设置处理请求之后运行的代码块。

### 设置 Action View {#configuring-action-view}

`config.action_view` 包含以下设置项：

*   `config.action_view.field_error_proc`：设置用于生成 Active Record 表单错误的 HTML，默认为：

    {:lang="ruby"}
    ~~~
    Proc.new do |html_tag, instance|
      %Q(<div class="field_with_errors">#{html_tag}</div>).html_safe
    end
    ~~~

*   `config.action_view.default_form_builder`：设置默认使用的表单构造器。默认值为 `ActionView::Helpers::FormBuilder`。如果想让表单构造器在程序初始化完成后加载（在开发环境中每次请求都会重新加载），可使用字符串形式。

*  `config.action_view.logger`：接受一个实现了 Log4r 接口的类，或者使用默认的 `Logger` 类，用于写入来自 Action View 的日志。设为 `nil` 禁用日志。

*   `config.action_view.erb_trim_mode`：设置 ERB 使用的删除空白模式，默认为 `'-'`，使用 `<%= -%>` 或 `<%= =%>` 时，删除行尾的空白和换行。详情参阅 [Erubis 的文档](http://www.kuwata-lab.com/erubis/users-guide.06.html#topics-trimspaces)。

*   `config.action_view.embed_authenticity_token_in_remote_forms`：设置启用 `:remote => true` 选项的表单如何处理 `authenticity_token` 字段。默认值为 `false`，即不加入 `authenticity_token` 字段，有助于使用片段缓存缓存表单。远程表单可从 `meta` 标签中获取认证权标，因此没必要再加入 `authenticity_token` 字段，除非要支持没启用 JavaScript 的浏览器。如果要支持没启用 JavaScript 的浏览器，可以在表单的选项中加入 `:authenticity_token => true`，或者把这个设置设为 `true`。

*   `config.action_view.prefix_partial_path_with_controller_namespace`：设置渲染命名空间中的控制器时是否要在子文件夹中查找局部视图。例如，控制器名为 `Admin::PostsController`，渲染了以下视图：

    {:lang="erb"}
    ~~~
    <%= render @post %>
    ~~~

    这个设置的默认值为 `true`，渲染的局部视图为 `/admin/posts/_post.erb`。如果设为 `false`，就会渲染 `/posts/_post.erb`，和没加命名空间的控制器（例如 `PostsController`）行为一致。

*   `config.action_view.raise_on_missing_translations`：找不到翻译时是否抛出异常。

### 设置 Action Mailer {#configuring-action-mailer}

`config.action_mailer` 包含以下设置项：

*   `config.action_mailer.logger`：接受一个实现了 Log4r 接口的类，或者使用默认的 `Logger` 类，用于写入来自 Action Mailer 的日志。设为 `nil` 禁用日志。

*   `config.action_mailer.smtp_settings`：详细设置 `:smtp` 发送方式。接受一个 Hash，包含以下选项：
    * `:address`：设置远程邮件服务器，把默认值 `"localhost"` 改成所需值即可；
    * `:port`：如果邮件服务器不使用端口 25，可通过这个选项修改；
    * `:domain`：如果想指定一个 HELO 域名，可通过这个选项修改；
    * `:user_name`：如果所用邮件服务器需要身份认证，可通过这个选项设置用户名；
    * `:password`：如果所用邮件服务器需要身份认证，可通过这个选项设置密码；
    * `:authentication`：如果所用邮件服务器需要身份认证，可通过这个选项指定认证类型，可选值包括：`:plain`，`:login`，`:cram_md5`；

*   `config.action_mailer.sendmail_settings`：详细设置 `sendmail` 发送方式。接受一个 Hash，包含以下选项：
    * `:location`：`sendmail` 可执行文件的位置，默认为 `/usr/sbin/sendmail`；
    * `:arguments`：传入命令行的参数，默认为 `-i -t`；

*   `config.action_mailer.raise_delivery_errors`：如果无法发送邮件，是否抛出异常。默认为 `true`。

*   `config.action_mailer.delivery_method`：设置发送方式，默认为 `:smtp`。详情参阅“Action Mailer 基础”一文中的“[设置]({{ site.baseurl }}/action_mailer_basics.html#action-mailer-configuration)”一节。。

*   `config.action_mailer.perform_deliveries`：设置是否真的发送邮件，默认为 `true`。测试时可设为 `false`。

*   `config.action_mailer.default_options`：设置 Action Mailer 的默认选项。可设置各个邮件发送程序的 `from` 或 `reply_to` 等选项。默认值为：

    {:lang="ruby"}
    ~~~
    mime_version:  "1.0",
    charset:       "UTF-8",
    content_type: "text/plain",
    parts_order:  ["text/plain", "text/enriched", "text/html"]
    ~~~

    设置时要使用 Hash：

    {:lang="ruby"}
    ~~~
    config.action_mailer.default_options = {
      from: "noreply@example.com"
    }
    ~~~

*   `config.action_mailer.observers`：注册邮件发送后触发的监控器。

    {:lang="ruby"}
    ~~~
    config.action_mailer.observers = ["MailObserver"]
    ~~~

*   `config.action_mailer.interceptors`：注册发送邮件前调用的拦截程序。

    {:lang="ruby"}
    ~~~
    config.action_mailer.interceptors = ["MailInterceptor"]
    ~~~

### 设置 Active Support {#configuring-active-support}

Active Support 包含以下设置项：

* `config.active_support.bare`：启动 Rails 时是否加载 `active_support/all`。默认值为 `nil`，即加载 `active_support/all`。

* `config.active_support.escape_html_entities_in_json`：在 JSON 格式的数据中是否转义 HTML 实体。默认为 `false`。

* `config.active_support.use_standard_json_time_format`：在 JSON 格式的数据中是否把日期转换成 ISO 8601 格式。默认为 `true`。

* `config.active_support.time_precision`：设置 JSON 编码的时间精度，默认为 `3`。

* `ActiveSupport::Logger.silencer`：设为 `false` 可以静默代码块中的日志消息。默认为 `true`。

* `ActiveSupport::Cache::Store.logger`：设置缓存存储中使用的写日志程序。

* `ActiveSupport::Deprecation.behavior`：作用和 `config.active_support.deprecation` 一样，设置是否显示 Rails 废弃提醒。

* `ActiveSupport::Deprecation.silence`：接受一个代码块，静默废弃提醒。

* `ActiveSupport::Deprecation.silenced`：设置是否显示废弃提醒。

### 设置数据库 {#configuring-a-database}

几乎每个 Rails 程序都要用到数据库。数据库信息可以在环境变量 `ENV['DATABASE_URL']` 中设定，也可在 `config/database.yml` 文件中设置。

在 `config/database.yml` 文件中可以设置连接数据库所需的所有信息：

{:lang="yaml"}
~~~
development:
  adapter: postgresql
  database: blog_development
  pool: 5
~~~

上述设置使用 `postgresql` 适配器连接名为 `blog_development` 的数据库。这些信息也可存储在 URL 中，通过下面的环境变量提供：

{:lang="ruby"}
~~~
> puts ENV['DATABASE_URL']
postgresql://localhost/blog_development?pool=5
~~~

`config/database.yml` 文件包含三个区域，分别对应 Rails 中的三个默认环境：

* `development` 环境在本地开发电脑上运行，手动与程序交互；
* `test` 环境用于运行自动化测试；
* `production` 环境用于部署后的程序；

如果需要使用 URL 形式，也可在 `config/database.yml` 文件中按照下面的方式设置：

~~~
development:
  url: postgresql://localhost/blog_development?pool=5
~~~

`config/database.yml` 文件中可以包含 ERB 标签 `<%= %>`。这个标签中的代码被视为 Ruby 代码。使用 ERB 标签可以从环境变量中获取数据，或者计算所需的连接信息。

T> 你无须手动更新数据库设置信息。查看新建程序生成器，会发现一个名为 `--database` 的选项。使用这个选项可以从一组常用的关系型数据库中选择想用的数据库。甚至还可重复执行生成器：`cd .. && rails new blog --database=mysql`。确认覆盖文件 `config/database.yml` 后，程序就设置成使用 MySQL，而不是 SQLite。常用数据库的设置如下所示。

### 连接设置 {#connection-preference}

既然数据库的连接信息有两种设置方式，就要知道两者之间的关系。

如果 `config/database.yml` 文件为空，而且设置了环境变量 `ENV['DATABASE_URL']`，Rails 就会使用环境变量连接数据库：

{:lang="sh"}
~~~
$ cat config/database.yml

$ echo $DATABASE_URL
postgresql://localhost/my_database
~~~

如果 `config/database.yml` 文件存在，且没有设置环境变量 `ENV['DATABASE_URL']`，Rails 会使用设置文件中的信息连接数据库：

{:lang="sh"}
~~~
$ cat config/database.yml
development:
  adapter: postgresql
  database: my_database
  host: localhost

$ echo $DATABASE_URL
~~~

如果有 `config/database.yml` 文件，也设置了环境变量 `ENV['DATABASE_URL']`，Rails 会合并二者提供的信息。下面举个例子说明。

如果二者提供的信息有重复，环境变量中的信息优先级更高：

{:lang="sh"}
~~~
$ cat config/database.yml
development:
  adapter: sqlite3
  database: NOT_my_database
  host: localhost

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ rails runner 'puts ActiveRecord::Base.connections'
{"development"=>{"adapter"=>"postgresql", "host"=>"localhost", "database"=>"my_database"}}
~~~

这里的适配器、主机和数据库名都和 `ENV['DATABASE_URL']` 中的信息一致。

如果没有重复，则会从这两个信息源获取信息。如果有冲突，环境变量的优先级更高。

{:lang="sh"}
~~~
$ cat config/database.yml
development:
  adapter: sqlite3
  pool: 5

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ rails runner 'puts ActiveRecord::Base.connections'
{"development"=>{"adapter"=>"postgresql", "host"=>"localhost", "database"=>"my_database", "pool"=>5}}
~~~

因为 `ENV['DATABASE_URL']` 中没有提供数据库连接池信息，所以从设置文件中获取。二者都提供了 `adapter` 信息，但使用的是 `ENV['DATABASE_URL']` 中的信息。

如果完全不想使用 `ENV['DATABASE_URL']` 中的信息，要使用 `url` 子建指定一个 URL：

{:lang="sh"}
~~~
$ cat config/database.yml
development:
  url: sqlite3://localhost/NOT_my_database

$ echo $DATABASE_URL
postgresql://localhost/my_database

$ rails runner 'puts ActiveRecord::Base.connections'
{"development"=>{"adapter"=>"sqlite3", "host"=>"localhost", "database"=>"NOT_my_database"}}
~~~

如上所示，`ENV['DATABASE_URL']` 中的连接信息被忽略了，使用了不同的适配器和数据库名。

既然 `config/database.yml` 文件中可以使用 ERB，最好使用 `ENV['DATABASE_URL']` 中的信息连接数据库。这种方式在生产环境中特别有用，因为我们并不想把数据库密码等信息纳入版本控制系统（例如 Git）。

{:lang="sh"}
~~~
$ cat config/database.yml
production:
  url: <%= ENV['DATABASE_URL'] %>
~~~

注意，这种设置方式很明确，只使用 `ENV['DATABASE_URL']` 中的信息。

#### 设置 SQLite3 数据库 {#configuring-an-sqlite3-database}

Rails 内建支持 [SQLite3](http://www.sqlite.org)。SQLite 是个轻量级数据库，无需单独的服务器。大型线上环境可能并不适合使用 SQLite，但在开发环境和测试环境中使用却很便利。新建程序时，Rails 默认使用 SQLite，但可以随时换用其他数据库。

下面是默认的设置文件（`config/database.yml`）中针对开发环境的数据库设置：

{:lang="yaml"}
~~~
development:
  adapter: sqlite3
  database: db/development.sqlite3
  pool: 5
  timeout: 5000
~~~

I> Rails 默认使用 SQLite3 存储数据，因为 SQLite3 无需设置即可使用。Rails 还内建支持 MySQL 和 PostgreSQL。还提供了很多插件，支持更多的数据库系统。如果在生产环境中使用了数据库，Rails 很可能已经提供了对应的适配器。

#### 设置 MySQL 数据库 {#configuring-a-mysql-database}

如果不想使用 SQLite3，而是使用 MySQL，`config/database.yml` 文件的内容会有些不同。下面是针对开发环境的设置：

{:lang="yaml"}
~~~
development:
  adapter: mysql2
  encoding: utf8
  database: blog_development
  pool: 5
  username: root
  password:
  socket: /tmp/mysql.sock
~~~

如果开发电脑中的 MySQL 使用 root 用户，且没有密码，可以直接使用上述设置。否则就要相应的修改用户名和密码。

#### 设置 PostgreSQL 数据库 {#configuring-a-postgresql-database}

如果选择使用 PostgreSQL，`config/database.yml` 会准备好连接 PostgreSQL 数据库的信息：

{:lang="yaml"}
~~~
development:
  adapter: postgresql
  encoding: unicode
  database: blog_development
  pool: 5
  username: blog
  password:
~~~

`PREPARE` 语句可使用下述方法禁用：

{:lang="yaml"}
~~~
production:
  adapter: postgresql
  prepared_statements: false
~~~

#### 在 JRuby 平台上设置 SQLite3 数据库 {#configuring-an-sqlite3-database-for-jruby-platform}

如果在 JRuby 中使用 SQLite3，`config/database.yml` 文件的内容会有点不同。下面是针对开发环境的设置：

{:lang="yaml"}
~~~
development:
  adapter: jdbcsqlite3
  database: db/development.sqlite3
~~~

#### 在 JRuby 平台上设置 MySQL 数据库 {#configuring-a-mysql-database-for-jruby-platform}

如果在 JRuby 中使用 MySQL，`config/database.yml` 文件的内容会有点不同。下面是针对开发环境的设置：

{:lang="yaml"}
~~~
development:
  adapter: jdbcmysql
  database: blog_development
  username: root
  password:
~~~

#### 在 JRuby 平台上设置 PostgreSQL 数据库 {#configuring-a-postgresql-database-for-jruby-platform}

如果在 JRuby 中使用 PostgreSQL，`config/database.yml` 文件的内容会有点不同。下面是针对开发环境的设置：

{:lang="yaml"}
~~~
development:
  adapter: jdbcpostgresql
  encoding: unicode
  database: blog_development
  username: blog
  password:
~~~

请相应地修改 `development` 区中的用户名和密码。

### 新建 Rails 环境 {#creating-rails-environments}

默认情况下，Rails 提供了三个环境：开发，测试和生产。这三个环境能满足大多数需求，但有时需要更多的环境。

假设有个服务器镜像了生产环境，但只用于测试。这种服务器一般叫做“交付准备服务器”（staging server）。要想为这个服务器定义一个名为“staging”的环境，新建文件 `config/environments/staging.rb` 即可。请使用 `config/environments` 文件夹中的任一文件作为模板，以此为基础修改设置。

新建的环境和默认提供的环境没什么区别，可以执行 `rails server -e staging` 命令启动服务器，执行 `rails console staging` 命令进入控制台，`Rails.env.staging?` 也可使用。

### 部署到子目录中 {#deploy-to-a-subdirectory-relative-url-root}

默认情况下，Rails 在根目录（例如 `/`）中运行程序。本节说明如何在子目录中运行程序。

假设想把网站部署到 `/app1` 目录中。生成路由时，Rails 要知道这个目录：

{:lang="ruby"}
~~~
config.relative_url_root = "/app1"
~~~

或者，设置环境变量 `RAILS_RELATIVE_URL_ROOT` 也行。

这样设置之后，Rails 生成的链接都会加上前缀 `/app1`。

#### 使用 Passenger {#using-passenger}

使用 Passenger 时，在子目录中运行程序更简单。具体做法参见 [Passenger 手册](http://www.modrails.com/documentation/Users%20guide%20Apache.html#deploying_rails_to_sub_uri)。

#### 使用反向代理 {#using-a-reverse-proxy}

TODO

#### 部署到子目录时的注意事项 {#considerations-when-deploying-to-a-subdirectory}

在生产环境中部署到子目录中会影响 Rails 的多个功能：

* 开发环境
* 测试环境
* 伺服静态资源文件
* Asset Pipeline

## Rails 环境设置 {#rails-environment-settings}

Rails 的某些功能只能通过外部的环境变量设置。下面介绍的环境变量可以被 Rails 识别：

* `ENV["RAILS_ENV"]`：指定 Rails 运行在哪个环境中：生成环境，开发环境，测试环境等。

* `ENV["RAILS_RELATIVE_URL_ROOT"]`：[部署到子目录](#deploy-to-a-subdirectory-relative-url-root)时，路由用来识别 URL。

* `ENV["RAILS_CACHE_ID"]` 和 `ENV["RAILS_APP_VERSION"]`：用于生成缓存扩展键。允许在同一程序中使用多个缓存。

## 使用初始化脚本 {#using-initializer-files}

加载完框架以及程序中使用的 gem 后，Rails 会加载初始化脚本。初始化脚本是个 Ruby 文件，存储在程序的 `config/initializers` 文件夹中。初始化脚本可在框架和 gem 加载完成后做设置。

I> 如果有需求，可以使用子文件夹组织初始化脚本，Rails 会加载整个 `config/initializers` 文件夹中的内容。

T> 如果对初始化脚本的加载顺序有要求，可以通过文件名控制。初始化脚本的加载顺序按照文件名的字母表顺序进行。例如，`01_critical.rb` 在 `02_normal.rb` 之前加载。

## 初始化事件 {#initialization-events}

Rails 提供了 5 个初始化事件，可做钩子使用。下面按照事件的加载顺序介绍：

* `before_configuration`：程序常量继承自 `Rails::Application` 之后立即运行。`config` 方法在此事件之前调用。

* `before_initialize`：在程序初始化过程中的 `:bootstrap_hook` 之前运行，接近初始化过程的开头。

* `to_prepare`：所有 Railtie（包括程序本身）的初始化都运行完之后，但在按需加载代码和构建中间件列表之前运行。更重要的是，在开发环境中，每次请求都会运行，但在生产环境和测试环境中只运行一次（在启动阶段）。

* `before_eager_load`：在按需加载代码之前运行。这是在生产环境中的默认表现，但在开发环境中不是。

* `after_initialize`：在程序初始化完成之后运行，即 `config/initializers` 文件夹中的初始化脚本运行完毕之后。

要想为这些钩子定义事件，可以在 `Rails::Application`、`Rails::Railtie` 或 `Rails::Engine` 的子类中使用代码块：

{:lang="ruby"}
~~~
module YourApp
  class Application < Rails::Application
    config.before_initialize do
      # initialization code goes here
    end
  end
end
~~~

或者，在 `Rails.application` 对象上调用 `config` 方法：

{:lang="ruby"}
~~~
Rails.application.config.before_initialize do
  # initialization code goes here
end
~~~

W> 程序的某些功能，尤其是路由，在 `after_initialize` 之后还不可用。

### `Rails::Railtie#initializer` {#rails-railtie-initializer}

Rails 中有几个初始化脚本使用 `Rails::Railtie` 的 `initializer` 方法定义，在程序启动时运行。下面这段代码摘自 Action Controller 中的 `set_helpers_path` 初始化脚本：

{:lang="ruby"}
~~~
initializer "action_controller.set_helpers_path" do |app|
  ActionController::Helpers.helpers_path = app.helpers_paths
end
~~~

`initializer` 方法接受三个参数，第一个是初始化脚本的名字，第二个是选项 Hash（上述代码中没用到），第三个参数是代码块。参数 Hash 中的 `:before` 键指定在特定的初始化脚本之前运行，`:after` 键指定在特定的初始化脚本之后运行。

使用 `initializer` 方法定义的初始化脚本按照定义的顺序运行，但指定 `:before` 或 `:after` 参数的初始化脚本例外。

W> 初始化脚本可放在任一初始化脚本的前面或后面，只要符合逻辑即可。假设定义了四个初始化脚本，名字为 `"one"` 到 `"four"`（就按照这个顺序定义），其中 `"four"` 在 `"four"` 之前，且在 `"three"` 之后，这就不符合逻辑，Rails 无法判断初始化脚本的加载顺序。

`initializer` 方法的代码块参数是程序实例，因此可以调用 `config` 方法，如上例所示。

因为 `Rails::Application` 直接继承自 `Rails::Railtie`，因此可在文件 `config/application.rb` 中使用 `initializer` 方法定义程序的初始化脚本。

### 初始化脚本 {#initializers}

下面列出了 Rails 中的所有初始化脚本，按照定义的顺序，除非特别说明，也按照这个顺序执行。

* `load_environment_hook`：只是一个占位符，让 `:load_environment_config` 在其前运行。

* `load_active_support`：加载 `active_support/dependencies`，加入 Active Support 的基础。如果 `config.active_support.bare` 为非真值（默认），还会加载 `active_support/all`。

* `initialize_logger`：初始化日志程序（`ActiveSupport::Logger` 对象），可通过 `Rails.logger` 调用。在此之前的初始化脚本中不能定义 `Rails.logger`。

* `initialize_cache`：如果还没创建 `Rails.cache`，使用 `config.cache_store` 指定的方式初始化缓存，并存入 `Rails.cache`。如果对象能响应 `middleware` 方法，对应的中间件会插入 `Rack::Runtime` 之前。

* `set_clear_dependencies_hook`：为 `active_record.set_dispatch_hooks` 提供钩子，在本初始化脚本之前运行。这个初始化脚本只有当 `cache_classes` 为 `false` 时才会运行，使用 `ActionDispatch::Callbacks.after` 从对象空间中删除请求过程中已经引用的常量，以便下次请求重新加载。

* `initialize_dependency_mechanism`：如果 `config.cache_classes` 为 `true`，设置 `ActiveSupport::Dependencies.mechanism` 使用 `require` 而不是 `load` 加载依赖件。

* `bootstrap_hook`：运行所有 `before_initialize` 代码块。

* `i18n.callbacks`：在开发环境中，设置一个 `to_prepare` 回调，调用 `I18n.reload!` 加载上次请求后修改的本地化翻译。在生产环境中这个回调只会在首次请求时运行。

* `active_support.deprecation_behavior`：设置各环境的废弃提醒方式，开发环境的方式为 `:log`，生产环境的方式为 `:notify`，测试环境的方式为 `:stderr`。如果没有为 `config.active_support.deprecation` 设定值，这个初始化脚本会提醒用户在当前环境的设置文件中设置。可以设为一个数组。

* `active_support.initialize_time_zone`：根据 `config.time_zone` 设置程序的默认时区，默认值为 `"UTC"`。

* `active_support.initialize_beginning_of_week`：根据 `config.beginning_of_week` 设置程序默认使用的一周开始日，默认值为 `:monday`。

* `action_dispatch.configure`：把 `ActionDispatch::Http::URL.tld_length` 设置为 `config.action_dispatch.tld_length` 指定的值。

* `action_view.set_configs`：根据 `config.action_view` 设置 Action View，把指定的方法名做为赋值方法发送给 `ActionView::Base`，并传入指定的值。

* `action_controller.logger`：如果还未创建，把 `ActionController::Base.logger` 设为 `Rails.logger`。

* `action_controller.initialize_framework_caches`：如果还未创建，把 `ActionController::Base.cache_store` 设为 `Rails.cache`。

* `action_controller.set_configs`：根据 `config.action_controller` 设置 Action Controller，把指定的方法名作为赋值方法发送给 `ActionController::Base`，并传入指定的值。

* `action_controller.compile_config_methods`：初始化指定的设置方法，以便快速访问。

* `active_record.initialize_timezone`：把 `ActiveRecord::Base.time_zone_aware_attributes` 设为 `true`，并把 `ActiveRecord::Base.default_timezone` 设为 UTC。从数据库中读取数据时，转换成 `Time.zone` 中指定的时区。

* `active_record.logger`：如果还未创建，把 `ActiveRecord::Base.logger` 设为 `Rails.logger`。

* `active_record.set_configs`：根据 `config.active_record` 设置 Active Record，把指定的方法名作为赋值方法传给 `ActiveRecord::Base`，并传入指定的值。

* `active_record.initialize_database`：从 `config/database.yml` 中加载数据库设置信息，并为当前环境建立数据库连接。

* `active_record.log_runtime`：引入 `ActiveRecord::Railties::ControllerRuntime`，这个模块负责把 Active Record 查询花费的时间写入日志。

* `active_record.set_dispatch_hooks`：如果 `config.cache_classes` 为 `false`，重置所有可重新加载的数据库连接。

* `action_mailer.logger`：如果还未创建，把 `ActionMailer::Base.logger` 设为 `Rails.logger`。

* `action_mailer.set_configs`：根据 `config.action_mailer` 设置 Action Mailer，把指定的方法名作为赋值方法发送给 `ActionMailer::Base`，并传入指定的值。

* `action_mailer.compile_config_methods`：初始化指定的设置方法，以便快速访问。

* `set_load_path`：在 `bootstrap_hook` 之前运行。把 `vendor` 文件夹、`lib` 文件夹、`app` 文件夹中的所有子文件夹，以及 `config.load_paths` 中指定的路径加入 `$LOAD_PATH`。

* `set_autoload_paths`：在 `bootstrap_hook` 之前运行。把 `app` 文件夹中的所有子文件夹，以及 `config.autoload_paths` 指定的路径加入 `ActiveSupport::Dependencies.autoload_paths`。

* `add_routing_paths`：加载所有 `config/routes.rb` 文件（程序中的，Railtie 中的，以及引擎中的），并创建程序的路由。

* `add_locales`：把 `config/locales` 文件夹中的所有文件（程序中的，Railties 中的，以及引擎中的）加入 `I18n.load_path`，让这些文件中的翻译可用。

* `add_view_paths`：把程序、Railtie 和引擎中的 `app/views` 文件夹加入视图文件查找路径。

* `load_environment_config`：加载 `config/environments` 文件夹中当前环境对应的设置文件。

* `append_asset_paths`：查找程序的静态资源文件路径，Railtie 中的静态资源文件路径，以及 `config.static_asset_paths` 中可用的文件夹。

* `prepend_helpers_path`：把程序、Railtie、引擎中的 `app/helpers` 文件夹加入帮助文件查找路径。

* `load_config_initializers`：加载程序、Railtie、引擎中 `config/initializers` 文件夹里所有的 Ruby 文件。这些文件可在框架加载后做设置。

* `engines_blank_point`：在初始化过程加入一个时间点，以防加载引擎之前要做什么处理。在这一点之后，会运行所有 Railtie 和引擎的初始化脚本。

* `add_generator_templates`：在程序、Railtie、引擎的 `lib/templates` 文件夹中查找生成器使用的模板，并把这些模板添加到 `config.generators.templates`，让所有生成器都能使用。

* `ensure_autoload_once_paths_as_subset`：确保 `config.autoload_once_paths` 只包含 `config.autoload_paths` 中的路径。如果包含其他路径，会抛出异常。

* `add_to_prepare_blocks`：把程序、Railtie、引擎中的 `config.to_prepare` 加入 Action Dispatch 的 `to_prepare` 回调中，这些回调在开发环境中每次请求都会运行，但在生产环境中只在首次请求前运行。

* `add_builtin_route`：如果程序运行在开发环境中，这个初始化脚本会把 `rails/info/properties` 添加到程序的路由中。这个路由对应的页面显示了程序的详细信息，例如 Rails 和 Ruby 版本。

* `build_middleware_stack`：构建程序的中间件列表，返回一个对象，可响应 `call` 方法，参数为 Rack 请求的环境对象。

* `eager_load!`：如果 `config.eager_load` 为 `true`，运行 `config.before_eager_load` 钩子，然后调用 `eager_load!`，加载所有 `config.eager_load_namespaces` 中的命名空间。

* `finisher_hook`：为程序初始化完成点提供一个钩子，还会运行程序、Railtie、引擎中的所有 `config.after_initialize` 代码块。

* `set_routes_reloader`：设置 Action Dispatch 使用 `ActionDispatch::Callbacks.to_prepare` 重新加载路由文件。

* `disable_dependency_loading`：如果 `config.eager_load` 为 `true`，禁止自动加载依赖件。

## 数据库连接池 {#database-pooling}

Active Record 数据库连接由 `ActiveRecord::ConnectionAdapters::ConnectionPool` 管理，确保一个连接池的线程量限制在有限的数据库连接数之内。这个限制量默认为 5，但可以在文件 `database.yml` 中设置。

{:lang="ruby"}
~~~
development:
  adapter: sqlite3
  database: db/development.sqlite3
  pool: 5
  timeout: 5000
~~~

因为连接池在 Active Record 内部处理，因此程序服务器（Thin，mongrel，Unicorn 等）要表现一致。一开始数据库连接池是空的，然后按需创建更多的链接，直到达到连接池数量限制为止。

任何一个请求在初次需要连接数据库时都要检查连接，请求处理完成后还会再次检查，确保后续连接可使用这个连接池。

如果尝试使用比可用限制更多的连接，Active Record 会阻塞连接，等待连接池分配新的连接。如果无法获得连接，会抛出如下所示的异常。

{:lang="ruby"}
~~~
ActiveRecord::ConnectionTimeoutError - could not obtain a database connection within 5 seconds. The max pool size is currently 5; consider increasing it:
~~~

如果看到以上异常，可能需要增加连接池限制数量，方法是修改 `database.yml` 文件中的 `pool` 选项。

I> 如果在多线程环境中运行程序，有可能多个线程同时使用多个连接。所以，如果程序的请求量很大，有可能出现多个线程抢用有限的连接。
