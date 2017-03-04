调试 Rails 应用
===============

本文介绍如何调试 Rails 应用。

读完本文后，您将学到：

- 调试的目的；

- 如何追查测试没有发现的问题；

- 不同的调试方法；

- 如何分析堆栈跟踪。

--------------------------------------------------------------------------------

调试相关的视图辅助方法
----------------------

一个常见的需求是查看变量的值。在 Rails 中，可以使用下面这三个方法：

- `debug`

- `to_yaml`

- `inspect`

### `debug`

`debug` 方法使用 YAML 格式渲染对象，把结果放在 `<pre>` 标签中，可以把任何对象转换成人类可读的数据格式。例如，在视图中有以下代码：

```erb
<%= debug @article %>
<p>
  <b>Title:</b>
  <%= @article.title %>
</p>
```

渲染后会看到如下结果：

```yaml
--- !ruby/object Article
attributes:
  updated_at: 2008-09-05 22:55:47
  body: It's a very helpful guide for debugging your Rails app.
  title: Rails debugging guide
  published: t
  id: "1"
  created_at: 2008-09-05 22:55:47
attributes_cache: {}


Title: Rails debugging guide
```

### `to_yaml`

在任何对象上调用 `to_yaml` 方法可以把对象转换成 YAML。转换得到的对象可以传给 `simple_format` 辅助方法，格式化输出。`debug` 就是这么做的：

```erb
<%= simple_format @article.to_yaml %>
<p>
  <b>Title:</b>
  <%= @article.title %>
</p>
```

渲染后得到的结果如下：

```yaml
--- !ruby/object Article
attributes:
updated_at: 2008-09-05 22:55:47
body: It's a very helpful guide for debugging your Rails app.
title: Rails debugging guide
published: t
id: "1"
created_at: 2008-09-05 22:55:47
attributes_cache: {}

Title: Rails debugging guide
```

### `inspect`

另一个用于显示对象值的方法是 `inspect`，显示数组和散列时使用这个方法特别方便。`inspect` 方法以字符串的形式显示对象的值。例如：

```erb
<%= [1, 2, 3, 4, 5].inspect %>
<p>
  <b>Title:</b>
  <%= @article.title %>
</p>
```

渲染后得到的结果如下：

    [1, 2, 3, 4, 5]

    Title: Rails debugging guide

日志记录器
----------

运行时把信息写入日志文件也很有用。Rails 分别为各个运行时环境维护着单独的日志文件。

### 日志记录器是什么？

Rails 使用 `ActiveSupport::Logger` 类把信息写入日志。当然也可以换用其他库，比如 `Log4r`。

若想替换日志库，可以在 `config/application.rb` 或其他环境的配置文件中设置，例如：

```ruby
config.logger = Logger.new(STDOUT)
config.logger = Log4r::Logger.new("Application Log")
```

或者在 `config/environment.rb` 中添加下述代码中的某一行：

```ruby
Rails.logger = Logger.new(STDOUT)
Rails.logger = Log4r::Logger.new("Application Log")
```

TIP: 默认情况下，日志文件都保存在 `Rails.root/log/` 目录中，日志文件的名称对应于各个环境。

### 日志等级

如果消息的日志等级等于或高于设定的等级，就会写入对应的日志文件中。如果想知道当前的日志等级，可以调用 `Rails.logger.level` 方法。

可用的日志等级包括 `:debug`、`:info`、`:warn`、`:error`、`:fatal` 和 `:unknown`，分别对应数字 0-5。修改默认日志等级的方式如下：

```ruby
config.log_level = :warn # 在环境的配置文件中
Rails.logger.level = 0 # 任何时候
```

这么设置在开发环境和交付准备环境中很有用，在生产环境中则不会写入大量不必要的信息。

TIP: Rails 为所有环境设定的默认日志等级是 `debug`。

### 发送消息

把消息写入日志文件可以在控制器、模型或邮件程序中调用 `logger.(debug|info|warn|error|fatal)` 方法。

```ruby
logger.debug "Person attributes hash: #{@person.attributes.inspect}"
logger.info "Processing the request..."
logger.fatal "Terminating application, raised unrecoverable error!!!"
```

下面这个例子增加了额外的写日志功能：

```ruby
class ArticlesController < ApplicationController
  # ...

  def create
    @article = Article.new(params[:article])
    logger.debug "New article: #{@article.attributes.inspect}"
    logger.debug "Article should be valid: #{@article.valid?}"

    if @article.save
      flash[:notice] =  'Article was successfully created.'
      logger.debug "The article was saved and now the user is going to be redirected..."
      redirect_to(@article)
    else
      render action: "new"
    end
  end

  # ...
end
```

执行上述动作后得到的日志如下：

    Processing ArticlesController#create (for 127.0.0.1 at 2008-09-08 11:52:54) [POST]
      Session ID: BAh7BzoMY3NyZl9pZCIlMDY5MWU1M2I1ZDRjODBlMzkyMWI1OTg2NWQyNzViZjYiCmZsYXNoSUM6J0FjdGl
    vbkNvbnRyb2xsZXI6OkZsYXNoOjpGbGFzaEhhc2h7AAY6CkB1c2VkewA=--b18cd92fba90eacf8137e5f6b3b06c4d724596a4
      Parameters: {"commit"=>"Create", "article"=>{"title"=>"Debugging Rails",
     "body"=>"I'm learning how to print in logs!!!", "published"=>"0"},
     "authenticity_token"=>"2059c1286e93402e389127b1153204e0d1e275dd", "action"=>"create", "controller"=>"articles"}
    New article: {"updated_at"=>nil, "title"=>"Debugging Rails", "body"=>"I'm learning how to print in logs!!!",
     "published"=>false, "created_at"=>nil}
    Article should be valid: true
      Article Create (0.000443)   INSERT INTO "articles" ("updated_at", "title", "body", "published",
     "created_at") VALUES('2008-09-08 14:52:54', 'Debugging Rails',
     'I''m learning how to print in logs!!!', 'f', '2008-09-08 14:52:54')
    The article was saved and now the user is going to be redirected...
    Redirected to # Article:0x20af760>
    Completed in 0.01224 (81 reqs/sec) | DB: 0.00044 (3%) | 302 Found [http://localhost/articles]

加入这种日志信息有助于发现异常现象。如果添加了额外的日志消息，记得要合理设定日志等级，免得把大量无用的消息写入生产环境的日志文件。

### 为日志打标签

运行多用户、多账户的应用时，使用自定义的规则筛选日志信息能节省很多时间。Active Support 中的 `TaggedLogging` 模块可以实现这种功能，可以在日志消息中加入二级域名、请求 ID 等有助于调试的信息。

```ruby
logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
logger.tagged("BCX") { logger.info "Stuff" }                            # Logs "[BCX] Stuff"
logger.tagged("BCX", "Jason") { logger.info "Stuff" }                   # Logs "[BCX] [Jason] Stuff"
logger.tagged("BCX") { logger.tagged("Jason") { logger.info "Stuff" } } # Logs "[BCX] [Jason] Stuff"
```

### 日志对性能的影响

如果把日志写入磁盘，肯定会对应用有点小的性能影响。不过可以做些小调整：`:debug` 等级比 `:fatal` 等级对性能的影响更大，因为写入的日志消息量更多。

如果按照下面的方式大量调用 `Logger`，也有潜在的问题：

```ruby
logger.debug "Person attributes hash: #{@person.attributes.inspect}"
```

在上述代码中，即使日志等级不包含 `:debug` 也会对性能产生影响。这是因为 Ruby 要初始化字符串，再花时间做插值。因此建议把代码块传给 `logger` 方法，只有等于或大于设定的日志等级时才执行其中的代码。重写后的代码如下：

```ruby
logger.debug {"Person attributes hash: #{@person.attributes.inspect}"}
```

代码块中的内容，即字符串插值，仅当允许 `:debug` 日志等级时才会执行。这种节省性能的方式只有在日志量比较大时才能体现出来，但却是个好的编程习惯。

使用 `byebug` gem 调试
----------------------

如果代码表现异常，可以在日志或控制台中诊断问题。但有时使用这种方法效率不高，无法找到导致问题的根源。如果需要检查源码，`byebug` gem 可以助你一臂之力。

如果想学习 Rails 源码但却无从下手，也可使用 `byebug` gem。随便找个请求，然后按照这里介绍的方法，从你编写的代码一直研究到 Rails 框架的代码。

### 安装

`byebug` gem 可以设置断点，实时查看执行的 Rails 代码。安装方法如下：

```sh
$ gem install byebug
```

在任何 Rails 应用中都可以使用 `byebug` 方法呼出调试器。

下面举个例子：

```ruby
class PeopleController < ApplicationController
  def new
    byebug
    @person = Person.new
  end
end
```

### Shell

在应用中调用 `byebug` 方法后，在启动应用的终端窗口中会启用调试器 shell，并显示调试器的提示符 `(byebug)`。提示符前面显示的是即将执行的代码，当前行以“=&gt;”标记，例如：

    [1, 10] in /PathTo/project/app/controllers/articles_controller.rb
        3:
        4:   # GET /articles
        5:   # GET /articles.json
        6:   def index
        7:     byebug
    =>  8:     @articles = Article.find_recent
        9:
       10:     respond_to do |format|
       11:       format.html # index.html.erb
       12:       format.json { render json: @articles }

    (byebug)

如果是浏览器中执行的请求到达了那里，当前浏览器标签页会处于挂起状态，等待调试器完工，跟踪完整个请求。

例如：

    => Booting Puma
    => Rails 5.0.0 application starting in development on http://0.0.0.0:3000
    => Run `rails server -h` for more startup options
    Puma starting in single mode...
    * Version 3.4.0 (ruby 2.3.1-p112), codename: Owl Bowl Brawl
    * Min threads: 5, max threads: 5
    * Environment: development
    * Listening on tcp://localhost:3000
    Use Ctrl-C to stop
    Started GET "/" for 127.0.0.1 at 2014-04-11 13:11:48 +0200
      ActiveRecord::SchemaMigration Load (0.2ms)  SELECT "schema_migrations".* FROM "schema_migrations"
    Processing by ArticlesController#index as HTML

    [3, 12] in /PathTo/project/app/controllers/articles_controller.rb
        3:
        4:   # GET /articles
        5:   # GET /articles.json
        6:   def index
        7:     byebug
    =>  8:     @articles = Article.find_recent
        9:
       10:     respond_to do |format|
       11:       format.html # index.html.erb
       12:       format.json { render json: @articles }
    (byebug)

现在可以深入分析应用的代码了。首先我们来查看一下调试器的帮助信息，输入 `help`：

    (byebug) help

      break      -- Sets breakpoints in the source code
      catch      -- Handles exception catchpoints
      condition  -- Sets conditions on breakpoints
      continue   -- Runs until program ends, hits a breakpoint or reaches a line
      debug      -- Spawns a subdebugger
      delete     -- Deletes breakpoints
      disable    -- Disables breakpoints or displays
      display    -- Evaluates expressions every time the debugger stops
      down       -- Moves to a lower frame in the stack trace
      edit       -- Edits source files
      enable     -- Enables breakpoints or displays
      finish     -- Runs the program until frame returns
      frame      -- Moves to a frame in the call stack
      help       -- Helps you using byebug
      history    -- Shows byebug's history of commands
      info       -- Shows several informations about the program being debugged
      interrupt  -- Interrupts the program
      irb        -- Starts an IRB session
      kill       -- Sends a signal to the current process
      list       -- Lists lines of source code
      method     -- Shows methods of an object, class or module
      next       -- Runs one or more lines of code
      pry        -- Starts a Pry session
      quit       -- Exits byebug
      restart    -- Restarts the debugged program
      save       -- Saves current byebug session to a file
      set        -- Modifies byebug settings
      show       -- Shows byebug settings
      source     -- Restores a previously saved byebug session
      step       -- Steps into blocks or methods one or more times
      thread     -- Commands to manipulate threads
      tracevar   -- Enables tracing of a global variable
      undisplay  -- Stops displaying all or some expressions when program stops
      untracevar -- Stops tracing a global variable
      up         -- Moves to a higher frame in the stack trace
      var        -- Shows variables and its values
      where      -- Displays the backtrace

    (byebug)

如果想查看前面十行代码，输入 `list-`（或 `l-`）。

    (byebug) l-

    [1, 10] in /PathTo/project/app/controllers/articles_controller.rb
       1  class ArticlesController < ApplicationController
       2    before_action :set_article, only: [:show, :edit, :update, :destroy]
       3
       4    # GET /articles
       5    # GET /articles.json
       6    def index
       7      byebug
       8      @articles = Article.find_recent
       9
       10      respond_to do |format|

这样我们就可以在文件内移动，查看 `byebug` 所在行上面的代码。如果想查看你在哪一行，输入 `list=`：

    (byebug) list=

    [3, 12] in /PathTo/project/app/controllers/articles_controller.rb
        3:
        4:   # GET /articles
        5:   # GET /articles.json
        6:   def index
        7:     byebug
    =>  8:     @articles = Article.find_recent
        9:
       10:     respond_to do |format|
       11:       format.html # index.html.erb
       12:       format.json { render json: @articles }
    (byebug)

### 上下文

开始调试应用时，会进入堆栈中不同部分对应的不同上下文。

到达一个停止点或者触发某个事件时，调试器就会创建一个上下文。上下文中包含被终止应用的信息，调试器用这些信息审查帧堆栈，计算变量的值，以及调试器在应用的什么地方终止执行。

任何时候都可执行 `backtrace` 命令（或别名 `where`）打印应用的回溯信息。这有助于理解是如何执行到当前位置的。只要你想知道应用是怎么执行到当前代码的，就可以通过 `backtrace` 命令获得答案。

    (byebug) where
    --> #0  ArticlesController.index
          at /PathToProject/app/controllers/articles_controller.rb:8
        #1  ActionController::BasicImplicitRender.send_action(method#String, *args#Array)
          at /PathToGems/actionpack-5.0.0/lib/action_controller/metal/basic_implicit_render.rb:4
        #2  AbstractController::Base.process_action(action#NilClass, *args#Array)
          at /PathToGems/actionpack-5.0.0/lib/abstract_controller/base.rb:181
        #3  ActionController::Rendering.process_action(action, *args)
          at /PathToGems/actionpack-5.0.0/lib/action_controller/metal/rendering.rb:30
    ...

当前帧使用 `-->` 标记。在回溯信息中可以执行 `frame n` 命令移动（从而改变上下文），其中 `n` 为帧序号。如果移动了，`byebug` 会显示新的上下文。

    (byebug) frame 2

    [176, 185] in /PathToGems/actionpack-5.0.0/lib/abstract_controller/base.rb
       176:       # is the intended way to override action dispatching.
       177:       #
       178:       # Notice that the first argument is the method to be dispatched
       179:       # which is *not* necessarily the same as the action name.
       180:       def process_action(method_name, *args)
    => 181:         send_action(method_name, *args)
       182:       end
       183:
       184:       # Actually call the method associated with the action. Override
       185:       # this method if you wish to change how action methods are called,
    (byebug)

可用的变量和逐行执行代码时一样。毕竟，这就是调试的目的。

向前或向后移动帧可以执行 `up [n]` 或 `down [n]` 命令，分别向前或向后移动 n 帧。n 的默认值为 1。向前移动是指向较高的帧数移动，向下移动是指向较低的帧数移动。

### 线程

`thread` 命令（缩写为 `th`）可以列出所有线程、停止线程、恢复线程，或者在线程之间切换。其选项如下：

- `thread`：显示当前线程；

- `thread list`：列出所有线程及其状态，`+` 符号表示当前线程；

- `thread stop n`：停止线程 `n`；

- `thread resume n`：恢复线程 `n`；

- `thread switch n`：把当前线程切换到线程 `n`；

调试并发线程时，如果想确认代码中没有条件竞争，使用这个命令十分方便。

### 审查变量

任何表达式都可在当前上下文中求值。如果想计算表达式的值，直接输入表达式即可。

下面这个例子说明如何查看当前上下文中实例变量的值：

    [3, 12] in /PathTo/project/app/controllers/articles_controller.rb
        3:
        4:   # GET /articles
        5:   # GET /articles.json
        6:   def index
        7:     byebug
    =>  8:     @articles = Article.find_recent
        9:
       10:     respond_to do |format|
       11:       format.html # index.html.erb
       12:       format.json { render json: @articles }

    (byebug) instance_variables
    [:@_action_has_layout, :@_routes, :@_request, :@_response, :@_lookup_context,
     :@_action_name, :@_response_body, :@marked_for_same_origin_verification,
     :@_config]

你可能已经看出来了，在控制器中可以使用的实例变量都显示出来了。这个列表随着代码的执行会动态更新。例如，使用 `next` 命令（本文后面会进一步说明这个命令）执行下一行代码：

    (byebug) next

    [5, 14] in /PathTo/project/app/controllers/articles_controller.rb
       5     # GET /articles.json
       6     def index
       7       byebug
       8       @articles = Article.find_recent
       9
    => 10       respond_to do |format|
       11         format.html # index.html.erb
       12        format.json { render json: @articles }
       13      end
       14    end
       15
    (byebug)

然后再查看 `instance_variables` 的值：

    (byebug) instance_variables
    [:@_action_has_layout, :@_routes, :@_request, :@_response, :@_lookup_context,
     :@_action_name, :@_response_body, :@marked_for_same_origin_verification,
     :@_config, :@articles]

实例变量中出现了 `@articles`，因为执行了定义它的代码。

TIP: 执行 `irb` 命令可进入 **irb** 模式（这不显然吗），irb 会话使用当前上下文。

`var` 命令是显示变量值最便捷的方式：

    (byebug) help var

      [v]ar <subcommand>

      Shows variables and its values


      var all      -- Shows local, global and instance variables of self.
      var args     -- Information about arguments of the current scope
      var const    -- Shows constants of an object.
      var global   -- Shows global variables.
      var instance -- Shows instance variables of self or a specific object.
      var local    -- Shows local variables in current scope.

上述方法可以很轻易查看当前上下文中的变量值。例如，下述代码确认没有局部变量：

    (byebug) var local
    (byebug)

审查对象的方法也可以使用这个命令：

    (byebug) var instance Article.new
    @_start_transaction_state = {}
    @aggregation_cache = {}
    @association_cache = {}
    @attributes = #<ActiveRecord::AttributeSet:0x007fd0682a9b18 @attributes={"id"=>#<ActiveRecord::Attribute::FromDatabase:0x007fd0682a9a00 @name="id", @value_be...
    @destroyed = false
    @destroyed_by_association = nil
    @marked_for_destruction = false
    @new_record = true
    @readonly = false
    @transaction_state = nil
    @txn = nil

`display` 命令可用于监视变量，查看在代码执行过程中变量值的变化：

    (byebug) display @articles
    1: @articles = nil

`display` 命令后跟的变量值会随着执行堆栈的推移而变化。如果想停止显示变量值，可以执行 `undisplay n` 命令，其中 `n` 是变量的代号（在上例中是 `1`）。

### 逐步执行

现在你知道在运行代码的什么位置，以及如何查看变量的值了。下面我们继续执行应用。

`step` 命令（缩写为 `s`）可以一直执行应用，直到下一个逻辑停止点，再把控制权交给调试器。`next` 命令的作用和 `step` 命令类似，但是 `step` 命令会在执行下一行代码之前停止，一次只执行一步，而 `next` 命令会执行下一行代码，但不跳出方法。

我们来看看下面这种情形：

    Started GET "/" for 127.0.0.1 at 2014-04-11 13:39:23 +0200
    Processing by ArticlesController#index as HTML

    [1, 6] in /PathToProject/app/models/article.rb
       1: class Article < ApplicationRecord
       2:   def self.find_recent(limit = 10)
       3:     byebug
    => 4:     where('created_at > ?', 1.week.ago).limit(limit)
       5:   end
       6: end

    (byebug)

如果使用 `next`，不会深入方法调用，`byebug` 会进入同一上下文中的下一行。这里，进入的是当前方法的最后一行，因此 `byebug` 会返回调用方的下一行。

    (byebug) next
    [4, 13] in /PathToProject/app/controllers/articles_controller.rb
        4:   # GET /articles
        5:   # GET /articles.json
        6:   def index
        7:     @articles = Article.find_recent
        8:
    =>  9:     respond_to do |format|
       10:       format.html # index.html.erb
       11:       format.json { render json: @articles }
       12:     end
       13:   end

    (byebug)

如果使用 `step`，`byebug` 会进入要执行的下一个 Ruby 指令——这里是 Active Support 的 `week` 方法。

    (byebug) step

    [49, 58] in /PathToGems/activesupport-5.0.0/lib/active_support/core_ext/numeric/time.rb
       49:
       50:   # Returns a Duration instance matching the number of weeks provided.
       51:   #
       52:   #   2.weeks # => 14 days
       53:   def weeks
    => 54:     ActiveSupport::Duration.new(self * 7.days, [[:days, self * 7]])
       55:   end
       56:   alias :week :weeks
       57:
       58:   # Returns a Duration instance matching the number of fortnights provided.
    (byebug)

逐行执行代码是找出代码缺陷的最佳方式。

TIP: 还可以使用 `step n` 或 `next n` 一次向前移动 `n` 步。

### 断点

断点设置在何处终止执行代码。调试器会在设定断点的行呼出。

断点可以使用 `break` 命令（缩写为 `b`）动态添加。添加断点有三种方式：

- `break n`：在当前源码文件的第 `n` 行设定断点。

- `break file:n [if expression]`：在文件 `file` 的第 `n` 行设定断点。如果指定了表达式 `expression`，其返回结果必须为 `true` 才会启动调试器。

- `break class(.|#)method [if expression]`：在 `class` 类的 `method` 方法中设置断点，`.` 和 `#` 分别表示类和实例方法。表达式 `expression` 的作用与 `file:n` 中的一样。

例如，在前面的情形下：

    [4, 13] in /PathToProject/app/controllers/articles_controller.rb
        4:   # GET /articles
        5:   # GET /articles.json
        6:   def index
        7:     @articles = Article.find_recent
        8:
    =>  9:     respond_to do |format|
       10:       format.html # index.html.erb
       11:       format.json { render json: @articles }
       12:     end
       13:   end

    (byebug) break 11
    Successfully created breakpoint with id 1

使用 `info breakpoints` 命令可以列出断点。如果指定了数字，只会列出对应的断点，否则列出所有断点。

    (byebug) info breakpoints
    Num Enb What
    1   y   at /PathToProject/app/controllers/articles_controller.rb:11

如果想删除断点，使用 `delete n` 命令，删除编号为 `n` 的断点。如果不指定数字，则删除所有在用的断点。

    (byebug) delete 1
    (byebug) info breakpoints
    No breakpoints.

断点也可以启用或禁用：

- `enable breakpoints [n [m […​]]]`：在指定的断点列表或者所有断点处停止应用。这是创建断点后的默认状态。

- `disable breakpoints [n [m […​]]]`：让指定的断点（或全部断点）在应用中不起作用。

### 捕获异常

`catch exception-name` 命令（或 `cat exception-name`）可捕获 `exception-name` 类型的异常，源码很有可能没有处理这个异常。

执行 `catch` 命令可以列出所有可用的捕获点。

### 恢复执行

有两种方法可以恢复被调试器终止执行的应用：

- `continue [n]`（或 `c`）：从停止的地方恢复执行程序，设置的断点失效。可选的参数 `n` 指定一个行数，设定一个一次性断点，应用执行到这一行时，断点会被删除。

- `finish [n]`：一直执行，直到指定的堆栈帧返回为止。如果没有指定帧序号，应用会一直执行，直到当前堆栈帧返回为止。当前堆栈帧就是最近刚使用过的帧，如果之前没有移动帧的位置（执行 `up`、`down` 或 `frame` 命令），就是第 0 帧。如果指定了帧序号，则运行到指定的帧返回为止。

### 编辑

下面这个方法可以在调试器中使用编辑器打开源码：

- `edit [file:n]`：使用环境变量 `EDITOR` 指定的编辑器打开文件 `file`。还可指定行数 `n`。

### 退出

若想退出调试器，使用 `quit` 命令（缩写为 `q`）。也可以输入 `q!`，跳过 `Really quit? (y/n)` 提示，无条件地退出。

退出后会终止所有线程，因此服务器也会停止，需要重启。

### 设置

`byebug` 有几个选项，可用于调整行为：

    (byebug) help set

      set <setting> <value>

      Modifies byebug settings

      Boolean values take "on", "off", "true", "false", "1" or "0". If you
      don't specify a value, the boolean setting will be enabled. Conversely,
      you can use "set no<setting>" to disable them.

      You can see these environment settings with the "show" command.

      List of supported settings:

      autosave       -- Automatically save command history record on exit
      autolist       -- Invoke list command on every stop
      width          -- Number of characters per line in byebug's output
      autoirb        -- Invoke IRB on every stop
      basename       -- <file>:<line> information after every stop uses short paths
      linetrace      -- Enable line execution tracing
      autopry        -- Invoke Pry on every stop
      stack_on_error -- Display stack trace when `eval` raises an exception
      fullpath       -- Display full file names in backtraces
      histfile       -- File where cmd history is saved to. Default: ./.byebug_history
      listsize       -- Set number of source lines to list by default
      post_mortem    -- Enable/disable post-mortem mode
      callstyle      -- Set how you want method call parameters to be displayed
      histsize       -- Maximum number of commands that can be stored in byebug history
      savefile       -- File where settings are saved to. Default: ~/.byebug_save

TIP: 可以把这些设置保存在家目录中的 `.byebugrc` 文件里。启动时，调试器会读取这些全局设置。例如：
>
>     set callstyle short
>     set listsize 25

使用 `web-console` gem 调试
---------------------------

Web Console 的作用与 `byebug` 有点类似，不过它在浏览器中运行。在任何页面中都可以在视图或控制器的上下文中请求控制台。控制台在 HTML 内容下面渲染。

### 控制台

在任何控制器动作或视图中，都可以调用 `console` 方法呼出控制台。

例如，在一个控制器中：

```ruby
class PostsController < ApplicationController
  def new
    console
    @post = Post.new
  end
end
```

或者在一个视图中：

```erb
<% console %>

<h2>New Post</h2>
```

控制台在视图中渲染。调用 `console` 的位置不用担心，它不会在调用的位置显示，而是显示在 HTML 内容下方。

控制台可以执行纯 Ruby 代码，你可以定义并实例化类、创建新模型或审查变量。

NOTE: 一个请求只能渲染一个控制台，否则 `web-console` 会在第二个 `console` 调用处抛出异常。

### 审查变量

可以调用 `instance_variables` 列出当前上下文中的全部实例变量。如果想列出全部局部变量，调用 `local_variables`。

### 设置

- `config.web_console.whitelisted_ips`：授权的 IPv4 或 IPv6 地址和网络列表（默认值：`127.0.0.1/8, ::1`）。

- `config.web_console.whiny_requests`：禁止渲染控制台时记录一条日志（默认值：`true`）。

`web-console` 会在远程服务器中执行 Ruby 代码，因此别在生产环境中使用。

调试内存泄露
------------

Ruby 应用（Rails 或其他）可能会导致内存泄露，泄露可能由 Ruby 代码引起，也可能由 C 代码引起。

本节介绍如何使用 Valgrind 等工具查找并修正内存泄露问题。

### Valgrind

[Valgrind](http://valgrind.org/) 应用能检测 C 语言层的内存泄露和条件竞争。

Valgrind 提供了很多工具，能自动检测很多内存管理和线程问题，也能详细分析程序。例如，如果 C 扩展调用了 `malloc()` 函数，但没调用 `free()` 函数，这部分内存就会一直被占用，直到应用终止执行。

关于如何安装以及如何在 Ruby 中使用 Valgrind，请阅读 Evan Weaver 写的 [Valgrind and Ruby](http://blog.evanweaver.com/articles/2008/02/05/valgrind-and-ruby/) 一文。

用于调试的插件
--------------

有很多 Rails 插件可以帮助你查找问题和调试应用。下面列出一些有用的调试插件：

- [Footnotes](https://github.com/josevalim/rails-footnotes)：在应用的每个页面底部显示请求信息，并链接到源码（可通过 TextMate 打开）；

- [Query Trace](https://github.com/ruckus/active-record-query-trace/tree/master)：在日志中写入请求源信息；

- [Query Reviewer](https://github.com/nesquena/query_reviewer)：这个 Rails 插件在开发环境中会在每个 `SELECT` 查询前执行 `EXPLAIN` 查询，并在每个页面中添加一个 `div` 元素，显示分析到的查询问题；

- [Exception Notifier](https://github.com/smartinez87/exception_notification/tree/master)：提供了一个邮件程序和一组默认的邮件模板，Rails 应用出现问题后发送邮件通知；

- [Better Errors](https://github.com/charliesome/better_errors)：使用全新的页面替换 Rails 默认的错误页面，显示更多的上下文信息，例如源码和变量的值；

- [RailsPanel](https://github.com/dejan/rails_panel)：一个 Chrome 扩展，在浏览器的开发者工具中显示 `development.log` 文件的内容，显示的内容包括：数据库查询时间、渲染时间、总时间、参数列表、渲染的视图，等等。

参考资源
--------

- [ruby-debug 首页](http://bashdb.sourceforge.net/ruby-debug/home-page.html)

- [debugger 首页](https://github.com/cldwalker/debugger)

- [byebug 首页](https://github.com/deivid-rodriguez/byebug)

- [web-console 首页](https://github.com/rails/web-console)

- [文章：Debugging a Rails application with ruby-debug](http://www.sitepoint.com/debug-rails-app-ruby-debug/)

- [Ryan Bates 制作的视频“Debugging Ruby (revised)”](http://railscasts.com/episodes/54-debugging-ruby-revised)

- [Ryan Bates 制作的视频“The Stack Trace”](http://railscasts.com/episodes/24-the-stack-trace)

- [Ryan Bates 制作的视频“The Logger”](http://railscasts.com/episodes/56-the-logger)

- [Debugging with ruby-debug](http://bashdb.sourceforge.net/ruby-debug.html)
