表单帮助方法
===========

表单是网页程序的基本组成部分，用于接收用户的输入。然而，由于表单中控件的名称和各种属性，使用标记语言难以编写和维护。Rails 提供了很多视图帮助方法简化表单的创建过程。因为各帮助方法的用途不一样，所以开发者在使用之前必须要知道相似帮助方法的差异。

读完本文，你将学到：

* 如何创建搜索表单等不需要操作模型的普通表单；
* 如何使用针对模型的表单创建和编辑数据库中的记录；
* 如何使用各种类型的数据生成选择列表；
* 如何使用 Rails 提供用于处理日期和时间的帮助方法；
* 上传文件的表单有什么特殊之处；
* 创建操作外部资源的案例；
* 如何编写复杂的表单；

--------------------------------------------------------------------------------

NOTE: 本文的目的不是全面解说每个表单方法和其参数，完整的说明请阅读 [Rails API 文档](http://api.rubyonrails.org/)。

编写简单的表单
------------

最基本的表单帮助方法是 `form_tag`。

```erb
<%= form_tag do %>
  Form contents
<% end %>
```

像上面这样不传入参数时，`form_tag` 会创建一个 `<form>` 标签，提交表单后，向当前页面发起 POST 请求。假设当前页面是 `/home/index`，生成的 HTML 如下（为了提升可读性，添加了一些换行）：

```html
<form accept-charset="UTF-8" action="/home/index" method="post">
  <div style="margin:0;padding:0">
    <input name="utf8" type="hidden" value="&#x2713;" />
    <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  </div>
  Form contents
</form>
```

你会发现 HTML 中多了一个 `div` 元素，其中有两个隐藏的 `input` 元素。这个 `div` 元素很重要，没有就无法提交表单。第一个 `input` 元素的 `name` 属性值为 `utf8`，其作用是强制浏览器使用指定的编码处理表单，不管是 GET 还是 POST。第二个 `input` 元素的 `name` 属性值为 `authenticity_token`，这是 Rails 的一项安全措施，称为“跨站请求伪造保护”。`form_tag` 帮助方法会为每个非 GET 表单生成这个元素（表明启用了这项安全保护措施）。详情参阅“[Rails 安全指南](security.html#cross-site-request-forgery-csrf)”。

NOTE: 为了行文简洁，后续代码没有包含这个 `div` 元素。

### 普通的搜索表单

在网上见到最多的表单是搜索表单，搜索表单包含以下元素：

* `form` 元素，`action` 属性值为 `GET`；
* 输入框的 `label` 元素；
* 文本输入框 ；
* 提交按钮；

创建这样一个表单要分别使用帮助方法 `form_tag`、`label_tag`、`text_field_tag` 和 `submit_tag`，如下所示：

```erb
<%= form_tag("/search", method: "get") do %>
  <%= label_tag(:q, "Search for:") %>
  <%= text_field_tag(:q) %>
  <%= submit_tag("Search") %>
<% end %>
```

生成的 HTML 如下：

```html
<form accept-charset="UTF-8" action="/search" method="get">
  <div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div>
  <label for="q">Search for:</label>
  <input id="q" name="q" type="text" />
  <input name="commit" type="submit" value="Search" />
</form>
```

TIP: 表单中的每个 `input` 元素都有 ID 属性，其值和 `name` 属性的值一样（上例中是 `q`）。ID 可用于 CSS 样式或使用 JavaScript 处理表单控件。

除了 `text_field_tag` 和 `submit_tag` 之外，每个 HTML 表单控件都有对应的帮助方法。

NOTE: 搜索表单的请求类型一定要用 GET，这样用户才能把某个搜索结果页面加入收藏夹，以便后续访问。一般来说，Rails 建议使用合适的请求方法处理表单。

### 调用 `form_tag` 时使用多个 Hash 参数

`form_tag` 方法可接受两个参数：表单提交地址和一个 Hash 选项。Hash 选项指定提交表单使用的请求方法和 HTML 选项，例如 `form` 元素的 `class` 属性。

和 `link_to` 方法一样，提交地址不一定非得使用字符串，也可使用一个由 URL 参数组成的 Hash，这个 Hash 经 Rails 路由转换成 URL 地址。这种情况下，`form_tag` 方法的两个参数都是 Hash，同时指定两个参数时很容易产生问题。假设写成下面这样：

```ruby
form_tag(controller: "people", action: "search", method: "get", class: "nifty_form")
# => '<form accept-charset="UTF-8" action="/people/search?method=get&class=nifty_form" method="post">'
```

在这段代码中，`method` 和 `class` 会作为生成 URL 的请求参数，虽然你想传入两个 Hash，但实际上只传入了一个。所以，你要把第一个 Hash（或两个 Hash）放在一对花括号中，告诉 Ruby 哪个是哪个，写成这样：

```ruby
form_tag({controller: "people", action: "search"}, method: "get", class: "nifty_form")
# => '<form accept-charset="UTF-8" action="/people/search" method="get" class="nifty_form">'
```

### 生成表单中控件的帮助方法

Rails 提供了很多用来生成表单中控件的帮助方法，例如复选框，文本输入框和单选框。这些基本的帮助方法都以 `_tag` 结尾，例如 `text_field_tag` 和 `check_box_tag`，生成单个 `input` 元素。这些帮助方法的第一个参数都是 `input` 元素的 `name` 属性值。提交表单后，`name` 属性的值会随表单中的数据一起传入控制器，在控制器中可通过 `params` 这个 Hash 获取各输入框中的值。例如，如果表单中包含 `<%= text_field_tag(:query) %>`，就可以在控制器中使用 `params[:query]` 获取这个输入框中的值。

Rails 使用特定的规则生成 `input` 的 `name` 属性值，便于提交非标量值，例如数组和 Hash，这些值也可通过 `params` 获取。

各帮助方法的详细用法请查阅 [API 文档](http://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html)。

#### 复选框

复选框是一种表单控件，给用户一些选项，可用于启用或禁用某项功能。

```erb
<%= check_box_tag(:pet_dog) %>
<%= label_tag(:pet_dog, "I own a dog") %>
<%= check_box_tag(:pet_cat) %>
<%= label_tag(:pet_cat, "I own a cat") %>
```

生成的 HTML 如下：

```html
<input id="pet_dog" name="pet_dog" type="checkbox" value="1" />
<label for="pet_dog">I own a dog</label>
<input id="pet_cat" name="pet_cat" type="checkbox" value="1" />
<label for="pet_cat">I own a cat</label>
```

`check_box_tag` 方法的第一个参数是 `name` 属性的值。第二个参数是 `value` 属性的值。选中复选框后，`value` 属性的值会包含在提交的表单数据中，因此可以通过 `params` 获取。

#### 单选框

单选框有点类似复选框，但是各单选框之间是互斥的，只能选择一组中的一个：

```erb
<%= radio_button_tag(:age, "child") %>
<%= label_tag(:age_child, "I am younger than 21") %>
<%= radio_button_tag(:age, "adult") %>
<%= label_tag(:age_adult, "I'm over 21") %>
```

生成的 HTML 如下：

```html
<input id="age_child" name="age" type="radio" value="child" />
<label for="age_child">I am younger than 21</label>
<input id="age_adult" name="age" type="radio" value="adult" />
<label for="age_adult">I'm over 21</label>
```

和 `check_box_tag` 方法一样，`radio_button_tag` 方法的第二个参数也是 `value` 属性的值。因为两个单选框的 `name` 属性值一样（都是 `age`），所以用户只能选择其中一个单选框，`params[:age]` 的值不是 `"child"` 就是 `"adult"`。

NOTE: 复选框和单选框一定要指定 `label` 标签。`label` 标签可以为指定的选项框附加文字说明，还能增加选项框的点选范围，让用户更容易选中。

### 其他帮助方法

其他值得说明的表单控件包括：多行文本输入框，密码输入框，隐藏输入框，搜索关键字输入框，电话号码输入框，日期输入框，时间输入框，颜色输入框，日期时间输入框，本地日期时间输入框，月份输入框，星期输入框，URL 地址输入框，Email 地址输入框，数字输入框和范围输入框：

```erb
<%= text_area_tag(:message, "Hi, nice site", size: "24x6") %>
<%= password_field_tag(:password) %>
<%= hidden_field_tag(:parent_id, "5") %>
<%= search_field(:user, :name) %>
<%= telephone_field(:user, :phone) %>
<%= date_field(:user, :born_on) %>
<%= datetime_field(:user, :meeting_time) %>
<%= datetime_local_field(:user, :graduation_day) %>
<%= month_field(:user, :birthday_month) %>
<%= week_field(:user, :birthday_week) %>
<%= url_field(:user, :homepage) %>
<%= email_field(:user, :address) %>
<%= color_field(:user, :favorite_color) %>
<%= time_field(:task, :started_at) %>
<%= number_field(:product, :price, in: 1.0..20.0, step: 0.5) %>
<%= range_field(:product, :discount, in: 1..100) %>
```

生成的 HTML 如下：

```html
<textarea id="message" name="message" cols="24" rows="6">Hi, nice site</textarea>
<input id="password" name="password" type="password" />
<input id="parent_id" name="parent_id" type="hidden" value="5" />
<input id="user_name" name="user[name]" type="search" />
<input id="user_phone" name="user[phone]" type="tel" />
<input id="user_born_on" name="user[born_on]" type="date" />
<input id="user_meeting_time" name="user[meeting_time]" type="datetime" />
<input id="user_graduation_day" name="user[graduation_day]" type="datetime-local" />
<input id="user_birthday_month" name="user[birthday_month]" type="month" />
<input id="user_birthday_week" name="user[birthday_week]" type="week" />
<input id="user_homepage" name="user[homepage]" type="url" />
<input id="user_address" name="user[address]" type="email" />
<input id="user_favorite_color" name="user[favorite_color]" type="color" value="#000000" />
<input id="task_started_at" name="task[started_at]" type="time" />
<input id="product_price" max="20.0" min="1.0" name="product[price]" step="0.5" type="number" />
<input id="product_discount" max="100" min="1" name="product[discount]" type="range" />
```

用户看不到隐藏输入框，但却和其他文本类输入框一样，能保存数据。隐藏输入框中的值可以通过 JavaScript 修改。

NOTE: 搜索关键字输入框，电话号码输入框，日期输入框，时间输入框，颜色输入框，日期时间输入框，本地日期时间输入框，月份输入框，星期输入框，URL 地址输入框，Email 地址输入框，数字输入框和范围输入框是 HTML5 提供的控件。如果想在旧版本的浏览器中保持体验一致，需要使用 HTML5 polyfill（使用 CSS 或 JavaScript 编写）。polyfill 虽[无不足之处](https://github.com/Modernizr/Modernizr/wiki/HTML5-Cross-Browser-Polyfills)，但现今比较流行的工具是 [Modernizr](http://www.modernizr.com/) 和 [yepnope](http://yepnopejs.com/)，根据检测到的 HTML5 特性添加相应的功能。

TIP: 如果使用密码输入框，或许还不想把其中的值写入日志。具体做法参见“[Rails 安全指南](security.html#logging)”。

处理模型对象
-----------

### 模型对象帮助方法

表单的一个特别常见的用途是编辑或创建模型对象。这时可以使用 `*_tag` 帮助方法，但是太麻烦了，每个元素都要设置正确的参数名称和默认值。Rails 提供了很多帮助方法可以简化这一过程，这些帮助方法没有 `_tag` 后缀，例如 `text_field` 和 `text_area`。

这些帮助方法的第一个参数是实例变量的名字，第二个参数是在对象上调用的方法名（一般都是模型的属性）。Rails 会把在对象上调用方法得到的值设为控件的 `value` 属性值，并且设置相应的 `name` 属性值。如果在控制器中定义了 `@person` 实例变量，其名字为“Henry”，在表单中有以下代码：

```erb
<%= text_field(:person, :name) %>
```

生成的结果如下：

```erb
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

提交表单后，用户输入的值存储在 `params[:person][:name]` 中。`params[:person]` 这个 Hash 可以传递给 `Person.new` 方法；如果 `@person` 是 `Person` 的实例，还可传递给 `@person.update`。一般来说，这些帮助方法的第二个参数是对象属性的名字，但 Rails 并不对此做强制要求，只要对象能响应 `name` 和 `name=` 方法即可。

WARNING: 传入的参数必须是实例变量的名字，例如 `:person` 或 `"person"`，而不是模型对象的实例本身。

Rails 还提供了用于显示模型对象数据验证错误的帮助方法，详情参阅“[Active Record 数据验证](active_record_validations.html#displaying-validation-errors-in-views)”一文。

### 把表单绑定到对象上

虽然上述用法很方便，但却不是最好的使用方式。如果 `Person` 有很多要编辑的属性，我们就得不断重复编写要编辑对象的名字。我们想要的是能把表单绑定到对象上的方法，`form_for` 帮助方法就是为此而生。

假设有个用来处理文章的控制器 `app/controllers/articles_controller.rb`：

```ruby
def new
  @article = Article.new
end
```

在 `new` 动作对应的视图 `app/views/articles/new.html.erb` 中可以像下面这样使用 `form_for` 方法：

```erb
<%= form_for @article, url: {action: "create"}, html: {class: "nifty_form"} do |f| %>
  <%= f.text_field :title %>
  <%= f.text_area :body, size: "60x12" %>
  <%= f.submit "Create" %>
<% end %>
```

有几点要注意：

* `@article` 是要编辑的对象；
* `form_for` 方法的参数中只有一个 Hash。路由选项传入嵌套 Hash `:url` 中，HTML 选项传入嵌套 Hash `:html` 中。还可指定 `:namespace` 选项为 `form` 元素生成一个唯一的 ID 属性值。`:namespace` 选项的值会作为自动生成的 ID 的前缀。
* `form_for` 方法会拽入一个**表单构造器**对象（`f` 变量）；
* 生成表单控件的帮助方法在表单构造器对象 `f` 上调用；

上述代码生成的 HTML 如下：

```html
<form accept-charset="UTF-8" action="/articles/create" method="post" class="nifty_form">
  <input id="article_title" name="article[title]" type="text" />
  <textarea id="article_body" name="article[body]" cols="60" rows="12"></textarea>
  <input name="commit" type="submit" value="Create" />
</form>
```

`form_for` 方法的第一个参数指明通过 `params` 的哪个键获取表单中的数据。在上面的例子中，第一个参数名为 `article`，因此所有控件的 `name` 属性都是 `article[attribute_name]` 这种形式。所以，在 `create` 动作中，`params[:article]` 这个 Hash 有两个键：`:title` 和 `:body`。`name` 属性的重要性参阅“[理解参数命名约定](#understanding-parameter-naming-conventions)”一节。

在表单构造器对象上调用帮助方法和在模型对象上调用的效果一样，唯有一点区别，无法指定编辑哪个模型对象，因为这由表单构造器负责。

使用 `fields_for` 帮助方法也可创建类似的绑定，但不会生成 `<form>` 标签。在同一表单中编辑多个模型对象时经常使用 `fields_for` 方法。例如，有个 `Person` 模型，和 `ContactDetail` 模型关联，编写如下的表单可以同时创建两个模型的对象：

```erb
<%= form_for @person, url: {action: "create"} do |person_form| %>
  <%= person_form.text_field :name %>
  <%= fields_for @person.contact_detail do |contact_details_form| %>
    <%= contact_details_form.text_field :phone_number %>
  <% end %>
<% end %>
```

生成的 HTML 如下：

```html
<form accept-charset="UTF-8" action="/people/create" class="new_person" id="new_person" method="post">
  <input id="person_name" name="person[name]" type="text" />
  <input id="contact_detail_phone_number" name="contact_detail[phone_number]" type="text" />
</form>
```

`fields_for` 方法拽入的对象和 `form_for` 方法一样，都是表单构造器（其实在代码内部 `form_for` 会调用 `fields_for` 方法）。

### 记录辨别技术

用户可以直接处理程序中的 `Article` 模型，根据开发 Rails 的最佳实践，应该将其视为一个资源：

```ruby
resources :articles
```

TIP: 声明资源有很多附属作用。资源的创建与使用请阅读“[Rails 路由全解](routing.html#resource-routing-the-rails-default)”一文。

处理 REST 资源时，使用“记录辨别”技术可以简化 `form_for` 方法的调用。简单来说，你可以只把模型实例传给 `form_for`，让 Rails 查找模型名等其他信息：

```ruby
## Creating a new article
# long-style:
form_for(@article, url: articles_path)
# same thing, short-style (record identification gets used):
form_for(@article)

## Editing an existing article
# long-style:
form_for(@article, url: article_path(@article), html: {method: "patch"})
# short-style:
form_for(@article)
```

注意，不管记录是否存在，使用简短形式的 `form_for` 调用都很方便。记录辨别技术很智能，会调用 `record.new_record?` 方法检查是否为新记录；而且还能自动选择正确的提交地址，根据对象所属的类生成 `name` 属性的值。

Rails 还会自动设置 `class` 和 `id` 属性。在新建文章的表单中，`id` 和 `class` 属性的值都是 `new_article`。如果编辑 ID 为 23 的文章，表单的 `class` 为 `edit_article`，`id` 为 `edit_article_23`。为了行文简洁，后文会省略这些属性。

WARNING: 如果在模型中使用单表继承（single-table inheritance，简称 STI），且只有父类声明为资源，子类就不能依赖记录辨别技术，必须指定模型名，`:url` 和 `:method` 选项。

#### 处理命名空间

如果在路由中使用了命名空间，`form_for` 方法也有相应的简写形式。如果程序中有个 `admin` 命名空间，表单可以写成：

```ruby
form_for [:admin, @article]
```

这个表单会提交到命名空间 `admin` 中的 `ArticlesController`（更新文章时提交到 `admin_article_path(@article)`）。如果命名空间有很多层，句法类似：

```ruby
form_for [:admin, :management, @article]
```

关于 Rails 路由的详细信息以及相关的约定，请阅读“[Rails 路由全解](routing.html)”一文。

### 表单如何处理 PATCH，PUT 或 DELETE 请求？

Rails 框架建议使用 REST 架构设计程序，因此除了 GET 和 POST 请求之外，还要处理 PATCH 和 DELETE 请求。但是大多数浏览器不支持从表单中提交 GET 和 POST 之外的请求。

为了解决这个问题，Rails 使用 POST 请求进行模拟，并在表单中加入一个名为 `_method` 的隐藏字段，其值表示真正希望使用的请求方法：

```ruby
form_tag(search_path, method: "patch")
```

生成的 HTML 为：

```html
<form accept-charset="UTF-8" action="/search" method="post">
  <div style="margin:0;padding:0">
    <input name="_method" type="hidden" value="patch" />
    <input name="utf8" type="hidden" value="&#x2713;" />
    <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  </div>
  ...
```

处理提交的数据时，Rails 以 `_method` 的值为准，发起相应类型的请求（在这个例子中是 PATCH 请求）。

快速创建选择列表
--------------

HTML 中的选择列表往往需要编写很多标记语言（每个选项都要创建一个 `option` 元素），因此最适合自动生成。

选择列表的标记语言如下所示：

```html
<select name="city_id" id="city_id">
  <option value="1">Lisbon</option>
  <option value="2">Madrid</option>
  ...
  <option value="12">Berlin</option>
</select>
```

这个列表列出了一组城市名。在程序内部只需要处理各选项的 ID，因此把各选项的 `value` 属性设为 ID。下面来看一下 Rails 为我们提供了哪些帮助方法。

### `select` 和 `option` 标签

最常见的帮助方法是 `select_tag`，如其名所示，其作用是生成 `select` 标签，其中可以包含一个由选项组成的字符串：

```erb
<%= select_tag(:city_id, '<option value="1">Lisbon</option>...') %>
```

这只是个开始，还无法动态生成 `option` 标签。`option` 标签可以使用帮助方法 `options_for_select` 生成：

```erb
<%= options_for_select([['Lisbon', 1], ['Madrid', 2], ...]) %>
```

生成的 HTML 为：

```html
<option value="1">Lisbon</option>
<option value="2">Madrid</option>
...
```

`options_for_select` 方法的第一个参数是一个嵌套数组，每个元素都有两个子元素：选项的文本（城市名）和选项的 `value` 属性值（城市 ID）。选项的 `value` 属性值会提交到控制器中。ID 的值经常表示数据库对象，但这个例子除外。

知道上述用法后，就可以结合 `select_tag` 和 `options_for_select` 两个方法生成所需的完整 HTML 标记：

```erb
<%= select_tag(:city_id, options_for_select(...)) %>
```

`options_for_select` 方法还可预先选中一个选项，通过第二个参数指定：

```erb
<%= options_for_select([['Lisbon', 1], ['Madrid', 2], ...], 2) %>
```

生成的 HTML 如下：

```html
<option value="1">Lisbon</option>
<option value="2" selected="selected">Madrid</option>
...
```

当 Rails 发现生成的选项 `value` 属性值和指定的值一样时，就会在这个选项中加上 `selected` 属性。

TIP: `options_for_select` 方法的第二个参数必须完全和需要选中的选项 `value` 属性值相等。如果 `value` 的值是整数 2，就不能传入字符串 `"2"`，必须传入数字 `2`。注意，从 `params` 中获取的值都是字符串。

使用 Hash 可以为选项指定任意属性：

```erb
<%= options_for_select([['Lisbon', 1, {'data-size' => '2.8 million'}], ['Madrid', 2, {'data-size' => '3.2 million'}]], 2) %>
```

生成的 HTML 如下：

```html
<option value="1" data-size="2.8 million">Lisbon</option>
<option value="2" selected="selected" data-size="3.2 million">Madrid</option>
...
```

### 处理模型的选择列表

大多数情况下，表单的控件用于处理指定的数据库模型，正如你所期望的，Rails 为此提供了很多用于生成选择列表的帮助方法。和其他表单帮助方法一样，处理模型时要去掉 `select_tag` 中的 `_tag`：

```ruby
# controller:
@person = Person.new(city_id: 2)
```

```erb
# view:
<%= select(:person, :city_id, [['Lisbon', 1], ['Madrid', 2], ...]) %>
```

注意，第三个参数，选项数组，和传入 `options_for_select` 方法的参数一样。这种帮助方法的一个好处是，无需关心如何预先选中正确的城市，只要用户设置了所在城市，Rails 就会读取 `@person.city_id` 的值，为你代劳。

和其他帮助方法一样，如果要在绑定到 `@person` 对象上的表单构造器上使用 `select` 方法，相应的句法为：

```erb
# select on a form builder
<%= f.select(:city_id, ...) %>
```

`select` 帮助方法还可接受一个代码块：

```erb
<%= f.select(:city_id) do %>
  <% [['Lisbon', 1], ['Madrid', 2]].each do |c| -%>
    <%= content_tag(:option, c.first, value: c.last) %>
  <% end %>
<% end %>
```

WARNING: 如果使用 `select` 方法（或类似的帮助方法，例如 `collection_select` 和 `select_tag`）处理 `belongs_to` 关联，必须传入外键名（在上例中是 `city_id`），而不是关联名。如果传入的是 `city` 而不是 `city_id`，把 `params` 传给 `Person.new` 或 `update` 方法时，会抛出异常：` ActiveRecord::AssociationTypeMismatch: City(#17815740) expected, got String(#1138750)`。这个要求还可以这么理解，表单帮助方法只能编辑模型的属性。此外还要知道，允许用户直接编辑外键具有潜在地安全隐患。

### 根据任意对象组成的集合创建 `option` 标签

使用 `options_for_select` 方法生成 `option` 标签必须使用数组指定各选项的文本和值。如果有个 `City` 模型，想根据模型实例组成的集合生成 `option` 标签应该怎么做呢？一种方法是遍历集合，创建一个嵌套数组：

```erb
<% cities_array = City.all.map { |city| [city.name, city.id] } %>
<%= options_for_select(cities_array) %>
```

这种方法完全可行，但 Rails 提供了一个更简洁的帮助方法：`options_from_collection_for_select`。这个方法接受一个由任意对象组成的集合，以及另外两个参数：获取选项文本和值使用的方法。

```erb
<%= options_from_collection_for_select(City.all, :id, :name) %>
```

从这个帮助方法的名字中可以看出，它只生成 `option` 标签。如果想生成可使用的选择列表，和 `options_for_select` 方法一样要结合 `select_tag` 方法一起使用。`select` 方法集成了 `select_tag` 和 `options_for_select` 两个方法，类似地，处理集合时，可以使用 `collection_select` 方法，它集成了 `select_tag` 和 `options_from_collection_for_select` 两个方法。

```erb
<%= collection_select(:person, :city_id, City.all, :id, :name) %>
```

`options_from_collection_for_select` 对 `collection_select` 来说，就像 `options_for_select` 与 `select` 的关系一样。

NOTE: 传入 `options_for_select` 方法的子数组第一个元素是选项文本，第二个元素是选项的值，但传入 `options_from_collection_for_select` 方法的第一个参数是获取选项值的方法，第二个才是获取选项文本的方法。

### 时区和国家选择列表

要想在 Rails 程序中实现时区相关的功能，就得询问用户其所在的时区。设定时区时可以使用 `collection_select` 方法根据预先定义的时区对象生成一个选择列表，也可以直接使用 `time_zone_select` 帮助方法：

```erb
<%= time_zone_select(:person, :time_zone) %>
```

如果想定制时区列表，可使用 `time_zone_options_for_select` 帮助方法。这两个方法可接受的参数请查阅 API 文档。

以前 Rails 还内置了 `country_select` 帮助方法，用于创建国家选择列表，但现在已经被提取出来做成了 [country_select](https://github.com/stefanpenner/country_select) gem。使用这个 gem 时要注意，是否包含某个国家还存在争议（正因为此，Rails 才不想内置）。

使用日期和时间表单帮助方法
----------------------

你可以选择不使用生成 HTML5 日期和时间输入框的帮助方法，而使用生成日期和时间选择列表的帮助方法。生成日期和时间选择列表的帮助方法和其他表单帮助方法有两个重要的不同点：

* 日期和时间不在单个 `input` 元素中输入，而是每个时间单位都有各自的元素，因此在 `params` 中就没有单个值能表示完整的日期和时间；
* 其他帮助方法通过 `_tag` 后缀区分是独立的帮助方法还是操作模型对象的帮助方法。对日期和时间帮助方法来说，`select_date`、`select_time` 和 `select_datetime` 是独立的帮助方法，`date_select`、`time_select` 和 `datetime_select` 是相应的操作模型对象的帮助方法。

这两类帮助方法都会为每个时间单位（年，月，日等）生成各自的选择列表。

### 独立的帮助方法

`select_*` 这类帮助方法的第一个参数是 `Date`、`Time` 或 `DateTime` 类的实例，并选中指定的日期时间。如果不指定，就使用当前日期时间。例如：

```erb
<%= select_date Date.today, prefix: :start_date %>
```

生成的 HTML 如下（为了行文简洁，省略了各选项）：

```html
<select id="start_date_year" name="start_date[year]"> ... </select>
<select id="start_date_month" name="start_date[month]"> ... </select>
<select id="start_date_day" name="start_date[day]"> ... </select>
```

上面各控件会组成 `params[:start_date]`，其中包含名为 `:year`、`:month` 和 `:day` 的键。如果想获取 `Time` 或 `Date` 对象，要读取各时间单位的值，然后传入适当的构造方法中，例如：

```ruby
Date.civil(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
```

`:prefix` 选项的作用是指定从 `params` 中获取各时间组成部分的键名。在上例中，`:prefix` 选项的值是 `start_date`。如果不指定这个选项，就是用默认值 `date`。

### 处理模型对象的帮助方法

`select_date` 方法在更新或创建 Active Record 对象的表单中有点力不从心，因为 Active Record 期望 `params` 中的每个元素都对应一个属性。用于处理模型对象的日期和时间帮助方法会提交一个名字特殊的参数，Active Record 看到这个参数时就知道必须和其他参数结合起来传递给字段类型对应的构造方法。例如：

```erb
<%= date_select :person, :birth_date %>
```

生成的 HTML 如下（为了行文简洁，省略了各选项）：

```html
<select id="person_birth_date_1i" name="person[birth_date(1i)]"> ... </select>
<select id="person_birth_date_2i" name="person[birth_date(2i)]"> ... </select>
<select id="person_birth_date_3i" name="person[birth_date(3i)]"> ... </select>
```

创建的 `params` Hash 如下：

```ruby
{'person' => {'birth_date(1i)' => '2008', 'birth_date(2i)' => '11', 'birth_date(3i)' => '22'}}
```

传递给 `Person.new`（或 `update`）方法时，Active Record 知道这些参数应该结合在一起组成 `birth_date` 属性，使用括号中的信息决定传给 `Date.civil` 等方法的顺序。

### 通用选项

这两种帮助方法都使用同一组核心函数生成各选择列表，因此使用的选项基本一样。默认情况下，Rails 生成的年份列表包含本年前后五年。如果这个范围不能满足需求，可以使用 `:start_year` 和 `:end_year` 选项指定。更详细的可用选项列表请参阅 [API 文档](http://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html)。

基本原则是，使用 `date_select` 方法处理模型对象，其他情况都使用 `select_date` 方法，例如在搜索表单中根据日期过滤搜索结果。

NOTE: 很多时候内置的日期选择列表不太智能，不能协助用户处理日期和星期几之间的对应关系。

### 单个时间单位选择列表

有时只需显示日期中的一部分，例如年份或月份。为此，Rails 提供了一系列帮助方法，分别用于创建各时间单位的选择列表：`select_year`，`select_month`，`select_day`，`select_hour`，`select_minute`，`select_second`。各帮助方法的作用一目了然。默认情况下，这些帮助方法创建的选择列表 `name` 属性都跟时间单位的名称一样，例如，`select_year` 方法创建的 `select` 元素 `name` 属性值为 `year`，`select_month` 方法创建的 `select` 元素 `name` 属性值为 `month`，不过也可使用 `:field_name` 选项指定其他值。`:prefix` 选项的作用与在 `select_date` 和 `select_time` 方法中一样，且默认值也一样。

这些帮助方法的第一个参数指定选中哪个值，可以是 `Date`、`Time` 或 `DateTime` 类的实例（会从实例中获取对应的值），也可以是数字。例如：

```erb
<%= select_year(2009) %>
<%= select_year(Time.now) %>
```

如果今年是 2009 年，那么上述两种用法生成的 HTML 是一样的。用户选择的值可以通过 `params[:date][:year]` 获取。

上传文件
--------

程序中一个常见的任务是上传某种文件，可以是用户的照片，或者 CSV 文件包含要处理的数据。处理文件上传功能时有一点要特别注意，表单的编码必须设为 `"multipart/form-data"`。如果使用 `form_for` 生成上传文件的表单，Rails 会自动加入这个编码。如果使用 `form_tag` 就得自己设置，如下例所示。

下面这两个表单都能用于上传文件：

```erb
<%= form_tag({action: :upload}, multipart: true) do %>
  <%= file_field_tag 'picture' %>
<% end %>

<%= form_for @person do |f| %>
  <%= f.file_field :picture %>
<% end %>
```

像往常一样，Rails 提供了两种帮助方法：独立的 `file_field_tag` 方法和处理模型的 `file_field` 方法。这两个方法和其他帮助方法唯一的区别是不能为文件选择框指定默认值，因为这样做没有意义。正如你所期望的，`file_field_tag` 方法上传的文件在 `params[:picture]` 中，`file_field` 方法上传的文件在 `params[:person][:picture]` 中。

### 上传了什么

存在 `params` Hash 中的对象其实是 `IO` 的子类，根据文件大小，可能是 `StringIO` 或者是存储在临时文件中的 `File` 实例。不管是哪个类，这个对象都有 `original_filename` 属性，其值为文件在用户电脑中的文件名；还有个 `content_type` 属性，其值为上传文件的 MIME 类型。下面这段代码把上传的文件保存在 `#{Rails.root}/public/uploads` 文件夹中，文件名和原始文件名一样（假设使用前面的表单上传）。

```ruby
def upload
  uploaded_io = params[:person][:picture]
  File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
    file.write(uploaded_io.read)
  end
end
```

文件上传完毕后可以做很多操作，例如把文件存储在某个地方（服务器的硬盘，Amazon S3 等）；把文件和模型关联起来；缩放图片，生成缩略图。这些复杂的操作已经超出了本文范畴。有很多代码库可以协助完成这些操作，其中两个广为人知的是 [CarrierWave](https://github.com/jnicklas/carrierwave) 和 [Paperclip](http://www.thoughtbot.com/projects/paperclip)。

NOTE: 如果用户没有选择文件，相应的参数为空字符串。

### 使用 Ajax 上传文件

异步上传文件和其他类型的表单不一样，仅在 `form_for` 方法中加入 `remote: true` 选项是不够的。在 Ajax 表单中，使用浏览器中的 JavaScript 进行序列化，但是 JavaScript 无法读取硬盘中的文件，因此文件无法上传。常见的解决方法是使用一个隐藏的 `iframe` 作为表单提交的目标。

定制表单构造器
-------------

前面说过，`form_for` 和 `fields_for` 方法拽入的对象是 `FormBuilder` 或其子类的实例。表单构造器中封装了用于显示单个对象表单元素的信息。你可以使用常规的方式使用各帮助方法，也可以继承 `FormBuilder` 类，添加其他的帮助方法。例如：

```erb
<%= form_for @person do |f| %>
  <%= text_field_with_label f, :first_name %>
<% end %>
```

可以写成：

```erb
<%= form_for @person, builder: LabellingFormBuilder do |f| %>
  <%= f.text_field :first_name %>
<% end %>
```

在此之前需要定义 `LabellingFormBuilder` 类，如下所示：

```ruby
class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options={})
    label(attribute) + super
  end
end
```

如果经常这么使用，可以定义 `labeled_form_for` 帮助方法，自动启用 `builder: LabellingFormBuilder` 选项。

所用的表单构造器还会决定执行下面这个渲染操作时会发生什么：

```erb
<%= render partial: f %>
```

如果 `f` 是 `FormBuilder` 类的实例，上述代码会渲染局部视图 `form`，并把传入局部视图的对象设为表单构造器。如果表单构造器是 `LabellingFormBuilder` 类的实例，则会渲染局部视图 `labelling_form`。

理解参数命名约定
--------------

从前几节可以看出，表单提交的数据可以直接保存在 `params` Hash 中，或者嵌套在子 Hash 中。例如，在 `Person` 模型对应控制器的 `create` 动作中，`params[:person]` 一般是一个 Hash，保存创建 `Person` 实例的所有属性。`params` Hash 中也可以保存数组，或由 Hash 组成的数组，等等。

HTML 表单基本上不能处理任何结构化数据，提交的只是由普通的字符串组成的键值对。在程序中使用的数组参数和 Hash 参数是通过 Rails 的参数命名约定生成的。

TIP: 如果想快速试验本节中的示例，可以在控制台中直接调用 Rack 的参数解析器。例如：
T>
```ruby
TIP: Rack::Utils.parse_query "name=fred&phone=0123456789"
TIP: # => {"name"=>"fred", "phone"=>"0123456789"}
TIP: ```

### 基本结构

数组和 Hash 是两种基本结构。获取 Hash 中值的方法和 `params` 一样。如果表单中包含以下控件：

```html
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

得到的 `params` 值为：

```erb
{'person' => {'name' => 'Henry'}}
```

在控制器中可以使用 `params[:person][:name]` 获取提交的值。

Hash 可以随意嵌套，不限制层级，例如：

```html
<input id="person_address_city" name="person[address][city]" type="text" value="New York"/>
```

得到的 `params` 值为：

```ruby
{'person' => {'address' => {'city' => 'New York'}}}
```

一般情况下 Rails 会忽略重复的参数名。如果参数名中包含空的方括号（`[]`），Rails 会将其组建成一个数组。如果想让用户输入多个电话号码，在表单中可以这么做：

```html
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
```

得到的 `params[:person][:phone_number]` 就是一个数组。

### 结合在一起使用

上述命名约定可以结合起来使用，让 `params` 的某个元素值为数组（如前例），或者由 Hash 组成的数组。例如，使用下面的表单控件可以填写多个地址：

```html
<input name="addresses[][line1]" type="text"/>
<input name="addresses[][line2]" type="text"/>
<input name="addresses[][city]" type="text"/>
```

得到的 `params[:addresses]` 值是一个由 Hash 组成的数组，Hash 中的键包括 `line1`、`line2` 和 `city`。如果 Rails 发现输入框的 `name` 属性值已经存在于当前 Hash 中，就会新建一个 Hash。

不过有个限制，虽然 Hash 可以嵌套任意层级，但数组只能嵌套一层。如果需要嵌套多层数组，可以使用 Hash 实现。例如，如果想创建一个包含模型对象的数组，可以创建一个 Hash，以模型对象的 ID、数组索引或其他参数为键。

WARNING: 数组类型参数不能很好的在 `check_box` 帮助方法中使用。根据 HTML 规范，未选中的复选框不应该提交值。但是不管是否选中都提交值往往更便于处理。为此 `check_box` 方法额外创建了一个同名的隐藏 `input` 元素。如果没有选中复选框，只会提交隐藏 `input` 元素的值，如果选中则同时提交两个值，但复选框的值优先级更高。处理数组参数时重复提交相同的参数会让 Rails 迷惑，因为对 Rails 来说，见到重复的 `input` 值，就会创建一个新数组元素。所以更推荐使用 `check_box_tag` 方法，或者用 Hash 代替数组。

### 使用表单帮助方法

前面几节并没有使用 Rails 提供的表单帮助方法。你可以自己创建 `input` 元素的 `name` 属性，然后直接将其传递给 `text_field_tag` 等帮助方法。但是 Rails 提供了更高级的支持。本节介绍 `form_for` 和 `fields_for` 方法的 `name` 参数以及 `:index` 选项。

你可能会想编写一个表单，其中有很多字段，用于编辑某人的所有地址。例如：

```erb
<%= form_for @person do |person_form| %>
  <%= person_form.text_field :name %>
  <% @person.addresses.each do |address| %>
    <%= person_form.fields_for address, index: address.id do |address_form|%>
      <%= address_form.text_field :city %>
    <% end %>
  <% end %>
<% end %>
```

假设这个人有两个地址，ID 分别为 23 和 45。那么上述代码生成的 HTML 如下：

```html
<form accept-charset="UTF-8" action="/people/1" class="edit_person" id="edit_person_1" method="post">
  <input id="person_name" name="person[name]" type="text" />
  <input id="person_address_23_city" name="person[address][23][city]" type="text" />
  <input id="person_address_45_city" name="person[address][45][city]" type="text" />
</form>
```

得到的 `params` Hash 如下：

```ruby
{'person' => {'name' => 'Bob', 'address' => {'23' => {'city' => 'Paris'}, '45' => {'city' => 'London'}}}}
```

Rails 之所以知道这些输入框中的值是 `person` Hash 的一部分，是因为我们在第一个表单构造器上调用了 `fields_for` 方法。指定 `:index` 选项的目的是告诉 Rails，其中的输入框 `name` 属性值不是 `person[address][city]`，而要在 `address` 和 `city` 索引之间插入 `:index` 选项对应的值（放入方括号中）。这么做很有用，因为便于分辨要修改的 `Address` 记录是哪个。`:index` 选项的值可以是具有其他意义的数字、字符串，甚至是 `nil`（此时会新建一个数组参数）。

如果想创建更复杂的嵌套，可以指定 `name` 属性的第一部分（前例中的 `person[address]`）：

```erb
<%= fields_for 'person[address][primary]', address, index: address do |address_form| %>
  <%= address_form.text_field :city %>
<% end %>
```

生成的 HTML 如下：

```html
<input id="person_address_primary_1_city" name="person[address][primary][1][city]" type="text" value="bologna" />
```

一般来说，最终得到的 `name` 属性值是 `fields_for` 或 `form_for` 方法的第一个参数加 `:index` 选项的值再加属性名。`:index` 选项也可直接传给 `text_field` 等帮助方法，但在表单构造器中指定可以避免代码重复。

为了简化句法，还可以不使用 `:index` 选项，直接在第一个参数后面加上 `[]`。这么做和指定 `index: address` 选项的作用一样，因此下面这段代码

```erb
<%= fields_for 'person[address][primary][]', address do |address_form| %>
  <%= address_form.text_field :city %>
<% end %>
```

生成的 HTML 和前面一样。


处理外部资源的表单
----------------

如果想把数据提交到外部资源，还是可以使用 Rails 提供的表单帮助方法。但有时需要为这些资源创建 `authenticity_token`。做法是把 `authenticity_token: 'your_external_token'` 作为选项传递给 `form_tag` 方法：

```erb
<%= form_tag 'http://farfar.away/form', authenticity_token: 'external_token') do %>
  Form contents
<% end %>
```

提交到外部资源的表单，其中可包含的字段有时受 API 的限制，例如支付网关。所有可能不用生成隐藏的 `authenticity_token` 字段，此时把 `:authenticity_token` 选项设为 `false` 即可：

```erb
<%= form_tag 'http://farfar.away/form', authenticity_token: false) do %>
  Form contents
<% end %>
```

以上技术也可用在 `form_for` 方法中：

```erb
<%= form_for @invoice, url: external_url, authenticity_token: 'external_token' do |f| %>
  Form contents
<% end %>
```

如果不想生成 `authenticity_token` 字段，可以这么做：

```erb
<%= form_for @invoice, url: external_url, authenticity_token: false do |f| %>
  Form contents
<% end %>
```

编写复杂的表单
------------

很多程序已经复杂到在一个表单中编辑一个对象已经无法满足需求了。例如，创建 `Person` 对象时还想让用户在同一个表单中创建多个地址（家庭地址，工作地址，等等）。以后编辑这个 `Person` 时，还想让用户根据需要添加、删除或修改地址。

### 设置模型

Active Record 为此种需求在模型中提供了支持，通过 `accepts_nested_attributes_for` 方法实现：

```ruby
class Person < ActiveRecord::Base
  has_many :addresses
  accepts_nested_attributes_for :addresses
end

class Address < ActiveRecord::Base
  belongs_to :person
end
```

这段代码会在 `Person` 对象上创建 `addresses_attributes=` 方法，用于创建、更新和删除地址（可选操作）。

### 嵌套表单

使用下面的表单可以创建 `Person` 对象及其地址：

```erb
<%= form_for @person do |f| %>
  Addresses:
  <ul>
    <%= f.fields_for :addresses do |addresses_form| %>
      <li>
        <%= addresses_form.label :kind %>
        <%= addresses_form.text_field :kind %>

        <%= addresses_form.label :street %>
        <%= addresses_form.text_field :street %>
        ...
      </li>
    <% end %>
  </ul>
<% end %>
```

如果关联支持嵌套属性，`fields_for` 方法会为关联中的每个元素执行一遍代码块。如果没有地址，就不执行代码块。一般的作法是在控制器中构建一个或多个空的子属性，这样至少会有一组字段显示出来。下面的例子会在新建 `Person` 对象的表单中显示两组地址字段。

```ruby
def new
  @person = Person.new
  2.times { @person.addresses.build}
end
```

`fields_for` 方法拽入一个表单构造器，参数的名字就是 `accepts_nested_attributes_for` 方法期望的。例如，如果用户填写了两个地址，提交的参数如下：

```ruby
{
  'person' => {
    'name' => 'John Doe',
    'addresses_attributes' => {
      '0' => {
        'kind' => 'Home',
        'street' => '221b Baker Street'
      },
      '1' => {
        'kind' => 'Office',
        'street' => '31 Spooner Street'
      }
    }
  }
}
```

`:addresses_attributes`  Hash 的键是什么不重要，但至少不能相同。

如果关联的对象已经存在于数据库中，`fields_for` 方法会自动生成一个隐藏字段，`value` 属性的值为记录的 `id`。把 `include_id: false` 选项传递给 `fields_for` 方法可以禁止生成这个隐藏字段。如果自动生成的字段位置不对，导致 HTML 无法通过验证，或者在 ORM 关系中子对象不存在 `id` 字段，就可以禁止自动生成这个隐藏字段。

### 控制器端

像往常一样，参数传递给模型之前，在控制器中要[过滤参数](action_controller_overview.html#strong-parameters)：

```ruby
def create
  @person = Person.new(person_params)
  # ...
end

private
  def person_params
    params.require(:person).permit(:name, addresses_attributes: [:id, :kind, :street])
  end
```

### 删除对象

如果允许用户删除关联的对象，可以把 `allow_destroy: true` 选项传递给 `accepts_nested_attributes_for` 方法：

```ruby
class Person < ActiveRecord::Base
  has_many :addresses
  accepts_nested_attributes_for :addresses, allow_destroy: true
end
```

如果属性组成的 Hash 中包含 `_destroy` 键，且其值为 `1` 或 `true`，就会删除对象。下面这个表单允许用户删除地址：

```erb
<%= form_for @person do |f| %>
  Addresses:
  <ul>
    <%= f.fields_for :addresses do |addresses_form| %>
      <li>
        <%= addresses_form.check_box :_destroy%>
        <%= addresses_form.label :kind %>
        <%= addresses_form.text_field :kind %>
        ...
      </li>
    <% end %>
  </ul>
<% end %>
```

别忘了修改控制器中的参数白名单，允许使用 `_destroy`：

```ruby
def person_params
  params.require(:person).
    permit(:name, addresses_attributes: [:id, :kind, :street, :_destroy])
end
```

### 避免创建空记录

如果用户没有填写某些字段，最好将其忽略。此功能可以通过 `accepts_nested_attributes_for` 方法的 `:reject_if` 选项实现，其值为 Proc 对象。这个 Proc 对象会在通过表单提交的每一个属性 Hash 上调用。如果返回值为 `false`，Active Record 就不会为这个 Hash 构建关联对象。下面的示例代码只有当 `kind` 属性存在时才尝试构建地址对象：

```ruby
class Person < ActiveRecord::Base
  has_many :addresses
  accepts_nested_attributes_for :addresses, reject_if: lambda {|attributes| attributes['kind'].blank?}
end
```

为了方便，可以把 `reject_if` 选项的值设为 `:all_blank`，此时创建的 Proc 会拒绝为 `_destroy` 之外其他属性都为空的 Hash 构建对象。

### 按需添加字段

我们往往不想事先显示多组字段，而是当用户点击“添加新地址”按钮后再显示。Rails 并没有内建这种功能。生成新的字段时要确保关联数组的键是唯一的，一般可在 JavaScript 中使用当前时间。
