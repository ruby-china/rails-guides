
Active Job 基础
=================

本文提供开始创建任务、将任务加入队列和后台执行任务的所有知识。

读完本文，你将学到:

* 如何新建任务
* 如何将任务加入队列
* 如何在后台运行任务
* 如何在应用中异步发送邮件

--------------------------------------------------------------------------------


 简介
-------------

Active Job 是用来声明任务，并把任务放到多种多样的队列后台中执行的框架。从定期地安排清理，费用账单到发送邮件，任何事情都可以是任务。任何可以切分为小的单元和并行执行的任务都可以用 Active Job 来执行。


Active Job 的目标
----------------------

主要是确保所有的 Rails 程序有一致任务框架，即便是以 “立即执行”的形式存在。然后可以基于 Active Job 来新建框架功能和其他的 RubyGems， 而不用担心多种任务后台，比如 Dalayed Job 和 Resque 之间 API 的差异。之后，选择队列后台更多会变成运维方面的考虑，这样就能切换后台而无需重写任务代码。


创建一个任务
---------

本节将会逐步地创建任务然后把任务加入队列中。

### 创建任务

Active Job 提供了 Rails 生成器来创建任务。以下代码会在 `app/jobs` 中新建一个任务,（并且会在 `test/jobs` 中创建测试用例）：

```bash
$ bin/rails generate job guests_cleanup
invoke  test_unit
create    test/jobs/guests_cleanup_job_test.rb
create  app/jobs/guests_cleanup_job.rb
```

也可以创建运行在一个特定队列上的任务：

```bash
$ bin/rails generate job guests_cleanup --queue urgent
```

如果不想使用生成器，需要自己创建文件，并且替换掉 `app/jobs`。确保任务继承自 `ActiveJob::Base` 即可。

以下是一个任务示例:

```ruby
class GuestsCleanupJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
    # Do something later
  end
end
```

### 任务加入队列

将任务加入到队列中：

```ruby
# 将加入到队列系统中任务立即执行
MyJob.perform_later record
```

```ruby
# 在明天中午执行加入队列的任务
MyJob.set(wait_until: Date.tomorrow.noon).perform_later(record)
```

```ruby
# 一星期后执行加入到队列的任务
MyJob.set(wait: 1.week).perform_later(record)
```

就这么简单！


任务执行
-------

如果没有设置连接器，任务会立即执行。


### 后台

Active Job 内建支持多种队列后台连接器（Sidekiq、Resque、Delayed Job 等）。最新的连接器的列表详见 [ActiveJob::QueueAdapters](http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html) 的 API 文件。


### 设置后台

设置队列后台很简单：

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    # Be sure to have the adapter's gem in your Gemfile and follow
    # the adapter's specific installation and deployment instructions.
    config.active_job.queue_adapter = :sidekiq
  end
end
```


队列
----

大多数连接器支持多种队列。用 Active Job 可以安排任务运行在特定的队列：

```ruby
class GuestsCleanupJob < ActiveJob::Base
  queue_as :low_priority
  #....
end
```

在 `application.rb` 中通过  `config.active_job.queue_name_prefix` 来设置所有任务的队列名称的前缀。

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.active_job.queue_name_prefix = Rails.env
  end
end

# app/jobs/guests_cleanup.rb
class GuestsCleanupJob < ActiveJob::Base
  queue_as :low_priority
  #....
end

# Now your job will run on queue production_low_priority on your
# production environment and on staging_low_priority on your staging
# environment
```

默认队列名称的前缀是 `_`。可以设置 `application.rb` 里 `config.active_job.queue_name_delimiter` 的值来改变：

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.active_job.queue_name_prefix = Rails.env
    config.active_job.queue_name_delimiter = '.'
  end
end

# app/jobs/guests_cleanup.rb
class GuestsCleanupJob < ActiveJob::Base
  queue_as :low_priority
  #....
end

# Now your job will run on queue production.low_priority on your
# production environment and on staging.low_priority on your staging
# environment
```

如果想要更细致的控制任务的执行，可以传 `:queue` 选项给 `#set` 方法：

```ruby
MyJob.set(queue: :another_queue).perform_later(record)
```

为了在任务级别控制队列，可以传递一个块给 `#queue_as`。块会在任务的上下文中执行（所以能获得 `self.arguments`）并且必须返回队列的名字：

```ruby
class ProcessVideoJob < ActiveJob::Base
  queue_as do
    video = self.arguments.first
    if video.owner.premium?
      :premium_videojobs
    else
      :videojobs
    end
  end

  def perform(video)
    # do process video
  end
end

ProcessVideoJob.perform_later(Video.last)
```

NOTE: 确认运行的队列后台“监听”队列的名称。某些后台需要明确的指定要“监听”队列的名称。


回调
---------

Active Job 在一个任务的生命周期里提供了钩子。回调允许在任务的生命周期中触发逻辑。

### 可用的回调

* `before_enqueue`
* `around_enqueue`
* `after_enqueue`
* `before_perform`
* `around_perform`
* `after_perform`

### 用法

```ruby
class GuestsCleanupJob < ActiveJob::Base
  queue_as :default

  before_enqueue do |job|
    # do something with the job instance
  end

  around_perform do |job, block|
    # do something before perform
    block.call
    # do something after perform
  end

  def perform
    # Do something later
  end
end
```


Action Mailer
----------------

现代网站应用中最常见的任务之一是，在请求响应周期外发送 Email，这样所有用户不需要焦急地等待邮件的发送。Active Job 集成到 Action Mailer 里了，所以能够简单的实现异步发送邮件：

```ruby
# If you want to send the email now use #deliver_now
UserMailer.welcome(@user).deliver_now

# If you want to send the email through Active Job use #deliver_later
UserMailer.welcome(@user).deliver_later
```


GlobalID
-----------

Active Job 支持 GlobalID 作为参数。这样传递运行中的 Active Record 对象到任务中，来取代通常需要序列化的 class/id 对。之前任务看起来是像这样：

```ruby
class TrashableCleanupJob < ActiveJob::Base
  def perform(trashable_class, trashable_id, depth)
    trashable = trashable_class.constantize.find(trashable_id)
    trashable.cleanup(depth)
  end
end
```

现在可以简化为:

```ruby
class TrashableCleanupJob < ActiveJob::Base
  def perform(trashable, depth)
    trashable.cleanup(depth)
  end
end
```


异常
-------

Active Job 提供了在任务执行期间捕获异常的方法：

```ruby
class GuestsCleanupJob < ActiveJob::Base
  queue_as :default

  rescue_from(ActiveRecord::RecordNotFound) do |exception|
   # do something with the exception
  end

  def perform
    # Do something later
  end
end
```
