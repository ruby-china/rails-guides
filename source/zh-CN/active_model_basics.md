Active Model 基础
=================

本文简述模型类。Active Model 允许使用 Action Pack 辅助方法与普通的 Ruby 类交互。Active Model 还协助构建自定义的 ORM，可在 Rails 框架外部使用。

读完本文后，您将学到：

- Active Record 模型的行为；

- 回调和数据验证的工作方式；

- 序列化程序的工作方式；

- Active Model 与 Rails 国际化（i18n）框架的集成。

NOTE: 本文原文尚未完工！

简介
----

Active Model 库包含很多模块，用于开发要在 Active Record 中存储的类。下面说明其中部分模块。

### 属性方法

`ActiveModel::AttributeMethods` 模块可以为类中的方法添加自定义的前缀和后缀。它用于定义前缀和后缀，对象中的方法将使用它们。

```ruby
class Person
  include ActiveModel::AttributeMethods

  attribute_method_prefix 'reset_'
  attribute_method_suffix '_highest?'
  define_attribute_methods 'age'

  attr_accessor :age

  private
    def reset_attribute(attribute)
      send("#{attribute}=", 0)
    end

    def attribute_highest?(attribute)
      send(attribute) > 100
    end
end

person = Person.new
person.age = 110
person.age_highest?  # => true
person.reset_age     # => 0
person.age_highest?  # => false
```

### 回调

`ActiveModel::Callbacks` 模块为 Active Record 提供回调，在某个时刻运行。定义回调之后，可以使用前置、后置和环绕方法包装。

```ruby
class Person
  extend ActiveModel::Callbacks

  define_model_callbacks :update

  before_update :reset_me

  def update
    run_callbacks(:update) do
      # 在对象上调用 update 时执行这个方法
    end
  end

  def reset_me
    # 在对象上调用 update 方法时执行这个方法
    # 因为把它定义为 before_update 回调了
  end
end
```

### 转换

如果一个类定义了 `persisted?` 和 `id` 方法，可以在那个类中引入 `ActiveModel::Conversion` 模块，这样便能在类的对象上调用 Rails 提供的转换方法。

```ruby
class Person
  include ActiveModel::Conversion

  def persisted?
    false
  end

  def id
    nil
  end
end

person = Person.new
person.to_model == person  # => true
person.to_key              # => nil
person.to_param            # => nil
```

### 弄脏

如果修改了对象的一个或多个属性，但是没有保存，此时就把对象弄脏了。`ActiveModel::Dirty` 模块提供检查对象是否被修改的功能。它还提供了基于属性的存取方法。假如有个 `Person` 类，它有两个属性，`first_name` 和 `last_name`：

```ruby
class Person
  include ActiveModel::Dirty
  define_attribute_methods :first_name, :last_name

  def first_name
    @first_name
  end

  def first_name=(value)
    first_name_will_change!
    @first_name = value
  end

  def last_name
    @last_name
  end

  def last_name=(value)
    last_name_will_change!
    @last_name = value
  end

  def save
    # 执行保存操作……
    changes_applied
  end
end
```

#### 直接查询对象，获取所有被修改的属性列表

```ruby
person = Person.new
person.changed? # => false

person.first_name = "First Name"
person.first_name # => "First Name"

# 如果修改属性后未保存，返回 true，否则返回 false
person.changed? # => true

# 返回修改之后没有保存的属性列表
person.changed # => ["first_name"]

# 返回一个属性散列，指明原来的值
person.changed_attributes # => {"first_name"=>nil}

# 返回一个散列，键为修改的属性名，值是一个数组，包含旧值和新值
person.changes # => {"first_name"=>[nil, "First Name"]}
```

#### 基于属性的存取方法

判断具体的属性是否被修改了：

```ruby
# attr_name_changed?
person.first_name # => "First Name"
person.first_name_changed? # => true
```

查看属性之前的值：

```ruby
person.first_name_was # => nil
```

查看属性修改前后的值。如果修改了，返回一个数组，否则返回 `nil`：

```ruby
person.first_name_change # => [nil, "First Name"]
person.last_name_change # => nil
```

### 数据验证

`ActiveModel::Validations` 模块提供数据验证功能，这与 Active Record 中的类似。

```ruby
class Person
  include ActiveModel::Validations

  attr_accessor :name, :email, :token

  validates :name, presence: true
  validates_format_of :email, with: /\A([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})\z/i
  validates! :token, presence: true
end

person = Person.new
person.token = "2b1f325"
person.valid?                        # => false
person.name = 'vishnu'
person.email = 'me'
person.valid?                        # => false
person.email = 'me@vishnuatrai.com'
person.valid?                        # => true
person.token = nil
person.valid?                        # => raises ActiveModel::StrictValidationFailed
```

### 命名

`ActiveModel::Naming` 添加一些类方法，便于管理命名和路由。这个模块定义了 `model_name` 类方法，它使用 `ActiveSupport::Inflector` 中的一些方法定义一些存取方法。

```ruby
class Person
  extend ActiveModel::Naming
end

Person.model_name.name                # => "Person"
Person.model_name.singular            # => "person"
Person.model_name.plural              # => "people"
Person.model_name.element             # => "person"
Person.model_name.human               # => "Person"
Person.model_name.collection          # => "people"
Person.model_name.param_key           # => "person"
Person.model_name.i18n_key            # => :person
Person.model_name.route_key           # => "people"
Person.model_name.singular_route_key  # => "person"
```

### 模型

`ActiveModel::Model` 模块能让一个类立即能与 Action Pack 和 Action View 集成。

```ruby
class EmailContact
  include ActiveModel::Model

  attr_accessor :name, :email, :message
  validates :name, :email, :message, presence: true

  def deliver
    if valid?
      # 发送电子邮件
    end
  end
end
```

引入 `ActiveModel::Model` 后，将获得以下功能：

- 模型名称内省

- 转换

- 翻译

- 数据验证

还能像 Active Record 对象那样使用散列指定属性，初始化对象。

```ruby
email_contact = EmailContact.new(name: 'David',
                                 email: 'david@example.com',
                                 message: 'Hello World')
email_contact.name       # => 'David'
email_contact.email      # => 'david@example.com'
email_contact.valid?     # => true
email_contact.persisted? # => false
```

只要一个类引入了 `ActiveModel::Model`，它就能像 Active Record 对象那样使用 `form_for`、`render` 和任何 Action View 辅助方法。

### 序列化

`ActiveModel::Serialization` 模块为对象提供基本的序列化支持。你要定义一个属性散列，包含想序列化的属性。属性名必须使用字符串，不能使用符号。

```ruby
class Person
  include ActiveModel::Serialization

  attr_accessor :name

  def attributes
    {'name' => nil}
  end
end
```

这样就可以使用 `serializable_hash` 方法访问对象的序列化散列：

```ruby
person = Person.new
person.serializable_hash   # => {"name"=>nil}
person.name = "Bob"
person.serializable_hash   # => {"name"=>"Bob"}
```

#### `ActiveModel::Serializers`

Rails 提供了 `ActiveModel::Serializers::JSON` 序列化程序。这个模块自动引入 `ActiveModel::Serialization`。

##### `ActiveModel::Serializers::JSON`

若想使用 `ActiveModel::Serializers::JSON`，只需把 `ActiveModel::Serialization` 换成 `ActiveModel::Serializers::JSON`。

```ruby
class Person
  include ActiveModel::Serializers::JSON

  attr_accessor :name

  def attributes
    {'name' => nil}
  end
end
```

调用 `as_json` 方法即可访问模型的散列表示形式。

```ruby
person = Person.new
person.as_json # => {"name"=>nil}
person.name = "Bob"
person.as_json # => {"name"=>"Bob"}
```

若想使用 JSON 字符串定义模型的属性，要在类中定义 `attributes=` 方法：

```ruby
class Person
  include ActiveModel::Serializers::JSON

  attr_accessor :name

  def attributes=(hash)
    hash.each do |key, value|
      send("#{key}=", value)
    end
  end

  def attributes
    {'name' => nil}
  end
end
```

现在，可以使用 `from_json` 方法创建 `Person` 实例，并且设定属性：

```ruby
json = { name: 'Bob' }.to_json
person = Person.new
person.from_json(json) # => #<Person:0x00000100c773f0 @name="Bob">
person.name            # => "Bob"
```

### 翻译

`ActiveModel::Translation` 模块把对象与 Rails 国际化（i18n）框架集成起来。

```ruby
class Person
  extend ActiveModel::Translation
end
```

使用 `human_attribute_name` 方法可以把属性名称变成对人类友好的格式。对人类友好的格式在本地化文件中定义。

- `config/locales/app.pt-BR.yml`

    ``` ruby
    pt-BR:
      activemodel:
        attributes:
          person:
            name: 'Nome'
    ```

```ruby
Person.human_attribute_name('name') # => "Nome"
```

### lint 测试

`ActiveModel::Lint::Tests` 模块测试对象是否符合 Active Model API。

- `app/models/person.rb`

    ``` ruby
    class Person
      include ActiveModel::Model
    end
    ```

- `test/models/person_test.rb`

    ``` ruby
    require 'test_helper'

    class PersonTest < ActiveSupport::TestCase
      include ActiveModel::Lint::Tests

      setup do
        @model = Person.new
      end
    end
    ```

```sh
$ rails test

Run options: --seed 14596

# Running:

......

Finished in 0.024899s, 240.9735 runs/s, 1204.8677 assertions/s.

6 runs, 30 assertions, 0 failures, 0 errors, 0 skips
```

为了使用 Action Pack，对象无需实现所有 API。这个模块只是提供一种指导，以防你需要全部功能。

### 安全密码

`ActiveModel::SecurePassword` 提供安全加密密码的功能。这个模块提供了 `has_secure_password` 类方法，它定义了一个名为 `password` 的存取方法，而且有相应的数据验证。

#### 要求

`ActiveModel::SecurePassword` 依赖 [bcrypt](https://github.com/codahale/bcrypt-ruby)，因此要在 `Gemfile` 中加入这个 gem，`ActiveModel::SecurePassword` 才能正确运行。为了使用安全密码，模型中必须定义一个名为 `password_digest` 的存取方法。`has_secure_password` 类方法会为 `password` 存取方法添加下述数据验证：

1.  密码应该存在

2.  密码应该等于密码确认

3.  密码的最大长度为 72（`ActiveModel::SecurePassword` 依赖的 `bcrypt` 的要求）

#### 示例

```ruby
class Person
  include ActiveModel::SecurePassword
  has_secure_password
  attr_accessor :password_digest
end

person = Person.new

# 密码为空时
person.valid? # => false

# 密码确认与密码不匹配时
person.password = 'aditya'
person.password_confirmation = 'nomatch'
person.valid? # => false

# 密码长度超过 72 时
person.password = person.password_confirmation = 'a' * 100
person.valid? # => false

# 所有数据验证都通过时
person.password = person.password_confirmation = 'aditya'
person.valid? # => true
```
