调试 Rails 程序
==============

本文介绍如何调试 Rails 程序。

读完本文，你将学到：

* 调试的目的；
* 如何追查测试没有发现的问题；
* 不同的调试方法；
* 如何分析调用堆栈；

--------------------------------------------------------------------------------

调试相关的视图帮助方法
-------------------

调试一个常见的需求是查看变量的值。在 Rails 中，可以使用下面这三个方法：

* `debug`
* `to_yaml`
* `inspect`

### `debug`

`debug` 方法使用 YAML 格式渲染对象，把结果包含在 `<pre>` 标签中，可以把任何对象转换成人类可读的数据格式。例如，在视图中有以下代码：

```erb
<%= debug @post %>
<p>
  <b>Title:</b>
  <%= @post.title %>
</p>
```

渲染后会看到如下结果：

```yaml
--- !ruby/object:Post
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

使用 YAML 格式显示实例变量、对象的值或者方法的返回值，可以这么做：

```erb
<%= simple_format @post.to_yaml %>
<p>
  <b>Title:</b>
  <%= @post.title %>
</p>
```

`to_yaml` 方法把对象转换成可读性较好地 YAML 格式，`simple_format` 方法按照终端中的方式渲染每一行。`debug` 方法就是包装了这两个步骤。

上述代码在渲染后的页面中会显示如下内容：

```yaml
--- !ruby/object:Post
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

另一个用于显示对象值的方法是 `inspect`，显示数组和 Hash 时使用这个方法特别方便。`inspect` 方法以字符串的形式显示对象的值。例如：

```erb
<%= [1, 2, 3, 4, 5].inspect %>
<p>
  <b>Title:</b>
  <%= @post.title %>
</p>
```

渲染后得到的结果如下：

```
[1, 2, 3, 4, 5]

Title: Rails debugging guide
```

Logger
------

运行时把信息写入日志文件也很有用。Rails 分别为各运行环境都维护着单独的日志文件。

### Logger 是什么

Rails 使用 `ActiveSupport::Logger` 类把信息写入日志。当然也可换用其他代码库，比如 `Log4r`。

替换日志代码库可以在 `environment.rb` 或其他环境文件中设置：

```ruby
Rails.logger = Logger.new(STDOUT)
Rails.logger = Log4r::Logger.new("Application Log")
```

TIP: 默认情况下，日志文件都保存在 `Rails.root/log/` 文件夹中，日志文件名为 `environment_name.log`。

### 日志等级

如果消息的日志等级等于或高于设定的等级，就会写入对应的日志文件中。如果想知道当前的日志等级，可以调用 `Rails.logger.level` 方法。

可用的日志等级包括：`:debug`，`:info`，`:warn`，`:error`，`:fatal` 和 `:unknown`，分别对应数字 0-5。修改默认日志等级的方式如下：

```ruby
config.log_level = :warn # In any environment initializer, or
Rails.logger.level = 0 # at any time
```

这么设置在开发环境和交付准备环境中很有用，在生产环境中则不会写入大量不必要的信息。

TIP: Rails 所有环境的默认日志等级是 `debug`。

### 写日志

把消息写入日志文件可以在控制器、模型或邮件发送程序中调用 `logger.(debug|info|warn|error|fatal)` 方法。

```ruby
logger.debug "Person attributes hash: #{@person.attributes.inspect}"
logger.info "Processing the request..."
logger.fatal "Terminating application, raised unrecoverable error!!!"
```

下面这个例子增加了额外的写日志功能：

```ruby
class PostsController < ApplicationController
  # ...

  def create
    @post = Post.new(params[:post])
    logger.debug "New post: #{@post.attributes.inspect}"
    logger.debug "Post should be valid: #{@post.valid?}"

    if @post.save
      flash[:notice] = 'Post was successfully created.'
      logger.debug "The post was saved and now the user is going to be redirected..."
      redirect_to(@post)
    else
      render action: "new"
    end
  end

  # ...
end
```

执行上述动作后得到的日志如下：

```
Processing PostsController#create (for 127.0.0.1 at 2008-09-08 11:52:54) [POST]
  Session ID: BAh7BzoMY3NyZl9pZCIlMDY5MWU1M2I1ZDRjODBlMzkyMWI1OTg2NWQyNzViZjYiCmZsYXNoSUM6J0FjdGl
vbkNvbnRyb2xsZXI6OkZsYXNoOjpGbGFzaEhhc2h7AAY6CkB1c2VkewA=--b18cd92fba90eacf8137e5f6b3b06c4d724596a4
  Parameters: {"commit"=>"Create", "post"=>{"title"=>"Debugging Rails",
 "body"=>"I'm learning how to print in logs!!!", "published"=>"0"},
 "authenticity_token"=>"2059c1286e93402e389127b1153204e0d1e275dd", "action"=>"create", "controller"=>"posts"}
New post: {"updated_at"=>nil, "title"=>"Debugging Rails", "body"=>"I'm learning how to print in logs!!!",
 "published"=>false, "created_at"=>nil}
Post should be valid: true
  Post Create (0.000443)   INSERT INTO "posts" ("updated_at", "title", "body", "published",
 "created_at") VALUES('2008-09-08 14:52:54', 'Debugging Rails',
 'I''m learning how to print in logs!!!', 'f', '2008-09-08 14:52:54')
The post was saved and now the user is going to be redirected...
Redirected to #<Post:0x20af760>
Completed in 0.01224 (81 reqs/sec) | DB: 0.00044 (3%) | 302 Found [http://localhost/posts]
```

加入这种日志信息有助于发现异常现象。如果添加了额外的日志消息，记得要合理设定日志等级，免得把大量无用的消息写入生产环境的日志文件。

### 日志标签

运行多用户/多账户的程序时，使用自定义的规则筛选日志信息能节省很多时间。Active Support 中的 `TaggedLogging` 模块可以实现这种功能，可以在日志消息中加入二级域名、请求 ID 等有助于调试的信息。

```ruby
logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
logger.tagged("BCX") { logger.info "Stuff" }                            # Logs "[BCX] Stuff"
logger.tagged("BCX", "Jason") { logger.info "Stuff" }                   # Logs "[BCX] [Jason] Stuff"
logger.tagged("BCX") { logger.tagged("Jason") { logger.info "Stuff" } } # Logs "[BCX] [Jason] Stuff"
```

### 日志对性能的影响

如果把日志写入硬盘，肯定会对程序有点小的性能影响。不过可以做些小调整：`:debug` 等级比 `:fatal` 等级对性能的影响更大，因为写入的日志消息量更多。

如果按照下面的方式大量调用 `Logger`，也有潜在的问题：

```ruby
logger.debug "Person attributes hash: #{@person.attributes.inspect}"
```

在上述代码中，即使日志等级不包含 `:debug` 也会对性能产生影响。因为 Ruby 要初始化字符串，再花时间做插值。因此推荐把代码块传给 `logger` 方法，只有等于或大于设定的日志等级时才会执行其中的代码。重写后的代码如下：

```ruby
logger.debug {"Person attributes hash: #{@person.attributes.inspect}"}
```

代码块中的内容，即字符串插值，仅当允许 `:debug` 日志等级时才会执行。这种降低性能的方式只有在日志量比较大时才能体现出来，但却是个好的编程习惯。

使用 `debugger` gem 调试
-----------------------

如果代码表现异常，可以在日志文件或者控制台查找原因。但有时使用这种方法效率不高，无法找到导致问题的根源。如果需要检查源码，`debugger` gem 可以助你一臂之力。

如果想学习 Rails 源码但却无从下手，也可使用 `debugger` gem。随便找个请求，然后按照这里介绍的方法，从你编写的代码一直研究到 Rails 框架的代码。

### 安装

`debugger` gem 可以设置断点，实时查看执行的 Rails 代码。安装方法如下：

```bash
$ gem install debugger
```

从 2.0 版本开始，Rails 内置了调试功能。在任何 Rails 程序中都可以使用 `debugger` 方法调出调试器。

下面举个例子：

```ruby
class PeopleController < ApplicationController
  def new
    debugger
    @person = Person.new
  end
end
```

然后就能在控制台或者日志中看到如下信息：

```
***** Debugger requested, but was not available: Start server with --debugger to enable *****
```

记得启动服务器时要加上 `--debugger` 选项：

```bash
$ rails server --debugger
=> Booting WEBrick
=> Rails 4.2.0 application starting on http://0.0.0.0:3000
=> Debugger enabled
...
```

TIP: 在开发环境中，如果启动服务器时没有指定 `--debugger` 选项，不用重启服务器，加入 `require "debugger"` 即可。

### Shell

在程序中调用 `debugger` 方法后，会在启动程序所在的终端窗口中启用调试器 shell，并进入调试器的终端 `(rdb:n)` 中。其中 `n` 是线程编号。在调试器的终端中会显示接下来要执行哪行代码。

如果在浏览器中执行的请求触发了调试器，当前浏览器选项卡会处于停顿状态，等待调试器启动，跟踪完整个请求。

例如：

```bash
@posts = Post.all
(rdb:7)
```

现在可以深入分析程序的代码了。首先我们来查看一下调试器的帮助信息，输入 `help`：

```bash
(rdb:7) help
ruby-debug help v0.10.2
Type 'help <command-name>' for help on a specific command

Available commands:
backtrace  delete   enable  help    next  quit     show    trace
break      disable  eval    info    p     reload   source  undisplay
catch      display  exit    irb     pp    restart  step    up
condition  down     finish  list    ps    save     thread  var
continue   edit     frame   method  putl  set      tmate   where
```

TIP: 要想查看某个命令的帮助信息，可以在终端里输入 `help <command-name>`，例如 `help var`。

接下来要学习最有用的命令之一：`list`。调试器中的命令可以使用简写形式，只要输入的字母数量足够和其他命令区分即可。因此，可使用 `l` 代替 `list`。

`list` 命令输出当前执行代码的前后 5 行代码。下面的例子中，当前行是第 6 行，前面用 `=>` 符号标记。

```bash
(rdb:7) list
[1, 10] in /PathTo/project/app/controllers/posts_controller.rb
   1  class PostsController < ApplicationController
   2    # GET /posts
   3    # GET /posts.json
   4    def index
   5      debugger
=> 6      @posts = Post.all
   7
   8      respond_to do |format|
   9        format.html # index.html.erb
   10        format.json { render json: @posts }
```

如果再次执行 `list` 命令，请用 `l` 试试。接下来要执行的 10 行代码会显示出来：

```bash
(rdb:7) l
[11, 20] in /PathTo/project/app/controllers/posts_controller.rb
   11      end
   12    end
   13
   14    # GET /posts/1
   15    # GET /posts/1.json
   16    def show
   17      @post = Post.find(params[:id])
   18
   19      respond_to do |format|
   20        format.html # show.html.erb
```

可以一直这么执行下去，直到文件的末尾。如果到文件末尾了，`list` 命令会回到该文件的开头，再次从头开始执行一遍，把文件视为一个环形缓冲。

如果想查看前面 10 行代码，可以输入 `list-`（或者 `l-`）：

```bash
(rdb:7) l-
[1, 10] in /PathTo/project/app/controllers/posts_controller.rb
   1  class PostsController < ApplicationController
   2    # GET /posts
   3    # GET /posts.json
   4    def index
   5      debugger
   6      @posts = Post.all
   7
   8      respond_to do |format|
   9        format.html # index.html.erb
   10        format.json { render json: @posts }
```

使用 `list` 命令可以在文件中来回移动，查看 `debugger` 方法所在位置前后的代码。如果想知道 `debugger` 方法在文件的什么位置，可以输入 `list=`：

```bash
(rdb:7) list=
[1, 10] in /PathTo/project/app/controllers/posts_controller.rb
   1  class PostsController < ApplicationController
   2    # GET /posts
   3    # GET /posts.json
   4    def index
   5      debugger
=> 6      @posts = Post.all
   7
   8      respond_to do |format|
   9        format.html # index.html.erb
   10        format.json { render json: @posts }
```

### 上下文

开始调试程序时，会进入堆栈中不同部分对应的不同上下文。

到达一个停止点或者触发某个事件时，调试器就会创建一个上下文。上下文中包含被终止程序的信息，调试器用这些信息审查调用帧，计算变量的值，以及调试器在程序的什么地方终止执行。

任何时候都可执行 `backtrace` 命令（简写形式为 `where`）显示程序的调用堆栈。这有助于理解如何执行到当前位置。只要你想知道程序是怎么执行到当前代码的，就可以通过 `backtrace` 命令获得答案。

```bash
(rdb:5) where
    #0 PostsController.index
       at line /PathTo/project/app/controllers/posts_controller.rb:6
    #1 Kernel.send
       at line /PathTo/project/vendor/rails/actionpack/lib/action_controller/base.rb:1175
    #2 ActionController::Base.perform_action_without_filters
       at line /PathTo/project/vendor/rails/actionpack/lib/action_controller/base.rb:1175
    #3 ActionController::Filters::InstanceMethods.call_filters(chain#ActionController::Fil...,...)
       at line /PathTo/project/vendor/rails/actionpack/lib/action_controller/filters.rb:617
...
```

执行 `frame n` 命令可以进入指定的调用帧，其中 `n` 为帧序号。

```bash
(rdb:5) frame 2
#2 ActionController::Base.perform_action_without_filters
       at line /PathTo/project/vendor/rails/actionpack/lib/action_controller/base.rb:1175
```

可用的变量和逐行执行代码时一样。毕竟，这就是调试的目的。

向前或向后移动调用帧可以执行 `up [n]`（简写形式为 `u`）和 `down [n]` 命令，分别向前或向后移动 n 帧。n 的默认值为 1。向前移动是指向更高的帧数移动，向下移动是指向更低的帧数移动。

### 线程

`thread` 命令（缩略形式为 `th`）可以列出所有线程，停止线程，恢复线程，或者在线程之间切换。其选项如下：

* `thread`：显示当前线程；
* `thread list`：列出所有线程及其状态，`+` 符号和数字表示当前线程；
* `thread stop n`：停止线程 `n`；
* `thread resume n`：恢复线程 `n`；
* `thread switch n`：把当前线程切换到线程 `n`；

`thread` 命令有很多作用。调试并发线程时，如果想确认代码中没有条件竞争，使用这个命令十分方便。

### 审查变量

任何表达式都可在当前上下文中运行。如果想计算表达式的值，直接输入表达式即可。

下面这个例子说明如何查看在当前上下文中 `instance_variables` 的值：

```
@posts = Post.all
(rdb:11) instance_variables
["@_response", "@action_name", "@url", "@_session", "@_cookies", "@performed_render", "@_flash", "@template", "@_params", "@before_filter_chain_aborted", "@request_origin", "@_headers", "@performed_redirect", "@_request"]
```

你可能已经看出来了，在控制器中可使用的所有实例变量都显示出来了。这个列表随着代码的执行会动态更新。例如，使用 `next` 命令执行下一行代码：

```
(rdb:11) next
Processing PostsController#index (for 127.0.0.1 at 2008-09-04 19:51:34) [GET]
  Session ID: BAh7BiIKZmxhc2hJQzonQWN0aW9uQ29udHJvbGxlcjo6Rmxhc2g6OkZsYXNoSGFzaHsABjoKQHVzZWR7AA==--b16e91b992453a8cc201694d660147bba8b0fd0e
  Parameters: {"action"=>"index", "controller"=>"posts"}
/PathToProject/posts_controller.rb:8
respond_to do |format|
```

然后再查看 `instance_variables` 的值：

```
(rdb:11) instance_variables.include? "@posts"
true
```

实例变量中出现了 `@posts`，因为执行了定义这个变量的代码。

TIP: 执行 `irb` 命令可进入 **irb** 模式，irb 会话使用当前上下文。警告：这是实验性功能。

`var` 命令是显示变量值最便捷的方式：

```
var
(rdb:1) v[ar] const <object>            show constants of object
(rdb:1) v[ar] g[lobal]                  show global variables
(rdb:1) v[ar] i[nstance] <object>       show instance variables of object
(rdb:1) v[ar] l[ocal]                   show local variables
```

上述方法可以很轻易的查看当前上下文中的变量值。例如：

```
(rdb:9) var local
  __dbg_verbose_save => false
```

审查对象的方法可以使用下述方式：

```
(rdb:9) var instance Post.new
@attributes = {"updated_at"=>nil, "body"=>nil, "title"=>nil, "published"=>nil, "created_at"...
@attributes_cache = {}
@new_record = true
```

TIP: 命令 `p`（print，打印）和 `pp`(pretty print，精美格式化打印)可用来执行 Ruby 表达式并把结果显示在终端里。

`display` 命令可用来监视变量，查看在代码执行过程中变量值的变化：

```
(rdb:1) display @recent_comments
1: @recent_comments =
```

`display` 命令后跟的变量值会随着执行堆栈的推移而变化。如果想停止显示变量值，可以执行 `undisplay n` 命令，其中 `n` 是变量的代号，在上例中是 `1`。

### 逐步执行

现在你知道在运行代码的什么位置，以及如何查看变量的值。下面我们继续执行程序。

`step` 命令（缩写形式为 `s`）可以一直执行程序，直到下一个逻辑停止点，再把控制权交给调试器。

TIP: `step+ n` 和 `step- n` 可以相应的向前或向后 `n` 步。

`next` 命令的作用和 `step` 命令类似，但执行的方法不会停止。和 `step` 命令一样，也可使用加号前进 `n` 步。

`next` 命令和 `step` 命令的区别是，`step` 命令会在执行下一行代码之前停止，一次只执行一步；`next` 命令会执行下一行代码，但不跳出方法。

例如，下面这段代码调用了 `debugger` 方法：

```ruby
class Author < ActiveRecord::Base
  has_one :editorial
  has_many :comments

  def find_recent_comments(limit = 10)
    debugger
    @recent_comments ||= comments.where("created_at > ?", 1.week.ago).limit(limit)
  end
end
```

TIP: 在控制台中也可启用调试器，但要记得在调用 `debugger` 方法之前先 `require "debugger"`。

```bash
$ rails console
Loading development environment (Rails 4.2.0)
>> require "debugger"
=> []
>> author = Author.first
=> #<Author id: 1, first_name: "Bob", last_name: "Smith", created_at: "2008-07-31 12:46:10", updated_at: "2008-07-31 12:46:10">
>> author.find_recent_comments
/PathTo/project/app/models/author.rb:11
)
```

停止执行代码时，看一下输出：

```bash
(rdb:1) list
[2, 9] in /PathTo/project/app/models/author.rb
   2    has_one :editorial
   3    has_many :comments
   4
   5    def find_recent_comments(limit = 10)
   6      debugger
=> 7      @recent_comments ||= comments.where("created_at > ?", 1.week.ago).limit(limit)
   8    end
   9  end
```

在方法内的最后一行停止了。但是这行代码执行了吗？你可以审查一下实例变量。

```bash
(rdb:1) var instance
@attributes = {"updated_at"=>"2008-07-31 12:46:10", "id"=>"1", "first_name"=>"Bob", "las...
@attributes_cache = {}
```

`@recent_comments` 还未定义，所以这行代码还没执行。执行 `next` 命令执行这行代码：

```bash
(rdb:1) next
/PathTo/project/app/models/author.rb:12
@recent_comments
(rdb:1) var instance
@attributes = {"updated_at"=>"2008-07-31 12:46:10", "id"=>"1", "first_name"=>"Bob", "las...
@attributes_cache = {}
@comments = []
@recent_comments = []
```

现在看以看到，因为执行了这行代码，所以加载了 `@comments` 关联，也定义了 `@recent_comments`。

如果想深入方法和 Rails 代码执行堆栈，可以使用 `step` 命令，一步一步执行。这是发现代码问题（或者 Rails 框架问题）最好的方式。

### 断点

断点设置在何处终止执行代码。调试器会在断点设定行调用。

断点可以使用 `break` 命令（缩写形式为 `b`）动态添加。设置断点有三种方式：

* `break line`：在当前源码文件的第 `line` 行设置断点；
* `break file:line [if expression]`：在文件 `file` 的第 `line` 行设置断点。如果指定了表达式 `expression`，其返回结果必须为 `true` 才会启动调试器；
* `break class(.|\#)method [if expression]`：在 `class` 类的 `method` 方法中设置断点，`.` 和 `\#` 分别表示类和实例方法。表达式 `expression` 的作用和上个命令一样；

```bash
(rdb:5) break 10
Breakpoint 1 file /PathTo/project/vendor/rails/actionpack/lib/action_controller/filters.rb, line 10
```

`info breakpoints n` 或 `info break n` 命令可以列出断点。如果指定了数字 `n`，只会列出对应的断点，否则列出所有断点。

```bash
(rdb:5) info breakpoints
Num Enb What
  1 y   at filters.rb:10
```

如果想删除断点，可以执行 `delete n` 命令，删除编号为 `n` 的断点。如果不指定数字 `n`，则删除所有在用的断点。

```bash
(rdb:5) delete 1
(rdb:5) info breakpoints
No breakpoints.
```

启用和禁用断点的方法如下：

* `enable breakpoints`：允许使用指定的断点列表或者所有断点终止执行程序。这是创建断点后的默认状态。
* `disable breakpoints`：指定的断点 `breakpoints` 在程序中不起作用。

### 捕获异常

`catch exception-name` 命令（或 `cat exception-name`）可捕获 `exception-name` 类型的异常，源码很有可能没有处理这个异常。

执行 `catch` 命令可以列出所有可用的捕获点。

### 恢复执行

有两种方法可以恢复被调试器终止执行的程序：

* `continue [line-specification]`（或 `c`）：从停止的地方恢复执行程序，设置的断点失效。可选的参数 `line-specification` 指定一个代码行数，设定一个一次性断点，程序执行到这一行时，断点会被删除。
* `finish [frame-number]`（或 `fin`）：一直执行程序，直到指定的堆栈帧结束为止。如果没有指定 `frame-number` 参数，程序会一直执行，直到当前堆栈帧结束为止。当前堆栈帧就是最近刚使用过的帧，如果之前没有移动帧的位置（执行 `up`，`down` 或 `frame` 命令），就是第 0 帧。如果指定了帧数，则运行到指定的帧结束为止。

### 编辑

下面两种方法可以从调试器中使用编辑器打开源码：

* `edit [file:line]`：使用环境变量 `EDITOR` 指定的编辑器打开文件 `file`。还可指定文件的行数（`line`）。
* `tmate n`（简写形式为 `tm`）：在 TextMate 中打开当前文件。如果指定了参数 `n`，则使用第 n 帧。

### 退出

要想退出调试器，请执行 `quit` 命令（缩写形式为 `q`），或者别名 `exit`。

退出后会终止所有线程，所以服务器也会被停止，因此需要重启。

### 设置

`debugger` gem 能自动显示你正在分析的代码，在编辑器中修改代码后，还会重新加载源码。下面是可用的选项：

* `set reload`：修改代码后重新加载；
* `set autolist`：在每个断点处执行 `list` 命令；
* `set listsize n`：设置显示 `n` 行源码；
* `set forcestep`：强制 `next` 和 `step` 命令移到终点后的下一行；

执行 `help set` 命令可以查看完整说明。执行 `help set subcommand` 可以查看 `subcommand` 的帮助信息。

TIP: 设置可以保存到家目录中的 `.rdebugrc` 文件中。启动调试器时会读取这个文件中的全局设置。

下面是 `.rdebugrc` 文件示例：

```bash
set autolist
set forcestep
set listsize 25
```

调试内存泄露
-----------

Ruby 程序（Rails 或其他）可能会导致内存泄露，泄露可能由 Ruby 代码引起，也可能由 C 代码引起。

本节介绍如何使用 Valgrind 等工具查找并修正内存泄露问题。

### Valgrind

[Valgrind](http://valgrind.org/) 这个程序只能在 Linux 系统中使用，用于侦察 C 语言层的内存泄露和条件竞争。

Valgrind 提供了很多工具，可用来侦察内存管理和线程问题，也能详细分析程序。例如，如果 C 扩展调用了 `malloc()` 函数，但没调用 `free()` 函数，这部分内存就会一直被占用，直到程序结束。

关于如何安装 Valgrind 及在 Ruby 中使用，请阅读 Evan Weaver 编写的 [Valgrind and Ruby](http://blog.evanweaver.com/articles/2008/02/05/valgrind-and-ruby/) 一文。

用于调试的插件
------------

有很多 Rails 插件可以帮助你查找问题和调试程序。下面列出一些常用的调试插件：

* [Footnotes](https://github.com/josevalim/rails-footnotes)：在程序的每个页面底部显示请求信息，并链接到 TextMate 中的源码；
* [Query Trace](https://github.com/ntalbott/query_trace/tree/master)：在日志中写入请求源信息；
* [Query Reviewer](https://github.com/nesquena/query_reviewer)：这个 Rails 插件在开发环境中会在每个 `SELECT` 查询前执行 `EXPLAIN` 查询，并在每个页面中添加一个 `div` 元素，显示分析到的查询问题；
* [Exception Notifier](https://github.com/smartinez87/exception_notification/tree/master)：提供了一个邮件发送程序和一组默认的邮件模板，Rails 程序出现问题后发送邮件提醒；
* [Better Errors](https://github.com/charliesome/better_errors)：使用全新的页面替换 Rails 默认的错误页面，显示更多的上下文信息，例如源码和变量的值；
* [RailsPanel](https://github.com/dejan/rails_panel)：一个 Chrome 插件，在浏览器的开发者工具中显示 `development.log` 文件的内容，显示的内容包括：数据库查询时间，渲染时间，总时间，参数列表，渲染的视图等。

参考资源
-------

* [ruby-debug 首页](http://bashdb.sourceforge.net/ruby-debug/home-page.html)
* [debugger 首页](https://github.com/cldwalker/debugger)
* [文章：使用 ruby-debug 调试 Rails 程序](http://www.sitepoint.com/debug-rails-app-ruby-debug/)
* [Ryan Bates 制作的视频“Debugging Ruby (revised)”](http://railscasts.com/episodes/54-debugging-ruby-revised)
* [Ryan Bates 制作的视频“The Stack Trace”](http://railscasts.com/episodes/24-the-stack-trace)
* [Ryan Bates 制作的视频“The Logger”](http://railscasts.com/episodes/56-the-logger)
* [使用 ruby-debug 调试](http://bashdb.sourceforge.net/ruby-debug.html)
