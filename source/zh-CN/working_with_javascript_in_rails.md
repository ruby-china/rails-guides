在 Rails 中使用 JavaScript
=========================

本文介绍 Rails 内建对 Ajax 和 JavaScript 等的支持，使用这些功能可以轻易的开发强大的 Ajax 程序。

读完本文，你将学到：

* Ajax 基本知识；
* 非侵入式 JavaScript；
* 如何使用 Rails 内建的帮助方法；
* 如何在服务器端处理 Ajax；
* Turbolinks 简介；

--------------------------------------------------------------------------------

Ajax 简介
---------

在理解 Ajax 之前，要先知道网页浏览器常规的工作原理。

在浏览器的地址栏中输入 `http://localhost:3000` 后，浏览器（客户端）会向服务器发起一个请求。然后浏览器会处理响应，获取相关的资源文件，比如 JavaScript、样式表、图片，然后显示页面内容。点击链接后发生的事情也是如此：获取页面内容，获取资源文件，把全部内容放在一起，显示最终的网页。这个过程叫做“请求-响应循环”。

JavaScript 也可以向服务器发起请求，并处理响应。而且还能更新网页中的内容。因此，JavaScript 程序员可以编写只需更新部分内容的网页，而不用从服务器获取完整的页面数据。这是一种强大的技术，我们称之为 Ajax。

Rails 默认支持 CoffeeScript，后文所有的示例都用 CoffeeScript 编写。本文介绍的技术，在普通的 JavaScript 中也可使用。

例如，下面这段 CoffeeScript 代码使用 jQuery 发起一个 Ajax 请求：

```coffeescript
$.ajax(url: "/test").done (html) ->
  $("#results").append html
```

这段代码从 `/test` 地址上获取数据，然后把结果附加到 `div#results`。

Rails 内建了很多使用这种技术开发程序的功能，基本上无需自己动手编写上述代码。后文介绍 Rails 如何为开发这种程序提供帮助，不过都构建在这种简单的技术之上。

非侵入式 JavaScript
----------------

Rails 使用一种叫做“非侵入式 JavaScript”（Unobtrusive JavaScript）的技术把 JavaScript 应用到 DOM 上。非侵入式 JavaScript 是前端开发社区推荐使用的方法，但有些教程可能会使用其他方式。

下面是编写 JavaScript 最简单的方式，你可能见过，这叫做“行间 JavaScript”：

```html
<a href="#" onclick="this.style.backgroundColor='#990000'">Paint it red</a>
```

点击链接后，链接的背景会变成红色。这种用法的问题是，如果点击链接后想执行大量代码怎么办？

```html
<a href="#" onclick="this.style.backgroundColor='#009900';this.style.color='#FFFFFF';">Paint it green</a>
```

太别扭了，不是吗？我们可以把处理点击的代码定义成一个函数，用 CoffeeScript 编写如下：

```coffeescript
paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor
```

然后在页面中这么做：

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
```

这种方法好点儿，但是如果很多链接需要同样的效果该怎么办呢？

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
<a href="#" onclick="paintIt(this, '#009900', '#FFFFFF')">Paint it green</a>
<a href="#" onclick="paintIt(this, '#000099', '#FFFFFF')">Paint it blue</a>
```

非常不符合 DRY 原则。为了解决这个问题，我们可以使用“事件”。在链接上添加一个 `data-*` 属性，然后把处理程序绑定到拥有这个属性的点击事件上：

```coffeescript
paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor

$ ->
  $("a[data-background-color]").click ->
    backgroundColor = $(this).data("background-color")
    textColor = $(this).data("text-color")
    paintIt(this, backgroundColor, textColor)
```

```html
<a href="#" data-background-color="#990000">Paint it red</a>
<a href="#" data-background-color="#009900" data-text-color="#FFFFFF">Paint it green</a>
<a href="#" data-background-color="#000099" data-text-color="#FFFFFF">Paint it blue</a>
```

我们把这种方法称为“非侵入式 JavaScript”，因为 JavaScript 代码不再和 HTML 混用。我们把两中代码完全分开，这么做易于修改功能。我们可以轻易地把这种效果应用到其他链接上，只要添加相应的 `data` 属性就行。所有 JavaScript 代码都可以放在一个文件中，进行压缩，每个页面都使用这个 JavaScript 文件，因此只在第一次请求时加载，后续请求会直接从缓存中读取。“非侵入式 JavaScript”带来的好处太多了。

Rails 团队极力推荐使用这种方式编写 CoffeeScript 和 JavaScript，而且你会发现很多代码库都沿用了这种方式。

内建的帮助方法
------------

Rails 提供了很多视图帮助方法协助你生成 HTML，如果想在元素上实现 Ajax 效果也没问题。

因为使用的是非侵入式 JavaScript，所以 Ajax 相关的帮助方法其实分成两部分，一部分是 JavaScript 代码，一部分是 Ruby 代码。

[rails.js](https://github.com/rails/jquery-ujs/blob/master/src/rails.js) 提供 JavaScript 代码，常规的 Ruby 视图帮助方法用来生成 DOM 标签。rails.js 中的 CoffeeScript 会监听这些属性，执行相应的处理程序。

### `form_for`

[`form_for`](http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_for) 方法协助编写表单，可指定 `:remote` 选项，用法如下：

```erb
<%= form_for(@post, remote: true) do |f| %>
  ...
<% end %>
```

生成的 HTML 如下：

```html
<form accept-charset="UTF-8" action="/posts" class="new_post" data-remote="true" id="new_post" method="post">
  ...
</form>
```

注意 `data-remote="true"` 属性，现在这个表单不会通过常规的提交按钮方式提交，而是通过 Ajax 提交。

或许你并不需要一个只能填写内容的表单，而是想在表单提交成功后做些事情。为此，我们要绑定到 `ajax:success` 事件上。处理表单提交失败的程序要绑定到 `ajax:error` 事件上。例如：

```coffeescript
$(document).ready ->
  $("#new_post").on("ajax:success", (e, data, status, xhr) ->
    $("#new_post").append xhr.responseText
  ).on "ajax:error", (e, xhr, status, error) ->
    $("#new_post").append "<p>ERROR</p>"
```

显然你需要的功能比这要复杂，上面的例子只是个入门。关于事件的更多内容请阅读 [jquery-ujs 的维基](https://github.com/rails/jquery-ujs/wiki/ajax)。

### `form_tag`

[`form_tag`](http://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-form_tag) 方法的功能和 `form_for` 类似，也可指定 `:remote` 选项，如下所示：

```erb
<%= form_tag('/posts', remote: true) do %>
  ...
<% end %>
```

生成的 HTML 如下：

```html
<form accept-charset="UTF-8" action="/posts" data-remote="true" method="post">
  ...
</form>
```

其他用法都和 `form_for` 一样。详细介绍参见文档。

### `link_to`

[`link_to`](http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to) 方法用来生成链接，可以指定 `:remote`，用法如下：

```erb
<%= link_to "a post", @post, remote: true %>
```

生成的 HTML 如下：

```html
<a href="/posts/1" data-remote="true">a post</a>
```

绑定的 Ajax 事件和 `form_for` 方法一样。下面举个例子。假如有一个文章列表，我们想只点击一个链接就删除所有文章，视图代码如下：

```erb
<%= link_to "Delete post", @post, remote: true, method: :delete %>
```

CoffeeScript 代码如下：

```coffeescript
$ ->
  $("a[data-remote]").on "ajax:success", (e, data, status, xhr) ->
    alert "The post was deleted."
```

### `button_to`

[`button_to`](http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-button_to) 方法用来生成按钮，可以指定 `:remote` 选项，用法如下：

```erb
<%= button_to "A post", @post, remote: true %>
```

生成的 HTML 如下：

```html
<form action="/posts/1" class="button_to" data-remote="true" method="post">
  <div><input type="submit" value="A post"></div>
</form>
```

因为生成的就是一个表单，所以 `form_for` 的全部信息都适用于这里。

服务器端处理
-----------

Ajax 不仅需要编写客户端代码，服务器端也要做处理。Ajax 请求一般不返回 HTML，而是 JSON。下面详细介绍处理过程。

### 一个简单的例子

假设在网页中要显示一系列用户，还有一个新建用户的表单，控制器的 `index` 动作如下所示：

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    @user = User.new
  end
  # ...
```

`index` 动作的视图（`app/views/users/index.html.erb`）如下：

```erb
<b>Users</b>

<ul id="users">
<%= render @users %>
</ul>

<br>

<%= form_for(@user, remote: true) do |f| %>
  <%= f.label :name %><br>
  <%= f.text_field :name %>
  <%= f.submit %>
<% end %>
```

`app/views/users/_user.html.erb` 局部视图如下：

```erb
<li><%= user.name %></li>
```

`index` 动作的上部显示用户，下部显示新建用户的表单。

下部的表单会调用 `UsersController` 的 `create` 动作。因为表单的 `remote` 属性为 `true`，所以发往 `UsersController` 的是 Ajax 请求，使用 JavaScript 处理。要想处理这个请求，控制器的  `create` 动作应该这么写：

```ruby
  # app/controllers/users_controller.rb
  # ......
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.js   {}
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
```

注意，在 `respond_to` 的代码块中使用了 `format.js`，这样控制器才能处理 Ajax 请求。然后还要新建 `app/views/users/create.js.erb` 视图文件，编写发送响应以及在客户端执行的 JavaScript 代码。

```erb
$("<%= escape_javascript(render @user) %>").appendTo("#users");
```

Turbolinks
----------

Rails 4 提供了 [Turbolinks gem](https://github.com/rails/turbolinks)，这个 gem 可用于大多数程序，加速页面渲染。

### Turbolinks 的工作原理

Turbolinks 为页面中所有的 `<a>` 元素添加了一个点击事件处理程序。如果浏览器支持 [PushState](http://dwz.cn/pushstate)，Turbolinks 会发起 Ajax 请求，处理响应，然后使用响应主体替换原始页面的整个 `<body>` 元素。最后，使用 PushState 技术更改页面的 URL，让新页面可刷新，并且有个精美的 URL。

要想使用 Turbolinks，只需将其加入 `Gemfile`，然后在 `app/assets/javascripts/application.js` 中加入 `//= require turbolinks` 即可。

如果某个链接不想使用 Turbolinks，可以在链接中添加 `data-no-turbolink` 属性：

```html
<a href="..." data-no-turbolink>No turbolinks here</a>.
```

### 页面内容变更事件

编写 CoffeeScript 代码时，经常需要在页面加载时做一些事情。在 jQuery 中，我们可以这么写：

```coffeescript
$(document).ready ->
  alert "page has loaded!"
```

不过，因为 Turbolinks 改变了常规的页面加载流程，所以不会触发这个事件。如果编写了类似上面的代码，要将其修改为：

```coffeescript
$(document).on "page:change", ->
  alert "page has loaded!"
```

其他可用事件等详细信息，请参阅 [Turbolinks 的说明文件](https://github.com/rails/turbolinks/blob/master/README.md)。

其他资源
-------

下面列出一些链接，可以帮助你进一步学习：

* [jquery-ujs 的维基](https://github.com/rails/jquery-ujs/wiki)
* [其他介绍 jquery-ujs 的文章](https://github.com/rails/jquery-ujs/wiki/External-articles)
* [Rails 3 远程链接和表单权威指南](http://www.alfajango.com/blog/rails-3-remote-links-and-forms/)
* [Railscasts: Unobtrusive JavaScript](http://railscasts.com/episodes/205-unobtrusive-javascript)
* [Railscasts: Turbolinks](http://railscasts.com/episodes/390-turbolinks)
