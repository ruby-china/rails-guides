# Rails 命令行

读完本文后，您将学到：

*   如何新建 Rails 应用；
*   如何生成模型、控制器、数据库迁移和单元测试；
*   如何启动开发服务器；
*   如果在交互式 shell 中测试对象；

-----------------------------------------------------------------------------

NOTE: 阅读本文前请阅读[Rails 入门](getting_started.html)，掌握一些 Rails 基础知识。


<a class="anchor" id="command-line-basics"></a>

## 命令行基础

有些命令在 Rails 开发过程中经常会用到，下面按照使用频率倒序列出：

*   `rails console`
*   `rails server`
*   `bin/rails`
*   `rails generate`
*   `rails dbconsole`
*   `rails new app_name`

这些命令都可指定 `-h` 或 `--help` 选项列出更多信息。

下面我们新建一个 Rails 应用，通过它介绍各个命令的用法。

<a class="anchor" id="rails-new"></a>

### `rails new`

安装 Rails 后首先要做的就是使用 `rails new` 命令新建 Rails 应用。

TIP: 如果还没安装 Rails ，可以执行 `gem install rails` 命令安装。


```sh
$ rails new commandsapp
     create
     create  README.md
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

这个简单的命令会生成很多文件，组成一个完整的 Rails 应用目录结构，直接就可运行。

<a class="anchor" id="rails-server"></a>

### `rails server`

`rails server` 命令用于启动 Rails 自带的 Puma Web 服务器。若想在浏览器中访问应用，就要执行这个命令。

无需其他操作，执行 `rails server` 命令后就能运行刚才创建的 Rails 应用：

```sh
$ cd commandsapp
$ bin/rails server
=> Booting Puma
=> Rails 5.1.0 application starting in development on http://0.0.0.0:3000
=> Run `rails server -h` for more startup options
Puma starting in single mode...
* Version 3.0.2 (ruby 2.3.0-p0), codename: Plethora of Penguin Pinatas
* Min threads: 5, max threads: 5
* Environment: development
* Listening on tcp://localhost:3000
Use Ctrl-C to stop
```

只执行了三个命令，我们就启动了一个 Rails 服务器，监听着 3000 端口。打开浏览器，访问 <http://localhost:3000>，你会看到一个简单的 Rails 应用。

TIP: 启动服务器的命令还可使用别名“s”：`rails s`。


如果想让服务器监听其他端口，可通过 `-p` 选项指定。所处的环境（默认为开发环境）可由 `-e` 选项指定。

```sh
$ bin/rails server -e production -p 4000
```

`-b` 选项把 Rails 绑定到指定的 IP（默认为 localhost）。指定 `-d` 选项后，服务器会以守护进程的形式运行。

<a class="anchor" id="rails-generate"></a>

### `rails generate`

`rails generate` 目录使用模板生成很多东西。单独执行 `rails generate` 命令，会列出可用的生成器：

TIP: 还可使用别名“g”执行生成器命令：`rails g`。


```sh
$ bin/rails generate
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


使用生成器可以节省大量编写样板代码（即应用运行必须的代码）的时间。

下面我们使用控制器生成器生成一个控制器。不过，应该使用哪个命令呢？我们问一下生成器：

TIP: 所有 Rails 命令都有帮助信息。和其他 *nix 命令一样，可以在命令后加上 `--help` 或 `-h` 选项，例如 `rails server --help`。


```sh
$ bin/rails generate controller
Usage: rails generate controller NAME [action action] [options]

...
...

Description:
    ...

    To create a controller within a module, specify the controller name as a path like 'parent_module/controller_name'.

    ...

Example:
    `rails generate controller CreditCards open debit credit close`

    Credit card controller with URLs like /credit_cards/debit.
        Controller: app/controllers/credit_cards_controller.rb
        Test:       test/controllers/credit_cards_controller_test.rb
        Views:      app/views/credit_cards/debit.html.erb [...]
        Helper:     app/helpers/credit_cards_helper.rb
```

控制器生成器接受的参数形式是 `generate controller ControllerName action1 action2`。下面我们来生成 `Greetings` 控制器，包含一个动作 `hello`，通过它跟读者打个招呼。

```sh
$ bin/rails generate controller Greetings hello
     create  app/controllers/greetings_controller.rb
      route  get "greetings/hello"
     invoke  erb
     create    app/views/greetings
     create    app/views/greetings/hello.html.erb
     invoke  test_unit
     create    test/controllers/greetings_controller_test.rb
     invoke  helper
     create    app/helpers/greetings_helper.rb
     invoke  assets
     invoke    coffee
     create      app/assets/javascripts/greetings.coffee
     invoke    scss
     create      app/assets/stylesheets/greetings.scss
```

这个命令生成了什么呢？它在应用中创建了一堆目录，还有控制器文件、视图文件、功能测试文件、视图辅助方法文件、JavaScript 文件和样式表文件。

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

```sh
$ bin/rails server
=> Booting Puma...
```

要查看的 URL 是 <http://localhost:3000/greetings/hello>。

TIP: 在常规的 Rails 应用中，URL 的格式是 http://(host)/(controller)/(action)，访问 http://(host)/(controller) 这样的 URL 会进入控制器的 `index` 动作。


Rails 也为数据模型提供了生成器。

```sh
$ bin/rails generate model
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

NOTE: `type` 参数可用的全部字段类型参见 `SchemaStatements` 模块中 [`add_column` 方法的 API 文档](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_column)。`index` 参数为相应的列生成索引。


不过我们暂且不直接生成模型（后文再生成），先来使用脚手架（scaffold）。Rails 中的脚手架会生成资源所需的全部文件，包括模型、模型所用的迁移、处理模型的控制器、查看数据的视图，以及各部分的测试组件。

我们要创建一个名为“HighScore”的资源，记录视频游戏的最高得分。

```sh
$ bin/rails generate scaffold HighScore game:string score:integer
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
    invoke    jbuilder
    create      app/views/high_scores/index.json.jbuilder
    create      app/views/high_scores/show.json.jbuilder
    invoke  assets
    invoke    coffee
    create      app/assets/javascripts/high_scores.coffee
    invoke    scss
    create      app/assets/stylesheets/high_scores.scss
    invoke  scss
   identical    app/assets/stylesheets/scaffolds.scss
```

这个生成器检测到以下各组件对应的目录已经存在：模型、控制器、辅助方法、布局、功能测试、单元测试和样式表。然后创建“HighScore”资源的视图、控制器、模型和数据库迁移（用于创建 `high_scores` 数据表和字段），并设置好路由，以及测试等。

我们要运行迁移，执行文件 `20130717151933_create_high_scores.rb` 中的代码，这样才能修改数据库的模式。那么要修改哪个数据库呢？执行 `bin/rails db:migrate` 命令后会生成 SQLite3 数据库。稍后再详细说明 `bin/rails`。

```sh
$ bin/rails db:migrate
==  CreateHighScores: migrating ===============================================
-- create_table(:high_scores)
   -> 0.0017s
==  CreateHighScores: migrated (0.0019s) ======================================
```

TIP: 介绍一下单元测试。单元测试是用来测试和做断言的代码。在单元测试中，我们只关注代码的一小部分，例如模型中的一个方法，测试其输入和输出。单元测试是你的好伙伴，你逐渐会意识到，单元测试的程度越高，生活的质量越高。真的。关于单元测试的详情，参阅[Rails 应用测试指南](testing.html)。


我们来看一下 Rails 创建的界面。

```sh
$ bin/rails server
```

打开浏览器，访问 <http://localhost:3000/high_scores>，现在可以创建新的最高得分了（太空入侵者得了 55,160 分）。

<a class="anchor" id="rails-console"></a>

### `rails console`

执行 `console` 命令后，可以在命令行中与 Rails 应用交互。`rails console` 使用的是 IRB，所以如果你用过 IRB 的话，操作起来很顺手。在控制台里可以快速测试想法，或者修改服务器端数据，而无需在网站中操作。

TIP: 这个命令还可以使用别名“c”：`rails c`。


执行 `console` 命令时可以指定在哪个环境中打开控制台：

```sh
$ bin/rails console staging
```

如果你想测试一些代码，但不想改变存储的数据，可以执行 `rails console --sandbox` 命令。

```sh
$ bin/rails console --sandbox
Loading development environment in sandbox (Rails 5.1.0)
Any modifications you make will be rolled back on exit
irb(main):001:0>
```

<a class="anchor" id="the-app-and-helper-objects"></a>

#### `app` 和 `helper` 对象

在控制台中可以访问 `app` 和 `helper` 对象。

通过 `app` 可以访问 URL 和路径辅助方法，还可以发送请求。

```irb
>> app.root_path
=> "/"

>> app.get _
Started GET "/" for 127.0.0.1 at 2014-06-19 10:41:57 -0300
...
```

通过 `helper` 可以访问 Rails 和应用定义的辅助方法。

```irb
>> helper.time_ago_in_words 30.days.ago
=> "about 1 month"

>> helper.my_custom_helper
=> "my custom helper"
```

<a class="anchor" id="rails-dbconsole"></a>

### `rails dbconsole`

`rails dbconsole` 能检测到你正在使用的数据库类型（还能理解传入的命令行参数），然后进入该数据库的命令行界面。该命令支持 MySQL（包括 MariaDB）、PostgreSQL 和 SQLite3。

TIP: 这个命令还可以使用别名“db”：`rails db`。


<a class="anchor" id="rails-runner"></a>

### `rails runner`

`runner` 能以非交互的方式在 Rails 中运行 Ruby 代码。例如：

```sh
$ bin/rails runner "Model.long_running_method"
```

TIP: 这个命令还可以使用别名“r”：`rails r`。


可以使用 `-e` 选项指定 `runner` 命令在哪个环境中运行。

```sh
$ bin/rails runner -e staging "Model.long_running_method"
```

甚至还可以执行文件中的 Ruby 代码：

```sh
$ bin/rails runner lib/code_to_be_run.rb
```

<a class="anchor" id="rails-destroy"></a>

### `rails destroy`

`destroy` 可以理解成 `generate` 的逆操作，它能识别生成了什么，然后撤销。

TIP: 这个命令还可以使用别名“d”：`rails d`。


```sh
$ bin/rails generate model Oops
      invoke  active_record
      create    db/migrate/20120528062523_create_oops.rb
      create    app/models/oops.rb
      invoke    test_unit
      create      test/models/oops_test.rb
      create      test/fixtures/oops.yml
```

```sh
$ bin/rails destroy model Oops
      invoke  active_record
      remove    db/migrate/20120528062523_create_oops.rb
      remove    app/models/oops.rb
      invoke    test_unit
      remove      test/models/oops_test.rb
      remove      test/fixtures/oops.yml
```

<a class="anchor" id="bin-rails"></a>

## `bin/rails`

从 Rails 5.0+ 起，rake 命令内建到 `rails` 可执行文件中了，因此现在应该使用 `bin/rails` 执行命令。

`bin/rails` 支持的任务列表可通过 `bin/rails --help` 查看（可用的任务根据所在的目录有所不同）。每个任务都有描述，应该能帮助你找到所需的那个。

```sh
$ bin/rails --help
Usage: rails COMMAND [ARGS]

The most common rails commands are:
generate    Generate new code (short-cut alias: "g")
console     Start the Rails console (short-cut alias: "c")
server      Start the Rails server (short-cut alias: "s")
...

All commands can be run with -h (or --help) for more information.

In addition to those commands, there are:
about                               List versions of all Rails ...
assets:clean[keep]                  Remove old compiled assets
assets:clobber                      Remove compiled assets
assets:environment                  Load asset compile environment
assets:precompile                   Compile all the assets ...
...
db:fixtures:load                    Loads fixtures into the ...
db:migrate                          Migrate the database ...
db:migrate:status                   Display status of migrations
db:rollback                         Rolls the schema back to ...
db:schema:cache:clear               Clears a db/schema_cache.yml file
db:schema:cache:dump                Creates a db/schema_cache.yml file
db:schema:dump                      Creates a db/schema.rb file ...
db:schema:load                      Loads a schema.rb file ...
db:seed                             Loads the seed data ...
db:structure:dump                   Dumps the database structure ...
db:structure:load                   Recreates the databases ...
db:version                          Retrieves the current schema ...
...
restart                             Restart app by touching ...
tmp:create
```

TIP: 还可以使用 `bin/rails -T` 列出所有任务。


<a class="anchor" id="about"></a>

### `about`

`bin/rails about` 输出以下信息：Ruby、RubyGems、Rails 的版本号，Rails 使用的组件，应用所在的文件夹，Rails 当前所处的环境名，应用使用的数据库适配器，以及数据库模式版本号。如果想向他人需求帮助，检查安全补丁对你是否有影响，或者需要查看现有 Rails 应用的状态，就可以使用这个任务。

```sh
$ bin/rails about
About your application's environment
Rails version             5.1.0
Ruby version              2.2.2 (x86_64-linux)
RubyGems version          2.4.6
Rack version              2.0.1
JavaScript Runtime        Node.js (V8)
Middleware:               Rack::Sendfile, ActionDispatch::Static, ActionDispatch::Executor, ActiveSupport::Cache::Strategy::LocalCache::Middleware, Rack::Runtime, Rack::MethodOverride, ActionDispatch::RequestId, ActionDispatch::RemoteIp, Sprockets::Rails::QuietAssets, Rails::Rack::Logger, ActionDispatch::ShowExceptions, WebConsole::Middleware, ActionDispatch::DebugExceptions, ActionDispatch::Reloader, ActionDispatch::Callbacks, ActiveRecord::Migration::CheckPending, ActionDispatch::Cookies, ActionDispatch::Session::CookieStore, ActionDispatch::Flash, Rack::Head, Rack::ConditionalGet, Rack::ETag
Application root          /home/foobar/commandsapp
Environment               development
Database adapter          sqlite3
Database schema version   20110805173523
```

<a class="anchor" id="assets"></a>

### `assets`

`bin/rails assets:precompile` 用于预编译 `app/assets` 文件夹中的静态资源文件。`bin/rails assets:clean` 用于把之前编译好的静态资源文件删除。滚动部署时应该执行 `assets:clean`，以防仍然链接旧的静态资源文件。

如果想完全清空 `public/assets` 目录，可以使用 `bin/rails assets:clobber`。

<a class="anchor" id="db"></a>

### `db`

`bin/rails` 命名空间 `db:` 中最常用的任务是 `migrate` 和 `create`，这两个任务会尝试运行所有迁移相关的任务（`up`、`down`、`redo`、`reset`）。`bin/rails db:version` 在排查问题时很有用，它会输出数据库的当前版本。

关于数据库迁移的进一步说明，参阅[Active Record 迁移](active_record_migrations.html)。

<a class="anchor" id="notes"></a>

### `notes`

`bin/rails notes` 在代码中搜索以 FIXME、OPTIMIZE 或 TODO 开头的注释。搜索的文件类型包括 `.builder`、`.rb`、`.rake`、`.yml`、`.yaml`、`.ruby`、`.css`、`.js` 和 `.erb`，搜索的注解包括默认的和自定义的。

```sh
$ bin/rails notes
(in /home/foobar/commandsapp)
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] any other way to do this?
  * [132] [FIXME] high priority for next deploy

app/models/school.rb:
  * [ 13] [OPTIMIZE] refactor this code to make it faster
  * [ 17] [FIXME]
```

可以使用 `config.annotations.register_extensions` 选项添加新的文件扩展名。这个选项的值是扩展名列表和对应的正则表达式。

```ruby
config.annotations.register_extensions("scss", "sass", "less") { |annotation| /\/\/\s*(#{annotation}):?\s*(.*)$/ }
```

如果想查看特定类型的注解，如 FIXME，可以使用 `bin/rails notes:fixme`。注意，注解的名称是小写形式。

```sh
$ bin/rails notes:fixme
(in /home/foobar/commandsapp)
app/controllers/admin/users_controller.rb:
  * [132] high priority for next deploy

app/models/school.rb:
  * [ 17]
```

此外，还可以在代码中使用自定义的注解，然后使用 `bin/rails notes:custom`，并通过 `ANNOTATION` 环境变量指定注解类型，将其列出。

```sh
$ bin/rails notes:custom ANNOTATION=BUG
(in /home/foobar/commandsapp)
app/models/article.rb:
  * [ 23] Have to fix this one before pushing!
```

NOTE: 使用内置的注解或自定义的注解时，注解的名称（FIXME、BUG 等）不会在输出中显示。


默认情况下，`rails notes` 在 `app`、`config`、`db`、`lib` 和 `test` 目录中搜索。如果想搜索其他目录，可以通过 `config.annotations.register_directories` 选项配置。

```ruby
config.annotations.register_directories("spec", "vendor")
```

此外，还可以通过 `SOURCE_ANNOTATION_DIRECTORIES` 环境变量指定，目录之间使用逗号分开。

```sh
$ export SOURCE_ANNOTATION_DIRECTORIES='spec,vendor'
$ bin/rails notes
(in /home/foobar/commandsapp)
app/models/user.rb:
  * [ 35] [FIXME] User should have a subscription at this point
spec/models/user_spec.rb:
  * [122] [TODO] Verify the user that has a subscription works
```

<a class="anchor" id="routes"></a>

### `routes`

`rails routes` 列出应用中定义的所有路由，可为解决路由问题提供帮助，还可以让你对应用中的所有 URL 有个整体了解。

<a class="anchor" id="test"></a>

### `test`

TIP: Rails 中的单元测试详情，参见[Rails 应用测试指南](testing.html)。


Rails 提供了一个名为 Minitest 的测试组件。Rails 的稳定性由测试决定。`test:` 命名空间中的任务可用于运行各种测试。

<a class="anchor" id="tmp"></a>

### `tmp`

`Rails.root/tmp` 目录和 *nix 系统中的 `/tmp` 目录作用相同，用于存放临时文件，例如 PID 文件和缓存的动作等。

`tmp:` 命名空间中的任务可以清理或创建 `Rails.root/tmp` 目录：

*   `rails tmp:cache:clear` 清空 `tmp/cache` 目录；
*   `rails tmp:sockets:clear` 清空 `tmp/sockets` 目录；
*   `rails tmp:clear` 清空所有缓存和套接字文件；
*   `rails tmp:create` 创建缓存、套接字和 PID 所需的临时目录；

<a class="anchor" id="miscellaneous"></a>

### 其他任务

*   `rails stats` 用于统计代码状况，显示千行代码数和测试比例等；
*   `rails secret` 生成一个伪随机字符串，作为会话的密钥；
*   `rails time:zones:all` 列出 Rails 能理解的所有时区；

<a class="anchor" id="custom-rake-tasks"></a>

### 自定义 Rake 任务

自定义的 Rake 任务保存在 `Rails.root/lib/tasks` 目录中，文件的扩展名是 `.rake`。执行 `bin/rails generate task` 命令会生成一个新的自定义任务文件。

```ruby
desc "I am short, but comprehensive description for my cool task"
task task_name: [:prerequisite_task, :another_task_we_depend_on] do
  # 在这里定义任务
  # 可以使用任何有效的 Ruby 代码
end
```

向自定义的任务传入参数的方式如下：

```ruby
task :task_name, [:arg_1] => [:prerequisite_1, :prerequisite_2] do |task, args|
  argument_1 = args.arg_1
end
```

任务可以分组，放入命名空间：

```ruby
namespace :db do
  desc "This task does nothing"
  task :nothing do
    # 确实什么也没做
  end
end
```

执行任务的方法如下：

```sh
$ bin/rails task_name
$ bin/rails "task_name[value 1]" # 整个参数字符串应该放在引号内
$ bin/rails db:nothing
```

NOTE: 如果在任务中要与应用的模型交互、查询数据库等，可以使用 `environment` 任务加载应用代码。


<a class="anchor" id="the-rails-advanced-command-line"></a>

## Rails 命令行高级用法

Rails 命令行的高级用法就是找到实用的参数，满足特定需求或者工作流程。下面是一些常用的高级命令。

<a class="anchor" id="rails-with-databases-and-scm"></a>

### 新建应用时指定数据库和源码管理系统

新建 Rails 应用时，可以设定一些选项指定使用哪种数据库和源码管理系统。这么做可以节省一点时间，减少敲击键盘的次数。

我们来看一下 `--git` 和 `--database=postgresql` 选项有什么作用：

```sh
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
      create  README.md
add 'README.md'
      create  app/controllers/application_controller.rb
add 'app/controllers/application_controller.rb'
      create  app/helpers/application_helper.rb
...
      create  log/test.log
add 'log/test.log'
```

上面的命令先新建 `gitapp` 文件夹，初始化一个空的 git 仓库，然后再把 Rails 生成的文件纳入仓库。再来看一下它在数据库配置文件中添加了什么：

```sh
$ cat config/database.yml
# PostgreSQL. Versions 9.1 and up are supported.
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

这个命令还根据我们选择的 PostgreSQL 数据库在 `database.yml` 中添加了一些配置。

NOTE: 指定源码管理系统选项时唯一的不便是，要先新建存放应用的目录，再初始化源码管理系统，然后才能执行 `rails new` 命令生成应用骨架。

