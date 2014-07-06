Ruby on Rails 4.2 发布记
========================

Rails 4.2 精华摘要：

本篇仅记录主要的变化。要了解关于已修复的 Bug、功能变更等，请参考 [Rails GitHub 主页][rails]上各个 Gem 的 CHANGELOG 或是 [Rails 的提交历史](https://github.com/rails/rails/commits/master)。

--------------------------------------------------------------------------------

升级至 Rails 4.2
----------------------

如果您正试着升级现有的应用程序，最好有广的测试覆盖度。首先应先升级至 4.1，确保应用程序仍正常工作，接着再升上 4.2。升级需要注意的事项在 [Ruby on Rails 升级指南](upgrading_ruby_on_rails.html#upgrading-from-rails-4-1-to-rails-4-2)可以找到。

重要新功能
--------------

### 外键支援

迁移 DSL 现在支援新增、移除外键，也会导出到 `schema.rb`。目前只有 `mysql`、`mysql2` 以及 `postgresql` 的适配器支援外键。

```ruby
# add a foreign key to `articles.author_id` referencing `authors.id`
add_foreign_key :articles, :authors

# add a foreign key to `articles.author_id` referencing `users.lng_id`
add_foreign_key :articles, :users, column: :author_id, primary_key: "lng_id"

# remove the foreign key on `accounts.branch_id`
remove_foreign_key :accounts, :branches

# remove the foreign key on `accounts.owner_id`
remove_foreign_key :accounts, column: :owner_id
```

完整说明请参考 API 文档：[add_foreign_key](http://api.rubyonrails.org/v4.2.0/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_foreign_key) 和 [remove_foreign_key](http://api.rubyonrails.org/v4.2.0/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_foreign_key)。

Railties
--------

请参考 [CHANGELOG][Railties-CHANGELOG] 来了解更多细节。

### 移除

* 移除了 `rails application` 命令。
  ([Pull Request](https://github.com/rails/rails/pull/11616))

### 值得一提的变化

* 导入 `bin/setup` 脚本来启动应用程序。
  ([Pull Request](https://github.com/rails/rails/pull/15189))

* `config.assets.digest` 在开发模式的缺省值改为 `true`。
  ([Pull Request](https://github.com/rails/rails/pull/15155))

* 导入给 `rake notes` 注册新扩展功能的 API。
  ([Pull Request](https://github.com/rails/rails/pull/14379))

* 导入 `Rails.gem_version` 作为返回 `Gem::Version.new(Rails.version)` 的便捷方法。
  ([Pull Request](https://github.com/rails/rails/pull/14101))

Action Pack
-----------

请参考 [CHANGELOG][AP-CHANGELOG] 来了解更多细节。

### 弃用

* 弃用路由的 `:to` 选项里，`:to` 可以指向符号或不含井号的字串这两个功能。

      get '/posts', to: MyRackApp    => (No change necessary)
      get '/posts', to: 'post#index' => (No change necessary)
      get '/posts', to: 'posts'      => get '/posts', controller: :posts
      get '/posts', to: :index       => get '/posts', action: :index

  ([Commit](https://github.com/rails/rails/commit/cc26b6b7bccf0eea2e2c1a9ebdcc9d30ca7390d9))

### 值得一提的变化

* `*_filter` 方法已经从文档中移除，已经不鼓励使用。偏好使用 `*_action` 方法：

    ```ruby
    after_filter          => after_action
    append_after_filter   => append_after_action
    append_around_filter  => append_around_action
    append_before_filter  => append_before_action
    around_filter         => around_action
    before_filter         => before_action
    prepend_after_filter  => prepend_after_action
    prepend_around_filter => prepend_around_action
    prepend_before_filter => prepend_before_action
    skip_after_filter     => skip_after_action
    skip_around_filter    => skip_around_action
    skip_before_filter    => skip_before_action
    skip_filter           => skip_action_callback
    ```

  若应用程序依赖这些 `*_filter` 方法，应该使用 `*_action` 方法替换。
  因为 `*_filter` 方法最终会从 Rails 里拿掉。
  (Commit [1](https://github.com/rails/rails/commit/6c5f43bab8206747a8591435b2aa0ff7051ad3de),
  [2](https://github.com/rails/rails/commit/489a8f2a44dc9cea09154ee1ee2557d1f037c7d4))

* 从 RFC-4791 新增 HTTP 方法 `MKCALENDAR`。
  ([Pull Request](https://github.com/rails/rails/pull/15121))

* `*_fragment.action_controller` 通知消息的 Payload 现在包含 Controller 与动作名称。
  ([Pull Request](https://github.com/rails/rails/pull/14137))

* 传入 URL 辅助方法的片段现在会自动 Escaped。
  ([Commit](https://github.com/rails/rails/commit/5460591f0226a9d248b7b4f89186bd5553e7768f))

* 改善路由错误页面，搜索路由支持模糊搜索。
  ([Pull Request](https://github.com/rails/rails/pull/14619))

* 新增关掉记录 CSRF 失败的选项。
  ([Pull Request](https://github.com/rails/rails/pull/14280))

Action View
-------------

请参考 [CHANGELOG][AV-CHANGELOG] 来了解更多细节。

### 弃用

* 弃用 `AbstractController::Base.parent_prefixes`。想修改寻找视图的位置，
  请覆写 `AbstractController::Base.local_prefixes`。
  ([Pull Request](https://github.com/rails/rails/pull/15026))

* 弃用 `ActionView::Digestor#digest(name, format, finder, options = {})`，
  现在参数改用 Hash 传入。
  ([Pull Request](https://github.com/rails/rails/pull/14243))

### 值得一提的变化

Action Mailer
-------------

请参考 [CHANGELOG](https://github.com/rails/rails/blob/4-1-stable/actionmailer/CHANGELOG.md) 来了解更多细节。

### 值得一提的变化

Active Record
-------------

请参考 [CHANGELOG][AR-CHANGELOG] 来了解更多细节。

### 移除

* 移除已弃用的方法 `ActiveRecord::Base.quoted_locking_column`.
  ([Pull Request](https://github.com/rails/rails/pull/15612))

* 移除已弃用的方法 `ActiveRecord::Migrator.proper_table_name`。
  请改用 `ActiveRecord::Migration` 的实例方法：`proper_table_name`。
  ([Pull Request](https://github.com/rails/rails/pull/15512))

* 移除 `cache_attributes` 以及其它相关的方法，所有的属性现在都会快取了。
  ([Pull Request](https://github.com/rails/rails/pull/15429))

* 移除了未使用的 `:timestamp` 类型。把所有 `timestamp` 类型都改为 `:datetime` 的别名。
  修正在 `ActiveRecord` 之外，栏位类型不一致的问题，譬如 XML 序列化。
  ([Pull Request](https://github.com/rails/rails/pull/15184))

### 弃用

* 弃用了当栏位不存在时，还会从 `column_for_attribute` 返回 `nil` 的情况。
  Rails 5.0 将会返回 Null Object。
  ([Pull Request](https://github.com/rails/rails/pull/15878))

* 弃用了 `serialized_attributes`，没有替代方案。
  ([Pull Request](https://github.com/rails/rails/pull/15704))

* 依赖实例状态（有定义接受参数的作用域）的关联现在不能使用 `.joins`、`.preload` 以及 `.eager_load` 了。
  ([Commit](https://github.com/rails/rails/commit/ed56e596a0467390011bc9d56d462539776adac1))

* 弃用 `.find` 或 `.exists?` 可传入 Active Record 对象。请先对对象呼叫 `#id`。
  (Commit [1](https://github.com/rails/rails/commit/d92ae6ccca3bcfd73546d612efaea011270bd270),
  [2](https://github.com/rails/rails/commit/d35f0033c7dec2b8d8b52058fb8db495d49596f7))

* 弃用仅支持一半的 PostgreSQL 范围数值（不包含起始值）。目前我们把 PostgreSQL 的范围对应到 Ruby 的范围。但由于 Ruby 的范围不支援不包含起始值，所以无法完全转换。

  目前的解决方法是将起始数递增，这是不对的，已经弃用了。关于不知如何递增的子类型（比如没有定义 `#succ`）会对不包含起始值的抛出 `ArgumentError`。

  ([Commit](https://github.com/rails/rails/commit/91949e48cf41af9f3e4ffba3e5eecf9b0a08bfc3))

* 弃用对 `has_many :through` 自动侦测 counter cache 的支持。要自己对 `has_many` 与
  `belongs_to` 关联，给 `through` 的纪录手动设定。
  ([Pull Request](https://github.com/rails/rails/pull/15754))

### 值得一提的变化

* 新增 `ActiveRecord::Base` 对象的 `#pretty_print` 方法。
  ([Pull Request](https://github.com/rails/rails/pull/15172))

* PostgreSQL 与 SQLite 适配器不再默认限制字串只能 255 字符。
  ([Pull Request](https://github.com/rails/rails/pull/14579))

* `sqlite3:///some/path` 现在可以解析系统的绝对路径 `/some/path`。
  相对路径请使用 `sqlite3:some/path`。(先前是 `sqlite3:///some/path`
  会解析成 `some/path`。这个行为已在 Rails 4.1 被弃用了。  Rails 4.1.)
  ([Pull Request](https://github.com/rails/rails/pull/14569))

* 引入 `#validate` 作为 `#valid?` 的别名。
  ([Pull Request](https://github.com/rails/rails/pull/14456))

* `#touch` 现在可一次对多属性操作。
  ([Pull Request](https://github.com/rails/rails/pull/14423))

* 新增 MySQL 5.6 以上版本的 fractional seconds 支持。
  (Pull Request [1](https://github.com/rails/rails/pull/8240), [2](https://github.com/rails/rails/pull/14359))

* 新增 PostgreSQL 适配器的 `citext` 支持。
  ([Pull Request](https://github.com/rails/rails/pull/12523))

* 新增 PostgreSQL 适配器的使用自建的范围类型支持。
  ([Commit](https://github.com/rails/rails/commit/4cb47167e747e8f9dc12b0ddaf82bdb68c03e032))

* 单数关联增加 `:required` 选项，用来定义关联的存在性验证。
  ([Pull Request](https://github.com/rails/rails/pull/16056))

Active Model
------------

请参考 [CHANGELOG][AM-CHANGELOG] 来了解更多细节。

### 移除

* 移除了 `Validator#setup`，没有替代方案。
  ([Pull Request](https://github.com/rails/rails/pull/15617))

### 值得一提的变化

* 引入 `#validate` 作为 `#valid?` 的别名。
  ([Pull Request](https://github.com/rails/rails/pull/14456))

Active Support
--------------

请参考 [CHANGELOG](https://github.com/rails/rails/blob/4-1-stable/activesupport/CHANGELOG.md) 来了解更多细节。

### 移除

* 移除弃用的 `Numeric#ago`、`Numeric#until`、`Numeric#since` 以及
  `Numeric#from_now`. ([Commit](https://github.com/rails/rails/commit/f1eddea1e3f6faf93581c43651348f48b2b7d8bb))

* 移除弃用 `ActiveSupport::Callbacks` 基于字串的终止符。
  ([Pull Request](https://github.com/rails/rails/pull/15100))

### 弃用

* 弃用 `Class#superclass_delegating_accessor`，请改用 `Class#class_attribute`。
  ([Pull Request](https://github.com/rails/rails/pull/14271))

* 弃用 `ActiveSupport::SafeBuffer#prepend!` 请改用 `ActiveSupport::SafeBuffer#prepend`（两者功能相同）。
  ([Pull Request](https://github.com/rails/rails/pull/14529))

### 值得一提的变化

* `humanize` 现在会去掉前面的底线。
  ([Commit](https://github.com/rails/rails/commit/daaa21bc7d20f2e4ff451637423a25ff2d5e75c7))

* 新增 `SecureRandom::uuid_v3` 和 `SecureRandom::uuid_v5` 方法。
  ([Pull Request](https://github.com/rails/rails/pull/12016))

* 导入 `Concern#class_methods` 来取代 `module ClassMethods` 以及 `Kernel#concern`，
  来避免使用 `module Foo; extend ActiveSupport::Concern; end` 这样的样板。
  ([Commit](https://github.com/rails/rails/commit/b16c36e688970df2f96f793a759365b248b582ad))

* 新增 `Hash#transform_values` 与 `Hash#transform_values!` 方法，来简化 Hash
  值需要更新、但键保留不变这样的常见模式。
  ([Pull Request](https://github.com/rails/rails/pull/15819))

致谢
----

许多人花费宝贵的时间贡献至 Rails 项目，使 Rails 成为更稳定、更强韧的网络框架，参考[完整的 Rails 贡献者清单](http://contributors.rubyonrails.org/)，感谢所有的贡献者！

[rails]: https://github.com/rails/rails
[Railties-CHANGELOG]: https://github.com/rails/rails/blob/4-2-stable/railties/CHANGELOG.md
[AR-CHANGELOG]: https://github.com/rails/rails/blob/4-2-stable/activerecord/CHANGELOG.md
[AP-CHANGELOG]: https://github.com/rails/rails/blob/4-2-stable/actionpack/CHANGELOG.md
[AM-CHANGELOG]: https://github.com/rails/rails/blob/4-2-stable/activemodel/CHANGELOG.md
[AV-CHANGELOG]: https://github.com/rails/rails/blob/4-2-stable/actionview/CHANGELOG.md
