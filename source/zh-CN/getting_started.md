Rails 入门
==========

本文介绍如何开始使用 Ruby on Rails。

读完本文后，您将学到：

- 如何安装 Rails、创建 Rails 应用，如何连接数据库；

- Rails 应用的基本文件结构；

- MVC（模型、视图、控制器）和 REST 架构的基本原理；

- 如何快速生成 Rails 应用骨架。

--------------------------------------------------------------------------------

前提条件
--------

本文针对想从零开始开发 Rails 应用的初学者，不要求 Rails 使用经验。不过，为了能顺利阅读，还是需要事先安装好一些软件：

- [Ruby](https://www.ruby-lang.org/en/downloads) 2.2.2 及以上版本

- [开发工具包](http://rubyinstaller.org/downloads/)的正确版本（针对 Windows 用户）

- 包管理工具 [RubyGems](https://rubygems.org/)，随 Ruby 预装。若想深入了解 RubyGems，请参阅 [RubyGems 指南](http://guides.rubygems.org/)

- [SQLite3 数据库](https://www.sqlite.org/)

Rails 是使用 Ruby 语言开发的 Web 应用框架。如果之前没接触过 Ruby，会感到直接学习 Rails 的学习曲线很陡。这里提供几个学习 Ruby 的在线资源：

- [Ruby 语言官方网站](https://www.ruby-lang.org/en/documentation/)

- [免费编程图书列表](https://github.com/vhf/free-programming-books/blob/master/free-programming-books.md#ruby)

需要注意的是，有些资源虽然很好，但针对的是 Ruby 1.8 甚至 1.6 这些老版本，因此不涉及一些 Rails 日常开发的常见句法。

Rails 是什么？
--------------

Rails 是使用 Ruby 语言编写的 Web 应用开发框架，目的是通过解决快速开发中的共通问题，简化 Web 应用的开发。与其他编程语言和框架相比，使用 Rails 只需编写更少代码就能实现更多功能。有经验的 Rails 程序员常说，Rails 让 Web 应用开发变得更有趣。

Rails 有自己的设计原则，认为问题总有最好的解决方法，并且有意识地通过设计来鼓励用户使用最好的解决方法，而不是其他替代方案。一旦掌握了“Rails 之道”，就可能获得生产力的巨大提升。在 Rails 开发中，如果不改变使用其他编程语言时养成的习惯，总想使用原有的设计模式，开发体验可能就不那么让人愉快了。

Rails 哲学包含两大指导思想：

- 不要自我重复（DRY）： DRY 是软件开发中的一个原则，意思是“系统中的每个功能都要具有单一、准确、可信的实现。”。不重复表述同一件事，写出的代码才更易维护、更具扩展性，也更不容易出问题。

- 多约定，少配置： Rails 为 Web 应用的大多数需求都提供了最好的解决方法，并且默认使用这些约定，而不是在长长的配置文件中设置每个细节。

创建 Rails 项目
---------------

阅读本文的最佳方法是一步步跟着操作。所有这些步骤对于运行示例应用都是必不可少的，同时也不需要更多的代码或步骤。

通过学习本文，你将学会如何创建一个名为 Blog 的 Rails 项目，这是一个非常简单的博客。在动手开发之前，请确保已经安装了 Rails。

TIP: 文中的示例代码使用 UNIX 风格的命令行提示符 $，如果你的命令行提示符是自定义的，看起来可能会不一样。在 Windows 中，命令行提示符可能类似 `c:\source_code>`。

### 安装 Rails

打开命令行：在 Mac OS X 中打开 Terminal.app，在 Windows 中要在开始菜单中选择“运行”，然后输入“cmd.exe”。本文中所有以 $ 开头的代码，都应该在命令行中执行。首先确认是否安装了 Ruby 的最新版本：

```sh
$ ruby -v
ruby 2.3.0p0
```

TIP: 有很多工具可以帮助你快速地在系统中安装 Ruby 和 Ruby on Rails。Windows 用户可以使用 [Rails Installer](http://railsinstaller.org/)，Mac OS X 用户可以使用 [Tokaido](https://github.com/tokaido/tokaidoapp)。更多操作系统中的安装方法请访问 [ruby-lang.org](https://www.ruby-lang.org/en/documentation/installation/)。

很多类 UNIX 系统都预装了版本较新的 SQLite3。在 Windows 中，通过 Rails Installer 安装 Rails 会同时安装 SQLite3。其他操作系统中 SQLite3 的安装方法请参阅 [SQLite3 官网](https://www.sqlite.org/)。接下来，确认 SQLite3 是否在 PATH 中：

```sh
$ sqlite3 --version
```

执行结果应该显示 SQLite3 的版本号。

安装 Rails，请使用 RubyGems 提供的 `gem install` 命令：

```sh
$ gem install rails
```

执行下面的命令来确认所有软件是否都已正确安装：

```sh
$ rails --version
```

如果执行结果类似 `Rails 5.0.0`，那么就可以继续往下读了。

### 创建 Blog 应用

Rails 提供了许多名为“生成器”（generator）的脚本，这些脚本可以为特定任务生成所需的全部文件，从而简化开发。其中包括新应用生成器，这个脚本用于创建 Rails 应用骨架，避免了手动编写基础代码。

要使用新应用生成器，请打开终端，进入具有写权限的文件夹，输入：

```sh
$ rails new blog
```

这个命令会在文件夹 `blog` 中创建名为 Blog 的 Rails 应用，然后执行 `bundle install` 命令安装 Gemfile 中列出的 gem 及其依赖。

TIP: 执行 `rails new -h` 命令可以查看新应用生成器的所有命令行选项。

创建 blog 应用后，进入该文件夹：

```sh
$ cd blog
```

`blog` 文件夹中有许多自动生成的文件和文件夹，这些文件和文件夹组成了 Rails 应用的结构。本文涉及的大部分工作都在 app 文件夹中完成。下面简单介绍一下这些用新应用生成器默认选项生成的文件和文件夹的功能：

| 文件/文件夹 | 作用 |
|--------|----|
| app/ | 包含应用的控制器、模型、视图、辅助方法、邮件程序和静态资源文件。这个文件夹是本文剩余内容关注的重点。 |
| bin/ | 包含用于启动应用的 rails 脚本，以及用于安装、更新、部署或运行应用的其他脚本。 |
| config/ | 配置应用的路由、数据库等。详情请参阅configuring.xml。 |
| config.ru | 基于 Rack 的服务器所需的 Rack 配置，用于启动应用。 |
| db/ | 包含当前数据库的模式，以及数据库迁移文件。 |
| Gemfile, Gemfile.lock | 这两个文件用于指定 Rails 应用所需的 gem 依赖。Bundler gem 需要用到这两个文件。关于 Bundler 的更多介绍，请访问 Bundler 官网。 |
| lib/ | 应用的扩展模块。 |
| log/ | 应用日志文件。 |
| public/ | 仅有的可以直接从外部访问的文件夹，包含静态文件和编译后的静态资源文件。 |
| Rakefile | 定位并加载可在命令行中执行的任务。这些任务在 Rails 的各个组件中定义。如果要添加自定义任务，请不要修改 Rakefile，真接把自定义任务保存在 lib/tasks 文件夹中即可。 |
| README.md | 应用的自述文件，说明应用的用途、安装方法等。 |
| test/ | 单元测试、固件和其他测试装置。详情请参阅testing.xml。 |
| tmp/ | 临时文件（如缓存和 PID 文件）。 |
| vendor/ | 包含第三方代码，如第三方 gem。 |

Hello, Rails!
-------------

首先，让我们快速地在页面中添加一些文字。为了访问页面，需要运行 Rails 应用服务器（即 Web 服务器）。

### 启动 Web 服务器

实际上这个 Rails 应用已经可以正常运行了。要访问应用，需要在开发设备中启动 Web 服务器。请在 `blog` 文件夹中执行下面的命令：

```sh
$ bin/rails server
```

TIP: Windows 用户需要把 `bin` 文件夹下的脚本文件直接传递给 Ruby 解析器，例如 `ruby bin\rails server`。

TIP: 编译 CoffeeScript 和压缩 JavaScript 静态资源文件需要 JavaScript 运行时，如果没有运行时，在压缩静态资源文件时会报错，提示没有 `execjs`。Mac OS X 和 Windows 一般都提供了 JavaScript 运行时。在 Rails 应用的 Gemfile 中，`therubyracer` gem 被注释掉了，如果需要使用这个 gem，请去掉注释。对于 JRuby 用户，推荐使用 `therubyrhino` 这个运行时，在 JRuby 中创建 Rails 应用的 Gemfile 中默认包含了这个 gem。要查看 Rails 支持的所有运行时，请参阅 [ExecJS](https://github.com/rails/execjs#readme)。

上述命令会启动 Puma，这是 Rails 默认使用的 Web 服务器。要查看运行中的应用，请打开浏览器窗口，访问 <http://localhost:3000>。这时应该看到默认的 Rails 欢迎页面：

![默认的 Rails 欢迎页面](images/getting_started/rails_welcome.png)

TIP: 要停止 Web 服务器，请在终端中按 Ctrl+C 键。服务器停止后命令行提示符会重新出现。在大多数类 Unix 系统中，包括 Mac OS X，命令行提示符是 $ 符号。在开发模式中，一般情况下无需重启服务器，服务器会自动加载修改后的文件。

欢迎页面是创建 Rails 应用的冒烟测试，看到这个页面就表示应用已经正确配置，能够正常工作了。

### 显示“Hello, Rails!”

要让 Rails 显示“Hello, Rails!”，需要创建控制器和视图。

控制器接受向应用发起的特定访问请求。路由决定哪些访问请求被哪些控制器接收。一般情况下，一个控制器会对应多个路由，不同路由对应不同动作。动作搜集数据并把数据提供给视图。

视图以人类能看懂的格式显示数据。有一点要特别注意，数据是在控制器而不是视图中获取的，视图只是显示数据。默认情况下，视图模板使用 eRuby（嵌入式 Ruby）语言编写，经由 Rails 解析后，再发送给用户。

可以用控制器生成器来创建控制器。下面的命令告诉控制器生成器创建一个包含“index”动作的“Welcome”控制器：

```sh
$ bin/rails generate controller Welcome index
```

上述命令让 Rails 生成了多个文件和一个路由：

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
    create      app/assets/javascripts/welcome.coffee
    invoke    scss
    create      app/assets/stylesheets/welcome.scss

其中最重要的文件是控制器和视图，控制器位于 `app/controllers/welcome_controller.rb` 文件 ，视图位于 `app/views/welcome/index.html.erb` 文件 。

在文本编辑器中打开 `app/views/welcome/index.html.erb` 文件，删除所有代码，然后添加下面的代码：

```html
<h1>Hello, Rails!</h1>
```

### 设置应用主页

现在我们已经创建了控制器和视图，还需要告诉 Rails 何时显示“Hello, Rails!”，我们希望在访问根地址 <http://localhost:3000> 时显示。目前根地址显示的还是默认的 Rails 欢迎页面。

接下来需要告诉 Rails 真正的主页在哪里。

在编辑器中打开 `config/routes.rb` 文件。

```ruby
Rails.application.routes.draw do
  get 'welcome/index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
```

这是应用的路由文件，使用特殊的 DSL（domain-specific language，领域专属语言）编写，告诉 Rails 把访问请求发往哪个控制器和动作。编辑这个文件，添加一行代码 `root 'welcome#index'`，此时文件内容应该变成下面这样：

```ruby
Rails.application.routes.draw do
  get 'welcome/index'

  root 'welcome#index'
end
```

`root 'welcome#index'` 告诉 Rails 对根路径的访问请求应该发往 welcome 控制器的 index 动作，`get 'welcome/index'` 告诉 Rails 对 <http://localhost:3000/welcome/index> 的访问请求应该发往 welcome 控制器的 index 动作。后者是之前使用控制器生成器创建控制器（`bin/rails generate controller Welcome index`）时自动生成的。

如果在生成控制器时停止了服务器，请再次启动服务器（`bin/rails server`），然后在浏览器中访问 <http://localhost:3000>。我们会看到之前添加到 `app/views/welcome/index.html.erb` 文件 的“Hello, Rails!”信息，这说明新定义的路由确实把访问请求发往了 `WelcomeController` 的 `index` 动作，并正确渲染了视图。

TIP: 关于路由的更多介绍，请参阅[Rails 路由全解](routing.html)。

启动并运行起来
--------------

前文已经介绍了如何创建控制器、动作和视图，接下来我们要创建一些更具实用价值的东西。

在 Blog 应用中创建一个资源（resource）。资源是一个术语，表示一系列类似对象的集合，如文章、人或动物。资源中的项目可以被创建、读取、更新和删除，这些操作简称 CRUD（Create, Read, Update, Delete）。

Rails 提供了 `resources` 方法，用于声明标准的 REST 资源。把 article 资源添加到 `config/routes.rb` 文件，此时文件内容应该变成下面这样：

```ruby
Rails.application.routes.draw do

  resources :articles

  root 'welcome#index'
end
```

执行 `bin/rails routes` 命令，可以看到所有标准 REST 动作都具有对应的路由。输出结果中各列的意义稍后会作说明，现在只需注意 Rails 从 article 的单数形式推导出了它的复数形式，并进行了合理使用。

```sh
$ bin/rails routes
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

下一节，我们将为应用添加新建文章和查看文章的功能。这两个操作分别对应于 CRUD 的“C”和“R”：创建和读取。下面是用于新建文章的表单：

![用于新建文章的表单](images/getting_started/new_article.png)

表单看起来很简陋，不过没关系，之后我们再来美化。

### 打地基

首先，应用需要一个页面用于新建文章，`/articles/new` 是个不错的选择。相关路由之前已经定义过了，可以直接访问。打开 <http://localhost:3000/articles/new>，会看到下面的路由错误：

![路由错误，常量 ArticlesController 未初始化](images/getting_started/routing_error_no_controller.png)

产生错误的原因是，用于处理该请求的控制器还没有定义。解决问题的方法很简单：创建 `Articles` 控制器。执行下面的命令：

```sh
$ bin/rails generate controller Articles
```

打开刚刚生成的 `app/controllers/articles_controller.rb` 文件，会看到一个空的控制器：

```ruby
class ArticlesController < ApplicationController
end
```

控制器实际上只是一个继承自 `ApplicationController` 的类。接在来要在这个类中定义的方法也就是控制器的动作。这些动作对文章执行 CRUD 操作。

NOTE: 在 Ruby 中，有 `public`、`private` 和 `protected` 三种方法，其中只有 `public` 方法才能作为控制器的动作。详情请参阅 [Programming Ruby](http://www.ruby-doc.org/docs/ProgrammingRuby/) 一书。

现在刷新 <http://localhost:3000/articles/new>，会看到一个新错误：

![未知动作，在 ArticlesController 中找不到 new 动作](images/getting_started/unknown_action_new_for_articles.png)

这个错误的意思是，Rails 在刚刚生成的 `ArticlesController` 中找不到 new 动作。这是因为在 Rails 中生成控制器时，如果不指定想要的动作，生成的控制器就会是空的。

在控制器中手动定义动作，只需要定义一个新方法。打开 `app/controllers/articles_controller.rb` 文件，在 `ArticlesController` 类中定义 `new` 方法，此时控制器应该变成下面这样：

```ruby
class ArticlesController < ApplicationController
  def new
  end
end
```

在 `ArticlesController` 中定义 `new` 方法后，再次刷新 <http://localhost:3000/articles/new>，会看到另一个错误：

![未知格式，缺少对应模板](images/getting_started/template_is_missing_articles_new.png)

产生错误的原因是，Rails 要求这样的常规动作有用于显示数据的对应视图。如果没有视图可用，Rails 就会抛出异常。

上图中下面的几行都被截断了，下面是完整信息：

> ArticlesController\#new is missing a template for this request format and variant. request.formats: \["text/html"\] request.variant: \[\] NOTE! For XHR/Ajax or API requests, this action would normally respond with 204 No Content: an empty white screen. Since you’re loading it in a web browser, we assume that you expected to actually render a template, not… nothing, so we’re showing an error to be extra-clear. If you expect 204 No Content, carry on. That’s what you’ll get from an XHR or API request. Give it a shot.

内容还真不少！让我们快速浏览一下，看看各部分是什么意思。

第一部分说明缺少哪个模板，这里缺少的是 `articles/new` 模板。Rails 首先查找这个模板，如果找不到再查找 `application/new` 模板。之所以会查找后面这个模板，是因为 `ArticlesController` 继承自 `ApplicationController`。

下一部分是 `request.formats`，说明响应使用的模板格式。当我们在浏览器中请求页面时，`request.formats` 的值是 `text/html`，因此 Rails 会查找 HTML 模板。`request.variants` 指明伺服的是何种物理设备，帮助 Rails 判断该使用哪个模板渲染响应。它的值是空的，因为没有为其提供信息。

在本例中，能够工作的最简单的模板位于 `app/views/articles/new.html.erb` 文件中。文件的扩展名很重要：第一个扩展名是模板格式，第二个扩展名是模板处理器。Rails 会尝试在 `app/views` 文件夹中查找 `articles/new` 模板。这个模板的格式只能是 `html`，模板处理器只能是 `erb`、`builder` 和 `coffee` 中的一个。`:erb` 是最常用的 HTML 模板处理器，`:builder` 是 XML 模板处理器，`:coffee` 模板处理器用 CoffeeScript 创建 JavaScript 模板。因为我们要创建 HTML 表单，所以应该使用能够在 HTML 中嵌入 Ruby 的 `ERB` 语言。

所以我们需要创建 `articles/new.html.erb` 文件，并把它放在应用的 `app/views` 文件夹中。

现在让我们继续前进。新建 `app/views/articles/new.html.erb` 文件，添加下面的代码：

```erb
<h1>New Article</h1>
```

刷新 <http://localhost:3000/articles/new>，会看到页面有了标题。现在路由、控制器、动作和视图都可以协调地工作了！是时候创建用于新建文章的表单了。

### 第一个表单

在模板中创建表单，可以使用表单构建器。Rails 中最常用的表单构建器是 `form_for` 辅助方法。让我们使用这个方法，在 `app/views/articles/new.html.erb` 文件中添加下面的代码：

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

现在刷新页面，会看到和前文截图一样的表单。在 Rails 中创建表单就是这么简单！

调用 `form_for` 辅助方法时，需要为表单传递一个标识对象作为参数，这里是 `:article` 符号。这个符号告诉 `form_for` 辅助方法表单用于处理哪个对象。在 `form_for` 辅助方法的块中，`f` 表示 `FormBuilder` 对象，用于创建两个标签和两个文本字段，分别用于添加文章的标题和正文。最后在 `f` 对象上调用 `submit` 方法来为表单创建提交按钮。

不过这个表单还有一个问题，查看 HTML 源代码会看到表单 `action` 属性的值是 `/articles/new`，指向的是当前页面，而当前页面只是用于显示新建文章的表单。

应该把表单指向其他 URL，为此可以使用 `form_for` 辅助方法的 `:url` 选项。在 Rails 中习惯用 `create` 动作来处理提交的表单，因此应该把表单指向这个动作。

修改 `app/views/articles/new.html.erb` 文件的 `form_for` 这一行，改为：

```erb
<%= form_for :article, url: articles_path do |f| %>
```

这里我们把 `articles_path` 辅助方法传递给 `:url` 选项。要想知道这个方法有什么用，我们可以回过头看一下 `bin/rails routes` 的输出结果：

```sh
$ bin/rails routes
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

`articles_path` 辅助方法告诉 Rails 把表单指向和 `articles` 前缀相关联的 URI 模式。默认情况下，表单会向这个路由发起 `POST` 请求。这个路由和当前控制器 `ArticlesController` 的 `create` 动作相关联。

有了表单和与之相关联的路由，我们现在可以填写表单，然后点击提交按钮来新建文章了，请实际操作一下。提交表单后，会看到一个熟悉的错误：

![未知动作，在 `ArticlesController` 中找不到 `create` 动作](images/getting_started/unknown_action_create_for_articles.png)

解决问题的方法是在 `ArticlesController` 中创建 `create` 动作。

### 创建文章

要消除“未知动作”错误，我们需要修改 `app/controllers/articles_controller.rb` 文件，在 `ArticlesController` 类的 `new` 动作之后添加 `create` 动作，就像下面这样：

```ruby
class ArticlesController < ApplicationController
  def new
  end

  def create
  end
end
```

现在重新提交表单，会看到什么都没有改变。别着急！这是因为当我们没有说明动作的响应是什么时，Rails 默认返回 `204 No Content response`。我们刚刚添加了 `create` 动作，但没有说明响应是什么。这里，`create` 动作应该把新建文章保存到数据库中。

表单提交后，其字段以参数形式传递给 Rails，然后就可以在控制器动作中引用这些参数，以执行特定任务。要想查看这些参数的内容，可以把 `create` 动作的代码修改成下面这样：

```ruby
def create
  render plain: params[:article].inspect
end
```

这里 `render` 方法接受了一个简单的散列（hash）作为参数，`:plain` 键的值是 `params[:article].inspect`。`params` 方法是代表表单提交的参数（或字段）的对象。`params` 方法返回 `ActionController::Parameters` 对象，这个对象允许使用字符串或符号访问散列的键。这里我们只关注通过表单提交的参数。

TIP: 请确保牢固掌握 `params` 方法，这个方法很常用。让我们看一个示例 URL：http://www.example.com/?username=dhh&email=dhh@email.com。在这个 URL 中，`params[:username]` 的值是“dhh”，`params[:email]` 的值是“dhh@email.com”。

如果再次提交表单，就不会再看到缺少模板错误，而是会看到下面这些内容：

    <ActionController::Parameters {"title"=>"First Article!", "text"=>"This is my first article."} permitted: false>

`create` 动作把表单提交的参数都显示出来了，但这并没有什么用，只是看到了参数实际上却什么也没做。

### 创建 Article 模型

在 Rails 中，模型使用单数名称，对应的数据库表使用复数名称。Rails 提供了用于创建模型的生成器，大多数 Rails 开发者在新建模型时倾向于使用这个生成器。要想新建模型，请执行下面的命令：

    $ bin/rails generate model Article title:string text:text

上面的命令告诉 Rails 创建 `Article` 模型，并使模型具有字符串类型的 `title` 属性和文本类型的 `text` 属性。这两个属性会自动添加到数据库的 `articles` 表中，并映射到 `Article` 模型上。

为此 Rails 会创建一堆文件。这里我们只关注 `app/models/article.rb` 和 `db/migrate/20140120191729_create_articles.rb` 这两个文件 （后面这个文件名和你看到的可能会有点不一样）。后者负责创建数据库结构，下一节会详细说明。

TIP: Active Record 很智能，能自动把数据表的字段名映射到模型属性上，因此无需在 Rails 模型中声明属性，让 Active Record 自动完成即可。

### 运行迁移

如前文所述，`bin/rails generate model` 命令会在 `db/migrate` 文件夹中生成数据库迁移文件。迁移是用于简化创建和修改数据库表操作的 Ruby 类。Rails 使用 rake 命令运行迁移，并且在迁移作用于数据库之后还可以撤销迁移操作。迁移的文件名包含了时间戳，以确保迁移按照创建时间顺序运行。

让我们看一下 `db/migrate/YYYYMMDDHHMMSS_create_articles.rb` 文件（记住，你的文件名可能会有点不一样），会看到下面的内容：

```ruby
class CreateArticles < ActiveRecord::Migration[5.0]
  def change
    create_table :articles do |t|
      t.string :title
      t.text :text

      t.timestamps
    end
  end
end
```

上面的迁移创建了 `change` 方法，在运行迁移时会调用这个方法。在 `change` 方法中定义的操作都是可逆的，在需要时 Rails 知道如何撤销这些操作。运行迁移后会创建 `articles` 表，这个表包括一个字符串字段和一个文本字段，以及两个用于跟踪文章创建和更新时间的时间戳字段。

TIP: 关于迁移的更多介绍，请参阅[Active Record 迁移](active_record_migrations.html)。

现在可以使用 `bin/rails` 命令运行迁移了：

```sh
$ bin/rails db:migrate
```

Rails 会执行迁移命令并告诉我们它创建了 Articles 表。

    ==  CreateArticles: migrating ==================================================
    -- create_table(:articles)
       -> 0.0019s
    ==  CreateArticles: migrated (0.0020s) =========================================

NOTE: 因为默认情况下我们是在开发环境中工作，所以上述命令应用于 `config/database.yml` 文件中 `development` 部分定义的的数据库。要想在其他环境中执行迁移，例如生产环境，就必须在调用命令时显式传递环境变量：`bin/rails db:migrate RAILS_ENV=production`。

### 在控制器中保存数据

回到 `ArticlesController`，修改 `create` 动作，使用新建的 `Article` 模型把数据保存到数据库。打开 `app/controllers/articles_controller.rb` 文件，像下面这样修改 `create` 动作：

```ruby
def create
  @article = Article.new(params[:article])

  @article.save
  redirect_to @article
end
```

让我们看一下上面的代码都做了什么：Rails 模型可以用相应的属性初始化，它们会自动映射到对应的数据库字段。`create` 动作中的第一行代码完成的就是这个操作（记住，`params[:article]` 包含了我们想要的属性）。接下来 `@article.save` 负责把模型保存到数据库。最后把页面重定向到 `show` 动作，这个 `show` 动作我们稍后再定义。

TIP: 你可能想知道，为什么在上面的代码中 `Article.new` 的 `A` 是大写的，而在本文的其他地方引用 articles 时大都是小写的。因为这里我们引用的是在 `app/models/article.rb` 文件中定义的 `Article` 类，而在 Ruby 中类名必须以大写字母开头。

TIP: 之后我们会看到，`@article.save` 返回布尔值，以表明文章是否保存成功。

现在访问 <http://localhost:3000/articles/new>，我们就快要能够创建文章了，但我们还会看到下面的错误：

![禁用属性错误](images/getting_started/forbidden_attributes_for_new_article.png)

Rails 提供了多种安全特性来帮助我们编写安全的应用，上面看到的就是一种安全特性。这个安全特性叫做 [健壮参数](action_controller_overview.xml#strong-parameters)（strong parameter），要求我们明确地告诉 Rails 哪些参数允许在控制器动作中使用。

为什么我们要这样自找麻烦呢？一次性获取所有控制器参数并自动赋值给模型显然更简单，但这样做会造成恶意使用的风险。设想一下，如果有人对服务器发起了一个精心设计的请求，看起来就像提交了一篇新文章，但同时包含了能够破坏应用完整性的额外字段和值，会怎么样？这些恶意数据会批量赋值给模型，然后和正常数据一起进入数据库，这样就有可能破坏我们的应用或者造成更大损失。

所以我们只能为控制器参数设置白名单，以避免错误地批量赋值。这里，我们想在 `create` 动作中合法使用 `title` 和 `text` 参数，为此需要使用 `require` 和 `permit` 方法。像下面这样修改 `create` 动作中的一行代码：

```ruby
@article = Article.new(params.require(:article).permit(:title, :text))
```

上述代码通常被抽象为控制器类的一个方法，以便在控制器的多个动作中重用，例如在 `create` 和 `update` 动作中都会用到。除了批量赋值问题，为了禁止从外部调用这个方法，通常还要把它设置为 `private`。最后的代码像下面这样：

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

TIP: 关于键壮参数的更多介绍，请参阅上面提供的参考资料和[这篇博客](http://weblog.rubyonrails.org/2012/3/21/strong-parameters/)。

### 显示文章

现在再次提交表单，Rails 会提示找不到 `show` 动作。尽管这个提示没有多大用处，但在继续前进之前我们还是先添加 `show` 动作吧。

之前我们在 `bin/rails routes` 命令的输出结果中看到，`show` 动作对应的路由是：

    article GET    /articles/:id(.:format)      articles#show

特殊句法 `:id` 告诉 Rails 这个路由期望接受 `:id` 参数，在这里也就是文章的 ID。

和前面一样，我们需要在 `app/controllers/articles_controller.rb` 文件中添加 `show` 动作，并创建对应的视图文件。

NOTE: 常见的做法是按照以下顺序在控制器中放置标准的 CRUD 动作：`index`，`show`，`new`，`edit`，`create`，`update` 和 `destroy`。你也可以按照自己的顺序放置这些动作，但要记住它们都是公开方法，如前文所述，必须放在控制器的私有方法或受保护的方法之前才能正常工作。

有鉴于此，让我们像下面这样添加 `show` 动作：

```ruby
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])
  end

  def new
  end

  # 为了行文简洁，省略以下内容
```

上面的代码中有几个问题需要注意。我们使用 `Article.find` 来查找文章，并传入 `params[:id]` 以便从请求中获得 `:id` 参数。我们还使用实例变量（前缀为 `@`）保存对文章对象的引用。这样做是因为 Rails 会把所有实例变量传递给视图。

现在新建 `app/views/articles/show.html.erb` 文件，添加下面的代码：

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

通过上面的修改，我们终于能够新建文章了。访问 <http://localhost:3000/articles/new>，自己试一试吧！

![显示文章](images/getting_started/show_action_for_articles.png)

### 列出所有文章

我们还需要列出所有文章，下面就来完成这个功能。在 `bin/rails routes` 命令的输出结果中，和列出文章对应的路由是：

    articles GET    /articles(.:format)          articles#index

在 `app/controllers/articles_controller.rb` 文件的 `ArticlesController` 中为上述路由添加对应的 `index` 动作。在编写 `index` 动作时，常见的做法是把它作为控制器的第一个方法，就像下面这样：

```ruby
class ArticlesController < ApplicationController
  def index
    @articles = Article.all
  end

  def show
    @article = Article.find(params[:id])
  end

  def new
  end

  # 为了行文简洁，省略以下内容
```

最后，在 `app/views/articles/index.html.erb` 文件中为 `index` 动作添加视图：

```erb
<h1>Listing articles</h1>


```

现在访问 <http://localhost:3000/articles>，会看到已创建的所有文章的列表。

### 添加链接

至此，我们可以创建、显示、列出文章了。下面我们添加一些指向这些页面的链接。

打开 `app/views/welcome/index.html.erb` 文件，修改成下面这样：

```erb
<h1>Hello, Rails!</h1>
<%= link_to 'My Blog', controller: 'articles' %>
```

`link_to` 方法是 Rails 内置的视图辅助方法之一，用于创建基于链接文本和地址的超链接。在这里地址指的是文章列表页面的路径。

接下来添加指向其他视图的链接。首先在 `app/views/articles/index.html.erb` 文件中添加“New Article”链接，把这个链接放在 `
```

接着在 `app/views/articles/show.html.erb` 模板中添加 `Edit` 链接，这样文章页面也有 `Edit` 链接了。把这个链接添加到模板底部：

```erb
...

<%= link_to 'Edit', edit_article_path(@article) %> |
<%= link_to 'Back', articles_path %>
```

下面是文章列表现在的样子：

![文章列表](images/getting_started/index_action_with_edit_link.png)

### 使用局部视图去掉视图中的重复代码

编辑文章页面和新建文章页面看起来很相似，实际上这两个页面用于显示表单的代码是相同的。现在我们要用局部视图来去掉这些重复代码。按照约定，局部视图的文件名以下划线开头。

TIP: 关于局部视图的更多介绍，请参阅[Rails 布局和视图渲染](layouts_and_rendering.html)。

新建 `app/views/articles/_form.html.erb` 文件，添加下面的代码：

```erb
<%= form_for @article do |f| %>

  <% if @article.errors.any? %>
    <div id="error_explanation">
      <h2>
        <%= pluralize(@article.errors.count, "error") %> prohibited
        this article from being saved:
      </h2>
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

除了第一行 `form_for` 的用法变了之外，其他代码都和之前一样。之所以能用这个更短、更简单的 `form_for` 声明来代替新建文章页面和编辑文章页面的两个表单，是因为 `@article` 是一个资源，对应于一套 REST 式路由，Rails 能够推断出应该使用哪个地址和方法。关于 `form_for` 用法的更多介绍，请参阅“[面向资源的风格](http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_for-label-Resource-oriented+style)”。

现在更新 `app/views/articles/new.html.erb` 视图，以使用新建的局部视图。把文件内容替换为下面的代码：

```erb
<h1>New article</h1>

<%= render 'form' %>

<%= link_to 'Back', articles_path %>
```

然后按照同样的方法修改 `app/views/articles/edit.html.erb` 视图：

```erb
<h1>Edit article</h1>

<%= render 'form' %>

<%= link_to 'Back', articles_path %>
```

### 删除文章

现在该介绍 CRUD 中的“D”操作了，也就是从数据库删除文章。按照 REST 架构的约定，在 `bin/rails routes` 命令的输出结果中删除文章的路由是：

    DELETE /articles/:id(.:format)      articles#destroy

删除资源的路由应该使用 `delete` 路由方法。如果在删除资源时仍然使用 `get` 路由，就可能给那些设计恶意地址的人提供可乘之机：

```html
<a href='http://example.com/articles/1/destroy'>look at this cat!</a>
```

我们用 `delete` 方法来删除资源，对应的路由会映射到 `app/controllers/articles_controller.rb` 文件中的 `destroy` 动作，稍后我们要创建这个动作。`destroy` 动作是控制器中的最后一个 CRUD 动作，和其他公共 CRUD 动作一样，这个动作应该放在 `private` 或 `protected` 方法之前。打开 `app/controllers/articles_controller.rb` 文件，添加下面的代码：

```ruby
def destroy
  @article = Article.find(params[:id])
  @article.destroy

  redirect_to articles_path
end
```

在 `app/controllers/articles_controller.rb` 文件中，`ArticlesController` 的完整代码应该像下面这样：

```ruby
class ArticlesController < ApplicationController
  def index
    @articles = Article.all
  end

  def show
    @article = Article.find(params[:id])
  end

  def new
    @article = Article.new
  end

  def edit
    @article = Article.find(params[:id])
  end

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to @article
    else
      render 'new'
    end
  end

  def update
    @article = Article.find(params[:id])

    if @article.update(article_params)
      redirect_to @article
    else
      render 'edit'
    end
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    redirect_to articles_path
  end

  private
    def article_params
      params.require(:article).permit(:title, :text)
    end
end
```

在 Active Record 对象上调用 `destroy` 方法，就可从数据库中删除它们。注意，我们不需要为 `destroy` 动作添加视图，因为完成操作后它会重定向到 `index` 动作。

最后，在 `index` 动作的模板（`app/views/articles/index.html.erb`）中加上“Destroy”链接，这样就大功告成了：

```erb
<h1>Listing Articles</h1>
<%= link_to 'New article', new_article_path %>

```

在上面的代码中，`link_to` 辅助方法生成“Destroy”链接的用法有点不同，其中第二个参数是具名路由（named route），还有一些选项作为其他参数。`method: :delete` 和 `data: { confirm: 'Are you sure?' }` 选项用于设置链接的 HTML5 属性，这样点击链接后 Rails 会先向用户显示一个确认对话框，然后用 `delete` 方法发起请求。这些操作是通过 JavaScript 脚本 `jquery_ujs` 实现的，这个脚本在生成应用骨架时已经被自动包含在了应用的布局中（`app/views/layouts/application.html.erb`）。如果没有这个脚本，确认对话框就无法显示。

![确认对话框](images/getting_started/confirm_dialog.png)

TIP: 关于 jQuery 非侵入式适配器（jQuery UJS）的更多介绍，请参阅[在 Rails 中使用 JavaScript](working_with_javascript_in_rails.html)。

恭喜你！现在你已经可以创建、显示、列出、更新和删除文章了！

TIP: 通常 Rails 鼓励用资源对象来代替手动声明路由。关于路由的更多介绍，请参阅[Rails 路由全解](routing.html)。

添加第二个模型
--------------

现在是为应用添加第二个模型的时候了。这个模型用于处理文章评论。

### 生成模型

接下来将要使用的生成器，和之前用于创建 `Article` 模型的一样。这次我们要创建 `Comment` 模型，用于保存文章评论。在终端中执行下面的命令：

```sh
$ bin/rails generate model Comment commenter:string body:text article:references
```

上面的命令会生成 4 个文件：

| 文件 | 用途 |
|----|----|
| db/migrate/20140120201010_create_comments.rb | 用于在数据库中创建 comments 表的迁移文件（你的文件名会包含不同的时间戳） |
| app/models/comment.rb | Comment 模型文件 |
| test/models/comment_test.rb | Comment 模型的测试文件 |
| test/fixtures/comments.yml | 用于测试的示例评论 |

首先看一下 `app/models/comment.rb` 文件：

```ruby
class Comment < ApplicationRecord
  belongs_to :article
end
```

可以看到，`Comment` 模型文件的内容和之前的 `Article` 模型差不多，仅仅多了一行 `belongs_to :article`，这行代码用于建立 Active Record 关联。下一节会简单介绍关联。

在上面的 Bash 命令中使用的 `:references` 关键字是一种特殊的模型数据类型，用于在数据表中新建字段。这个字段以提供的模型名加上 `_id` 后缀作为字段名，保存整数值。之后通过分析 `db/schema.rb` 文件可以更好地理解这些内容。

除了模型文件，Rails 还生成了迁移文件，用于创建对应的数据表：

```ruby
class CreateComments < ActiveRecord::Migration[5.0]
  def change
    create_table :comments do |t|
      t.string :commenter
      t.text :body
      t.references :article, foreign_key: true

      t.timestamps
    end
  end
end
```

`t.references` 这行代码创建 `article_id` 整数字段，为这个字段建立索引，并建立指向 `articles` 表的 `id` 字段的外键约束。下面运行这个迁移：

```sh
$ bin/rails db:migrate
```

Rails 很智能，只会运行针对当前数据库还没有运行过的迁移，运行结果像下面这样：

    ==  CreateComments: migrating =================================================
    -- create_table(:comments)
       -> 0.0115s
    ==  CreateComments: migrated (0.0119s) ========================================

### 模型关联

Active Record 关联让我们可以轻易地声明两个模型之间的关系。对于评论和文章，我们可以像下面这样声明：

- 每一条评论都属于某一篇文章

- 一篇文章可以有多条评论

实际上，这种表达方式和 Rails 用于声明模型关联的句法非常接近。前文我们已经看过 `Comment` 模型中用于声明模型关联的代码，这行代码用于声明每一条评论都属于某一篇文章：

```ruby
class Comment < ApplicationRecord
  belongs_to :article
end
```

现在修改 `app/models/article.rb` 文件来添加模型关联的另一端：

```ruby
class Article < ApplicationRecord
  has_many :comments
  validates :title, presence: true,
                    length: { minimum: 5 }
end
```

这两行声明能够启用一些自动行为。例如，如果 `@article` 实例变量表示一篇文章，就可以使用 `@article.comments` 以数组形式取回这篇文章的所有评论。

TIP: 关于模型关联的更多介绍，请参阅[Active Record 关联](association_basics.html)。

### 为评论添加路由

和 `welcome` 控制器一样，在添加路由之后 Rails 才知道在哪个地址上查看评论。再次打开 `config/routes.rb` 文件，像下面这样进行修改：

```ruby
resources :articles do
  resources :comments
end
```

上面的代码在 `articles` 资源中创建 `comments` 资源，这种方式被称为嵌套资源。这是表明文章和评论之间层级关系的另一种方式。

TIP: 关于路由的更多介绍，请参阅[Rails 路由全解](routing.html)。

### 生成控制器

有了模型，下面应该创建对应的控制器了。还是使用前面用过的生成器：

```sh
$ bin/rails generate controller Comments
```

上面的命令会创建 5 个文件和一个空文件夹：

| 文件/文件夹 | 用途 |
|--------|----|
| app/controllers/comments_controller.rb | Comments 控制器文件 |
| app/views/comments/ | 控制器的视图保存在这里 |
| test/controllers/comments_controller_test.rb | 控制器的测试文件 |
| app/helpers/comments_helper.rb | 视图辅助方法文件 |
| app/assets/javascripts/comment.coffee | 控制器的 CoffeeScript 文件 |
| app/assets/stylesheets/comment.scss | 控制器的样式表文件 |

在博客中，读者看完文章后可以直接发表评论，并且马上可以看到这些评论是否在页面上显示出来了。我们的博客采取同样的设计。这里 `CommentsController` 需要提供创建评论和删除垃圾评论的方法。

首先修改显示文章的模板（`app/views/articles/show.html.erb`），添加发表评论的功能：

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

<%= link_to 'Edit', edit_article_path(@article) %> |
<%= link_to 'Back', articles_path %>
```

上面的代码在显示文章的页面中添加了用于新建评论的表单，通过调用 `CommentsController` 的 `create` 动作来发表评论。这里 `form_for` 辅助方法以数组为参数，会创建嵌套路由，例如 `/articles/1/comments`。

接下来在 `app/controllers/comments_controller.rb` 文件中添加 `create` 动作：

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

上面的代码比 `Articles` 控制器的代码复杂得多，这是嵌套带来的副作用。对于每一个发表评论的请求，都必须记录这条评论属于哪篇文章，因此需要在 `Article` 模型上调用 `find` 方法来获取文章对象。

此外，上面的代码还利用了关联特有的方法，在 `@article.comments` 上调用 `create` 方法来创建和保存评论，同时自动把评论和对应的文章关联起来。

添加评论后，我们使用 `article_path(@article)` 辅助方法把用户带回原来的文章页面。如前文所述，这里调用了 `ArticlesController` 的 `show` 动作来渲染 `show.html.erb` 模板，因此需要修改 `app/views/articles/show.html.erb` 文件来显示评论：

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

<%= link_to 'Edit', edit_article_path(@article) %> |
<%= link_to 'Back', articles_path %>
```

现在可以在我们的博客中为文章添加评论了，评论添加后就会显示在正确的位置上。

![带有评论的文章](images/getting_started/article_with_comments.png)

重构
----

现在博客的文章和评论都已经正常工作，打开 `app/views/articles/show.html.erb` 文件，会看到文件代码变得又长又不美观。因此下面我们要用局部视图来重构代码。

### 渲染局部视图集合

首先创建评论的局部视图，把显示文章评论的代码抽出来。创建 `app/views/comments/_comment.html.erb` 文件，添加下面的代码：

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

然后像下面这样修改 `app/views/articles/show.html.erb` 文件：

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

<%= link_to 'Edit', edit_article_path(@article) %> |
<%= link_to 'Back', articles_path %>
```

这样对于 `@article.comments` 集合中的每条评论，都会渲染 `app/views/comments/_comment.html.erb` 文件中的局部视图。`render` 方法会遍历 `@article.comments` 集合，把每条评论赋值给局部视图中的同名局部变量，也就是这里的 `comment` 变量。

### 渲染局部视图表单

我们把添加评论的代码也移到局部视图中。创建 `app/views/comments/_form.html.erb` 文件，添加下面的代码：

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

然后像下面这样修改 `app/views/articles/show.html.erb` 文件：

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
<%= render 'comments/form' %>

<%= link_to 'Edit', edit_article_path(@article) %> |
<%= link_to 'Back', articles_path %>
```

上面的代码中第二个 `render` 方法的参数就是我们刚刚定义的 `comments/form` 局部视图。Rails 很智能，能够发现字符串中的斜线，并意识到我们想渲染 `app/views/comments` 文件夹中的 `_form.html.erb` 文件。

`@article` 是实例变量，因此在所有局部视图中都可以使用。

删除评论
--------

博客还有一个重要功能是删除垃圾评论。为了实现这个功能，我们需要在视图中添加一个链接，并在 `CommentsController` 中添加 `destroy` 动作。

首先在 `app/views/comments/_comment.html.erb` 局部视图中添加删除评论的链接：

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

点击“Destroy Comment”链接后，会向 `CommentsController` 发起 `DELETE /articles/:article_id/comments/:id` 请求，这个请求将用于删除指定评论。下面在控制器（`app/controllers/comments_controller.rb`）中添加 `destroy` 动作：

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

`destroy` 动作首先找到指定文章，然后在 `@article.comments` 集合中找到指定评论，接着从数据库删除这条评论，最后重定向到显示文章的页面。

### 删除关联对象

如果要删除一篇文章，文章的相关评论也需要删除，否则这些评论还会占用数据库空间。在 Rails 中可以使用关联的 `dependent` 选项来完成这一工作。像下面这样修改 `app/models/article.rb` 文件中的 `Article` 模型：

```ruby
class Article < ApplicationRecord
  has_many :comments, dependent: :destroy
  validates :title, presence: true,
                    length: { minimum: 5 }
end
```

安全
----

### 基本身份验证

现在如果我们把博客放在网上，任何人都能够添加、修改、删除文章或删除评论。

Rails 提供了一个非常简单的 HTTP 身份验证系统，可以很好地解决这个问题。

我们需要一种方法来禁止未认证用户访问 `ArticlesController` 的动作。这里我们可以使用 Rails 的 `http_basic_authenticate_with` 方法，通过这个方法的认证后才能访问所请求的动作。

要使用这个身份验证系统，可以在 `app/controllers/articles_controller` 文件中的 `ArticlesController` 的顶部进行指定。这里除了 `index` 和 `show` 动作，其他动作都要通过身份验证才能访问，为此要像下面这样添加代码：

```ruby
class ArticlesController < ApplicationController

  http_basic_authenticate_with name: "dhh", password: "secret", except: [:index, :show]

  def index
    @articles = Article.all
  end

  # 为了行文简洁，省略以下内容
```

同时只有通过身份验证的用户才能删除评论，为此要在 `CommentsController`（`app/controllers/comments_controller.rb`）中像下面这样添加代码：

```ruby
class CommentsController < ApplicationController

  http_basic_authenticate_with name: "dhh", password: "secret", only: :destroy

  def create
    @article = Article.find(params[:article_id])
    # ...
  end

  # 为了行文简洁，省略以下内容
```

现在如果我们试着新建文章，就会看到 HTTP 基本身份验证对话框：

![HTTP 基本认证对话框](images/getting_started/challenge.png)

此外，还可以在 Rails 中使用其他身份验证方法。在众多选择中，[Devise](https://github.com/plataformatec/devise) 和 [Authlogic](https://github.com/binarylogic/authlogic) 是两个流行的 Rails 身份验证扩展。

### 其他安全注意事项

安全，尤其是 Web 应用的安全，是一个广泛和值得深入研究的领域。关于 Rails 应用安全的更多介绍，请参阅[安全指南](security.html)。

接下来做什么？
--------------

至此，我们已经完成了第一个 Rails 应用，请在此基础上尽情修改、试验。

记住你不需要独自完成一切，在安装和运行 Rails 时如果需要帮助，请随时使用下面的资源：

- [Ruby on Rails 指南](http://rails.guide)

- [Ruby on Rails 教程](http://railstutorial-china.org)

- [Ruby on Rails 邮件列表](http://groups.google.com/group/rubyonrails-talk)

- irc.freenode.net 中的 [\#rubyonrails](irc://irc.freenode.net/#rubyonrails) 频道

配置问题
--------

在 Rails 中，储存外部数据最好都使用 UTF-8 编码。虽然 Ruby 库和 Rails 通常都能将使用其他编码的外部数据转换为 UTF-8 编码，但并非总是能可靠地工作，所以最好还是确保所有的外部数据都使用 UTF-8 编码。

编码出错的最常见症状是在浏览器中出现带有问号的黑色菱形块，另一个常见症状是本该出现“ü”字符的地方出现了“Ã¼”字符。Rails 内部采取了许多步骤来解决常见的可以自动检测和纠正的编码问题。尽管如此，如果不使用 UTF-8 编码来储存外部数据，偶尔还是会出现无法自动检测和纠正的编码问题。

下面是非 UTF-8 编码数据的两种常见来源：

- 文本编辑器：大多数文本编辑器（例如 TextMate）默认使用 UTF-8 编码保存文件。如果你的文本编辑器未使用 UTF-8 编码，就可能导致在模板中输入的特殊字符（例如 é）在浏览器中显示为带有问号的黑色菱形块。这个问题也会出现在 i18n 翻译文件中。大多数未默认使用 UTF-8 编码的文本编辑器（例如 Dreamweaver 的某些版本）提供了将默认编码修改为 UTF-8 的方法，别忘了进行修改。

- 数据库：默认情况下，Rails 会把从数据库中取出的数据转换成 UTF-8 格式。尽管如此，如果数据库内部不使用 UTF-8 编码，就有可能无法保存用户输入的所有字符。例如，如果数据库内部使用 Latin-1 编码，而用户输入了俄语、希伯来语或日语字符，那么在把数据保存到数据库时就会造成数据永久丢失。因此，只要可能，就请在数据库内部使用 UTF-8 编码。
