Active Record 基础
==================

本文介绍 Active Record。

读完本文后，你将了解：

* 对象关系映射（Object Relational Mapping，ORM）和 Active Record 是什么，以及如何在 Rails 中使用；
* Active Record 在 MVC 中的作用；
* 如何使用 Active Record 模型处理保存在关系型数据库中的数据；
* Active Record 模式（schema）命名约定；
* 数据库迁移，数据验证和回调；

--------------------------------------------------------------------------------

## Active Record 是什么？ {#what-is-active-record}

Active Record 是 [MVC]({{ site.baseurl }}/getting_started.html#the-mvc-architecture) 中的 M（模型），处理数据和业务逻辑。Active Record 负责创建和使用需要持久存入数据库中的数据。Active Record 实现了 Active Record 模式，是一种对象关系映射系统。

### Active Record 模式 {#the-active-record-pattern}

Active Record 模式出自 [Martin Fowler](http://www.martinfowler.com/eaaCatalog/activeRecord.html) 的《企业应用架构模式》一书。在 Active Record 模式中，对象中既有持久存储的数据，也有针对数据的操作。Active Record 模式把数据存取逻辑作为对象的一部分，处理对象的用户知道如何把数据写入数据库，以及从数据库中读出数据。

### 对象关系映射 {#object-relational-mapping}

对象关系映射（ORM）是一种技术手段，把程序中的对象和关系型数据库中的数据表连接起来。使用 ORM，程序中对象的属性和对象之间的关系可以通过一种简单的方法从数据库获取，无需直接编写 SQL 语句，也不过度依赖特定的数据库种类。

### Active Record 用作 ORM 框架 {#active-record-as-an-orm-framework}

Active Record 提供了很多功能，其中最重要的几个如下：

* 表示模型和其中的数据；
* 表示模型之间的关系；
* 通过相关联的模型表示集成关系；
* 持久存入数据库之前，验证模型；
* 以面向对象的方式处理数据库操作；

## Active Record 中的“多约定少配置”原则 {#convention-over-configuration-in-active-record}

使用其他编程语言或框架开发程序时，可能必须要编写很多配置代码。大多数的 ORM 框架都是这样。但是，如果遵循 Rails 的约定，创建 Active Record 模型时不用做多少配置（有时甚至完全不用配置）。Rails 的理念是，如果大多数情况下都要使用相同的方式配置程序，那么就应该把这定为默认的方法。所以，只有常规的方法无法满足要求时，才要额外的配置。

### 命名约定 {#naming-conventions}

默认情况下，Active Record 使用一些命名约定，查找模型和数据表之间的映射关系。Rails 把模型的类名转换成复数，然后查找对应的数据表。例如，模型类名为 `Book`，数据表就是 `books`。Rails 提供的单复数变形功能很强大，常见和不常见的变形方式都能处理。如果类名由多个单词组成，应该按照 Ruby 的约定，使用驼峰式命名法，这时对应的数据表将使用下划线分隔各单词。因此：

* 数据表名：复数，下划线分隔单词（例如 `book_clubs`）
* 模型类名：单数，每个单词的首字母大写（例如 `BookClub`）

| 模型 / 类      | 数据表 / 模式   |
| ------------- | -------------- |
| `Post`        | `posts`        |
| `LineItem`    | `line_items`   |
| `Deer`        | `deers`        |
| `Mouse`       | `mice`         |
| `Person`      | `people`       |


### 模式约定 {#schema-conventions}

根据字段的作用不同，Active Record 对数据表中的字段命名也做了相应的约定：

* **外键** - 使用 `singularized_table_name_id` 形式命名，例如 `item_id`，`order_id`。创建模型关联后，Active Record 会查找这个字段；
* **主键** - 默认情况下，Active Record 使用整数字段 `id` 作为表的主键。使用 [Active Record 迁移]({{ site.baseurl}}/migrations.html)创建数据表时，会自动创建这个字段；

还有一些可选的字段，能为 Active Record 实例添加更多的功能：

* `created_at` - 创建记录时，自动设为当前的时间戳；
* `updated_at` - 更新记录时，自动设为当前的时间戳；
* `lock_version` - 在模型中添加[乐观锁定](http://api.rubyonrails.org/classes/ActiveRecord/Locking.html)功能；
* `type` - 让模型使用[单表集成](http://api.rubyonrails.org/classes/ActiveRecord/Base.html#label-Single+table+inheritance)；
* `(association_name)_type` - [多态关联]({{ site.baseurl }}/association_basics.html#polymorphic-associations)的类型；
* `(table_name)_count` - 缓存关联对象的数量。例如，`posts` 表中的 `comments_count` 字段，缓存每篇文章的评论数；

I> 虽然这些字段是可选的，但在 Active Record 中是被保留的。如果想使用相应的功能，就不要把这些保留字段用作其他用途。例如，`type` 这个保留字段是用来指定数据表使用“单表继承”（STI）的，如果不用 STI，请使用其他的名字，例如“context”，这也能表明该字段的作用。

## 创建 Active Record 模型 {#creating-active-record-models}

创建 Active Record 模型的过程很简单，只要继承 `ActiveRecord::Base` 类就行了：

{:lang="ruby"}
~~~
class Product < ActiveRecord::Base
end
~~~

上面的代码会创建 `Product` 模型，对应于数据库中的 `products` 表。同时，`products` 表中的字段也映射到 `Product` 模型实例的属性上。假如 `products` 表由下面的 SQL 语句创建：

{:lang="sql"}
~~~
CREATE TABLE products (
   id int(11) NOT NULL auto_increment,
   name varchar(255),
   PRIMARY KEY  (id)
);
~~~

按照这样的数据表结构，可以编写出下面的代码：

{:lang="ruby"}
~~~
p = Product.new
p.name = "Some Book"
puts p.name # "Some Book"
~~~

## 不用默认的命名约定 {#overriding-the-naming-conventions}

如果想使用其他的命名约定，或者在 Rails 程序中使用即有的数据库可以吗？没问题，不用默认的命名约定也很简单。

使用 `ActiveRecord::Base.table_name=` 方法可以指定数据表的名字：

{:lang="ruby"}
~~~
class Product < ActiveRecord::Base
  self.table_name = "PRODUCT"
end
~~~

如果这么做，还要在测试中调用 `set_fixture_class` 方法，手动指定固件（`class_name.yml`）的类名：

{:lang="ruby"}
~~~
class FunnyJoke < ActiveSupport::TestCase
  set_fixture_class funny_jokes: Joke
  fixtures :funny_jokes
  ...
end
~~~

还可以使用 `ActiveRecord::Base.primary_key=` 方法指定数据表的主键：

{:lang="ruby"}
~~~
class Product < ActiveRecord::Base
  self.primary_key = "product_id"
end
~~~

## CRUD：读写数据 {#crud-reading-and-writing-data}

CURD 是四种数据操作的简称：C 表示创建，R 表示读取，U 表示更新，D 表示删除。Active Record 自动创建了处理数据表中数据的方法。

### 创建 {#create}

Active Record 对象可以使用 Hash 创建，在块中创建，或者创建后手动设置属性。`new` 方法创建一个新对象，`create` 方法创建新对象，并将其存入数据库。

例如，`User` 模型中有两个属性，`name` 和 `occupation`。调用 `create` 方法会创建一个新纪录，并存入数据库：

{:lang="ruby"}
~~~
user = User.create(name: "David", occupation: "Code Artist")
~~~

使用 `new` 方法，可以实例化一个新对象，但不会保存：

{:lang="ruby"}
~~~
user = User.new
user.name = "David"
user.occupation = "Code Artist"
~~~

调用 `user.save` 可以把记录存入数据库。

如果在 `create` 和 `new` 方法中使用块，会把新创建的对象拉入块中：

{:lang="ruby"}
~~~
user = User.new do |u|
  u.name = "David"
  u.occupation = "Code Artist"
end
~~~

### 读取 {#read}

Active Record 为读取数据库中的数据提供了丰富的 API。下面举例说明。

{:lang="ruby"}
~~~
# return a collection with all users
users = User.all
~~~

{:lang="ruby"}
~~~
# return the first user
user = User.first
~~~

{:lang="ruby"}
~~~
# return the first user named David
david = User.find_by(name: 'David')
~~~

{:lang="ruby"}
~~~
# find all users named David who are Code Artists and sort by created_at
# in reverse chronological order
users = User.where(name: 'David', occupation: 'Code Artist').order('created_at DESC')
~~~

[Active Record 查询]({{ site.baseurl }}/active_record_querying.html)一文会详细介绍查询 Active Record 模型的方法。

### 更新 {#update}

得到 Active Record 对象后，可以修改其属性，然后再存入数据库。

{:lang="ruby"}
~~~
user = User.find_by(name: 'David')
user.name = 'Dave'
user.save
~~~

还有个简写方式，使用 Hash，指定属性名和属性值，例如：

{:lang="ruby"}
~~~
user = User.find_by(name: 'David')
user.update(name: 'Dave')
~~~

一次更新多个属性时使用这种方法很方便。如果想批量更新多个记录，可以使用类方法 `update_all`：

{:lang="ruby"}
~~~
User.update_all "max_login_attempts = 3, must_change_password = 'true'"
~~~

### 删除 {#delete}

类似地，得到 Active Record 对象后还可以将其销毁，从数据库中删除。

{:lang="ruby"}
~~~
user = User.find_by(name: 'David')
user.destroy
~~~

## 数据验证 {#validations}

在存入数据库之前，Active Record 还可以验证模型。模型验证有很多方法，可以检查属性值是否不为空、是否是唯一的，或者没有在数据库中出现过，等等。

把数据存入数据库之前进行验证是十分重要的步骤，所以调用 `create`、`save`、`update` 这三个方法时会做数据验证，验证失败时返回 `false`，此时不会对数据库做任何操作。这三个方法都要对应的爆炸方法（`create!`，`save!`，`update!`），爆炸方法要严格一些，如果验证失败，会抛出 `ActiveRecord::RecordInvalid` 异常。下面是个简单的例子：

{:lang="ruby"}
~~~
class User < ActiveRecord::Base
  validates :name, presence: true
end

User.create  # => false
User.create! # => ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
~~~

[Active Record 数据验证]({{ site.baseurl }}/active_record_validations.html)一文会详细介绍数据验证。

## 回调 {#callbacks}

Active Record 回调可以在模型声明周期的特定事件上绑定代码，相应的事件发生时，执行这些代码。例如创建新纪录时，更新记录时，删除记录时，等等。[Active Record 回调]({{ site.baseurl }}/active_record_callbacks.html)一文会详细介绍回调。

## 迁移 {#migrations}

Rails 提供了一个 DSL 用来处理数据库模式，叫做“迁移”。迁移的代码存储在特定的文件中，通过 `rake` 调用，可以用在 Active Record 支持的所有数据库上。下面这个迁移会新建一个数据表：

{:lang="ruby"}
~~~
class CreatePublications < ActiveRecord::Migration
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
~~~

Rails 会跟踪哪些迁移已经应用到数据库中，还提供了回滚功能。创建数据表要执行 `rake db:migrate` 命令；回滚操作要执行 `rake db:rollback` 命令。

注意，上面的代码和具体的数据库种类无关，可用于 MySQL、PostgreSQL、Oracle 等数据库。关于迁移的详细介绍，参阅 [Active Record 迁移]({{ site.baseurl }}/migrations.html)一文。
