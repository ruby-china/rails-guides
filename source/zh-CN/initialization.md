Rails 应用的初始化过程
================================

本章节介绍了 Rails 4 应用启动的内部流程。很适合有一定经验的Rails 开发者阅读。

通过学习本章节，您会学到如下知识：

* 如何使用 `rails server`；
* Rails应用初始化的时间序列；
* Rails应用启动过程都用到哪些文件；
* Rails::Server接口的定义和使用；

--------------------------------------------------------------------------------
 
本章节通过介绍一个基于Ruby on Rails框架默认配置的 Rails 4 应用程序启动过程中的方法调用，详细介绍了每个调用的细节。通过本章节，我们将了解当你执行`rails server`命令启动你的Rails应用时，背后究竟都发生了什么。


提示：本章节中的路径如果没有特别说明都是指Rails应用程序下的路径。


提示：如果你想浏览Rails的源代码[sourcecode](https://github.com/rails/rails)，强烈建议您使用快捷键 `t`快速查找Github中的文件。

启 动 !
-------

我们现在准备启动和初始化一个Rails 应用。 一个Rails 应用经常是以运行命令 `rails console` 或者 `rails server` 开始的。

### `railties/bin/rails`

Rails应用中的 `rails server`命令是Rails应用程序所在文件中的一个Ruby的可执行程序，该程序包含如下操作：

```ruby
version = ">= 0"
load Gem.bin_path('railties', 'rails', version)
```

如果你在Rails 控制台中使用上述命令，你将会看到载入`railties/bin/rails`这个路径。作为 `railties/bin/rails.rb`的一部分，包含如下代码：

```ruby
require "rails/cli"
```

模块`railties/lib/rails/cli` 会调用`Rails::AppRailsLoader.exec_app_rails`方法.

### `railties/lib/rails/app_rails_loader.rb`

`exec_app_rails`模块的主要功能是去执行你的Rails应用中`bin/rails`文件夹下的指令。如果当前文件夹下没有`bin/rails`文件，它会到父级目录去搜索，直到找到为止（Windows下应该会去搜索环境变量中的路径），在Rails应用程序目录下的任意位置(命令行模式下)，都会触发`rails`的指令执行。

因为`rails server`命令和下面的操作是等价的：

```bash
$ exec ruby bin/rails server
```

### `bin/rails`

文件`railties/bin/rails`包含如下代码：

```ruby
#!/usr/bin/env ruby
APP_PATH = File.expand_path('../../config/application', __FILE__)
require_relative '../config/boot'
require 'rails/commands'
```

`APP_PATH`稍后会在`rails/commands`中用到。`config/boot`在这被引用是因为我们的Rails应用中需要`config/boot.rb`文件来载入Bundler,并初始化Bundler的配置。

### `config/boot.rb`

`config/boot.rb` 包含如下代码:

```ruby
# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
```

在一个标准的Rails应用中，一个`Gemfile`文件配置会配置它的所有依赖项。`config/boot.rb`文件会根据`ENV['BUNDLE_GEMFILE']`中的值来查找`Gemfile`的路径。如果Gemfile文件存在，那么`bundler/setup`操作会被执行，Bundler执行该操作是为了配置Gemfile依赖项的加载路径。

一个标准的Rails应用会包含若干Gem包，特别是下面这些：

* actionmailer
* actionpack
* actionview
* activemodel
* activerecord
* activesupport
* arel
* builder
* bundler
* erubis
* i18n
* mail
* mime-types
* polyglot
* rack
* rack-cache
* rack-mount
* rack-test
* rails
* railties
* rake
* sqlite3
* thor
* treetop
* tzinfo

### `rails/commands.rb`

一旦`config/boot.rb`执行完毕，接下来要引用的是`rails/commands`文件，这个文件于帮助解析别名。在本应用中，`ARGV` 数组包含的 `server`项会被匹配：

```ruby
ARGV << '--help' if ARGV.empty?

aliases = {
  "g"  => "generate",
  "d"  => "destroy",
  "c"  => "console",
  "s"  => "server",
  "db" => "dbconsole",
  "r"  => "runner"
}

command = ARGV.shift
command = aliases[command] || command

require 'rails/commands/commands_tasks'

Rails::CommandsTasks.new(ARGV).run_command!(command)
```

提示： 如你所见，一个空的ARGV数组将会让系统显示相关的帮助项。

如果我们使用`s`缩写代替 `server`，Rails系统会从`aliases`中查找匹配的命令。

### `rails/commands/command_tasks.rb`

当你键入一个错误的rails命令，`run_command`函数会抛出一个错误信息。如果命令正确，一个与命令同名的方法会被调用。

```ruby
COMMAND_WHITELIST = %(plugin generate destroy console server dbconsole application runner new version help)

def run_command!(command)
  command = parse_command(command)
  if COMMAND_WHITELIST.include?(command)
    send(command)
  else
    write_error_message(command)
  end
end
```

如果执行`server`命令，Rails将会继续执行下面的代码：

```ruby
def set_application_directory!
  Dir.chdir(File.expand_path('../../', APP_PATH)) unless File.exist?(File.expand_path("config.ru"))
end

def server
  set_application_directory!
  require_command!("server")

  Rails::Server.new.tap do |server|
    # We need to require application after the server sets environment,
    # otherwise the --environment option given to the server won't propagate.
    require APP_PATH
    Dir.chdir(Rails.application.root)
    server.start
  end
end

def require_command!(command)
  require "rails/commands/#{command}"
end
```

这个文件将会指向Rails的根目录（与`APP_PATH`中指向`config/application.rb`不同），但是如果没找到`config.ru`文件，接下来将需要`rails/commands/server`来创建`Rails::Server`类。

```ruby
require 'fileutils'
require 'optparse'
require 'action_dispatch'
require 'rails'

module Rails
  class Server < ::Rack::Server
```

`fileutils` 和 `optparse` 是Ruby标准库中帮助操作文件和解析选项的函数。

### `actionpack/lib/action_dispatch.rb`

动作分发(Action Dispatch)是Rails框架中的路径组件。它增强了路径，会话和中间件的功能。

### `rails/commands/server.rb`

这个文件中定义的`Rails::Server`类是继承自`Rack::Server`类的。当`Rails::Server.new`被调用时，会在 `rails/commands/server.rb`中调用一个`initialize`方法：

```ruby
def initialize(*)
  super
  set_environment
end
```

首先，`super`会调用父类`Rack::Server`中的`initialize`方法。

### Rack: `lib/rack/server.rb`

`Rack::Server`会为所有基于Rack的应用提供服务接口，现在它已经是Rails框架的一部分了。

`Rack::Server`中的`initialize` 方法会简单的设置一对变量：

```ruby
def initialize(options = nil)
  @options = options
  @app = options[:app] if options && options[:app]
end
```

在这种情况下，`options` 的值是 `nil`，所以在这个方法中相当于什么都没做。

当`Rack::Server`中的`super`方法执行完毕后。我们回到`rails/commands/server.rb`，此时此刻，`Rails::Server`对象会调用 `set_environment` 方法，这个方法貌似看上去什么也没干： 

```ruby
def set_environment
  ENV["RAILS_ENV"] ||= options[:environment]
end
```

事实上，`options`方法在这做了很多事情。`Rack::Server` 中的这个方法定义如下：

```ruby
def options
  @options ||= parse_options(ARGV)
end
```

接着`parse_options`方法定义如下：

```ruby
def parse_options(args)
  options = default_options

  # Don't evaluate CGI ISINDEX parameters.
  # http://www.meb.uni-bonn.de/docs/cgi/cl.html
  args.clear if ENV.include?("REQUEST_METHOD")

  options.merge! opt_parser.parse!(args)
  options[:config] = ::File.expand_path(options[:config])
  ENV["RACK_ENV"] = options[:environment]
  options
end
```

`default_options`方法的代码如下：

```ruby
def default_options
  environment  = ENV['RACK_ENV'] || 'development'
  default_host = environment == 'development' ? 'localhost' : '0.0.0.0'

  {
    :environment => environment,
    :pid         => nil,
    :Port        => 9292,
    :Host        => default_host,
    :AccessLog   => [],
    :config      => "config.ru"
  }
end
```

`ENV`中没有`REQUEST_METHOD`项，所以我们可以忽略这一行。接下来是已经在 `Rack::Server`被定义好的`opt_parser`方法：

```ruby
def opt_parser
  Options.new
end
```

**这个**方法已经在`Rack::Server`被定义过了，但是在`Rails::Server` 使用不同的参数进行了重载。他的 `parse!`方法如下：

```ruby
def parse!(args)
  args, options = args.dup, {}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: rails server [mongrel, thin, etc] [options]"
    opts.on("-p", "--port=port", Integer,
            "Runs Rails on the specified port.", "Default: 3000") { |v| options[:Port] = v }
  ...
```

这个方法为`options`建立一些配置选项，以便给Rails决定如何运行服务提供支持。`initialize`方法执行完毕后。我们将回到`rails/server`目录下，就是`APP_PATH`中的路径。

### `config/application`

当`require APP_PATH`操作执行完毕后。`config/application.rb` 被载入了 (重新调用`bin/rails`中的`APP_PATH`), 在你的应用中，你可以根据需求对该文件进行配置。

### `Rails::Server#start`

`config/application`载入后，`server.start`方法被调用了。这个方法定义如下：

```ruby
def start
  print_boot_information
  trap(:INT) { exit }
  create_tmp_directories
  log_to_stdout if options[:log_stdout]

  super
  ...
end

private

  def print_boot_information
    ...
    puts "=> Run `rails server -h` for more startup options"
    ...
    puts "=> Ctrl-C to shutdown server" unless options[:daemonize]
  end

  def create_tmp_directories
    %w(cache pids sessions sockets).each do |dir_to_make|
      FileUtils.mkdir_p(File.join(Rails.root, 'tmp', dir_to_make))
    end
  end

  def log_to_stdout
    wrapped_app # touch the app so the logger is set up

    console = ActiveSupport::Logger.new($stdout)
    console.formatter = Rails.logger.formatter
    console.level = Rails.logger.level

    Rails.logger.extend(ActiveSupport::Logger.broadcast(console))
  end
```

这是Rails初始化过程中的第一次控制台输出。这个方法创建了一个`INT`中断信号，所以当你在服务端控制台按下`CTRL-C`键后，这将终止Server的运行。我们可以看到，它创建了`tmp/cache`,`tmp/pids`, `tmp/sessions`和`tmp/sockets`等目录。在创建和声明`ActiveSupport::Logger`之前，会调用 `wrapped_app`方法来创建一个Rake 应用程序。

`super`会调用`Rack::Server.start` 方法，该方法定义如下：

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

  # Touch the wrapped app, so that the config.ru is loaded before
  # daemonization (i.e. before chdir, etc).
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

上述Rails 应用有趣的部分在最后一行，`server.run`方法。它再次调用了`wrapped_app`方法(温故而知新)。

```ruby
@wrapped_app ||= build_app app
```

这里的`app`方法定义如下：

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

`options[:config]`中的值默认会从 `config.ru` 中获取，包含如下代码：

```ruby
# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)
run <%= app_const %>
```


`Rack::Builder.parse_file`方法会从`config.ru`中获取内容，包含如下代码：

```ruby
app = new_from_string cfgfile, config

...

def self.new_from_string(builder_script, file="(rackup)")
  eval "Rack::Builder.new {\n" + builder_script + "\n}.to_app",
    TOPLEVEL_BINDING, file, 0
end
```

`Rack::Builder`中的`initialize`方法会创建一个新的`Rack::Builder`实例，这是Rails应用初始化过程中主要内容。接下来`config.ru`中的`require`项`config/environment.rb`会继续执行：

```ruby
require ::File.expand_path('../config/environment', __FILE__)
```

### `config/environment.rb`

这是`config.ru` (`rails server`)和信使(Passenger)都要用到的文件，是两者交流的媒介。之前的操作都是为了创建Rack和Rails。

这个文件是以引用 `config/application.rb`开始的：

```ruby
require File.expand_path('../application', __FILE__)
```

### `config/application.rb`

这个文件需要引用`config/boot.rb`：

```ruby
require File.expand_path('../boot', __FILE__)
```

如果之前在`rails server`中没有引用上述的依赖项，那么它**将不会**和信使(Passenger)发生联系。

现在，有趣的部分要开始了！

加载 Rails
-------------

`config/application.rb`中的下一行是这样的：

```ruby
require 'rails/all'
```

### `railties/lib/rails/all.rb`

本文件中将引用和Rails框架相关的所有内容：

```ruby
require "rails"

%w(
  active_record
  action_controller
  action_view
  action_mailer
  rails/test_unit
  sprockets
).each do |framework|
  begin
    require "#{framework}/railtie"
  rescue LoadError
  end
end
```

这样Rails框架中的所有组件已经准备就绪了。我们将不会深入介绍这些框架的内部细节，不过强烈建议您去探索和发现她们。

现在，我们关心的模块比如Rails engines,I18n 和 Rails configuration 都已经准备就绪了。

### 回到 `config/environment.rb`

`config/application.rb`为`Rails::Application`定义了Rails应用初始化之后所有需要用到的资源。当`config/application.rb` 加载了Rails和命名空间后，我们回到`config/environment.rb`，就是初始化完成的地方。比如我们的应用叫‘blog’，我们将在`rails/application.rb`中调用`Rails.application.initialize!`方法。

### `railties/lib/rails/application.rb`

`initialize!`方法部分代码如下： 

```ruby
def initialize!(group=:default) #:nodoc:
  raise "Application has been already initialized." if @initialized
  run_initializers(group, self)
  @initialized = true
  self
end
```

如你所见，一个应用只能初始化一次。初始化器通过在`railties/lib/rails/initializable.rb`中的`run_initializers`方法运行：

```ruby
def run_initializers(group=:default, *args)
  return if instance_variable_defined?(:@ran)
  initializers.tsort_each do |initializer|
    initializer.run(*args) if initializer.belongs_to?(group)
  end
  @ran = true
end
```

`run_initializers`代码本身是有点投机取巧的，Rails在这里要做的是遍历所有的祖先，查找一个`initializers`方法，之后根据名字进行排序，并依次执行它们。举个例子，`Engine`类将调用自己和祖先中名为`initializers`的方法。

`Rails::Application` 类是在`railties/lib/rails/application.rb`定义的。定义了`bootstrap`, `railtie`和 `finisher`模块的初始化器。`bootstrap`的初始化器在应用被加载以前就预加载了。(类似初始化中的日志记录器)，`finisher`的初始化器则是最后加载的。`railtie`初始化器被定义在`Rails::Application`中，执行是在`bootstrap`和 `finishers`之间。

这些完成后，我们将回到`Rack::Server` 。

### Rack: lib/rack/server.rb

上次我们离开的时候，`app` 方法代码如下：

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

此时此刻，`app`是Rails 应用本身(中间件)。接下来就是Rack调用所有的依赖项了(提供支持的中间件)：

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

必须牢记，`Server#start`最后一行中调用了`build_app`方法(被`wrapped_app`调用)了。接下来我们看看还剩下什么：

```ruby
server.run wrapped_app, options, &blk
```

此时此刻，调用`server.run` 方法将依赖于你所用的Server类型 。比如，如果你的Server是Puma， 那么就会是下面这个结果：

```ruby
...
DEFAULT_OPTIONS = {
  :Host => '0.0.0.0',
  :Port => 8080,
  :Threads => '0:16',
  :Verbose => false
}

def self.run(app, options = {})
  options  = DEFAULT_OPTIONS.merge(options)

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

我们没有深入到服务端配置的细节，因为这是我们探索Rails应用初始化过程之旅的终点了。

高层次的阅读将有助于您提高编写代码的水平，成为Rail开发高手。如果你想要知道更多，那么去读Rails的源代码将是你的不二选择。
