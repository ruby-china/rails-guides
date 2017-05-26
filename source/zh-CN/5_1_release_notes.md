# Ruby on Rails 5.1 发布记

Rails 5.1 的重要变化：

*   支持 Yarn
*   支持 Webpack（可选）
*   jQuery 不再是默认的依赖
*   系统测试
*   机密信息加密
*   参数化邮件程序
*   direct 路由和 resolve 路由
*   `form_for` 和 `form_tag` 统一为 `form_with`

本文只涵盖重要变化。若想了解缺陷修正和具体变化，请查看更新日志或 GitHub 中 Rails 主仓库的[提交历史](https://github.com/rails/rails/commits/5-1-stable)。

-----------------------------------------------------------------------------

<a class="anchor" id="upgrading-to-rails-5-1"></a>

## 升级到 Rails 5.1

如果升级现有应用，在继续之前，最好确保有足够的测试覆盖度。如果尚未升级到 Rails 5.0，应该先升级到 5.0 版，确保应用能正常运行之后，再尝试升级到 Rails 5.1。升级时的注意事项参见 [从 Rails 5.0 升级到 5.1](upgrading_ruby_on_rails.html#upgrading-from-rails-5-0-to-rails-5-1)。

<a class="anchor" id="major-features"></a>

## 主要功能

<a class="anchor" id="yarn-support"></a>

### 支持 Yarn

[拉取请求](https://github.com/rails/rails/pull/26836)

Rails 5.1 支持使用 Yarn 管理通过 NPM 安装的 JavaScript 依赖。这样便于使用 NPM 中的 React、VueJS 等库。对 Yarn 的支持集成在 Asset Pipeline 中，因此所有依赖都能顺利在 Rails 5.1 应用中使用。

<a class="anchor" id="optional-webpack-support"></a>

### Webpack 支持（可选）

[拉取请求](https://github.com/rails/rails/pull/27288)

Rails 应用使用新开发的 [Webpacker](https://github.com/rails/webpacker) gem 可以轻易集成 JavaScript 静态资源打包工具 [Webpack](https://webpack.js.org/)。新建应用时指定 `--webpack` 参数可启用对 Webpack 的集成。

这与 Asset Pipeline 完全兼容，你可以继续使用 Asset Pipeline 管理图像、字体、音频等静态资源。甚至还可以使用 Asset Pipeline 管理部分 JavaScript 代码，使用 Webpack 管理其他代码。这些都由默认启用的 Yarn 管理。

<a class="anchor" id="jquery-no-longer-a-default-dependency"></a>

### jQuery 不再是默认的依赖

[拉取请求](https://github.com/rails/rails/pull/27113)

Rails 之前的版本默认需要 jQuery，因为要支持 `data-remote` 和 `data-confirm` 等功能，以及 Rails 提供的非侵入式 JavaScript。现在 jQuery 不再需要了，因为 UJS 使用纯 JavaScript 重写了。这个脚本现在通过 Action View  提供，名为 `rails-ujs`。

如果需要，可以继续使用 jQuery，但它不再是默认的依赖了。

<a class="anchor" id="system-tests"></a>

### 系统测试

[拉取请求](https://github.com/rails/rails/pull/26703)

Rails 5.1 内建对 Capybara 测试的支持，不过对外称为系统测试。你无需再担心配置 Capybara 和数据库清理策略。Rails 5.1 对这类测试做了包装，可以在 Chrome 运行相关测试，而且失败时还能截图。

<a class="anchor" id="encrypted-secrets"></a>

### 机密信息加密

[拉取请求](https://github.com/rails/rails/pull/28038)

受 [sekrets](https://github.com/ahoward/sekrets) gem 启发，Rails 现在以一种安全的方式管理应用中的机密信息。

运行 `bin/rails secrets:setup`，创建一个加密的机密信息文件。这个命令还会生成一个主密钥，必须把它放在仓库外部。机密信息已经加密，可以放心检入版本控制系统。

在生产环境中，Rails 会使用 `RAILS_MASTER_KEY` 环境变量或密钥文件中的密钥解密机密信息。

<a class="anchor" id="parameterized-mailers"></a>

### 参数化邮件程序

[拉取请求](https://github.com/rails/rails/pull/27825)

允许为一个邮件程序类中的所有方法指定通用的参数，方便共享实例变量、首部和其他数据。

```ruby
class InvitationsMailer < ApplicationMailer
  before_action { @inviter, @invitee = params[:inviter], params[:invitee] }
  before_action { @account = params[:inviter].account }

  def account_invitation
    mail subject: "#{@inviter.name} invited you to their Basecamp (#{@account.name})"
  end
end

InvitationsMailer.with(inviter: person_a, invitee: person_b)
                 .account_invitation.deliver_later
```

<a class="anchor" id="direct-resolved-routes"></a>

### direct 路由和 resolve 路由

[拉取请求](https://github.com/rails/rails/pull/23138)

Rails 5.1 为路由 DSL 增加了两个新方法：`resolve` 和 `direct`。前者用于定制模型的多态映射。

```ruby
resource :basket

resolve("Basket") { [:basket] }
```

```erb
<%= form_for @basket do |form| %>
  <!-- basket form -->
<% end %>
```

此时生成的 URL 是单数形式的 `/basket`，而不是往常的 `/baskets/:id`。

`direct` 用于创建自定义的 URL 辅助方法。

```ruby
direct(:homepage) { "http://www.rubyonrails.org" }
```

```irb
>> homepage_url
=> "http://www.rubyonrails.org"
```

块的返回值必须能用作 `url_for` 方法的参数。因此，可以传入有效的 URL 字符串、散列、数组、Active Model 实例或 Active Model 类。

```ruby
direct :commentable do |model|
  [ model, anchor: model.dom_id ]
end

direct :main do
  { controller: 'pages', action: 'index', subdomain: 'www' }
end
```

<a class="anchor" id="unification-of-form-for-and-form-tag-into-form-with"></a>

### `form_for` 和 `form_tag` 统一为 `form_with`

[拉取请求](https://github.com/rails/rails/pull/26976)

在 Rails 5.1 之前，处理 HTML 表单有两个接口：针对模型实例的 `form_for` 和针对自定义 URL 的 `form_tag`。

Rails 5.1 把这两个接口统一成 `form_with` 了，可以根据 URL、作用域或模型生成表单标签。

只使用 URL：

```erb
<%= form_with url: posts_path do |form| %>
  <%= form.text_field :title %>
<% end %>

<%# 生成的表单为 %>

<form action="/posts" method="post" data-remote="true">
  <input type="text" name="title">
</form>
```

指定作用域，添加到输入字段的名称前：

```erb
<%= form_with scope: :post, url: posts_path do |form| %>
  <%= form.text_field :title %>
<% end %>

<%# 生成的表单为 %>

<form action="/posts" method="post" data-remote="true">
  <input type="text" name="post[title]">
</form>
```

使用模型，从中推知 URL 和作用域：

```erb
<%= form_with model: Post.new do |form| %>
  <%= form.text_field :title %>
<% end %>

<%# 生成的表单为 %>

<form action="/posts" method="post" data-remote="true">
  <input type="text" name="post[title]">
</form>
```

现有模型的更新表单填有字段的值：

```erb
<%= form_with model: Post.first do |form| %>
  <%= form.text_field :title %>
<% end %>

<%# 生成的表单为 %>

<form action="/posts/1" method="post" data-remote="true">
  <input type="hidden" name="_method" value="patch">
  <input type="text" name="post[title]" value="<the title of the post>">
</form>
```

<a class="anchor" id="incompatibilities"></a>

## 不兼容的功能

下述变动需要立即采取行动。

<a class="anchor" id="transactional-tests-with-multiple-connections"></a>

### 使用多个连接的事务型测试

事务型测试现在把所有 Active Record 连接包装在数据库事务中。

如果测试派生额外的线程，而且线程获得了数据库连接，这些连接现在使用特殊的方式处理。

这些线程将共享一个连接，放在事务中。这样能确保所有线程看到的数据库状态是一样的，忽略最外层的事务。以前，额外的连接无法查看固件记录。

线程进入嵌套的事务时，为了维护隔离性，它会临时获得连接的专用权。

如果你的测试目前要在派生的线程中获得不在事务中的单独连接，需要直接管理连接。

如果测试派生线程，而线程与显式数据库事务交互，这一变化可能导致死锁。

若想避免这个新行为的影响，简单的方法是在受影响的测试用例上禁用事务型测试。

<a class="anchor" id="railties-5-1"></a>

## Railties

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-1-stable/railties/CHANGELOG.md)。

<a class="anchor" id="railties-removals-5-1"></a>

### 删除

*   删除弃用的 `config.static_cache_control`。（[提交](https://github.com/rails/rails/commit/c861decd44198f8d7d774ee6a74194d1ac1a5a13)）
*   删除弃用的 `config.serve_static_files`。（[提交](https://github.com/rails/rails/commit/0129ca2eeb6d5b2ea8c6e6be38eeb770fe45f1fa)）
*   删除弃用的 `rails/rack/debugger`。（[提交](https://github.com/rails/rails/commit/7563bf7b46e6f04e160d664e284a33052f9804b8)）
*   删除弃用的任务：`rails:update`，`rails:template`，`rails:template:copy`，`rails:update:configs` 和 `rails:update:bin`。（[提交](https://github.com/rails/rails/commit/f7782812f7e727178e4a743aa2874c078b722eef)）
*   删除 `routes` 任务弃用的 `CONTROLLER` 环境变量。（[提交](https://github.com/rails/rails/commit/f9ed83321ac1d1902578a0aacdfe55d3db754219)）
*   删除 `rails new` 命令的 `-j`（`--javascript`）选项。（[拉取请求](https://github.com/rails/rails/pull/28546)）

<a class="anchor" id="railties-notable-changes-5-1"></a>

### 重要变化

*   在 `config/secrets.yml` 中添加一部分，供所有环境使用。（[提交](https://github.com/rails/rails/commit/e530534265d2c32b5c5f772e81cb9002dcf5e9cf)）
*   `config/secrets.yml` 文件中的所有键现在都通过符号加载。（[拉取请求](https://github.com/rails/rails/pull/26929)）
*   从默认栈中删除 jquery-rails。Action View 提供的 rails-ujs 现在是默认的 UJS 适配器。（[拉取请求](https://github.com/rails/rails/pull/27113)）
*   为新应用添加 Yarn 支持，创建 yarn binstub 和 package.json。（[拉取请求](https://github.com/rails/rails/pull/26836)）
*   通过 `--webpack` 选项为新应用添加 Webpack 支持，相关功能由 rails/webpacker gem 提供。（[拉取请求](https://github.com/rails/rails/pull/27288)）
*   生成新应用时，如果没提供 `--skip-git` 选项，初始化 Git 仓库。（[拉取请求](https://github.com/rails/rails/pull/27632)）
*   在 `config/secrets.yml.enc` 文件中保存加密的机密信息。（[拉取请求](https://github.com/rails/rails/pull/28038)）
*   在 `rails initializers` 中显示 railtie 类名。（[拉取请求](https://github.com/rails/rails/pull/25257)）

<a class="anchor" id="action-cable-5-1"></a>

## Action Cable

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-1-stable/actioncable/CHANGELOG.md)。

<a class="anchor" id="action-cable-notable-changes-5-1"></a>

### 重要变化

*   允许在 `cable.yml` 中为 Redis 和事件型 Redis 适配器提供 `channel_prefix`，以防多个应用使用同一个 Redis 服务器时名称有冲突。（[拉取请求](https://github.com/rails/rails/pull/27425)）
*   添加 `ActiveSupport::Notifications` 钩子，用于广播数据。（[拉取请求](https://github.com/rails/rails/pull/24988)）

<a class="anchor" id="action-pack-5-1"></a>

## Action Pack

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-1-stable/actionpack/CHANGELOG.md)。

<a class="anchor" id="action-pack-removals-5-1"></a>

### 删除

*   `ActionDispatch::IntegrationTest` 和 `ActionController::TestCase` 类的 `#process`、`#get`、`#post`、`#patch`、`#put`、`#delete` 和 `#head` 等方法不再允许使用非关键字参数。（[提交](https://github.com/rails/rails/commit/98b8309569a326910a723f521911e54994b112fb)，[提交](https://github.com/rails/rails/commit/de9542acd56f60d281465a59eac11e15ca8b3323)）
*   删除弃用的 `ActionDispatch::Callbacks.to_prepare` 和 `ActionDispatch::Callbacks.to_cleanup`。（[提交](https://github.com/rails/rails/commit/3f2b7d60a52ffb2ad2d4fcf889c06b631db1946b)）
*   删除弃用的与控制器过滤器有关的方法。（[提交](https://github.com/rails/rails/commit/d7be30e8babf5e37a891522869e7b0191b79b757)）

<a class="anchor" id="action-pack-deprecations-5-1"></a>

### 弃用

*   弃用 `config.action_controller.raise_on_unfiltered_parameters`。在 Rails 5.1 中没有任何效果。（[提交](https://github.com/rails/rails/commit/c6640fb62b10db26004a998d2ece98baede509e5)）

<a class="anchor" id="action-pack-notable-changes-5-1"></a>

### 重要变化

*   为路由 DSL 增加 `direct` 和 `resolve` 方法。（[拉取请求](https://github.com/rails/rails/pull/23138)）
*   新增 `ActionDispatch::SystemTestCase` 类，用于编写应用的系统测试。（[拉取请求](https://github.com/rails/rails/pull/26703)）

<a class="anchor" id="action-view-5-1"></a>

## Action View

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-1-stable/actionview/CHANGELOG.md)。

<a class="anchor" id="action-view-removals-5-1"></a>

### 删除

*   删除 `ActionView::Template::Error` 中弃用的 `#original_exception` 方法。（[提交](https://github.com/rails/rails/commit/b9ba263e5aaa151808df058f5babfed016a1879f)）
*   删除 `strip_tags` 方法不恰当的 `encode_special_chars` 选项。（[拉取请求](https://github.com/rails/rails/pull/28061)）

<a class="anchor" id="action-view-deprecations-5-1"></a>

### 弃用

*   弃用 ERB 处理程序 Erubis，换成 Erubi。（[拉取请求](https://github.com/rails/rails/pull/27757)）

<a class="anchor" id="action-view-notable-changes-5-1"></a>

### 重要变化

*   原始模板处理程序（Rails 5 默认的模板处理程序）现在输出对 HTML 安全的字符串。（[提交](https://github.com/rails/rails/commit/1de0df86695f8fa2eeae6b8b46f9b53decfa6ec8)）
*   修改 `datetime_field` 和 `datetime_field_tag`，让它们生成 `datetime-local` 字段。（[拉取请求](https://github.com/rails/rails/pull/28061)）
*   新增 Builder 风格的 HTML 标签句法（`tag.div`、`tag.br`，等等）。（[拉取请求](https://github.com/rails/rails/pull/25543)）
*   添加 `form_with`，统一 `form_tag` 和 `form_for`。（[拉取请求](https://github.com/rails/rails/pull/26976)）
*   为 `current_page?` 方法添加 `check_parameters` 选项。（[拉取请求](https://github.com/rails/rails/pull/27549)）

<a class="anchor" id="action-mailer-5-1"></a>

## Action Mailer

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-1-stable/actionmailer/CHANGELOG.md)。

<a class="anchor" id="action-mailer-notable-changes-5-1"></a>

### 重要变化

*   有附件而且在行间设定正文时，允许自定义内容类型。（[拉取请求](https://github.com/rails/rails/pull/27227)）
*   允许把 lambda 传给 `default` 方法。（[提交](https://github.com/rails/rails/commit/1cec84ad2ddd843484ed40b1eb7492063ce71baf)）
*   支持参数化邮件程序，在动作之间共享前置过滤器和默认值。（[提交](https://github.com/rails/rails/commit/1cec84ad2ddd843484ed40b1eb7492063ce71baf)）
*   把传给邮件程序动作的参数传给 `process.action_mailer` 时间，放在 `args` 键名下。（[拉取请求](https://github.com/rails/rails/pull/27900)）

<a class="anchor" id="active-record-5-1"></a>

## Active Record

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-1-stable/activerecord/CHANGELOG.md)。

<a class="anchor" id="active-record-removals-5-1"></a>

### 删除

*   不再允许同时为 `ActiveRecord::QueryMethods#select` 传入参数和块。（[提交](https://github.com/rails/rails/commit/4fc3366d9d99a0eb19e45ad2bf38534efbf8c8ce)）
*   删除弃用的 i18n 作用域 `activerecord.errors.messages.restrict_dependent_destroy.one` 和 `activerecord.errors.messages.restrict_dependent_destroy.many`。（[提交](https://github.com/rails/rails/commit/00e3973a311)）
*   删除单个和集合关系读值方法中弃用的 `force_reload` 参数。（[提交](https://github.com/rails/rails/commit/09cac8c67af)）
*   不再支持把一列传给 `#quote`。（[提交](https://github.com/rails/rails/commit/e646bad5b7c)）
*   删除 `#tables` 方法弃用的 `name` 参数。（[提交](https://github.com/rails/rails/commit/d5be101dd02214468a27b6839ffe338cfe8ef5f3)）
*   `#tables` 和 `#table_exists?` 不再返回表和视图，而只返回表。（[提交](https://github.com/rails/rails/commit/5973a984c369a63720c2ac18b71012b8347479a8)）
*   删除 `ActiveRecord::StatementInvalid#initialize` 和 `ActiveRecord::StatementInvalid#original_exception` 弃用的 `original_exception` 参数。（[提交](https://github.com/rails/rails/commit/bc6c5df4699d3f6b4a61dd12328f9e0f1bd6cf46)）
*   不再支持在查询中使用类。（[提交](https://github.com/rails/rails/commit/b4664864c972463c7437ad983832d2582186e886)）
*   不再支持在 LIMIT 子句中使用逗号。（[提交](https://github.com/rails/rails/commit/fc3e67964753fb5166ccbd2030d7382e1976f393)）
*   删除 `#destroy_all` 弃用的 `conditions` 参数。（[提交](https://github.com/rails/rails/commit/d31a6d1384cd740c8518d0bf695b550d2a3a4e9b)）
*   删除 `#delete_all` 弃用的 `conditions` 参数。（[提交](https://github.com/rails/rails/pull/27503/commits/e7381d289e4f8751dcec9553dcb4d32153bd922b)）
*   删除弃用的 `#load_schema_for` 方法，换成 `#load_schema`。（[提交](https://github.com/rails/rails/commit/419e06b56c3b0229f0c72d3e4cdf59d34d8e5545)）
*   删除弃用的 `#raise_in_transactional_callbacks` 配置。（[提交](https://github.com/rails/rails/commit/8029f779b8a1dd9848fee0b7967c2e0849bf6e07)）
*   删除弃用的 `#use_transactional_fixtures` 配置。（[提交](https://github.com/rails/rails/commit/3955218dc163f61c932ee80af525e7cd440514b3)）

<a class="anchor" id="active-record-deprecations-5-1"></a>

### 弃用

*   弃用 `error_on_ignored_order_or_limit` 旗标，改用 `error_on_ignored_order`。（[提交](https://github.com/rails/rails/commit/451437c6f57e66cc7586ec966e530493927098c7)）
*   弃用 `sanitize_conditions`，改用 `sanitize_sql`。（[拉取请求](https://github.com/rails/rails/pull/25999)）
*   弃用连接适配器的 `supports_migrations?` 方法。（[拉取请求](https://github.com/rails/rails/pull/28172)）
*   弃用 `Migrator.schema_migrations_table_name`，改用 `SchemaMigration.table_name`。（[拉取请求](https://github.com/rails/rails/pull/28351)）
*   加引号和做类型转换时不再调用 `#quoted_id`。（[拉取请求](https://github.com/rails/rails/pull/27962)）
*   `#index_name_exists?` 方法不再接受 `default` 参数。（[拉取请求](https://github.com/rails/rails/pull/26930)）

<a class="anchor" id="active-record-notable-changes-5-1"></a>

### 重要变化

*   主键的默认类型改为 BIGINT。（[拉取请求](https://github.com/rails/rails/pull/26266)）
*   支持 MySQL 5.7.5+ 和 MariaDB 5.2.0+ 的虚拟（生成的）列。（[提交](https://github.com/rails/rails/commit/65bf1c60053e727835e06392d27a2fb49665484c)）
*   支持在批量处理时限制记录数量。（[提交](https://github.com/rails/rails/commit/451437c6f57e66cc7586ec966e530493927098c7)）
*   事务型测试现在把所有 Active Record 连接包装在数据库事务中。（[拉取请求](https://github.com/rails/rails/pull/28726)）
*   默认跳过 `mysqldump` 命令输出的注释。（[拉取请求](https://github.com/rails/rails/pull/23301)）
*   把块传给 `ActiveRecord::Relation#count` 时，使用 Ruby 的 `Enumerable#count` 计算记录数量，而不是悄无声息地忽略块。（[拉取请求](https://github.com/rails/rails/pull/24203)）
*   把 `"-v ON_ERROR_STOP=1"` 旗标传给 `psql` 命令，不静默 SQL 错误。（[拉取请求](https://github.com/rails/rails/pull/24773)）
*   添加 `ActiveRecord::Base.connection_pool.stat`。（[拉取请求](https://github.com/rails/rails/pull/26988)）
*   如果直接继承 `ActiveRecord::Migration`，抛出错误。应该指定迁移针对的 Rails 版本。（[提交](https://github.com/rails/rails/commit/249f71a22ab21c03915da5606a063d321f04d4d3)）
*   通过 `through` 建立的关联，如果反射名称有歧义，抛出错误。（[提交](https://github.com/rails/rails/commit/0944182ad7ed70d99b078b22426cbf844edd3f61)）

<a class="anchor" id="active-model-5-1"></a>

## Active Model

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-1-stable/activemodel/CHANGELOG.md)。

<a class="anchor" id="active-model-removals-5-1"></a>

### 删除

*   删除 `ActiveModel::Errors` 中弃用的方法。（[提交](https://github.com/rails/rails/commit/9de6457ab0767ebab7f2c8bc583420fda072e2bd)）
*   删除长度验证的 `:tokenizer` 选项。（[提交](https://github.com/rails/rails/commit/6a78e0ecd6122a6b1be9a95e6c4e21e10e429513)）
*   回调返回 `false` 时不再终止回调链。（[提交](https://github.com/rails/rails/commit/3a25cdca3e0d29ee2040931d0cb6c275d612dffe)）

<a class="anchor" id="active-model-notable-changes-5-1"></a>

### 重要变化

*   赋值给模型属性的字符串现在能正确冻结了。（[拉取请求](https://github.com/rails/rails/pull/28729)）

<a class="anchor" id="active-job-5-1"></a>

## Active Job

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-1-stable/activejob/CHANGELOG.md)。

<a class="anchor" id="active-job-removals-5-1"></a>

### 删除

*   不再支持把适配器类传给 `.queue_adapter`。（[提交](https://github.com/rails/rails/commit/d1fc0a5eb286600abf8505516897b96c2f1ef3f6)）
*   删除 `ActiveJob::DeserializationError` 中弃用的 `#original_exception`。（[提交](https://github.com/rails/rails/commit/d861a1fcf8401a173876489d8cee1ede1cecde3b)）

<a class="anchor" id="active-job-notable-changes"></a>

### 重要变化

*   增加通过 `ActiveJob::Base.retry_on` 和 `ActiveJob::Base.discard_on` 实现的声明式异常处理。（[拉取请求](https://github.com/rails/rails/pull/25991)）
*   把作业实例传入块，这样在尝试失败后可以访问 `job.arguments` 等信息。（[提交](https://github.com/rails/rails/commit/a1e4c197cb12fef66530a2edfaeda75566088d1f)）

<a class="anchor" id="active-support-5-1"></a>

## Active Support

变化详情参见 [Changelog](https://github.com/rails/rails/blob/5-1-stable/activesupport/CHANGELOG.md)。

<a class="anchor" id="active-support-removals-5-1"></a>

### 删除

*   删除 `ActiveSupport::Concurrency::Latch` 类。（[提交](https://github.com/rails/rails/commit/0d7bd2031b4054fbdeab0a00dd58b1b08fb7fea6)）
*   删除 `halt_callback_chains_on_return_false`。（[提交](https://github.com/rails/rails/commit/4e63ce53fc25c3bc15c5ebf54bab54fa847ee02a)）
*   回调返回 `false` 时不再终止回调链。（[提交](https://github.com/rails/rails/commit/3a25cdca3e0d29ee2040931d0cb6c275d612dffe)）

<a class="anchor" id="active-support-deprecations-5-1"></a>

### 弃用

*   温和弃用顶层 `HashWithIndifferentAccess` 类，换成 `ActiveSupport::HashWithIndifferentAccess`。（[拉取请求](https://github.com/rails/rails/pull/28157)）
*   `set_callback` 和 `skip_callback` 的 `:if` 和 `:unless` 条件选项不再接受字符串。（[提交](https://github.com/rails/rails/commit/0952552)）

<a class="anchor" id="notable-changes-5-1"></a>

### 重要变化

*   修正 DST 发生变化时的时段解析和变迁。（[提交](https://github.com/rails/rails/commit/8931916f4a1c1d8e70c06063ba63928c5c7eab1e)，[拉取请求](https://github.com/rails/rails/pull/26597)）
*   Unicode 更新到 9.0.0 版。（[拉取请求](https://github.com/rails/rails/pull/27822)）
*   为 `#ago` 添加别名 `Duration#before`，为 `#since` 添加别名 `#after`。（[拉取请求](https://github.com/rails/rails/pull/27721)）
*   添加 `Module#delegate_missing_to`，把当前对象未定义的方法委托给一个代理对象。（[拉取请求](https://github.com/rails/rails/pull/23930)）
*   添加 `Date#all_day`，返回一个范围，表示当前日期和时间上的一整天。（[拉取请求](https://github.com/rails/rails/pull/24930)）
*   为测试引入 `assert_changes` 和 `assert_no_changes`。（[拉取请求](https://github.com/rails/rails/pull/25393)）
*   现在嵌套调用 `travel` 和 `travel_to` 抛出异常。（[拉取请求](https://github.com/rails/rails/pull/24890)）
*   更新 `DateTime#change`，支持微秒和纳秒。（[拉取请求](https://github.com/rails/rails/pull/28242)）

<a class="anchor" id="credits-5-1"></a>

## 荣誉榜

得益于[众多贡献者](http://contributors.rubyonrails.org/)，Rails 才能变得这么稳定和强健。向他们致敬！
