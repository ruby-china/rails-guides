个性化Rails生成器与模板
=====================================================

Rails 生成器是提高你工作效率的有力工具。通过本章节的学习，你可以了解如何创建和个性化生成器。

通过学习本章节，你将学到：

* 如何在你的Rails应用中辨别哪些生成器是可用的；
* 如何使用模板创建一个生成器；
* Rails应用在调用生成器之前如何找到他们；
* 如何通过创建一个生成器来定制你的 scaffold ；
* 如何通过改变生成器模板定制你的scaffold ；
* 如何使用回调复用生成器；
* 如何创建一个应用模板；

--------------------------------------------------------------------------------

简单介绍 
-------------

当使用`rails` 命令创建一个应用的时候，实际上使用的是一个Rails生成器，创建应用之后，你可以使用`rails generate`命令获取当前可用的生成器列表：


```bash
$ rails new myapp
$ cd myapp
$ bin/rails generate
```

你将会看到和Rails相关的生成器列表，如果想了解这些生成器的详情，可以做如下操作：

```bash
$ bin/rails generate helper --help
```

 创建你的第一个生成器
-----------------------------

从Rails 3.0开始，生成器都是基于[Thor](https://github.com/erikhuda/thor)构建的。Thor提供了强力的解析和操作文件的功能。比如，我们想让生成器在`config/initializers`目录下创建一个名为`initializer.rb`的文件：

第一步可以通过`lib/generators/initializer_generator.rb`中的代码创建一个文件：

```ruby
class InitializerGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

提示： `Thor::Actions`提供了`create_file`方法。关于`create_file`方法的详情可以参考[Thor's documentation](http://rdoc.info/github/erikhuda/thor/master/Thor/Actions.html)

我们创建的生成器非常简单： 它继承自`Rails::Generators::Base`，只包含一个方法。当一个生成器被调用时，每个在生成器内部定义的方法都会顺序执行一次。最终，我们会根据程序执行环境调用`create_file`方法，在目标文件目录下创建一个文件。 如果你很熟悉Rails应用模板API，那么你在看生成器API时，也会轻车熟路，没什么障碍。


为了调用我们刚才创建的生成器，我们只需要做如下操作：

```bash
$ bin/rails generate initializer
```

我们可以通过如下代码，了解我们刚才创建的生成器的相关信息：
```bash
$ bin/rails generate initializer --help
```

Rails可以对一个命名空间化的生成器自动生成一个很好的描述信息。比如 `ActiveRecord::Generators::ModelGenerator`。一般而言，我们可以通过2中方式生成相关的描述。第一种是在生成器内部调用`desc`方法：


```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "This generator creates an initializer file at config/initializers"
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

现在我们可以通过`--help`选项看到刚创建的生成器的描述信息。第二种是在生成器同名的目录下创建一个名为`USAGE`的文件存放和生成器相关的描述信息。

用生成器创建生成器
-----------------------------------

生成器本身拥有一个生成器：

```bash
$ bin/rails generate generator initializer
      create  lib/generators/initializer
      create  lib/generators/initializer/initializer_generator.rb
      create  lib/generators/initializer/USAGE
      create  lib/generators/initializer/templates
```

这个生成器实际上只创建了这些：

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)
end
```

首先，我们注意到生成器是继承自`Rails::Generators::NamedBase`而非`Rails::Generators::Base`，
这意味着，我们的生成器在被调用时，至少要接收一个参数，即初始化器的名字。这样我们才能通过代码中的变量`name`来访问它。 

我们可以通过查看生成器的描述信息来证实(别忘了删除旧的生成器文件)：

```bash
$ bin/rails generate initializer --help
Usage:
  rails generate initializer NAME [options]
```

我们可以看到刚才创建的生成器有一个名为`source_root`的类方法。这个方法会指定生成器模板文件的存放路径，一般情况下，会放在 `lib/generators/initializer/templates`目录下。 

为了了解生成器模板的作用，我们在`lib/generators/initializer/templates/initializer.rb`创建该文件，并添加如下内容：

```ruby
# Add initialization content here
```

现在，我们来为生成器添加一个拷贝方法，将模板文件拷贝到指定目录：

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
  end
end
```

接下来，使用刚才创建的生成器：

```bash
$ bin/rails generate initializer core_extensions
```

我们可以看到通过生成器的模板在`config/initializers/core_extensions.rb`创建了一个名为core_extensions的初始化器。这说明 `copy_file` 方法从指定文件下拷贝了一个文件到目标文件夹。因为我们是继承自`Rails::Generators::NamedBase`的，所以会自动生成`file_name`方法 。

这个方法将在本章节的[final section](#generator-methods)实现完整功能。 

生成器查找
-----------------

当你运行 `rails generate initializer core_extensions` 命令时，Rails会做如下搜索：

```bash
rails/generators/initializer/initializer_generator.rb
generators/initializer/initializer_generator.rb
rails/generators/initializer_generator.rb
generators/initializer_generator.rb
```

如果没有找到，你将会看到一个错误信息。

提示：　上面的例子把文件放在Rails应用的`lib`文件夹下，是因为该文件夹路径属于`$LOAD_PATH`。

个性化你的工作流　
-------------------------

Rails自带的生成器为工作流的个性化提供了支持。它们可以在`config/application.rb`中进行配置：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: true
end
```

在个性化我们的工作流之前，我们先看看scaffold工具会做些什么：　

```bash
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
      invoke      test_unit
      create        test/helpers/users_helper_test.rb
      invoke    jbuilder
      create      app/views/users/index.json.jbuilder
      create      app/views/users/show.json.jbuilder
      invoke  assets
      invoke    coffee
      create      app/assets/javascripts/users.js.coffee
      invoke    scss
      create      app/assets/stylesheets/users.css.scss
      invoke  scss
      create    app/assets/stylesheets/scaffolds.css.scss
```

通过上面的内容，我们可以很容易理解Rails3.0以上版本的生成器是如何工作的。scaffold生成器几乎不生成文件。它只是调用其他生成器去做。这样的话，我们可以很方便的添加/替换/删除这些被调用的生成器。比如说，scaffold生成器调用了scaffold_controller生成器(调用了erb,test_unit和helper生成器)，它们每个生成器都有一个单独的响应方法，这样就很容易实现代码复用。

如果我们希望scaffold 在生成工作流时不必生成样式表，脚本文件和测试固件等文件，那么我们可以进行如下配置：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
end
```

如果我们使用scaffold生成器创建另外一个资源时，就会发现样式表，脚本文件和测试固件的文件都不再创建了。如果你想更深入的进行定制，比如使用DataMapper和RSpec 替换Active Record和TestUnit
，那么只需要把相关的gem文件引入，并配置你的生成器。

为了证明这一点，我们将创建一个新的helper生成器，简单的添加一些实例变量访问器。首先，我们创建一个带Rails命名空间的的生成器，因为这样为Rails方便搜索提供了支持：

```bash
$ bin/rails generate generator rails/my_helper
      create  lib/generators/rails/my_helper
      create  lib/generators/rails/my_helper/my_helper_generator.rb
      create  lib/generators/rails/my_helper/USAGE
      create  lib/generators/rails/my_helper/templates
```

现在，我们可以删除`templates`和`source_root`文件了，因为我们将不会用到它们，接下来我们在生成器中添加如下代码： 

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

我们可以使用修改过的生成器为products提供一个helper文件：

```bash
$ bin/rails generate my_helper products
      create  app/helpers/products_helper.rb
```

这将会在 `app/helpers`目录下生成一个对应的文件： 

```ruby
module ProductsHelper
  attr_reader :products, :product
end
```

这就是我们希望看到的。现在，我们可以修改`config/application.rb`，告诉scaffold使用我们的helper 生成器：

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
 
你将在生成动作列表中看到上述方法的调用：

```bash
$ bin/rails generate scaffold Article body:text
      [...]
      invoke    my_helper
      create      app/helpers/articles_helper.rb
```

我们注意到新的helper生成器替换了Rails默认的调用。但有一件事情却忽略了，如何为新的生成器提供测试呢？我们可以复用原有的helpers测试生成器。

从Rails 3.0开始，简单的实现上述功能依赖于钩子的概念。我们新的helper方法不需要拘泥于特定的测试框架，它可以简单的提供一个钩子，测试框架只需要实现这个钩子并与之一致即可。

为此，我们需要对生成器做如下修改：

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

现在，当helper生成器被调用时，与之匹配的测试框架是TestUnit，那么这将会调用`Rails::TestUnitGenerator`和 `TestUnit::MyHelperGenerator`。如果他们都没有定义，我们可以告诉生成器调用`TestUnit::Generators::HelperGenerator`来替代。对于一个Rails生成器来说，我们只需要添加如下代码：

```ruby
# Search for :helper instead of :my_helper
hook_for :test_framework, as: :helper
```

现在，你再次运行scaffold生成器生成Rails应用时，它就会生成相关的测试了。

通过修改生成器模板个性化工作流
----------------------------------------------------------

上一章节中，我们只是简单的在helper生成器中添加了一行代码，没有添加额外的功能。有一种简便的方法可以实现它，那就是替换模版中已经存在的生成器。比如`Rails::Generators::HelperGenerator`。


从Rails 3.0开始，生成器不只是在源目录中查找模版，它们也会搜索其他路径。其中一个就是`lib/templates`，如果我们想定制`Rails::Generators::HelperGenerator`，那么我们可以在`lib/templates/rails/helper`中添加一个名为`helper.rb`的文件，文件内容包含如下代码：

```erb
module <%= class_name %>Helper
  attr_reader :<%= plural_name %>, :<%= plural_name.singularize %>
end
```

将 `config/application.rb`中重复的内容删除：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
end
```

现在生成另外一个Rails应用时，你会发现得到的结果几乎一致。这是一个很有用的功能，如果你只想修改`edit.html.erb`, `index.html.erb`等文件的布局，那么可以在`lib/templates/erb/scaffold`中进行配置。

让生成器支持备选功能 
---------------------------

最后将要介绍的生成器特性对插件生成器特别有用。举个例子，如果你想给TestUnit添加一个名为 [shoulda](https://github.com/thoughtbot/shoulda)的特性，TestUnit已经实现了所有Rails要求的生成器功能，shoulda想重用其中的部分功能，shoulda不需要重新实现这些生成器，可以告诉Rails使用`TestUnit`的生成器，如果在`Shoulda`的命名空间中没找到的话。

我们可以通过修改`config/application.rb`的内容，很方便的实现这个功能：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :shoulda, fixture: false
  g.stylesheets     false
  g.javascripts     false

  # Add a fallback!
  g.fallbacks[:shoulda] = :test_unit
end
```

现在，如果你使用scaffold 创建一个Comment 资源，那么你将看到shoulda生成器被调用了，但最后调用的是TestUnit的生成器方法：

```bash
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
      invoke      shoulda
      create        test/helpers/comments_helper_test.rb
      invoke    jbuilder
      create      app/views/comments/index.json.jbuilder
      create      app/views/comments/show.json.jbuilder
      invoke  assets
      invoke    coffee
      create      app/assets/javascripts/comments.js.coffee
      invoke    scss
```

备选功能支持你的生成器拥有单独的响应，可以实现代码复用，减少重复代码。


应用模版
---------------------

现在你已经了解如何在一个应用中使用生成器，那么你知道生成器还可以生成应用吗？ 这种生成器一般是由"template"来实现的。接下来我们会简要介绍模版API，进一步了解可以参考[Rails Application Templates guide](rails_application_templates.html)。

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

上述模版在`Gemfile`声明了 `rspec-rails` 和 `cucumber-rails`两个gem包属于`test`组，之后会发送一个问题给使用者，是否希望安装Devise？如果用户同意安装，那么模版会将Devise添加到`Gemfile`文件中，并运行 `devise:install`命令，之后根据用户输入的模块名，指定`devise`所属模块。

假如你想使用一个名为`template.rb`的模版文件，我们可以通过在执行 `rails new`命令时，加上 `-m` 选项来改变输出信息：

```bash
$ rails new thud -m template.rb
```

上述命令将会生成`Thud` 应用，并使用模版生成输出信息。

模版文件不一定要存储在本地文件中， `-m`选项也支持在线模版：

```bash
$ rails new thud -m https://gist.github.com/radar/722911/raw/
```

本文最后的章节没有介绍如何生成大家都熟知的模版，而是介绍在开发模版过程中会用到的方法。同样这些方法也可以通过生成器来调用。

生成器方法
-----------------

下面要介绍的方法对生成器和模版来说都是可用的。

提示： Thor中未介绍的方法可以通过访问[Thor's documentation](http://rdoc.info/github/erikhuda/thor/master/Thor/Actions.html)做进一步了解。

### `gem` 

声明一个gem在Rails应用中的依赖项。

```ruby
gem "rspec", group: "test", version: "2.1.0"
gem "devise", "1.1.5"
```

可用的选项如下：

* `:group` - 在`Gemfile`中声明所安装的gem包所在的分组。
* `:version` - 声明gem的版本信息，你也可以在该方法的第二个参数中声明。
* `:git` - gem包相关的git地址 

可以在该方法参数列表的最后添加额外的信息：

```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

上述代码将在`Gemfile`中添加如下内容：

```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

### `gem_group`

将gem包安装到指定组中：

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### `add_source`

为`Gemfile`文件添加指定数据源：

```ruby
add_source "http://gems.github.com"
```

### `inject_into_file`

在文件中插入一段代码：

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

使用正则表达式可以更准确的匹配信息。同时可以分别使用`append_file`和 `prepend_file`方法从文件的开始处或末尾处匹配信息。

### `application`

在`config/application.rb`文件中的application类定义之后添加一行信息。

```ruby
application "config.asset_host = 'http://example.com'"
```

这个方法也可以写成一个代码块的方式：

```ruby
application do
  "config.asset_host = 'http://example.com'"
end
```

可用的选项如下：

* `:env` -为配置文件指定运行环境，如果你希望写成代码块的方式，可以这么做:

```ruby
application(nil, env: "development") do
  "config.asset_host = 'http://localhost:3000'"
end
```

### `git`

运行指定的git命令：

```ruby
git :init
git add: "."
git commit: "-m First commit!"
git add: "onefile.rb", rm: "badfile.cxx"
```

哈希值可以作为git命令的参数来使用，上述代码中指定了多个git命令，但并不能保证这些命令按顺序执行。


### `vendor`

查找`vendor`文件加下指定文件是否包含指定内容：

```ruby
vendor "sekrit.rb", '#top secret stuff'
```

这个方法也可以写成一个代码块 ：

```ruby
vendor "seeds.rb" do
  "puts 'in your app, seeding your database'"
end
```

### `lib`

查找`lib`文件加下指定文件是否包含指定内容：

```ruby
lib "special.rb", "p Rails.root"
```

这个方法也可以写成一个代码块 ：

```ruby
lib "super_special.rb" do
  puts "Super special!"
end
```

### `rakefile`

在Rails应用的 `lib/tasks`文件夹下创建一个Rake文件。

```ruby
rakefile "test.rake", "hello there"
```

这个方法也可以写成一个代码块 ：

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

在Rails应用的`config/initializers` 目录下创建一个初始化器：

```ruby
initializer "begin.rb", "puts 'this is the beginning'"
```

这个方法也可以写成一个代码块，并返回一个字符串：

```ruby
initializer "begin.rb" do
  "puts 'this is the beginning'"
end
```

### `generate`

运行指定的生成器，第一个参数是生成器名字，其余的直接传给生成器：

```ruby
generate "scaffold", "forums title:string description:text"
```


### `rake`

运行指定的Rake任务：


```ruby
rake "db:migrate"
```

可用是选项如下：

* `:env` - 声明rake任务的执行环境。
* `:sudo` - 是否使用`sudo`命令运行rake任务，默认不使用。

### `capify!`

在Rails应用的根目录下使用Capistrano运行`capify`命令，生成和Rails应用相关的Capistrano配置文件。

```ruby
capify!
```

### `route`

在`config/routes.rb` 文件中添加文本：

```ruby
route "resources :people"
```

### `readme`

输出模版的`source_path`相关的内容，通常是一个README文件。

```ruby
readme "README"
```
