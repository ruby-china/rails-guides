# 在 Rails 中使用 JavaScript

本文介绍 Rails 内建对 Ajax 和 JavaScript 等的支持，使用这些功能可以轻易地开发强大的 Ajax 动态应用。

本完本文后，您将学到：

*   Ajax 基础知识；
*   非侵入式 JavaScript；
*   如何使用 Rails 内建的辅助方法；
*   如何在服务器端处理 Ajax；
*   Turbolinks gem。

-----------------------------------------------------------------------------

<a class="anchor" id="an-introduction-to-ajax"></a>

## Ajax 简介

在理解 Ajax 之前，要先知道 Web 浏览器常规的工作原理。

在浏览器的地址栏中输入 `<http://localhost:3000>` 后，浏览器（客户端）会向服务器发起一个请求。然后浏览器处理响应，获取相关的静态资源文件，比如 JavaScript、样式表和图像，然后显示页面内容。点击链接后发生的事情也是如此：获取页面，获取静态资源，把全部内容放在一起，显示最终的网页。这个过程叫做“请求响应循环”。

JavaScript 也可以向服务器发起请求，并解析响应。而且还能更新网页中的内容。因此，JavaScript 程序员可以编写只更新部分内容的网页，而不用从服务器获取完整的页面数据。这是一种强大的技术，我们称之为 Ajax。

Rails 默认支持 CoffeeScript，后文所有的示例都用 CoffeeScript 编写。本文介绍的技术，在普通的 JavaScript 中也可以使用。

例如，下面这段 CoffeeScript 代码使用 jQuery 库发起一个 Ajax 请求：

```coffeescript
$.ajax(url: "/test").done (html) ->
  $("#results").append html
```

这段代码从 `/test` 地址上获取数据，然后把结果追加到 `div#results` 元素中。

Rails 内建了很多使用这种技术开发应用的功能，基本上无需自己动手编写上述代码。后文介绍 Rails 如何为开发这种应用提供协助，不过都构建在这种简单的技术之上。

<a class="anchor" id="unobtrusive-javascript"></a>

## 非侵入式 JavaScript

Rails 使用一种叫做“非侵入式 JavaScript”（Unobtrusive JavaScript）的技术把 JavaScript 依附到 DOM 上。非侵入式 JavaScript 是前端开发社区推荐的做法，但有些教程可能会使用其他方式。

下面是编写 JavaScript 最简单的方式，你可能见过，这叫做“行间 JavaScript”：

```html
<a href="#" onclick="this.style.backgroundColor='#990000'">Paint it red</a>
```

点击链接后，链接的背景会变成红色。这种用法的问题是，如果点击链接后想执行大量 JavaScript 代码怎么办？

```html
<a href="#" onclick="this.style.backgroundColor='#009900';this.style.color='#FFFFFF';">Paint it green</a>
```

太别扭了，不是吗？我们可以把处理点击的代码定义成一个函数，用 CoffeeScript 编写如下：

```coffeescript
@paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor
```

然后在页面中这么写：

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
```

这种方法好点儿，但是如果很多链接需要同样的效果该怎么办呢？

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
<a href="#" onclick="paintIt(this, '#009900', '#FFFFFF')">Paint it green</a>
<a href="#" onclick="paintIt(this, '#000099', '#FFFFFF')">Paint it blue</a>
```

这样非常不符合 DRY 原则。为了解决这个问题，我们可以使用“事件”。在链接上添加一个 `data-*` 属性，然后把处理程序绑定到拥有这个属性的点击事件上：

```coffee
@paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor

$ ->
  $("a[data-background-color]").click (e) ->
    e.preventDefault()

    backgroundColor = $(this).data("background-color")
    textColor = $(this).data("text-color")
    paintIt(this, backgroundColor, textColor)
```

```html
<a href="#" data-background-color="#990000">Paint it red</a>
<a href="#" data-background-color="#009900" data-text-color="#FFFFFF">Paint it green</a>
<a href="#" data-background-color="#000099" data-text-color="#FFFFFF">Paint it blue</a>
```

我们把这种方法称为“非侵入式 JavaScript”，因为 JavaScript 代码不再和 HTML 混合在一起。这样做正确分离了关注点，易于修改功能。我们可以轻易地把这种效果应用到其他链接上，只要添加相应的 `data` 属性即可。我们可以简化并拼接全部 JavaScript，然后在各个页面加载一个 JavaScript 文件，这样只在第一次请求时需要加载，后续请求都会直接从缓存中读取。“非侵入式 JavaScript”带来的好处太多了。

Rails 团队极力推荐使用这种方式编写 CoffeeScript（以及 JavaScript），而且你会发现很多代码库都采用了这种方式。

<a class="anchor" id="built-in-helpers"></a>

## 内置的辅助方法

<a class="anchor" id="remote-elements"></a>

### 远程元素

Rails 提供了很多视图辅助方法协助你生成 HTML，如果想在元素上实现 Ajax 效果也没问题。

因为使用的是非侵入式 JavaScript，所以 Ajax 相关的辅助方法其实分成两部分，一部分是 JavaScript 代码，一部分是 Ruby 代码。

如果没有禁用 Asset Pipeline，[rails-ujs](https://github.com/rails/rails/tree/master/actionview/app/assets/javascripts) 负责提供 JavaScript 代码，常规的 Ruby 视图辅助方法负责生成 DOM 标签。

应用在处理远程元素的过程中触发的不同事件参见下文。

<a class="anchor" id="form-with"></a>

#### `form_with`

[`form_with` 方法](http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with)协助编写表单，默认假定表单使用 Ajax。如果不想使用 Ajax，把 `:local` 选项传给 `form_with`。

```erb
<%= form_with(model: @article) do |f| %>
  ...
<% end %>
```

生成的 HTML 如下：

```html
<form action="/articles" method="post" data-remote="true">
  ...
</form>
```

注意 `data-remote="true"` 属性，现在这个表单不会通过常规的方式提交，而是通过 Ajax 提交。

或许你并不需要一个只能填写内容的表单，而是想在表单提交成功后做些事情。为此，我们要绑定 `ajax:success` 事件。处理表单提交失败的程序要绑定到 `ajax:error` 事件上。例如：

```coffee
$(document).ready ->
  $("#new_article").on("ajax:success", (e, data, status, xhr) ->
    $("#new_article").append xhr.responseText
  ).on "ajax:error", (e, xhr, status, error) ->
    $("#new_article").append "<p>ERROR</p>"
```

显然你需要的功能比这要复杂，上面的例子只是个入门。

<a class="anchor" id="link-to"></a>

#### `link_to`

[`link_to` 方法](http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to)用于生成链接，可以指定 `:remote` 选项，用法如下：

```erb
<%= link_to "an article", @article, remote: true %>
```

生成的 HTML 如下：

```html
<a href="/articles/1" data-remote="true">an article</a>
```

绑定的 Ajax 事件和 `form_with` 方法一样。下面举个例子。假如有一个文章列表，我们想只点击一个链接就删除所有文章。视图代码如下：

```erb
<%= link_to "Delete article", @article, remote: true, method: :delete %>
```

CoffeeScript 代码如下：

```coffee
$ ->
  $("a[data-remote]").on "ajax:success", (e, data, status, xhr) ->
    alert "The article was deleted."
```

<a class="anchor" id="button-to"></a>

#### `button_to`

[`button_to` 方法](http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-button_to)用于生成按钮，可以指定 `:remote` 选项，用法如下：

```erb
<%= button_to "An article", @article, remote: true %>
```

生成的 HTML 如下：

```html
<form action="/articles/1" class="button_to" data-remote="true" method="post">
  <input type="submit" value="An article" />
</form>
```

因为生成的就是一个表单，所以 `form_with` 的全部信息都可使用。

<a class="anchor" id="customize-remote-elements"></a>

### 定制远程元素

不编写任何 JavaScript 代码，仅通过 `data-remote` 属性就能定制元素的行为。此外，还可以指定额外的 `data-` 属性。

<a class="anchor" id="data-method"></a>

#### `data-method`

链接始终发送 HTTP GET 请求。然而，如果你的应用使用 [REST 架构](http://en.wikipedia.org/wiki/Representational_State_Transfer)，有些链接其实要对服务器中的数据做些操作，因此必须发送 GET 之外的请求。这个属性用于标记这类链接，明确指定使用“post”、“put”或“delete”方法。

Rails 的处理方式是，点击链接后，在文档中构建一个隐藏的表单，把表单的 `action` 属性的值设为链接的 `href` 属性值，把表单的 `method` 属性的值设为链接的 `data-method` 属性值，然后提交表单。

NOTE: 由于通过表单提交 GET 和 POST 之外的请求未得到浏览器的广泛支持，所以其他 HTTP 方法其实是通过 POST 发送的，意欲发送的请求在 `_method` 参数中指明。Rails 能自动检测并处理这种情况。

<a class="anchor" id="data-url-and-data-params"></a>

#### `data-url` 和 `data-params`

页面中有些元素并不指向任何 URL，但是却想让它们触发 Ajax 调用。为元素设定 `data-url` 和 `data-remote` 属性将向指定的 URL 发送 Ajax 请求。还可以通过 `data-params` 属性指定额外的参数。

例如，可以利用这一点在复选框上触发操作：

```html
<input type="checkbox" data-remote="true"
    data-url="/update" data-params="id=10" data-method="put">
```

<a class="anchor" id="data-type"></a>

#### `data-type`

此外，在含有 `data-remote` 属性的元素上还可以通过 `data-type` 属性明确定义 Ajax 的 `dataType`。

<a class="anchor" id="confirmations"></a>

### 确认

可以在链接和表单上添加 `data-confirm` 属性，让用户确认操作。呈献给用户的是 JavaScript `confirm()` 对话框，内容为 `data-confirm` 属性的值。如果用户选择“取消”，操作不会执行。

在链接上添加这个属性后，对话框在点击链接后弹出；在表单上添加这个属性后，对话框在提交时弹出。例如：

```erb
<%= link_to "Dangerous zone", dangerous_zone_path,
  data: { confirm: 'Are you sure?' } %>
```

生成的 HTML 为：

```html
<a href="..." data-confirm="Are you sure?">Dangerous zone</a>
```

在表单的提交按钮上也可以设定这个属性。这样可以根据所按的按钮定制提醒消息。此时，不能在表单元素上设定 `data-confirm` 属性。

默认使用的是 JavaScript 确认对话框，不过你可以定制这一行为，监听 `confirm` 时间，在对话框弹出之前触发。若想禁止弹出默认的对话框，让事件句柄返回 `false`。

<a class="anchor" id="automatic-disabling"></a>

### 自动禁用

还可以使用 `disable-with` 属性在提交表单的过程中禁用输入元素。这样能避免用户不小心点击两次，发送两个重复的 HTTP 请求，导致后端无法正确处理。这个属性的值是按钮处于禁用状态时显示的新值。

带有 `data-method` 属性的链接也可设定这个属性。

例如：

```erb
<%= form_with(model: @article.new) do |f| %>
  <%= f.submit data: { "disable-with": "Saving..." } %>
<%= end %>
```

生成的表单包含：

```html
<input data-disable-with="Saving..." type="submit">
```

<a class="anchor" id="dealing-with-ajax-events"></a>

## 处理 Ajax 事件

带 `data-remote` 属性的元素具有下述事件。

NOTE: 这些事件绑定的句柄的第一个参数始终是事件对象。下面列出的是事件对象之后的其他参数。例如，如果列出的参数是 `xhr, settings`，那么定义句柄时要写为 `function(event, xhr, settings)`。

| 事件名 | 额外参数 | 触发时机  |
|---|---|---|
| `ajax:before` |  | 在整个 Ajax 调用开始之前，如果被停止了，就不再调用。  |
| `ajax:beforeSend` | `xhr, options` | 在发送请求之前，如果被停止了，就不再发送。  |
| `ajax:send` | `xhr` | 发送请求时。  |
| `ajax:success` | `xhr, status, err` | Ajax 调用结束，返回表示成功的响应时。  |
| `ajax:error` | `xhr, status, err` | Ajax 调用结束，返回表示失败的响应时。  |
| `ajax:complete` | `xhr, status` | Ajax 调用结束时，不管成功还是失败。  |
| `ajax:aborted:file` | `elements` | 有非空文件输入时，如果被停止了，就不再调用。  |

<a class="anchor" id="stoppable-events"></a>

### 可停止的事件

如果在 `ajax:before` 或 `ajax:beforeSend` 的句柄中返回 `false`，不会发送 Ajax 请求。`ajax:before` 事件可用于在序列化之前处理表单数据。`ajax:beforeSend` 事件也可用于添加额外的请求首部。

如果停止 `ajax:aborted:file` 事件，允许浏览器通过常规方式（即不是 Ajax）提交表单这个默认行为将失效，表单根本无法提交。利用这一点可以自行实现通过 Ajax 上传文件的变通方式。

<a class="anchor" id="server-side-concerns"></a>

## 服务器端处理

Ajax 不仅涉及客户端，服务器端也要做处理。Ajax 请求一般不返回 HTML，而是 JSON。下面详细说明处理过程。

<a class="anchor" id="a-simple-example"></a>

### 一个简单的例子

假设在网页中要显示一系列用户，还有一个新建用户的表单。控制器的 `index` 动作如下所示：

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    @user = User.new
  end
  # ...
```

`index` 视图（`app/views/users/index.html.erb`）如下：

```erb
<b>Users</b>

<ul id="users">
<%= render @users %>
</ul>

<br>

<%= form_with(model: @user) do |f| %>
  <%= f.label :name %><br>
  <%= f.text_field :name %>
  <%= f.submit %>
<% end %>
```

`app/views/users/_user.html.erb` 局部视图的内容如下：

```erb
<li><%= user.name %></li>
```

`index` 页面的上部显示用户列表，下部显示新建用户的表单。

下部的表单会调用 `UsersController` 的 `create` 动作。因为表单的 `remote` 选项为 `true`，所以发给 `UsersController` 的是 Ajax 请求，使用 JavaScript 处理。要想处理这个请求，控制器的  `create` 动作应该这么写：

```ruby
# app/controllers/users_controller.rb
# ......
def create
  @user = User.new(params[:user])

  respond_to do |format|
    if @user.save
      format.html { redirect_to @user, notice: 'User was successfully created.' }
      format.js
      format.json { render json: @user, status: :created, location: @user }
    else
      format.html { render action: "new" }
      format.json { render json: @user.errors, status: :unprocessable_entity }
    end
  end
end
```

注意，在 `respond_to` 块中使用了 `format.js`，这样控制器才能响应 Ajax 请求。然后还要新建 `app/views/users/create.js.erb` 视图文件，编写发送响应以及在客户端执行的 JavaScript 代码。

```erb
$("<%= escape_javascript(render @user) %>").appendTo("#users");
```

<a class="anchor" id="turbolinks"></a>

## Turbolinks

Rails 提供了 [Turbolinks 库](https://github.com/turbolinks/turbolinks)，它使用 Ajax 渲染页面，在多数应用中可以提升页面加载速度。

<a class="anchor" id="how-turbolinks-works"></a>

### Turbolinks 的工作原理

Turbolinks 为页面中所有的 `<a>` 元素添加一个点击事件处理程序。如果浏览器支持 [PushState](https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Manipulating_the_browser_history#The_pushState%28%29_method)，Turbolinks 会发起 Ajax 请求，解析响应，然后使用响应主体替换原始页面的整个 `<body>` 元素。最后，使用 PushState 技术更改页面的 URL，让新页面可刷新，并且有个精美的 URL。

要想使用 Turbolinks，只需将其加入 `Gemfile`，然后在 `app/assets/javascripts/application.js` 中加入 `//= require turbolinks`。

如果某个链接不想使用 Turbolinks，可以在链接中添加 `data-turbolinks="false"` 属性：

```html
<a href="..." data-turbolinks="false">No turbolinks here</a>.
```

<a class="anchor" id="page-change-events"></a>

### 页面内容变更事件

编写 CoffeeScript 代码时，经常需要在页面加载时做一些事情。在 jQuery 中，我们可以这么写：

```coffee
$(document).ready ->
  alert "page has loaded!"
```

不过，Turbolinks 改变了常规的页面加载流程，不会触发这个事件。如果编写了类似上面的代码，要将其修改为：

```coffee
$(document).on "turbolinks:load", ->
  alert "page has loaded!"
```

其他可用事件的详细信息，参阅 [Turbolinks 的自述文件](https://github.com/turbolinks/turbolinks/blob/master/README.md)。

<a class="anchor" id="other-resources"></a>

## 其他资源

下面列出一些链接，可以帮助你进一步学习：

*   [jquery-ujs 的维基](https://github.com/rails/jquery-ujs/wiki)
*   [其他介绍 jquery-ujs 的文章](https://github.com/rails/jquery-ujs/wiki/External-articles)
*   [Rails 3 Remote Links and Forms: A Definitive Guide](http://www.alfajango.com/blog/rails-3-remote-links-and-forms/)
*   [Railscasts: Unobtrusive JavaScript](http://railscasts.com/episodes/205-unobtrusive-javascript)
*   [Railscasts: Turbolinks](http://railscasts.com/episodes/390-turbolinks)
