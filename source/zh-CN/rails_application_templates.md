Rails应用模版
===========================

应用模版是一个包括使用DSL添加gems/initializers等操作的普通Ruby文件.可以很方便的在你的应用中创建。

读完本章节，你将会学到：

* 如何使用模版生成/个性化一个应用。
* 如何使用Rails的模版API编写可复用的应用模版。


--------------------------------------------------------------------------------

模版应用简介
-----

为了使用一个模版，你需要为Rails应用生成器在生成新应用时提供一个'-m'选项来配置模版的路径。该路径可以是本地文件路径也可以是URL地址。

```bash
$ rails new blog -m ~/template.rb
$ rails new blog -m http://example.com/template.rb
```

你可以使用rake的任务命令`rails:template`为Rails应用配置模版。模版的文件路径需要通过名为'LOCATION'的环境变量设定。再次强调，这个路径可以是本地文件路径也可以是URL地址：

```bash
$ bin/rake rails:template LOCATION=~/template.rb
$ bin/rake rails:template LOCATION=http://example.com/template.rb
```

模版API
------------

Rails模版API很容易理解，下面我们来看一个典型的模版例子：

```ruby
# template.rb
generate(:scaffold, "person name:string")
route "root to: 'people#index'"
rake("db:migrate")

git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }
```

下面的章节将详细介绍模版API的主要方法：

### gem(*args)

向一个Rails应用的`Gemfile`配置文件添加一个'gem'实体。
举个例子，如果你的应用的依赖项包含`bj` 和 `nokogiri`等gem ： 

```ruby
gem "bj"
gem "nokogiri"
```

需要注意的是上述代码不会安装gem文件到你的应用里，你需要运行`bundle install` 命令来安装它们。

```bash
bundle install
```

### gem_group(*names, &block)

将gem实体嵌套在一个组里。

比如，如果你只希望在`development`和`test`组里面使用`rspec-rails`，可以这么做 ： 


```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### add_source(source, options = {})

为Rails应用的`Gemfile`文件指定数据源。

举个例子。如果你需要从`"http://code.whytheluckystiff.net"`下载一个gem： 

```ruby
add_source "http://code.whytheluckystiff.net"
```

### environment/application(data=nil, options={}, &block)

为`Application`在`config/application.rb`中添加一行内容。

如果声明了`options[:env]`参数，那么这一行会在`config/environments`添加。

```ruby
environment 'config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}', env: 'production'
```

可以使用一个 'block'标志代替`data`参数。

### vendor/lib/file/initializer(filename, data = nil, &block)

为一个应用的`config/initializers`目录添加初始化器。

假如你喜欢使用`Object#not_nil?` 和 `Object#not_blank?`：

```ruby
initializer 'bloatlol.rb', <<-CODE
  class Object
    def not_nil?
      !nil?
    end

    def not_blank?
      !blank?
    end
  end
CODE
```

一般来说，`lib()`方法会在 `lib/` 目录下创建一个文件，而`vendor()`方法会在`vendor/`目录下创建一个文件。

甚至可以用`Rails.root`的`file()`方法创建所有Rails应用必须的文件和目录。

```ruby
file 'app/components/foo.rb', <<-CODE
  class Foo
  end
CODE
```

上述操作会在`app/components`目录下创建一个 `foo.rb` 文件。

### rakefile(filename, data = nil, &block)

在 `lib/tasks`目录下创建一个新的rake文件执行任务： 

```ruby
rakefile("bootstrap.rake") do
  <<-TASK
    namespace :boot do
      task :strap do
        puts "i like boots!"
      end
    end
  TASK
end
```

上述代码将在`lib/tasks/bootstrap.rake`中创建一个`boot:strap`任务。 

### generate(what, *args)

通过给定参数执行生成器操作：

```ruby
generate(:scaffold, "person", "name:string", "address:text", "age:number")
```

### run(command)

执行命令行命令，和你在命令行终端敲命令效果一样。比如你想删除`README.rdoc`文件：

```ruby
run "rm README.rdoc"
```

### rake(command, options = {})

执行Rails应用的rake任务，比如你想迁移数据库：

```ruby
rake "db:migrate"
```

你也可以在不同的Rails应用环境中执行rake任务：

```ruby
rake "db:migrate", env: 'production'
```

### route(routing_code)

在`config/routes.rb`文件中添加一个路径实体。比如我们之前为某个人生成了一些简单的页面并且把 `README.rdoc`删除了。现在我们可以把应用的`PeopleController#index`设置为默认页面：

```ruby
route "root to: 'person#index'"
```

### inside(dir)

允许你在指定目录执行命令。举个例子，你如果希望将一个外部应用添加到你的新应用中，可以这么做：

```ruby
inside('vendor') do
  run "ln -s ~/commit-rails/rails rails"
end
```

### ask(question)

`ask()`方法为你提供了一个机会去获取用户反馈。比如你希望用户在你的新应用'shiny library'提交用户反馈意见： 

```ruby
lib_name = ask("What do you want to call the shiny library ?")
lib_name << ".rb" unless lib_name.index(".rb")

lib lib_name, <<-CODE
  class Shiny
  end
CODE
```

### yes?(question) or no?(question)

这些方法是根据用户的选择之后做一些操作的。比如你的用户希望停止Rails应用，你可以这么做：

```ruby
rake("rails:freeze:gems") if yes?("Freeze rails gems?")
# no?(question) acts just the opposite.
```

### git(:command)

Rails模版允许你运行任何git命令：

```ruby
git :init
git add: "."
git commit: "-a -m 'Initial commit'"
```

高级应用
--------------

应用模版是在`Rails::Generators::AppGenerator`实例的上下文环境中执行的，它使用`apply` 动作来执行操作[Thor](https://github.com/erikhuda/thor/blob/master/lib/thor/actions.rb#L207)。这意味着你可以根据需要扩展它的功能。

比如重载`source_paths`方法实现把本地路径添加到你的模版应用中。那么类似`copy_file`方法会在你的模版路径中识别相对路径参数。

```ruby
def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end
```
