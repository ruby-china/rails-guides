# Rails 初始化过程

本文介绍 Rails 初始化过程的内部细节，内容较深，建议 Rails 高级开发者阅读。

读完本文后，您将学到：

*   如何使用 `rails server`；
*   Rails 初始化过程的时间线；
*   引导过程中所需的不同文件的所在位置；
*   `Rails::Server` 接口的定义和使用方式。

-----------------------------------------------------------------------------

NOTE: 本文原文尚未完工！

本文介绍默认情况下，Rails 应用初始化过程中的每一个方法调用，详细解释各个步骤的具体细节。本文将聚焦于使用 `rails server` 启动 Rails 应用时发生的事情。

NOTE: 除非另有说明，本文中出现的路径都是相对于 Rails 或 Rails 应用所在目录的相对路径。

TIP: 如果想一边阅读本文一边查看 [Rails 源代码](https://github.com/rails/rails)，推荐在 GitHub 中使用 `t` 快捷键打开文件查找器，以便快速查找相关文件。

<a class="anchor" id="launch"></a>

## 启动

首先介绍 Rails 应用引导和初始化的过程。我们可以通过 `rails console` 或 `rails server` 命令启动 Rails 应用。

<a class="anchor" id="railties-exe-rails"></a>

### `railties/exe/rails` 文件

`rails server` 命令中的 `rails` 是位于加载路径中的一个 Ruby 可执行文件。这个文件包含如下内容：

```ruby
version = ">= 0"
load Gem.bin_path('railties', 'rails', version)
```

在 Rails 控制台中运行上述代码，可以看到加载的是 `railties/exe/rails` 文件。`railties/exe/rails` 文件的部分内容如下：

```ruby
require "rails/cli"
```

`railties/lib/rails/cli` 文件又会调用 `Rails::AppLoader.exec_app` 方法。

<a class="anchor" id="railties-lib-rails-app-loader-rb"></a>

### `railties/lib/rails/app_loader.rb` 文件

`exec_app` 方法的主要作用是执行应用中的 `bin/rails` 文件。如果在当前文件夹中未找到 `bin/rails` 文件，就会继续在上层文件夹中查找，直到找到为止。因此，我们可以在 Rails 应用中的任何位置执行 `rails` 命令。

执行 `rails server` 命令时，实际执行的是等价的下述命令：

```sh
$ exec ruby bin/rails server
```

<a class="anchor" id="bin-rails"></a>

### `bin/rails` 文件

此文件包含如下内容：

```ruby
#!/usr/bin/env ruby
APP_PATH = File.expand_path('../../config/application', __FILE__)
require_relative '../config/boot'
require 'rails/commands'
```

其中 `APP_PATH` 常量稍后将在 `rails/commands` 中使用。所加载的 `config/boot` 是应用中的 `config/boot.rb` 文件，用于加载并设置 Bundler。

<a class="anchor" id="config-boot-rb"></a>

### `config/boot.rb` 文件

此文件包含如下内容：

```ruby
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' # 设置 Gemfile 中列出的所有 gem
```

标准的 Rails 应用中包含 `Gemfile` 文件，用于声明应用的所有依赖关系。`config/boot.rb` 文件会把 `ENV['BUNDLE_GEMFILE']` 设置为 `Gemfile` 文件的路径。如果 `Gemfile` 文件存在，就会加载 `bundler/setup`，Bundler 通过它设置 Gemfile 中依赖关系的加载路径。

标准的 Rails 应用依赖多个 gem，包括：

*   actionmailer
*   actionpack
*   actionview
*   activemodel
*   activerecord
*   activesupport
*   activejob
*   arel
*   builder
*   bundler
*   erubis
*   i18n
*   mail
*   mime-types
*   rack
*   rack-cache
*   rack-mount
*   rack-test
*   rails
*   railties
*   rake
*   sqlite3
*   thor
*   tzinfo

<a class="anchor" id="rails-commands-rb"></a>

### `rails/commands.rb` 文件

执行完 `config/boot.rb` 文件，下一步就要加载 `rails/commands`，其作用是扩展命令别名。在本例中（输入的命令为 `rails server`），`ARGV` 数组只包含将要传递的 `server` 命令：

```ruby
require "rails/command"

aliases = {
  "g"  => "generate",
  "d"  => "destroy",
  "c"  => "console",
  "s"  => "server",
  "db" => "dbconsole",
  "r"  => "runner",
  "t"  => "test"
}

command = ARGV.shift
command = aliases[command] || command

Rails::Command.invoke command, ARGV
```

如果输入的命令使用的是 `s` 而不是 `server`，Rails 就会在上面定义的 `aliases` 散列中查找对应的命令。

<a class="anchor" id="rails-command-rb"></a>

### `rails/command.rb` 文件

输入 Rails 命令时，`invoke` 尝试查找指定命名空间中的命令，如果找到就执行那个命令。

如果找不到命令，Rails 委托 Rake 执行同名任务。

如下述代码所示，`args` 为空时，`Rails::Command` 自动显示帮助信息。

```ruby
module Rails::Command
  class << self
    def invoke(namespace, args = [], **config)
      namespace = namespace.to_s
      namespace = "help" if namespace.blank? || HELP_MAPPINGS.include?(namespace)
      namespace = "version" if %w( -v --version ).include? namespace

      if command = find_by_namespace(namespace)
        command.perform(namespace, args, config)
      else
        find_by_namespace("rake").perform(namespace, args, config)
      end
    end
  end
end
```

本例中输入的是 `server` 命令，因此 Rails 会进一步运行下述代码：

```ruby
module Rails
  module Command
    class ServerCommand < Base # :nodoc:
      def perform
        set_application_directory!

        Rails::Server.new.tap do |server|
          # Require application after server sets environment to propagate
          # the --environment option.
          require APP_PATH
          Dir.chdir(Rails.application.root)
          server.start
        end
      end
    end
  end
end
```

仅当 `config.ru` 文件无法找到时，才会切换到 Rails 应用根目录（`APP_PATH` 所在文件夹的上一层文件夹，其中 `APP_PATH` 指向 `config/application.rb` 文件）。然后运行 `Rails::Server` 类。

<a class="anchor" id="actionpack-lib-action-dispatch-rb"></a>

### `actionpack/lib/action_dispatch.rb` 文件

Action Dispatch 是 Rails 框架的路由组件，提供路由、会话、常用中间件等功能。

<a class="anchor" id="rails-commands-server-server-command-rb"></a>

### `rails/commands/server/server_command.rb` 文件

此文件中定义的 `Rails::Server` 类，继承自 `Rack::Server` 类。当调用 `Rails::Server.new` 方法时，会调用此文件中定义的 `initialize` 方法：

```ruby
def initialize(*)
  super
  set_environment
end
```

首先调用的 `super` 方法，会调用 `Rack::Server` 类的 `initialize` 方法。

<a class="anchor" id="rack-lib-rack-server-rb"></a>

### Rack：`lib/rack/server.rb` 文件

`Rack::Server` 类负责为所有基于 Rack 的应用（包括 Rails）提供通用服务器接口。

`Rack::Server` 类的 `initialize` 方法的作用是设置几个变量：

```ruby
def initialize(options = nil)
  @options = options
  @app = options[:app] if options && options[:app]
end
```

在本例中，`options` 的值是 `nil`，因此这个方法什么也没做。

当 `super` 方法完成 `Rack::Server` 类的 `initialize` 方法的调用后，程序执行流程重新回到 `rails/commands/server/server_command.rb` 文件中。此时，会在 `Rails::Server` 对象的上下文中调用 `set_environment` 方法。乍一看这个方法什么也没做：

```ruby
def set_environment
  ENV["RAILS_ENV"] ||= options[:environment]
end
```

实际上，其中的 `options` 方法做了很多工作。`options` 方法在 `Rack::Server` 类中定义：

```ruby
def options
  @options ||= parse_options(ARGV)
end
```

而 `parse_options` 方法的定义如下：

```ruby
def parse_options(args)
  options = default_options

  # 请不要计算 CGI `ISINDEX` 参数的值。
  # http://www.meb.uni-bonn.de/docs/cgi/cl.html
  args.clear if ENV.include?("REQUEST_METHOD")

  options.merge! opt_parser.parse!(args)
  options[:config] = ::File.expand_path(options[:config])
  ENV["RACK_ENV"] = options[:environment]
  options
end
```

其中 `default_options` 方法的定义如下：

```ruby
def default_options
  super.merge(
    Port:               ENV.fetch("PORT", 3000).to_i,
    Host:               ENV.fetch("HOST", "localhost").dup,
    DoNotReverseLookup: true,
    environment:        (ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development").dup,
    daemonize:          false,
    caching:            nil,
    pid:                Options::DEFAULT_PID_PATH,
    restart_cmd:        restart_command)
end
```

在 `ENV` 散列中不存在 `REQUEST_METHOD` 键，因此可以跳过该行。下一行会合并 `opt_parser` 方法返回的选项，其中 `opt_parser` 方法在 `Rack::Server` 类中定义：

```ruby
def opt_parser
  Options.new
end
```

`Options` 类在 `Rack::Server` 类中定义，但在 `Rails::Server` 类中被覆盖了，目的是为了接受不同参数。`Options` 类的 `parse!` 方法的定义如下：

```ruby
def parse!(args)
  args, options = args.dup, {}

  option_parser(options).parse! args

  options[:log_stdout] = options[:daemonize].blank? && (options[:environment] || Rails.env) == "development"
  options[:server]     = args.shift
  options
end
```

此方法为 `options` 散列的键赋值，稍后 Rails 将使用此散列确定服务器的运行方式。`initialize` 方法运行完成后，程序执行流程会跳回 `server` 命令，然后加载之前设置的 `APP_PATH`。

<a class="anchor" id="config-application"></a>

### `config/application.rb` 文件

执行 `require APP_PATH` 时，会加载 `config/application.rb` 文件（前文说过 `APP_PATH` 已经在 `bin/rails` 中定义）。这个文件也是应用的一部分，我们可以根据需要修改这个文件的内容。

<a class="anchor" id="rails-server-start"></a>

### `Rails::Server#start` 方法

`config/application.rb` 文件加载完成后，会调用 `server.start` 方法。这个方法的定义如下：

```ruby
def start
  print_boot_information
  trap(:INT) { exit }
  create_tmp_directories
  setup_dev_caching
  log_to_stdout if options[:log_stdout]

  super
  ...
end

private
  def print_boot_information
    ...
    puts "=> Run `rails server -h` for more startup options"
  end

  def create_tmp_directories
    %w(cache pids sockets).each do |dir_to_make|
      FileUtils.mkdir_p(File.join(Rails.root, 'tmp', dir_to_make))
    end
  end

  def setup_dev_caching
    if options[:environment] == "development"
      Rails::DevCaching.enable_by_argument(options[:caching])
    end
  end

  def log_to_stdout
    wrapped_app # 对应用执行 touch 操作，以便设置记录器

    console = ActiveSupport::Logger.new(STDOUT)
    console.formatter = Rails.logger.formatter
    console.level = Rails.logger.level

    unless ActiveSupport::Logger.logger_outputs_to?(Rails.logger, STDOUT)
    Rails.logger.extend(ActiveSupport::Logger.broadcast(console))
  end
```

这是 Rails 初始化过程中第一次输出信息。`start` 方法为 `INT` 信号创建了一个陷阱，只要在服务器运行时按下 `CTRL-C`，服务器进程就会退出。我们看到，上述代码会创建 `tmp/cache`、`tmp/pids` 和 `tmp/sockets` 文件夹。然后，如果运行 `rails server` 命令时指定了 `--dev-caching` 参数，在开发环境中启用缓存。最后，调用 `wrapped_app` 方法，其作用是先创建 Rack 应用，再创建 `ActiveSupport::Logger` 类的实例。

`super` 方法会调用 `Rack::Server.start` 方法，后者的定义如下：

```ruby
def start &blk
  if options[:warn]
    $-w = true
  end

  if includes = options[:include]
    $LOAD_PATH.unshift(*includes)
  end

  if library = options[:require]
    require library
  end

  if options[:debug]
    $DEBUG = true
    require 'pp'
    p options[:server]
    pp wrapped_app
    pp app
  end

  check_pid! if options[:pid]

  # 对包装后的应用执行 touch 操作，以便在创建守护进程之前
  # 加载 `config.ru` 文件（例如在 `chdir` 等操作之前）
  wrapped_app

  daemonize_app if options[:daemonize]

  write_pid if options[:pid]

  trap(:INT) do
    if server.respond_to?(:shutdown)
      server.shutdown
    else
      exit
    end
  end

  server.run wrapped_app, options, &blk
end
```

代码块最后一行中的 `server.run` 非常有意思。这里我们再次遇到了 `wrapped_app` 方法，这次我们要更深入地研究它（前文已经调用过 `wrapped_app` 方法，现在需要回顾一下）。

```ruby
@wrapped_app ||= build_app app
```

其中 `app` 方法定义如下：

```ruby
def app
  @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
end
...
private
  def build_app_and_options_from_config
    if !::File.exist? options[:config]
      abort "configuration #{options[:config]} not found"
    end

    app, options = Rack::Builder.parse_file(self.options[:config], opt_parser)
    self.options.merge! options
    app
  end

  def build_app_from_string
    Rack::Builder.new_from_string(self.options[:builder])
  end
```

`options[:config]` 的默认值为 `config.ru`，此文件包含如下内容：

```ruby
# 基于 Rack 的服务器使用此文件来启动应用。

require_relative 'config/environment'
run <%= app_const %>
```

`Rack::Builder.parse_file` 方法读取 `config.ru` 文件的内容，并使用下述代码解析文件内容：

```ruby
app = new_from_string cfgfile, config

...

def self.new_from_string(builder_script, file="(rackup)")
  eval "Rack::Builder.new {\n" + builder_script + "\n}.to_app",
    TOPLEVEL_BINDING, file, 0
end
```

`Rack::Builder` 类的 `initialize` 方法会把接收到的代码块在 `Rack::Builder` 类的实例中执行，Rails 初始化过程中的大部分工作都在这一步完成。在 `config.ru` 文件中，加载 `config/environment.rb` 文件的这一行代码首先被执行：

```ruby
require_relative 'config/environment'
```

<a class="anchor" id="config-environment-rb"></a>

### `config/environment.rb` 文件

`config.ru` 文件（`rails server`）和 Passenger 都需要加载此文件。这两种运行服务器的方式直到这里才出现了交集，此前的一切工作都只是围绕 Rack 和 Rails 的设置进行的。

此文件以加载 `config/application.rb` 文件开始：

```ruby
require_relative 'application'
```

<a class="anchor" id="config-application-rb"></a>

### `config/application.rb` 文件

此文件会加载 `config/boot.rb` 文件：

```ruby
require_relative 'boot'
```

对于 `rails server` 这种启动服务器的方式，之前并未加载过 `config/boot.rb` 文件，因此这里会加载该文件；对于 Passenger，之前已经加载过该文件，这里就不会重复加载了。

接下来，有趣的事情就要开始了！

<a class="anchor" id="loading-rails"></a>

## 加载 Rails

`config/application.rb` 文件的下一行是：

```ruby
require 'rails/all'
```

<a class="anchor" id="railties-lib-rails-all-rb"></a>

### `railties/lib/rails/all.rb` 文件

此文件负责加载 Rails 中所有独立的框架：

```ruby
require "rails"

%w(
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
  action_cable/engine
  rails/test_unit/railtie
  sprockets/railtie
).each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end
```

这些框架加载完成后，就可以在 Rails 应用中使用了。这里不会深入介绍每个框架，而是鼓励读者自己动手试验和探索。

现在，我们只需记住，Rails 的常见功能，例如 Rails 引擎、I18n 和 Rails 配置，都在这里定义好了。

<a class="anchor" id="config-environment-rb-1"></a>

### 回到 `config/environment.rb` 文件

`config/application.rb` 文件的其余部分定义了 `Rails::Application` 的配置，当应用的初始化全部完成后就会使用这些配置。当 `config/application.rb` 文件完成了 Rails 的加载和应用命名空间的定义后，程序执行流程再次回到 `config/environment.rb` 文件。在这里会通过 `rails/application.rb` 文件中定义的 `Rails.application.initialize!` 方法完成应用的初始化。

<a class="anchor" id="railties-lib-rails-application-rb"></a>

### `railties/lib/rails/application.rb` 文件

`initialize!` 方法的定义如下：

```ruby
def initialize!(group=:default) #:nodoc:
  raise "Application has been already initialized." if @initialized
  run_initializers(group, self)
  @initialized = true
  self
end
```

我们看到，一个应用只能初始化一次。`railties/lib/rails/initializable.rb` 文件中定义的 `run_initializers` 方法负责运行初始化程序：

```ruby
def run_initializers(group=:default, *args)
  return if instance_variable_defined?(:@ran)
  initializers.tsort_each do |initializer|
    initializer.run(*args) if initializer.belongs_to?(group)
  end
  @ran = true
end
```

`run_initializers` 方法的代码比较复杂，Rails 会遍历所有类的祖先，以查找能够响应 `initializers` 方法的类。对于找到的类，首先按名称排序，然后依次调用 `initializers` 方法。例如，`Engine` 类通过为所有的引擎提供 `initializers` 方法而使它们可用。

`railties/lib/rails/application.rb` 文件中定义的 `Rails::Application` 类，定义了 `bootstrap`、`railtie` 和 `finisher` 初始化程序。`bootstrap` 初始化程序负责完成应用初始化的准备工作（例如初始化记录器），而 `finisher` 初始化程序（例如创建中间件栈）总是最后运行。`railtie` 初始化程序在 `Rails::Application` 类自身中定义，在 `bootstrap` 之后、`finishers` 之前运行。

应用初始化完成后，程序执行流程再次回到 `Rack::Server` 类。

<a class="anchor" id="rack-lib-rack-server-rb-1"></a>

### Rack：`lib/rack/server.rb` 文件

程序执行流程上一次离开此文件是在定义 `app` 方法时：

```ruby
def app
  @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
end
...
private
  def build_app_and_options_from_config
    if !::File.exist? options[:config]
      abort "configuration #{options[:config]} not found"
    end

    app, options = Rack::Builder.parse_file(self.options[:config], opt_parser)
    self.options.merge! options
    app
  end

  def build_app_from_string
    Rack::Builder.new_from_string(self.options[:builder])
  end
```

此时，`app` 就是 Rails 应用本身（一个中间件），接下来 Rack 会调用所有已提供的中间件：

```ruby
def build_app(app)
  middleware[options[:environment]].reverse_each do |middleware|
    middleware = middleware.call(self) if middleware.respond_to?(:call)
    next unless middleware
    klass = middleware.shift
    app = klass.new(app, *middleware)
  end
  app
end
```

记住，在 `Server#start` 方法定义的最后一行代码中，通过 `wrapped_app` 方法调用了 `build_app` 方法。让我们回顾一下这行代码：

```ruby
server.run wrapped_app, options, &blk
```

此时，`server.run` 方法的实现方式取决于我们所使用的服务器。例如，如果使用的是 Puma，`run` 方法的实现方式如下：

```ruby
...
DEFAULT_OPTIONS = {
  :Host => '0.0.0.0',
  :Port => 8080,
  :Threads => '0:16',
  :Verbose => false
}

def self.run(app, options = {})
  options = DEFAULT_OPTIONS.merge(options)

  if options[:Verbose]
    app = Rack::CommonLogger.new(app, STDOUT)
  end

  if options[:environment]
    ENV['RACK_ENV'] = options[:environment].to_s
  end

  server   = ::Puma::Server.new(app)
  min, max = options[:Threads].split(':', 2)

  puts "Puma #{::Puma::Const::PUMA_VERSION} starting..."
  puts "* Min threads: #{min}, max threads: #{max}"
  puts "* Environment: #{ENV['RACK_ENV']}"
  puts "* Listening on tcp://#{options[:Host]}:#{options[:Port]}"

  server.add_tcp_listener options[:Host], options[:Port]
  server.min_threads = min
  server.max_threads = max
  yield server if block_given?

  begin
    server.run.join
  rescue Interrupt
    puts "* Gracefully stopping, waiting for requests to finish"
    server.stop(true)
    puts "* Goodbye!"
  end

end
```

我们不会深入介绍服务器配置本身，不过这已经是 Rails 初始化过程的最后一步了。

本文高度概括的介绍，旨在帮助读者理解 Rails 应用的代码何时执行、如何执行，从而使读者成为更优秀的 Rails 开发者。要想掌握更多这方面的知识，Rails 源代码本身也许是最好的研究对象。
