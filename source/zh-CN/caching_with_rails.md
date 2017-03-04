Rails 缓存概览
==============

本文简述如何使用缓存提升 Rails 应用的速度。

缓存是指存储请求-响应循环中生成的内容，在类似请求的响应中复用。

通常，缓存是提升应用性能最有效的方式。通过缓存，在单个服务器中使用单个数据库的网站可以承受数千个用户并发访问。

Rails 自带了一些缓存功能。本文说明它们的适用范围和作用。掌握这些技术之后，你的 Rails 应用能承受大量访问，而不必花大量时间生成响应，或者支付高昂的服务器账单。

读完本文后，您将学到：

- 片段缓存和俄罗斯套娃缓存；

- 如何管理缓存依赖；

- 不同的缓存存储器；

- 对条件 GET 请求的支持。

--------------------------------------------------------------------------------

基本缓存
--------

本节简介三种缓存技术：页面缓存（page caching）、动作缓存（action caching）和片段缓存（fragment caching）。Rails 默认提供了片段缓存。如果想使用页面缓存或动作缓存，要把 `actionpack-page_caching` 或 `actionpack-action_caching` 添加到 `Gemfile` 中。

默认情况下，缓存只在生产环境启用。如果想在本地启用缓存，要在相应的 `config/environments/*.rb` 文件中把 `config.action_controller.perform_caching` 设为 `true`。

```ruby
config.action_controller.perform_caching = true
```

NOTE: 修改 `config.action_controller.perform_caching` 的值只对 Action Controller 组件提供的缓存有影响。例如，对低层缓存没影响，[下文详述](#低层缓存)。

### 页面缓存

页面缓存时 Rails 提供的一种缓存机制，让 Web 服务器（如 Apache 和 NGINX）直接伺服生成的页面，而不经由 Rails 栈处理。虽然这种缓存的速度超快，但是不适用于所有情况（例如需要验证身份的页面）。此外，因为 Web 服务器直接从文件系统中伺服文件，所以你要自行实现缓存失效机制。

TIP: Rails 4 删除了页面缓存。参见 [actionpack-page\_caching gem](https://github.com/rails/actionpack-page_caching)。

### 动作缓存

有前置过滤器的动作不能使用页面缓存，例如需要验证身份的页面。此时，应该使用动作缓存。动作缓存的工作原理与页面缓存类似，不过入站请求会经过 Rails 栈处理，以便运行前置过滤器，然后再伺服缓存。这样，可以做身份验证和其他限制，同时还能从缓存的副本中伺服结果。

TIP: Rails 4 删除了动作缓存。参见 [actionpack-action\_caching gem](https://github.com/rails/actionpack-action_caching)。最新推荐的做法参见 DHH 写的“[How key-based cache expiration works](https://signalvnoise.com/posts/3113-how-key-based-cache-expiration-works)”一文。

### 片段缓存

动态 Web 应用一般使用不同的组件构建页面，不是所有组件都能使用同一种缓存机制。如果页面的不同部分需要使用不同的缓存机制，在不同的条件下失效，可以使用片段缓存。

片段缓存把视图逻辑的一部分放在 `cache` 块中，下次请求使用缓存存储器中的副本伺服。

例如，如果想缓存页面中的各个商品，可以使用下述代码：

```erb
<% @products.each do |product| %>
  <% cache product do %>
    <%= render product %>
  <% end %>
<% end %>
```

首次访问这个页面时，Rails 会创建一个具有唯一键的缓存条目。缓存键类似下面这种：

    views/products/1-201505056193031061005000/bea67108094918eeba42cd4a6e786901

中间的数字是 `product_id` 加上商品记录的 `updated_at` 属性中存储的时间戳。Rails 使用时间戳确保不伺服过期的数据。如果 `updated_at` 的值变了，Rails 会生成一个新键，然后在那个键上写入一个新缓存，旧键上的旧缓存不再使用。这叫基于键的失效方式。

视图片段有变化时（例如视图的 HTML 有变），缓存的片段也失效。缓存键末尾那个字符串是模板树摘要，是基于缓存的视图片段的内容计算的 MD5 哈希值。如果视图片段有变化，MD5 哈希值就变了，因此现有文件失效。

TIP: Memcached 等缓存存储器会自动删除旧的缓存文件。

如果想在特定条件下缓存一个片段，可以使用 `cache_if` 或 `cache_unless`：

```erb
<% cache_if admin?, product do %>
  <%= render product %>
<% end %>
```

#### 集合缓存

`render` 辅助方法还能缓存渲染集合的单个模板。这甚至比使用 `each` 的前述示例更好，因为是一次性读取所有缓存模板的，而不是一次读取一个。若想缓存集合，渲染集合时传入 `cached: true` 选项：

```erb
<%= render partial: 'products/product', collection: @products, cached: true %>
```

上述代码中所有的缓存模板一次性获取，速度更快。此外，尚未缓存的模板也会写入缓存，在下次渲染时获取。

### 俄罗斯套娃缓存

有时，可能想把缓存的片段嵌套在其他缓存的片段里。这叫俄罗斯套娃缓存（Russian doll caching）。

俄罗斯套娃缓存的优点是，更新单个商品后，重新生成外层片段时，其他内存片段可以复用。

前一节说过，如果缓存的文件对应的记录的 `updated_at` 属性值变了，缓存的文件失效。但是，内层嵌套的片段不失效。

对下面的视图来说：

```erb
<% cache product do %>
  <%= render product.games %>
<% end %>
```

而它渲染这个视图：

```erb
<% cache game do %>
  <%= render game %>
<% end %>
```

如果游戏的任何一个属性变了，`updated_at` 的值会设为当前时间，因此缓存失效。然而，商品对象的 `updated_at` 属性不变，因此它的缓存不失效，从而导致应用伺服过期的数据。为了解决这个问题，可以使用 `touch` 方法把模型绑在一起：

```ruby
class Product < ApplicationRecord
  has_many :games
end

class Game < ApplicationRecord
  belongs_to :product, touch: true
end
```

把 `touch` 设为 `true` 后，导致游戏的 `updated_at` 变化的操作，也会修改关联的商品的 `updated_at` 属性，从而让缓存失效。

### 管理依赖

为了正确地让缓存失效，要正确地定义缓存依赖。Rails 足够智能，能处理常见的情况，无需自己指定。但是有时需要处理自定义的辅助方法（以此为例），因此要自行定义。

#### 隐式依赖

多数模板依赖可以从模板中的 `render` 调用中推导出来。下面举例说明 `ActionView::Digestor` 知道如何解码的 `render` 调用：

```ruby
render partial: "comments/comment", collection: commentable.comments
render "comments/comments"
render 'comments/comments'
render('comments/comments')

render "header" => render("comments/header")

render(@topic)         => render("topics/topic")
render(topics)         => render("topics/topic")
render(message.topics) => render("topics/topic")
```

而另一方面，有些调用要做修改方能让缓存正确工作。例如，如果传入自定义的集合，要把下述代码：

```ruby
render @project.documents.where(published: true)
```

改为：

```ruby
render partial: "documents/document", collection: @project.documents.where(published: true)
```

#### 显式依赖

有时，模板依赖推导不出来。在辅助方法中渲染时经常是这样。下面举个例子：

```erb
<%= render_sortable_todolists @project.todolists %>
```

此时，要使用一种特殊的注释格式：

```erb
<%# Template Dependency: todolists/todolist %>
<%= render_sortable_todolists @project.todolists %>
```

某些情况下，例如设置单表继承，可能要显式定义一堆依赖。此时无需写出每个模板，可以使用通配符匹配一个目录中的全部模板：

```erb
<%# Template Dependency: events/* %>
<%= render_categorizable_events @person.events %>
```

对集合缓存来说，如果局部模板不是以干净的缓存调用开头，依然可以使用集合缓存，不过要在模板中的任意位置添加一种格式特殊的注释，如下所示：

```erb
<%# Template Collection: notification %>
<% my_helper_that_calls_cache(some_arg, notification) do %>
  <%= notification.name %>
<% end %>
```

#### 外部依赖

如果在缓存的块中使用辅助方法，而后更新了辅助方法，还要更新缓存。具体方法不限，只要能改变模板文件的 MD5 值就行。推荐的方法之一是添加一个注释，如下所示：

```erb
<%# Helper Dependency Updated: Jul 28, 2015 at 7pm %>
<%= some_helper_method(person) %>
```

### 低层缓存

有时需要缓存特定的值或查询结果，而不是缓存视图片段。Rails 的缓存机制能存储任何类型的信息。

实现低层缓存最有效的方式是使用 `Rails.cache.fetch` 方法。这个方法既能读取也能写入缓存。传入单个参数时，获取指定的键，返回缓存中的值。传入块时，在指定键上缓存块的结果，并返回结果。

下面举个例子。应用中有个 `Product` 模型，它有个实例方法，在竞争网站中查找商品的价格。这个方法返回的数据特别适合使用低层缓存：

```ruby
class Product < ApplicationRecord
  def competing_price
    Rails.cache.fetch("#{cache_key}/competing_price", expires_in: 12.hours) do
      Competitor::API.find_price(id)
    end
  end
end
```

NOTE: 注意，这个示例使用了 `cache_key` 方法，因此得到的缓存键类似这种：`products/233-20140225082222765838000/competing_price`。`cache_key` 方法根据模型的 `id` 和 `updated_at` 属性生成一个字符串。这是常见的约定，有个好处是，商品更新后缓存自动失效。一般来说，使用低层缓存缓存实例层信息时，需要生成缓存键。

### SQL 缓存

查询缓存是 Rails 提供的一个功能，把各个查询的结果集缓存起来。如果在同一个请求中遇到了相同的查询，Rails 会使用缓存的结果集，而不再次到数据库中运行查询。

例如：

```ruby
class ProductsController < ApplicationController

  def index
    # 运行查找查询
    @products = Product.all

    ...

    # 再次运行相同的查询
    @products = Product.all
  end

end
```

再次运行相同的查询时，根本不会发给数据库。首次运行查询得到的结果存储在查询缓存中（内存里），第二次查询从内存中获取。

然而要知道，查询缓存在动作开头创建，到动作末尾销毁，只在动作的存续时间内存在。如果想持久化存储查询结果，使用低层缓存也能实现。

缓存存储器
----------

Rails 为存储缓存数据（SQL 缓存和页面缓存除外）提供了不同的存储器。

### 配置

`config.cache_store` 配置选项用于设定应用的默认缓存存储器。可以设定其他参数，传给缓存存储器的构造方法：

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

NOTE: 此外，还可以在配置块外部调用 `ActionController::Base.cache_store`。

缓存存储器通过 `Rails.cache` 访问。

### `ActiveSupport::Cache::Store`

这个类是在 Rails 中与缓存交互的基础。这是个抽象类，不能直接使用。你必须根据存储器引擎具体实现这个类。Rails 提供了几个实现，说明如下。

主要调用的方法有 `read`、`write`、`delete`、`exist?` 和 `fetch`。`fetch` 方法接受一个块，返回缓存中现有的值，或者把新值写入缓存。

所有缓存实现有些共用的选项，可以传给构造方法，或者传给与缓存条目交互的各个方法。

- `:namespace`：在缓存存储器中创建命名空间。如果与其他应用共用同一个缓存存储器，这个选项特别有用。

- `:compress`：指定压缩缓存。通过缓慢的网络传输大量缓存时用得着。

- `:compress_threshold`：与 `:compress` 选项搭配使用，指定一个阈值，未达到时不压缩缓存。默认为 16 千字节。

- `:expires_in`：为缓存条目设定失效时间（秒数），失效后自动从缓存中删除。

- `:race_condition_ttl`：与 `:expires_in` 选项搭配使用。避免多个进程同时重新生成相同的缓存条目（也叫 dog pile effect），防止让缓存条目过期时出现条件竞争。这个选项设定在重新生成新值时失效的条目还可以继续使用多久（秒数）。如果使用 `:expires_in` 选项， 最好也设定这个选项。

#### 自定义缓存存储器

缓存存储器可以自己定义，只需扩展 `ActiveSupport::Cache::Store` 类，实现相应的方法。这样，你可以把任何缓存技术带到你的 Rails 应用中。

若想使用自定义的缓存存储器，只需把 `cache_store` 设为自定义类的实例：

```ruby
config.cache_store = MyCacheStore.new
```

### `ActiveSupport::Cache::MemoryStore`

这个缓存存储器把缓存条目放在内存中，与 Ruby 进程放在一起。可以把 `:size` 选项传给构造方法，指定缓存的大小限制（默认为 32Mb）。超过分配的大小后，会清理缓存，把最不常用的条目删除。

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

如果运行多个 Ruby on Rails 服务器进程（例如使用 mongrel\_cluster 或 Phusion Passenger），各个实例之间无法共享缓存数据。这个缓存存储器不适合大型应用使用。不过，适合只有几个服务器进程的低流量小型应用使用，也适合在开发环境和测试环境中使用。

### `ActiveSupport::Cache::FileStore`

这个缓存存储器使用文件系统存储缓存条目。初始化这个存储器时，必须指定存储文件的目录：

```ruby
config.cache_store = :file_store, "/path/to/cache/directory"
```

使用这个缓存存储器时，在同一台主机中运行的多个服务器进程可以共享缓存。这个缓存存储器适合一到两个主机的中低流量网站使用。运行在不同主机中的多个服务器进程若想共享缓存，可以使用共享的文件系统，但是不建议这么做。

缓存量一直增加，直到填满磁盘，所以建议你定期清理旧缓存条目。

这是默认的缓存存储器。

### `ActiveSupport::Cache::MemCacheStore`

这个缓存存储器使用 Danga 的 `memcached` 服务器为应用提供中心化缓存。Rails 默认使用自带的 `dalli` gem。这是生产环境的网站目前最常使用的缓存存储器。通过它可以实现单个共享的缓存集群，效率很高，有较好的冗余。

初始化这个缓存存储器时，要指定集群中所有 memcached 服务器的地址。如果不指定，假定 memcached 运行在本地的默认端口上，但是对大型网站来说，这样做并不好。

这个缓存存储器的 `write` 和 `fetch` 方法接受两个额外的选项，以便利用 memcached 的独有特性。指定 `:raw` 时，直接把值发给服务器，不做序列化。值必须是字符串或数字。memcached 的直接操作，如 `increment` 和 `decrement`，只能用于原始值。还可以指定 `:unless_exist` 选项，不让 memcached 覆盖现有条目。

```ruby
config.cache_store = :mem_cache_store, "cache-1.example.com", "cache-2.example.com"
```

### `ActiveSupport::Cache::NullStore`

这个缓存存储器只应该在开发或测试环境中使用，它并不存储任何信息。在开发环境中，如果代码直接与 `Rails.cache` 交互，但是缓存可能对代码的结果有影响，可以使用这个缓存存储器。在这个缓存存储器上调用 `fetch` 和 `read` 方法不返回任何值。

```ruby
config.cache_store = :null_store
```

缓存键
------

缓存中使用的键可以是能响应 `cache_key` 或 `to_param` 方法的任何对象。如果想定制生成键的方式，可以覆盖 `cache_key` 方法。Active Record 根据类名和记录 ID 生成缓存键。

缓存键的值可以是散列或数组：

```ruby
# 这是一个有效的缓存键
Rails.cache.read(site: "mysite", owners: [owner_1, owner_2])
```

`Rails.cache` 使用的键与存储引擎使用的并不相同，存储引擎使用的键可能含有命名空间，或者根据后端的限制做调整。这意味着，使用 `Rails.cache` 存储值时使用的键可能无法用于供 `dalli` gem 获取缓存条目。然而，你也无需担心会超出 memcached 的大小限制，或者违背句法规则。

对条件 GET 请求的支持
---------------------

条件 GET 请求是 HTTP 规范的一个特性，以此告诉 Web 浏览器，GET 请求的响应自上次请求之后没有变化，可以放心从浏览器的缓存中读取。

为此，要传递 `HTTP_IF_NONE_MATCH` 和 `HTTP_IF_MODIFIED_SINCE` 首部，其值分别为唯一的内容标识符和上一次改动时的时间戳。浏览器发送的请求，如果内容标识符（etag）或上一次修改的时间戳与服务器中的版本匹配，那么服务器只需返回一个空响应，把状态设为未修改。

服务器（也就是我们自己）要负责查看最后修改时间戳和 `HTTP_IF_NONE_MATCH` 首部，判断要不要返回完整的响应。既然 Rails 支持条件 GET 请求，那么这个任务就非常简单：

```ruby
class ProductsController < ApplicationController

  def show
    @product = Product.find(params[:id])

    # 如果根据指定的时间戳和 etag 值判断请求的内容过期了
    # （即需要重新处理）执行这个块
    if stale?(last_modified: @product.updated_at.utc, etag: @product.cache_key)
      respond_to do |wants|
        # ... 正常处理响应
      end
    end

    # 如果请求的内容还新鲜（即未修改），无需做任何事
    # render 默认使用前面 stale? 中的参数做检查，会自动发送 :not_modified 响应
    # 就这样，工作结束
  end
end
```

除了散列，还可以传入模型。Rails 会使用 `updated_at` 和 `cache_key` 方法设定 `last_modified` 和 `etag`：

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])

    if stale?(@product)
      respond_to do |wants|
        # ... 正常处理响应
      end
    end
  end
end
```

如果无需特殊处理响应，而且使用默认的渲染机制（即不使用 `respond_to`，或者不自己调用 `render`），可以使用 `fresh_when` 简化这个过程：

```ruby
class ProductsController < ApplicationController

  # 如果请求的内容是新鲜的，自动返回 :not_modified
  # 否则渲染默认的模板（product.*）

  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, etag: @product
  end
end
```

### 强 Etag 与弱 Etag

Rails 默认生成弱 ETag。这种 Etag 允许语义等效但主体不完全匹配的响应具有相同的 Etag。如果响应主体有微小改动，而不想重新渲染页面，可以使用这种 Etag。

为了与强 Etag 区别，弱 Etag 前面有 `W/`。

    W/"618bbc92e2d35ea1945008b42799b0e7" => 弱 ETag
    "618bbc92e2d35ea1945008b42799b0e7"   => 强 ETag

与弱 Etag 不同，强 Etag 要求响应完全一样，不能有一个字节的差异。在大型视频或 PDF 文件内部做 Range 查询时用得到。有些 CDN，如 Akamai，只支持强 Etag。如果确实想生成强 Etag，可以这么做：

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, strong_etag: @product
  end
end
```

也可以直接在响应上设定强 Etag：

```ruby
response.strong_etag = response.body
# => "618bbc92e2d35ea1945008b42799b0e7"
```

参考资源
--------

- [DHH 写的文章：How key-based cache expiration works](https://signalvnoise.com/posts/3113-how-key-based-cache-expiration-works)

- [Railscast 中介绍缓存摘要的视频](http://railscasts.com/episodes/387-cache-digests)
