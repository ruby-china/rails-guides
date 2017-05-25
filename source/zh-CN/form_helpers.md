# 表单辅助方法

表单是 Web 应用中用户输入的基本界面。尽管如此，由于需要处理表单控件的名称和众多属性，编写和维护表单标记可能很快就会变得单调乏味。Rails 提供用于生成表单标记的视图辅助方法来消除这种复杂性。然而，由于这些辅助方法具有不同的用途和用法，开发者在使用之前需要知道它们之间的差异。

读完本文后，您将学到：

*   如何在 Rails 应用中创建搜索表单和类似的不针对特定模型的通用表单；
*   如何使用针对特定模型的表单来创建和修改对应的数据库记录；
*   如何使用多种类型的数据生成选择列表；
*   Rails 提供了哪些日期和时间辅助方法；
*   上传文件的表单有什么特殊之处；
*   如何用 `post` 方法把表单提交到外部资源并设置真伪令牌；
*   如何创建复杂表单。

-----------------------------------------------------------------------------

NOTE: 本文不是所有可用表单辅助方法及其参数的完整文档。关于表单辅助方法的完整介绍，请参阅 [Rails API 文档](http://api.rubyonrails.org/)。

<a class="anchor" id="dealing-with-basic-forms"></a>

## 处理基本表单

`form_tag` 方法是最基本的表单辅助方法。

```erb
<%= form_tag do %>
  Form contents
<% end %>
```

无参数调用 `form_tag` 方法会创建 `<form>` 标签，在提交表单时会向当前页面发起 POST 请求。例如，假设当前页面是 `/home/index`，上面的代码会生成下面的 HTML（为了提高可读性，添加了一些换行）：

```html
<form accept-charset="UTF-8" action="/" method="post">
  <input name="utf8" type="hidden" value="&#x2713;" />
  <input name="authenticity_token" type="hidden" value="J7CBxfHalt49OSHp27hblqK20c9PgwJ108nDHX/8Cts=" />
  Form contents
</form>
```

我们注意到，上面的 HTML 的第二行是一个 `hidden` 类型的 `input` 元素。这个 `input` 元素很重要，一旦缺少，表单就不能成功提交。这个 `input` 元素的 `name` 属性的值是 `utf8`，用于说明浏览器处理表单时使用的字符编码方式。对于所有表单，不管表单动作是“GET”还是“POST”，都会生成这个 `input` 元素。

上面的 HTML 的第三行也是一个 `input` 元素，元素的 `name` 属性的值是 `authenticity_token`。这个 `input` 元素是 Rails 的一个名为跨站请求伪造保护的安全特性。在启用跨站请求伪造保护的情况下，表单辅助方法会为所有非 GET 表单生成这个 `input` 元素。关于跨站请求伪造保护的更多介绍，请参阅 [跨站请求伪造（CSRF）](security.html#cross-site-request-forgery-csrf)。

<a class="anchor" id="a-generic-search-form"></a>

### 通用搜索表单

搜索表单是网上最常见的基本表单，包含：

*   具有“GET”方法的表单元素
*   文本框的 `label` 标签
*   文本框
*   提交按钮

我们可以分别使用 `form_tag`、`label_tag`、`text_field_tag`、`submit_tag` 标签来创建搜索表单，就像下面这样：

```erb
<%= form_tag("/search", method: "get") do %>
  <%= label_tag(:q, "Search for:") %>
  <%= text_field_tag(:q) %>
  <%= submit_tag("Search") %>
<% end %>
```

上面的代码会生成下面的 HTML：

```html
<form accept-charset="UTF-8" action="/search" method="get">
  <input name="utf8" type="hidden" value="&#x2713;" />
  <label for="q">Search for:</label>
  <input id="q" name="q" type="text" />
  <input name="commit" type="submit" value="Search" />
</form>
```

NOTE: 表单中的文本框会根据 `name` 属性（在上面的例子中值为 `q`）生成 `id` 属性。`id` 属性在应用 CSS 样式或使用 JavaScript 操作表单控件时非常有用。

除 `text_field_tag` 和 `submit_tag` 方法之外，每个 HTML 表单控件都有对应的辅助方法。

WARNING: 搜索表单的方法都应该设置为“GET”，这样用户就可以把搜索结果添加为书签。一般来说，Rails 推荐为表单动作使用正确的 HTTP 动词。

<a class="anchor" id="multiple-hashes-in-form-helper-calls"></a>

### 在调用表单辅助方法时使用多个散列

`form_tag` 辅助方法接受两个参数：提交表单的地址和选项散列。选项散列用于指明提交表单的方法，以及 HTML 选项，例如表单的 `class` 属性。

和 `link_to` 辅助方法一样，提交表单的地址可以是字符串，也可以是散列形式的 URL 参数。Rails 路由能够识别这个散列，将其转换为有效的 URL 地址。尽管如此，由于 `form_tag` 方法的两个参数都是散列，如果我们想同时指定两个参数，就很容易遇到问题。假如有下面的代码：

```ruby
form_tag(controller: "people", action: "search", method: "get", class: "nifty_form")
# => '<form accept-charset="UTF-8" action="/people/search?method=get&class=nifty_form" method="post">'
```

在上面的代码中，`method` 和 `class` 选项的值会被添加到生成的 URL 地址的查询字符串中，不管我们是不是想要使用两个散列作为参数，Rails 都会把这些选项当作一个散列。为了告诉 Rails 我们想要使用两个散列作为参数，我们可以把第一个散列放在大括号中，或者把两个散列都放在大括号中。这样就可以生成我们想要的 HTML 了：

```ruby
form_tag({controller: "people", action: "search"}, method: "get", class: "nifty_form")
# => '<form accept-charset="UTF-8" action="/people/search" method="get" class="nifty_form">'
```

<a class="anchor" id="helpers-for-generating-form-elements"></a>

### 用于生成表单元素的辅助方法

Rails 提供了一系列用于生成表单元素（如复选框、文本字段和单选按钮）的辅助方法。这些名称以 `_tag` 结尾的基本辅助方法（如 `text_field_tag` 和 `check_box_tag`）只生成单个 `input` 元素，并且第一个参数都是 `input` 元素的 `name` 属性的值。在提交表单时，`name` 属性的值会和表单数据一起传递，这样在控制器中就可以通过 `params` 来获得各个 `input` 元素的值。例如，如果表单包含 `<%= text_field_tag(:query) %>`，我们就可以通过 `params[:query]` 来获得这个文本字段的值。

在给 `input` 元素命名时，Rails 有一些命名约定，使我们可以提交非标量值（如数组或散列），这些值同样可以通过 `params` 来获得。关于这些命名约定的更多介绍，请参阅 [理解参数命名约定](#understanding-parameter-naming-conventions)。

关于这些辅助方法的用法的详细介绍，请参阅 [API 文档](http://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html)。

<a class="anchor" id="checkboxes"></a>

#### 复选框

复选框表单控件为用户提供一组可以启用或禁用的选项：

```erb
<%= check_box_tag(:pet_dog) %>
<%= label_tag(:pet_dog, "I own a dog") %>
<%= check_box_tag(:pet_cat) %>
<%= label_tag(:pet_cat, "I own a cat") %>
```

上面的代码会生成下面的 HTML：

```html
<input id="pet_dog" name="pet_dog" type="checkbox" value="1" />
<label for="pet_dog">I own a dog</label>
<input id="pet_cat" name="pet_cat" type="checkbox" value="1" />
<label for="pet_cat">I own a cat</label>
```

`check_box_tag` 辅助方法的第一个参数是生成的 `input` 元素的 `name` 属性的值。可选的第二个参数是 `input` 元素的值，当对应复选框被选中时，这个值会包含在表单数据中，并可以通过 `params` 来获得。

<a class="anchor" id="radio-buttons"></a>

#### 单选按钮

和复选框类似，单选按钮表单控件为用户提供一组选项，区别在于这些选项是互斥的，用户只能从中选择一个：

```erb
<%= radio_button_tag(:age, "child") %>
<%= label_tag(:age_child, "I am younger than 21") %>
<%= radio_button_tag(:age, "adult") %>
<%= label_tag(:age_adult, "I'm over 21") %>
```

上面的代码会生成下面的 HTML：

```html
<input id="age_child" name="age" type="radio" value="child" />
<label for="age_child">I am younger than 21</label>
<input id="age_adult" name="age" type="radio" value="adult" />
<label for="age_adult">I'm over 21</label>
```

和 `check_box_tag` 一样，`radio_button_tag` 辅助方法的第二个参数是生成的 `input` 元素的值。因为两个单选按钮的 `name` 属性的值相同（都是 `age`），所以用户只能从中选择一个，`params[:age]` 的值要么是 `"child"` 要么是 `"adult"`。

NOTE: 在使用复选框和单选按钮时一定要指定 `label` 标签。`label` 标签为对应选项提供说明文字，并扩大可点击区域，使用户更容易选中想要的选项。

<a class="anchor" id="other-helpers-of-interest"></a>

### 其他你可能感兴趣的辅助方法

其他值得一提的表单控件包括文本区域、密码框、隐藏输入字段、搜索字段、电话号码字段、日期字段、时间字段、颜色字段、本地日期时间字段、月份字段、星期字段、URL 地址字段、电子邮件地址字段、数字字段和范围字段：

```erb
<%= text_area_tag(:message, "Hi, nice site", size: "24x6") %>
<%= password_field_tag(:password) %>
<%= hidden_field_tag(:parent_id, "5") %>
<%= search_field(:user, :name) %>
<%= telephone_field(:user, :phone) %>
<%= date_field(:user, :born_on) %>
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

上面的代码会生成下面的 HTML：

```html
<textarea id="message" name="message" cols="24" rows="6">Hi, nice site</textarea>
<input id="password" name="password" type="password" />
<input id="parent_id" name="parent_id" type="hidden" value="5" />
<input id="user_name" name="user[name]" type="search" />
<input id="user_phone" name="user[phone]" type="tel" />
<input id="user_born_on" name="user[born_on]" type="date" />
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

隐藏输入字段不显示给用户，但和其他 `input` 元素一样可以保存数据。我们可以使用 JavaScript 来修改隐藏输入字段的值。

WARNING: 搜索字段、电话号码字段、日期字段、时间字段、颜色字段、日期时间字段、本地日期时间字段、月份字段、星期字段、URL 地址字段、电子邮件地址字段、数字字段和范围字段都是 HTML5 控件。要想在旧版本浏览器中拥有一致的体验，我们需要使用 HTML5 polyfill（针对 CSS 或 JavaScript 代码）。[HTML5 Cross Browser Polyfills](https://github.com/Modernizr/Modernizr/wiki/HTML5-Cross-Browser-Polyfills) 提供了 HTML5 polyfill 的完整列表，目前最流行的工具是 [Modernizr](https://modernizr.com/)，通过检测 HTML5 特性是否存在来添加缺失的功能。

TIP: 使用密码框时可以配置 Rails 应用，不把密码框的值写入日志，详情参阅 [日志](security.html#logging)。

<a class="anchor" id="dealing-with-model-objects"></a>

## 处理模型对象

<a class="anchor" id="dealing-with-model-objects-model-object-helpers"></a>

### 模型对象辅助方法

表单经常用于修改或创建模型对象。这种情况下当然可以使用 `*_tag` 辅助方法，但使用起来却有些麻烦，因为我们需要确保每个标记都使用了正确的参数名称并设置了合适的默认值。为此，Rails 提供了量身定制的辅助方法。这些辅助方法的名称不使用 `_tag` 后缀，例如 `text_field` 和 `text_area`。

这些辅助方法的第一个参数是实例变量，第二个参数是在这个实例变量对象上调用的方法（通常是模型属性）的名称。 Rails 会把 `input` 控件的值设置为所调用方法的返回值，并为 `input` 控件的 `name` 属性设置合适的值。假设我们在控制器中定义了 `@person` 实例变量，这个人的名字是 Henry，那么表单中的下述代码：

```erb
<%= text_field(:person, :name) %>
```

会生成下面的 HTML：

```html
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

提交表单时，用户输入的值储存在 `params[:person][:name]` 中。`params[:person]` 这个散列可以传递给 `Person.new` 方法作为参数，而如果 `@person` 是 `Person` 模型的实例，这个散列还可以传递给 `@person.update` 方法作为参数。尽管这些辅助方法的第二个参数通常都是模型属性的名称，但不是必须这样做。在上面的例子中，只要 `@person` 对象拥有 `name` 和 `name=` 方法即可省略第二个参数。

WARNING: 传入的参数必须是实例变量的名称，如 `:person` 或 `"person"`，而不是模型实例本身。

Rails 还提供了用于显示模型对象数据验证错误的辅助方法，详情参阅 [在视图中显示验证错误](active_record_validations.html#displaying-validation-errors-in-views)。

<a class="anchor" id="binding-a-form-to-an-object"></a>

### 把表单绑定到对象上

上一节介绍的辅助方法使用起来虽然很方便，但远非完美的解决方案。如果 `Person` 模型有很多属性需要修改，那么实例变量对象的名称就需要重复写很多遍。更好的解决方案是把表单绑定到模型对象上，为此我们可以使用 `form_for` 辅助方法。

假设有一个用于处理文章的控制器 `app/controllers/articles_controller.rb`：

```ruby
def new
  @article = Article.new
end
```

在对应的 `app/views/articles/new.html.erb` 视图中，可以像下面这样使用 `form_for` 辅助方法：

```erb
<%= form_for @article, url: {action: "create"}, html: {class: "nifty_form"} do |f| %>
  <%= f.text_field :title %>
  <%= f.text_area :body, size: "60x12" %>
  <%= f.submit "Create" %>
<% end %>
```

这里有几点需要注意：

*   实际需要修改的对象是 `@article`。
*   `form_for` 辅助方法的选项是一个散列，其中 `:url` 键对应的值是路由选项，`:html` 键对应的值是 HTML 选项，这两个选项本身也是散列。还可以提供 `:namespace` 选项来确保表单元素具有唯一的 ID 属性，自动生成的 ID 会以 `:namespace` 选项的值和下划线作为前缀。
*   `form_for` 辅助方法会产出一个表单生成器对象，即变量 `f`。
*   用于生成表单控件的辅助方法都在表单生成器对象 `f` 上调用。

上面的代码会生成下面的 HTML：

```html
<form accept-charset="UTF-8" action="/articles" method="post" class="nifty_form">
  <input id="article_title" name="article[title]" type="text" />
  <textarea id="article_body" name="article[body]" cols="60" rows="12"></textarea>
  <input name="commit" type="submit" value="Create" />
</form>
```

`form_for` 辅助方法的第一个参数决定了 `params` 使用哪个键来访问表单数据。在上面的例子中，这个参数为 `@article`，因此所有 `input` 控件的 `name` 属性都是 `article[attribute_name]` 这种形式，而在 `create` 动作中 `params[:article]` 是一个拥有 `:title` 和 `:body` 键的散列。关于 `input` 控件 `name` 属性重要性的更多介绍，请参阅 [理解参数命名约定](#understanding-parameter-naming-conventions)。

在表单生成器上调用的辅助方法和模型对象辅助方法几乎完全相同，区别在于前者无需指定需要修改的对象，因为表单生成器已经指定了需要修改的对象。

使用 `fields_for` 辅助方法也可以把表单绑定到对象上，但不会创建 `<form>` 标签。需要在同一个表单中修改多个模型对象时可以使用 `fields_for` 方法。例如，假设 `Person` 模型和 `ContactDetail` 模型关联，我们可以在下面这个表单中同时创建这两个模型的对象：

```erb
<%= form_for @person, url: {action: "create"} do |person_form| %>
  <%= person_form.text_field :name %>
  <%= fields_for @person.contact_detail do |contact_detail_form| %>
    <%= contact_detail_form.text_field :phone_number %>
  <% end %>
<% end %>
```

上面的代码会生成下面的 HTML：

```html
<form accept-charset="UTF-8" action="/people" class="new_person" id="new_person" method="post">
  <input id="person_name" name="person[name]" type="text" />
  <input id="contact_detail_phone_number" name="contact_detail[phone_number]" type="text" />
</form>
```

和 `form_for` 辅助方法一样， `fields_for` 方法产出的对象是一个表单生成器（实际上 `form_for` 方法在内部调用了 `fields_for` 方法）。

<a class="anchor" id="relying-on-record-identification"></a>

### 使用记录识别技术

`Article` 模型对我们来说是直接可用的，因此根据 Rails 开发的最佳实践，我们应该把这个模型声明为资源：

```ruby
resources :articles
```

NOTE: 资源的声明有许多副作用。关于设置和使用资源的更多介绍，请参阅 [资源路由：Rails 的默认风格](routing.html#resource-routing-the-rails-default)。

在处理 REST 架构的资源时，使用记录识别技术可以大大简化 `form_for` 辅助方法的调用。简而言之，使用记录识别技术后，我们只需把模型实例传递给 `form_for` 方法作为参数，Rails 会找出模型名称和其他信息：

```ruby
## 创建一篇新文章
# 冗长风格：
form_for(@article, url: articles_path)
# 简短风格，效果一样（用到了记录识别技术）：
form_for(@article)

## 编辑一篇现有文章
# 冗长风格：
form_for(@article, url: article_path(@article), html: {method: "patch"})
# 简短风格：
form_for(@article)
```

注意，不管是新建记录还是修改已有记录，`form_for` 方法调用的短格式都是相同的，很方便。记录识别技术很智能，能够通过调用 `record.new_record?` 方法来判断记录是否为新记录，同时还能选择正确的提交地址，并根据对象的类设置 `name` 属性的值。

Rails 还会自动为表单的 `class` 和 `id` 属性设置合适的值，例如，用于创建文章的表单，其 `id` 和 `class` 属性的值都会被设置为 `new_article`。用于修改 ID 为 23 的文章的表单，其 `class` 属性会被设置为 `edit_article`，其 `id` 属性会被设置为 `edit_article_23`。为了行文简洁，后文会省略这些属性。

WARNING: 在模型中使用单表继承（single-table inheritance，STI）时，如果只有父类声明为资源，在子类上就不能使用记录识别技术。这时，必须显式说明模型名称、`:url` 和 `:method`。

<a class="anchor" id="dealing-with-namespaces"></a>

#### 处理命名空间

如果在路由中使用了命名空间，我们同样可以使用 `form_for` 方法调用的短格式。例如，假设有 `admin` 命名空间，那么 `form_for` 方法调用的短格式可以写成：

```ruby
form_for [:admin, @article]
```

上面的代码会创建提交到 `admin` 命名空间中 `ArticlesController` 控制器的表单（在更新文章时会提交到 `admin_article_path(@article)` 这个地址）。对于多层命名空间的情况，语法也类似：

```ruby
form_for [:admin, :management, @article]
```

关于 Rails 路由及其相关约定的更多介绍，请参阅[Rails 路由全解](routing.html)。

<a class="anchor" id="how-do-forms-with-patch-put-or-delete-methods-work"></a>

### 表单如何处理 PATCH、PUT 或 DELETE 请求方法？

Rails 框架鼓励应用使用 REST 架构的设计，这意味着除了 GET 和 POST 请求，应用还要处理许多 PATCH 和 DELETE 请求。不过，大多数浏览器只支持表单的 GET 和 POST 方法，而不支持其他方法。

为了解决这个问题，Rails 使用 `name` 属性的值为 `_method` 的隐藏的 `input` 标签和 POST 方法来模拟其他方法，从而实现相同的效果：

```ruby
form_tag(search_path, method: "patch")
```

上面的代码会生成下面的 HTML：

```html
<form accept-charset="UTF-8" action="/search" method="post">
  <input name="_method" type="hidden" value="patch" />
  <input name="utf8" type="hidden" value="&#x2713;" />
  <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  ...
</form>
```

在处理提交的数据时，Rails 会考虑 `_method` 这个特殊参数的值，并按照指定的 HTTP 方法处理请求（在本例中为 PATCH）。

<a class="anchor" id="making-select-boxes-with-ease"></a>

## 快速创建选择列表

选择列表由大量 HTML 标签组成（需要为每个选项分别创建 `option` 标签），因此最适合动态生成。

下面是选择列表的一个例子：

```html
<select name="city_id" id="city_id">
  <option value="1">Lisbon</option>
  <option value="2">Madrid</option>
  ...
  <option value="12">Berlin</option>
</select>
```

这个选择列表显示了一组城市的列表，用户看到的是城市的名称，应用处理的是城市的 ID。每个 `option` 标签的 `value` 属性的值就是城市的 ID。下面我们会看到 Rails 为生成选择列表提供了哪些辅助方法。

<a class="anchor" id="the-select-and-option-tags"></a>

### `select` 和 `option` 标签

最通用的辅助方法是 `select_tag`，故名思义，这个辅助方法用于生成 `select` 标签，并在这个 `select` 标签中封装选项字符串：

```erb
<%= select_tag(:city_id, '<option value="1">Lisbon</option>...') %>
```

使用 `select_tag` 辅助方法只是第一步，仅靠它我们还无法动态生成 `option` 标签。接下来，我们可以使用 `options_for_select` 辅助方法生成 `option` 标签：

```erb
<%= options_for_select([['Lisbon', 1], ['Madrid', 2], ...]) %>
```

输出：

```html
<option value="1">Lisbon</option>
<option value="2">Madrid</option>
...
```

`options_for_select` 辅助方法的第一个参数是嵌套数组，其中每个子数组都有两个元素：选项文本（城市名称）和选项值（城市 ID）。选项值会提交给控制器。选项值通常是对应的数据库对象的 ID，但并不一定是这样。

掌握了上述知识，我们就可以联合使用 `select_tag` 和 `options_for_select` 辅助方法来动态生成选择列表了：

```erb
<%= select_tag(:city_id, options_for_select(...)) %>
```

`options_for_select` 辅助方法允许我们传递第二个参数来设置默认选项：

```erb
<%= options_for_select([['Lisbon', 1], ['Madrid', 2], ...], 2) %>
```

输出：

```html
<option value="1">Lisbon</option>
<option value="2" selected="selected">Madrid</option>
...
```

当 Rails 发现生成的选项值和第二个参数指定的值一样时，就会为这个选项添加 `selected` 属性。

WARNING: 如果 `select` 标签的 `required` 属性的值为 `true`，`size` 属性的值为 1，`multiple` 属性未设置为 `true`，并且未设置 `:include_blank` 或 `:prompt` 选项时，`:include_blank` 选项的值会被强制设置为 `true`。

我们可以通过散列为选项添加任意属性：

```erb
<%= options_for_select(
  [
    ['Lisbon', 1, { 'data-size' => '2.8 million' }],
    ['Madrid', 2, { 'data-size' => '3.2 million' }]
  ], 2
) %>
```

输出：

```html
<option value="1" data-size="2.8 million">Lisbon</option>
<option value="2" selected="selected" data-size="3.2 million">Madrid</option>
...
```

<a class="anchor" id="select-boxes-for-dealing-with-models"></a>

### 用于处理模型的选择列表

在大多数情况下，表单控件会绑定到特定的数据库模型，和我们期望的一样，Rails 为此提供了辅助方法。与其他表单辅助方法一致，在处理模型时，需要从 `select_tag` 中删除 `_tag` 后缀：

```ruby
# controller:
@person = Person.new(city_id: 2)
```

```erb
# view:
<%= select(:person, :city_id, [['Lisbon', 1], ['Madrid', 2], ...]) %>
```

需要注意的是，`select` 辅助方法的第三个参数，即选项数组，和传递给 `options_for_select` 辅助方法作为参数的选项数组是一样的。如果用户已经设置了默认城市，Rails 会从 `@person.city_id` 属性中读取这一设置，一切都是自动的，十分方便。

和其他辅助方法一样，如果要在绑定到 `@person` 对象的表单生成器上使用 `select` 辅助方法，相关句法如下：

```erb
# select on a form builder
<%= f.select(:city_id, ...) %>
```

我们还可以把块传递给 `select` 辅助方法：

```erb
<%= f.select(:city_id) do %>
  <% [['Lisbon', 1], ['Madrid', 2]].each do |c| -%>
    <%= content_tag(:option, c.first, value: c.last) %>
  <% end %>
<% end %>
```

WARNING: 如果我们使用 `select` 辅助方法（或类似的辅助方法，如 `collection_select`、`select_tag`）来设置 `belongs_to` 关联，就必须传入外键的名称（在上面的例子中是 `city_id`），而不是关联的名称。在上面的例子中，如果传入的是 `city` 而不是 `city_id`，在把 `params` 传递给 `Person.new` 或 `update` 方法时，Active Record 会抛出 `ActiveRecord::AssociationTypeMismatch: City(#17815740) expected, got String(#1138750)` 错误。换一个角度看，这说明表单辅助方法只能修改模型属性。我们还应该注意到允许用户直接修改外键的潜在安全后果。

<a class="anchor" id="pption-tags-from-a-collection-of-arbitrary-objects"></a>

### 从任意对象组成的集合创建 `option` 标签

使用 `options_for_select` 辅助方法生成 `option` 标签需要创建包含各个选项的文本和值的数组。但如果我们已经拥有 `City` 模型（可能是 Active Record 模型），并且想要从这些对象的集合生成 `option` 标签，那么应该怎么做呢？一个解决方案是创建并遍历嵌套数组：

```erb
<% cities_array = City.all.map { |city| [city.name, city.id] } %>
<%= options_for_select(cities_array) %>
```

这是一个完全有效的解决方案，但 Rails 提供了一个更简洁的替代方案：`options_from_collection_for_select` 辅助方法。这个辅助方法接受一个任意对象组成的集合作为参数，以及两个附加参数，分别用于读取选项值和选项文本的方法的名称：

```erb
<%= options_from_collection_for_select(City.all, :id, :name) %>
```

顾名思义，`options_from_collection_for_select` 辅助方法只生成 `option` 标签。和 `options_for_select` 辅助方法一样，要想生成可用的选择列表，我们需要联合使用 `options_from_collection_for_select` 和 `select_tag` 辅助方法。在处理模型对象时，`select` 辅助方法联合使用了 `select_tag` 和 `options_for_select` 辅助方法，同样，`collection_select` 辅助方法联合使用了 `select_tag` 和 `options_from_collection_for_select` 辅助方法。

```erb
<%= collection_select(:person, :city_id, City.all, :id, :name) %>
```

和其他辅助方法一样，如果要在绑定到 `@person` 对象的表单生成器上使用 `collection_select` 辅助方法，相关句法如下：

```erb
<%= f.collection_select(:city_id, City.all, :id, :name) %>
```

总结一下，`options_from_collection_for_select` 对于 `collection_select` 辅助方法，就如同 `options_for_select` 对于 `select` 辅助方法。

NOTE: 传递给 `options_for_select` 辅助方法作为参数的嵌套数组，子数组的第一个元素是选项文本，第二个元素是选项值，然而传递给 `options_from_collection_for_select` 辅助方法作为参数的嵌套数组，子数组的第一个元素是读取选项值的方法的名称，第二个元素是读取选项文本的方法的名称。

<a class="anchor" id="time-zone-and-country-select"></a>

### 时区和国家选择列表

要想利用 Rails 提供的时区相关功能，首先需要设置用户所在的时区。为此，我们可以使用 `collection_select` 辅助方法从预定义时区对象生成选择列表，我们也可以使用更简单的 `time_zone_select` 辅助方法：

```erb
<%= time_zone_select(:person, :time_zone) %>
```

Rails 还提供了 `time_zone_options_for_select` 辅助方法用于手动生成定制的时区选择列表。关于 `time_zone_select` 和 `time_zone_options_for_select` 辅助方法的更多介绍，请参阅 [API 文档](http://api.rubyonrails.org/classes/ActionView/Helpers/FormOptionsHelper.html#method-i-time_zone_options_for_select)。

Rails 的早期版本提供了用于生成国家选择列表的 `country_select` 辅助方法，现在这一功能被放入独立的 [country_select 插件](https://github.com/stefanpenner/country_select)。需要注意的是，在使用这个插件生成国家选择列表时，一些特定地区是否应该被当作国家还存在争议，这也是 Rails 不再内置这一功能的原因。

<a class="anchor" id="using-date-and-time-form-helpers"></a>

## 使用日期和时间的表单辅助方法

我们可以选择不使用生成 HTML5 日期和时间输入字段的表单辅助方法，而使用替代的日期和时间辅助方法。这些日期和时间辅助方法与所有其他表单辅助方法主要有两点不同：

*   日期和时间不是在单个 `input` 元素中输入，而是每个时间单位（年、月、日等）都有各自的 `input` 元素。因此在 `params` 散列中没有表示日期和时间的单个值。
*   其他表单辅助方法使用 `_tag` 后缀区分独立的辅助方法和处理模型对象的辅助方法。对于日期和时间辅助方法，`select_date`、`select_time` 和 `select_datetime` 是独立的辅助方法，`date_select`、`time_select` 和 `datetime_select` 是对应的处理模型对象的辅助方法。

这两类辅助方法都会为每个时间单位（年、月、日等）生成各自的选择列表。

<a class="anchor" id="barebones-helpers"></a>

### 独立的辅助方法

`select_*` 这类辅助方法的第一个参数是 `Date`、`Time` 或 `DateTime` 类的实例，用于指明选中的日期时间。如果省略这个参数，选中当前的日期时间。例如：

```erb
<%= select_date Date.today, prefix: :start_date %>
```

上面的代码会生成下面的 HTML（为了行文简洁，省略了实际选项值）：

```html
<select id="start_date_year" name="start_date[year]"> ... </select>
<select id="start_date_month" name="start_date[month]"> ... </select>
<select id="start_date_day" name="start_date[day]"> ... </select>
```

上面的代码会使 `params[:start_date]` 成为拥有 `:year`、`:month` 和 `:day` 键的散列。要想得到实际的 `Date`、`Time` 或 `DateTime` 对象，我们需要提取 `params[:start_date]` 中的信息并传递给适当的构造方法，例如：

```ruby
Date.civil(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
```

`:prefix` 选项用于说明从 `params` 散列中取回时间信息的键名。这个选项的默认值是 `date`，在上面的例子中被设置为 `start_date`。

<a class="anchor" id="model-object-helpers"></a>

### 处理模型对象的辅助方法

在更新或创建 Active Record 对象的表单中，`select_date` 辅助方法不能很好地工作，因为 Active Record 期望 `params` 散列的每个元素都对应一个模型属性。处理模型对象的日期和时间辅助方法使用特殊名称提交参数，Active Record 一看到这些参数就知道必须把这些参数和其他参数一起传递给对应字段类型的构造方法。例如：

```erb
<%= date_select :person, :birth_date %>
```

上面的代码会生成下面的 HTML（为了行文简洁，省略了实际选项值）：

```html
<select id="person_birth_date_1i" name="person[birth_date(1i)]"> ... </select>
<select id="person_birth_date_2i" name="person[birth_date(2i)]"> ... </select>
<select id="person_birth_date_3i" name="person[birth_date(3i)]"> ... </select>
```

上面的代码会生成下面的 `params` 散列：

```ruby
{'person' => {'birth_date(1i)' => '2008', 'birth_date(2i)' => '11', 'birth_date(3i)' => '22'}}
```

当把这个 `params` 散列传递给 `Person.new` 或 `update` 方法时，Active Record 会发现应该把这些参数都用于构造 `birth_date` 属性，并且会使用附加信息来确定把这些参数传递给构造方法（如 `Date.civil` 方法）的顺序。

<a class="anchor" id="common-options"></a>

### 通用选项

这两类辅助方法使用一组相同的核心函数来生成选择列表，因此使用的选项也大体相同。特别是默认情况下，Rails 生成的年份选项会包含当前年份的前后 5 年。如果这个范围不能满足使用需求，可以使用 `:start_year` 和 `:end_year` 选项覆盖这一默认设置。关于这两类辅助方法的可用选项的更多介绍，请参阅 [API 文档](http://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html)。

根据经验，在处理模型对象时应该使用 `date_select` 辅助方法，在其他情况下应该使用 `select_date` 辅助方法。例如在根据日期过滤搜索结果时就应该使用 `select_date` 辅助方法。

NOTE: 在许多情况下，内置的日期选择器显得笨手笨脚，不能帮助用户正确计算出日期和星期几之间的关系。

<a class="anchor" id="individual-components"></a>

### 独立组件

偶尔我们需要显示单个日期组件，例如年份或月份。为此，Rails 提供了一系列辅助方法，每个时间单位对应一个辅助方法，即 `select_year`、`select_month`、`select_day`、`select_hour`、`select_minute` 和 `select_second` 辅助方法。这些辅助方法的用法非常简单。默认情况下，它们会生成以时间单位命名的输入字段（例如，`select_year` 辅助方法生成名为“year”的输入字段，`select_month` 辅助方法生成名为“month”的输入字段），我们可以使用 `:field_name` 选项指定输入字段的名称。`:prefix` 选项的用法和在 `select_date` 和 `select_time` 辅助方法中一样，默认值也一样。

这些辅助方法的第一个参数可以是 `Date`、`Time` 或 `DateTime` 类的实例（会从实例中取出对应的值）或数值，用于指明选中的日期时间。例如：

```erb
<%= select_year(2009) %>
<%= select_year(Time.now) %>
```

如果当前年份是 2009 年，上面的代码会成生相同的 HTML。用户选择的年份可以通过 `params[:date][:year]` 取回。

<a class="anchor" id="uploading-files"></a>

## 上传文件

上传某种类型的文件是常见任务，例如上传某人的照片或包含待处理数据的 CSV 文件。在上传文件时特别需要注意的是，表单的编码必须设置为 `multipart/form-data`。使用 `form_for` 辅助方法时会自动完成这一设置。如果使用 `form_tag` 辅助方法，就必须手动完成这一设置，具体操作可以参考下面的例子。

下面这两个表单都用于上传文件。

```erb
<%= form_tag({action: :upload}, multipart: true) do %>
  <%= file_field_tag 'picture' %>
<% end %>

<%= form_for @person do |f| %>
  <%= f.file_field :picture %>
<% end %>
```

Rails 同样为上传文件提供了一对辅助方法：独立的辅助方法 `file_field_tag` 和处理模型的辅助方法 `file_field`。这两个辅助方法和其他辅助方法的唯一区别是，我们无法为文件上传控件设置默认值，因为这样做没有意义。和我们期望的一样，在上述例子的第一个表单中上传的文件通过 `params[:picture]` 取回，在第二个表单中通过 `params[:person][:picture]` 取回。

<a class="anchor" id="what-gets-uploaded"></a>

### 上传的内容

在上传文件时，`params` 散列中保存的文件对象实际上是 `IO` 类的子类的实例。根据上传文件大小的不同，这个实例有可能是 `StringIO` 类的实例，也可能是临时文件的 `File` 类的实例。在这两种情况下，文件对象具有 `original_filename` 属性，其值为上传的文件在用户计算机上的文件名，也具有 `content_type` 属性，其值为上传的文件的 MIME 类型。下面这段代码把上传的文件保存在 `#{Rails.root}/public/uploads` 文件夹中，文件名不变（假设使用上一节例子中的表单来上传文件）。

```ruby
def upload
  uploaded_io = params[:person][:picture]
  File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
    file.write(uploaded_io.read)
  end
end
```

一旦文件上传完毕，就可以执行很多后续操作，例如把文件储存到磁盘、Amazon S3 等位置并和模型关联起来，缩放图片并生成缩略图等。这些复杂的操作已经超出本文的范畴，不过有一些 Ruby 库可以帮助我们完成这些操作，其中两个众所周知的是 [CarrierWave](https://github.com/jnicklas/carrierwave) 和 [Paperclip](https://github.com/thoughtbot/paperclip)。

NOTE: 如果用户没有选择要上传的文件，对应参数会是空字符串。

<a class="anchor" id="dealing-with-ajax"></a>

### 处理 Ajax

和其他表单不同，异步上传文件的表单可不是为 `form_for` 辅助方法设置 `remote: true` 选项这么简单。在这个 Ajax 表单中，上传文件的序列化是通过浏览器端的 JavaScript 完成的，而 JavaScript 无法读取硬盘上的文件，因此文件无法上传。最常见的解决方案是使用不可见的 iframe 作为表单提交的目标。

<a class="anchor" id="customizing-form-builders"></a>

## 定制表单生成器

前面说过，`form_for` 和 `fields_for` 辅助方法产出的对象是 `FormBuilder` 类或其子类的实例，即表单生成器。表单生成器为单个对象封装了显示表单所需的功能。我们可以用常规的方式使用表单辅助方法，也可以继承 `FormBuilder` 类并添加其他辅助方法。例如：

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

在使用前需要定义 `LabellingFormBuilder` 类：

```ruby
class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options={})
    label(attribute) + super
  end
end
```

如果经常这样使用，我们可以定义 `labeled_form_for` 辅助方法，自动应用 `builder: LabellingFormBuilder` 选项。

```ruby
def labeled_form_for(record, options = {}, &block)
  options.merge! builder: LabellingFormBuilder
  form_for record, options, &block
end
```

表单生成器还会确定进行下面的渲染时应该执行的操作：

```erb
<%= render partial: f %>
```

如果表单生成器 `f` 是 `FormBuilder` 类的实例，那么上面的代码会渲染局部视图 `form`，并把传入局部视图的对象设置为表单生成器。如果表单生成器 `f` 是 `LabellingFormBuilder` 类的实例，那么上面的代码会渲染局部视图 `labelling_form`。

<a class="anchor" id="understanding-parameter-naming-conventions"></a>

## 理解参数命名约定

从前面几节我们可以看到，表单提交的数据可以保存在 `params` 散列或嵌套的子散列中。例如，在 `Person` 模型的标准 `create` 动作中，`params[:person]` 通常是储存了创建 `Person` 实例所需的所有属性的散列。`params` 散列也可以包含数组、散列构成的数组等等。

从根本上说，HTML 表单并不理解任何类型的结构化数据，表单提交的数据都是普通字符串组成的键值对。我们在应用中看到的数组和散列都是 Rails 根据参数命名约定生成的。

<a class="anchor" id="basic-structures"></a>

### 基本结构

数组和散列是两种基本数据结构。散列句法用于访问 `params` 中的值。例如，如果表单包含：

```html
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

`params` 散列会包含：

```ruby
{'person' => {'name' => 'Henry'}}
```

在控制器中可以使用 `params[:person][:name]` 取回表单提交的值。

散列可以根据需要嵌套，不限制层级，例如：

```html
<input id="person_address_city" name="person[address][city]" type="text" value="New York"/>
```

`params` 散列会包含：

```ruby
{'person' => {'address' => {'city' => 'New York'}}}
```

通常 Rails 会忽略重复的参数名。如果参数名包含一组空的方括号 `[]`，Rails 就会用这些参数的值生成一个数组。例如，要想让用户输入多个电话号码，我们可以在表单中添加：

```html
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
```

得到的 `params[:person][:phone_number]` 是包含用户输入的电话号码的数组。

<a class="anchor" id="combining-them"></a>

### 联合使用

我们可以联合使用数组和散列。散列的元素可以是前面例子中那样的数组，也可以是散列构成的数组。例如，通过重复使用下面的表单控件我们可以添加任意长度的多行地址：

```html
<input name="addresses[][line1]" type="text"/>
<input name="addresses[][line2]" type="text"/>
<input name="addresses[][city]" type="text"/>
```

得到的 `params[:addresses]` 是散列构成的数组，散列的键包括 `line1`、`line2` 和 `city`。如果 Rails 发现输入控件的名称已经存在于当前散列的键中，就会新建一个散列。

不过还有一个限制，尽管散列可以任意嵌套，但数组只能有一层。数组通常可以用散列替换。例如，模型对象的数组可以用以模型对象 ID 、数组索引或其他参数为键的散列替换。

WARNING: 数组参数在 `check_box` 辅助方法中不能很好地工作。根据 HTML 规范，未选中的复选框不提交任何值。然而，未选中的复选框也提交值往往会更容易处理。为此，`check_box` 辅助方法通过创建辅助的同名隐藏 `input` 元素来模拟这一行为。如果复选框未选中，只有隐藏的 `input` 元素的值会被提交；如果复选框被选中，复选框本身的值和隐藏的 `input` 元素的值都会被提交，但复选框本身的值优先级更高。在处理数组参数时，这样的重复提交会把 Rails 搞糊涂，因为 Rails 无法确定什么时候创建新的数组元素。这种情况下，我们可以使用 `check_box_tag` 辅助方法，或者用散列代替数组。

<a class="anchor" id="using-form-helpers"></a>

### 使用表单辅助方法

在前面两节中我们没有使用 Rails 表单辅助方法。尽管我们可以手动为 `input` 元素命名，然后直接把它们传递给 `text_field_tag` 这类辅助方法，但 Rails 支持更高级的功能。我们可以使用 `form_for` 和 `fields_for` 辅助方法的 `name` 参数以及 `:index` 选项。

假设我们想要渲染一个表单，用于修改某人地址的各个字段。例如：

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

如果某人有两个地址，ID 分别为 23 和 45，那么上面的代码会生成下面的 HTML：

```html
<form accept-charset="UTF-8" action="/people/1" class="edit_person" id="edit_person_1" method="post">
  <input id="person_name" name="person[name]" type="text" />
  <input id="person_address_23_city" name="person[address][23][city]" type="text" />
  <input id="person_address_45_city" name="person[address][45][city]" type="text" />
</form>
```

得到的 `params` 散列会包含：

```ruby
{'person' => {'name' => 'Bob', 'address' => {'23' => {'city' => 'Paris'}, '45' => {'city' => 'London'}}}}
```

Rails 之所以知道这些输入控件的值是 `person` 散列的一部分，是因为我们在第一个表单生成器上调用了 `fields_for` 辅助方法。指定 `:index` 选项是为了告诉 Rails，不要把输入控件命名为 `person[address][city]`，而要在 `address` 和 `city` 之间插入索引（放在 `[]` 中）。这样要想确定需要修改的 `Address` 记录就变得很容易，因此往往也很有用。`:index` 选项的值还可以是其他重要数字、字符串甚至 `nil`（使用 `nil` 时会创建数组参数）。

要想创建更复杂的嵌套，我们可以显式指定输入控件名称的 `name` 参数（在上面的例子中是 `person[address]`）：

```erb
<%= fields_for 'person[address][primary]', address, index: address do |address_form| %>
  <%= address_form.text_field :city %>
<% end %>
```

上面的代码会生成下面的 HTML：

```html
<input id="person_address_primary_1_city" name="person[address][primary][1][city]" type="text" value="bologna" />
```

一般来说，输入控件的最终名称是 `fields_for` 或 `form_for` 辅助方法的 `name` 参数，加上 `:index` 选项的值，再加上属性名。我们也可以直接把 `:index` 选项传递给 `text_field` 这样的辅助方法作为参数，但在表单生成器中指定这个选项比在输入控件中分别指定这个选项要更为简洁。

还有一种简易写法，可以在 `name` 参数后加上 `[]` 并省略 `:index` 选项。这种简易写法和指定 `index: address` 选项的效果是一样的：

```erb
<%= fields_for 'person[address][primary][]', address do |address_form| %>
  <%= address_form.text_field :city %>
<% end %>
```

上面的代码生成的 HTML 和前一个例子完全相同。

<a class="anchor" id="forms-to-external-resources"></a>

## 处理外部资源的表单

Rails 表单辅助方法也可用于创建向外部资源提交数据的表单。不过，有时我们需要为这些外部资源设置 `authenticity_token`，具体操作是为 `form_tag` 辅助方法设置 `authenticity_token: 'your_external_token'` 选项：

```erb
<%= form_tag 'http://farfar.away/form', authenticity_token: 'external_token' do %>
  Form contents
<% end %>
```

在向外部资源（例如支付网关）提交数据时，有时表单中可用的字段会受到外部 API 的限制，并且不需要生成 `authenticity_token`。通过设置 `authenticity_token: false` 选项即可禁用 `authenticity_token`。

```erb
<%= form_tag 'http://farfar.away/form', authenticity_token: false do %>
  Form contents
<% end %>
```

相同的技术也可用于 `form_for` 辅助方法：

```erb
<%= form_for @invoice, url: external_url, authenticity_token: 'external_token' do |f| %>
  Form contents
<% end %>
```

或者，如果想要禁用 `authenticity_token`：

```erb
<%= form_for @invoice, url: external_url, authenticity_token: false do |f| %>
  Form contents
<% end %>
```

<a class="anchor" id="building-complex-forms"></a>

## 创建复杂表单

许多应用可不只是在表单中修改单个对象这样简单。例如，在创建 `Person` 模型的实例时，我们可能还想让用户在同一个表单中创建多条地址记录（如家庭地址、单位地址等）。之后在修改 `Person` 模型的实例时，用户应该能够根据需要添加、删除或修改地址。

<a class="anchor" id="configuring-the-model"></a>

### 配置模型

为此，Active Record 通过 `accepts_nested_attributes_for` 方法在模型层面提供支持：

```ruby
class Person < ApplicationRecord
  has_many :addresses
  accepts_nested_attributes_for :addresses
end

class Address < ApplicationRecord
  belongs_to :person
end
```

上面的代码会在 `Person` 模型上创建 `addresses_attributes=` 方法，用于创建、更新或删除地址。

<a class="anchor" id="nested-forms"></a>

### 嵌套表单

通过下面的表单我们可以创建 `Person` 模型的实例及其关联的地址：

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

如果关联支持嵌套属性，`fields_for` 方法会为关联中的每个元素执行块。如果 `Person` 模型的实例没有关联地址，就不会显示地址字段。一般的做法是构建一个或多个空的子属性，这样至少会显示一组字段。下面的例子会在新建 `Person` 模型实例的表单中显示两组地址字段。

```ruby
def new
  @person = Person.new
  2.times { @person.addresses.build}
end
```

`fields_for` 辅助方法会产出表单生成器，而 `accepts_nested_attributes_for` 方法需要参数名。例如，当创建具有两个地址的 `Person` 模型的实例时，表单提交的参数如下：

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

`:addresses_attributes` 散列的键是什么并不重要，只要每个地址的键互不相同即可。

如果关联对象在数据库中已存在，`fields_for` 方法会使用这个对象的 ID 自动生成隐藏输入字段。通过设置 `include_id: false` 选项可以禁止自动生成隐藏输入字段。如果自动生成的隐藏输入字段位置不对，导致 HTML 无效，或者 ORM 中子对象不存在 ID，那么我们就应该禁止自动生成隐藏输入字段。

<a class="anchor" id="the-controller"></a>

### 控制器

照例，我们需要在控制器中[把参数列入白名单](action_controller_overview.html#strong-parameters)，然后再把参数传递给模型：

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

<a class="anchor" id="removing-objects"></a>

### 删除对象

通过为 `accepts_nested_attributes_for` 方法设置 `allow_destroy: true` 选项，用户就可以删除关联对象。

```ruby
class Person < ApplicationRecord
  has_many :addresses
  accepts_nested_attributes_for :addresses, allow_destroy: true
end
```

如果对象属性散列包含 `_destroy` 键并且值为 1，这个对象就会被删除。下面的表单允许用户删除地址：

```erb
<%= form_for @person do |f| %>
  Addresses:
  <ul>
    <%= f.fields_for :addresses do |addresses_form| %>
      <li>
        <%= addresses_form.check_box :_destroy %>
        <%= addresses_form.label :kind %>
        <%= addresses_form.text_field :kind %>
        ...
      </li>
    <% end %>
  </ul>
<% end %>
```

别忘了在控制器中更新参数白名单，添加 `_destroy` 字段。

```ruby
def person_params
  params.require(:person).
    permit(:name, addresses_attributes: [:id, :kind, :street, :_destroy])
end
```

<a class="anchor" id="preventing-empty-records"></a>

### 防止创建空记录

通常我们需要忽略用户没有填写的字段。要实现这个功能，我们可以为 `accepts_nested_attributes_for` 方法设置 `:reject_if` 选项，这个选项的值是一个 Proc 对象。在表单提交每个属性散列时都会调用这个 Proc 对象。当 Proc 对象的返回值为 `true` 时，Active Record 不会为这个属性 Hash 创建关联对象。在下面的例子中，当设置了 `kind` 属性时，Active Record 才会创建地址：

```ruby
class Person < ApplicationRecord
  has_many :addresses
  accepts_nested_attributes_for :addresses, reject_if: lambda {|attributes| attributes['kind'].blank?}
end
```

方便起见，我们可以把 `:reject_if` 选项的值设为 `:all_blank`，此时创建的 Proc 对象会拒绝为除 `_destroy` 之外的其他属性都为空的属性散列创建关联对象。

<a class="anchor" id="adding-fields-on-the-fly"></a>

### 按需添加字段

有时，与其提前显示多组字段，倒不如等用户点击“添加新地址”按钮后再添加。Rails 没有内置这种功能。在生成这些字段时，我们必须保证关联数组的键是唯一的，这种情况下通常会使用 JavaScript 的当前时间（从 1970 年 1 月 1 日午夜开始经过的毫秒数）。
