Rails 路由全解
=============

本文介绍面向用户的 Rails 路由功能。

读完后，你将学会：

* 如何理解 `routes.rb` 文件中的代码；
* 如何使用推荐的资源式，或使用 `match` 方法编写路由；
* 动作能接收到什么参数；
* 如何使用路由帮助方法自动创建路径和 URL；
* 约束和 Rack 端点等高级技术；

--------------------------------------------------------------------------------

Rails 路由的作用
---------------

Rails 路由能识别 URL，将其分发给控制器的动作进行处理，还能生成路径和 URL，无需直接在视图中硬编码字符串。

### 把 URL 和代码连接起来

Rails 程序收到如下请求时

```
GET /patients/17
```

会查询路由，找到匹配的控制器动作。如果首个匹配的路由是：

```ruby
get '/patients/:id', to: 'patients#show'
```

那么这个请求就交给 `patients` 控制器的 `show` 动作处理，并把 `{ id: '17' }` 传入 `params`。

### 生成路径和 URL

通过路由还可生成路径和 URL。如果把前面的路由修改成：

```ruby
get '/patients/:id', to: 'patients#show', as: 'patient'
```

在控制器中有如下代码：

```ruby
@patient = Patient.find(17)
```

在相应的视图中有如下代码：

```erb
<%= link_to 'Patient Record', patient_path(@patient) %>
```

那么路由就会生成路径 `/patients/17`。这么做代码易于维护、理解。注意，在路由帮助方法中无需指定 ID。

资源路径：Rails 的默认值
----------------------

使用资源路径可以快速声明资源式控制器所有的常规路由，无需分别为 `index`、`show`、`new`、`edit`、`create`、`update` 和 `destroy` 动作分别声明路由，只需一行代码就能搞定。

### 网络中的资源

浏览器向 Rails 程序请求页面时会使用特定的 HTTP 方法，例如 `GET`、`POST`、`PATCH`、`PUT` 和 `DELETE`。每个方法对应对资源的一种操作。资源路由会把一系列相关请求映射到单个路由器的不同动作上。

如果 Rails 程序收到如下请求：

```
DELETE /photos/17
```

会查询路由将其映射到一个控制器的路由上。如果首个匹配的路由是：

```ruby
resources :photos
```

那么这个请求就交给 `photos` 控制器的 `destroy` 方法处理，并把 `{ id: '17' }` 传入 `params`。

### CRUD，HTTP 方法和动作

在 Rails 中，资源式路由把 HTTP 方法和 URL 映射到控制器的动作上。而且根据约定，还映射到数据库的 CRUD 操作上。路由文件中如下的单行声明：

```ruby
resources :photos
```

会创建七个不同的路由，全部映射到 `Photos` 控制器上：

| HTTP 方法 | 路径             | 控制器#动作       | 作用                                         |
|-----------|------------------|-------------------|----------------------------------------------|
| GET       | /photos          | photos#index      | 显示所有图片                                 |
| GET       | /photos/new      | photos#new        | 显示新建图片的表单                           |
| POST      | /photos          | photos#create     | 新建图片                                     |
| GET       | /photos/:id      | photos#show       | 显示指定的图片                               |
| GET       | /photos/:id/edit | photos#edit       | 显示编辑图片的表单                           |
| PATCH/PUT | /photos/:id      | photos#update     | 更新指定的图片                               |
| DELETE    | /photos/:id      | photos#destroy    | 删除指定的图片                               |

NOTE: 路由使用 HTTP 方法和 URL 匹配请求，把四个 URL 映射到七个不同的动作上。
I>
NOTE: 路由按照声明的顺序匹配哦，如果在 `get 'photos/poll'` 之前声明了 `resources :photos`，那么 `show` 动作的路由由 `resources` 这行解析。如果想使用 `get` 这行，就要将其移到 `resources` 之前。

### 路径和 URL 帮助方法

声明资源式路由后，会自动创建一些帮助方法。以 `resources :photos` 为例：

* `photos_path` 返回 `/photos`
* `new_photo_path` 返回 `/photos/new`
* `edit_photo_path(:id)` 返回 `/photos/:id/edit`，例如 `edit_photo_path(10)` 返回 `/photos/10/edit`
* `photo_path(:id)` 返回 `/photos/:id`，例如 `photo_path(10)` 返回 `/photos/10`

这些帮助方法都有对应的 `_url` 形式，例如 `photos_url`，返回主机、端口加路径。

### 一次声明多个资源路由

如果需要为多个资源声明路由，可以节省一点时间，调用一次 `resources` 方法完成：

```ruby
resources :photos, :books, :videos
```

这种方式等价于：

```ruby
resources :photos
resources :books
resources :videos
```

### 单数资源

有时希望不用 ID 就能查看资源，例如，`/profile` 一直显示当前登入用户的个人信息。针对这种需求，可以使用单数资源，把 `/profile`（不是 `/profile/:id`）映射到 `show` 动作：

```ruby
get 'profile', to: 'users#show'
```

如果 `get` 方法的 `to` 选项是字符串，要使用 `controller#action` 形式；如果是 Symbol，就可以直接指定动作：

```ruby
get 'profile', to: :show
```

下面这个资源式路由：

```ruby
resource :geocoder
```

会生成六个路由，全部映射到 `Geocoders` 控制器：

| HTTP 方法 | 路径           | 控制器#动作       | 作用                                          |
|-----------|----------------|-------------------|-----------------------------------------------|
| GET       | /geocoder/new  | geocoders#new     | 显示新建 geocoder 的表单                      |
| POST      | /geocoder      | geocoders#create  | 新建 geocoder                                 |
| GET       | /geocoder      | geocoders#show    | 显示唯一的 geocoder 资源                      |
| GET       | /geocoder/edit | geocoders#edit    | 显示编辑 geocoder 的表单                      |
| PATCH/PUT | /geocoder      | geocoders#update  | 更新唯一的 geocoder 资源                      |
| DELETE    | /geocoder      | geocoders#destroy | 删除 geocoder 资源                            |

NOTE: 有时需要使用同个控制器处理单数路由（例如 `/account`）和复数路由（例如 `/accounts/45`），把单数资源映射到复数控制器上。例如，`resource :photo` 和 `resources :photos` 分别声明单数和复数路由，映射到同个控制器（`PhotosController`）上。

单数资源式路由生成以下帮助方法：

* `new_geocoder_path` 返回 `/geocoder/new`
* `edit_geocoder_path` 返回 `/geocoder/edit`
* `geocoder_path` 返回 `/geocoder`

和复数资源一样，上面各帮助方法都有对应的 `_url` 形式，返回主机、端口加路径。

WARNING: 有个一直存在的问题导致 `form_for` 无法自动处理单数资源。为了解决这个问题，可以直接指定表单的 URL，例如：

```ruby
form_for @geocoder, url: geocoder_path do |f|
```

### 控制器命名空间和路由

你可能想把一系列控制器放在一个命名空间内，最常见的是把管理相关的控制器放在 `Admin::` 命名空间内。你需要把这些控制器存在 `app/controllers/admin` 文件夹中，然后在路由中做如下声明：

```ruby
namespace :admin do
  resources :posts, :comments
end
```

上述代码会为 `posts` 和 `comments` 控制器生成很多路由。对 `Admin::PostsController` 来说，Rails 会生成：

| HTTP 方法 | 路径                  | 控制器#动作         | 具名帮助方法              |
|-----------|-----------------------|---------------------|---------------------------|
| GET       | /admin/posts          | admin/posts#index   | admin_posts_path          |
| GET       | /admin/posts/new      | admin/posts#new     | new_admin_post_path       |
| POST      | /admin/posts          | admin/posts#create  | admin_posts_path          |
| GET       | /admin/posts/:id      | admin/posts#show    | admin_post_path(:id)      |
| GET       | /admin/posts/:id/edit | admin/posts#edit    | edit_admin_post_path(:id) |
| PATCH/PUT | /admin/posts/:id      | admin/posts#update  | admin_post_path(:id)      |
| DELETE    | /admin/posts/:id      | admin/posts#destroy | admin_post_path(:id)      |

如果想把 `/posts`（前面没有 `/admin`）映射到 `Admin::PostsController` 控制器上，可以这么声明：

```ruby
scope module: 'admin' do
  resources :posts, :comments
end
```

如果只有一个资源，还可以这么声明：

```ruby
resources :posts, module: 'admin'
```

如果想把 `/admin/posts` 映射到 `PostsController` 控制器（不在 `Admin::` 命名空间内），可以这么声明：

```ruby
scope '/admin' do
  resources :posts, :comments
end
```

如果只有一个资源，还可以这么声明：

```ruby
resources :posts, path: '/admin/posts'
```

在上述两种用法中，具名路由没有变化，跟不用 `scope` 时一样。在后一种用法中，映射到 `PostsController` 控制器上的路径如下：

| HTTP 方法 | 路径                  | 控制器#动作       | 具名帮助方法        |
|-----------|-----------------------|-------------------|---------------------|
| GET       | /admin/posts          | posts#index       | posts_path          |
| GET       | /admin/posts/new      | posts#new         | new_post_path       |
| POST      | /admin/posts          | posts#create      | posts_path          |
| GET       | /admin/posts/:id      | posts#show        | post_path(:id)      |
| GET       | /admin/posts/:id/edit | posts#edit        | edit_post_path(:id) |
| PATCH/PUT | /admin/posts/:id      | posts#update      | post_path(:id)      |
| DELETE    | /admin/posts/:id      | posts#destroy     | post_path(:id)      |

TIP: 如果在 `namespace` 代码块中想使用其他的控制器命名空间，可以指定控制器的绝对路径，例如 `get '/foo' => '/foo#index'`。

### 嵌套资源

开发程序时经常会遇到一个资源是其他资源的子资源这种情况。假设程序中有如下的模型：

```ruby
class Magazine < ActiveRecord::Base
  has_many :ads
end

class Ad < ActiveRecord::Base
  belongs_to :magazine
end
```

在路由中可以使用“嵌套路由”反应这种关系。针对这个例子，可以声明如下路由：

```ruby
resources :magazines do
  resources :ads
end
```

除了创建 `MagazinesController` 的路由之外，上述声明还会创建 `AdsController` 的路由。广告的 URL 要用到杂志资源：

| HTTP 方法 | 路径                                 | 控制器#动作       | 作用                                     |
|-----------|--------------------------------------|-------------------|------------------------------------------|
| GET       | /magazines/:magazine_id/ads          | ads#index         | 显示指定杂志的所有广告                   |
| GET       | /magazines/:magazine_id/ads/new      | ads#new           | 显示新建广告的表单，该告属于指定的杂志   |
| POST      | /magazines/:magazine_id/ads          | ads#create        | 创建属于指定杂志的广告                   |
| GET       | /magazines/:magazine_id/ads/:id      | ads#show          | 显示属于指定杂志的指定广告               |
| GET       | /magazines/:magazine_id/ads/:id/edit | ads#edit          | 显示编辑广告的表单，该广告属于指定的杂志 |
| PATCH/PUT | /magazines/:magazine_id/ads/:id      | ads#update        | 更新属于指定杂志的指定广告               |
| DELETE    | /magazines/:magazine_id/ads/:id      | ads#destroy       | 删除属于指定杂志的指定广告               |

上述路由还会生成 `magazine_ads_url` 和 `edit_magazine_ad_path` 等路由帮助方法。这些帮助方法的第一个参数是 `Magazine` 实例，例如 `magazine_ads_url(@magazine)`。

#### 嵌套限制

嵌套路由可以放在其他嵌套路由中，例如：

```ruby
resources :publishers do
  resources :magazines do
    resources :photos
  end
end
```

层级较多的嵌套路由很难处理。例如，程序可能要识别如下的路径：

```
/publishers/1/magazines/2/photos/3
```

对应的路由帮助方法是 `publisher_magazine_photo_url`，要指定三个层级的对象。这种用法很让人困扰，Jamis Buck 在[一篇文章](http://weblog.jamisbuck.org/2007/2/5/nesting-resources)中指出了嵌套路由的用法总则，即：

TIP: 嵌套资源不可超过一层。

#### 浅层嵌套

避免深层嵌套的方法之一，是把控制器集合动作放在父级资源中，表明层级关系，但不嵌套成员动作。也就是说，用最少的信息表明资源的路由关系，如下所示：

```ruby
resources :posts do
  resources :comments, only: [:index, :new, :create]
end
resources :comments, only: [:show, :edit, :update, :destroy]
```

这种做法在描述路由和深层嵌套之间做了适当的平衡。上述代码还有简写形式，即使用 `:shallow` 选项：

```ruby
resources :posts do
  resources :comments, shallow: true
end
```

这种形式生成的路由和前面一样。`:shallow` 选项还可以在父级资源中使用，此时所有嵌套其中的资源都是浅层嵌套：

```ruby
resources :posts, shallow: true do
  resources :comments
  resources :quotes
  resources :drafts
end
```

`shallow` 方法可以创建一个作用域，其中所有嵌套都是浅层嵌套。如下代码生成的路由和前面一样：

```ruby
shallow do
  resources :posts do
    resources :comments
    resources :quotes
    resources :drafts
  end
end
```

`scope` 方法有两个选项可以定制浅层嵌套路由。`:shallow_path` 选项在成员路径前加上指定的前缀：

```ruby
scope shallow_path: "sekret" do
  resources :posts do
    resources :comments, shallow: true
  end
end
```

上述代码为 `comments` 资源生成的路由如下：

| HTTP 方法 | 路径                                   | 控制器#动作       | 具名帮助方法          |
|-----------|----------------------------------------|-------------------|-----------------------|
| GET       | /posts/:post_id/comments(.:format)     | comments#index    | post_comments_path    |
| POST      | /posts/:post_id/comments(.:format)     | comments#create   | post_comments_path    |
| GET       | /posts/:post_id/comments/new(.:format) | comments#new      | new_post_comment_path |
| GET       | /sekret/comments/:id/edit(.:format)    | comments#edit     | edit_comment_path     |
| GET       | /sekret/comments/:id(.:format)         | comments#show     | comment_path          |
| PATCH/PUT | /sekret/comments/:id(.:format)         | comments#update   | comment_path          |
| DELETE    | /sekret/comments/:id(.:format)         | comments#destroy  | comment_path          |

`:shallow_prefix` 选项在具名帮助方法前加上指定的前缀：

```ruby
scope shallow_prefix: "sekret" do
  resources :posts do
    resources :comments, shallow: true
  end
end
```

上述代码为 `comments` 资源生成的路由如下：

| HTTP 方法 | 路径                                   | 控制器#动作       | 具名帮助方法             |
| --------- | -------------------------------------- | ----------------- | ------------------------ |
| GET       | /posts/:post_id/comments(.:format)     | comments#index    | post_comments_path       |
| POST      | /posts/:post_id/comments(.:format)     | comments#create   | post_comments_path       |
| GET       | /posts/:post_id/comments/new(.:format) | comments#new      | new_post_comment_path    |
| GET       | /comments/:id/edit(.:format)           | comments#edit     | edit_sekret_comment_path |
| GET       | /comments/:id(.:format)                | comments#show     | sekret_comment_path      |
| PATCH/PUT | /comments/:id(.:format)                | comments#update   | sekret_comment_path      |
| DELETE    | /comments/:id(.:format)                | comments#destroy  | sekret_comment_path      |

### Routing Concerns

Routing Concerns 用来声明通用路由，可在其他资源和路由中重复使用。定义 concern 的方式如下：

```ruby
concern :commentable do
  resources :comments
end

concern :image_attachable do
  resources :images, only: :index
end
```

Concerns 可在资源中重复使用，避免代码重复：

```ruby
resources :messages, concerns: :commentable

resources :posts, concerns: [:commentable, :image_attachable]
```

上述声明等价于：

```ruby
resources :messages do
  resources :comments
end

resources :posts do
  resources :comments
  resources :images, only: :index
end
```

Concerns 在路由的任何地方都能使用，例如，在作用域或命名空间中：

```ruby
namespace :posts do
  concerns :commentable
end
```

### 由对象创建路径和 URL

除了使用路由帮助方法之外，Rails 还能从参数数组中创建路径和 URL。例如，假设有如下路由：

```ruby
resources :magazines do
  resources :ads
end
```

使用 `magazine_ad_path` 时，可以不传入数字 ID，传入 `Magazine` 和 `Ad` 实例即可：

```erb
<%= link_to 'Ad details', magazine_ad_path(@magazine, @ad) %>
```

而且还可使用 `url_for` 方法，指定一组对象，Rails 会自动决定使用哪个路由：

```erb
<%= link_to 'Ad details', url_for([@magazine, @ad]) %>
```

此时，Rails 知道 `@magazine` 是 `Magazine` 的实例，`@ad` 是 `Ad` 的实例，所以会调用 `magazine_ad_path` 帮助方法。使用 `link_to` 等方法时，无需使用完整的 `url_for` 方法，直接指定对象即可：

```erb
<%= link_to 'Ad details', [@magazine, @ad] %>
```

如果想链接到一本杂志，可以这么做：

```erb
<%= link_to 'Magazine details', @magazine %>
```

要想链接到其他动作，把数组的第一个元素设为所需动作名即可：

```erb
<%= link_to 'Edit Ad', [:edit, @magazine, @ad] %>
```

在这种用法中，会把模型实例转换成对应的 URL，这是资源式路由带来的主要好处之一。

### 添加更多的 REST 架构动作

可用的路由并不局限于 REST 路由默认创建的那七个，还可以添加额外的集合路由或成员路由。

#### 添加成员路由

要添加成员路由，在 `resource` 代码块中使用 `member` 块即可：

```ruby
resources :photos do
  member do
    get 'preview'
  end
end
```

这段路由能识别 `/photos/1/preview` 是个 GET 请求，映射到 `PhotosController` 的 `preview` 动作上，资源的 ID 传入 `params[:id]`。同时还生成了 `preview_photo_url` 和 `preview_photo_path` 两个帮助方法。

在 `member` 代码块中，每个路由都要指定使用的 HTTP 方法。可以使用 `get`，`patch`，`put`，`post` 或 `delete`。如果成员路由不多，可以不使用代码块形式，直接在路由上使用 `:on` 选项：

```ruby
resources :photos do
  get 'preview', on: :member
end
```

也可以不使用 `:on` 选项，得到的成员路由是相同的，但资源 ID 存储在 `params[:photo_id]` 而不是 `params[:id]` 中。

#### 添加集合路由

添加集合路由的方式如下：

```ruby
resources :photos do
  collection do
    get 'search'
  end
end
```

这段路由能识别 `/photos/search` 是个 GET 请求，映射到 `PhotosController` 的 `search` 动作上。同时还会生成 `search_photos_url` 和 `search_photos_path` 两个帮助方法。

和成员路由一样，也可使用 `:on` 选项：

```ruby
resources :photos do
  get 'search', on: :collection
end
```

#### 添加额外新建动作的路由

要添加额外的新建动作，可以使用 `:on` 选项：

```ruby
resources :comments do
  get 'preview', on: :new
end
```

这段代码能识别 `/comments/new/preview` 是个 GET 请求，映射到 `CommentsController` 的 `preview` 动作上。同时还会生成 `preview_new_comment_url` 和 `preview_new_comment_path` 两个路由帮助方法。

TIP: 如果在资源式路由中添加了过多额外动作，这时就要停下来问自己，是不是要新建一个资源。

非资源式路由
-----------

除了资源路由之外，Rails 还提供了强大功能，把任意 URL 映射到动作上。此时，不会得到资源式路由自动生成的一系列路由，而是分别声明各个路由。

虽然一般情况下要使用资源式路由，但也有一些情况使用简单的路由更合适。如果不合适，也不用非得使用资源实现程序的每种功能。

简单的路由特别适合把传统的 URL 映射到 Rails 动作上。

### 绑定参数

声明常规路由时，可以提供一系列 Symbol，做为 HTTP 请求的一部分，传入 Rails 程序。其中两个 Symbol 有特殊作用：`:controller` 映射程序的控制器名，`:action` 映射控制器中的动作名。例如，有下面的路由：

```ruby
get ':controller(/:action(/:id))'
```

如果 `/photos/show/1` 由这个路由处理（没匹配路由文件中其他路由声明），会映射到 `PhotosController` 的 `show` 动作上，最后一个参数 `"1"` 可通过 `params[:id]` 获取。上述路由还能处理 `/photos` 请求，映射到 `PhotosController#index`，因为 `:action` 和 `:id` 放在括号中，是可选参数。

### 动态路径片段

在常规路由中可以使用任意数量的动态片段。`:controller` 和 `:action` 之外的参数都会存入 `params` 传给动作。如果有下面的路由：

```ruby
get ':controller/:action/:id/:user_id'
```

`/photos/show/1/2` 请求会映射到 `PhotosController` 的 `show` 动作。`params[:id]` 的值是 `"1"`，`params[:user_id]` 的值是 `"2"`。

NOTE: 匹配控制器时不能使用 `:namespace` 或 `:module`。如果需要这种功能，可以为控制器做个约束，匹配所需的命名空间。例如：
I>
I>
I>```ruby
NOTE: get ':controller(/:action(/:id))', controller: /admin\/[^\/]+/
NOTE: ```

TIP: 默认情况下，动态路径片段中不能使用点号，因为点号是格式化路由的分隔符。如果需要在动态路径片段中使用点号，可以添加一个约束条件。例如，`id: /[^\/]+/` 可以接受除斜线之外的所有字符。

### 静态路径片段

声明路由时可以指定静态路径片段，片段前不加冒号即可：

```ruby
get ':controller/:action/:id/with_user/:user_id'
```

这个路由能响应 `/photos/show/1/with_user/2` 这种路径。此时，`params` 的值为 `{ controller: 'photos', action: 'show', id: '1', user_id: '2' }`。

### 查询字符串

`params` 中还包含查询字符串中的所有参数。例如，有下面的路由：

```ruby
get ':controller/:action/:id'
```

`/photos/show/1?user_id=2` 请求会映射到 `Photos` 控制器的 `show` 动作上。`params` 的值为 `{ controller: 'photos', action: 'show', id: '1', user_id: '2' }`。

### 定义默认值

在路由中无需特别使用 `:controller` 和 `:action`，可以指定默认值：

```ruby
get 'photos/:id', to: 'photos#show'
```

这样声明路由后，Rails 会把 `/photos/12` 映射到 `PhotosController` 的 `show` 动作上。

路由中的其他部分也使用 `:defaults` 选项设置默认值。甚至可以为没有指定的动态路径片段设定默认值。例如：

```ruby
get 'photos/:id', to: 'photos#show', defaults: { format: 'jpg' }
```

Rails 会把 `photos/12` 请求映射到 `PhotosController` 的 `show` 动作上，把 `params[:format]` 的值设为 `"jpg"`。

### 命名路由

使用 `:as` 选项可以为路由起个名字：

```ruby
get 'exit', to: 'sessions#destroy', as: :logout
```

这段路由会生成 `logout_path` 和 `logout_url` 这两个具名路由帮助方法。调用 `logout_path` 方法会返回 `/exit`。

使用 `:as` 选项还能重设资源的路径方法，例如：

```ruby
get ':username', to: 'users#show', as: :user
```

这段路由会定义一个名为 `user_path` 的方法，可在控制器、帮助方法和视图中使用。在 `UsersController` 的 `show` 动作中，`params[:username]` 的值即用户的用户名。如果不想使用 `:username` 作为参数名，可在路由声明中修改。

### HTTP 方法约束

一般情况下，应该使用 `get`、`post`、`put`、`patch` 和 `delete` 方法限制路由可使用的 HTTP 方法。如果使用 `match` 方法，可以通过 `:via` 选项一次指定多个 HTTP 方法：

```ruby
match 'photos', to: 'photos#show', via: [:get, :post]
```

如果某个路由想使用所有 HTTP 方法，可以使用 `via: :all`：

```ruby
match 'photos', to: 'photos#show', via: :all
```

NOTE: 同个路由即处理 `GET` 请求又处理 `POST` 请求有安全隐患。一般情况下，除非有特殊原因，切记不要允许在一个动作上使用所有 HTTP 方法。

### 路径片段约束

可使用 `:constraints` 选项限制动态路径片段的格式：

```ruby
get 'photos/:id', to: 'photos#show', constraints: { id: /[A-Z]\d{5}/ }
```

这个路由能匹配 `/photos/A12345`，但不能匹配 `/photos/893`。上述路由还可简化成：

```ruby
get 'photos/:id', to: 'photos#show', id: /[A-Z]\d{5}/
```

`:constraints` 选项中的正则表达式不能使用“锚记”。例如，下面的路由是错误的：

```ruby
get '/:id', to: 'posts#show', constraints: {id: /^\d/}
```

之所以不能使用锚记，是因为所有正则表达式都从头开始匹配。

例如，有下面的路由。如果 `to_param` 方法得到的值以数字开头，例如 `1-hello-world`，就会把请求交给 `posts` 控制器处理；如果 `to_param` 方法得到的值不以数字开头，例如 `david`，就交给 `users` 控制器处理。

```ruby
get '/:id', to: 'posts#show', constraints: { id: /\d.+/ }
get '/:username', to: 'users#show'
```

### 基于请求的约束

约束还可以根据任何一个返回值为字符串的 [Request](action_controller_overview.html#the-request-object) 方法设定。

基于请求的约束和路径片段约束的设定方式一样：

```ruby
get 'photos', constraints: {subdomain: 'admin'}
```

约束还可使用代码块形式：

```ruby
namespace :admin do
  constraints subdomain: 'admin' do
    resources :photos
  end
end
```

### 高级约束

如果约束很复杂，可以指定一个能响应 `matches?` 方法的对象。假设要用 `BlacklistConstraint` 过滤所有用户，可以这么做：

```ruby
class BlacklistConstraint
  def initialize
    @ips = Blacklist.retrieve_ips
  end

  def matches?(request)
    @ips.include?(request.remote_ip)
  end
end

TwitterClone::Application.routes.draw do
  get '*path', to: 'blacklist#index',
    constraints: BlacklistConstraint.new
end
```

约束还可以在 lambda 中指定：

```ruby
TwitterClone::Application.routes.draw do
  get '*path', to: 'blacklist#index',
    constraints: lambda { |request| Blacklist.retrieve_ips.include?(request.remote_ip) }
end
```

`matches?` 方法和 lambda 的参数都是 `request` 对象。

### 通配片段

路由中的通配符可以匹配其后的所有路径片段。例如：

```ruby
get 'photos/*other', to: 'photos#unknown'
```

这个路由可以匹配 `photos/12` 或 `/photos/long/path/to/12`，`params[:other]` 的值为 `"12"` 或 `"long/path/to/12"`。以星号开头的路径片段叫做“通配片段”。

通配片段可以出现在路由的任何位置。例如：

```ruby
get 'books/*section/:title', to: 'books#show'
```

这个路由可以匹配 `books/some/section/last-words-a-memoir`，`params[:section]` 的值为 `'some/section'`，`params[:title]` 的值为 `'last-words-a-memoir'`。

严格来说，路由中可以有多个通配片段。匹配器会根据直觉赋值各片段。例如：

```ruby
get '*a/foo/*b', to: 'test#index'
```

这个路由可以匹配 `zoo/woo/foo/bar/baz`，`params[:a]` 的值为 `'zoo/woo'`，`params[:b]` 的值为 `'bar/baz'`。

NOTE: 如果请求 `'/foo/bar.json'`，那么 `params[:pages]` 的值为 `'foo/bar'`，请求类型为 JSON。如果想使用 Rails 3.0.x 中的表现，可以指定 `format: false` 选项，如下所示：
I>
I>
I>```ruby
NOTE: get '*pages', to: 'pages#show', format: false
NOTE: ```
I>
NOTE: 如果必须指定格式，可以指定 `format: true` 选项，如下所示：
I>
I>
I>```ruby
NOTE: get '*pages', to: 'pages#show', format: true
NOTE: ```

### 重定向

在路由中可以使用 `redirect` 帮助方法把一个路径重定向到另一个路径：

```ruby
get '/stories', to: redirect('/posts')
```

重定向时还可使用匹配的动态路径片段：

```ruby
get '/stories/:name', to: redirect('/posts/%{name}')
```

`redirect` 还可使用代码块形式，传入路径参数和 `request` 对象作为参数：

```ruby
get '/stories/:name', to: redirect {|path_params, req| "/posts/#{path_params[:name].pluralize}" }
get '/stories', to: redirect {|path_params, req| "/posts/#{req.subdomain}" }
```

注意，`redirect` 实现的是 301 "Moved Permanently" 重定向，有些浏览器或代理服务器会缓存这种重定向，导致旧的页面不可用。

如果不指定主机（`http://www.example.com`），Rails 会从当前请求中获取。

### 映射到 Rack 程序

除了使用字符串，例如 `'posts#index'`，把请求映射到 `PostsController` 的 `index` 动作上之外，还可使用 [Rack](rails_on_rack.html) 程序作为端点：

```ruby
match '/application.js', to: Sprockets, via: :all
```

只要 `Sprockets` 能响应 `call` 方法，而且返回 `[status, headers, body]` 形式的结果，路由器就不知道这是个 Rack 程序还是动作。这里使用 `via: :all` 是正确的，因为我们想让 Rack 程序自行判断，处理所有 HTTP 方法。

NOTE: 其实 `'posts#index'` 的复杂形式是 `PostsController.action(:index)`，得到的也是个合法的 Rack 程序。

### 使用 `root`

使用 `root` 方法可以指定怎么处理 `'/'` 请求：

```ruby
root to: 'pages#main'
root 'pages#main' # shortcut for the above
```

`root` 路由应该放在文件的顶部，因为这是最常用的路由，应该先匹配。

NOTE: `root` 路由只处理映射到动作上的 `GET` 请求。

在命名空间和作用域中也可使用 `root`。例如：

```ruby
namespace :admin do
  root to: "admin#index"
end

root to: "home#index"
```

### Unicode 字符路由

路由中可直接使用 Unicode 字符。例如：

```ruby
get 'こんにちは', to: 'welcome#index'
```

定制资源式路由
------------

虽然 `resources :posts` 默认生成的路由和帮助方法都满足大多数需求，但有时还是想做些定制。Rails 允许对资源式帮助方法做几乎任何形式的定制。

### 指定使用的控制器

`:controller` 选项用来指定资源使用的控制器。例如：

```ruby
resources :photos, controller: 'images'
```

能识别以 `/photos` 开头的请求，但交给 `Images` 控制器处理：

| HTTP 方法 | 路径             | 控制器#动作       | 具名帮助方法         |
|-----------|------------------|-------------------|----------------------|
| GET       | /photos          | images#index      | photos_path          |
| GET       | /photos/new      | images#new        | new_photo_path       |
| POST      | /photos          | images#create     | photos_path          |
| GET       | /photos/:id      | images#show       | photo_path(:id)      |
| GET       | /photos/:id/edit | images#edit       | edit_photo_path(:id) |
| PATCH/PUT | /photos/:id      | images#update     | photo_path(:id)      |
| DELETE    | /photos/:id      | images#destroy    | photo_path(:id)      |

NOTE: 要使用 `photos_path`、`new_photo_path` 等生成该资源的路径。

命名空间中的控制器可通过目录形式指定。例如：

```ruby
resources :user_permissions, controller: 'admin/user_permissions'
```

这个路由会交给 `Admin::UserPermissions` 控制器处理。

NOTE: 只支持目录形式。如果使用 Ruby 常量形式，例如 `controller: 'Admin::UserPermissions'`，会导致路由报错。

### 指定约束

可以使用 `:constraints`选项指定 `id` 必须满足的格式。例如：

```ruby
resources :photos, constraints: {id: /[A-Z][A-Z][0-9]+/}
```

这个路由声明限制参数 `:id` 必须匹配指定的正则表达式。因此，这个路由能匹配 `/photos/RR27`，不能匹配 `/photos/1`。

使用代码块形式可以把约束应用到多个路由上：

```ruby
constraints(id: /[A-Z][A-Z][0-9]+/) do
  resources :photos
  resources :accounts
end
```

NOTE: 当然了，在资源式路由中也能使用非资源式路由中的高级约束。

TIP: 默认情况下，在 `:id` 参数中不能使用点号，因为点号是格式化路由的分隔符。如果需要在 `:id` 中使用点号，可以添加一个约束条件。例如，`id: /[^\/]+/` 可以接受除斜线之外的所有字符。

### 改写具名帮助方法

`:as` 选项可以改写常规的具名路由帮助方法。例如：

```ruby
resources :photos, as: 'images'
```

能识别以 `/photos` 开头的请求，交给 `PhotosController` 处理，但使用 `:as` 选项的值命名帮助方法：

| HTTP 方法 | 路径             | 控制器#动作       | 具名帮助方法         |
|-----------|------------------|-------------------|----------------------|
| GET       | /photos          | photos#index      | images_path          |
| GET       | /photos/new      | photos#new        | new_image_path       |
| POST      | /photos          | photos#create     | images_path          |
| GET       | /photos/:id      | photos#show       | image_path(:id)      |
| GET       | /photos/:id/edit | photos#edit       | edit_image_path(:id) |
| PATCH/PUT | /photos/:id      | photos#update     | image_path(:id)      |
| DELETE    | /photos/:id      | photos#destroy    | image_path(:id)      |

### 改写 `new` 和 `edit` 片段

`:path_names` 选项可以改写路径中自动生成的 `"new"` 和 `"edit"` 片段：

```ruby
resources :photos, path_names: { new: 'make', edit: 'change' }
```

这样设置后，路由就能识别如下的路径：

```
/photos/make
/photos/1/change
```

NOTE: 这个选项并不能改变实际处理请求的动作名。上述两个路径还是交给 `new` 和 `edit` 动作处理。

TIP: 如果想按照这种方式修改所有路由，可以使用作用域。
T>
T>
T>```ruby
TIP: scope path_names: { new: 'make' } do
TIP:   # rest of your routes
TIP: end
TIP: ```

### 为具名路由帮助方法加上前缀

使用 `:as` 选项可在 Rails 为路由生成的路由帮助方法前加上前缀。这个选项可以避免作用域内外产生命名冲突。例如：

```ruby
scope 'admin' do
  resources :photos, as: 'admin_photos'
end

resources :photos
```

这段路由会生成 `admin_photos_path` 和 `new_admin_photo_path` 等帮助方法。

要想为多个路由添加前缀，可以在 `scope` 方法中设置 `:as` 选项：

```ruby
scope 'admin', as: 'admin' do
  resources :photos, :accounts
end

resources :photos, :accounts
```

这段路由会生成 `admin_photos_path` 和 `admin_accounts_path` 等帮助方法，分别映射到 `/admin/photos` 和 `/admin/accounts` 上。

NOTE: `namespace` 作用域会自动添加 `:as` 以及 `:module` 和 `:path` 前缀。

路由帮助方法的前缀还可使用具名参数：

```ruby
scope ':username' do
  resources :posts
end
```

这段路由能识别 `/bob/posts/1` 这种请求，在控制器、帮助方法和视图中可使用 `params[:username]` 获取 `username` 的值。

### 限制生成的路由

默认情况下，Rails 会为每个 REST 路由生成七个默认动作（`index`，`show`，`new`，`create`，`edit`，`update` 和 `destroy`）对应的路由。你可以使用 `:only` 和 `:except` 选项调整这种行为。`:only` 选项告知 Rails，只生成指定的路由：

```ruby
resources :photos, only: [:index, :show]
```

此时，向 `/photos` 能发起 GET 请求，但不能发起 `POST` 请求（正常情况下由 `create` 动作处理）。

`:except` 选项指定**不用**生成的路由：

```ruby
resources :photos, except: :destroy
```

此时，Rails 会生成除 `destroy`（向 `/photos/:id` 发起的 `DELETE` 请求）之外的所有常规路由。

TIP: 如果程序中有很多 REST 路由，使用 `:only` 和 `:except` 指定只生成所需的路由，可以节省内存，加速路由处理过程。

### 翻译路径

使用 `scope` 时，可以改写资源生成的路径名：

```ruby
scope(path_names: { new: 'neu', edit: 'bearbeiten' }) do
  resources :categories, path: 'kategorien'
end
```

Rails 为 `CategoriesController` 生成的路由如下：

| HTTP 方法 | 路径                       | 控制器#动作        | 具名帮助方法            |
|-----------|----------------------------|--------------------|-------------------------|
| GET       | /kategorien                | categories#index   | categories_path         |
| GET       | /kategorien/neu            | categories#new     | new_category_path       |
| POST      | /kategorien                | categories#create  | categories_path         |
| GET       | /kategorien/:id            | categories#show    | category_path(:id)      |
| GET       | /kategorien/:id/bearbeiten | categories#edit    | edit_category_path(:id) |
| PATCH/PUT | /kategorien/:id            | categories#update  | category_path(:id)      |
| DELETE    | /kategorien/:id            | categories#destroy | category_path(:id)      |

### 改写单数形式

如果想定义资源的单数形式，需要在 `Inflector` 中添加额外的规则：

```ruby
ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'tooth', 'teeth'
end
```

### 在嵌套资源中使用 `:as` 选项

`:as` 选项可以改自动生成的嵌套路由帮助方法名。例如：

```ruby
resources :magazines do
  resources :ads, as: 'periodical_ads'
end
```

这段路由会生成 `magazine_periodical_ads_url` 和 `edit_magazine_periodical_ad_path` 等帮助方法。

路由审查和测试
------------

Rails 提供有路由审查和测试功能。

### 列出现有路由

要想查看程序完整的路由列表，可以在**开发环境**中使用浏览器打开 `http://localhost:3000/rails/info/routes`。也可以在终端执行 `rake routes` 任务查看，结果是一样的。

这两种方法都能列出所有路由，和在 `routes.rb` 中的定义顺序一致。你会看到每个路由的以下信息：

* 路由名（如果有的话）
* 使用的 HTTP 方法（如果不响应所有方法）
* 匹配的 URL 模式
* 路由的参数

例如，下面是执行 `rake routes` 命令后看到的一个 REST 路由片段：

```
    users GET    /users(.:format)          users#index
          POST   /users(.:format)          users#create
 new_user GET    /users/new(.:format)      users#new
edit_user GET    /users/:id/edit(.:format) users#edit
```

可以使用环境变量 `CONTROLLER` 限制只显示映射到该控制器上的路由：

```bash
$ CONTROLLER=users rake routes
```

TIP: 拉宽终端窗口直至没断行，这时看到的 `rake routes` 输出更完整。

### 测试路由

和程序的其他部分一样，路由也要测试。Rails [内建了三个断言](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html)，可以简化测试：

* `assert_generates`
* `assert_recognizes`
* `assert_routing`

#### `assert_generates` 断言

`assert_generates` 检测提供的选项是否能生成默认路由或自定义路由。例如：

```ruby
assert_generates '/photos/1', { controller: 'photos', action: 'show', id: '1' }
assert_generates '/about', controller: 'pages', action: 'about'
```

#### `assert_recognizes` 断言

`assert_recognizes` 是 `assert_generates` 的反测试，检测提供的路径是否能陪识别并交由特定的控制器处理。例如：

```ruby
assert_recognizes({ controller: 'photos', action: 'show', id: '1' }, '/photos/1')
```

可以使用 `:method` 参数指定使用的 HTTP 方法：

```ruby
assert_recognizes({ controller: 'photos', action: 'create' }, { path: 'photos', method: :post })
```

#### `assert_routing` 断言

`assert_routing` 做双向测试：检测路径是否能生成选项，以及选项能否生成路径。因此，综合了 `assert_generates` 和 `assert_recognizes` 两个断言。

```ruby
assert_routing({ path: 'photos', method: :post }, { controller: 'photos', action: 'create' })
```
