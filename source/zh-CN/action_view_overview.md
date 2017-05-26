# Action View 概览

读完本文后，您将学到：

*   Action View 是什么，如何在 Rails 中使用 Action View；
*   模板、局部视图和布局的最佳使用方法；
*   Action View 提供了哪些辅助方法，如何自己编写辅助方法；
*   如何使用本地化视图。

-----------------------------------------------------------------------------

NOTE: 本文原文尚未完工！

<a class="anchor" id="what-is-action-view"></a>

## Action View 是什么

在 Rails 中，Web 请求由 Action Controller（请参阅[Action Controller 概览](action_controller_overview.html)）和 Action View 处理。通常，Action Controller 参与和数据库的通信，并在需要时执行 CRUD 操作，然后由 Action View 负责编译响应。

Action View 模板使用混合了 HTML 标签的嵌入式 Ruby 语言编写。为了避免样板代码把模板弄乱，Action View 提供了许多辅助方法，用于创建表单、日期和字符串等常用组件。随着开发的深入，为应用添加新的辅助方法也很容易。

NOTE: Action View 的某些特性与 Active Record 有关，但这并不意味着 Action View 依赖 Active Record。Action View 是独立的软件包，可以和任何类型的 Ruby 库一起使用。

<a class="anchor" id="using-action-view-with-rails"></a>

## 在 Rails 中使用 Action View

在 `app/views` 文件夹中，每个控制器都有一个对应的文件夹，其中保存了控制器对应视图的模板文件。这些模板文件用于显示每个控制器动作产生的视图。

在 Rails 中使用脚手架生成器新建资源时，默认会执行下面的操作：

```sh
$ bin/rails generate scaffold article
      [...]
      invoke  scaffold_controller
      create    app/controllers/articles_controller.rb
      invoke    erb
      create      app/views/articles
      create      app/views/articles/index.html.erb
      create      app/views/articles/edit.html.erb
      create      app/views/articles/show.html.erb
      create      app/views/articles/new.html.erb
      create      app/views/articles/_form.html.erb
      [...]
```

在上面的输出结果中我们可以看到 Rails 中视图的命名约定。通常，视图和对应的控制器动作共享名称。例如，`articles_controller.rb` 控制器文件中的 `index` 动作对应 `app/views/articles` 文件夹中的 `index.html.erb` 视图文件。返回客户端的完整 HTML 由 ERB 视图文件和包装它的布局文件，以及视图可能引用的所有局部视图文件组成。后文会详细说明这三种文件。

<a class="anchor" id="templates-partials-and-layouts"></a>

## 模板、局部视图和布局

前面说过，最后输出的 HTML 由模板、局部视图和布局这三种 Rails 元素组成。下面分别进行简要介绍。

<a class="anchor" id="templates"></a>

### 模板

Action View 模板可以用多种方式编写。扩展名是 `.erb` 的模板文件混合使用 ERB（嵌入式 Ruby）和 HTML 编写，扩展名是 `.builder` 的模板文件使用 `Builder::XmlMarkup` 库编写。

Rails 支持多种模板系统，并使用文件扩展名加以区分。例如，使用 ERB 模板系统的 HTML 文件的扩展名是 `.html.erb`。

<a class="anchor" id="erb"></a>

#### ERB 模板

在 ERB 模板中，可以使用 `<% %>` 和 `<%= %>` 标签来包含 Ruby 代码。`<% %>` 标签用于执行不返回任何内容的 Ruby 代码，例如条件、循环或块，而 `<%= %>` 标签用于输出 Ruby 代码的执行结果。

下面是一个循环输出名称的例子：

```erb
<h1>Names of all the people</h1>
<% @people.each do |person| %>
  Name: <%= person.name %><br>
<% end %>
```

在上面的代码中，使用普通嵌入标签（`<% %>`）建立循环，使用输出嵌入标签（`<%= %>`）插入名称。请注意，这种用法不仅仅是建议用法（而是必须这样使用），因为在 ERB 模板中，普通的输出方法，例如 `print` 和 `puts` 方法，无法正常渲染。因此，下面的代码是错误的：

```erb
<%# WRONG %>
Hi, Mr. <% puts "Frodo" %>
```

要想删除前导和结尾空格，可以把 `<% %>` 标签替换为 `<%- -%>` 标签。

<a class="anchor" id="builder"></a>

#### Builder 模板

和 ERB 模板相比，Builder 模板更加按部就班，常用于生成 XML 内容。在扩展名为 `.builder` 的模板中，可以直接使用名为 `xml` 的 XmlMarkup 对象。

下面是一些简单的例子：

```ruby
xml.em("emphasized")
xml.em { xml.b("emph & bold") }
xml.a("A Link", "href" => "http://rubyonrails.org")
xml.target("name" => "compile", "option" => "fast")
```

上面的代码会生成下面的 XML：

```xml
<em>emphasized</em>
<em><b>emph &amp; bold</b></em>
<a href="http://rubyonrails.org">A link</a>
<target option="fast" name="compile" />
```

带有块的方法会作为 XML 标签处理，块中的内容会嵌入这个标签中。例如：

```ruby
xml.div {
  xml.h1(@person.name)
  xml.p(@person.bio)
}
```

上面的代码会生成下面的 XML：

```xml
<div>
  <h1>David Heinemeier Hansson</h1>
  <p>A product of Danish Design during the Winter of '79...</p>
</div>
```

下面是 Basecamp 网站用于生成 RSS 的完整的实际代码：

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

<a class="anchor" id="jbuilder"></a>

#### Jbuilder 模板系统

[Jbuilder](https://github.com/rails/jbuilder) 是由 Rails 团队维护并默认包含在 Rails Gemfile 中的 gem。它类似 Builder，但用于生成 JSON，而不是 XML。

如果你的应用中没有 Jbuilder 这个 gem，可以把下面的代码添加到 Gemfile：

```ruby
gem 'jbuilder'
```

在扩展名为 `.jbuilder` 的模板中，可以直接使用名为 `json` 的 Jbuilder 对象。

下面是一个简单的例子：

```ruby
json.name("Alex")
json.email("alex@example.com")
```

上面的代码会生成下面的 JSON：

```json
{
  "name": "Alex",
  "email": "alex@example.com"
}
```

关于 Jbuilder 模板的更多例子和信息，请参阅 [Jbuilder 文档](https://github.com/rails/jbuilder#jbuilder)。

<a class="anchor" id="template-caching"></a>

#### 模板缓存

默认情况下，Rails 会把所有模板分别编译为方法，以便进行渲染。在开发环境中，当我们修改了模板时，Rails 会检查文件的修改时间并自动重新编译。

<a class="anchor" id="partials"></a>

### 局部视图

局部视图模板，通常直接称为“局部视图”，作用是把渲染过程分成多个更容易管理的部分。局部视图从模板中提取代码片断并保存在独立的文件中，然后在模板中重用。

<a class="anchor" id="naming-partials"></a>

#### 局部视图的名称

在视图中我们使用 `render` 方法来渲染局部视图：

```erb
<%= render "menu" %>
```

在渲染视图的过程中，上面的代码会渲染 `_menu.html.erb` 局部视图文件。请注意开头的下划线：局部视图的文件名总是以下划线开头，以便和普通视图文件区分开来，但在引用局部视图时不写下划线。从其他文件夹中加载局部视图文件时同样遵守这一规则：

```erb
<%= render "shared/menu" %>
```

上面的代码会加载 `app/views/shared/_menu.html.erb` 局部视图文件。

<a class="anchor" id="using-partials-to-simplify-views"></a>

#### 使用局部视图来简化视图

使用局部视图的一种方式是把它们看作子程序（subroutine），也就是把细节内容从视图中移出来，这样会使视图更容易理解。例如：

```erb
<%= render "shared/ad_banner" %>

<h1>Products</h1>

<p>Here are a few of our fine products:</p>
<% @products.each do |product| %>
  <%= render partial: "product", locals: { product: product } %>
<% end %>

<%= render "shared/footer" %>
```

在上面的代码中，`_ad_banner.html.erb` 和 `_footer.html.erb` 局部视图可以在多个页面中使用。当我们专注于实现某个页面时，不必关心这些局部视图的细节。

<a class="anchor" id="render-without-partial-and-locals-options"></a>

#### 不使用 `partial` 和 `locals` 选项进行渲染

在前面的例子中，`render` 方法有两个选项：`partial` 和 `locals`。如果一共只有这两个选项，那么可以跳过不写。例如，下面的代码：

```erb
<%= render partial: "product", locals: { product: @product } %>
```

可以改写为：

```erb
<%= render "product", product: @product %>
```

<a class="anchor" id="the-as-and-object-options"></a>

#### `as` 和 `object` 选项

默认情况下，`ActionView::Partials::PartialRenderer` 的对象储存在和模板同名的局部变量中。因此，我们可以扩展下面的代码：

```erb
<%= render partial: "product" %>
```

在 `_product` 局部视图中，我们可以通过局部变量 `product` 引用 `@product` 实例变量：

```erb
<%= render partial: "product", locals: { product: @product } %>
```

`object` 选项用于直接指定想要在局部视图中使用的对象，常用于模板对象位于其他地方（例如位于其他实例变量或局部变量中）的情况。例如，下面的代码：

```erb
<%= render partial: "product", locals: { product: @item } %>
```

可以改写为：

```erb
<%= render partial: "product", object: @item %>
```

使用 `as` 选项可以为局部变量指定别的名称。例如，如果想把 `product` 换成 `item`，可以这么做：

```erb
<%= render partial: "product", object: @item, as: "item" %>
```

这等效于：

```erb
<%= render partial: "product", locals: { item: @item } %>
```

<a class="anchor" id="rendering-collections"></a>

#### 渲染集合

模板经常需要遍历集合并使用集合中的每个元素分别渲染子模板。在 Rails 中我们只需一行代码就可以完成这项工作。例如，下面这段渲染产品局部视图的代码：

```erb
<% @products.each do |product| %>
  <%= render partial: "product", locals: { product: product } %>
<% end %>
```

可以改写为：

```erb
<%= render partial: "product", collection: @products %>
```

当使用集合来渲染局部视图时，在每个局部视图实例中，都可以使用和局部视图同名的局部变量来访问集合中的元素。在本例中，局部视图是 `_product`，在这个局部视图中我们可以通过 `product` 局部变量来访问用于渲染局部视图的集合中的元素。

渲染集合还有一个简易写法。假设 `@products` 是 `Product` 实例的集合，上面的代码可以改写为：

```erb
<%= render @products %>
```

Rails 会根据集合中的模型名来确定应该使用哪个局部视图，在本例中模型名是 `Product`。实际上，我们甚至可以使用这种简易写法来渲染由不同模型实例组成的集合，Rails 会为集合中的每个元素选择适当的局部视图。

<a class="anchor" id="spacer-templates"></a>

#### 间隔模板

我们还可以使用 `:spacer_template` 选项来指定第二个局部视图（也就是间隔模板），在渲染第一个局部视图（也就是主局部视图）的两个实例之间会渲染这个间隔模板:

```erb
<%= render partial: @products, spacer_template: "product_ruler" %>
```

上面的代码会在两个 `_product` 局部视图（主局部视图）之间渲染 `_product_ruler` 局部视图（间隔模板）。

<a class="anchor" id="layouts"></a>

### 布局

布局是渲染 Rails 控制器返回结果时使用的公共视图模板。通常，Rails 应用中会包含多个视图用于渲染不同页面。例如，网站中用户登录后页面的布局，营销或销售页面的布局。用户登录后页面的布局可以包含在多个控制器动作中出现的顶级导航。SaaS 应用的销售页面布局可以包含指向“定价”和“联系我们”页面的顶级导航。不同布局可以有不同的外观和感官。关于布局的更多介绍，请参阅[Rails 布局和视图渲染](layouts_and_rendering.html)。

<a class="anchor" id="partial-layout"></a>

## 局部布局

应用于局部视图的布局称为局部布局。局部布局和应用于控制器动作的全局布局不一样，但两者的工作方式类似。

比如说我们想在页面中显示文章，并把文章放在 `div` 标签里。首先，我们新建一个 `Article` 实例：

```ruby
Article.create(body: 'Partial Layouts are cool!')
```

在 `show` 模板中，我们要在 `box` 布局中渲染 `_article` 局部视图：

**`articles/show.html.erb`**

```erb
<%= render partial: 'article', layout: 'box', locals: { article: @article } %>
```

`box` 布局只是把 `_article` 局部视图放在 `div` 标签里：

**`articles/_box.html.erb`**

```erb
<div class='box'>
  <%= yield %>
</div>
```

请注意，局部布局可以访问传递给 `render` 方法的局部变量 `article`。不过，和全局部局不同，局部布局的文件名以下划线开头。

我们还可以直接渲染代码块而不调用 `yield` 方法。例如，如果不使用 `_article` 局部视图，我们可以像下面这样编写代码：

**`articles/show.html.erb`**

```erb
<% render(layout: 'box', locals: { article: @article }) do %>
  <div>
    <p><%= article.body %></p>
  </div>
<% end %>
```

假设我们使用的 `_box` 局部布局和前面一样，那么这里模板的渲染结果也会和前面一样。

<a class="anchor" id="view-paths"></a>

## 视图路径

在渲染响应时，控制器需要解析不同视图所在的位置。默认情况下，控制器只查找 `app/views` 文件夹。

我们可以使用 `prepend_view_path` 和 `append_view_path` 方法分别在查找路径的开头和结尾添加其他位置。

<a class="anchor" id="prepend-view-path"></a>

### 在开头添加视图路径

例如，当需要把视图放在子域名的不同文件夹中时，我们可以使用下面的代码：

```ruby
prepend_view_path "app/views/#{request.subdomain}"
```

这样在解析视图时，Action View 会首先查找这个文件夹。

<a class="anchor" id="append-view-path"></a>

### 在末尾添加视图路径

同样，我们可以在查找路径的末尾添加视图路径：

```ruby
append_view_path "app/views/direct"
```

上面的代码会在查找路径的末尾添加 `app/views/direct` 文件夹。

<a class="anchor" id="overview-of-helpers-provided-by-action-view"></a>

## Action View 提供的辅助方法概述

NOTE: 本节内容仍在完善中，目前并没有列出所有辅助方法。关于辅助方法的完整列表，请参阅 [API 文档](http://api.rubyonrails.org/classes/ActionView/Helpers.html)。

本节内容只是对 Action View 中可用辅助方法的简要概述。在阅读本节内容之后，推荐查看 [API 文档](http://api.rubyonrails.org/classes/ActionView/Helpers.html)，文档详细介绍了所有辅助方法。

<a class="anchor" id="assettaghelper"></a>

### `AssetTagHelper` 模块

`AssetTagHelper` 模块提供的方法用于生成链接静态资源文件的 HTML 代码，例如链接图像、JavaScript 文件和订阅源的 HTML 代码。

默认情况下，Rails 会链接当前主机 `public` 文件夹中的静态资源文件。要想链接专用的静态资源文件服务器上的文件，可以设置 Rails 应用配置文件（通常是 `config/environments/production.rb` 文件）中的 `config.action_controller.asset_host` 选项。假如静态资源文件服务器的域名是 `assets.example.com`，我们可以像下面这样设置：

```ruby
config.action_controller.asset_host = "assets.example.com"
image_tag("rails.png") # => <img src="http://assets.example.com/images/rails.png" alt="Rails" />
```

<a class="anchor" id="auto-discovery-link-tag"></a>

#### `auto_discovery_link_tag` 方法

`auto_discovery_link_tag` 方法用于返回链接标签，使浏览器和订阅阅读器可以自动检测 RSS 或 Atom 订阅源。

```ruby
auto_discovery_link_tag(:rss, "http://www.example.com/feed.rss", { title: "RSS Feed" })
# => <link rel="alternate" type="application/rss+xml" title="RSS Feed" href="http://www.example.com/feed.rss" />
```

<a class="anchor" id="image-path"></a>

#### `image_path` 方法

`image_path` 方法用于计算 `app/assets/images` 文件夹中图像资源的路径，得到的路径是从根目录开始的完整路径（也就是绝对路径）。`image_tag` 方法在内部使用 `image_path` 方法生成图像路径。

```ruby
image_path("edit.png") # => /assets/edit.png
```

当 `config.assets.digest` 选项设置为 `true` 时，Rails 会为图像资源的文件名添加指纹。

```ruby
image_path("edit.png") # => /assets/edit-2d1a2db63fc738690021fedb5a65b68e.png
```

<a class="anchor" id="image-url"></a>

#### `image_url` 方法

`image_url` 方法用于计算 `app/assets/images` 文件夹中图像资源的 URL 地址。`image_url` 方法在内部调用了 `image_path` 方法，并把得到的图像资源路径和当前主机或静态资源文件服务器的 URL 地址合并。

```ruby
image_url("edit.png") # => http://www.example.com/assets/edit.png
```

<a class="anchor" id="image-tag"></a>

#### `image_tag` 方法

`image_tag` 方法用于返回 HTML 图像标签。此方法接受图像的完整路径或 `app/assets/images` 文件夹中图像的文件名作为参数。

```ruby
image_tag("icon.png") # => <img src="/assets/icon.png" alt="Icon" />
```

<a class="anchor" id="javascript-include-tag"></a>

#### `javascript_include_tag` 方法

`javascript_include_tag` 方法用于返回 HTML 脚本标签。此方法接受 `app/assets/javascripts` 文件夹中 JavaScript 文件的文件名（`.js` 后缀可以省略）或 JavaScript 文件的完整路径（绝对路径）作为参数。

```ruby
javascript_include_tag "common" # => <script src="/assets/common.js"></script>
```

如果 Rails 应用不使用 Asset Pipeline，就需要向 `javascript_include_tag` 方法传递 `:defaults` 参数来包含 jQuery JavaScript 库。此时，如果 `app/assets/javascripts` 文件夹中存在 `application.js` 文件，那么这个文件也会包含到页面中。

```ruby
javascript_include_tag :defaults
```

通过向 `javascript_include_tag` 方法传递 `:all` 参数，可以把 `app/assets/javascripts` 文件夹下的所有 JavaScript 文件包含到页面中。

```ruby
javascript_include_tag :all
```

我们还可以把多个 JavaScript 文件缓存为一个文件，这样可以减少下载时的 HTTP 连接数，同时还可以启用 gzip 压缩来提高传输速度。当 `ActionController::Base.perform_caching` 选项设置为 `true` 时才会启用缓存，此选项在生产环境下默认为 `true`，在开发环境下默认为 `false`。

```ruby
javascript_include_tag :all, cache: true
# => <script src="/javascripts/all.js"></script>
```

<a class="anchor" id="javascript-path"></a>

#### `javascript_path` 方法

`javascript_path` 方法用于计算 `app/assets/javascripts` 文件夹中 JavaScript 资源的路径。如果没有指定文件的扩展名，Rails 会自动添加 `.js`。`javascript_path` 方法返回 JavaScript 资源的完整路径（绝对路径）。`javascript_include_tag` 方法在内部使用 `javascript_path` 方法生成脚本路径。

```ruby
javascript_path "common" # => /assets/common.js
```

<a class="anchor" id="javascript-url"></a>

#### `javascript_url` 方法

`javascript_url` 方法用于计算 `app/assets/javascripts` 文件夹中 JavaScript 资源的 URL 地址。`javascript_url` 方法在内部调用了 `javascript_path` 方法，并把得到的 JavaScript 资源的路径和当前主机或静态资源文件服务器的 URL 地址合并。

```ruby
javascript_url "common" # => http://www.example.com/assets/common.js
```

<a class="anchor" id="stylesheet-link-tag"></a>

#### `stylesheet_link_tag` 方法

`stylesheet_link_tag` 方法用于返回样式表链接标签。如果没有指定文件的扩展名，Rails 会自动添加 `.css`。

```ruby
stylesheet_link_tag "application"
# => <link href="/assets/application.css" media="screen" rel="stylesheet" />
```

通过向 `stylesheet_link_tag` 方法传递 `:all` 参数，可以把样式表文件夹中的所有样式表包含到页面中。

```ruby
stylesheet_link_tag :all
```

我们还可以把多个样式表缓存为一个文件，这样可以减少下载时的 HTTP 连接数，同时还可以启用 gzip 压缩来提高传输速度。当 `ActionController::Base.perform_caching` 选项设置为 `true` 时才会启用缓存，此选项在生产环境下默认为 `true`，在开发环境下默认为 `false`。

```ruby
stylesheet_link_tag :all, cache: true
# => <link href="/assets/all.css" media="screen" rel="stylesheet" />
```

<a class="anchor" id="stylesheet-path"></a>

#### `stylesheet_path` 方法

`stylesheet_path` 方法用于计算 `app/assets/stylesheets` 文件夹中样式表资源的路径。如果没有指定文件的扩展名，Rails 会自动添加 `.css`。`stylesheet_path` 方法返回样式表资源的完整路径（绝对路径）。`stylesheet_link_tag` 方法在内部使用 `stylesheet_path` 方法生成样式表路径。

```ruby
stylesheet_path "application" # => /assets/application.css
```

<a class="anchor" id="stylesheet-url"></a>

#### `stylesheet_url` 方法

`stylesheet_url` 方法用于计算 `app/assets/stylesheets` 文件夹中样式表资源的 URL 地址。`stylesheet_url` 方法在内部调用了 `stylesheet_path` 方法，并把得到的样式表资源路径和当前主机或静态资源文件服务器的 URL 地址合并。

```ruby
stylesheet_url "application" # => http://www.example.com/assets/application.css
```

<a class="anchor" id="atomfeedhelper"></a>

### `AtomFeedHelper` 模块

<a class="anchor" id="atom-feed"></a>

#### `atom_feed` 方法

通过 `atom_feed` 辅助方法我们可以轻松创建 Atom 订阅源。下面是一个完整的示例：

`config/routes.rb`

```ruby
resources :articles
```

`app/controllers/articles_controller.rb`

```ruby
def index
  @articles = Article.all

  respond_to do |format|
    format.html
    format.atom
  end
end
```

`app/views/articles/index.atom.builder`

```ruby
atom_feed do |feed|
  feed.title("Articles Index")
  feed.updated(@articles.first.created_at)

  @articles.each do |article|
    feed.entry(article) do |entry|
      entry.title(article.title)
      entry.content(article.body, type: 'html')

      entry.author do |author|
        author.name(article.author_name)
      end
    end
  end
end
```

<a class="anchor" id="benchmarkhelper"></a>

### `BenchmarkHelper` 模块

<a class="anchor" id="benchmark"></a>

#### `benchmark` 方法

`benchmark` 方法用于测量模板中某个块的执行时间，并把测量结果写入日志。`benchmark` 方法常用于测量耗时操作或可能的性能瓶颈的执行时间。

```erb
<% benchmark "Process data files" do %>
  <%= expensive_files_operation %>
<% end %>
```

上面的代码会在日志中写入类似 `Process data files (0.34523)` 的测量结果，我们可以通过比较执行时间来优化代码。

<a class="anchor" id="cachehelper"></a>

### `CacheHelper` 模块

<a class="anchor" id="cache"></a>

#### `cache` 方法

`cache` 方法用于缓存视图片断而不是整个动作或页面。此方法常用于缓存页面中诸如菜单、新闻主题列表、静态 HTML 片断等内容。`cache` 方法接受块作为参数，块中包含要缓存的内容。关于 `cache` 方法的更多介绍，请参阅 `AbstractController::Caching::Fragments` 模块的文档。

```erb
<% cache do %>
  <%= render "shared/footer" %>
<% end %>
```

<a class="anchor" id="capturehelper"></a>

### `CaptureHelper` 模块

<a class="anchor" id="capture"></a>

#### `capture` 方法

`capture` 方法用于取出模板的一部分并储存在变量中，然后我们可以在模板或布局中的任何地方使用这个变量。

```erb
<% @greeting = capture do %>
  <p>Welcome! The date and time is <%= Time.now %></p>
<% end %>
```

可以在模板或布局中的任何地方使用 `@greeting` 变量。

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

<a class="anchor" id="content-for"></a>

#### `content_for` 方法

`content_for` 方法以块的方式把模板内容保存在标识符中，然后我们可以在模板或布局中把这个标识符传递给 `yield` 方法作为参数来调用所保存的内容。

假如应用拥有标准布局，同时拥有一个特殊页面，这个特殊页面需要包含其他页面都不需要的 JavaScript 脚本。为此我们可以在这个特殊页面中使用 `content_for` 方法来包含所需的 JavaScript 脚本，而不必增加其他页面的体积。

`app/views/layouts/application.html.erb`

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

`app/views/articles/special.html.erb`

```erb
<p>This is a special page.</p>

<% content_for :special_script do %>
  <script>alert('Hello!')</script>
<% end %>
```

<a class="anchor" id="datehelper"></a>

### `DateHelper` 模块

<a class="anchor" id="date-select"></a>

#### `date_select` 方法

`date_select` 方法返回年、月、日的选择列表标签，用于设置 `date` 类型的属性的值。

```ruby
date_select("article", "published_on")
```

<a class="anchor" id="datetime-select"></a>

#### `datetime_select` 方法

`datetime_select` 方法返回年、月、日、时、分的选择列表标签，用于设置 `datetime` 类型的属性的值。

```ruby
datetime_select("article", "published_on")
```

<a class="anchor" id="distance-of-time-in-words"></a>

#### `distance_of_time_in_words` 方法

`distance_of_time_in_words` 方法用于计算两个 `Time` 对象、`Date` 对象或秒数的大致时间间隔。把 `include_seconds` 选项设置为 `true` 可以得到更精确的时间间隔。

```ruby
distance_of_time_in_words(Time.now, Time.now + 15.seconds)        # => less than a minute
distance_of_time_in_words(Time.now, Time.now + 15.seconds, include_seconds: true)  # => less than 20 seconds
```

<a class="anchor" id="select-date"></a>

#### `select_date` 方法

`select_date` 方法返回年、月、日的选择列表标签，并通过 `Date` 对象来设置默认值。

```ruby
# 生成一个日期选择列表，默认选中指定的日期（六天以后）
select_date(Time.today + 6.days)

# 生成一个日期选择列表，默认选中今天（未指定日期）
select_date()
```

<a class="anchor" id="select-datetime"></a>

#### `select_datetime` 方法

`select_datetime` 方法返回年、月、日、时、分的选择列表标签，并通过 `Datetime` 对象来设置默认值。

```ruby
# 生成一个日期时间选择列表，默认选中指定的日期时间（四天以后）
select_datetime(Time.now + 4.days)

# 生成一个日期时间选择列表，默认选中今天（未指定日期时间）
select_datetime()
```

<a class="anchor" id="select-day"></a>

#### `select_day` 方法

`select_day` 方法返回当月全部日子的选择列表标签，如 1 到 31，并把当日设置为默认值。

```ruby
# 生成一个日子选择列表，默认选中指定的日子
select_day(Time.today + 2.days)

# 生成一个日子选择列表，默认选中指定数字对应的日子
select_day(5)
```

<a class="anchor" id="select-hour"></a>

#### `select_hour` 方法

`select_hour` 方法返回一天中 24 小时的选择列表标签，即 0 到 23，并把当前小时设置为默认值。

```ruby
# 生成一个小时选择列表，默认选中指定的小时
select_hour(Time.now + 6.hours)
```

<a class="anchor" id="select-minute"></a>

#### `select_minute` 方法

`select_minute` 方法返回一小时中 60 分钟的选择列表标签，即 0 到 59，并把当前分钟设置为默认值。

```ruby
# 生成一个分钟选择列表，默认选中指定的分钟
select_minute(Time.now + 10.minutes)
```

<a class="anchor" id="select-month"></a>

#### `select_month` 方法

`select_month` 方法返回一年中 12 个月的选择列表标签，并把当月设置为默认值。

```ruby
# 生成一个月份选择列表，默认选中当前月份
select_month(Date.today)
```

<a class="anchor" id="select-second"></a>

#### `select_second` 方法

`select_second` 方法返回一分钟中 60 秒的选择列表标签，即 0 到 59，并把当前秒设置为默认值。

```ruby
# 生成一个秒数选择列表，默认选中指定的秒数
select_second(Time.now + 16.seconds)
```

<a class="anchor" id="select-time"></a>

#### `select_time` 方法

`select_time` 方法返回时、分的选择列表标签，并通过 `Time` 对象来设置默认值。

```ruby
# 生成一个时间选择列表，默认选中指定的时间
select_time(Time.now)
```

<a class="anchor" id="select-year"></a>

#### `select_year` 方法

`select_year` 方法返回当年和前后各五年的选择列表标签，并把当年设置为默认值。可以通过 `:start_year` 和 `:end_year` 选项自定义年份范围。

```ruby
# 选择今天所在年份前后五年的年份选择列表，默认选中当年
select_year(Date.today)

# 选择一个从 1900 年到 20009 年的年份选择列表，默认选中当年
select_year(Date.today, start_year: 1900, end_year: 2009)
```

<a class="anchor" id="time-ago-in-words"></a>

#### `time_ago_in_words` 方法

`time_ago_in_words` 方法和 `distance_of_time_in_words` 方法类似，区别在于 `time_ago_in_words` 方法计算的是指定时间到 `Time.now` 对应的当前时间的时间间隔。

```ruby
time_ago_in_words(3.minutes.from_now)  # => 3 minutes
```

<a class="anchor" id="time-select"></a>

#### `time_select` 方法

`time_select` 方返回时、分、秒的选择列表标签（其中秒可选），用于设置 `time` 类型的属性的值。选择的结果作为多个参数赋值给 Active Record 对象。

```ruby
# 生成一个时间选择标签，通过 POST 发送后存储在提交的属性中的 order 变量中
time_select("order", "submitted")
```

<a class="anchor" id="debughelper"></a>

### `DebugHelper` 模块

`debug` 方法返回放在 `pre` 标签里的 YAML 格式的对象内容。这种审查对象的方式可读性很好。

```ruby
my_hash = { 'first' => 1, 'second' => 'two', 'third' => [1,2,3] }
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

<a class="anchor" id="formhelper"></a>

### `FormHelper` 模块

和仅使用标准 HTML 元素相比，表单辅助方法提供了一组基于模型创建表单的方法，可以大大简化模型的处理过程。表单辅助方法生成表单的 HTML 代码，并提供了用于生成各种输入组件（如文本框、密码框、选择列表等）的 HTML 代码的辅助方法。在提交表单时（用户点击提交按钮或通过 JavaScript 调用 `form.submit`），表单输入会绑定到 `params` 对象上并回传给控制器。

表单辅助方法分为两类：一类专门用于处理模型属性，另一类不处理模型属性。本节中介绍的辅助方法都属于前者，后者的例子可参阅 `ActionView::Helpers::FormTagHelper` 模块的文档。

`form_for` 辅助方法是 `FormHelper` 模块中最核心的方法，用于创建处理模型实例的表单。例如，假设我们想为 `Person` 模型创建实例：

```erb
# 注意：要在控制器中创建 @person 变量（例如 @person = Person.new）
<%= form_for @person, url: { action: "create" } do |f| %>
  <%= f.text_field :first_name %>
  <%= f.text_field :last_name %>
  <%= submit_tag 'Create' %>
<% end %>
```

上面的代码会生成下面的 HTML：

```html
<form action="/people/create" method="post">
  <input id="person_first_name" name="person[first_name]" type="text" />
  <input id="person_last_name" name="person[last_name]" type="text" />
  <input name="commit" type="submit" value="Create" />
</form>
```

提交表单时创建的 `params` 对象会像下面这样：

```ruby
{ "action" => "create", "controller" => "people", "person" => { "first_name" => "William", "last_name" => "Smith" } }
```

`params` 散列包含了嵌套的 `person` 值，这个值可以在控制器中通过 `params[:person]` 访问。

<a class="anchor" id="check-box"></a>

#### `check_box` 方法

`check_box` 方法返回用于处理指定模型属性的复选框标签。

```ruby
# 假设 @article.validated? 的值是 1
check_box("article", "validated")
# => <input type="checkbox" id="article_validated" name="article[validated]" value="1" />
#    <input name="article[validated]" type="hidden" value="0" />
```

<a class="anchor" id="fields-for"></a>

#### `fields_for` 方法

和 `form_for` 方法类似，`fields_for` 方法创建用于处理指定模型对象的作用域，区别在于 `fields_for` 方法不会创建 `form` 标签。`fields_for` 方法适用于在同一个表单中指明附加的模型对象。

```erb
<%= form_for @person, url: { action: "update" } do |person_form| %>
  First name: <%= person_form.text_field :first_name %>
  Last name : <%= person_form.text_field :last_name %>

  <%= fields_for @person.permission do |permission_fields| %>
    Admin?  : <%= permission_fields.check_box :admin %>
  <% end %>
<% end %>
```

<a class="anchor" id="file-field"></a>

#### `file_field` 方法

`file_field` 方法返回用于处理指定模型属性的文件上传组件标签。

```ruby
file_field(:user, :avatar)
# => <input type="file" id="user_avatar" name="user[avatar]" />
```

<a class="anchor" id="form-for"></a>

#### `form_for` 方法

`form_for` 方法创建用于处理指定模型对象的表单和作用域，表单的各个组件用于处理模型对象的对应属性。

```erb
<%= form_for @article do |f| %>
  <%= f.label :title, 'Title' %>:
  <%= f.text_field :title %><br>
  <%= f.label :body, 'Body' %>:
  <%= f.text_area :body %><br>
<% end %>
```

<a class="anchor" id="hidden-field"></a>

#### `hidden_​​field` 方法

`hidden_​​field` 方法返回用于处理指定模型属性的隐藏输入字段标签。

```ruby
hidden_field(:user, :token)
# => <input type="hidden" id="user_token" name="user[token]" value="#{@user.token}" />
```

<a class="anchor" id="label"></a>

#### `label` 方法

`label` 方法返回用于处理指定模型属性的文本框的 label 标签。

```ruby
label(:article, :title)
# => <label for="article_title">Title</label>
```

<a class="anchor" id="password-field"></a>

#### `password_field` 方法

`password_field` 方法返回用于处理指定模型属性的密码框标签。

```ruby
password_field(:login, :pass)
# => <input type="text" id="login_pass" name="login[pass]" value="#{@login.pass}" />
```

<a class="anchor" id="radio-button"></a>

#### `radio_button` 方法

`radio_button` 方法返回用于处理指定模型属性的单选按钮标签。

```ruby
# 假设 @article.category 的值是“rails”
radio_button("article", "category", "rails")
radio_button("article", "category", "java")
# => <input type="radio" id="article_category_rails" name="article[category]" value="rails" checked="checked" />
#    <input type="radio" id="article_category_java" name="article[category]" value="java" />
```

<a class="anchor" id="text-area"></a>

#### `text_area` 方法

`text_area` 方法返回用于处理指定模型属性的文本区域标签。

```ruby
text_area(:comment, :text, size: "20x30")
# => <textarea cols="20" rows="30" id="comment_text" name="comment[text]">
#      #{@comment.text}
#    </textarea>
```

<a class="anchor" id="text-field"></a>

#### `text_field` 方法

`text_field` 方法返回用于处理指定模型属性的文本框标签。

```ruby
text_field(:article, :title)
# => <input type="text" id="article_title" name="article[title]" value="#{@article.title}" />
```

<a class="anchor" id="email-field"></a>

#### `email_field` 方法

`email_field` 方法返回用于处理指定模型属性的电子邮件地址输入框标签。

```ruby
email_field(:user, :email)
# => <input type="email" id="user_email" name="user[email]" value="#{@user.email}" />
```

<a class="anchor" id="url-field"></a>

#### `url_field` 方法

`url_field` 方法返回用于处理指定模型属性的 URL 地址输入框标签。

```ruby
url_field(:user, :url)
# => <input type="url" id="user_url" name="user[url]" value="#{@user.url}" />
```

<a class="anchor" id="formoptionshelper"></a>

### `FormOptionsHelper` 模块

`FormOptionsHelper` 模块提供了许多方法，用于把不同类型的容器转换为一组选项标签。

<a class="anchor" id="collection-select"></a>

#### `collection_select` 方法

`collection_select` 方法返回一个集合的选择列表标签，其中每个集合元素的两个指定方法的返回值分别是每个选项的值和文本。

在下面的示例代码中，我们定义了两个模型：

```ruby
class Article < ApplicationRecord
  belongs_to :author
end

class Author < ApplicationRecord
  has_many :articles
  def name_with_initial
    "#{first_name.first}. #{last_name}"
  end
end
```

在下面的示例代码中，`collection_select` 方法用于生成 `Article` 模型的实例 `@article` 的相关作者的选择列表：

```ruby
collection_select(:article, :author_id, Author.all, :id, :name_with_initial, { prompt: true })
```

如果 `@article.author_id` 的值为 1，上面的代码会生成下面的 HTML：

```html
<select name="article[author_id]">
  <option value="">Please select</option>
  <option value="1" selected="selected">D. Heinemeier Hansson</option>
  <option value="2">D. Thomas</option>
  <option value="3">M. Clark</option>
</select>
```

<a class="anchor" id="collection-radio-buttons"></a>

#### `collection_radio_buttons` 方法

`collection_radio_buttons` 方法返回一个集合的单选按钮标签，其中每个集合元素的两个指定方法的返回值分别是每个选项的值和文本。

在下面的示例代码中，我们定义了两个模型：

```ruby
class Article < ApplicationRecord
  belongs_to :author
end

class Author < ApplicationRecord
  has_many :articles
  def name_with_initial
    "#{first_name.first}. #{last_name}"
  end
end
```

在下面的示例代码中，`collection_radio_buttons` 方法用于生成 `Article` 模型的实例 `@article` 的相关作者的单选按钮：

```ruby
collection_radio_buttons(:article, :author_id, Author.all, :id, :name_with_initial)
```

如果 `@article.author_id` 的值为 1，上面的代码会生成下面的 HTML：

```html
<input id="article_author_id_1" name="article[author_id]" type="radio" value="1" checked="checked" />
<label for="article_author_id_1">D. Heinemeier Hansson</label>
<input id="article_author_id_2" name="article[author_id]" type="radio" value="2" />
<label for="article_author_id_2">D. Thomas</label>
<input id="article_author_id_3" name="article[author_id]" type="radio" value="3" />
<label for="article_author_id_3">M. Clark</label>
```

<a class="anchor" id="collection-check-boxes"></a>

#### `collection_check_boxes` 方法

`collection_check_boxes` 方法返回一个集合的复选框标签，其中每个集合元素的两个指定方法的返回值分别是每个选项的值和文本。

在下面的示例代码中，我们定义了两个模型：

```ruby
class Article < ApplicationRecord
  has_and_belongs_to_many :authors
end

class Author < ApplicationRecord
  has_and_belongs_to_many :articles
  def name_with_initial
    "#{first_name.first}. #{last_name}"
  end
end
```

在下面的示例代码中，`collection_check_boxes` 方法用于生成 `Article` 模型的实例 `@article` 的相关作者的复选框：

```ruby
collection_check_boxes(:article, :author_ids, Author.all, :id, :name_with_initial)
```

如果 `@article.author_ids` 的值为 `[1]`，上面的代码会生成下面的 HTML：

```html
<input id="article_author_ids_1" name="article[author_ids][]" type="checkbox" value="1" checked="checked" />
<label for="article_author_ids_1">D. Heinemeier Hansson</label>
<input id="article_author_ids_2" name="article[author_ids][]" type="checkbox" value="2" />
<label for="article_author_ids_2">D. Thomas</label>
<input id="article_author_ids_3" name="article[author_ids][]" type="checkbox" value="3" />
<label for="article_author_ids_3">M. Clark</label>
<input name="article[author_ids][]" type="hidden" value="" />
```

<a class="anchor" id="option-groups-from-collection-for-select"></a>

#### `option_groups_from_collection_for_select` 方法

和 `options_from_collection_for_select` 方法类似，`option_groups_from_collection_for_select` 方法返回一组选项标签，区别在于使用 `option_groups_from_collection_for_select` 方法时这些选项会根据模型的关联关系用 `optgroup` 标签分组。

在下面的示例代码中，我们定义了两个模型：

```ruby
class Continent < ApplicationRecord
  has_many :countries
  # attribs: id, name
end

class Country < ApplicationRecord
  belongs_to :continent
  # attribs: id, name, continent_id
end
```

示例用法：

```ruby
option_groups_from_collection_for_select(@continents, :countries, :name, :id, :name, 3)
```

可能的输出结果：

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

注意：`option_groups_from_collection_for_select` 方法只返回 `optgroup` 和 `option` 标签，我们要把这些 `optgroup` 和 `option` 标签放在 `select` 标签里。

<a class="anchor" id="options-for-select"></a>

#### `options_for_select` 方法

`options_for_select` 方法接受容器（如散列、数组、可枚举对象、自定义类型）作为参数，返回一组选项标签。

```ruby
options_for_select([ "VISA", "MasterCard" ])
# => <option>VISA</option> <option>MasterCard</option>
```

注意：`options_for_select` 方法只返回 `option` 标签，我们要把这些 `option` 标签放在 `select` 标签里。

<a class="anchor" id="options-from-collection-for-select"></a>

#### `options_from_collection_for_select` 方法

`options_from_collection_for_select` 方法通过遍历集合返回一组选项标签，其中每个集合元素的 `value_method` 和 `text_method` 方法的返回值分别是每个选项的值和文本。

```ruby
# options_from_collection_for_select(collection, value_method, text_method, selected = nil)
```

在下面的示例代码中，我们遍历 `@project.people` 集合得到 `person` 元素，`person.id` 和 `person.name` 方法分别是前面提到的 `value_method` 和 `text_method` 方法，这两个方法分别返回选项的值和文本：

```ruby
options_from_collection_for_select(@project.people, "id", "name")
# => <option value="#{person.id}">#{person.name}</option>
```

注意：`options_from_collection_for_select` 方法只返回 `option` 标签，我们要把这些 `option` 标签放在 `select` 标签里。

<a class="anchor" id="select"></a>

#### `select` 方法

`select` 方法使用指定对象和方法创建选择列表标签。

示例用法：

```ruby
select("article", "person_id", Person.all.collect { |p| [ p.name, p.id ] }, { include_blank: true })
```

如果 `@article.persion_id` 的值为 1，上面的代码会生成下面的 HTML：

```html
<select name="article[person_id]">
  <option value=""></option>
  <option value="1" selected="selected">David</option>
  <option value="2">Eileen</option>
  <option value="3">Rafael</option>
</select>
```

<a class="anchor" id="time-zone-options-for-select"></a>

#### `time_zone_options_for_select` 方法

`time_zone_options_for_select` 方法返回一组选项标签，其中每个选项对应一个时区，这些时区几乎包含了世界上所有的时区。

<a class="anchor" id="time-zone-select"></a>

#### `time_zone_select` 方法

`time_zone_select` 方法返回时区的选择列表标签，其中选项标签是通过 `time_zone_options_for_select` 方法生成的。

```ruby
time_zone_select( "user", "time_zone")
```

<a class="anchor" id="date-field"></a>

#### `date_field` 方法

`date_field` 方法返回用于处理指定模型属性的日期输入框标签。

```ruby
date_field("user", "dob")
```

<a class="anchor" id="formtaghelper"></a>

### `FormTagHelper` 模块

`FormTagHelper` 模块提供了许多用于创建表单标签的方法。和 `FormHelper` 模块不同，`FormTagHelper` 模块提供的方法不依赖于传递给模板的 Active Record 对象。作为替代，我们可以手动为表单的各个组件的标签提供 `name` 和 `value` 属性。

<a class="anchor" id="check-box-tag"></a>

#### `check_box_tag` 方法

`check_box_tag` 方法用于创建复选框标签。

```ruby
check_box_tag 'accept'
# => <input id="accept" name="accept" type="checkbox" value="1" />
```

<a class="anchor" id="field-set-tag"></a>

#### `field_set_tag` 方法

`field_set_tag` 方法用于创建 `fieldset` 标签。

```erb
<%= field_set_tag do %>
  <p><%= text_field_tag 'name' %></p>
<% end %>
# => <fieldset><p><input id="name" name="name" type="text" /></p></fieldset>
```

<a class="anchor" id="file-field-tag"></a>

#### `file_field_tag` 方法

`file_field_tag` 方法用于创建文件上传组件标签。

```erb
<%= form_tag({ action: "post" }, multipart: true) do %>
  <label for="file">File to Upload</label> <%= file_field_tag "file" %>
  <%= submit_tag %>
<% end %>
```

示例输出：

```ruby
file_field_tag 'attachment'
# => <input id="attachment" name="attachment" type="file" />
```

<a class="anchor" id="form-tag"></a>

#### `form_tag` 方法

`form_tag` 方法用于创建表单标签。和 `ActionController::Base#url_for` 方法类似，`form_tag` 方法的第一个参数是 `url_for_options` 选项，用于说明提交表单的 URL。

```erb
<%= form_tag '/articles' do %>
  <div><%= submit_tag 'Save' %></div>
<% end %>
# => <form action="/articles" method="post"><div><input type="submit" name="submit" value="Save" /></div></form>
```

<a class="anchor" id="hidden-field-tag"></a>

#### `hidden_​​field_tag` 方法

`hidden_​​field_tag` 方法用于创建隐藏输入字段标签。隐藏输入字段用于传递因 HTTP 无状态特性而丢失的数据，或不想让用户看到的数据。

```ruby
hidden_field_tag 'token', 'VUBJKB23UIVI1UU1VOBVI@'
# => <input id="token" name="token" type="hidden" value="VUBJKB23UIVI1UU1VOBVI@" />
```

<a class="anchor" id="image-submit-tag"></a>

#### `image_submit_tag` 方法

`image_submit_tag` 方法会显示一张图像，点击这张图像会提交表单。

```ruby
image_submit_tag("login.png")
# => <input src="/images/login.png" type="image" />
```

<a class="anchor" id="label-tag"></a>

#### `label_tag` 方法

`label_tag` 方法用于创建 `label` 标签。

```ruby
label_tag 'name'
# => <label for="name">Name</label>
```

<a class="anchor" id="password-field-tag"></a>

#### `password_field_tag` 方法

`password_field_tag` 方法用于创建密码框标签。用户在密码框中输入的密码会被隐藏起来。

```ruby
password_field_tag 'pass'
# => <input id="pass" name="pass" type="password" />
```

<a class="anchor" id="radio-button-tag"></a>

#### `radio_button_tag` 方法

`radio_button_tag` 方法用于创建单选按钮标签。为一组单选按钮设置相同的 `name` 属性即可实现对一组选项进行单选。

```ruby
radio_button_tag 'gender', 'male'
# => <input id="gender_male" name="gender" type="radio" value="male" />
```

<a class="anchor" id="select-tag"></a>

#### `select_tag` 方法

`select_tag` 方法用于创建选择列表标签。

```ruby
select_tag "people", "<option>David</option>"
# => <select id="people" name="people"><option>David</option></select>
```

<a class="anchor" id="submit-tag"></a>

#### `submit_tag` 方法

`submit_tag` 方法用于创建提交按钮标签，并在按钮上显示指定的文本。

```ruby
submit_tag "Publish this article"
# => <input name="commit" type="submit" value="Publish this article" />
```

<a class="anchor" id="text-area-tag"></a>

#### `text_area_tag` 方法

`text_area_tag` 方法用于创建文本区域标签。文本区域用于输入较长的文本，如博客帖子或页面描述。

```ruby
text_area_tag 'article'
# => <textarea id="article" name="article"></textarea>
```

<a class="anchor" id="text-field-tag"></a>

#### `text_field_tag` 方法

`text_field_tag` 方法用于创建文本框标签。文本框用于输入较短的文本，如用户名或搜索关键词。

```ruby
text_field_tag 'name'
# => <input id="name" name="name" type="text" />
```

<a class="anchor" id="email-field-tag"></a>

#### `email_field_tag` 方法

`email_field_tag` 方法用于创建电子邮件地址输入框标签。

```ruby
email_field_tag 'email'
# => <input id="email" name="email" type="email" />
```

<a class="anchor" id="url-field-tag"></a>

#### `url_field_tag` 方法

`url_field_tag` 方法用于创建 URL 地址输入框标签。

```ruby
url_field_tag 'url'
# => <input id="url" name="url" type="url" />
```

<a class="anchor" id="date-field-tag"></a>

#### `date_field_tag` 方法

`date_field_tag` 方法用于创建日期输入框标签。

```ruby
date_field_tag "dob"
# => <input id="dob" name="dob" type="date" />
```

<a class="anchor" id="javascripthelper"></a>

### `JavaScriptHelper` 模块

`JavaScriptHelper` 模块提供在视图中使用 JavaScript 的相关方法。

<a class="anchor" id="escape-javascript"></a>

#### `escape_javascript` 方法

`escape_javascript` 方法转义 JavaScript 代码中的回车符、单引号和双引号。

<a class="anchor" id="javascript-tag"></a>

#### `javascript_tag` 方法

`javascript_tag` 方法返回放在 `script` 标签里的 JavaScript 代码。

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

<a class="anchor" id="numberhelper"></a>

### `NumberHelper` 模块

`NumberHelper` 模块提供把数字转换为格式化字符串的方法，包括把数字转换为电话号码、货币、百分数、具有指定精度的数字、带有千位分隔符的数字和文件大小的方法。

<a class="anchor" id="number-to-currency"></a>

#### `number_to_currency` 方法

`number_to_currency` 方法用于把数字转换为货币字符串（例如 $13.65）。

```ruby
number_to_currency(1234567890.50) # => $1,234,567,890.50
```

<a class="anchor" id="number-to-human-size"></a>

#### `number_to_human_size` 方法

`number_to_human_size` 方法用于把数字转换为容易阅读的形式，常用于显示文件大小。

```ruby
number_to_human_size(1234)          # => 1.2 KB
number_to_human_size(1234567)       # => 1.2 MB
```

<a class="anchor" id="number-to-percentage"></a>

#### `number_to_percentage` 方法

`number_to_percentage` 方法用于把数字转换为百分数字符串。

```ruby
number_to_percentage(100, precision: 0)        # => 100%
```

<a class="anchor" id="number-to-phone"></a>

#### `number_to_phone` 方法

`number_to_phone` 方法用于把数字转换为电话号码（默认为美国）。

```ruby
number_to_phone(1235551234) # => 123-555-1234
```

<a class="anchor" id="number-with-delimiter"></a>

#### `number_with_delimiter` 方法

`number_with_delimiter` 方法用于把数字转换为带有千位分隔符的数字。

```ruby
number_with_delimiter(12345678) # => 12,345,678
```

<a class="anchor" id="number-with-precision"></a>

#### `number_with_precision` 方法

`number_with_precision` 方法用于把数字转换为具有指定精度的数字，默认精度为 3。

```ruby
number_with_precision(111.2345)     # => 111.235
number_with_precision(111.2345, precision: 2)  # => 111.23
```

<a class="anchor" id="sanitizehelper"></a>

### `SanitizeHelper` 模块

`SanitizeHelper` 模块提供从文本中清除不需要的 HTML 元素的方法。

<a class="anchor" id="sanitize"></a>

#### `sanitize` 方法

`sanitize` 方法会对所有标签进行 HTML 编码，并清除所有未明确允许的属性。

```ruby
sanitize @article.body
```

如果指定了 `:attributes` 或 `:tags` 选项，那么只有指定的属性或标签才不会被清除。

```ruby
sanitize @article.body, tags: %w(table tr td), attributes: %w(id class style)
```

要想修改 `sanitize` 方法的默认选项，例如把表格标签设置为允许的属性，可以按下面的方式设置：

```ruby
class Application < Rails::Application
  config.action_view.sanitized_allowed_tags = 'table', 'tr', 'td'
end
```

<a class="anchor" id="sanitize-css-style"></a>

#### `sanitize_css(style)` 方法

`sanitize_css(style)` 方法用于净化 CSS 代码。

<a class="anchor" id="strip-links-html"></a>

#### `strip_links(html)` 方法

`strip_links(html)` 方法用于清除文本中所有的链接标签，只保留链接文本。

```ruby
strip_links('<a href="http://rubyonrails.org">Ruby on Rails</a>')
# => Ruby on Rails
```

```ruby
strip_links('emails to <a href="mailto:me@email.com">me@email.com</a>.')
# => emails to me@email.com.
```

```ruby
strip_links('Blog: <a href="http://myblog.com/">Visit</a>.')
# => Blog: Visit.
```

<a class="anchor" id="strip-tags-html"></a>

#### `strip_tags(html)` 方法

`strip_tags(html)` 方法用于清除包括注释在内的所有 HTML 标签。这个方法的功能由 rails-html-sanitizer gem 提供。

```ruby
strip_tags("Strip <i>these</i> tags!")
# => Strip these tags!
```

```ruby
strip_tags("<b>Bold</b> no more!  <a href='more.html'>See more</a>")
# => Bold no more!  See more
```

注意：使用 `strip_tags(html)` 方法清除后的文本仍然可能包含 &lt;、&gt; 和 &amp; 字符，从而导致浏览器显示异常。

<a class="anchor" id="csrfhelper"></a>

### `CsrfHelper` 模块

`csrf_meta_tags` 方法用于生成 `csrf-param` 和 `csrf-token` 这两个元标签，它们分别是跨站请求伪造保护的参数和令牌。

```erb
<%= csrf_meta_tags %>
```

NOTE: 普通表单生成隐藏字段，因此不使用这些标签。关于这个问题的更多介绍，请参阅 [跨站请求伪造（CSRF）](security.html#cross-site-request-forgery-csrf)。

<a class="anchor" id="localized-views"></a>

## 本地化视图

Action View 可以根据当前的本地化设置渲染不同的模板。

假如 `ArticlesController` 控制器中有 `show` 动作。默认情况下，调用 `show` 动作会渲染 `app/views/articles/show.html.erb` 模板。如果我们设置了 `I18n.locale = :de`，那么调用 `show` 动作会渲染 `app/views/articles/show.de.html.erb` 模板。如果对应的本地化模板不存在，就会使用对应的默认模板。这意味着我们不需要为所有情况提供本地化视图，但如果本地化视图可用就会优先使用。

我们可以使用相同的技术来本地化公共目录中的错误文件。例如，通过设置 `I18n.locale = :de` 并创建 `public/500.de.html` 和 `public/404.de.html` 文件，我们就拥有了本地化的错误文件。

由于 Rails 不会限制用于设置 `I18n.locale` 的符号，我们可以利用本地化视图根据我们喜欢的任何东西来显示不同的内容。例如，假设专家用户应该看到和普通用户不同的页面，我们可以在 `app/controllers/application.rb` 配置文件中进行如下设置：

```ruby
before_action :set_expert_locale

def set_expert_locale
  I18n.locale = :expert if current_user.expert?
end
```

然后创建 `app/views/articles/show.expert.html.erb` 这样的显示给专家用户看的特殊视图。

关于 Rails 国际化的更多介绍，请参阅[Rails 国际化 API](i18n.html)。
