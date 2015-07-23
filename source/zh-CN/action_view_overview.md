Action View 基础
================

读完本文，你将学到：

* Action View 是什么，如何在 Rails 中使用；
* 模板、局部视图和布局的最佳使用方法；
* Action View 提供了哪些帮助方法，如何自己编写帮助方法；
* 如何使用本地化视图；
* 如何在 Rails 之外的程序中使用 Action View；

--------------------------------------------------------------------------------

Action View 是什么？
-------------------

Action View 和 Action Controller 是 Action Pack 的两个主要组件。在 Rails 中，请求由 Action Pack 分两步处理，一步交给控制器（逻辑处理），一步交给视图（渲染视图）。一般来说，Action Controller 的作用是和数据库通信，根据需要执行 CRUD 操作；Action View 用来构建响应。

Action View 模板由嵌入 HTML 的 Ruby 代码编写。为了保证模板代码简洁明了，Action View 提供了很多帮助方法，用来构建表单、日期和字符串等。如果需要，自己编写帮助方法也很简单。

NOTE: Action View 的有些功能和 Active Record 绑定在一起，但并不意味着 Action View 依赖于 Active Record。Action View 是个独立的代码库，可以在任何 Ruby 代码库中使用。

在 Rails 中使用 Action View
--------------------------

每个控制器在 `app/views` 中都对应一个文件夹，用来保存该控制器的模板文件。模板文件的作用是显示控制器动作的视图。

我们来看一下使用脚手架创建资源时，Rails 做了哪些事情：

```bash
$ rails generate scaffold post
      [...]
      invoke  scaffold_controller
      create    app/controllers/posts_controller.rb
      invoke    erb
      create      app/views/posts
      create      app/views/posts/index.html.erb
      create      app/views/posts/edit.html.erb
      create      app/views/posts/show.html.erb
      create      app/views/posts/new.html.erb
      create      app/views/posts/_form.html.erb
      [...]
```

Rails 中的视图也有命名约定。一般情况下，视图名和对应的控制器动作同名，如上所示。例如，`posts_controller.rb` 控制器中的 `index` 动作使用 `app/views/posts` 文件夹中的 `index.html.erb` 视图文件。

返回给客户端的完整 HTML 由这个 ERB 文件、布局文件和视图中用到的所有局部视图组成。后文会详细介绍这几种视图文件。

模板，局部视图和布局
-----------------

前面说过，最终输出的 HTML 由三部分组成：模板，局部视图和布局。下面详细介绍各部分。

### 模板

Action View 模板可使用多种语言编写。如果模板文件的扩展名是 `.erb`，使用的是 ERB 和 HTML。如果模板文件的扩展名是 `.builder`，使用的是 `Builder::XmlMarkup`。

Rails 支持多种模板系统，通过文件扩展名加以区分。例如，使用 ERB 模板系统的 HTML 文件，其扩展名为 `.html.erb`。

#### ERB

在 ERB 模板中，可以使用 `<% %>` 和 `<%= %>` 标签引入 Ruby 代码。`<% %>` 标签用来执行 Ruby 代码，没有返回值，例如条件判断、循环或代码块。`<%= %>` 用来输出结果。

例如下面的代码，循环遍历名字：

```erb
<h1>Names of all the people</h1>
<% @people.each do |person| %>
  Name: <%= person.name %><br>
<% end %>
```

在上述代码中，循环使用普通嵌入标签（`<% %>`），输出名字时使用输出式嵌入标签（`<%= %>`）。注意，这并不仅仅是一种使用建议：常规的输出方法，例如 `print` 或 `puts`，无法在 ERB 模板中使用。所以，下面这段代码是错误的：

```erb
<%# WRONG %>
Hi, Mr. <% puts "Frodo" %>
```

如果想去掉前后的空白，可以把 `<%` 和 `%>` 换成 `<%-` 和 `-%>`。

#### Builder

Builder 模板比 ERB 模板需要更多的编程，特别适合生成 XML 文档。在扩展名为 `.builder` 的模板中，可以直接使用名为 `xml` 的 `XmlMarkup` 对象。

下面是个简单的例子：

```ruby
xml.em("emphasized")
xml.em { xml.b("emph & bold") }
xml.a("A Link", "href" => "http://rubyonrails.org")
xml.target("name" => "compile", "option" => "fast")
```

输出结果如下：

```html
<em>emphasized</em>
<em><b>emph &amp; bold</b></em>
<a href="http://rubyonrails.org">A link</a>
<target option="fast" name="compile" />
```

代码块被视为一个 XML 标签，代码块中的标记会嵌入这个标签之中。例如：

```ruby
xml.div {
  xml.h1(@person.name)
  xml.p(@person.bio)
}
```

输出结果如下：

```html
<div>
  <h1>David Heinemeier Hansson</h1>
  <p>A product of Danish Design during the Winter of '79...</p>
</div>
```

下面这个例子是 Basecamp 用来生成 RSS 的完整代码：

```ruby
xml.rss("version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/") do
  xml.channel do
    xml.title(@feed_title)
    xml.link(@url)
    xml.description "Basecamp: Recent items"
    xml.language "en-us"
    xml.ttl "40"

    for item in @recent_items
      xml.item do
        xml.title(item_title(item))
        xml.description(item_description(item)) if item_description(item)
        xml.pubDate(item_pubDate(item))
        xml.guid(@person.firm.account.url + @recent_items.url(item))
        xml.link(@person.firm.account.url + @recent_items.url(item))
        xml.tag!("dc:creator", item.author_name) if item_has_creator?(item)
      end
    end
  end
end
```

#### 模板缓存

默认情况下，Rails 会把各个模板都编译成一个方法，这样才能渲染视图。在开发环境中，修改模板文件后，Rails 会检查文件的修改时间，然后重新编译。

### 局部视图

局部视图把整个渲染过程分成多个容易管理的代码片段。局部视图把模板中的代码片段提取出来，写入单独的文件中，可在所有模板中重复使用。

#### 局部视图的名字

要想在视图中使用局部视图，可以调用 `render` 方法：

```erb
<%= render "menu" %>
```

模板渲染到上述代码时，会渲染名为 `_menu.html.erb` 的文件。注意，文件名前面有个下划线。局部视图文件前面加上下划线是为了和普通视图区分，不过加载局部视图时不用加上下划线。从其他文件夹中加载局部视图也是一样：

```erb
<%= render "shared/menu" %>
```

上述代码会加载 `app/views/shared/_menu.html.erb` 这个局部视图。

#### 使用局部视图简化视图

局部视图的一种用法是作为子程序，把细节从视图中移出，这样能更好的理解整个视图的作用。例如，有如下的视图：

```erb
<%= render "shared/ad_banner" %>

<h1>Products</h1>

<p>Here are a few of our fine products:</p>
<% @products.each do |product| %>
  <%= render partial: "product", locals: {product: product} %>
<% end %>

<%= render "shared/footer" %>
```

在上述代码中，`_ad_banner.html.erb` 和 `_footer.html.erb` 局部视图中的代码可能要用到程序的多个页面中。专注实现某个页面时，无需关心这些局部视图中的细节。

#### `as` 和 `object` 选项

默认情况下，`ActionView::Partials::PartialRenderer` 对象存在一个本地变量中，变量名和模板名相同。所以，如果有以下代码：

```erb
<%= render partial: "product" %>
```

在 `_product.html.erb` 中，就可使用本地变量 `product` 表示 `@product`，和下面的写法是等效的：

```erb
<%= render partial: "product", locals: {product: @product} %>
```

`as` 选项可以为这个本地变量指定一个不同的名字。例如，如果想用 `item` 代替 `product`，可以这么做：

```erb
<%= render partial: "product", as: "item" %>
```

`object` 选项可以直接指定要在局部视图中使用的对象。如果模板中的对象在其他地方（例如，在其他实例变量或本地变量中），可以使用这个选项指定。

例如，用

```erb
<%= render partial: "product", object: @item %>
```

代替

```erb
<%= render partial: "product", locals: {product: @item} %>
```

`object` 和 `as` 选项还可同时使用：

```erb
<%= render partial: "product", object: @item, as: "item" %>
```

#### 渲染集合

在模板中经常需要遍历集合，使用子模板渲染各元素。这种需求可使用一个方法实现，把数组传入该方法，然后使用局部视图渲染各元素。

例如下面这个例子，渲染所有产品：

```erb
<% @products.each do |product| %>
  <%= render partial: "product", locals: { product: product } %>
<% end %>
```

可以写成：

```erb
<%= render partial: "product", collection: @products %>
```

像上面这样使用局部视图时，每个局部视图实例都可以通过一个和局部视图同名的变量访问集合中的元素。在上面的例子中，渲染的局部视图是 `_product`，在局部视图中，可以通过变量 `product` 访问要渲染的单个产品。

渲染集合还有个简写形式。假设 `@products` 是一个 `Product` 实例集合，可以使用下面的简写形式达到同样目的：

```erb
<%= render @products %>
```

Rails 会根据集合中的模型名（在这个例子中，是 `Product` 模型）决定使用哪个局部视图。其实，集合中还可包含多种模型的实例，Rails 会根据各元素所属的模型渲染对应的局部视图。

#### 间隔模板

渲染局部视图时还可使用 `:spacer_template` 选项指定第二个局部视图，在使用主局部视图渲染各实例之间渲染：

```erb
<%= render partial: @products, spacer_template: "product_ruler" %>
```

在这段代码中，渲染各 `_product` 局部视图之间还会渲染 `_product_ruler` 局部视图（不传入任何数据）。

### 布局

布局用来渲染 Rails 控制器动作的页面整体结构。一般来说，Rails 程序中有多个布局，大多数页面都使用这个布局渲染。例如，网站中可能有个布局用来渲染用户登录后的页面，以及一个布局用来渲染市场和销售页面。在用户登录后使用的布局中可能包含一个顶级导航，会在多个控制器动作中使用。在 SaaS 程序中，销售布局中可能包含一个顶级导航，指向“定价”和“联系”页面。每个布局都可以有自己的外观样式。关于布局的详细介绍，请阅读“[Rails 布局和视图渲染](layouts_and_rendering.html)”一文。

局部布局
-------

局部视图可以使用自己的布局。局部布局和动作使用的全局布局不一样，但原理相同。

例如，要在网页中显示一篇文章，文章包含在一个 `div` 标签中。首先，我们要创建一个新 `Post` 实例：

```ruby
Post.create(body: 'Partial Layouts are cool!')
```

在 `show` 动作的视图中，我们要在 `box` 布局中渲染 `_post` 局部视图：

```erb
<%= render partial: 'post', layout: 'box', locals: {post: @post} %>
```

`box` 布局只是把 `_post` 局部视图放在一个 `div` 标签中：

```erb
<div class='box'>
  <%= yield %>
</div>
```

在 `_post` 局部视图中，文章的内容放在一个 `div` 标签中，并设置了标签的 `id` 属性，这两个操作通过 `div_for` 帮助方法实现：

```erb
<%= div_for(post) do %>
  <p><%= post.body %></p>
<% end %>
```

最终渲染的文章如下：

```html
<div class='box'>
  <div id='post_1'>
    <p>Partial Layouts are cool!</p>
  </div>
</div>
```

注意，在局部布局中可以使用传入 `render` 方法的本地变量 `post`。和全局布局不一样，局部布局文件名前也要加上下划线。

在局部布局中可以不调用 `yield` 方法，直接使用代码块。例如，如果不使用 `_post` 局部视图，可以这么写：

```erb
<% render(layout: 'box', locals: {post: @post}) do %>
  <%= div_for(post) do %>
    <p><%= post.body %></p>
  <% end %>
<% end %>
```

假如还使用相同的 `_box` 局部布局，上述代码得到的输出和前面一样。

视图路径
-------

暂无内容。

Action View 提供的帮助方法简介
---------------------------

NOTE: 本节并未列出所有帮助方法。完整的帮助方法列表请查阅 [API 文档](http://api.rubyonrails.org/classes/ActionView/Helpers.html)。

以下各节对 Action View 提供的帮助方法做个简单介绍。如果想深入了解各帮助方法，建议查看 [API 文档](http://api.rubyonrails.org/classes/ActionView/Helpers.html)。

### `RecordTagHelper`

这个模块提供的帮助方法用来生成记录的容器标签，例如 `div`。渲染 Active Record 对象时，如果要将其放入容器标签中，推荐使用这些帮助方法，因为会相应的设置标签的 `class` 和 `id` 属性。如果遵守约定，可以很容易的引用这些容器，不用再想容器的 `class` 或 `id` 属性值是什么。

#### `content_tag_for`

为 Active Record 对象生成一个容器标签。

假设 `@post` 是 `Post` 类的一个对象，可以这么写：

```erb
<%= content_tag_for(:tr, @post) do %>
  <td><%= @post.title %></td>
<% end %>
```

生成的 HTML 如下：

```html
<tr id="post_1234" class="post">
  <td>Hello World!</td>
</tr>
```

还可以使用一个 Hash 指定 HTML 属性，例如：

```erb
<%= content_tag_for(:tr, @post, class: "frontpage") do %>
  <td><%= @post.title %></td>
<% end %>
```

生成的 HTML 如下：

```html
<tr id="post_1234" class="post frontpage">
  <td>Hello World!</td>
</tr>
```

还可传入 Active Record 对象集合，`content_tag_for` 方法会遍历集合，为每个元素生成一个容器标签。假如 `@posts` 中有两个 `Post` 对象：

```erb
<%= content_tag_for(:tr, @posts) do |post| %>
  <td><%= post.title %></td>
<% end %>
```

生成的 HTML 如下：

```html
<tr id="post_1234" class="post">
  <td>Hello World!</td>
</tr>
<tr id="post_1235" class="post">
  <td>Ruby on Rails Rocks!</td>
</tr>
```

#### `div_for`

这个方法是使用 `content_tag_for` 创建 `div` 标签的快捷方式。可以传入一个 Active Record 对象，或对象集合。例如：

```erb
<%= div_for(@post, class: "frontpage") do %>
  <td><%= @post.title %></td>
<% end %>
```

生成的 HTML 如下：

```html
<div id="post_1234" class="post frontpage">
  <td>Hello World!</td>
</div>
```

### `AssetTagHelper`

这个模块中的帮助方法用来生成链接到静态资源文件的 HTML，例如图片、JavaScript 文件、样式表和 Feed 等。

默认情况下，Rails 链接的静态文件在程序所处主机的 `public` 文件夹中。不过也可以链接到静态资源文件专用的服务器，在程序的设置文件（一般来说是 `config/environments/production.rb`）中设置 `config.action_controller.asset_host` 选项即可。假设静态资源服务器是 `assets.example.com`：

```ruby
config.action_controller.asset_host = "assets.example.com"
image_tag("rails.png") # => <img src="http://assets.example.com/images/rails.png" alt="Rails" />
```

#### `register_javascript_expansion`

这个方法注册一到多个 JavaScript 文件，把 Symbol 传给 `javascript_include_tag` 方法时，会引入相应的文件。这个方法经常用在插件的初始化代码中，注册保存在 `vendor/assets/javascripts` 文件夹中的 JavaScript 文件。

```ruby
ActionView::Helpers::AssetTagHelper.register_javascript_expansion monkey: ["head", "body", "tail"]

javascript_include_tag :monkey # =>
  <script src="/assets/head.js"></script>
  <script src="/assets/body.js"></script>
  <script src="/assets/tail.js"></script>
```

#### `register_stylesheet_expansion`

这个方法注册一到多个样式表文件，把 Symbol 传给 `stylesheet_link_tag` 方法时，会引入相应的文件。这个方法经常用在插件的初始化代码中，注册保存在 `vendor/assets/stylesheets` 文件夹中的样式表文件。

```ruby
ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion monkey: ["head", "body", "tail"]

stylesheet_link_tag :monkey # =>
  <link href="/assets/head.css" media="screen" rel="stylesheet" />
  <link href="/assets/body.css" media="screen" rel="stylesheet" />
  <link href="/assets/tail.css" media="screen" rel="stylesheet" />
```

#### `auto_discovery_link_tag`

返回一个 `link` 标签，浏览器和 Feed 阅读器用来自动检测 RSS 或 Atom Feed。

```ruby
auto_discovery_link_tag(:rss, "http://www.example.com/feed.rss", {title: "RSS Feed"}) # =>
  <link rel="alternate" type="application/rss+xml" title="RSS Feed" href="http://www.example.com/feed" />
```

#### `image_path`

生成 `app/assets/images` 文件夹中所存图片的地址。得到的地址是从根目录到图片的完整路径。用于 `image_tag` 方法，获取图片的路径。

```ruby
image_path("edit.png") # => /assets/edit.png
```

如果 `config.assets.digest` 选项为 `true`，图片文件名后会加上指纹码。

```ruby
image_path("edit.png") # => /assets/edit-2d1a2db63fc738690021fedb5a65b68e.png
```

#### `image_url`

生成 `app/assets/images` 文件夹中所存图片的 URL 地址。`image_url` 会调用 `image_path`，然后加上程序的主机地址或静态文件的主机地址。

```ruby
image_url("edit.png") # => http://www.example.com/assets/edit.png
```

#### `image_tag`

生成图片的 HTML `image` 标签。图片的地址可以是完整的 URL，或者 `app/assets/images` 文件夹中的图片。

```ruby
image_tag("icon.png") # => <img src="/assets/icon.png" alt="Icon" />
```

#### `javascript_include_tag`

为指定的每个资源生成 HTML `script` 标签。可以传入 `app/assets/javascripts` 文件夹中所存 JavaScript 文件的文件名（扩展名 `.js` 可加可不加），或者可以使用相对文件根目录的完整路径。

```ruby
javascript_include_tag "common" # => <script src="/assets/common.js"></script>
```

如果程序不使用 Asset Pipeline，要想引入 jQuery，可以传入 `:default`。使用 `:default` 时，如果 `app/assets/javascripts` 文件夹中存在 `application.js` 文件，也会将其引入。

```ruby
javascript_include_tag :defaults
```

还可以使用 `:all` 引入 `app/assets/javascripts` 文件夹中所有的 JavaScript 文件。

```ruby
javascript_include_tag :all
```

多个 JavaScript 文件还可合并成一个文件，减少 HTTP 连接数，还可以使用 gzip 压缩（提升传输速度）。只有 `ActionController::Base.perform_caching` 为 `true`（生产环境的默认值，开发环境为 `false`）时才会合并文件。

```ruby
javascript_include_tag :all, cache: true # =>
  <script src="/javascripts/all.js"></script>
```

#### `javascript_path`

生成 `app/assets/javascripts` 文件夹中 JavaScript 文件的地址。如果没指定文件的扩展名，会自动加上 `.js`。参数也可以使用相对文档根路径的完整地址。这个方法在 `javascript_include_tag` 中调用，用来生成脚本的地址。

```ruby
javascript_path "common" # => /assets/common.js
```

#### `javascript_url`

生成 `app/assets/javascripts` 文件夹中 JavaScript 文件的 URL 地址。这个方法调用 `javascript_path`，然后再加上当前程序的主机地址或静态资源文件的主机地址。

```ruby
javascript_url "common" # => http://www.example.com/assets/common.js
```

#### `stylesheet_link_tag`

返回指定资源的样式表 `link` 标签。如果没提供扩展名，会自动加上 `.css`。

```ruby
stylesheet_link_tag "application" # => <link href="/assets/application.css" media="screen" rel="stylesheet" />
```

还可以使用 `:all`，引入 `app/assets/stylesheets` 文件夹中的所有样式表。

```ruby
stylesheet_link_tag :all
```

多个样式表还可合并成一个文件，减少 HTTP 连接数，还可以使用 gzip 压缩（提升传输速度）。只有 `ActionController::Base.perform_caching` 为 `true`（生产环境的默认值，开发环境为 `false`）时才会合并文件。

```ruby
stylesheet_link_tag :all, cache: true
# => <link href="/assets/all.css" media="screen" rel="stylesheet" />
```

#### `stylesheet_path`

生成 `app/assets/stylesheets` 文件夹中样式表的地址。如果没指定文件的扩展名，会自动加上 `.css`。参数也可以使用相对文档根路径的完整地址。这个方法在 `stylesheet_link_tag` 中调用，用来生成样式表的地址。

```ruby
stylesheet_path "application" # => /assets/application.css
```

#### `stylesheet_url`

生成 `app/assets/stylesheets` 文件夹中样式表的 URL 地址。这个方法调用 `stylesheet_path`，然后再加上当前程序的主机地址或静态资源文件的主机地址。

```ruby
stylesheet_url "application" # => http://www.example.com/assets/application.css
```

### `AtomFeedHelper`

#### `atom_feed`

这个帮助方法可以简化生成 Atom Feed 的过程。下面是个完整的示例：

```ruby
resources :posts
```

```ruby
def index
  @posts = Post.all

  respond_to do |format|
    format.html
    format.atom
  end
end
```

```ruby
atom_feed do |feed|
  feed.title("Posts Index")
  feed.updated((@posts.first.created_at))

  @posts.each do |post|
    feed.entry(post) do |entry|
      entry.title(post.title)
      entry.content(post.body, type: 'html')

      entry.author do |author|
        author.name(post.author_name)
      end
    end
  end
end
```

### `BenchmarkHelper`

#### `benchmark`

这个方法可以计算模板中某个代码块的执行时间，然后把结果写入日志。可以把耗时的操作或瓶颈操作放入 `benchmark` 代码块中，查看此项操作使用的时间。

```erb
<% benchmark "Process data files" do %>
  <%= expensive_files_operation %>
<% end %>
```

上述代码会在日志中写入类似“Process data files (0.34523)”的文本，可用来对比优化前后的时间。

### `CacheHelper`

#### `cache`

这个方法缓存视图片段，而不是整个动作或页面。常用来缓存目录，新话题列表，静态 HTML 片段等。此方法接受一个代码块，即要缓存的内容。详情参见 `ActionController::Caching::Fragments` 模块的文档。

```erb
<% cache do %>
  <%= render "shared/footer" %>
<% end %>
```

### `CaptureHelper`

#### `capture`

`capture` 方法可以把视图中的一段代码赋值给一个变量，这个变量可以在任何模板或视图中使用。

```erb
<% @greeting = capture do %>
  <p>Welcome! The date and time is <%= Time.now %></p>
<% end %>
```

`@greeting` 变量可以在任何地方使用。

```erb
<html>
  <head>
    <title>Welcome!</title>
  </head>
  <body>
    <%= @greeting %>
  </body>
</html>
```

#### `content_for`

`content_for` 方法用一个标记符表示一段代码，在其他模板或布局中，可以把这个标记符传给 `yield` 方法，调用这段代码。

例如，程序有个通用的布局，但还有一个特殊页面，用到了其他页面不需要的 JavaScript 文件，此时就可以在这个特殊的页面中使用 `content_for` 方法，在不影响其他页面的情况下，引入所需的 JavaScript。

```erb
<html>
  <head>
    <title>Welcome!</title>
    <%= yield :special_script %>
  </head>
  <body>
    <p>Welcome! The date and time is <%= Time.now %></p>
  </body>
</html>
```

```erb
<p>This is a special page.</p>

<% content_for :special_script do %>
  <script>alert('Hello!')</script>
<% end %>
```

### `DateHelper`

#### `date_select`

这个方法会生成一组选择列表，分别对应年月日，用来设置日期相关的属性。

```ruby
date_select("post", "published_on")
```

#### `datetime_select`

这个方法会生成一组选择列表，分别对应年月日时分，用来设置日期和时间相关的属性。

```ruby
datetime_select("post", "published_on")
```

#### `distance_of_time_in_words`

这个方法会计算两个时间、两个日期或两个秒数之间的近似间隔。如果想得到更精准的间隔，可以把 `include_seconds` 选项设为 `true`。

```ruby
distance_of_time_in_words(Time.now, Time.now + 15.seconds)        # => less than a minute
distance_of_time_in_words(Time.now, Time.now + 15.seconds, include_seconds: true)  # => less than 20 seconds
```

#### `select_date`

返回一组 HTML 选择列表标签，分别对应年月日，并且选中指定的日期。

```ruby
# Generates a date select that defaults to the date provided (six days after today)
select_date(Time.today + 6.days)

# Generates a date select that defaults to today (no specified date)
select_date()
```

#### `select_datetime`

返回一组 HTML 选择列表标签，分别对应年月日时分，并且选中指定的日期和时间。

```ruby
# Generates a datetime select that defaults to the datetime provided (four days after today)
select_datetime(Time.now + 4.days)

# Generates a datetime select that defaults to today (no specified datetime)
select_datetime()
```

#### `select_day`

返回一个选择列表标签，其选项是当前月份的每一天，并且选中当日。

```ruby
# Generates a select field for days that defaults to the day for the date provided
select_day(Time.today + 2.days)

# Generates a select field for days that defaults to the number given
select_day(5)
```

#### `select_hour`

返回一个选择列表标签，其选项是一天中的每一个小时（0-23），并且选中当前的小时数。

```ruby
# Generates a select field for hours that defaults to the hours for the time provided
select_hour(Time.now + 6.hours)
```

#### `select_minute`

返回一个选择列表标签，其选项是一小时中的每一分钟（0-59），并且选中当前的分钟数。

```ruby
# Generates a select field for minutes that defaults to the minutes for the time provided.
select_minute(Time.now + 6.hours)
```

#### `select_month`

返回一个选择列表标签，其选项是一年之中的所有月份（“January”-“December”），并且选中当前月份。

```ruby
# Generates a select field for months that defaults to the current month
select_month(Date.today)
```

#### `select_second`

返回一个选择列表标签，其选项是一分钟内的各秒数（0-59），并且选中当前时间的秒数。

```ruby
# Generates a select field for seconds that defaults to the seconds for the time provided
select_second(Time.now + 16.minutes)
```

#### `select_time`

返回一组 HTML 选择列表标签，分别对应小时和分钟。

```ruby
# Generates a time select that defaults to the time provided
select_time(Time.now)
```

#### `select_year`

返回一个选择列表标签，其选项是今年前后各五年，并且选择今年。年份的前后范围可使用 `:start_year` 和 `:end_year` 选项指定。

```ruby
# Generates a select field for five years on either side of Date.today that defaults to the current year
select_year(Date.today)

# Generates a select field from 1900 to 2009 that defaults to the current year
select_year(Date.today, start_year: 1900, end_year: 2009)
```

#### `time_ago_in_words`

和 `distance_of_time_in_words` 方法作用类似，但是后一个时间点固定为当前时间（`Time.now`）。

```ruby
time_ago_in_words(3.minutes.from_now)  # => 3 minutes
```

#### `time_select`

返回一组选择列表标签，分别对应小时和分钟，秒数是可选的，用来设置基于时间的属性。选中的值会作为多个参数赋值给 Active Record 对象。

```ruby
# Creates a time select tag that, when POSTed, will be stored in the order variable in the submitted attribute
time_select("order", "submitted")
```

### `DebugHelper`

返回一个 `pre` 标签，以 YAML 格式显示对象。用这种方法审查对象，可读性极高。

```ruby
my_hash = {'first' => 1, 'second' => 'two', 'third' => [1,2,3]}
debug(my_hash)
```

```html
<pre class='debug_dump'>---
first: 1
second: two
third:
- 1
- 2
- 3
</pre>
```

### `FormHelper`

表单帮助方法的目的是替代标准的 HTML 元素，简化处理模型的过程。`FormHelper` 模块提供了很多方法，基于模型创建表单，不单可以生成表单的 HTML 标签，还能生成各种输入框标签，例如文本输入框，密码输入框，选择列表等。提交表单后（用户点击提交按钮，或者在 JavaScript 中调用 `form.submit`），其输入框中的值会存入 `params` 对象，传给控制器。

表单帮助方法分为两类，一种专门处理模型，另一种则不是。前者处理模型的属性；后者不处理模型属性，详情参见 `ActionView::Helpers::FormTagHelper` 模块的文档。

`FormHelper` 模块的核心是 `form_for` 方法，生成处理模型实例的表单。例如，有个名为 `Person` 的模型，要创建一个新实例，可使用下面的代码实现：

```erb
# Note: a @person variable will have been created in the controller (e.g. @person = Person.new)
<%= form_for @person, url: {action: "create"} do |f| %>
  <%= f.text_field :first_name %>
  <%= f.text_field :last_name %>
  <%= submit_tag 'Create' %>
<% end %>
```

生成的 HTML 如下：

```html
<form action="/people/create" method="post">
  <input id="person_first_name" name="person[first_name]" type="text" />
  <input id="person_last_name" name="person[last_name]" type="text" />
  <input name="commit" type="submit" value="Create" />
</form>
```

表单提交后创建的 `params` 对象如下：

```ruby
{"action" => "create", "controller" => "people", "person" => {"first_name" => "William", "last_name" => "Smith"}}
```

`params` 中有个嵌套 Hash `person`，在控制器中使用 `params[:person]` 获取。

#### `check_box`

返回一个复选框标签，处理指定的属性。

```ruby
# Let's say that @post.validated? is 1:
check_box("post", "validated")
# => <input type="checkbox" id="post_validated" name="post[validated]" value="1" />
#    <input name="post[validated]" type="hidden" value="0" />
```

#### `fields_for`

类似 `form_for`，为指定的模型创建一个作用域，但不会生成 `form` 标签。特别适合在同一个表单中处理多个模型。

```erb
<%= form_for @person, url: {action: "update"} do |person_form| %>
  First name: <%= person_form.text_field :first_name %>
  Last name : <%= person_form.text_field :last_name %>

  <%= fields_for @person.permission do |permission_fields| %>
    Admin?  : <%= permission_fields.check_box :admin %>
  <% end %>
<% end %>
```

#### `file_field`

返回一个文件上传输入框，处理指定的属性。

```ruby
file_field(:user, :avatar)
# => <input type="file" id="user_avatar" name="user[avatar]" />
```

#### `form_for`

为指定的模型创建一个表单和作用域，表单中各字段的值都通过这个模型获取。

```erb
<%= form_for @post do |f| %>
  <%= f.label :title, 'Title' %>:
  <%= f.text_field :title %><br>
  <%= f.label :body, 'Body' %>:
  <%= f.text_area :body %><br>
<% end %>
```

#### `hidden_field`

返回一个隐藏 `input` 标签，处理指定的属性。

```ruby
hidden_field(:user, :token)
# => <input type="hidden" id="user_token" name="user[token]" value="#{@user.token}" />
```

#### `label`

返回一个 `label` 标签，为指定属性的输入框加上标签。

```ruby
label(:post, :title)
# => <label for="post_title">Title</label>
```

#### `password_field`

返回一个密码输入框，处理指定的属性。

```ruby
password_field(:login, :pass)
# => <input type="text" id="login_pass" name="login[pass]" value="#{@login.pass}" />
```

#### `radio_button`

返回一个单选框，处理指定的属性。

```ruby
# Let's say that @post.category returns "rails":
radio_button("post", "category", "rails")
radio_button("post", "category", "java")
# => <input type="radio" id="post_category_rails" name="post[category]" value="rails" checked="checked" />
#    <input type="radio" id="post_category_java" name="post[category]" value="java" />
```

#### `text_area`

返回一个多行文本输入框，处理指定的属性。

```ruby
text_area(:comment, :text, size: "20x30")
# => <textarea cols="20" rows="30" id="comment_text" name="comment[text]">
#      #{@comment.text}
#    </textarea>
```

#### `text_field`

返回一个文本输入框，处理指定的属性。

```ruby
text_field(:post, :title)
# => <input type="text" id="post_title" name="post[title]" value="#{@post.title}" />
```

#### `email_field`

返回一个 Email 输入框，处理指定的属性。

```ruby
email_field(:user, :email)
# => <input type="email" id="user_email" name="user[email]" value="#{@user.email}" />
```

#### `url_field`

返回一个 URL 输入框，处理指定的属性。

```ruby
url_field(:user, :url)
# => <input type="url" id="user_url" name="user[url]" value="#{@user.url}" />
```

### `FormOptionsHelper`

这个模块提供很多方法用来把不同类型的集合转换成一组 `option` 标签。

#### `collection_select`

为 `object` 类的 `method` 方法返回的集合创建 `select` 和 `option` 标签。

使用此方法的模型示例：

```ruby
class Post < ActiveRecord::Base
  belongs_to :author
end

class Author < ActiveRecord::Base
  has_many :posts
  def name_with_initial
    "#{first_name.first}. #{last_name}"
  end
end
```

使用举例，为文章实例（`@post`）选择作者（`Author`）：

```ruby
collection_select(:post, :author_id, Author.all, :id, :name_with_initial, {prompt: true})
```

如果 `@post.author_id` 的值是 1，上述代码生成的 HTML 如下：

```html
<select name="post[author_id]">
  <option value="">Please select</option>
  <option value="1" selected="selected">D. Heinemeier Hansson</option>
  <option value="2">D. Thomas</option>
  <option value="3">M. Clark</option>
</select>
```

#### `collection_radio_buttons`

为 `object` 类的 `method` 方法返回的集合创建 `radio_button` 标签。

使用此方法的模型示例：

```ruby
class Post < ActiveRecord::Base
  belongs_to :author
end

class Author < ActiveRecord::Base
  has_many :posts
  def name_with_initial
    "#{first_name.first}. #{last_name}"
  end
end
```

使用举例，为文章实例（`@post`）选择作者（`Author`）：

```ruby
collection_radio_buttons(:post, :author_id, Author.all, :id, :name_with_initial)
```

如果 `@post.author_id` 的值是 1，上述代码生成的 HTML 如下：

```html
<input id="post_author_id_1" name="post[author_id]" type="radio" value="1" checked="checked" />
<label for="post_author_id_1">D. Heinemeier Hansson</label>
<input id="post_author_id_2" name="post[author_id]" type="radio" value="2" />
<label for="post_author_id_2">D. Thomas</label>
<input id="post_author_id_3" name="post[author_id]" type="radio" value="3" />
<label for="post_author_id_3">M. Clark</label>
```

#### `collection_check_boxes`

为 `object` 类的 `method` 方法返回的集合创建复选框标签。

使用此方法的模型示例：

```ruby
class Post < ActiveRecord::Base
  has_and_belongs_to_many :authors
end

class Author < ActiveRecord::Base
  has_and_belongs_to_many :posts
  def name_with_initial
    "#{first_name.first}. #{last_name}"
  end
end
```

使用举例，为文章实例（`@post`）选择作者（`Author`）：

```ruby
collection_check_boxes(:post, :author_ids, Author.all, :id, :name_with_initial)
```

如果 `@post.author_ids` 的值是 `[1]`，上述代码生成的 HTML 如下：

```html
<input id="post_author_ids_1" name="post[author_ids][]" type="checkbox" value="1" checked="checked" />
<label for="post_author_ids_1">D. Heinemeier Hansson</label>
<input id="post_author_ids_2" name="post[author_ids][]" type="checkbox" value="2" />
<label for="post_author_ids_2">D. Thomas</label>
<input id="post_author_ids_3" name="post[author_ids][]" type="checkbox" value="3" />
<label for="post_author_ids_3">M. Clark</label>
<input name="post[author_ids][]" type="hidden" value="" />
```

#### `country_options_for_select`

返回一组 `option` 标签，几乎包含世界上所有国家。

#### `country_select`

返回指定对象和方法的 `select` 和 `option` 标签。使用 `country_options_for_select` 方法生成各个 `option` 标签。

#### `option_groups_from_collection_for_select`

返回一个字符串，由多个 `option` 标签组成。和 `options_from_collection_for_select` 方法类似，但会根据对象之间的关系使用 `optgroup` 标签分组。

使用此方法的模型示例：

```ruby
class Continent < ActiveRecord::Base
  has_many :countries
  # attribs: id, name
end

class Country < ActiveRecord::Base
  belongs_to :continent
  # attribs: id, name, continent_id
end
```

使用举例：

```ruby
option_groups_from_collection_for_select(@continents, :countries, :name, :id, :name, 3)
```

可能得到的输出如下：

```html
<optgroup label="Africa">
  <option value="1">Egypt</option>
  <option value="4">Rwanda</option>
  ...
</optgroup>
<optgroup label="Asia">
  <option value="3" selected="selected">China</option>
  <option value="12">India</option>
  <option value="5">Japan</option>
  ...
</optgroup>
```

注意，这个方法只会返回 `optgroup` 和 `option` 标签，所以你要把输出放入 `select` 标签中。

#### `options_for_select`

接受一个集合（Hash，数组，可枚举的对象等），返回一个由 `option` 标签组成的字符串。

```ruby
options_for_select([ "VISA", "MasterCard" ])
# => <option>VISA</option> <option>MasterCard</option>
```

注意，这个方法只返回 `option` 标签，所以你要把输出放入 `select` 标签中。

#### `options_from_collection_for_select`

遍历 `collection`，返回一组 `option` 标签。每个 `option` 标签的值是在 `collection` 元素上调用 `value_method` 方法得到的结果，`option` 标签的显示文本是在 `collection` 元素上调用 `text_method` 方法得到的结果

```ruby
# options_from_collection_for_select(collection, value_method, text_method, selected = nil)
```

例如，下面的代码遍历 `@project.people`，生成一组 `option` 标签：

```ruby
options_from_collection_for_select(@project.people, "id", "name")
# => <option value="#{person.id}">#{person.name}</option>
```

注意：`options_from_collection_for_select` 方法只返回 `option` 标签，你应该将其放在 `select` 标签中。

#### `select`

创建一个 `select` 元素以及根据指定对象和方法得到的一系列 `option` 标签。

例如：

```ruby
select("post", "person_id", Person.all.collect {|p| [ p.name, p.id ] }, {include_blank: true})
```

如果 `@post.person_id` 的值为 1，返回的结果是：

```html
<select name="post[person_id]">
  <option value=""></option>
  <option value="1" selected="selected">David</option>
  <option value="2">Sam</option>
  <option value="3">Tobias</option>
</select>
```

#### `time_zone_options_for_select`

返回一组 `option` 标签，包含几乎世界上所有的时区。

#### `time_zone_select`

为指定的对象和方法返回 `select` 标签和 `option` 标签，`option` 标签使用 `time_zone_options_for_select` 方法生成。

```ruby
time_zone_select( "user", "time_zone")
```

#### `date_field`

返回一个 `date` 类型的 `input` 标签，用于访问指定的属性。

```ruby
date_field("user", "dob")
```

### `FormTagHelper`

这个模块提供一系列方法用于创建表单标签。`FormHelper` 依赖于传入模板的 Active Record 对象，但 `FormTagHelper` 需要手动指定标签的 `name` 属性和 `value` 属性。

#### `check_box_tag`

为表单创建一个复选框标签。

```ruby
check_box_tag 'accept'
# => <input id="accept" name="accept" type="checkbox" value="1" />
```

#### `field_set_tag`

创建 `fieldset` 标签，用于分组 HTML 表单元素。

```erb
<%= field_set_tag do %>
  <p><%= text_field_tag 'name' %></p>
<% end %>
# => <fieldset><p><input id="name" name="name" type="text" /></p></fieldset>
```

#### `file_field_tag`

创建一个文件上传输入框。

```erb
<%= form_tag({action:"post"}, multipart: true) do %>
  <label for="file">File to Upload</label> <%= file_field_tag "file" %>
  <%= submit_tag %>
<% end %>
```

结果示例：

```ruby
file_field_tag 'attachment'
# => <input id="attachment" name="attachment" type="file" />
```

#### `form_tag`

创建 `form` 标签，指向的地址由 `url_for_options` 选项指定，和 `ActionController::Base#url_for` 方法类似。

```erb
<%= form_tag '/posts' do %>
  <div><%= submit_tag 'Save' %></div>
<% end %>
# => <form action="/posts" method="post"><div><input type="submit" name="submit" value="Save" /></div></form>
```

#### `hidden_field_tag`

为表单创建一个隐藏的 `input` 标签，用于传递由于 HTTP 无状态的特性而丢失的数据，或者隐藏不想让用户看到的数据。

```ruby
hidden_field_tag 'token', 'VUBJKB23UIVI1UU1VOBVI@'
# => <input id="token" name="token" type="hidden" value="VUBJKB23UIVI1UU1VOBVI@" />
```

#### `image_submit_tag`

显示一个图片，点击后提交表单。

```ruby
image_submit_tag("login.png")
# => <input src="/images/login.png" type="image" />
```

#### `label_tag`

创建一个 `label` 标签。

```ruby
label_tag 'name'
# => <label for="name">Name</label>
```

#### `password_field_tag`

创建一个密码输入框，用户输入的值会被遮盖。

```ruby
password_field_tag 'pass'
# => <input id="pass" name="pass" type="password" />
```

#### `radio_button_tag`

创建一个单选框。如果希望用户从一组选项中选择，可以使用多个单选框，`name` 属性的值都设为一样的。

```ruby
radio_button_tag 'gender', 'male'
# => <input id="gender_male" name="gender" type="radio" value="male" />
```

#### `select_tag`

创建一个下拉选择框。

```ruby
select_tag "people", "<option>David</option>"
# => <select id="people" name="people"><option>David</option></select>
```

#### `submit_tag`

创建一个提交按钮，按钮上显示指定的文本。

```ruby
submit_tag "Publish this post"
# => <input name="commit" type="submit" value="Publish this post" />
```

#### `text_area_tag`

创建一个多行文本输入框，用于输入大段文本，例如博客和描述信息。

```ruby
text_area_tag 'post'
# => <textarea id="post" name="post"></textarea>
```

#### `text_field_tag`

创建一个标准文本输入框，用于输入小段文本，例如用户名和搜索关键字。

```ruby
text_field_tag 'name'
# => <input id="name" name="name" type="text" />
```

#### `email_field_tag`

创建一个标准文本输入框，用于输入 Email 地址。

```ruby
email_field_tag 'email'
# => <input id="email" name="email" type="email" />
```

#### `url_field_tag`

创建一个标准文本输入框，用于输入 URL 地址。

```ruby
url_field_tag 'url'
# => <input id="url" name="url" type="url" />
```

#### `date_field_tag`

创建一个标准文本输入框，用于输入日期。

```ruby
date_field_tag "dob"
# => <input id="dob" name="dob" type="date" />
```

### `JavaScriptHelper`

这个模块提供在视图中使用 JavaScript 的相关方法。

#### `button_to_function`

返回一个按钮，点击后触发一个 JavaScript 函数。例如：

```ruby
button_to_function "Greeting", "alert('Hello world!')"
button_to_function "Delete", "if (confirm('Really?')) do_delete()"
button_to_function "Details" do |page|
  page[:details].visual_effect :toggle_slide
end
```

#### `define_javascript_functions`

在一个 `script` 标签中引入 Action Pack JavaScript 代码库。

#### `escape_javascript`

转义 JavaScript 中的回车符、单引号和双引号。

#### `javascript_tag`

返回一个 `script` 标签，把指定的代码放入其中。

```ruby
javascript_tag "alert('All is good')"
```

```html
<script>
//<![CDATA[
alert('All is good')
//]]>
</script>
```

#### `link_to_function`

返回一个链接，点击后触发指定的 JavaScript 函数并返回 `false`。

```ruby
link_to_function "Greeting", "alert('Hello world!')"
# => <a onclick="alert('Hello world!'); return false;" href="#">Greeting</a>
```

### `NumberHelper`

这个模块提供用于把数字转换成格式化字符串所需的方法。包括用于格式化电话号码、货币、百分比、精度、进位制和文件大小的方法。

#### `number_to_currency`

把数字格式化成货币字符串，例如 $13.65。

```ruby
number_to_currency(1234567890.50) # => $1,234,567,890.50
```

#### `number_to_human_size`

把字节数格式化成更易理解的形式，显示文件大小时特别有用。

```ruby
number_to_human_size(1234)          # => 1.2 KB
number_to_human_size(1234567)       # => 1.2 MB
```

#### `number_to_percentage`

把数字格式化成百分数形式。

```ruby
number_to_percentage(100, precision: 0)        # => 100%
```

#### `number_to_phone`

把数字格式化成美国使用的电话号码形式。

```ruby
number_to_phone(1235551234) # => 123-555-1234
```

#### `number_with_delimiter`

格式化数字，使用分隔符隔开每三位数字。

```ruby
number_with_delimiter(12345678) # => 12,345,678
```

#### `number_with_precision`

使用指定的精度格式化数字，精度默认值为 3。

```ruby
number_with_precision(111.2345)     # => 111.235
number_with_precision(111.2345, 2)  # => 111.23
```

### `SanitizeHelper`

`SanitizeHelper` 模块提供一系列方法，用于剔除不想要的 HTML 元素。

#### `sanitize`

`sanitize` 方法会编码所有标签，并删除所有不允许使用的属性。

```ruby
sanitize @article.body
```

如果指定了 `:attributes` 或 `:tags` 选项，只允许使用指定的标签和属性。

```ruby
sanitize @article.body, tags: %w(table tr td), attributes: %w(id class style)
```

要想修改默认值，例如允许使用 `table` 标签，可以这么设置：

```ruby
class Application < Rails::Application
  config.action_view.sanitized_allowed_tags = 'table', 'tr', 'td'
end
```

#### `sanitize_css(style)`

过滤一段 CSS 代码。

#### `strip_links(html)`

删除文本中的所有链接标签，但保留链接文本。

```ruby
strip_links("<a href="http://rubyonrails.org">Ruby on Rails</a>")
# => Ruby on Rails
```

```ruby
strip_links("emails to <a href="mailto:me@email.com">me@email.com</a>.")
# => emails to me@email.com.
```

```ruby
strip_links('Blog: <a href="http://myblog.com/">Visit</a>.')
# => Blog: Visit.
```

#### `strip_tags(html)`

过滤 `html` 中的所有 HTML 标签，以及注释。

这个方法使用 `html-scanner` 解析 HTML，所以解析能力受 `html-scanner` 的限制。

```ruby
strip_tags("Strip <i>these</i> tags!")
# => Strip these tags!
```

```ruby
strip_tags("<b>Bold</b> no more!  <a href='more.html'>See more</a>")
# => Bold no more!  See more
```

注意，得到的结果中可能仍然有字符 `<`、`>` 和 `&`，会导致浏览器显示异常。

视图本地化
---------

Action View 可以根据当前的本地化设置渲染不同的模板。

例如，假设有个 `PostsController`，在其中定义了 `show` 动作。默认情况下，执行这个动作时渲染的是 `app/views/posts/show.html.erb`。如果设置了 `I18n.locale = :de`，渲染的则是 `app/views/posts/show.de.html.erb`。如果本地化对应的模板不存在就使用默认模板。也就是说，没必要为所有动作编写本地化视图，但如果有本地化对应的模板就会使用。

相同的技术还可用在 `public` 文件夹中的错误文件上。例如，设置了 `I18n.locale = :de`，并创建了 `public/500.de.html` 和 `public/404.de.html`，就能显示本地化的错误页面。

Rails 并不限制 `I18n.locale` 选项的值，因此可以根据任意需求显示不同的内容。假设想让专业用户看到不同于普通用户的页面，可以在 `app/controllers/application_controller.rb` 中这么设置：

```ruby
before_action :set_expert_locale

def set_expert_locale
  I18n.locale = :expert if current_user.expert?
end
```

然后创建只显示给专业用户的 `app/views/posts/show.expert.html.erb` 视图。

详情参阅“[Rails 国际化 API](i18n.html)”一文。
