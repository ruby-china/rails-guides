# Active Record 查询接口

本文介绍使用 Active Record 从数据库中检索数据的不同方法。

读完本文后，您将学到：

*   如何使用各种方法和条件查找记录；
*   如何指定所查找记录的排序方式、想要检索的属性、分组方式和其他特性；
*   如何使用预先加载以减少数据检索所需的数据库查询的数量；
*   如何使用动态查找方法；
*   如何通过方法链来连续使用多个 Active Record 方法；
*   如何检查某个记录是否存在；
*   如何在 Active Record 模型上做各种计算；
*   如何在关联上执行 `EXPLAIN` 命令。

-----------------------------------------------------------------------------

如果你习惯直接使用 SQL 来查找数据库记录，那么你通常会发现 Rails 为执行相同操作提供了更好的方式。在大多数情况下，Active Record 使你无需使用 SQL。

本文中的示例代码会用到下面的一个或多个模型：

TIP: 除非另有说明，下面所有模型都使用 `id` 作为主键。

```ruby
class Client < ApplicationRecord
  has_one :address
  has_many :orders
  has_and_belongs_to_many :roles
end
```

```ruby
class Address < ApplicationRecord
  belongs_to :client
end
```

```ruby
class Order < ApplicationRecord
  belongs_to :client, counter_cache: true
end
```

```ruby
class Role < ApplicationRecord
  has_and_belongs_to_many :clients
end
```

Active Record 会为你执行数据库查询，它和大多数数据库系统兼容，包括 MySQL、MariaDB、PostgreSQL 和 SQLite。不管使用哪个数据库系统，Active Record 方法的用法总是相同的。

<a class="anchor" id="retrieving-objects-from-the-database"></a>

## 从数据库中检索对象

Active Record 提供了几个用于从数据库中检索对象的查找方法。查找方法接受参数并执行指定的数据库查询，使我们无需直接编写 SQL。

下面列出这些查找方法：

*   `find`
*   `create_with`
*   `distinct`
*   `eager_load`
*   `extending`
*   `from`
*   `group`
*   `having`
*   `includes`
*   `joins`
*   `left_outer_joins`
*   `limit`
*   `lock`
*   `none`
*   `offset`
*   `order`
*   `preload`
*   `readonly`
*   `references`
*   `reorder`
*   `reverse_order`
*   `select`
*   `where`

返回集合的查找方法，如 `where` 和 `group`，返回一个 `ActiveRecord::Relation` 实例。查找单个记录的方法，如 `find` 和 `first`，返回相应模型的一个实例。

`Model.find(options)` 执行的主要操作可以概括为：

*   把提供的选项转换为等价的 SQL 查询。
*   触发 SQL 查询并从数据库中检索对应的结果。
*   为每个查询结果实例化对应的模型对象。
*   当存在回调时，先调用 `after_find` 回调再调用 `after_initialize` 回调。

<a class="anchor" id="retrieving-a-single-object"></a>

### 检索单个对象

Active Record 为检索单个对象提供了几个不同的方法。

<a class="anchor" id="find"></a>

#### `find` 方法

可以使用 `find` 方法检索指定主键对应的对象，指定主键时可以使用多个选项。例如：

```ruby
# 查找主键（ID）为 10 的客户
client = Client.find(10)
# => #<Client id: 10, first_name: "Ryan">
```

和上面的代码等价的 SQL 是：

```sql
SELECT * FROM clients WHERE (clients.id = 10) LIMIT 1
```

如果没有找到匹配的记录，`find` 方法抛出 `ActiveRecord::RecordNotFound` 异常。

还可以使用 `find` 方法查询多个对象，方法是调用 `find` 方法并传入主键构成的数组。返回值是包含所提供的主键的所有匹配记录的数组。例如：

```ruby
# 查找主键为 1 和 10 的客户
client = Client.find([1, 10]) # Or even Client.find(1, 10)
# => [#<Client id: 1, first_name: "Lifo">, #<Client id: 10, first_name: "Ryan">]
```

和上面的代码等价的 SQL 是：

```sql
SELECT * FROM clients WHERE (clients.id IN (1,10))
```

WARNING: 如果所提供的主键都没有匹配记录，那么 `find` 方法会抛出 `ActiveRecord::RecordNotFound` 异常。

<a class="anchor" id="take"></a>

#### `take` 方法

`take` 方法检索一条记录而不考虑排序。例如：

```ruby
client = Client.take
# => #<Client id: 1, first_name: "Lifo">
```

和上面的代码等价的 SQL 是：

```sql
SELECT * FROM clients LIMIT 1
```

如果没有找到记录，`take` 方法返回 `nil`，而不抛出异常。

`take` 方法接受数字作为参数，并返回不超过指定数量的查询结果。例如：

```ruby
client = Client.take(2)
# => [
#   #<Client id: 1, first_name: "Lifo">,
#   #<Client id: 220, first_name: "Sara">
# ]
```

和上面的代码等价的 SQL 是：

```sql
SELECT * FROM clients LIMIT 2
```

`take!` 方法的行为和 `take` 方法类似，区别在于如果没有找到匹配的记录，`take!` 方法抛出 `ActiveRecord::RecordNotFound` 异常。

TIP: 对于不同的数据库引擎，`take` 方法检索的记录可能不一样。

<a class="anchor" id="first"></a>

#### `first` 方法

`first` 方法默认查找按主键排序的第一条记录。例如：

```ruby
client = Client.first
# => #<Client id: 1, first_name: "Lifo">
```

和上面的代码等价的 SQL 是：

```sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

如果没有找到匹配的记录，`first` 方法返回 `nil`，而不抛出异常。

如果默认作用域 （请参阅 [应用默认作用域](#applying-a-default-scope)）包含排序方法，`first` 方法会返回按照这个顺序排序的第一条记录。

`first` 方法接受数字作为参数，并返回不超过指定数量的查询结果。例如：

```ruby
client = Client.first(3)
# => [
#   #<Client id: 1, first_name: "Lifo">,
#   #<Client id: 2, first_name: "Fifo">,
#   #<Client id: 3, first_name: "Filo">
# ]
```

和上面的代码等价的 SQL 是：

```sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 3
```

对于使用 `order` 排序的集合，`first` 方法返回按照指定属性排序的第一条记录。例如：

```ruby
client = Client.order(:first_name).first
# => #<Client id: 2, first_name: "Fifo">
```

和上面的代码等价的 SQL 是：

```sql
SELECT * FROM clients ORDER BY clients.first_name ASC LIMIT 1
```

`first!` 方法的行为和 `first` 方法类似，区别在于如果没有找到匹配的记录，`first!` 方法会抛出 `ActiveRecord::RecordNotFound` 异常。

<a class="anchor" id="last"></a>

#### `last` 方法

`last` 方法默认查找按主键排序的最后一条记录。例如：

```ruby
client = Client.last
# => #<Client id: 221, first_name: "Russel">
```

和上面的代码等价的 SQL 是：

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

如果没有找到匹配的记录，`last` 方法返回 `nil`，而不抛出异常。

如果默认作用域 （请参阅 [应用默认作用域](#applying-a-default-scope)）包含排序方法，`last` 方法会返回按照这个顺序排序的最后一条记录。

`last` 方法接受数字作为参数，并返回不超过指定数量的查询结果。例如：

```ruby
client = Client.last(3)
# => [
#   #<Client id: 219, first_name: "James">,
#   #<Client id: 220, first_name: "Sara">,
#   #<Client id: 221, first_name: "Russel">
# ]
```

和上面的代码等价的 SQL 是：

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 3
```

对于使用 `order` 排序的集合，`last` 方法返回按照指定属性排序的最后一条记录。例如：

```ruby
client = Client.order(:first_name).last
# => #<Client id: 220, first_name: "Sara">
```

和上面的代码等价的 SQL 是：

```sql
SELECT * FROM clients ORDER BY clients.first_name DESC LIMIT 1
```

`last!` 方法的行为和 `last` 方法类似，区别在于如果没有找到匹配的记录，`last!` 方法会抛出 `ActiveRecord::RecordNotFound` 异常。

<a class="anchor" id="find-by"></a>

#### `find_by` 方法

`find_by` 方法查找匹配指定条件的第一条记录。 例如：

```ruby
Client.find_by first_name: 'Lifo'
# => #<Client id: 1, first_name: "Lifo">

Client.find_by first_name: 'Jon'
# => nil
```

上面的代码等价于：

```ruby
Client.where(first_name: 'Lifo').take
```

和上面的代码等价的 SQL 是：

```sql
SELECT * FROM clients WHERE (clients.first_name = 'Lifo') LIMIT 1
```

`find_by!` 方法的行为和 `find_by` 方法类似，区别在于如果没有找到匹配的记录，`find_by!` 方法会抛出 `ActiveRecord::RecordNotFound` 异常。例如：

```ruby
Client.find_by! first_name: 'does not exist'
# => ActiveRecord::RecordNotFound
```

上面的代码等价于：

```ruby
Client.where(first_name: 'does not exist').take!
```

<a class="anchor" id="retrieving-multiple-objects-in-batches"></a>

### 批量检索多个对象

我们常常需要遍历大量记录，例如向大量用户发送时事通讯、导出数据等。

处理这类问题的方法看起来可能很简单：

```ruby
# 如果表中记录很多，可能消耗大量内存
User.all.each do |user|
  NewsMailer.weekly(user).deliver_now
end
```

但随着数据表越来越大，这种方法越来越行不通，因为 `User.all.each` 会使 Active Record 一次性取回整个数据表，为每条记录创建模型对象，并把整个模型对象数组保存在内存中。事实上，如果我们有大量记录，整个模型对象数组需要占用的空间可能会超过可用的内存容量。

Rails 提供了两种方法来解决这个问题，两种方法都是把整个记录分成多个对内存友好的批处理。第一种方法是通过 `find_each` 方法每次检索一批记录，然后逐一把每条记录作为模型传入块。第二种方法是通过 `find_in_batches` 方法每次检索一批记录，然后把这批记录整个作为模型数组传入块。

TIP: `find_each` 和 `find_in_batches` 方法用于大量记录的批处理，这些记录数量很大以至于不适合一次性保存在内存中。如果只需要循环 1000 条记录，那么应该首选常规的 `find` 方法。

<a class="anchor" id="find-each"></a>

#### `find_each` 方法

`find_each` 方法批量检索记录，然后逐一把每条记录作为模型传入块。在下面的例子中，`find_each` 方法取回 1000 条记录，然后逐一把每条记录作为模型传入块。

```ruby
User.find_each do |user|
  NewsMailer.weekly(user).deliver_now
end
```

这一过程会不断重复，直到处理完所有记录。

如前所述，`find_each` 能处理模型类，此外它还能处理关系：

```ruby
User.where(weekly_subscriber: true).find_each do |user|
  NewsMailer.weekly(user).deliver_now
end
```

前提是关系不能有顺序，因为这个方法在迭代时有既定的顺序。

如果接收者定义了顺序，具体行为取决于 `config.active_record.error_on_ignored_order` 旗标。设为 `true` 时，抛出 `ArgumentError` 异常，否则忽略顺序，发出提醒（这是默认设置）。这一行为可使用 `:error_on_ignore` 选项覆盖，详情参见下文。

**`:batch_size`**

`:batch_size` 选项用于指明批量检索记录时一次检索多少条记录。例如，一次检索 5000 条记录：

```ruby
User.find_each(batch_size: 5000) do |user|
  NewsMailer.weekly(user).deliver_now
end
```

**`:start`**

记录默认是按主键的升序方式取回的，这里的主键必须是整数。`:start` 选项用于配置想要取回的记录序列的第一个 ID，比这个 ID 小的记录都不会取回。这个选项有时候很有用，例如当需要恢复之前中断的批处理时，只需从最后一个取回的记录之后开始继续处理即可。

下面的例子把时事通讯发送给主键从 2000 开始的用户：

```ruby
User.find_each(start: 2000) do |user|
  NewsMailer.weekly(user).deliver_now
end
```

**`:finish`**

和 `:start` 选项类似，`:finish` 选项用于配置想要取回的记录序列的最后一个 ID，比这个 ID 大的记录都不会取回。这个选项有时候很有用，例如可以通过配置 `:start` 和 `:finish` 选项指明想要批处理的子记录集。

下面的例子把时事通讯发送给主键从 2000 到 10000 的用户：

```ruby
User.find_each(start: 2000, finish: 10000) do |user|
  NewsMailer.weekly(user).deliver_now
end
```

另一个例子是使用多个职程（worker）处理同一个进程队列。通过分别配置 `:start` 和 `:finish` 选项可以让每个职程每次都处理 10000 条记录。

**`:error_on_ignore`**

覆盖应用的配置，指定有顺序的关系是否抛出异常。

<a class="anchor" id="find-in-batches"></a>

#### `find_in_batches` 方法

`find_in_batches` 方法和 `find_each` 方法类似，两者都是批量检索记录。区别在于，`find_in_batches` 方法会把一批记录作为模型数组传入块，而不是像 `find_each` 方法那样逐一把每条记录作为模型传入块。下面的例子每次把 1000 张发票的数组一次性传入块（最后一次传入块的数组中的发票数量可能不到 1000）：

```ruby
# 一次把 1000 张发票组成的数组传给 add_invoices
Invoice.find_in_batches do |invoices|
  export.add_invoices(invoices)
end
```

如前所述，`find_in_batches` 能处理模型，也能处理关系：

```ruby
Invoice.pending.find_in_batches do |invoice|
  pending_invoices_export.add_invoices(invoices)
end
```

但是关系不能有顺序，因为这个方法在迭代时有既定的顺序。

<a class="anchor" id="options-for-find-in-batches"></a>

##### `find_in_batches` 方法的选项

`find_in_batches` 方法接受的选项与 `find_each` 方法一样。

<a class="anchor" id="conditions"></a>

## 条件查询

`where` 方法用于指明限制返回记录所使用的条件，相当于 SQL 语句的 `WHERE` 部分。条件可以使用字符串、数组或散列指定。

<a class="anchor" id="pure-string-conditions"></a>

### 纯字符串条件

可以直接用纯字符串为查找添加条件。例如，`Client.where("orders_count = '2'")` 会查找所有 `orders_count` 字段的值为 2 的客户记录。

WARNING: 使用纯字符串创建条件存在容易受到 SQL 注入攻击的风险。例如，`Client.where("first_name LIKE '%#{params[:first_name]}%'")` 是不安全的。在下一节中我们会看到，使用数组创建条件是推荐的做法。

<a class="anchor" id="array-conditions"></a>

### 数组条件

如果 `Client.where("orders_count = '2'")` 这个例子中的数字是变化的，比如说是从别处传递过来的参数，那么可以像下面这样进行查找：

```ruby
Client.where("orders_count = ?", params[:orders])
```

Active Record 会把第一个参数作为条件字符串，并用之后的其他参数来替换条件字符串中的问号（`?`）。

我们还可以指定多个条件：

```ruby
Client.where("orders_count = ? AND locked = ?", params[:orders], false)
```

在上面的例子中，第一个问号会被替换为 `params[:orders]` 的值，第二个问号会被替换为 `false` 在 SQL 中对应的值，这个值是什么取决于所使用的数据库适配器。

强烈推荐使用下面这种写法：

```ruby
Client.where("orders_count = ?", params[:orders])
```

而不是：

```ruby
Client.where("orders_count = #{params[:orders]}")
```

原因是出于参数的安全性考虑。把变量直接放入条件字符串会导致变量原封不动地传递给数据库，这意味着即使是恶意用户提交的变量也不会被转义。这样一来，整个数据库就处于风险之中，因为一旦恶意用户发现自己能够滥用数据库，他就可能做任何事情。所以，永远不要把参数直接放入条件字符串。

TIP: 关于 SQL 注入的危险性的更多介绍，请参阅 [SQL 注入](security.html#sql-injection)。

<a class="anchor" id="placeholder-conditions"></a>

#### 条件中的占位符

和问号占位符（`?`）类似，我们还可以在条件字符串中使用符号占位符，并通过散列提供符号对应的值：

```ruby
Client.where("created_at >= :start_date AND created_at <= :end_date",
  {start_date: params[:start_date], end_date: params[:end_date]})
```

如果条件中有很多变量，那么上面这种写法的可读性更高。

<a class="anchor" id="hash-conditions"></a>

### 散列条件

Active Record 还允许使用散列条件，以提高条件语句的可读性。使用散列条件时，散列的键指明需要限制的字段，键对应的值指明如何进行限制。

NOTE: 在散列条件中，只能进行相等性、范围和子集检查。

<a class="anchor" id="equality-conditions"></a>

#### 相等性条件

```ruby
Client.where(locked: true)
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT * FROM clients WHERE (clients.locked = 1)
```

其中字段名也可以是字符串：

```ruby
Client.where('locked' => true)
```

对于 `belongs_to` 关联来说，如果使用 Active Record 对象作为值，就可以使用关联键来指定模型。这种方法也适用于多态关联。

```ruby
Article.where(author: author)
Author.joins(:articles).where(articles: { author: author })
```

NOTE: 相等性条件中的值不能是符号。例如，`Client.where(status: :active)` 这种写法是错误的。

<a class="anchor" id="range-conditions"></a>

#### 范围条件

```ruby
Client.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)
```

上面的代码会使用 `BETWEEN` SQL 表达式查找所有昨天创建的客户记录：

```sql
SELECT * FROM clients WHERE (clients.created_at BETWEEN '2008-12-21 00:00:00' AND '2008-12-22 00:00:00')
```

这是 [数组条件](#array-conditions)中那个示例代码的更简短的写法。

<a class="anchor" id="subset-conditions"></a>

#### 子集条件

要想用 `IN` 表达式来查找记录，可以在散列条件中使用数组：

```ruby
Client.where(orders_count: [1,3,5])
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT * FROM clients WHERE (clients.orders_count IN (1,3,5))
```

<a class="anchor" id="not-conditions"></a>

### NOT 条件

可以用 `where.not` 创建 `NOT` SQL 查询：

```ruby
Client.where.not(locked: true)
```

也就是说，先调用没有参数的 `where` 方法，然后马上链式调用 `not` 方法，就可以生成这个查询。上面的代码会生成下面的 SQL 语句：

```sql
SELECT * FROM clients WHERE (clients.locked != 1)
```

<a class="anchor" id="ordering"></a>

## 排序

要想按特定顺序从数据库中检索记录，可以使用 `order` 方法。

例如，如果想按 `created_at` 字段的升序方式取回记录：

```ruby
Client.order(:created_at)
# 或
Client.order("created_at")
```

还可以使用 `ASC`（升序） 或 `DESC`（降序） 指定排序方式：

```ruby
Client.order(created_at: :desc)
# 或
Client.order(created_at: :asc)
# 或
Client.order("created_at DESC")
# 或
Client.order("created_at ASC")
```

或按多个字段排序：

```ruby
Client.order(orders_count: :asc, created_at: :desc)
# 或
Client.order(:orders_count, created_at: :desc)
# 或
Client.order("orders_count ASC, created_at DESC")
# 或
Client.order("orders_count ASC", "created_at DESC")
```

如果多次调用 `order` 方法，后续排序会在第一次排序的基础上进行：

```sql
Client.order("orders_count ASC").order("created_at DESC")
# SELECT * FROM clients ORDER BY orders_count ASC, created_at DESC
```

WARNING: 使用 **MySQL 5.7.5** 及以上版本时，若想从结果集合中选择字段，要使用 `select`、`pluck` 和 `ids` 等方法。如果 `order` 子句中使用的字段不在选择列表中，`order` 方法抛出 `ActiveRecord::StatementInvalid` 异常。从结果集合中选择字段的方法参见下一节。


<a class="anchor" id="selecting-specific-fields"></a>

## 选择特定字段

`Model.find` 默认使用 `select *` 从结果集中选择所有字段。

可以使用 `select` 方法从结果集中选择字段的子集。

例如，只选择 `viewable_by` 和 `locked` 字段：

```ruby
Client.select("viewable_by, locked")
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT viewable_by, locked FROM clients
```

请注意，上面的代码初始化的模型对象只包含了所选择的字段，这时如果访问这个模型对象未包含的字段就会抛出异常：

```
ActiveModel::MissingAttributeError: missing attribute: <attribute>
```

其中 `<attribute>` 是我们想要访问的字段。`id` 方法不会引发 `ActiveRecord::MissingAttributeError` 异常，因此在使用关联时一定要小心，因为只有当 `id` 方法正常工作时关联才能正常工作。

在查询时如果想让某个字段的同值记录只出现一次，可以使用 `distinct` 方法添加唯一性约束：

```ruby
Client.select(:name).distinct
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT DISTINCT name FROM clients
```

唯一性约束在添加之后还可以删除：

```ruby
query = Client.select(:name).distinct
# => 返回无重复的名字

query.distinct(false)
# => 返回所有名字，即使有重复
```

<a class="anchor" id="limit-and-offset"></a>

## 限量和偏移量

要想在 `Model.find` 生成的 SQL 语句中使用 `LIMIT` 子句，可以在关联上使用 `limit` 和 `offset` 方法。

`limit` 方法用于指明想要取回的记录数量，`offset` 方法用于指明取回记录时在第一条记录之前要跳过多少条记录。例如：

```ruby
Client.limit(5)
```

上面的代码会返回 5 条客户记录，因为没有使用 `offset` 方法，所以返回的这 5 条记录就是前 5 条记录。生成的 SQL 语句如下：

```sql
SELECT * FROM clients LIMIT 5
```

如果使用 `offset` 方法：

```ruby
Client.limit(5).offset(30)
```

这时会返回从第 31 条记录开始的 5 条记录。生成的 SQL 语句如下：

```sql
SELECT * FROM clients LIMIT 5 OFFSET 30
```

<a class="anchor" id="group"></a>

## 分组

要想在查找方法生成的 SQL 语句中使用 `GROUP BY` 子句，可以使用 `group` 方法。

例如，如果我们想根据订单创建日期查找订单记录：

```ruby
Order.select("date(created_at) as ordered_date, sum(price) as total_price").group("date(created_at)")
```

上面的代码会为数据库中同一天创建的订单创建 `Order` 对象。生成的 SQL 语句如下：

```sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
```

<a class="anchor" id="total-of-grouped-items"></a>

### 分组项目的总数

要想得到一次查询中分组项目的总数，可以在调用 `group` 方法后调用 `count` 方法。

```ruby
Order.group(:status).count
# => { 'awaiting_approval' => 7, 'paid' => 12 }
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT COUNT (*) AS count_all, status AS status
FROM "orders"
GROUP BY status
```

<a class="anchor" id="having"></a>

## `having` 方法

SQL 语句用 `HAVING` 子句指明 `GROUP BY` 字段的约束条件。要想在 `Model.find` 生成的 SQL 语句中使用 `HAVING` 子句，可以使用 `having` 方法。例如：

```ruby
Order.select("date(created_at) as ordered_date, sum(price) as total_price").
  group("date(created_at)").having("sum(price) > ?", 100)
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
HAVING sum(price) > 100
```

上面的查询会返回每个 `Order` 对象的日期和总价，查询结果按日期分组并排序，并且总价必须高于 100。

<a class="anchor" id="overriding-conditions"></a>

## 条件覆盖

<a class="anchor" id="unscope"></a>

### `unscope` 方法

可以使用 `unscope` 方法删除某些条件。 例如：

```ruby
Article.where('id > 10').limit(20).order('id asc').unscope(:order)
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT * FROM articles WHERE id > 10 LIMIT 20

# 没使用 `unscope` 之前的查询
SELECT * FROM articles WHERE id > 10 ORDER BY id asc LIMIT 20
```

还可以使用 `unscope` 方法删除 `where` 方法中的某些条件。例如：

```ruby
Article.where(id: 10, trashed: false).unscope(where: :id)
# SELECT "articles".* FROM "articles" WHERE trashed = 0
```

在关联中使用 `unscope` 方法，会对整个关联造成影响：

```ruby
Article.order('id asc').merge(Article.unscope(:order))
# SELECT "articles".* FROM "articles"
```

<a class="anchor" id="only"></a>

### `only` 方法

可以使用 `only` 方法覆盖某些条件。例如：

```ruby
Article.where('id > 10').limit(20).order('id desc').only(:order, :where)
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT * FROM articles WHERE id > 10 ORDER BY id DESC

# 没使用 `only` 之前的查询
SELECT "articles".* FROM "articles" WHERE (id > 10) ORDER BY id desc LIMIT 20
```

<a class="anchor" id="reorder"></a>

### `reorder` 方法

可以使用 `reorder` 方法覆盖默认作用域中的排序方式。例如：

```ruby
class Article < ApplicationRecord
  has_many :comments, -> { order('posted_at DESC') }
end
```

```ruby
Article.find(10).comments.reorder('name')
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT * FROM articles WHERE id = 10
SELECT * FROM comments WHERE article_id = 10 ORDER BY name
```

如果不使用 `reorder` 方法，那么会生成下面的 SQL 语句：

```sql
SELECT * FROM articles WHERE id = 10
SELECT * FROM comments WHERE article_id = 10 ORDER BY posted_at DESC
```

<a class="anchor" id="reverse-order"></a>

### `reverse_order` 方法

可以使用 `reverse_order` 方法反转排序条件。

```sql
Client.where("orders_count > 10").order(:name).reverse_order
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT * FROM clients WHERE orders_count > 10 ORDER BY name DESC
```

如果查询时没有使用 `order` 方法，那么 `reverse_order` 方法会使查询结果按主键的降序方式排序。

```ruby
Client.where("orders_count > 10").reverse_order
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT * FROM clients WHERE orders_count > 10 ORDER BY clients.id DESC
```

`reverse_order` 方法不接受任何参数。

<a class="anchor" id="rewhere"></a>

### `rewhere` 方法

可以使用 `rewhere` 方法覆盖 `where` 方法中指定的条件。例如：

```ruby
Article.where(trashed: true).rewhere(trashed: false)
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT * FROM articles WHERE `trashed` = 0
```

如果不使用 `rewhere` 方法而是再次使用 `where` 方法：

```sql
Article.where(trashed: true).where(trashed: false)
```

会生成下面的 SQL 语句：

```sql
SELECT * FROM articles WHERE `trashed` = 1 AND `trashed` = 0
```

<a class="anchor" id="null-relation"></a>

## 空关系

`none` 方法返回可以在链式调用中使用的、不包含任何记录的空关系。在这个空关系上应用后续条件链，会继续生成空关系。对于可能返回零结果、但又需要在链式调用中使用的方法或作用域，可以使用 `none` 方法来提供返回值。

```ruby
Article.none # 返回一个空 Relation 对象，而且不执行查询
```

```ruby
# 下面的 visible_articles 方法期待返回一个空 Relation 对象
@articles = current_user.visible_articles.where(name: params[:name])

def visible_articles
  case role
  when 'Country Manager'
    Article.where(country: country)
  when 'Reviewer'
    Article.published
  when 'Bad User'
    Article.none # => 如果这里返回 [] 或 nil，会导致调用方出错
  end
end
```

<a class="anchor" id="readonly-objects"></a>

## 只读对象

在关联中使用 Active Record 提供的 `readonly` 方法，可以显式禁止修改任何返回对象。如果尝试修改只读对象，不但不会成功，还会抛出 `ActiveRecord::ReadOnlyRecord` 异常。

```ruby
client = Client.readonly.first
client.visits += 1
client.save
```

在上面的代码中，`client` 被显式设置为只读对象，因此在更新 `client.visits` 的值后调用 `client.save` 会抛出 `ActiveRecord::ReadOnlyRecord` 异常。

<a class="anchor" id="locking-records-for-update"></a>

## 在更新时锁定记录

在数据库中，锁定用于避免更新记录时的条件竞争，并确保原子更新。

Active Record 提供了两种锁定机制：

*   乐观锁定
*   悲观锁定

<a class="anchor" id="optimistic-locking"></a>

### 乐观锁定

乐观锁定允许多个用户访问并编辑同一记录，并假设数据发生冲突的可能性最小。其原理是检查读取记录后是否有其他进程尝试更新记录，如果有就抛出 `ActiveRecord::StaleObjectError` 异常，并忽略该更新。

<a class="anchor" id="optimistic-locking-column"></a>

#### 字段的乐观锁定

为了使用乐观锁定，数据表中需要有一个整数类型的 `lock_version` 字段。每次更新记录时，Active Record 都会增加 `lock_version` 字段的值。如果更新请求中 `lock_version` 字段的值比当前数据库中 `lock_version` 字段的值小，更新请求就会失败，并抛出 `ActiveRecord::StaleObjectError` 异常。例如：

```ruby
c1 = Client.find(1)
c2 = Client.find(1)

c1.first_name = "Michael"
c1.save

c2.name = "should fail"
c2.save # 抛出 ActiveRecord::StaleObjectError
```

抛出异常后，我们需要救援异常并处理冲突，或回滚，或合并，或应用其他业务逻辑来解决冲突。

通过设置 `ActiveRecord::Base.lock_optimistically = false` 可以关闭乐观锁定。

可以使用 `ActiveRecord::Base` 提供的 `locking_column` 类属性来覆盖 `lock_version` 字段名：

```ruby
class Client < ApplicationRecord
  self.locking_column = :lock_client_column
end
```

<a class="anchor" id="pessimistic-locking"></a>

### 悲观锁定

悲观锁定使用底层数据库提供的锁定机制。在创建关联时使用 `lock` 方法，会在选定字段上生成互斥锁。使用 `lock` 方法的关联通常被包装在事务中，以避免发生死锁。例如：

```ruby
Item.transaction do
  i = Item.lock.first
  i.name = 'Jones'
  i.save!
end
```

对于 MySQL 后端，上面的会话会生成下面的 SQL 语句：

```sql
SQL (0.2ms)   BEGIN
Item Load (0.3ms)   SELECT * FROM `items` LIMIT 1 FOR UPDATE
Item Update (0.4ms)   UPDATE `items` SET `updated_at` = '2009-02-07 18:05:56', `name` = 'Jones' WHERE `id` = 1
SQL (0.8ms)   COMMIT
```

要想支持其他锁定类型，可以直接传递 SQL 给 `lock` 方法。例如，MySQL 的 `LOCK IN SHARE MODE` 表达式在锁定记录时允许其他查询读取记录，这个表达式可以用作锁定选项：

```ruby
Item.transaction do
  i = Item.lock("LOCK IN SHARE MODE").find(1)
  i.increment!(:views)
end
```

对于已有模型实例，可以启动事务并一次性获取锁：

```ruby
item = Item.first
item.with_lock do
  # 这个块在事务中调用
  # item 已经锁定
  item.increment!(:views)
end
```

<a class="anchor" id="joining-tables"></a>

## 联结表

Active Record 提供了 `joins` 和 `left_outer_joins` 这两个查找方法，用于指明生成的 SQL 语句中的 `JOIN` 子句。其中，`joins` 方法用于 `INNER JOIN` 查询或定制查询，`left_outer_joins` 用于 `LEFT OUTER JOIN` 查询。

<a class="anchor" id="joins"></a>

### `joins` 方法

`joins` 方法有多种用法。

<a class="anchor" id="using-a-string-sql-fragment"></a>

#### 使用字符串 SQL 片段

在 `joins` 方法中可以直接用 SQL 指明 `JOIN` 子句：

```ruby
Author.joins("INNER JOIN posts ON posts.author_id = authors.id AND posts.published = 't'")
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT authors.* FROM authors INNER JOIN posts ON posts.author_id = authors.id AND posts.published = 't'
```

<a class="anchor" id="using-array-hash-of-named-associations"></a>

#### 使用具名关联数组或散列

使用 `joins` 方法时，Active Record 允许我们使用在模型上定义的关联的名称，作为指明这些关联的 `JOIN` 子句的快捷方式。

例如，假设有 `Category`、`Article`、`Comment`、`Guest` 和 `Tag` 这几个模型：

```ruby
class Category < ApplicationRecord
  has_many :articles
end

class Article < ApplicationRecord
  belongs_to :category
  has_many :comments
  has_many :tags
end

class Comment < ApplicationRecord
  belongs_to :article
  has_one :guest
end

class Guest < ApplicationRecord
  belongs_to :comment
end

class Tag < ApplicationRecord
  belongs_to :article
end
```

下面几种用法都会使用 `INNER JOIN` 生成我们想要的关联查询。

（译者注：原文此处开始出现编号错误，由译者根据内容逻辑关系进行了修正。）

<a class="anchor" id="joining-a-single-association"></a>

##### 单个关联的联结

```ruby
Category.joins(:articles)
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT categories.* FROM categories
  INNER JOIN articles ON articles.category_id = categories.id
```

这个查询的意思是把所有包含了文章的（非空）分类作为一个 `Category` 对象返回。请注意，如果多篇文章同属于一个分类，那么这个分类会在 `Category` 对象中出现多次。要想让每个分类只出现一次，可以使用 `Category.joins(:articles).distinct`。

<a class="anchor" id="joining-multiple-associations"></a>

##### 多个关联的联结

```ruby
Article.joins(:category, :comments)
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT articles.* FROM articles
  INNER JOIN categories ON articles.category_id = categories.id
  INNER JOIN comments ON comments.article_id = articles.id
```

这个查询的意思是把所有属于某个分类并至少拥有一条评论的文章作为一个 `Article` 对象返回。同样请注意，拥有多条评论的文章会在 `Article` 对象中出现多次。

<a class="anchor" id="joining-nested-associations-single-level"></a>

##### 单层嵌套关联的联结

```ruby
Article.joins(comments: :guest)
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT articles.* FROM articles
  INNER JOIN comments ON comments.article_id = articles.id
  INNER JOIN guests ON guests.comment_id = comments.id
```

这个查询的意思是把所有拥有访客评论的文章作为一个 `Article` 对象返回。

<a class="anchor" id="joining-nested-associations-multiple-level"></a>

##### 多层嵌套关联的联结

```ruby
Category.joins(articles: [{ comments: :guest }, :tags])
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT categories.* FROM categories
  INNER JOIN articles ON articles.category_id = categories.id
  INNER JOIN comments ON comments.article_id = articles.id
  INNER JOIN guests ON guests.comment_id = comments.id
  INNER JOIN tags ON tags.article_id = articles.id
```

这个查询的意思是把所有包含文章的分类作为一个 `Category` 对象返回，其中这些文章都拥有访客评论并且带有标签。

<a class="anchor" id="specifying-conditions-on-the-joined-tables"></a>

#### 为联结表指明条件

可以使用普通的数组和字符串条件作为关联数据表的条件。但如果想使用散列条件作为关联数据表的条件，就需要使用特殊语法了：

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Client.joins(:orders).where('orders.created_at' => time_range)
```

还有一种更干净的替代语法，即嵌套使用散列条件：

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Client.joins(:orders).where(orders: { created_at: time_range })
```

这个查询会查找所有在昨天创建过订单的客户，在生成的 SQL 语句中同样使用了 `BETWEEN` SQL 表达式。

<a class="anchor" id="left-outer-joins"></a>

### `left_outer_joins` 方法

如果想要选择一组记录，而不管它们是否具有关联记录，可以使用 `left_outer_joins` 方法。

```ruby
Author.left_outer_joins(:posts).distinct.select('authors.*, COUNT(posts.*) AS posts_count').group('authors.id')
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT DISTINCT authors.*, COUNT(posts.*) AS posts_count FROM "authors"
LEFT OUTER JOIN posts ON posts.author_id = authors.id GROUP BY authors.id
```

这个查询的意思是返回所有作者和每位作者的帖子数，而不管这些作者是否发过帖子。

<a class="anchor" id="eager-loading-associations"></a>

## 及早加载关联

及早加载是一种用于加载 `Model.find` 返回对象的关联记录的机制，目的是尽可能减少查询次数。

**N + 1 查询问题**

假设有如下代码，查找 10 条客户记录并打印这些客户的邮编：

```ruby
clients = Client.limit(10)

clients.each do |client|
  puts client.address.postcode
end
```

上面的代码第一眼看起来不错，但实际上存在查询总次数较高的问题。这段代码总共需要执行 1（查找 10 条客户记录）+ 10（每条客户记录都需要加载地址）= 11 次查询。

**N + 1 查询问题的解决办法**

Active Record 允许我们提前指明需要加载的所有关联，这是通过在调用 `Model.find` 时指明 `includes` 方法实现的。通过指明 `includes` 方法，Active Record 会使用尽可能少的查询来加载所有已指明的关联。

回到之前 N + 1 查询问题的例子，我们重写其中的 `Client.limit(10)` 来使用及早加载：

```ruby
clients = Client.includes(:address).limit(10)

clients.each do |client|
  puts client.address.postcode
end
```

上面的代码只执行 2 次查询，而不是之前的 11 次查询：

```sql
SELECT * FROM clients LIMIT 10
SELECT addresses.* FROM addresses
  WHERE (addresses.client_id IN (1,2,3,4,5,6,7,8,9,10))
```

<a class="anchor" id="eager-loading-multiple-associations"></a>

### 及早加载多个关联

通过在 `includes` 方法中使用数组、散列或嵌套散列，Active Record 允许我们在一次 `Model.find` 调用中及早加载任意数量的关联。

<a class="anchor" id="array-of-multiple-associations"></a>

#### 多个关联的数组

```ruby
Article.includes(:category, :comments)
```

上面的代码会加载所有文章、所有关联的分类和每篇文章的所有评论。

<a class="anchor" id="nested-associations-hash"></a>

#### 嵌套关联的散列

```ruby
Category.includes(articles: [{ comments: :guest }, :tags]).find(1)
```

上面的代码会查找 ID 为 1 的分类，并及早加载所有关联的文章、这些文章关联的标签和评论，以及这些评论关联的访客。

<a class="anchor" id="specifying-conditions-on-eager-loaded-associations"></a>

### 为关联的及早加载指明条件

尽管 Active Record 允许我们像 `joins` 方法那样为关联的及早加载指明条件，但推荐的方式是使用[联结](#joining-tables)。

尽管如此，在必要时仍然可以用 `where` 方法来为关联的及早加载指明条件。

```ruby
Article.includes(:comments).where(comments: { visible: true })
```

上面的代码会生成使用 `LEFT OUTER JOIN` 子句的 SQL 语句，而 `joins` 方法会成生使用 `INNER JOIN` 子句的 SQL 语句。

```sql
SELECT "articles"."id" AS t0_r0, ... "comments"."updated_at" AS t1_r5 FROM "articles" LEFT OUTER JOIN "comments" ON "comments"."article_id" = "articles"."id" WHERE (comments.visible = 1)
```

如果上面的代码没有使用 `where` 方法，就会生成常规的一组两条查询语句。

NOTE: 要想像上面的代码那样使用 `where` 方法，必须在 `where` 方法中使用散列。如果想要在 `where` 方法中使用字符串 SQL 片段，就必须用 `references` 方法强制使用联结表：

```ruby
Article.includes(:comments).where("comments.visible = true").references(:comments)
```


通过在 `where` 方法中使用字符串 SQL 片段并使用 `references` 方法这种方式，即使一条评论都没有，所有文章仍然会被加载。而在使用 `joins` 方法（`INNER JOIN`）时，必须匹配关联条件，否则一条记录都不会返回。

<a class="anchor" id="scopes"></a>

## 作用域

作用域允许我们把常用查询定义为方法，然后通过在关联对象或模型上调用方法来引用这些查询。fotnote:[“作用域”和“作用域方法”在本文中是一个意思。——译者注]在作用域中，我们可以使用之前介绍过的所有方法，如 `where`、`join` 和 `includes` 方法。所有作用域都会返回 `ActiveRecord::Relation` 对象，这样就可以继续在这个对象上调用其他方法（如其他作用域）。

要想定义简单的作用域，我们可以在类中通过 `scope` 方法定义作用域，并传入调用这个作用域时执行的查询。

```ruby
class Article < ApplicationRecord
  scope :published, -> { where(published: true) }
end
```

通过上面这种方式定义作用域和通过定义类方法来定义作用域效果完全相同，至于使用哪种方式只是个人喜好问题：

```ruby
class Article < ApplicationRecord
  def self.published
    where(published: true)
  end
end
```

在作用域中可以链接其他作用域：

```ruby
class Article < ApplicationRecord
  scope :published,               -> { where(published: true) }
  scope :published_and_commented, -> { published.where("comments_count > 0") }
end
```

我们可以在模型上调用 `published` 作用域：

```ruby
Article.published # => [published articles]
```

或在多个 `Article` 对象组成的关联对象上调用 `published` 作用域：

```ruby
category = Category.first
category.articles.published # => [published articles belonging to this category]
```

<a class="anchor" id="passing-in-arguments"></a>

### 传入参数

作用域可以接受参数：

```ruby
class Article < ApplicationRecord
  scope :created_before, ->(time) { where("created_at < ?", time) }
end
```

调用作用域和调用类方法一样：

```ruby
Article.created_before(Time.zone.now)
```

不过这只是复制了本该通过类方法提供给我们的的功能。

```ruby
class Article < ApplicationRecord
  def self.created_before(time)
    where("created_at < ?", time)
  end
end
```

当作用域需要接受参数时，推荐改用类方法。使用类方法时，这些方法仍然可以在关联对象上访问：

```ruby
category.articles.created_before(time)
```

<a class="anchor" id="using-conditionals"></a>

### 使用条件

我们可以在作用域中使用条件：

```ruby
class Article < ApplicationRecord
  scope :created_before, ->(time) { where("created_at < ?", time) if time.present? }
end
```

和之前的例子一样，作用域的这一行为也和类方法类似。

```ruby
class Article < ApplicationRecord
  def self.created_before(time)
    where("created_at < ?", time) if time.present?
  end
end
```

不过有一点需要特别注意：不管条件的值是 `true` 还是 `false`，作用域总是返回 `ActiveRecord::Relation` 对象，而当条件是 `false` 时，类方法返回的是 `nil`。因此，当链接带有条件的类方法时，如果任何一个条件的值是 `false`，就会引发 `NoMethodError` 异常。

<a class="anchor" id="applying-a-default-scope"></a>

### 应用默认作用域

要想在模型的所有查询中应用作用域，我们可以在这个模型上使用 `default_scope` 方法。

```ruby
class Client < ApplicationRecord
  default_scope { where("removed_at IS NULL") }
end
```

应用默认作用域后，在这个模型上执行查询，会生成下面这样的 SQL 语句：

```sql
SELECT * FROM clients WHERE removed_at IS NULL
```

如果想用默认作用域做更复杂的事情，我们也可以把它定义为类方法：

```ruby
class Client < ApplicationRecord
  def self.default_scope
    # 应该返回一个 ActiveRecord::Relation 对象
  end
end
```

NOTE: 默认作用域在创建记录时同样起作用，但在更新记录时不起作用。例如：

```ruby
class Client < ApplicationRecord
  default_scope { where(active: true) }
end

Client.new          # => #<Client id: nil, active: true>
Client.unscoped.new # => #<Client id: nil, active: nil>
```


<a class="anchor" id="merging-of-scopes"></a>

### 合并作用域

和 `WHERE` 子句一样，我们用 `AND` 来合并作用域。

```ruby
class User < ApplicationRecord
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.active.inactive
# SELECT "users".* FROM "users" WHERE "users"."state" = 'active' AND "users"."state" = 'inactive'
```

我们可以混合使用 `scope` 和 `where` 方法，这样最后生成的 SQL 语句会使用 `AND` 连接所有条件。

```ruby
User.active.where(state: 'finished')
# SELECT "users".* FROM "users" WHERE "users"."state" = 'active' AND "users"."state" = 'finished'
```

如果使用 `Relation#merge` 方法，那么在发生条件冲突时总是最后的 `WHERE` 子句起作用。

```ruby
User.active.merge(User.inactive)
# SELECT "users".* FROM "users" WHERE "users"."state" = 'inactive'
```

有一点需要特别注意，`default_scope` 总是在所有 `scope` 和 `where` 之前起作用。

```ruby
class User < ApplicationRecord
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

在上面的代码中我们可以看到，在 `scope` 条件和 `where` 条件中都合并了 `default_scope` 条件。

<a class="anchor" id="removing-all-scoping"></a>

### 删除所有作用域

在需要时，可以使用 `unscoped` 方法删除作用域。如果在模型中定义了默认作用域，但在某次查询中又不想应用默认作用域，这时就可以使用 `unscoped` 方法。

```ruby
Client.unscoped.load
```

`unscoped` 方法会删除所有作用域，仅在数据表上执行常规查询。

```ruby
Client.unscoped.all
# SELECT "clients".* FROM "clients"

Client.where(published: false).unscoped.all
# SELECT "clients".* FROM "clients"
```

`unscoped` 方法也接受块作为参数。

```ruby
Client.unscoped {
  Client.created_before(Time.zone.now)
}
```

<a class="anchor" id="dynamic-finders"></a>

## 动态查找方法

Active Record 为数据表中的每个字段（也称为属性）都提供了查找方法（也就是动态查找方法）。例如，对于 `Client` 模型的 `first_name` 字段，Active Record 会自动生成 `find_by_first_name` 查找方法。对于 `Client` 模型的 `locked` 字段，Active Record 会自动生成 `find_by_locked` 查找方法。

在调用动态查找方法时可以在末尾加上感叹号（`!`），例如 `Client.find_by_name!("Ryan")`，这样如果动态查找方法没有返回任何记录，就会抛出 `ActiveRecord::RecordNotFound` 异常。

如果想同时查询 `first_name` 和 `locked` 字段，可以在动态查找方法中用 `and` 把这两个字段连起来，例如 `Client.find_by_first_name_and_locked("Ryan", true)`。

<a class="anchor" id="enums"></a>

## `enum` 宏

`enum` 宏把整数字段映射为一组可能的值。

```ruby
class Book < ApplicationRecord
  enum availability: [:available, :unavailable]
end
```

上面的代码会自动创建用于查询模型的对应作用域，同时会添加用于转换状态和查询当前状态的方法。

```ruby
# 下面的示例只查询可用的图书
Book.available
# 或
Book.where(availability: :available)

book = Book.new(availability: :available)
book.available?   # => true
book.unavailable! # => true
book.available?   # => false
```

请访问 [Rails API 文档](http://api.rubyonrails.org/classes/ActiveRecord/Enum.html)，查看 `enum` 宏的完整文档。

<a class="anchor" id="understanding-the-method-chaining"></a>

## 理解方法链

Active Record 实现[方法链](http://en.wikipedia.org/wiki/Method_chaining)的方式既简单又直接，有了方法链我们就可以同时使用多个 Active Record 方法。

当之前的方法调用返回 `ActiveRecord::Relation` 对象时，例如 `all`、`where` 和 `joins` 方法，我们就可以在语句中把方法连接起来。返回单个对象的方法（请参阅 [检索单个对象](#retrieving-a-single-object)）必须位于语句的末尾。

下面给出了一些例子。本文无法涵盖所有的可能性，这里给出的只是很少的一部分例子。在调用 Active Record 方法时，查询不会立即生成并发送到数据库，这些操作只有在实际需要数据时才会执行。下面的每个例子都会生成一次查询。

<a class="anchor" id="retrieving-filtered-data-from-multiple-tables"></a>

### 从多个数据表中检索过滤后的数据

```ruby
Person
  .select('people.id, people.name, comments.text')
  .joins(:comments)
  .where('comments.created_at > ?', 1.week.ago)
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT people.id, people.name, comments.text
FROM people
INNER JOIN comments
  ON comments.person_id = people.id
WHERE comments.created_at > '2015-01-01'
```

<a class="anchor" id="retrieving-specific-data-from-multiple-tables"></a>

### 从多个数据表中检索特定的数据

```ruby
Person
  .select('people.id, people.name, companies.name')
  .joins(:company)
  .find_by('people.name' => 'John') # this should be the last
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT people.id, people.name, companies.name
FROM people
INNER JOIN companies
  ON companies.person_id = people.id
WHERE people.name = 'John'
LIMIT 1
```

NOTE: 请注意，如果查询匹配多条记录，`find_by` 方法会取回第一条记录并忽略其他记录（如上面的 SQL 语句中的 `LIMIT 1`）。

<a class="anchor" id="find-or-build-a-new-object"></a>

## 查找或创建新对象

我们经常需要查找记录并在找不到记录时创建记录，这时我们可以使用 `find_or_create_by` 和 `find_or_create_by!` 方法。

<a class="anchor" id="find-or-create_by"></a>

### `find_or_create_by` 方法

`find_or_create_by` 方法检查具有指定属性的记录是否存在。如果记录不存在，就调用 `create` 方法创建记录。让我们看一个例子。

假设我们在查找名为“Andy”的用户记录，但是没找到，因此要创建这条记录。这时我们可以执行下面的代码：

```ruby
Client.find_or_create_by(first_name: 'Andy')
# => #<Client id: 1, first_name: "Andy", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT * FROM clients WHERE (clients.first_name = 'Andy') LIMIT 1
BEGIN
INSERT INTO clients (created_at, first_name, locked, orders_count, updated_at) VALUES ('2011-08-30 05:22:57', 'Andy', 1, NULL, '2011-08-30 05:22:57')
COMMIT
```

`find_or_create_by` 方法会返回已存在的记录或新建的记录。在本例中，名为“Andy”的客户记录并不存在，因此会创建并返回这条记录。

新建记录不一定会保存到数据库，是否保存取决于验证是否通过（就像 `create` 方法那样）。

假设我们想在新建记录时把 `locked` 字段设置为 `false`，但又不想在查询中进行设置。例如，我们想查找名为“Andy”的客户记录，但这条记录并不存在，因此要创建这条记录并把 `locked` 字段设置为 `false`。

要完成这一操作有两种方式。第一种方式是使用 `create_with` 方法：

```ruby
Client.create_with(locked: false).find_or_create_by(first_name: 'Andy')
```

第二种方式是使用块：

```ruby
Client.find_or_create_by(first_name: 'Andy') do |c|
  c.locked = false
end
```

只有在创建客户记录时才会执行该块。第二次运行这段代码时（此时客户记录已创建），块会被忽略。

<a class="anchor" id="find-or-create-by-exclamation-point"></a>

### `find_or_create_by!` 方法

我们也可以使用 `find_or_create_by!` 方法，这样如果新建记录是无效的就会抛出异常。本文不涉及数据验证，不过这里我们暂且假设已经在 `Client` 模型中添加了下面的数据验证：

```ruby
validates :orders_count, presence: true
```

如果我们尝试新建客户记录，但忘了传递 `orders_count` 字段的值，新建记录就是无效的，因而会抛出下面的异常：

```ruby
Client.find_or_create_by!(first_name: 'Andy')
# => ActiveRecord::RecordInvalid: Validation failed: Orders count can't be blank
```

<a class="anchor" id="find-or-initialize-by"></a>

### `find_or_initialize_by` 方法

`find_or_initialize_by` 方法的工作原理和 `find_or_create_by` 方法类似，区别之处在于前者调用的是 `new` 方法而不是 `create` 方法。这意味着新建模型实例在内存中创建，但没有保存到数据库。下面继续使用介绍 `find_or_create_by` 方法时使用的例子，我们现在想查找名为“Nick”的客户记录：

```ruby
nick = Client.find_or_initialize_by(first_name: 'Nick')
# => #<Client id: nil, first_name: "Nick", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">

nick.persisted?
# => false

nick.new_record?
# => true
```

出现上面的执行结果是因为 `nick` 对象还没有保存到数据库。在上面的代码中，`find_or_initialize_by` 方法会生成下面的 SQL 语句：

```sql
SELECT * FROM clients WHERE (clients.first_name = 'Nick') LIMIT 1
```

要想把 `nick` 对象保存到数据库，只需调用 `save` 方法：

```ruby
nick.save
# => true
```

<a class="anchor" id="finding-by-sql"></a>

## 使用 SQL 语句进行查找

要想直接使用 SQL 语句在数据表中查找记录，可以使用 `find_by_sql` 方法。`find_by_sql` 方法总是返回对象的数组，即使底层查询只返回了一条记录也是如此。例如，我们可以执行下面的查询：

```ruby
Client.find_by_sql("SELECT * FROM clients
  INNER JOIN orders ON clients.id = orders.client_id
  ORDER BY clients.created_at desc")
# =>  [
#   #<Client id: 1, first_name: "Lucas" >,
#   #<Client id: 2, first_name: "Jan" >,
#   ...
# ]
```

`find_by_sql` 方法提供了对数据库进行定制查询并取回实例化对象的简单方式。

<a class="anchor" id="select-all"></a>

### `select_all` 方法

`find_by_sql` 方法有一个名为 `connection#select_all` 的近亲。和 `find_by_sql` 方法一样，`select_all` 方法也会使用定制的 SQL 语句从数据库中检索对象，区别在于 `select_all` 方法不会对这些对象进行实例化，而是返回一个散列构成的数组，其中每个散列表示一条记录。

```ruby
Client.connection.select_all("SELECT first_name, created_at FROM clients WHERE id = '1'")
# => [
#   {"first_name"=>"Rafael", "created_at"=>"2012-11-10 23:23:45.281189"},
#   {"first_name"=>"Eileen", "created_at"=>"2013-12-09 11:22:35.221282"}
# ]
```

<a class="anchor" id="pluck"></a>

### `pluck` 方法

`pluck` 方法用于在模型对应的底层数据表中查询单个或多个字段。它接受字段名的列表作为参数，并返回这些字段的值的数组，数组中的每个值都具有对应的数据类型。

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

使用 `pluck` 方法，我们可以把下面的代码：

```ruby
Client.select(:id).map { |c| c.id }
# 或
Client.select(:id).map(&:id)
# 或
Client.select(:id, :name).map { |c| [c.id, c.name] }
```

替换为：

```ruby
Client.pluck(:id)
# 或
Client.pluck(:id, :name)
```

和 `select` 方法不同，`pluck` 方法把数据库查询结果直接转换为 Ruby 数组，而不是构建 Active Record 对象。这意味着对于大型查询或常用查询，`pluck` 方法的性能更好。不过对于 `pluck` 方法，模型方法重载是不可用的。例如：

```ruby
class Client < ApplicationRecord
  def name
    "I am #{super}"
  end
end

Client.select(:name).map &:name
# => ["I am David", "I am Jeremy", "I am Jose"]

Client.pluck(:name)
# => ["David", "Jeremy", "Jose"]
```

此外，和 `select` 方法及其他 `Relation` 作用域不同，`pluck` 方法会触发即时查询，因此在 `pluck` 方法之前可以链接作用域，但在 `pluck` 方法之后不能链接作用域：

```ruby
Client.pluck(:name).limit(1)
# => NoMethodError: undefined method `limit' for #<Array:0x007ff34d3ad6d8>

Client.limit(1).pluck(:name)
# => ["David"]
```

<a class="anchor" id="ids"></a>

### `ids` 方法

使用 `ids` 方法可以获得关联的所有 ID，也就是数据表的主键。

```ruby
Person.ids
# SELECT id FROM people
```

```ruby
class Person < ApplicationRecord
  self.primary_key = "person_id"
end

Person.ids
# SELECT person_id FROM people
```

<a class="anchor" id="existence-of-objects"></a>

## 检查对象是否存在

要想检查对象是否存在，可以使用 `exists?` 方法。`exists?` 方法查询数据库的工作原理和 `find` 方法相同，但是 `find` 方法返回的是对象或对象集合，而 `exists?` 方法返回的是 `true` 或 `false`。

```ruby
Client.exists?(1)
```

`exists?` 方法也接受多个值作为参数，并且只要有一条对应记录存在就会返回 `true`。

```ruby
Client.exists?(id: [1,2,3])
# 或
Client.exists?(name: ['John', 'Sergei'])
```

我们还可以在模型或关联上调用 `exists?` 方法，这时不需要任何参数。

```ruby
Client.where(first_name: 'Ryan').exists?
```

只要存在一条名为“Ryan”的客户记录，上面的代码就会返回 `true`，否则返回 `false`。

```ruby
Client.exists?
```

如果 `clients` 数据表是空的，上面的代码返回 `false`，否则返回 `true`。

我们还可以在模型或关联上调用 `any?` 和 `many?` 方法来检查对象是否存在。

```ruby
# 通过模型
Article.any?
Article.many?

# 通过指定的作用域
Article.recent.any?
Article.recent.many?

# 通过关系
Article.where(published: true).any?
Article.where(published: true).many?

# 通过关联
Article.first.categories.any?
Article.first.categories.many?
```

<a class="anchor" id="calculations"></a>

## 计算

在本节的前言中我们以 `count` 方法为例，例子中提到的所有选项对本节的各小节都适用。

所有用于计算的方法都可以直接在模型上调用：

```ruby
Client.count
# SELECT count(*) AS count_all FROM clients
```

或者在关联上调用：

```ruby
Client.where(first_name: 'Ryan').count
# SELECT count(*) AS count_all FROM clients WHERE (first_name = 'Ryan')
```

我们还可以在关联上执行各种查找方法来执行复杂的计算：

```ruby
Client.includes("orders").where(first_name: 'Ryan', orders: { status: 'received' }).count
```

上面的代码会生成下面的 SQL 语句：

```sql
SELECT count(DISTINCT clients.id) AS count_all FROM clients
  LEFT OUTER JOIN orders ON orders.client_id = clients.id WHERE
  (clients.first_name = 'Ryan' AND orders.status = 'received')
```

<a class="anchor" id="count"></a>

### `count` 方法

要想知道模型对应的数据表中有多少条记录，可以使用 `Client.count` 方法，这个方法的返回值就是记录条数。如果想要知道特定记录的条数，例如具有 `age` 字段值的所有客户记录的条数，可以使用 `Client.count(:age)`。

关于 `count` 方法的选项的更多介绍，请参阅 [计算](#calculations)。

<a class="anchor" id="average"></a>

### `average` 方法

要想知道数据表中某个字段的平均值，可以在数据表对应的类上调用 `average` 方法。例如：

```ruby
Client.average("orders_count")
```

上面的代码会返回表示 `orders_count` 字段平均值的数字（可能是浮点数，如 3.14159265）。

关于 `average` 方法的选项的更多介绍，请参阅 [计算](#calculations)。

<a class="anchor" id="minimum"></a>

### `minimum` 方法

要想查找数据表中某个字段的最小值，可以在数据表对应的类上调用 `minimum` 方法。例如：

```ruby
Client.minimum("age")
```

关于 `minimum` 方法的选项的更多介绍，请参阅 [计算](#calculations)。

<a class="anchor" id="maximum"></a>

### `maximum` 方法

要想查找数据表中某个字段的最大值，可以在数据表对应的类上调用 `maximum` 方法。例如：

```ruby
Client.maximum("age")
```

关于 `maximum` 方法的选项的更多介绍，请参阅 [计算](#calculations)。

<a class="anchor" id="sum"></a>

### `sum` 方法

要想知道数据表中某个字段的所有字段值之和，可以在数据表对应的类上调用 `sum` 方法。例如：

```ruby
Client.sum("orders_count")
```

关于 `sum` 方法的选项的更多介绍，请参阅 [计算](#calculations)。

<a class="anchor" id="running-explain"></a>

## 执行 `EXPLAIN` 命令

我们可以在关联触发的查询上执行 `EXPLAIN` 命令。例如：

```ruby
User.where(id: 1).joins(:articles).explain
```

对于 MySQL 和 MariaDB 数据库后端，上面的代码会产生下面的输出结果：

```
EXPLAIN for: SELECT `users`.* FROM `users` INNER JOIN `articles` ON `articles`.`user_id` = `users`.`id` WHERE `users`.`id` = 1
+----+-------------+----------+-------+---------------+
| id | select_type | table    | type  | possible_keys |
+----+-------------+----------+-------+---------------+
|  1 | SIMPLE      | users    | const | PRIMARY       |
|  1 | SIMPLE      | articles | ALL   | NULL          |
+----+-------------+----------+-------+---------------+
+---------+---------+-------+------+-------------+
| key     | key_len | ref   | rows | Extra       |
+---------+---------+-------+------+-------------+
| PRIMARY | 4       | const |    1 |             |
| NULL    | NULL    | NULL  |    1 | Using where |
+---------+---------+-------+------+-------------+

2 rows in set (0.00 sec)
```

Active Record 会模拟对应数据库的 shell 来打印输出结果。因此对于 PostgreSQL 数据库后端，同样的代码会产生下面的输出结果：

```
EXPLAIN for: SELECT "users".* FROM "users" INNER JOIN "articles" ON "articles"."user_id" = "users"."id" WHERE "users"."id" = 1
                                  QUERY PLAN
------------------------------------------------------------------------------
 Nested Loop Left Join  (cost=0.00..37.24 rows=8 width=0)
   Join Filter: (articles.user_id = users.id)
   ->  Index Scan using users_pkey on users  (cost=0.00..8.27 rows=1 width=4)
         Index Cond: (id = 1)
   ->  Seq Scan on articles  (cost=0.00..28.88 rows=8 width=4)
         Filter: (articles.user_id = 1)
(6 rows)
```

及早加载在底层可能会触发多次查询，有的查询可能需要使用之前查询的结果。因此，`explain` 方法实际上先执行了查询，然后询问查询计划。例如：

```ruby
User.where(id: 1).includes(:articles).explain
```

对于 MySQL 和 MariaDB 数据库后端，上面的代码会产生下面的输出结果：

```
EXPLAIN for: SELECT `users`.* FROM `users`  WHERE `users`.`id` = 1
+----+-------------+-------+-------+---------------+
| id | select_type | table | type  | possible_keys |
+----+-------------+-------+-------+---------------+
|  1 | SIMPLE      | users | const | PRIMARY       |
+----+-------------+-------+-------+---------------+
+---------+---------+-------+------+-------+
| key     | key_len | ref   | rows | Extra |
+---------+---------+-------+------+-------+
| PRIMARY | 4       | const |    1 |       |
+---------+---------+-------+------+-------+

1 row in set (0.00 sec)

EXPLAIN for: SELECT `articles`.* FROM `articles`  WHERE `articles`.`user_id` IN (1)
+----+-------------+----------+------+---------------+
| id | select_type | table    | type | possible_keys |
+----+-------------+----------+------+---------------+
|  1 | SIMPLE      | articles | ALL  | NULL          |
+----+-------------+----------+------+---------------+
+------+---------+------+------+-------------+
| key  | key_len | ref  | rows | Extra       |
+------+---------+------+------+-------------+
| NULL | NULL    | NULL |    1 | Using where |
+------+---------+------+------+-------------+


1 row in set (0.00 sec)
```

<a class="anchor" id="interpreting-explain"></a>

### 对 `EXPLAIN` 命令输出结果的解释

对 `EXPLAIN` 命令输出结果的解释超出了本文的范畴。下面提供了一些有用链接：

*   SQLite3：[对查询计划的解释](http://www.sqlite.org/eqp.html)
*   MySQL：[EXPLAIN 输出格式](http://dev.mysql.com/doc/refman/5.7/en/explain-output.html)
*   MariaDB：[EXPLAIN](https://mariadb.com/kb/en/mariadb/explain/)
*   PostgreSQL：[使用 EXPLAIN](http://www.postgresql.org/docs/current/static/using-explain.html)
