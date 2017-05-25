# Rails 应用模板

应用模板是包含 DSL 的 Ruby 文件，作用是为新建的或现有的 Rails 项目添加 gem 和初始化脚本等。

读完本文后，您将学到：

*   如何使用模板生成和定制 Rails 应用；
*   如何使用 Rails Templates API 编写可复用的应用模板。

-----------------------------------------------------------------------------

<a class="anchor" id="usage"></a>

## 用法

若想使用模板，调用 Rails 生成器时把模板的位置传给 `-m` 选项。模板的位置可以是文件路径，也可以是 URL。

```sh
$ rails new blog -m ~/template.rb
$ rails new blog -m http://example.com/template.rb
```

可以使用 `app:template` 任务在现有的 Rails 应用中使用模板。模板的位置要通过 `LOCATION` 环境变量指定。同样，模板的位置可以是文件路径，也可以是 URL。

```sh
$ bin/rails app:template LOCATION=~/template.rb
$ bin/rails app:template LOCATION=http://example.com/template.rb
```

<a class="anchor" id="template-api"></a>

## Templates API

Rails Templates API 易于理解。下面是一个典型的 Rails 模板：

```ruby
# template.rb
generate(:scaffold, "person name:string")
route "root to: 'people#index'"
rails_command("db:migrate")

after_bundle do
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
```

下面各小节简介这个 API 提供的主要方法。

<a class="anchor" id="gem-args"></a>

### `gem(*args)`

在生成的应用的 `Gemfile` 中添加指定的 `gem` 条目。

例如，如果应用依赖 `bj` 和 `nokogiri`：

```ruby
gem "bj"
gem "nokogiri"
```

请注意，这么做不会为你安装 gem，你要执行 `bundle install` 命令安装。

```sh
$ bundle install
```

<a class="anchor" id="gem-group-names-block"></a>

### `gem_group(*names, &block)`

把指定的 gem 条目放在一个分组中。

例如，如果只想在 `development` 和 `test` 组中加载 `rspec-rails`：

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

<a class="anchor" id="add-source-source-options-block"></a>

### `add_source(source, options={}, &block)`

在生成的应用的 `Gemfile` 中添加指定的源。

例如，如果想安装 `"http://code.whytheluckystiff.net"` 源中的 gem：

```ruby
add_source "http://code.whytheluckystiff.net"
```

如果提供块，块中的 gem 条目放在指定的源分组里：

```ruby
add_source "http://gems.github.com/" do
  gem "rspec-rails"
end
```

<a class="anchor" id="environment-application-data-nil-options-block"></a>

### `environment`/`application(data=nil, options={}, &block)`

在 `config/application.rb` 文件中的 `Application` 类里添加一行代码。

如果指定了 `options[:env]`，代码添加到 `config/environments` 目录中对应的文件中。

```ruby
environment 'config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}', env: 'production'
```

`data` 参数的位置可以使用块。

<a class="anchor" id="vendor-lib-file-initializer-filename-data-nil-block"></a>

### `vendor`/`lib`/`file`/`initializer(filename, data = nil, &block)`

在生成的应用的 `config/initializers` 目录中添加一个初始化脚本。

假设你想使用 `Object#not_nil?` 和 `Object#not_blank?` 方法：

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

类似地，`lib()` 方法在 `lib/ directory` 目录中创建一个文件，`vendor()` 方法在 `vendor/` 目录中创建一个文件。

此外还有个 `file()` 方法，它的参数是一个相对于 `Rails.root` 的路径，用于创建所需的目录和文件：

```ruby
file 'app/components/foo.rb', <<-CODE
  class Foo
  end
CODE
```

上述代码会创建 `app/components` 目录，然后在里面创建 `foo.rb` 文件。

<a class="anchor" id="rakefile-filename-data-nil-block"></a>

### `rakefile(filename, data = nil, &block)`

在 `lib/tasks` 目录中创建一个 Rake 文件，写入指定的任务：

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

上述代码会创建 `lib/tasks/bootstrap.rake` 文件，写入 `boot:strap` rake 任务。

<a class="anchor" id="generate-what-args"></a>

### `generate(what, *args)`

运行指定的 Rails 生成器，并传入指定的参数。

```ruby
generate(:scaffold, "person", "name:string", "address:text", "age:number")
```

<a class="anchor" id="run-command"></a>

### `run(command)`

运行任意命令。作用类似于反引号。假如你想删除 `README.rdoc` 文件：

```ruby
run "rm README.rdoc"
```

<a class="anchor" id="rails-command-command-options"></a>

### `rails_command(command, options = {})`

在 Rails 应用中运行指定的任务。假如你想迁移数据库：

```ruby
rails_command "db:migrate"
```

还可以在不同的 Rails 环境中运行任务：

```ruby
rails_command "db:migrate", env: 'production'
```

还能以超级用户的身份运行任务：

```ruby
rails_command "log:clear", sudo: true
```

<a class="anchor" id="route-routing-code"></a>

### `route(routing_code)`

在 `config/routes.rb` 文件中添加一条路由规则。在前面几节中，我们使用脚手架生成了 Person 资源，还删除了 `README.rdoc` 文件。现在，把 `PeopleController#index` 设为应用的首页：

```ruby
route "root to: 'person#index'"
```

<a class="anchor" id="inside-dir"></a>

### `inside(dir)`

在指定的目录中执行命令。假如你有一份最新版 Rails，想通过符号链接指向 `rails` 命令，可以这么做：

```ruby
inside('vendor') do
  run "ln -s ~/commit-rails/rails rails"
end
```

<a class="anchor" id="ask-question"></a>

### `ask(question)`

`ask()` 方法获取用户的反馈，供模板使用。假如你想让用户为新添加的库起个响亮的名称：

```ruby
lib_name = ask("What do you want to call the shiny library ?")
lib_name << ".rb" unless lib_name.index(".rb")

lib lib_name, <<-CODE
  class Shiny
  end
CODE
```

<a class="anchor" id="yes-questionmark-question-or-no-questionmark-question"></a>

### `yes?(question)` 或 `no?(question)`

这两个方法用于询问用户问题，然后根据用户的回答决定流程。假如你想在用户同意时才冰封 Rails：

```ruby
rails_command("rails:freeze:gems") if yes?("Freeze rails gems?")
# no?(question) 的作用正好相反
```

<a class="anchor" id="git-command"></a>

### `git(:command)`

在 Rails 模板中可以运行任意 Git 命令：

```ruby
git :init
git add: "."
git commit: "-a -m 'Initial commit'"
```

<a class="anchor" id="after-bundle-block"></a>

### `after_bundle(&block)`

注册一个回调，在安装好 gem 并生成 binstubs 之后执行。可以用来把生成的文件纳入版本控制：

```ruby
after_bundle do
  git :init
  git add: '.'
  git commit: "-a -m 'Initial commit'"
end
```

即便传入 `--skip-bundle` 和（或） `--skip-spring` 选项，也会执行这个回调。

<a class="anchor" id="advanced-usage"></a>

## 高级用法

应用模板在 `Rails::Generators::AppGenerator` 实例的上下文中运行，用到了 [Thor 提供的 `apply` 方法](https://github.com/erikhuda/thor/blob/master/lib/thor/actions.rb#L207)。因此，你可以扩展或修改这个实例，满足自己的需求。

例如，覆盖指定模板位置的 `source_paths` 方法。现在，`copy_file` 等方法能接受相对于模板位置的相对路径。

```ruby
def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end
```
