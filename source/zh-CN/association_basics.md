Active Record 关联
==================

本文介绍 Active Record 中的关联功能。

读完后，你将学会：

* 如何声明 Active Record 模型间的关联；
* 怎么理解不同的 Active Record 关联类型；
* 如何使用关联添加的方法；

--------------------------------------------------------------------------------

为什么要使用关联
--------------

模型之间为什么要有关联？因为关联让常规操作更简单。例如，在一个简单的 Rails 程序中，有一个顾客模型和一个订单模型。每个顾客可以下多个订单。没用关联的模型定义如下：

```ruby
class Customer < ActiveRecord::Base
end

class Order < ActiveRecord::Base
end
```

假如我们要为一个顾客添加一个订单，得这么做：

```ruby
@order = Order.create(order_date: Time.now, customer_id: @customer.id)
```

或者说要删除一个顾客，确保他的所有订单都会被删除，得这么做：

```ruby
@orders = Order.where(customer_id: @customer.id)
@orders.each do |order|
  order.destroy
end
@customer.destroy
```

使用 Active Record 关联，告诉 Rails 这两个模型是有一定联系的，就可以把这些操作连在一起。下面使用关联重新定义顾客和订单模型：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, dependent: :destroy
end

class Order < ActiveRecord::Base
  belongs_to :customer
end
```

这么修改之后，为某个顾客添加新订单就变得简单了：

```ruby
@order = @customer.orders.create(order_date: Time.now)
```

删除顾客及其所有订单更容易：

```ruby
@customer.destroy
```

学习更多关联类型，请阅读下一节。下一节介绍了一些使用关联时的小技巧，然后列出了关联添加的所有方法和选项。

关联的类型
---------

在 Rails 中，关联是两个 Active Record 模型之间的关系。关联使用宏的方式实现，用声明的形式为模型添加功能。例如，声明一个模型属于（`belongs_to`）另一个模型后，Rails 会维护两个模型之间的“主键-外键”关系，而且还向模型中添加了很多实用的方法。Rails 支持六种关联：

* `belongs_to`
* `has_one`
* `has_many`
* `has_many :through`
* `has_one :through`
* `has_and_belongs_to_many`

在后面的几节中，你会学到如何声明并使用这些关联。首先来看一下各种关联适用的场景。

### `belongs_to` 关联

`belongs_to` 关联创建两个模型之间一对一的关系，声明所在的模型实例属于另一个模型的实例。例如，如果程序中有顾客和订单两个模型，每个订单只能指定给一个顾客，就要这么声明订单模型：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
```

![belongs_to 关联](images/belongs_to.png)

NOTE: 在 `belongs_to` 关联声明中必须使用单数形式。如果在上面的代码中使用复数形式，程序会报错，提示未初始化常量 `Order::Customers`。因为 Rails 自动使用关联中的名字引用类名。如果关联中的名字错误的使用复数，引用的类也就变成了复数。

相应的迁移如下：

```ruby
class CreateOrders < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :name
      t.timestamps
    end

    create_table :orders do |t|
      t.belongs_to :customer
      t.datetime :order_date
      t.timestamps
    end
  end
end
```

### `has_one` 关联

`has_one` 关联也会建立两个模型之间的一对一关系，但语义和结果有点不一样。这种关联表示模型的实例包含或拥有另一个模型的实例。例如，在程序中，每个供应商只有一个账户，可以这么定义供应商模型：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
end
```

![has_one 关联](images/has_one.png)

相应的迁移如下：

```ruby
class CreateSuppliers < ActiveRecord::Migration
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier
      t.string :account_number
      t.timestamps
    end
  end
end
```

### `has_many` 关联

`has_many` 关联建立两个模型之间的一对多关系。在 `belongs_to` 关联的另一端经常会使用这个关联。`has_many` 关联表示模型的实例有零个或多个另一个模型的实例。例如，在程序中有顾客和订单两个模型，顾客模型可以这么定义：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders
end
```

NOTE: 声明 `has_many` 关联时，另一个模型使用复数形式。

![has_many 关联](images/has_many.png)

相应的迁移如下：

```ruby
class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :name
      t.timestamps
    end

    create_table :orders do |t|
      t.belongs_to :customer
      t.datetime :order_date
      t.timestamps
    end
  end
end
```

### `has_many :through` 关联

`has_many :through` 关联经常用来建立两个模型之间的多对多关联。这种关联表示一个模型的实例可以借由第三个模型，拥有零个和多个另一个模型的实例。例如，在医疗锻炼中，病人要和医生约定练习时间。这中间的关联声明如下：

```ruby
class Physician < ActiveRecord::Base
  has_many :appointments
  has_many :patients, through: :appointments
end

class Appointment < ActiveRecord::Base
  belongs_to :physician
  belongs_to :patient
end

class Patient < ActiveRecord::Base
  has_many :appointments
  has_many :physicians, through: :appointments
end
```

![has_many :through 关联](images/has_many_through.png)

相应的迁移如下：

```ruby
class CreateAppointments < ActiveRecord::Migration
  def change
    create_table :physicians do |t|
      t.string :name
      t.timestamps
    end

    create_table :patients do |t|
      t.string :name
      t.timestamps
    end

    create_table :appointments do |t|
      t.belongs_to :physician
      t.belongs_to :patient
      t.datetime :appointment_date
      t.timestamps
    end
  end
end
```

连接模型中的集合可以使用 API 关联。例如：

```ruby
physician.patients = patients
```

会为新建立的关联对象创建连接模型实例，如果其中一个对象删除了，相应的记录也会删除。


WARNING: 自动删除连接模型的操作直接执行，不会触发 `*_destroy` 回调。

`has_many :through` 还可用来简化嵌套的 `has_many` 关联。例如，一个文档分为多个部分，每一部分又有多个段落，如果想使用简单的方式获取文档中的所有段落，可以这么做：

```ruby
class Document < ActiveRecord::Base
  has_many :sections
  has_many :paragraphs, through: :sections
end

class Section < ActiveRecord::Base
  belongs_to :document
  has_many :paragraphs
end

class Paragraph < ActiveRecord::Base
  belongs_to :section
end
```

加上 `through: :sections` 后，Rails 就能理解这段代码：

```ruby
@document.paragraphs
```

### `has_one :through` 关联

`has_one :through` 关联建立两个模型之间的一对一关系。这种关联表示一个模型通过第三个模型拥有另一个模型的实例。例如，每个供应商只有一个账户，而且每个账户都有一个历史账户，那么可以这么定义模型：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
  has_one :account_history, through: :account
end

class Account < ActiveRecord::Base
  belongs_to :supplier
  has_one :account_history
end

class AccountHistory < ActiveRecord::Base
  belongs_to :account
end
```

![has_one :through 关联](images/has_one_through.png)

相应的迁移如下：

```ruby
class CreateAccountHistories < ActiveRecord::Migration
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier
      t.string :account_number
      t.timestamps
    end

    create_table :account_histories do |t|
      t.belongs_to :account
      t.integer :credit_rating
      t.timestamps
    end
  end
end
```

### `has_and_belongs_to_many` 关联

`has_and_belongs_to_many` 关联之间建立两个模型之间的多对多关系，不借由第三个模型。例如，程序中有装配体和零件两个模型，每个装配体中有多个零件，每个零件又可用于多个装配体，这时可以按照下面的方式定义模型：

```ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end

class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

![has_and_belongs_to_many 关联](images/habtm.png)

相应的迁移如下：

```ruby
class CreateAssembliesAndParts < ActiveRecord::Migration
  def change
    create_table :assemblies do |t|
      t.string :name
      t.timestamps
    end

    create_table :parts do |t|
      t.string :part_number
      t.timestamps
    end

    create_table :assemblies_parts, id: false do |t|
      t.belongs_to :assembly
      t.belongs_to :part
    end
  end
end
```

### 使用 `belongs_to` 还是 `has_one`

如果想建立两个模型之间的一对一关系，可以在一个模型中声明 `belongs_to`，然后在另一模型中声明 `has_one`。但是怎么知道在哪个模型中声明哪种关联？

不同的声明方式带来的区别是外键放在哪个模型对应的数据表中（外键在声明 `belongs_to` 关联所在模型对应的数据表中）。不过声明时要考虑一下语义，`has_one` 的意思是某样东西属于我。例如，说供应商有一个账户，比账户拥有供应商更合理，所以正确的关联应该这么声明：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
end

class Account < ActiveRecord::Base
  belongs_to :supplier
end
```

相应的迁移如下：

```ruby
class CreateSuppliers < ActiveRecord::Migration
  def change
    create_table :suppliers do |t|
      t.string  :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.integer :supplier_id
      t.string  :account_number
      t.timestamps
    end
  end
end
```

NOTE: `t.integer :supplier_id` 更明确的表明了外键的名字。在目前的 Rails 版本中，可以抽象实现的细节，使用 `t.references :supplier` 代替。

### 使用 `has_many :through` 还是 `has_and_belongs_to_many`

Rails 提供了两种建立模型之间多对多关系的方法。其中比较简单的是 `has_and_belongs_to_many`，可以直接建立关联：

```ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end

class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

第二种方法是使用 `has_many :through`，但无法直接建立关联，要通过第三个模型：

```ruby
class Assembly < ActiveRecord::Base
  has_many :manifests
  has_many :parts, through: :manifests
end

class Manifest < ActiveRecord::Base
  belongs_to :assembly
  belongs_to :part
end

class Part < ActiveRecord::Base
  has_many :manifests
  has_many :assemblies, through: :manifests
end
```

根据经验，如果关联的第三个模型要作为独立实体使用，要用 `has_many :through` 关联；如果不需要使用第三个模型，用简单的 `has_and_belongs_to_many` 关联即可（不过要记得在数据库中创建连接数据表）。

如果需要做数据验证、回调，或者连接模型上要用到其他属性，此时就要使用 `has_many :through` 关联。

### 多态关联

关联还有一种高级用法，“多态关联”。在多态关联中，在同一个关联中，模型可以属于其他多个模型。例如，图片模型可以属于雇员模型或者产品模型，模型的定义如下：

```ruby
class Picture < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true
end

class Employee < ActiveRecord::Base
  has_many :pictures, as: :imageable
end

class Product < ActiveRecord::Base
  has_many :pictures, as: :imageable
end
```

在 `belongs_to` 中指定使用多态，可以理解成创建了一个接口，可供任何一个模型使用。在 `Employee` 模型实例上，可以使用 `@employee.pictures` 获取图片集合。类似地，可使用 `@product.pictures` 获取产品的图片。

在 `Picture` 模型的实例上，可以使用 `@picture.imageable` 获取父对象。不过事先要在声明多态接口的模型中创建外键字段和类型字段：

```ruby
class CreatePictures < ActiveRecord::Migration
  def change
    create_table :pictures do |t|
      t.string  :name
      t.integer :imageable_id
      t.string  :imageable_type
      t.timestamps
    end
  end
end
```

上面的迁移可以使用 `t.references` 简化：

```ruby
class CreatePictures < ActiveRecord::Migration
  def change
    create_table :pictures do |t|
      t.string :name
      t.references :imageable, polymorphic: true
      t.timestamps
    end
  end
end
```

![多态关联](images/polymorphic.png)

### 自连接

设计数据模型时会发现，有时模型要和自己建立关联。例如，在一个数据表中保存所有雇员的信息，但要建立经理和下属之间的关系。这种情况可以使用自连接关联解决：

```ruby
class Employee < ActiveRecord::Base
  has_many :subordinates, class_name: "Employee",
                          foreign_key: "manager_id"

  belongs_to :manager, class_name: "Employee"
end
```

这样定义模型后，就可以使用 `@employee.subordinates` 和 `@employee.manager` 了。

在迁移中，要添加一个引用字段，指向模型自身：

```ruby
class CreateEmployees < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      t.references :manager
      t.timestamps
    end
  end
end
```

小技巧和注意事项
--------------

在 Rails 程序中高效地使用 Active Record 关联，要了解以下几个知识：

* 缓存控制
* 避免命名冲突
* 更新模式
* 控制关联的作用域
* Bi-directional associations

### 缓存控制

关联添加的方法都会使用缓存，记录最近一次查询结果，以备后用。缓存还会在方法之间共享。例如：

```ruby
customer.orders                 # retrieves orders from the database
customer.orders.size            # uses the cached copy of orders
customer.orders.empty?          # uses the cached copy of orders
```

程序的其他部分会修改数据，那么应该怎么重载缓存呢？调用关联方法时传入 `true` 参数即可：

```ruby
customer.orders                 # retrieves orders from the database
customer.orders.size            # uses the cached copy of orders
customer.orders(true).empty?    # discards the cached copy of orders
                                # and goes back to the database
```

### 避免命名冲突

关联的名字并不能随意使用。因为创建关联时，会向模型添加同名方法，所以关联的名字不能和 `ActiveRecord::Base` 中的实例方法同名。如果同名，关联方法会覆盖 `ActiveRecord::Base` 中的实例方法，导致错误。例如，关联的名字不能为 `attributes` 或 `connection`。

### 更新模式

关联非常有用，但没什么魔法。关联对应的数据库模式需要你自己编写。不同的关联类型，要做的事也不同。对 `belongs_to` 关联来说，要创建外键；对 `has_and_belongs_to_many` 来说，要创建相应的连接数据表。

#### 创建 `belongs_to` 关联所需的外键

声明 `belongs_to` 关联后，要创建相应的外键。例如，有下面这个模型：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
```

这种关联需要在数据表中创建合适的外键：

```ruby
class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.datetime :order_date
      t.string   :order_number
      t.integer  :customer_id
    end
  end
end
```

如果声明关联之前已经定义了模型，则要在迁移中使用 `add_column` 创建外键。

#### 创建 `has_and_belongs_to_many` 关联所需的连接数据表

声明 `has_and_belongs_to_many` 关联后，必须手动创建连接数据表。除非在 `:join_table` 选项中指定了连接数据表的名字，否则 Active Record 会按照类名出现在字典中的顺序为数据表起名字。那么，顾客和订单模型使用的连接数据表默认名为“customers_orders”，因为在字典中，“c”在“o”前面。

WARNING: 模型名的顺序使用字符串的 `<` 操作符确定。所以，如果两个字符串的长度不同，比较最短长度时，两个字符串是相等的，但长字符串的排序比短字符串靠前。例如，你可能以为“"paper\_boxes”和“papers”这两个表生成的连接表名为“papers\_paper\_boxes”，因为“paper\_boxes”比“papers”长。其实生成的连接表名为“paper\_boxes\_papers”，因为在一般的编码方式中，“\_”比“s”靠前。

不管名字是什么，你都要在迁移中手动创建连接数据表。例如下面的关联声明：

```ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end

class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

需要在迁移中创建 `assemblies_parts` 数据表，而且该表无主键：

```ruby
class CreateAssembliesPartsJoinTable < ActiveRecord::Migration
  def change
    create_table :assemblies_parts, id: false do |t|
      t.integer :assembly_id
      t.integer :part_id
    end
  end
end
```

我们把 `id: false` 选项传给 `create_table` 方法，因为这个表不对应模型。只有这样，关联才能正常建立。如果在使用 `has_and_belongs_to_many` 关联时遇到奇怪的表现，例如提示模型 ID 损坏，或 ID 冲突，有可能就是因为创建了主键。

### 控制关联的作用域

默认情况下，关联只会查找当前模块作用域中的对象。如果在模块中定义 Active Record 模型，知道这一点很重要。例如：

```ruby
module MyApplication
  module Business
    class Supplier < ActiveRecord::Base
       has_one :account
    end

    class Account < ActiveRecord::Base
       belongs_to :supplier
    end
  end
end
```

上面的代码能正常运行，因为 `Supplier` 和 `Account` 在同一个作用域内。但下面这段代码就不行了，因为 `Supplier` 和 `Account` 在不同的作用域中：

```ruby
module MyApplication
  module Business
    class Supplier < ActiveRecord::Base
       has_one :account
    end
  end

  module Billing
    class Account < ActiveRecord::Base
       belongs_to :supplier
    end
  end
end
```

要想让处在不同命名空间中的模型正常建立关联，声明关联时要指定完整的类名：

```ruby
module MyApplication
  module Business
    class Supplier < ActiveRecord::Base
       has_one :account,
        class_name: "MyApplication::Billing::Account"
    end
  end

  module Billing
    class Account < ActiveRecord::Base
       belongs_to :supplier,
        class_name: "MyApplication::Business::Supplier"
    end
  end
end
```

### 双向关联

一般情况下，都要求能在关联的两端进行操作。例如，有下面的关联声明：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders
end

class Order < ActiveRecord::Base
  belongs_to :customer
end
```

默认情况下，Active Record 并不知道这个关联中两个模型之间的联系。可能导致同一对象的两个副本不同步：

```ruby
c = Customer.first
o = c.orders.first
c.first_name == o.customer.first_name # => true
c.first_name = 'Manny'
c.first_name == o.customer.first_name # => false
```

之所以会发生这种情况，是因为 `c` 和 `o.customer` 在内存中是同一数据的两钟表示，修改其中一个并不会刷新另一个。Active Record 提供了 `:inverse_of` 选项，可以告知 Rails 两者之间的关系：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, inverse_of: :customer
end

class Order < ActiveRecord::Base
  belongs_to :customer, inverse_of: :orders
end
```

这么修改之后，Active Record 就只会加载一个顾客对象，避免数据的不一致性，提高程序的执行效率：

```ruby
c = Customer.first
o = c.orders.first
c.first_name == o.customer.first_name # => true
c.first_name = 'Manny'
c.first_name == o.customer.first_name # => true
```

`inverse_of` 有些限制：

* 不能和 `:through` 选项同时使用；
* 不能和 `:polymorphic` 选项同时使用；
* 不能和 `:as` 选项同时使用；
* 在 `belongs_to` 关联中，会忽略 `has_many` 关联的 `inverse_of` 选项；

每种关联都会尝试自动找到关联的另一端，设置 `:inverse_of` 选项（根据关联的名字）。使用标准名字的关联都有这种功能。但是，如果在关联中设置了下面这些选项，将无法自动设置 `:inverse_of`：

* `:conditions`
* `:through`
* `:polymorphic`
* `:foreign_key`

关联详解
-------

下面几节详细说明各种关联，包括添加的方法和声明关联时可以使用的选项。

### `belongs_to` 关联详解

`belongs_to` 关联创建一个模型与另一个模型之间的一对一关系。用数据库的行话来说，就是这个类中包含了外键。如果外键在另一个类中，就应该使用 `has_one` 关联。

#### `belongs_to` 关联添加的方法

声明  `belongs_to` 关联后，所在的类自动获得了五个和关联相关的方法：

* `association(force_reload = false)`
* `association=(associate)`
* `build_association(attributes = {})`
* `create_association(attributes = {})`
* `create_association!(attributes = {})`

这五个方法中的 `association` 要替换成传入 `belongs_to` 方法的第一个参数。例如，如下的声明：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
```

每个 `Order` 模型实例都获得了这些方法：

```ruby
customer
customer=
build_customer
create_customer
create_customer!
```

NOTE: 在 `has_one` 和 `belongs_to` 关联中，必须使用 `build_*` 方法构建关联对象。`association.build` 方法是在 `has_many` 和 `has_and_belongs_to_many` 关联中使用的。创建关联对象要使用 `create_*` 方法。

##### `association(force_reload = false)`

如果关联的对象存在，`association` 方法会返回关联对象。如果找不到关联对象，则返回 `nil`。

```ruby
@customer = @order.customer
```

如果关联对象之前已经取回，会返回缓存版本。如果不想使用缓存版本，强制重新从数据库中读取，可以把 `force_reload` 参数设为 `true`。

##### `association=(associate)`

`association=` 方法用来赋值关联的对象。这个方法的底层操作是，从关联对象上读取主键，然后把值赋给该主键对应的对象。

```ruby
@order.customer = @customer
```

##### `build_association(attributes = {})`

`build_association` 方法返回该关联类型的一个新对象。这个对象使用传入的属性初始化，和对象连接的外键会自动设置，但关联对象不会存入数据库。

```ruby
@customer = @order.build_customer(customer_number: 123,
                                  customer_name: "John Doe")
```

##### `create_association(attributes = {})`

`create_association` 方法返回该关联类型的一个新对象。这个对象使用传入的属性初始化，和对象连接的外键会自动设置，只要能通过所有数据验证，就会把关联对象存入数据库。

```ruby
@customer = @order.create_customer(customer_number: 123,
                                   customer_name: "John Doe")
```

##### `create_association!(attributes = {})`

和 `create_association` 方法作用相同，但是如果记录不合法，会抛出 `ActiveRecord::RecordInvalid` 异常。

#### `belongs_to` 方法的选项

Rails 的默认设置足够智能，能满足常见需求。但有时还是需要定制 `belongs_to` 关联的行为。定制的方法很简单，声明关联时传入选项或者使用代码块即可。例如，下面的关联使用了两个选项：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, dependent: :destroy,
    counter_cache: true
end
```

`belongs_to` 关联支持以下选项：

* `:autosave`
* `:class_name`
* `:counter_cache`
* `:dependent`
* `:foreign_key`
* `:inverse_of`
* `:polymorphic`
* `:touch`
* `:validate`

##### `:autosave`

如果把 `:autosave` 选项设为 `true`，保存父对象时，会自动保存所有子对象，并把标记为析构的子对象销毁。

##### `:class_name`

如果另一个模型无法从关联的名字获取，可以使用 `:class_name` 选项指定模型名。例如，如果订单属于顾客，但表示顾客的模型是 `Patron`，就可以这样声明关联：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, class_name: "Patron"
end
```

##### `:counter_cache`

`:counter_cache` 选项可以提高统计所属对象数量操作的效率。假如如下的模型：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
class Customer < ActiveRecord::Base
  has_many :orders
end
```

这样声明关联后，如果想知道 `@customer.orders.size` 的结果，就要在数据库中执行 `COUNT(*)` 查询。如果不想执行这个查询，可以在声明 `belongs_to` 关联的模型中加入计数缓存功能：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, counter_cache: true
end
class Customer < ActiveRecord::Base
  has_many :orders
end
```

这样声明关联后，Rails 会及时更新缓存，调用 `size` 方法时返回缓存中的值。

虽然 `:counter_cache` 选项在声明 `belongs_to` 关联的模型中设置，但实际使用的字段要添加到关联的模型中。针对上面的例子，要把 `orders_count` 字段加入 `Customer` 模型。这个字段的默认名也是可以设置的：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, counter_cache: :count_of_orders
end
class Customer < ActiveRecord::Base
  has_many :orders
end
```

计数缓存字段通过 `attr_readonly` 方法加入关联模型的只读属性列表中。

##### `:dependent`

`:dependent` 选项的值有两个：

* `:destroy`：销毁对象时，也会在关联对象上调用 `destroy` 方法；
* `:delete`：销毁对象时，关联的对象不会调用 `destroy` 方法，而是直接从数据库中删除；

WARNING: 在 `belongs_to` 关联和 `has_many` 关联配对时，不应该设置这个选项，否则会导致数据库中出现孤儿记录。

##### `:foreign_key`

按照约定，用来存储外键的字段名是关联名后加 `_id`。`:foreign_key` 选项可以设置要使用的外键名：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, class_name: "Patron",
                        foreign_key: "patron_id"
end
```

TIP: 不管怎样，Rails 都不会自动创建外键字段，你要自己在迁移中创建。

##### `:inverse_of`

`:inverse_of` 选项指定 `belongs_to` 关联另一端的 `has_many` 和 `has_one` 关联名。不能和 `:polymorphic` 选项一起使用。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, inverse_of: :customer
end

class Order < ActiveRecord::Base
  belongs_to :customer, inverse_of: :orders
end
```

##### `:polymorphic`

`:polymorphic` 选项为 `true` 时表明这是个多态关联。[前文](#polymorphic-associations)已经详细介绍过多态关联。

##### `:touch`

如果把 `:touch` 选项设为 `true`，保存或销毁对象时，关联对象的 `updated_at` 或 `updated_on` 字段会自动设为当前时间戳。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, touch: true
end

class Customer < ActiveRecord::Base
  has_many :orders
end
```

在这个例子中，保存或销毁订单后，会更新关联的顾客中的时间戳。还可指定要更新哪个字段的时间戳：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, touch: :orders_updated_at
end
```

##### `:validate`

如果把 `:validate` 选项设为 `true`，保存对象时，会同时验证关联对象。该选项的默认值是 `false`，保存对象时不验证关联对象。

#### `belongs_to` 的作用域

有时可能需要定制 `belongs_to` 关联使用的查询方式，定制的查询可在作用域代码块中指定。例如：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, -> { where active: true },
                        dependent: :destroy
end
```

在作用域代码块中可以使用任何一个标准的[查询方法](active_record_querying.html)。下面分别介绍这几个方法：

* `where`
* `includes`
* `readonly`
* `select`

##### `where`

`where` 方法指定关联对象必须满足的条件。

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, -> { where active: true }
end
```

##### `includes`

`includes` 方法指定使用关联时要按需加载的间接关联。例如，有如下的模型：

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :line_items
end

class Customer < ActiveRecord::Base
  has_many :orders
end
```

如果经常要直接从商品上获取顾客对象（`@line_item.order.customer`），就可以把顾客引入商品和订单的关联中：

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order, -> { includes :customer }
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :line_items
end

class Customer < ActiveRecord::Base
  has_many :orders
end
```

NOTE: 直接关联没必要使用 `includes`。如果 `Order belongs_to :customer`，那么顾客会自动按需加载。

##### `readonly`

如果使用 `readonly`，通过关联获取的对象就是只读的。

##### `select`

`select` 方法会覆盖获取关联对象使用的 SQL `SELECT` 子句。默认情况下，Rails 会读取所有字段。

TIP: 如果在 `belongs_to` 关联中使用 `select` 方法，应该同时设置 `:foreign_key` 选项，确保返回正确的结果。

#### 检查关联的对象是否存在

检查关联的对象是否存在可以使用 `association.nil?` 方法：

```ruby
if @order.customer.nil?
  @msg = "No customer found for this order"
end
```

#### 什么时候保存对象

把对象赋值给 `belongs_to` 关联不会自动保存对象，也不会保存关联的对象。

### `has_one` 关联详解

`has_one` 关联建立两个模型之间的一对一关系。用数据库的行话说，这种关联的意思是外键在另一个类中。如果外键在这个类中，应该使用 `belongs_to` 关联。

#### `has_one` 关联添加的方法

声明 `has_one` 关联后，声明所在的类自动获得了五个关联相关的方法：

* `association(force_reload = false)`
* `association=(associate)`
* `build_association(attributes = {})`
* `create_association(attributes = {})`
* `create_association!(attributes = {})`

这五个方法中的 `association` 要替换成传入 `has_one` 方法的第一个参数。例如，如下的声明：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
end
```

每个 `Supplier` 模型实例都获得了这些方法：

```ruby
account
account=
build_account
create_account
create_account!
```

NOTE: 在 `has_one` 和 `belongs_to` 关联中，必须使用 `build_*` 方法构建关联对象。`association.build` 方法是在 `has_many` 和 `has_and_belongs_to_many` 关联中使用的。创建关联对象要使用 `create_*` 方法。

##### `association(force_reload = false)`

如果关联的对象存在，`association` 方法会返回关联对象。如果找不到关联对象，则返回 `nil`。

```ruby
@account = @supplier.account
```

如果关联对象之前已经取回，会返回缓存版本。如果不想使用缓存版本，强制重新从数据库中读取，可以把 `force_reload` 参数设为 `true`。

##### `association=(associate)`

`association=` 方法用来赋值关联的对象。这个方法的底层操作是，从关联对象上读取主键，然后把值赋给该主键对应的关联对象。

```ruby
@supplier.account = @account
```

##### `build_association(attributes = {})`

`build_association` 方法返回该关联类型的一个新对象。这个对象使用传入的属性初始化，和对象连接的外键会自动设置，但关联对象不会存入数据库。

```ruby
@account = @supplier.build_account(terms: "Net 30")
```

##### `create_association(attributes = {})`

`create_association` 方法返回该关联类型的一个新对象。这个对象使用传入的属性初始化，和对象连接的外键会自动设置，只要能通过所有数据验证，就会把关联对象存入数据库。

```ruby
@account = @supplier.create_account(terms: "Net 30")
```

##### `create_association!(attributes = {})`

和 `create_association` 方法作用相同，但是如果记录不合法，会抛出 `ActiveRecord::RecordInvalid` 异常。

#### `has_one` 方法的选项

Rails 的默认设置足够智能，能满足常见需求。但有时还是需要定制 `has_one` 关联的行为。定制的方法很简单，声明关联时传入选项即可。例如，下面的关联使用了两个选项：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, class_name: "Billing", dependent: :nullify
end
```

`has_one` 关联支持以下选项：

* `:as`
* `:autosave`
* `:class_name`
* `:dependent`
* `:foreign_key`
* `:inverse_of`
* `:primary_key`
* `:source`
* `:source_type`
* `:through`
* `:validate`

##### `:as`

`:as` 选项表明这是多态关联。[前文](#polymorphic-associations)已经详细介绍过多态关联。

##### `:autosave`

如果把 `:autosave` 选项设为 `true`，保存父对象时，会自动保存所有子对象，并把标记为析构的子对象销毁。

##### `:class_name`

如果另一个模型无法从关联的名字获取，可以使用 `:class_name` 选项指定模型名。例如，供应商有一个账户，但表示账户的模型是 `Billing`，就可以这样声明关联：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, class_name: "Billing"
end
```

##### `:dependent`

设置销毁拥有者时要怎么处理关联对象：

* `:destroy`：也销毁关联对象；
* `:delete`：直接把关联对象对数据库中删除，因此不会执行回调；
* `:nullify`：把外键设为 `NULL`，不会执行回调；
* `:restrict_with_exception`：有关联的对象时抛出异常；
* `:restrict_with_error`：有关联的对象时，向拥有者添加一个错误；

如果在数据库层设置了 `NOT NULL` 约束，就不能使用 `:nullify` 选项。如果 `:dependent` 选项没有销毁关联，就无法修改关联对象，因为关联对象的外键设置为不接受 `NULL`。

##### `:foreign_key`

按照约定，在另一个模型中用来存储外键的字段名是模型名后加 `_id`。`:foreign_key` 选项可以设置要使用的外键名：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, foreign_key: "supp_id"
end
```

TIP: 不管怎样，Rails 都不会自动创建外键字段，你要自己在迁移中创建。

##### `:inverse_of`

`:inverse_of` 选项指定 `has_one` 关联另一端的 `belongs_to` 关联名。不能和 `:through` 或 `:as` 选项一起使用。

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, inverse_of: :supplier
end

class Account < ActiveRecord::Base
  belongs_to :supplier, inverse_of: :account
end
```

##### `:primary_key`

按照约定，用来存储该模型主键的字段名 `id`。`:primary_key` 选项可以设置要使用的主键名。

##### `:source`

`:source` 选项指定 `has_one :through` 关联的关联源名字。

##### `:source_type`

`:source_type` 选项指定 `has_one :through` 关联中用来处理多态关联的关联源类型。

##### `:through`

`:through` 选项指定用来执行查询的连接模型。[前文](#the-has-one-through-association)详细介绍过 `has_one :through` 关联。

##### `:validate`

如果把 `:validate` 选项设为 `true`，保存对象时，会同时验证关联对象。该选项的默认值是 `false`，保存对象时不验证关联对象。

#### `has_one` 的作用域

有时可能需要定制 `has_one` 关联使用的查询方式，定制的查询可在作用域代码块中指定。例如：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, -> { where active: true }
end
```

在作用域代码块中可以使用任何一个标准的[查询方法](active_record_querying.html)。下面分别介绍这几个方法：

* `where`
* `includes`
* `readonly`
* `select`

##### `where`

`where` 方法指定关联对象必须满足的条件。

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, -> { where "confirmed = 1" }
end
```

##### `includes`

`includes` 方法指定使用关联时要按需加载的间接关联。例如，有如下的模型：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
end

class Account < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :representative
end

class Representative < ActiveRecord::Base
  has_many :accounts
end
```

如果经常要直接获取供应商代表（`@supplier.account.representative`），就可以把代表引入供应商和账户的关联中：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, -> { includes :representative }
end

class Account < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :representative
end

class Representative < ActiveRecord::Base
  has_many :accounts
end
```

##### `readonly`

如果使用 `readonly`，通过关联获取的对象就是只读的。

##### `select`

`select` 方法会覆盖获取关联对象使用的 SQL `SELECT` 子句。默认情况下，Rails 会读取所有字段。

#### 检查关联的对象是否存在

检查关联的对象是否存在可以使用 `association.nil?` 方法：

```ruby
if @supplier.account.nil?
  @msg = "No account found for this supplier"
end
```

#### 什么时候保存对象

把对象赋值给 `has_one` 关联时，会自动保存对象（因为要更新外键）。而且所有被替换的对象也会自动保存，因为外键也变了。

如果无法通过验证，随便哪一次保存失败了，赋值语句就会返回 `false`，赋值操作会取消。

如果父对象（`has_one` 关联声明所在的模型）没保存（`new_record?` 方法返回 `true`），那么子对象也不会保存。只有保存了父对象，才会保存子对象。

如果赋值给 `has_one` 关联时不想保存对象，可以使用 `association.build` 方法。

### `has_many` 关联详解

`has_many` 关联建立两个模型之间的一对多关系。用数据库的行话说，这种关联的意思是外键在另一个类中，指向这个类的实例。

#### `has_many` 关联添加的方法

声明 `has_many` 关联后，声明所在的类自动获得了 16 个关联相关的方法：

* `collection(force_reload = false)`
* `collection<<(object, ...)`
* `collection.delete(object, ...)`
* `collection.destroy(object, ...)`
* `collection=objects`
* `collection_singular_ids`
* `collection_singular_ids=ids`
* `collection.clear`
* `collection.empty?`
* `collection.size`
* `collection.find(...)`
* `collection.where(...)`
* `collection.exists?(...)`
* `collection.build(attributes = {}, ...)`
* `collection.create(attributes = {})`
* `collection.create!(attributes = {})`

这些个方法中的 `collection` 要替换成传入 `has_many` 方法的第一个参数。`collection_singular` 要替换成第一个参数的单数形式。例如，如下的声明：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders
end
```

每个 `Customer` 模型实例都获得了这些方法：

```ruby
orders(force_reload = false)
orders<<(object, ...)
orders.delete(object, ...)
orders.destroy(object, ...)
orders=objects
order_ids
order_ids=ids
orders.clear
orders.empty?
orders.size
orders.find(...)
orders.where(...)
orders.exists?(...)
orders.build(attributes = {}, ...)
orders.create(attributes = {})
orders.create!(attributes = {})
```

##### `collection(force_reload = false)`

`collection` 方法返回一个数组，包含所有关联的对象。如果没有关联的对象，则返回空数组。

```ruby
@orders = @customer.orders
```

##### `collection<<(object, ...)`

`collection<<` 方法向关联对象数组中添加一个或多个对象，并把各所加对象的外键设为调用此方法的模型的主键。

```ruby
@customer.orders << @order1
```

##### `collection.delete(object, ...)`

`collection.delete` 方法从关联对象数组中删除一个或多个对象，并把删除的对象外键设为 `NULL`。

```ruby
@customer.orders.delete(@order1)
```

WARNING: 如果关联设置了 `dependent: :destroy`，还会销毁关联对象；如果关联设置了 `dependent: :delete_all`，还会删除关联对象。

##### `collection.destroy(object, ...)`

`collection.destroy` 方法在关联对象上调用 `destroy` 方法，从关联对象数组中删除一个或多个对象。

```ruby
@customer.orders.destroy(@order1)
```

WARNING: 对象会从数据库中删除，忽略 `:dependent` 选项。

##### `collection=objects`

`collection=` 让关联对象数组只包含指定的对象，根据需求会添加或删除对象。

##### `collection_singular_ids`

`collection_singular_ids` 返回一个数组，包含关联对象数组中各对象的 ID。

```ruby
@order_ids = @customer.order_ids
```

##### `collection_singular_ids=ids`

`collection_singular_ids=` 方法让数组中只包含指定的主键，根据需要增删 ID。

##### `collection.clear`

`collection.clear` 方法删除数组中的所有对象。如果关联中指定了 `dependent: :destroy` 选项，会销毁关联对象；如果关联中指定了 `dependent: :delete_all` 选项，会直接从数据库中删除对象，然后再把外键设为 `NULL`。

##### `collection.empty?`

如果关联数组中没有关联对象，`collection.empty?` 方法返回 `true`。

```erb
<% if @customer.orders.empty? %>
  No Orders Found
<% end %>
```

##### `collection.size`

`collection.size` 返回关联对象数组中的对象数量。

```ruby
@order_count = @customer.orders.size
```

##### `collection.find(...)`

`collection.find` 方法在关联对象数组中查找对象，句法和可用选项跟 `ActiveRecord::Base.find` 方法一样。

```ruby
@open_orders = @customer.orders.find(1)
```

##### `collection.where(...)`

`collection.where` 方法根据指定的条件在关联对象数组中查找对象，但会惰性加载对象，用到对象时才会执行查询。

```ruby
@open_orders = @customer.orders.where(open: true) # No query yet
@open_order = @open_orders.first # Now the database will be queried
```

##### `collection.exists?(...)`

`collection.exists?` 方法根据指定的条件检查关联对象数组中是否有符合条件的对象，句法和可用选项跟 `ActiveRecord::Base.exists?` 方法一样。

##### `collection.build(attributes = {}, ...)`

`collection.build` 方法返回一个或多个此种关联类型的新对象。这些对象会使用传入的属性初始化，还会创建对应的外键，但不会保存关联对象。

```ruby
@order = @customer.orders.build(order_date: Time.now,
                                order_number: "A12345")
```

##### `collection.create(attributes = {})`

`collection.create` 方法返回一个此种关联类型的新对象。这个对象会使用传入的属性初始化，还会创建对应的外键，只要能通过所有数据验证，就会保存关联对象。

```ruby
@order = @customer.orders.create(order_date: Time.now,
                                 order_number: "A12345")
```

##### `collection.create!(attributes = {})`

作用和 `collection.create` 相同，但如果记录不合法会抛出 `ActiveRecord::RecordInvalid` 异常。

#### `has_many` 方法的选项

Rails 的默认设置足够智能，能满足常见需求。但有时还是需要定制 `has_many` 关联的行为。定制的方法很简单，声明关联时传入选项即可。例如，下面的关联使用了两个选项：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, dependent: :delete_all, validate: :false
end
```

`has_many` 关联支持以下选项：

* `:as`
* `:autosave`
* `:class_name`
* `:dependent`
* `:foreign_key`
* `:inverse_of`
* `:primary_key`
* `:source`
* `:source_type`
* `:through`
* `:validate`

##### `:as`

`:as` 选项表明这是多态关联。[前文](#polymorphic-associations)已经详细介绍过多态关联。

##### `:autosave`

如果把 `:autosave` 选项设为 `true`，保存父对象时，会自动保存所有子对象，并把标记为析构的子对象销毁。

##### `:class_name`

如果另一个模型无法从关联的名字获取，可以使用 `:class_name` 选项指定模型名。例如，顾客有多个订单，但表示订单的模型是 `Transaction`，就可以这样声明关联：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, class_name: "Transaction"
end
```

##### `:dependent`

设置销毁拥有者时要怎么处理关联对象：

* `:destroy`：也销毁所有关联的对象；
* `:delete_all`：直接把所有关联对象对数据库中删除，因此不会执行回调；
* `:nullify`：把外键设为 `NULL`，不会执行回调；
* `:restrict_with_exception`：有关联的对象时抛出异常；
* `:restrict_with_error`：有关联的对象时，向拥有者添加一个错误；

NOTE: 如果声明关联时指定了 `:through` 选项，会忽略这个选项。

##### `:foreign_key`

按照约定，另一个模型中用来存储外键的字段名是模型名后加 `_id`。`:foreign_key` 选项可以设置要使用的外键名：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, foreign_key: "cust_id"
end
```

TIP: 不管怎样，Rails 都不会自动创建外键字段，你要自己在迁移中创建。

##### `:inverse_of`

`:inverse_of` 选项指定 `has_many` 关联另一端的 `belongs_to` 关联名。不能和 `:through` 或 `:as` 选项一起使用。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, inverse_of: :customer
end

class Order < ActiveRecord::Base
  belongs_to :customer, inverse_of: :orders
end
```

##### `:primary_key`

按照约定，用来存储该模型主键的字段名 `id`。`:primary_key` 选项可以设置要使用的主键名。

假设 `users` 表的主键是 `id`，但还有一个 `guid` 字段。根据要求，`todos` 表中应该使用 `guid` 字段，而不是 `id` 字段。这种需求可以这么实现：

```ruby
class User < ActiveRecord::Base
  has_many :todos, primary_key: :guid
end
```

如果执行 `@user.todos.create` 创建新的待办事项，那么 `@todo.user_id` 就是 `guid` 字段中的值。

##### `:source`

`:source` 选项指定 `has_many :through` 关联的关联源名字。只有无法从关联名种解出关联源的名字时才需要设置这个选项。

##### `:source_type`

`:source_type` 选项指定 `has_many :through` 关联中用来处理多态关联的关联源类型。

##### `:through`

`:through` 选项指定用来执行查询的连接模型。`has_many :through` 关联是实现多对多关联的一种方式，[前文](#the-has-many-through-association)已经介绍过。

##### `:validate`

如果把 `:validate` 选项设为 `false`，保存对象时，不会验证关联对象。该选项的默认值是 `true`，保存对象验证关联的对象。

#### `has_many` 的作用域

有时可能需要定制 `has_many` 关联使用的查询方式，定制的查询可在作用域代码块中指定。例如：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, -> { where processed: true }
end
```

在作用域代码块中可以使用任何一个标准的[查询方法](active_record_querying.html)。下面分别介绍这几个方法：

* `where`
* `extending`
* `group`
* `includes`
* `limit`
* `offset`
* `order`
* `readonly`
* `select`
* `uniq`

##### `where`

`where` 方法指定关联对象必须满足的条件。

```ruby
class Customer < ActiveRecord::Base
  has_many :confirmed_orders, -> { where "confirmed = 1" },
    class_name: "Order"
end
```

条件还可以使用 Hash 的形式指定：

```ruby
class Customer < ActiveRecord::Base
  has_many :confirmed_orders, -> { where confirmed: true },
                              class_name: "Order"
end
```

如果 `where` 使用 Hash 形式，通过这个关联创建的记录会自动使用 Hash 中的作用域。针对上面的例子，使用 `@customer.confirmed_orders.create` 或 `@customer.confirmed_orders.build` 创建订单时，会自动把 `confirmed` 字段的值设为 `true`。

##### `extending`

`extending` 方法指定一个模块名，用来扩展关联代理。[后文](#association-extensions)会详细介绍关联扩展。

##### `group`

`group` 方法指定一个属性名，用在 SQL `GROUP BY` 子句中，分组查询结果。

```ruby
class Customer < ActiveRecord::Base
  has_many :line_items, -> { group 'orders.id' },
                        through: :orders
end
```

##### `includes`

`includes` 方法指定使用关联时要按需加载的间接关联。例如，有如下的模型：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :line_items
end

class LineItem < ActiveRecord::Base
  belongs_to :order
end
```

如果经常要直接获取顾客购买的商品（`@customer.orders.line_items`），就可以把商品引入顾客和订单的关联中：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, -> { includes :line_items }
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :line_items
end

class LineItem < ActiveRecord::Base
  belongs_to :order
end
```

##### `limit`

`limit` 方法限制通过关联获取的对象数量。

```ruby
class Customer < ActiveRecord::Base
  has_many :recent_orders,
    -> { order('order_date desc').limit(100) },
    class_name: "Order",
end
```

##### `offset`

`offset` 方法指定通过关联获取对象时的偏移量。例如，`-> { offset(11) }` 会跳过前 11 个记录。

##### `order`

`order` 方法指定获取关联对象时使用的排序方式，用于 SQL `ORDER BY` 子句。

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, -> { order "date_confirmed DESC" }
end
```

##### `readonly`

如果使用 `readonly`，通过关联获取的对象就是只读的。

##### `select`

`select` 方法用来覆盖获取关联对象数据的 SQL `SELECT` 子句。默认情况下，Rails 会读取所有字段。

WARNING: 如果设置了 `select`，记得要包含主键和关联模型的外键。否则，Rails 会抛出异常。

##### `distinct`

使用 `distinct` 方法可以确保集合中没有重复的对象，和 `:through` 选项一起使用最有用。

```ruby
class Person < ActiveRecord::Base
  has_many :readings
  has_many :posts, through: :readings
end

person = Person.create(name: 'John')
post   = Post.create(name: 'a1')
person.posts << post
person.posts << post
person.posts.inspect # => [#<Post id: 5, name: "a1">, #<Post id: 5, name: "a1">]
Reading.all.inspect  # => [#<Reading id: 12, person_id: 5, post_id: 5>, #<Reading id: 13, person_id: 5, post_id: 5>]
```

在上面的代码中，读者读了两篇文章，即使是同一篇文章，`person.posts` 也会返回两个对象。

下面我们加入 `distinct` 方法：

```ruby
class Person
  has_many :readings
  has_many :posts, -> { distinct }, through: :readings
end

person = Person.create(name: 'Honda')
post   = Post.create(name: 'a1')
person.posts << post
person.posts << post
person.posts.inspect # => [#<Post id: 7, name: "a1">]
Reading.all.inspect  # => [#<Reading id: 16, person_id: 7, post_id: 7>, #<Reading id: 17, person_id: 7, post_id: 7>]
```

在这段代码中，读者还是读了两篇文章，但 `person.posts` 只返回一个对象，因为加载的集合已经去除了重复元素。

如果要确保只把不重复的记录写入关联模型的数据表（这样就不会从数据库中获取重复记录了），需要在数据表上添加唯一性索引。例如，数据表名为 `person_posts`，我们要保证其中所有的文章都没重复，可以在迁移中加入以下代码：

```ruby
add_index :person_posts, :post, unique: true
```

注意，使用 `include?` 等方法检查唯一性可能导致条件竞争。不要使用 `include?` 确保关联的唯一性。还是以前面的文章模型为例，下面的代码会导致条件竞争，因为多个用户可能会同时执行这一操作：

```ruby
person.posts << post unless person.posts.include?(post)
```

#### 什么时候保存对象

把对象赋值给 `has_many` 关联时，会自动保存对象（因为要更新外键）。如果一次赋值多个对象，所有对象都会自动保存。

如果无法通过验证，随便哪一次保存失败了，赋值语句就会返回 `false`，赋值操作会取消。

如果父对象（`has_many` 关联声明所在的模型）没保存（`new_record?` 方法返回 `true`），那么子对象也不会保存。只有保存了父对象，才会保存子对象。

如果赋值给 `has_many` 关联时不想保存对象，可以使用 `collection.build` 方法。

### `has_and_belongs_to_many` 关联详解

`has_and_belongs_to_many` 关联建立两个模型之间的多对多关系。用数据库的行话说，这种关联的意思是有个连接数据表包含指向这两个类的外键。

#### `has_and_belongs_to_many` 关联添加的方法

声明 `has_and_belongs_to_many` 关联后，声明所在的类自动获得了 16 个关联相关的方法：

* `collection(force_reload = false)`
* `collection<<(object, ...)`
* `collection.delete(object, ...)`
* `collection.destroy(object, ...)`
* `collection=objects`
* `collection_singular_ids`
* `collection_singular_ids=ids`
* `collection.clear`
* `collection.empty?`
* `collection.size`
* `collection.find(...)`
* `collection.where(...)`
* `collection.exists?(...)`
* `collection.build(attributes = {})`
* `collection.create(attributes = {})`
* `collection.create!(attributes = {})`

这些个方法中的 `collection` 要替换成传入 `has_and_belongs_to_many` 方法的第一个参数。`collection_singular` 要替换成第一个参数的单数形式。例如，如下的声明：

```ruby
class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

每个 `Part` 模型实例都获得了这些方法：

```ruby
assemblies(force_reload = false)
assemblies<<(object, ...)
assemblies.delete(object, ...)
assemblies.destroy(object, ...)
assemblies=objects
assembly_ids
assembly_ids=ids
assemblies.clear
assemblies.empty?
assemblies.size
assemblies.find(...)
assemblies.where(...)
assemblies.exists?(...)
assemblies.build(attributes = {}, ...)
assemblies.create(attributes = {})
assemblies.create!(attributes = {})
```

##### 额外的字段方法

如果 `has_and_belongs_to_many` 关联使用的连接数据表中，除了两个外键之外还有其他字段，通过关联获取的记录中会包含这些字段，但是只读字段，因为 Rails 不知道如何保存对这些字段的改动。

WARNING: 在 `has_and_belongs_to_many` 关联的连接数据表中使用其他字段的功能已经废弃。如果在多对多关联中需要使用这么复杂的数据表，可以用 `has_many :through` 关联代替 `has_and_belongs_to_many` 关联。

##### `collection(force_reload = false)`

`collection` 方法返回一个数组，包含所有关联的对象。如果没有关联的对象，则返回空数组。

```ruby
@assemblies = @part.assemblies
```

##### `collection<<(object, ...)`

`collection<<` 方法向关联对象数组中添加一个或多个对象，并在连接数据表中创建相应的记录。

```ruby
@part.assemblies << @assembly1
```

NOTE: 这个方法与 `collection.concat` 和 `collection.push` 是同名方法。

##### `collection.delete(object, ...)`

`collection.delete` 方法从关联对象数组中删除一个或多个对象，并删除连接数据表中相应的记录。

```ruby
@part.assemblies.delete(@assembly1)
```

WARNING: 这个方法不会触发连接记录上的回调。

##### `collection.destroy(object, ...)`

`collection.destroy` 方法在连接数据表中的记录上调用 `destroy` 方法，从关联对象数组中删除一个或多个对象，还会触发回调。这个方法不会销毁对象本身。

```ruby
@part.assemblies.destroy(@assembly1)
```

##### `collection=objects`

`collection=` 让关联对象数组只包含指定的对象，根据需求会添加或删除对象。

##### `collection_singular_ids`

`collection_singular_ids` 返回一个数组，包含关联对象数组中各对象的 ID。

```ruby
@assembly_ids = @part.assembly_ids
```

##### `collection_singular_ids=ids`

`collection_singular_ids=` 方法让数组中只包含指定的主键，根据需要增删 ID。

##### `collection.clear`

`collection.clear` 方法删除数组中的所有对象，并把连接数据表中的相应记录删除。这个方法不会销毁关联对象。

##### `collection.empty?`

如果关联数组中没有关联对象，`collection.empty?` 方法返回 `true`。

```ruby
<% if @part.assemblies.empty? %>
  This part is not used in any assemblies
<% end %>
```

##### `collection.size`

`collection.size` 返回关联对象数组中的对象数量。

```ruby
@assembly_count = @part.assemblies.size
```

##### `collection.find(...)`

`collection.find` 方法在关联对象数组中查找对象，句法和可用选项跟 `ActiveRecord::Base.find` 方法一样。同时还限制对象必须在集合中。

```ruby
@assembly = @part.assemblies.find(1)
```

##### `collection.where(...)`

`collection.where` 方法根据指定的条件在关联对象数组中查找对象，但会惰性加载对象，用到对象时才会执行查询。同时还限制对象必须在集合中。

```ruby
@new_assemblies = @part.assemblies.where("created_at > ?", 2.days.ago)
```

##### `collection.exists?(...)`

`collection.exists?` 方法根据指定的条件检查关联对象数组中是否有符合条件的对象，句法和可用选项跟 `ActiveRecord::Base.exists?` 方法一样。

##### `collection.build(attributes = {})`

`collection.build` 方法返回一个此种关联类型的新对象。这个对象会使用传入的属性初始化，还会在连接数据表中创建对应的记录，但不会保存关联对象。

```ruby
@assembly = @part.assemblies.build({assembly_name: "Transmission housing"})
```

##### `collection.create(attributes = {})`

`collection.create` 方法返回一个此种关联类型的新对象。这个对象会使用传入的属性初始化，还会在连接数据表中创建对应的记录，只要能通过所有数据验证，就会保存关联对象。

```ruby
@assembly = @part.assemblies.create({assembly_name: "Transmission housing"})
```

##### `collection.create!(attributes = {})`

作用和 `collection.create` 相同，但如果记录不合法会抛出 `ActiveRecord::RecordInvalid` 异常。

#### `has_and_belongs_to_many` 方法的选项

Rails 的默认设置足够智能，能满足常见需求。但有时还是需要定制 `has_and_belongs_to_many` 关联的行为。定制的方法很简单，声明关联时传入选项即可。例如，下面的关联使用了两个选项：

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies, autosave: true,
                                       readonly: true
end
```

`has_and_belongs_to_many` 关联支持以下选项：

* `:association_foreign_key`
* `:autosave`
* `:class_name`
* `:foreign_key`
* `:join_table`
* `:validate`
* `:readonly`

##### `:association_foreign_key`

按照约定，在连接数据表中用来指向另一个模型的外键名是模型名后加 `_id`。`:association_foreign_key` 选项可以设置要使用的外键名：

TIP: `:foreign_key` 和 `:association_foreign_key` 这两个选项在设置多对多自连接时很有用。

```ruby
class User < ActiveRecord::Base
  has_and_belongs_to_many :friends,
      class_name: "User",
      foreign_key: "this_user_id",
      association_foreign_key: "other_user_id"
end
```

##### `:autosave`

如果把 `:autosave` 选项设为 `true`，保存父对象时，会自动保存所有子对象，并把标记为析构的子对象销毁。

##### `:class_name`

如果另一个模型无法从关联的名字获取，可以使用 `:class_name` 选项指定模型名。例如，一个部件由多个装配件组成，但表示装配件的模型是 `Gadget`，就可以这样声明关联：

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies, class_name: "Gadget"
end
```

##### `:foreign_key`

按照约定，在连接数据表中用来指向模型的外键名是模型名后加 `_id`。`:foreign_key` 选项可以设置要使用的外键名：

```ruby
class User < ActiveRecord::Base
  has_and_belongs_to_many :friends,
      class_name: "User",
      foreign_key: "this_user_id",
      association_foreign_key: "other_user_id"
end
```

##### `:join_table`

如果默认按照字典顺序生成的默认名不能满足要求，可以使用 `:join_table` 选项指定。

##### `:validate`

如果把 `:validate` 选项设为 `false`，保存对象时，不会验证关联对象。该选项的默认值是 `true`，保存对象验证关联的对象。

#### `has_and_belongs_to_many` 的作用域

有时可能需要定制 `has_and_belongs_to_many` 关联使用的查询方式，定制的查询可在作用域代码块中指定。例如：

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies, -> { where active: true }
end
```

在作用域代码块中可以使用任何一个标准的[查询方法](active_record_querying.html)。下面分别介绍这几个方法：

* `where`
* `extending`
* `group`
* `includes`
* `limit`
* `offset`
* `order`
* `readonly`
* `select`
* `uniq`

##### `where`

`where` 方法指定关联对象必须满足的条件。

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies,
    -> { where "factory = 'Seattle'" }
end
```

条件还可以使用 Hash 的形式指定：

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies,
    -> { where factory: 'Seattle' }
end
```

如果 `where` 使用 Hash 形式，通过这个关联创建的记录会自动使用 Hash 中的作用域。针对上面的例子，使用 `@parts.assemblies.create` 或 `@parts.assemblies.build` 创建订单时，会自动把 `factory` 字段的值设为 `"Seattle"`。

##### `extending`

`extending` 方法指定一个模块名，用来扩展关联代理。[后文](#association-extensions)会详细介绍关联扩展。

##### `group`

`group` 方法指定一个属性名，用在 SQL `GROUP BY` 子句中，分组查询结果。

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies, -> { group "factory" }
end
```

##### `includes`

`includes` 方法指定使用关联时要按需加载的间接关联。

##### `limit`

`limit` 方法限制通过关联获取的对象数量。

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies,
    -> { order("created_at DESC").limit(50) }
end
```

##### `offset`

`offset` 方法指定通过关联获取对象时的偏移量。例如，`-> { offset(11) }` 会跳过前 11 个记录。

##### `order`

`order` 方法指定获取关联对象时使用的排序方式，用于 SQL `ORDER BY` 子句。

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies,
    -> { order "assembly_name ASC" }
end
```

##### `readonly`

如果使用 `readonly`，通过关联获取的对象就是只读的。

##### `select`

`select` 方法用来覆盖获取关联对象数据的 SQL `SELECT` 子句。默认情况下，Rails 会读取所有字段。

##### `uniq`

`uniq` 方法用来删除集合中重复的对象。

#### 什么时候保存对象

把对象赋值给 `has_and_belongs_to_many` 关联时，会自动保存对象（因为要更新外键）。如果一次赋值多个对象，所有对象都会自动保存。

如果无法通过验证，随便哪一次保存失败了，赋值语句就会返回 `false`，赋值操作会取消。

如果父对象（`has_and_belongs_to_many` 关联声明所在的模型）没保存（`new_record?` 方法返回 `true`），那么子对象也不会保存。只有保存了父对象，才会保存子对象。

如果赋值给 `has_and_belongs_to_many` 关联时不想保存对象，可以使用 `collection.build` 方法。

### 关联回调

普通回调会介入 Active Record 对象的生命周期，在很多时刻处理对象。例如，可以使用 `:before_save` 回调在保存对象之前处理对象。

关联回调和普通回调差不多，只不过由集合生命周期中的事件触发。关联回调有四种：

* `before_add`
* `after_add`
* `before_remove`
* `after_remove`

关联回调在声明关联时定义。例如：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, before_add: :check_credit_limit

  def check_credit_limit(order)
    ...
  end
end
```

Rails 会把添加或删除的对象传入回调。

同一事件可触发多个回调，多个回调使用数组指定：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders,
    before_add: [:check_credit_limit, :calculate_shipping_charges]

  def check_credit_limit(order)
    ...
  end

  def calculate_shipping_charges(order)
    ...
  end
end
```

如果 `before_add` 回调抛出异常，不会把对象加入集合。类似地，如果 `before_remove` 抛出异常，对象不会从集合中删除。

### 关联扩展

Rails 基于关联代理对象自动创建的功能是死的，但是可以通过匿名模块、新的查询方法、创建对象的方法等进行扩展。例如：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders do
    def find_by_order_prefix(order_number)
      find_by(region_id: order_number[0..2])
    end
  end
end
```

如果扩展要在多个关联中使用，可以将其写入具名扩展模块。例如：

```ruby
module FindRecentExtension
  def find_recent
    where("created_at > ?", 5.days.ago)
  end
end

class Customer < ActiveRecord::Base
  has_many :orders, -> { extending FindRecentExtension }
end

class Supplier < ActiveRecord::Base
  has_many :deliveries, -> { extending FindRecentExtension }
end
```

在扩展中可以使用如下 `proxy_association` 方法的三个属性获取关联代理的内部信息：

* `proxy_association.owner`：返回关联所属的对象；
* `proxy_association.reflection`：返回描述关联的反射对象；
* `proxy_association.target`：返回 `belongs_to` 或 `has_one` 关联的关联对象，或者 `has_many` 或 `has_and_belongs_to_many` 关联的关联对象集合；
