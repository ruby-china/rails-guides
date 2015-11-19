Active Record 数据验证
=====================

本文介绍如何使用 Active Record 提供的数据验证功能在数据存入数据库之前验证对象的状态。

读完本文，你将学到：

* 如何使用 Active Record 内建的数据验证帮助方法；
* 如何编写自定义的数据验证方法；
* 如何处理验证时产生的错误消息；

--------------------------------------------------------------------------------

数据验证简介
----------

下面演示一个非常简单的数据验证：

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

Person.create(name: "John Doe").valid? # => true
Person.create(name: nil).valid? # => false
```

如上所示，如果 `Person`的 `name` 属性值为空，验证就会将其视为不合法对象。创建的第二个 `Person` 对象不会存入数据库。

在深入探讨之前，我们先来介绍数据验证在整个程序中的作用。

### 为什么要做数据验证？

数据验证能确保只有合法的数据才会存入数据库。例如，程序可能需要用户提供一个合法的 Email 地址和邮寄地址。在模型中做验证是最有保障的，只有通过验证的数据才能存入数据库。数据验证和使用的数据库种类无关，终端用户也无法跳过，而且容易测试和维护。在 Rails 中做数据验证很简单，Rails 内置了很多帮助方法，能满足常规的需求，而且还可以编写自定义的验证方法。

数据存入数据库之前的验证方法还有其他几种，包括数据库内建的约束，客户端验证和控制器层验证。下面列出了这几种验证方法的优缺点：

* 数据库约束和“存储过程”无法兼容多种数据库，而且测试和维护较为困难。不过，如果其他程序也要使用这个数据库，最好在数据库层做些约束。数据库层的某些验证（例如在使用量很高的数据表中做唯一性验证）通过其他方式实现起来有点困难。
* 客户端验证很有用，但单独使用时可靠性不高。如果使用 JavaScript 实现，用户在浏览器中禁用 JavaScript 后很容易跳过验证。客户端验证和其他验证方式结合使用，可以为用户提供实时反馈。
* 控制器层验证很诱人，但一般都不灵便，难以测试和维护。只要可能，就要保证控制器的代码简洁性，这样才有利于长远发展。

你可以根据实际的需求选择使用哪种验证方式。Rails 团队认为，模型层数据验证最具普适性。

### 什么时候做数据验证？

在 Active Record 中对象有两种状态：一种在数据库中有对应的记录，一种没有。新建的对象（例如，使用 `new` 方法）还不属于数据库。在对象上调用 `save` 方法后，才会把对象存入相应的数据表。Active Record 使用实例方法 `new_record?` 判断对象是否已经存入数据库。假如有下面这个简单的 Active Record 类：

```ruby
class Person < ActiveRecord::Base
end
```

我们可以在 `rails console` 中看一下到底怎么回事：

```ruby
$ rails console
>> p = Person.new(name: "John Doe")
=> #<Person id: nil, name: "John Doe", created_at: nil, updated_at: nil>
>> p.new_record?
=> true
>> p.save
=> true
>> p.new_record?
=> false
```

新建并保存记录会在数据库中执行 SQL `INSERT` 操作。更新现有的记录会在数据库上执行 SQL `UPDATE` 操作。一般情况下，数据验证发生在这些 SQL 操作执行之前。如果验证失败，对象会被标记为不合法，Active Record 不会向数据库发送 `INSERT` 或 `UPDATE` 指令。这样就可以避免把不合法的数据存入数据库。你可以选择在对象创建、保存或更新时执行哪些数据验证。

WARNING: 修改数据库中对象的状态有很多方法。有些方法会做数据验证，有些则不会。所以，如果不小心处理，还是有可能把不合法的数据存入数据库。

下列方法会做数据验证，如果验证失败就不会把对象存入数据库：

* `create`
* `create!`
* `save`
* `save!`
* `update`
* `update!`

爆炸方法（例如 `save!`）会在验证失败后抛出异常。验证失败后，非爆炸方法不会抛出异常，`save` 和 `update` 返回 `false`，`create` 返回对象本身。

### 跳过验证

下列方法会跳过验证，不管验证是否通过都会把对象存入数据库，使用时要特别留意。

* `decrement!`
* `decrement_counter`
* `increment!`
* `increment_counter`
* `toggle!`
* `touch`
* `update_all`
* `update_attribute`
* `update_column`
* `update_columns`
* `update_counters`

注意，使用 `save` 时如果传入 `validate: false`，也会跳过验证。使用时要特别留意。

* `save(validate: false)`

### `valid?` 和 `invalid?`

Rails 使用 `valid?` 方法检查对象是否合法。`valid?` 方法会触发数据验证，如果对象上没有错误，就返回 `true`，否则返回 `false`。前面我们已经用过了：

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

Person.create(name: "John Doe").valid? # => true
Person.create(name: nil).valid? # => false
```

Active Record 验证结束后，所有发现的错误都可以通过实例方法 `errors.messages` 获取，该方法返回一个错误集合。如果数据验证后，这个集合为空，则说明对象是合法的。

注意，使用 `new` 方法初始化对象时，即使不合法也不会报错，因为这时还没做数据验证。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

>> p = Person.new
# => #<Person id: nil, name: nil>
>> p.errors.messages
# => {}

>> p.valid?
# => false
>> p.errors.messages
# => {name:["can't be blank"]}

>> p = Person.create
# => #<Person id: nil, name: nil>
>> p.errors.messages
# => {name:["can't be blank"]}

>> p.save
# => false

>> p.save!
# => ActiveRecord::RecordInvalid: Validation failed: Name can't be blank

>> Person.create!
# => ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

`invalid?` 是 `valid?` 的逆测试，会触发数据验证，如果找到错误就返回 `true`，否则返回 `false`。

### `errors[]`

要检查对象的某个属性是否合法，可以使用 `errors[:attribute]`。`errors[:attribute]` 中包含 `:attribute` 的所有错误。如果某个属性没有错误，就会返回空数组。

这个方法只在数据验证之后才能使用，因为它只是用来收集错误信息的，并不会触发验证。而且，和前面介绍的 `ActiveRecord::Base#invalid?` 方法不一样，因为 `errors[:attribute]` 不会验证整个对象，只检查对象的某个属性是否出错。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

>> Person.new.errors[:name].any? # => false
>> Person.create.errors[:name].any? # => true
```

我们会在“[处理验证错误](#working-with-validation-errors)”一节详细介绍验证错误。现在，我们来看一下 Rails 默认提供的数据验证帮助方法。

数据验证帮助方法
--------------

Active Record 预先定义了很多数据验证帮助方法，可以直接在模型类定义中使用。这些帮助方法提供了常用的验证规则。每次验证失败后，都会向对象的 `errors` 集合中添加一个消息，这些消息和所验证的属性是关联的。

每个帮助方法都可以接受任意数量的属性名，所以一行代码就能在多个属性上做同一种验证。

所有的帮助方法都可指定 `:on` 和 `:message` 选项，指定何时做验证，以及验证失败后向 `errors` 集合添加什么消息。`:on` 选项的可选值是 `:create` 和 `:update`。每个帮助函数都有默认的错误消息，如果没有通过 `:message` 选项指定，则使用默认值。下面分别介绍各帮助方法。

### `acceptance`

这个方法检查表单提交时，用户界面中的复选框是否被选中。这个功能一般用来要求用户接受程序的服务条款，阅读一些文字，等等。这种验证只针对网页程序，不会存入数据库（如果没有对应的字段，该方法会创建一个虚拟属性）。

```ruby
class Person < ActiveRecord::Base
  validates :terms_of_service, acceptance: true
end
```

这个帮助方法的默认错误消息是“must be accepted”。

这个方法可以指定 `:accept` 选项，决定可接受什么值。默认为“1”，很容易修改：

```ruby
class Person < ActiveRecord::Base
  validates :terms_of_service, acceptance: { accept: 'yes' }
end
```

### `validates_associated`

如果模型和其他模型有关联，也要验证关联的模型对象，可以使用这个方法。保存对象时，会在相关联的每个对象上调用 `valid?` 方法。

```ruby
class Library < ActiveRecord::Base
  has_many :books
  validates_associated :books
end
```

这个帮助方法可用于所有关联类型。

WARNING: 不要在关联的两端都使用 `validates_associated`，这样会生成一个循环。

`validates_associated` 的默认错误消息是“is invalid”。注意，相关联的每个对象都有各自的 `errors` 集合，错误消息不会都集中在调用该方法的模型对象上。

### `confirmation`

如果要检查两个文本字段的值是否完全相同，可以使用这个帮助方法。例如，确认 Email 地址或密码。这个帮助方法会创建一个虚拟属性，其名字为要验证的属性名后加 `_confirmation`。

```ruby
class Person < ActiveRecord::Base
  validates :email, confirmation: true
end
```

在视图中可以这么写：

```erb
<%= text_field :person, :email %>
<%= text_field :person, :email_confirmation %>
```

只有 `email_confirmation` 的值不是 `nil` 时才会做这个验证。所以要为确认属性加上存在性验证（后文会介绍 `presence` 验证）。

```ruby
class Person < ActiveRecord::Base
  validates :email, confirmation: true
  validates :email_confirmation, presence: true
end
```

这个帮助方法的默认错误消息是“doesn't match confirmation”。

### `exclusion`

这个帮助方法检查属性的值是否不在指定的集合中。集合可以是任何一种可枚举的对象。

```ruby
class Account < ActiveRecord::Base
  validates :subdomain, exclusion: { in: %w(www us ca jp),
    message: "%{value} is reserved." }
end
```

`exclusion` 方法要指定 `:in` 选项，设置哪些值不能作为属性的值。`:in` 选项有个别名 `:with`，作用相同。上面的例子设置了 `:message` 选项，演示如何获取属性的值。

默认的错误消息是“is reserved”。

### `format`

这个帮助方法检查属性的值是否匹配 `:with` 选项指定的正则表达式。

```ruby
class Product < ActiveRecord::Base
  validates :legacy_code, format: { with: /\A[a-zA-Z]+\z/,
    message: "only allows letters" }
end
```

默认的错误消息是“is invalid”。

### `inclusion`

这个帮助方法检查属性的值是否在指定的集合中。集合可以是任何一种可枚举的对象。

```ruby
class Coffee < ActiveRecord::Base
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value} is not a valid size" }
end
```

`inclusion` 方法要指定 `:in` 选项，设置可接受哪些值。`:in` 选项有个别名 `:within`，作用相同。上面的例子设置了 `:message` 选项，演示如何获取属性的值。

该方法的默认错误消息是“is not included in the list”。

### `length`

这个帮助方法验证属性值的长度，有多个选项，可以使用不同的方法指定长度限制：

```ruby
class Person < ActiveRecord::Base
  validates :name, length: { minimum: 2 }
  validates :bio, length: { maximum: 500 }
  validates :password, length: { in: 6..20 }
  validates :registration_number, length: { is: 6 }
end
```

可用的长度限制选项有：

* `:minimum`：属性的值不能比指定的长度短；
* `:maximum`：属性的值不能比指定的长度长；
* `:in`（或 `:within`）：属性值的长度在指定值之间。该选项的值必须是一个范围；
* `:is`：属性值的长度必须等于指定值；

默认的错误消息根据长度验证类型而有所不同，还是可以 `:message` 定制。定制消息时，可以使用 `:wrong_length`、`:too_long` 和 `:too_short` 选项，`%{count}` 表示长度限制的值。

```ruby
class Person < ActiveRecord::Base
  validates :bio, length: { maximum: 1000,
    too_long: "%{count} characters is the maximum allowed" }
end
```

这个帮助方法默认统计字符数，但可以使用 `:tokenizer` 选项设置其他的统计方式：

```ruby
class Essay < ActiveRecord::Base
  validates :content, length: {
    minimum: 300,
    maximum: 400,
    tokenizer: lambda { |str| str.scan(/\w+/) },
    too_short: "must have at least %{count} words",
    too_long: "must have at most %{count} words"
  }
end
```

注意，默认的错误消息使用复数形式（例如，“is too short (minimum is %{count} characters”），所以如果长度限制是 `minimum: 1`，就要提供一个定制的消息，或者使用 `presence: true` 代替。`:in` 或 `:within` 的值比 1 小时，都要提供一个定制的消息，或者在 `length` 之前，调用 `presence` 方法。

### `numericality`

这个帮助方法检查属性的值是否值包含数字。默认情况下，匹配的值是可选的正负符号后加整数或浮点数。如果只接受整数，可以把 `:only_integer` 选项设为 `true`。

如果 `:only_integer` 为 `true`，则使用下面的正则表达式验证属性的值。

```ruby
/\A[+-]?\d+\Z/
```

否则，会尝试使用 `Float` 把值转换成数字。

WARNING: 注意上面的正则表达式允许最后出现换行符。

```ruby
class Player < ActiveRecord::Base
  validates :points, numericality: true
  validates :games_played, numericality: { only_integer: true }
end
```

除了 `:only_integer` 之外，这个方法还可指定以下选项，限制可接受的值：

* `:greater_than`：属性值必须比指定的值大。该选项默认的错误消息是“must be greater than %{count}”；
* `:greater_than_or_equal_to`：属性值必须大于或等于指定的值。该选项默认的错误消息是“must be greater than or equal to %{count}”；
* `:equal_to`：属性值必须等于指定的值。该选项默认的错误消息是“must be equal to %{count}”；
* `:less_than`：属性值必须比指定的值小。该选项默认的错误消息是“must be less than %{count}”；
* `:less_than_or_equal_to`：属性值必须小于或等于指定的值。该选项默认的错误消息是“must be less than or equal to %{count}”；
* `:odd`：如果设为 `true`，属性值必须是奇数。该选项默认的错误消息是“must be odd”；
* `:even`：如果设为 `true`，属性值必须是偶数。该选项默认的错误消息是“must be even”；

默认的错误消息是“is not a number”。

### `presence`

这个帮助方法检查指定的属性是否为非空值，调用 `blank?` 方法检查值是否为 `nil` 或空字符串，即空字符串或只包含空白的字符串。

```ruby
class Person < ActiveRecord::Base
  validates :name, :login, :email, presence: true
end
```

如果要确保关联对象存在，需要测试关联的对象本身是够存在，而不是用来映射关联的外键。

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order
  validates :order, presence: true
end
```

为了能验证关联的对象是否存在，要在关联中指定 `:inverse_of` 选项。

```ruby
class Order < ActiveRecord::Base
  has_many :line_items, inverse_of: :order
end
```

如果验证 `has_one` 或 `has_many` 关联的对象是否存在，会在关联的对象上调用 `blank?` 和 `marked_for_destruction?` 方法。

因为 `false.blank?` 的返回值是 `true`，所以如果要验证布尔值字段是否存在要使用 `validates :field_name, inclusion: { in: [true, false] }`。

默认的错误消息是“can't be blank”。

### `absence`

这个方法验证指定的属性值是否为空，使用 `present?` 方法检测值是否为 `nil` 或空字符串，即空字符串或只包含空白的字符串。

```ruby
class Person < ActiveRecord::Base
  validates :name, :login, :email, absence: true
end
```

如果要确保关联对象为空，需要测试关联的对象本身是够为空，而不是用来映射关联的外键。

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order
  validates :order, absence: true
end
```

为了能验证关联的对象是否为空，要在关联中指定 `:inverse_of` 选项。

```ruby
class Order < ActiveRecord::Base
  has_many :line_items, inverse_of: :order
end
```

如果验证 `has_one` 或 `has_many` 关联的对象是否为空，会在关联的对象上调用 `present?` 和 `marked_for_destruction?` 方法。

因为 `false.present?` 的返回值是 `false`，所以如果要验证布尔值字段是否为空要使用 `validates :field_name, exclusion: { in: [true, false] }`。

默认的错误消息是“must be blank”。

### `uniqueness`

这个帮助方法会在保存对象之前验证属性值是否是唯一的。该方法不会在数据库中创建唯一性约束，所以有可能两个数据库连接创建的记录字段的值是相同的。为了避免出现这种问题，要在数据库的字段上建立唯一性索引。关于多字段索引的详细介绍，参阅 [MySQL 手册](http://dev.mysql.com/doc/refman/5.6/en/multiple-column-indexes.html)。

```ruby
class Account < ActiveRecord::Base
  validates :email, uniqueness: true
end
```

这个验证会在模型对应的数据表中执行一个 SQL 查询，检查现有的记录中该字段是否已经出现过相同的值。

`:scope` 选项可以指定其他属性，用来约束唯一性验证：

```ruby
class Holiday < ActiveRecord::Base
  validates :name, uniqueness: { scope: :year,
    message: "should happen once per year" }
end
```

还有个 `:case_sensitive` 选项，指定唯一性验证是否要区分大小写，默认值为 `true`。

```ruby
class Person < ActiveRecord::Base
  validates :name, uniqueness: { case_sensitive: false }
end
```

WARNING: 注意，有些数据库的设置是，查询时不区分大小写。

默认的错误消息是“has already been taken”。

### `validates_with`

这个帮助方法把记录交给其他的类做验证。

```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if record.first_name == "Evil"
      record.errors[:base] << "This person is evil"
    end
  end
end

class Person < ActiveRecord::Base
  validates_with GoodnessValidator
end
```

NOTE: `record.errors[:base]` 中的错误针对整个对象，而不是特定的属性。

`validates_with` 方法的参数是一个类，或一组类，用来做验证。`validates_with` 方法没有默认的错误消息。在做验证的类中要手动把错误添加到记录的错误集合中。

实现 `validate` 方法时，必须指定 `record` 参数，这是要做验证的记录。

和其他验证一样，`validates_with` 也可指定 `:if`、`:unless` 和 `:on` 选项。如果指定了其他选项，会包含在 `options` 中传递给做验证的类。

```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if options[:fields].any?{|field| record.send(field) == "Evil" }
      record.errors[:base] << "This person is evil"
    end
  end
end

class Person < ActiveRecord::Base
  validates_with GoodnessValidator, fields: [:first_name, :last_name]
end
```

注意，做验证的类在整个程序的生命周期内只会初始化一次，而不是每次验证时都初始化，所以使用实例变量时要特别小心。

如果做验证的类很复杂，必须要用实例变量，可以用纯粹的 Ruby 对象代替：

```ruby
class Person < ActiveRecord::Base
  validate do |person|
    GoodnessValidator.new(person).validate
  end
end

class GoodnessValidator
  def initialize(person)
    @person = person
  end

  def validate
    if some_complex_condition_involving_ivars_and_private_methods?
      @person.errors[:base] << "This person is evil"
    end
  end

  # ...
end
```

### `validates_each`

这个帮助方法会把属性值传入代码库做验证，没有预先定义验证的方式，你应该在代码库中定义验证方式。要验证的每个属性都会传入块中做验证。在下面的例子中，我们确保名和姓都不能以小写字母开头：

```ruby
class Person < ActiveRecord::Base
  validates_each :name, :surname do |record, attr, value|
    record.errors.add(attr, 'must start with upper case') if value =~ /\A[a-z]/
  end
end
```

代码块的参数是记录，属性名和属性值。在代码块中可以做任何检查，确保数据合法。如果验证失败，要向模型添加一个错误消息，把数据标记为不合法。

常用的验证选项
-------------

常用的验证选项包括：

### `:allow_nil`

指定 `:allow_nil` 选项后，如果要验证的值为 `nil` 就会跳过验证。

```ruby
class Coffee < ActiveRecord::Base
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value} is not a valid size" }, allow_nil: true
end
```

### `:allow_blank`

`:allow_blank` 选项和 `:allow_nil` 选项类似。如果要验证的值为空（调用 `blank?` 方法，例如 `nil` 或空字符串），就会跳过验证。

```ruby
class Topic < ActiveRecord::Base
  validates :title, length: { is: 5 }, allow_blank: true
end

Topic.create(title: "").valid?  # => true
Topic.create(title: nil).valid? # => true
```

### `:message`

前面已经介绍过，如果验证失败，会把 `:message` 选项指定的字符串添加到 `errors` 集合中。如果没指定这个选项，Active Record 会使用各种验证帮助方法的默认错误消息。

### `:on`

`:on` 选项指定什么时候做验证。所有内建的验证帮助方法默认都在保存时（新建记录或更新记录）做验证。如果想修改，可以使用 `on: :create`，指定只在创建记录时做验证；或者使用 `on: :update`，指定只在更新记录时做验证。

```ruby
class Person < ActiveRecord::Base
  # it will be possible to update email with a duplicated value
  validates :email, uniqueness: true, on: :create

  # it will be possible to create the record with a non-numerical age
  validates :age, numericality: true, on: :update

  # the default (validates on both create and update)
  validates :name, presence: true
end
```

严格验证
-------

数据验证还可以使用严格模式，失败后会抛出 `ActiveModel::StrictValidationFailed` 异常。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: { strict: true }
end

Person.new.valid?  # => ActiveModel::StrictValidationFailed: Name can't be blank
```

通过 `:strict` 选项，还可以指定抛出什么异常：

```ruby
class Person < ActiveRecord::Base
  validates :token, presence: true, uniqueness: true, strict: TokenGenerationException
end

Person.new.valid?  # => TokenGenerationException: Token can't be blank
```

条件验证
-------

有时只有满足特定条件时做验证才说得通。条件可通过 `:if` 和 `:unless` 选项指定，这两个选项的值可以是 Symbol、字符串、`Proc` 或数组。`:if` 选项指定何时做验证。如果要指定何时不做验证，可以使用 `:unless` 选项。

### 指定 Symbol

`:if` 和 `:unless` 选项的值为 Symbol 时，表示要在验证之前执行对应的方法。这是最常用的设置方法。

```ruby
class Order < ActiveRecord::Base
  validates :card_number, presence: true, if: :paid_with_card?

  def paid_with_card?
    payment_type == "card"
  end
end
```

### 指定字符串

`:if` 和 `:unless` 选项的值还可以是字符串，但必须是 Ruby 代码，传入 `eval` 方法中执行。当字符串表示的条件非常短时才应该使用这种形式。

```ruby
class Person < ActiveRecord::Base
  validates :surname, presence: true, if: "name.nil?"
end
```

### 指定 Proc

`:if` and `:unless` 选项的值还可以是 Proc。使用 Proc 对象可以在行间编写条件，不用定义额外的方法。这种形式最适合用在一行代码能表示的条件上。

```ruby
class Account < ActiveRecord::Base
  validates :password, confirmation: true,
    unless: Proc.new { |a| a.password.blank? }
end
```

### 条件组合

有时同一个条件会用在多个验证上，这时可以使用 `with_options` 方法：

```ruby
class User < ActiveRecord::Base
  with_options if: :is_admin? do |admin|
    admin.validates :password, length: { minimum: 10 }
    admin.validates :email, presence: true
  end
end
```

`with_options` 代码块中的所有验证都会使用 `if: :is_admin?` 这个条件。

### 联合条件

另一方面，当多个条件规定验证是否应该执行时，可以使用数组。而且，同一个验证可以同时指定 `:if` 和 `:unless` 选项。

```ruby
class Computer < ActiveRecord::Base
  validates :mouse, presence: true,
                    if: ["market.retail?", :desktop?]
                    unless: Proc.new { |c| c.trackpad.present? }
end
```

只有当 `:if` 选项的所有条件都返回 `true`，且 `:unless` 选项中的条件返回 `false` 时才会做验证。

自定义验证方式
------------

如果内建的数据验证帮助方法无法满足需求时，可以选择自己定义验证使用的类或方法。

### 自定义验证使用的类

自定义的验证类继承自 `ActiveModel::Validator`，必须实现 `validate` 方法，传入的参数是要验证的记录，然后验证这个记录是否合法。自定义的验证类通过 `validates_with` 方法调用。

```ruby
class MyValidator < ActiveModel::Validator
  def validate(record)
    unless record.name.starts_with? 'X'
      record.errors[:name] << 'Need a name starting with X please!'
    end
  end
end

class Person
  include ActiveModel::Validations
  validates_with MyValidator
end
```

在自定义的验证类中验证单个属性，最简单的方法是集成 `ActiveModel::EachValidator` 类。此时，自定义的验证类中要实现 `validate_each` 方法。这个方法接受三个参数：记录，属性名和属性值。

```ruby
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "is not an email")
    end
  end
end

class Person < ActiveRecord::Base
  validates :email, presence: true, email: true
end
```

如上面的代码所示，可以同时使用内建的验证方法和自定义的验证类。

### 自定义验证使用的方法

还可以自定义方法验证模型的状态，如果验证失败，向 `errors` 集合添加错误消息。然后还要使用类方法 `validate` 注册这些方法，传入自定义验证方法名的 Symbol 形式。

类方法可以接受多个 Symbol，自定义的验证方法会按照注册的顺序执行。

```ruby
class Invoice < ActiveRecord::Base
  validate :expiration_date_cannot_be_in_the_past,
    :discount_cannot_be_greater_than_total_value

  def expiration_date_cannot_be_in_the_past
    if expiration_date.present? && expiration_date < Date.today
      errors.add(:expiration_date, "can't be in the past")
    end
  end

  def discount_cannot_be_greater_than_total_value
    if discount > total_value
      errors.add(:discount, "can't be greater than total value")
    end
  end
end
```

默认情况下，每次调用 `valid?` 方法时都会执行自定义的验证方法。使用 `validate` 方法注册自定义验证方法时可以设置 `:on` 选项，执行什么时候运行。`:on` 的可选值为 `:create` 和 `:update`。

```ruby
class Invoice < ActiveRecord::Base
  validate :active_customer, on: :create

  def active_customer
    errors.add(:customer_id, "is not active") unless customer.active?
  end
end
```

处理验证错误
-----------

除了前面介绍的 `valid?` 和 `invalid?` 方法之外，Rails 还提供了很多方法用来处理 `errors` 集合，以及查询对象的合法性。

下面介绍其中一些常用的方法。所有可用的方法请查阅 `ActiveModel::Errors` 的文档。

### `errors`

`ActiveModel::Errors` 的实例包含所有的错误。其键是每个属性的名字，值是一个数组，包含错误消息字符串。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors.messages
 # => {:name=>["can't be blank", "is too short (minimum is 3 characters)"]}

person = Person.new(name: "John Doe")
person.valid? # => true
person.errors.messages # => {}
```

### `errors[]`

`errors[]` 用来获取某个属性上的错误消息，返回结果是一个由该属性所有错误消息字符串组成的数组，每个字符串表示一个错误消息。如果字段上没有错误，则返回空数组。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new(name: "John Doe")
person.valid? # => true
person.errors[:name] # => []

person = Person.new(name: "JD")
person.valid? # => false
person.errors[:name] # => ["is too short (minimum is 3 characters)"]

person = Person.new
person.valid? # => false
person.errors[:name]
 # => ["can't be blank", "is too short (minimum is 3 characters)"]
```

### `errors.add`

`add` 方法可以手动添加某属性的错误消息。使用 `errors.full_messages` 或 `errors.to_a` 方法会以最终显示给用户的形式显示错误消息。这些错误消息的前面都会加上字段名可读形式（并且首字母大写）。`add` 方法接受两个参数：错误消息要添加到的字段名和错误消息本身。

```ruby
class Person < ActiveRecord::Base
  def a_method_used_for_validation_purposes
    errors.add(:name, "cannot contain the characters !@#%*()_-+=")
  end
end

person = Person.create(name: "!@#")

person.errors[:name]
 # => ["cannot contain the characters !@#%*()_-+="]

person.errors.full_messages
 # => ["Name cannot contain the characters !@#%*()_-+="]
```

还有一种方法可以实现同样地效果，使用 `[]=` 设置方法：

```ruby
  class Person < ActiveRecord::Base
    def a_method_used_for_validation_purposes
      errors[:name] = "cannot contain the characters !@#%*()_-+="
    end
  end

  person = Person.create(name: "!@#")

  person.errors[:name]
   # => ["cannot contain the characters !@#%*()_-+="]

  person.errors.to_a
   # => ["Name cannot contain the characters !@#%*()_-+="]
```

### `errors[:base]`

错误消息可以添加到整个对象上，而不是针对某个属性。如果不想管是哪个属性导致对象不合法，指向把对象标记为不合法状态，就可以使用这个方法。`errors[:base]` 是个数字，可以添加字符串作为错误消息。

```ruby
class Person < ActiveRecord::Base
  def a_method_used_for_validation_purposes
    errors[:base] << "This person is invalid because ..."
  end
end
```

### `errors.clear`

如果想清除 `errors` 集合中的所有错误消息，可以使用 `clear` 方法。当然了，在不合法的对象上调用 `errors.clear` 方法后，这个对象还是不合法的，虽然 `errors` 集合为空了，但下次调用 `valid?` 方法，或调用其他把对象存入数据库的方法时， 会再次进行验证。如果任何一个验证失败了，`errors` 集合中就再次出现值了。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors[:name]
 # => ["can't be blank", "is too short (minimum is 3 characters)"]

person.errors.clear
person.errors.empty? # => true

p.save # => false

p.errors[:name]
# => ["can't be blank", "is too short (minimum is 3 characters)"]
```

### `errors.size`

`size` 方法返回对象上错误消息的总数。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors.size # => 2

person = Person.new(name: "Andrea", email: "andrea@example.com")
person.valid? # => true
person.errors.size # => 0
```

在视图中显示验证错误
-----------------

在模型中加入数据验证后，如果在表单中创建模型，出错时，你或许想把错误消息显示出来。

因为每个程序显示错误消息的方式不同，所以 Rails 没有直接提供用来显示错误消息的视图帮助方法。不过，Rails 提供了这么多方法用来处理验证，自己编写一个也不难。使用脚手架时，Rails 会在生成的 `_form.html.erb` 中加入一些 ERB 代码，显示模型错误消息的完整列表。

假设有个模型对象存储在实例变量 `@post` 中，视图的代码可以这么写：

```ruby
<% if @post.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@post.errors.count, "error") %> prohibited this post from being saved:</h2>

    <ul>
    <% @post.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
<% end %>
```

而且，如果使用 Rails 的表单帮助方法生成表单，如果某个表单字段验证失败，会把字段包含在一个 `<div>` 中：

```
<div class="field_with_errors">
 <input id="post_title" name="post[title]" size="30" type="text" value="">
</div>
```

然后可以根据需求为这个 `div` 添加样式。脚手架默认添加的 CSS 如下：

```
.field_with_errors {
  padding: 2px;
  background-color: red;
  display: table;
}
```

所有出错的表单字段都会放入一个内边距为 2 像素的红色框内。
