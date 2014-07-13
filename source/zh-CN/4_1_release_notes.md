Ruby on Rails 4.1 发布记
=======================

Rails 4.1 精华摘要：

* 采用 Spring 来预载应用程序
* `config/secrets.yml`
* Action Pack Variants
* Action Mailer 预览

本篇仅涵盖主要的变化。要了解关于已修复的 bug、特性变更等，请参考 [Rails GitHub 主页](https://github.com/rails/rails)上各个 Gem 的 CHANGELOG 或是 [Rails 的提交历史](https://github.com/rails/rails/commits/master)。

--------------------------------------------------------------------------------

升级至 Rails 4.1
---------------

如果你正试著升级现有的应用程序至 Rails 4.1，最好有广的测试覆盖度。首先应先升级至 4.0，再升上 4.1。升级需要注意的事项在此篇 [Ruby on Rails 升级指南](/guides/edge-translation/upgrading-ruby-on-rails-zh_CN.md#)可以找到。

主要特性
-------

### Spring 预加载应用程序

Spring 预加载你的 Rails 应用程序。保持应用程序在后台运行，如此一来运行 Rails 命令时：如测试、`rake`、`migrate` 不用每次都重启 Rails 应用程序，加速你的开发流程。

新版 Rails 4.1 应用程序出厂内建 “Spring 化” 的 binstubs（aka，运行文件，如 `rails`、`rake`）。这表示 `bin/rails`、`bin/rake` 会自动采用 Spring 预载的环境。

**运行 rake 任务：**

```
bin/rake test:models
```

**运行 console：**

```
bin/rails console
```

**查看 Spring**

```
$ bin/spring status
Spring is running:

 1182 spring server | my_app | started 29 mins ago
 3656 spring app    | my_app | started 23 secs ago | test mode
 3746 spring app    | my_app | started 10 secs ago | development mode
```

请查阅 [Spring README](https://github.com/jonleighton/spring/blob/master/README.md) 了解所有特性。

参考 [Ruby on Rails 升级指南](/guides/edge-translation/upgrading-ruby-on-rails-zh_TW.md#spring) 来了解如何在 Rails 4.1 以下使用此特性。

### `config/secrets.yml`

Rails 4.1 会在 `config/` 目录下产生新的 `secrets.yml`。这个文件默认存有应用程序的 `secret_key_base`，也可以用来存放其它 secrets，比如存放外部 API 需要用的 access keys。例子：

`secrets.yml`:

```yaml
development:
  secret_key_base: "3b7cd727ee24e8444053437c36cc66c3"
  some_api_key: "b2c299a4a7b2fe41b6b7ddf517604a1c34"
```

读取：

```ruby
> Rails.application.secrets
=> "3b7cd727ee24e8444053437c36cc66c3"
> Rails.application.secrets.some_api_key
=> "SOMEKEY"
```

参考 [Ruby on Rails 升级指南](/guides/edge-translation/upgrading-ruby-on-rails-zh_TW.md#config-secrets-yml) 来了解如何在 Rails 4.1 以下使用此特性。

### Action Pack Variants

针对手机、平板、桌上型电脑及浏览器，常需要 `render` 不同格式的模版：`html`、`json`、`xml`。

__Variant 简化了这件事。__

Request variant 是一种特殊的 request 格式，像是 `:tablet`、`:phone` 或 `:desktop`。

可在 `before_action` 里配置 Variant：

```ruby
request.variant = :tablet if request.user_agent =~ /iPad/
```

在 Controller `action` 里，回应特殊格式跟处理别的格式相同：

```ruby
respond_to do |format|
  format.html do |html|
    html.tablet # 会 render app/views/projects/show.html+tablet.erb
    html.phone { extra_setup; render ... }
  end
end
```

再给每个特殊格式提供对应的模版：

```
app/views/projects/show.html.erb
app/views/projects/show.html+tablet.erb
app/views/projects/show.html+phone.erb
```

Variant 定义可以用 inline 写法来简化：

```ruby
respond_to do |format|
  format.js         { render "trash" }
  format.html.phone { redirect_to progress_path }
  format.html.none  { render "trash" }
end
```

### Action Mailer 预览

Action Mailer Preview 提供你访问特定 URL 来预览 Email 的特性，假设你有个 `Notifier` Mailer，首先实现预览 `Notifier` 用的类：

```ruby
class NotifierPreview < ActionMailer::Preview
  def welcome
    Notifier.welcome(User.first)
  end
end
```

如此一来便可访问 http://localhost:3000/rails/mailers/notifier/welcome 来预览 Email。

所有可预览的 Email 可在此找到：http://localhost:3000/rails/mailers

默认 preview 类的文件保存在 `test/mailers/previews`、可以通过 `preview_path` 选项来配置。

参见 [Action Mailer 的文件](http://api.rubyonrails.org/v4.1.0/classes/ActionMailer/Base.html)来了解更多细节。

### Active Record enums


设置一个 `enum` 属性，将属性映射到数据库的整数，并可通过名字查询出来：

```ruby
class Conversation < ActiveRecord::Base
  enum status: [ :active, :archived ]
end

conversation.archived!
conversation.active? # => false
conversation.status  # => "archived"

Conversation.archived # => Relation for all archived Conversations
```

参见 [active_record/enum.rb](http://api.rubyonrails.org/v4.1.0/classes/ActiveRecord/Enum.html) 来了解更多细节。


### Message verifiers 信息验证器

信息验证器用来生成和校验签名信息，可以用来保障敏感数据（如记住我口令，朋友数据）传输的安全性。

```ruby
signed_token = Rails.application.message_verifier(:remember_me).generate(token)
Rails.application.message_verifier(:remember_me).verify(signed_token) # => token

Rails.application.message_verifier(:remember_me).verify(tampered_token)
# 抛出异常 ActiveSupport::MessageVerifier::InvalidSignature
```

### Module#concerning

一种更自然，轻量级的拆分类特性的方式：


```ruby
class Todo < ActiveRecord::Base
  concerning :EventTracking do
    included do
      has_many :events
    end

    def latest_event
      ...
    end

    private
      def some_internal_method
        ...
      end
  end
end
```

等同于以前要定义 `EventTracking` Module，`extend ActiveSupport::Concern`，再混入 (mixin) `Todo` 类。

参见 [Module#concerning](http://api.rubyonrails.org/v4.1.0/classes/Module/Concerning.html) 来了解更多细节。

### CSRF protection from remote `<script>` tags

Rails 的跨站伪造请求（CSRF）防护机制现在也会保护从第三方 JavaScript 来的 GET 请求了！这预防第三方网站运行你的 JavaScript，试图窃取敏感资料。

这代表任何访问 `.js` URL 的测试会失败，除非你明确指定使用 `xhr` （`XmlHttpRequests`）。

```ruby
post :create, format: :js
```

改写为

```ruby
xhr :post, :create, format: :js
```

Railties
--------

请参考 [Changelog][Railties-CHANGELOG] 来了解更多细节。

### 移除

* 移除了 `update:application_controller` rake 任务。

* 移除了 `Rails.application.railties.engines`。

* Rails 移除了 `config.threadsafe!` 配置。

* 移除了 `ActiveRecord::Generators::ActiveModel#update_attributes`，
    请改用 `ActiveRecord::Generators::ActiveModel#update`。

* 移除了 `config.whiny_nils` 配置。

* 移除了用来跑测试的两个 task：`rake test:uncommitted` 与 `rake test:recent`。

### 值得一提的变化

* [Spring](https://github.com/jonleighton/spring) 纳入默认 Gem，列在 `Gemfile`
  的 `group :development` 里，所以 production 环境不会安装。[PR#12958](https://github.com/rails/rails/pull/12958)

* `BACKTRACE` 环境变量可看（unfiltered）测试的 backtrace。[Commit](https://github.com/rails/rails/commit/84eac5dab8b0fe9ee20b51250e52ad7bfea36553)

* 可以在环境配置文件配置 `MiddlewareStack#unshift`。 [PR#12749](https://github.com/rails/rails/pull/12749)

* 新增 `Application#message_verifier` 方法来返回消息验证器。[PR#12995](https://github.com/rails/rails/pull/12995)

* 默认生成的 `test_helper.rb` 会 `require` `test_help.rb`，帮你把测试的数据库与 `db/schema.rb`（或 `db/structure.sql`）同步。但发现尚未迁移的 migration 与 schema 不一致时会抛出错误。错误抛出与否：`config.active_record.maintain_test_schema = false`，参见此[PR#13528](https://github.com/rails/rails/pull/13528)。

Action Pack
-----------

请参考 [Changelog][AP-CHANGELOG] 来了解更多细节。

### 移除

* 移除了 Rails 针对整合测试的补救方案（fallback），请配置 `ActionDispatch.test_app`。

* 移除了 `config.page_cache_extension` 配置。

* 移除了 `ActionController::RecordIdentifier`，请改用 `ActionView::RecordIdentifier`。

* 更改 Action Controller 下列常量的名称：


  | 移除                               | 采用                            |
  |:-----------------------------------|:--------------------------------|
  | ActionController::AbstractRequest  | ActionDispatch::Request         |
  | ActionController::Request          | ActionDispatch::Request         |
  | ActionController::AbstractResponse | ActionDispatch::Response        |
  | ActionController::Response         | ActionDispatch::Response        |
  | ActionController::Routing          | ActionDispatch::Routing         |
  | ActionController::Integration      | ActionDispatch::Integration     |
  | ActionController::IntegrationTest  | ActionDispatch::IntegrationTest |

### 值得一提的变化

* `protect_from_forgery` 现在也会预防跨站的 `<script>`。请更新测试，使用 `xhr :get, :foo, format: :js` 来取代 `get :foo, format: :js`。[PR#13345](https://github.com/rails/rails/pull/13345)

* `#url_for` 接受额外的 options，可将选项打包成 hash，放在数组传入。[PR#9599](https://github.com/rails/rails/pull/9599)

* 新增 `session#fetch` 方法，行为与 [Hash#fetch](http://www.ruby-doc.org/core-2.0.0/Hash.html#method-i-fetch) 类似，差别在返回值永远会存回 session。 [PR#12692](https://github.com/rails/rails/pull/12692)

* 将 Action View 从 Action Pack 里整个拿掉。 [PR#11032](https://github.com/rails/rails/pull/11032)

Action Mailer
-------------

请参考 [Changelog](https://github.com/rails/rails/blob/4-1-stable/actionmailer/CHANGELOG.md) 来了解更多细节。

### 值得一提的变化

*  Action Mailer 产生 mail 的时间会写到 log 里。 [PR#12556](https://github.com/rails/rails/pull/12556)

Active Record
-------------

请参考 [Changelog][AR-CHANGELOG] 来了解更多细节。

### 移除

* 移除了传入 `nil` 至右列 `SchemaCache` 的方法：`primary_keys`、`tables`、`columns` 及 `columns_hash`。

* 从 `ActiveRecord::Migrator#migrate` 移除了 block filter。

* 从 `ActiveRecord::Migrator` 移除了 String constructor。

* 移除了 scope 没传 callable object 的用法。

* 移除了 `transaction_joinable=`，请改用 `begin_transaction` 加 `:joinable` 选项的组合。

* 移除了 `decrement_open_transactions`。

* 移除了 `increment_open_transactions`。

* 移除了 `PostgreSQLAdapter#outside_transaction?`，可用 `#transaction_open?` 来取代。

* 移除了 `ActiveRecord::Fixtures.find_table_name` 请改用 `ActiveRecord::Fixtures.default_fixture_model_name`。

* 从 `SchemaStatements` 移除了 `columns_for_remove`。

* 移除了 `SchemaStatements#distinct`。

* 将弃用的 `ActiveRecord::TestCase` 移到 Rails test 里。

* 移除有 `:dependent` 选项的关联传入 `:restrict` 选项。

* 移除了 association 这几个选项 `:delete_sql`、`:insert_sql`、`:finder_sql` 及 `:counter_sql`。

* 从 Column 移除了 `type_cast_code` 方法。

* 移除了 `ActiveRecord::Base#connection` 实体方法，请透过 Class 来使用。

* 移除了 `auto_explain_threshold_in_seconds` 的警告。

* 移除了 `Relation#count` 的 `:distinct` 选项。

* 移除了 `partial_updates`、`partial_updates?` 与 `partial_updates=`。

* 移除了 `scoped`。

* 移除了 `default_scopes?`。

* 移除了隐式的 join references。

* 移掉 `activerecord-deprecated_finders` gem 的相依性。

* 移除了 `implicit_readonly`。请改用 `readonly` 方法，并将 record 明确标明为 `readonly`。 [PR#10769](https://github.com/rails/rails/pull/10769)

### 弃用

* 弃用了任何地方都没用到的 `quoted_locking_column` 方法。

* 弃用了 association 从 Array 获得的 bang 方法。要使用请先将 association 转成数组（`#to_a`），再对元素做处理。 [PR#12129](https://github.com/rails/rails/pull/12129)。

* Rails 内部弃用了 `ConnectionAdapters::SchemaStatements#distinct`。 [PR#10556](https://github.com/rails/rails/pull/10556)

* 弃用 `rake db:test:*` 系列的任务，因为现在会自动配置好测试数据库。参见 Railties 的发布记。[PR#13528](https://github.com/rails/rails/pull/13528)

* 弃用了无用的 `ActiveRecord::Base.symbolized_base_class` 与 `ActiveRecord::Base.symbolized_sti_name` 且没有替代方案。[Commit](https://github.com/rails/rails/commit/97e7ca48c139ea5cce2fa9b4be631946252a1ebd)

### 值得一提的变化

* 新增 `ActiveRecord::Base.to_param` 来显示漂亮的 URL。 [PR#12891](https://github.com/rails/rails/pull/12891)

* 新增 `ActiveRecord::Base.no_touching`，可允许忽略对 Model 的 touch。 [PR#12772](https://github.com/rails/rails/pull/12772)

* 统一了 `MysqlAdapter` 与 `Mysql2Adapter` 的布尔转换，`true` 会返回 `1`，`false` 返回 `0`。 [PR#12425](https://github.com/rails/rails/pull/12425)

* `unscope` 现在移除了 `default_scope` 规范的 conditions。[Commit](https://github.com/rails/rails/commit/94924dc32baf78f13e289172534c2e71c9c8cade)

* 新增 `ActiveRecord::QueryMethods#rewhere`，会覆写已存在的 where 条件。[Commit](https://github.com/rails/rails/commit/f950b2699f97749ef706c6939a84dfc85f0b05f2)

* 扩充了 `ActiveRecord::Base#cache_key`，可接受多个 timestamp，会使用数值最大的 timestamp。[Commit](https://github.com/rails/rails/commit/e94e97ca796c0759d8fcb8f946a3bbc60252d329)

* 新增 `ActiveRecord::Base#enum`，用来枚举 attributes。将 attributes 映射到数据库的整数，并可透过名字查询出来。[Commit](https://github.com/rails/rails/commit/db41eb8a6ea88b854bf5cd11070ea4245e1639c5)

* 写入数据库时，JSON 会做类型转换。这样子读写才会一致。 [PR#12643](https://github.com/rails/rails/pull/12643)

* 写入数据库时，hstore 会做类型转换，这样子读写才会一致。[Commit](https://github.com/rails/rails/commit/5ac2341fab689344991b2a4817bd2bc8b3edac9d)

* `next_migration_number` 可供第三方函式库存取。 [PR#12407](https://github.com/rails/rails/pull/12407)

* 若是调用 `update_attributes` 的参数有 `nil`，则会抛出 `ArgumentError`。更精准的说，传进来的参数，没有回应(`respond_to`) `stringify_keys` 的话，会抛出错误。[PR#9860](https://github.com/rails/rails/pull/9860)

* `CollectionAssociation#first`/`#last` (`has_many`) ，Query 会使用 `LIMIT` 来限制提取的数量，而不是将整个 collection 载入出来。 [PR#12137](https://github.com/rails/rails/pull/12137)

* 对 Active Record Model 的类别做 `inspect` 不会去连数据库。这样当数据库不存在时，`inspect` 才不会喷错误。[PR#11014](https://github.com/rails/rails/pull/11014)

* 移除了 `count` 的列限制，SQL 不正确时，让数据库自己丢出错误。 [PR#10710](https://github.com/rails/rails/pull/10710)

* Rails 现在会自动侦测 inverse associations。如果 association 没有配置 `:inverse_of`，则 Active Record 会自己猜出对应的 associaiton。[PR#10886](https://github.com/rails/rails/pull/10886)

* `ActiveRecord::Relation` 会处理有别名的 attributes。当使用符号作为 key 时，Active Record 现在也会一起翻译别名的属性了，将其转成数据库内所使用的列名。[PR#7839](https://github.com/rails/rails/pull/7839)

* Fixtures 文件中的 ERB 不在 main 对象上下文里执行了，多个 fixtures 使用的 Helper 方法，需要定义在被 `ActiveRecord::FixtureSet.context_class` 包含的模块里。[PR#13022](https://github.com/rails/rails/pull/13022)

* 若是明确指定了 `RAILS_ENV`，则不要建立与删除数据库。

Active Model
------------

请参考 [Changelog][AM-CHANGELOG] 来了解更多细节。

### 弃用

* 弃用了 `Validator#setup`。现在要手动在 Validator 的 constructor 里处理。[Commit](https://github.com/rails/rails/commit/7d84c3a2f7ede0e8d04540e9c0640de7378e9b3a)

### 值得一提的变化

* `ActiveModel::Dirty` 加入新的 API：`reset_changes` 与 `changes_applied`，来控制改变的状态。

Active Support
--------------

请参考 [Changelog](https://github.com/rails/rails/blob/4-1-stable/activesupport/CHANGELOG.md) 来了解更多细节。

### 移除

* 移除对 `MultiJSON` Gem 的依赖。也就是说 `ActiveSupport::JSON.decode` 不再接受给 `MultiJSON` 的 hash 参数。[PR#10576](https://github.com/rails/rails/pull/10576)

* 移除了 `encode_json` hook，本来可以用来把 object 转成 JSON。这个特性被抽成了 [activesupport-json_encoder](https://github.com/rails/activesupport-json_encoder) Gem，请参考 [PR#12183](https://github.com/rails/rails/pull/12183) 与[这里](upgrading_ruby_on_rails.html#changes-in-json-handling)。

* 移除了 `ActiveSupport::JSON::Variable`。

* 移除了 `String#encoding_aware?`（`core_ext/string/encoding.rb`）。

* 移除了 `Module#local_constant_names` 请改用 `Module#local_constants`。

* 移除了 `DateTime.local_offset` 请改用 `DateTime.civil_from_format`。

* 移除了 `Logger` （`core_ext/logger.rb`）。

* 移除了 `Time#time_with_datetime_fallback`、`Time#utc_time` 与
  `Time#local_time`，请改用 `Time#utc` 与 `Time#local`。

* 移除了 `Hash#diff`。

* 移除了 `Date#to_time_in_current_zone` 请改用 `Date#in_time_zone`。

* 移除了 `Proc#bind`。

* 移除了 `Array#uniq_by` 与 `Array#uniq_by!` 请改用 Ruby 原生的
  `Array#uniq` 与 `Array#uniq!`。

* 移除了 `ActiveSupport::BasicObject` 请改用 `ActiveSupport::ProxyObject`。

* 移除了 `BufferedLogger`, 请改用 `ActiveSupport::Logger`。

* 移除了 `assert_present` 与 `assert_blank`，请改用 `assert
  object.blank?` 与 `assert object.present?`。

### 弃用

* 弃用了 `Numeric#{ago,until,since,from_now}`，要明确的将数值转成 `AS::Duration`。比如 `5.ago` 请改成 `5.seconds.ago`。 [PR#12389](https://github.com/rails/rails/pull/12389)

* 引用路径里弃用了 `active_support/core_ext/object/to_json`. 请引用 `active_support/core_ext/object/json instead` [PR#12203](https://github.com/rails/rails/pull/12203)

* 弃用了 `ActiveSupport::JSON::Encoding::CircularReferenceError`。 这个特性被抽成了 [activesupport-json_encoder](https://github.com/rails/activesupport-json_encoder) Gem，请参考 [PR#12183](https://github.com/rails/rails/pull/12183) 与[这里](upgrading_ruby_on_rails.html#changes-in-json-handling)。

* 弃用了 `ActiveSupport.encode_big_decimal_as_string` 选项。 这个特性被抽成了 [activesupport-json_encoder](https://github.com/rails/activesupport-json_encoder) Gem，请参考 [PR#12183](https://github.com/rails/rails/pull/12183) 与[这里](upgrading_ruby_on_rails.html#changes-in-json-handling)。

### 值得一提的变化

* 使用 JSON gem 重写 ActiveSupport 的 JSON 编码部分，提升了纯 Ruby 定制编码的效率。参考 [PR#12183](https://github.com/rails/rails/pull/12183) 与[这里](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#changes-in-json-handling)。

* 提升 JSON gem 兼容性。 [PR#12862](https://github.com/rails/rails/pull/12862) 与[这里](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#changes-in-json-handling)

* 新增 `ActiveSupport::Testing::TimeHelpers#travel` 与 `#travel_to`。这两个方法通过 stubbing `Time.now` 与 `Date.today`，可设置任意时间，做时光旅行。参考 [PR#12824](https://github.com/rails/rails/pull/12824)

* 新增 `Numeric#in_milliseconds`，像是 1 小时有几毫秒：`1.hour.in_milliseconds`。可以将时间转成毫秒，再传给 JavaScript 的 `getTime()` 函数。[Commit](https://github.com/rails/rails/commit/423249504a2b468d7a273cbe6accf4f21cb0e643)

* 新增了 `Date#middle_of_day`、`DateTime#middle_of_day` 与 `Time#middle_of_day`
  方法。同时添加了 `midday`、`noon`、`at_midday`、`at_noon`、`at_middle_of_day` 作为别名。[PR#10879](https://github.com/rails/rails/pull/10879)

* `String#gsub(pattern,'')` 可简写为 `String#remove(pattern)`。[Commit](https://github.com/rails/rails/commit/5da23a3f921f0a4a3139495d2779ab0d3bd4cb5f)

* 移除了 `'cow'` => `'kine'` 这个不规则的转换。[Commit](https://github.com/rails/rails/commit/c300dca9963bda78b8f358dbcb59cabcdc5e1dc9)

致谢
-------

许多人花了宝贵的时间贡献至 Rails 项目，使 Rails 成为更稳定、更强韧的网络框架，参考[完整的 Rails 贡献者清单](http://contributors.rubyonrails.org/)，感谢所有的贡献者！

[railties]:       https://github.com/rails/rails/blob/4-1-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/4-1-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/4-1-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/4-1-stable/actionmailer/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/4-1-stable/activerecord/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/4-1-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/4-1-stable/activesupport/CHANGELOG.md
