Active Job 基础
===============

本文全面说明创建、入队和执行后台作业的基础知识。

读完本文后，您将学到：

- 如何创建作业；

- 如何入队作业；

- 如何在后台运行作业；

- 如何在应用中异步发送电子邮件。

--------------------------------------------------------------------------------

简介
----

Active Job 框架负责声明作业，在各种队列后端中运行。作业各种各样，可以是定期清理、账单支付和寄信。其实，任何可以分解且并行运行的工作都可以。

Active Job 的作用
-----------------

主要作用是确保所有 Rails 应用都有作业基础设施。这样便可以在此基础上构建各种功能和其他 gem，而无需担心不同作业运行程序（如 Delayed Job 和 Resque）的 API 之间的差异。此外，选用哪个队列后端只是战术问题。而且，切换队列后端也不用重写作业。

NOTE: Rails 默认实现了立即运行的队列运行程序。因此，队列中的各个作业会立即运行。

创建作业
--------

本节逐步说明创建和入队作业的过程。

### 创建作业

Active Job 提供了一个 Rails 生成器，用于创建作业。下述命令在 `app/jobs` 目录中创建一个作业（还在 `test/jobs` 目录中创建相关的测试用例）：

```sh
$ bin/rails generate job guests_cleanup
invoke  test_unit
create    test/jobs/guests_cleanup_job_test.rb
create  app/jobs/guests_cleanup_job.rb
```

还可以创建在指定队列中运行的作业：

```sh
$ bin/rails generate job guests_cleanup --queue urgent
```

如果不想使用生成器，可以自己动手在 `app/jobs` 目录中新建文件，不过要确保继承自 `ApplicationJob`。

看一下作业：

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  def perform(*guests)
    # 稍后做些事情
  end
end
```

注意，`perform` 方法的参数是任意个。

### 入队作业

像下面这样入队作业：

```ruby
# 入队作业，作业在队列系统空闲时立即执行
GuestsCleanupJob.perform_later guest
```

```ruby
# 入队作业，在明天中午执行
GuestsCleanupJob.set(wait_until: Date.tomorrow.noon).perform_later(guest)
```

```ruby
# 入队作业，在一周以后执行
GuestsCleanupJob.set(wait: 1.week).perform_later(guest)
```

```ruby
# `perform_now` 和 `perform_later` 会在幕后调用 `perform`
# 因此可以传入任意个参数
GuestsCleanupJob.perform_later(guest1, guest2, filter: 'some_filter')
```

就这么简单！

执行作业
--------

在生产环境中入队和执行作业需要使用队列后端，即要为 Rails 提供一个第三方队列库。Rails 本身只提供了一个进程内队列系统，把作业存储在 RAM 中。如果进程崩溃，或者设备重启了，默认的异步后端会丢失所有作业。这对小型应用或不重要的作业来说没什么，但是生产环境中的多数应用应该挑选一个持久后端。

### 后端

Active Job 为多种队列后端（Sidekiq、Resque、Delayed Job，等等）内置了适配器。最新的适配器列表参见 [`ActiveJob::QueueAdapters` 的 API 文档](http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html)。

### 设置后端

队列后端易于设置：

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    # 要把适配器的 gem 写入 Gemfile
    # 请参照适配器的具体安装和部署说明
    config.active_job.queue_adapter = :sidekiq
  end
end
```

也可以在各个作业中配置后端：

```ruby
class GuestsCleanupJob < ApplicationJob
  self.queue_adapter = :resque
  #....
end

# 现在，这个作业使用 `resque` 作为后端队列适配器
# 把 `config.active_job.queue_adapter` 配置覆盖了
```

### 启动后端

Rails 应用中的作业并行运行，因此多数队列库要求为自己启动专用的队列服务（与启动 Rails 应用的服务不同）。启动队列后端的说明参见各个库的文档。

下面列出部分文档：

- [Sidekiq](https://github.com/mperham/sidekiq/wiki/Active-Job)

- [Resque](https://github.com/resque/resque/wiki/ActiveJob)

- [Sucker Punch](https://github.com/brandonhilkert/sucker_punch#active-job)

- [Queue Classic](https://github.com/QueueClassic/queue_classic#active-job)

队列
----

多数适配器支持多个队列。Active Job 允许把作业调度到具体的队列中：

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  #....
end
```

队列名称可以使用 `application.rb` 文件中的 `config.active_job.queue_name_prefix` 选项配置前缀：

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.active_job.queue_name_prefix = Rails.env
  end
end

# app/jobs/guests_cleanup_job.rb
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  #....
end

# 在生产环境中，作业在 production_low_priority 队列中运行
# 在交付准备环境中，作业在 staging_low_priority 队列中运行
```

默认的队列名称前缀分隔符是 `'_'`。这个值可以使用 `application.rb` 文件中的 `config.active_job.queue_name_delimiter` 选项修改：

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.active_job.queue_name_prefix = Rails.env
    config.active_job.queue_name_delimiter = '.'
  end
end

# app/jobs/guests_cleanup_job.rb
class GuestsCleanupJob < ApplicationJob
  queue_as :low_priority
  #....
end

# 在生产环境中，作业在 production.low_priority 队列中运行
# 在交付准备环境中，作业在 staging.low_priority 队列中运行
```

如果想更进一步控制作业在哪个队列中运行，可以把 `:queue` 选项传给 `#set` 方法：

```ruby
MyJob.set(queue: :another_queue).perform_later(record)
```

如果想在作业层控制队列，可以把一个块传给 `#queue_as` 方法。那个块在作业的上下文中执行（因此可以访问 `self.arguments`），必须返回队列的名称：

```ruby
class ProcessVideoJob < ApplicationJob
  queue_as do
    video = self.arguments.first
    if video.owner.premium?
      :premium_videojobs
    else
      :videojobs
    end
  end

  def perform(video)
    # 处理视频
  end
end

ProcessVideoJob.perform_later(Video.last)
```

NOTE: 确保队列后端“监听”着队列名称。某些后端要求指定要监听的队列。

回调
----

Active Job 在作业的生命周期内提供了多个钩子。回调用于在作业的生命周期内触发逻辑。

### 可用的回调

- `before_enqueue`

- `around_enqueue`

- `after_enqueue`

- `before_perform`

- `around_perform`

- `after_perform`

### 用法

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  before_enqueue do |job|
    # 对作业实例做些事情
  end

  around_perform do |job, block|
    # 在执行之前做些事情
    block.call
    # 在执行之后做些事情
  end

  def perform
    # 稍后做些事情
  end
end
```

Action Mailer
-------------

对现代的 Web 应用来说，最常见的作业是在请求-响应循环之外发送电子邮件，这样用户无需等待。Active Job 与 Action Mailer 是集成的，因此可以轻易异步发送电子邮件：

```ruby
# 如需想现在发送电子邮件，使用 #deliver_now
UserMailer.welcome(@user).deliver_now

# 如果想通过 Active Job 发送电子邮件，使用 #deliver_later
UserMailer.welcome(@user).deliver_later
```

国际化
------

创建作业时，使用 `I18n.locale` 设置。如果异步发送电子邮件，可能用得到：

```ruby
I18n.locale = :eo

UserMailer.welcome(@user).deliver_later # 使用世界语本地化电子邮件
```

GlobalID
--------

Active Job 支持参数使用 GlobalID。这样便可以把 Active Record 对象传给作业，而不用传递类和 ID，再自己反序列化。以前，要这么定义作业：

```ruby
class TrashableCleanupJob < ApplicationJob
  def perform(trashable_class, trashable_id, depth)
    trashable = trashable_class.constantize.find(trashable_id)
    trashable.cleanup(depth)
  end
end
```

现在可以简化成这样：

```ruby
class TrashableCleanupJob < ApplicationJob
  def perform(trashable, depth)
    trashable.cleanup(depth)
  end
end
```

为此，模型类要混入 `GlobalID::Identification`。Active Record 模型类默认都混入了。

异常
----

Active Job 允许捕获执行作业过程中抛出的异常：

```ruby
class GuestsCleanupJob < ApplicationJob
  queue_as :default

  rescue_from(ActiveRecord::RecordNotFound) do |exception|
   # 处理异常
  end

  def perform
    # 稍后做些事情
  end
end
```

### 反序列化

有了 GlobalID，可以序列化传给 `#perform` 方法的整个 Active Record 对象。

如果在作业入队之后、调用 `#perform` 方法之前删除了传入的记录，Active Job 会抛出 `ActiveJob::DeserializationError` 异常。

测试作业
--------

测试作业的详细说明参见 [测试指南](testing.html#测试作业)。
