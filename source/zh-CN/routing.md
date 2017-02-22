Rails 路由全解
==============

本文介绍 Rails 路由面向用户的特性。

读完本文后，您将学到：

- 如何理解 `config/routes.rb` 文件中的代码；

- 如何使用推荐的资源式风格或 `match` 方法构建路由；

- 控制器动作预期收到什么参数；

- 如何使用路由辅助方法自动创建路径和 URL 地址；

- 约束和 Rack 端点等高级技术。

Rails 路由的用途
----------------

Rails 路由能够识别 URL 地址，并把它们分派给控制器动作进行处理。它还能生成路径和 URL 地址，从而避免在视图中硬编码字符串。

### 把 URL 地址连接到代码

当 Rails 应用收到下面的请求时：

```ruby
GET /patients/17
```

会查询路由，找到匹配的控制器动作。如果第一个匹配的路由是：

```ruby
get '/patients/:id', to: 'patients#show'
```

该请求会被分派给 `patients` 控制器的 `show` 动作，同时把 `{ id: '17' }` 传入 `params`。

### 从代码生成路径和 URL 地址

Rails 路由还可以生成路径和 URL 地址。如果把上面的路由修改为：

```ruby
get '/patients/:id', to: 'patients#show', as: 'patient'
```

并且在控制器中包含下面的代码：

```ruby
@patient = Patient.find(17)
```

同时在对应的视图中包含下面的代码：

```erb
<%= link_to 'Patient Record', patient_path(@patient) %>
```

那么路由会生成路径 `/patients/17`。这种方式使视图代码更容易维护和理解。注意，在路由辅助方法中不需要指定 ID。

资源路由：Rails 的默认风格
--------------------------

资源路由（resource routing）允许我们为资源式控制器快速声明所有常见路由。只需一行代码即可完成资源路由的声明，无需为 `index`、`show`、`new`、`edit`、`create`、`update` 和 `destroy` 动作分别声明路由。

### 网络资源

浏览器使用特定的 HTTP 方法向 Rails 应用请求页面，例如 `GET`、`POST`、`PATCH`、`PUT` 和 `DELETE`。每个 HTTP 方法对应对资源的一种操作。资源路由会把多个相关请求映射到单个控制器的不同动作上。

当 Rails 应用收到下面的请求：

    DELETE /photos/17

会查询路由，并把请求映射到控制器动作上。如果第一个匹配的路由是：

```ruby
resources :photos
```

Rails 会把请求分派给 `photos` 控制器的 `destroy` 动作，并把 `{ id: '17' }` 传入 `params`。

### CRUD、HTTP 方法和控制器动作

在 Rails 中，资源路由把 HTTP 方法和 URL 地址映射到控制器动作上。按照约定，每个控制器动作也会映射到对应的数据库 CRUD 操作上。路由文件中的单行声明，例如：

```ruby
resources :photos
```

会在应用中创建 7 个不同的路由，这些路由都会映射到 `Photos` 控制器上。

| HTTP 方法 | 路径 | 控制器#动作 | 用途 |
|---------|----|--------|----|
| GET | /photos | photos#index | 显示所有照片的列表 |
| GET | /photos/new | photos#new | 返回用于新建照片的 HTML 表单 |
| POST | /photos | photos#create | 新建照片 |
| GET | /photos/:id | photos#show | 显示指定照片 |
| GET | /photos/:id/edit | photos#edit | 返回用于修改照片的 HTML 表单 |
| PATCH/PUT | /photos/:id | photos#update | 更新指定照片 |
| DELETE | /photos/:id | photos#destroy | 删除指定照片 |

NOTE: 因为路由使用 HTTP 方法和 URL 地址来匹配请求，所以 4 个 URL 地址会映射到 7 个不同的控制器动作上。

NOTE: Rails 路由按照声明顺序进行匹配。如果 `resources :photos` 声明在先，`get 'photos/poll'` 声明在后，那么由前者声明的 `show` 动作的路由会先于后者匹配。要想匹配 `get 'photos/poll'`，就必须将其移到 `resources :photos` 之前。

### 用于生成路径和 URL 地址的辅助方法

在创建资源路由时，会同时创建多个可以在控制器中使用的辅助方法。例如，在创建 `resources :photos` 路由时，会同时创建下面的辅助方法：

- `photos_path` 辅助方法，返回值为 `/photos`

- `new_photo_path` 辅助方法，返回值为 `/photos/new`

- `edit_photo_path(:id)` 辅助方法，返回值为 `/photos/:id/edit`（例如，`edit_photo_path(10)` 的返回值为 `/photos/10/edit`）

- `photo_path(:id)` 辅助方法，返回值为 `/photos/:id`（例如，`photo_path(10)` 的返回值为 `/photos/10`）

这些辅助方法都有对应的 `_url` 形式（例如 `photos_url`）。前者的返回值是路径，后者的返回值是路径加上由当前的主机名、端口和路径前缀组成的前缀。

### 同时定义多个资源

如果需要为多个资源创建路由，可以只调用一次 `resources` 方法，节约一点敲键盘的时间。

```ruby
resources :photos, :books, :videos
```

上面的代码等价于：

```ruby
resources :photos
resources :books
resources :videos
```

### 单数资源

有时我们希望不使用 ID 就能查找资源。例如，让 `/profile` 总是显示当前登录用户的个人信息。这种情况下，我们可以使用单数资源来把 `/profile` 而不是 `/profile/:id` 映射到 `show` 动作：

```ruby
get 'profile', to: 'users#show'
```

如果 `get` 方法的 `to` 选项的值是字符串，那么这个字符串应该使用 `controller#action` 格式。如果 `to` 选项的值是表示动作的符号，那么还需要使用 `controller` 选项指定控制器：

```ruby
get 'profile', to: :show, controller: 'users'
```

下面的资源路由：

```ruby
resource :geocoder
```

会在应用中创建 6 个不同的路由，这些路由会映射到 `Geocoders` 控制器的动作上：

| HTTP 方法 | 路径 | 控制器#动作 | 用途 |
|---------|----|--------|----|
| GET | /geocoder/new | geocoders#new | 返回用于创建 geocoder 的 HTML 表单 |
| POST | /geocoder | geocoders#create | 新建 geocoder |
| GET | /geocoder | geocoders#show | 显示唯一的 geocoder 资源 |
| GET | /geocoder/edit | geocoders#edit | 返回用于修改 geocoder 的 HTML 表单 |
| PATCH/PUT | /geocoder | geocoders#update | 更新唯一的 geocoder 资源 |
| DELETE | /geocoder | geocoders#destroy | 删除 geocoder 资源 |

NOTE: 有时我们想要用同一个控制器处理单数路由（如 `/account`）和复数路由（如 `/accounts/45`），也就是把单数资源映射到复数资源对应的控制器上。例如，`resource :photo` 创建的单数路由和 `resources :photos` 创建的复数路由都会映射到相同的 `Photos` 控制器上。

在创建单数资源路由时，会同时创建下面的辅助方法：

- `new_geocoder_path` 辅助方法，返回值是 `/geocoder/new`

- `edit_geocoder_path` 辅助方法，返回值是 `/geocoder/edit`

- `geocoder_path` 辅助方法，返回值是 `/geocoder`

和创建复数资源路由时一样，上面这些辅助方法都有对应的 `_url` 形式，其返回值也包含了主机名、端口和路径前缀。

WARNING: 有一个长期存在的缺陷使 `form_for` 辅助方法无法自动处理单数资源。有一个解决方案是直接指定表单 URL，例如：
>
> ``` ruby
> form_for @geocoder, url: geocoder_path do |f|
>
> # 为了行文简洁，省略以下内容
> ```

### 控制器命名空间和路由

有时我们会把一组控制器放入同一个命名空间中。最常见的例子，是把和管理相关的控制器放入 `Admin::` 命名空间中。为此，我们可以把控制器文件放在 `app/controllers/admin` 文件夹中，然后在路由文件中作如下声明：

```ruby
namespace :admin do
  resources :articles, :comments
end
```

上面的代码会为 `articles` 和 `comments` 控制器分别创建多个路由。对于 `Admin::Articles` 控制器，Rails 会创建下列路由：

| HTTP 方法 | 路径 | 控制器#动作 | 具名辅助方法 |
|---------|----|--------|--------|
| GET | /admin/articles | admin/articles#index | admin_articles_path |
| GET | /admin/articles/new | admin/articles#new | new_admin_article_path |
| POST | /admin/articles | admin/articles#create | admin_articles_path |
| GET | /admin/articles/:id | admin/articles#show | admin_article_path(:id) |
| GET | /admin/articles/:id/edit | admin/articles#edit | edit_admin_article_path(:id) |
| PATCH/PUT | /admin/articles/:id | admin/articles#update | admin_article_path(:id) |
| DELETE | /admin/articles/:id | admin/articles#destroy | admin_article_path(:id) |

如果想把 `/articles` 路径（不带 `/admin` 前缀） 映射到 `Admin::Articles` 控制器上，可以这样声明：

```ruby
scope module: 'admin' do
  resources :articles, :comments
end
```

对于单个资源的情况，还可以这样声明：

```ruby
resources :articles, module: 'admin'
```

如果想把 `/admin/articles` 路径映射到 `Articles` 控制器上（不带 `Admin::` 前缀），可以这样声明：

```ruby
scope '/admin' do
  resources :articles, :comments
end
```

对于单个资源的情况，还可以这样声明：

```ruby
resources :articles, path: '/admin/articles'
```

在上述各个例子中，不管是否使用了 `scope` 方法，具名路由都保持不变。在最后一个例子中，下列路径都会映射到 `Articles` 控制器上：

| HTTP 方法 | 路径 | 控制器#动作 | 具名辅助方法 |
|---------|----|--------|--------|
| GET | /admin/articles | articles#index | articles_path |
| GET | /admin/articles/new | articles#new | new_article_path |
| POST | /admin/articles | articles#create | articles_path |
| GET | /admin/articles/:id | articles#show | article_path(:id) |
| GET | /admin/articles/:id/edit | articles#edit | edit_article_path(:id) |
| PATCH/PUT | /admin/articles/:id | articles#update | article_path(:id) |
| DELETE | /admin/articles/:id | articles#destroy | article_path(:id) |

NOTE: 如果想在命名空间代码块中使用另一个控制器命名空间，可以指定控制器的绝对路径，例如 `get '/foo' => '/foo#index'`。

### 嵌套资源

有的资源是其他资源的子资源，这种情况很常见。例如，假设我们的应用中包含下列模型：

```ruby
class Magazine < ApplicationRecord
  has_many :ads
end

class Ad < ApplicationRecord
  belongs_to :magazine
end
```

通过嵌套路由，我们可以在路由中反映模型关联。在本例中，我们可以这样声明路由：

```ruby
resources :magazines do
  resources :ads
end
```

上面的代码不仅为 `magazines` 创建了路由，还创建了映射到 `Ads` 控制器的路由。在 `ad` 的 URL 地址中，需要指定对应的 `magazine` 的 ID：

| HTTP 方法 | 路径 | 控制器#动作 | 用途 |
|---------|----|--------|----|
| GET | /magazines/:magazine_id/ads | ads#index | 显示指定杂志的所有广告的列表 |
| GET | /magazines/:magazine_id/ads/new | ads#new | 返回为指定杂志新建广告的 HTML 表单 |
| POST | /magazines/:magazine_id/ads | ads#create | 为指定杂志新建广告 |
| GET | /magazines/:magazine_id/ads/:id | ads#show | 显示指定杂志的指定广告 |
| GET | /magazines/:magazine_id/ads/:id/edit | ads#edit | 返回用于修改指定杂志的广告的 HTML 表单 |
| PATCH/PUT | /magazines/:magazine_id/ads/:id | ads#update | 更新指定杂志的指定广告 |
| DELETE | /magazines/:magazine_id/ads/:id | ads#destroy | 删除指定杂志的指定广告 |

在创建路由的同时，还会创建 `magazine_ads_url` 和 `edit_magazine_ad_path` 等路由辅助方法。这些辅助方法以 `Magazine` 类的实例作为第一个参数，例如 `magazine_ads_url(@magazine)`。

#### 嵌套限制

我们可以在嵌套资源中继续嵌套资源。例如：

```ruby
resources :publishers do
  resources :magazines do
    resources :photos
  end
end
```

随着嵌套层级的增加，嵌套资源的处理会变得很困难。例如，下面这个路径：

```ruby
/publishers/1/magazines/2/photos/3
```

对应的路由辅助方法是 `publisher_magazine_photo_url`，需要指定三层对象。这种用法很容易就把人搞糊涂了，为此，Jamis Buck 在[一篇广为流传的文章](http://weblog.jamisbuck.org/2007/2/5/nesting-resources)中提出了使用嵌套路由的经验法则：

TIP: 嵌套资源的层级不应超过 1 层。

#### 浅层嵌套

如前文所述，避免深层嵌套（deep nesting）的方法之一，是把动作集合放在在父资源中，这样既可以表明层级关系，又不必嵌套成员动作。换句话说，只用最少的信息创建路由，同样可以唯一地标识资源，例如：

```ruby
resources :articles do
  resources :comments, only: [:index, :new, :create]
end
resources :comments, only: [:show, :edit, :update, :destroy]
```

这种方式在描述性路由（descriptive route）和深层嵌套之间取得了平衡。上面的代码还有简易写法，即使用 `:shallow` 选项：

```ruby
resources :articles do
  resources :comments, shallow: true
end
```

这两种写法创建的路由完全相同。我们还可以在父资源中使用 `:shallow` 选项，这样会在所有嵌套的子资源中应用 `:shallow` 选项：

```ruby
resources :articles, shallow: true do
  resources :comments
  resources :quotes
  resources :drafts
end
```

可以用 `shallow` 方法创建作用域，使其中的所有嵌套都成为浅层嵌套。通过这种方式创建的路由，仍然和上面的例子相同：

```ruby
shallow do
  resources :articles do
    resources :comments
    resources :quotes
    resources :drafts
  end
end
```

`scope` 方法有两个选项用于自定义浅层路由。`:shallow_path` 选项会为成员路径添加指定前缀：

```ruby
scope shallow_path: "sekret" do
  resources :articles do
    resources :comments, shallow: true
  end
end
```

上面的代码会为 `comments` 资源生成下列路由：

| HTTP 方法 | 路径 | 控制器#动作 | 具名辅助方法 |
|---------|----|--------|--------|
| GET | /articles/:article_id/comments(.:format) | comments#index | article_comments_path |
| POST | /articles/:article_id/comments(.:format) | comments#create | article_comments_path |
| GET | /articles/:article_id/comments/new(.:format) | comments#new | new_article_comment_path |
| GET | /sekret/comments/:id/edit(.:format) | comments#edit | edit_comment_path |
| GET | /sekret/comments/:id(.:format) | comments#show | comment_path |
| PATCH/PUT | /sekret/comments/:id(.:format) | comments#update | comment_path |
| DELETE | /sekret/comments/:id(.:format) | comments#destroy | comment_path |

`:shallow_prefix` 选项会为具名辅助方法添加指定前缀：

```ruby
scope shallow_prefix: "sekret" do
  resources :articles do
    resources :comments, shallow: true
  end
end
```

上面的代码会为 `comments` 资源生成下列路由：

| HTTP 方法 | 路径 | 控制器#动作 | 具名辅助方法 |
|---------|----|--------|--------|
| GET | /articles/:article_id/comments(.:format) | comments#index | article_comments_path |
| POST | /articles/:article_id/comments(.:format) | comments#create | article_comments_path |
| GET | /articles/:article_id/comments/new(.:format) | comments#new | new_article_comment_path |
| GET | /comments/:id/edit(.:format) | comments#edit | edit_sekret_comment_path |
| GET | /comments/:id(.:format) | comments#show | sekret_comment_path |
| PATCH/PUT | /comments/:id(.:format) | comments#update | sekret_comment_path |
| DELETE | /comments/:id(.:format) | comments#destroy | sekret_comment_path |

### 路由 concern

路由 concern 用于声明公共路由，公共路由可以在其他资源和路由中重复使用。定义路由 concern 的方式如下：

```ruby
concern :commentable do
  resources :comments
end

concern :image_attachable do
  resources :images, only: :index
end
```

我们可以在资源中使用已定义的路由 concern，以避免代码重复，并在路由间共享行为：

```ruby
resources :messages, concerns: :commentable

resources :articles, concerns: [:commentable, :image_attachable]
```

上面的代码等价于：

```ruby
resources :messages do
  resources :comments
end

resources :articles do
  resources :comments
  resources :images, only: :index
end
```

我们还可以在各种路由声明中使用已定义的路由 concern，例如在作用域或命名空间中：

```ruby
namespace :articles do
  concerns :commentable
end
```

### 从对象创建路径和 URL 地址

除了使用路由辅助方法，Rails 还可以从参数数组创建路径和 URL 地址。例如，假设有下面的路由：

```ruby
resources :magazines do
  resources :ads
end
```

在使用 `magazine_ad_path` 方法时，我们可以传入 `Magazine` 和 `Ad` 的实例，而不是数字 ID：

```erb
<%= link_to 'Ad details', magazine_ad_path(@magazine, @ad) %>
```

我们还可以在使用 `url_for` 方法时传入一组对象，Rails 会自动确定对应的路由：

```erb
<%= link_to 'Ad details', url_for([@magazine, @ad]) %>
```

在这种情况下，Rails 知道 `@magazine` 是 `Magazine` 的实例，而 `@ad` 是 `Ad` 的实例，因此会使用 `magazine_ad_path` 辅助方法。在使用 `link_to` 等辅助方法时，我们可以只指定对象，而不必完整调用 `url_for` 方法：

```erb
<%= link_to 'Ad details', [@magazine, @ad] %>
```

如果想链接到一本杂志，可以直接指定 `Magazine` 的实例：

```erb
<%= link_to 'Magazine details', @magazine %>
```

如果想链接到其他控制器动作，只需把动作名称作为第一个元素插入对象数组即可：

```erb
<%= link_to 'Edit Ad', [:edit, @magazine, @ad] %>
```

这样，我们就可以把模型实例看作 URL 地址，这是使用资源式风格最关键的优势之一。

### 添加更多 REST 式动作

我们可以使用的路由，并不仅限于 REST 式路由默认创建的那 7 个。我们可以根据需要添加其他路由，包括集合路由（collection route）和成员路由（member route）。

#### 添加成员路由

要添加成员路由，只需在 `resource` 块中添加 `member` 块：

```ruby
resources :photos do
  member do
    get 'preview'
  end
end
```

通过上述声明，Rails 路由能够识别 `/photos/1/preview` 路径上的 `GET` 请求，并把请求映射到 `Photos` 控制器的 `preview` 动作上，同时把资源 ID 传入 `params[:id]`，并创建 `preview_photo_url` 和 `preview_photo_path` 辅助方法。

在 `member` 块中，每个成员路由都要指定对应的 HTTP 方法，即 `get`、`patch`、`put`、`post` 或 `delete`。如果只有一个成员路由，我们就可以忽略 `member` 块，直接使用成员路由的 `:on` 选项。

```ruby
resources :photos do
  get 'preview', on: :member
end
```

如果不使用 `:on` 选项，创建的成员路由也是相同的，但资源 ID 就必须通过 `params[:photo_id]` 而不是 `params[:id]` 来获取了。

#### 添加集合路由

添加集合路由的方式如下：

```ruby
resources :photos do
  collection do
    get 'search'
  end
end
```

通过上述声明，Rails 路由能够识别 `/photos/search` 路径上的 `GET` 请求，并把请求映射到 `Photos` 控制器的 `search` 动作上，同时创建 `search_photos_url` 和 `search_photos_path` 辅助方法。

和成员路由一样，我们可以使用集合路由的 `:on` 选项：

```ruby
resources :photos do
  get 'search', on: :collection
end
```

#### 为附加的 `new` 动作添加路由

我们可以通过 `:on` 选项，为附加的 `new` 动作添加路由：

```ruby
resources :comments do
  get 'preview', on: :new
end
```

通过上述声明，Rails 路由能够识别 `/comments/new/preview` 路径上的 `GET` 请求，并把请求映射到 `Comments` 控制器的 `preview` 动作上，同时创建 `preview_new_comment_url` 和 `preview_new_comment_path` 辅助方法。

NOTE: 如果我们为资源路由添加了过多动作，就需要考虑一下，是不是应该声明新资源了。

非资源式路由
------------

除了资源路由之外，对于把任意 URL 地址映射到控制器动作的路由，Rails 也提供了强大的支持。和资源路由自动生成一系列路由不同，这时我们需要分别声明各个路由。

尽管我们通常会使用资源路由，但在一些情况下，使用简单路由更为合适。对于不适合使用资源路由的情况，我们也不必强迫自己使用资源路由。

对于把旧系统的 URL 地址映射到新 Rails 应用上的情况，简单路由特别适用。

### 绑定参数

在声明普通路由时，我们可以使用符号，将其作为 HTTP 请求的一部分。其中有两个特殊符号：`:controller` 会被映射到控制器的名称上，`:action` 会被映射到控制器动作的名称上。例如，下面的路由：

```ruby
get ':controller(/:action(/:id))'
```

在处理 `/photos/show/1` 请求时（假设这个路由是第一个匹配的路由），会把请求映射到 `Photos` 控制器的 `show` 动作上，并把参数 1 传入 `params[:id]`。而 `/photos` 请求，也会被这个路由映射到 `PhotosController#index` 上，因为 `:action` 和 `:id` 都在括号中，是可选参数。

### 动态片段

在声明普通路由时，我们可以根据需要使用多个动态片段（dynamic segment）。除了 `:controller` 和 `:action`，其他动态片段都会传入 `params`，以便在控制器动作中使用。例如，对于下面的路由：

```ruby
get ':controller/:action/:id/:user_id'
```

`/photos/show/1/2` 路径会被映射到 `Photos` 控制器的 `show` 动作上。此时，`params[:id]` 的值是 `"1"`，`params[:user_id]` 的值是 `"2"`。

NOTE: `:namespace` 或 `:module` 不能用作动态片段。如果需要这一功能，可以通过为控制器添加约束，来匹配所需的命名空间。例如：
>
> ``` ruby
> get ':controller(/:action(/:id))', controller: /admin\/[^\/]+/
> ```

TIP: 默认情况下，在动态片段中不能使用小圆点（`.`），因为小圆点是格式化路由（formatted route）的分隔符。如果想在动态片段中使用小圆点，可以通过添加约束来实现相同效果，例如，`id: /[^\/]+/` 可以匹配除斜线外的一个或多个字符。

### 静态片段

在创建路由时，我们可以用不带冒号的片段来指定静态片段（static segment）：

```ruby
get ':controller/:action/:id/with_user/:user_id'
```

这个路由可以响应像 `/photos/show/1/with_user/2` 这样的路径，此时，`params` 的值为 `{ controller: 'photos', action: 'show', id: '1', user_id: '2' }`。

### 查询字符串

`params` 也包含了查询字符串中的所有参数。例如，对于下面的路由：

```ruby
get ':controller/:action/:id'
```

`/photos/show/1?user_id=2` 路径会被映射到 `Photos` 控制器的 `show` 动作上，此时，`params` 的值是 `{ controller: 'photos', action: 'show', id: '1', user_id: '2' }`。

### 定义默认值

通过定义默认值，我们可以避免在路由声明中显式使用 `:controller` 和 `:action` 符号：

```ruby
get 'photos/:id', to: 'photos#show'
```

这个路由会把 `/photos/12` 路径映射到 `Photos` 控制器的 `show` 动作上。

在路由声明中，我们还可以使用 `:defaults` 选项（其值为散列）定义更多默认值。对于未声明为动态片段的参数，也可以使用 `:defaults` 选项。例如：

```ruby
get 'photos/:id', to: 'photos#show', defaults: { format: 'jpg' }
```

这个路由会把 `photos/12` 路径映射到 `Photos` 控制器的 `show` 动作上，并把 `params[:format]` 的值设置为 `"jpg"`。

NOTE: 出于安全考虑，Rails 不允许用查询参数来覆盖默认值。只有一种情况下可以覆盖默认值，即通过 URL 路径替换来覆盖动态片段。

### 为路由命名

通过 `:as` 选项，我们可以为路由命名：

```ruby
get 'exit', to: 'sessions#destroy', as: :logout
```

这个路由声明会创建 `logout_path` 和 `logout_url` 具名辅助方法。其中，`logout_path` 辅助方法的返回值是 `/exit`。

通过为路由命名，我们还可以覆盖由资源路由定义的路由辅助方法，例如：

```ruby
get ':username', to: 'users#show', as: :user
```

这个路由声明会定义 `user_path` 辅助方法，此方法可以在控制器、辅助方法和视图中使用，其返回值类似 `/bob`。在 `Users` 控制器的 `show` 动作中，`params[:username]` 的值是用户名。如果不想使用 `:username` 作为参数名，可以在路由声明中把 `:username` 改为其他名字。

### HTTP 方法约束

通常，我们应该使用 `get`、`post`、`put`、`patch` 和 `delete` 方法来约束路由可以匹配的 HTTP 方法。通过使用 `match` 方法和 `:via` 选项，我们可以一次匹配多个 HTTP 方法：

```ruby
match 'photos', to: 'photos#show', via: [:get, :post]
```

通过 `via: :all` 选项，路由可以匹配所有 HTTP 方法：

```ruby
match 'photos', to: 'photos#show', via: :all
```

NOTE: 把 `GET` 和 `POST` 请求映射到同一个控制器动作上会带来安全隐患。通常，除非有足够的理由，我们应该避免把使用不同 HTTP 方法的所有请求映射到同一个控制器动作上。

NOTE: Rails 在处理 `GET` 请求时不会检查 CSRF 令牌。在处理 `GET` 请求时绝对不可以对数据库进行写操作，更多介绍请参阅 [安全指南](security.html#CSRF 对策)。

### 片段约束

我们可以使用 `:constraints` 选项来约束动态片段的格式：

```ruby
get 'photos/:id', to: 'photos#show', constraints: { id: /[A-Z]\d{5}/ }
```

这个路由会匹配 `/photos/A12345` 路径，但不会匹配 `/photos/893` 路径。此路由还可以简写为：

```ruby
get 'photos/:id', to: 'photos#show', id: /[A-Z]\d{5}/
```

`:constraints` 选项的值可以是正则表达式，但不能使用 `^` 符号。例如，下面的路由写法是错误的：

```ruby
get '/:id', to: 'articles#show', constraints: { id: /^\d/ }
```

其实，使用 `^` 符号也完全没有必要，因为路由总是从头开始匹配。

例如，对于下面的路由，`/1-hello-world` 路径会被映射到 `articles#show` 上，而 `/david` 路径会被映射到 `users#show` 上：

```ruby
get '/:id', to: 'articles#show', constraints: { id: /\d.+/ }
get '/:username', to: 'users#show'
```

### 请求约束

如果在[请求对象](action_controller_overview.xml#the-request-object)上调用某个方法的返回值是字符串，我们就可以用这个方法来约束路由。

请求约束和片段约束的用法相同：

```ruby
get 'photos', to: 'photos#index', constraints: { subdomain: 'admin' }
```

我们还可以用块来指定约束：

```ruby
namespace :admin do
  constraints subdomain: 'admin' do
    resources :photos
  end
end
```

NOTE: 请求约束（request constraint）的工作原理，是在[请求对象](action_controller_overview.xml#the-request-object)上调用和约束条件中散列的键同名的方法，然后比较返回值和散列的值。因此，约束中散列的值和调用方法返回的值的类型应当相同。例如，`constraints: { subdomain: 'api' }` 会匹配 `api` 子域名，但是 `constraints: { subdomain: :api }` 不会匹配 `api` 子域名，因为后者散列的值是符号，而 `request.subdomain` 方法的返回值 `'api'` 是字符串。

NOTE: 格式约束（format constraint）是一个例外：尽管格式约束是在请求对象上调用的方法，但同时也是路径的隐式可选参数（implicit optional parameter）。片段约束的优先级高于格式约束，而格式约束在通过散列指定时仅作为隐式可选参数。例如，`get 'foo', constraints: { format: 'json' }` 路由会匹配 `GET  /foo` 请求，因为默认情况下格式约束是可选的。尽管如此，我们可以[使用 lambda](#高级约束)，例如，`get 'foo', constraints: lambda { |req| req.format == :json }` 路由只匹配显式 JSON 请求。

### 高级约束

如果需要更复杂的约束，我们可以使用能够响应 `matches?` 方法的对象作为约束。假设我们想把所有黑名单用户映射到 `Blacklist` 控制器，可以这么做：

```ruby
class BlacklistConstraint
  def initialize
    @ips = Blacklist.retrieve_ips
  end

  def matches?(request)
    @ips.include?(request.remote_ip)
  end
end

Rails.application.routes.draw do
  get '*path', to: 'blacklist#index',
    constraints: BlacklistConstraint.new
end
```

我们还可以用 lambda 来指定约束：

```ruby
Rails.application.routes.draw do
  get '*path', to: 'blacklist#index',
    constraints: lambda { |request| Blacklist.retrieve_ips.include?(request.remote_ip) }
end
```

在上面两段代码中，`matches?` 方法和 lambda 都是把请求对象作为参数。

### 路由通配符和通配符片段

路由通配符用于指定特殊参数，这一参数会匹配路由的所有剩余部分。例如：

```ruby
get 'photos/*other', to: 'photos#unknown'
```

这个路由会匹配 `photos/12` 和 `/photos/long/path/to/12` 路径，并把 `params[:other]` 分别设置为 `"12"` 和 `"long/path/to/12"`。像 `*other` 这样以星号开头的片段，称作“通配符片段”。

通配符片段可以出现在路由中的任何位置。例如：

```ruby
get 'books/*section/:title', to: 'books#show'
```

这个路由会匹配 `books/some/section/last-words-a-memoir` 路径，此时，`params[:section]` 的值是 `'some/section'`，`params[:title]` 的值是 `'last-words-a-memoir'`。

严格来说，路由中甚至可以有多个通配符片段，其匹配方式也非常直观。例如：

```ruby
get '*a/foo/*b', to: 'test#index'
```

会匹配 `zoo/woo/foo/bar/baz` 路径，此时，`params[:a]` 的值是 `'zoo/woo'`，`params[:b]` 的值是 `'bar/baz'`。

NOTE: `get '*pages', to: 'pages#show'` 路由在处理 `'/foo/bar.json'` 请求时，`params[:pages]` 的值是 `'foo/bar'`，请求格式（request format）是 `JSON`。如果想让 Rails 按 `3.0.x` 版本的方式进行匹配，可以使用 `format: false` 选项，例如：
>
> ``` ruby
> get '*pages', to: 'pages#show', format: false
> ```
>
> 如果想强制使用格式约束，或者说让格式约束不再是可选的，我们可以使用 `format: true` 选项，例如：
>
> ``` ruby
> get '*pages', to: 'pages#show', format: true
> ```

### 重定向

在路由中，通过 `redirect` 辅助方法可以把一个路径重定向到另一个路径：

```ruby
get '/stories', to: redirect('/articles')
```

在重定向的目标路径中，可以使用源路径中的动态片段：

```ruby
get '/stories/:name', to: redirect('/articles/%{name}')
```

我们还可以重定向到块，这个块可以接受符号化的路径参数和请求对象：

```ruby
get '/stories/:name', to: redirect { |path_params, req| "/articles/#{path_params[:name].pluralize}" }
get '/stories', to: redirect { |path_params, req| "/articles/#{req.subdomain}" }
```

请注意，`redirect` 重定向默认是 301 永久重定向，有些浏览器或代理服务器会缓存这种类型的重定向，从而导致无法访问重定向前的网页。为了避免这种情况，我们可以使用 `:status` 选项修改响应状态：

```ruby
get '/stories/:name', to: redirect('/articles/%{name}', status: 302)
```

在重定向时，如果不指定主机（例如 http://www.example.com），Rails 会使用当前请求的主机。

### 映射到 Rack 应用的路由

在声明路由时，我们不仅可以使用字符串，例如映射到 `Articles` 控制器的 `index` 动作的 `'articles#index'`，还可以指定 [Rack 应用](rails_on_rack.xml#rails-on-rack)为端点：

```ruby
match '/application.js', to: MyRackApp, via: :all
```

只要 `MyRackApp` 应用能够响应 `call` 方法并返回 `[status, headers, body]` 数组，对于路由来说，Rack 应用和控制器动作就没有区别。`via: :all` 选项使 Rack 应用可以处理所有 HTTP 方法。

NOTE: 实际上，`'articles#index'` 会被展开为 `ArticlesController.action(:index)`，其返回值正是一个 Rack 应用。

记住，路由所匹配的路径，就是 Rack 应用接收的路径。例如，对于下面的路由，Rack 应用接收的路径是 `/admin`：

```ruby
match '/admin', to: AdminApp, via: :all
```

如果想让 Rack 应用接收根路径上的请求，可以使用 `mount` 方法：

```ruby
mount AdminApp, at: '/admin'
```

### 使用 `root` 方法

`root` 方法指明如何处理根路径（`/`）上的请求：

```ruby
root to: 'pages#main'
root 'pages#main' # 上一行代码的简易写法
```

`root` 路由应该放在路由文件的顶部，因为最常用的路由应该首先匹配。

NOTE: `root` 路由只处理 `GET` 请求。

我们还可以在命名空间和作用域中使用 `root` 方法，例如：

```ruby
namespace :admin do
  root to: "admin#index"
end

root to: "home#index"
```

### Unicode 字符路由

在声明路由时，可以直接使用 Unicode 字符，例如：

```ruby
get 'こんにちは', to: 'welcome#index'
```

自定义资源路由
--------------

尽管 `resources :articles` 默认生成的路由和辅助方法通常都能很好地满足需求，但是也有一些情况下我们需要自定义资源路由。Rails 允许我们通过各种方式自定义资源式辅助方法（resourceful helper）。

### 指定控制器

`:controller` 选项用于显式指定资源使用的控制器，例如：

```ruby
resources :photos, controller: 'images'
```

这个路由会把 `/photos` 路径映射到 `Images` 控制器上：

| HTTP 方法 | 路径 | 控制器#动作 | 具名辅助方法 |
|---------|----|--------|--------|
| GET | /photos | images#index | photos_path |
| GET | /photos/new | images#new | new_photo_path |
| POST | /photos | images#create | photos_path |
| GET | /photos/:id | images#show | photo_path(:id) |
| GET | /photos/:id/edit | images#edit | edit_photo_path(:id) |
| PATCH/PUT | /photos/:id | images#update | photo_path(:id) |
| DELETE | /photos/:id | images#destroy | photo_path(:id) |

NOTE: 请使用 `photos_path`、`new_photo_path` 等辅助方法为资源生成路径。

对于命名空间中的控制器，我们可以使用目录表示法（directory notation）。例如：

```ruby
resources :user_permissions, controller: 'admin/user_permissions'
```

这个路由会映射到 `Admin::UserPermissions` 控制器。

NOTE: 在这种情况下，我们只能使用目录表示法。如果我们使用 Ruby 的常量表示法（constant notation），例如 `controller: 'Admin::UserPermissions'`，有可能导致路由错误，而使 Rails 显示警告信息。

### 指定约束

`:constraints` 选项用于指定隐式 ID 必须满足的格式要求。例如：

```ruby
resources :photos, constraints: { id: /[A-Z][A-Z][0-9]+/ }
```

这个路由声明使用正则表达式来约束 `:id` 参数。此时，路由将不会匹配 `/photos/1` 路径，但会匹配 `/photos/RR27` 路径。

我们可以通过块把一个约束应用于多个路由：

```ruby
constraints(id: /[A-Z][A-Z][0-9]+/) do
  resources :photos
  resources :accounts
end
```

NOTE: 当然，在这种情况下，我们也可以使用非资源路由的高级约束。

TIP: 默认情况下，在 `:id` 参数中不能使用小圆点，因为小圆点是格式化路由的分隔符。如果想在 `:id` 参数中使用小圆点，可以通过添加约束来实现相同效果，例如，`id: /[^\/]+/` 可以匹配除斜线外的一个或多个字符。

### 覆盖具名路由辅助方法

通过 `:as` 选项，我们可以覆盖具名路由辅助方法的默认名称。例如：

```ruby
resources :photos, as: 'images'
```

这个路由会把以 `/photos` 开头的路径映射到 `Photos` 控制器上，同时通过 `:as` 选项设置具名辅助方法的名称。

| HTTP 方法 | 路径 | 控制器#动作 | 具名辅助方法 |
|---------|----|--------|--------|
| GET | /photos | photos#index | images_path |
| GET | /photos/new | photos#new | new_image_path |
| POST | /photos | photos#create | images_path |
| GET | /photos/:id | photos#show | image_path(:id) |
| GET | /photos/:id/edit | photos#edit | edit_image_path(:id) |
| PATCH/PUT | /photos/:id | photos#update | image_path(:id) |
| DELETE | /photos/:id | photos#destroy | image_path(:id) |

### 覆盖 `new` 和 `edit` 片段

`:path_names` 选项用于覆盖路径中自动生成的 `new` 和 `edit` 片段，例如：

```ruby
resources :photos, path_names: { new: 'make', edit: 'change' }
```

这个路由能够识别下面的路径：

    /photos/make
    /photos/1/change

NOTE: `:path_names` 选项不会改变控制器动作的名称，上面这两个路径仍然被分别映射到 `new` 和 `edit` 动作上。

TIP: 通过作用域，我们可以对所有路由应用 `:path_names` 选项。

```ruby
scope path_names: { new: 'make' } do
  # 其余路由
end
```

### 为具名路由辅助方法添加前缀

通过 `:as` 选项，我们可以为具名路由辅助方法添加前缀。通过在作用域中使用 `:as` 选项，我们可以解决路由名称冲突的问题。例如：

```ruby
scope 'admin' do
  resources :photos, as: 'admin_photos'
end

resources :photos
```

上述路由声明会生成 `admin_photos_path`、`new_admin_photo_path` 等辅助方法。

通过在作用域中使用 `:as` 选项，我们可以为一组路由辅助方法添加前缀：

```ruby
scope 'admin', as: 'admin' do
  resources :photos, :accounts
end

resources :photos, :accounts
```

上述路由会生成 `admin_photos_path`、`admin_accounts_path` 等辅助方法，其返回值分别为 `/admin/photos`、`/admin/accounts` 等。

NOTE: `namespace` 作用域除了添加 `:as` 选项指定的前缀，还会添加 `:module` 和 `:path` 前缀。

我们还可以使用具名参数指定路由前缀，例如：

```ruby
scope ':username' do
  resources :articles
end
```

这个路由能够识别 `/bob/articles/1` 路径，此时，在控制器、辅助方法和视图中，我们可以使用 `params[:username]` 获取路径中的 `username` 部分，即 `bob`。

### 限制所创建的路由

默认情况下，Rails 会为每个 REST 式路由创建 7 个默认动作（`index`、`show`、`new`、`create`、`edit`、`update` 和 `destroy`）。我们可以使用 `:only` 和 `:except` 选项来微调此行为。`:only` 选项用于指定想要生成的路由：

```ruby
resources :photos, only: [:index, :show]
```

此时，`/photos` 路径上的 `GET` 请求会成功，而 `POST` 请求会失败，因为后者会被映射到 `create` 动作上。

`:except` 选项用于指定不想生成的路由：

```ruby
resources :photos, except: :destroy
```

此时，Rails 会创建除 `destroy` 之外的所有路由，因此 `/photos/:id` 路径上的 `DELETE` 请求会失败。

TIP: 如果应用中有很多资源式路由，通过 `:only` 和 `:except` 选项，我们可以只生成实际需要的路由，这样可以减少内存使用、加速路由处理过程。

### 本地化路径

在使用 `scope` 方法时，我们可以修改 `resources` 方法生成的路径名称。例如：

```ruby
scope(path_names: { new: 'neu', edit: 'bearbeiten' }) do
  resources :categories, path: 'kategorien'
end
```

Rails 会生成下列映射到 `Categories` 控制器的路由：

| HTTP 方法 | 路径 | 控制器#动作 | 具名辅助方法 |
|---------|----|--------|--------|
| GET | /kategorien | categories#index | categories_path |
| GET | /kategorien/neu | categories#new | new_category_path |
| POST | /kategorien | categories#create | categories_path |
| GET | /kategorien/:id | categories#show | category_path(:id) |
| GET | /kategorien/:id/bearbeiten | categories#edit | edit_category_path(:id) |
| PATCH/PUT | /kategorien/:id | categories#update | category_path(:id) |
| DELETE | /kategorien/:id | categories#destroy | category_path(:id) |

### 覆盖资源的单数形式

通过为 `Inflector` 添加附加的规则，我们可以定义资源的单数形式。例如：

```ruby
ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'tooth', 'teeth'
end
```

### 在嵌套资源中使用 `:as` 选项

在嵌套资源中，我们可以使用 `:as` 选项覆盖自动生成的辅助方法名称。例如：

```ruby
resources :magazines do
  resources :ads, as: 'periodical_ads'
end
```

会生成 `magazine_periodical_ads_url` 和 `edit_magazine_periodical_ad_path` 等辅助方法。

### 覆盖具名路由的参数

`:param` 选项用于覆盖默认的资源标识符 `:id`（用于生成路由的动态片段的名称）。在控制器中，我们可以通过 `params[<:param>]` 访问资源标识符。

```ruby
resources :videos, param: :identifier
```

    videos GET  /videos(.:format)                  videos#index
           POST /videos(.:format)                  videos#create
    new_videos GET  /videos/new(.:format)              videos#new
    edit_videos GET  /videos/:identifier/edit(.:format) videos#edit

```ruby
Video.find_by(identifier: params[:identifier])
```

通过覆盖相关模型的 `ActiveRecord::Base#to_param` 方法，我们可以构造 URL 地址：

```ruby
class Video < ApplicationRecord
  def to_param
    identifier
  end
end

video = Video.find_by(identifier: "Roman-Holiday")
edit_videos_path(video) # => "/videos/Roman-Holiday"
```

审查和测试路由
--------------

Rails 提供了路由检查和测试的相关功能。

### 列出现有路由

要想得到应用中现有路由的完整列表，可以在开发环境中运行服务器，然后在浏览器中访问 http://localhost:3000/rails/info/routes。在终端中执行 `rails routes` 命令，也会得到相同的输出结果。

这两种方式都会按照路由在 `config/routes.rb` 文件中的声明顺序，列出所有路由。每个路由都包含以下信息：

- 路由名称（如果有的话）

- 所使用的 HTTP 方法（如果路由不响应所有的 HTTP 方法）

- 所匹配的 URL 模式

- 路由参数

例如，下面是执行 `rails routes` 命令后，REST 式路由的一部分输出结果：

        users GET    /users(.:format)          users#index
              POST   /users(.:format)          users#create
     new_user GET    /users/new(.:format)      users#new
    edit_user GET    /users/:id/edit(.:format) users#edit

可以使用 `grep` 选项（即 `-g`）搜索路由。只要路由的 URL 辅助方法的名称、HTTP 方法或 URL 路径中有部分匹配，该路由就会显示在搜索结果中。

```sh
$ bin/rails routes -g new_comment
$ bin/rails routes -g POST
$ bin/rails routes -g admin
```

要想查看映射到指定控制器的路由，可以使用 `-c` 选项。

```sh
$ bin/rails routes -c users
$ bin/rails routes -c admin/users
$ bin/rails routes -c Comments
$ bin/rails routes -c Articles::CommentsController
```

TIP: 为了增加 `rails routes` 命令输出结果的可读性，可以增加终端窗口的宽度，避免输出结果折行。

### 测试路由

路由和应用的其他部分一样，也应该包含在测试策略中。为了简化路由测试，Rails 提供了三个[内置断言](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html)：

- `assert_generates` 断言

- `assert_recognizes` 断言

- `assert_routing` 断言

#### `assert_generates` 断言

`assert_generates` 断言的功能是断定所指定的一组选项会生成指定路径，它可以用于默认路由或自定义路由。例如：

```ruby
assert_generates '/photos/1', { controller: 'photos', action: 'show', id: '1' }
assert_generates '/about', controller: 'pages', action: 'about'
```

#### `assert_recognizes` 断言

`assert_recognizes` 断言和 `assert_generates` 断言的功能相反，它断定所提供的路径能够被路由识别并映射到指定控制器动作。例如：

```ruby
assert_recognizes({ controller: 'photos', action: 'show', id: '1' }, '/photos/1')
```

我们可以通过 `:method` 参数指定 HTTP 方法：

```ruby
assert_recognizes（{controller：'photos'，action：'create'}，{path：'photos'，method：：post}）
```

#### `assert_routing` 断言

`assert_routing` 断言会对路由进行双向测试：既测试路径能否生成选项，也测试选项能否生成路径。也就是集 `assert_generates` 和 `assert_recognizes` 这两种断言的功能于一身。

```ruby
assert_routing({ path: 'photos', method: :post }, { controller: 'photos', action: 'create' })
```
