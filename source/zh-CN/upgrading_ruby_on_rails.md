Ruby on Rails 升级指南
======================

本文说明把 Ruby on Rails 升级到新版本的步骤。各个版本的发布记中也有升级步骤。

一般建议
--------

计划升级现有项目之前，应该确定有升级的必要。你要考虑几个因素：对新功能的需求，难于支持旧代码，以及你的时间和技能，等等。

### 测试覆盖度

为了确保升级后应用依然能正常运行，最好的方式是具有足够的测试覆盖度。如果没有自动化测试保障应用，你就要自己花时间检查有变化的部分。对升级 Rails 来说，你要检查应用的每个功能。不要给自己找麻烦，在升级之前一定要保障有足够的测试覆盖度。

### 升级过程

升级 Rails 版本时，最好放慢脚步，一次升级一个小版本，充分利用弃用提醒。Rails 版本号的格式是“大版本.小版本.补丁版本”。大版本和小版本允许修改公开 API，因此可能导致你的应用出错。补丁版本只修正缺陷，不改变公开 API。

升级过程如下：

1.  编写测试，确保能通过。

2.  升级到当前版本的最新补丁版本。

3.  修正测试和弃用的功能。

4.  升级到下一个小版本的补丁版本。

重复上述过程，直到你所选的版本为止。每次升级版本都要修改 `Gemfile` 中的 Rails 版本号（以及其他需要升级的 gem），再运行 `bundle update`。然后，运行下文所述的 `update` 任务，更新配置文件。最后运行测试。

Rails 的所有版本在[这个页面](https://rubygems.org/gems/rails/versions)中列出。

### Ruby 版本

发布新版 Rails 时，一般会紧跟最新的 Ruby 版本：

- Rails 5 要求 Ruby 2.2.2 或以上版本

- Rails 4 建议使用 Ruby 2.0，要求 1.9.3 或以上版本

- Rails 3.2.x 是支持 Ruby 1.8.7 的最后一个版本

- Rails 3 及以上版本要求 Ruby 1.8.7 或以上版本。官方不再支持之前的 Ruby 版本，应该尽早升级。

TIP: Ruby 1.8.7 p248 和 p249 有一些缺陷，会导致 Rails 崩溃。 Ruby Enterprise Edition 1.8.7-2010.02 修正了这些缺陷。对 1.9 系列来说，1.9.1 完全不能用，因此如果你使用 1.9.x 的话，应该直接跳到 1.9.3。

### `update` 任务

Rails 提供了 `app:update` 任务（4.2 及之前的版本是 `rails:update`）。更新 `Gemfile` 中的 Rails 版本号之后，运行这个任务。这个任务在交互式会话中协助你创建新文件和修改旧文件。

```sh
$ rails app:update
   identical  config/boot.rb
       exist  config
    conflict  config/routes.rb
Overwrite /myapp/config/routes.rb? (enter "h" for help) [Ynaqdh]
       force  config/routes.rb
    conflict  config/application.rb
Overwrite /myapp/config/application.rb? (enter "h" for help) [Ynaqdh]
       force  config/application.rb
    conflict  config/environment.rb
...
```

别忘了检查差异，以防有意料之外的改动。

从 Rails 4.2 升级到 5.0
-----------------------

Rails 5.0 的变动参见[发布记](5_0_release_notes.xml#ruby-on-rails-5-0-release-notes)。

### 要求 Ruby 2.2.2+

从 Ruby on Rails 5.0 开始，只支持 Ruby 2.2.2+。升级之前，确保你使用的是 Ruby 2.2.2 或以上版本。

### 现在 Active Record 模型默认继承自 ApplicationRecord

在 Rails 4.2 中，Active Record 模型继承自 `ActiveRecord::Base`。在 Rails 5.0 中，所有模型继承自 `ApplicationRecord`。

现在，`ApplicationRecord` 是应用中所有模型的超类，而不是 `ActionController::Base`，这样结构就与 `ApplicationController` 一样了，因此可以在一个地方为应用中的所有模型配置行为。

从 Rails 4.2 升级到 5.0 时，要在 `app/models/` 目录中创建 `application_record.rb` 文件，写入下述内容：

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
```

然后让所有模型继承它。

### 通过 `throw(:abort)` 停止回调链

在 Rails 4.2 中，如果 Active Record 和 Active Model 中的一个前置回调返回 `false`，整个回调链停止。也就是说，后续前置回调不会执行，回调中的操作也不执行。

在 Rails 5.0 中，Active Record 和 Active Model 中的前置回调返回 `false` 时不再停止回调链。如果想停止，要调用 `throw(:abort)`。

从 Rails 4.2 升级到 5.0 时，返回 `false` 的前置回调依然会停止回调链，但是你会收到一个弃用提醒，告诉你未来会像前文所述那样变化。

准备妥当之后，可以在 `config/application.rb` 文件中添加下述配置，启用新的行为（弃用消息不再显示）：

```ruby
ActiveSupport.halt_callback_chains_on_return_false = false
```

注意，这个选项不影响 Active Support 回调，因为不管返回什么值，这种回调链都不停止。

详情参见 [\#17227 工单](https://github.com/rails/rails/pull/17227)。

### 现在 ActiveJob 默认继承自 ApplicationJob

在 Rails 4.2 中，Active Job 类继承自 `ActiveJob::Base`。在 Rails 5.0 中，这一行为变了，现在继承自 `ApplicationJob`。

从 Rails 4.2 升级到 5.0 时，要在 `app/jobs/` 目录中创建 `application_job.rb` 文件，写入下述内容：

```ruby
class ApplicationJob < ActiveJob::Base
end
```

然后让所有作业类继承它。

详情参见 [\#19034 工单](https://github.com/rails/rails/pull/19034)。

### Rails 控制器测试

`assigns` 和 `assert_template` 提取到 `rails-controller-testing` gem 中了。如果想继续在控制器测试中使用这两个方法，把 `gem 'rails-controller-testing'` 添加到 `Gemfile` 中。

如果使用 RSpec 做测试，还要做些配置，详情参见这个 gem 的文档。

### 在生产环境启动后不再自动加载

现在，在生产环境启动后默认不再自动加载。

及早加载发生在应用的启动过程中，因此顶层常量不受影响，依然能自动加载，无需引入相应的文件。

层级较深的常量与常规的代码定义体一样，只在运行时执行，因此也不受影响，因为定义它们的文件在启动过程中及早加载了。

针对这一变化，大多数应用都无需改动。在少有的情况下，如果生产环境需要自动加载，把 `Rails.application.config.enable_dependency_loading` 设为 `true`。

### XML 序列化

`ActiveModel::Serializers::Xml` 从 Rails 中提取出来，变成 `activemodel-serializers-xml` gem 了。如果想继续在应用中使用 XML 序列化，把 `gem 'activemodel-serializers-xml'` 添加到 `Gemfile` 中。

### 不再支持旧的 `mysql` 数据库适配器

Rails 5 不再支持旧的 `mysql` 数据库适配器。多数用户应该换用 `mysql2`。找到维护人员之后，会作为一个单独的 gem 发布。

### 不再支持 debugger

Rails 5 要求的 Ruby 2.2 不支持 `debugger`。换用 `byebug`。

### 使用 bin/rails 运行任务和测试

Rails 5 支持使用 `bin/rails` 运行任务和测试。一般来说，还有相应的 rake 任务，但有些完全移过来了。

新的测试运行程序使用 `bin/rails test` 运行。

`rake dev:cache` 现在变成了 `rails dev:cache`。

执行 `bin/rails` 命令查看所有可用的命令。

### `ActionController::Parameters` 不再继承自 `HashWithIndifferentAccess`

现在，应用中的 `params` 不再返回散列。如果已经在参数上调用了 `permit`，无需做任何修改。如果使用 `slice` 及其他需要读取散列的方法，而不管是否调用了 `permitted?`，需要更新应用，首先调用 `permit`，然后转换成散列。

```ruby
params.permit([:proceed_to, :return_to]).to_h
```

### `protect_from_forgery` 的选项现在默认为 `prepend: false`

`protect_from_forgery` 的选项现在默认为 `prepend: false`，这意味着，在应用中调用 `protect_from_forgery` 时，会插入回调链。如果始终想让 `protect_from_forgery` 先运行，应该修改应用，使用 `protect_from_forgery prepend: true`。

### 默认的模板处理程序现在是 raw

文件扩展名中没有模板处理程序的，现在使用 raw 处理程序。以前，Rails 使用 ERB 模板处理程序渲染这种文件。

如果不想让 raw 处理程序处理文件，应该添加文件扩展名，让相应的模板处理程序解析。

### 为模板依赖添加通配符匹配

现在可以使用通配符匹配模板依赖。例如，如果像下面这样定义模板：

```erb
<% # Template Dependency: recordings/threads/events/subscribers_changed %>
<% # Template Dependency: recordings/threads/events/completed %>
<% # Template Dependency: recordings/threads/events/uncompleted %>
```

现在可以使用通配符一次调用所有依赖：

```erb
<% # Template Dependency: recordings/threads/events/* %>
```

### 不再支持 `protected_attributes` gem

Rails 5 不再支持 `protected_attributes` gem。

### 不再支持 `activerecord-deprecated_finders` gem

Rails 5 不再支持 `activerecord-deprecated_finders` gem。

### `ActiveSupport::TestCase` 现在默认随机运行测试

应用中的测试现在默认的运行顺序是 `:random`，不再是 `:sorted`。如果想改回 `:sorted`，使用下述配置选项：

```ruby
# config/environments/test.rb
Rails.application.configure do
  config.active_support.test_order = :sorted
end
```

### `ActionController::Live` 变为一个 `Concern`

如果在引入控制器的模块中引入了 `ActionController::Live`，还应该使用 `ActiveSupport::Concern` 扩展模块。或者，也可以使用 `self.included` 钩子在引入 `StreamingSupport` 之后直接把 `ActionController::Live` 引入控制器。

这意味着，如果应用有自己的流模块，下述代码在生产环境不可用：

```ruby
# This is a work-around for streamed controllers performing authentication with Warden/Devise.
# See https://github.com/plataformatec/devise/issues/2332
# Authenticating in the router is another solution as suggested in that issue
class StreamingSupport
  include ActionController::Live # this won't work in production for Rails 5
  # extend ActiveSupport::Concern # unless you uncomment this line.

  def process(name)
    super(name)
  rescue ArgumentError => e
    if e.message == 'uncaught throw :warden'
      throw :warden
    else
      raise e
    end
  end
end
```

### 框架的新默认值

#### Active Record `belongs_to_required_by_default` 选项

如果关联不存在，`belongs_to` 现在默认触发验证错误。

这一行为可在具体的关联中使用 `optional: true` 选项禁用。

新应用默认自动配置这一行为。如果现有项目想使用这一特性，可以在初始化脚本中启用：

```ruby
config.active_record.belongs_to_required_by_default = true
```

#### 每个表单都有自己的 CSRF 令牌

现在，Rails 5 支持每个表单有自己的 CSRF 令牌，从而降低 JavaScript 创建的表单遭受代码注入攻击的风险。启用这个选项后，应用中的表单都有自己的 CSRF 令牌，专门针对那个表单的动作和方法。

```ruby
config.action_controller.per_form_csrf_tokens = true
```

#### 伪造保护检查源

现在，可以配置应用检查 HTTP `Origin` 首部和网站的源，增加一道 CSRF 防线。把下述配置选项设为 `true`：

```ruby
config.action_controller.forgery_protection_origin_check = true
```

#### 允许配置 Action Mailer 队列的名称

默认的邮件程序队列名为 `mailers`。这个配置选项允许你全局修改队列名称。在配置文件中添加下述内容：

```ruby
config.action_mailer.deliver_later_queue_name = :new_queue_name
```

#### Action Mailer 视图支持片段缓存

在配置文件中设定 `config.action_mailer.perform_caching` 选项，决定是否让 Action Mailer 视图支持缓存。

```ruby
config.action_mailer.perform_caching = true
```

#### 配置 `db:structure:dump` 的输出

如果使用 `schema_search_path` 或者其他 PostgreSQL 扩展，可以控制如何转储数据库模式。设为 `:all` 生成全部转储，设为 `:schema_search_path` 从模式搜索路径中生成转储。

```ruby
config.active_record.dump_schemas = :all
```

#### 配置 SSL 选项为子域名启用 HSTS

在配置文件中设定下述选项，为子域名启用 HSTS：

```ruby
config.ssl_options = { hsts: { subdomains: true } }
```

#### 保留接收者的时区

使用 Ruby 2.4 时，调用 `to_time` 时可以保留接收者的时区：

```ruby
ActiveSupport.to_time_preserves_timezone = false
```

从 Rails 4.1 升级到 4.2
-----------------------

### Web Console

首先，把 `gem 'web-console', '~> 2.0'` 添加到 `Gemfile` 的 `:development` 组里（升级时不含这个 gem），然后执行 `bundle install` 命令。安装好之后，可以在任何想使用 Web Console 的视图里调用辅助方法 `<%= console %>`。开发环境的错误页面中也有 Web Console。

### `responders` gem

`respond_with` 实例方法和 `respond_to` 类方法已经提取到 `responders` gem 中。如果想使用这两个方法，只需把 `gem 'responders', '~> 2.0'` 添加到 `Gemfile` 中。如果依赖中没有 `responders` gem，无法调用二者。

```ruby
# app/controllers/users_controller.rb

class UsersController < ApplicationController
  respond_to :html, :json

  def show
    @user = User.find(params[:id])
    respond_with @user
  end
end
```

`respond_to` 实例方法不受影响，无需添加额外的 gem：

```ruby
# app/controllers/users_controller.rb

class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end
end
```

详情参见 [\#16526 工单](https://github.com/rails/rails/pull/16526)。

### 事务回调中的错误处理

目前，Active Record 压制 `after_rollback` 或 `after_commit` 回调抛出的错误，只将其输出到日志里。在下一版中，这些错误不再得到压制，而像其他 Active Record 回调一样正常冒泡。

你定义的 `after_rollback` 或 `after_commit` 回调会收到一个弃用提醒，说明这一变化。如果你做好了迎接新行为的准备，可以在 `config/application.rb` 文件中添加下述配置，不再发出弃用提醒：

```ruby
config.active_record.raise_in_transactional_callbacks = true
```

详情参见 [\#14488](https://github.com/rails/rails/pull/14488) 和 [\#16537 工单](https://github.com/rails/rails/pull/16537)。

### 测试用例的运行顺序

在 Rails 5.0 中，测试用例将默认以随机顺序运行。为了抢先使用这一个改变，Rails 4.2 引入了一个新配置选项，即 `active_support.test_order`，用于指定测试的运行顺序。你可以将其设为 `:sorted`，继续使用目前的行为，或者设为 `:random`，使用未来的行为。

如果不为这个选项设定一个值，Rails 会发出弃用提醒。如果不想看到弃用提醒，在测试环境的配置文件中添加下面这行：

```ruby
# config/environments/test.rb
Rails.application.configure do
  config.active_support.test_order = :sorted # 如果愿意，也可以设为 `:random`
end
```

### 序列化的属性

使用定制的编码器时（如 `serialize :metadata, JSON`），如果把 `nil` 赋值给序列化的属性，存入数据库中的值是 `NULL`，而不是通过编码器传递的 `nil` 值（例如，使用 `JSON` 编码器时的 `"null"`）。

### 生产环境的日志等级

Rails 5 将把生产环境的默认日志等级改为 `:debug`（以前是 `:info`）。若想继续使用目前的默认值，在 `production.rb` 文件中添加下面这行：

```ruby
# Set to `:info` to match the current default, or set to `:debug` to opt-into
# the future default.
config.log_level = :info
```

### 在 Rails 模板中使用 `after_bundle`

如果你的 Rails 模板把所有文件纳入版本控制，无法添加生成的 binstubs，因为模板在 Bundler 之前执行：

```ruby
# template.rb
generate(:scaffold, "person name:string")
route "root to: 'people#index'"
rake("db:migrate")

git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }
```

现在，你可以把 `git` 调用放在 `after_bundle` 块中，在生成 binstubs 之后执行：

```ruby
# template.rb
generate(:scaffold, "person name:string")
route "root to: 'people#index'"
rake("db:migrate")

after_bundle do
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
```

### rails-html-sanitizer

现在，净化应用中的 HTML 片段有了新的选择。古老的 html-scanner 方式正式弃用，换成了 [rails-html-sanitizer](https://github.com/rails/rails-html-sanitizer)。

因此，`sanitize`、`sanitize_css`、`strip_tags` 和 `strip_links` 等方法现在有了新的实现方式。

新的净化程序内部使用 [Loofah](https://github.com/flavorjones/loofah)，而它使用 Nokogiri。Nokogiri 包装了使用 C 和 Java 编写的 XML 解析器，因此不管使用哪个 Ruby 版本，净化的过程应该都很快。

新版本更新了 `sanitize`，它接受一个 `Loofah::Scrubber` 对象，提供强有力的清洗功能。清洗程序的示例参见[这里](https://github.com/flavorjones/loofah#loofahscrubber)。

此外，还添加了两个新清洗程序：`PermitScrubber` 和 `TargetScrubber`。详情参阅 [`rails-html-sanitizer` gem 的自述文件](https://github.com/rails/rails-html-sanitizer#rails-html-sanitizers)。

`PermitScrubber` 和 `TargetScrubber` 的文档说明了如何完全控制何时以及如何剔除元素。

如果应用想使用旧的净化程序，把 `rails-deprecated_sanitizer` 添加到 `Gemfile` 中：

```ruby
gem 'rails-deprecated_sanitizer'
```

### Rails DOM 测试

`TagAssertions` 模块（包含 `assert_tag` 等方法）已经弃用，换成了 `SelectorAssertions` 模块的 `assert_select` 方法。新的方法提取到 [`rails-dom-testing`](https://github.com/rails/rails-dom-testing) gem 中了。

### 遮蔽真伪令牌

为了防范 SSL 攻击，`form_authenticity_token` 现在做了遮蔽，每次请求都不同。因此，验证令牌时先解除遮蔽，然后再解密。所以，验证非 Rails 表单发送的，而且依赖静态会话 CSRF 令牌的请求时，要考虑这一点。

### Action Mailer

以前，在邮件程序类上调用邮件程序方法会直接执行相应的实例方法。引入 Active Job 和 `#deliver_later` 之后，情况变了。在 Rails 4.2 中，实例方法延后到调用 `deliver_now` 或 `deliver_later` 时才执行。例如：

```ruby
class Notifier < ActionMailer::Base
  def notify(user, ...)
    puts "Called"
    mail(to: user.email, ...)
  end
end

mail = Notifier.notify(user, ...) # 此时 Notifier#notify 还未执行
mail = mail.deliver_now           # 打印“Called”
```

对大多数应用来说，这不会导致明显的差别。然而，如果非邮件程序方法要同步执行，而以前依靠同步代理行为的话，应该将其定义为邮件程序类的类方法：

```ruby
class Notifier < ActionMailer::Base
  def self.broadcast_notifications(users, ...)
    users.each { |user| Notifier.notify(user, ...) }
  end
end
```

### 支持外键

迁移 DSL 做了扩充，支持定义外键。如果你以前使用 foreigner gem，可以考虑把它删掉了。注意，Rails 对外键的支持没有 foreigner 全面。这意味着，不是每一个 foreigner 定义都可以完全替换成 Rails 中相应的迁移 DSL。

替换的过程如下：

1.  从 `Gemfile` 中删除 `gem "foreigner"`。

2.  执行 `bundle install` 命令。

3.  执行 `bin/rake db:schema:dump` 命令。

4.  确保 `db/schema.rb` 文件中包含每一个外键定义，而且有所需的选项。

从 Rails 4.0 升级到 4.1
-----------------------

### 保护远程 `<script>` 标签免受 CSRF 攻击

或者“我的测试为什么失败了！？”“我的 `<script>` 小部件不能用了！！！”

现在，跨站请求伪造（Cross-site request forgery，CSRF）涵盖获取 JavaScript 响应的 GET 请求。这样能防止第三方网站通过 `<script>` 标签引用你的 JavaScript，获取敏感数据。

因此，使用下述代码的功能测试和集成测试现在会触发 CSRF 保护：

```ruby
get :index, format: :js
```

换成下述代码，明确测试 `XmlHttpRequest`：

```ruby
xhr :get, :index, format: :js
```

注意，站内的 `<script>` 标签也认为是跨源的，因此默认被阻拦。如果确实想使用 `<script>` 加载 JavaScript，必须在动作中明确指明跳过 CSRF 保护。

### Spring

如果想使用 Spring 预加载应用，要这么做：

1.  把 `gem 'spring', group: :development` 添加到 `Gemfile` 中。

2.  执行 `bundle install` 命令，安装 Spring。

3.  执行 `bundle exec spring binstub --all`，用 Spring 运行 binstub。

NOTE: 用户定义的 Rake 任务默认在开发环境中运行。如果想在其他环境中运行，查阅 [Spring 的自述文件](https://github.com/rails/spring#rake)。

### `config/secrets.yml`

若想使用新增的 `secrets.yml` 文件存储应用的机密信息，要这么做：

1.  在 `config` 文件夹中创建 `secrets.yml` 文件，写入下述内容：

    ``` yaml
    development:
      secret_key_base:

    test:
      secret_key_base:

    production:
      secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
    ```

2.  使用 `secret_token.rb` 初始化脚本中的 `secret_key_base` 设定 `SECRET_KEY_BASE` 环境变量，供生产环境中的用户使用。此外，还可以直接复制 `secret_key_base` 的值，把 `<%= ENV["SECRET_KEY_BASE"] %>` 替换掉。

3.  删除 `secret_token.rb` 初始化脚本。

4.  运行 `rake secret` 任务，为开发环境和测试环境生成密钥。

5.  重启服务器。

### 测试辅助方法的变化

如果测试辅助方法中有调用 `ActiveRecord::Migration.check_pending!`，可以将其删除了。现在，引入 `rails/test_help` 文件时会自动做此项检查，不过留着那一行代码也没什么危害。

### cookies 序列化程序

使用 Rails 4.1 之前的版本创建的应用使用 `Marshal` 序列化签名和加密的 cookie 值。若想使用新的基于 JSON 的格式，创建一个初始化脚本，写入下述内容：

```ruby
Rails.application.config.action_dispatch.cookies_serializer = :hybrid
```

这样便能平顺地从现在的 `Marshal` 序列化形式改成基于 JSON 的格式。

使用 `:json` 或 `:hybrid` 序列化程序时要注意，不是所有 Ruby 对象都能序列化成 JSON。例如，`Date` 和 `Time` 对象序列化成字符串，散列的键序列化成字符串。

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

建议只在 cookie 中存储简单的数据（字符串和数字）。如果存储复杂的对象，在后续请求中读取 cookie 时要自己动手转换。

如果使用 cookie 会话存储器，`session` 和 `flash` 散列也是如此。

### 闪现消息结构的变化

闪现消息的键会[整形成字符串](https://github.com/rails/rails/commit/a668beffd64106a1e1fedb71cc25eaaa11baf0c1)，不过依然可以使用符号或字符串访问。迭代闪现消息时始终使用字符串键：

```ruby
flash["string"] = "a string"
flash[:symbol] = "a symbol"

# Rails < 4.1
flash.keys # => ["string", :symbol]

# Rails >= 4.1
flash.keys # => ["string", "symbol"]
```

一定要使用字符串比较闪现消息的键。

### JSON 处理方式的变化

Rails 4.1 对 JSON 的处理方式做了几项修改。

#### 删除 MultiJSON

[MultiJSON 结束历史使命](https://github.com/rails/rails/pull/10576)，Rails 把它删除了。

如果你的应用现在直接依赖 MultiJSON，有几种解决方法：

1.  把 `multi_json` gem 添加到 `Gemfile` 中。注意，未来这种方法可能失效。

2.  摒除 MultiJSON，换用 `obj.to_json` 和 `JSON.parse(str)`。

WARNING: 不要直接把 `MultiJson.dump` 和 `MultiJson.load` 换成 `JSON.dump` 和 `JSON.load`。这两个 JSON gem API 的作用是序列化和反序列化任意的 Ruby 对象，一般[不安全](http://www.ruby-doc.org/stdlib-2.2.2/libdoc/json/rdoc/JSON.html#method-i-load)。

#### JSON gem 的兼容性

由于历史原因，Rails 有些 JSON gem 的兼容性问题。在 Rails 应用中使用 `JSON.generate` 和 `JSON.dump` 可能导致意料之外的错误。

Rails 4.1 修正了这些问题：在 JSON gem 之外提供了单独的编码器。JSON gem 的 API 现在能正常使用了，但是不能访问任何 Rails 专用的功能。例如：

```ruby
class FooBar
  def as_json(options = nil)
    { foo: 'bar' }
  end
end

>> FooBar.new.to_json # => "{\"foo\":\"bar\"}"
>> JSON.generate(FooBar.new, quirks_mode: true) # => "\"#<FooBar:0x007fa80a481610>\""
```

#### 新的 JSON 编码器

Rails 4.1 重写了 JSON 编码器，充分利用了 JSON gem。对多数应用来说，这一变化没有显著影响。然而，在重写的过程中从编码器中移除了下述功能：

1.  环形数据结构检测

2.  对 `encode_json` 钩子的支持

3.  把 `BigDecimal` 对象编码成数字而不是字符串的选项

如果你的应用依赖这些功能，可以把 [`activesupport-json_encoder`](https://github.com/rails/activesupport-json_encoder) gem 添加到 `Gemfile` 中。

#### 时间对象的 JSON 表述

在包含时间组件的对象（`Time`、`DateTime`、`ActiveSupport::TimeWithZone`）上调用 `#as_json`，现在返回值的默认精度是毫秒。如果想继续使用旧的行为，不含毫秒，在一个初始化脚本中设定下述选项：

```ruby
ActiveSupport::JSON::Encoding.time_precision = 0
```

### 行内回调块中 `return` 的用法

以前，Rails 允许在行内回调块中像下面这样使用 `return`：

```ruby
class ReadOnlyModel < ActiveRecord::Base
  before_save { return false } # BAD
end
```

这种行为一直没得到广泛支持。由于 `ActiveSupport::Callbacks` 内部的变化，Rails 4.1 不再允许这么做。如果在行内回调块中使用 `return`，执行回调时会抛出 `LocalJumpError` 异常。

使用 `return` 的行内回调块可以重构成求取返回值：

```ruby
class ReadOnlyModel < ActiveRecord::Base
  before_save { false } # GOOD
end
```

如果想使用 `return`，建议定义为方法：

```ruby
class ReadOnlyModel < ActiveRecord::Base
  before_save :before_save_callback # GOOD

  private
    def before_save_callback
      return false
    end
end
```

这一变化影响使用回调的多数地方，包括 Active Record 和 Active Model 回调，以及 Action Controller 的过滤器（如 `before_action`）。

详情参见[这个拉取请求](https://github.com/rails/rails/pull/13271)。

### Active Record 固件中定义的方法

Rails 4.1 在各自的上下文中处理各个固件中的 ERB，因此一个附件中定义的辅助方法，无法在另一个固件中使用。

在多个固件中使用的辅助方法应该在 `test_helper.rb` 文件的一个模块中定义，然后使用新的 `ActiveRecord::FixtureSet.context_class` 引入。

```ruby
module FixtureFileHelpers
  def file_sha(path)
    Digest::SHA2.hexdigest(File.read(Rails.root.join('test/fixtures', path)))
  end
end
ActiveRecord::FixtureSet.context_class.include FixtureFileHelpers
```

### i18n 强制检查可用的本地化

现在，Rails 4.1 默认把 i18n 的 `enforce_available_locales` 选项设为 `true`。这意味着，传给它的所有本地化都必须在 `available_locales` 列表中声明。

如果想禁用这一行为（让 i18n 接受任何本地化选项），在应用的配置文件中添加下述选项：

```ruby
config.i18n.enforce_available_locales = false
```

注意，这个选项是一项安全措施，为的是确保不把用户的输入作为本地化信息，除非这个信息之前是已知的。因此，除非有十足的原因，否则不建议禁用这个选项。

### 在 Relation 上调用的可变方法

`Relation` 不再提供可变方法，如 `#map!` 和 `#delete_if`。如果想使用这些方法，调用 `#to_a` 把它转换成数组。

这样改的目的是避免奇怪的缺陷，以及防止代码意图不明。

```ruby
# 现在不能这么写
Author.where(name: 'Hank Moody').compact!

# 要这么写
authors = Author.where(name: 'Hank Moody').to_a
authors.compact!
```

### 默认作用域的变化

默认作用域不再能够使用链式条件覆盖。

在之前的版本中，模型中的 `default_scope` 会被同一字段的链式条件覆盖。现在，与其他作用域一样，变成了合并。

以前：

```ruby
class User < ActiveRecord::Base
  default_scope { where state: 'pending' }
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.all
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending'

User.active
# SELECT "users".* FROM "users" WHERE "users"."state" = 'active'

User.where(state: 'inactive')
# SELECT "users".* FROM "users" WHERE "users"."state" = 'inactive'
```

现在：

```ruby
class User < ActiveRecord::Base
  default_scope { where state: 'pending' }
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.all
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending'

User.active
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending' AND "users"."state" = 'active'

User.where(state: 'inactive')
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending' AND "users"."state" = 'inactive'
```

如果想使用以前的行为，要使用 `unscoped`、`unscope`、`rewhere` 或 `except` 把 `default_scope` 定义的条件移除。

```ruby
class User < ActiveRecord::Base
  default_scope { where state: 'pending' }
  scope :active, -> { unscope(where: :state).where(state: 'active') }
  scope :inactive, -> { rewhere state: 'inactive' }
end

User.all
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending'

User.active
# SELECT "users".* FROM "users" WHERE "users"."state" = 'active'

User.inactive
# SELECT "users".* FROM "users" WHERE "users"."state" = 'inactive'
```

### 使用字符串渲染内容

Rails 4.1 为 `render` 引入了 `:plain`、`:html` 和 `:body` 选项。现在，建议使用这三个选项渲染字符串内容，因为这样可以指定响应的内容类型。

- `render :plain` 把内容类型设为 `text/plain`

- `render :html` 把内容类型设为 `text/html`

- `render :body` 不设定内容类型首部

从安全角度来看，如果响应主体中没有任何标记，应该使用 `render :plain`，因为多数浏览器会转义响应中不安全的内容。

未来的版本会弃用 `render :text`。所以，请开始使用更精准的 `:plain`、`:html` 和 `:body` 选项。使用 `render :text` 可能有安全风险，因为发送的内容类型是 `text/html`。

### PostgreSQL 的 json 和 hstore 数据类型

Rails 4.1 把 `json` 和 `hstore` 列映射成键为字符串的 Ruby 散列。之前的版本使用 `HashWithIndifferentAccess`。这意味着，不再支持使用符号访问。建立在 `json` 或 `hstore` 列之上的 `store_accessors` 也是如此。确保要始终使用字符串键。

### `ActiveSupport::Callbacks` 明确要求使用块

现在，Rails 4.1 明确要求调用 `ActiveSupport::Callbacks.set_callback` 时传入一个块。之所以这样要求，是因为 4.1 版大范围重写了 `ActiveSupport::Callbacks`。

```ruby
# Rails 4.0
set_callback :save, :around, ->(r, &block) { stuff; result = block.call; stuff }

# Rails 4.1
set_callback :save, :around, ->(r, block) { stuff; result = block.call; stuff }
```

从 Rails 3.2 升级到 4.0
-----------------------

如果你的应用目前使用的版本低于 3.2.x，应该先升级到 3.2，再升级到 4.0。

下述说明针对升级到 Rails 4.0。

### HTTP PATCH

现在，Rails 4.0 使用 `PATCH` 作为更新 REST 式资源（在 `config/routes.rb` 中声明）的主要 HTTP 动词。`update` 动作仍然在用，而且 `PUT` 请求继续交给 `update` 动作处理。因此，如果你只使用 REST 式路由，无需做任何修改。

```ruby
resources :users
```

```erb
<%= form_for @user do |f| %>
```

```ruby
class UsersController < ApplicationController
  def update
    # 无需修改，首选 PATCH，但是 PUT 依然能用
  end
end
```

然而，如果使用 `form_for` 更新资源，而且用的是使用 `PUT` HTTP 方法的自定义路由，要做修改：

```ruby
resources :users, do
  put :update_name, on: :member
end
```

```erb
<%= form_for [ :update_name, @user ] do |f| %>
```

```ruby
class UsersController < ApplicationController
  def update_name
    # 需要修改，因为 form_for 会尝试使用不存在的 PATCH 路由
  end
end
```

如果动作不在公开的 API 中，可以直接修改 HTTP 方法，把 `put` 路由改用 `patch`。

在 Rails 4 中，针对 `/users/:id` 的 `PUT` 请求交给 `update` 动作处理。因此，如果 API 使用 PUT 请求，依然能用。路由器也会把针对 `/users/:id` 的 `PATCH` 请求交给 `update` 动作处理。

```ruby
resources :users do
  patch :update_name, on: :member
end
```

如果动作在公开的 API 中，不能修改所用的 HTTP 方法，此时可以修改表单，让它使用 `PUT` 方法：

```erb
<%= form_for [ :update_name, @user ], method: :put do |f| %>
```

关于 `PATCH` 请求，以及为什么这样改，请阅读 Rails 博客中的[这篇文章](http://weblog.rubyonrails.org/2012/2/26/edge-rails-patch-is-the-new-primary-http-method-for-updates/)。

#### 关于媒体类型

`PATCH` 动词规范的勘误指出，[`PATCH` 请求应该使用“diff”媒体类型](http://www.rfc-editor.org/errata_search.php?rfc=5789)。[JSON Patch](http://tools.ietf.org/html/rfc6902) 就是这样的格式。虽然 Rails 原生不支持 JSON Patch，不过添加这一支持也不难：

```ruby
# 在控制器中
def update
  respond_to do |format|
    format.json do
      # 执行局部更新
      @article.update params[:article]
    end

    format.json_patch do
      # 执行复杂的更新
    end
  end
end

# 在 config/initializers/json_patch.rb 文件中
Mime::Type.register 'application/json-patch+json', :json_patch
```

JSON Patch 最近才收录到 RFC 中，因此还没有多少好的 Ruby 库。Aaron Patterson 开发的 [hana](https://github.com/tenderlove/hana) 是一个，但是没有支持规范最近的几项修改。

### Gemfile

Rails 4.0 删除了 `Gemfile` 的 `assets` 分组。升级时，要把那一行删除。此外，还要更新应用配置（`config/application.rb`）：

```ruby
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
```

### vendor/plugins

Rails 4.0 不再支持从 `vendor/plugins` 目录中加载插件。插件应该制成 gem，添加到 `Gemfile` 中。如果不想制成 gem，可以移到其他位置，例如 `lib/my_plugin/*`，然后添加相应的初始化脚本 `config/initializers/my_plugin.rb`。

### Active Record

- Rails 4.0 从 Active Record 中删除了标识映射（identity map），因为[与关联有些不一致](https://github.com/rails/rails/commit/302c912bf6bcd0fa200d964ec2dc4a44abe328a6)。如果你启动了这个功能，要把这个没有作用的配置删除：`config.active_record.identity_map`。

- 关联集合的 `delete` 方法的参数现在除了记录之外还可以使用 `Integer` 或 `String`，基本与 `destroy` 方法一样。以前，传入这样的参数时会抛出 `ActiveRecord::AssociationTypeMismatch` 异常。从 Rails 4.0 开始，`delete` 在删除记录之前会自动查找指定 ID 对应的记录。

- 在 Rails 4.0 中，如果修改了列或表的名称，相关的索引也会重命名。现在无需编写迁移重命名索引了。

- Rails 4.0 把 `serialized_attributes` 和 `attr_readonly` 改成只有类方法版本了。别再使用实例方法版本了，因为已经弃用。应该把实例方法版本改成类方法版本，例如把 `self.serialized_attributes` 改成 `self.class.serialized_attributes`。

- 使用默认的编码器时，把 `nil` 赋值给序列化的属性在数据库中保存的是 `NULL`，而不是通过 `YAML ("--- \n…​\n")` 传递 `nil` 值。

- Rails 4.0 删除了 `attr_accessible` 和 `attr_protected`，换成了健壮参数（strong parameter）。平滑升级可以使用 [`protected_attributes`](https://github.com/rails/protected_attributes) gem。

- 如果不使用 `protected_attributes` gem，可以把与它有关的选项都删除，例如 `whitelist_attributes` 或 `mass_assignment_sanitizer`。

- Rails 4.0 要求作用域使用可调用的对象，如 Proc 或 lambda：

    ``` ruby
    scope :active, where(active: true)

    # 变成
    scope :active, -> { where active: true }
    ```

- Rails 4.0 弃用了 `ActiveRecord::Fixtures`，改成了 `ActiveRecord::FixtureSet`。

- Rails 4.0 弃用了 `ActiveRecord::TestCase`，改成了 `ActiveSupport::TestCase`。

- Rails 4.0 弃用了以前基于散列的查找方法 API。这意味着，不能再给查找方法传入选项了。例如，`Book.find(:all, conditions: { name: '1984' })` 已经弃用，改成了 `Book.where(name: '1984')`。

- 除了 `find_by_…​` 和 `find_by_…​!`，其他动态查找方法都弃用了。新旧变化如下：

    -   `find_all_by_…​` 变成 `where(…​)`

    -   `find_last_by_…​` 变成 `where(…​).last`

    -   `scoped_by_…​` 变成 `where(…​)`

    -   `find_or_initialize_by_…​` 变成 `find_or_initialize_by(…​)`

    -   `find_or_create_by_…​` 变成 `find_or_create_by(…​)`

- 注意，`where(…​)` 返回一个关系，而不像旧的查找方法那样返回一个数组。如果需要使用数组，调用 `where(…​).to_a`。

- 等价的方法所执行的 SQL 语句可能与以前的实现不同。

- 如果想使用旧的查找方法，可以使用 [`activerecord-deprecated_finders`](https://github.com/rails/activerecord-deprecated_finders) gem。

- Rails 4.0 修改了 `has_and_belongs_to_many` 关联默认的联结表名，把第二个表名中的相同前缀去掉。现有的 `has_and_belongs_to_many` 关联，如果表名中有共用的前缀，要使用 `join_table` 选项指定。例如：

    ``` ruby
    CatalogCategory < ActiveRecord::Base
      has_and_belongs_to_many :catalog_products, join_table: 'catalog_categories_catalog_products'
    end

    CatalogProduct < ActiveRecord::Base
      has_and_belongs_to_many :catalog_categories, join_table: 'catalog_categories_catalog_products'
    end
    ```

- 注意，前缀含命名空间，因此 `Catalog::Category` 和 `Catalog::Product`，或者 `Catalog::Category` 和 `CatalogProduct` 之间的关联也要以同样的方式修改。

### Active Resource

Rails 4.0 把 Active Resource 提取出来，制成了单独的 gem。如果想继续使用这个功能，把 [`activeresource`](https://github.com/rails/activeresource) gem 添加到 `Gemfile` 中。

### Active Model

- Rails 4.0 修改了 `ActiveModel::Validations::ConfirmationValidator` 错误的依附方式。现在，如果二次确认验证失败，错误依附到 `:#{attribute}_confirmation` 上，而不是 `attribute`。

- Rails 4.0 把 `ActiveModel::Serializers::JSON.include_root_in_json` 的默认值改成 `false` 了。现在 Active Model 序列化程序和 Active Record 对象具有相同的默认行为。这意味着，可以把 `config/initializers/wrap_parameters.rb` 文件中的下述选项注释掉或删除：

    ``` ruby
    # Disable root element in JSON by default.
    # ActiveSupport.on_load(:active_record) do
    #   self.include_root_in_json = false
    # end
    ```

### Action Pack

- Rails 4.0 引入了 `ActiveSupport::KeyGenerator`，使用它生成和验证签名 cookie 等。Rails 3.x 生成的现有签名 cookie，如果有 `secret_token`，并且添加了 `secret_key_base`，会自动升级。

    ``` ruby
    # config/initializers/secret_token.rb
    Myapp::Application.config.secret_token = 'existing secret token'
    Myapp::Application.config.secret_key_base = 'new secret key base'
    ```

    注意，完全升级到 Rails 4.x，而且确定不再降级到 Rails 3.x之后再设定 `secret_key_base`。这是因为使用 Rails 4.x 中的新 `secret_key_base` 签名的 cookie 与 Rails 3.x 不兼容。你可以留着 `secret_token`，不设定新的 `secret_key_base`，把弃用消息忽略，等到完全升级好了再改。

    如果使用外部应用或 JavaScript 读取 Rails 应用的签名会话 cookie（或一般的签名 cookie），解耦之后才应该设定 `secret_key_base`。

- 如果设定了 `secret_key_base`，Rails 4.0 会加密基于 cookie 的会话内容。Rails 3.x 签名基于 cookie 的会话，但是不加密。签名的 cookie 是“安全的”，因为会确认是不是由应用生成的，无法篡改。然而，终端用户能看到内容，而加密后则无法查看，而且性能没有重大损失。

    改成加密会话 cookie 的详情参见 [\#9978 拉取请求](https://github.com/rails/rails/pull/9978)。

- Rails 4.0 删除了 `ActionController::Base.asset_path` 选项，改用 Asset Pipeline 功能。

- Rails 4.0 弃用了 `ActionController::Base.page_cache_extension` 选项，换成 `ActionController::Base.default_static_extension`。

- Rails 4.0 从 Action Pack 中删除了动作和页面缓存。如果想在控制器中使用 `caches_action`，要添加 `actionpack-action_caching` gem，想使用 `caches_page`，要添加 `actionpack-page_caching` gem。

- Rails 4.0 删除了 XML 参数解析器。若想使用，要添加 `actionpack-xml_parser` gem。

- Rails 4.0 修改了默认的 `layout` 查找集，使用返回 `nil` 的符号或 proc。如果不想使用布局，返回 `false`。

- Rails 4.0 把默认的 memcached 客户端由 `memcache-client` 改成了 `dalli`。若想升级，只需把 `gem 'dalli'` 添加到 `Gemfile` 中。

- Rails 4.0 弃用了控制器中的 `dom_id` 和 `dom_class` 方法（在视图中可以继续使用）。若想使用，要引入 `ActionView::RecordIdentifier` 模块。

- Rails 4.0 弃用了 `link_to` 辅助方法的 `:confirm` 选项。现在应该使用 `data` 属性（如 `data: { confirm: 'Are you sure?' }`）。基于这个辅助方法的辅助方法（如 `link_to_if` 或 `link_to_unless`）也受影响。

- Rails 4.0 改变了 `assert_generates`、`assert_recognizes` 和 `assert_routing` 的工作方式。现在，这三个断言抛出 `Assertion`，而不是 `ActionController::RoutingError`。

- 如果具名路由的名称有冲突，Rails 4.0 抛出 `ArgumentError`。自己定义具名路由，或者由 `resources` 生成都可能触发这一错误。下面两例中的 `example_path` 路由有冲突：

    ``` ruby
    get 'one' => 'test#example', as: :example
    get 'two' => 'test#example', as: :example

    resources :examples
    get 'clashing/:id' => 'test#example', as: :example
    ```

    在第一例中，可以为两个路由起不同的名称。在第二例中，可以使用 `resources` 方法提供的 `only` 或 `except` 选项，限制生成的路由。详情参见[路由指南](routing.html#限制所创建的路由)。

- Rails 4.0 还改变了含有 Unicode 字符的路由的处理方式。现在，可以直接在路由中使用 Unicode 字符。如果以前这样做过，要做修改。例如：

    ``` ruby
    get Rack::Utils.escape('こんにちは'), controller: 'welcome', action: 'index'
    ```

    要改成：

    ``` ruby
    get 'こんにちは', controller: 'welcome', action: 'index'
    ```

- Rails 4.0 要求使用 `match` 定义的路由必须指定请求方法。例如：

    ``` ruby
    # Rails 3.x
    match '/' => 'root#index'

    # 改成
    match '/' => 'root#index', via: :get

    # 或
    get '/' => 'root#index'
    ```

- Rails 4.0 删除了 `ActionDispatch::BestStandardsSupport` 中间件。根据[这篇文章](http://msdn.microsoft.com/en-us/library/jj676915(v=vs.85).aspx)，`<!DOCTYPE html>` 就能触发标准模式。此外，ChromeFrame 首部移到 `config.action_dispatch.default_headers` 中了。

    注意，还必须把对这个中间件的引用从应用的代码中删除，例如：

    ``` ruby
    # 抛出异常
    config.middleware.insert_before(Rack::Lock, ActionDispatch::BestStandardsSupport)
    ```

    此外，还要把环境配置中的 `config.action_dispatch.best_standards_support` 选项删除（如果有的话）。

- 在 Rails 4.0 中，预先编译好的静态资源不再自动从 `vendor/assets` 和 `lib/assets` 中复制 JS 和 CSS 之外的静态文件。Rails 应用和引擎开发者应该把静态资源文件放在 `app/assets` 目录中，或者配置 `config.assets.precompile` 选项。

- 在 Rails 4.0 中，如果动作无法处理请求的格式，抛出 `ActionController::UnknownFormat` 异常。默认情况下，这个异常的处理方式是返回“406 Not Acceptable”响应，不过现在可以覆盖。在 Rails 3 中始终返回“406 Not Acceptable”响应，不可覆盖。

- 在 Rails 4.0 中，如果 `ParamsParser` 无法解析请求参数，抛出 `ActionDispatch::ParamsParser::ParseError` 异常。你应该捕获这个异常，而不是具体的异常，如 `MultiJson::DecodeError`。

- 在 Rails 4.0 中，如果挂载引擎的 URL 有前缀，`SCRIPT_NAME` 能正确嵌套。现在不用设定 `default_url_options[:script_name]` 选项覆盖 URL 前缀了。

- Rails 4.0 弃用了 `ActionController::Integration`，改成了 `ActionDispatch::Integration`。

- Rails 4.0 弃用了 `ActionController::IntegrationTest`，改成了 `ActionDispatch::IntegrationTest`。

- Rails 4.0 弃用了 `ActionController::PerformanceTest`，改成了 `ActionDispatch::PerformanceTest`。

- Rails 4.0 弃用了 `ActionController::AbstractRequest`，改成了 `ActionDispatch::Request`。

- Rails 4.0 弃用了 `ActionController::Request`，改成了 `ActionDispatch::Request`。

- Rails 4.0 弃用了 `ActionController::AbstractResponse`，改成了 `ActionDispatch::Response`。

- Rails 4.0 弃用了 `ActionController::Response`，改成了 `ActionDispatch::Response`。

- Rails 4.0 弃用了 `ActionController::Routing`，改成了 `ActionDispatch::Routing`。

### Active Support

Rails 4.0 删除了 `ERB::Util#json_escape` 的别名 `j`，因为已经把它用作 `ActionView::Helpers::JavaScriptHelper#escape_javascript` 的别名。

### 辅助方法的加载顺序

Rails 4.0 改变了从不同目录中加载辅助方法的顺序。以前，先找到所有目录，然后按字母表顺序排序。升级到 Rails 4.0 之后，辅助方法的目录顺序依旧，只在各自的目录中按字母表顺序加载。如果没有使用 `helpers_path` 参数，这一变化只影响从引擎中加载辅助方法的方式。如果看重顺序，升级后应该检查辅助方法是否可用。如果想修改加载引擎的顺序，可以使用 `config.railties_order=` 方法。

### Active Record 观测器和 Action Controller 清洁器

`ActiveRecord::Observer` 和 `ActionController::Caching::Sweeper` 提取到 `rails-observers` gem 中了。如果要使用它们，要添加 `rails-observers` gem。

### sprockets-rails

- `assets:precompile:primary` 和 `assets:precompile:all` 删除了。改用 `assets:precompile`。

- `config.assets.compress` 选项要改成 `config.assets.js_compressor`，例如：

    ``` ruby
    config.assets.js_compressor = :uglifier
    ```

### sass-rails

- `asset-url` 不再接受两个参数。例如，`asset-url("rails.png", image)` 变成了 `asset-url("rails.png")`。

NOTE: [英语原文](http://guides.rubyonrails.org/upgrading_ruby_on_rails.html)还有从 Rails 3.0 升级到 3.1 及从 3.1 升级到 3.2 的说明，由于版本太旧，不再翻译，敬请谅解。——译者注
