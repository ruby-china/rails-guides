Active Record 回调
==================

本文介绍如何介入 Active Record 对象的生命周期。

读完后，你将学会：

* Active Record 对象的生命周期；
* 如何编写回调方法响应对象声明周期内发生的事件；
* 如何把常用的回调封装到特殊的类中；

--------------------------------------------------------------------------------

## 对象的声明周期

在 Rails 程序运行过程中，对象可以被创建、更新和销毁。Active Record 为对象的生命周期提供了很多钩子，让你控制程序及其数据。

回调可以在对象的状态改变之前或之后触发指定的逻辑操作。

## 回调简介

回调是在对象生命周期的特定时刻执行的方法。回调方法可以在 Active Record 对象创建、保存、更新、删除、验证或从数据库中读出时执行。

### 注册回调

在使用回调之前，要先注册。回调方法的定义和普通的方法一样，然后使用类方法注册：

{:lang="ruby"}
~~~
class User < ActiveRecord::Base
  validates :login, :email, presence: true

  before_validation :ensure_login_has_a_value

  protected
    def ensure_login_has_a_value
      if login.nil?
        self.login = email unless email.blank?
      end
    end
end
~~~

这种类方法还可以接受一个代码块。如果操作可以使用一行代码表述，可以考虑使用代码块形式。

{:lang="ruby"}
~~~
class User < ActiveRecord::Base
  validates :login, :email, presence: true

  before_create do
    self.name = login.capitalize if name.blank?
  end
end
~~~

注册回调时可以指定只在对象生命周期的特定事件发生时执行：

{:lang="ruby"}
~~~
class User < ActiveRecord::Base
  before_validation :normalize_name, on: :create

  # :on takes an array as well
  after_validation :set_location, on: [ :create, :update ]

  protected
    def normalize_name
      self.name = self.name.downcase.titleize
    end

    def set_location
      self.location = LocationService.query(self)
    end
end
~~~

一般情况下，都把回调方法定义为受保护的方法或私有方法。如果定义成公共方法，回调就可以在模型外部调用，违背了对象封装原则。

## 可用的回调

下面列出了所有可用的 Active Record 回调，按照执行各操作时触发的顺序：

### 创建对象

* `before_validation`
* `after_validation`
* `before_save`
* `around_save`
* `before_create`
* `around_create`
* `after_create`
* `after_save`

### 更新对象

* `before_validation`
* `after_validation`
* `before_save`
* `around_save`
* `before_update`
* `around_update`
* `after_update`
* `after_save`

### 销毁对象

* `before_destroy`
* `around_destroy`
* `after_destroy`

W> 创建和更新对象时都会触发 `after_save`，但不管注册的顺序，总在 `after_create` 和 `after_update` 之后执行。

### `after_initialize` 和 `after_find`

`after_initialize` 回调在 Active Record 对象初始化时执行，包括直接使用 `new` 方法初始化和从数据库中读取记录。`after_initialize` 回调不用直接重定义 Active Record 的 `initialize` 方法。

`after_find` 回调在从数据库中读取记录时执行。如果同时注册了 `after_find` 和 `after_initialize` 回调，`after_find` 会先执行。

`after_initialize` 和 `after_find` 没有对应的 `before_*` 回调，但可以像其他回调一样注册。

{:lang="ruby"}
~~~
class User < ActiveRecord::Base
  after_initialize do |user|
    puts "You have initialized an object!"
  end

  after_find do |user|
    puts "You have found an object!"
  end
end

>> User.new
You have initialized an object!
=> #<User id: nil>

>> User.first
You have found an object!
You have initialized an object!
=> #<User id: 1>
~~~

### `after_touch`

`after_touch` 回调在触碰 Active Record 对象时执行。

{:lang="ruby"}
~~~
class User < ActiveRecord::Base
  after_touch do |user|
    puts "You have touched an object"
  end
end

>> u = User.create(name: 'Kuldeep')
=> #<User id: 1, name: "Kuldeep", created_at: "2013-11-25 12:17:49", updated_at: "2013-11-25 12:17:49">

>> u.touch
You have touched an object
=> true
~~~

可以结合 `belongs_to` 一起使用：

{:lang="ruby"}
~~~
class Employee < ActiveRecord::Base
  belongs_to :company, touch: true
  after_touch do
    puts 'An Employee was touched'
  end
end

class Company < ActiveRecord::Base
  has_many :employees
  after_touch :log_when_employees_or_company_touched

  private
  def log_when_employees_or_company_touched
    puts 'Employee/Company was touched'
  end
end

>> @employee = Employee.last
=> #<Employee id: 1, company_id: 1, created_at: "2013-11-25 17:04:22", updated_at: "2013-11-25 17:05:05">

# triggers @employee.company.touch
>> @employee.touch
Employee/Company was touched
An Employee was touched
=> true
~~~

## 执行回调

下面的方法会触发执行回调：

* `create`
* `create!`
* `decrement!`
* `destroy`
* `destroy!`
* `destroy_all`
* `increment!`
* `save`
* `save!`
* `save(validate: false)`
* `toggle!`
* `update_attribute`
* `update`
* `update!`
* `valid?`

`after_find` 回调由以下查询方法触发执行：

* `all`
* `first`
* `find`
* `find_by`
* `find_by_*`
* `find_by_*!`
* `find_by_sql`
* `last`

`after_initialize` 回调在新对象初始化时触发执行。

I> `find_by_*` 和 `find_by_*!` 是为每个属性生成的动态查询方法，详情参见“[动态查询方法]({{ site.baseurl }}/active_record_querying.html#dynamic-finders)”一节。

## 跳过回调

和数据验证一样，回调也可跳过，使用下列方法即可：

* `decrement`
* `decrement_counter`
* `delete`
* `delete_all`
* `increment`
* `increment_counter`
* `toggle`
* `touch`
* `update_column`
* `update_columns`
* `update_all`
* `update_counters`

使用这些方法是要特别留心，因为重要的业务逻辑可能在回调中完成。如果没弄懂回调的作用直接跳过，可能导致数据不合法。

## 终止执行

在模型中注册回调后，回调会加入一个执行队列。这个队列中包含模型的数据验证，注册的回调，以及要执行的数据库操作。

整个回调链包含在一个事务中。如果任何一个 `before_*` 回调方法返回 `false` 或抛出异常，整个回调链都会终止执行，撤销事务；而 `after_*` 回调只有抛出异常才能达到相同的效果。

W> `ActiveRecord::Rollback` 之外的异常在回调链终止之后，还会由 Rails 再次抛出。抛出 `ActiveRecord::Rollback` 之外的异常，可能导致不应该抛出异常的方法（例如 `save` 和 `update_attributes`，应该返回 `true` 或 `false`）无法执行。

## 关联回调

回调能在模型关联中使用，甚至可由关联定义。假如一个用户发布了多篇文章，如果用户删除了，他发布的文章也应该删除。下面我们在 `Post` 模型中注册一个 `after_destroy` 回调，应用到 `User` 模型上：

{:lang="ruby"}
~~~
class User < ActiveRecord::Base
  has_many :posts, dependent: :destroy
end

class Post < ActiveRecord::Base
  after_destroy :log_destroy_action

  def log_destroy_action
    puts 'Post destroyed'
  end
end

>> user = User.first
=> #<User id: 1>
>> user.posts.create!
=> #<Post id: 1, user_id: 1>
>> user.destroy
Post destroyed
=> #<User id: 1>
~~~

## 条件回调

和数据验证类似，也可以在满足指定条件时再调用回调方法。条件通过 `:if` 和 `:unless` 选项指定，选项的值可以是 Symbol、字符串、`Proc` 或数组。`:if` 选项指定什么时候调用回调。如果要指定何时不调用回调，使用 `:unless` 选项。

### 使用 Symbol

:if 和 :unless 选项的值为 Symbol 时，表示要在调用回调之前执行对应的判断方法。使用 `:if` 选项时，如果判断方法返回 `false`，就不会调用回调；使用 `:unless` 选项时，如果判断方法返回 `true`，就不会调用回调。Symbol 是最常用的设置方式。使用这种方式注册回调时，可以使用多个判断方法检查是否要调用回调。

{:lang="ruby"}
~~~
class Order < ActiveRecord::Base
  before_save :normalize_card_number, if: :paid_with_card?
end
~~~

### 使用字符串

`:if` 和 `:unless` 选项的值还可以是字符串，但必须是 RUby 代码，传入 `eval` 方法中执行。当字符串表示的条件非常短时才应该是使用这种形式。

{:lang="ruby"}
~~~
class Order < ActiveRecord::Base
  before_save :normalize_card_number, if: "paid_with_card?"
end
~~~

### 使用 Proc

`:if` 和 `:unless` 选项的值还可以是 Proc 对象。这种形式最适合用在一行代码能表示的条件上。

{:lang="ruby"}
~~~
class Order < ActiveRecord::Base
  before_save :normalize_card_number,
    if: Proc.new { |order| order.paid_with_card? }
end
~~~

### 回调的多重条件

注册条件回调时，可以同时使用 `:if` 和 `:unless` 选项：

{:lang="ruby"}
~~~
class Comment < ActiveRecord::Base
  after_create :send_email_to_author, if: :author_wants_emails?,
    unless: Proc.new { |comment| comment.post.ignore_comments? }
end
~~~

## 回调类

有时回调方法可以在其他模型中重用，我们可以将其封装在类中。

在下面这个例子中，我们为 `PictureFile` 模型定义了一个 `after_destroy` 回调：

{:lang="ruby"}
~~~
class PictureFileCallbacks
  def after_destroy(picture_file)
    if File.exist?(picture_file.filepath)
      File.delete(picture_file.filepath)
    end
  end
end
~~~

在类中定义回调方法时（如上），可把模型对象作为参数传入。然后可以在模型中使用这个回调：

{:lang="ruby"}
~~~
class PictureFile < ActiveRecord::Base
  after_destroy PictureFileCallbacks.new
end
~~~

注意，因为回调方法被定义成实例方法，所以要实例化 `PictureFileCallbacks`。如果回调要使用实例化对象的状态，使用这种定义方式很有用。不过，一般情况下，定义为类方法更说得通：

{:lang="ruby"}
~~~
class PictureFileCallbacks
  def self.after_destroy(picture_file)
    if File.exist?(picture_file.filepath)
      File.delete(picture_file.filepath)
    end
  end
end
~~~

如果按照这种方式定义回调方法，就不用实例化 `PictureFileCallbacks`：

{:lang="ruby"}
~~~
class PictureFile < ActiveRecord::Base
  after_destroy PictureFileCallbacks
end
~~~

在回调类中可以定义任意数量的回调方法。

## 事务回调

还有两个回调会在数据库事务完成时触发：`after_commit` 和 `after_rollback`。这两个回调和 `after_save` 很像，只不过在数据库操作提交或回滚之前不会执行。如果模型要和数据库事务之外的系统交互，就可以使用这两个回调。

例如，在前面的例子中，`PictureFile` 模型中的记录删除后，还要删除相应的文件。如果执行 `after_destroy` 回调之后程序抛出了异常，事务就会回滚，文件会被删除，但模型的状态前后不一致。假设在下面的代码中，`picture_file_2` 是不合法的，那么调用 `save!` 方法会抛出异常。

{:lang="ruby"}
~~~
PictureFile.transaction do
  picture_file_1.destroy
  picture_file_2.save!
end
~~~

使用 `after_commit` 回调可以解决这个问题。

{:lang="ruby"}
~~~
class PictureFile < ActiveRecord::Base
  after_commit :delete_picture_file_from_disk, on: [:destroy]

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
~~~

I> `:on` 选项指定什么时候出发回调。如果不设置 `:on` 选项，每各个操作都会触发回调。

W> `after_commit` 和 `after_rollback` 回调确保模型的创建、更新和销毁等操作在事务中完成。如果这两个回调抛出了异常，会被忽略，因此不会干扰其他回调。因此，如果回调可能抛出异常，就要做适当的补救和处理。
