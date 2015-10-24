Rails 应用的初始化过程
================================

本章节介绍了 Rails 4 应用启动的内部流程。很适合有一定经验的Rails 开发者阅读。

通过学习本章节，您会学到如下知识：

* 如何使用 `rails server`.
* Rails应用初始化的时间序列.
* Rails应用启动过程都用到哪些文件.
* 接口 Rails::Server 的定义和使用.

--------------------------------------------------------------------------------
 
本章节通过介绍一个基于Ruby on Rails框架默认配置的 Rails 4 应用程序启动过程中的方法调用，详细介绍了每个调用的细节。通过本章节，我们将关注当你执行`rails server`命令启动你的应用时， 背后究竟发生了什么。


提示：本章节中的路径如果没有特别说明都是指Rails应用程序下的路径。


提示：如果你想浏览Rails的源代码[sourcecode](https://github.com/rails/rails)，强烈建议您使用快捷键 `t`快速查找Github中的文件。

启动!
-------

我们们现在准备启动和初始化一个Rails 应用。 一个Rails 应用 经常是以运行命令 `rails console` or `rails server` 开始的。

### `railties/bin/rails`

Rails 中的 “rails server” 是一个你rails应用程序所在文件中的一个 ruby 的可执行程序，该程序包含如下操作：

```ruby
version = ">= 0"
load Gem.bin_path('railties', 'rails', version)
```

如何你在Rails 控制台中使用上述命令 ，你将会看到载入`railties/exe/rails`这个路径。作为 `railties/exe/rails.rb`的一部分， 包含如下代码：

```ruby
require "rails/cli"
```

文件 `railties/lib/rails/cli` 会调用`Rails::AppRailsLoader.exec_app_rails`模块.

### `railties/lib/rails/app_rails_loader.rb`

 `exec_app_rails`模块的主要功能是去执行你的Rails应用中`bin/rails`文件夹下的指令。如果当前文件夹下没有`bin/rails`文件，它会到父级目录去搜索，直到找到为止（windows下应该会去搜索环境变量中的路径），在Rails应用程序目录的任意位置下(命令行模式下)，这将会触发一个`rails`的指令。

因为`rails server`命令和下面的操作是等价的：

```bash
$ exec ruby bin/rails server
```

### `bin/rails`

文件`railties/bin/rails`包含的代码如下：

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

在一个标准的Rails应用中，包含一个`Gemfile`文件配置该Rails应用的所以依赖项。`config/boot.rb`文件会设置`ENV['BUNDLE_GEMFILE']`来查找Gemfile的路径。如果Gemfile存在，那么`bundler/setup`操作会被执行，Bundler执行该操作是为了配置你的Gemfile相关的依赖项的加载路径。

一个标准的Rails应用会依赖若干gem包，特别是下面这些：

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

一旦`config/boot.rb`执行完毕，接下来要执行的是`rails/commands`操作，这个操作会帮助解析别名。在本应用中，`ARGV` 数组包含 `server`项会被匹配：

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

提示： 如你所见，一个空的ARGV数组将会让系统显示相关的帮助项 。

如果我们使用`s`缩写代替 `server`，Rails系统会使用`aliases`定义来查找匹配的命令。

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

动作分发(Action Dispatch)是Rails框架中的路径组件。它增强了路径，会话等中间件的函数化功能。

### `rails/commands/server.rb`

这个文件中定义的`Rails::Server` 类是继承自 `Rack::Server`类的。当`Rails::Server.new` 被调用时，会在 `rails/commands/server.rb`中调用一个`initialize`方法：

```ruby
def initialize(*)
  super
  set_environment
end
```

首先，`super`会调用父类`Rack::Server`中的`initialize`方法。

### Rack: `lib/rack/server.rb`

`Rack::Server`会为所以基于Rack的应用提供一般的服务接口，现在它已经是Rails框架的一部分了。

`Rack::Server`中的`initialize` 方法会简单的设置一对变量：

```ruby
def initialize(options = nil)
  @options = options
  @app = options[:app] if options && options[:app]
end
```

在这种情况下，`options` 的值是 `nil`，所以在这个方法中相当于什么都没做。

当`Rack::Server`中的`super`方法执行完毕后。我们会回到`rails/commands/server.rb`，此时此刻，`Rails::Server`对象根据上下文调用 `set_environment` 方法，貌似这个方法看上去也没干什么： 

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

接着`parse_options`被定义成这样：

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

使用　`default_options` 配置如下：

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

There is no `REQUEST_METHOD` key in `ENV` so we can skip over that line. The next line merges in the options from `opt_parser` which is defined plainly in `Rack::Server`:

```ruby
def opt_parser
  Options.new
end
```

The class **is** defined in `Rack::Server`, but is overwritten in `Rails::Server` to take different arguments. Its `parse!` method begins like this:

```ruby
def parse!(args)
  args, options = args.dup, {}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: rails server [mongrel, thin, etc] [options]"
    opts.on("-p", "--port=port", Integer,
            "Runs Rails on the specified port.", "Default: 3000") { |v| options[:Port] = v }
  ...
```

This method will set up keys for the `options` which Rails will then be
able to use to determine how its server should run. After `initialize`
has finished, we jump back into `rails/server` where `APP_PATH` (which was
set earlier) is required.

### `config/application`

When `require APP_PATH` is executed, `config/application.rb` is loaded (recall
that `APP_PATH` is defined in `bin/rails`). This file exists in your application
and it's free for you to change based on your needs.

### `Rails::Server#start`

After `config/application` is loaded, `server.start` is called. This method is
defined like this:

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

This is where the first output of the Rails initialization happens. This
method creates a trap for `INT` signals, so if you `CTRL-C` the server,
it will exit the process. As we can see from the code here, it will
create the `tmp/cache`, `tmp/pids`, `tmp/sessions` and `tmp/sockets`
directories. It then calls `wrapped_app` which is responsible for
creating the Rack app, before creating and assigning an
instance of `ActiveSupport::Logger`.

The `super` method will call `Rack::Server.start` which begins its definition like this:

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

The interesting part for a Rails app is the last line, `server.run`. Here we encounter the `wrapped_app` method again, which this time
we're going to explore more (even though it was executed before, and
thus memoized by now).

```ruby
@wrapped_app ||= build_app app
```

The `app` method here is defined like so:

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

The `options[:config]` value defaults to `config.ru` which contains this:

```ruby
# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)
run <%= app_const %>
```


The `Rack::Builder.parse_file` method here takes the content from this `config.ru` file and parses it using this code:

```ruby
app = new_from_string cfgfile, config

...

def self.new_from_string(builder_script, file="(rackup)")
  eval "Rack::Builder.new {\n" + builder_script + "\n}.to_app",
    TOPLEVEL_BINDING, file, 0
end
```

The `initialize` method of `Rack::Builder` will take the block here and execute it within an instance of `Rack::Builder`. This is where the majority of the initialization process of Rails happens. The `require` line for `config/environment.rb` in `config.ru` is the first to run:

```ruby
require ::File.expand_path('../config/environment', __FILE__)
```

### `config/environment.rb`

This file is the common file required by `config.ru` (`rails server`) and Passenger. This is where these two ways to run the server meet; everything before this point has been Rack and Rails setup.

This file begins with requiring `config/application.rb`:

```ruby
require File.expand_path('../application', __FILE__)
```

### `config/application.rb`

This file requires `config/boot.rb`:

```ruby
require File.expand_path('../boot', __FILE__)
```

But only if it hasn't been required before, which would be the case in `rails server`
but **wouldn't** be the case with Passenger.

Then the fun begins!

Loading Rails
-------------

The next line in `config/application.rb` is:

```ruby
require 'rails/all'
```

### `railties/lib/rails/all.rb`

This file is responsible for requiring all the individual frameworks of Rails:

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

This is where all the Rails frameworks are loaded and thus made
available to the application. We won't go into detail of what happens
inside each of those frameworks, but you're encouraged to try and
explore them on your own.

For now, just keep in mind that common functionality like Rails engines,
I18n and Rails configuration are all being defined here.

### Back to `config/environment.rb`

The rest of `config/application.rb` defines the configuration for the
`Rails::Application` which will be used once the application is fully
initialized. When `config/application.rb` has finished loading Rails and defined
the application namespace, we go back to `config/environment.rb`,
where the application is initialized. For example, if the application was called
`Blog`, here we would find `Rails.application.initialize!`, which is
defined in `rails/application.rb`.

### `railties/lib/rails/application.rb`

The `initialize!` method looks like this:

```ruby
def initialize!(group=:default) #:nodoc:
  raise "Application has been already initialized." if @initialized
  run_initializers(group, self)
  @initialized = true
  self
end
```

As you can see, you can only initialize an app once. The initializers are run through
the `run_initializers` method which is defined in `railties/lib/rails/initializable.rb`:

```ruby
def run_initializers(group=:default, *args)
  return if instance_variable_defined?(:@ran)
  initializers.tsort_each do |initializer|
    initializer.run(*args) if initializer.belongs_to?(group)
  end
  @ran = true
end
```

The `run_initializers` code itself is tricky. What Rails is doing here is
traversing all the class ancestors looking for those that respond to an
`initializers` method. It then sorts the ancestors by name, and runs them.
For example, the `Engine` class will make all the engines available by
providing an `initializers` method on them.

The `Rails::Application` class, as defined in `railties/lib/rails/application.rb`
defines `bootstrap`, `railtie`, and `finisher` initializers. The `bootstrap` initializers
prepare the application (like initializing the logger) while the `finisher`
initializers (like building the middleware stack) are run last. The `railtie`
initializers are the initializers which have been defined on the `Rails::Application`
itself and are run between the `bootstrap` and `finishers`.

After this is done we go back to `Rack::Server`.

### Rack: lib/rack/server.rb

Last time we left when the `app` method was being defined:

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

At this point `app` is the Rails app itself (a middleware), and what
happens next is Rack will call all the provided middlewares:

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

Remember, `build_app` was called (by `wrapped_app`) in the last line of `Server#start`.
Here's how it looked like when we left:

```ruby
server.run wrapped_app, options, &blk
```

At this point, the implementation of `server.run` will depend on the
server you're using. For example, if you were using Puma, here's what
the `run` method would look like:

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

We won't dig into the server configuration itself, but this is
the last piece of our journey in the Rails initialization process.

This high level overview will help you understand when your code is
executed and how, and overall become a better Rails developer. If you
still want to know more, the Rails source code itself is probably the
best place to go next.
