引擎入门
============================

本章节中您将学习有关引擎的知识，以及引擎如何通过简洁易用的方式为Rails应用插上飞翔的翅膀。

通过学习本章节，您将获得如下知识：

* 引擎是什么
* 如何生成一个引擎
* 为引擎添加特性
* 为Rails应用添加引擎
* 给Rails中的引擎提供重载功能

--------------------------------------------------------------------------------

引擎是什么？ 
-----------------

引擎可以被认为是一个可以为其宿主提供函数功能的中间件。一个Rails应用可以被看作一个"超级给力"的引擎，因为`Rails::Application` 类是继承自 `Rails::Engine`的。


从某种意义上说，引擎和Rails应用几乎可以说是双胞胎，差别很小。通过本章节的学习，你会发现引擎和Rails应用的结构几乎是一样的。


引擎和插件也是近亲，拥有相同的`lib`目录结构，并且都是使用`rails plugin new`命令生成。不同之处在于，一个引擎对于Rails来说是一个"发育完全的插件"(使用命令行生成引擎时会加`--full`选项)。在这里我们将使用几乎包含`--full`选项所有特性的`--mountable` 来代替。本章节中"发育完全的插件"和引擎是等价的。一个引擎可以是一个插件，但一个插件不能被看作是引擎。 

我们将创建一个叫"blorgh"的引擎。这个引擎将为其宿主提供博添加博客和博客评论等功能。刚出生的"blorgh"引擎也许会显得孤单，不过用不了多久，我们将看到她和自己的小伙伴一起愉快的聊天。

引擎也可以离开他的应用宿主独立存在。这意味着一个应用可以通过一个路径助手获得一个`articles_path`方法，使用引擎也可以生成一个名为`articles_path`的方法，并且两者不会冲突。同理，控制器，模型，数据库表名都是属于不同命名空间的。接下来我们来讨论该如何实现。

你心里须清楚Rails应用是老大，引擎是老大的小弟。一个Rails应用在她的地盘里面是老大，引擎的作用只是锦上添花。


可以看看下面的一些优秀的引擎项目,比如[Devise](https://github.com/plataformatec/devise) ，一个为其宿主应用提供权限认证功能的引擎；[Forem](https://github.com/radar/forem), 一个提供论坛功能的引擎；[Spree](https://github.com/spree/spree)，一个提供电子商务平台功能的引擎。[RefineryCMS](https://github.com/refinery/refinerycms), 一个 CMS 引擎 。


最后，大部分引擎开发工作离不开James Adam,Piotr Sarnacki 等Rails核心开发成员，以及很多默默无闻付出的人们。如果你见到他们，别忘了向他们致谢！ 

生成一个引擎
--------------------

为了生成一个引擎，你必须使用生成插件的命令和适当的选项配合。比如你要生成"blorgh"应用 ，你需要一个"mountable"引擎。那么在命令行终端你就要敲下如下代码： 

```bash
$ bin/rails plugin new blorgh --mountable
```

生成插件的命令相关的帮助信息可以敲下面代码得到： 

```bash
$ bin/rails plugin --help
```

`--mountable` 选项告诉生成器你想创建一个"mountable"，并且命名空间独立的引擎。如果你用选项`--full`的话，生成器几乎会做一样的操作。`--full` 选项告诉生成器你想创建一个引擎，包含如下结构： 


  * 一个 `app` 目录树
  * 一个 `config/routes.rb` 文件:

    ```ruby
    Rails.application.routes.draw do
    end
    ```

  * 一个`lib/blorgh/engine.rb`文件，以及在一个标准的Rails应用文件目录的`config/application.rb`中的如下声明： 

    ```ruby
    module Blorgh
      class Engine < ::Rails::Engine
      end
    end
    ```

`--mountable`选项会比`--full`选项多做的事情有:

  * 生成若干资源文件(`application.js` and `application.css`) 
  * 添加一个命名空间为`ApplicationController` 的子集
  * 添加一个命名空间为`ApplicationHelper` 的子集
  * 添加 一个引擎的布局视图模版
  * 在`config/routes.rb`中声明独立的命名空间 ；


    ```ruby
    Blorgh::Engine.routes.draw do
    end
    ```

  在`lib/blorgh/engine.rb`中声明独立的命名空间: 

    ```ruby
    module Blorgh
      class Engine < ::Rails::Engine
        isolate_namespace Blorgh
      end
    end
    ```

除此之外，`--mountable`选项告诉生成器在引擎内部的 `test/dummy` 文件夹中创建一个简单应用，在`test/dummy/config/routes.rb`中添加简单应用的路径。

```ruby
mount Blorgh::Engine, at: "blorgh"
```

### 引擎探秘

#### 文件冲突


在我们刚才创建的引擎根目录下有一个`blorgh.gemspec`文件。如果你想把引擎和Rails应用整合，那么接下来要做的是在目标Rails应用的`Gemfile`文件中添加如下代码：

```ruby
gem 'blorgh', path: "vendor/engines/blorgh"
```

接下来别忘了运行`bundle install`命令，Bundler通过解析刚才在`Gemfile`文件中关于引擎的声明，会去解析引擎的`blorgh.gemspec`文件，以及`lib`文件夹中名为`lib/blorgh.rb`的文件，然后定义一个`Blorgh`模块:

```ruby
require "blorgh/engine"

module Blorgh
end
```
提示： 某些引擎会使用一个全局配置文件来配置引擎，这的确是个好主意，所以如果你提供了一个全局配置文件来配置引擎的模块，那么这会更好的将你的模块的功能封装起来。

`lib/blorgh/engine.rb`文件中定义了引擎的基类。

```ruby
module Blorgh
  class Engine < Rails::Engine
    isolate_namespace Blorgh
  end
end
```
因为引擎继承自`Rails::Engine`类，gem会通知Rails有一个引擎的特别路径，之后会正确的整合引擎到Rails应用中。会为Rails应用中的模型，控制器，视图和邮件等配置加载引擎的`app`目录的路径。

`isolate_namespace`方法必须拿出来单独谈谈。这个方法会把引擎模块中与控制器，模型，路径等模块内的同名组件隔离。如果没他的话，可能会把引擎的内部方法暴露给其它模块，这样会破坏引擎的封装性，可能会引发不可预期的风险，比如引擎的内部方法被其他模块重载。举个例子，如果没有用命名空间对模块进行隔离，各模块的helpers方法会发生冲突，那么引擎内部的helper方法会被Rails应用的控制器所调用。


提示：强烈建议您使用`isolate_namespace`方法定义引擎的模块，如果没使用他，这可能会在一个Rails应用中和其他模块冲突。

命名空间对于执行像`bin/rails g model`的命令意味者什么呢？ 比如`bin/rails g model article`，这个操作不会产生一个`Article`，而是`Blorgh::Article`。除此之外，模型的数据库表名也是命名空间化的，会用`blorgh_articles` 来代替`articles`。与模型的命名空间类似，控制器中的 `ArticlesController`会被`Blorgh::ArticlesController`取代。而且和控制器相关的视图也会从`app/views/articles`变成`app/views/blorgh/articles`，邮件模块也是类似的情况。

总而言之，路径同引擎一样也是有命名空间的，命名空间的重要性将会在本指南中的[Routes](#routes)继续讨论。


#### `app` 目录

`app`内部的结构和一般的Rails应用差不多，都包含 `assets`, `controllers`, `helpers`,
`mailers`, `models` and `views` 等文件。`helpers`, `mailers` and `models` 文件夹是空的，我们就不详谈了。我们将会在将来的章节中讨论引擎的模型的时候，深入介绍。

`app/assets`文件夹包含`images`, `javascripts`和`stylesheets`，这些你在一个Rails应用中应该很熟悉了。不同之处是，它们每个文件夹下包含一个和引擎同名的子目录，因为引擎是命名空间化的，那么assets也会遵循这一规定 。

`app/controllers`文件夹下有一个`blorgh`文件夹，他包含一个名为`application_controller.rb`的文件。这个文件为引擎提供控制器的一般功能。`blorgh`文件夹是专属于`blorgh`引擎的，通过命名空间化的目录结构，可以很好的将引擎的控制器与外部隔离起来，免受其他引擎或Rails应用的影响。

提示：在引擎内部的`ApplicationController`类命名方式和Rails 应用类似是为了方便你将Rails应用和引擎整合。

最后，`app/views` 文件夹包含一个`layouts`文件。他包含一个`blorgh/application.html.erb`文件。这个文件可以为你的引擎定制视图。如果这个引擎被当作独立的组件使用，那么你可以通过这个视图文件来定制引擎的视图，就和Rails应用中的`app/views/layouts/application.html.erb`一样、

如果你不希望强制引擎的使用者使用你的布局样式，那么可以删除这个文件，使用其他控制器的视图文件。

#### `bin` 目录

这个目录包含了一个`bin/rails`文件，她为你像在Rails应用中使用`rails` 命令等命令提供了支持，比如为该引擎生成模型和视图等操作：

```bash
$ bin/rails g model
```

必须要注意的是，在引擎内部使用命令行工具生成的组件都会自动调用 `isolate_namespace`方法，以达到组件的命名空间化。

#### `test`目录  

`test`目录是引擎执行测试的地方，为了方便测试，`test/dummy`内置了一个精简版本的Rails 应用，这个应用可以和引擎整合，方便测试，他在`test/dummy/config/routes.rb` 中的声明如下： 

```ruby
Rails.application.routes.draw do
  mount Blorgh::Engine => "/blorgh"
end
```

mounts这行的意思是Rails应用只能通过`/blorgh`路径来访问引擎。

在测试目录下面有一个`test/integration`子目录，该子目录是为了引擎与测试交互而存在的。其他的目录也可以如此创建。举个例子，你想为你的模型创建一个测试目录，那么他的文件结构和`test/models`是一样的。

引擎功能简介
------------------------------


本章中创建的引擎需要提供发布博客，博客评论，关注[Getting Started
Guide](getting_started.html)某人是否有新博客发布等功能。

### 生成一个Article 资源


一个博客引擎首先要做的是生成一个`Article` 模型和相关的控制器。为了快速生成这些，你可以使用Rails的generator和 scaffold命令来实现：

```bash
$ bin/rails generate scaffold article title:string text:text
```

这个命令执行后会得到如下输出：

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
invoke      test_unit
create        test/helpers/blorgh/articles_helper_test.rb
invoke  assets
invoke    js
create      app/assets/javascripts/blorgh/articles.js
invoke    css
create      app/assets/stylesheets/blorgh/articles.css
invoke  css
create    app/assets/stylesheets/scaffold.css
```

scaffold生成器做的第一件事情是执行生成`active_record`操作，这将会为资源生成一个模型和迁移集，这里要注意的是，生成的迁移集的名字是 `create_blorgh_articles`而非Raisl应用中`create_articles`。这归功于`Blorgh::Engine`类中`isolate_namespace`方法。这里的模型也是命名空间化的，本来应该是`app/models/article.rb`，现在被 `app/models/blorgh/article.rb`取代。

接下来，模型的单元测试`test_unit`生成器会生成一个测试文件`test/models/blorgh/article_test.rb`(有别于`test/models/article_test.rb`)，和一个fixture`test/fixtures/blorgh/articles.yml`文件


接下来，该资源作为引擎的一部分会被插入`config/routes.rb`中。该引擎的资源`resources :articles`在`config/routes.rb`的声明如下：

```ruby
Blorgh::Engine.routes.draw do
  resources :articles
end
```

这里需要注意的是该资源的路径已经和引擎`Blorgh::Engine` 关联上了，就像普通的`YourApp::Application`一样。这样访问引擎的资源路径就被限制在特定的范围。可以提供给[test directory](#test-directory)访问。这样也可以让引擎的资源与Rails应用隔离开来。具体的详情亏参考[Routes](#routes)。

接下来，`scaffold_controller`生成器被触发了，生成一个名为`Blorgh::ArticlesController`的控制器(`app/controllers/blorgh/articles_controller.rb`)，以及和控制器相关的视图`app/views/blorgh/articles`。这个生成器同时也会自动为控制器生成一个测试用例(`test/controllers/blorgh/articles_controller_test.rb`)和帮助方法(`app/helpers/blorgh/articles_controller.rb`)。

生成器创建的所以对象几乎都是命名空间化的，控制器的类被定义在`Blorgh`模块中：  

```ruby
module Blorgh
  class ArticlesController < ApplicationController
    ...
  end
end
```

提示：`Blorgh::ApplicationController`类继承了`ApplicationController`类，而非一个应用的`ApplicationController`类。

`app/helpers/blorgh/articles_helper.rb`中的helper模块也是命名空间化的：
```ruby
module Blorgh
  module ArticlesHelper
    ...
  end
end
```
这样有助于避免和其他引擎或应用的同名资源发生冲突。

最后，生成该资源相关的样式表和js脚本文件，文件路径分别是`app/assets/javascripts/blorgh/articles.js` 和
`app/assets/stylesheets/blorgh/articles.css`。稍后你将了解如何使用它们。

一般情况下，基本的样式表并不会应用到引擎中，因为引擎的布局文件`app/views/layouts/blorgh/application.html.erb`并没载入。如果要让基本的样式表文件对引擎生效。必须在`<head>`标签内插入如下代码： 

```erb
<%= stylesheet_link_tag "scaffold" %>
```

现在，你已经了解了在引擎根目录下使用 scaffold 生成器进行数据库创建和迁移的整个过程，接下来，在`test/dummy`目录下运行`rails server` 后，用浏览器打开`http://localhost:3000/blorgh/articles` 后，随便浏览一下，刚才你生成的第一个引擎的功能。


如果你喜欢在控制台工作，那么`rails console`就像一个Rails应用。记住：`Article`是命名空间化的，所以你必须使用`Blorgh::Article`来访问它。


```ruby
>> Blorgh::Article.find(1)
=> #<Blorgh::Article id: 1 ...>
```

最后要做的一件事是让`articles`资源通过引擎的根目录就能访问。比如我打开`http://localhost:3000/blorgh`后，就能看到一个博客的主题列表。要实现这个目的，我们可以在引擎的`config/routes.rb`中做如下配置：  


```ruby
root to: "articles#index"
```

现在人们将不需要到引擎的`/articles`目录下浏览主题了，这意味着`http://localhost:3000/blorgh`获得的内容和`http://localhost:3000/blorgh/articles`是相同的。

### 生成一个评论资源

现在，这个引擎可以创建一个新主题，那么自然需要能够评论的功能。为了实现这个功能，你需要生成一个评论模型，以及和评论相关的控制器，并修改主题的结构用以显示评论和添加评论。

在Rails应用的根目录下，运行模型生成器，生成一个`Comment`模型，相关的表包含下面两个字段：整型 `article_id`和文本`text`。

```bash
$ bin/rails generate model Comment article_id:integer text:text
```

上述操作将会输出下面的信息：

```
invoke  active_record
create    db/migrate/[timestamp]_create_blorgh_comments.rb
create    app/models/blorgh/comment.rb
invoke    test_unit
create      test/models/blorgh/comment_test.rb
create      test/fixtures/blorgh/comments.yml
```

生成器会生成必要的模型文件，由于是命名空间化的，所以会在`blorgh`目录下生成`Blorgh::Comment`类。然后使用数据迁移命令对blorgh_comments表进行操作：

```bash
$ rake db:migrate
```

为了在主题中显示评论，需要在`app/views/blorgh/articles/show.html.erb`的 "Edit" 按钮之前添加如下代码：

```html+erb
<h3>Comments</h3>
<%= render @article.comments %>
```

上述代码需要为评论在`Blorgh::Article`模型中添加一个"一对多"(`has_many`)的关联声明。为了添加上述声明，请打开`app/models/blorgh/article.rb`，并添加如下代码： 

```ruby
has_many :comments
```

修改过的模型关系是这样的：

```ruby
module Blorgh
  class Article < ActiveRecord::Base
    has_many :comments
  end
end
```

提示：　因为　`一对多`(`has_many`) 的关联是在`Blorgh` 内部定义的，Rails明白你想为这些对象使用`Blorgh::Comment`模型。所以不需要特别使用类名来声明。

接下来，我们需要为主题提供一个表单提交评论，为了实现这个功能，请在 `app/views/blorgh/articles/show.html.erb` 中调用 `render @article.comments` 方法来显示表单:

```erb
<%= render "blorgh/comments/form" %>
```

接下来，上述代码中的表单必须存在才能被渲染，我们需要做的就是在`app/views/blorgh/comments`目录下创建一个`_form.html.erb`文件：

```html+erb
<h3>New comment</h3>
<%= form_for [@article, @article.comments.build] do |f| %>
  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>
  <%= f.submit %>
<% end %>
```

当表单被提交后，它将通过路径`/articles/:article_id/comments`给引擎发送一个`POST`请求。现在这个路径还不存在，所以我们可以修改`config/routes.rb`中的`resources :articles`的相关路径来实现它:

```ruby
resources :articles do
  resources :comments
end
```

给表单请求创建一个和评论相关的嵌套路径。

现在路径创建好了，相关的控制器却不存在，为了创建它们，我们使用命令行工具来创建它们：

```bash
$ bin/rails g controller comments
```

执行上述操作后，会输出下面的信息：

```
create  app/controllers/blorgh/comments_controller.rb
invoke  erb
 exist    app/views/blorgh/comments
invoke  test_unit
create    test/controllers/blorgh/comments_controller_test.rb
invoke  helper
create    app/helpers/blorgh/comments_helper.rb
invoke    test_unit
create      test/helpers/blorgh/comments_helper_test.rb
invoke  assets
invoke    js
create      app/assets/javascripts/blorgh/comments.js
invoke    css
create      app/assets/stylesheets/blorgh/comments.css
```

表单通过路径`/articles/:article_id/comments`提交`POST`请求后，`Blorgh::CommentsController`会响应一个`create`动作。
这个的动作在`app/controllers/blorgh/comments_controller.rb`的定义如下：

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

最后，我们希望在浏览主题时显示和主题相关的评论，但是如果你现在想提交一条评论，会发现遇到如下错误：　

```
Missing partial blorgh/comments/comment with {:handlers=>[:erb, :builder],
:formats=>[:html], :locale=>[:en, :en]}. Searched in:   *
"/Users/ryan/Sites/side_projects/blorgh/test/dummy/app/views"   *
"/Users/ryan/Sites/side_projects/blorgh/app/views"
```

显示上述错误是因为引擎无法知道和评论相关的内容。Rails 应用会首先去该应用的(`test/dummy`) `app/views`目录搜索，之后才会到引擎的`app/views` 目录下搜索匹配的内容。当找不到匹配的内容时，会抛出异常。引擎知道去`blorgh/comments/comment`目录下搜索，是因为模型对象是从`Blorgh::Comment`接受到请求的。


现在，为了显示评论，我们需要创建一个新文件 `app/views/blorgh/comments/_comment.html.erb`，并在该文件中添加如下代码：

```erb
<%= comment_counter + 1 %>. <%= comment.text %>
```

本地变量 `comment_counter`是通过`<%= render @article.comments %>`获取的。这个变量是评论的计数器。它用来显示评论的总数。

现在，我们完成一个带评论功能的博客引擎后，接下来我们将介绍如何将引擎与Rails应用整合。

和Rails应用整合
---------------------------

在Rails应用中可以很方便的使用引擎，本节将介绍如何将引擎和Rails应用整合。当然通常会把引擎和Rails应中的`User`类关联起来。


### 整合前的准备工作

首先，引擎需要在一个Rails应用中的`Gemfile`进行声明。如果我们无法知道Rails应用中是否有这些声明，那么我们可以在引擎目录之外创建一个新的Raisl应用：

```bash
$ rails new unicorn
```

一般而言，在Gemfile声明引擎和在Rails应用的一般Gem声明没有区别：

```ruby
gem 'devise'
```

但是，假如你在自己的本地机器上开发`blorgh`引擎，那么你需要在`Gemfile`中特别声明`:path`项：

```ruby
gem 'blorgh', path: "/path/to/blorgh"
```

运行`bundle`命令，安装gem 。 

如前所述，在`Gemfile`中声明的gem将会与Rails框架一起加载。应用会从引擎中加载 `lib/blorgh.rb`和`lib/blorgh/engine.rb`等与引擎相关的主要文件。

为了在Rails应用内部可以调用引擎，我们必须在Rails应用的`config/routes.rb`中做如下声明：

```ruby
mount Blorgh::Engine, at: "/blog"
```
上述代码的意思是引擎将被整合进Rails应用中的"/blog"下。当Rails应用通过 `rails server`启动时，可通过`http://localhost:3000/blog`访问。

提示： 对于其他引擎，比如 `Devise` ，他在处理路径的方式上稍有不同，可以通过自定义的助手方法比如`devise_for`来处理路径。这些路径助理方法工作千篇一律，为引擎大部分功能提供预定义路径的个性化支持。

### 建立引擎

和引擎相关的两个`blorgh_articles` 和 `blorgh_comments`表需要迁移到Rails应用数据库中，以保证引擎的模型能查询正确。迁移引擎的数据可以使用下面的命令：

```bash
$ rake blorgh:install:migrations
```

如果你有多个引擎需要数据迁移，可以使用`railties:install:migrations`命令来实现：

```bash
$ rake railties:install:migrations
```

第一次运行上述命令的时候，将会从引擎中复制所有的迁移集。当下次运行的时候，他只会迁移没被迁移过的数据。第一次运行该命令会显示如下信息： 

```bash
Copied migration [timestamp_1]_create_blorgh_articles.rb from blorgh
Copied migration [timestamp_2]_create_blorgh_comments.rb from blorgh
```

第一个时间戳(`[timestamp_1]`)将会是当前时间，接着第二个时间戳(`[timestamp_2]`) 将会是当前时间+1妙。这样做的原因是之前已经为引擎做过数据迁移操作。

在Rails应用中为引擎做数据迁移可以简单的使用`rake db:migrate` 执行操作。当通过`http://localhost:3000/blog`访问引擎的时候，你会发现主题列表是空的。这是因为在应用中创建的表与在引擎中创建的表是不同的。接下来你将发现应用中的引擎和独立环境中的引擎有很多不同之处。

如果你只想对某一个引擎执行数据迁移操作，那么可以通过`SCOPE`声明来实现：

```bash
rake db:migrate SCOPE=blorgh
```

这将有利于你的引擎执行数据迁移的回退操作。
如果想让引擎的数据回到原始状态，那么可以执行下面的操作： 

```bash
rake db:migrate SCOPE=blorgh VERSION=0
```

### 访问Rails应用中的类

#### 访问Rails应用中的模型

当一个引擎创建之后，那么就需要Rails应用提供一个专属的类，将引擎和Rails应用关联起来。在本例中，`blorgh`引擎需要Rails应用提供作者来发表主题和评论。

一个典型的Rails应用会有一个`User`类来实现发布主题和评论的功能。也许某些应用里面会用`Person`类来做这些事情。因此，引擎不应该硬编码到一个`User`类中。

为了简单起见，我们的应用将会使用`User`类来实现和引擎的关联。那么我们可以在应用中使用命令：

```bash
rails g model user name:string
```

在这里执行`rake db:migrate`命令是为了我们的应用中有`users`表，以备将来使用。

为了简单起见，主题表单也会添加一个新的字段`author_name`，这样方便用户填写他们的名字。
当用户提交了他们的名字后，引擎将会判断是否存在该用户，如果不存在，就将该用户添加到数据库里面，并通过`User`对象把该用户和主题关联起来。

首先需要在引擎内部的`app/views/blorgh/articles/_form.html.erb`文件中添加
`author_name`项。这些内容可以添加到`title`之前，代码如下：

```html+erb
<div class="field">
  <%= f.label :author_name %><br>
  <%= f.text_field :author_name %>
</div>
```

接下来我们需要更新`Blorgh::ArticleController#article_params`方法接受参数的格式：

```ruby
def article_params
  params.require(:article).permit(:title, :text, :author_name)
end
```

模型`Blorgh::Article`需要添加一些代码把`author_name`和`User`对象关联起来。以确保保存主题时，主题相关的 `author`也被同时保存了。同时我们需要为这个字段定义一个`attr_accessor`。以方便我们读取或设置它的属性。


上述工作完成后，你需要为`author_name`添加一个属性读写器(`attr_accessor`),调用在`app/models/blorgh/article.rb`的`before_save`方法以便关联。`author` 将会通过硬编码的方式和`User`关联：

```ruby
attr_accessor :author_name
belongs_to :author, class_name: "User"

before_save :set_author

private
  def set_author
    self.author = User.find_or_create_by(name: author_name)
  end
```

和`author`关联的`User`类，成了引擎和Rails应用之间联系的纽带。于此同时，也需要把`blorgh_articles`和 `users` 表进行关联。因为通过`author`关联，那么需要给`blorgh_articles`表添加一个`author_id`字段来实现关联。


为了生成这个新字段，我们需要在引擎中执行如下操作：

```bash
$ bin/rails g migration add_author_id_to_blorgh_articles author_id:integer
```

提示：假如数据迁移命令后面跟了一个字段声明。那么Rails会认为你想添加一个新字段到声明的表中，而无需做其他操作。


这个数据迁移操作必须在Rails应用中执行，为此，你必须保证是第一次在命令行中执行下面的操作：


```bash
$ rake blorgh:install:migrations
```

需要注意的是，这里只会发生一次数据迁移，这是因为前两个数据迁移拷贝已经执行过迁移操作了。

```
NOTE Migration [timestamp]_create_blorgh_articles.rb from blorgh has been
skipped. Migration with the same name already exists. NOTE Migration
[timestamp]_create_blorgh_comments.rb from blorgh has been skipped. Migration
with the same name already exists. Copied migration
[timestamp]_add_author_id_to_blorgh_articles.rb from blorgh
```

运行数据迁移命令：


```bash
$ rake db:migrate
```

现在所有准备工作都就绪了。上述操作实现了Rails应用中的`User`表和作者关联，引擎中的`blorgh_articles`表和主题关联。

最后，主题的作者将会显示在主题页面。在`app/views/blorgh/articles/show.html.erb`文件中的`Title`之前添加如下代码：

```html+erb
<p>
  <b>Author:</b>
  <%= @article.author %>
</p>
```

使用`<%=` 标签和`to_s`方法将会输出`@article.author`。默认情况下，这看上去很丑：

```
#<User:0x00000100ccb3b0>
```

这不是我们希望看到的，所以最好显示用户的名字。为此，我去需要给Rails应用中的`User`类添加`to_s`方法：

```ruby
def to_s
  name
end
```

现在，我们将看到主题的作者名字 。 

#### 与控制器交互

Rails应用的控制器一般都会和权限控制，会话变量访问模块共享代码，因为它们都是默认继承自
 `ApplicationController`类。Rails的引擎因为是命名空间化的，和主应用独立的模块。所以每个引擎都会有自己的`ApplicationController`类。这样做有利于避免代码冲突，但很多时候，引擎控制器需要调用主应用的`ApplicationController`。这里有一个简单的方法是让引擎的控制器继承主应用的`ApplicationController`。我们的Blorgh引擎会在`app/controllers/blorgh/application_controller.rb`中实现上述操作：


```ruby
class Blorgh::ApplicationController < ApplicationController
end
```

一般情况下，引擎的控制器是继承自`Blorgh::ApplicationController`，所以，做了上述改变后，引擎可以访问主应用的`ApplicationController`了，也就是说，它变成了主应用的一部分。

上述操作的一个必要条件是：和引擎相关的Rails应用必须包含一个`ApplicationController`类。

### 配置引擎


本章节将介绍如何让`User`类可配置化。下面我们将介绍配置引擎的细节。

#### 配置应用的配置文件

接下来的内容我们将讲述如何让应用中诸如`User`的类对象为引擎提供定制化的服务。如前所述，引擎要访问应用中的类不一定每次都叫`User`，所以我来实现可定制化的访问，必须在引擎里面设置一个名为`author_class`和应用中的`User`类进行交互。

为了定义这个设置，你将在引擎的`Blorgh` 模块中声明一个`mattr_accessor`方法和`author_class`关联。在引擎中的`lib/blorgh.rb`代码如下：


```ruby
mattr_accessor :author_class
```

这个方法的功能和它的兄弟`attr_accessor`和`cattr_accessor`功能类似，但是特别提供了一个方法，可以根据指定名字来对类或模块访问。我们使用它的时候，必须加上`Blorgh.author_class`前缀。


接下来要做的是通过新的设置器来选择`Blorgh::Article`的模型，将模型关联`belongs_to`(`app/models/blorgh/article.rb`)修改如下：

```ruby
belongs_to :author, class_name: Blorgh.author_class
```

模型`Blorgh::Article`中的`set_author`方法也可以使用这个类：

```ruby
self.author = Blorgh.author_class.constantize.find_or_create_by(name: author_name)
```

为了确保`author_class`调用`constantize`的结果一致，你需要重载`lib/blorgh.rb`中`Blorgh` 模块的`author_class`的get方法，确保在获取返回值之前调用`constantize`方法：
```ruby
def self.author_class
  @@author_class.constantize
end
```

上述代码将会让`set_author` 方法变成这样：

```ruby
self.author = Blorgh.author_class.find_or_create_by(name: author_name)
```

总之，这样会更明确它的行为，`author_class`方法会保证返回一个`Class`对象。


我们让`author_class`方法返回一个`Class`替代`String`后，我们也必须修改`Blorgh::Article`模块中的`belongs_to`定义：

```ruby
belongs_to :author, class_name: Blorgh.author_class.to_s
```

为了让这些配置在应用中生效，必须使用一个初始化器。使用初始化器可以保证这种配置在Rails应用调用引擎模块之前就生效，因为应用和引擎交互时也许需要用到某些配置。

在应用中的`config/initializers/blorgh.rb`添加一个新的初始化器，并添加如下代码：

```ruby
Blorgh.author_class = "User"
```

警告：使用`String`版本的类对象要比使用类对象本身更好。如果你使用类对象，Rails会尝试加载和类相关的数据库表。如果这个表不存在，就会抛出异常。所以，稍后在引擎中最好使用`String`类型，并且把类用`constantize`方法转换一下。

接下来我们创建一个新主题，除了让引擎读取`config/initializers/blorgh.rb`中的类信息之外，你将发现它和之前没什么区别，


这里对类没有严格的定义，只是提供了一个类必须做什么的指导。引擎也只是调用`find_or_create_by`方法来获取符合条件的类对象。当然这个对象也可以被其他对象引用。

#### 配置引擎


在引擎内部，有很多配置引擎的方法，比如initializers, internationalization和其他配置项。一个Rails引擎和一个Rails应用具有很多相同的功能。实际上一个Rails应用就是一个超级引擎。

如果你想使用一个初始化器，必须在引擎载入之前使用，配置文件在`config/initializers` 目录下。这个目录的详细使用说明在[Initializers section](configuring.html#initializers)中，它和一个应用中的`config/initializers`文件相对目录是一致的。可以把它当作一个Rails应用中的初始化器来配置。

关于本地文件，和一个应用中的目录类似，都在`config/locales`目录下。


引擎测试
-----------------

生成一个引擎后，引擎内部的`test/dummy`目录下会生成一个简单的Rails应用。这个应用被用来给引擎提供集成测试环境。你可以扩展这个应用的功能来测试你的引擎。

`test`目录将会被当作一个典型的Rails测试环境，允许单元测试，功能测试和交互测试。

### 功能测试

在编写引擎的功能测试时，我们会假定这个引擎会在一个应用中使用。`test/dummy`目录中的应用和你引擎结构差不多。这是因为建立测试环境后，引擎需要一个宿主来测试它的功能，特别是控制器。这意味着你需要在一个控制器功能测试函数中下如下代码：

```ruby
get :index
```

这似乎不能称为函数，因为这个应用不知道如何给引擎发送的请求做响应，除非你明确告诉他怎么做。为此，你必须在请求的参数中加上`:use_route`选项来声明：

```ruby
get :index, use_route: :blorgh
```

上述代码会告诉Rails应用你想让它的控制器响应一个`GET`请求，并执行`index`动作，但是你最好使用引擎的路径来代替。 

另外一种方法是在你的测试总建立一个setup方法，把`Engine.routes`赋值给变量`@routes` 。

```ruby
setup do
  @routes = Engine.routes
end
```

上诉操作也同时保证了引擎的url助手方法在你的测试中正常使用。

引擎优化 
------------------------------

本章节将介绍在Rails应用中如何添加或重载引擎的MVC功能。

### 重载模型和控制器

应用中的公共类可以扩展引擎的模型和控制器的功能。(因为模型和控制器类都继承了Rails应用的特定功能)应用中的公共类和引擎只是对模型和控制器根据需要进行了扩展。这种模式通常被称为装饰模式。

举个例子，`ActiveSupport::Concern`类使用`Class#class_eval`方法扩展了他的功能。

#### 装饰器的特点以及加载代码

因为装饰器不是引用Rails应用本身，Rails自动载入系统不会识别和载入你的装饰器。这意味着你需要用代码声明他们。

这是一个简单的例子：

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
上述操作不会应用到当前的装饰器，但是在引擎中添加的内容不会影响你的应用。

#### 使用 Class#class_eval 方法实现装饰模式

**添加** `Article#time_since_created`方法:

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

class Article < ActiveRecord::Base
  has_many :comments
end
```


**重载** `Article#summary`方法:

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

class Article < ActiveRecord::Base
  has_many :comments
  def summary
    "#{title}"
  end
end
```

#### 使用ActiveSupport::Concern类实现装饰模式

使用`Class#class_eval`方法可以应付一些简单的修改。但是如果要实现更复杂的操作，你可以考虑使用[`ActiveSupport::Concern`](http://edgeapi.rubyonrails.org/classes/ActiveSupport/Concern.html)。`ActiveSupport::Concern`管理着所有独立模块的内部链接指令，并且允许你在运行时声明模块代码。


**添加** `Article#time_since_created`方法和**重载** `Article#summary`方法:

```ruby
# MyApp/app/models/blorgh/article.rb

class Blorgh::Article < ActiveRecord::Base
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

class Article < ActiveRecord::Base
  include Blorgh::Concerns::Models::Article
end
```

```ruby
# Blorgh/lib/concerns/models/article

module Blorgh::Concerns::Models::Article
  extend ActiveSupport::Concern

  # 'included do' causes the included code to be evaluated in the
  # context where it is included (article.rb), rather than being
  # executed in the module's context (blorgh/concerns/models/article).
  included do
    attr_accessor :author_name
    belongs_to :author, class_name: "User"

    before_save :set_author

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

### 视图重载

Rails在寻找一个需要渲染的视图时，首先会去寻找应用的`app/views`目录下的文件。如果找不到，那么就会去当前应用目录下的所有引擎中找`app/views`目录下的内容。


当一个应用被要求为`Blorgh::ArticlesController`的`index`动作渲染视图时，它首先会在应用目录下去找`app/views/blorgh/articles/index.html.erb`，如果找不到，它将深入引擎内部寻找。


你可以在应用中创建一个新的`app/views/blorgh/articles/index.html.erb`文件来重载这个视图。接下来你会看到你改过的视图内容。

修改`app/views/blorgh/articles/index.html.erb`中的内容，代码如下： 

```html+erb
<h1>Articles</h1>
<%= link_to "New Article", new_article_path %>
<% @articles.each do |article| %>
  <h2><%= article.title %></h2>
  <small>By <%= article.author %></small>
  <%= simple_format(article.text) %>
  <hr>
<% end %>
```

### 路径 

引擎中的路径默认是和Rails应用隔离开的。主要通过`Engine`类的`isolate_namespace`方法 实现的。这意味着引擎和Rails应可以拥有同名的路径，但却不会冲突。

引擎内部的`config/routes.rb`中的`Engine`类是这样绑定路径的：

```ruby
Blorgh::Engine.routes.draw do
  resources :articles
end
```

因为拥有相对独立的路径，如果你希望在应用内部链接到引擎的某个地方，你需要使用引擎的路径代理方法。如果调用普通的路径方法，比如`articles_path`等，将不会得到你希望的结果。

举个例子。下面的`articles_path`方法根据情况自动识别，并渲染来自应用或引擎的内容。

```erb
<%= link_to "Blog articles", articles_path %>
```

为了确保这个路径使用引擎的`articles_path`方法，我们必须使用路径代理方法来实现：


```erb
<%= link_to "Blog articles", blorgh.articles_path %>
```
如果你希望在引擎内部访问Rails应用的路径，可以使用`main_app`方法：

```erb
<%= link_to "Home", main_app.root_path %>
```

如果你在引擎中使用了上诉方法，那么这将一直指向Rails应用的根目录。如果你没有使用`main_app`的
`routing proxy`路径代理调用方法，那么会根据调用源来指向引擎或Rails应用的根目录。


如果你引擎内的模板渲染想调用一个应用的路径帮助方法，这可能导致一个未定义的方法调用异常。如果你想解决这个问题，必须确保在引擎内部调用Rails应用的路径帮助方法时加上`main_app`前缀。


### 渲染页面相关的Assets文件

引擎内部的Assets文件位置和Rails应用的的相似。因为引擎类是继承自`Rails::Engine`的。应用会自动去引擎的`aapp/assets`和`lib/assets`目录搜索和页面渲染相关的文件。


像其他引擎组件一样，assets文件是可以命名空间化的。这意味着如果你有一个名为`style.css`的话，那么他的存放路径是`app/assets/stylesheets/[engine name]/style.css`, 而非
`app/assets/stylesheets/style.css`. 如果资源文件没有命名空间化，很有可能引擎的宿主中有一个和引擎同名的资源文件，这就会导致引擎相关的资源文件被忽略或覆盖。

假如你想在应用的中引用一个名为`app/assets/stylesheets/blorgh/style.css`文件， ，只需要使用`stylesheet_link_tag`就可以了：

```erb
<%= stylesheet_link_tag "blorgh/style.css" %>
```

你也可以在Asset Pipeline中声明你的资源文件是独立于其他资源文件的：

```
/*
 *= require blorgh/style
*/
```

提示： 如果你使用的是Sass或CoffeeScript语言，那么需要在你的引擎的`.gemspec`文件中设定相对路径。

### 页面资源文件分组和预编译

在某些情况下，你的引擎内部用到的资源文件，在Rails应用宿主中是不会用到的。举个例子，你为引擎创建了一个管理页面，它只在引擎内部使用，在这种情况下，Rails应用宿主并不需要用到`admin.css` 和`admin.js`文件，只是gem内部的管理页面需要用到它们。那么应用宿主就没必要添加`"blorgh/admin.css"`到他的样式表文件中
，这种情况下，你可以预编译这些文件。这会在你的引擎内部添加一个`rake assets:precompile`任务。

你可以在引擎的`engine.rb`中定义需要预编译的资源文件：

```ruby
initializer "blorgh.assets.precompile" do |app|
  app.config.assets.precompile += %w(admin.css admin.js)
end
```

想要了解更多详情，可以参考 [Asset Pipeline guide](asset_pipeline.html)

### 其他Gem依赖项

一个引擎的相关依赖项会在引擎的根目录下的`.gemspec`中声明。因为引擎也许会被当作一个gem安装到Rails应用中。如果在`Gemfile`中声明依赖项，那么这些依赖项就会被认为不是一个普通Gem，所以他们不会被安装，这会导致引擎发生故障。


为了让引擎被当作一个普通的Gem安装，需要声明他的依赖项已经安装过了。那么可以在引擎根目录下的`.gemspec`文件中添加`Gem::Specification`配置项：

```ruby
s.add_dependency "moo"
```

声明一个依赖项只作为开发应用时的依赖项，可以这么做： 


```ruby
s.add_development_dependency "moo"
```
所有的依赖项都会在执行`bundle install`命令时安装。gem开发环境的依赖项仅会在测试时用到。

注意，如果你希望引擎引用依赖项时马上引用。你应该在引擎初始化时就引用它们,比如：

```ruby
require 'other_engine/engine'
require 'yet_another_engine/engine'

module MyEngine
  class Engine < ::Rails::Engine
  end
end
```
