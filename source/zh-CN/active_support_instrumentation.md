Active Support 监测程序
=======================

Active Support 是 Rails 核心的一部分，提供 Ruby 语言扩展、实用方法等。其中包括一份监测 API，在应用中可以用它测度 Ruby 代码（如 Rails 应用或框架自身）中的特定操作。不过，这个 API 不限于只能在 Rails 中使用，如果愿意，也可以在其他 Ruby 脚本中使用。

本文教你如何使用 Active Support 中的监测 API 测度 Rails 和其他 Ruby 代码中的事件。

读完本文后，您将学到：

- 使用监测程序能做什么；

- Rails 框架为监测提供的钩子；

- 订阅钩子；

- 自定义监测点。

NOTE: 本文原文尚未完工！

监测程序简介
------------

Active Support 提供的监测 API 允许开发者提供钩子，供其他开发者订阅。在 Rails 框架中，有很多。通过这个 API，开发者可以选择在应用或其他 Ruby 代码中发生特定事件时接收通知。

例如，Active Record 中有一个钩子，在每次使用 SQL 查询数据库时调用。开发者可以订阅这个钩子，记录特定操作执行的查询次数。还有一个钩子在控制器的动作执行前后调用，记录动作的执行时间。

在应用中甚至还可以自己创建事件，然后订阅。

Rails 框架中的钩子
------------------

Ruby on Rails 框架为很多常见的事件提供了钩子。下面详述。

Action Controller
-----------------

### write\_fragment.action\_controller

| 键 | 值 |
|---|---|
| :key | 完整的键 |

```ruby
{
  key: 'posts/1-dashboard-view'
}
```

### read\_fragment.action\_controller

| 键 | 值 |
|---|---|
| :key | 完整的键 |

```ruby
{
  key: 'posts/1-dashboard-view'
}
```

### expire\_fragment.action\_controller

| 键 | 值 |
|---|---|
| :key | 完整的键 |

```ruby
{
  key: 'posts/1-dashboard-view'
}
```

### exist\_fragment?.action\_controller

| 键 | 值 |
|---|---|
| :key | 完整的键 |

```ruby
{
  key: 'posts/1-dashboard-view'
}
```

### write\_page.action\_controller

| 键 | 值 |
|---|---|
| :path | 完整的路径 |

```ruby
{
  path: '/users/1'
}
```

### expire\_page.action\_controller

| 键 | 值 |
|---|---|
| :path | 完整的路径 |

```ruby
{
  path: '/users/1'
}
```

### start\_processing.action\_controller

| 键 | 值 |
|---|---|
| :controller | 控制器名 |
| :action | 动作名 |
| :params | 请求参数散列，不过滤 |
| :headers | 请求首部 |
| :format | html、js、json、xml 等 |
| :method | HTTP 请求方法 |
| :path | 请求路径 |

```ruby
{
  controller: "PostsController",
  action: "new",
  params: { "action" => "new", "controller" => "posts" },
  headers: #<ActionDispatch::Http::Headers:0x0055a67a519b88>,
  format: :html,
  method: "GET",
  path: "/posts/new"
}
```

### process\_action.action\_controller

| 键 | 值 |
|---|---|
| :controller | 控制器名 |
| :action | 动作名 |
| :params | 请求参数散列，不过滤 |
| :headers | 请求首部 |
| :format | html、js、json、xml 等 |
| :method | HTTP 请求方法 |
| :path | 请求路径 |
| :status | HTTP 状态码 |
| :view_runtime | 花在视图上的时间量（ms） |
| :db_runtime | 执行数据库查询的时间量（ms） |

```ruby
{
  controller: "PostsController",
  action: "index",
  params: {"action" => "index", "controller" => "posts"},
  headers: #<ActionDispatch::Http::Headers:0x0055a67a519b88>,
  format: :html,
  method: "GET",
  path: "/posts",
  status: 200,
  view_runtime: 46.848,
  db_runtime: 0.157
}
```

### send\_file.action\_controller

| 键 | 值 |
|---|---|
| :path | 文件的完整路径 |

TIP: 调用方可以添加额外的键。

### send\_data.action\_controller

`ActionController` 在载荷（payload）中没有任何特定的信息。所有选项都传到载荷中。

### redirect\_to.action\_controller

| 键 | 值 |
|---|---|
| :status | HTTP 响应码 |
| :location | 重定向的 URL |

```ruby
{
  status: 302,
  location: "http://localhost:3000/posts/new"
}
```

### halted\_callback.action\_controller

| 键 | 值 |
|---|---|
| :filter | 过滤暂停的动作 |

```ruby
{
  filter: ":halting_filter"
}
```

Action View
-----------

### render\_template.action\_view

| 键 | 值 |
|---|---|
| :identifier | 模板的完整路径 |
| :layout | 使用的布局 |

```ruby
{
  identifier: "/Users/adam/projects/notifications/app/views/posts/index.html.erb",
  layout: "layouts/application"
}
```

### render-partial-action-view

| 键 | 值 |
|---|---|
| :identifier | 模板的完整路径 |

```ruby
{
  identifier: "/Users/adam/projects/notifications/app/views/posts/_form.html.erb"
}
```

### render\_collection.action\_view

| 键 | 值 |
|---|---|
| :identifier | 模板的完整路径 |
| :count | 集合的大小 |
| :cache_hits | 从缓存中获取的局部视图数量 |

仅当渲染集合时设定了 `cached: true` 选项，才有 `:cache_hits` 键。

```ruby
{
  identifier: "/Users/adam/projects/notifications/app/views/posts/_post.html.erb",
  count: 3,
  cache_hits: 0
}
```

Active Record
-------------

### sql.active\_record

| 键 | 值 |
|---|---|
| :sql | SQL 语句 |
| :name | 操作的名称 |
| :connection_id | self.object_id |
| :binds | 绑定的参数 |

TIP: 适配器也会添加数据。

```ruby
{
  sql: "SELECT \"posts\".* FROM \"posts\" ",
  name: "Post Load",
  connection_id: 70307250813140,
  binds: []
}
```

### instantiation.active\_record

| 键 | 值 |
|---|---|
| :record_count | 实例化记录的数量 |
| :class_name | 记录所属的类 |

```ruby
{
  record_count: 1,
  class_name: "User"
}
```

Action Mailer
-------------

### receive.action\_mailer

| 键 | 值 |
|---|---|
| :mailer | 邮件程序类的名称 |
| :message_id | 邮件的 ID，由 Mail gem 生成 |
| :subject | 邮件的主题 |
| :to | 邮件的收件地址 |
| :from | 邮件的发件地址 |
| :bcc | 邮件的密送地址 |
| :cc | 邮件的抄送地址 |
| :date | 发送邮件的日期 |
| :mail | 邮件的编码形式 |

```ruby
{
  mailer: "Notification",
  message_id: "4f5b5491f1774_181b23fc3d4434d38138e5@mba.local.mail",
  subject: "Rails Guides",
  to: ["users@rails.com", "ddh@rails.com"],
  from: ["me@rails.com"],
  date: Sat, 10 Mar 2012 14:18:09 +0100,
  mail: "..." # 为了节省空间，省略
}
```

### deliver.action\_mailer

| 键 | 值 |
|---|---|
| :mailer | 邮件程序类的名称 |
| :message_id | 邮件的 ID，由 Mail gem 生成 |
| :subject | 邮件的主题 |
| :to | 邮件的收件地址 |
| :from | 邮件的发件地址 |
| :bcc | 邮件的密送地址 |
| :cc | 邮件的抄送地址 |
| :date | 发送邮件的日期 |
| :mail | 邮件的编码形式 |

```ruby
{
  mailer: "Notification",
  message_id: "4f5b5491f1774_181b23fc3d4434d38138e5@mba.local.mail",
  subject: "Rails Guides",
  to: ["users@rails.com", "ddh@rails.com"],
  from: ["me@rails.com"],
  date: Sat, 10 Mar 2012 14:18:09 +0100,
  mail: "..." # 为了节省空间，省略
}
```

Active Support
--------------

### cache\_read.active\_support

| 键 | 值 |
|---|---|
| :key | 存储器中使用的键 |
| :hit | 是否读取了缓存 |
| :super_operation | 如果使用 #fetch 读取了，添加 :fetch |

### cache\_generate.active\_support

仅当使用块调用 `#fetch` 时使用这个事件。

| 键 | 值 |
|---|---|
| :key | 存储器中使用的键 |

TIP: 写入存储器时，传给 `fetch` 的选项会合并到载荷中。

```ruby
{
  key: 'name-of-complicated-computation'
}
```

### cache\_fetch\_hit.active\_support

仅当使用块调用 `#fetch` 时使用这个事件。

| 键 | 值 |
|---|---|
| :key | 存储器中使用的键 |

TIP: 传给 `fetch` 的选项会合并到载荷中。

```ruby
{
  key: 'name-of-complicated-computation'
}
```

### cache\_write.active\_support

| 键 | 值 |
|---|---|
| :key | 存储器中使用的键 |

TIP: 缓存存储器可能会添加其他键。

```ruby
{
  key: 'name-of-complicated-computation'
}
```

### cache\_delete.active\_support

| 键 | 值 |
|---|---|
| :key | 存储器中使用的键 |

```ruby
{
  key: 'name-of-complicated-computation'
}
```

### cache\_exist?.active\_support

| 键 | 值 |
|---|---|
| :key | 存储器中使用的键 |

```ruby
{
  key: 'name-of-complicated-computation'
}
```

Active Job
----------

### enqueue\_at.active\_job

| 键 | 值 |
|---|---|
| :adapter | 处理作业的 QueueAdapter 对象 |
| :job | 作业对象 |

### enqueue.active\_job

| 键 | 值 |
|---|---|
| :adapter | 处理作业的 QueueAdapter 对象 |
| :job | 作业对象 |

### perform\_start.active\_job

| 键 | 值 |
|---|---|
| :adapter | 处理作业的 QueueAdapter 对象 |
| :job | 作业对象 |

### perform.active\_job

| 键 | 值 |
|---|---|
| :adapter | 处理作业的 QueueAdapter 对象 |
| :job | 作业对象 |

Railties
--------

### load\_config\_initializer.railties

| 键 | 值 |
|---|---|
| :initializer | 从 config/initializers 中加载的初始化脚本的路径 |

Rails
-----

### deprecation.rails

| 键 | 值 |
|---|---|
| :message | 弃用提醒 |
| :callstack | 弃用的位置 |

订阅事件
--------

订阅事件是件简单的事，在 `ActiveSupport::Notifications.subscribe` 的块中监听通知即可。

这个块接收下述参数：

- 事件的名称

- 开始时间

- 结束时间

- 事件的唯一 ID

- 载荷（参见前述各节）

```ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, started, finished, unique_id, data|
  # 自己编写的其他代码
  Rails.logger.info "#{name} Received!"
end
```

每次都定义这些块参数很麻烦，我们可以使用 `ActiveSupport::Notifications::Event` 创建块参数，如下：

```ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
  event = ActiveSupport::Notifications::Event.new *args

  event.name      # => "process_action.action_controller"
  event.duration  # => 10 (in milliseconds)
  event.payload   # => {:extra=>information}

  Rails.logger.info "#{event} Received!"
end
```

多数时候，我们只关注数据本身。下面是只获取数据的简洁方式：

```ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
  data = args.extract_options!
  data # { extra: :information }
end
```

此外，还可以订阅匹配正则表达式的事件。这样可以一次订阅多个事件。下面是订阅 `ActionController` 中所有事件的方式：

```ruby
ActiveSupport::Notifications.subscribe /action_controller/ do |*args|
  # 审查所有 ActionController 事件
end
```

自定义事件
----------

自己添加事件也很简单，繁重的工作都由 `ActiveSupport::Notifications` 代劳，我们只需调用 `instrument`，并传入 `name`、`payload` 和一个块。通知在块返回后发送。`ActiveSupport` 会生成起始时间和唯一的 ID。传给 `instrument` 调用的所有数据都会放入载荷中。

下面举个例子：

```ruby
ActiveSupport::Notifications.instrument "my.custom.event", this: :data do
  # 自己编写的其他代码
end
```

然后可以使用下述代码监听这个事件：

```ruby
ActiveSupport::Notifications.subscribe "my.custom.event" do |name, started, finished, unique_id, data|
  puts data.inspect # {:this=>:data}
end
```

自己定义事件时，应该遵守 Rails 的约定。事件名称的格式是 `event.library`。如果应用发送推文，应该把事件命名为 `tweet.twitter`。
