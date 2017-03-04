Ruby on Rails 5.0 发布记
========================

Rails 5.0 的重要变化：

- Action Cable

- Rails API

- Active Record Attributes API

- 测试运行程序

- `rails` CLI 全面取代 Rake

- Sprockets 3

- Turbolinks 5

- 要求 Ruby 2.2.2+

本文只涵盖重要变化。若想了解缺陷修正和小变化，请查看更新日志，或者 GitHub 中 Rails 主仓库的[提交历史](https://github.com/rails/rails/commits/5-0-stable)。

升级到 Rails 5.0
----------------

如果升级现有应用，在继续之前，最好确保有足够的测试覆盖度。如果尚未升级到 Rails 4.2，应该先升级到 4.2 版，确保应用能正常运行之后，再尝试升级到 Rails 5.0。升级时的注意事项参见 [Ruby on Rails 升级指南](upgrading_ruby_on_rails.html#从 Rails 4.2 升级到 5.0)。

主要功能
--------

### Action Cable

[拉取请求](https://github.com/rails/rails/pull/22586)

Action Cable 是 Rails 4 新增的框架，其作用是把 [WebSockets](https://en.wikipedia.org/wiki/WebSocket) 无缝集成到 Rails 应用中。

有了 Action Cable，你就可以使用与 Rails 应用其他部分一样的风格和形式使用 Ruby 编写实时功能，而且兼顾性能和可伸缩性。这是一个全栈框架，既提供了客户端 JavaScript 框架，也提供了服务器端 Ruby 框架。你对使用 Active Record 或其他 ORM 编写的领域模型有完全的访问能力。

详情参见[Action Cable 概览](action_cable_overview.html)。

### API 应用

Rails 现在可用于创建专门的 API 应用了。如此以来，我们便可以创建类似 [Twitter](https://dev.twitter.com/) 和 [GitHub](http://developer.github.com/) 那样的 API，提供给公众使用，或者只供自己使用。

Rails API 应用通过下述命令生成：

```sh
$ rails new my_api --api
```

上述命令主要做三件事：

- 配置应用，使用有限的中间件（比常规应用少）。具体而言，不含默认主要针对浏览器应用的中间件（如提供 cookie 支持的中间件）。

- 让 `ApplicationController` 继承 `ActionController::API`，而不继承 `ActionController::Base`。与中间件一样，这样做是为了去除主要针对浏览器应用的 Action Controller 模块。

- 配置生成器，生成资源时不生成视图、辅助方法和静态资源。

生成的应用提供了基本的 API，你可以根据应用的需要配置，[加入所需的功能](api_app.xml#using-rails-for-api-only-applications)。

详情参见[使用 Rails 开发只提供 API 的应用](api_app.html)。

### Active Record Attributes API

为模型定义指定类型的属性。如果需要，会覆盖属性的当前类型。通过这一 API 可以控制属性的类型在模型和 SQL 之间的转换。此外，还可以改变传给 `ActiveRecord::Base.where` 的值的行为，以便让领域对象可以在 Active Record 的大多数地方使用，而不用依赖实现细节或使用猴子补丁。

通过这一 API 可以实现：

- 覆盖 Active Record 检测到的类型。

- 提供默认类型。

- 属性不一定对应于数据库列。

```ruby
# db/schema.rb
create_table :store_listings, force: true do |t|
  t.decimal :price_in_cents
  t.string :my_string, default: "original default"
end

# app/models/store_listing.rb
class StoreListing < ActiveRecord::Base
end

store_listing = StoreListing.new(price_in_cents: '10.1')

# 以前
store_listing.price_in_cents # => BigDecimal.new(10.1)
StoreListing.new.my_string # => "original default"

class StoreListing < ActiveRecord::Base
  attribute :price_in_cents, :integer # custom type
  attribute :my_string, :string, default: "new default" # default value
  attribute :my_default_proc, :datetime, default: -> { Time.now } # default value
  attribute :field_without_db_column, :integer, array: true
end

# 现在
store_listing.price_in_cents # => 10
StoreListing.new.my_string # => "new default"
StoreListing.new.my_default_proc # => 2015-05-30 11:04:48 -0600
model = StoreListing.new(field_without_db_column: ["1", "2", "3"])
model.attributes # => {field_without_db_column: [1, 2, 3]}
```

创建自定义类型  
你可以自定义类型，只要它们能响应值类型定义的方法。`deserialize` 或 `cast` 会在自定义类型的对象上调用，传入从数据库或控制器获取的原始值。通过这一特性可以自定义转换方式，例如处理货币数据。

查询  
`ActiveRecord::Base.where` 会使用模型类定义的类型把值转换成 SQL，方法是在自定义类型对象上调用 `serialize`。

这样，做 SQL 查询时可以指定如何转换值。

Dirty Tracking  
通过属性的类型可以改变 Dirty Tracking 的执行方式。

详情参见[文档](http://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html)。

### 测试运行程序

为了增强 Rails 运行测试的能力，这一版引入了新的测试运行程序。若想使用这个测试运行程序，输入 `bin/rails test` 即可。

这个测试运行程序受 `RSpec`、`minitest-reporters` 和 `maxitest` 等启发，包含下述主要优势：

- 通过测试的行号运行单个测试。

- 指定多个行号，运行多个测试。

- 改进失败消息，也便于重新运行失败的测试。

- 指定 `-f` 选项，尽早失败，一旦发现失败就停止测试，而不是等到整个测试组件运行完毕。

- 指定 `-d` 选项，等到测试全部运行完毕再显示输出。

- 指定 `-b` 选项，输出完整的异常回溯信息。

- 与 `Minitest` 集成，允许指定 `-s` 选项测试种子数据，指定 `-n` 选项运行指定名称的测试，指定 `-v` 选项输出更详细的信息，等等。

- 以不同颜色显示测试输出。

Railties
--------

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-0-stable/railties/CHANGELOG.md)。

### 删除

- 删除对 `debugger` 的支持，换用 `byebug`。因为 Ruby 2.2 不支持 `debugger`。（[提交](https://github.com/rails/rails/commit/93559da4826546d07014f8cfa399b64b4a143127)）

- 删除弃用的 `test:all` 和 `test:all:db` 任务。（[提交](https://github.com/rails/rails/commit/f663132eef0e5d96bf2a58cec9f7c856db20be7c)）

- 删除弃用的 `Rails::Rack::LogTailer`。（[提交](https://github.com/rails/rails/commit/c564dcb75c191ab3d21cc6f920998b0d6fbca623)）

- 删除弃用的 `RAILS_CACHE` 常量。（[提交](https://github.com/rails/rails/commit/b7f856ce488ef8f6bf4c12bb549f462cb7671c08)）

- 删除弃用的 `serve_static_assets` 配置。（[提交](https://github.com/rails/rails/commit/463b5d7581ee16bfaddf34ca349b7d1b5878097c)）

- 删除 `doc:app`、`doc:rails` 和 `doc:gudies` 三个文档任务。（[提交](https://github.com/rails/rails/commit/cd7cc5254b090ccbb84dcee4408a5acede25ef2a)）

- 从默认栈中删除 `Rack::ContentLength` 中间件。（[提交](https://github.com/rails/rails/commit/56903585a099ab67a7acfaaef0a02db8fe80c450)）

### 弃用

- 弃用 `config.static_cache_control`，换成 `config.public_file_server.headers`。（[拉取请求](https://github.com/rails/rails/pull/19135)）

- 弃用 `config.serve_static_files`，换成 `config.public_file_server.enabled`。（[拉取请求](https://github.com/rails/rails/pull/22173)）

- 弃用 `rails` 命名空间下的任务，换成 `app` 命名空间（例如，`rails:update` 和 `rails:template` 任务变成了 `app:update` 和 `app:template`）。（[拉取请求](https://github.com/rails/rails/pull/23439)）

### 重要变化

- 添加 Rails 测试运行程序 `bin/rails test`。（[拉取请求](https://github.com/rails/rails/pull/19216)）

- 新生成的应用和插件的自述文件使用 Markdown 格式。（[提交](https://github.com/rails/rails/commit/89a12c931b1f00b90e74afffcdc2fc21f14ca663)，[拉取请求](https://github.com/rails/rails/pull/22068)）

- 添加 `bin/rails restart` 任务，通过 touch `tmp/restart.txt` 文件重启 Rails 应用。（[拉取请求](https://github.com/rails/rails/pull/18965)）

- 添加 `bin/rails initializers` 任务，按照 Rails 调用的顺序输出所有初始化脚本。（[拉取请求](https://github.com/rails/rails/pull/19323)）

- 添加 `bin/rails dev:cache` 任务，在开发环境启用或禁用缓存。（[拉取请求](https://github.com/rails/rails/pull/20961)）

- 添加 `bin/update` 脚本，自动更新开发环境。（[拉取请求](https://github.com/rails/rails/pull/20972)）

- 通过 `bin/rails` 代理 Rake 任务。（[拉取请求](https://github.com/rails/rails/pull/22457)，[拉取请求](https://github.com/rails/rails/pull/22288)）

- 新生成的应用在 Linux 和 macOS 中启用文件系统事件监控。把 `--skip-listen` 传给生成器可以禁用这一功能。（[提交](https://github.com/rails/rails/commit/de6ad5665d2679944a9ee9407826ba88395a1003)，[提交](https://github.com/rails/rails/commit/94dbc48887bf39c241ee2ce1741ee680d773f202)）

- 使用环境变量 `RAILS_LOG_TO_STDOUT` 把生产环境的日志输出到 STDOUT。（[拉取请求](https://github.com/rails/rails/pull/23734)）

- 新应用通过 IncludeSudomains 首部启用 HSTS。（[拉取请求](https://github.com/rails/rails/pull/23852)）

- 应用生成器创建一个名为 `config/spring.rb` 的新文件，告诉 Spring 监视其他常见的文件。（[提交](https://github.com/rails/rails/commit/b04d07337fd7bc17e88500e9d6bcd361885a45f8)）

- 添加 `--skip-action-mailer`，生成新应用时不生成 Action Mailer。（[拉取请求](https://github.com/rails/rails/pull/18288)）

- 删除 `tmp/sessions` 目录，以及与之对应的 Rake 清理任务。（[拉取请求](https://github.com/rails/rails/pull/18314)）

- 让脚手架生成的 `_form.html.erb` 使用局部变量。（[拉取请求](https://github.com/rails/rails/pull/13434)）

- 禁止在生产环境自动加载类。（[提交](https://github.com/rails/rails/commit/a71350cae0082193ad8c66d65ab62e8bb0b7853b)）

Action Pack
-----------

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-0-stable/actionpack/CHANGELOG.md)。

### 删除

- 删除 `ActionDispatch::Request::Utils.deep_munge`。（[提交](https://github.com/rails/rails/commit/52cf1a71b393486435fab4386a8663b146608996)）

- 删除 `ActionController::HideActions`。（[拉取请求](https://github.com/rails/rails/pull/18371)）

- 删除占位方法 `respond_to` 和 `respond_with`，提取为 [`responders`](https://github.com/plataformatec/responders) gem。([提交](https://github.com/rails/rails/commit/afd5e9a7ff0072e482b0b0e8e238d21b070b6280))

- 删除弃用的断言文件。（[提交](https://github.com/rails/rails/commit/92e27d30d8112962ee068f7b14aa7b10daf0c976)）

- 不再允许在 URL 辅助方法中使用字符串键。（[提交](https://github.com/rails/rails/commit/34e380764edede47f7ebe0c7671d6f9c9dc7e809)）

- 删除弃用的 `*_path` 辅助方法的 `only_path` 选项。（[提交](https://github.com/rails/rails/commit/e4e1fd7ade47771067177254cb133564a3422b8a)）

- 删除弃用的 `NamedRouteCollection#helpers`。（[提交](https://github.com/rails/rails/commit/2cc91c37bc2e32b7a04b2d782fb8f4a69a14503f)）

- 不再允许使用不带 `#` 的 `:to` 选项定义路由。（[提交](https://github.com/rails/rails/commit/1f3b0a8609c00278b9a10076040ac9c90a9cc4a6)）

- 删除弃用的 `ActionDispatch::Response#to_ary`。（[提交](https://github.com/rails/rails/commit/4b19d5b7bcdf4f11bd1e2e9ed2149a958e338c01)）

- 删除弃用的 `ActionDispatch::Request#deep_munge`。（[提交](https://github.com/rails/rails/commit/7676659633057dacd97b8da66e0d9119809b343e)）

- 删除弃用的 `ActionDispatch::Http::Parameters#symbolized_path_parameters`。（[提交](https://github.com/rails/rails/commit/7fe7973cd8bd119b724d72c5f617cf94c18edf9e)）

- 不再允许在控制器测试中使用 `use_route` 选项。（[提交](https://github.com/rails/rails/commit/e4cfd353a47369dd32198b0e67b8cbb2f9a1c548)）

- 删除 `assigns` 和 `assert_template`，提取为 [`rails-controller-testing`](https://github.com/rails/rails-controller-testing) gem 中。（[拉取请求](https://github.com/rails/rails/pull/20138)）

### 弃用

- 弃用所有 `*_filter` 回调，换成 `*_action`。（[拉取请求](https://github.com/rails/rails/pull/18410)）

- 弃用 `*_via_redirect` 集成测试方法。请在请求后手动调用 `follow_redirect!`，效果一样。（[拉取请求](https://github.com/rails/rails/pull/18693)）

- 弃用 `AbstractController#skip_action_callback`，换成单独的 `skip_callback` 方法。（[拉取请求](https://github.com/rails/rails/pull/19060)）

- 弃用 `render` 方法的 `:nothing` 选项。（[拉取请求](https://github.com/rails/rails/pull/20336)）

- 以前，`head` 方法的第一个参数是一个 散列，而且可以设定默认的状态码；现在弃用了。（[拉取请求](https://github.com/rails/rails/pull/20407)）

- 弃用通过字符串或符号指定中间件类名。直接使用类名。（[提交](https://github.com/rails/rails/commit/83b767ce)）

- 弃用通过常量访问 MIME 类型（如 `Mime::HTML`）。换成通过下标和符号访问（如 `Mime[:html]`）。（[拉取请求](https://github.com/rails/rails/pull/21869)）

- 弃用 `redirect_to :back`，换成 `redirect_back`。后者必须指定 `fallback_location` 参数，从而避免出现 `RedirectBackError` 异常。（[拉取请求](https://github.com/rails/rails/pull/22506)）

- `ActionDispatch::IntegrationTest` 和 `ActionController::TestCase` 弃用位置参数，换成关键字参数。（[拉取请求](https://github.com/rails/rails/pull/18323)）

- 弃用 `:controller` 和 `:action` 路径参数。（[拉取请求](https://github.com/rails/rails/pull/23980)）

- 弃用控制器实例的 `env` 方法。（[提交](https://github.com/rails/rails/commit/05934d24aff62d66fc62621aa38dae6456e276be)）

- 启用了 `ActionDispatch::ParamsParser`，而且从中间件栈中删除了。若想配置参数解析程序，使用 `ActionDispatch::Request.parameter_parsers=`。（[提交](https://github.com/rails/rails/commit/38d2bf5fd1f3e014f2397898d371c339baa627b1)，[提交](https://github.com/rails/rails/commit/5ed38014811d4ce6d6f957510b9153938370173b)）

### 重要变化

- 添加 `ActionController::Renderer`，在控制器动作之外渲染任意模板。（[拉取请求](https://github.com/rails/rails/pull/18546)）

- 把 `ActionController::TestCase` 和 `ActionDispatch::Integration` 的 HTTP 请求方法的参数换成关键字参数。（[拉取请求](https://github.com/rails/rails/pull/18323)）

- 为 Action Controller 添加 `http_cache_forever`，缓存响应，永不过期。（[拉取请求](https://github.com/rails/rails/pull/18394)）

- 为获取请求设备提供更友好的方式。（[拉取请求](https://github.com/rails/rails/pull/18939)）

- 对没有模板的动作来说，渲染 `head :no_content`，而不是抛出异常。（[拉取请求](https://github.com/rails/rails/pull/19377)）

- 支持覆盖控制器默认的表单构建程序。（[拉取请求](https://github.com/rails/rails/pull/19736)）

- 添加对只提供 API 的应用的支持。添加 `ActionController::API`，在这类应用中取代 `ActionController::Base`。（[拉取请求](https://github.com/rails/rails/pull/19832)）

- `ActionController::Parameters` 不再继承自 `HashWithIndifferentAccess`。（[拉取请求](https://github.com/rails/rails/pull/20868)）

- 减少 `config.force_ssl` 和 `config.ssl_options` 的危险性，更便于禁用。（[拉取请求](https://github.com/rails/rails/pull/21520)）

- 允许 `ActionDispatch::Static` 返回任意首部。（[拉取请求](https://github.com/rails/rails/pull/19135)）

- 把 `protect_from_forgery` 提供的保护措施默认设为 `false`。（[提交](https://github.com/rails/rails/commit/39794037817703575c35a75f1961b01b83791191)）

- `ActionController::TestCase` 将在 Rails 5.1 中移除，制成单独的 gem。换用 `ActionDispatch::IntegrationTest`。（[提交](https://github.com/rails/rails/commit/4414c5d1795e815b102571425974a8b1d46d932d)）

- Rails 默认生成弱 ETag。（[拉取请求](https://github.com/rails/rails/pull/17573)）

- 如果控制器动作没有显式调用 `render`，而且没有对应的模板，隐式渲染 `head :no_content`，不再抛出异常。（[拉取请求](https://github.com/rails/rails/pull/19377)，[拉取请求](https://github.com/rails/rails/pull/23827)）

- 添加一个选项，为每个表单指定单独的 CSRF 令牌。（[拉取请求](https://github.com/rails/rails/pull/22275)）

- 为集成测试添加请求编码和响应解析功能。（[拉取请求](https://github.com/rails/rails/pull/21671)）

- 添加 `ActionController#helpers`，在控制器层访问视图上下文。（[拉取请求](https://github.com/rails/rails/pull/24866)）

- 不用的闪现消息在存入会话之前删除。（[拉取请求](https://github.com/rails/rails/pull/18721)）

- 让 `fresh_when` 和 `stale?` 支持解析记录集合。（[拉取请求](https://github.com/rails/rails/pull/18374)）

- `ActionController::Live` 变成一个 `ActiveSupport::Concern`。这意味着，不能直接将其引入其他模块，而不使用 `ActiveSupport::Concern` 扩展，否则，`ActionController::Live` 在生产环境无效。有些人还可能会使用其他模块引入处理 `Warden`/`Devise` 身份验证失败的特殊代码，因为中间件无法捕获派生的线程抛出的 `:warden` 异常——使用 `ActionController::Live` 时就是如此。（[详情](https://github.com/rails/rails/issues/25581)）

- 引入 `Response#strong_etag=` 和 `#weak_etag=`，以及 `fresh_when` 和 `stale?` 的相应选项。（[拉取请求](https://github.com/rails/rails/pull/24387)）

Action View
-----------

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-0-stable/actionview/CHANGELOG.md)。

### 删除

- 删除弃用的 `AbstractController::Base::parent_prefixes`。（[提交](https://github.com/rails/rails/commit/34bcbcf35701ca44be559ff391535c0dd865c333)）

- 删除 `ActionView::Helpers::RecordTagHelper`，提取为 [`record_tag_helper`](https://github.com/rails/record_tag_helper) gem。（[拉取请求](https://github.com/rails/rails/pull/18411)）

- 删除 `translate` 辅助方法的 `:rescue_format` 选项，因为 I18n 不再支持。（[拉取请求](https://github.com/rails/rails/pull/20019)）

### 重要变化

- 把默认的模板处理程序由 `ERB` 改为 `Raw`。（[提交](https://github.com/rails/rails/commit/4be859f0fdf7b3059a28d03c279f03f5938efc80)）

- 对集合的渲染可以缓存，而且可以一次获取多个局部视图。（[拉取请求](https://github.com/rails/rails/pull/18948)，[提交](https://github.com/rails/rails/commit/e93f0f0f133717f9b06b1eaefd3442bd0ff43985)）

- 为显式依赖增加通配符匹配。（[拉取请求](https://github.com/rails/rails/pull/20904)）

- 把 `disable_with` 设为 `submit` 标签的默认行为。提交后禁用按钮能避免多次提交。（[拉取请求](https://github.com/rails/rails/pull/21135)）

- 局部模板的名称不再必须是有效的 Ruby 标识符。（[提交](https://github.com/rails/rails/commit/da9038e)）

- `datetime_tag` 辅助方法现在生成类型为 `datetime-local` 的 `input` 标签。（[拉取请求](https://github.com/rails/rails/pull/25469)）

Action Mailer
-------------

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-0-stable/actionmailer/CHANGELOG.md)。

### 删除

- 删除邮件视图中弃用的 `*_path` 辅助方法。（[提交](https://github.com/rails/rails/commit/d282125a18c1697a9b5bb775628a2db239142ac7)）

- 删除弃用的 `deliver` 和 `deliver!` 方法。（[提交](https://github.com/rails/rails/commit/755dcd0691f74079c24196135f89b917062b0715)）

### 重要变化

- 查找模板时会考虑默认的本地化设置和 I18n 后备机制。（[提交](https://github.com/rails/rails/commit/ecb1981b)）

- 为生成器创建的邮件程序添加 `_mailer` 后缀，让命名约定与控制器和作业相同。（[拉取请求](https://github.com/rails/rails/pull/18074)）

- 添加 `assert_enqueued_emails` 和 `assert_no_enqueued_emails`。（[拉取请求](https://github.com/rails/rails/pull/18403)）

- 添加 `config.action_mailer.deliver_later_queue_name` 选项，配置邮件程序队列的名称。（[拉取请求](https://github.com/rails/rails/pull/18587)）

- 支持片段缓存 Action Mailer 视图。新增 `config.action_mailer.perform_caching` 选项，设定是否缓存邮件模板。（[拉取请求](https://github.com/rails/rails/pull/22825)）

Active Record
-------------

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-0-stable/activerecord/CHANGELOG.md)。

### 删除

- 不再允许使用嵌套数组作为查询值。（[拉取请求](https://github.com/rails/rails/pull/17919)）

- 删除弃用的 `ActiveRecord::Tasks::DatabaseTasks#load_schema`，替换为 `ActiveRecord::Tasks::DatabaseTasks#load_schema_for`。（[提交](https://github.com/rails/rails/commit/ad783136d747f73329350b9bb5a5e17c8f8800da)）

- 删除弃用的 `serialized_attributes`。（[提交](https://github.com/rails/rails/commit/82043ab53cb186d59b1b3be06122861758f814b2)）

- 删除 `has_many :through` 弃用的自动计数器缓存。（[提交](https://github.com/rails/rails/commit/87c8ce340c6c83342df988df247e9035393ed7a0)）

- 删除弃用的 `sanitize_sql_hash_for_conditions`。（[提交](https://github.com/rails/rails/commit/3a59dd212315ebb9bae8338b98af259ac00bbef3)）

- 删除弃用的 `Reflection#source_macro`。（[提交](https://github.com/rails/rails/commit/ede8c199a85cfbb6457d5630ec1e285e5ec49313)）

- 删除弃用的 `symbolized_base_class` 和 `symbolized_sti_name`。（[提交](https://github.com/rails/rails/commit/9013e28e52eba3a6ffcede26f85df48d264b8951)）

- 删除弃用的 `ActiveRecord::Base.disable_implicit_join_references=`。（[提交](https://github.com/rails/rails/commit/0fbd1fc888ffb8cbe1191193bf86933110693dfc)）

- 不再允许使用字符串存取方法访问连接规范。（[提交](https://github.com/rails/rails/commit/efdc20f36ccc37afbb2705eb9acca76dd8aabd4f)）

- 不再预加载依赖实例的关联。（[提交](https://github.com/rails/rails/commit/4ed97979d14c5e92eb212b1a629da0a214084078)）

- PostgreSQL 值域不再排除下限。（[提交](https://github.com/rails/rails/commit/a076256d63f64d194b8f634890527a5ed2651115)）

- 删除通过缓存的 Arel 修改关系时的弃用消息。现在抛出 `ImmutableRelation` 异常。（[提交](https://github.com/rails/rails/commit/3ae98181433dda1b5e19910e107494762512a86c)）

- 从核心中删除 `ActiveRecord::Serialization::XmlSerializer`，提取到 [`activemodel-serializers-xml`](https://github.com/rails/activemodel-serializers-xml) gem 中。（[拉取请求](https://github.com/rails/rails/pull/21161)）

- 核心不再支持旧的 `mysql` 数据库适配器。多数用户应该使用 `mysql2`。找到维护人员后，会把对 `mysql` 的支持制成单独的 gem。（[拉取请求](https://github.com/rails/rails/pull/22642)，[拉取请求](https://github.com/rails/rails/pull/22715)）

- 不再支持 `protected_attributes` gem。（[提交](https://github.com/rails/rails/commit/f4fbc0301021f13ae05c8e941c8efc4ae351fdf9)）

- 不再支持低于 9.1 版的 PostgreSQL。（[拉取请求](https://github.com/rails/rails/pull/23434)）

- 不再支持 `activerecord-deprecated_finders` gem。（[提交](https://github.com/rails/rails/commit/78dab2a8569408658542e462a957ea5a35aa4679)）

- 删除 `ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES` 常量。（[提交](https://github.com/rails/rails/commit/a502703c3d2151d4d3b421b29fefdac5ad05df61)）

### 弃用

- 弃用在查询中把类作为值传递。应该传递字符串。（[拉取请求](https://github.com/rails/rails/pull/17916)）

- 弃用通过返回 `false` 停止 Active Record 回调链。建议的方式是 `throw(:abort)`。（[拉取请求](https://github.com/rails/rails/pull/17227)）

- 弃用 `ActiveRecord::Base.errors_in_transactional_callbacks=`。（[提交](https://github.com/rails/rails/commit/07d3d402341e81ada0214f2cb2be1da69eadfe72)）

- 弃用 `Relation#uniq`，换用 `Relation#distinct`。（[提交](https://github.com/rails/rails/commit/adfab2dcf4003ca564d78d4425566dd2d9cd8b4f)）

- 弃用 PostgreSQL 的 `:point` 类型，换成返回 `Point` 对象，而不是数组。（[拉取请求](https://github.com/rails/rails/pull/20448)）

- 弃用通过为关联方法传入一个真值参数强制重新加载关联。（[拉取请求](https://github.com/rails/rails/pull/20888)）

- 弃用关联的错误键 `restrict_dependent_destroy`，换成更好的键名。（[拉取请求](https://github.com/rails/rails/pull/20668)）

- `#tables` 的同步行为。（[拉取请求](https://github.com/rails/rails/pull/21601)）

- 弃用 `SchemaCache#tables`、`SchemaCache#table_exists?` 和 `SchemaCache#clear_table_cache!`，换成相应的数据源方法。（[拉取请求](https://github.com/rails/rails/pull/21715)）

- 弃用 SQLite3 和 MySQL 适配器的 `connection.tables`。（[拉取请求](https://github.com/rails/rails/pull/21601)）

- 弃用把参数传给 `#tables`：在某些适配器中（mysql2、sqlite3），它返回表和视图，而其他适配器（postgresql）只返回表。为了保持行为一致，未来 `#tables` 只返回表。（[拉取请求](https://github.com/rails/rails/pull/21601)）

- 弃用 `table_exists?` 方法：它既检查表，也检查视图。为了与 `#tables` 的行为一致，未来 `#table_exists?` 只检查表。（[拉取请求](https://github.com/rails/rails/pull/21601)）

- 弃用 `find_nth` 方法的 `offset` 参数。请在关系上使用 `offset` 方法。（[拉取请求](https://github.com/rails/rails/pull/22053)）

- 弃用 `DatabaseStatements` 中的 `{insert|update|delete}_sql`。换用公开方法 `{insert|update|delete}`。（[拉取请求](https://github.com/rails/rails/pull/23086)）

- 弃用 `use_transactional_fixtures`，换成更明确的 `use_transactional_tests`。（[拉取请求](https://github.com/rails/rails/pull/19282)）

- 弃用把一列传给 `ActiveRecord::Connection#quote`。（[提交](https://github.com/rails/rails/commit/7bb620869725ad6de603f6a5393ee17df13aa96c)）

- 为 `find_in_batches` 方法添加与 `start` 参数对应的 `end` 参数，指定在哪里停止批量处理。（[拉取请求](https://github.com/rails/rails/pull/12257)）

### 重要变化

- 创建表时为 `references` 添加 `foreign_key` 选项。（[提交](https://github.com/rails/rails/commit/99a6f9e60ea55924b44f894a16f8de0162cf2702)）

- 新的 Attributes API。（[提交](https://github.com/rails/rails/commit/8c752c7ac739d5a86d4136ab1e9d0142c4041e58)）

- 为 `enum` 添加 `:_prefix`/`:_suffix` 选项。（[拉取请求](https://github.com/rails/rails/pull/19813)，[拉取请求](https://github.com/rails/rails/pull/20999)）

- 为 `ActiveRecord::Relation` 添加 `#cache_key` 方法。（[拉取请求](https://github.com/rails/rails/pull/20884)）

- 把 `timestamps` 默认的 `null` 值改为 `false`。（[提交](https://github.com/rails/rails/commit/a939506f297b667291480f26fa32a373a18ae06a)）

- 添加 `ActiveRecord::SecureToken`，在模型中使用 `SecureRandom` 为属性生成唯一令牌。（[拉取请求](https://github.com/rails/rails/pull/18217)）

- 为 `drop_table` 添加 `:if_exists` 选项。（[拉取请求](https://github.com/rails/rails/pull/18597)）

- 添加 `ActiveRecord::Base#accessed_fields`，在模型中只从数据库中选择数据时快速查看读取哪些字段。（[提交](https://github.com/rails/rails/commit/be9b68038e83a617eb38c26147659162e4ac3d2c)）

- 为 `ActiveRecord::Relation` 添加 `#or` 方法，允许在 `WHERE` 或 `HAVING` 子句中使用 `OR` 运算符。（[提交](https://github.com/rails/rails/commit/b0b37942d729b6bdcd2e3178eda7fa1de203b3d0)）

- 添加 `ActiveRecord::Base.suppress`，禁止在指定的块执行时保存接收者。（[拉取请求](https://github.com/rails/rails/pull/18910)）

- 如果关联的对象不存在，`belongs_to` 现在默认触发验证错误。在具体的关联中可以通过 `optional: true` 选项禁止这一行为。因为添加了 `optional` 选项，所以弃用了 `required` 选项。（[拉取请求](https://github.com/rails/rails/pull/18937)）

- 添加 `config.active_record.dump_schemas` 选项，用于配置 `db:structure:dump` 的行为。（[拉取请求](https://github.com/rails/rails/pull/19347)）

- 添加 `config.active_record.warn_on_records_fetched_greater_than` 选项。（[拉取请求](https://github.com/rails/rails/pull/18846)）

- 为 MySQL 添加原生支持的 JSON 数据类型。（[拉取请求](https://github.com/rails/rails/pull/21110)）

- 支持在 PostgreSQL 中并发删除索引。（[拉取请求](https://github.com/rails/rails/pull/21317)）

- 为连接适配器添加 `#views` 和 `#view_exists?` 方法。（[拉取请求](https://github.com/rails/rails/pull/21609)）

- 添加 `ActiveRecord::Base.ignored_columns`，让一些列对 Active Record 不可见。（[拉取请求](https://github.com/rails/rails/pull/21720)）

- 添加 `connection.data_sources` 和 `connection.data_source_exists?`。这两个方法判断什么关系可以用于支持 Active Record 模型（通常是表和视图）。（[拉取请求](https://github.com/rails/rails/pull/21715)）

- 允许在 YAML 固件文件中设定模型类。（[拉取请求](https://github.com/rails/rails/pull/20574)）

- 生成数据库迁移时允许把 `uuid` 用作主键。（[拉取请求](https://github.com/rails/rails/pull/21762)）

- 添加 `ActiveRecord::Relation#left_joins` 和 `ActiveRecord::Relation#left_outer_joins`。（[拉取请求](https://github.com/rails/rails/pull/12071)）

- 添加 `after_{create,update,delete}_commit` 回调。（[拉取请求](https://github.com/rails/rails/pull/22516)）

- 为迁移类添加版本，这样便可以修改参数的默认值，而不破坏现有的迁移，或者通过弃用循环强制重写。（[拉取请求](https://github.com/rails/rails/pull/21538)）

- 现在，`ApplicationRecord` 是应用中所有模型的超类，这与控制器一样，控制器是 `ApplicationController` 的子类，而不是 `ActionController::Base`。因此，应用可以在一处全局配置模型的行为。（[拉取请求](https://github.com/rails/rails/pull/22567)）

- 添加 `#second_to_last` 和 `#third_to_last` 方法。（[拉取请求](https://github.com/rails/rails/pull/23583)）

- 允许通过存储在 PostgreSQL 和 MySQL 数据库元数据中的注释注解数据库对象。（[拉取请求](https://github.com/rails/rails/pull/22911)）

- 为 `mysql2` 适配器（0.4.4+）添加预处理语句支持。以前只支持弃用的 `mysql` 适配器。若想启用，在 `config/database.yml` 中设定 `prepared_statements: true`。（[拉取请求](https://github.com/rails/rails/pull/23461)）

- 允许在关系对象上调用 `ActionRecord::Relation#update`，在关系涉及的所有对象上运行回调。（[拉取请求](https://github.com/rails/rails/pull/11898)）

- 为 `save` 方法添加 `:touch` 选项，允许保存记录时不更新时间戳。（[拉取请求](https://github.com/rails/rails/pull/18225)）

- 为 PostgreSQL 添加表达式索引和运算符类支持。（[提交](https://github.com/rails/rails/commit/edc2b7718725016e988089b5fb6d6fb9d6e16882)）

- 添加 `:index_errors` 选项，为嵌套属性的错误添加索引。（[拉取请求](https://github.com/rails/rails/pull/19686)）

- 添加对双向销毁依赖的支持。（[拉取请求](https://github.com/rails/rails/pull/18548)）

- 支持在事务型测试中使用 `after_commit` 回调。（[拉取请求](https://github.com/rails/rails/pull/18662)）

- 添加 `foreign_key_exists?` 方法，检查表中是否有外键。（[拉取请求](https://github.com/rails/rails/pull/18662)）

- 为 `touch` 方法添加 `:time` 选项，使用当前时间之外的时间更新记录的时间戳。（[拉取请求](https://github.com/rails/rails/pull/18956)）

Active Model
------------

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-0-stable/activemodel/CHANGELOG.md)。

### 删除

- 删除弃用的 `ActiveModel::Dirty#reset_#{attribute}` 和 `ActiveModel::Dirty#reset_changes`。（[拉取请求](https://github.com/rails/rails/commit/37175a24bd508e2983247ec5d011d57df836c743)）

- 删除 XML 序列化，提取到 [`activemodel-serializers-xml`](https://github.com/rails/activemodel-serializers-xml) gem 中。（[拉取请求](https://github.com/rails/rails/pull/21161)）

- 删除 `ActionController::ModelNaming` 模块。（[拉取请求](https://github.com/rails/rails/pull/18194)）

### 弃用

- 弃用通过返回 `false` 停止 Active Model 和 `ActiveModel::Validations` 回调链的方式。推荐的方式是 `throw(:abort)`。（[拉取请求](https://github.com/rails/rails/pull/17227)）

- 弃用行为不一致的 `ActiveModel::Errors#get`、`ActiveModel::Errors#set` 和 `ActiveModel::Errors#[]=` 方法。（[拉取请求](https://github.com/rails/rails/pull/18634)）

- 弃用 `validates_length_of` 的 `:tokenizer` 选项，换成普通的 Ruby。（[拉取请求](https://github.com/rails/rails/pull/19585)）

- 弃用 `ActiveModel::Errors#add_on_empty` 和 `ActiveModel::Errors#add_on_blank`，而且没有替代方法。（[拉取请求](https://github.com/rails/rails/pull/18996)）

### 重要变化

- 添加 `ActiveModel::Errors#details`，判断哪个验证失败。（[拉取请求](https://github.com/rails/rails/pull/18322)）

- 把 `ActiveRecord::AttributeAssignment` 提取为 `ActiveModel::AttributeAssignment`，以便把任意对象作为引入的模块使用。（[拉取请求](https://github.com/rails/rails/pull/10776)）

- 添加 `ActiveModel::Dirty#[attr_name]_previously_changed?` 和 `ActiveModel::Dirty#[attr_name]_previous_change`，更好地访问保存模型后有变的记录。（[拉取请求](https://github.com/rails/rails/pull/19847)）

- 让 `valid?` 和 `invalid?` 一次验证多个上下文。（[拉取请求](https://github.com/rails/rails/pull/21069)）

- 让 `validates_acceptance_of` 除了 `1` 之外接受 `true` 为默认值。（[拉取请求](https://github.com/rails/rails/pull/18439)）

Active Job
----------

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-0-stable/activejob/CHANGELOG.md)。

### 重要变化

- `ActiveJob::Base.deserialize` 委托给作业类，以便序列化作业时依附任意元数据，并在执行时读取。（[拉取请求](https://github.com/rails/rails/pull/18260)）

- 允许在单个作业中配置队列适配器，防止相互影响。（[拉取请求](https://github.com/rails/rails/pull/16992)）

- 生成的作业现在默认继承自 `app/jobs/application_job.rb`。（[拉取请求](https://github.com/rails/rails/pull/19034)）

- 允许 `DelayedJob`、`Sidekiq`、`qu`、`que` 和 `queue_classic` 把作业 ID 报给 `ActiveJob::Base`，通过 `provider_job_id` 获取。（[拉取请求](https://github.com/rails/rails/pull/20064)，[拉取请求](https://github.com/rails/rails/pull/20056)，[提交](https://github.com/rails/rails/commit/68e3279163d06e6b04e043f91c9470e9259bbbe0)）

- 实现一个简单的 `AsyncJob` 处理程序和相关的 `AsyncAdapter`，把作业队列放入一个 `concurrent-ruby` 线程池。（[拉取请求](https://github.com/rails/rails/pull/21257)）

- 把默认的适配器由 inline 改为 async。这是更好的默认值，因为测试不会错误地依赖同步行为。（[提交](https://github.com/rails/rails/commit/625baa69d14881ac49ba2e5c7d9cac4b222d7022)）

Active Support
--------------

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-0-stable/activesupport/CHANGELOG.md)。

### 删除

- 删除弃用的 `ActiveSupport::JSON::Encoding::CircularReferenceError`。（[提交](https://github.com/rails/rails/commit/d6e06ea8275cdc3f126f926ed9b5349fde374b10)）

- 删除弃用的 `ActiveSupport::JSON::Encoding.encode_big_decimal_as_string=` 和 `ActiveSupport::JSON::Encoding.encode_big_decimal_as_string` 方法。（[提交](https://github.com/rails/rails/commit/c8019c0611791b2716c6bed48ef8dcb177b7869c)）

- 删除弃用的 `ActiveSupport::SafeBuffer#prepend`。（[提交](https://github.com/rails/rails/commit/e1c8b9f688c56aaedac9466a4343df955b4a67ec)）

- 删除 `Kernel` 中弃用的方法：`silence_stderr`、`silence_stream`、`capture` 和 `quietly`。（[提交](https://github.com/rails/rails/commit/481e49c64f790e46f4aff3ed539ed227d2eb46cb)）

- 删除弃用的 `active_support/core_ext/big_decimal/yaml_conversions` 文件。（[提交](https://github.com/rails/rails/commit/98ea19925d6db642731741c3b91bd085fac92241)）

- 删除弃用的 `ActiveSupport::Cache::Store.instrument` 和 `ActiveSupport::Cache::Store.instrument=` 方法。（[提交](https://github.com/rails/rails/commit/a3ce6ca30ed0e77496c63781af596b149687b6d7)）

- 删除弃用的 `Class#superclass_delegating_accessor`，换用 `Class#class_attribute`。（[拉取请求](https://github.com/rails/rails/pull/16938)）

- 删除弃用的 `ThreadSafe::Cache`，换用 `Concurrent::Map`。（[拉取请求](https://github.com/rails/rails/pull/21679)）

- 删除 `Object#itself`，因为 Ruby 2.2 自带了。（[拉取请求](https://github.com/rails/rails/pull/18244)）

### 弃用

- 弃用 `MissingSourceFile`，换用 `LoadError`。（[提交](https://github.com/rails/rails/commit/734d97d2)）

- 弃用 `alias_method_chain`，换用 Ruby 2.0 引入的 `Module#prepend`。（[拉取请求](https://github.com/rails/rails/pull/19434)）

- 弃用 `ActiveSupport::Concurrency::Latch`，换用 concurrent-ruby 中的 `Concurrent::CountDownLatch`。（[拉取请求](https://github.com/rails/rails/pull/20866)）

- 弃用 `number_to_human_size` 的 `:prefix` 选项，而且没有替代选项。（[拉取请求](https://github.com/rails/rails/pull/21191)）

- 弃用 `Module#qualified_const_`，换用内置的 `Module#const_` 方法。（[拉取请求](https://github.com/rails/rails/pull/17845)）

- 弃用通过字符串定义回调。（[拉取请求](https://github.com/rails/rails/pull/22598)）

- 弃用 `ActiveSupport::Cache::Store#namespaced_key`、`ActiveSupport::Cache::MemCachedStore#escape_key` 和 `ActiveSupport::Cache::FileStore#key_file_path`，换用 `normalize_key`。（[拉取请求](https://github.com/rails/rails/pull/22215)，[提交](https://github.com/rails/rails/commit/a8f773b0)）

- 弃用 `ActiveSupport::Cache::LocaleCache#set_cache_value`，换用 `write_cache_value`。（[拉取请求](https://github.com/rails/rails/pull/22215)）

- 弃用 `assert_nothing_raised` 的参数。（[拉取请求](https://github.com/rails/rails/pull/23789)）

- 弃用 `Module.local_constants`，换用 `Module.constants(false)`。（[拉取请求](https://github.com/rails/rails/pull/23936)）

### 重要变化

- 为 `ActiveSupport::MessageVerifier` 添加 `#verified` 和 `#valid_message?` 方法。（[拉取请求](https://github.com/rails/rails/pull/17727)）

- 改变回调链停止的方式。现在停止回调链的推荐方式是明确使用 `throw(:abort)`。（[拉取请求](https://github.com/rails/rails/pull/17227)）

- 新增配置选项 `config.active_support.halt_callback_chains_on_return_false`，指定是否允许在前置回调中停止 ActiveRecord、ActiveModel 和 ActiveModel::Validations 回调链。（[拉取请求](https://github.com/rails/rails/pull/17227)）

- 把默认的测试顺序由 `:sorted` 改为 `:random`。（[提交](https://github.com/rails/rails/commit/5f777e4b5ee2e3e8e6fd0e2a208ec2a4d25a960d)）

- 为 `Date`、`Time` 和 `DateTime` 添加 `#on_weekend?`、`#on_weekday?`、`#next_weekday` 及 `#prev_weekday` 方法。（[拉取请求](https://github.com/rails/rails/pull/18335)，[拉取请求](https://github.com/rails/rails/pull/23687)）

- 为 `Date`、`Time` 和 `DateTime` 的 `#next_week` 和 `#prev_week` 方法添加 `same_time` 选项。（[拉取请求](https://github.com/rails/rails/pull/18335)）

- 为 `Date`、`Time` 和 `DateTime` 添加 `#yesterday` 和 `#tomorrow` 对应的 `#prev_day` 和 `#next_day` 方法。

- 添加 `SecureRandom.base58`，生成 base58 字符串。（[提交](https://github.com/rails/rails/commit/b1093977110f18ae0cafe56c3d99fc22a7d54d1b)）

- 为 `ActiveSupport::TestCase` 添加 `file_fixture`。这样更便于在测试用例中访问示例文件。（[拉取请求](https://github.com/rails/rails/pull/18658)）

- 为 `Enumerable` 和 `Array` 添加 `#without`，返回一个可枚举对象副本，但是不含指定的元素。（[拉取请求](https://github.com/rails/rails/pull/19157)）

- 添加 `ActiveSupport::ArrayInquirer` 和 `Array#inquiry`。（[拉取请求](https://github.com/rails/rails/pull/18939)）

- 添加 `ActiveSupport::TimeZone#strptime`，使用指定的时区解析时间。（[提交](https://github.com/rails/rails/commit/a5e507fa0b8180c3d97458a9b86c195e9857d8f6)）

- 受 `Integer#zero?` 启发，添加 `Integer#positive?` 和 `Integer#negative?`。（[提交](https://github.com/rails/rails/commit/e54277a45da3c86fecdfa930663d7692fd083daa)）

- 为 `ActiveSupport::OrderedOptions` 中的读值方法添加炸弹版本，如果没有值，抛出 `KeyError`。（[拉取请求](https://github.com/rails/rails/pull/20208)）

- 添加 `Time.days_in_year`，返回指定年份中的日数，如果没有参数，返回当前年份。（[提交](https://github.com/rails/rails/commit/2f4f4d2cf1e4c5a442459fc250daf66186d110fa)）

- 添加一个文件事件监视程序，异步监测应用源码、路由、本地化文件等的变化。（[拉取请求](https://github.com/rails/rails/pull/22254)）

- 添加 `thread_m`/`cattr_accessor`/`reader`/`writer` 方法，声明存活在各个线程中的类和模块变量。（[拉取请求](https://github.com/rails/rails/pull/22630)）

- 添加 `Array#second_to_last` 和 `Array#third_to_last` 方法。（[拉取请求](https://github.com/rails/rails/pull/23583)）

- 发布 `ActiveSupport::Executor` 和 `ActiveSupport::Reloader` API，允许组件和库管理并参与应用代码的执行以及应用重新加载过程。（[拉取请求](https://github.com/rails/rails/pull/23807)）

- `ActiveSupport::Duration` 现在支持使用和解析 ISO8601 格式。（[拉取请求](https://github.com/rails/rails/pull/16917)）

- 启用 `parse_json_times` 后，`ActiveSupport::JSON.decode` 支持解析 ISO8601 本地时间。（[拉取请求](https://github.com/rails/rails/pull/23011)）

- `ActiveSupport::JSON.decode` 现在解析日期字符串后返回 `Date` 对象。（[拉取请求](https://github.com/rails/rails/pull/23011)）

- 让 `TaggedLogging` 支持多次实例化日志记录器，避免共享标签。（[拉取请求](https://github.com/rails/rails/pull/9065)）

名誉榜
------

得益于[众多贡献者](http://contributors.rubyonrails.org/)，Rails 才能变得这么稳定和强健。向他们致敬！

NOTE: 英语原文还有 [Rails 4.2](http://guides.rubyonrails.org/4_2_release_notes.html)、[4.1](http://guides.rubyonrails.org/4_1_release_notes.html)、[4.0](http://guides.rubyonrails.org/4_0_release_notes.html) 等版本的发布记，由于版本旧，不再翻译，敬请谅解。——译者注
