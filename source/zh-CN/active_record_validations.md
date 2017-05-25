# Active Record 数据验证

本文介绍如何使用 Active Record 提供的数据验证功能，在数据存入数据库之前验证对象的状态。

读完本文后，您将学到：

*   如何使用 Active Record 内置的数据验证辅助方法；
*   如果自定义数据验证方法；
*   如何处理验证过程产生的错误消息。

-----------------------------------------------------------------------------

<a class="anchor" id="validations-overview"></a>

## 数据验证概览

下面是一个非常简单的数据验证：

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end

Person.create(name: "John Doe").valid? # => true
Person.create(name: nil).valid? # => false
```

可以看出，如果 `Person` 没有 `name` 属性，验证就会将其视为无效对象。第二个 `Person` 对象不会存入数据库。

在深入探讨之前，我们先来了解数据验证在应用中的作用。

<a class="anchor" id="why-use-validations"></a>

### 为什么要做数据验证？

数据验证确保只有有效的数据才能存入数据库。例如，应用可能需要用户提供一个有效的电子邮件地址和邮寄地址。在模型中做验证是最有保障的，只有通过验证的数据才能存入数据库。数据验证和使用的数据库种类无关，终端用户也无法跳过，而且容易测试和维护。在 Rails 中做数据验证很简单，Rails 内置了很多辅助方法，能满足常规的需求，而且还可以编写自定义的验证方法。

在数据存入数据库之前，也有几种验证数据的方法，包括数据库原生的约束、客户端验证和控制器层验证。下面列出这几种验证方法的优缺点：

*   数据库约束和存储过程无法兼容多种数据库，而且难以测试和维护。然而，如果其他应用也要使用这个数据库，最好在数据库层做些约束。此外，数据库层的某些验证（例如在使用量很高的表中做唯一性验证）通过其他方式实现起来有点困难。
*   客户端验证很有用，但单独使用时可靠性不高。如果使用 JavaScript 实现，用户在浏览器中禁用 JavaScript 后很容易跳过验证。然而，客户端验证和其他验证方式相结合，可以为用户提供实时反馈。
*   控制器层验证很诱人，但一般都不灵便，难以测试和维护。只要可能，就要保证控制器的代码简洁，这样才有利于长远发展。

你可以根据实际需求选择使用合适的验证方式。Rails 团队认为，模型层数据验证最具普适性。

<a class="anchor" id="when-does-validation-happen"></a>

### 数据在何时验证？

Active Record 对象分为两种：一种在数据库中有对应的记录，一种没有。新建的对象（例如，使用 `new` 方法）还不属于数据库。在对象上调用 `save` 方法后，才会把对象存入相应的数据库表。Active Record 使用实例方法 `new_record?` 判断对象是否已经存入数据库。假如有下面这个简单的 Active Record 类：

```ruby
class Person < ApplicationRecord
end
```

我们可以在 `rails console` 中看一下到底怎么回事：

```irb
$ bin/rails console
>> p = Person.new(name: "John Doe")
=> #<Person id: nil, name: "John Doe", created_at: nil, updated_at: nil>
>> p.new_record?
=> true
>> p.save
=> true
>> p.new_record?
=> false
```

新建并保存记录会在数据库中执行 SQL `INSERT` 操作。更新现有的记录会在数据库中执行 SQL `UPDATE` 操作。一般情况下，数据验证发生在这些 SQL 操作执行之前。如果验证失败，对象会被标记为无效，Active Record 不会向数据库发送 `INSERT` 或 `UPDATE` 指令。这样就可以避免把无效的数据存入数据库。你可以选择在对象创建、保存或更新时执行特定的数据验证。

WARNING: 修改数据库中对象的状态有多种方式。有些方法会触发数据验证，有些则不会。所以，如果不小心处理，还是有可能把无效的数据存入数据库。


下列方法会触发数据验证，如果验证失败就不把对象存入数据库：

*   `create`
*   `create!`
*   `save`
*   `save!`
*   `update`
*   `update!`

爆炸方法（例如 `save!`）会在验证失败后抛出异常。验证失败后，非爆炸方法不会抛出异常，`save` 和 `update` 返回 `false`，`create` 返回对象本身。

<a class="anchor" id="skipping-validations"></a>

### 跳过验证

下列方法会跳过验证，不管验证是否通过都会把对象存入数据库，使用时要特别留意。

*   `decrement!`
*   `decrement_counter`
*   `increment!`
*   `increment_counter`
*   `toggle!`
*   `touch`
*   `update_all`
*   `update_attribute`
*   `update_column`
*   `update_columns`
*   `update_counters`

注意，使用 `save` 时如果传入 `validate: false` 参数，也会跳过验证。使用时要特别留意。

*   `save(validate: false)`

<a class="anchor" id="valid-questionmark-and-invalid-questionmark"></a>

### `valid?` 和 `invalid?`

Rails 在保存 Active Record 对象之前验证数据。如果验证过程产生错误，Rails 不会保存对象。

你还可以自己执行数据验证。`valid?` 方法会触发数据验证，如果对象上没有错误，返回 `true`，否则返回 `false`。前面我们已经用过了：

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end

Person.create(name: "John Doe").valid? # => true
Person.create(name: nil).valid? # => false
```

Active Record 执行验证后，所有发现的错误都可以通过实例方法 `errors.messages` 获取。该方法返回一个错误集合。如果数据验证后，这个集合为空，说明对象是有效的。

注意，使用 `new` 方法初始化对象时，即使无效也不会报错，因为只有保存对象时才会验证数据，例如调用 `create` 或 `save` 方法。

```ruby
class Person < ApplicationRecord
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

`invalid?` 的作用与 `valid?` 相反，它会触发数据验证，如果找到错误就返回 `true`，否则返回 `false`。

<a class="anchor" id="validations-overview-errors"></a>

### `errors[]`

若想检查对象的某个属性是否有效，可以使用 `errors[:attribute]`。`errors[:attribute]` 中包含与 `:attribute` 有关的所有错误。如果某个属性没有错误，就会返回空数组。

这个方法只在数据验证之后才能使用，因为它只是用来收集错误信息的，并不会触发验证。与前面介绍的 `ActiveRecord::Base#invalid?` 方法不一样，`errors[:attribute]` 不会验证整个对象，只检查对象的某个属性是否有错。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end

>> Person.new.errors[:name].any? # => false
>> Person.create.errors[:name].any? # => true
```

我们会在 [处理验证错误](#working-with-validation-errors)详细说明验证错误。

<a class="anchor" id="validations-overview-errors-details"></a>

### `errors.details`

若想查看是哪个验证导致属性无效的，可以使用 `errors.details[:attribute]`。它的返回值是一个由散列组成的数组，`:error` 键的值是一个符号，指明出错的数据验证。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true
end

>> person = Person.new
>> person.valid?
>> person.errors.details[:name] # => [{error: :blank}]
```

[处理验证错误](#working-with-validation-errors)会说明如何在自定义的数据验证中使用 `details`。

<a class="anchor" id="validation-helpers"></a>

## 数据验证辅助方法

Active Record 预先定义了很多数据验证辅助方法，可以直接在模型类定义中使用。这些辅助方法提供了常用的验证规则。每次验证失败后，都会向对象的 `errors` 集合中添加一个消息，而且这些消息与所验证的属性是关联的。

每个辅助方法都可以接受任意个属性名，所以一行代码就能在多个属性上做同一种验证。

所有辅助方法都可指定 `:on` 和 `:message` 选项，分别指定何时做验证，以及验证失败后向 `errors` 集合添加什么消息。`:on` 选项的可选值是 `:create` 或 `:update`。每个辅助函数都有默认的错误消息，如果没有通过 `:message` 选项指定，则使用默认值。下面分别介绍各个辅助方法。

<a class="anchor" id="acceptance"></a>

### `acceptance`

这个方法检查表单提交时，用户界面中的复选框是否被选中。这个功能一般用来要求用户接受应用的服务条款、确保用户阅读了一些文本，等等。

```ruby
class Person < ApplicationRecord
  validates :terms_of_service, acceptance: true
end
```

仅当 `terms_of_service` 不为 `nil` 时才会执行这个检查。这个辅助方法的默认错误消息是“must be accepted”。通过 `message` 选项可以传入自定义的消息。

```ruby
class Person < ApplicationRecord
  validates :terms_of_service, acceptance: { message: 'must be abided' }
end
```

这个辅助方法还接受 `:accept` 选项，指定把哪些值视作“接受”。默认为 `['1', true]`，不过可以轻易修改：

```ruby
class Person < ApplicationRecord
  validates :terms_of_service, acceptance: { accept: 'yes' }
  validates :eula, acceptance: { accept: ['TRUE', 'accepted'] }
end
```

这种验证只针对 Web 应用，接受与否无需存入数据库。如果没有对应的字段，该方法会创建一个虚拟属性。如果数据库中有对应的字段，必须把 `accept` 选项的值设为或包含 `true`，否则验证不会执行。

<a class="anchor" id="validates-associated"></a>

### `validates_associated`

如果模型和其他模型有关联，而且关联的模型也要验证，要使用这个辅助方法。保存对象时，会在相关联的每个对象上调用 `valid?` 方法。

```ruby
class Library < ApplicationRecord
  has_many :books
  validates_associated :books
end
```

这种验证支持所有关联类型。

WARNING: 不要在关联的两端都使用 `validates_associated`，这样会变成无限循环。


`validates_associated` 的默认错误消息是“is invalid”。注意，相关联的每个对象都有各自的 `errors` 集合，错误消息不会都集中在调用该方法的模型对象上。

<a class="anchor" id="confirmation"></a>

### `confirmation`

如果要检查两个文本字段的值是否完全相同，使用这个辅助方法。例如，确认电子邮件地址或密码。这个验证创建一个虚拟属性，其名字为要验证的属性名后加 `_confirmation`。

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: true
end
```

在视图模板中可以这么写：

```erb
<%= text_field :person, :email %>
<%= text_field :person, :email_confirmation %>
```

只有 `email_confirmation` 的值不是 `nil` 时才会检查。所以要为确认属性加上存在性验证（后文会介绍 `presence` 验证）。

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: true
  validates :email_confirmation, presence: true
end
```

此外，还可以使用 `:case_sensitive` 选项指定确认时是否区分大小写。这个选项的默认值是 `true`。

```ruby
class Person < ApplicationRecord
  validates :email, confirmation: { case_sensitive: false }
end
```

这个辅助方法的默认错误消息是“doesn&#8217;t match confirmation”。

<a class="anchor" id="exclusion"></a>

### `exclusion`

这个辅助方法检查属性的值是否不在指定的集合中。集合可以是任何一种可枚举的对象。

```ruby
class Account < ApplicationRecord
  validates :subdomain, exclusion: { in: %w(www us ca jp),
    message: "%{value} is reserved." }
end
```

`exclusion` 方法要指定 `:in` 选项，设置哪些值不能作为属性的值。`:in` 选项有个别名 `:with`，作用相同。上面的例子设置了 `:message` 选项，演示如何获取属性的值。`:message` 选项的完整参数参见 [`:message`](#message)。

默认的错误消息是“is reserved”。

<a class="anchor" id="format"></a>

### `format`

这个辅助方法检查属性的值是否匹配 `:with` 选项指定的正则表达式。

```ruby
class Product < ApplicationRecord
  validates :legacy_code, format: { with: /\A[a-zA-Z]+\z/,
    message: "only allows letters" }
end
```

或者，使用 `:without` 选项，指定属性的值不能匹配正则表达式。

默认的错误消息是“is invalid”。

<a class="anchor" id="inclusion"></a>

### `inclusion`

这个辅助方法检查属性的值是否在指定的集合中。集合可以是任何一种可枚举的对象。

```ruby
class Coffee < ApplicationRecord
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value} is not a valid size" }
end
```

`inclusion` 方法要指定 `:in` 选项，设置可接受哪些值。`:in` 选项有个别名 `:within`，作用相同。上面的例子设置了 `:message` 选项，演示如何获取属性的值。`:message` 选项的完整参数参见 [`:message`](#message)。

该方法的默认错误消息是“is not included in the list”。

<a class="anchor" id="length"></a>

### `length`

这个辅助方法验证属性值的长度，有多个选项，可以使用不同的方法指定长度约束：

```ruby
class Person < ApplicationRecord
  validates :name, length: { minimum: 2 }
  validates :bio, length: { maximum: 500 }
  validates :password, length: { in: 6..20 }
  validates :registration_number, length: { is: 6 }
end
```

可用的长度约束选项有：

*   `:minimum`：属性的值不能比指定的长度短；
*   `:maximum`：属性的值不能比指定的长度长；
*   `:in`（或 `:within`）：属性值的长度在指定的范围内。该选项的值必须是一个范围；
*   `:is`：属性值的长度必须等于指定值；

默认的错误消息根据长度验证的约束类型而有所不同，不过可以使用 `:message` 选项定制。定制消息时，可以使用 `:wrong_length`、`:too_long` 和 `:too_short` 选项，`%{count}` 表示长度限制的值。

```ruby
class Person < ApplicationRecord
  validates :bio, length: { maximum: 1000,
    too_long: "%{count} characters is the maximum allowed" }
end
```

这个辅助方法默认统计字符数，但可以使用 `:tokenizer` 选项设置其他的统计方式：

注意，默认的错误消息使用复数形式（例如，“is too short (minimum is %{count} characters”），所以如果长度限制是 `minimum: 1`，就要提供一个定制的消息，或者使用 `presence: true` 代替。`:in` 或 `:within` 的下限值比 1 小时，要提供一个定制的消息，或者在 `length` 之前调用 `presence` 方法。

<a class="anchor" id="numericality"></a>

### `numericality`

这个辅助方法检查属性的值是否只包含数字。默认情况下，匹配的值是可选的正负符号后加整数或浮点数。如果只接受整数，把 `:only_integer` 选项设为 `true`。

如果把 `:only_integer` 的值设为 `true`，使用下面的正则表达式验证属性的值：

```ruby
/\A[+-]?\d+\z/
```

否则，会尝试使用 `Float` 把值转换成数字。

```ruby
class Player < ApplicationRecord
  validates :points, numericality: true
  validates :games_played, numericality: { only_integer: true }
end
```

除了 `:only_integer` 之外，这个方法还可指定以下选项，限制可接受的值：

*   `:greater_than`：属性值必须比指定的值大。该选项默认的错误消息是“must be greater than %{count}”；
*   `:greater_than_or_equal_to`：属性值必须大于或等于指定的值。该选项默认的错误消息是“must be greater than or equal to %{count}”；
*   `:equal_to`：属性值必须等于指定的值。该选项默认的错误消息是“must be equal to %{count}”；
*   `:less_than`：属性值必须比指定的值小。该选项默认的错误消息是“must be less than %{count}”；
*   `:less_than_or_equal_to`：属性值必须小于或等于指定的值。该选项默认的错误消息是“must be less than or equal to %{count}”；
*   `:other_than`：属性值必须与指定的值不同。该选项默认的错误消息是“must be other than %{count}”。
*   `:odd`：如果设为 `true`，属性值必须是奇数。该选项默认的错误消息是“must be odd”；
*   `:even`：如果设为 `true`，属性值必须是偶数。该选项默认的错误消息是“must be even”；

NOTE: `numericality` 默认不接受 `nil` 值。可以使用 `allow_nil: true` 选项允许接受 `nil`。


默认的错误消息是“is not a number”。

<a class="anchor" id="presence"></a>

### `presence`

这个辅助方法检查指定的属性是否为非空值。它调用 `blank?` 方法检查值是否为 `nil` 或空字符串，即空字符串或只包含空白的字符串。

```ruby
class Person < ApplicationRecord
  validates :name, :login, :email, presence: true
end
```

如果要确保关联对象存在，需要测试关联的对象本身是否存在，而不是用来映射关联的外键。

```ruby
class LineItem < ApplicationRecord
  belongs_to :order
  validates :order, presence: true
end
```

为了能验证关联的对象是否存在，要在关联中指定 `:inverse_of` 选项。

```ruby
class Order < ApplicationRecord
  has_many :line_items, inverse_of: :order
end
```

如果验证 `has_one` 或 `has_many` 关联的对象是否存在，会在关联的对象上调用 `blank?` 和 `marked_for_destruction?` 方法。

因为 `false.blank?` 的返回值是 `true`，所以如果要验证布尔值字段是否存在，要使用下述验证中的一个：

```ruby
validates :boolean_field_name, inclusion: { in: [true, false] }
validates :boolean_field_name, exclusion: { in: [nil] }
```

上述验证确保值不是 `nil`；在多数情况下，即验证不是 `NULL`。

默认的错误消息是“can&#8217;t be blank”。

<a class="anchor" id="absence"></a>

### `absence`

这个辅助方法验证指定的属性值是否为空。它使用 `present?` 方法检测值是否为 `nil` 或空字符串，即空字符串或只包含空白的字符串。

```ruby
class Person < ApplicationRecord
  validates :name, :login, :email, absence: true
end
```

如果要确保关联对象为空，要测试关联的对象本身是否为空，而不是用来映射关联的外键。

```ruby
class LineItem < ApplicationRecord
  belongs_to :order
  validates :order, absence: true
end
```

为了能验证关联的对象是否为空，要在关联中指定 `:inverse_of` 选项。

```ruby
class Order < ApplicationRecord
  has_many :line_items, inverse_of: :order
end
```

如果验证 `has_one` 或 `has_many` 关联的对象是否为空，会在关联的对象上调用 `present?` 和 `marked_for_destruction?` 方法。

因为 `false.present?` 的返回值是 `false`，所以如果要验证布尔值字段是否为空要使用 `validates :field_name, exclusion: { in: [true, false] }`。

默认的错误消息是“must be blank”。

<a class="anchor" id="uniqueness"></a>

### `uniqueness`

这个辅助方法在保存对象之前验证属性值是否是唯一的。该方法不会在数据库中创建唯一性约束，所以有可能两次数据库连接创建的记录具有相同的字段值。为了避免出现这种问题，必须在数据库的字段上建立唯一性索引。

```ruby
class Account < ApplicationRecord
  validates :email, uniqueness: true
end
```

这个验证会在模型对应的表中执行一个 SQL 查询，检查现有的记录中该字段是否已经出现过相同的值。

`:scope` 选项用于指定检查唯一性时使用的一个或多个属性：

```ruby
class Holiday < ApplicationRecord
  validates :name, uniqueness: { scope: :year,
    message: "should happen once per year" }
end
```

如果想确保使用 `:scope` 选项的唯一性验证严格有效，必须在数据库中为多列创建唯一性索引。多列索引的详情参见 [MySQL 手册](http://dev.mysql.com/doc/refman/5.7/en/multiple-column-indexes.html)，[PostgreSQL 手册](http://www.postgresql.org/docs/current/static/ddl-constraints.html)中有些示例，说明如何为一组列创建唯一性约束。

还有个 `:case_sensitive` 选项，指定唯一性验证是否区分大小写，默认值为 `true`。

```ruby
class Person < ApplicationRecord
  validates :name, uniqueness: { case_sensitive: false }
end
```

WARNING: 注意，不管怎样设置，有些数据库查询时始终不区分大小写。


默认的错误消息是“has already been taken”。

<a class="anchor" id="validates-with"></a>

### `validates_with`

这个辅助方法把记录交给其他类做验证。

```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if record.first_name == "Evil"
      record.errors[:base] << "This person is evil"
    end
  end
end

class Person < ApplicationRecord
  validates_with GoodnessValidator
end
```

NOTE: `record.errors[:base]` 中的错误针对整个对象，而不是特定的属性。


`validates_with` 方法的参数是一个类或一组类，用来做验证。`validates_with` 方法没有默认的错误消息。在做验证的类中要手动把错误添加到记录的错误集合中。

实现 `validate` 方法时，必须指定 `record` 参数，这是要做验证的记录。

与其他验证一样，`validates_with` 也可指定 `:if`、`:unless` 和 `:on` 选项。如果指定了其他选项，会包含在 `options` 中传递给做验证的类。

```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if options[:fields].any?{|field| record.send(field) == "Evil" }
      record.errors[:base] << "This person is evil"
    end
  end
end

class Person < ApplicationRecord
  validates_with GoodnessValidator, fields: [:first_name, :last_name]
end
```

注意，做验证的类在整个应用的生命周期内只会初始化一次，而不是每次验证时都初始化，所以使用实例变量时要特别小心。

如果做验证的类很复杂，必须要用实例变量，可以用纯粹的 Ruby 对象代替：

```ruby
class Person < ApplicationRecord
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

<a class="anchor" id="validates-each"></a>

### `validates_each`

这个辅助方法使用代码块中的代码验证属性。它没有预先定义验证函数，你要在代码块中定义验证方式。要验证的每个属性都会传入块中做验证。在下面的例子中，我们确保名和姓都不能以小写字母开头：

```ruby
class Person < ApplicationRecord
  validates_each :name, :surname do |record, attr, value|
    record.errors.add(attr, 'must start with upper case') if value =~ /\A[[:lower:]]/
  end
end
```

代码块的参数是记录、属性名和属性值。在代码块中可以做任何检查，确保数据有效。如果验证失败，应该向模型添加一个错误消息，把数据标记为无效。

<a class="anchor" id="common-validation-options"></a>

## 常用的验证选项

下面介绍常用的验证选项。

<a class="anchor" id="allow-nil"></a>

### `:allow_nil`

指定 `:allow_nil` 选项后，如果要验证的值为 `nil` 就跳过验证。

```ruby
class Coffee < ApplicationRecord
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value} is not a valid size" }, allow_nil: true
end
```

`:message` 选项的完整参数参见 [`:message`](#message)。

<a class="anchor" id="allow-blank"></a>

### `:allow_blank`

`:allow_blank` 选项和 `:allow_nil` 选项类似。如果要验证的值为空（调用 `blank?` 方法判断，例如 `nil` 或空字符串），就跳过验证。

```ruby
class Topic < ApplicationRecord
  validates :title, length: { is: 5 }, allow_blank: true
end

Topic.create(title: "").valid?  # => true
Topic.create(title: nil).valid? # => true
```

<a class="anchor" id="message"></a>

### `:message`

前面已经介绍过，如果验证失败，会把 `:message` 选项指定的字符串添加到 `errors` 集合中。如果没指定这个选项，Active Record 使用各个验证辅助方法的默认错误消息。`:message` 选项的值是一个字符串或一个 `Proc` 对象。

字符串消息中可以包含 `%{value}`、`%{attribute}` 和 `%{model}`，在验证失败时它们会被替换成具体的值。替换通过 I18n gem 实现，而且占位符必须精确匹配，不能有空格。

`Proc` 形式的消息有两个参数：验证的对象，以及包含 `:model`、`:attribute` 和 `:value` 键值对的散列。

```ruby
class Person < ApplicationRecord
  # 直接写消息
  validates :name, presence: { message: "must be given please" }

  # 带有动态属性值的消息。%{value} 会被替换成属性的值
  # 此外还可以使用 %{attribute} 和 %{model}
  validates :age, numericality: { message: "%{value} seems wrong" }

  # Proc
  validates :username,
    uniqueness: {
      # object = 要验证的 person 对象
      # data = { model: "Person", attribute: "Username", value: <username> }
      message: ->(object, data) do
        "Hey #{object.name}!, #{data[:value]} is taken already! Try again #{Time.zone.tomorrow}"
      end
    }
end
```

<a class="anchor" id="on"></a>

### `:on`

`:on` 选项指定什么时候验证。所有内置的验证辅助方法默认都在保存时（新建记录或更新记录）验证。如果想修改，可以使用 `on: :create`，指定只在创建记录时验证；或者使用 `on: :update`，指定只在更新记录时验证。

```ruby
class Person < ApplicationRecord
  # 更新时允许电子邮件地址重复
  validates :email, uniqueness: true, on: :create

  # 创建记录时允许年龄不是数字
  validates :age, numericality: true, on: :update

  # 默认行为（创建和更新时都验证）
  validates :name, presence: true
end
```

此外，还可以使用 `on:` 定义自定义的上下文。必须把上下文的名称传给 `valid?`、`invalid?` 或 `save` 才能触发自定义的上下文。

```ruby
class Person < ApplicationRecord
  validates :email, uniqueness: true, on: :account_setup
  validates :age, numericality: true, on: :account_setup
end

person = Person.new
```

`person.valid?(:account_setup)` 会执行上述两个验证，但不保存记录。`person.save(context: :account_setup)` 在保存之前在 `account_setup` 上下文中验证 `person`。显式触发时，可以只使用某个上下文验证，也可以不使用某个上下文验证。

<a class="anchor" id="strict-validations"></a>

## 严格验证

数据验证还可以使用严格模式，当对象无效时抛出 `ActiveModel::StrictValidationFailed` 异常。

```ruby
class Person < ApplicationRecord
  validates :name, presence: { strict: true }
end

Person.new.valid?  # => ActiveModel::StrictValidationFailed: Name can't be blank
```

还可以通过 `:strict` 选项指定抛出什么异常：

```ruby
class Person < ApplicationRecord
  validates :token, presence: true, uniqueness: true, strict: TokenGenerationException
end

Person.new.valid?  # => TokenGenerationException: Token can't be blank
```

<a class="anchor" id="conditional-validation"></a>

## 条件验证

有时，只有满足特定条件时做验证才说得通。条件可通过 `:if` 和 `:unless` 选项指定，这两个选项的值可以是符号、字符串、`Proc` 或数组。`:if` 选项指定何时做验证。如果要指定何时不做验证，使用 `:unless` 选项。

<a class="anchor" id="using-a-symbol-with-if-and-unless"></a>

### 使用符号

`:if` 和 `:unless` 选项的值为符号时，表示要在验证之前执行对应的方法。这是最常用的设置方法。

```ruby
class Order < ApplicationRecord
  validates :card_number, presence: true, if: :paid_with_card?

  def paid_with_card?
    payment_type == "card"
  end
end
```

<a class="anchor" id="using-a-proc-with-if-and-unless"></a>

### 使用 Proc

`:if` and `:unless` 选项的值还可以是 Proc。使用 Proc 对象可以在行间编写条件，不用定义额外的方法。这种形式最适合用在一行代码能表示的条件上。

```ruby
class Account < ApplicationRecord
  validates :password, confirmation: true,
    unless: Proc.new { |a| a.password.blank? }
end
```

<a class="anchor" id="grouping-conditional-validations"></a>

### 条件组合

有时，同一个条件会用在多个验证上，这时可以使用 `with_options` 方法：

```ruby
class User < ApplicationRecord
  with_options if: :is_admin? do |admin|
    admin.validates :password, length: { minimum: 10 }
    admin.validates :email, presence: true
  end
end
```

`with_options` 代码块中的所有验证都会使用 `if: :is_admin?` 这个条件。

<a class="anchor" id="combining-validation-conditions"></a>

### 联合条件

另一方面，如果是否做某个验证要满足多个条件时，可以使用数组。而且，一个验证可以同时指定 `:if` 和 `:unless` 选项。

```ruby
class Computer < ApplicationRecord
  validates :mouse, presence: true,
                    if: ["market.retail?", :desktop?],
                    unless: Proc.new { |c| c.trackpad.present? }
end
```

只有当 `:if` 选项的所有条件都返回 `true`，且 `:unless` 选项中的条件返回 `false` 时才会做验证。

<a class="anchor" id="performing-custom-validations"></a>

## 自定义验证

如果内置的数据验证辅助方法无法满足需求，可以选择自己定义验证使用的类或方法。

<a class="anchor" id="custom-validators"></a>

### 自定义验证类

自定义的验证类继承自 `ActiveModel::Validator`，必须实现 `validate` 方法，其参数是要验证的记录，然后验证这个记录是否有效。自定义的验证类通过 `validates_with` 方法调用。

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

在自定义的验证类中验证单个属性，最简单的方法是继承 `ActiveModel::EachValidator` 类。此时，自定义的验证类必须实现 `validate_each` 方法。这个方法接受三个参数：记录、属性名和属性值。它们分别对应模型实例、要验证的属性及其值。

```ruby
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "is not an email")
    end
  end
end

class Person < ApplicationRecord
  validates :email, presence: true, email: true
end
```

如上面的代码所示，可以同时使用内置的验证方法和自定义的验证类。

<a class="anchor" id="custom-methods"></a>

### 自定义验证方法

你还可以自定义方法，验证模型的状态，如果验证失败，向 `erros` 集合添加错误消息。验证方法必须使用类方法 `validate`（[API](http://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validate)）注册，传入自定义验证方法名的符号形式。

这个类方法可以接受多个符号，自定义的验证方法会按照注册的顺序执行。

`valid?` 方法会验证错误集合是否为空，因此若想让验证失败，自定义的验证方法要把错误添加到那个集合中。

```ruby
class Invoice < ApplicationRecord
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

默认情况下，每次调用 `valid?` 方法或保存对象时都会执行自定义的验证方法。不过，使用 `validate` 方法注册自定义验证方法时可以设置 `:on` 选项，指定什么时候验证。`:on` 的可选值为 `:create` 和 `:update`。

```ruby
class Invoice < ApplicationRecord
  validate :active_customer, on: :create

  def active_customer
    errors.add(:customer_id, "is not active") unless customer.active?
  end
end
```

<a class="anchor" id="working-with-validation-errors"></a>

## 处理验证错误

除了前面介绍的 `valid?` 和 `invalid?` 方法之外，Rails 还提供了很多方法用来处理 `errors` 集合，以及查询对象的有效性。

下面介绍其中一些最常用的方法。所有可用的方法请查阅 `ActiveModel::Errors` 的文档。

<a class="anchor" id="working-with-validation-errors-errors"></a>

### `errors`

`ActiveModel::Errors` 的实例包含所有的错误。键是每个属性的名称，值是一个数组，包含错误消息字符串。

```ruby
class Person < ApplicationRecord
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

<a class="anchor" id="errors"></a>

### `errors[]`

`errors[]` 用于获取某个属性上的错误消息，返回结果是一个由该属性所有错误消息字符串组成的数组，每个字符串表示一个错误消息。如果字段上没有错误，则返回空数组。

```ruby
class Person < ApplicationRecord
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

<a class="anchor" id="errors-add"></a>

### `errors.add`

`add` 方法用于手动添加某属性的错误消息，它的参数是属性和错误消息。

使用 `errors.full_messages`（或等价的 `errors.to_a`）方法以对用户友好的格式显示错误消息。这些错误消息的前面都会加上属性名（首字母大写），如下述示例所示。

```ruby
class Person < ApplicationRecord
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

`<<` 的作用与 `errors#add` 一样：把一个消息追加到 `errors.messages` 数组中。

```ruby
class Person < ApplicationRecord
  def a_method_used_for_validation_purposes
    errors.messages[:name] << "cannot contain the characters !@#%*()_-+="
  end
end

person = Person.create(name: "!@#")

person.errors[:name]
 # => ["cannot contain the characters !@#%*()_-+="]

person.errors.to_a
 # => ["Name cannot contain the characters !@#%*()_-+="]
```

<a class="anchor" id="working-with-validation-errors-errors-details"></a>

### `errors.details`

使用 `errors.add` 方法可以为返回的错误详情散列指定验证程序类型。

```ruby
class Person < ApplicationRecord
  def a_method_used_for_validation_purposes
    errors.add(:name, :invalid_characters)
  end
end

person = Person.create(name: "!@#")

person.errors.details[:name]
# => [{error: :invalid_characters}]
```

如果想提升错误详情的信息量，可以为 `errors.add` 方法提供额外的键，指定不允许的字符。

```ruby
class Person < ApplicationRecord
  def a_method_used_for_validation_purposes
    errors.add(:name, :invalid_characters, not_allowed: "!@#%*()_-+=")
  end
end

person = Person.create(name: "!@#")

person.errors.details[:name]
# => [{error: :invalid_characters, not_allowed: "!@#%*()_-+="}]
```

Rails 内置的验证程序生成的错误详情散列都有对应的验证程序类型。

<a class="anchor" id="errors-base"></a>

### `errors[:base]`

错误消息可以添加到整个对象上，而不是针对某个属性。如果不想管是哪个属性导致对象无效，只想把对象标记为无效状态，就可以使用这个方法。`errors[:base]` 是个数组，可以添加字符串作为错误消息。

```ruby
class Person < ApplicationRecord
  def a_method_used_for_validation_purposes
    errors[:base] << "This person is invalid because ..."
  end
end
```

<a class="anchor" id="errors-clear"></a>

### `errors.clear`

如果想清除 `errors` 集合中的所有错误消息，可以使用 `clear` 方法。当然，在无效的对象上调用 `errors.clear` 方法后，对象还是无效的，虽然 `errors` 集合为空了，但下次调用 `valid?` 方法，或调用其他把对象存入数据库的方法时， 会再次进行验证。如果任何一个验证失败了，`errors` 集合中就再次出现值了。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors[:name]
 # => ["can't be blank", "is too short (minimum is 3 characters)"]

person.errors.clear
person.errors.empty? # => true

person.save # => false

person.errors[:name]
# => ["can't be blank", "is too short (minimum is 3 characters)"]
```

<a class="anchor" id="errors-size"></a>

### `errors.size`

`size` 方法返回对象上错误消息的总数。

```ruby
class Person < ApplicationRecord
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors.size # => 2

person = Person.new(name: "Andrea", email: "andrea@example.com")
person.valid? # => true
person.errors.size # => 0
```

<a class="anchor" id="displaying-validation-errors-in-views"></a>

## 在视图中显示验证错误

在模型中加入数据验证后，如果在表单中创建模型，出错时，你或许想把错误消息显示出来。

因为每个应用显示错误消息的方式不同，所以 Rails 没有直接提供用于显示错误消息的视图辅助方法。不过，Rails 提供了这么多方法用来处理验证，自己编写一个也不难。使用脚手架时，Rails 会在生成的 `_form.html.erb` 中加入一些 ERB 代码，显示模型错误消息的完整列表。

假如有个模型对象存储在实例变量 `@article` 中，视图的代码可以这么写：

```erb
<% if @article.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@article.errors.count, "error") %> prohibited this article from being saved:</h2>

    <ul>
    <% @article.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
<% end %>
```

此外，如果使用 Rails 的表单辅助方法生成表单，如果某个表单字段验证失败，会把字段包含在一个 `<div>` 中：

```html
<div class="field_with_errors">
  <input id="article_title" name="article[title]" size="30" type="text" value="">
</div>
```

然后，你可以根据需求为这个 `div` 添加样式。脚手架默认添加的 CSS 规则如下：

```css
.field_with_errors {
  padding: 2px;
  background-color: red;
  display: table;
}
```

上述样式把所有出错的表单字段放入一个内边距为 2 像素的红色框内。
