Rails 入门
==========

本文介绍如何开始使用 Ruby on Rails。

读完本文，你将学到：

* 如何安装 Rails，新建 Rails 程序，如何连接数据库；
* Rails 程序的基本文件结构；
* MVC（模型，视图，控制器）和 REST 架构的基本原理；
* 如何快速生成 Rails 程序骨架；

--------------------------------------------------------------------------------

前提条件
-------

本文针对想从零开始开发 Rails 程序的初学者，不需要预先具备任何的 Rails 使用经验。不过，为了能顺利阅读，还是需要事先安装好一些软件：

* [Ruby](https://www.ruby-lang.org/en/downloads)  1.9.3 及以上版本
* 包管理工具 [RubyGems](https://rubygems.org)，随 Ruby 1.9+ 安装。想深入了解 RubyGems，请阅读 [RubyGems 指南](http://guides.rubygems.org)
* [SQLite3](https://www.sqlite.org) 数据库

Rails 是使用 Ruby 语言开发的网页程序框架。如果之前没接触过 Ruby，学习 Rails 可要深下一番功夫。网上有很多资源可以学习 Ruby：

* [Ruby 语言官方网站](https://www.ruby-lang.org/zh_cn/documentation/)
* [reSRC 列出的免费编程书籍](http://resrc.io/list/10/list-of-free-programming-books/#ruby)

记住，某些资源虽然很好，但是针对 Ruby 1.8，甚至 1.6 编写的，所以没有介绍一些 Rails 日常开发会用到的句法。

Rails 是什么？
-------------

Rails 是使用 Ruby 语言编写的网页程序开发框架，目的是为开发者提供常用组件，简化网页程序的开发。只需编写较少的代码，就能实现其他编程语言或框架难以企及的功能。经验丰富的 Rails 程序员会发现，Rails 让程序开发变得更有乐趣。

Rails 有自己的一套规则，认为问题总有最好的解决方法，而且建议使用最好的方法，有些情况下甚至不推荐使用其他替代方案。学会如何按照 Rails 的思维开发，能极大提高开发效率。如果坚持在 Rails 开发中使用其他语言中的旧思想，尝试使用别处学来的编程模式，开发过程就不那么有趣了。

Rails 哲学包含两大指导思想：

* **不要自我重复（DRY）：** DRY 是软件开发中的一个原则，“系统中的每个功能都要具有单一、准确、可信的实现。”。不重复表述同一件事，写出的代码才能更易维护，更具扩展性，也更不容易出问题。
* **多约定，少配置：** Rails 为网页程序的大多数需求都提供了最好的解决方法，而且默认使用这些约定，不用在长长的配置文件中设置每个细节。

新建 Rails 程序
--------------

阅读本文时，最好跟着一步一步操作，如果错过某段代码或某个步骤，程序就可能出错，所以请一步一步跟着做。完整的源码可以在[这里](https://github.com/rails/docrails/tree/master/guides/code/getting_started)获取。

本文会新建一个名为 `blog` 的 Rails 程序，这是一个非常简单的博客。在开始开发程序之前，要确保已经安装了 Rails。

TIP: 文中的示例代码使用 `$` 表示命令行提示符，你的提示符可能修改过，所以会不一样。在 Windows 中，提示符可能是 `c:\source_code>`。

### 安装 Rails

打开命令行：在 Mac OS X 中打开 Terminal.app，在 Windows 中选择“运行”，然后输入“cmd.exe”。下文中所有以 `$` 开头的代码，都要在命令行中运行。先确认是否安装了 Ruby 最新版：

TIP: 有很多工具可以帮助你快速在系统中安装 Ruby 和 Ruby on Rails。Windows 用户可以使用 [Rails Installer](http://railsinstaller.org)，Mac OS X 用户可以使用 [Tokaido](https://github.com/tokaido/tokaidoapp)。

```bash
$ ruby -v
ruby 2.1.2p95
```

如果你还没安装 Ruby，请访问 [ruby-lang.org](https://www.ruby-lang.org/en/downloads/)，找到针对所用系统的安装方法。

很多类 Unix 系统都自带了版本尚新的 SQLite3。Windows 等其他操作系统的用户可以在 [SQLite3 的网站](https://www.sqlite.org)上找到安装说明。然后，确认是否在 PATH 中：

```bash
$ sqlite3 --version
```

命令行应该回显版本才对。

安装 Rails，请使用 RubyGems 提供的 `gem install` 命令：

```bash
$ gem install rails
```

要检查所有软件是否都正确安装了，可以执行下面的命令：

```bash
$ rails --version
```

如果显示的结果类似“Rails 4.2.0”，那么就可以继续往下读了。

### 创建 Blog 程序

Rails 提供了多个被称为“生成器”的脚本，可以简化开发，生成某项操作需要的所有文件。其中一个是新程序生成器，生成一个 Rails 程序骨架，不用自己一个一个新建文件。

打开终端，进入有写权限的文件夹，执行以下命令生成一个新程序：

```bash
$ rails new blog
```

这个命令会在文件夹 `blog` 中新建一个 Rails 程序，然后执行 `bundle install` 命令安装 `Gemfile` 中列出的 gem。

TIP: 执行 `rails new -h` 可以查看新程序生成器的所有命令行选项。

生成 `blog` 程序后，进入该文件夹：

```bash
$ cd blog
```

`blog` 文件夹中有很多自动生成的文件和文件夹，组成一个 Rails 程序。本文大部分时间都花在 `app` 文件夹上。下面简单介绍默认生成的文件和文件夹的作用：

| 文件/文件夹 | 作用 |
| ----------- | ------- |
|app/|存放程序的控制器、模型、视图、帮助方法、邮件和静态资源文件。本文主要关注的是这个文件夹。|
|bin/|存放运行程序的 `rails` 脚本，以及其他用来部署或运行程序的脚本。|
|config/|设置程序的路由，数据库等。详情参阅“[设置 Rails 程序](/configuring.html)”一文。|
|config.ru|基于 Rack 服务器的程序设置，用来启动程序。|
|db/|存放当前数据库的模式，以及数据库迁移文件。|
|Gemfile, Gemfile.lock|这两个文件用来指定程序所需的 gem 依赖件，用于 Bundler gem。关于 Bundler 的详细介绍，请访问 [Bundler 官网](http://bundler.io)。|
|lib/|程序的扩展模块。|
|log/|程序的日志文件。|
|public/|唯一对外开放的文件夹，存放静态文件和编译后的资源文件。|
|Rakefile|保存并加载可在命令行中执行的任务。任务在 Rails 的各组件中定义。如果想添加自己的任务，不要修改这个文件，把任务保存在 `lib/tasks` 文件夹中。|
|README.rdoc|程序的简单说明。你应该修改这个文件，告诉其他人这个程序的作用，如何安装等。|
|test/|单元测试，固件等测试用文件。详情参阅“[测试 Rails 程序](/testing.html)”一文。|
|tmp/|临时文件，例如缓存，PID，会话文件。|
|vendor/|存放第三方代码。经常用来放第三方 gem。|

Hello, Rails!
-------------

首先，我们来添加一些文字，在页面中显示。为了能访问网页，要启动程序服务器。

### 启动服务器

现在，新建的 Rails 程序已经可以正常运行。要访问网站，需要在开发电脑上启动服务器。请在 `blog` 文件夹中执行下面的命令：

```bash
$ rails server
```

TIP: 把 CoffeeScript 编译成 JavaScript 需要 JavaScript 运行时，如果没有运行时，会报错，提示没有 `execjs`。Mac OS X 和 Windows 一般都提供了 JavaScript 运行时。Rails 生成的 `Gemfile` 中，安装 `therubyracer` gem 的代码被注释掉了，如果需要使用这个 gem，请把前面的注释去掉。在 JRuby 中推荐使用 `therubyracer`。在 JRuby 中生成的 `Gemfile` 已经包含了这个 gem。所有支持的运行时参见 [ExecJS](https://github.com/sstephenson/execjs#readme)。

上述命令会启动 WEBrick，这是 Ruby 内置的服务器。要查看程序，请打开一个浏览器窗口，访问 <http://localhost:3000>。应该会看到默认的 Rails 信息页面：

![欢迎使用页面](images/getting_started/rails_welcome.png)

TIP: 要想停止服务器，请在命令行中按 Ctrl+C 键。服务器成功停止后回重新看到命令行提示符。在大多数类 Unix 系统中，包括 Mac OS X，命令行提示符是 `$` 符号。在开发模式中，一般情况下无需重启服务器，修改文件后，服务器会自动重新加载。

“欢迎使用”页面是新建 Rails 程序后的“冒烟测试”：确保程序设置正确，能顺利运行。你可以点击“About your application's environment”链接查看程序所处环境的信息。

### 显示“Hello, Rails!”

要在 Rails 中显示“Hello, Rails!”，需要新建一个控制器和视图。

控制器用来接受向程序发起的请求。路由决定哪个控制器会接受到这个请求。一般情况下，每个控制器都有多个路由，对应不同的动作。动作用来提供视图中需要的数据。

视图的作用是，以人类能看懂的格式显示数据。有一点要特别注意，数据是在控制器中获取的，而不是在视图中。视图只是把数据显示出来。默认情况下，视图使用 eRuby（嵌入式 Ruby）语言编写，经由 Rails 解析后，再发送给用户。

控制器可用控制器生成器创建，你要告诉生成器，我想要个名为“welcome”的控制器和一个名为“index”的动作，如下所示：

```bash
$ rails generate controller welcome index
```

运行上述命令后，Rails 会生成很多文件，以及一个路由。

```bash
create  app/controllers/welcome_controller.rb
 route  get 'welcome/index'
invoke  erb
create    app/views/welcome
create    app/views/welcome/index.html.erb
invoke  test_unit
create    test/controllers/welcome_controller_test.rb
invoke  helper
create    app/helpers/welcome_helper.rb
invoke  assets
invoke    coffee
create      app/assets/javascripts/welcome.js.coffee
invoke    scss
create      app/assets/stylesheets/welcome.css.scss
```

在这些文件中，最重要的当然是控制器，位于 `app/controllers/welcome_controller.rb`，以及视图，位于 `app/views/welcome/index.html.erb`。

使用文本编辑器打开 `app/views/welcome/index.html.erb` 文件，删除全部内容，写入下面这行代码：

```html
<h1>Hello, Rails!</h1>
```

### 设置程序的首页

我们已经创建了控制器和视图，现在要告诉 Rails 在哪个地址上显示“Hello, Rails!”。这里，我们希望访问根地址 <http://localhost:3000> 时显示。但是现在显示的还是欢迎页面。

我们要告诉 Rails 真正的首页是什么。

在编辑器中打开 `config/routes.rb` 文件。

```ruby
Rails.application.routes.draw do
  get 'welcome/index'

  # The priority is based upon order of creation:
  # first created -> highest priority.
  #
  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  #
  # ...
```

这是程序的路由文件，使用特殊的 DSL（domain-specific language，领域专属语言）编写，告知 Rails 请求应该发往哪个控制器和动作。文件中有很多注释，举例说明如何定义路由。其中有一行说明了如何指定控制器和动作设置网站的根路由。找到以 `root` 开头的代码行，去掉注释，变成这样：

```ruby
root 'welcome#index'
```

`root 'welcome#index'` 告知 Rails，访问程序的根路径时，交给 `welcome` 控制器中的 `index` 动作处理。`get 'welcome/index'` 告知 Rails，访问 <http://localhost:3000/welcome/index> 时，交给 `welcome` 控制器中的 `index` 动作处理。`get 'welcome/index'` 是运行 `rails generate controller welcome index` 时生成的。

如果生成控制器时停止了服务器，请再次启动（`rails server`），然后在浏览器中访问 <http://localhost:3000>。你会看到之前写入 `app/views/welcome/index.html.erb` 文件的“Hello, Rails!”，说明新定义的路由把根目录交给 `WelcomeController` 的 `index` 动作处理了，而且也正确的渲染了视图。

TIP: 关于路由的详细介绍，请阅读“[Rails 路由全解](/routing.html)”一文。

开始使用
-------

前文已经介绍如何创建控制器、动作和视图，下面我们来创建一些更实质的功能。

在博客程序中，我们要创建一个新“资源”。资源是指一系列类似的对象，比如文章，人和动物。

资源可以被创建、读取、更新和删除，这些操作简称 CRUD。

Rails 提供了一个 `resources` 方法，可以声明一个符合 REST 架构的资源。创建文章资源后，`config/routes.rb` 文件的内容如下：

```ruby
Rails.application.routes.draw do

  resources :articles

  root 'welcome#index'
end
```

执行 `rake routes` 任务，会看到定义了所有标准的 REST 动作。输出结果中各列的意义稍后会说明，现在只要留意 `article` 的单复数形式，这在 Rails 中有特殊的含义。

```bash
$ bin/rake routes
      Prefix Verb   URI Pattern                  Controller#Action
    articles GET    /articles(.:format)          articles#index
             POST   /articles(.:format)          articles#create
 new_article GET    /articles/new(.:format)      articles#new
edit_article GET    /articles/:id/edit(.:format) articles#edit
     article GET    /articles/:id(.:format)      articles#show
             PATCH  /articles/:id(.:format)      articles#update
             PUT    /articles/:id(.:format)      articles#update
             DELETE /articles/:id(.:format)      articles#destroy
        root GET    /                            welcome#index
```

下一节，我们会加入新建文章和查看文章的功能。这两个操作分别对应于 CRUD 的 C 和 R，即创建和读取。新建文章的表单如下所示：

![新建文章表单](images/getting_started/new_article.png)

表单看起来很简陋，不过没关系，后文会加入更多的样式。

### 挖地基

首先，程序中要有个页面用来新建文章。一个比较好的选择是 `/articles/new`。这个路由前面已经定义了，可以访问。打开 <http://localhost:3000/articles/new> ，会看到如下的路由错误：

![路由错误，常量 ArticlesController 未初始化](images/getting_started/routing_error_no_controller.png)

产生这个错误的原因是，没有定义用来处理该请求的控制器。解决这个问题的方法很简单：创建名为 `ArticlesController` 的控制器。执行下面的命令即可：

```bash
$ bin/rails g controller articles
```

打开刚生成的 `app/controllers/articles_controller.rb` 文件，会看到一个几乎没什么内容的控制器：

```ruby
class ArticlesController < ApplicationController
end
```

控制器就是一个类，继承自 `ApplicationController`。在这个类中定义的方法就是控制器的动作。动作的作用是处理文章的 CRUD 操作。

NOTE: 在 Ruby 中，方法分为 `public`、`private` 和 `protected` 三种，只有 `public` 方法才能作为控制器的动作。详情参阅 [Programming Ruby](http://www.ruby-doc.org/docs/ProgrammingRuby/) 一书。

现在刷新 <http://localhost:3000/articles/new>，会看到一个新错误：

![ArticlesController 控制器不知如何处理 new 动作](images/getting_started/unknown_action_new_for_articles.png)

这个错误的意思是，在刚生成的 `ArticlesController` 控制器中找不到 `new` 动作。因为在生成控制器时，除非指定要哪些动作，否则不会生成，控制器是空的。

手动创建动作只需在控制器中定义一个新方法。打开 `app/controllers/articles_controller.rb` 文件，在 `ArticlesController` 类中，定义 `new` 方法，如下所示：

```ruby
class ArticlesController < ApplicationController
  def new
  end
end
```

在 `ArticlesController` 中定义 `new` 方法后，再刷新 <http://localhost:3000/articles/new>，看到的还是个错误：

![找不到 articles/new 所用模板](images/getting_started/template_is_missing_articles_new.png)

产生这个错误的原因是，Rails 希望这样的常规动作有对应的视图，用来显示内容。没有视图可用，Rails 就报错了。

在上图中，最后一行被截断了，我们来看一下完整的信息：

```
Missing template articles/new, application/new with {locale:[:en], formats:[:html], handlers:[:erb, :builder, :coffee]}. Searched in: * "/path/to/blog/app/views"
```

这行信息还挺长，我们来看一下到底是什么意思。

第一部分说明找不到哪个模板，这里，丢失的是 `articles/new` 模板。Rails 首先会寻找这个模板，如果找不到，再找名为 `application/new` 的模板。之所以这么找，是因为 `ArticlesController` 继承自 `ApplicationController`。

后面一部分是个 Hash。`:locale` 表示要找哪国语言模板，默认是英语（`"en"`）。`:format` 表示响应使用的模板格式，默认为 `:html`，所以 Rails 要寻找一个 HTML 模板。`:handlers` 表示用来处理模板的程序，HTML 模板一般使用 `:erb`，XML 模板使用 `:builder`，`:coffee` 用来把 CoffeeScript 转换成 JavaScript。

最后一部分说明 Rails 在哪里寻找模板。在这个简单的程序里，模板都存放在一个地方，复杂的程序可能存放在多个位置。

让这个程序正常运行，最简单的一种模板是 `app/views/articles/new.html.erb`。模板文件的扩展名是关键所在：第一个扩展名是模板的类型，第二个扩展名是模板的处理程序。Rails 会尝试在 `app/views` 文件夹中寻找名为 `articles/new` 的模板。这个模板的类型只能是 `html`，处理程序可以是 `erb`、`builder` 或 `coffee`。因为我们要编写一个 HTML 表单，所以使用 `erb`。所以这个模板文件应该命名为 `articles/new.html.erb`，还要放在 `app/views` 文件夹中。

新建文件 `app/views/articles/new.html.erb`，写入如下代码：

```html
<h1>New Article</h1>
```

再次刷新 <http://localhost:3000/articles/new>，可以看到页面中显示了一个标头。现在路由、控制器、动作和视图都能正常运行了。接下来要编写新建文章的表单了。

### 首个表单

要在模板中编写表单，可以使用“表单构造器”。Rails 中常用的表单构造器是 `form_for`。在 `app/views/articles/new.html.erb` 文件中加入以下代码：

```erb
<%= form_for :article do |f| %>
  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>
  </p>

  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>

  <p>
    <%= f.submit %>
  </p>
<% end %>
```

现在刷新页面，会看到上述代码生成的表单。在 Rails 中编写表单就是这么简单！

调用 `form_for` 方法时，要指定一个对象。在上面的表单中，指定的是 `:article`。这个对象告诉 `form_for`，这个表单是用来处理哪个资源的。在 `form_for` 方法的块中，`FormBuilder` 对象（用 `f` 表示）创建了两个标签和两个文本字段，一个用于文章标题，一个用于文章内容。最后，在 `f` 对象上调用 `submit` 方法，创建一个提交按钮。

不过这个表单还有个问题。如果查看这个页面的源码，会发现表单 `action` 属性的值是 `/articles/new`。这就是问题所在，因为其指向的地址就是现在这个页面，而这个页面是用来显示新建文章表单的。

要想转到其他地址，就要使用其他的地址。这个问题可使用 `form_for` 方法的 `:url` 选项解决。在 Rails 中，用来处理新建资源表单提交数据的动作是 `create`，所以表单应该转向这个动作。

修改 `app/views/articles/new.html.erb` 文件中的 `form_for`，改成这样：

```erb
<%= form_for :article, url: articles_path do |f| %>
```

这里，我们把 `:url` 选项的值设为 `articles_path` 帮助方法。要想知道这个方法有什么作用，我们要回过头再看一下 `rake routes` 的输出：

```bash
$ bin/rake routes
      Prefix Verb   URI Pattern                  Controller#Action
    articles GET    /articles(.:format)          articles#index
             POST   /articles(.:format)          articles#create
 new_article GET    /articles/new(.:format)      articles#new
edit_article GET    /articles/:id/edit(.:format) articles#edit
     article GET    /articles/:id(.:format)      articles#show
             PATCH  /articles/:id(.:format)      articles#update
             PUT    /articles/:id(.:format)      articles#update
             DELETE /articles/:id(.:format)      articles#destroy
        root GET    /                            welcome#index
```

`articles_path` 帮助方法告诉 Rails，对应的地址是 `/articles`，默认情况下，这个表单会向这个路由发起 `POST` 请求。这个路由对应于 `ArticlesController` 控制器的 `create` 动作。

表单写好了，路由也定义了，现在可以填写表单，然后点击提交按钮新建文章了。请实际操作一下。提交表单后，会看到一个熟悉的错误：

![ArticlesController 控制器不知如何处理 create 动作](images/getting_started/unknown_action_create_for_articles.png)

解决这个错误，要在 `ArticlesController` 控制器中定义 `create` 动作。

### 创建文章

要解决前一节出现的错误，可以在 `ArticlesController` 类中定义 `create` 方法。在 `app/controllers/articles_controller.rb` 文件中 `new` 方法后面添加以下代码：

```ruby
class ArticlesController < ApplicationController
  def new
  end

  def create
  end
end
```

然后再次提交表单，会看到另一个熟悉的错误：找不到模板。现在暂且不管这个错误。`create` 动作的作用是把新文章保存到数据库中。

提交表单后，其中的字段以参数的形式传递给 Rails。这些参数可以在控制器的动作中使用，完成指定的操作。要想查看这些参数的内容，可以把 `create` 动作改成：

```ruby
def create
  render plain: params[:article].inspect
end
```

`render` 方法接受一个简单的 Hash 为参数，这个 Hash 的键是 `plain`，对应的值为 `params[:article].inspect`。`params` 方法表示通过表单提交的参数，返回 `ActiveSupport::HashWithIndifferentAccess` 对象，可以使用字符串或者 Symbol 获取键对应的值。现在，我们只关注通过表单提交的参数。

如果现在再次提交表单，不会再看到找不到模板错误，而是会看到类似下面的文字：

```ruby
{"title"=>"First article!", "text"=>"This is my first article."}
```

`create` 动作把表单提交的参数显示出来了。不过这么做没什么用，看到了参数又怎样，什么都没发生。

### 创建 Article 模型

在 Rails 中，模型的名字使用单数，对应的数据表名使用复数。Rails 提供了一个生成器用来创建模型，大多数 Rails 开发者创建模型时都会使用。创建模型，请在终端里执行下面的命令：

```bash
$ bin/rails generate model Article title:string text:text
```

这个命令告知 Rails，我们要创建 `Article` 模型，以及一个字符串属性 `title` 和文本属性 `text`。这两个属性会自动添加到 `articles` 数据表中，映射到 `Article` 模型。

执行这个命令后，Rails 会生成一堆文件。现在我们只关注 `app/models/article.rb` 和 `db/migrate/20140120191729_create_articles.rb`（你得到的文件名可能有点不一样）这两个文件。后者用来创建数据库结构，下一节会详细说明。

TIP: Active Record 很智能，能自动把数据表中的字段映射到模型的属性上。所以无需在 Rails 的模型中声明属性，因为 Active Record 会自动映射。

### 运行迁移

如前文所述，`rails generate model` 命令会在 `db/migrate` 文件夹中生成一个数据库迁移文件。迁移是一个 Ruby 类，能简化创建和修改数据库结构的操作。Rails 使用 rake 任务运行迁移，修改数据库结构后还能撤销操作。迁移的文件名中有个时间戳，这样能保证迁移按照创建的时间顺序运行。

`db/migrate/20140120191729_create_articles.rb`（还记得吗，你的迁移文件名可能有点不一样）文件的内容如下所示：

```ruby
class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :title
      t.text :text

      t.timestamps
    end
  end
end
```

在这个迁移中定义了一个名为 `change` 的方法，在运行迁移时执行。`change` 方法中定义的操作都是可逆的，Rails 知道如何撤销这次迁移操作。运行迁移后，会创建 `articles` 表，以及一个字符串字段和文本字段。同时还会创建两个时间戳字段，用来跟踪记录的创建时间和更新时间。

TIP: 关于迁移的详细说明，请参阅“[Active Record 数据库迁移](/migrations.html)”一文。

然后，使用 rake 命令运行迁移：

```bash
$ bin/rake db:migrate
```

Rails 会执行迁移操作，告诉你创建了 `articles` 表。

```bash
==  CreateArticles: migrating ==================================================
-- create_table(:articles)
   -> 0.0019s
==  CreateArticles: migrated (0.0020s) =========================================
```

NOTE: 因为默认情况下，程序运行在开发环境中，所以相关的操作应用于 `config/database.yml` 文件中 `development` 区域设置的数据库上。如果想在其他环境中运行迁移，必须在命令中指明：`rake db:migrate RAILS_ENV=production`。

### 在控制器中保存数据

再回到 `ArticlesController` 控制器，我们要修改 `create` 动作，使用 `Article` 模型把数据保存到数据库中。打开 `app/controllers/articles_controller.rb` 文件，把 `create` 动作修改成这样：

```ruby
def create
  @article = Article.new(params[:article])

  @article.save
  redirect_to @article
end
```

在 Rails 中，每个模型可以使用各自的属性初始化，自动映射到数据库字段上。`create` 动作中的第一行就是这个目的（还记得吗，`params[:article]` 就是我们要获取的属性）。`@article.save` 的作用是把模型保存到数据库中。保存完后转向 `show` 动作。稍后再编写 `show` 动作。

TIP: 后文会看到，`@article.save` 返回一个布尔值，表示保存是否成功。

再次访问 <http://localhost:3000/articles/new>，填写表单，还差一步就能创建文章了，会看到一个错误页面：

![新建文章时禁止使用属性](images/getting_started/forbidden_attributes_for_new_article.png)

Rails 提供了很多安全防范措施保证程序的安全，你所看到的错误就是因为违反了其中一个措施。这个防范措施叫做“健壮参数”，我们要明确地告知 Rails 哪些参数可在控制器中使用。这里，我们想使用 `title` 和 `text` 参数。请把 `create` 动作修成成：

```ruby
def create
  @article = Article.new(article_params)

  @article.save
  redirect_to @article
end

private
  def article_params
    params.require(:article).permit(:title, :text)
  end
```

看到 `permit` 方法了吗？这个方法允许在动作中使用 `title` 和 `text` 属性。

TIP: 注意，`article_params` 是私有方法。这种用法可以防止攻击者把修改后的属性传递给模型。关于健壮参数的更多介绍，请阅读[这篇文章](http://weblog.rubyonrails.org/2012/3/21/strong-parameters/)。

### 显示文章

现在再次提交表单，Rails 会提示找不到 `show` 动作。这个提示没多大用，我们还是先添加 `show` 动作吧。

我们在 `rake routes` 的输出中看到，`show` 动作的路由是：

```
article GET    /articles/:id(.:format)      articles#show
```

`:id` 的意思是，路由期望接收一个名为 `id` 的参数，在这个例子中，就是文章的 ID。

和前面一样，我们要在 `app/controllers/articles_controller.rb` 文件中添加 `show` 动作，以及相应的视图文件。

```ruby
def show
  @article = Article.find(params[:id])
end
```

有几点要注意。我们调用 `Article.find` 方法查找想查看的文章，传入的参数 `params[:id]` 会从请求中获取 `:id` 参数。我们还把文章对象存储在一个实例变量中（以 `@` 开头的变量），只有这样，变量才能在视图中使用。

然后，新建 `app/views/articles/show.html.erb` 文件，写入下面的代码：

```erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>
```

做了以上修改后，就能真正的新建文章了。访问 <http://localhost:3000/articles/new>，自己试试。

![显示文章](images/getting_started/show_action_for_articles.png)

### 列出所有文章

我们还要列出所有文章，对应的路由是：

```
articles GET    /articles(.:format)          articles#index
```

在 `app/controllers/articles_controller.rb` 文件中，为 `ArticlesController` 控制器添加 `index` 动作：

```ruby
def index
  @articles = Article.all
end
```

然后编写这个动作的视图，保存为 `app/views/articles/index.html.erb`：

```erb
<h1>Listing articles</h1>

<table>
  <tr>
    <th>Title</th>
    <th>Text</th>
  </tr>

  <% @articles.each do |article| %>
    <tr>
      <td><%= article.title %></td>
      <td><%= article.text %></td>
    </tr>
  <% end %>
</table>
```

现在访问 <http://localhost:3000/articles>，会看到已经发布的文章列表。

### 添加链接

至此，我们可以新建、显示、列出文章了。下面我们添加一些链接，指向这些页面。

打开 `app/views/welcome/index.html.erb` 文件，改成这样：

```erb
<h1>Hello, Rails!</h1>
<%= link_to 'My Blog', controller: 'articles' %>
```

`link_to` 是 Rails 内置的视图帮助方法之一，根据提供的文本和地址创建超链接。这上面这段代码中，地址是文章列表页面。

接下来添加到其他页面的链接。先在 `app/views/articles/index.html.erb` 中添加“New Article”链接，放在 `<table>` 标签之前：

```erb
<%= link_to 'New article', new_article_path %>
```

点击这个链接后，会转向新建文章的表单页面。

然后在 `app/views/articles/new.html.erb` 中添加一个链接，位于表单下面，返回到 `index` 动作：

```erb
<%= form_for :article do |f| %>
  ...
<% end %>

<%= link_to 'Back', articles_path %>
```

最后，在 `app/views/articles/show.html.erb` 模板中添加一个链接，返回 `index` 动作，这样用户查看某篇文章后就可以返回文章列表页面了：

```erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<%= link_to 'Back', articles_path %>
```

TIP: 如果要链接到同一个控制器中的动作，不用指定 `:controller` 选项，因为默认情况下使用的就是当前控制器。

TIP: 在开发模式下（默认），每次请求 Rails 都会重新加载程序，因此修改之后无需重启服务器。

### 添加数据验证

模型文件，比如 `app/models/article.rb`，可以简单到只有这两行代码：

```ruby
class Article < ActiveRecord::Base
end
```

文件中没有多少代码，不过请注意，`Article` 类继承自 `ActiveRecord::Base`。Active Record 提供了很多功能，包括：基本的数据库 CRUD 操作，数据验证，复杂的搜索功能，以及多个模型之间的关联。

Rails 为模型提供了很多方法，用来验证传入的数据。打开 `app/models/article.rb` 文件，修改成：

```ruby
class Article < ActiveRecord::Base
  validates :title, presence: true,
                    length: { minimum: 5 }
end
```

添加的这段代码可以确保每篇文章都有一个标题，而且至少有五个字符。在模型中可以验证数据是否满足多种条件，包括：字段是否存在、是否唯一，数据类型，以及关联对象是否存在。“[Active Record 数据验证](/active_record_validations.html)”一文会详细介绍数据验证。

添加数据验证后，如果把不满足验证条件的文章传递给 `@article.save`，会返回 `false`。打开 `app/controllers/articles_controller.rb` 文件，会发现，我们还没在 `create` 动作中检查 `@article.save` 的返回结果。如果保存失败，应该再次显示表单。为了实现这种功能，请打开 `app/controllers/articles_controller.rb` 文件，把 `new` 和 `create` 动作改成：

```ruby
def new
  @article = Article.new
end

def create
  @article = Article.new(article_params)

  if @article.save
    redirect_to @article
  else
    render 'new'
  end
end

private
  def article_params
    params.require(:article).permit(:title, :text)
  end
```

在 `new` 动作中添加了一个实例变量 `@article`。稍后你会知道为什么要这么做。

注意，在 `create` 动作中，如果保存失败，调用的是 `render` 方法而不是 `redirect_to` 方法。用 `render` 方法才能在保存失败后把 `@article` 对象传给 `new` 动作的视图。渲染操作和表单提交在同一次请求中完成；而 `redirect_to` 会让浏览器发起一次新请求。

刷新 <http://localhost:3000/articles/new>，提交一个没有标题的文章，Rails 会退回这个页面，但这种处理方法没多少用，你要告诉用户哪儿出错了。为了实现这种功能，请在 `app/views/articles/new.html.erb` 文件中检测错误消息：

```erb
<%= form_for :article, url: articles_path do |f| %>
  <% if @article.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@article.errors.count, "error") %> prohibited
      this article from being saved:</h2>
    <ul>
    <% @article.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
  <% end %>
  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>
  </p>

  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>

  <p>
    <%= f.submit %>
  </p>
<% end %>

<%= link_to 'Back', articles_path %>
```

我们添加了很多代码，使用 `@article.errors.any?` 检查是否有错误，如果有错误，使用 `@article.errors.full_messages` 显示错误。

`pluralize` 是 Rails 提供的帮助方法，接受一个数字和字符串作为参数。如果数字比 1 大，字符串会被转换成复数形式。

在 `new` 动作中加入 `@article = Article.new` 的原因是，如果不这么做，在视图中 `@article` 的值就是 `nil`，调用 `@article.errors.any?` 时会发生错误。

TIP: Rails 会自动把出错的表单字段包含在一个 `div` 中，并为其添加了一个 class：`field_with_errors`。我们可以定义一些样式，凸显出错的字段。

再次访问 <http://localhost:3000/articles/new>，尝试发布一篇没有标题的文章，会看到一个很有用的错误提示。

![出错的表单](images/getting_started/form_with_errors.png)

### 更新文章

我们已经说明了 CRUD 中的 CR 两种操作。下面进入 U 部分，更新文章。

首先，要在 `ArticlesController` 中添加 `edit` 动作：

```ruby
def edit
  @article = Article.find(params[:id])
end
```

视图中要添加一个类似新建文章的表单。新建 `app/views/articles/edit.html.erb` 文件，写入下面的代码：

```erb
<h1>Editing article</h1>

<%= form_for :article, url: article_path(@article), method: :patch do |f| %>
  <% if @article.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@article.errors.count, "error") %> prohibited
      this article from being saved:</h2>
    <ul>
    <% @article.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
  <% end %>
  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>
  </p>

  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>

  <p>
    <%= f.submit %>
  </p>
<% end %>

<%= link_to 'Back', articles_path %>
```

这里的表单指向 `update` 动作，现在还没定义，稍后会添加。

`method: :patch` 选项告诉 Rails，提交这个表单时使用 `PATCH` 方法发送请求。根据 REST 架构，更新资源时要使用 HTTP `PATCH` 方法。

`form_for` 的第一个参数可以是对象，例如 `@article`，把对象中的字段填入表单。如果传入一个和实例变量（`@article`）同名的 Symbol（`:article`），效果也是一样。上面的代码使用的就是 Symbol。详情参见 [form_for 的文档](http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_for)。

然后，要在 `app/controllers/articles_controller.rb` 中添加 `update` 动作：

```ruby
def update
  @article = Article.find(params[:id])

  if @article.update(article_params)
    redirect_to @article
  else
    render 'edit'
  end
end

private
  def article_params
    params.require(:article).permit(:title, :text)
  end
```

新定义的 `update` 方法用来处理对现有文章的更新操作，接收一个 Hash，包含想要修改的属性。和之前一样，如果更新文章出错了，要再次显示表单。

上面的代码再次使用了前面为 `create` 动作定义的 `article_params` 方法。

TIP: 不用把所有的属性都提供给 `update` 动作。例如，如果使用 `@article.update(title: 'A new title')`，Rails 只会更新 `title` 属性，不修改其他属性。

最后，我们想在文章列表页面，在每篇文章后面都加上一个链接，指向 `edit` 动作。打开 `app/views/articles/index.html.erb` 文件，在“Show”链接后面添加“Edit”链接：

```erb
<table>
  <tr>
    <th>Title</th>
    <th>Text</th>
    <th colspan="2"></th>
  </tr>

<% @articles.each do |article| %>
  <tr>
    <td><%= article.title %></td>
    <td><%= article.text %></td>
    <td><%= link_to 'Show', article_path(article) %></td>
    <td><%= link_to 'Edit', edit_article_path(article) %></td>
  </tr>
<% end %>
</table>
```

我们还要在 `app/views/articles/show.html.erb` 模板的底部加上“Edit”链接：

```erb
...

<%= link_to 'Back', articles_path %>
| <%= link_to 'Edit', edit_article_path(@article) %>
```

下图是文章列表页面现在的样子：

![在文章列表页面显示了编辑链接](images/getting_started/index_action_with_edit_link.png)

### 使用局部视图去掉视图中的重复代码

编辑文章页面和新建文章页面很相似，显示表单的代码是相同的。下面使用局部视图去掉两个视图中的重复代码。按照约定，局部视图的文件名以下划线开头。

TIP: 关于局部视图的详细介绍参阅“[Layouts and Rendering in Rails](/layouts_and_rendering.html)”一文。

新建 `app/views/articles/_form.html.erb` 文件，写入以下代码：

```erb
<%= form_for @article do |f| %>
  <% if @article.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@article.errors.count, "error") %> prohibited
      this article from being saved:</h2>
    <ul>
    <% @article.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
  <% end %>
  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>
  </p>

  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>

  <p>
    <%= f.submit %>
  </p>
<% end %>
```

除了第一行 `form_for` 的用法变了之外，其他代码都和之前一样。之所以能在两个动作中共用一个 `form_for`，是因为 `@article` 是一个资源，对应于符合 REST 架构的路由，Rails 能自动分辨使用哪个地址和请求方法。

关于这种 `form_for` 用法的详细说明，请查阅 [API 文档](http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_for-label-Resource-oriented+style)。

下面来修改 `app/views/articles/new.html.erb` 视图，使用新建的局部视图，把其中的代码全删掉，替换成：

```erb
<h1>New article</h1>

<%= render 'form' %>

<%= link_to 'Back', articles_path %>
```

然后按照同样地方法修改 `app/views/articles/edit.html.erb` 视图：

```erb
<h1>Edit article</h1>

<%= render 'form' %>

<%= link_to 'Back', articles_path %>
```

### 删除文章

现在介绍 CRUD 中的 D，从数据库中删除文章。按照 REST 架构的约定，删除文章的路由是：

```ruby
DELETE /articles/:id(.:format)      articles#destroy
```

删除资源时使用 DELETE 请求。如果还使用 GET 请求，可以构建如下所示的恶意地址：

```html
<a href='http://example.com/articles/1/destroy'>look at this cat!</a>
```

删除资源使用 DELETE 方法，路由会把请求发往 `app/controllers/articles_controller.rb` 中的 `destroy` 动作。`destroy` 动作现在还不存在，下面来添加：

```ruby
def destroy
  @article = Article.find(params[:id])
  @article.destroy

  redirect_to articles_path
end
```

想把记录从数据库删除，可以在 Active Record 对象上调用 `destroy` 方法。注意，我们无需为这个动作编写视图，因为它会转向 `index` 动作。

最后，在 `index` 动作的模板（`app/views/articles/index.html.erb`）中加上“Destroy”链接：

```erb
<h1>Listing Articles</h1>
<%= link_to 'New article', new_article_path %>
<table>
  <tr>
    <th>Title</th>
    <th>Text</th>
    <th colspan="3"></th>
  </tr>

<% @articles.each do |article| %>
  <tr>
    <td><%= article.title %></td>
    <td><%= article.text %></td>
    <td><%= link_to 'Show', article_path(article) %></td>
    <td><%= link_to 'Edit', edit_article_path(article) %></td>
    <td><%= link_to 'Destroy', article_path(article),
                    method: :delete, data: { confirm: 'Are you sure?' } %></td>
  </tr>
<% end %>
</table>
```

生成“Destroy”链接的 `link_to` 用法有点不一样，第二个参数是具名路由，随后还传入了几个参数。`:method` 和 `:'data-confirm'` 选项设置链接的 HTML5 属性，点击链接后，首先会显示一个对话框，然后发起 DELETE 请求。这两个操作通过 `jquery_ujs` 这个 JavaScript 脚本实现。生成程序骨架时，会自动把 `jquery_ujs` 加入程序的布局中（`app/views/layouts/application.html.erb`）。没有这个脚本，就不会显示确认对话框。

![确认对话框](images/getting_started/confirm_dialog.png)

恭喜，现在你可以新建、显示、列出、更新、删除文章了。

TIP: 一般情况下，Rails 建议使用资源对象，而不手动设置路由。关于路由的详细介绍参阅“[Rails 路由全解](/routing.html)”一文。

添加第二个模型
------------

接下来要在程序中添加第二个模型，用来处理文章的评论。

### 生成模型

下面要用到的生成器，和之前生成 `Article` 模型的一样。我们要创建一个 `Comment` 模型，表示文章的评论。在终端执行下面的命令：

```bash
$ rails generate model Comment commenter:string body:text article:references
```

这个命令生成四个文件：

| 文件                                         | 作用                                                |
|----------------------------------------------|----------------------------------------------------|
| db/migrate/20140120201010_create_comments.rb | 生成 comments 表所用的迁移文件（你得到的文件名稍有不同） |
| app/models/comment.rb                        | Comment 模型文件                                    |
| test/models/comment_test.rb                  | Comment 模型的测试文件                               |
| test/fixtures/comments.yml                   | 测试时使用的固件                                  |

首先来看一下 `app/models/comment.rb` 文件：

```ruby
class Comment < ActiveRecord::Base
  belongs_to :article
end
```

文件的内容和前面的 `Article` 模型差不多，不过多了一行代码：`belongs_to :article`。这行代码用来建立 Active Record 关联。下文会简单介绍关联。

除了模型文件，Rails 还生成了一个迁移文件，用来创建对应的数据表：

```ruby
class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string :commenter
      t.text :body

      # this line adds an integer column called `article_id`.
      t.references :article, index: true

      t.timestamps
    end
  end
end
```

`t.references` 这行代码为两个模型的关联创建一个外键字段，同时还为这个字段创建了索引。下面运行这个迁移：

```bash
$ rake db:migrate
```

Rails 相当智能，只会执行还没有运行的迁移，在命令行中会看到以下输出：

```bash
==  CreateComments: migrating =================================================
-- create_table(:comments)
   -> 0.0115s
==  CreateComments: migrated (0.0119s) ========================================
```

### 模型关联

使用 Active Record 关联可以轻易的建立两个模型之间的关系。评论和文章之间的关联是这样的：

* 评论属于一篇文章
* 一篇文章有多个评论

这种关系和 Rails 用来声明关联的句法具有相同的逻辑。我们已经看过 `Comment` 模型中那行代码，声明评论属于文章：

```ruby
class Comment < ActiveRecord::Base
  belongs_to :article
end
```

我们要编辑 `app/models/article.rb` 文件，加入这层关系的另一端：

```ruby
class Article < ActiveRecord::Base
  has_many :comments
  validates :title, presence: true,
                    length: { minimum: 5 }
end
```

这两行声明能自动完成很多操作。例如，如果实例变量 `@article` 是一个文章对象，可以使用 `@article.comments` 取回一个数组，其元素是这篇文章的评论。

TIP: 关于 Active Record 关联的详细介绍，参阅“[Active Record 关联](/association_basics.html)”一文。

### 添加评论的路由

和 `article` 控制器一样，添加路由后 Rails 才知道在哪个地址上查看评论。打开 `config/routes.rb` 文件，按照下面的方式修改：

```ruby
resources :articles do
  resources :comments
end
```

我们把 `comments` 放在 `articles` 中，这叫做嵌套资源，表明了文章和评论间的层级关系。

TIP: 关于路由的详细介绍，参阅“[Rails 路由全解](/routing.html)”一文。

### 生成控制器

有了模型，下面要创建控制器了，还是使用前面用过的生成器：

```bash
$ rails generate controller Comments
```

这个命令生成六个文件和一个空文件夹：

| 文件/文件夹                                   | 作用                                      |
| -------------------------------------------- | ---------------------------------------- |
| app/controllers/comments_controller.rb       | Comments 控制器文件                       |
| app/views/comments/                          | 控制器的视图存放在这个文件夹里               |
| test/controllers/comments_controller_test.rb | 控制器测试文件                             |
| app/helpers/comments_helper.rb               | 视图帮助方法文件                           |
| test/helpers/comments_helper_test.rb         | 帮助方法测试文件                           |
| app/assets/javascripts/comment.js.coffee     | 控制器的 CoffeeScript 文件                |
| app/assets/stylesheets/comment.css.scss      | 控制器的样式表文件                         |

在任何一个博客中，读者读完文章后就可以发布评论。评论发布后，会转向文章显示页面，查看自己的评论是否显示出来了。所以，`CommentsController` 中要定义新建评论的和删除垃圾评论的方法。

首先，修改显示文章的模板（`app/views/articles/show.html.erb`），允许读者发布评论：

```erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<h2>Add a comment:</h2>
<%= form_for([@article, @article.comments.build]) do |f| %>
  <p>
    <%= f.label :commenter %><br>
    <%= f.text_field :commenter %>
  </p>
  <p>
    <%= f.label :body %><br>
    <%= f.text_area :body %>
  </p>
  <p>
    <%= f.submit %>
  </p>
<% end %>

<%= link_to 'Back', articles_path %>
| <%= link_to 'Edit', edit_article_path(@article) %>
```

上面的代码在显示文章的页面添加了一个表单，调用 `CommentsController` 控制器的 `create` 动作发布评论。`form_for` 的参数是个数组，构建嵌套路由，例如 `/articles/1/comments`。

下面在 `app/controllers/comments_controller.rb` 文件中定义 `create` 方法：

```ruby
class CommentsController < ApplicationController
  def create
    @article = Article.find(params[:article_id])
    @comment = @article.comments.create(comment_params)
    redirect_to article_path(@article)
  end

  private
    def comment_params
      params.require(:comment).permit(:commenter, :body)
    end
end
```

这里使用的代码要比文章的控制器复杂得多，因为设置了嵌套关系，必须这么做评论功能才能使用。发布评论时要知道这个评论属于哪篇文章，所以要在 `Article` 模型上调用 `find` 方法查找文章对象。

而且，这段代码还充分利用了关联关系生成的方法。我们在 `@article.comments` 上调用 `create` 方法，创建并保存评论。这么做能自动把评论和文章联系起来，让这个评论属于这篇文章。

添加评论后，调用 `article_path(@article)` 帮助方法，转向原来的文章页面。前面说过，这个帮助函数调用 `ArticlesController` 的 `show` 动作，渲染 `show.html.erb` 模板。我们要在这个模板中显示评论，所以要修改一下 `app/views/articles/show.html.erb`：

```erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<h2>Comments</h2>
<% @article.comments.each do |comment| %>
  <p>
    <strong>Commenter:</strong>
    <%= comment.commenter %>
  </p>

  <p>
    <strong>Comment:</strong>
    <%= comment.body %>
  </p>
<% end %>

<h2>Add a comment:</h2>
<%= form_for([@article, @article.comments.build]) do |f| %>
  <p>
    <%= f.label :commenter %><br>
    <%= f.text_field :commenter %>
  </p>
  <p>
    <%= f.label :body %><br>
    <%= f.text_area :body %>
  </p>
  <p>
    <%= f.submit %>
  </p>
<% end %>

<%= link_to 'Edit Article', edit_article_path(@article) %> |
<%= link_to 'Back to Articles', articles_path %>
```

现在，可以为文章添加评论了，成功添加后，评论会在正确的位置显示。

![文章的评论](images/getting_started/article_with_comments.png)

重构
----

现在博客的文章和评论都能正常使用了。看一下 `app/views/articles/show.html.erb` 模板，内容太多。下面使用局部视图重构。

### 渲染局部视图中的集合

首先，把显示文章评论的代码抽出来，写入局部视图中。新建 `app/views/comments/_comment.html.erb` 文件，写入下面的代码：

```erb
<p>
  <strong>Commenter:</strong>
  <%= comment.commenter %>
</p>

<p>
  <strong>Comment:</strong>
  <%= comment.body %>
</p>
```

然后把 `app/views/articles/show.html.erb` 修改成：

```erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<h2>Comments</h2>
<%= render @article.comments %>

<h2>Add a comment:</h2>
<%= form_for([@article, @article.comments.build]) do |f| %>
  <p>
    <%= f.label :commenter %><br>
    <%= f.text_field :commenter %>
  </p>
  <p>
    <%= f.label :body %><br>
    <%= f.text_area :body %>
  </p>
  <p>
    <%= f.submit %>
  </p>
<% end %>

<%= link_to 'Edit Article', edit_article_path(@article) %> |
<%= link_to 'Back to Articles', articles_path %>
```

这个视图会使用局部视图 `app/views/comments/_comment.html.erb` 渲染 `@article.comments` 集合中的每个评论。`render` 方法会遍历 `@article.comments` 集合，把每个评论赋值给一个和局部视图同名的本地变量，在这个例子中本地变量是 `comment`，这个本地变量可以在局部视图中使用。

### 渲染局部视图中的表单

我们把添加评论的代码也移到局部视图中。新建 `app/views/comments/_form.html.erb` 文件，写入：

```erb
<%= form_for([@article, @article.comments.build]) do |f| %>
  <p>
    <%= f.label :commenter %><br>
    <%= f.text_field :commenter %>
  </p>
  <p>
    <%= f.label :body %><br>
    <%= f.text_area :body %>
  </p>
  <p>
    <%= f.submit %>
  </p>
<% end %>
```

然后把 `app/views/articles/show.html.erb` 改成：

```erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<h2>Comments</h2>
<%= render @article.comments %>

<h2>Add a comment:</h2>
<%= render "comments/form" %>

<%= link_to 'Edit Article', edit_article_path(@article) %> |
<%= link_to 'Back to Articles', articles_path %>
```

第二个 `render` 方法的参数就是要渲染的局部视图，即 `comments/form`。Rails 很智能，能解析其中的斜线，知道要渲染 `app/views/comments` 文件夹中的 `_form.html.erb` 模板。

`@article` 变量在所有局部视图中都可使用，因为它是实例变量。

删除评论
-------

博客还有一个重要的功能是删除垃圾评论。为了实现这个功能，要在视图中添加一个连接，并在 `CommentsController` 中定义 `destroy` 动作。

先在 `app/views/comments/_comment.html.erb` 局部视图中加入删除评论的链接：

```erb
<p>
  <strong>Commenter:</strong>
  <%= comment.commenter %>
</p>

<p>
  <strong>Comment:</strong>
  <%= comment.body %>
</p>

<p>
  <%= link_to 'Destroy Comment', [comment.article, comment],
               method: :delete,
               data: { confirm: 'Are you sure?' } %>
</p>
```

点击“Destroy Comment”链接后，会向 `CommentsController` 控制器发起 `DELETE /articles/:article_id/comments/:id` 请求。我们可以从这个请求中找到要删除的评论。下面在控制器中加入 `destroy` 动作（`app/controllers/comments_controller.rb`）：

```ruby
class CommentsController < ApplicationController
  def create
    @article = Article.find(params[:article_id])
    @comment = @article.comments.create(comment_params)
    redirect_to article_path(@article)
  end

  def destroy
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])
    @comment.destroy
    redirect_to article_path(@article)
  end

  private
    def comment_params
      params.require(:comment).permit(:commenter, :body)
    end
end
```

`destroy` 动作先查找当前文章，然后在 `@article.comments` 集合中找到对应的评论，将其从数据库中删掉，最后转向显示文章的页面。

### 删除关联对象

如果删除一篇文章，也要删除文章中的评论，不然这些评论会占用数据库空间。在 Rails 中可以在关联中指定 `dependent` 选项达到这一目的。把 `Article` 模型（`app/models/article.rb`）修改成：

```ruby
class Article < ActiveRecord::Base
  has_many :comments, dependent: :destroy
  validates :title, presence: true,
                    length: { minimum: 5 }
end
```

安全
----

### 基本认证

如果把这个博客程序放在网上，所有人都能添加、编辑、删除文章和评论。

Rails 提供了一种简单的 HTTP 身份认证机制可以避免出现这种情况。

在 `ArticlesController` 中，我们要用一种方法禁止未通过认证的用户访问其中几个动作。我们需要的是 `http_basic_authenticate_with` 方法，通过这个方法的认证后才能访问所请求的动作。

要使用这个身份认证机制，需要在 `ArticlesController` 控制器的顶部调用 `http_basic_authenticate_with` 方法。除了 `index` 和 `show` 动作，访问其他动作都要通过认证，所以在 `app/controllers/articles_controller.rb` 中，要这么做：

```ruby
class ArticlesController < ApplicationController

  http_basic_authenticate_with name: "dhh", password: "secret", except: [:index, :show]

  def index
    @articles = Article.all
  end

  # snipped for brevity
```

同时，我们还希望只有通过认证的用户才能删除评论。修改 `CommentsController` 控制器（`app/controllers/comments_controller.rb`）：

```ruby
class CommentsController < ApplicationController

  http_basic_authenticate_with name: "dhh", password: "secret", only: :destroy

  def create
    @article = Article.find(params[:article_id])
    ...
  end

  # snipped for brevity
```

现在，如果想新建文章，会看到一个 HTTP 基本认证对话框。

![HTTP 基本认证对话框](images/getting_started/challenge.png)

其他的身份认证方法也可以在 Rails 程序中使用。其中两个比较流行的是 [Devise](https://github.com/plataformatec/devise) 引擎和 [Authlogic](https://github.com/binarylogic/authlogic) gem。

### 其他安全注意事项

安全，尤其是在网页程序中，是个很宽泛和值得深入研究的领域。Rails 程序的安全措施，在“[Ruby on Rails 安全指南](/security.html)”中有更深入的说明。

接下来做什么
-----------

至此，我们开发了第一个 Rails 程序，请尽情的修改、试验。在开发过程中难免会需要帮助，如果使用 Rails 时需要协助，可以使用这些资源：

* [Ruby on Rails 指南]({{ site.baseurl}}/index.html)
* [Ruby on Rails 教程](http://railstutorial-china.org/)
* [Ruby on Rails 邮件列表](http://groups.google.com/group/rubyonrails-talk)
* irc.freenode.net 上的 [#rubyonrails](irc://irc.freenode.net/#rubyonrails) 频道

Rails 本身也提供了帮助文档，可以使用下面的 rake 任务生成：

* 运行 `rake doc:guides`，会在程序的 `doc/guides` 文件夹中生成一份 Rails 指南。在浏览器中打开 `doc/guides/index.html` 可以查看这份指南。
* 运行 `rake doc:rails`，会在程序的 `doc/api` 文件夹中生成一份完整的 API 文档。在浏览器中打开 `doc/api/index.html` 可以查看 API 文档。

TIP: 使用 `doc:guides` 任务在本地生成 Rails 指南，要安装 RedCloth gem。在 `Gemfile` 中加入这个 gem，然后执行 `bundle install` 命令即可。

常见问题
-------

使用 Rails 时，最好使用 UTF-8 编码存储所有外部数据。如果没使用 UTF-8 编码，Ruby 的代码库和 Rails 一般都能将其转换成 UTF-8，但不一定总能成功，所以最好还是确保所有的外部数据都使用 UTF-8 编码。

如果编码出错，常见的征兆是浏览器中显示很多黑色方块和问号。还有一种常见的符号是“Ã¼”，包含在“ü”中。Rails 内部采用很多方法尽量避免出现这种问题。如果你使用的外部数据编码不是 UTF-8，有时会出现这些问题，Rails 无法自动纠正。

非 UTF-8 编码的数据经常来源于：

* 你的文本编辑器：大多数文本编辑器（例如 TextMate）默认使用 UTF-8 编码保存文件。如果你的编辑器没使用 UTF-8 编码，有可能是你在模板中输入了特殊字符（例如 é），在浏览器中显示为方块和问号。这种问题也会出现在国际化文件中。默认不使用 UTF-8 保存文件的编辑器（例如 Dreamweaver 的某些版本）都会提供一种方法，把默认编码设为 UTF-8。记得要修改。
* 你的数据库：默认情况下，Rails 会把从数据库中取出的数据转换成 UTF-8 格式。如果数据库内部不使用 UTF-8 编码，就无法保存用户输入的所有字符。例如，数据库内部使用 Latin-1 编码，用户输入俄语、希伯来语或日语字符时，存进数据库时就会永远丢失。如果可能，在数据库中尽量使用 UTF-8 编码。
