Rails 命令行
===========

读完本文后，你将学会：

* 如何新建 Rails 程序；
* 如何生成模型、控制器、数据库迁移和单元测试；
* 如何启动开发服务器；
* 如果在交互 shell 中测试对象；
* 如何分析、评测程序；

--------------------------------------------------------------------------------

NOTE: 阅读本文前要具备一些 Rails 基础知识，可以阅读“[Rails 入门]({{ site.baseurl }}/getting_started.html)”一文。

命令行基础
---------

有些命令在 Rails 开发过程中经常会用到，下面按照使用频率倒序列出：

* `rails console`
* `rails server`
* `rake`
* `rails generate`
* `rails dbconsole`
* `rails new app_name`

这些命令都可指定 `-h` 或 `--help` 选项显示具体用法。

下面我们来新建一个 Rails 程序，介绍各命令的用法。

### `rails new`

安装 Rails 后首先要做的就是使用 `rails new` 命令新建 Rails 程序。

NOTE: 如果还没安装 Rails ，可以执行 `gem install rails` 命令安装。

```bash
$ rails new commandsapp
     create
     create  README.rdoc
     create  Rakefile
     create  config.ru
     create  .gitignore
     create  Gemfile
     create  app
     ...
     create  tmp/cache
     ...
        run  bundle install
```

这个简单的命令会生成很多文件，组成一个完整的 Rails 程序，直接就可运行。

### `rails server`

`rails server` 命令会启动 Ruby 内建的小型服务器 WEBrick。要想在浏览器中访问程序，就要执行这个命令。

无需其他操作，执行 `rails server` 命令后就能运行刚创建的 Rails 程序：

```bash
$ cd commandsapp
$ rails server
=> Booting WEBrick
=> Rails 4.0.0 application starting in development on http://0.0.0.0:3000
=> Call with -d to detach
=> Ctrl-C to shutdown server
[2013-08-07 02:00:01] INFO  WEBrick 1.3.1
[2013-08-07 02:00:01] INFO  ruby 2.0.0 (2013-06-27) [x86_64-darwin11.2.0]
[2013-08-07 02:00:01] INFO  WEBrick::HTTPServer#start: pid=69680 port=3000
```

只执行了三个命令，我们就启动了一个 Rails 服务器，监听端口 3000。打开浏览器，访问 <http://localhost:3000>，会看到一个简单的 Rails 程序。

NOTE: 启动服务器的命令还可使用别名“s”：`rails s`。

如果想让服务器监听其他端口，可通过 `-p` 选项指定。所处的环境可由 `-e` 选项指定。

```bash
$ rails server -e production -p 4000
```

`-b` 选项把 Rails 绑定到指定的 IP，默认 IP 是 0.0.0.0。指定 `-d` 选项后，服务器会以守护进程的形式运行。

### `rails generate`

`rails generate` 使用模板生成很多东西。单独执行 `rails generate` 命令，会列出可用的生成器：

NOTE: 还可使用别名“g”执行生成器命令：`rails g`。

```bash
$ rails generate
Usage: rails generate GENERATOR [args] [options]

...
...

Please choose a generator below.

Rails:
  assets
  controller
  generator
  ...
  ...
```

NOTE: 使用其他生成器 gem 可以安装更多的生成器，或者使用插件中提供的生成器，甚至还可以自己编写生成器。

使用生成器可以节省大量编写程序骨架的时间。

下面我们使用控制器生成器生成控制器。但应该使用哪个命令呢？我们问一下生成器：

NOTE: 所有的 Rails 命令都有帮助信息。和其他 *nix 命令一样，可以在命令后加上 `--help` 或 `-h` 选项，例如 `rails server --help`。

```bash
$ rails generate controller
Usage: rails generate controller NAME [action action] [options]

...
...

Description:
    ...

    To create a controller within a module, specify the controller name as a
    path like 'parent_module/controller_name'.

    ...

Example:
    `rails generate controller CreditCard open debit credit close`

    Credit card controller with URLs like /credit_card/debit.
        Controller: app/controllers/credit_card_controller.rb
        Test:       test/controllers/credit_card_controller_test.rb
        Views:      app/views/credit_card/debit.html.erb [...]
        Helper:     app/helpers/credit_card_helper.rb
```

控制器生成器接受的参数形式是 `generate controller ControllerName action1 action2`。下面我们来生成 `Greetings` 控制器，包含一个动作 `hello`，跟读者打个招呼。

```bash
$ rails generate controller Greetings hello
     create  app/controllers/greetings_controller.rb
      route  get "greetings/hello"
     invoke  erb
     create    app/views/greetings
     create    app/views/greetings/hello.html.erb
     invoke  test_unit
     create    test/controllers/greetings_controller_test.rb
     invoke  helper
     create    app/helpers/greetings_helper.rb
     invoke    test_unit
     create      test/helpers/greetings_helper_test.rb
     invoke  assets
     invoke    coffee
     create      app/assets/javascripts/greetings.js.coffee
     invoke    scss
     create      app/assets/stylesheets/greetings.css.scss
```

这个命令生成了什么呢？在程序中创建了一堆文件夹，还有控制器文件、视图文件、功能测试文件、视图帮助方法文件、JavaScript 文件盒样式表文件。

打开控制器文件（`app/controllers/greetings_controller.rb`），做些改动：

```ruby
class GreetingsController < ApplicationController
  def hello
    @message = "Hello, how are you today?"
  end
end
```

然后修改视图文件（`app/views/greetings/hello.html.erb`），显示消息：

```erb
<h1>A Greeting for You!</h1>
<p><%= @message %></p>
```

执行 `rails server` 命令启动服务器：

```bash
$ rails server
=> Booting WEBrick...
```

要查看的地址是 <http://localhost:3000/greetings/hello>。

NOTE: 在常规的 Rails 程序中，URL 的格式是 http://(host)/(controller)/(action)，访问 http://(host)/(controller) 会进入控制器的 `index` 动作。

Rails 也为数据模型提供了生成器。

```bash
$ rails generate model
Usage:
  rails generate model NAME [field[:type][:index] field[:type][:index]] [options]

...

Active Record options:
      [--migration]            # Indicates when to generate migration
                               # Default: true

...

Description:
    Create rails files for model generator.
```

NOTE: 全部可用的字段类型，请查看 `TableDefinition#column` 方法的[文档](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html#method-i-column)。

不过我们暂且不单独生成模型（后文再生成），先使用脚手架。Rails 中的脚手架会生成资源所需的全部文件，包括：模型，模型所用的迁移，处理模型的控制器，查看数据的视图，以及测试组件。

我们要创建一个名为“HighScore”的资源，记录视频游戏的最高得分。

```bash
$ rails generate scaffold HighScore game:string score:integer
    invoke  active_record
    create    db/migrate/20130717151933_create_high_scores.rb
    create    app/models/high_score.rb
    invoke    test_unit
    create      test/models/high_score_test.rb
    create      test/fixtures/high_scores.yml
    invoke  resource_route
     route    resources :high_scores
    invoke  scaffold_controller
    create    app/controllers/high_scores_controller.rb
    invoke    erb
    create      app/views/high_scores
    create      app/views/high_scores/index.html.erb
    create      app/views/high_scores/edit.html.erb
    create      app/views/high_scores/show.html.erb
    create      app/views/high_scores/new.html.erb
    create      app/views/high_scores/_form.html.erb
    invoke    test_unit
    create      test/controllers/high_scores_controller_test.rb
    invoke    helper
    create      app/helpers/high_scores_helper.rb
    invoke      test_unit
    create        test/helpers/high_scores_helper_test.rb
    invoke    jbuilder
    create      app/views/high_scores/index.json.jbuilder
    create      app/views/high_scores/show.json.jbuilder
    invoke  assets
    invoke    coffee
    create      app/assets/javascripts/high_scores.js.coffee
    invoke    scss
    create      app/assets/stylesheets/high_scores.css.scss
    invoke  scss
   identical    app/assets/stylesheets/scaffolds.css.scss
```

这个生成器检测到以下各组件对应的文件夹已经存储在：模型，控制器，帮助方法，布局，功能测试，单元测试，样式表。然后创建“HighScore”资源的视图、控制器、模型和迁移文件（用来创建 `high_scores` 数据表和字段），并设置好路由，以及测试等。

我们要运行迁移，执行文件 `20130717151933_create_high_scores.rb` 中的代码，这才能修改数据库的模式。那么要修改哪个数据库呢？执行 `rake db:migrate` 命令后会生成 SQLite3 数据库。稍后再详细介绍 Rake。

```bash
$ rake db:migrate
==  CreateHighScores: migrating ===============================================
-- create_table(:high_scores)
   -> 0.0017s
==  CreateHighScores: migrated (0.0019s) ======================================
```

NOTE: 介绍一下单元测试。单元测试是用来测试代码、做断定的代码。在单元测试中，我们只关注代码的一部分，例如模型中的一个方法，测试其输入和输出。单元测试是你的好伙伴，你逐渐会意识到，单元测试的程度越高，生活的质量才能提上来。真的。稍后我们会编写一个单元测试。

我们来看一下 Rails 创建的界面。

```bash
$ rails server
```

打开浏览器，访问 <http://localhost:3000/high_scores>，现在可以创建新的最高得分了（太空入侵者得了 55,160 分）。

### `rails console`

执行 `console` 命令后，可以在命令行中和 Rails 程序交互。`rails` console` 使用的是 IRB，所以如果你用过 IRB 的话，操作起来很顺手。在终端里可以快速测试想法，或者修改服务器端的数据，而无需在网站中操作。

NOTE:  这个命令还可以使用别名“c”：`rails c`。

执行 `console` 命令时可以指定终端在哪个环境中打开：

```bash
$ rails console staging
```

如果你想测试一些代码，但不想改变存储的数据，可以执行 `rails console --sandbox`。

```bash
$ rails console --sandbox
Loading development environment in sandbox (Rails 4.0.0)
Any modifications you make will be rolled back on exit
irb(main):001:0>
```

### `rails dbconsole`

`rails dbconsole` 能检测到你正在使用的数据库类型（还能理解传入的命令行参数），然后进入该数据库的命令行界面。该命令支持 MySQL，PostgreSQL，SQLite 和 SQLite3。

NOTE: 这个命令还可使用别名“db”：`rails db`。

### `rails runner`

`runner` 可以以非交互的方式在 Rails 中运行 Ruby 代码。例如：

```bash
$ rails runner "Model.long_running_method"
```

NOTE: 这个命令还可使用别名“r”：`rails r`。

可使用 `-e` 选项指定 `runner` 命令在哪个环境中运行。

```bash
$ rails runner -e staging "Model.long_running_method"
```

### `rails destroy`

`destroy` 可以理解成 `generate` 的逆操作，能识别生成了什么，然后将其删除。

NOTE: 这个命令还可使用别名“d”：`rails d`。

```bash
$ rails generate model Oops
      invoke  active_record
      create    db/migrate/20120528062523_create_oops.rb
      create    app/models/oops.rb
      invoke    test_unit
      create      test/models/oops_test.rb
      create      test/fixtures/oops.yml
```

```bash
$ rails destroy model Oops
      invoke  active_record
      remove    db/migrate/20120528062523_create_oops.rb
      remove    app/models/oops.rb
      invoke    test_unit
      remove      test/models/oops_test.rb
      remove      test/fixtures/oops.yml
```

Rake
----

Rake 是 Ruby 领域的 Make，是个独立的 Ruby 工具，目的是代替 Unix 中的 make。Rake 根据 `Rakefile` 和 `.rake` 文件构建任务。Rails 使用 Rake 实现常见的管理任务，尤其是较为复杂的任务。

执行 `rake -- tasks` 命令可以列出所有可用的 Rake 任务，具体的任务根据所在文件夹会有所不同。每个任务都有描述信息，帮助你找到所需的命令。

要想查看执行 Rake 任务时的完整调用栈，可以在命令中使用 `--trace` 选项，例如 `rake db:create --trace`。

```bash
$ rake --tasks
rake about              # List versions of all Rails frameworks and the environment
rake assets:clean       # Remove compiled assets
rake assets:precompile  # Compile all the assets named in config.assets.precompile
rake db:create          # Create the database from config/database.yml for the current Rails.env
...
rake log:clear          # Truncates all *.log files in log/ to zero bytes (specify which logs with LOGS=test,development)
rake middleware         # Prints out your Rack middleware stack
...
rake tmp:clear          # Clear session, cache, and socket files from tmp/ (narrow w/ tmp:sessions:clear, tmp:cache:clear, tmp:sockets:clear)
rake tmp:create         # Creates tmp directories for sessions, cache, sockets, and pids
```

NOTE: 还可以执行 `rake -T` 查看所有任务。

### `about`

`rake about` 任务输出以下信息：Ruby、RubyGems、Rails 的版本号，Rails 使用的组件，程序所在的文件夹，Rails 当前所处的环境名，程序使用的数据库适配器，数据库模式版本号。如果想向他人需求帮助，检查安全补丁是否影响程序，或者需要查看现有 Rails 程序的信息，可以使用这个任务。

```bash
$ rake about
About your application's environment
Ruby version              1.9.3 (x86_64-linux)
RubyGems version          1.3.6
Rack version              1.3
Rails version             4.1.0
JavaScript Runtime        Node.js (V8)
Active Record version     4.1.0
Action Pack version       4.1.0
Action View version       4.1.0
Action Mailer version     4.1.0
Active Support version    4.1.0
Middleware                Rack::Sendfile, ActionDispatch::Static, Rack::Lock, #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x007ffd131a7c88>, Rack::Runtime, Rack::MethodOverride, ActionDispatch::RequestId, Rails::Rack::Logger, ActionDispatch::ShowExceptions, ActionDispatch::DebugExceptions, ActionDispatch::RemoteIp, ActionDispatch::Reloader, ActionDispatch::Callbacks, ActiveRecord::Migration::CheckPending, ActiveRecord::ConnectionAdapters::ConnectionManagement, ActiveRecord::QueryCache, ActionDispatch::Cookies, ActionDispatch::Session::CookieStore, ActionDispatch::Flash, ActionDispatch::ParamsParser, Rack::Head, Rack::ConditionalGet, Rack::ETag
Application root          /home/foobar/commandsapp
Environment               development
Database adapter          sqlite3
Database schema version   20110805173523
```

### `assets`

`rake assets:precompile` 任务会预编译 `app/assets` 文件夹中的静态资源文件。`rake assets:clean` 任务会把编译好的静态资源文件删除。

### `db`

Rake 命名空间 `db:` 中最常用的任务是 `migrate` 和 `create`，这两个任务会尝试运行所有迁移相关的 Rake 任务（`up`，`down`，`redo`，`reset`）。`rake db:version` 在排查问题时很有用，会输出数据库的当前版本。

关于数据库迁移的更多介绍，参阅“[Active Record 数据库迁移]({{ site.baseurl }}/migrations.html)”一文。

### `doc`

`doc:` 命名空间中的任务可以生成程序的文档，Rails API 文档和 Rails 指南。生成的文档可以随意分割，减少程序的大小，适合在嵌入式平台使用。

* `rake doc:app` 在 `doc/app` 文件夹中生成程序的文档；
* `rake doc:guides` 在 `doc/guides` 文件夹中生成 Rails 指南；
* `rake doc:rails` 在 `doc/api` 文件夹中生成 Rails API 文档；

### `notes`

`rake notes` 会搜索整个程序，寻找以 FIXME、OPTIMIZE 或 TODO 开头的注释。搜索的文件包括 `.builder`，`.rb`，`.erb`，`.haml`，`.slim`，`.css`，`.scss`，`.js`，`.coffee`，`.rake`，`.sass` 和 `.less`。搜索的内容包括默认注解和自定义注解。

```bash
$ rake notes
(in /home/foobar/commandsapp)
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] any other way to do this?
  * [132] [FIXME] high priority for next deploy

app/models/school.rb:
  * [ 13] [OPTIMIZE] refactor this code to make it faster
  * [ 17] [FIXME]
```

如果想查找特定的注解，例如 FIXME，可以执行 `rake notes:fixme` 任务。注意，在命令中注解的名字要使用小写形式。

```bash
$ rake notes:fixme
(in /home/foobar/commandsapp)
app/controllers/admin/users_controller.rb:
  * [132] high priority for next deploy

app/models/school.rb:
  * [ 17]
```

在代码中可以使用自定义的注解，然后执行 `rake notes:custom` 任务，并使用 `ANNOTATION` 环境变量指定要查找的注解。

```bash
$ rake notes:custom ANNOTATION=BUG
(in /home/foobar/commandsapp)
app/models/post.rb:
  * [ 23] Have to fix this one before pushing!
```

NOTE: 注意，不管查找的是默认的注解还是自定义的直接，注解名（例如 FIXME，BUG 等）不会在输出结果中显示。

默认情况下，`rake notes` 会搜索 `app`、`config`、`lib`、`bin` 和 `test` 这几个文件夹中的文件。如果想在其他的文件夹中查找，可以使用 `SOURCE_ANNOTATION_DIRECTORIES` 环境变量指定一个以逗号分隔的列表。

```bash
$ export SOURCE_ANNOTATION_DIRECTORIES='spec,vendor'
$ rake notes
(in /home/foobar/commandsapp)
app/models/user.rb:
  * [ 35] [FIXME] User should have a subscription at this point
spec/models/user_spec.rb:
  * [122] [TODO] Verify the user that has a subscription works
```

### `routes`

`rake routes` 会列出程序中定义的所有路由，可为解决路由问题提供帮助，还可以让你对程序中的所有 URL 有个整体了解。

### `test`

NOTE: Rails 中的单元测试详情，参见“[Rails 程序测试指南]({{ site.baseurl }}/testing.html)”一文。

Rails 提供了一个名为 Minitest 的测试组件。Rails 的稳定性也由测试决定。`test:` 命名空间中的任务可用于运行各种测试。

### `tmp`

`Rails.root/tmp` 文件夹和 *nix 中的 `/tmp` 作用相同，用来存放临时文件，例如会话（如果使用文件存储会话）、PID 文件和缓存文件等。

`tmp:` 命名空间中的任务可以清理或创建 `Rails.root/tmp` 文件夹：

* `rake tmp:cache:clear` 清理 `tmp/cache` 文件夹；
* `rake tmp:sessions:clear` 清理 `tmp/sessions` 文件夹；
* `rake tmp:sockets:clear` 清理 `tmp/sockets` 文件夹；
* `rake tmp:clear` 清理以上三个文件夹；
* `rake tmp:create` 创建会话、缓存、套接字和 PID 所需的临时文件夹；

### 其他任务

* `rake stats` 用来统计代码状况，显示千行代码数和测试比例等；
* `rake secret` 会生成一个伪随机字符串，作为会话的密钥；
* `rake time:zones:all` 列出 Rails 能理解的所有时区；

### 编写 Rake 任务

自己编写的 Rake 任务保存在 `Rails.root/lib/tasks` 文件夹中，文件的扩展名是 `.rake`。执行 `bin/rails generate task` 命令会生成一个新的自定义任务文件。

```ruby
desc "I am short, but comprehensive description for my cool task"
task task_name: [:prerequisite_task, :another_task_we_depend_on] do
  # All your magic here
  # Any valid Ruby code is allowed
end
```

向自定义的任务中传入参数的方式如下：

```ruby
task :task_name, [:arg_1] => [:pre_1, :pre_2] do |t, args|
  # You can use args from here
end
```

任务可以分组，放入命名空间：

```ruby
namespace :db do
  desc "This task does nothing"
  task :nothing do
    # Seriously, nothing
  end
end
```

执行任务的方法如下：

```bash
rake task_name
rake "task_name[value 1]" # entire argument string should be quoted
rake db:nothing
```

NOTE: 如果在任务中要和程序的模型交互，例如查询数据库等，可以使用 `environment` 任务，加载程序代码。

Rails 命令行高级用法
------------------

Rails 命令行的高级用法就是找到实用的参数，满足特定需求或者工作流程。下面是一些常用的高级命令。

### 新建程序时指定数据库和源码管理系统

新建程序时，可设置一些选项指定使用哪种数据库和源码管理系统。这么做可以节省一点时间，减少敲击键盘的次数。

我们来看一下 `--git` 和 `--database=postgresql` 选项有什么作用：

```bash
$ mkdir gitapp
$ cd gitapp
$ git init
Initialized empty Git repository in .git/
$ rails new . --git --database=postgresql
      exists
      create  app/controllers
      create  app/helpers
...
...
      create  tmp/cache
      create  tmp/pids
      create  Rakefile
add 'Rakefile'
      create  README.rdoc
add 'README.rdoc'
      create  app/controllers/application_controller.rb
add 'app/controllers/application_controller.rb'
      create  app/helpers/application_helper.rb
...
      create  log/test.log
add 'log/test.log'
```

上面的命令先新建一个 `gitapp` 文件夹，初始化一个空的 git 仓库，然后再把 Rails 生成的文件加入仓库。再来看一下在数据库设置文件中添加了什么：

```bash
$ cat config/database.yml
# PostgreSQL. Versions 8.2 and up are supported.
#
# Install the pg driver:
#   gem install pg
# On OS X with Homebrew:
#   gem install pg -- --with-pg-config=/usr/local/bin/pg_config
# On OS X with MacPorts:
#   gem install pg -- --with-pg-config=/opt/local/lib/postgresql84/bin/pg_config
# On Windows:
#   gem install pg
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.
#
# Configure Using Gemfile
# gem 'pg'
#
development:
  adapter: postgresql
  encoding: unicode
  database: gitapp_development
  pool: 5
  username: gitapp
  password:
...
...
```

这个命令还根据我们选择的 PostgreSQL 数据库在 `database.yml` 中添加了一些设置。

NOTE: 指定源码管理系统选项时唯一的不便是，要先新建程序的文件夹，再初始化源码管理系统，然后才能执行 `rails new` 命令生成程序骨架。
