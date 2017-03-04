创建及定制 Rails 生成器和模板
=============================

如果你打算改进自己的工作流程，Rails 生成器是必备工具。本文教你创建及定制生成器的方式。

读完本文后，您将学到：

- 如何查看应用中有哪些生成器可用；

- 如何使用模板创建生成器；

- 在调用生成器之前，Rails 如何搜索生成器；

- Rails 内部如何使用模板生成 Rails 代码；

- 如何通过创建新生成器定制脚手架；

- 如何通过修改生成器模板定制脚手架；

- 如何使用后备机制防范覆盖大量生成器；

- 如何创建应用模板。

第一次接触
----------

使用 `rails` 命令创建应用时，使用的其实就是一个 Rails 生成器。创建应用之后，可以使用 `rails generator` 命令列出全部可用的生成器：

```sh
$ rails new myapp
$ cd myapp
$ bin/rails generate
```

你会看到 Rails 自带的全部生成器。如果想查看生成器的详细描述，比如说 `helper` 生成器，可以这么做：

```sh
$ bin/rails generate helper --help
```

创建首个生成器
--------------

自 Rails 3.0 起，生成器使用 [Thor](https://github.com/erikhuda/thor) 构建。Thor 提供了强大的解析选项和处理文件的丰富 API。举个例子。我们来构建一个生成器，在 `config/initializers` 目录中创建一个名为 `initializer.rb` 的初始化脚本。

第一步是创建 `lib/generators/initializer_generator.rb` 文件，写入下述内容：

```ruby
class InitializerGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# 这里是初始化文件的内容"
  end
end
```

NOTE: `create_file` 是 `Thor::Actions` 提供的一个方法。`create_file` 即其他 Thor 方法的文档参见 [Thor 的文档](http://rdoc.info/github/erikhuda/thor/master/Thor/Actions.html)。

这个生成器相当简单：继承自 `Rails::Generators::Base`，定义了一个方法。调用生成器时，生成器中的公开方法按照定义的顺序依次执行。最后，我们调用 `create_file` 方法在指定的位置创建一个文件，写入指定的内容。如果你熟悉 Rails Application Templates API，对这个生成器 API 就不会感到陌生。

若想调用这个生成器，只需这么做：

```sh
$ bin/rails generate initializer
```

在继续之前，先看一下这个生成器的描述：

```sh
$ bin/rails generate initializer --help
```

如果把生成器放在命名空间里（如 `ActiveRecord::Generators::ModelGenerator`），Rails 通常能生成好的描述，但这里没有。这一问题有两个解决方法。第一个是，在生成器中调用 `desc`：

```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "This generator creates an initializer file at config/initializers"
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

现在，调用生成器时指定 `--help` 选项便能看到刚添加的描述。添加描述的第二个方法是，在生成器所在的目录中创建一个名为 `USAGE` 的文件。下一节将这么做。

使用生成器创建生成器
--------------------

生成器本身也有一个生成器：

```sh
$ bin/rails generate generator initializer
      create  lib/generators/initializer
      create  lib/generators/initializer/initializer_generator.rb
      create  lib/generators/initializer/USAGE
      create  lib/generators/initializer/templates
```

下述代码是这个生成器生成的：

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)
end
```

首先注意，我们继承的是 `Rails::Generators::NamedBase`，而不是 `Rails::Generators::Base`。这表明，我们的生成器至少需要一个参数，即初始化脚本的名称，在代码中通过 `name` 变量获取。

查看这个生成器的描述可以证实这一点（别忘了删除旧的生成器文件）：

```sh
$ bin/rails generate initializer --help
Usage:
  rails generate initializer NAME [options]
```

还能看到，这个生成器有个名为 `source_root` 的类方法。这个方法指向生成器模板（如果有的话）所在的位置，默认是生成的 `lib/generators/initializer/templates` 目录。

为了弄清生成器模板的作用，下面创建 `lib/generators/initializer/templates/initializer.rb` 文件，写入下述内容：

```ruby
# Add initialization content here
```

然后修改生成器，调用时复制这个模板：

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
  end
end
```

下面执行这个生成器：

```sh
$ bin/rails generate initializer core_extensions
```

可以看到，这个命令生成了 `config/initializers/core_extensions.rb` 文件，里面的内容与模板中一样。这表明，`copy_file` 方法的作用是把源根目录中的文件复制到指定的目标路径。`file_name` 方法是继承自 `Rails::Generators::NamedBase` 之后自动创建的。

生成器中可用的方法在本章[最后一节](#生成器方法)说明。

查找生成器
----------

执行 `rails generate initializer core_extensions` 命令时，Rails 按照下述顺序引入文件，直到找到所需的生成器为止：

    rails/generators/initializer/initializer_generator.rb
    generators/initializer/initializer_generator.rb
    rails/generators/initializer_generator.rb
    generators/initializer_generator.rb

如果最后找不到，显示一个错误消息。

TIP: 上述示例把文件放在应用的 `lib` 目录中，因为这个目录在 `$LOAD_PATH` 中。

定制工作流程
------------

Rails 自带的生成器十分灵活，可以定制脚手架。生成器在 `config/application.rb` 文件中配置，下面是一些默认值：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: true
end
```

在定制工作流程之前，先看看脚手架是什么：

```sh
$ bin/rails generate scaffold User name:string
      invoke  active_record
      create    db/migrate/20130924151154_create_users.rb
      create    app/models/user.rb
      invoke    test_unit
      create      test/models/user_test.rb
      create      test/fixtures/users.yml
      invoke  resource_route
       route    resources :users
      invoke  scaffold_controller
      create    app/controllers/users_controller.rb
      invoke    erb
      create      app/views/users
      create      app/views/users/index.html.erb
      create      app/views/users/edit.html.erb
      create      app/views/users/show.html.erb
      create      app/views/users/new.html.erb
      create      app/views/users/_form.html.erb
      invoke    test_unit
      create      test/controllers/users_controller_test.rb
      invoke    helper
      create      app/helpers/users_helper.rb
      invoke    jbuilder
      create      app/views/users/index.json.jbuilder
      create      app/views/users/show.json.jbuilder
      invoke  assets
      invoke    coffee
      create      app/assets/javascripts/users.coffee
      invoke    scss
      create      app/assets/stylesheets/users.scss
      invoke  scss
      create    app/assets/stylesheets/scaffolds.scss
```

通过上述输出不难看出 Rails 3.0 及以上版本中生成器的工作方式。脚手架生成器其实什么也不生成，只是调用其他生成器。因此，我们可以添加、替换和删除任何生成器。例如，脚手架生成器调用了 scaffold\_controller 生成器，而它调用了 erb、test\_unit 和 helper 生成器。因为各个生成器的职责单一，所以可以轻易复用，从而避免代码重复。

我们定制工作流程的第一步是，不让脚手架生成样式表、JavaScript 和测试固件文件。为此，我们要像下面这样修改配置：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
end
```

如果再使用脚手架生成器生成一个资源，你会看到，它不再创建样式表、JavaScript 和固件文件了。如果想进一步定制，例如使用 DataMapper 和 RSpec 替换 Active Record 和 TestUnit，只需添加相应的 gem，然后配置生成器。

下面举个例子。我们将创建一个辅助方法生成器，添加一些实例变量读值方法。首先，在 rails 命名空间（Rails 在这里搜索作为钩子的生成器）中创建一个生成器：

```sh
$ bin/rails generate generator rails/my_helper
      create  lib/generators/rails/my_helper
      create  lib/generators/rails/my_helper/my_helper_generator.rb
      create  lib/generators/rails/my_helper/USAGE
      create  lib/generators/rails/my_helper/templates
```

然后，把 `templates` 目录和 `source_root` 类方法删除，因为用不到。然后添加下述方法，此时生成器如下所示：

```ruby
# lib/generators/rails/my_helper/my_helper_generator.rb
class Rails::MyHelperGenerator < Rails::Generators::NamedBase
  def create_helper_file
    create_file "app/helpers/#{file_name}_helper.rb", <<-FILE
module #{class_name}Helper
  attr_reader :#{plural_name}, :#{plural_name.singularize}
end
    FILE
  end
end
```

下面为 products 创建一个辅助方法，试试这个新生成器：

```sh
$ bin/rails generate my_helper products
      create  app/helpers/products_helper.rb
```

上述命令会在 `app/helpers` 目录中生成下述辅助方法文件：

```ruby
module ProductsHelper
  attr_reader :products, :product
end
```

这正是我们预期的。接下来再次编辑 `config/application.rb`，告诉脚手架使用这个新辅助方法生成器：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
  g.helper          :my_helper
end
```

然后调用这个生成器，实测一下：

```sh
$ bin/rails generate scaffold Article body:text
      [...]
      invoke    my_helper
      create      app/helpers/articles_helper.rb
```

从输出中可以看出，Rails 调用了这个新辅助方法生成器，而不是默认的那个。不过，少了点什么：没有生成测试。我们将复用旧的辅助方法生成器测试。

自 Rails 3.0 起，测试很容易，因为有了钩子。辅助方法无需限定于特定的测试框架，只需提供一个钩子，让测试框架实现钩子即可。

为此，我们可以按照下述方式修改生成器：

```ruby
# lib/generators/rails/my_helper/my_helper_generator.rb
class Rails::MyHelperGenerator < Rails::Generators::NamedBase
  def create_helper_file
    create_file "app/helpers/#{file_name}_helper.rb", <<-FILE
module #{class_name}Helper
  attr_reader :#{plural_name}, :#{plural_name.singularize}
end
    FILE
  end

  hook_for :test_framework
end
```

现在，如果再调用这个辅助方法生成器，而且配置的测试框架是 TestUnit，它会调用 `Rails::TestUnitGenerator` 和 `TestUnit::MyHelperGenerator`。这两个生成器都没定义，我们可以告诉生成器去调用 `TestUnit::Generators::HelperGenerator`。这个生成器是 Rails 自带的。为此，我们只需添加：

```ruby
# 搜索 :helper，而不是 :my_helper
hook_for :test_framework, as: :helper
```

现在，你可以使用脚手架再生成一个资源，你会发现它生成了测试。

通过修改生成器模板定制工作流程
------------------------------

前面我们只想在生成的辅助方法中添加一行代码，而不增加额外的功能。为此有种更为简单的方式：替换现有生成器的模板。这里要替换的是 `Rails::Generators::HelperGenerator` 的模板。

在 Rails 3.0 及以上版本中，生成器搜索模板时不仅查看源根目录，还会在其他路径中搜索模板。其中一个是 `lib/templates`。我们要定制的是 `Rails::Generators::HelperGenerator`，因此可以在 `lib/templates/rails/helper` 目录中放一个模板副本，名为 `helper.rb`。创建这个文件，写入下述内容：

```ruby
module <%= class_name %>Helper
  attr_reader :<%= plural_name %>, :<%= plural_name.singularize %>
end
```

然后撤销之前对 `config/application.rb` 文件的修改：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
end
```

再生成一个资源，你将看到，得到的结果完全一样。如果你想定制脚手架模板和（或）布局，只需在 `lib/templates/erb/scaffold` 目录中创建 `edit.html.erb`、`index.html.erb`，等等。

Rails 的脚手架模板经常使用 ERB 标签，这些标签要转义，这样生成的才是有效的 ERB 代码。

例如，在模板中要像下面这样转义 ERB 标签（注意多了个 %）：

```erb
<%%= stylesheet_include_tag :application %>
```

生成的内容如下：

```erb
<%= stylesheet_include_tag :application %>
```

为生成器添加后备机制
--------------------

生成器最后一个相当有用的功能是插件生成器的后备机制。比如说我们想在 TestUnit 的基础上添加类似 [shoulda](https://github.com/thoughtbot/shoulda) 的功能。因为 TestUnit 已经实现了 Rails 所需的全部生成器，而 shoulda 只是覆盖其中部分，所以 shoulda 没必要重新实现某些生成器。相反，shoulda 可以告诉 Rails，在 `Shoulda` 命名空间中找不到某个生成器时，使用 `TestUnit` 中的生成器。

我们可以再次修改 `config/application.rb` 文件，模拟这种行为：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :shoulda, fixture: false
  g.stylesheets     false
  g.javascripts     false

  # 添加后备机制
  g.fallbacks[:shoulda] = :test_unit
end
```

现在，使用脚手架生成 Comment 资源时，你会看到调用了 shoulda 生成器，而它调用的其实是 TestUnit 生成器：

```sh
$ bin/rails generate scaffold Comment body:text
      invoke  active_record
      create    db/migrate/20130924143118_create_comments.rb
      create    app/models/comment.rb
      invoke    shoulda
      create      test/models/comment_test.rb
      create      test/fixtures/comments.yml
      invoke  resource_route
       route    resources :comments
      invoke  scaffold_controller
      create    app/controllers/comments_controller.rb
      invoke    erb
      create      app/views/comments
      create      app/views/comments/index.html.erb
      create      app/views/comments/edit.html.erb
      create      app/views/comments/show.html.erb
      create      app/views/comments/new.html.erb
      create      app/views/comments/_form.html.erb
      invoke    shoulda
      create      test/controllers/comments_controller_test.rb
      invoke    my_helper
      create      app/helpers/comments_helper.rb
      invoke    jbuilder
      create      app/views/comments/index.json.jbuilder
      create      app/views/comments/show.json.jbuilder
      invoke  assets
      invoke    coffee
      create      app/assets/javascripts/comments.coffee
      invoke    scss
```

后备机制能让生成器专注于实现单一职责，尽量复用代码，减少重复代码量。

应用模板
--------

至此，我们知道生成器可以在应用内部使用，但是你知道吗，生成器也可用于生成应用？这种生成器叫“模板”（template）。本节简介 Templates API，详情参阅[Rails 应用模板](rails_application_templates.html)。

```ruby
gem "rspec-rails", group: "test"
gem "cucumber-rails", group: "test"

if yes?("Would you like to install Devise?")
  gem "devise"
  generate "devise:install"
  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate "devise", model_name
end
```

在上述模板中，我们指定应用要使用 `rspec-rails` 和 `cucumber-rails` 两个 gem，因此把它们添加到 `Gemfile` 的 `test` 组。然后，我们询问用户是否想安装 Devise。如果用户回答“y”或“yes”，这个模板会将其添加到 `Gemfile` 中，而且不放在任何分组中，然后运行 `devise:install` 生成器。然后，这个模板获取用户的输入，运行 `devise` 生成器，并传入用户对前一个问题的回答。

假如这个模板保存在名为 `template.rb` 的文件中。我们可以使用它修改 `rails new` 命令的输出，方法是把文件名传给 `-m` 选项：

```sh
$ rails new thud -m template.rb
```

上述命令会生成 Thud 应用，然后把模板应用到生成的输出上。

模板不一定非得存储在本地系统中，`-m` 选项也支持在线模板：

```sh
$ rails new thud -m https://gist.github.com/radar/722911/raw/
```

本章最后一节虽然不说明如何生成大多数已知的优秀模板，但是会详细说明可用的方法，供你自己开发模板。那些方法也可以在生成器中使用。

生成器方法
----------

下面是可供 Rails 生成器和模板使用的方法。

NOTE: 本文不涵盖 Thor 提供的方法。如果想了解，参阅 [Thor 的文档](http://rdoc.info/github/erikhuda/thor/master/Thor/Actions.html)。

### `gem`

指定应用的一个 gem 依赖。

```ruby
gem "rspec", group: "test", version: "2.1.0"
gem "devise", "1.1.5"
```

可用的选项：

- `:group`：把 gem 添加到 `Gemfile` 中的哪个分组里。

- `:version`：要使用的 gem 版本号，字符串。也可以在 `gem` 方法的第二个参数中指定。

- `:git`：gem 的 Git 仓库的 URL。

传给这个方法的其他选项放在行尾：

```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

上述代码在 `Gemfile` 中写入下面这行代码：

```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

### `gem_group`

把 gem 放在一个分组里：

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### `add_source`

在 `Gemfile` 中添加指定的源：

```ruby
add_source "http://gems.github.com"
```

这个方法也接受块：

```ruby
add_source "http://gems.github.com" do
  gem "rspec-rails"
end
```

### `inject_into_file`

在文件中的指定位置插入一段代码：

```ruby
inject_into_file 'name_of_file.rb', after: "#The code goes below this line. Don't forget the Line break at the end\n" do <<-'RUBY'
  puts "Hello World"
RUBY
end
```

### `gsub_file`

替换文件中的文本：

```ruby
gsub_file 'name_of_file.rb', 'method.to_be_replaced', 'method.the_replacing_code'
```

使用正则表达式替换的效果更精准。可以使用类似的方式调用 `append_file` 和 `prepend_file`，分别在文件的末尾和开头添加代码。

### `application`

在 `config/application.rb` 文件中应用类定义后面直接添加内容：

```ruby
application "config.asset_host = 'http://example.com'"
```

这个方法也接受块：

```ruby
application do
  "config.asset_host = 'http://example.com'"
end
```

可用的选项：

- `:env`：指定配置选项所属的环境。如果想在块中使用这个选项，建议使用下述句法：

    ``` ruby
    application(nil, env: "development") do
      "config.asset_host = 'http://localhost:3000'"
    end
    ```

### `git`

运行指定的 Git 命令：

```ruby
git :init
git add: "."
git commit: "-m First commit!"
git add: "onefile.rb", rm: "badfile.cxx"
```

这里的散列是传给指定 Git 命令的参数或选项。如最后一行所示，一次可以指定多个 Git 命令，但是命令的运行顺序不一定与指定的顺序一样。

### `vendor`

在 `vendor` 目录中放一个文件，内有指定的代码：

```ruby
vendor "sekrit.rb", '#top secret stuff'
```

这个方法也接受块：

```ruby
vendor "seeds.rb" do
  "puts 'in your app, seeding your database'"
end
```

### `lib`

在 `lib` 目录中放一个文件，内有指定的代码：

```ruby
lib "special.rb", "p Rails.root"
```

这个方法也接受块

```ruby
lib "super_special.rb" do
  puts "Super special!"
end
```

### `rakefile`

在应用的 `lib/tasks` 目录中创建一个 Rake 文件：

```ruby
rakefile "test.rake", "hello there"
```

这个方法也接受块：

```ruby
rakefile "test.rake" do
  %Q{
    task rock: :environment do
      puts "Rockin'"
    end
  }
end
```

### `initializer`

在应用的 `config/initializers` 目录中创建一个初始化脚本：

```ruby
initializer "begin.rb", "puts 'this is the beginning'"
```

这个方法也接受块，期待返回一个字符串：

```ruby
initializer "begin.rb" do
  "puts 'this is the beginning'"
end
```

### `generate`

运行指定的生成器，第一个参数是生成器的名称，后续参数直接传给生成器：

```ruby
generate "scaffold", "forums title:string description:text"
```

### `rake`

运行指定的 Rake 任务：

```ruby
rake "db:migrate"
```

可用的选项：

- `:env`：指定在哪个环境中运行 Rake 任务。

- `:sudo`：是否使用 `sudo` 运行任务。默认为 `false`。

### `capify!`

在应用的根目录中运行 Capistrano 提供的 `capify` 命令，生成 Capistrano 配置。

```ruby
capify!
```

### `route`

在 `config/routes.rb` 文件中添加文本：

```ruby
route "resources :people"
```

### `readme`

输出模板的 `source_path` 中某个文件的内容，通常是 README 文件：

```ruby
readme "README"
```
