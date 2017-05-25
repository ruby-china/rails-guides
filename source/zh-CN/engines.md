# 引擎入门

本文介绍引擎及其用法，即如何通过引擎这个干净、易用的接口，为宿主应用提供附加功能。

读完本文后，您将学到：

*   引擎由什么组成；
*   如何生成引擎；
*   如何为引擎创建特性；
*   如何把引擎挂载到应用中；
*   如何在应用中覆盖引擎的功能;
*   通过加载和配置钩子避免加载 Rails 组件。

-----------------------------------------------------------------------------

NOTE: 本文原文尚未完工！

<a class="anchor" id="what-are-engines"></a>

## 引擎是什么

引擎可以看作为宿主应用提供附加功能的微型应用。实际上，Rails 应用只不过是“加强版”的引擎，`Rails::Application` 类从 `Rails::Engine` 类继承了大量行为。

因此，引擎和应用基本上可以看作同一个事物，通过本文的介绍，我们会看到两者之间只有细微差异。引擎和应用还具有相同的结构。

引擎还和插件密切相关。两者具有相同的 `lib` 目录结构，并且都使用 `rails plugin new` 生成器来生成。区别在于，引擎被 Rails 视为“完整的插件”（通过传递给生成器的 `--full` 选项可以看出这一点）。在这里我们实际使用的是 `--mountable` 选项，这个选项包含了 `--full` 选项的所有特性。本文把这类“完整的插件”简称为“引擎”。也就是说，引擎可以是插件，插件也可以是引擎。

本文将创建名为“blorgh”的引擎，用于为宿主应用提供博客功能，即新建文章和评论的功能。在本文的开头部分，我们将看到引擎的内部工作原理，在之后的部分中，我们将看到如何把引擎挂载到应用中。

我们还可以把引擎和宿主应用隔离开来。也就是说，应用和引擎可以使用同名的 `articles_path` 路由辅助方法而不会发生冲突。除此之外，应用和引擎的控制器、模型和表名也具有不同的命名空间。后文将介绍这些特性是如何实现的。

一定要记住，在任何时候，应用的优先级都应该比引擎高。应用对其环境中发生的事情拥有最终的决定权。引擎用于增强应用的功能，而不是彻底改变应用的功能。

引擎的例子有 [Devise](https://github.com/plataformatec/devise)（提供身份验证）、[Thredded](https://github.com/thredded/thredded)（提供论坛功能）、[Spree](https://github.com/spree/spree)（提供电子商务平台） 和 [RefineryCMS](https://github.com/refinery/refinerycms)（CMS 引擎）。

最后，如果没有 James Adam、Piotr Sarnacki、Rails 核心开发团队和其他许多人的努力，引擎就不可能实现。如果遇见他们，请不要忘记说声谢谢！

<a class="anchor" id="generating-an-engine"></a>

## 生成引擎

通过运行插件生成器并传递必要的选项就可以生成引擎。在 Blorgh 引擎的例子中，我们需要创建“可挂载”的引擎，为此可以在终端中运行下面的命令：

```sh
$ rails plugin new blorgh --mountable
```

通过下面的命令可以查看插件生成器选项的完整列表：

```sh
$ rails plugin --help
```

通过 `--mountable` 选项，生成器会创建“可挂载”和具有独立命名空间的引擎。此选项和 `--full` 选项会为引擎生成相同的程序骨架。通过 `--full` 选项，生成器会在创建引擎的同时生成下面的程序骨架：

*   `app` 目录树
*   `config/routes.rb` 文件：

    ```ruby
    Rails.application.routes.draw do
    end
    ```


*   `lib/blorgh/engine.rb` 文件，相当于 Rails 应用的 `config/application.rb` 配置文件：

    ```ruby
    module Blorgh
      class Engine < ::Rails::Engine
      end
    end
    ```



`--mountable` 选项在 `--full` 选项的基础上增加了如下特性：

*   静态资源文件的清单文件（`application.js` 和 `application.css`）
*   具有独立命名空间的 `ApplicationController`
*   具有独立命名空间的 `ApplicationHelper`
*   引擎的布局视图模板
*   在 `config/routes.rb` 文件中为引擎设置独立的命名空间：

    ```ruby
    Blorgh::Engine.routes.draw do
    end
    ```


*   在 `lib/blorgh/engine.rb` 文件中为引擎设置独立的命名空间：

    ```ruby
    module Blorgh
      class Engine < ::Rails::Engine
        isolate_namespace Blorgh
      end
    end
    ```



此外，通过 `--mountable` 选项，生成器会在位于 `test/dummy` 的 dummy 测试应用中挂载 blorgh 引擎，具体做法是把下面这行代码添加到 dummy 应用的路由文件 `test/dummy/config/routes.rb` 中：

```ruby
mount Blorgh::Engine => "/blorgh"
```

<a class="anchor" id="inside-an-engine"></a>

### 深入引擎内部

<a class="anchor" id="critical-files"></a>

#### 关键文件

在新建引擎的文件夹中有一个 `blorgh.gemspec` 文件。通过在 Rails 应用的 Gemfile 文件中添加下面的代码，可以把引擎挂载到应用中：

```ruby
gem 'blorgh', path: 'engines/blorgh'
```

和往常一样，别忘了运行 `bundle install` 命令。通过在 Gemfile 中添加 `blorgh` gem，Bundler 将加载此 gem，解析其中的 `blorgh.gemspec` 文件，并加载 `lib/blorgh.rb` 文件。`lib/blorgh.rb` 文件会加载 `lib/blorgh/engine.rb` 文件，其中定义了 `Blorgh` 基础模块。

```ruby
require "blorgh/engine"

module Blorgh
end
```

TIP: 有些引擎会通过 `lib/blorgh/engine.rb` 文件提供全局配置选项。相对而言这是个不错的主意，因此我们可以优先选择在定义引擎模块的 `lib/blorgh/engine.rb` 文件中定义全局配置选项，也就是在引擎模块中定义相关方法。

在 `lib/blorgh/engine.rb` 文件中定义引擎的基类：

```ruby
module Blorgh
  class Engine < ::Rails::Engine
    isolate_namespace Blorgh
  end
end
```

通过继承 `Rails::Engine` 类，`blorgh` gem 告知 Rails 在指定路径上有一个引擎，Rails 会把该引擎正确挂载到应用中，并执行相关任务，例如把 `app` 文件夹添加到模型、邮件程序、控制器和视图的加载路径中。

这里的 `isolate_namespace` 方法尤其需要注意。通过调用此方法，可以把引擎的控制器、模型、路由和其他组件隔离到各自的命名空间中，以便和应用中的类似组件隔离开来。要是没有这个方法，引擎的组件就可能“泄漏”到应用中，从而引起意外的混乱，引擎的重要组件也可能被应用中的同名组件覆盖。这类冲突的一个例子是辅助方法。在未调用 `isolate_namespace` 方法的情况下，引擎的辅助方法会被包含到应用的控制器中。

NOTE: 强烈建议在 `Engine` 类的定义中调用 `isolate_namespace` 方法。在未调用此方法的情况下，引擎中生成的类有可能和应用发生冲突。

命名空间隔离的意思是，通过 `bin/rails g model` 生成的模型，例如 `bin/rails g model article`，不会被命名为 `Article`，而会被命名为带有命名空间的 `Blorgh::Article`。此外，模型的表名同样带有命名空间，也就是说表名不是 `articles`，而是 `blorgh_articles`。和模型的命名规则类似，控制器不会被命名为 `ArticlesController`，而会被命名为 `Blorgh::ArticlesController`，控制器对应的视图不是 `app/views/articles`，而是 `app/views/blorgh/articles`。邮件程序的情况类似。

最后，路由也会被隔离在引擎中。这是命名空间最重要的内容之一，稍后将在 [路由](#engines-routes)介绍。

<a class="anchor" id="app-directory"></a>

#### `app` 文件夹

和应用类似，引擎的 `app` 文件夹中包含了标准的 `assets`、`controllers`、`helpers`、`mailers`、`models` 和 `views` 文件夹。其中 `helpers`、`mailers` 和 `models` 是空文件夹，因此本节不作介绍。后文介绍引擎编写时，会详细介绍 `models` 文件夹。

同样，和应用类似，引擎的 `app/assets` 文件夹中包含了 `images`、`javascripts` 和 `stylesheets` 文件夹。不过两者有一个区别，引擎的这三个文件夹中还包含了和引擎同名的文件夹。因为引擎位于命名空间中，所以引擎的静态资源文件也位于命名空间中。

`app/controllers` 文件夹中包含 `blorgh` 文件夹，其中包含 `application_controller.rb` 文件。此文件中包含了引擎控制器的通用功能。其他控制器文件也应该放在 `blorgh` 文件夹中。通过把引擎的控制器文件放在 `blorgh` 文件夹（作为控制器的命名空间）中，就可以避免和其他引擎甚至应用中的同名控制器发生冲突。

NOTE: 引擎的 `ApplicationController` 类采用了和 Rails 应用相同的命名规则，这样便于把应用转换为引擎。

NOTE: 鉴于 Ruby 进行常量查找的方式，我们可能会遇到引擎的控制器继承自应用的 `ApplicationController`，而不是继承自引擎的 `ApplicationController` 的情况。此时 Ruby 能够解析 `ApplicationController`，因此不会触发自动加载机制。关于这个问题的更多介绍，请参阅 [常量未缺失](autoloading_and_reloading_constants.html#when-constants-aren-t-missed)。避免出现这种情况的最好办法是使用 `require_dependency` 方法，以确保加载的是引擎的 `ApplicationController`。例如：

```ruby
# app/controllers/blorgh/articles_controller.rb:
require_dependency "blorgh/application_controller"

module Blorgh
  class ArticlesController < ApplicationController
    ...
  end
end
```


WARNING: 不要使用 `require` 方法，否则会破坏开发环境中类的自动重新加载——使用 `require_dependency` 方法才能确保以正确的方式加载和卸载类。

最后，`app/views` 文件夹中包含 `layouts` 文件夹，其中包含 `blorgh/application.html.erb` 文件。此文件用于为引擎指定布局。如果此引擎要作为独立引擎使用，那么应该在此文件而不是 `app/views/layouts/application.html.erb` 文件中自定义引擎布局。

如果不想强制用户使用引擎布局，那么可以删除此文件，并在引擎控制器中引用不同的布局。

<a class="anchor" id="bin-directory"></a>

#### `bin` 文件夹

引擎的 `bin` 文件夹中包含 `bin/rails` 文件。和应用类似，此文件提供了对 `rails` 子命令和生成器的支持。也就是说，我们可以像下面这样通过命令生成引擎的控制器和模型：

```sh
$ bin/rails g model
```

记住，在 `Engine` 的子类中调用 `isolate_namespace` 方法后，通过这些命令生成的引擎控制器和模型都将位于命名空间中。

<a class="anchor" id="test-directory"></a>

#### `test` 文件夹

引擎的 `test` 文件夹用于储存引擎测试文件。在 `test/dummy` 文件夹中有一个内嵌于引擎中的精简版 Rails 测试应用，可用于测试引擎。此测试应用会挂载 `test/dummy/config/routes.rb` 文件中的引擎：

```ruby
Rails.application.routes.draw do
  mount Blorgh::Engine => "/blorgh"
end
```

上述代码会挂载 `/blorgh` 文件夹中的引擎，在应用中只能通过此路径访问该引擎。

`test/integration` 文件夹用于储存引擎的集成测试文件。在 `test` 文件夹中还可以创建其他文件夹。例如，我们可以为引擎的模型测试创建 `test/models` 文件夹。

<a class="anchor" id="providing-engine-functionality"></a>

## 为引擎添加功能

本文创建的“blorgh”示例引擎，和[Rails 入门](getting_started.html)中的 Blog 应用类似，具有添加文章和评论的功能。

<a class="anchor" id="generating-an-article-resource"></a>

### 生成文章资源

创建博客引擎的第一步是生成 `Article` 模型和相关控制器。为此，我们可以使用 Rails 的脚手架生成器：

```sh
$ bin/rails generate scaffold article title:string text:text
```

上述命令输出的提示信息为：

```
invoke  active_record
create    db/migrate/[timestamp]_create_blorgh_articles.rb
create    app/models/blorgh/article.rb
invoke    test_unit
create      test/models/blorgh/article_test.rb
create      test/fixtures/blorgh/articles.yml
invoke  resource_route
 route    resources :articles
invoke  scaffold_controller
create    app/controllers/blorgh/articles_controller.rb
invoke    erb
create      app/views/blorgh/articles
create      app/views/blorgh/articles/index.html.erb
create      app/views/blorgh/articles/edit.html.erb
create      app/views/blorgh/articles/show.html.erb
create      app/views/blorgh/articles/new.html.erb
create      app/views/blorgh/articles/_form.html.erb
invoke    test_unit
create      test/controllers/blorgh/articles_controller_test.rb
invoke    helper
create      app/helpers/blorgh/articles_helper.rb
invoke  assets
invoke    js
create      app/assets/javascripts/blorgh/articles.js
invoke    css
create      app/assets/stylesheets/blorgh/articles.css
invoke  css
create    app/assets/stylesheets/scaffold.css
```

脚手架生成器完成的第一项工作是调用 `active_record` 生成器，这个生成器会为文章资源生成迁移和模型。但请注意，这里生成的迁移是 `create_blorgh_articles` 而不是通常的 `create_articles`，这是因为我们在 `Blorgh::Engine` 类的定义中调用了 `isolate_namespace` 方法。同样，这里生成的模型也带有命名空间，模型文件储存在 `app/models/blorgh/article.rb` 文件夹而不是 `app/models/article.rb` 文件夹中。

接下来，脚手架生成器会为此模型调用 `test_unit` 生成器，这个生成器会生成模型测试 `test/models/blorgh/article_test.rb`（而不是 `test/models/article_test.rb`）和测试固件 `test/fixtures/blorgh/articles.yml`（而不是 `test/fixtures/articles.yml`）。

之后，脚手架生成器会在引擎的 `config/routes.rb` 文件中为文章资源添加路由，也即 `resources :articles`，修改后的 `config/routes.rb` 文件的内容如下：

```ruby
Blorgh::Engine.routes.draw do
  resources :articles
end
```

注意，这里的路由是通过 `Blorgh::Engine` 对象而非 `YourApp::Application` 类定义的。正如 [`test` 文件夹](#test-directory)介绍的那样，这样做的目的是把引擎路由限制在引擎中，这样就可以根据需要把引擎路由挂载到不同位置，同时也把引擎路由和应用中的其他路由隔离开来。关于这个问题的更多介绍，请参阅 [路由](#engines-routes)。

接下来，脚手架生成器会调用 `scaffold_controller` 生成器，以生成 `Blorgh::ArticlesController`（即 `app/controllers/blorgh/articles_controller.rb` 控制器文件）以及对应的视图（位于 `app/views/blorgh/articles` 文件夹中）、测试（即 `test/controllers/blorgh/articles_controller_test.rb` 测试文件）和辅助方法（即 `app/helpers/blorgh/articles_helper.rb` 文件）。

脚手架生成器生成的上述所有组件都带有命名空间。其中控制器类在 `Blorgh` 模块中定义：

```ruby
module Blorgh
  class ArticlesController < ApplicationController
    ...
  end
end
```

NOTE: 这里的 `ArticlesController` 类继承自 `Blorgh::ApplicationController` 类，而不是应用的 `ApplicationController` 类。

在 `app/helpers/blorgh/articles_helper.rb` 文件中定义的辅助方法也带有命名空间：

```ruby
module Blorgh
  module ArticlesHelper
    ...
  end
end
```

这样，即便其他引擎或应用中定义了同名的文章资源，也不会发生冲突。

最后，脚手架生成器会生成两个静态资源文件 `app/assets/javascripts/blorgh/articles.js` 和 `app/assets/stylesheets/blorgh/articles.css`，其用法将在后文介绍。

我们可以在引擎的根目录中通过 `bin/rails db:migrate` 命令运行前文中生成的迁移，然后在 `test/dummy` 文件夹中运行 `rails server` 命令以查看迄今为止的工作成果。打开 http://localhost:3000/blorgh/articles 页面，可以看到刚刚生成的默认脚手架。随意点击页面中的链接吧！这是我们为引擎添加的第一项功能。

我们也可以在 Rails 控制台中对引擎的功能进行一些测试，其效果和 Rails 应用类似。注意，因为引擎的 `Article` 模型带有命名空间，所以调用时应使用 `Blorgh::Article`：

```irb
>> Blorgh::Article.find(1)
=> #<Blorgh::Article id: 1 ...>
```

最后一个需要注意的问题是，引擎的 `articles` 资源应作为引擎的根路径。当用户访问挂载引擎的根路径时，看到的应该是文章列表。具体的设置方法是在引擎的 `config/routes.rb` 文件中添加下面这行代码：

```ruby
root to: "articles#index"
```

这样，用户只需访问引擎的根路径，而无需访问 `/articles`，就可以看到所有文章的列表。也就是说，现在应该访问 http://localhost:3000/blorgh 页面，而不是 http://localhost:3000/blorgh/articles 页面。

<a class="anchor" id="generating-a-comments-resource"></a>

### 生成评论资源

到目前为止，我们的 Blorgh 引擎已经能够新建文章了，下一步应该为文章添加评论。为此，我们需要生成评论模型和评论控制器，同时修改文章脚手架，以显示文章的已有评论并提供添加评论的表单。

在引擎的根目录中运行模型生成器，以生成 `Comment` 模型，此模型具有 `article_id` 整型字段和 `text` 文本字段：

```sh
$ bin/rails generate model Comment article_id:integer text:text
```

上述命令输出的提示信息为：

```
invoke  active_record
create    db/migrate/[timestamp]_create_blorgh_comments.rb
create    app/models/blorgh/comment.rb
invoke    test_unit
create      test/models/blorgh/comment_test.rb
create      test/fixtures/blorgh/comments.yml
```

通过运行模型生成器，我们生成了必要的模型文件，这些文件都储存在 `blorgh` 文件夹中（用作模型的命名空间），同时创建了 `Blorgh::Comment` 模型类。接下来，在引擎的根目录中运行迁移，以创建 `blorgh_comments` 数据表：

```sh
$ bin/rails db:migrate
```

为了显示文章评论，我们需要修改 `app/views/blorgh/articles/show.html.erb` 文件，在“修改”链接之前添加下面的代码：

```erb
<h3>Comments</h3>
<%= render @article.comments %>
```

上述代码要求在 `Blorgh::Article` 模型上定义到 `comments` 的 `has_many` 关联，这项工作目前还未进行。为此，我们需要打开 `app/models/blorgh/article.rb` 文件，在模型定义中添加下面这行代码：

```ruby
has_many :comments
```

修改后的模型定义如下：

```ruby
module Blorgh
  class Article < ApplicationRecord
    has_many :comments
  end
end
```

NOTE: 这里的 `has_many` 关联是在 `Blorgh` 模块内的类中定义的，因此 Rails 知道应该为关联对象使用 `Blorgh::Comment` 模型，而无需指定 `:class_name` 选项。

接下来，还需要提供添加评论的表单。为此，我们需要打开 `app/views/blorgh/articles/show.html.erb` 文件，在 `render @article.comments` 之后添加下面这行代码：

```erb
<%= render "blorgh/comments/form" %>
```

接下来需要添加上述代码中使用的局部视图。新建 `app/views/blorgh/comments` 文件夹，在其中新建 `_form.html.erb` 文件并添加下面的局部视图代码：

```erb
<h3>New comment</h3>
<%= form_for [@article, @article.comments.build] do |f| %>
  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>
  <%= f.submit %>
<% end %>
```

此表单在提交时，会向引擎的 `/articles/:article_id/comments` 地址发起 `POST` 请求。此地址对应的路由还不存在，为此需要打开 `config/routes.rb` 文件，修改其中的 `resources :articles` 相关代码：

```ruby
resources :articles do
  resources :comments
end
```

上述代码创建了表单所需的嵌套路由。

我们刚刚添加了路由，但路由指向的控制器还不存在。为此，需要在引擎的根目录中运行下面的命令：

```sh
$ bin/rails g controller comments
```

上述命令输出的提示信息为：

```
create  app/controllers/blorgh/comments_controller.rb
invoke  erb
 exist    app/views/blorgh/comments
invoke  test_unit
create    test/controllers/blorgh/comments_controller_test.rb
invoke  helper
create    app/helpers/blorgh/comments_helper.rb
invoke  assets
invoke    js
create      app/assets/javascripts/blorgh/comments.js
invoke    css
create      app/assets/stylesheets/blorgh/comments.css
```

提交表单时向 `/articles/:article_id/comments` 地址发起的 `POST` 请求，将由 `Blorgh::CommentsController` 的 `create` 动作处理。我们需要创建此动作，为此需要打开 `app/controllers/blorgh/comments_controller.rb` 文件，并在类定义中添加下面的代码：

```ruby
def create
  @article = Article.find(params[:article_id])
  @comment = @article.comments.create(comment_params)
  flash[:notice] = "Comment has been created!"
  redirect_to articles_path
end

private
  def comment_params
    params.require(:comment).permit(:text)
  end
```

这是提供评论表单的最后一步。但是仍有问题需要解决，如果我们添加一条评论，将会遇到下面的错误：

```
Missing partial blorgh/comments/_comment with {:handlers=>[:erb, :builder],
:formats=>[:html], :locale=>[:en, :en]}. Searched in:   *
"/Users/ryan/Sites/side_projects/blorgh/test/dummy/app/views"   *
"/Users/ryan/Sites/side_projects/blorgh/app/views"
```

引擎无法找到渲染评论所需的局部视图。Rails 首先会在测试应用（`test/dummy`）的 `app/views` 文件夹中进行查找，然在在引擎的 `app/views` 文件夹中进行查找。如果找不到，就会抛出上述错误。因为引擎接收的模型对象来自 `Blorgh::Comment` 类，所以引擎知道应该查找 `blorgh/comments/_comment` 局部视图。

目前，`blorgh/comments/_comment` 局部视图只需渲染评论文本。为此，我们可以新建 `app/views/blorgh/comments/_comment.html.erb` 文件，并添加下面这行代码：

```erb
<%= comment_counter + 1 %>. <%= comment.text %>
```

上述代码中的 `comment_counter` 局部变量由 `<%= render @article.comments %>` 调用提供，此调用会遍历每条评论并自动增加计数器的值。这里的 `comment_counter` 局部变量用于为每条评论添加序号。

到此为止，我们完成了博客引擎的评论功能。接下来我们就可以在应用中使用这项功能了。

<a class="anchor" id="hooking-into-an-application"></a>

## 把引擎挂载到应用中

要想在应用中使用引擎非常容易。本节介绍如何把引擎挂载到应用中并完成必要的初始化设置，以及如何把引擎连接到应用中的 `User` 类上，以便使应用中的用户拥有引擎中的文章及其评论。

<a class="anchor" id="mounting-the-engine"></a>

### 挂载引擎

首先，需要在应用的 Gemfile 中指定引擎。我们需要新建一个应用用于测试，为此可以在引擎文件夹之外执行 `rails new` 命令：

```sh
$ rails new unicorn
```

通常，只需在 Gemfile 中以普通 gem 的方式指定引擎。

```ruby
gem 'devise'
```

由于我们是在本地开发 `blorgh` 引擎，因此需要在 Gemfile 中指定 `:path` 选项：

```ruby
gem 'blorgh', path: 'engines/blorgh'
```

然后通过 `bundle` 命令安装 gem。

如前文所述，Gemfile 中的 gem 将在 Rails 启动时加载。上述代码首先加载引擎中的 `lib/blorgh.rb` 文件，然后加载 `lib/blorgh/engine.rb` 文件，后者定义了引擎的主要功能。

要想在应用中访问引擎的功能，我们需要在应用的 `config/routes.rb` 文件中挂载该引擎：

```ruby
mount Blorgh::Engine, at: "/blog"
```

上述代码会在应用的 `/blog` 路径上挂载引擎。通过 `rails server` 命令运行应用后，我们就可以通过 http://localhost:3000/blog 访问引擎了。

NOTE: 其他一些引擎，例如 Devise，工作原理略有不同，这些引擎会在路由中自定义辅助方法（例如 `devise_for`）。这些辅助方法的作用都是在预定义路径（可以自定义）上挂载引擎的功能。

<a class="anchor" id="engine-setup"></a>

### 引擎设置

引擎中包含了 `blorgh_articles` 和 `blorgh_comments` 数据表的迁移。通过这些迁移在应用的数据库中创建数据表之后，引擎模型才能正确查询对应的数据表。在引擎的 `test/dummy` 文件夹中运行下面的命令，可以把这些迁移复制到应用中：

```sh
$ bin/rails blorgh:install:migrations
```

如果需要从多个引擎中复制迁移，可以使用 `railties:install:migrations`：

```sh
$ bin/rails railties:install:migrations
```

第一次运行上述命令时，Rails 会从所有引擎中复制迁移。再次运行时，只会复制尚未复制的迁移。第一次运行上述命令时输出的提示信息为：

```
Copied migration [timestamp_1]_create_blorgh_articles.blorgh.rb from blorgh
Copied migration [timestamp_2]_create_blorgh_comments.blorgh.rb from blorgh
```

其中第一个时间戳（`[timestamp_1]`）是当前时间，第二个时间戳（`[timestamp_2]`）是当前时间加上 1 秒。这样就能确保引擎的迁移总是在应用的现有迁移之后运行。

通过 `bin/rails db:migrate` 命令即可在应用的上下文中运行引擎的迁移。此时访问 http://localhost:3000/blog 会看到文章列表是空的，这是因为在应用中和在引擎中创建的数据表有所不同。继续浏览刚刚挂载的这个引擎的其他页面，我们会发现引擎和应用看起来并没有什么区别。

通过指定 `SCOPE` 选项，我们可以只运行指定引擎的迁移：

```sh
$ bin/rails db:migrate SCOPE=blorgh
```

在需要还原并删除引擎的迁移时常常采取这种做法。通过下面的命令可以还原 `blorgh` 引擎的所有迁移：

```sh
$ bin/rails db:migrate SCOPE=blorgh VERSION=0
```

<a class="anchor" id="using-a-class-provided-by-the-application"></a>

### 使用应用提供的类

<a class="anchor" id="using-a-model-provided-by-the-application"></a>

#### 使用应用提供的模型

在创建引擎时，有时需要通过应用提供的类把引擎和应用连接起来。在 `blorgh` 引擎的例子中，我们需要把文章及其评论和作者关联起来。

一个典型的应用可能包含 `User` 类，可用于表示文章和评论的作者。但有的应用包含的可能是 `Person` 类而不是 `User` 类。因此，我们不能通过硬编码直接在引擎中建立和 `User` 类的关联。

为了避免例子变得复杂，我们假设应用包含的是 `User` 类（后文将对这个类进行配置）。通过下面的命令可以在应用中生成这个 `User` 类：

```sh
$ bin/rails g model user name:string
```

然后执行 `bin/rails db:migrate` 命令以创建 `users` 数据表。

同样，为了避免例子变得复杂，我们会在文章表单中添加 `author_name` 文本字段，用于输入作者名称。引擎会根据作者名称新建或查找已有的 `User` 对象，然后建立此 `User` 对象和其文章的关联。

具体操作的第一步是在引擎的 `app/views/blorgh/articles/_form.html.erb` 局部视图中添加 `author_name` 文本字段，添加的位置是在 `title` 字段之前：

```erb
<div class="field">
  <%= f.label :author_name %><br>
  <%= f.text_field :author_name %>
</div>
```

接下来，需要更新 `Blorgh::ArticleController#article_params` 方法，以便使用新增的表单参数：

```ruby
def article_params
  params.require(:article).permit(:title, :text, :author_name)
end
```

然后还要在 `Blorgh::Article` 模型中添加相关代码，以便把 `author_name` 字段转换为实际的 `User` 对象，并在保存文章之前把 `User` 对象和其文章关联起来。为此，需要为 `author_name` 字段设置 `attr_accessor`，也就是为其定义设值方法（setter）和读值方法（getter）。

为此，我们不仅需要为 `author_name` 添加 `attr_accessor`，还需要为 `author` 建立关联，并在 `app/models/blorgh/article.rb` 文件中添加 `before_validation` 调用。这里，我们暂时通过硬编码直接把 `author` 关联到 `User` 类上。

```ruby
attr_accessor :author_name
belongs_to :author, class_name: "User"

before_validation :set_author

private
  def set_author
    self.author = User.find_or_create_by(name: author_name)
  end
```

通过把 `author` 对象关联到 `User` 类上，我们成功地把引擎和应用连接起来。接下来还需要通过某种方式把 `blorgh_articles` 和 `users` 数据表中的记录关联起来。由于关联的名称是 `author`，我们应该为 `blorgh_articles` 数据表添加 `author_id` 字段。

在引擎中运行下面的命令可以生成 `author_id` 字段：

```sh
$ bin/rails g migration add_author_id_to_blorgh_articles author_id:integer
```

NOTE: 通过迁移名称和所提供的字段信息，Rails 知道需要向数据表中添加哪些字段，并会将相关代码写入迁移中，因此无需手动编写迁移代码。

我们应该在应用中运行迁移，因此需要通过下面的命令把引擎的迁移复制到应用中：

```sh
$ bin/rails blorgh:install:migrations
```

注意，上述命令实际只复制了一个迁移，因为之前的两个迁移在上一次执行此命令时已经复制过了。

```
NOTE Migration [timestamp]_create_blorgh_articles.blorgh.rb from blorgh has been skipped. Migration with the same name already exists.
NOTE Migration [timestamp]_create_blorgh_comments.blorgh.rb from blorgh has been skipped. Migration with the same name already exists.
Copied migration [timestamp]_add_author_id_to_blorgh_articles.blorgh.rb from blorgh
```

然后通过下面的命令运行迁移：

```sh
$ bin/rails db:migrate
```

现在，一切都已各就各位，我们完成了作者（用应用的 `users` 数据表中的记录表示）和文章（用引擎的 `blorgh_articles` 数据表中的记录表示）的关联。

最后，还需要把作者名称显示在文章页面上。为此，需要在 `app/views/blorgh/articles/show.html.erb` 文件中把下面的代码添加到“Title”之前：

```erb
<p>
  <b>Author:</b>
  <%= @article.author.name %>
</p>
```

<a class="anchor" id="using-a-controller-provided-by-the-application"></a>

#### 使用应用提供的控制器

默认情况下，Rails 控制器通常会通过继承 `ApplicationController` 类实现功能共享，例如身份验证和会话变量的访问。而引擎的作用域是和宿主应用隔离开的，因此其 `ApplicationController` 类具有独立的命名空间。独立的命名空间避免了代码冲突，但是引擎的控制器常常需要访问宿主应用的 `ApplicationController` 类中的方法，为此我们可以让引擎的 `ApplicationController` 类继承自宿主应用的 `ApplicationController` 类。在 Blorgh 引擎的例子中，我们可以对 `app/controllers/blorgh/application_controller.rb` 文件进行如下修改：

```ruby
module Blorgh
  class ApplicationController < ::ApplicationController
  end
end
```

默认情况下，引擎的控制器继承自 `Blorgh::ApplicationController` 类，因此通过上述修改，这些控制器将能够访问宿主应用的 `ApplicationController` 类中的方法，就好像它们是宿主应用的一部分一样。

当然，进行上述修改的前提是，宿主应用必须是具有 `ApplicationController` 类的应用。

<a class="anchor" id="configuring-an-engine"></a>

### 配置引擎

本节介绍如何使 `User` 类成为可配置的，然后介绍引擎的基本配置中的注意事项。

<a class="anchor" id="setting-configuration-settings-in-the-application"></a>

#### 在引擎中配置所使用的应用中的类

接下来我们需要想办法在引擎中配置所使用的应用中的用户类。如前文所述，应用中的用户类有可能是 `User`，也有可能是 `Person` 或其他类，因此这个用户类必须是可配置的。为此，我们需要在引擎中通过 `author_class` 选项指定所使用的应用中的用户类。

具体操作是在引擎的 `Blorgh` 模块中使用 `mattr_accessor` 方法，也就是把下面这行代码添加到引擎的 `lib/blorgh.rb` 文件中：

```ruby
mattr_accessor :author_class
```

`mattr_accessor` 方法的工作原理与 `attr_accessor` 和 `cattr_accessor` 方法类似，其作用是根据指定名称为模块提供设值方法和读值方法。使用时直接调用 `Blorgh.author_class` 方法即可。

接下来需要把 `Blorgh::Article` 模型切换到新配置，具体操作是在 `app/models/blorgh/article.rb` 中修改模型的 `belongs_to` 关联：

```ruby
belongs_to :author, class_name: Blorgh.author_class
```

`Blorgh::Article` 模型的 `set_author` 方法的定义也调用了 `Blorgh.author_class` 方法：

```ruby
self.author = Blorgh.author_class.constantize.find_or_create_by(name: author_name)
```

为了避免在每次调用 `Blorgh.author_class` 方法时调用 `constantize` 方法，我们可以在 `lib/blorgh.rb` 文件中覆盖 `Blorgh` 模块的 `author_class` 读值方法，在返回 `author_class` 前调用 `constantize` 方法：

```ruby
def self.author_class
  @@author_class.constantize
end
```

这时上述 `set_author` 方法的定义将变为：

```ruby
self.author = Blorgh.author_class.find_or_create_by(name: author_name)
```

修改后的代码更短，意义更明确。`author_class` 方法本来就应该返回 `Class` 对象。

因为修改后的 `author_class` 方法返回的是 `Class`，而不是原来的 `String`，我们还需要修改 `Blorgh::Article` 模型中 `belongs_to` 关联的定义：

```ruby
belongs_to :author, class_name: Blorgh.author_class.to_s
```

为了配置引擎所使用的应用中的类，我们需要使用初始化脚本。只有通过初始化脚本，我们才能在应用启动并调用引擎模型前完成相关配置。

在安装 `blorgh` 引擎的应用中，打开 `config/initializers/blorgh.rb` 文件，创建新的初始化脚本并添加如下代码：

```ruby
Blorgh.author_class = "User"
```

WARNING: 注意这里使用的是类的字符串版本，而非类本身。如果我们使用了类本身，Rails 就会尝试加载该类并引用对应的数据表。如果对应的数据表还未创建，就会抛出错误。因此，这里只能使用类的字符串版本，然后在引擎中通过 `constantize` 方法把类的字符串版本转换为类本身。

接下来我们试着添加一篇文章，整个过程和之前并无差别，只不过这次引擎使用的是我们在 `config/initializers/blorgh.rb` 文件中配置的类。

这样，我们再也不必关心应用中的用户类到底是什么，而只需关心该用户类是否实现了我们所需要的 API。`blorgh` 引擎只要求应用中的用户类实现了 `find_or_create_by` 方法，此方法需返回该用户类的对象，以便和对应的文章关联起来。当然，用户类的对象必须具有某种标识符，以便引用。

<a class="anchor" id="general-engine-configuration"></a>

#### 引擎的基本配置

有时我们需要在引擎中使用初始化脚本、国际化和其他配置选项。一般来说这些都可以实现，因为 Rails 引擎和 Rails 应用共享了相当多的功能。事实上，Rails 应用的功能就是 Rails 引擎的功能的超集。

引擎的初始化脚本包含了需要在加载引擎之前运行的代码，其存储位置是引擎的 `config/initializers` 文件夹。[初始化脚本](configuring.html#initializers)介绍过应用的 `config/initializers` 文件夹的功能，而引擎和应用的 `config/initializers` 文件夹的功能完全相同。对于标准的初始化脚本，需要完成的工作都是一样的。

引擎的区域设置也和应用相同，只需把区域设置文件放在引擎的 `config/locales` 文件夹中即可。

<a class="anchor" id="testing-an-engine"></a>

## 测试引擎

在使用生成器创建引擎时，Rails 会在引擎的 `test/dummy` 文件夹中创建一个小型的虚拟应用，作为测试引擎时的挂载点。通过在 `test/dummy` 文件夹中生成控制器、模型和视图，我们可以扩展这个应用，以更好地满足测试需求。

`test` 文件夹和典型的 Rails 测试环境一样，支持单元测试、功能测试和集成测试。

<a class="anchor" id="functional-tests"></a>

### 功能测试

在编写功能测试时，我们需要思考如何在 `test/dummy` 应用上运行测试，而不是在引擎上运行测试。这是由测试环境的设置决定的，只有通过引擎的宿主应用我们才能测试引擎的功能（尤其是引擎控制器）。也就是说，在编写引擎控制器的功能测试时，我们应该像下面这样处理典型的 `GET` 请求：

```ruby
module Blorgh
  class FooControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def test_index
      get foos_url
      ...
    end
  end
end
```

上述代码还无法正常工作，这是因为宿主应用不知道如何处理引擎的路由，因此我们需要手动指定路由。具体操作是把 `@routes` 实例变量的值设置为引擎的路由：

```ruby
module Blorgh
  class FooControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @routes = Engine.routes
    end

    def test_index
      get foos_url
      ...
    end
  end
end
```

上述代码告诉应用，用户对 `Foo` 控制器的 `index` 动作发起的 `GET` 请求应该由引擎的路由来处理，而不是由应用的路由来处理。

`include Engine.routes.url_helpers` 这行代码可以确保引擎的 URL 辅助方法能够在测试中正常工作。

<a class="anchor" id="improving-engine-functionality"></a>

## 改进引擎的功能

本节介绍如何在宿主应用中添加或覆盖引擎的 MVC 功能。

<a class="anchor" id="overriding-models-and-controllers"></a>

### 覆盖模型和控制器

要想扩展引擎的模型类和控制器类，我们可以在宿主应用中直接打开它们（因为模型类和控制器类只不过是继承了特定 Rails 功能的 Ruby 类）。通过打开类的技术，我们可以根据宿主应用的需求对引擎的类进行自定义，实际操作中通常会使用装饰器模式。

通过 `Class#class_eval` 方法可以对类进行简单修改，通过 `ActiveSupport::Concern` 模块可以完成对类的复杂修改。

<a class="anchor" id="a-note-on-decorators-and-loading-code"></a>

#### 使用装饰器以及加载代码时的注意事项

打开类时使用的装饰器并未在 Rails 应用中引用，因此 Rails 的自动加载系统不会加载这些装饰器。换句话说，我们需要手动加载这些装饰器。

下面是一些示例代码：

```ruby
# lib/blorgh/engine.rb
module Blorgh
  class Engine < ::Rails::Engine
    isolate_namespace Blorgh

    config.to_prepare do
      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
        require_dependency(c)
      end
    end
  end
end
```

不光是装饰器，对于添加到引擎中但没有在宿主应用中引用的任何东西，都需要进行这样的处理。

<a class="anchor" id="implementing-decorator-pattern-using-class-class-eval"></a>

#### 通过 `Class#class_eval` 实现装饰器模式

添加 `Article#time_since_created` 方法：

```ruby
# MyApp/app/decorators/models/blorgh/article_decorator.rb

Blorgh::Article.class_eval do
  def time_since_created
    Time.current - created_at
  end
end
```

```ruby
# Blorgh/app/models/article.rb

class Article < ApplicationRecord
  has_many :comments
end
```

覆盖 `Article#summary` 方法：

```ruby
# MyApp/app/decorators/models/blorgh/article_decorator.rb

Blorgh::Article.class_eval do
  def summary
    "#{title} - #{truncate(text)}"
  end
end
```

```ruby
# Blorgh/app/models/article.rb

class Article < ApplicationRecord
  has_many :comments
  def summary
    "#{title}"
  end
end
```

<a class="anchor" id="implementing-decorator-pattern-using-activesupport-concern"></a>

#### 通过 `ActiveSupport::Concern` 模块实现装饰器模式

对类进行简单修改时，使用 `Class#class_eval` 方法很方便，但对于复杂的修改，就应该考虑使用 [`ActiveSupport::Concern` 模块](http://api.rubyonrails.org/classes/ActiveSupport/Concern.html)了。`ActiveSupport::Concern` 模块能够管理互相关联、依赖的模块和类运行时的加载顺序，这样我们就可以放心地实现代码的模块化。

添加 `Article#time_since_created` 方法并覆盖 `Article#summary` 方法：

```ruby
# MyApp/app/models/blorgh/article.rb

class Blorgh::Article < ApplicationRecord
  include Blorgh::Concerns::Models::Article

  def time_since_created
    Time.current - created_at
  end

  def summary
    "#{title} - #{truncate(text)}"
  end
end
```

```ruby
# Blorgh/app/models/article.rb

class Article < ApplicationRecord
  include Blorgh::Concerns::Models::Article
end
```

```ruby
# Blorgh/lib/concerns/models/article.rb

module Blorgh::Concerns::Models::Article
  extend ActiveSupport::Concern

  # `included do` 中的代码可以在代码所在位置（article.rb）的上下文中执行，
  # 而不是在模块的上下文中执行（blorgh/concerns/models/article）。
  included do
    attr_accessor :author_name
    belongs_to :author, class_name: "User"

    before_validation :set_author

    private
      def set_author
        self.author = User.find_or_create_by(name: author_name)
      end
  end

  def summary
    "#{title}"
  end

  module ClassMethods
    def some_class_method
      'some class method string'
    end
  end
end
```

<a class="anchor" id="overriding-views"></a>

### 覆盖视图

Rails 在查找需要渲染的视图时，首先会在应用的 `app/views` 文件夹中查找。如果找不到，就会接着在所有引擎的 `app/views` 文件夹中查找。

在渲染 `Blorgh::ArticlesController` 的 `index` 动作的视图时，Rails 首先在应用中查找 `app/views/blorgh/articles/index.html.erb` 文件。如果找不到，就会接着在引擎中查找。

只要在应用中新建 `app/views/blorgh/articles/index.html.erb` 视图，就可覆盖引擎中的对应视图，这样我们就可以根据需要自定义视图的内容。

马上动手试一下，新建 `app/views/blorgh/articles/index.html.erb` 文件并添加下面的内容：

```erb
<h1>Articles</h1>
<%= link_to "New Article", new_article_path %>
<% @articles.each do |article| %>
  <h2><%= article.title %></h2>
  <small>By <%= article.author %></small>
  <%= simple_format(article.text) %>
  <hr>
<% end %>
```

<a class="anchor" id="engines-routes"></a>

### 路由

默认情况下，引擎和应用的路由是隔离开的。这种隔离是通过在 `Engine` 类中调用 `isolate_namespace` 方法实现的。这样，应用和引擎中的同名路由就不会发生冲突。

在 `config/routes.rb` 文件中，我们可以在 `Engine` 类上定义引擎的路由，例如：

```ruby
Blorgh::Engine.routes.draw do
  resources :articles
end
```

正因为引擎和应用的路由是隔离开的，当我们想要在应用中链接到引擎的某个位置时，就必须使用引擎的路由代理方法。如果像使用普通路由辅助方法那样直接使用 `articles_path` 辅助方法，将无法确定实际生成的链接，因为引擎和应用有可能都定义了这个辅助方法。

例如，对于下面的例子，如果是在应用中渲染模板，就会调用应用的 `articles_path` 辅助方法，如果是在引擎中渲染模板，就会调用引擎的 `articles_path` 辅助方法：

```erb
<%= link_to "Blog articles", articles_path %>
```

要想确保使用的是引擎的 `articles_path` 辅助方法，我们必须通过路由代理方法来调用这个辅助方法：

```erb
<%= link_to "Blog articles", blorgh.articles_path %>
```

要想确保使用的是应用的 `articles_path` 辅助方法，我们可以使用 `main_app` 路由代理方法：

```erb
<%= link_to "Home", main_app.root_path %>
```

这样，当我们在引擎中渲染模板时，上述代码生成的链接将总是指向应用的根路径。要是不使用 `main_app` 路由代理方法，在不同位置渲染模板时，上述代码生成的链接就既有可能指向引擎的根路径，也有可能指向应用的根路径。

当我们在引擎中渲染模板时，如果在模板中调用了应用的路由辅助方法，Rails 就有可能抛出未定义方法错误。如果遇到此类问题，请检查代码中是否存在未通过 `main_app` 路由代理方法直接调用应用的路由辅助方法的情况。

<a class="anchor" id="assets"></a>

### 静态资源文件

引擎和应用的静态资源文件的工作原理完全相同。由于引擎类继承自 `Rails::Engine` 类，应用知道应该在引擎的 `app/assets` 和 `lib/assets` 文件夹中查找静态资源文件。

和引擎的所有其他组件一样，引擎的静态资源文件应该具有独立的命名空间。也就是说，引擎的静态资源文件 `style.css` 的路径应该是 `app/assets/stylesheets/[engine name]/style.css`，而不是 `app/assets/stylesheets/style.css`。如果引擎的静态资源文件不具有独立的命名空间，那么就有可能和宿主应用中的同名静态资源文件发生冲突，而一旦发生冲突，宿主应用中的静态资源文件将具有更高的优先级，引擎的静态资源文件将被忽略。

假设引擎有 `app/assets/stylesheets/blorgh/style.css` 这么一个静态资源文件，要想在宿主应用中包含此文件，直接使用 `stylesheet_link_tag` 辅助方法即可：

```erb
<%= stylesheet_link_tag "blorgh/style.css" %>
```

同样，我们也可以使用 Asset Pipeline 的 `require` 语句加载引擎中的静态资源文件：

```css
/*
 *= require blorgh/style
*/
```

TIP: 记住，若想使用 Sass 和 CoffeeScript 等语言，要把相关的 gem 添加到引擎的 `.gemspec` 文件中。

<a class="anchor" id="separate-assets-precompiling"></a>

### 独立的静态资源文件和预编译

有时，宿主应用并不需要加载引擎的静态资源文件。例如，假设我们创建了一个仅适用于某个引擎的管理后台，这时宿主应用就不需要加载引擎的 `admin.css` 和 `admin.js` 文件，因为只有引擎的管理后台才需要这些文件。也就是说，在宿主应用的样式表中包含 `blorgh/admin.css` 文件没有任何意义。对于这种情况，我们应该显式定义那些需要预编译的静态资源文件，这样在执行 `bin/rails assets:precompile` 命令时，Sprockets 就会预编译所指定的引擎的静态资源文件。

我们可以在引擎的 `engine.rb` 文件中定义需要预编译的静态资源文件：

```ruby
initializer "blorgh.assets.precompile" do |app|
  app.config.assets.precompile += %w( admin.js admin.css )
end
```

关于这个问题的更多介绍，请参阅[Asset Pipeline](asset_pipeline.html)。

<a class="anchor" id="other-gem-dependencies"></a>

### 其他 gem 依赖

我们应该在引擎根目录中的 `.gemspec` 文件中声明引擎的 gem 依赖，因为我们可能会以 gem 的方式安装引擎。如果在引擎的 `Gemfile` 文件中声明 gem 依赖，在通过 `gem install` 命令安装引擎时，就无法识别并安装这些依赖，这样引擎安装后将无法正常工作。

要想让 `gem install` 命令能够识别引擎的 gem 依赖，只需在引擎的 `.gemspec` 文件的 `Gem::Specification` 代码块中进行声明：

```ruby
s.add_dependency "moo"
```

还可以像下面这样声明用于开发环境的依赖：

```ruby
s.add_development_dependency "moo"
```

不管是用于所有环境的依赖，还是用于开发环境的依赖，在执行 `bundle install` 命令时都会被安装，只不过用于开发环境的依赖只会在运行引擎测试时用到。

注意，如果有些依赖在加载引擎时就必须加载，那么应该在引擎初始化之前就加载它们，例如：

```ruby
require 'other_engine/engine'
require 'yet_another_engine/engine'

module MyEngine
  class Engine < ::Rails::Engine
  end
end
```

<a class="anchor" id="active-support-on-load-hooks"></a>

## Active Support `on_load` 钩子

由于 Ruby 是动态语言，所有有些代码会导致加载相关的 Rails 组件。以下述代码片段为例：

```ruby
ActiveRecord::Base.include(MyActiveRecordHelper)
```

加载这段代码时发现有 `ActiveRecord::Base`，因此 Ruby 会查找这个常量的定义，然后引入它。这就导致整个 Active Record 组件在启动时加载。

`ActiveSupport.on_load` 可以延迟加载代码，在真正需要时才加载。上述代码可以修改为：

```ruby
ActiveSupport.on_load(:active_record) { include MyActiveRecordHelper }
```

这样修改之后，加载 `ActiveRecord::Base` 时才会引入 `MyActiveRecordHelper`。

<a class="anchor" id="how-does-it-work-questionmark"></a>

### 运作方式

在 Rails 框架中，加载相应的库时会调用这些钩子。例如，加载 `ActionController::Base` 时，调用 `:action_controller_base` 钩子。也就是说，`ActiveSupport.on_load` 调用设定的 `:action_controller_base` 钩子在 `ActionController::Base` 的上下文中调用（因此 `self` 是 `ActionController::Base` 的实例）。

<a class="anchor" id="modifying-code-to-use-on-load-hooks"></a>

### 修改代码，使用 `on_load` 钩子

修改代码的方式很简单。如果代码引用了某个 Rails 组件，如 `ActiveRecord::Base`，只需把代码放在 `on_load` 钩子中。

**示例 1**

```ruby
ActiveRecord::Base.include(MyActiveRecordHelper)
```

改为：

```ruby
ActiveSupport.on_load(:active_record) { include MyActiveRecordHelper }
# self 在这里指代 ActiveRecord::Base 实例，因此可以直接调用 #include
```

*   示例 2**

```ruby
ActionController::Base.prepend(MyActionControllerHelper)
```

改为：

```ruby
ActiveSupport.on_load(:action_controller_base) { prepend MyActionControllerHelper }
# self 在这里指代 ActionController::Base 实例，因此可以直接调用 #prepend
```

**示例 3**

```ruby
ActiveRecord::Base.include_root_in_json = true
```

改为：

```ruby
ActiveSupport.on_load(:active_record) { self.include_root_in_json = true }
# self 在这里指代 ActiveRecord::Base 实例
```

<a class="anchor" id="available-hooks"></a>

### 可用的钩子

下面是可在代码中使用的钩子。

若想勾入下述某个类的初始化过程，使用相应的钩子。

| 类 | 可用的钩子  |
|---|---|
| `ActionCable` | `action_cable`  |
| `ActionController::API` | `action_controller_api`  |
| `ActionController::API` | `action_controller`  |
| `ActionController::Base` | `action_controller_base`  |
| `ActionController::Base` | `action_controller`  |
| `ActionController::TestCase` | `action_controller_test_case`  |
| `ActionDispatch::IntegrationTest` | `action_dispatch_integration_test`  |
| `ActionMailer::Base` | `action_mailer`  |
| `ActionMailer::TestCase` | `action_mailer_test_case`  |
| `ActionView::Base` | `action_view`  |
| `ActionView::TestCase` | `action_view_test_case`  |
| `ActiveJob::Base` | `active_job`  |
| `ActiveJob::TestCase` | `active_job_test_case`  |
| `ActiveRecord::Base` | `active_record`  |
| `ActiveSupport::TestCase` | `active_support_test_case`  |
| `i18n` | `i18n`  |

<a class="anchor" id="configuration-hooks"></a>

## 配置钩子

下面是可用的配置钩子。这些钩子不勾入具体的组件，而是在整个应用的上下文中运行。

| 钩子 | 使用场景  |
|---|---|
| `before_configuration` | 第一运行，在所有初始化脚本运行之前调用。  |
| `before_initialize` | 第二运行，在初始化各组件之前运行。  |
| `before_eager_load` | 第三运行。`config.cache_classes` 设为 `false` 时不运行。  |
| `after_initialize` | 最后运行，各组件初始化完成之后调用。  |

**示例**

```ruby
config.before_configuration { puts 'I am called before any initializers' }
```
