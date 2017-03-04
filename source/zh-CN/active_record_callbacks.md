Active Record 回调
==================

本文介绍如何介入 Active Record 对象的生命周期。

读完本文后，您将学到：

- Active Record 对象的生命周期；

- 如何创建用于响应对象生命周期内事件的回调方法；

- 如何把常用的回调封装到特殊的类中。

--------------------------------------------------------------------------------

对象的生命周期
--------------

在 Rails 应用正常运作期间，对象可以被创建、更新或删除。Active Record 为对象的生命周期提供了钩子，使我们可以控制应用及其数据。

回调使我们可以在对象状态更改之前或之后触发逻辑。

回调概述
--------

回调是在对象生命周期的某些时刻被调用的方法。通过回调，我们可以编写在创建、保存、更新、删除、验证或从数据库中加载 Active Record 对象时执行的代码。

### 注册回调

回调在使用之前需要注册。我们可以先把回调定义为普通方法，然后使用宏式类方法把这些普通方法注册为回调：

```ruby
class User < ApplicationRecord
  validates :login, :email, presence: true

  before_validation :ensure_login_has_a_value

  protected
    def ensure_login_has_a_value
      if login.nil?
        self.login = email unless email.blank?
      end
    end
end
```

宏式类方法也接受块。如果块中的代码短到可以放在一行里，可以考虑使用这种编程风格：

```ruby
class User < ApplicationRecord
  validates :login, :email, presence: true

  before_create do
    self.name = login.capitalize if name.blank?
  end
end
```

回调也可以注册为仅被某些生命周期事件触发：

```ruby
class User < ApplicationRecord
  before_validation :normalize_name, on: :create

  # :on 选项的值也可以是数组
  after_validation :set_location, on: [ :create, :update ]

  protected
    def normalize_name
      self.name = name.downcase.titleize
    end

    def set_location
      self.location = LocationService.query(self)
    end
end
```

通常应该把回调定义为受保护的方法或私有方法。如果把回调定义为公共方法，就可以从模型外部调用回调，这样做违反了对象封装原则。

可用的回调
----------

下面按照回调在 Rails 应用正常运作期间被调用的顺序，列出所有可用的 Active Record 回调。

### 创建对象

- `before_validation`

- `after_validation`

- `before_save`

- `around_save`

- `before_create`

- `around_create`

- `after_create`

- `after_save`

- `after_commit/after_rollback`

### 更新对象

- `before_validation`

- `after_validation`

- `before_save`

- `around_save`

- `before_update`

- `around_update`

- `after_update`

- `after_save`

- `after_commit/after_rollback`

### 删除对象

- `before_destroy`

- `around_destroy`

- `after_destroy`

- `after_commit/after_rollback`

WARNING: 无论按什么顺序注册回调，在创建和更新对象时，`after_save` 回调总是在更明确的 `after_create` 和 `after_update` 回调之后被调用。

### `after_initialize` 和 `after_find` 回调

当 Active Record 对象被实例化时，不管是通过直接使用 `new` 方法还是从数据库加载记录，都会调用 `after_initialize` 回调。使用这个回调可以避免直接覆盖 Active Record 的 `initialize` 方法。

当 Active Record 从数据库中加载记录时，会调用 `after_find` 回调。如果同时定义了 `after_initialize` 和 `after_find` 回调，会先调用 `after_find` 回调。

`after_initialize` 和 `after_find` 回调没有对应的 `before_*` 回调，这两个回调的注册方式和其他 Active Record 回调一样。

```ruby
class User < ApplicationRecord
  after_initialize do |user|
    puts "You have initialized an object!"
  end

  after_find do |user|
    puts "You have found an object!"
  end
end
```

```irb
>> User.new
You have initialized an object!
=> #<User id: nil>

>> User.first
You have found an object!
You have initialized an object!
=> #<User id: 1>
```

### `after_touch` 回调

当我们在 Active Record 对象上调用 `touch` 方法时，会调用 `after_touch` 回调。

```ruby
class User < ApplicationRecord
  after_touch do |user|
    puts "You have touched an object"
  end
end
```

```irb
>> u = User.create(name: 'Kuldeep')
=> #<User id: 1, name: "Kuldeep", created_at: "2013-11-25 12:17:49", updated_at: "2013-11-25 12:17:49">

>> u.touch
You have touched an object
=> true
```

`after_touch` 回调可以和 `belongs_to` 一起使用：

```ruby
class Employee < ApplicationRecord
  belongs_to :company, touch: true
  after_touch do
    puts 'An Employee was touched'
  end
end

class Company < ApplicationRecord
  has_many :employees
  after_touch :log_when_employees_or_company_touched

  private
  def log_when_employees_or_company_touched
    puts 'Employee/Company was touched'
  end
end
```

```irb
>> @employee = Employee.last
=> #<Employee id: 1, company_id: 1, created_at: "2013-11-25 17:04:22", updated_at: "2013-11-25 17:05:05">

# triggers @employee.company.touch
>> @employee.touch
Employee/Company was touched
An Employee was touched
=> true
```

调用回调
--------

下面这些方法会触发回调：

- `create`

- `create!`

- `decrement!`

- `destroy`

- `destroy!`

- `destroy_all`

- `increment!`

- `save`

- `save!`

- `save(validate: false)`

- `toggle!`

- `update_attribute`

- `update`

- `update!`

- `valid?`

此外，下面这些查找方法会触发 `after_find` 回调：

- `all`

- `first`

- `find`

- `find_by`

- `find_by_*`

- `find_by_*!`

- `find_by_sql`

- `last`

每次初始化类的新对象时都会触发 `after_initialize` 回调。

NOTE: `find_by_*` 和 `find_by_*!` 方法是为每个属性自动生成的动态查找方法。关于动态查找方法的更多介绍，请参阅 [动态查找方法](active_record_querying.html#动态查找方法)。

跳过回调
--------

和验证一样，我们可以跳过回调。使用下面这些方法可以跳过回调：

- `decrement`

- `decrement_counter`

- `delete`

- `delete_all`

- `increment`

- `increment_counter`

- `toggle`

- `touch`

- `update_column`

- `update_columns`

- `update_all`

- `update_counters`

请慎重地使用这些方法，因为有些回调包含了重要的业务规则和应用逻辑，在不了解潜在影响的情况下就跳过回调，可能导致无效数据。

停止执行
--------

回调在模型中注册后，将被加入队列等待执行。这个队列包含了所有模型的验证、已注册的回调和将要执行的数据库操作。

整个回调链包装在一个事务中。如果任何一个 `before` 回调方法返回 `false` 或引发异常，整个回调链就会停止执行，同时发出 `ROLLBACK` 消息来回滚事务；而 `after` 回调方法只能通过引发异常来达到相同的效果。

WARNING: 当回调链停止后，Rails 会重新抛出除了 `ActiveRecord::Rollback` 和 `ActiveRecord::RecordInvalid` 之外的其他异常。这可能导致那些预期 `save` 和 `update_attributes` 等方法（通常返回 `true` 或 `false` ）不会引发异常的代码出错。

关联回调
--------

回调不仅可以在模型关联中使用，还可以通过模型关联定义。假设有一个用户在博客中发表了多篇文章，现在我们要删除这个用户，那么这个用户的所有文章也应该删除，为此我们通过 `Article` 模型和 `User` 模型的关联来给 `User` 模型添加一个 `after_destroy` 回调：

```ruby
class User < ApplicationRecord
  has_many :articles, dependent: :destroy
end

class Article < ApplicationRecord
  after_destroy :log_destroy_action

  def log_destroy_action
    puts 'Article destroyed'
  end
end
```

```irb
>> user = User.first
=> #<User id: 1>
>> user.articles.create!
=> #<Article id: 1, user_id: 1>
>> user.destroy
Article destroyed
=> #<User id: 1>
```

条件回调
--------

和验证一样，我们可以在满足指定条件时再调用回调方法。为此，我们可以使用 `:if` 和 `:unless` 选项，选项的值可以是符号、字符串、`Proc` 或数组。要想指定在哪些条件下调用回调，可以使用 `:if` 选项。要想指定在哪些条件下不调用回调，可以使用 `:unless` 选项。

### 使用符号作为 `:if` 和 `:unless` 选项的值

可以使用符号作为 `:if` 和 `:unless` 选项的值，这个符号用于表示先于回调调用的断言方法。当使用 `:if` 选项时，如果断言方法返回 `false` 就不会调用回调；当使用 `:unless` 选项时，如果断言方法返回 `true` 就不会调用回调。使用符号作为 `:if` 和 `:unless` 选项的值是最常见的方式。在使用这种方式注册回调时，我们可以同时使用几个不同的断言，用于检查是否应该调用回调。

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number, if: :paid_with_card?
end
```

### 使用字符串作为 `:if` 和 `:unless` 选项的值

还可以使用字符串作为 `:if` 和 `:unless` 选项的值，这个字符串会通过 `eval` 方法执行，因此必须包含有效的 Ruby 代码。当字符串表示的条件非常短时我们才使用这种方式：

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number, if: "paid_with_card?"
end
```

### 使用 Proc 作为 `:if` 和 `:unless` 选项的值

最后，可以使用 Proc 作为 `:if` 和 `:unless` 选项的值。在验证方法非常短时最适合使用这种方式，这类验证方法通常只有一行代码：

```ruby
class Order < ApplicationRecord
  before_save :normalize_card_number,
    if: Proc.new { |order| order.paid_with_card? }
end
```

### 在条件回调中使用多个条件

在编写条件回调时，我们可以在同一个回调声明中混合使用 `:if` 和 `:unless` 选项：

```ruby
class Comment < ApplicationRecord
  after_create :send_email_to_author, if: :author_wants_emails?,
    unless: Proc.new { |comment| comment.article.ignore_comments? }
end
```

回调类
------

有时需要在其他模型中重用已有的回调方法，为了解决这个问题，Active Record 允许我们用类来封装回调方法。有了回调类，回调方法的重用就变得非常容易。

在下面的例子中，我们为 `PictureFile` 模型创建了 `PictureFileCallbacks` 回调类，在这个回调类中包含了 `after_destroy` 回调方法：

```ruby
class PictureFileCallbacks
  def after_destroy(picture_file)
    if File.exist?(picture_file.filepath)
      File.delete(picture_file.filepath)
    end
  end
end
```

在上面的代码中我们可以看到，当在回调类中声明回调方法时，回调方法接受模型对象作为参数。回调类定义之后就可以在模型中使用了：

```ruby
class PictureFile < ApplicationRecord
  after_destroy PictureFileCallbacks.new
end
```

请注意，上面我们把回调声明为实例方法，因此需要实例化新的 `PictureFileCallbacks` 对象。当回调想要使用实例化的对象的状态时，这种声明方式特别有用。尽管如此，一般我们会把回调声明为类方法：

```ruby
class PictureFileCallbacks
  def self.after_destroy(picture_file)
    if File.exist?(picture_file.filepath)
      File.delete(picture_file.filepath)
    end
  end
end
```

如果把回调声明为类方法，就不需要实例化新的 `PictureFileCallbacks` 对象。

```ruby
class PictureFile < ApplicationRecord
  after_destroy PictureFileCallbacks
end
```

我们可以根据需要在回调类中声明任意多个回调。

事务回调
--------

`after_commit` 和 `after_rollback` 这两个回调会在数据库事务完成时触发。它们和 `after_save` 回调非常相似，区别在于它们在数据库变更已经提交或回滚后才会执行，常用于 Active Record 模型需要和数据库事务之外的系统交互的场景。

例如，在前面的例子中，`PictureFile` 模型中的记录删除后，还要删除相应的文件。如果 `after_destroy` 回调执行后应用引发异常，事务就会回滚，文件会被删除，模型会保持不一致的状态。例如，假设在下面的代码中，`picture_file_2` 对象是无效的，那么调用 `save!` 方法会引发错误：

```ruby
PictureFile.transaction do
  picture_file_1.destroy
  picture_file_2.save!
end
```

通过使用 `after_commit` 回调，我们可以解决这个问题：

```ruby
class PictureFile < ApplicationRecord
  after_commit :delete_picture_file_from_disk, on: [:destroy]

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
```

NOTE: `:on` 选项说明什么时候触发回调。如果不提供 `:on` 选项，那么每个动作都会触发回调。

由于只在执行创建、更新或删除动作时触发 `after_commit` 回调是很常见的，这些操作都拥有别名：

- `after_create_commit`

- `after_update_commit`

- `after_destroy_commit`

```ruby
class PictureFile < ApplicationRecord
  after_destroy_commit :delete_picture_file_from_disk

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
```

WARNING: 对于在事务中创建、更新或删除的模型，`after_commit` 和 `after_rollback` 回调一定会被调用。如果其中有一个回调引发异常，这个异常会被忽略，以避免干扰其他回调。因此，如果回调代码可能引发异常，就需要在回调中救援并进行适当处理。
