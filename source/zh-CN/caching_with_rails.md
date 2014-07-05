Rails 缓存简介
=============

本文要教你如果避免频繁查询数据库，在最短的时间内把真正需要的内容返回给客户端。

读完后，你将学到：

* 页面和动作缓存（在 Rails 4 中被提取成单独的 gem）；
* 片段缓存；
* 存储缓存的方法；
* Rails 对条件 GET 请求的支持；

--------------------------------------------------------------------------------

缓存基础
-------

本节介绍三种缓存技术：页面，动作和片段。Rails 默认支持片段缓存。如果想使用页面缓存和动作缓存，要在 `Gemfile` 中加入 `actionpack-page_caching` 和 `actionpack-action_caching`。

在开发环境中若想使用缓存，要把 `config.action_controller.perform_caching` 选项设为 `true`。这个选项一般都在各环境的设置文件（`config/environments/*.rb`）中设置，在开发环境和测试环境默认是禁用的，在生产环境中默认是开启的。

```ruby
config.action_controller.perform_caching = true
```

### 页面缓存

页面缓存机制允许网页服务器（Apache 或 Nginx 等）直接处理请求，不经 Rails 处理。这么做显然速度超快，但并不适用于所有情况（例如需要身份认证的页面）。服务器直接从文件系统上伺服文件，所以缓存过期是一个很棘手的问题。

NOTE: Rails 4 删除了对页面缓存的支持，如想使用就得安装 [actionpack-page_caching gem](https://github.com/rails/actionpack-page_caching)。最新推荐的缓存方法参见 [DHH 对键基缓存过期的介绍](http://37signals.com/svn/posts/3113-how-key-based-cache-expiration-works)。

### 动作缓存

如果动作上有前置过滤器就不能使用页面缓存，例如需要身份认证的页面，这时需要使用动作缓存。动作缓存和页面缓存的工作方式差不多，但请求还是会经由 Rails 处理，所以在伺服缓存之前会执行前置过滤器。使用动作缓存可以执行身份认证等限制，然后再从缓存中取出结果返回客户端。

NOTE: Rails 4 删除了对动作缓存的支持，如想使用就得安装 [actionpack-action_caching gem](https://github.com/rails/actionpack-action_caching)。最新推荐的缓存方法参见 [DHH 对键基缓存过期的介绍](http://37signals.com/svn/posts/3113-how-key-based-cache-expiration-works)。

### 片段缓存

如果能缓存整个页面或动作的内容，再伺服给客户端，这个世界就完美了。但是，动态网页程序的页面一般都由很多部分组成，使用的缓存机制也不尽相同。在动态生成的页面中，不同的内容要使用不同的缓存方式和过期日期。为此，Rails 提供了一种缓存机制叫做“片段缓存”。

片段缓存把视图逻辑的一部分打包放在 `cache` 块中，后续请求都会从缓存中伺服这部分内容。

例如，如果想实时显示网站的订单，而且不想缓存这部分内容，但想缓存显示所有可选商品的部分，就可以使用下面这段代码：

```erb
<% Order.find_recent.each do |o| %>
  <%= o.buyer.name %> bought <%= o.product.name %>
<% end %>

<% cache do %>
  All available products:
  <% Product.all.each do |p| %>
    <%= link_to p.name, product_url(p) %>
  <% end %>
<% end %>
```

上述代码中的 `cache` 块会绑定到调用它的动作上，输出到动作缓存的所在位置。因此，如果要在动作中使用多个片段缓存，就要使用 `action_suffix` 为 `cache` 块指定前缀：

```erb
<% cache(action: 'recent', action_suffix: 'all_products') do %>
  All available products:
```

`expire_fragment` 方法可以把缓存设为过期，例如：

```ruby
expire_fragment(controller: 'products', action: 'recent', action_suffix: 'all_products')
```

如果不想把缓存绑定到调用它的动作上，调用 `cahce` 方法时可以使用全局片段名：

```erb
<% cache('all_available_products') do %>
  All available products:
<% end %>
```

在 `ProductsController` 的所有动作中都可以使用片段名调用这个片段缓存，而且过期的设置方式不变：

```ruby
expire_fragment('all_available_products')
```

如果不想手动设置片段缓存过期，而想每次更新商品后自动过期，可以定义一个帮助方法：

```ruby
module ProductsHelper
  def cache_key_for_products
    count          = Product.count
    max_updated_at = Product.maximum(:updated_at).try(:utc).try(:to_s, :number)
    "products/all-#{count}-#{max_updated_at}"
  end
end
```

这个方法生成一个缓存键，用于所有商品的缓存。在视图中可以这么做：

```erb
<% cache(cache_key_for_products) do %>
  All available products:
<% end %>
```

如果想在满足某个条件时缓存片段，可以使用 `cache_if` 或 `cache_unless` 方法：

```erb
<% cache_if (condition, cache_key_for_products) do %>
  All available products:
<% end %>
```

缓存的键名还可使用 Active Record 模型：

```erb
<% Product.all.each do |p| %>
  <% cache(p) do %>
    <%= link_to p.name, product_url(p) %>
  <% end %>
<% end %>
```

Rails 会在模型上调用 `cache_key` 方法，返回一个字符串，例如 `products/23-20130109142513`。键名中包含模型名，ID 以及 `updated_at` 字段的时间戳。所以更新商品后会自动生成一个新片段缓存，因为键名变了。

上述两种缓存机制还可以结合在一起使用，这叫做“俄罗斯套娃缓存”（Russian Doll Caching）：

```erb
<% cache(cache_key_for_products) do %>
  All available products:
  <% Product.all.each do |p| %>
    <% cache(p) do %>
      <%= link_to p.name, product_url(p) %>
    <% end %>
  <% end %>
<% end %>
```

之所以叫“俄罗斯套娃缓存”，是因为嵌套了多个片段缓存。这种缓存的优点是，更新单个商品后，重新生成外层片段缓存时可以继续使用内层片段缓存。

### 底层缓存

有时不想缓存视图片段，只想缓存特定的值或者查询结果。Rails 中的缓存机制可以存储各种信息。

实现底层缓存最有效地方式是使用 `Rails.cache.fetch` 方法。这个方法既可以从缓存中读取数据，也可以把数据写入缓存。传入单个参数时，读取指定键对应的值。传入代码块时，会把代码块的计算结果存入缓存的指定键中，然后返回计算结果。

以下面的代码为例。程序中有个 `Product` 模型，其中定义了一个实例方法，用来查询竞争对手网站上的商品价格。这个方法的返回结果最好使用底层缓存：

```ruby
class Product < ActiveRecord::Base
  def competing_price
    Rails.cache.fetch("#{cache_key}/competing_price", expires_in: 12.hours) do
      Competitor::API.find_price(id)
    end
  end
end
```

NOTE: 注意，在这个例子中使用了 `cache_key` 方法，所以得到的缓存键名是这种形式：`products/233-20140225082222765838000/competing_price`。`cache_key` 方法根据模型的 `id` 和 `updated_at` 属性生成键名。这是最常见的做法，因为商品更新后，缓存就失效了。一般情况下，使用底层缓存保存实例的相关信息时，都要生成缓存键。

### SQL 缓存

查询缓存是 Rails 的一个特性，把每次查询的结果缓存起来，如果在同一次请求中遇到相同的查询，直接从缓存中读取结果，不用再次查询数据库。

例如：

```ruby
class ProductsController < ApplicationController

  def index
    # Run a find query
    @products = Product.all

    ...

    # Run the same query again
    @products = Product.all
  end

end
```

缓存的存储方式
------------

Rails 为动作缓存和片段缓存提供了不同的存储方式。

TIP: 页面缓存全部存储在硬盘中。

### 设置

程序默认使用的缓存存储方式可以在文件 `config/application.rb` 的 `Application` 类中或者环境设置文件（`config/environments/*.rb`）的 `Application.configure` 代码块中调用 `config.cache_store=` 方法设置。该方法的第一个参数是存储方式，后续参数都是传给对应存储方式构造器的参数。

```ruby
config.cache_store = :memory_store
```

NOTE: 在设置代码块外部可以调用 `ActionController::Base.cache_store` 方法设置存储方式。

缓存中的数据通过 `Rails.cache` 方法获取。

### ActiveSupport::Cache::Store

这个类提供了在 Rails 中和缓存交互的基本方法。这是个抽象类，不能直接使用，应该使用针对各存储引擎的具体实现。Rails 实现了几种存储方式，介绍参见后几节。

和缓存交互常用的方法有：`read`，`write`，`delete`，`exist?`，`fetch`。`fetch` 方法接受一个代码块，如果缓存中有对应的数据，将其返回；否则，执行代码块，把结果写入缓存。

Rails 实现的所有存储方式都共用了下面几个选项。这些选项可以传给构造器，也可传给不同的方法，和缓存中的记录交互。

* `:namespace`：在缓存存储中创建命名空间。如果和其他程序共用同一个存储，可以使用这个选项。

* `:compress`：是否压缩缓存。便于在低速网络中传输大型缓存记录。

* `:compress_threshold`：结合 `:compress` 选项使用，设定一个阈值，低于这个值就不压缩缓存。默认为 16 KB。

* `:expires_in`：为缓存记录设定一个过期时间，单位为秒，过期后把记录从缓存中删除。

* `:race_condition_ttl`：结合 `:expires_in` 选项使用。缓存过期后，禁止多个进程同时重新生成同一个缓存记录（叫做 dog pile effect），从而避免条件竞争。这个选项设置一个秒数，在这个时间之后才能再次使用重新生成的新值。如果设置了 `:expires_in` 选项，最好也设置这个选项。

### ActiveSupport::Cache::MemoryStore

这种存储方式在 Ruby 进程中把缓存保存在内存中。存储空间的大小由 `:size` 选项指定，默认为 32MB。如果超出分配的大小，系统会清理缓存，把最不常使用的记录删除。

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

如果运行多个 Rails 服务器进程（使用 mongrel_cluster 或 Phusion Passenger 时），进程间无法共用缓存数据。这种存储方式不适合在大型程序中使用，不过很适合只有几个服务器进程的小型、低流量网站，也可在开发环境和测试环境中使用。

### ActiveSupport::Cache::FileStore

这种存储方式使用文件系统保存缓存。缓存文件的存储位置必须在初始化时指定。

```ruby
config.cache_store = :file_store, "/path/to/cache/directory"
```

使用这种存储方式，同一主机上的服务器进程之间可以共用缓存。运行在不同主机上的服务器进程之间也可以通过共享的文件系统共用缓存，但这种用法不是最好的方式，因此不推荐使用。这种存储方式适合在只用了一到两台主机的中低流量网站中使用。

注意，如果不定期清理，缓存会不断增多，最终会用完硬盘空间。

这是默认使用的缓存存储方式。

### ActiveSupport::Cache::MemCacheStore

这种存储方式使用 Danga 开发的 `memcached` 服务器，为程序提供一个中心化的缓存存储。Rails 默认使用附带安装的 `dalli` gem 实现这种存储方式。这是目前在生产环境中使用最广泛的缓存存储方式，可以提供单个缓存存储，或者共享的缓存集群，性能高，冗余度低。

初始化时要指定集群中所有 memcached 服务器的地址。如果没有指定地址，默认运行在本地主机的默认端口上，这对大型网站来说不是个好主意。

在这种缓存存储中使用 `write` 和 `fetch` 方法还可指定两个额外的选项，充分利用 memcached 的特有功能。指定 `:raw` 选项可以直接把没有序列化的数据传给 memcached 服务器。在这种类型的数据上可以使用 memcached 的原生操作，例如 `increment` 和 `decrement`。如果不想让 memcached 覆盖已经存在的记录，可以指定 `:unless_exist` 选项。

```ruby
config.cache_store = :mem_cache_store, "cache-1.example.com", "cache-2.example.com"
```

### ActiveSupport::Cache::EhcacheStore

如果在 JRuby 平台上运行程序，可以使用 Terracotta 开发的 Ehcache 存储缓存。Ehcache 是使用 Java 开发的开源缓存存储，同时也提供企业版，增强了稳定性、操作便利性，以及商用支持。使用这种存储方式要先安装 `jruby-ehcache-rails3` gem（1.1.0 及以上版本）。

```ruby
config.cache_store = :ehcache_store
```

初始化时，可以使用 `:ehcache_config` 选项指定 Ehcache 设置文件的位置（默认为 Rails 程序根目录中的 `ehcache.xml`），还可使用 `:cache_name` 选项定制缓存名（默认为 `rails_cache`）。

使用 `write` 方法时，除了可以使用通用的 `:expires_in` 选项之外，还可指定 `:unless_exist` 选项，让 Ehcache 使用 `putIfAbsent` 方法代替 `put` 方法，不覆盖已经存在的记录。除此之外，`write` 方法还可接受 [Ehcache Element 类](http://ehcache.org/apidocs/net/sf/ehcache/Element.html)开放的所有属性，包括：

| 属性                        | 参数类型             | 说明                                                         |
| --------------------------- | ------------------- | ----------------------------------------------------------- |
| elementEvictionData         | ElementEvictionData | 设置元素的 eviction 数据实例                                  |
| eternal                     | boolean             | 设置元素是否为 eternal                                        |
| timeToIdle, tti             | int                 | 设置空闲时间                                                 |
| timeToLive, ttl, expires_in | int                 | 设置在线时间                                                 |
| version                     | long                | 设置 ElementAttributes 对象的 `version` 属性                  |

这些选项通过 Hash 传给 `write` 方法，可以使用驼峰式或者下划线分隔形式。例如：

```ruby
Rails.cache.write('key', 'value', time_to_idle: 60.seconds, timeToLive: 600.seconds)
caches_action :index, expires_in: 60.seconds, unless_exist: true
```

关于 Ehcache 更多的介绍，请访问 <http://ehcache.org/>。关于如何在运行于 JRuby 平台之上的 Rails 中使用 Ehcache，请访问 <http://ehcache.org/documentation/jruby.html>。

### ActiveSupport::Cache::NullStore

这种存储方式只可在开发环境和测试环境中使用，并不会存储任何数据。如果在开发过程中必须和 `Rails.cache` 交互，而且会影响到修改代码后的效果，使用这种存储方式尤其方便。使用这种存储方式时调用 `fetch` 和 `read` 方法没有实际作用。

```ruby
config.cache_store = :null_store
```

### 自建存储方式

要想自建缓存存储方式，可以继承 `ActiveSupport::Cache::Store` 类，并实现相应的方法。自建存储方式时，可以使用任何缓存技术。

使用自建的存储方式，把 `cache_store` 设为类的新实例即可。

```ruby
config.cache_store = MyCacheStore.new
```

### 缓存键

缓存中使用的键可以是任意对象，只要能响应 `:cache_key` 或 `:to_param` 方法即可。如果想生成自定义键，可以在类中定义 `:cache_key` 方法。Active Record 根据类名和记录的 ID 生成缓存键。

缓存键也可使用 Hash 或者数组。

```ruby
# This is a legal cache key
Rails.cache.read(site: "mysite", owners: [owner_1, owner_2])
```

`Rails.cache` 方法中使用的键和保存到存储引擎中的键并不一样。保存时，可能会根据命名空间或引擎的限制做修改。也就是说，不能使用 `memcache-client` gem 调用 `Rails.cache` 方法保存缓存再尝试读取缓存。不过，无需担心会超出 memcached 的大小限制，或者违反句法规则。

支持条件 GET 请求
---------------

条件请求是 HTTP 规范的一个特性，网页服务器告诉浏览器 GET 请求的响应自上次请求以来没有发生变化，可以直接读取浏览器缓存中的副本。

条件请求通过 `If-None-Match` 和 `If-Modified-Since` 报头实现，这两个报头的值分别是内容的唯一 ID 和上次修改内容的时间戳，在服务器和客户端之间来回传送。如果浏览器发送的请求中内容 ID（ETag）或上次修改时间戳和服务器上保存的值一样，服务器只需返回一个空响应，并把状态码设为未修改。

服务器负责查看上次修改时间戳和 `If-None-Match` 报头的值，决定是否返回完整的响应。在 Rails 中使用条件 GET 请求很简单：

```ruby
class ProductsController < ApplicationController

  def show
    @product = Product.find(params[:id])

    # If the request is stale according to the given timestamp and etag value
    # (i.e. it needs to be processed again) then execute this block
    if stale?(last_modified: @product.updated_at.utc, etag: @product.cache_key)
      respond_to do |wants|
        # ... normal response processing
      end
    end

    # If the request is fresh (i.e. it's not modified) then you don't need to do
    # anything. The default render checks for this using the parameters
    # used in the previous call to stale? and will automatically send a
    # :not_modified. So that's it, you're done.
  end
end
```

如果不想使用 Hash，还可直接传入模型实例，Rails 会调用 `updated_at` 和 `cache_key` 方法分别设置 `last_modified` 和 `etag`：

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])
    respond_with(@product) if stale?(@product)
  end
end
```

如果没有使用特殊的方式处理响应，使用默认的渲染机制（例如，没有使用 `respond_to` 代码块，或者没有手动调用 `render` 方法），还可使用十分便利的 `fresh_when` 方法：

```ruby
class ProductsController < ApplicationController

  # This will automatically send back a :not_modified if the request is fresh,
  # and will render the default template (product.*) if it's stale.

  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, etag: @product
  end
end
```
