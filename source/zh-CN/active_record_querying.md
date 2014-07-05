Active Record 查询
==================

本文介绍使用 Active Record 从数据库中获取数据的不同方法。

读完本文，你将学到：

* 如何使用各种方法查找满足条件的记录；
* 如何指定查找记录的排序方式，获取哪些属性，分组等；
* 获取数据时如何使用按需加载介绍数据库查询数；
* 如何使用动态查询方法；
* 如何检查某个记录是否存在；
* 如何在 Active Record 模型中做各种计算；
* 如何执行 EXPLAIN 命令；

--------------------------------------------------------------------------------

如果习惯使用 SQL 查询数据库，会发现在 Rails 中执行相同的查询有更好的方式。大多数情况下，在 Active Record 中无需直接使用 SQL。

文中的实例代码会用到下面一个或多个模型：

TIP: 下面所有的模型除非有特别说明之外，都使用 `id` 做主键。

```ruby
class Client < ActiveRecord::Base
  has_one :address
  has_many :orders
  has_and_belongs_to_many :roles
end
```

```ruby
class Address < ActiveRecord::Base
  belongs_to :client
end
```

```ruby
class Order < ActiveRecord::Base
  belongs_to :client, counter_cache: true
end
```

```ruby
class Role < ActiveRecord::Base
  has_and_belongs_to_many :clients
end
```

Active Record 会代你执行数据库查询，可以兼容大多数数据库（MySQL，PostgreSQL 和 SQLite 等）。不管使用哪种数据库，所用的 Active Record 方法都是一样的。

从数据库中获取对象
---------------

Active Record 提供了很多查询方法，用来从数据库中获取对象。每个查询方法都接可接受参数，不用直接写 SQL 就能在数据库中执行指定的查询。

这些方法是：

* `bind`
* `create_with`
* `distinct`
* `eager_load`
* `extending`
* `from`
* `group`
* `having`
* `includes`
* `joins`
* `limit`
* `lock`
* `none`
* `offset`
* `order`
* `preload`
* `readonly`
* `references`
* `reorder`
* `reverse_order`
* `select`
* `uniq`
* `where`

上述所有方法都返回一个 `ActiveRecord::Relation` 实例。

`Model.find(options)` 方法执行的主要操作概括如下：

* 把指定的选项转换成等价的 SQL 查询语句；
* 执行 SQL 查询，从数据库中获取结果；
* 为每个查询结果实例化一个对应的模型对象；
* 如果有 `after_find` 回调，再执行 `after_find` 回调；

### 获取单个对象

在 Active Record 中获取单个对象有好几种方法。

#### 使用主键

使用 `Model.find(primary_key)` 方法可以获取指定主键对应的对象。例如：

```ruby
# Find the client with primary key (id) 10.
client = Client.find(10)
# => #<Client id: 10, first_name: "Ryan">
```

和上述方法等价的 SQL 查询是：

```sql
SELECT * FROM clients WHERE (clients.id = 10) LIMIT 1
```

如果未找到匹配的记录，`Model.find(primary_key)` 会抛出 `ActiveRecord::RecordNotFound` 异常。

#### `take`

`Model.take` 方法会获取一个记录，不考虑任何顺序。例如：

```ruby
client = Client.take
# => #<Client id: 1, first_name: "Lifo">
```

和上述方法等价的 SQL 查询是：

```sql
SELECT * FROM clients LIMIT 1
```

如果没找到记录，`Model.take` 不会抛出异常，而是返回 `nil`。

TIP: 获取的记录根据所用的数据库引擎会有所不同。

#### `first`

`Model.first` 获取按主键排序得到的第一个记录。例如：

```ruby
client = Client.first
# => #<Client id: 1, first_name: "Lifo">
```

和上述方法等价的 SQL 查询是：

```sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

`Model.first` 如果没找到匹配的记录，不会抛出异常，而是返回 `nil`。

#### `last`

`Model.last` 获取按主键排序得到的最后一个记录。例如：

```ruby
client = Client.last
# => #<Client id: 221, first_name: "Russel">
```

和上述方法等价的 SQL 查询是：

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

`Model.last` 如果没找到匹配的记录，不会抛出异常，而是返回 `nil`。

#### `find_by`

`Model.find_by` 获取满足条件的第一个记录。例如：

```ruby
Client.find_by first_name: 'Lifo'
# => #<Client id: 1, first_name: "Lifo">

Client.find_by first_name: 'Jon'
# => nil
```

等价于：

```ruby
Client.where(first_name: 'Lifo').take
```

#### `take!`

`Model.take!` 方法会获取一个记录，不考虑任何顺序。例如：

```ruby
client = Client.take!
# => #<Client id: 1, first_name: "Lifo">
```

和上述方法等价的 SQL 查询是：

```sql
SELECT * FROM clients LIMIT 1
```

如果未找到匹配的记录，`Model.take!` 会抛出 `ActiveRecord::RecordNotFound` 异常。

#### `first!`

`Model.first!` 获取按主键排序得到的第一个记录。例如：

```ruby
client = Client.first!
# => #<Client id: 1, first_name: "Lifo">
```

和上述方法等价的 SQL 查询是：

```sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

如果未找到匹配的记录，`Model.first!` 会抛出 `ActiveRecord::RecordNotFound` 异常。

#### `last!`

`Model.last!` 获取按主键排序得到的最后一个记录。例如：

```ruby
client = Client.last!
# => #<Client id: 221, first_name: "Russel">
```

和上述方法等价的 SQL 查询是：

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

如果未找到匹配的记录，`Model.last!` 会抛出 `ActiveRecord::RecordNotFound` 异常。

#### `find_by!`

`Model.find_by!` 获取满足条件的第一个记录。如果没找到匹配的记录，会抛出 `ActiveRecord::RecordNotFound` 异常。例如：

```ruby
Client.find_by! first_name: 'Lifo'
# => #<Client id: 1, first_name: "Lifo">

Client.find_by! first_name: 'Jon'
# => ActiveRecord::RecordNotFound
```

等价于：

```ruby
Client.where(first_name: 'Lifo').take!
```

### 获取多个对象

#### 使用多个主键

`Model.find(array_of_primary_key)` 方法可接受一个由主键组成的数组，返回一个由主键对应记录组成的数组。例如：

```ruby
# Find the clients with primary keys 1 and 10.
client = Client.find([1, 10]) # Or even Client.find(1, 10)
# => [#<Client id: 1, first_name: "Lifo">, #<Client id: 10, first_name: "Ryan">]
```

上述方法等价的 SQL 查询是：

```sql
SELECT * FROM clients WHERE (clients.id IN (1,10))
```

WARNING: 只要有一个主键的对应的记录未找到，`Model.find(array_of_primary_key)` 方法就会抛出 `ActiveRecord::RecordNotFound` 异常。

#### take

`Model.take(limit)` 方法获取 `limit` 个记录，不考虑任何顺序：

```ruby
Client.take(2)
# => [#<Client id: 1, first_name: "Lifo">,
      #<Client id: 2, first_name: "Raf">]
```

和上述方法等价的 SQL 查询是：

```sql
SELECT * FROM clients LIMIT 2
```

#### first

`Model.first(limit)` 方法获取按主键排序的前 `limit` 个记录：

```ruby
Client.first(2)
# => [#<Client id: 1, first_name: "Lifo">,
      #<Client id: 2, first_name: "Raf">]
```

和上述方法等价的 SQL 查询是：

```sql
SELECT * FROM clients ORDER BY id ASC LIMIT 2
```

#### last

`Model.last(limit)` 方法获取按主键降序排列的前 `limit` 个记录：

```ruby
Client.last(2)
# => [#<Client id: 10, first_name: "Ryan">,
      #<Client id: 9, first_name: "John">]
```

和上述方法等价的 SQL 查询是：

```sql
SELECT * FROM clients ORDER BY id DESC LIMIT 2
```

### 批量获取多个对象

我们经常需要遍历由很多记录组成的集合，例如给大量用户发送邮件列表，或者导出数据。

我们可能会直接写出如下的代码：

```ruby
# This is very inefficient when the users table has thousands of rows.
User.all.each do |user|
  NewsLetter.weekly_deliver(user)
end
```

但这种方法在数据表很大时就有点不现实了，因为 `User.all.each` 会一次读取整个数据表，一行记录创建一个模型对象，然后把整个模型对象数组存入内存。如果记录数非常多，可能会用完内存。

Rails 为了解决这种问题提供了两个方法，把记录分成几个批次，不占用过多内存。第一个方法是 `find_each`，获取一批记录，然后分别把每个记录传入代码块。第二个方法是 `find_in_batches`，获取一批记录，然后把整批记录作为数组传入代码块。

TIP: `find_each` 和 `find_in_batches` 方法的目的是分批处理无法一次载入内存的巨量记录。如果只想遍历几千个记录，更推荐使用常规的查询方法。

#### `find_each`

`find_each` 方法获取一批记录，然后分别把每个记录传入代码块。在下面的例子中，`find_each` 获取 1000 各记录，然后把每个记录传入代码块，知道所有记录都处理完为止：

```ruby
User.find_each do |user|
  NewsLetter.weekly_deliver(user)
end
```

##### `find_each` 方法的选项

在 `find_each` 方法中可使用 `find` 方法的大多数选项，但不能使用 `:order` 和 `:limit`，因为这两个选项是保留给 `find_each` 内部使用的。

`find_each` 方法还可使用另外两个选项：`:batch_size` 和 `:start`。

**`:batch_size`**

`:batch_size` 选项指定在把各记录传入代码块之前，各批次获取的记录数量。例如，一个批次获取 5000 个记录：

```ruby
User.find_each(batch_size: 5000) do |user|
  NewsLetter.weekly_deliver(user)
end
```

**`:start`**

默认情况下，按主键的升序方式获取记录，其中主键的类型必须是整数。如果不想用最小的 ID，可以使用 `:start` 选项指定批次的起始 ID。例如，前面的批量处理中断了，但保存了中断时的 ID，就可以使用这个选项继续处理。

例如，在有 5000 个记录的批次中，只向主键大于 2000 的用户发送邮件列表，可以这么做：

```ruby
User.find_each(start: 2000, batch_size: 5000) do |user|
  NewsLetter.weekly_deliver(user)
end
```

还有一个例子是，使用多个 worker 处理同一个进程队列。如果需要每个 worker 处理 10000 个记录，就可以在每个 worker 中设置相应的 `:start` 选项。

#### `find_in_batches`

`find_in_batches` 方法和 `find_each` 类似，都获取一批记录。二者的不同点是，`find_in_batches` 把整批记录作为一个数组传入代码块，而不是单独传入各记录。在下面的例子中，会把 1000 个单据一次性传入代码块，让代码块后面的程序处理剩下的单据：

```ruby
# Give add_invoices an array of 1000 invoices at a time
Invoice.find_in_batches(include: :invoice_lines) do |invoices|
  export.add_invoices(invoices)
end
```

NOTE: `:include` 选项可以让指定的关联和模型一同加载。

##### `find_in_batches` 方法的选项

`find_in_batches` 方法和 `find_each` 方法一样，可以使用 `:batch_size` 和 `:start` 选项，还可使用常规的 `find` 方法中的大多数选项，但不能使用 `:order` 和 `:limit` 选项，因为这两个选项保留给 `find_in_batches` 方法内部使用。

条件查询
-------

`where` 方法用来指定限制获取记录的条件，用于 SQL 语句的 `WHERE` 子句。条件可使用字符串、数组或 Hash 指定。

### 纯字符串条件

如果查询时要使用条件，可以直接指定。例如 `Client.where("orders_count = '2'")`，获取 `orders_count` 字段为 `2` 的客户记录。

WARNING: 使用纯字符串指定条件可能导致 SQL 注入漏洞。例如，`Client.where("first_name LIKE '%#{params[:first_name]}%'")`，这里的条件就不安全。推荐使用的条件指定方式是数组，请阅读下一节。

### 数组条件

如果数字是在别处动态生成的话应该怎么处理呢？可用下面的查询：

```ruby
Client.where("orders_count = ?", params[:orders])
```

Active Record 会先处理第一个元素中的条件，然后使用后续元素替换第一个元素中的问号（`?`）。

指定多个条件的方式如下：

```ruby
Client.where("orders_count = ? AND locked = ?", params[:orders], false)
```

在这个例子中，第一个问号会替换成 `params[:orders]` 的值；第二个问号会替换成 `false` 在 SQL 中对应的值，具体的值视所用的适配器而定。

下面这种形式

```ruby
Client.where("orders_count = ?", params[:orders])
```

要比这种形式好

```ruby
Client.where("orders_count = #{params[:orders]}")
```

因为前者传入的参数更安全。直接在条件字符串中指定的条件会原封不动的传给数据库。也就是说，即使用户不怀好意，条件也会转义。如果这么做，整个数据库就处在一个危险境地，只要用户发现可以接触数据库，就能做任何想做的事。所以，千万别直接在条件字符串中使用参数。

TIP: 关于 SQL 注入更详细的介绍，请阅读“[Ruby on Rails 安全指南](security.html#sql-injection)”

#### 条件中的占位符

除了使用问号占位之外，在数组条件中还可使用键值对 Hash 形式的占位符：

```ruby
Client.where("created_at >= :start_date AND created_at <= :end_date",
  {start_date: params[:start_date], end_date: params[:end_date]})
```

如果条件中有很多参数，使用这种形式可读性更高。

### Hash 条件

Active Record 还允许使用 Hash 条件，提高条件语句的可读性。使用 Hash 条件时，传入 Hash 的键是要设定条件的字段，值是要设定的条件。

NOTE: 在 Hash 条件中只能指定相等。范围和子集这三种条件。

#### 相等

```ruby
Client.where(locked: true)
```

字段的名字还可使用字符串表示：

```ruby
Client.where('locked' => true)
```

在 `belongs_to` 关联中，如果条件中的值是模型对象，可用关联键表示。这种条件指定方式也可用于多态关联。

```ruby
Post.where(author: author)
Author.joins(:posts).where(posts: { author: author })
```

NOTE: 条件的值不能为 Symbol。例如，不能这么指定条件：`Client.where(status: :active)`。

#### 范围

```ruby
Client.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)
```

指定这个条件后，会使用 SQL `BETWEEN` 子句查询昨天创建的客户：

```sql
SELECT * FROM clients WHERE (clients.created_at BETWEEN '2008-12-21 00:00:00' AND '2008-12-22 00:00:00')
```

这段代码演示了[数组条件](#array-conditions)的简写形式。

#### 子集

如果想使用 `IN` 子句查询记录，可以在 Hash 条件中使用数组：

```ruby
Client.where(orders_count: [1,3,5])
```

上述代码生成的 SQL 语句如下：

```sql
SELECT * FROM clients WHERE (clients.orders_count IN (1,3,5))
```

### `NOT` 条件

SQL `NOT` 查询可用 `where.not` 方法构建。

```ruby
Post.where.not(author: author)
```

也即是说，这个查询首先调用没有参数的 `where` 方法，然后再调用 `not` 方法。

排序
----

要想按照特定的顺序从数据库中获取记录，可以使用 `order` 方法。

例如，想按照 `created_at` 的升序方式获取一些记录，可以这么做：

```ruby
Client.order(:created_at)
# OR
Client.order("created_at")
```

还可使用 `ASC` 或 `DESC` 指定排序方式：

```ruby
Client.order(created_at: :desc)
# OR
Client.order(created_at: :asc)
# OR
Client.order("created_at DESC")
# OR
Client.order("created_at ASC")
```

或者使用多个字段排序：

```ruby
Client.order(orders_count: :asc, created_at: :desc)
# OR
Client.order(:orders_count, created_at: :desc)
# OR
Client.order("orders_count ASC, created_at DESC")
# OR
Client.order("orders_count ASC", "created_at DESC")
```

如果想在不同的上下文中多次调用 `order`，可以在前一个 `order` 后再调用一次：

```ruby
Client.order("orders_count ASC").order("created_at DESC")
# SELECT * FROM clients ORDER BY orders_count ASC, created_at DESC
```

查询指定字段
-----------

默认情况下，`Model.find` 使用 `SELECT *` 查询所有字段。

要查询部分字段，可使用 `select` 方法。

例如，只查询 `viewable_by` 和 `locked` 字段：

```ruby
Client.select("viewable_by, locked")
```

上述查询使用的 SQL 语句如下：

```sql
SELECT viewable_by, locked FROM clients
```

使用时要注意，因为模型对象只会使用选择的字段初始化。如果字段不能初始化模型对象，会得到以下异常：

```bash
ActiveModel::MissingAttributeError: missing attribute: <attribute>
```

其中 `<attribute>` 是所查询的字段。`id` 字段不会抛出 `ActiveRecord::MissingAttributeError` 异常，所以在关联中使用时要注意，因为关联需要 `id` 字段才能正常使用。

如果查询时希望指定字段的同值记录只出现一次，可以使用 `distinct` 方法：

```ruby
Client.select(:name).distinct
```

上述方法生成的 SQL 语句如下：

```sql
SELECT DISTINCT name FROM clients
```

查询后还可以删除唯一性限制：

```ruby
query = Client.select(:name).distinct
# => Returns unique names

query.distinct(false)
# => Returns all names, even if there are duplicates
```

限量和偏移
---------

要想在 `Model.find` 方法中使用 SQL `LIMIT` 子句，可使用 `limit` 和 `offset` 方法。

`limit` 方法指定获取的记录数量，`offset` 方法指定在返回结果之前跳过多少个记录。例如：

```ruby
Client.limit(5)
```

上述查询最大只会返回 5 各客户对象，因为没指定偏移，多以会返回数据表中的前 5 个记录。生成的 SQL 语句如下：

```sql
SELECT * FROM clients LIMIT 5
```

再加上 `offset` 方法：

```ruby
Client.limit(5).offset(30)
```

这时会从第 31 个记录开始，返回最多 5 个客户对象。生成的 SQL 语句如下：

```sql
SELECT * FROM clients LIMIT 5 OFFSET 30
```

分组
----

要想在查询时使用 SQL `GROUP BY` 子句，可以使用 `group` 方法。

例如，如果想获取一组订单的创建日期，可以这么做：

```ruby
Order.select("date(created_at) as ordered_date, sum(price) as total_price").group("date(created_at)")
```

上述查询会只会为相同日期下的订单创建一个 `Order` 对象。

生成的 SQL 语句如下：

```sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
```

分组筛选
-------

SQL 使用 `HAVING` 子句指定 `GROUP BY` 分组的条件。在 `Model.find` 方法中可使用 `:having` 选项指定 `HAVING` 子句。

例如：

```ruby
Order.select("date(created_at) as ordered_date, sum(price) as total_price").
  group("date(created_at)").having("sum(price) > ?", 100)
```

生成的 SQL 如下：

```sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
HAVING sum(price) > 100
```

这个查询只会为同一天下的订单创建一个 `Order` 对象，而且这一天的订单总额要大于 $100。

条件覆盖
-------

### `unscope`

如果要删除某个条件可使用 `unscope` 方法。例如：

```ruby
Post.where('id > 10').limit(20).order('id asc').unscope(:order)
```

生成的 SQL 语句如下：

```sql
SELECT * FROM posts WHERE id > 10 LIMIT 20

# Original query without `unscope`
SELECT * FROM posts WHERE id > 10 ORDER BY id asc LIMIT 20
```

`unscope` 还可删除 `WHERE` 子句中的条件。例如：

```ruby
Post.where(id: 10, trashed: false).unscope(where: :id)
# SELECT "posts".* FROM "posts" WHERE trashed = 0
```

`unscope` 还可影响合并后的查询：

```ruby
Post.order('id asc').merge(Post.unscope(:order))
# SELECT "posts".* FROM "posts"
```

### `only`

查询条件还可使用 `only` 方法覆盖。例如：

```ruby
Post.where('id > 10').limit(20).order('id desc').only(:order, :where)
```

执行的 SQL 语句如下：

```sql
SELECT * FROM posts WHERE id > 10 ORDER BY id DESC

# Original query without `only`
SELECT "posts".* FROM "posts" WHERE (id > 10) ORDER BY id desc LIMIT 20
```

### `reorder`

`reorder` 方法覆盖原来的 `order` 条件。例如：

```ruby
class Post < ActiveRecord::Base
  ..
  ..
  has_many :comments, -> { order('posted_at DESC') }
end

Post.find(10).comments.reorder('name')
```

执行的 SQL 语句如下：

```sql
SELECT * FROM posts WHERE id = 10 ORDER BY name
```

没用 `reorder` 方法时执行的 SQL 语句如下：

```sql
SELECT * FROM posts WHERE id = 10 ORDER BY posted_at DESC
```

### `reverse_order`

`reverse_order` 方法翻转 `ORDER` 子句的条件。

```ruby
Client.where("orders_count > 10").order(:name).reverse_order
```

执行的 SQL 语句如下：

```sql
SELECT * FROM clients WHERE orders_count > 10 ORDER BY name DESC
```

如果查询中没有使用 `ORDER` 子句，`reverse_order` 方法会按照主键的逆序查询：

```ruby
Client.where("orders_count > 10").reverse_order
```

执行的 SQL 语句如下：

```sql
SELECT * FROM clients WHERE orders_count > 10 ORDER BY clients.id DESC
```

这个方法**没有**参数。

### `rewhere`

`rewhere` 方法覆盖前面的 `where` 条件。例如：

```ruby
Post.where(trashed: true).rewhere(trashed: false)
```

执行的 SQL 语句如下：

```sql
SELECT * FROM posts WHERE `trashed` = 0
```

如果不使用 `rewhere` 方法，写成：

```ruby
Post.where(trashed: true).where(trashed: false)
```

执行的 SQL 语句如下：

```sql
SELECT * FROM posts WHERE `trashed` = 1 AND `trashed` = 0
```

空关系
------

`none` 返回一个可链接的关系，没有相应的记录。`none` 方法返回对象的后续条件查询，得到的还是空关系。如果想以可链接的方式响应可能无返回结果的方法或者作用域，可使用 `none` 方法。

```ruby
Post.none # returns an empty Relation and fires no queries.
```

```ruby
# The visible_posts method below is expected to return a Relation.
@posts = current_user.visible_posts.where(name: params[:name])

def visible_posts
  case role
  when 'Country Manager'
    Post.where(country: country)
  when 'Reviewer'
    Post.published
  when 'Bad User'
    Post.none # => returning [] or nil breaks the caller code in this case
  end
end
```

只读对象
-------

Active Record 提供了 `readonly` 方法，禁止修改获取的对象。试图修改只读记录的操作不会成功，而且会抛出 `ActiveRecord::ReadOnlyRecord` 异常。

```ruby
client = Client.readonly.first
client.visits += 1
client.save
```

因为把 `client` 设为了只读对象，所以上述代码调用 `client.save` 方法修改 `visits` 的值时会抛出 `ActiveRecord::ReadOnlyRecord` 异常。

更新时锁定记录
------------

锁定可以避免更新记录时的条件竞争，也能保证原子更新。

Active Record 提供了两种锁定机制：

* 乐观锁定
* 悲观锁定

### 乐观锁定

乐观锁定允许多个用户编辑同一个记录，假设数据发生冲突的可能性最小。Rails 会检查读取记录后是否有其他程序在修改这个记录。如果检测到有其他程序在修改，就会抛出 `ActiveRecord::StaleObjectError` 异常，忽略改动。

**乐观锁定字段**

为了使用乐观锁定，数据表中要有一个类型为整数的 `lock_version` 字段。每次更新记录时，Active Record 都会增加 `lock_version` 字段的值。如果更新请求中的 `lock_version` 字段值比数据库中的 `lock_version` 字段值小，会抛出 `ActiveRecord::StaleObjectError` 异常，更新失败。例如：

```ruby
c1 = Client.find(1)
c2 = Client.find(1)

c1.first_name = "Michael"
c1.save

c2.name = "should fail"
c2.save # Raises an ActiveRecord::StaleObjectError
```

抛出异常后，你要负责处理冲突，可以回滚操作、合并操作或者使用其他业务逻辑处理。

乐观锁定可以使用 `ActiveRecord::Base.lock_optimistically = false` 关闭。

要想修改 `lock_version` 字段的名字，可以使用 `ActiveRecord::Base` 提供的 `locking_column` 类方法：

```ruby
class Client < ActiveRecord::Base
  self.locking_column = :lock_client_column
end
```

### 悲观锁定

悲观锁定使用底层数据库提供的锁定机制。使用 `lock` 方法构建的关系在所选记录上生成一个“互斥锁”（exclusive lock）。使用 `lock` 方法构建的关系一般都放入事务中，避免死锁。

例如：

```ruby
Item.transaction do
  i = Item.lock.first
  i.name = 'Jones'
  i.save
end
```

在 MySQL 中，上述代码生成的 SQL 如下：

```sql
SQL (0.2ms)   BEGIN
Item Load (0.3ms)   SELECT * FROM `items` LIMIT 1 FOR UPDATE
Item Update (0.4ms)   UPDATE `items` SET `updated_at` = '2009-02-07 18:05:56', `name` = 'Jones' WHERE `id` = 1
SQL (0.8ms)   COMMIT
```

`lock` 方法还可以接受 SQL 语句，使用其他锁定类型。例如，MySQL 中有一个语句是 `LOCK IN SHARE MODE`，会锁定记录，但还是允许其他查询读取记录。要想使用这个语句，直接传入 `lock` 方法即可：

```ruby
Item.transaction do
  i = Item.lock("LOCK IN SHARE MODE").find(1)
  i.increment!(:views)
end
```

如果已经创建了模型实例，可以在事务中加上这种锁定，如下所示：

```ruby
item = Item.first
item.with_lock do
  # This block is called within a transaction,
  # item is already locked.
  item.increment!(:views)
end
```

连接数据表
---------

Active Record 提供了一个查询方法名为 `joins`，用来指定 SQL `JOIN` 子句。`joins` 方法的用法有很多种。

### 使用字符串形式的 SQL 语句

在 `joins` 方法中可以直接使用 `JOIN` 子句的 SQL：

```ruby
Client.joins('LEFT OUTER JOIN addresses ON addresses.client_id = clients.id')
```

生成的 SQL 语句如下：

```sql
SELECT clients.* FROM clients LEFT OUTER JOIN addresses ON addresses.client_id = clients.id
```

### 使用数组或 Hash 指定具名关联

WARNING: 这种方法只用于 `INNER JOIN`。

使用 `joins` 方法时，可以使用声明[关联](association_basics.html)时使用的关联名指定 `JOIN` 子句。

例如，假如按照如下方式定义 `Category`、`Post`、`Comment`、`Guest` 和 `Tag` 模型：

```ruby
class Category < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :category
  has_many :comments
  has_many :tags
end

class Comment < ActiveRecord::Base
  belongs_to :post
  has_one :guest
end

class Guest < ActiveRecord::Base
  belongs_to :comment
end

class Tag < ActiveRecord::Base
  belongs_to :post
end
```

下面各种用法能都使用 `INNER JOIN` 子句生成正确的连接查询：

#### 连接单个关联

```ruby
Category.joins(:posts)
```

生成的 SQL 语句如下：

```sql
SELECT categories.* FROM categories
  INNER JOIN posts ON posts.category_id = categories.id
```

用人类语言表达，上述查询的意思是，“使用文章的分类创建分类对象”。注意，分类对象可能有重复，因为多篇文章可能属于同一分类。如果不想出现重复，可使用 `Category.joins(:posts).uniq` 方法。

#### 连接多个关联

```ruby
Post.joins(:category, :comments)
```

生成的 SQL 语句如下：

```sql
SELECT posts.* FROM posts
  INNER JOIN categories ON posts.category_id = categories.id
  INNER JOIN comments ON comments.post_id = posts.id
```

用人类语言表达，上述查询的意思是，“返回指定分类且至少有一个评论的所有文章”。注意，如果文章有多个评论，同个文章对象会出现多次。

#### 连接一层嵌套关联

```ruby
Post.joins(comments: :guest)
```

生成的 SQL 语句如下：

```sql
SELECT posts.* FROM posts
  INNER JOIN comments ON comments.post_id = posts.id
  INNER JOIN guests ON guests.comment_id = comments.id
```

用人类语言表达，上述查询的意思是，“返回有一个游客发布评论的所有文章”。

#### 连接多层嵌套关联

```ruby
Category.joins(posts: [{ comments: :guest }, :tags])
```

生成的 SQL 语句如下：

```sql
SELECT categories.* FROM categories
  INNER JOIN posts ON posts.category_id = categories.id
  INNER JOIN comments ON comments.post_id = posts.id
  INNER JOIN guests ON guests.comment_id = comments.id
  INNER JOIN tags ON tags.post_id = posts.id
```

### 指定用于连接数据表上的条件

作用在连接数据表上的条件可以使用[数组](#array-conditions)和[字符串](#pure-string-conditions)指定。[Hash 形式的条件]((#hash-conditions)使用的句法有点特殊：

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Client.joins(:orders).where('orders.created_at' => time_range)
```

还有一种更简洁的句法是使用嵌套 Hash：

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Client.joins(:orders).where(orders: { created_at: time_range })
```

上述查询会获取昨天下订单的所有客户对象，再次用到了 SQL `BETWEEN` 语句。

按需加载关联
-----------

使用 `Model.find` 方法获取对象的关联记录时，按需加载机制会使用尽量少的查询次数。

**N + 1 查询问题**

假设有如下的代码，获取 10 个客户对象，并把客户的邮编打印出来

```ruby
clients = Client.limit(10)

clients.each do |client|
  puts client.address.postcode
end
```

上述代码初看起来很好，但问题在于查询的总次数。上述代码总共会执行 1（获取 10 个客户记录）+ 10（分别获取 10 个客户的地址）= *11* 次查询。

**N + 1 查询的解决办法**

在 Active Record 中可以进一步指定要加载的所有关联，调用 `Model.find` 方法是使用 `includes` 方法实现。使用 `includes` 后，Active Record 会使用尽可能少的查询次数加载所有指定的关联。

我们可以使用按需加载机制加载客户的地址，把 `Client.limit(10)` 改写成：

```ruby
clients = Client.includes(:address).limit(10)

clients.each do |client|
  puts client.address.postcode
end
```

和前面的 **11** 次查询不同，上述代码只会执行 **2** 次查询：

```sql
SELECT * FROM clients LIMIT 10
SELECT addresses.* FROM addresses
  WHERE (addresses.client_id IN (1,2,3,4,5,6,7,8,9,10))
```

### 按需加载多个关联

调用 `Model.find` 方法时，使用 `includes` 方法可以一次加载任意数量的关联，加载的关联可以通过数组、Hash、嵌套 Hash 指定。

#### 用数组指定多个关联

```ruby
Post.includes(:category, :comments)
```

上述代码会加载所有文章，以及和每篇文章关联的分类和评论。

#### 使用 Hash 指定嵌套关联

```ruby
Category.includes(posts: [{ comments: :guest }, :tags]).find(1)
```

上述代码会获取 ID 为 1 的分类，按需加载所有关联的文章，文章的标签和评论，以及每个评论的 `guest` 关联。

### 指定用于按需加载关联上的条件

虽然 Active Record 允许使用 `joins` 方法指定用于按需加载关联上的条件，但是推荐的做法是使用[连接数据表](#joining-tables)。

如果非要这么做，可以按照常规方式使用 `where` 方法。

```ruby
Post.includes(:comments).where("comments.visible" => true)
```

上述代码生成的查询中会包含 `LEFT OUTER JOIN` 子句，而 `joins` 方法生成的查询使用的是 `INNER JOIN` 子句。

```ruby
SELECT "posts"."id" AS t0_r0, ... "comments"."updated_at" AS t1_r5 FROM "posts" LEFT OUTER JOIN "comments" ON "comments"."post_id" = "posts"."id" WHERE (comments.visible = 1)
```

如果没指定 `where` 条件，上述代码会生成两个查询语句。

如果像上面的代码一样使用 `includes`，即使所有文章都没有评论，也会加载所有文章。使用 `joins` 方法（`INNER JOIN`）时，必须满足连接条件，否则不会得到任何记录。

作用域
------

作用域把常用的查询定义成方法，在关联对象或模型上调用。在作用域中可以使用前面介绍的所有方法，例如 `where`、`joins` 和 `includes`。所有作用域方法都会返回一个 `ActiveRecord::Relation` 对象，允许继续调用其他方法（例如另一个作用域方法）。

要想定义简单的作用域，可在类中调用 `scope` 方法，传入执行作用域时运行的代码：

```ruby
class Post < ActiveRecord::Base
  scope :published, -> { where(published: true) }
end
```

上述方式和直接定义类方法的作用一样，使用哪种方式只是个人喜好：

```ruby
class Post < ActiveRecord::Base
  def self.published
    where(published: true)
  end
end
```

作用域可以链在一起调用：

```ruby
class Post < ActiveRecord::Base
  scope :published,               -> { where(published: true) }
  scope :published_and_commented, -> { published.where("comments_count > 0") }
end
```

可以在模型类上调用 `published` 作用域：

```ruby
Post.published # => [published posts]
```

也可以在包含 `Post` 对象的关联上调用：

```ruby
category = Category.first
category.posts.published # => [published posts belonging to this category]
```

### 传入参数

作用域可接受参数：

```ruby
class Post < ActiveRecord::Base
  scope :created_before, ->(time) { where("created_at < ?", time) }
end
```

作用域的调用方法和类方法一样：

```ruby
Post.created_before(Time.zone.now)
```

不过这就和类方法的作用一样了。

```ruby
class Post < ActiveRecord::Base
  def self.created_before(time)
    where("created_at < ?", time)
  end
end
```

如果作用域要接受参数，推荐直接使用类方法。有参数的作用域也可在关联对象上调用：

```ruby
category.posts.created_before(time)
```

### 合并作用域

和 `where` 方法一样，作用域也可通过 `AND` 合并查询条件：

```ruby
class User < ActiveRecord::Base
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.active.inactive
# SELECT "users".* FROM "users" WHERE "users"."state" = 'active' AND "users"."state" = 'inactive'
```

作用域还可以 `where` 一起使用，生成的 SQL 语句会使用 `AND` 连接所有条件。

```ruby
User.active.where(state: 'finished')
# SELECT "users".* FROM "users" WHERE "users"."state" = 'active' AND "users"."state" = 'finished'
```

如果不想让最后一个 `WHERE` 子句获得优先权，可以使用 `Relation#merge` 方法。

```ruby
User.active.merge(User.inactive)
# SELECT "users".* FROM "users" WHERE "users"."state" = 'inactive'
```

使用作用域时要注意，`default_scope` 会添加到作用域和 `where` 方法指定的条件之前。

```ruby
class User < ActiveRecord::Base
  default_scope { where state: 'pending' }
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.all
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending'

User.active
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending' AND "users"."state" = 'active'

User.where(state: 'inactive')
# SELECT "users".* FROM "users" WHERE "users"."state" = 'pending' AND "users"."state" = 'inactive'
```

如上所示，`default_scope` 中的条件添加到了 `active` 和 `where` 之前。

### 指定默认作用域

如果某个作用域要用在模型的所有查询中，可以在模型中使用 `default_scope` 方法指定。

```ruby
class Client < ActiveRecord::Base
  default_scope { where("removed_at IS NULL") }
end
```

执行查询时使用的 SQL 语句如下：

```sql
SELECT * FROM clients WHERE removed_at IS NULL
```

如果默认作用域中的条件比较复杂，可以使用类方法的形式定义：

```ruby
class Client < ActiveRecord::Base
  def self.default_scope
    # Should return an ActiveRecord::Relation.
  end
end
```

### 删除所有作用域

如果基于某些原因想删除作用域，可以使用 `unscoped` 方法。如果模型中定义了 `default_scope`，而在这个作用域中不需要使用，就可以使用 `unscoped` 方法。

```ruby
Client.unscoped.load
```

`unscoped` 方法会删除所有作用域，在数据表中执行常规查询。

注意，不能在作用域后链式调用 `unscoped`，这时可以使用代码块形式的 `unscoped` 方法：

```ruby
Client.unscoped {
  Client.created_before(Time.zone.now)
}
```

动态查询方法
-----------

Active Record 为数据表中的每个字段都提供了一个查询方法。例如，在 `Client` 模型中有个 `first_name` 字段，那么 Active Record 就会生成 `find_by_first_name` 方法。如果在 `Client` 模型中有个 `locked` 字段，就有一个 `find_by_locked` 方法。

在这些动态生成的查询方法后，可以加上感叹号（`!`），例如 `Client.find_by_name!("Ryan")`。此时，如果找不到记录就会抛出 `ActiveRecord::RecordNotFound` 异常。

如果想同时查询 `first_name` 和 `locked` 字段，可以用 `and` 把两个字段连接起来，获得所需的查询方法，例如 `Client.find_by_first_name_and_locked("Ryan", true)`。

查找或构建新对象
--------------

NOTE: 某些动态查询方法在 Rails 4.0 中已经启用，会在 Rails 4.1 中删除。推荐的做法是使用 Active Record 作用域。废弃的方法可以在这个 gem 中查看：<https://github.com/rails/activerecord-deprecated_finders>。

我们经常需要在查询不到记录时创建一个新记录。这种需求可以使用 `find_or_create_by` 或 `find_or_create_by!` 方法实现。

### `find_or_create_by`

`find_or_create_by` 方法首先检查指定属性对应的记录是否存在，如果不存在就调用 `create` 方法。我们来看一个例子。

假设你想查找一个名为“Andy”的客户，如果这个客户不存在就新建。这个需求可以使用下面的代码完成：

```ruby
Client.find_or_create_by(first_name: 'Andy')
# => #<Client id: 1, first_name: "Andy", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">
```

上述方法生成的 SQL 语句如下：

```sql
SELECT * FROM clients WHERE (clients.first_name = 'Andy') LIMIT 1
BEGIN
INSERT INTO clients (created_at, first_name, locked, orders_count, updated_at) VALUES ('2011-08-30 05:22:57', 'Andy', 1, NULL, '2011-08-30 05:22:57')
COMMIT
```

`find_or_create_by` 方法返回现有的记录或者新建的记录。在上面的例子中，名为“Andy”的客户不存在，所以会新建一个记录，然后将其返回。

新纪录可能没有存入数据库，这取决于是否能通过数据验证（就像 `create` 方法一样）。

假设创建新记录时，要把 `locked` 属性设为 `false`，但不想在查询中设置。例如，我们要查询一个名为“Andy”的客户，如果这个客户不存在就新建一个，而且 `locked` 属性为 `false`。

这种需求有两种实现方法。第一种，使用 `create_with` 方法：

```ruby
Client.create_with(locked: false).find_or_create_by(first_name: 'Andy')
```

第二种，使用代码块：

```ruby
Client.find_or_create_by(first_name: 'Andy') do |c|
  c.locked = false
end
```

代码块中的代码只会在创建客户之后执行。再次运行这段代码时，会忽略代码块中的代码。

### `find_or_create_by!`

还可使用 `find_or_create_by!` 方法，如果新纪录不合法，会抛出异常。本文不涉及数据验证，假设已经在 `Client` 模型中定义了下面的验证：

```ruby
validates :orders_count, presence: true
```

如果创建新 `Client` 对象时没有指定 `orders_count` 属性的值，这个对象就是不合法的，会抛出以下异常：

```ruby
Client.find_or_create_by!(first_name: 'Andy')
# => ActiveRecord::RecordInvalid: Validation failed: Orders count can't be blank
```

### `find_or_initialize_by`

`find_or_initialize_by` 方法和 `find_or_create_by` 的作用差不多，但不调用 `create` 方法，而是 `new` 方法。也就是说新建的模型实例在内存中，没有存入数据库。继续使用前面的例子，现在我们要查询的客户名为“Nick”：

```ruby
nick = Client.find_or_initialize_by(first_name: 'Nick')
# => <Client id: nil, first_name: "Nick", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">

nick.persisted?
# => false

nick.new_record?
# => true
```

因为对象不会存入数据库，上述代码生成的 SQL 语句如下：

```sql
SELECT * FROM clients WHERE (clients.first_name = 'Nick') LIMIT 1
```

如果想把对象存入数据库，调用 `save` 方法即可：

```ruby
nick.save
# => true
```

使用 SQL 语句查询
----------------

如果想使用 SQL 语句查询数据表中的记录，可以使用 `find_by_sql` 方法。就算只找到一个记录，`find_by_sql` 方法也会返回一个由记录组成的数组。例如，可以运行下面的查询：

```ruby
Client.find_by_sql("SELECT * FROM clients
  INNER JOIN orders ON clients.id = orders.client_id
  ORDER BY clients.created_at desc")
```

`find_by_sql` 方法提供了一种定制查询的简单方式。

### `select_all`

`find_by_sql` 方法有一个近亲，名为 `connection#select_all`。和 `find_by_sql` 一样，`select_all` 方法会使用 SQL 语句查询数据库，获取记录，但不会初始化对象。`select_all` 返回的结果是一个由 Hash 组成的数组，每个 Hash 表示一个记录。

```ruby
Client.connection.select_all("SELECT * FROM clients WHERE id = '1'")
```

### `pluck`

`pluck` 方法可以在模型对应的数据表中查询一个或多个字段，其参数是一组字段名，返回结果是由各字段的值组成的数组。

```ruby
Client.where(active: true).pluck(:id)
# SELECT id FROM clients WHERE active = 1
# => [1, 2, 3]

Client.distinct.pluck(:role)
# SELECT DISTINCT role FROM clients
# => ['admin', 'member', 'guest']

Client.pluck(:id, :name)
# SELECT clients.id, clients.name FROM clients
# => [[1, 'David'], [2, 'Jeremy'], [3, 'Jose']]
```

如下的代码：

```ruby
Client.select(:id).map { |c| c.id }
# or
Client.select(:id).map(&:id)
# or
Client.select(:id, :name).map { |c| [c.id, c.name] }
```

可用 `pluck` 方法实现：

```ruby
Client.pluck(:id)
# or
Client.pluck(:id, :name)
```

和 `select` 方法不一样，`pluck` 直接把查询结果转换成 Ruby 数组，不生成 Active Record 对象，可以提升大型查询或常用查询的执行效率。但 `pluck` 方法不会使用重新定义的属性方法处理查询结果。例如：

```ruby
class Client < ActiveRecord::Base
  def name
    "I am #{super}"
  end
end

Client.select(:name).map &:name
# => ["I am David", "I am Jeremy", "I am Jose"]

Client.pluck(:name)
# => ["David", "Jeremy", "Jose"]
```

而且，与 `select` 和其他 `Relation` 作用域不同的是，`pluck` 方法会直接执行查询，因此后面不能和其他作用域链在一起，但是可以链接到已经执行的作用域之后：

```ruby
Client.pluck(:name).limit(1)
# => NoMethodError: undefined method `limit' for #<Array:0x007ff34d3ad6d8>

Client.limit(1).pluck(:name)
# => ["David"]
```

### `ids`

`ids` 方法可以直接获取数据表的主键。

```ruby
Person.ids
# SELECT id FROM people
```

```ruby
class Person < ActiveRecord::Base
  self.primary_key = "person_id"
end

Person.ids
# SELECT person_id FROM people
```

检查对象是否存在
--------------

如果只想检查对象是否存在，可以使用 `exists?` 方法。这个方法使用的数据库查询和 `find` 方法一样，但不会返回对象或对象集合，而是返回 `true` 或 `false`。

```ruby
Client.exists?(1)
```

`exists?` 方法可以接受多个值，但只要其中一个记录存在，就会返回 `true`。

```ruby
Client.exists?(id: [1,2,3])
# or
Client.exists?(name: ['John', 'Sergei'])
```

在模型或关系上调用 `exists?` 方法时，可以不指定任何参数。

```ruby
Client.where(first_name: 'Ryan').exists?
```

在上述代码中，只要有一个客户的 `first_name` 字段值为 `'Ryan'`，就会返回 `true`，否则返回 `false`。

```ruby
Client.exists?
```

在上述代码中，如果 `clients` 表是空的，会返回 `false`，否则返回 `true`。

在模型或关系中检查存在性时还可使用 `any?` 和 `many?` 方法。

```ruby
# via a model
Post.any?
Post.many?

# via a named scope
Post.recent.any?
Post.recent.many?

# via a relation
Post.where(published: true).any?
Post.where(published: true).many?

# via an association
Post.first.categories.any?
Post.first.categories.many?
```

计算
----

这里先以 `count` 方法为例，所有的选项都可在后面各方法中使用。

所有计算型方法都可直接在模型上调用：

```ruby
Client.count
# SELECT count(*) AS count_all FROM clients
```

或者在关系上调用：

```ruby
Client.where(first_name: 'Ryan').count
# SELECT count(*) AS count_all FROM clients WHERE (first_name = 'Ryan')
```

执行复杂计算时还可使用各种查询方法：

```ruby
Client.includes("orders").where(first_name: 'Ryan', orders: { status: 'received' }).count
```

上述代码执行的 SQL 语句如下：

```sql
SELECT count(DISTINCT clients.id) AS count_all FROM clients
  LEFT OUTER JOIN orders ON orders.client_id = client.id WHERE
  (clients.first_name = 'Ryan' AND orders.status = 'received')
```

### 计数

如果想知道模型对应的数据表中有多少条记录，可以使用 `Client.count` 方法。如果想更精确的计算设定了 `age` 字段的记录数，可以使用 `Client.count(:age)`。

`count` 方法可用的选项[如前所述](#calculations)。

### 平均值

如果想查看某个字段的平均值，可以使用 `average` 方法。用法如下：

```ruby
Client.average("orders_count")
```

这个方法会返回指定字段的平均值，得到的有可能是浮点数，例如 3.14159265。

`average` 方法可用的选项[如前所述](#calculations)。

### 最小值

如果想查看某个字段的最小值，可以使用 `minimum` 方法。用法如下：

```ruby
Client.minimum("age")
```

`minimum` 方法可用的选项[如前所述](#calculations)。

### 最大值

如果想查看某个字段的最大值，可以使用 `maximum` 方法。用法如下：

```ruby
Client.maximum("age")
```

`maximum` 方法可用的选项[如前所述](#calculations)。

### 求和

如果想查看所有记录中某个字段的总值，可以使用 `sum` 方法。用法如下：

```ruby
Client.sum("orders_count")
```

`sum` 方法可用的选项[如前所述](#calculations)。

执行 EXPLAIN 命令
----------------

可以在关系执行的查询中执行 EXPLAIN 命令。例如：

```ruby
User.where(id: 1).joins(:posts).explain
```

在 MySQL 中得到的输出如下：

```
EXPLAIN for: SELECT `users`.* FROM `users` INNER JOIN `posts` ON `posts`.`user_id` = `users`.`id` WHERE `users`.`id` = 1
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------------+
| id | select_type | table | type  | possible_keys | key     | key_len | ref   | rows | Extra       |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------------+
|  1 | SIMPLE      | users | const | PRIMARY       | PRIMARY | 4       | const |    1 |             |
|  1 | SIMPLE      | posts | ALL   | NULL          | NULL    | NULL    | NULL  |    1 | Using where |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------------+
2 rows in set (0.00 sec)
```

Active Record 会按照所用数据库 shell 的方式输出结果。所以，相同的查询在 PostgreSQL 中得到的输出如下：

```
EXPLAIN for: SELECT "users".* FROM "users" INNER JOIN "posts" ON "posts"."user_id" = "users"."id" WHERE "users"."id" = 1
                                  QUERY PLAN
------------------------------------------------------------------------------
 Nested Loop Left Join  (cost=0.00..37.24 rows=8 width=0)
   Join Filter: (posts.user_id = users.id)
   ->  Index Scan using users_pkey on users  (cost=0.00..8.27 rows=1 width=4)
         Index Cond: (id = 1)
   ->  Seq Scan on posts  (cost=0.00..28.88 rows=8 width=4)
         Filter: (posts.user_id = 1)
(6 rows)
```

按需加载会触发多次查询，而且有些查询要用到之前查询的结果。鉴于此，`explain` 方法会真正执行查询，然后询问查询计划。例如：

```ruby
User.where(id: 1).includes(:posts).explain
```

在 MySQL 中得到的输出如下：

```
EXPLAIN for: SELECT `users`.* FROM `users`  WHERE `users`.`id` = 1
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------+
| id | select_type | table | type  | possible_keys | key     | key_len | ref   | rows | Extra |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------+
|  1 | SIMPLE      | users | const | PRIMARY       | PRIMARY | 4       | const |    1 |       |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------+
1 row in set (0.00 sec)

EXPLAIN for: SELECT `posts`.* FROM `posts`  WHERE `posts`.`user_id` IN (1)
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra       |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
|  1 | SIMPLE      | posts | ALL  | NULL          | NULL | NULL    | NULL |    1 | Using where |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
1 row in set (0.00 sec)
```

### 解读 EXPLAIN 命令的输出结果

解读 EXPLAIN 命令的输出结果不在本文的范畴之内。下面列出的链接可以帮助你进一步了解相关知识：

* SQLite3: [EXPLAIN QUERY PLAN](http://www.sqlite.org/eqp.html)
* MySQL: [EXPLAIN 的输出格式](http://dev.mysql.com/doc/refman/5.6/en/explain-output.html)
* PostgreSQL: [使用 EXPLAIN](http://www.postgresql.org/docs/current/static/using-explain.html)
