Ruby on Rails 4.2 发布记
========================

Rails 4.2 精华摘要：

* Active Job
* 异步邮件
* Adequate Record
* Web 终端
* 外键支持

本篇仅记录主要的变化。要了解关于已修复的 Bug、特性变更等，请参考 [Rails GitHub 主页](https://github.com/rails/rails)上各个 Gem 的 CHANGELOG 或是 [Rails 的提交历史](https://github.com/rails/rails/commits/master)。

--------------------------------------------------------------------------------

升级至 Rails 4.2
----------------------

如果您正试着升级现有的应用，应用最好要有足够的测试。第一步先升级至 4.1，确保应用仍正常工作，接着再升上 4.2。升级需要注意的事项在 [Ruby on Rails 升级指南](upgrading_ruby_on_rails.html#upgrading-from-rails-4-1-to-rails-4-2)可以找到。

重要新特性
---------

### Active Job

Active Job 是 Rails 4.2 新搭载的框架。是队列系统（Queuing systems）的统一接口，用来连接像是 [Resque](https://github.com/resque/resque)、[Delayed
Job](https://github.com/collectiveidea/delayed_job)、[Sidekiq](https://github.com/mperham/sidekiq) 等队列系统。

采用 Active Job API 撰写的任务程序（Background jobs），便可在任何支持的队列系统上运行而无需对代码进行任何修改。Active Job 缺省会即时执行任务。

任务通常需要传入 Active Record 对象作为参数。Active Job 将传入的对象作为 URI（统一资源标识符），而不是直接对对象进行 marshal。新增的 GlobalID 函式库，给对象生成统一资源标识符，并使用该标识符来查找对象。现在因为内部使用了 Global ID，任务只要传入 Active Record 对象即可。

譬如，`trashable` 是一个 Active Record 对象，则下面这个任务无需做任何序列化，便可正常完成任务：

```ruby
class TrashableCleanupJob < ActiveJob::Base
  def perform(trashable, depth)
    trashable.cleanup(depth)
  end
end
```

参考 [Active Job 基础](active_job_basics.html)指南来进一步了解。

### 异步邮件

构造于 Active Job 之上，Action Mailer 新增了 `#deliver_later` 方法，通过队列来发送邮件，若开启了队列的异步特性，便不会拖慢控制器或模型的运行（缺省队列是即时执行任务）。

想直接发送信件仍可以使用 `deliver_now`。

### Adequate Record

Adequate Record 是对 Active Record `find` 和 `find_by` 方法以及其它的关联查询方法所进行的一系列重构，查询速度最高提升到了两倍之多。

工作原理是在执行 Active Record 调用时，把 SQL 查询语句缓存起来。有了查询语句的缓存之后，同样的 SQL 查询就无需再次把调用转换成 SQL 语句。更多细节请参考 [Aaron Patterson 的博文](http://tenderlovemaking.com/2014/02/19/adequaterecord-pro-like-activerecord.html)。

Adequate Record 已经合并到 Rails 里，所以不需要特别启用这个特性。多数的 `find` 和 `find_by` 调用和关联查询会自动使用 Adequate Record，比如：

```ruby
Post.find(1)  # First call generates and cache the prepared statement
Post.find(2)  # Subsequent calls reuse the cached prepared statement

Post.find_by_title('first post')
Post.find_by_title('second post')

post.comments
post.comments(true)
```

有一点特别要说明的是，如上例所示，缓存的语句不会缓存传入的数值，只是缓存语句的模版而已。

下列场景则不会使用缓存：

- 当 model 有缺省作用域时
- 当 model 使用了单表继承时
- 当 `find` 查询一组 ID 时：

  ```ruby
  # not cached
  Post.find(1, 2, 3)
  Post.find([1,2])
  ```

- 以 SQL 片段执行 `find_by`：

  ```ruby
  Post.find_by('published_at < ?', 2.weeks.ago)
  ```

### Web 终端

用 Rails 4.2 新产生的应用程序，缺省搭载了 [Web 终端](https://github.com/rails/web-console)。Web 终端给错误页面添加了一个互动式 Ruby 终端，并提供视图帮助方法 `console`，以及一些控制器帮助方法。

错误页面的互动式的终端，让你可以在异常发生的地方执行代码。插入 `console` 视图帮助方法到任何页面，便可以在页面的上下文里，在页面渲染结束后启动一个互动式的终端。

最后，可以执行 `rails console` 来启动一个 VT100 终端。若需要建立或修改测试资料，可以直接从浏览器里执行。

### 外键支持

迁移 DSL 现在支持新增、移除外键，外键也会导出到 `schema.rb`。目前只有 `mysql`、`mysql2` 以及 `postgresql` 的适配器支持外键。

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

Rails 4.2 向下不兼容的部份
------------------------

前版弃用的特性已全数移除。请参考文后下列各 Rails 部件来了解 Rails 4.2 新弃用的特性有那些。

以下是升级至 Rails 4.2 所需要立即采取的行动。

### `render` 字串参数

4.2 以前在 Controller action 调用 `render "foo/bar"` 时，效果等同于：`render file: "foo/bar"`；Rails 4.2 则改为 `render template: "foo/bar"`。如需 `render` 文件，请将代码改为 `render file: "foo/bar"`。

### `respond_with` / class-level `respond_to`

`respond_with` 以及对应的**类别层级** `respond_to` 被移到了 `responders` gem。要使用这个特性，把 `gem 'responders', '~> 2.0'` 加入到 Gemfile：

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

而实例层级的 `respond_to` 则不受影响：

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

### `rails server` 的缺省主机（host）变更

由于 [Rack 的一项修正](https://github.com/rack/rack/commit/28b014484a8ac0bbb388e7eaeeef159598ec64fc)，`rails server` 现在缺省会监听 `localhost` 而不是 `0.0.0.0`。http://127.0.0.1:3000 和 http://localhost:3000 仍可以像先前一般使用。

但这项变更禁止了从其它机器访问 Rails 服务器（譬如开发环境位于虚拟环境里，而想要从宿主机器上访问），则需要用 `rails server -b 0.0.0.0` 来启动，才能像先前一样使用。

若是使用了 `0.0.0.0`，记得要把防火墙设置好，改成只有信任的机器才可以存取你的开发服务器。

### HTML Sanitizer

HTML sanitizer 换成一个新的、更加安全的实现，基于 Loofah 和 Nokogiri。新的 Sanitizer 更安全，而 sanitization 更加强大与灵活。

有了新的 sanitization 算法之后，某些 pathological 输入的输出会和之前不太一样。

若真的需要使用旧的 sanitizer，可以把 `rails-deprecated_sanitizer` 加到 Gemfile，便会用旧的 sanitizer 取代掉新的。而因为这是自己选择性加入的 gem，所以并不会抛出弃用警告。

Rails 4.2 仍会维护 `rails-deprecated_sanitizer`，但 Rails 5.0 之后便不会再进行维护。

参考[这篇文章](http://blog.plataformatec.com.br/2014/07/the-new-html-sanitizer-in-rails-4-2/)来了解更多关于新的 sanitizer 的变更内容细节。

### `assert_select`

`assert_select` 测试方法现在用 Nokogiri 改写了。

不再支援某些先前可用的选择器。若应用程式使用了以下的选择器，则会需要进行更新：

*   属性选择器的数值需要用双引号包起来。

    ```
    a[href=/]      =>     a[href="/"]
    a[href$=/]     =>     a[href$="/"]
    ```

*   含有错误嵌套的 HTML 所建出来的 DOM 可能会不一样

    譬如：

    ``` ruby
    # content: <div><i><p></i></div>

    # before:
    assert_select('div > i')  # => true
    assert_select('div > p')  # => false
    assert_select('i > p')    # => true

    # now:
    assert_select('div > i')  # => true
    assert_select('div > p')  # => true
    assert_select('i > p')    # => false
    ```

*   之前要比较含有 HTML entities 的元素要写未经转译的 HTML，现在写转译后的即可

    ``` ruby
    # content: <p>AT&amp;T</p>

    # before:
    assert_select('p', 'AT&amp;T')  # => true
    assert_select('p', 'AT&T')      # => false

    # now:
    assert_select('p', 'AT&T')      # => true
    assert_select('p', 'AT&amp;T')  # => false
    ```


Railties
--------

请参考 [CHANGELOG][railties] 来了解更多细节。

### 移除

*   `--skip-action-view` 选项从 app generator 移除。
    ([Pull Request](https://github.com/rails/rails/pull/17042))

*   移除 `rails application` 命令。
    ([Pull Request](https://github.com/rails/rails/pull/11616))

### 弃用

*   生产环境新增 `config.log_level` 设置。
    ([Pull Request](https://github.com/rails/rails/pull/16622))

*   弃用 `rake test:all`，请改用 `rake test` 来执行 `test` 目录下的所有测试。
    ([Pull Request](https://github.com/rails/rails/pull/17348))

*   弃用 `rake test:all:db`，请改用 `rake test:db`。
    ([Pull Request](https://github.com/rails/rails/pull/17348))

*   弃用 `Rails::Rack::LogTailer`，没有替代方案。
    ([Commit](https://github.com/rails/rails/commit/84a13e019e93efaa8994b3f8303d635a7702dbce))

### 值得一提的变化

*   `web-console` 导入为应用内建的 Gem。
    ([Pull Request](https://github.com/rails/rails/pull/11667))

*   Model 用来产生关联的 generator 添加 `required` 选项。
    ([Pull Request](https://github.com/rails/rails/pull/16062))

*   导入 `after_bundle` 回调到 Rails 模版。
  ([Pull Request](https://github.com/rails/rails/pull/16359))

*   导入 `x` 命名空间，可用来自订设置选项：

    ```ruby
    # config/environments/production.rb
    config.x.payment_processing.schedule = :daily
    config.x.payment_processing.retries  = 3
    config.x.super_debugger              = true
    ```

    这些选项都可以从设置对象里获取：

    ```ruby
    Rails.configuration.x.payment_processing.schedule # => :daily
    Rails.configuration.x.payment_processing.retries  # => 3
    Rails.configuration.x.super_debugger              # => true
    ```

    ([Commit](https://github.com/rails/rails/commit/611849772dd66c2e4d005dcfe153f7ce79a8a7db))

*   导入 `Rails::Application.config_for`，用来给当前的环境载入设置

    ```ruby
    # config/exception_notification.yml:
    production:
      url: http://127.0.0.1:8080
      namespace: my_app_production
    development:
      url: http://localhost:3001
      namespace: my_app_development

    # config/production.rb
    Rails.application.configure do
      config.middleware.use ExceptionNotifier, config_for(:exception_notification)
    end
    ```

    ([Pull Request](https://github.com/rails/rails/pull/16129))

*   产生器新增 `--skip-turbolinks` 选项，可在新建应用时拿掉 turbolink。
    ([Commit](https://github.com/rails/rails/commit/bf17c8a531bc8059d50ad731398002a3e7162a7d))

*   导入 `bin/setup` 脚本来启动（bootstrapping）应用。
  ([Pull Request](https://github.com/rails/rails/pull/15189))

*   `config.assets.digest` 在开发模式的缺省值改为 `true`。
  ([Pull Request](https://github.com/rails/rails/pull/15155))

*   导入给 `rake notes` 注册新扩充功能的 API。
  ([Pull Request](https://github.com/rails/rails/pull/14379))

*   导入 `Rails.gem_version` 作为返回 `Gem::Version.new(Rails.version)` 的便捷方法。
  ([Pull Request](https://github.com/rails/rails/pull/14101))

Action Pack
-----------

请参考 [CHANGELOG][action-pack] 来了解更多细节。

### 移除

*   将 `respond_with` 以及类别层级的 `respond_to` 从 Rails 移除，移到 `responders` gem（版本 2.0）。要继续使用这个特性，请在 Gemfile 添加：`gem 'responders', '~> 2.0'`。([Pull Request](https://github.com/rails/rails/pull/16526))

*   移除弃用的 `AbstractController::Helpers::ClassMethods::MissingHelperError`，
    改用 `AbstractController::Helpers::MissingHelperError` 取代。
    ([Commit](https://github.com/rails/rails/commit/a1ddde15ae0d612ff2973de9cf768ed701b594e8))

### 弃用

*   弃用 `*_path` 帮助方法的 `only_path` 选项。
    ([Commit](https://github.com/rails/rails/commit/aa1fadd48fb40dd9396a383696134a259aa59db9))

*   弃用 `assert_tag`、`assert_no_tag`、`find_tag` 以及 `find_all_tag`，请改用 `assert_select`。
    ([Commit](https://github.com/rails/rails-dom-testing/commit/b12850bc5ff23ba4b599bf2770874dd4f11bf750))

*   弃用路由的 `:to` 选项里，`:to` 可以指向符号或不含井号的字串这两个功能。

    ```ruby
    get '/posts', to: MyRackApp    => (No change necessary)
    get '/posts', to: 'post#index' => (No change necessary)
    get '/posts', to: 'posts'      => get '/posts', controller: :posts
    get '/posts', to: :index       => get '/posts', action: :index
    ```

    ([Commit](https://github.com/rails/rails/commit/cc26b6b7bccf0eea2e2c1a9ebdcc9d30ca7390d9))

*   弃用 URL 帮助方法不再支持使用字串作为键：

    ```ruby
    # bad
    root_path('controller' => 'posts', 'action' => 'index')

    # good
    root_path(controller: 'posts', action: 'index')
    ```

    ([Pull Request](https://github.com/rails/rails/pull/17743))


### 值得一提的变化

*   `*_filter` 方法已经从文件中移除，已经不鼓励使用。偏好使用 `*_action` 方法：

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

    若应用程式依赖这些 `*_filter` 方法，应该使用 `*_action` 方法替换。
    因为 `*_filter` 方法最终会从 Rails 里拿掉。
    (Commit [1](https://github.com/rails/rails/commit/6c5f43bab8206747a8591435b2aa0ff7051ad3de),
    [2](https://github.com/rails/rails/commit/489a8f2a44dc9cea09154ee1ee2557d1f037c7d4))

*   `render nothing: true` 或算绘 `nil` 不再加入一个空白到响应主体。
  ([Pull Request](https://github.com/rails/rails/pull/14883))

*   Rails 现在会自动把模版的 digest 加入到 ETag。
    ([Pull Request](https://github.com/rails/rails/pull/16527))

* 传入 URL 辅助方法的片段现在会自动 Escaped。
  ([Commit](https://github.com/rails/rails/commit/5460591f0226a9d248b7b4f89186bd5553e7768f))

*   导入 `always_permitted_parameters` 选项，用来设置全局允许赋值的参数。
  缺省值是 `['controller', 'action']`。
  ([Pull Request](https://github.com/rails/rails/pull/15933))

*   从 [RFC 4791](https://tools.ietf.org/html/rfc4791) 新增 HTTP 方法 `MKCALENDAR`。
  ([Pull Request](https://github.com/rails/rails/pull/15121))

*   `*_fragment.action_controller` 通知消息的 Payload 现在会带有控制器和动作名称。
  ([Pull Request](https://github.com/rails/rails/pull/14137))

*   改善路由错误页面，搜索路由支持模糊搜寻。
  ([Pull Request](https://github.com/rails/rails/pull/14619))

*   新增关掉记录 CSRF 失败的选项。
  ([Pull Request](https://github.com/rails/rails/pull/14280))

*   当使用 Rails 服务器来提供静态资源时，若客户端支持 gzip，则会自动传送预先产生好的 gzip 静态资源。Asset Pipeline 缺省会给所有可压缩的静态资源产生 `.gz` 文件。传送 gzip 可将所需传输的数据量降到最小，并加速静态资源请求的存取。当然若要在 Rails 生产环境提供静态资源，最好还是使用 [CDN](http://guides.rubyonrails.org/asset_pipeline.html#cdns)。([Pull Request](https://github.com/rails/rails/pull/16466))

*   在整合测试里调用 `process` 帮助方法时，路径开始需要有 `/`。以前可以忽略开头的 `/`，但这是实作所产生的副产品，而不是有意新增的特性，譬如：

    ```ruby
    test "list all posts" do
      get "/posts"
      assert_response :success
    end
    ```

Action View
-----------

请参考 [CHANGELOG][action-view] 来了解更多细节。

### 弃用

* 弃用 `AbstractController::Base.parent_prefixes`。想修改寻找视图的位置，
  请覆盖 `AbstractController::Base.local_prefixes`。
  ([Pull Request](https://github.com/rails/rails/pull/15026))

* 弃用 `ActionView::Digestor#digest(name, format, finder, options = {})`，现在参数改用 Hash 传入。
  ([Pull Request](https://github.com/rails/rails/pull/14243))

### 值得一提的变化

*   `render "foo/bar"` 现在等同 `render template: "foo/bar"` 而不是 `render file: "foo/bar"`。([Pull Request](https://github.com/rails/rails/pull/16888))

*   隐藏栏位的表单辅助方法不再产生含有行内样式表的 `<div>` 元素。
  ([Pull Request](https://github.com/rails/rails/pull/14738))

*   导入一个特别的 `#{partial_name}_iteration` 局部变量，给在 collection 里渲染的部分视图（Partial）使用。这个变量可以通过 `#index`、`#size`、`first?` 以及 `last?` 等方法来获得目前迭代的状态。([Pull Request](https://github.com/rails/rails/pull/7698))

*   Placeholder I18n 遵循和 `label` I18n 一样的惯例。
    ([Pull Request](https://github.com/rails/rails/pull/16438))

Action Mailer
-------------

请参考 [CHANGELOG][action-mailer] 来了解更多细节。

### 弃用

*   Mailer 弃用所有 `*_path` 的帮助方法。请全面改用 `*_url`。
    ([Pull Request](https://github.com/rails/rails/pull/15840))

*   弃用 `deliver` 与 `deliver!`，请改用 `deliver_now` 或 `deliver_now!`。
    ([Pull Request](https://github.com/rails/rails/pull/16582))

### 值得一提的变化

*   `link_to` 和 `url_for` 在模版里缺省产生绝对路径，不再需要传入 `only_path: false`。
    ([Commit](https://github.com/rails/rails/commit/9685080a7677abfa5d288a81c3e078368c6bb67c))

*   导入 `deliver_later` 方法，将邮件加到应用的队列里，用来异步发送邮件。
    ([Pull Request](https://github.com/rails/rails/pull/16485))

*   新增 `show_previews` 选项，用来在开发环境之外启用邮件预览特性。
  ([Pull Request](https://github.com/rails/rails/pull/15970))


Active Record
-------------

请参考 [CHANGELOG][active-record] 来了解更多细节。

### 移除

*   移除 `cache_attributes` 以及其它相关的方法，所有的属性现在都会缓存了。
  ([Pull Request](https://github.com/rails/rails/pull/15429))

*   移除已弃用的方法 `ActiveRecord::Base.quoted_locking_column`.
  ([Pull Request](https://github.com/rails/rails/pull/15612))

*   移除已弃用的方法 `ActiveRecord::Migrator.proper_table_name`。
  请改用 `ActiveRecord::Migration` 的实例方法：`proper_table_name`。
  ([Pull Request](https://github.com/rails/rails/pull/15512))

*   移除了未使用的 `:timestamp` 类型。把所有 `timestamp` 类型都改为 `:datetime` 的别名。
  修正在 `ActiveRecord` 之外，栏位类型不一致的问题，譬如 XML 序列化。
  ([Pull Request](https://github.com/rails/rails/pull/15184))

### 弃用

*   弃用 `after_commit` 和 `after_rollback` 会吃掉错误的行为。
    ([Pull Request](https://github.com/rails/rails/pull/16537))

*   弃用对 `has_many :through` 自动侦测 counter cache 的支持。要自己对 `has_many` 和 `belongs_to` 关联，给 `through` 的记录手动设置。
  ([Pull Request](https://github.com/rails/rails/pull/15754))

*   弃用 `.find` 或 `.exists?` 可传入 Active Record 对象。请先对对象调用 `#id`。
  (Commit [1](https://github.com/rails/rails/commit/d92ae6ccca3bcfd73546d612efaea011270bd270),
  [2](https://github.com/rails/rails/commit/d35f0033c7dec2b8d8b52058fb8db495d49596f7))

*   弃用仅支持一半的 PostgreSQL 范围数值（不包含起始值）。目前我们把 PostgreSQL 的范围对应到 Ruby 的范围。但由于 Ruby 的范围不支持不包含起始值，所以无法完全转换。

    目前的解决方法是将起始数递增，这是不对的，已经弃用了。关于不知如何递增的子类型（比如没有定义 `#succ`）会对不包含起始值的抛出 `ArgumentError`。

    ([Commit](https://github.com/rails/rails/commit/91949e48cf41af9f3e4ffba3e5eecf9b0a08bfc3))

*   弃用无连接调用 `DatabaseTasks.load_schema`。请改用 `DatabaseTasks.load_schema_current` 来取代。
    ([Commit](https://github.com/rails/rails/commit/f15cef67f75e4b52fd45655d7c6ab6b35623c608))

*   弃用 `sanitize_sql_hash_for_conditions`，没有替代方案。使用 `Relation` 来进行查询或更新是推荐的做法。
    ([Commit](https://github.com/rails/rails/commit/d5902c9e))

*   弃用 `add_timestamps` 和 `t.timestamps` 可不用传入 `:null` 选项的行为。Rails 5 将把缺省 `null: true` 改为 `null: false`。
    ([Pull Request](https://github.com/rails/rails/pull/16481))

*   弃用 `Reflection#source_macro`，没有替代方案。Active Record 不再需要这个方法了。
    ([Pull Request](https://github.com/rails/rails/pull/16373))

*   弃用 `serialized_attributes`，没有替代方案。
  ([Pull Request](https://github.com/rails/rails/pull/15704))

*   弃用了当栏位不存在时，还会从 `column_for_attribute` 返回 `nil` 的情况。
  Rails 5.0 将会返回 Null Object。
  ([Pull Request](https://github.com/rails/rails/pull/15878))

*   弃用了 `serialized_attributes`，没有替代方案。
  ([Pull Request](https://github.com/rails/rails/pull/15704))

*   弃用依赖实例状态（有定义接受参数的作用域）的关联可以使用 `.joins`、`.preload` 以及 `.eager_load` 的行为
  ([Commit](https://github.com/rails/rails/commit/ed56e596a0467390011bc9d56d462539776adac1))


### 值得一提的变化

*   `SchemaDumper` 对 `create_table` 使用 `force: :cascade`。这样就可以重载加入外键的纲要文件。

*   单数关联增加 `:required` 选项，用来定义关联的存在性验证。
  ([Pull Request](https://github.com/rails/rails/pull/16056))

*   `ActiveRecord::Dirty` 现在会侦测可变数值的变化。序列化过的属性只在有变更时才会保存。
    修复了像是 PostgreSQL 不会侦测到字串或 JSON 栏位改变的问题。
  (Pull Requests [1](https://github.com/rails/rails/pull/15674),
  [2](https://github.com/rails/rails/pull/15786),
  [3](https://github.com/rails/rails/pull/15788))

*   导入 `bin/rake db:purge` 任务，用来清空当前环境的数据库。
  ([Commit](https://github.com/rails/rails/commit/e2f232aba15937a4b9d14bd91e0392c6d55be58d))

*   导入 `ActiveRecord::Base#validate!`，若记录不合法时会抛出 `RecordInvalid`。
  ([Pull Request](https://github.com/rails/rails/pull/8639))

*   引入 `#validate` 作为 `#valid?` 的别名。
  ([Pull Request](https://github.com/rails/rails/pull/14456))

*   `#touch` 现在可一次对多属性操作。
  ([Pull Request](https://github.com/rails/rails/pull/14423))

*   PostgreSQL 适配器现在支持 PostgreSQL 9.4+ 的 `jsonb` 数据类型。
    ([Pull Request](https://github.com/rails/rails/pull/16220))

*   新增 PostgreSQL 适配器的 `citext` 支持。
  ([Pull Request](https://github.com/rails/rails/pull/12523))

*   PostgreSQL 与 SQLite 适配器不再默认限制字串只能 255 字符。
  ([Pull Request](https://github.com/rails/rails/pull/14579))

*   新增 PostgreSQL 适配器的使用自建的范围类型支持。
  ([Commit](https://github.com/rails/rails/commit/4cb47167e747e8f9dc12b0ddaf82bdb68c03e032))

*   `sqlite3:///some/path` 现在可以解析系统的绝对路径 `/some/path`。
  相对路径请使用 `sqlite3:some/path`。(先前是 `sqlite3:///some/path`
  会解析成 `some/path`。这个行为已在 Rails 4.1 被弃用了。  Rails 4.1.)
  ([Pull Request](https://github.com/rails/rails/pull/14569))

*   新增 MySQL 5.6 以上版本的 fractional seconds 支持。
  (Pull Request [1](https://github.com/rails/rails/pull/8240), [2](https://github.com/rails/rails/pull/14359))

*   新增 `ActiveRecord::Base` 对象的 `#pretty_print` 方法。
  ([Pull Request](https://github.com/rails/rails/pull/15172))

*   `ActiveRecord::Base#reload` 现在的行为同 `m = Model.find(m.id)`，代表不再给自定的
  `select` 保存额外的属性。
  ([Pull Request](https://github.com/rails/rails/pull/15866))

*   `ActiveRecord::Base#reflections` 现在返回的 hash 的键是字串类型，而不是符号。 ([Pull Request](https://github.com/rails/rails/pull/17718))

*   迁移的 `references` 方法支持 `type` 选项，用来指定外键的类型，比如 `:uuid`。
    ([Pull Request](https://github.com/rails/rails/pull/16231))

Active Model
------------

请参考 [CHANGELOG][active-model] 来了解更多细节。

### 移除

* 移除了 `Validator#setup`，没有替代方案。
  ([Pull Request](https://github.com/rails/rails/pull/15617))

### 弃用

*   弃用 `reset_#{attribute}`，请改用 `restore_#{attribute}`。
    ([Pull Request](https://github.com/rails/rails/pull/16180))

*   弃用 `ActiveModel::Dirty#reset_changes`，请改用 `#clear_changes_information`。
    ([Pull Request](https://github.com/rails/rails/pull/16180))

### 值得一提的变化

*    引入 `#validate` 作为 `#valid?` 的别名。
  ([Pull Request](https://github.com/rails/rails/pull/14456))

*   `ActiveModel::Dirty` 导入 `restore_attributes` 方法，用来回复已修改的属性到先前的数值。
    (Pull Request [1](https://github.com/rails/rails/pull/14861),
    [2](https://github.com/rails/rails/pull/16180))

*   `has_secure_password` 现在缺省允许空密码（只含空白的密码也算空密码）。
    ([Pull Request](https://github.com/rails/rails/pull/16412))

*    验证启用时，`has_secure_password` 现在会检查密码是否少于 72 个字符。
  ([Pull Request](https://github.com/rails/rails/pull/15708))

Active Support
--------------

请参考 [CHANGELOG][active-support] 来了解更多细节。

### 移除

*   移除弃用的 `Numeric#ago`、`Numeric#until`、`Numeric#since` 以及
  `Numeric#from_now`. ([Commit](https://github.com/rails/rails/commit/f1eddea1e3f6faf93581c43651348f48b2b7d8bb))

*   移除弃用 `ActiveSupport::Callbacks` 基于字串的终止符。
  ([Pull Request](https://github.com/rails/rails/pull/15100))

### 弃用

*   弃用 `Kernel#silence_stderr`、`Kernel#capture` 以及 `Kernel#quietly` 方法，没有替代方案。([Pull Request](https://github.com/rails/rails/pull/13392))

*   弃用 `Class#superclass_delegating_accessor`，请改用 `Class#class_attribute`。
  ([Pull Request](https://github.com/rails/rails/pull/14271))

*   弃用 `ActiveSupport::SafeBuffer#prepend!` 请改用 `ActiveSupport::SafeBuffer#prepend`（两者功能相同）。
  ([Pull Request](https://github.com/rails/rails/pull/14529))

### 值得一提的变化

*   导入新的设置选项： `active_support.test_order`，用来指定测试执行的顺序，预设是 `:sorted`，在 Rails 5.0 将会改成 `:random`。([Commit](https://github.com/rails/rails/commit/53e877f7d9291b2bf0b8c425f9e32ef35829f35b))

*   `Object#try` 和 `Object#try!` 方法现在不需要消息接收者也可以使用。
    ([Commit](https://github.com/rails/rails/commit/5e51bdda59c9ba8e5faf86294e3e431bd45f1830),
    [Pull Request](https://github.com/rails/rails/pull/17361))

*   `travel_to` 测试辅助方法现在会把 `usec` 部分截断为 0。
    ([Commit](https://github.com/rails/rails/commit/9f6e82ee4783e491c20f5244a613fdeb4024beb5))

*   导入 `Object#itself` 作为 identity 函数（返回自身的函数）。(Commit [1](https://github.com/rails/rails/commit/702ad710b57bef45b081ebf42e6fa70820fdd810) 和 [2](https://github.com/rails/rails/commit/64d91122222c11ad3918cc8e2e3ebc4b0a03448a))

*   `Object#with_options` 方法现在不需要消息接收者也可以使用。
    ([Pull Request](https://github.com/rails/rails/pull/16339))

*   导入 `String#truncate_words` 方法，可指定要单词截断至几个单词。
    ([Pull Request](https://github.com/rails/rails/pull/16190))

*   新增 `Hash#transform_values` 与 `Hash#transform_values!` 方法，来简化 Hash 值需要更新、但键保留不变这样的常见模式。
  ([Pull Request](https://github.com/rails/rails/pull/15819))

*   `humanize` 现在会去掉前面的底线。
  ([Commit](https://github.com/rails/rails/commit/daaa21bc7d20f2e4ff451637423a25ff2d5e75c7))

*   导入 `Concern#class_methods` 来取代 `module ClassMethods` 以及 `Kernel#concern`，来避免使用 `module Foo; extend ActiveSupport::Concern; end` 这样的样板。
  ([Commit](https://github.com/rails/rails/commit/b16c36e688970df2f96f793a759365b248b582ad))

*   新增一篇[指南](constant_autoloading_and_reloading.html)，关于常量的载入与重载。

致谢
----

许多人花费宝贵的时间贡献至 Rails 项目，使 Rails 成为更稳定、更强韧的网络框架，参考[完整的 Rails 贡献者清单](http://contributors.rubyonrails.org/)，感谢所有的贡献者！

[railties]:       https://github.com/rails/rails/blob/4-2-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/4-2-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/4-2-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/4-2-stable/actionmailer/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/4-2-stable/activerecord/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/4-2-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/4-2-stable/activesupport/CHANGELOG.md
