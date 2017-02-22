Active Record 基础
==================

本文简介 Active Record。

读完本文后，您将学到：

- 对象关系映射（Object Relational Mapping，ORM）和 Active Record 是什么，以及如何在 Rails 中使用；

- Active Record 在 MVC 中的作用；

- 如何使用 Active Record 模型处理保存在关系型数据库中的数据；

- Active Record 模式（schema）的命名约定；

- 数据库迁移，数据验证和回调。

Active Record 是什么？
----------------------

Active Record 是 [MVC](http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) 中的 M（模型），负责处理数据和业务逻辑。Active Record 负责创建和使用需要持久存入数据库中的数据。Active Record 实现了 Active Record 模式，是一种对象关系映射系统。

### Active Record 模式

[Active Record 模式](http://www.martinfowler.com/eaaCatalog/activeRecord.html)出自 Martin Fowler 写的《[企业应用架构模式](https://book.douban.com/subject/4826290/)》一书。在 Active Record 模式中，对象中既有持久存储的数据，也有针对数据的操作。Active Record 模式把数据存取逻辑作为对象的一部分，处理对象的用户知道如何把数据写入数据库，还知道如何从数据库中读出数据。

### 对象关系映射

对象关系映射（ORM）是一种技术手段，把应用中的对象和关系型数据库中的数据表连接起来。使用 ORM，应用中对象的属性和对象之间的关系可以通过一种简单的方法从数据库中获取，无需直接编写 SQL 语句，也不过度依赖特定的数据库种类。

### 用作 ORM 框架的 Active Record

Active Record 提供了很多功能，其中最重要的几个如下：

- 表示模型和其中的数据；

- 表示模型之间的关系；

- 通过相关联的模型表示继承层次结构；

- 持久存入数据库之前，验证模型；

- 以面向对象的方式处理数据库操作。

Active Record 中的“多约定少配置”原则
------------------------------------

使用其他编程语言或框架开发应用时，可能必须要编写很多配置代码。大多数 ORM 框架都是这样。但是，如果遵循 Rails 的约定，创建 Active Record 模型时不用做多少配置（有时甚至完全不用配置）。Rails 的理念是，如果大多数情况下都要使用相同的方式配置应用，那么就应该把这定为默认的方式。所以，只有约定无法满足要求时，才要额外配置。

### 命名约定

默认情况下，Active Record 使用一些命名约定，查找模型和数据库表之间的映射关系。Rails 把模型的类名转换成复数，然后查找对应的数据表。例如，模型类名为 `Book`，数据表就是 `books`。Rails 提供的单复数转换功能很强大，常见和不常见的转换方式都能处理。如果类名由多个单词组成，应该按照 Ruby 的约定，使用驼峰式命名法，这时对应的数据库表将使用下划线分隔各单词。因此：

- 数据库表名：复数，下划线分隔单词（例如 `book_clubs`）

- 模型类名：单数，每个单词的首字母大写（例如 `BookClub`）

| 模型/类 | 表/模式 |
|------|------|
| Article | articles |
| LineItem | line_items |
| Deer | deers |
| Mouse | mice |
| Person | people |

### 模式约定

根据字段的作用不同，Active Record 对数据库表中的字段命名也做了相应的约定：

- **外键**：使用 `singularized_table_name_id` 形式命名，例如 `item_id`，`order_id`。创建模型关联后，Active Record 会查找这个字段；

- **主键**：默认情况下，Active Record 使用整数字段 `id` 作为表的主键。使用 [Active Record 迁移](active_record_migrations.xml#active-record-migrations)创建数据库表时，会自动创建这个字段；

还有一些可选的字段，能为 Active Record 实例添加更多的功能：

- `created_at`：创建记录时，自动设为当前的日期和时间；

- `updated_at`：更新记录时，自动设为当前的日期和时间；

- `lock_version`：在模型中添加[乐观锁](http://api.rubyonrails.org/classes/ActiveRecord/Locking.html)；

- `type`：让模型使用[单表继承](http://api.rubyonrails.org/classes/ActiveRecord/Base.html#class-ActiveRecord::Base-label-Single+table+inheritance)；

- `(association_name)_type`：存储[多态关联](association_basics.xml#polymorphic-associations)的类型；

- `(table_name)_count`：缓存所关联对象的数量。比如说，一个 `Article` 有多个 `Comment`，那么 `comments_count` 列存储各篇文章现有的评论数量；

NOTE: 虽然这些字段是可选的，但在 Active Record 中是被保留的。如果想使用相应的功能，就不要把这些保留字段用作其他用途。例如，`type` 这个保留字段是用来指定数据库表使用单表继承（Single Table Inheritance，STI）的。如果不用单表继承，请使用其他的名称，例如“context”，这也能表明数据的作用。

创建 Active Record 模型
-----------------------

创建 Active Record 模型的过程很简单，只要继承 `ApplicationRecord` 类就行了：

```ruby
class Product < ApplicationRecord
end
```

上面的代码会创建 `Product` 模型，对应于数据库中的 `products` 表。同时，`products` 表中的字段也映射到 `Product` 模型实例的属性上。假如 `products` 表由下面的 SQL 语句创建：

```sql
CREATE TABLE products (
   id int(11) NOT NULL auto_increment,
   name varchar(255),
   PRIMARY KEY  (id)
);
```

按照这样的数据表结构，可以编写下面的代码：

```ruby
p = Product.new
p.name = "Some Book"
puts p.name # "Some Book"
```

覆盖命名约定
------------

如果想使用其他的命名约定，或者在 Rails 应用中使用即有的数据库可以吗？没问题，默认的约定能轻易覆盖。

`ApplicationRecord` 继承自 `ActiveRecord::Base`，后者定义了一系列有用的方法。使用 `ActiveRecord::Base.table_name=` 方法可以指定要使用的表名：

```ruby
class Product < ApplicationRecord
  self.table_name = "my_products"
end
```

如果这么做，还要调用 `set_fixture_class` 方法，手动指定固件（my\_products.yml）的类名：

```ruby
class ProductTest < ActiveSupport::TestCase
  set_fixture_class my_products: Product
  fixtures :my_products
  ...
end
```

还可以使用 `ActiveRecord::Base.primary_key=` 方法指定表的主键：

```ruby
class Product < ApplicationRecord
  self.primary_key = "product_id"
end
```

CRUD：读写数据
--------------

CURD 是四种数据操作的简称：C 表示创建，R 表示读取，U 表示更新，D 表示删除。Active Record 自动创建了处理数据表中数据的方法。

### 创建

Active Record 对象可以使用散列创建，在块中创建，或者创建后手动设置属性。`new` 方法创建一个新对象，`create` 方法创建新对象，并将其存入数据库。

例如，`User` 模型中有两个属性，`name` 和 `occupation`。调用 `create` 方法会创建一个新记录，并将其存入数据库：

```ruby
user = User.create(name: "David", occupation: "Code Artist")
```

`new` 方法实例化一个新对象，但不保存：

```ruby
user = User.new
user.name = "David"
user.occupation = "Code Artist"
```

调用 `user.save` 可以把记录存入数据库。

最后，如果在 `create` 和 `new` 方法中使用块，会把新创建的对象拉入块中，初始化对象：

```ruby
user = User.new do |u|
  u.name = "David"
  u.occupation = "Code Artist"
end
```

### 读取

Active Record 为读取数据库中的数据提供了丰富的 API。下面举例说明。

```ruby
# 返回所有用户组成的集合
users = User.all
```

```ruby
# 返回第一个用户
user = User.first
```

```ruby
# 返回第一个名为 David 的用户
david = User.find_by(name: 'David')
```

```ruby
# 查找所有名为 David，职业为 Code Artists 的用户，而且按照 created_at 反向排列
users = User.where(name: 'David', occupation: 'Code Artist').order(created_at: :desc)
```

[Active Record 查询接口](active_record_querying.html)会详细介绍查询 Active Record 模型的方法。

### 更新

检索到 Active Record 对象后，可以修改其属性，然后再将其存入数据库。

```ruby
user = User.find_by(name: 'David')
user.name = 'Dave'
user.save
```

还有种使用散列的简写方式，指定属性名和属性值，例如：

```ruby
user = User.find_by(name: 'David')
user.update(name: 'Dave')
```

一次更新多个属性时使用这种方法最方便。如果想批量更新多个记录，可以使用类方法 `update_all`：

```ruby
User.update_all "max_login_attempts = 3, must_change_password = 'true'"
```

### 删除

类似地，检索到 Active Record 对象后还可以将其销毁，从数据库中删除。

```ruby
user = User.find_by(name: 'David')
user.destroy
```

数据验证
--------

在存入数据库之前，Active Record 还可以验证模型。模型验证有很多方法，可以检查属性值是否不为空，是否是唯一的、没有在数据库中出现过，等等。

把数据存入数据库之前进行验证是十分重要的步骤，所以调用 `save` 和 `update` 方法时会做数据验证。验证失败时返回 `false`，此时不会对数据库做任何操作。这两个方法都有对应的爆炸方法（`save!` 和 `update!`）。爆炸方法要严格一些，如果验证失败，抛出 `ActiveRecord::RecordInvalid` 异常。下面举个简单的例子：

```ruby
class User < ApplicationRecord
  validates :name, presence: true
end

user = User.new
user.save  # => false
user.save! # => ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

[Active Record 数据验证](active_record_validations.html)会详细介绍数据验证。

回调
----

Active Record 回调用于在模型生命周期的特定事件上绑定代码，相应的事件发生时，执行绑定的代码。例如创建新纪录时、更新记录时、删除记录时，等等。[Active Record 回调](active_record_callbacks.html)会详细介绍回调。

迁移
----

Rails 提供了一个 DSL（Domain-Specific Language）用来处理数据库模式，叫做“迁移”。迁移的代码存储在特定的文件中，通过 `rails` 命令执行，可以用在 Active Record 支持的所有数据库上。下面这个迁移新建一个表：

```ruby
class CreatePublications < ActiveRecord::Migration[5.0]
  def change
    create_table :publications do |t|
      t.string :title
      t.text :description
      t.references :publication_type
      t.integer :publisher_id
      t.string :publisher_type
      t.boolean :single_issue

      t.timestamps
    end
    add_index :publications, :publication_type_id
  end
end
```

Rails 会跟踪哪些迁移已经应用到数据库上，还提供了回滚功能。为了创建表，要执行 `rails db:migrate` 命令。如果想回滚，则执行 `rails db:rollback` 命令。

注意，上面的代码与具体的数据库种类无关，可用于 MySQL、PostgreSQL、Oracle 等数据库。关于迁移的详细介绍，参阅[Active Record 迁移](active_record_migrations.html)。
