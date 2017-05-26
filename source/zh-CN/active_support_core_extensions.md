# Active Support 核心扩展

Active Support 是 Ruby on Rails 的一个组件，扩展了 Ruby 语言，提供了一些实用功能。

Active Support 丰富了 Rails 使用的编程语言，目的是便于开发 Rails 应用以及 Rails 本身。

读完本文后，您将学到：

*   核心扩展是什么；
*   如何加载所有扩展；
*   如何按需加载想用的扩展；
*   Active Support 提供了哪些扩展。

-----------------------------------------------------------------------------

<a class="anchor" id="how-to-load-core-extensions"></a>

## 如何加载核心扩展

<a class="anchor" id="stand-alone-active-support"></a>

### 独立的 Active Support

为了减轻应用的负担，默认情况下 Active Support 不会加载任何功能。Active Support 中的各部分功能是相对独立的，可以只加载需要的功能，也可以方便地加载相互联系的功能，或者加载全部功能。

因此，只编写下面这个 `require` 语句，对象甚至无法响应 `blank?` 方法：

```ruby
require 'active_support'
```

我们来看一下到底应该如何加载。

<a class="anchor" id="cherry-picking-a-definition"></a>

#### 按需加载

获取 `blank?` 方法最轻便的做法是按需加载其定义所在的文件。

本文为核心扩展中的每个方法都做了说明，告知是在哪个文件中定义的。对 `blank?` 方法而言，说明如下：

NOTE: 在 `active_support/core_ext/object/blank.rb` 文件中定义。

因此 `blank?` 方法要这么加载：

```ruby
require 'active_support'
require 'active_support/core_ext/object/blank'
```

Active Support 的设计方式精良，确保按需加载时真的只加载所需的扩展。

<a class="anchor" id="loading-grouped-core-extensions"></a>

#### 成组加载核心扩展

下一层级是加载 `Object` 对象的所有扩展。一般来说，对 `SomeClass` 的扩展都保存在 `active_support/core_ext/some_class` 文件夹中。

因此，加载 `Object` 对象的所有扩展（包括 `balnk?` 方法）可以这么做：

```ruby
require 'active_support'
require 'active_support/core_ext/object'
```

<a class="anchor" id="loading-all-core-extensions"></a>

#### 加载所有扩展

如果想加载所有核心扩展，可以这么做：

```ruby
require 'active_support'
require 'active_support/core_ext'
```

<a class="anchor" id="loading-all-active-support"></a>

#### 加载 Active Support 提供的所有功能

最后，如果想使用 Active Support 提供的所有功能，可以这么做：

```ruby
require 'active_support/all'
```

其实，这么做并不会把整个 Active Support 载入内存，有些功能通过 `autoload` 加载，所以真正使用时才会加载。

<a class="anchor" id="active-support-within-a-ruby-on-rails-application"></a>

### 在 Rails 应用中使用 Active Support

除非把 `config.active_support.bare` 设为 `true`，否则 Rails 应用不会加载 Active Support 提供的所有功能。即便全部加载，应用也会根据框架的设置按需加载所需功能，而且应用开发者还可以根据需要做更细化的选择，方法如前文所述。

<a class="anchor" id="extensions-to-all-objects"></a>

## 所有对象皆可使用的扩展

<a class="anchor" id="blank-questionmark-and-present-questionmark"></a>

### `blank?` 和 `present?`

在 Rails 应用中，下面这些值表示空值：

*   `nil` 和 `false`；
*   只有空白的字符串（注意下面的说明）；
*   空数组和空散列；
*   其他能响应 `empty?` 方法，而且返回值为 `true` 的对象；

TIP: 判断字符串是否为空使用的是能理解 Unicode 字符的 `[:space:]`，所以 `U+2029`（分段符）会被视为空白。

WARNING: 注意，这里并没有提到数字。特别说明，`0` 和 `0.0` 不是空值。

例如，`ActionController::HttpAuthentication::Token::ControllerMethods` 定义的这个方法使用 `blank?` 检查是否有令牌：

```ruby
def authenticate(controller, &login_procedure)
  token, options = token_and_options(controller.request)
  unless token.blank?
    login_procedure.call(token, options)
  end
end
```

`present?` 方法等价于 `!blank?`。下面这个方法摘自 `ActionDispatch::Http::Cache::Response`：

```ruby
def set_conditional_cache_control!
  return if self["Cache-Control"].present?
  ...
end
```

NOTE: 在 `active_support/core_ext/object/blank.rb` 文件中定义。

<a class="anchor" id="presence"></a>

### `presence`

如果 `present?` 方法返回 `true`，`presence` 方法的返回值为调用对象，否则返回 `nil`。惯用法如下：

```ruby
host = config[:host].presence || 'localhost'
```

NOTE: 在 `active_support/core_ext/object/blank.rb` 文件中定义。

<a class="anchor" id="duplicable-questionmark"></a>

### `duplicable?`

Ruby 中很多基本的对象是单例。例如，在应用的整个生命周期内，整数 1 始终表示同一个实例：

```ruby
1.object_id                 # => 3
Math.cos(0).to_i.object_id  # => 3
```

因此，这些对象无法通过 `dup` 或 `clone` 方法复制：

```ruby
true.dup  # => TypeError: can't dup TrueClass
```

有些数字虽然不是单例，但也不能复制：

```ruby
0.0.clone        # => allocator undefined for Float
(2**1024).clone  # => allocator undefined for Bignum
```

Active Support 提供的 `duplicable?` 方法用于查询对象是否可以复制：

```ruby
"foo".duplicable? # => true
"".duplicable?    # => true
0.0.duplicable?   # => false
false.duplicable? # => false
```

按照定义，除了 `nil`、`false`、`true`、符号、数字、类、模块和方法对象之外，其他对象都可以复制。

WARNING: 任何类都可以禁止对象复制，只需删除 `dup` 和 `clone` 两个方法，或者在这两个方法中抛出异常。因此只能在 `rescue` 语句中判断对象是否可复制。`duplicable?` 方法直接检查对象是否在上述列表中，因此比 `rescue` 的速度快。仅当你知道上述列表能满足需求时才应该使用 `duplicable?` 方法。

NOTE: 在 `active_support/core_ext/object/duplicable.rb` 文件中定义。

<a class="anchor" id="deep-dup"></a>

### `deep_dup`

`deep_dup` 方法深拷贝指定的对象。一般情况下，复制包含其他对象的对象时，Ruby 不会复制内部对象，这叫做浅拷贝。假如有一个由字符串组成的数组，浅拷贝的行为如下：

```ruby
array     = ['string']
duplicate = array.dup

duplicate.push 'another-string'

# 创建了对象副本，因此元素只添加到副本中
array     # => ['string']
duplicate # => ['string', 'another-string']

duplicate.first.gsub!('string', 'foo')

# 第一个元素没有副本，因此两个数组都会变
array     # => ['foo']
duplicate # => ['foo', 'another-string']
```

如上所示，复制数组后得到了一个新对象，修改新对象后原对象没有变化。但对数组中的元素来说情况就不一样了。因为 `dup` 方法不是深拷贝，所以数组中的字符串是同一个对象。

如果想深拷贝一个对象，应该使用 `deep_dup` 方法。举个例子：

```ruby
array     = ['string']
duplicate = array.deep_dup

duplicate.first.gsub!('string', 'foo')

array     # => ['string']
duplicate # => ['foo']
```

如果对象不可复制，`deep_dup` 方法直接返回对象本身：

```ruby
number = 1
duplicate = number.deep_dup
number.object_id == duplicate.object_id   # => true
```

NOTE: 在 `active_support/core_ext/object/deep_dup.rb` 文件中定义。

<a class="anchor" id="try"></a>

### `try`

如果只想当对象不为 `nil` 时在其上调用方法，最简单的方式是使用条件语句，但这么做把代码变复杂了。你可以使用 `try` 方法。`try` 方法和 `Object#send` 方法类似，但如果在 `nil` 上调用，返回值为 `nil`。

举个例子：

```ruby
# 不使用 try
unless @number.nil?
  @number.next
end

# 使用 try
@number.try(:next)
```

下面这个例子摘自 `ActiveRecord::ConnectionAdapters::AbstractAdapter`，实例变量 `@logger` 有可能为 `nil`。可以看出，使用 `try` 方法可以避免不必要的检查。

```ruby
def log_info(sql, name, ms)
  if @logger.try(:debug?)
    name = '%s (%.1fms)' % [name || 'SQL', ms]
    @logger.debug(format_log_entry(name, sql.squeeze(' ')))
  end
end
```

`try` 方法也可接受代码块，仅当对象不为 `nil` 时才会执行其中的代码：

```ruby
@person.try { |p| "#{p.first_name} #{p.last_name}" }
```

注意，`try` 会吞没没有方法错误，返回 `nil`。如果想避免此类问题，应该使用 `try!`：

```ruby
@number.try(:nest)  # => nil
@number.try!(:nest) # NoMethodError: undefined method `nest' for 1:Integer
```

NOTE: 在 `active_support/core_ext/object/try.rb` 文件中定义。

<a class="anchor" id="class-eval-args-block"></a>

### `class_eval(*args, &block)`

使用 `class_eval` 方法可以在对象的单例类上下文中执行代码：

```ruby
class Proc
  def bind(object)
    block, time = self, Time.current
    object.class_eval do
      method_name = "__bind_#{time.to_i}_#{time.usec}"
      define_method(method_name, &block)
      method = instance_method(method_name)
      remove_method(method_name)
      method
    end.bind(object)
  end
end
```

NOTE: 在 `active_support/core_ext/kernel/singleton_class.rb` 文件中定义。

<a class="anchor" id="acts-like-questionmark-duck"></a>

### `acts_like?(duck)`

`acts_like?` 方法检查一个类的行为是否与另一个类相似。比较是基于一个简单的约定：如果在某个类中定义了下面这个方法，就说明其接口与字符串一样。

```ruby
def acts_like_string?
end
```

这个方法只是一个标记，其定义体和返回值不影响效果。开发者可使用下面这种方式判断两个类的表现是否类似：

```ruby
some_klass.acts_like?(:string)
```

Rails 使用这种约定定义了行为与 `Date` 和 `Time` 相似的类。

NOTE: 在 `active_support/core_ext/object/acts_like.rb` 文件中定义。

<a class="anchor" id="to-param"></a>

### `to_param`

Rails 中的所有对象都能响应 `to_param` 方法。`to_param` 方法的返回值表示查询字符串的值，或者 URL 片段。

默认情况下，`to_param` 方法直接调用 `to_s` 方法：

```ruby
7.to_param # => "7"
```

`to_param` 方法的返回值**不应该**转义：

```ruby
"Tom & Jerry".to_param # => "Tom & Jerry"
```

Rails 中的很多类都覆盖了这个方法。

例如，`nil`、`true` 和 `false` 返回自身。`Array#to_param` 在各个元素上调用 `to_param` 方法，然后使用 `"/"` 合并：

```ruby
[0, true, String].to_param # => "0/true/String"
```

注意，Rails 的路由系统在模型上调用 `to_param` 方法获取占位符 `:id` 的值。`ActiveRecord::Base#to_param` 返回模型的 `id`，不过可以在模型中重新定义。例如，按照下面的方式重新定义：

```ruby
class User
  def to_param
    "#{id}-#{name.parameterize}"
  end
end
```

效果如下：

```ruby
user_path(@user) # => "/users/357-john-smith"
```

WARNING: 应该让控制器知道重新定义了 `to_param` 方法，因为接收到上面这种请求后，`params[:id]` 的值为 `"357-john-smith"`。

NOTE: 在 `active_support/core_ext/object/to_param.rb` 文件中定义。

<a class="anchor" id="to-query"></a>

### `to_query`

除散列之外，传入未转义的 `key`，`to_query` 方法把 `to_param` 方法的返回值赋值给 `key`，组成查询字符串。例如，重新定义了 `to_param` 方法：

```ruby
class User
  def to_param
    "#{id}-#{name.parameterize}"
  end
end
```

效果如下：

```ruby
current_user.to_query('user') # => user=357-john-smith
```

`to_query` 方法会根据需要转义键和值：

```ruby
account.to_query('company[name]')
# => "company%5Bname%5D=Johnson+%26+Johnson"
```

因此得到的值可以作为查询字符串使用。

`Array#to_query` 方法在各个元素上调用 `to_query` 方法，键为 `key[]`，然后使用 `"&"` 合并：

```ruby
[3.4, -45.6].to_query('sample')
# => "sample%5B%5D=3.4&sample%5B%5D=-45.6"
```

散列也响应 `to_query` 方法，但处理方式不一样。如果不传入参数，先在各个元素上调用 `to_query(key)`，得到一系列键值对赋值字符串，然后按照键的顺序排列，再使用 `"&"` 合并：

```ruby
{c: 3, b: 2, a: 1}.to_query # => "a=1&b=2&c=3"
```

`Hash#to_query` 方法还有一个可选参数，用于指定键的命名空间：

```rb
{id: 89, name: "John Smith"}.to_query('user')
# => "user%5Bid%5D=89&user%5Bname%5D=John+Smith"
```

NOTE: 在 `active_support/core_ext/object/to_query.rb` 文件中定义。

<a class="anchor" id="with-options"></a>

### `with_options`

`with_options` 方法把一系列方法调用中的通用选项提取出来。

使用散列指定通用选项后，`with_options` 方法会把一个代理对象拽入代码块。在代码块中，代理对象调用的方法会转发给调用者，并合并选项。例如，如下的代码

```ruby
class Account < ApplicationRecord
  has_many :customers, dependent: :destroy
  has_many :products,  dependent: :destroy
  has_many :invoices,  dependent: :destroy
  has_many :expenses,  dependent: :destroy
end
```

其中的重复可以使用 `with_options` 方法去除：

```ruby
class Account < ApplicationRecord
  with_options dependent: :destroy do |assoc|
    assoc.has_many :customers
    assoc.has_many :products
    assoc.has_many :invoices
    assoc.has_many :expenses
  end
end
```

这种用法还可形成一种分组方式。假如想根据用户使用的语言发送不同的电子报，在邮件发送程序中可以根据用户的区域设置分组：

```ruby
I18n.with_options locale: user.locale, scope: "newsletter" do |i18n|
  subject i18n.t :subject
  body    i18n.t :body, user_name: user.name
end
```

TIP: `with_options` 方法会把方法调用转发给调用者，因此可以嵌套使用。每层嵌套都会合并上一层的选项。

NOTE: 在 `active_support/core_ext/object/with_options.rb` 文件中定义。

<a class="anchor" id="json-support"></a>

### 对 JSON 的支持

Active Support 实现的 `to_json` 方法比 `json` gem 更好用，这是因为 `Hash`、`OrderedHash` 和 `Process::Status` 等类转换成 JSON 时要做特别处理。

NOTE: 在 `active_support/core_ext/object/json.rb` 文件中定义。

<a class="anchor" id="instance-variables"></a>

### 实例变量

Active Support 提供了很多便于访问实例变量的方法。

<a class="anchor" id="instance-values"></a>

#### `instance_values`

`instance_values` 方法返回一个散列，把实例变量的名称（不含前面的 `@` 符号）映射到其值上，键是字符串：

```ruby
class C
  def initialize(x, y)
    @x, @y = x, y
  end
end

C.new(0, 1).instance_values # => {"x" => 0, "y" => 1}
```

NOTE: 在 `active_support/core_ext/object/instance_variables.rb` 文件中定义。

<a class="anchor" id="instance-variable-names"></a>

#### `instance_variable_names`

`instance_variable_names` 方法返回一个数组，实例变量的名称前面包含 `@` 符号。

```ruby
class C
  def initialize(x, y)
    @x, @y = x, y
  end
end

C.new(0, 1).instance_variable_names # => ["@x", "@y"]
```

NOTE: 在 `active_support/core_ext/object/instance_variables.rb` 文件中定义。

<a class="anchor" id="silencing-warnings-and-exceptions"></a>

### 静默警告和异常

`silence_warnings` 和 `enable_warnings` 方法修改各自代码块的 `$VERBOSE` 全局变量，代码块结束后恢复原值：

```ruby
silence_warnings { Object.const_set "RAILS_DEFAULT_LOGGER", logger }
```

异常消息也可静默，使用 `suppress` 方法即可。`suppress` 方法可接受任意个异常类。如果执行代码块的过程中抛出异常，而且异常属于（`kind_of?`）参数指定的类，`suppress` 方法会静默该异常类的消息，否则抛出异常：

```ruby
# 如果用户锁定了，访问次数不增加也没关系
suppress(ActiveRecord::StaleObjectError) do
  current_user.increment! :visits
end
```

NOTE: 在 `active_support/core_ext/kernel/reporting.rb` 文件中定义。

<a class="anchor" id="in-questionmark"></a>

### `in?`

`in?` 方法测试某个对象是否在另一个对象中。如果传入的对象不能响应 `include?` 方法，抛出 `ArgumentError` 异常。

`in?` 方法使用举例：

```ruby
1.in?([1,2])        # => true
"lo".in?("hello")   # => true
25.in?(30..50)      # => false
1.in?(1)            # => ArgumentError
```

NOTE: 在 `active_support/core_ext/object/inclusion.rb` 文件中定义。

<a class="anchor" id="extensions-to-module"></a>

## `Module` 的扩展

<a class="anchor" id="attributes"></a>

### 属性

<a class="anchor" id="alias-attribute"></a>

#### `alias_attribute`

模型的属性有读值方法、设值方法和判断方法。`alias_attribute` 方法可以一次性为这三种方法创建别名。和其他创建别名的方法一样，`alias_attribute` 方法的第一个参数是新属性名，第二个参数是旧属性名（我是这样记的，参数的顺序和赋值语句一样）：

```ruby
class User < ApplicationRecord
  # 可以使用 login 指代 email 列
  # 在身份验证代码中可以这样做
  alias_attribute :login, :email
end
```

NOTE: 在 `active_support/core_ext/module/aliasing.rb` 文件中定义。

<a class="anchor" id="internal-attributes"></a>

#### 内部属性

如果在父类中定义属性，有可能会出现命名冲突。代码库一定要注意这个问题。

Active Support 提供了 `attr_internal_reader`、`attr_internal_writer` 和 `attr_internal_accessor` 三个方法，其行为与 Ruby 内置的 `attr_*` 方法类似，但使用其他方式命名实例变量，从而减少重名的几率。

`attr_internal` 方法是 `attr_internal_accessor` 方法的别名：

```ruby
# 库
class ThirdPartyLibrary::Crawler
  attr_internal :log_level
end

# 客户代码
class MyCrawler < ThirdPartyLibrary::Crawler
  attr_accessor :log_level
end
```

在上面的例子中，`:log_level` 可能不属于代码库的公开接口，只在开发过程中使用。开发者并不知道潜在的重名风险，创建了子类，并在子类中定义了 `:log_level`。幸好用了 `attr_internal` 方法才不会出现命名冲突。

默认情况下，内部变量的名字前面有个下划线，上例中的内部变量名为 `@_log_level`。不过可使用 `Module.attr_internal_naming_format` 重新设置，可以传入任何 `sprintf` 方法能理解的格式，开头加上 `@` 符号，并在某处放入 `%s`（代表原变量名）。默认的设置为 `"@_%s"`。

Rails 的代码很多地方都用到了内部属性，例如，在视图相关的代码中有如下代码：

```ruby
module ActionView
  class Base
    attr_internal :captures
    attr_internal :request, :layout
    attr_internal :controller, :template
  end
end
```

NOTE: 在 `active_support/core_ext/module/attr_internal.rb` 文件中定义。

<a class="anchor" id="module-attributes"></a>

#### 模块属性

方法 `mattr_reader`、`mattr_writer` 和 `mattr_accessor` 类似于为类定义的 `cattr_*` 方法。其实 `cattr_*` 方法就是 `mattr_*` 方法的别名。参见 [类属性](#class-attributes)。

例如，依赖机制就用到了这些方法：

```ruby
module ActiveSupport
  module Dependencies
    mattr_accessor :warnings_on_first_load
    mattr_accessor :history
    mattr_accessor :loaded
    mattr_accessor :mechanism
    mattr_accessor :load_paths
    mattr_accessor :load_once_paths
    mattr_accessor :autoloaded_constants
    mattr_accessor :explicitly_unloadable_constants
    mattr_accessor :constant_watch_stack
    mattr_accessor :constant_watch_stack_mutex
  end
end
```

NOTE: 在 `active_support/core_ext/module/attribute_accessors.rb` 文件中定义。

<a class="anchor" id="extensions-to-module-parents"></a>

### 父级

<a class="anchor" id="parent"></a>

#### `parent`

在嵌套的具名模块上调用 `parent` 方法，返回包含对应常量的模块：

```ruby
module X
  module Y
    module Z
    end
  end
end
M = X::Y::Z

X::Y::Z.parent # => X::Y
M.parent       # => X::Y
```

如果是匿名模块或者位于顶层，`parent` 方法返回 `Object`。

WARNING: 此时，`parent_name` 方法返回 `nil`。

NOTE: 在 `active_support/core_ext/module/introspection.rb` 文件中定义。

<a class="anchor" id="parent-name"></a>

#### `parent_name`

在嵌套的具名模块上调用 `parent_name` 方法，返回包含对应常量的完全限定模块名：

```ruby
module X
  module Y
    module Z
    end
  end
end
M = X::Y::Z

X::Y::Z.parent_name # => "X::Y"
M.parent_name       # => "X::Y"
```

如果是匿名模块或者位于顶层，`parent_name` 方法返回 `nil`。

WARNING: 注意，此时 `parent` 方法返回 `Object`。

NOTE: 在 `active_support/core_ext/module/introspection.rb` 文件中定义。

<a class="anchor" id="extensions-to-module-parents-parents"></a>

#### `parents`

`parents` 方法在调用者上调用 `parent` 方法，直至 `Object` 为止。返回的结果是一个数组，由底而上：

```ruby
module X
  module Y
    module Z
    end
  end
end
M = X::Y::Z

X::Y::Z.parents # => [X::Y, X, Object]
M.parents       # => [X::Y, X, Object]
```

NOTE: 在 `active_support/core_ext/module/introspection.rb` 文件中定义。

<a class="anchor" id="reachable"></a>

### 可达性

如果把具名模块存储在相应的常量中，模块是可达的，意即可以通过常量访问模块对象。

通常，模块都是如此。如果有名为“M”的模块，`M` 常量就存在，指代那个模块：

```ruby
module M
end

M.reachable? # => true
```

但是，常量和模块其实是解耦的，因此模块对象也许不可达：

```ruby
module M
end

orphan = Object.send(:remove_const, :M)

# 现在模块对象是孤儿，但它仍有名称
orphan.name # => "M"

# 不能通过常量 M 访问，因为这个常量不存在
orphan.reachable? # => false

# 再定义一个名为“M”的模块
module M
end

# 现在常量 M 存在了，而且存储名为“M”的常量对象
# 但这是一个新实例
orphan.reachable? # => false
```

NOTE: 在 `active_support/core_ext/module/reachable.rb` 文件中定义。

<a class="anchor" id="anonymous"></a>

### 匿名

模块可能有也可能没有名称：

```ruby
module M
end
M.name # => "M"

N = Module.new
N.name # => "N"

Module.new.name # => nil
```

可以使用 `anonymous?` 方法判断模块有没有名称：

```ruby
module M
end
M.anonymous? # => false

Module.new.anonymous? # => true
```

注意，不可达不意味着就是匿名的：

```ruby
module M
end

m = Object.send(:remove_const, :M)

m.reachable? # => false
m.anonymous? # => false
```

但是按照定义，匿名模块是不可达的。

NOTE: 在 `active_support/core_ext/module/anonymous.rb` 文件中定义。

<a class="anchor" id="method-delegation"></a>

### 方法委托

`delegate` 方法提供一种便利的方法转发方式。

假设在一个应用中，用户的登录信息存储在 `User` 模型中，而名字和其他数据存储在 `Profile` 模型中：

```ruby
class User < ApplicationRecord
  has_one :profile
end
```

此时，要通过个人资料获取用户的名字，即 `user.profile.name`。不过，若能直接访问这些信息更为便利：

```ruby
class User < ApplicationRecord
  has_one :profile

  def name
    profile.name
  end
end
```

`delegate` 方法正是为这种需求而生的：

```ruby
class User < ApplicationRecord
  has_one :profile

  delegate :name, to: :profile
end
```

这样写出的代码更简洁，而且意图更明显。

委托的方法在目标中必须是公开的。

`delegate` 方法可接受多个参数，委托多个方法：

```ruby
delegate :name, :age, :address, :twitter, to: :profile
```

内插到字符串中时，`:to` 选项的值应该能求值为方法委托的对象。通常，使用字符串或符号。这个选项的值在接收者的上下文中求值：

```ruby
# 委托给 Rails 常量
delegate :logger, to: :Rails

# 委托给接收者所属的类
delegate :table_name, to: :class
```

WARNING: 如果 `:prefix` 选项的值为 `true`，不能这么做。参见下文。

默认情况下，如果委托导致 `NoMethodError` 抛出，而且目标是 `nil`，这个异常会向上冒泡。可以指定 `:allow_nil` 选项，遇到这种情况时返回 `nil`：

```ruby
delegate :name, to: :profile, allow_nil: true
```

设定 `:allow_nil` 选项后，如果用户没有个人资料，`user.name` 返回 `nil`。

`:prefix` 选项在生成的方法前面添加一个前缀。如果想起个更好的名称，就可以使用这个选项：

```ruby
delegate :street, to: :address, prefix: true
```

上述示例生成的方法是 `address_street`，而不是 `street`。

WARNING: 此时，生成的方法名由目标对象和目标方法的名称构成，因此 `:to` 选项必须是一个方法名。

此外，还可以自定义前缀：

```ruby
delegate :size, to: :attachment, prefix: :avatar
```

在这个示例中，生成的方法是 `avatar_size`，而不是 `size`。

NOTE: 在 `active_support/core_ext/module/delegation.rb` 文件中定义。

<a class="anchor" id="redefining-methods"></a>

### 重新定义方法

有时需要使用 `define_method` 定义方法，但却不知道那个方法名是否已经存在。如果存在，而且启用了警告消息，会发出警告。这没什么，但却不够利落。

`redefine_method` 方法能避免这种警告，如果需要，会把现有的方法删除。

NOTE: 在 `active_support/core_ext/module/remove_method.rb` 文件中定义。

<a class="anchor" id="extensions-to-class"></a>

## `Class` 的扩展

<a class="anchor" id="class-attributes"></a>

### 类属性

<a class="anchor" id="class-attribute"></a>

#### `class_attribute`

`class_attribute` 方法声明一个或多个可继承的类属性，它们可以在继承树的任一层级覆盖。

```ruby
class A
  class_attribute :x
end

class B < A; end

class C < B; end

A.x = :a
B.x # => :a
C.x # => :a

B.x = :b
A.x # => :a
C.x # => :b

C.x = :c
A.x # => :a
B.x # => :b
```

例如，`ActionMailer::Base` 定义了：

```ruby
class_attribute :default_params
self.default_params = {
  mime_version: "1.0",
  charset: "UTF-8",
  content_type: "text/plain",
  parts_order: [ "text/plain", "text/enriched", "text/html" ]
}.freeze
```

类属性还可以通过实例访问和覆盖：

```ruby
A.x = 1

a1 = A.new
a2 = A.new
a2.x = 2

a1.x # => 1, comes from A
a2.x # => 2, overridden in a2
```

把 `:instance_writer` 选项设为 `false`，不生成设值实例方法：

```ruby
module ActiveRecord
  class Base
    class_attribute :table_name_prefix, instance_writer: false
    self.table_name_prefix = ""
  end
end
```

模型可以使用这个选项，禁止批量赋值属性。

把 `:instance_reader` 选项设为 `false`，不生成读值实例方法：

```ruby
class A
  class_attribute :x, instance_reader: false
end

A.new.x = 1
A.new.x # NoMethodError
```

为了方便，`class_attribute` 还会定义实例判断方法，对实例读值方法的返回值做双重否定。在上例中，判断方法是 `x?`。

如果 `:instance_reader` 的值是 `false`，实例判断方法与读值方法一样，返回 `NoMethodError`。

如果不想要实例判断方法，传入 `instance_predicate: false`，这样就不会定义了。

NOTE: 在 `active_support/core_ext/class/attribute.rb` 文件中定义。

<a class="anchor" id="cattr-reader-cattr-writer-and-cattr-accessor"></a>

#### `cattr_reader`、`cattr_writer` 和 `cattr_accessor`

`cattr_reader`、`cattr_writer` 和 `cattr_accessor` 的作用与相应的 `attr_*` 方法类似，不过是针对类的。它们声明的类属性，初始值为 `nil`，除非在此之前类属性已经存在，而且会生成相应的访问方法：

```ruby
class MysqlAdapter < AbstractAdapter
  # 生成访问 @@emulate_booleans 的类方法
  cattr_accessor :emulate_booleans
  self.emulate_booleans = true
end
```

为了方便，也会生成实例方法，这些实例方法只是类属性的代理。因此，实例可以修改类属性，但是不能覆盖——这与 `class_attribute` 不同（参见上文）。例如：

```ruby
module ActionView
  class Base
    cattr_accessor :field_error_proc
    @@field_error_proc = Proc.new{ ... }
  end
end
```

这样，我们便可以在视图中访问 `field_error_proc`。

此外，可以把一个块传给 `cattr_*` 方法，设定属性的默认值：

```ruby
class MysqlAdapter < AbstractAdapter
  # 生成访问 @@emulate_booleans 的类方法，其默认值为 true
  cattr_accessor(:emulate_booleans) { true }
end
```

把 `:instance_reader` 设为 `false`，不生成实例读值方法，把 `:instance_writer` 设为 `false`，不生成实例设值方法，把 `:instance_accessor` 设为 `false`，实例读值和设置方法都不生成。此时，这三个选项的值都必须是 `false`，而不能是假值。

```ruby
module A
  class B
    # 不生成实例读值方法 first_name
    cattr_accessor :first_name, instance_reader: false
    # 不生成实例设值方法 last_name=
    cattr_accessor :last_name, instance_writer: false
    # 不生成实例读值方法 surname 和实例设值方法 surname=
    cattr_accessor :surname, instance_accessor: false
  end
end
```

在模型中可以把 `:instance_accessor` 设为 `false`，防止批量赋值属性。

NOTE: 在 `active_support/core_ext/module/attribute_accessors.rb` 文件中定义。

<a class="anchor" id="subclasses-descendants"></a>

### 子类和后代

<a class="anchor" id="subclasses"></a>

#### `subclasses`

`subclasses` 方法返回接收者的子类：

```ruby
class C; end
C.subclasses # => []

class B < C; end
C.subclasses # => [B]

class A < B; end
C.subclasses # => [B]

class D < C; end
C.subclasses # => [B, D]
```

返回的子类没有特定顺序。

NOTE: 在 `active_support/core_ext/class/subclasses.rb` 文件中定义。

<a class="anchor" id="descendants"></a>

#### `descendants`

`descendants` 方法返回接收者的后代：

```ruby
class C; end
C.descendants # => []

class B < C; end
C.descendants # => [B]

class A < B; end
C.descendants # => [B, A]

class D < C; end
C.descendants # => [B, A, D]
```

返回的后代没有特定顺序。

NOTE: 在 `active_support/core_ext/class/subclasses.rb` 文件中定义。

<a class="anchor" id="extensions-to-string"></a>

## `String` 的扩展

<a class="anchor" id="output-safety"></a>

### 输出的安全性

<a class="anchor" id="motivation"></a>

#### 引子

把数据插入 HTML 模板要格外小心。例如，不能原封不动地把 `@review.title` 内插到 HTML 页面中。假如标题是“Flanagan &amp; Matz rules!”，得到的输出格式就不对，因为 &amp; 会转义成“&amp;amp;”。更糟的是，如果应用编写不当，这可能留下严重的安全漏洞，因为用户可以注入恶意的 HTML，设定精心编造的标题。关于这个问题的详情，请阅读 [跨站脚本（XSS）](security.html#cross-site-scripting-xss)对跨站脚本的说明。

<a class="anchor" id="safe-strings"></a>

#### 安全字符串

Active Support 提出了安全字符串（对 HTML 而言）这一概念。安全字符串是对字符串做的一种标记，表示可以原封不动地插入 HTML。这种字符串是可信赖的，不管会不会转义。

默认，字符串被认为是不安全的：

```ruby
"".html_safe? # => false
```

可以使用 `html_safe` 方法把指定的字符串标记为安全的：

```ruby
s = "".html_safe
s.html_safe? # => true
```

注意，无论如何，`html_safe` 不会执行转义操作，它的作用只是一种断定：

```ruby
s = "<script>...</script>".html_safe
s.html_safe? # => true
s            # => "<script>...</script>"
```

你要自己确定该不该在某个字符串上调用 `html_safe`。

如果把字符串追加到安全字符串上，不管是就地修改，还是使用 `concat`/`<<` 或 `+`，结果都是一个安全字符串。不安全的字符会转义：

```ruby
"".html_safe + "<" # => "&lt;"
```

安全的字符直接追加：

```ruby
"".html_safe + "<".html_safe # => "<"
```

在常规的视图中不应该使用这些方法。不安全的值会自动转义：

```erb
<%= @review.title %> <%# 可以这么做，如果需要会转义 %>
```

如果想原封不动地插入值，不能调用 `html_safe`，而要使用 `raw` 辅助方法：

```erb
<%= raw @cms.current_template %> <%# 原封不动地插入 @cms.current_template %>
```

或者，可以使用等效的 `<%==`：

```erb
<%== @cms.current_template %> <%# 原封不动地插入 @cms.current_template %>
```

`raw` 辅助方法已经调用 `html_safe` 了：

```ruby
def raw(stringish)
  stringish.to_s.html_safe
end
```

NOTE: 在 `active_support/core_ext/string/output_safety.rb` 文件中定义。

<a class="anchor" id="transformation"></a>

#### 转换

通常，修改字符串的方法都返回不安全的字符串，前文所述的拼接除外。例如，`downcase`、`gsub`、`strip`、`chomp`、`underscore`，等等。

就地转换接收者，如 `gsub!`，其本身也变成不安全的了。

TIP: 不管是否修改了自身，安全性都丧失了。

<a class="anchor" id="conversion-and-coercion"></a>

#### 类型转换和强制转换

在安全字符串上调用 `to_s`，得到的还是安全字符串，但是使用 `to_str` 强制转换，得到的是不安全的字符串。

<a class="anchor" id="copying"></a>

#### 复制

在安全字符串上调用 `dup` 或 `clone`，得到的还是安全字符串。

<a class="anchor" id="remove"></a>

### `remove`

`remove` 方法删除匹配模式的所有内容：

```ruby
"Hello World".remove(/Hello /) # => "World"
```

也有破坏性版本，`String#remove!`。

NOTE: 在 `active_support/core_ext/string/filters.rb` 文件中定义。

<a class="anchor" id="squish"></a>

### `squish`

`squish` 方法把首尾的空白去掉，还会把多个空白压缩成一个：

```ruby
" \n  foo\n\r \t bar \n".squish # => "foo bar"
```

也有破坏性版本，`String#squish!`。

注意，既能处理 ASCII 空白，也能处理 Unicode 空白。

NOTE: 在 `active_support/core_ext/string/filters.rb` 文件中定义。

<a class="anchor" id="truncate"></a>

### `truncate`

`truncate` 方法在指定长度处截断接收者，返回一个副本：

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(20)
# => "Oh dear! Oh dear!..."
```

省略号可以使用 `:omission` 选项自定义：

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(20, omission: '&hellip;')
# => "Oh dear! Oh &hellip;"
```

尤其要注意，截断长度包含省略字符串。

设置 `:separator` 选项，以自然的方式截断：

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(18)
# => "Oh dear! Oh dea..."
"Oh dear! Oh dear! I shall be late!".truncate(18, separator: ' ')
# => "Oh dear! Oh..."
```

`:separator` 选项的值可以是一个正则表达式：

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(18, separator: /\s/)
# => "Oh dear! Oh..."
```

在上述示例中，本该在“dear”中间截断，但是 `:separator` 选项进行了阻止。

NOTE: 在 `active_support/core_ext/string/filters.rb` 文件中定义。

<a class="anchor" id="truncate-words"></a>

### `truncate_words`

`truncate_words` 方法在指定个单词处截断接收者，返回一个副本：

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(4)
# => "Oh dear! Oh dear!..."
```

省略号可以使用 `:omission` 选项自定义：

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(4, omission: '&hellip;')
# => "Oh dear! Oh dear!&hellip;"
```

设置 `:separator` 选项，以自然的方式截断：

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(3, separator: '!')
# => "Oh dear! Oh dear! I shall be late..."
```

`:separator` 选项的值可以是一个正则表达式：

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(4, separator: /\s/)
# => "Oh dear! Oh dear!..."
```

NOTE: 在 `active_support/core_ext/string/filters.rb` 文件中定义。

<a class="anchor" id="inquiry"></a>

### `inquiry`

`inquiry` 方法把字符串转换成 `StringInquirer` 对象，这样可以使用漂亮的方式检查相等性：

```ruby
"production".inquiry.production? # => true
"active".inquiry.inactive?       # => false
```

<a class="anchor" id="starts-with-questionmark-and-ends-with-questionmark"></a>

### `starts_with?` 和 `ends_with?`

Active Support 为 `String#start_with?` 和 `String#end_with?` 定义了第三人称版本：

```ruby
"foo".starts_with?("f") # => true
"foo".ends_with?("o")   # => true
```

NOTE: 在 `active_support/core_ext/string/starts_ends_with.rb` 文件中定义。

<a class="anchor" id="strip-heredoc"></a>

### `strip_heredoc`

`strip_heredoc` 方法去掉 here 文档中的缩进。

例如：

```ruby
if options[:usage]
  puts <<-USAGE.strip_heredoc
    This command does such and such.

    Supported options are:
      -h         This message
      ...
  USAGE
end
```

用户看到的消息会靠左边对齐。

从技术层面来说，这个方法寻找整个字符串中的最小缩进量，然后删除那么多的前导空白。

NOTE: 在 `active_support/core_ext/string/strip.rb` 文件中定义。

<a class="anchor" id="indent"></a>

### `indent`

按指定量缩进接收者：

```ruby
<<EOS.indent(2)
def some_method
  some_code
end
EOS
# =>
  def some_method
    some_code
  end
```

第二个参数，`indent_string`，指定使用什么字符串缩进。默认值是 `nil`，让这个方法根据第一个缩进行做猜测，如果第一行没有缩进，则使用空白。

```ruby
"  foo".indent(2)        # => "    foo"
"foo\n\t\tbar".indent(2) # => "\t\tfoo\n\t\t\t\tbar"
"foo".indent(2, "\t")    # => "\t\tfoo"
```

`indent_string` 的值虽然经常设为一个空格或一个制表符，但是可以使用任何字符串。

第三个参数，`indent_empty_lines`，是个旗标，指明是否缩进空行。默认值是 `false`。

```ruby
"foo\n\nbar".indent(2)            # => "  foo\n\n  bar"
"foo\n\nbar".indent(2, nil, true) # => "  foo\n  \n  bar"
```

`indent!` 方法就地执行缩进。

NOTE: 在 `active_support/core_ext/string/indent.rb` 文件中定义。

<a class="anchor" id="access"></a>

### 访问

<a class="anchor" id="at-position"></a>

#### `at(position)`

返回字符串中 `position` 位置上的字符：

```ruby
"hello".at(0)  # => "h"
"hello".at(4)  # => "o"
"hello".at(-1) # => "o"
"hello".at(10) # => nil
```

NOTE: 在 `active_support/core_ext/string/access.rb` 文件中定义。

<a class="anchor" id="from-position"></a>

#### `from(position)`

返回子串，从 `position` 位置开始：

```ruby
"hello".from(0)  # => "hello"
"hello".from(2)  # => "llo"
"hello".from(-2) # => "lo"
"hello".from(10) # => nil
```

NOTE: 在 `active_support/core_ext/string/access.rb` 文件中定义。

<a class="anchor" id="to-position"></a>

#### `to(position)`

返回子串，到 `position` 位置为止：

```ruby
"hello".to(0)  # => "h"
"hello".to(2)  # => "hel"
"hello".to(-2) # => "hell"
"hello".to(10) # => "hello"
```

NOTE: 在 `active_support/core_ext/string/access.rb` 文件中定义。

<a class="anchor" id="first-limit-1"></a>

#### `first(limit = 1)`

如果 `n` &gt; 0，`str.first(n)` 的作用与 `str.to(n-1)` 一样；如果 `n` == 0，返回一个空字符串。

NOTE: 在 `active_support/core_ext/string/access.rb` 文件中定义。

<a class="anchor" id="last-limit-1"></a>

#### `last(limit = 1)`

如果 `n` &gt; 0，`str.last(n)` 的作用与 `str.from(-n)` 一样；如果 `n` == 0，返回一个空字符串。

NOTE: 在 `active_support/core_ext/string/access.rb` 文件中定义。

<a class="anchor" id="inflections"></a>

### 词形变化

<a class="anchor" id="pluralize"></a>

#### `pluralize`

`pluralize` 方法返回接收者的复数形式：

```ruby
"table".pluralize     # => "tables"
"ruby".pluralize      # => "rubies"
"equipment".pluralize # => "equipment"
```

如上例所示，Active Support 知道如何处理不规则的复数形式和不可数名词。内置的规则可以在 `config/initializers/inflections.rb` 文件中扩展。那个文件是由 `rails` 命令生成的，里面的注释说明了该怎么做。

`pluralize` 还可以接受可选的 `count` 参数。如果 `count == 1`，返回单数形式。把 `count` 设为其他值，都会返回复数形式：

```ruby
"dude".pluralize(0) # => "dudes"
"dude".pluralize(1) # => "dude"
"dude".pluralize(2) # => "dudes"
```

Active Record 使用这个方法计算模型对应的默认表名：

```ruby
# active_record/model_schema.rb
def undecorated_table_name(class_name = base_class.name)
  table_name = class_name.to_s.demodulize.underscore
  pluralize_table_names ? table_name.pluralize : table_name
end
```

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="singularize"></a>

#### `singularize`

作用与 `pluralize` 相反：

```ruby
"tables".singularize    # => "table"
"rubies".singularize    # => "ruby"
"equipment".singularize # => "equipment"
```

关联使用这个方法计算默认的关联类：

```ruby
# active_record/reflection.rb
def derive_class_name
  class_name = name.to_s.camelize
  class_name = class_name.singularize if collection?
  class_name
end
```

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="camelize"></a>

#### `camelize`

`camelize` 方法把接收者变成驼峰式：

```ruby
"product".camelize    # => "Product"
"admin_user".camelize # => "AdminUser"
```

一般来说，你可以把这个方法的作用想象为把路径转换成 Ruby 类或模块名的方式（使用斜线分隔命名空间）：

```ruby
"backoffice/session".camelize # => "Backoffice::Session"
```

例如，Action Pack 使用这个方法加载提供特定会话存储功能的类：

```ruby
# action_controller/metal/session_management.rb
def session_store=(store)
  @@session_store = store.is_a?(Symbol) ?
    ActionDispatch::Session.const_get(store.to_s.camelize) :
    store
end
```

`camelize` 接受一个可选的参数，其值可以是 `:upper`（默认值）或 `:lower`。设为后者时，第一个字母是小写的：

```ruby
"visual_effect".camelize(:lower) # => "visualEffect"
```

为使用这种风格的语言计算方法名时可以这么设定，例如 JavaScript。

TIP: 一般来说，可以把 `camelize` 视作 `underscore` 的逆操作，不过也有例外：`"SSLError".underscore.camelize` 的结果是 `"SslError"`。为了支持这种情况，Active Support 允许你在 `config/initializers/inflections.rb` 文件中指定缩略词。

```ruby
ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym 'SSL'
end

"SSLError".underscore.camelize # => "SSLError"
```


`camelcase` 是 `camelize` 的别名。

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="underscore"></a>

#### `underscore`

`underscore` 方法的作用相反，把驼峰式变成蛇底式：

```ruby
"Product".underscore   # => "product"
"AdminUser".underscore # => "admin_user"
```

还会把 `"::"` 转换成 `"/"`：

```ruby
"Backoffice::Session".underscore # => "backoffice/session"
```

也能理解以小写字母开头的字符串：

```ruby
"visualEffect".underscore # => "visual_effect"
```

不过，`underscore` 不接受任何参数。

Rails 自动加载类和模块的机制使用 `underscore` 推断可能定义缺失的常量的文件的相对路径（不带扩展名）：

```ruby
# active_support/dependencies.rb
def load_missing_constant(from_mod, const_name)
  ...
  qualified_name = qualified_name_for from_mod, const_name
  path_suffix = qualified_name.underscore
  ...
end
```

TIP: 一般来说，可以把 `underscore` 视作 `camelize` 的逆操作，不过也有例外。例如，`"SSLError".underscore.camelize` 的结果是 `"SslError"`。

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="titleize"></a>

#### `titleize`

`titleize` 方法把接收者中的单词首字母变成大写：

```ruby
"alice in wonderland".titleize # => "Alice In Wonderland"
"fermat's enigma".titleize     # => "Fermat's Enigma"
```

`titlecase` 是 `titleize` 的别名。

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="dasherize"></a>

#### `dasherize`

`dasherize` 方法把接收者中的下划线替换成连字符：

```ruby
"name".dasherize         # => "name"
"contact_data".dasherize # => "contact-data"
```

模型的 XML 序列化程序使用这个方法处理节点名：

```ruby
# active_model/serializers/xml.rb
def reformat_name(name)
  name = name.camelize if camelize?
  dasherize? ? name.dasherize : name
end
```

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="demodulize"></a>

#### `demodulize`

`demodulize` 方法返回限定常量名的常量名本身，即最右边那一部分：

```ruby
"Product".demodulize                        # => "Product"
"Backoffice::UsersController".demodulize    # => "UsersController"
"Admin::Hotel::ReservationUtils".demodulize # => "ReservationUtils"
"::Inflections".demodulize                  # => "Inflections"
"".demodulize                               # => ""
```

例如，Active Record 使用这个方法计算计数器缓存列的名称：

```ruby
# active_record/reflection.rb
def counter_cache_column
  if options[:counter_cache] == true
    "#{active_record.name.demodulize.underscore.pluralize}_count"
  elsif options[:counter_cache]
    options[:counter_cache]
  end
end
```

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="deconstantize"></a>

#### `deconstantize`

`deconstantize` 方法去掉限定常量引用表达式的最右侧部分，留下常量的容器：

```ruby
"Product".deconstantize                        # => ""
"Backoffice::UsersController".deconstantize    # => "Backoffice"
"Admin::Hotel::ReservationUtils".deconstantize # => "Admin::Hotel"
```

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="parameterize"></a>

#### `parameterize`

`parameterize` 方法对接收者做整形，以便在精美的 URL 中使用。

```ruby
"John Smith".parameterize # => "john-smith"
"Kurt Gödel".parameterize # => "kurt-godel"
```

如果想保留大小写，把 `preserve_case` 参数设为 `true`。这个参数的默认值是 `false`。

```ruby
"John Smith".parameterize(preserve_case: true) # => "John-Smith"
"Kurt Gödel".parameterize(preserve_case: true) # => "Kurt-Godel"
```

如果想使用自定义的分隔符，覆盖 `separator` 参数。

```ruby
"John Smith".parameterize(separator: "_") # => "john\_smith"
"Kurt Gödel".parameterize(separator: "_") # => "kurt\_godel"
```

其实，得到的字符串包装在 `ActiveSupport::Multibyte::Chars` 实例中。

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="tableize"></a>

#### `tableize`

`tableize` 方法相当于先调用 `underscore`，再调用 `pluralize`。

```ruby
"Person".tableize      # => "people"
"Invoice".tableize     # => "invoices"
"InvoiceLine".tableize # => "invoice_lines"
```

一般来说，`tableize` 返回简单模型对应的表名。Active Record 真正的实现方式不是只使用 `tableize`，还会使用 `demodulize`，再检查一些可能影响返回结果的选项。

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="classify"></a>

#### `classify`

`classify` 方法的作用与 `tableize` 相反，返回表名对应的类名：

```ruby
"people".classify        # => "Person"
"invoices".classify      # => "Invoice"
"invoice_lines".classify # => "InvoiceLine"
```

这个方法能处理限定的表名：

```ruby
"highrise_production.companies".classify # => "Company"
```

注意，`classify` 方法返回的类名是字符串。你可以调用 `constantize` 方法，得到真正的类对象，如下一节所述。

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="constantize"></a>

#### `constantize`

`constantize` 方法解析接收者中的常量引用表达式：

```ruby
"Integer".constantize # => Integer

module M
  X = 1
end
"M::X".constantize # => 1
```

如果结果是未知的常量，或者根本不是有效的常量名，`constantize` 抛出 `NameError` 异常。

即便开头没有 `::`，`constantize` 也始终从顶层的 `Object` 解析常量名。

```ruby
X = :in_Object
module M
  X = :in_M

  X                 # => :in_M
  "::X".constantize # => :in_Object
  "X".constantize   # => :in_Object (!)
end
```

因此，通常这与 Ruby 的处理方式不同，Ruby 会求值真正的常量。

邮件程序测试用例使用 `constantize` 方法从测试用例的名称中获取要测试的邮件程序：

```ruby
# action_mailer/test_case.rb
def determine_default_mailer(name)
  name.sub(/Test$/, '').constantize
rescue NameError => e
  raise NonInferrableMailerError.new(name)
end
```

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="humanize"></a>

#### `humanize`

`humanize` 方法对属性名做调整，以便显示给终端用户查看。

这个方法所做的转换如下：

*   根据参数做对人类友好的词形变化
*   删除前导下划线（如果有）
*   删除“_id”后缀（如果有）
*   把下划线替换成空格（如果有）
*   把所有单词变成小写，缩略词除外
*   把第一个单词的首字母变成大写

把 `:capitalize` 选项设为 `false`（默认值为 `true`）可以禁止把第一个单词的首字母变成大写。

```ruby
"name".humanize                         # => "Name"
"author_id".humanize                    # => "Author"
"author_id".humanize(capitalize: false) # => "author"
"comments_count".humanize               # => "Comments count"
"_id".humanize                          # => "Id"
```

如果把“SSL”定义为缩略词：

```ruby
'ssl_error'.humanize # => "SSL error"
```

`full_messages` 辅助方法使用 `humanize` 作为一种后备机制，以便包含属性名：

```ruby
def full_messages
  map { |attribute, message| full_message(attribute, message) }
end

def full_message
  ...
  attr_name = attribute.to_s.tr('.', '_').humanize
  attr_name = @base.class.human_attribute_name(attribute, default: attr_name)
  ...
end
```

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="foreign-key"></a>

#### `foreign_key`

`foreign_key` 方法根据类名计算外键列的名称。为此，它先调用 `demodulize`，再调用 `underscore`，最后加上“_id”：

```ruby
"User".foreign_key           # => "user_id"
"InvoiceLine".foreign_key    # => "invoice_line_id"
"Admin::Session".foreign_key # => "session_id"
```

如果不想添加“_id”中的下划线，传入 `false` 参数：

```ruby
"User".foreign_key(false) # => "userid"
```

关联使用这个方法推断外键，例如 `has_one` 和 `has_many` 是这么做的：

```ruby
# active_record/associations.rb
foreign_key = options[:foreign_key] || reflection.active_record.name.foreign_key
```

NOTE: 在 `active_support/core_ext/string/inflections.rb` 文件中定义。

<a class="anchor" id="extensions-to-string-conversions"></a>

### 转换

<a class="anchor" id="to-date-to-time-to-datetime"></a>

#### `to_date`、`to_time`、`to_datetime`

`to_date`、`to_time` 和 `to_datetime` 是对 `Date._parse` 的便利包装：

```ruby
"2010-07-27".to_date              # => Tue, 27 Jul 2010
"2010-07-27 23:37:00".to_time     # => 2010-07-27 23:37:00 +0200
"2010-07-27 23:37:00".to_datetime # => Tue, 27 Jul 2010 23:37:00 +0000
```

`to_time` 有个可选的参数，值为 `:utc` 或 `:local`，指明想使用的时区：

```ruby
"2010-07-27 23:42:00".to_time(:utc)   # => 2010-07-27 23:42:00 UTC
"2010-07-27 23:42:00".to_time(:local) # => 2010-07-27 23:42:00 +0200
```

默认值是 `:utc`。

详情参见 `Date._parse` 的文档。

TIP: 参数为空时，这三个方法返回 `nil`。

NOTE: 在 `active_support/core_ext/string/conversions.rb` 文件中定义。

<a class="anchor" id="extensions-to-numeric"></a>

## `Numeric` 的扩展

<a class="anchor" id="bytes"></a>

### 字节

所有数字都能响应下述方法：

```ruby
bytes
kilobytes
megabytes
gigabytes
terabytes
petabytes
exabytes
```

这些方法返回相应的字节数，因子是 1024：

```ruby
2.kilobytes   # => 2048
3.megabytes   # => 3145728
3.5.gigabytes # => 3758096384
-4.exabytes   # => -4611686018427387904
```

这些方法都有单数别名，因此可以这样用：

```ruby
1.megabyte # => 1048576
```

NOTE: 在 `active_support/core_ext/numeric/bytes.rb` 文件中定义。

<a class="anchor" id="time"></a>

### 时间

用于计算和声明时间，例如 `45.minutes + 2.hours + 4.years`。

使用 `from_now`、`ago` 等精确计算日期，以及增减 `Time` 对象时使用 `Time#advance`。例如：

```ruby
# 等价于 Time.current.advance(months: 1)
1.month.from_now

# 等价于 Time.current.advance(years: 2)
2.years.from_now

# 等价于 Time.current.advance(months: 4, years: 5)
(4.months + 5.years).from_now
```

NOTE: 在 `active_support/core_ext/numeric/time.rb` 文件中定义。

<a class="anchor" id="formatting"></a>

### 格式化

以各种形式格式化数字。

把数字转换成字符串表示形式，表示电话号码：

```ruby
5551234.to_s(:phone)
# => 555-1234
1235551234.to_s(:phone)
# => 123-555-1234
1235551234.to_s(:phone, area_code: true)
# => (123) 555-1234
1235551234.to_s(:phone, delimiter: " ")
# => 123 555 1234
1235551234.to_s(:phone, area_code: true, extension: 555)
# => (123) 555-1234 x 555
1235551234.to_s(:phone, country_code: 1)
# => +1-123-555-1234
```

把数字转换成字符串表示形式，表示货币：

```ruby
1234567890.50.to_s(:currency)                 # => $1,234,567,890.50
1234567890.506.to_s(:currency)                # => $1,234,567,890.51
1234567890.506.to_s(:currency, precision: 3)  # => $1,234,567,890.506
```

把数字转换成字符串表示形式，表示百分比：

```ruby
100.to_s(:percentage)
# => 100.000%
100.to_s(:percentage, precision: 0)
# => 100%
1000.to_s(:percentage, delimiter: '.', separator: ',')
# => 1.000,000%
302.24398923423.to_s(:percentage, precision: 5)
# => 302.24399%
```

把数字转换成字符串表示形式，以分隔符分隔：

```ruby
12345678.to_s(:delimited)                     # => 12,345,678
12345678.05.to_s(:delimited)                  # => 12,345,678.05
12345678.to_s(:delimited, delimiter: ".")     # => 12.345.678
12345678.to_s(:delimited, delimiter: ",")     # => 12,345,678
12345678.05.to_s(:delimited, separator: " ")  # => 12,345,678 05
```

把数字转换成字符串表示形式，以指定精度四舍五入：

```ruby
111.2345.to_s(:rounded)                     # => 111.235
111.2345.to_s(:rounded, precision: 2)       # => 111.23
13.to_s(:rounded, precision: 5)             # => 13.00000
389.32314.to_s(:rounded, precision: 0)      # => 389
111.2345.to_s(:rounded, significant: true)  # => 111
```

把数字转换成字符串表示形式，得到人类可读的字节数：

```ruby
123.to_s(:human_size)                  # => 123 Bytes
1234.to_s(:human_size)                 # => 1.21 KB
12345.to_s(:human_size)                # => 12.1 KB
1234567.to_s(:human_size)              # => 1.18 MB
1234567890.to_s(:human_size)           # => 1.15 GB
1234567890123.to_s(:human_size)        # => 1.12 TB
1234567890123456.to_s(:human_size)     # => 1.1 PB
1234567890123456789.to_s(:human_size)  # => 1.07 EB
```

把数字转换成字符串表示形式，得到人类可读的词：

```ruby
123.to_s(:human)               # => "123"
1234.to_s(:human)              # => "1.23 Thousand"
12345.to_s(:human)             # => "12.3 Thousand"
1234567.to_s(:human)           # => "1.23 Million"
1234567890.to_s(:human)        # => "1.23 Billion"
1234567890123.to_s(:human)     # => "1.23 Trillion"
1234567890123456.to_s(:human)  # => "1.23 Quadrillion"
```

NOTE: 在 `active_support/core_ext/numeric/conversions.rb` 文件中定义。

<a class="anchor" id="extensions-to-integer"></a>

## `Integer` 的扩展

<a class="anchor" id="multiple-of-questionmark"></a>

### `multiple_of?`

`multiple_of?` 方法测试一个整数是不是参数的倍数：

```ruby
2.multiple_of?(1) # => true
1.multiple_of?(2) # => false
```

NOTE: 在 `active_support/core_ext/integer/multiple.rb` 文件中定义。

<a class="anchor" id="ordinal"></a>

### `ordinal`

`ordinal` 方法返回整数接收者的序数词后缀（字符串）：

```ruby
1.ordinal    # => "st"
2.ordinal    # => "nd"
53.ordinal   # => "rd"
2009.ordinal # => "th"
-21.ordinal  # => "st"
-134.ordinal # => "th"
```

NOTE: 在 `active_support/core_ext/integer/inflections.rb` 文件中定义。

<a class="anchor" id="ordinalize"></a>

### `ordinalize`

`ordinalize` 方法返回整数接收者的序数词（字符串）。注意，`ordinal` 方法只返回后缀。

```ruby
1.ordinalize    # => "1st"
2.ordinalize    # => "2nd"
53.ordinalize   # => "53rd"
2009.ordinalize # => "2009th"
-21.ordinalize  # => "-21st"
-134.ordinalize # => "-134th"
```

NOTE: 在 `active_support/core_ext/integer/inflections.rb` 文件中定义。

<a class="anchor" id="extensions-to-bigdecimal"></a>

## `BigDecimal` 的扩展

<a class="anchor" id="extensions-to-bigdecimal-to-s"></a>

### `to_s`

`to_s` 方法把默认的说明符设为“F”。这意味着，不传入参数时，`to_s` 返回浮点数表示形式，而不是工程计数法。

```ruby
BigDecimal.new(5.00, 6).to_s  # => "5.0"
```

说明符也可以使用符号：

```ruby
BigDecimal.new(5.00, 6).to_s(:db)  # => "5.0"
```

也支持工程计数法：

```ruby
BigDecimal.new(5.00, 6).to_s("e")  # => "0.5E1"
```

<a class="anchor" id="extensions-to-enumerable"></a>

## `Enumerable` 的扩展

<a class="anchor" id="sum"></a>

### `sum`

`sum` 方法计算可枚举对象的元素之和：

```ruby
[1, 2, 3].sum # => 6
(1..100).sum  # => 5050
```

只假定元素能响应 `+`：

```ruby
[[1, 2], [2, 3], [3, 4]].sum    # => [1, 2, 2, 3, 3, 4]
%w(foo bar baz).sum             # => "foobarbaz"
{a: 1, b: 2, c: 3}.sum          # => [:b, 2, :c, 3, :a, 1]
```

空集合的元素之和默认为零，不过可以自定义：

```ruby
[].sum    # => 0
[].sum(1) # => 1
```

如果提供块，`sum` 变成迭代器，把集合中的元素拽入块中，然后求返回值之和：

```ruby
(1..5).sum {|n| n * 2 } # => 30
[2, 4, 6, 8, 10].sum    # => 30
```

空接收者之和也可以使用这种方式自定义：

```ruby
[].sum(1) {|n| n**3} # => 1
```

NOTE: 在 `active_support/core_ext/enumerable.rb` 文件中定义。

<a class="anchor" id="index-by"></a>

### `index_by`

`index_by` 方法生成一个散列，使用某个键索引可枚举对象中的元素。

它迭代集合，把各个元素传入块中。元素使用块的返回值为键：

```ruby
invoices.index_by(&:number)
# => {'2009-032' => <Invoice ...>, '2009-008' => <Invoice ...>, ...}
```

WARNING: 键一般是唯一的。如果块为不同的元素返回相同的键，不会使用那个键构建集合。最后一个元素胜出。

NOTE: 在 `active_support/core_ext/enumerable.rb` 文件中定义。

<a class="anchor" id="many-questionmark"></a>

### `many?`

`many?` 方法是 `collection.size > 1` 的简化：

```erb
<% if pages.many? %>
  <%= pagination_links %>
<% end %>
```

如果提供可选的块，`many?` 只考虑返回 `true` 的元素：

```ruby
@see_more = videos.many? {|video| video.category == params[:category]}
```

NOTE: 在 `active_support/core_ext/enumerable.rb` 文件中定义。

<a class="anchor" id="exclude-questionmark"></a>

### `exclude?`

`exclude?` 方法测试指定对象是否不在集合中。这是内置方法 `include?` 的逆向判断。

```ruby
to_visit << node if visited.exclude?(node)
```

NOTE: 在 `active_support/core_ext/enumerable.rb` 文件中定义。

<a class="anchor" id="without"></a>

### `without`

`without` 从可枚举对象中删除指定的元素，然后返回副本：

```ruby
["David", "Rafael", "Aaron", "Todd"].without("Aaron", "Todd") # => ["David", "Rafael"]
```

NOTE: 在 `active_support/core_ext/enumerable.rb` 文件中定义。

<a class="anchor" id="pluck"></a>

### `pluck`

`pluck` 方法基于指定的键返回一个数组：

```ruby
[{ name: "David" }, { name: "Rafael" }, { name: "Aaron" }].pluck(:name) # => ["David", "Rafael", "Aaron"]
```

NOTE: 在 `active_support/core_ext/enumerable.rb` 文件中定义。

<a class="anchor" id="extensions-to-array"></a>

## `Array` 的扩展

<a class="anchor" id="accessing"></a>

### 访问

为了便于以多种方式访问数组，Active Support 增强了数组的 API。例如，若想获取到指定索引的子数组，可以这么做：

```ruby
%w(a b c d).to(2) # => %w(a b c)
[].to(7)          # => []
```

类似地，`from` 从指定索引一直获取到末尾。如果索引大于数组的长度，返回一个空数组。

```ruby
%w(a b c d).from(2)  # => %w(c d)
%w(a b c d).from(10) # => []
[].from(0)           # => []
```

`second`、`third`、`fourth` 和 `fifth` 分别返回对应的元素，`second_to_last` 和 `third_to_last` 也是（`first` 和 `last` 是内置的）。得益于公众智慧和积极的建设性建议，还有 `forty_two` 可用。

```ruby
%w(a b c d).third # => c
%w(a b c d).fifth # => nil
```

NOTE: 在 `active_support/core_ext/array/access.rb` 文件中定义。

<a class="anchor" id="adding-elements"></a>

### 添加元素

<a class="anchor" id="prepend"></a>

#### `prepend`

这个方法是 `Array#unshift` 的别名。

```ruby
%w(a b c d).prepend('e')  # => ["e", "a", "b", "c", "d"]
[].prepend(10)            # => [10]
```

NOTE: 在 `active_support/core_ext/array/prepend_and_append.rb` 文件中定义。

<a class="anchor" id="append"></a>

#### `append`

这个方法是 `Array#<<` 的别名。

```ruby
%w(a b c d).append('e')  # => ["a", "b", "c", "d", "e"]
[].append([1,2])         # => [[1, 2]]
```

NOTE: 在 `active_support/core_ext/array/prepend_and_append.rb` 文件中定义。

<a class="anchor" id="options-extraction"></a>

### 选项提取

如果方法调用的最后一个参数（不含 `&block` 参数）是散列，Ruby 允许省略花括号：

```ruby
User.exists?(email: params[:email])
```

Rails 大量使用这种语法糖，以此避免编写大量位置参数，用于模仿具名参数。Rails 经常在最后一个散列选项上使用这种惯用法。

然而，如果方法期待任意个参数，在声明中使用 `*`，那么选项散列就会变成数组中一个元素，失去了应有的作用。

此时，可以使用 `extract_options!` 特殊处理选项散列。这个方法检查数组最后一个元素的类型，如果是散列，把它提取出来，并返回；否则，返回一个空散列。

下面以控制器的 `caches_action` 方法的定义为例：

```ruby
def caches_action(*actions)
  return unless cache_configured?
  options = actions.extract_options!
  ...
end
```

这个方法接收任意个动作名，最后一个参数是选项散列。`extract_options!` 方法获取选项散列，把它从 `actions` 参数中删除，这样简单便利。

NOTE: 在 `active_support/core_ext/array/extract_options.rb` 文件中定义。

<a class="anchor" id="extensions-to-array-conversions"></a>

### 转换

<a class="anchor" id="to-sentence"></a>

#### `to_sentence`

`to_sentence` 方法枚举元素，把数组变成一个句子（字符串）：

```ruby
%w().to_sentence                # => ""
%w(Earth).to_sentence           # => "Earth"
%w(Earth Wind).to_sentence      # => "Earth and Wind"
%w(Earth Wind Fire).to_sentence # => "Earth, Wind, and Fire"
```

这个方法接受三个选项：

*   `:two_words_connector`：数组长度为 2 时使用什么词。默认为“ and”。
*   `:words_connector`：数组元素数量为 3 个以上（含）时，使用什么连接除最后两个元素之外的元素。默认为“, ”。
*   `:last_word_connector`：数组元素数量为 3 个以上（含）时，使用什么连接最后两个元素。默认为“, and”。

这些选项的默认值可以本地化，相应的键为：

| 选项 | i18n 键  |
|---|---|
| `:two_words_connector` | `support.array.two_words_connector`  |
| `:words_connector` | `support.array.words_connector`  |
| `:last_word_connector` | `support.array.last_word_connector`  |

NOTE: 在 `active_support/core_ext/array/conversions.rb` 文件中定义。

<a class="anchor" id="to-formatted-s"></a>

#### `to_formatted_s`

默认情况下，`to_formatted_s` 的行为与 `to_s` 一样。

然而，如果数组中的元素能响应 `id` 方法，可以传入参数 `:db`。处理 Active Record 对象集合时经常如此。返回的字符串如下：

```ruby
[].to_formatted_s(:db)            # => "null"
[user].to_formatted_s(:db)        # => "8456"
invoice.lines.to_formatted_s(:db) # => "23,567,556,12"
```

在上述示例中，整数是在元素上调用 `id` 得到的。

NOTE: 在 `active_support/core_ext/array/conversions.rb` 文件中定义。

<a class="anchor" id="extensions-to-array-conversions-to-xml"></a>

#### `to_xml`

`to_xml` 方法返回接收者的 XML 表述：

```ruby
Contributor.limit(2).order(:rank).to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <contributors type="array">
#   <contributor>
#     <id type="integer">4356</id>
#     <name>Jeremy Kemper</name>
#     <rank type="integer">1</rank>
#     <url-id>jeremy-kemper</url-id>
#   </contributor>
#   <contributor>
#     <id type="integer">4404</id>
#     <name>David Heinemeier Hansson</name>
#     <rank type="integer">2</rank>
#     <url-id>david-heinemeier-hansson</url-id>
#   </contributor>
# </contributors>
```

为此，它把 `to_xml` 分别发送给每个元素，然后收集结果，放在一个根节点中。所有元素都必须能响应 `to_xml`，否则抛出异常。

默认情况下，根元素的名称是第一个元素的类名的复数形式经过 `underscore` 和 `dasherize` 处理后得到的值——前提是余下的元素属于那个类型（使用 `is_a?` 检查），而且不是散列。在上例中，根元素是“contributors”。

只要有不属于那个类型的元素，根元素就使用“objects”：

```ruby
[Contributor.first, Commit.first].to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <objects type="array">
#   <object>
#     <id type="integer">4583</id>
#     <name>Aaron Batalion</name>
#     <rank type="integer">53</rank>
#     <url-id>aaron-batalion</url-id>
#   </object>
#   <object>
#     <author>Joshua Peek</author>
#     <authored-timestamp type="datetime">2009-09-02T16:44:36Z</authored-timestamp>
#     <branch>origin/master</branch>
#     <committed-timestamp type="datetime">2009-09-02T16:44:36Z</committed-timestamp>
#     <committer>Joshua Peek</committer>
#     <git-show nil="true"></git-show>
#     <id type="integer">190316</id>
#     <imported-from-svn type="boolean">false</imported-from-svn>
#     <message>Kill AMo observing wrap_with_notifications since ARes was only using it</message>
#     <sha1>723a47bfb3708f968821bc969a9a3fc873a3ed58</sha1>
#   </object>
# </objects>
```

如果接收者是由散列组成的数组，根元素默认也是“objects”：

```ruby
[{a: 1, b: 2}, {c: 3}].to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <objects type="array">
#   <object>
#     <b type="integer">2</b>
#     <a type="integer">1</a>
#   </object>
#   <object>
#     <c type="integer">3</c>
#   </object>
# </objects>
```

WARNING: 如果集合为空，根元素默认为“nil-classes”。例如上述示例中的贡献者列表，如果集合为空，根元素不是“contributors”，而是“nil-classes”。可以使用 `:root` 选项确保根元素始终一致。

子节点的名称默认为根节点的单数形式。在前面几个例子中，我们见到的是“contributor”和“object”。可以使用 `:children` 选项设定子节点的名称。

默认的 XML 构建程序是一个新的 `Builder::XmlMarkup` 实例。可以使用 `:builder` 选项指定构建程序。这个方法还接受 `:dasherize` 等方法，它们会被转发给构建程序。

```ruby
Contributor.limit(2).order(:rank).to_xml(skip_types: true)
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <contributors>
#   <contributor>
#     <id>4356</id>
#     <name>Jeremy Kemper</name>
#     <rank>1</rank>
#     <url-id>jeremy-kemper</url-id>
#   </contributor>
#   <contributor>
#     <id>4404</id>
#     <name>David Heinemeier Hansson</name>
#     <rank>2</rank>
#     <url-id>david-heinemeier-hansson</url-id>
#   </contributor>
# </contributors>
```

NOTE: 在 `active_support/core_ext/array/conversions.rb` 文件中定义。

<a class="anchor" id="wrapping"></a>

### 包装

`Array.wrap` 方法把参数包装成一个数组，除非参数已经是数组（或与数组类似的结构）。

具体而言：

*   如果参数是 `nil`，返回一个空数组。
*   否则，如果参数响应 `to_ary` 方法，调用之；如果 `to_ary` 返回值不是 `nil`，返回之。
*   否则，把参数作为数组的唯一元素，返回之。

```ruby
Array.wrap(nil)       # => []
Array.wrap([1, 2, 3]) # => [1, 2, 3]
Array.wrap(0)         # => [0]
```

这个方法的作用与 `Kernel#Array` 类似，不过二者之间有些区别：

*   如果参数响应 `to_ary`，调用之。如果 `to_ary` 的返回值是 `nil`，`Kernel#Array` 接着调用 `to_a`，而 `Array.wrap` 把参数作为数组的唯一元素，返回之。
*   如果 `to_ary` 的返回值既不是 `nil`，也不是 `Array` 对象，`Kernel#Array` 抛出异常，而 `Array.wrap` 不会，它返回那个值。
*   如果参数不响应 `to_ary`，`Array.wrap` 不在参数上调用 `to_a`，而是把参数作为数组的唯一元素，返回之。

对某些可枚举对象来说，最后一点尤为重要：

```ruby
Array.wrap(foo: :bar) # => [{:foo=>:bar}]
Array(foo: :bar)      # => [[:foo, :bar]]
```

还有一种惯用法是使用星号运算符：

```ruby
[*object]
```

在 Ruby 1.8 中，如果参数是 `nil`，返回 `[nil]`，否则调用 `Array(object)`。（如果你知道在 Ruby 1.9 中的行为，请联系 fxn。）

因此，参数为 `nil` 时二者的行为不同，前文对 `Kernel#Array` 的说明适用于其他对象。

NOTE: 在 `active_support/core_ext/array/wrap.rb` 文件中定义。

<a class="anchor" id="duplicating"></a>

### 复制

`Array#deep_dup` 方法使用 Active Support 提供的 `Object#deep_dup` 方法复制数组自身和里面的对象。其工作方式相当于通过 `Array#map` 把 `deep_dup` 方法发给里面的各个对象。

```ruby
array = [1, [2, 3]]
dup = array.deep_dup
dup[1][2] = 4
array[1][2] == nil   # => true
```

NOTE: 在 `active_support/core_ext/object/deep_dup.rb` 文件中定义。

<a class="anchor" id="grouping"></a>

### 分组

<a class="anchor" id="in-groups-of-number-fill-with-nil"></a>

#### `in_groups_of(number, fill_with = nil)`

`in_groups_of` 方法把数组拆分成特定长度的连续分组，返回由各分组构成的数组：

```ruby
[1, 2, 3].in_groups_of(2) # => [[1, 2], [3, nil]]
```

如果有块，把各分组拽入块中：

```erb
<% sample.in_groups_of(3) do |a, b, c| %>
  <tr>
    <td><%= a %></td>
    <td><%= b %></td>
    <td><%= c %></td>
  </tr>
<% end %>
```

第一个示例说明 `in_groups_of` 会使用 `nil` 元素填充最后一组，得到指定大小的分组。可以使用第二个参数（可选的）修改填充值：

```ruby
[1, 2, 3].in_groups_of(2, 0) # => [[1, 2], [3, 0]]
```

如果传入 `false`，不填充最后一组：

```ruby
[1, 2, 3].in_groups_of(2, false) # => [[1, 2], [3]]
```

因此，`false` 不能作为填充值使用。

NOTE: 在 `active_support/core_ext/array/grouping.rb` 文件中定义。

<a class="anchor" id="in-groups-number-fill-with-nil"></a>

#### `in_groups(number, fill_with = nil)`

`in_groups` 方法把数组分成特定个分组。这个方法返回由分组构成的数组：

```ruby
%w(1 2 3 4 5 6 7).in_groups(3)
# => [["1", "2", "3"], ["4", "5", nil], ["6", "7", nil]]
```

如果有块，把分组拽入块中：

```ruby
%w(1 2 3 4 5 6 7).in_groups(3) {|group| p group}
["1", "2", "3"]
["4", "5", nil]
["6", "7", nil]
```

在上述示例中，`in_groups` 使用 `nil` 填充尾部的分组。一个分组至多有一个填充值，而且是最后一个元素。有填充值的始终是最后几个分组。

可以使用第二个参数（可选的）修改填充值：

```ruby
%w(1 2 3 4 5 6 7).in_groups(3, "0")
# => [["1", "2", "3"], ["4", "5", "0"], ["6", "7", "0"]]
```

如果传入 `false`，不填充较短的分组：

```ruby
%w(1 2 3 4 5 6 7).in_groups(3, false)
# => [["1", "2", "3"], ["4", "5"], ["6", "7"]]
```

因此，`false` 不能作为填充值使用。

NOTE: 在 `active_support/core_ext/array/grouping.rb` 文件中定义。

<a class="anchor" id="split-value-nil"></a>

#### `split(value = nil)`

`split` 方法在指定的分隔符处拆分数组，返回得到的片段。

如果有块，使用块中表达式返回 `true` 的元素作为分隔符：

```ruby
(-5..5).to_a.split { |i| i.multiple_of?(4) }
# => [[-5], [-3, -2, -1], [1, 2, 3], [5]]
```

否则，使用指定的参数（默认为 `nil`）作为分隔符：

```ruby
[0, 1, -5, 1, 1, "foo", "bar"].split(1)
# => [[0], [-5], [], ["foo", "bar"]]
```

TIP: 仔细观察上例，出现连续的分隔符时，得到的是空数组。

NOTE: 在 `active_support/core_ext/array/grouping.rb` 文件中定义。

<a class="anchor" id="extensions-to-hash"></a>

## `Hash` 的扩展

<a class="anchor" id="extensions-to-hash-conversions"></a>

### 转换

<a class="anchor" id="conversions-to-xml"></a>

#### `to_xml`

`to_xml` 方法返回接收者的 XML 表述（字符串）：

```ruby
{"foo" => 1, "bar" => 2}.to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <hash>
#   <foo type="integer">1</foo>
#   <bar type="integer">2</bar>
# </hash>
```

为此，这个方法迭代各个键值对，根据值构建节点。假如键值对是 `key, value`：

*   如果 `value` 是一个散列，递归调用，此时 `key` 作为 `:root`。
*   如果 `value` 是一个数组，递归调用，此时 `key` 作为 `:root`，`key` 的单数形式作为 `:children`。
*   如果 `value` 是可调用对象，必须能接受一个或两个参数。根据参数的数量，传给可调用对象的第一个参数是 `options` 散列，`key` 作为 `:root`，`key` 的单数形式作为第二个参数。它的返回值作为新节点。
*   如果 `value` 响应 `to_xml`，调用这个方法时把 `key` 作为 `:root`。
*   否则，使用 `key` 为标签创建一个节点，`value` 的字符串表示形式为文本作为节点的文本。如果 `value` 是 `nil`，添加“nil”属性，值为“true”。除非有 `:skip_type` 选项，而且值为 `true`，否则还会根据下述对应关系添加“type”属性：

    ```ruby
    XML_TYPE_NAMES = {
      "Symbol"     => "symbol",
      "Integer"    => "integer",
      "BigDecimal" => "decimal",
      "Float"      => "float",
      "TrueClass"  => "boolean",
      "FalseClass" => "boolean",
      "Date"       => "date",
      "DateTime"   => "datetime",
      "Time"       => "datetime"
    }
    ```



默认情况下，根节点是“hash”，不过可以通过 `:root` 选项配置。

默认的 XML 构建程序是一个新的 `Builder::XmlMarkup` 实例。可以使用 `:builder` 选项配置构建程序。这个方法还接受 `:dasherize` 等选项，它们会被转发给构建程序。

NOTE: 在 `active_support/core_ext/hash/conversions.rb` 文件中定义。

<a class="anchor" id="merging"></a>

### 合并

Ruby 有个内置的方法，`Hash#merge`，用于合并两个散列：

```ruby
{a: 1, b: 1}.merge(a: 0, c: 2)
# => {:a=>0, :b=>1, :c=>2}
```

为了方便，Active Support 定义了几个用于合并散列的方法。

<a class="anchor" id="reverse-merge-and-reverse-merge-bang"></a>

#### `reverse_merge` 和 `reverse_merge!`

如果键有冲突，`merge` 方法的参数中的键胜出。通常利用这一点为选项散列提供默认值：

```ruby
options = {length: 30, omission: "..."}.merge(options)
```

Active Support 定义了 `reverse_merge` 方法，以防你想使用相反的合并方式：

```ruby
options = options.reverse_merge(length: 30, omission: "...")
```

还有一个爆炸版本，`reverse_merge!`，就地执行合并：

```ruby
options.reverse_merge!(length: 30, omission: "...")
```

WARNING: `reverse_merge!` 方法会就地修改调用方，这可能不是个好主意。

NOTE: 在 `active_support/core_ext/hash/reverse_merge.rb` 文件中定义。

<a class="anchor" id="reverse-update"></a>

#### `reverse_update`

`reverse_update` 方法是 `reverse_merge!` 的别名，作用参见前文。

WARNING: 注意，`reverse_update` 方法的名称中没有感叹号。

NOTE: 在 `active_support/core_ext/hash/reverse_merge.rb` 文件中定义。

<a class="anchor" id="deep-merge-and-deep-merge-bang"></a>

#### `deep_merge` 和 `deep_merge!`

如前面的示例所示，如果两个散列中有相同的键，参数中的散列胜出。

Active Support 定义了 `Hash#deep_merge` 方法。在深度合并中，如果两个散列中有相同的键，而且它们的值都是散列，那么在得到的散列中，那个键的值是合并后的结果：

```ruby
{a: {b: 1}}.deep_merge(a: {c: 2})
# => {:a=>{:b=>1, :c=>2}}
```

`deep_merge!` 方法就地执行深度合并。

NOTE: 在 `active_support/core_ext/hash/deep_merge.rb` 文件中定义。

<a class="anchor" id="deep-duplicating"></a>

### 深度复制

`Hash#deep_dup` 方法使用 Active Support 提供的 `Object#deep_dup` 方法复制散列自身及里面的键值对。其工作方式相当于通过 `Enumerator#each_with_object` 把 `deep_dup` 方法发给各个键值对。

```ruby
hash = { a: 1, b: { c: 2, d: [3, 4] } }

dup = hash.deep_dup
dup[:b][:e] = 5
dup[:b][:d] << 5

hash[:b][:e] == nil      # => true
hash[:b][:d] == [3, 4]   # => true
```

NOTE: 在 `active_support/core_ext/object/deep_dup.rb` 文件中定义。

<a class="anchor" id="working-with-keys"></a>

### 处理键

<a class="anchor" id="except-and-except-bang"></a>

#### `except` 和 `except!`

`except` 方法返回一个散列，从接收者中把参数中列出的键删除（如果有的话）：

```ruby
{a: 1, b: 2}.except(:a) # => {:b=>2}
```

如果接收者响应 `convert_key` 方法，会在各个参数上调用它。这样 `except` 能更好地处理不区分键类型的散列，例如：

```ruby
{a: 1}.with_indifferent_access.except(:a)  # => {}
{a: 1}.with_indifferent_access.except("a") # => {}
```

还有爆炸版本，`except!`，就地从接收者中删除键。

NOTE: 在 `active_support/core_ext/hash/except.rb` 文件中定义。

<a class="anchor" id="transform-keys-and-transform-keys-bang"></a>

#### `transform_keys` 和 `transform_keys!`

`transform_keys` 方法接受一个块，使用块中的代码处理接收者的键：

```ruby
{nil => nil, 1 => 1, a: :a}.transform_keys { |key| key.to_s.upcase }
# => {"" => nil, "A" => :a, "1" => 1}
```

遇到冲突的键时，只会从中选择一个。选择哪个值并不确定。

```ruby
{"a" => 1, a: 2}.transform_keys { |key| key.to_s.upcase }
# 结果可能是
# => {"A"=>2}
# 也可能是
# => {"A"=>1}
```

这个方法可以用于构建特殊的转换方式。例如，`stringify_keys` 和 `symbolize_keys` 使用 `transform_keys` 转换键：

```ruby
def stringify_keys
  transform_keys { |key| key.to_s }
end
...
def symbolize_keys
  transform_keys { |key| key.to_sym rescue key }
end
```

还有爆炸版本，`transform_keys!`，就地使用块中的代码处理接收者的键。

此外，可以使用 `deep_transform_keys` 和 `deep_transform_keys!` 把块应用到指定散列及其嵌套的散列的所有键上。例如：

```ruby
{nil => nil, 1 => 1, nested: {a: 3, 5 => 5}}.deep_transform_keys { |key| key.to_s.upcase }
# => {""=>nil, "1"=>1, "NESTED"=>{"A"=>3, "5"=>5}}
```

NOTE: 在 `active_support/core_ext/hash/keys.rb` 文件中定义。

<a class="anchor" id="stringify-keys-and-stringify-keys-bang"></a>

#### `stringify_keys` 和 `stringify_keys!`

`stringify_keys` 把接收者中的键都变成字符串，然后返回一个散列。为此，它在键上调用 `to_s`。

```ruby
{nil => nil, 1 => 1, a: :a}.stringify_keys
# => {"" => nil, "1" => 1, "a" => :a}
```

遇到冲突的键时，只会从中选择一个。选择哪个值并不确定。

```ruby
{"a" => 1, a: 2}.stringify_keys
# 结果可能是
# => {"a"=>2}
# 也可能是
# => {"a"=>1}
```

使用这个方法，选项既可以是符号，也可以是字符串。例如 `ActionView::Helpers::FormHelper` 定义的这个方法：

```ruby
def to_check_box_tag(options = {}, checked_value = "1", unchecked_value = "0")
  options = options.stringify_keys
  options["type"] = "checkbox"
  ...
end
```

因为有第二行，所以用户可以传入 `:type` 或 `"type"`。

也有爆炸版本，`stringify_keys!`，直接把接收者的键变成字符串。

此外，可以使用 `deep_stringify_keys` 和 `deep_stringify_keys!` 把指定散列及其中嵌套的散列的键全都转换成字符串。例如：

```ruby
{nil => nil, 1 => 1, nested: {a: 3, 5 => 5}}.deep_stringify_keys
# => {""=>nil, "1"=>1, "nested"=>{"a"=>3, "5"=>5}}
```

NOTE: 在 `active_support/core_ext/hash/keys.rb` 文件中定义。

<a class="anchor" id="symbolize-keys-and-symbolize-keys-bang"></a>

#### `symbolize_keys` 和 `symbolize_keys!`

`symbolize_keys` 方法把接收者中的键尽量变成符号。为此，它在键上调用 `to_sym`。

```ruby
{nil => nil, 1 => 1, "a" => "a"}.symbolize_keys
# => {nil=>nil, 1=>1, :a=>"a"}
```

WARNING: 注意，在上例中，只有键变成了符号。

遇到冲突的键时，只会从中选择一个。选择哪个值并不确定。

```ruby
{"a" => 1, a: 2}.symbolize_keys
# 结果可能是
# => {:a=>2}
# 也可能是
# => {:a=>1}
```

使用这个方法，选项既可以是符号，也可以是字符串。例如 `ActionController::UrlRewriter` 定义的这个方法：

```ruby
def rewrite_path(options)
  options = options.symbolize_keys
  options.update(options[:params].symbolize_keys) if options[:params]
  ...
end
```

因为有第二行，所以用户可以传入 `:params` 或 `"params"`。

也有爆炸版本，`symbolize_keys!`，直接把接收者的键变成符号。

此外，可以使用 `deep_symbolize_keys` 和 `deep_symbolize_keys!` 把指定散列及其中嵌套的散列的键全都转换成符号。例如：

```ruby
{nil => nil, 1 => 1, "nested" => {"a" => 3, 5 => 5}}.deep_symbolize_keys
# => {nil=>nil, 1=>1, nested:{a:3, 5=>5}}
```

NOTE: 在 `active_support/core_ext/hash/keys.rb` 文件中定义。

<a class="anchor" id="to-options-and-to-options-bang"></a>

#### `to_options` 和 `to_options!`

`to_options` 和 `to_options!` 分别是 `symbolize_keys` and `symbolize_keys!` 的别名。

NOTE: 在 `active_support/core_ext/hash/keys.rb` 文件中定义。

<a class="anchor" id="assert-valid-keys"></a>

#### `assert_valid_keys`

`assert_valid_keys` 方法的参数数量不定，检查接收者的键是否在白名单之外。如果是，抛出 `ArgumentError` 异常。

```ruby
{a: 1}.assert_valid_keys(:a)  # passes
{a: 1}.assert_valid_keys("a") # ArgumentError
```

例如，Active Record 构建关联时不接受未知的选项。这个功能就是通过 `assert_valid_keys` 实现的。

NOTE: 在 `active_support/core_ext/hash/keys.rb` 文件中定义。

<a class="anchor" id="working-with-values"></a>

### 处理值

<a class="anchor" id="transform-values-transform-values-bang"></a>

#### `transform_values` 和 `transform_values!`

`transform_values` 的参数是一个块，使用块中的代码处理接收者中的各个值。

```ruby
{ nil => nil, 1 => 1, :x => :a }.transform_values { |value| value.to_s.upcase }
# => {nil=>"", 1=>"1", :x=>"A"}
```

也有爆炸版本，`transform_values!`，就地处理接收者的值。

NOTE: 在 `active_support/core_ext/hash/transform_values.rb` 文件中定义。

<a class="anchor" id="slicing"></a>

### 切片

Ruby 原生支持从字符串和数组中提取切片。Active Support 为散列增加了这个功能：

```ruby
{a: 1, b: 2, c: 3}.slice(:a, :c)
# => {:a=>1, :c=>3}

{a: 1, b: 2, c: 3}.slice(:b, :X)
# => {:b=>2} # 不存在的键会被忽略
```

如果接收者响应 `convert_key`，会使用它对键做整形：

```ruby
{a: 1, b: 2}.with_indifferent_access.slice("a")
# => {:a=>1}
```

NOTE: 可以通过切片使用键白名单净化选项散列。

也有 `slice!`，它就地执行切片，返回被删除的键值对：

```ruby
hash = {a: 1, b: 2}
rest = hash.slice!(:a) # => {:b=>2}
hash                   # => {:a=>1}
```

NOTE: 在 `active_support/core_ext/hash/slice.rb` 文件中定义。

<a class="anchor" id="extracting"></a>

### 提取

`extract!` 方法删除并返回匹配指定键的键值对。

```ruby
hash = {a: 1, b: 2}
rest = hash.extract!(:a) # => {:a=>1}
hash                     # => {:b=>2}
```

`extract!` 方法的返回值类型与接收者一样，是 `Hash` 或其子类。

```ruby
hash = {a: 1, b: 2}.with_indifferent_access
rest = hash.extract!(:a).class
# => ActiveSupport::HashWithIndifferentAccess
```

NOTE: 在 `active_support/core_ext/hash/slice.rb` 文件中定义。

<a class="anchor" id="indifferent-access"></a>

### 无差别访问

`with_indifferent_access` 方法把接收者转换成 `ActiveSupport::HashWithIndifferentAccess` 实例：

```ruby
{a: 1}.with_indifferent_access["a"] # => 1
```

NOTE: 在 `active_support/core_ext/hash/indifferent_access.rb` 文件中定义。

<a class="anchor" id="compacting"></a>

### 压缩

`compact` 和 `compact!` 方法返回没有 `nil` 值的散列：

```ruby
{a: 1, b: 2, c: nil}.compact # => {a: 1, b: 2}
```

NOTE: 在 `active_support/core_ext/hash/compact.rb` 文件中定义。

<a class="anchor" id="extensions-to-regexp"></a>

## `Regexp` 的扩展

<a class="anchor" id="multiline-questionmark"></a>

### `multiline?`

`multiline?` 方法判断正则表达式有没有设定 `/m` 旗标，即点号是否匹配换行符。

```ruby
%r{.}.multiline?  # => false
%r{.}m.multiline? # => true

Regexp.new('.').multiline?                    # => false
Regexp.new('.', Regexp::MULTILINE).multiline? # => true
```

Rails 只在一处用到了这个方法，也在路由代码中。路由的条件不允许使用多行正则表达式，这个方法简化了这一约束的实施。

```ruby
def assign_route_options(segments, defaults, requirements)
  ...
  if requirement.multiline?
    raise ArgumentError, "Regexp multiline option not allowed in routing requirements: #{requirement.inspect}"
  end
  ...
end
```

NOTE: 在 `active_support/core_ext/regexp.rb` 文件中定义。

<a class="anchor" id="match-questionmark"></a>

### `match?`

Rails 实现了 `Regexp#match?` 方法，供 Ruby 2.4 之前的版本使用：

```ruby
/oo/.match?('foo')    # => true
/oo/.match?('bar')    # => false
/oo/.match?('foo', 1) # => true
```

这个向后移植的版本与原生的 `match?` 方法具有相同的接口，但是调用方没有未设定 `$1` 等副作用，不过速度没什么优势。定义这个方法的目的是编写与 2.4 兼容的代码。Rails 内部有用到这个判断方法。

只有 Ruby 未定义 `Regexp#match?` 方法时，Rails 才会定义，因此在 Ruby 2.4 或以上版本中运行的代码使用的是原生版本，性能有保障。

<a class="anchor" id="extensions-to-range"></a>

## `Range` 的扩展

<a class="anchor" id="extensions-to-range-to-s"></a>

### `to_s`

Active Support 扩展了 `Range#to_s` 方法，让它接受一个可选的格式参数。目前，唯一支持的非默认格式是 `:db`：

```ruby
(Date.today..Date.tomorrow).to_s
# => "2009-10-25..2009-10-26"

(Date.today..Date.tomorrow).to_s(:db)
# => "BETWEEN '2009-10-25' AND '2009-10-26'"
```

如上例所示，`:db` 格式生成一个 `BETWEEN` SQL 子句。Active Record 使用它支持范围值条件。

NOTE: 在 `active_support/core_ext/range/conversions.rb` 文件中定义。

<a class="anchor" id="include-questionmark"></a>

### `include?`

`Range#include?` 和 `Range#===` 方法判断值是否在值域的范围内：

```ruby
(2..3).include?(Math::E) # => true
```

Active Support 扩展了这两个方法，允许参数为另一个值域。此时，测试参数指定的值域是否在接收者的范围内：

```ruby
(1..10).include?(3..7)  # => true
(1..10).include?(0..7)  # => false
(1..10).include?(3..11) # => false
(1...9).include?(3..9)  # => false

(1..10) === (3..7)  # => true
(1..10) === (0..7)  # => false
(1..10) === (3..11) # => false
(1...9) === (3..9)  # => false
```

NOTE: 在 `active_support/core_ext/range/include_range.rb` 文件中定义。

<a class="anchor" id="overlaps-questionmark"></a>

### `overlaps?`

`Range#overlaps?` 方法测试两个值域是否有交集：

```ruby
(1..10).overlaps?(7..11)  # => true
(1..10).overlaps?(0..7)   # => true
(1..10).overlaps?(11..27) # => false
```

NOTE: 在 `active_support/core_ext/range/overlaps.rb` 文件中定义。

<a class="anchor" id="extensions-to-date"></a>

## `Date` 的扩展

<a class="anchor" id="extensions-to-date-calculations"></a>

### 计算

NOTE: 这一节的方法都在 `active_support/core_ext/date/calculations.rb` 文件中定义。

TIP: 下述计算方法在 1582 年 10 月有边缘情况，因为 5..14 日不存在。简单起见，本文没有说明这些日子的行为，不过可以说，其行为与预期是相符的。即，`Date.new(1582, 10, 4).tomorrow` 返回 `Date.new(1582, 10, 15)`，等等。预期的行为参见 `test/core_ext/date_ext_test.rb` 中的 Active Support 测试组件。

<a class="anchor" id="date-current"></a>

#### `Date.current`

Active Support 定义的 `Date.current` 方法表示当前时区中的今天。其作用类似于 `Date.today`，不过会考虑用户设定的时区（如果定义了时区的话）。Active Support 还定义了 `Date.yesterday` 和 `Date.tomorrow`，以及实例判断方法 `past?`、`today?`、`future?`、`on_weekday?` 和 `on_weekend?`，这些方法都与 `Date.current` 相关。

比较日期时，如果要考虑用户设定的时区，应该使用 `Date.current`，而不是 `Date.today`。与系统的时区（`Date.today` 默认采用）相比，用户设定的时区可能超前，这意味着，`Date.today` 可能等于 `Date.yesterday`。

<a class="anchor" id="named-dates"></a>

#### 具名日期

<a class="anchor" id="prev-year-next-year"></a>

##### `prev_year`、`next_year`

在 Ruby 1.9 中，`prev_year` 和 `next_year` 方法返回前一年和下一年中的相同月和日：

```ruby
d = Date.new(2010, 5, 8) # => Sat, 08 May 2010
d.prev_year              # => Fri, 08 May 2009
d.next_year              # => Sun, 08 May 2011
```

如果是润年的 2 月 29 日，得到的是 28 日：

```ruby
d = Date.new(2000, 2, 29) # => Tue, 29 Feb 2000
d.prev_year               # => Sun, 28 Feb 1999
d.next_year               # => Wed, 28 Feb 2001
```

`last_year` 是 `prev_year` 的别名。

<a class="anchor" id="prev-month-next-month"></a>

##### `prev_month`、`next_month`

在 Ruby 1.9 中，`prev_month` 和 `next_month` 方法分别返回前一个月和后一个月中的相同日：

```ruby
d = Date.new(2010, 5, 8) # => Sat, 08 May 2010
d.prev_month             # => Thu, 08 Apr 2010
d.next_month             # => Tue, 08 Jun 2010
```

如果日不存在，返回前一月中的最后一天：

```ruby
Date.new(2000, 5, 31).prev_month # => Sun, 30 Apr 2000
Date.new(2000, 3, 31).prev_month # => Tue, 29 Feb 2000
Date.new(2000, 5, 31).next_month # => Fri, 30 Jun 2000
Date.new(2000, 1, 31).next_month # => Tue, 29 Feb 2000
```

`last_month` 是 `prev_month` 的别名。

<a class="anchor" id="prev-quarter-next-quarter"></a>

##### `prev_quarter`、`next_quarter`

类似于 `prev_month` 和 `next_month`，返回前一季度和下一季度中的相同日：

```ruby
t = Time.local(2010, 5, 8) # => Sat, 08 May 2010
t.prev_quarter             # => Mon, 08 Feb 2010
t.next_quarter             # => Sun, 08 Aug 2010
```

如果日不存在，返回前一月中的最后一天：

```ruby
Time.local(2000, 7, 31).prev_quarter  # => Sun, 30 Apr 2000
Time.local(2000, 5, 31).prev_quarter  # => Tue, 29 Feb 2000
Time.local(2000, 10, 31).prev_quarter # => Mon, 30 Oct 2000
Time.local(2000, 11, 31).next_quarter # => Wed, 28 Feb 2001
```

`last_quarter` 是 `prev_quarter` 的别名。

<a class="anchor" id="beginning-of-week-end-of-week"></a>

##### `beginning_of_week`、`end_of_week`

`beginning_of_week` 和 `end_of_week` 方法分别返回某一周的第一天和最后一天的日期。一周假定从周一开始，不过这是可以修改的，方法是在线程中设定 `Date.beginning_of_week` 或 `config.beginning_of_week`。

```ruby
d = Date.new(2010, 5, 8)     # => Sat, 08 May 2010
d.beginning_of_week          # => Mon, 03 May 2010
d.beginning_of_week(:sunday) # => Sun, 02 May 2010
d.end_of_week                # => Sun, 09 May 2010
d.end_of_week(:sunday)       # => Sat, 08 May 2010
```

`at_beginning_of_week` 是 `beginning_of_week` 的别名，`at_end_of_week` 是 `end_of_week` 的别名。

<a class="anchor" id="monday-sunday"></a>

##### `monday`、`sunday`

`monday` 和 `sunday` 方法分别返回前一个周一和下一个周日的日期：

```ruby
d = Date.new(2010, 5, 8)     # => Sat, 08 May 2010
d.monday                     # => Mon, 03 May 2010
d.sunday                     # => Sun, 09 May 2010

d = Date.new(2012, 9, 10)    # => Mon, 10 Sep 2012
d.monday                     # => Mon, 10 Sep 2012

d = Date.new(2012, 9, 16)    # => Sun, 16 Sep 2012
d.sunday                     # => Sun, 16 Sep 2012
```

<a class="anchor" id="prev-week-next-week"></a>

##### `prev_week`、`next_week`

`next_week` 的参数是一个符号，指定周几的英文名称（默认为线程中的 `Date.beginning_of_week` 或 `config.beginning_of_week`，或者 `:monday`），返回那一天的日期。

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.next_week              # => Mon, 10 May 2010
d.next_week(:saturday)   # => Sat, 15 May 2010
```

`prev_week` 的作用类似：

```ruby
d.prev_week              # => Mon, 26 Apr 2010
d.prev_week(:saturday)   # => Sat, 01 May 2010
d.prev_week(:friday)     # => Fri, 30 Apr 2010
```

`last_week` 是 `prev_week` 的别名。

设定 `Date.beginning_of_week` 或 `config.beginning_of_week` 之后，`next_week` 和 `prev_week` 能按预期工作。

<a class="anchor" id="beginning-of-month-end-of-month"></a>

##### `beginning_of_month`、`end_of_month`

`beginning_of_month` 和 `end_of_month` 方法分别返回某个月的第一天和最后一天的日期：

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.beginning_of_month     # => Sat, 01 May 2010
d.end_of_month           # => Mon, 31 May 2010
```

`at_beginning_of_month` 是 `beginning_of_month` 的别名，`at_end_of_month` 是 `end_of_month` 的别名。

<a class="anchor" id="beginning-of-quarter-end-of-quarter"></a>

##### `beginning_of_quarter`、`end_of_quarter`

`beginning_of_quarter` 和 `end_of_quarter` 分别返回接收者日历年的季度第一天和最后一天的日期：

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.beginning_of_quarter   # => Thu, 01 Apr 2010
d.end_of_quarter         # => Wed, 30 Jun 2010
```

`at_beginning_of_quarter` 是 `beginning_of_quarter` 的别名，`at_end_of_quarter` 是 `end_of_quarter` 的别名。

<a class="anchor" id="beginning-of-year-end-of-year"></a>

##### `beginning_of_year`、`end_of_year`

`beginning_of_year` 和 `end_of_year` 方法分别返回一年的第一天和最后一天的日期：

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.beginning_of_year      # => Fri, 01 Jan 2010
d.end_of_year            # => Fri, 31 Dec 2010
```

`at_beginning_of_year` 是 `beginning_of_year` 的别名，`at_end_of_year` 是 `end_of_year` 的别名。

<a class="anchor" id="other-date-computations"></a>

#### 其他日期计算方法

<a class="anchor" id="years-ago-years-since"></a>

##### `years_ago`、`years_since`

`years_ago` 方法的参数是一个数字，返回那么多年以前同一天的日期：

```ruby
date = Date.new(2010, 6, 7)
date.years_ago(10) # => Wed, 07 Jun 2000
```

`years_since` 方法向前移动时间：

```ruby
date = Date.new(2010, 6, 7)
date.years_since(10) # => Sun, 07 Jun 2020
```

如果那一天不存在，返回前一个月的最后一天：

```ruby
Date.new(2012, 2, 29).years_ago(3)     # => Sat, 28 Feb 2009
Date.new(2012, 2, 29).years_since(3)   # => Sat, 28 Feb 2015
```

<a class="anchor" id="months-ago-months-since"></a>

##### `months_ago`、`months_since`

`months_ago` 和 `months_since` 方法的作用类似，不过是针对月的：

```ruby
Date.new(2010, 4, 30).months_ago(2)   # => Sun, 28 Feb 2010
Date.new(2010, 4, 30).months_since(2) # => Wed, 30 Jun 2010
```

如果那一天不存在，返回前一个月的最后一天：

```ruby
Date.new(2010, 4, 30).months_ago(2)    # => Sun, 28 Feb 2010
Date.new(2009, 12, 31).months_since(2) # => Sun, 28 Feb 2010
```

<a class="anchor" id="weeks-ago"></a>

##### `weeks_ago`

`weeks_ago` 方法的作用类似，不过是针对周的：

```ruby
Date.new(2010, 5, 24).weeks_ago(1)    # => Mon, 17 May 2010
Date.new(2010, 5, 24).weeks_ago(2)    # => Mon, 10 May 2010
```

<a class="anchor" id="other-date-computations-advance"></a>

##### `advance`

跳到另一天最普适的方法是 `advance`。这个方法的参数是一个散列，包含 `:years`、`:months`、`:weeks`、`:days` 键，返回移动相应量之后的日期。

```ruby
date = Date.new(2010, 6, 6)
date.advance(years: 1, weeks: 2)  # => Mon, 20 Jun 2011
date.advance(months: 2, days: -2) # => Wed, 04 Aug 2010
```

如上例所示，增量可以是负数。

这个方法做计算时，先增加年，然后是月和周，最后是日。这个顺序是重要的，向一个月的末尾流动。假如我们在 2010 年 2 月的最后一天，我们想向前移动一个月和一天。

此时，`advance` 先向前移动一个月，然后移动一天，结果是：

```ruby
Date.new(2010, 2, 28).advance(months: 1, days: 1)
# => Sun, 29 Mar 2010
```

如果以其他方式移动，得到的结果就不同了：

```ruby
Date.new(2010, 2, 28).advance(days: 1).advance(months: 1)
# => Thu, 01 Apr 2010
```

<a class="anchor" id="extensions-to-date-calculations-changing-components"></a>

#### 修改日期组成部分

`change` 方法在接收者的基础上修改日期，修改的值由参数指定：

```ruby
Date.new(2010, 12, 23).change(year: 2011, month: 11)
# => Wed, 23 Nov 2011
```

这个方法无法容错不存在的日期，如果修改无效，抛出 `ArgumentError` 异常：

```ruby
Date.new(2010, 1, 31).change(month: 2)
# => ArgumentError: invalid date
```

<a class="anchor" id="extensions-to-date-calculations-durations"></a>

#### 时间跨度

可以为日期增加或减去时间跨度：

```ruby
d = Date.current
# => Mon, 09 Aug 2010
d + 1.year
# => Tue, 09 Aug 2011
d - 3.hours
# => Sun, 08 Aug 2010 21:00:00 UTC +00:00
```

增加跨度会调用 `since` 或 `advance`。例如，跳跃时能正确考虑历法改革：

```ruby
Date.new(1582, 10, 4) + 1.day
# => Fri, 15 Oct 1582
```

<a class="anchor" id="timestamps"></a>

#### 时间戳

TIP: 如果可能，下述方法返回 `Time` 对象，否则返回 `DateTime` 对象。如果用户设定了时区，会将其考虑在内。

<a class="anchor" id="beginning-of-day-end-of-day"></a>

##### `beginning_of_day`、`end_of_day`

`beginning_of_day` 方法返回一天的起始时间戳（00:00:00）：

```ruby
date = Date.new(2010, 6, 7)
date.beginning_of_day # => Mon Jun 07 00:00:00 +0200 2010
```

`end_of_day` 方法返回一天的结束时间戳（23:59:59）：

```ruby
date = Date.new(2010, 6, 7)
date.end_of_day # => Mon Jun 07 23:59:59 +0200 2010
```

`at_beginning_of_day`、`midnight` 和 `at_midnight` 是 `beginning_of_day` 的别名，

<a class="anchor" id="beginning-of-hour-end-of-hour"></a>

##### `beginning_of_hour`、`end_of_hour`

`beginning_of_hour` 返回一小时的起始时间戳（hh:00:00）：

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.beginning_of_hour # => Mon Jun 07 19:00:00 +0200 2010
```

`end_of_hour` 方法返回一小时的结束时间戳（hh:59:59）：

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.end_of_hour # => Mon Jun 07 19:59:59 +0200 2010
```

`at_beginning_of_hour` 是 `beginning_of_hour` 的别名。

<a class="anchor" id="beginning-of-minute-end-of-minute"></a>

##### `beginning_of_minute`、`end_of_minute`

`beginning_of_minute` 方法返回一分钟的起始时间戳（hh:mm:00）：

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.beginning_of_minute # => Mon Jun 07 19:55:00 +0200 2010
```

`end_of_minute` 方法返回一分钟的结束时间戳（hh:mm:59）：

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.end_of_minute # => Mon Jun 07 19:55:59 +0200 2010
```

`at_beginning_of_minute` 是 `beginning_of_minute` 的别名。

TIP: `Time` 和 `DateTime` 实现了 `beginning_of_hour`、`end_of_hour`、`beginning_of_minute` 和 `end_of_minute` 方法，但是 `Date` 没有实现，因为在 `Date` 实例上请求小时和分钟的起始和结束时间戳没有意义。

<a class="anchor" id="ago-since"></a>

##### `ago`、`since`

`ago` 的参数是秒数，返回自午夜起那么多秒之后的时间戳：

```ruby
date = Date.current # => Fri, 11 Jun 2010
date.ago(1)         # => Thu, 10 Jun 2010 23:59:59 EDT -04:00
```

类似的，`since` 向前移动：

```ruby
date = Date.current # => Fri, 11 Jun 2010
date.since(1)       # => Fri, 11 Jun 2010 00:00:01 EDT -04:00
```

<a class="anchor" id="extensions-to-datetime"></a>

## `DateTime` 的扩展

WARNING: `DateTime` 不理解夏令时规则，因此如果正处于夏令时，这些方法可能有边缘情况。例如，在夏令时中，`seconds_since_midnight` 可能无法返回真实的量。

<a class="anchor" id="extensions-to-datetime-calculations"></a>

### 计算

NOTE: 本节的方法都在 `active_support/core_ext/date_time/calculations.rb` 文件中定义。

`DateTime` 类是 `Date` 的子类，因此加载 `active_support/core_ext/date/calculations.rb` 时也就继承了下述方法及其别名，只不过，此时都返回 `DateTime` 对象：

```text
yesterday
tomorrow
beginning_of_week (at_beginning_of_week)
end_of_week (at_end_of_week)
monday
sunday
weeks_ago
prev_week (last_week)
next_week
months_ago
months_since
beginning_of_month (at_beginning_of_month)
end_of_month (at_end_of_month)
prev_month (last_month)
next_month
beginning_of_quarter (at_beginning_of_quarter)
end_of_quarter (at_end_of_quarter)
beginning_of_year (at_beginning_of_year)
end_of_year (at_end_of_year)
years_ago
years_since
prev_year (last_year)
next_year
on_weekday?
on_weekend?
```

下述方法重新实现了，因此使用它们时无需加载 `active_support/core_ext/date/calculations.rb`：

```text
beginning_of_day (midnight, at_midnight, at_beginning_of_day)
end_of_day
ago
since (in)
```

此外，还定义了 `advance` 和 `change` 方法，而且支持更多选项。参见下文。

下述方法只在 `active_support/core_ext/date_time/calculations.rb` 中实现，因为它们只对 `DateTime` 实例有意义：

```ruby
beginning_of_hour (at_beginning_of_hour)
end_of_hour
```

<a class="anchor" id="named-datetimes"></a>

#### 具名日期时间

<a class="anchor" id="datetime-current"></a>

##### `DateTime.current`

Active Support 定义的 `DateTime.current` 方法类似于 `Time.now.to_datetime`，不过会考虑用户设定的时区（如果定义了时区的话）。Active Support 还定义了 `DateTime.yesterday` 和 `DateTime.tomorrow`，以及与 `DateTime.current` 相关的判断方法 `past?` 和 `future?`。

<a class="anchor" id="other-extensions"></a>

#### 其他扩展

<a class="anchor" id="seconds-since-midnight"></a>

##### `seconds_since_midnight`

`seconds_since_midnight` 方法返回自午夜起的秒数：

```ruby
now = DateTime.current     # => Mon, 07 Jun 2010 20:26:36 +0000
now.seconds_since_midnight # => 73596
```

<a class="anchor" id="utc"></a>

##### `utc`

`utc` 返回的日期时间与接收者一样，不过使用 UTC 表示。

```ruby
now = DateTime.current # => Mon, 07 Jun 2010 19:27:52 -0400
now.utc                # => Mon, 07 Jun 2010 23:27:52 +0000
```

这个方法有个别名，`getutc`。

<a class="anchor" id="utc-questionmark"></a>

##### `utc?`

`utc?` 判断接收者的时区是不是 UTC：

```ruby
now = DateTime.now # => Mon, 07 Jun 2010 19:30:47 -0400
now.utc?           # => false
now.utc.utc?       # => true
```

<a class="anchor" id="other-extensions-advance"></a>

##### `advance`

跳到其他日期时间最普适的方法是 `advance`。这个方法的参数是一个散列，包含 `:years`、`:months`、`:weeks`、`:days`、`:hours`、`:minutes` 和 `:seconds` 等键，返回移动相应量之后的日期时间。

```ruby
d = DateTime.current
# => Thu, 05 Aug 2010 11:33:31 +0000
d.advance(years: 1, months: 1, days: 1, hours: 1, minutes: 1, seconds: 1)
# => Tue, 06 Sep 2011 12:34:32 +0000
```

这个方法计算目标日期时，把 `:years`、`:months`、`:weeks` 和 `:days` 传给 `Date#advance`，然后调用 `since` 处理时间，前进相应的秒数。这个顺序是重要的，如若不然，在某些边缘情况下可能得到不同的日期时间。讲解 `Date#advance` 时所举的例子在这里也适用，我们可以扩展一下，显示处理时间的顺序。

如果先移动日期部分（如前文所述，处理日期的顺序也很重要），然后再计算时间，得到的结果如下：

```ruby
d = DateTime.new(2010, 2, 28, 23, 59, 59)
# => Sun, 28 Feb 2010 23:59:59 +0000
d.advance(months: 1, seconds: 1)
# => Mon, 29 Mar 2010 00:00:00 +0000
```

但是如果以其他方式计算，结果就不同了：

```ruby
d.advance(seconds: 1).advance(months: 1)
# => Thu, 01 Apr 2010 00:00:00 +0000
```

WARNING: 因为 `DateTime` 不支持夏令时，所以可能得到不存在的时间点，而且没有提醒或报错。

<a class="anchor" id="extensions-to-datetime-calculations-changing-components"></a>

#### 修改日期时间组成部分

`change` 方法在接收者的基础上修改日期时间，修改的值由选项指定，可以包括 `:year`、`:month`、`:day`、`:hour`、`:min`、`:sec`、`:offset` 和 `:start`：

```ruby
now = DateTime.current
# => Tue, 08 Jun 2010 01:56:22 +0000
now.change(year: 2011, offset: Rational(-6, 24))
# => Wed, 08 Jun 2011 01:56:22 -0600
```

如果小时归零了，分钟和秒也归零（除非指定了值）：

```ruby
now.change(hour: 0)
# => Tue, 08 Jun 2010 00:00:00 +0000
```

类似地，如果分钟归零了，秒也归零（除非指定了值）：

```ruby
now.change(min: 0)
# => Tue, 08 Jun 2010 01:00:00 +0000
```

这个方法无法容错不存在的日期，如果修改无效，抛出 `ArgumentError` 异常：

```ruby
DateTime.current.change(month: 2, day: 30)
# => ArgumentError: invalid date
```

<a class="anchor" id="extensions-to-datetime-calculations-durations"></a>

#### 时间跨度

可以为日期时间增加或减去时间跨度：

```ruby
now = DateTime.current
# => Mon, 09 Aug 2010 23:15:17 +0000
now + 1.year
# => Tue, 09 Aug 2011 23:15:17 +0000
now - 1.week
# => Mon, 02 Aug 2010 23:15:17 +0000
```

增加跨度会调用 `since` 或 `advance`。例如，跳跃时能正确考虑历法改革：

```ruby
DateTime.new(1582, 10, 4, 23) + 1.hour
# => Fri, 15 Oct 1582 00:00:00 +0000
```

<a class="anchor" id="extensions-to-time"></a>

## `Time` 的扩展

<a class="anchor" id="extensions-to-time-calculations"></a>

### 计算

NOTE: 本节的方法都在 `active_support/core_ext/time/calculations.rb` 文件中定义。

Active Support 为 `Time` 添加了 `DateTime` 的很多方法：

```text
past?
today?
future?
yesterday
tomorrow
seconds_since_midnight
change
advance
ago
since (in)
beginning_of_day (midnight, at_midnight, at_beginning_of_day)
end_of_day
beginning_of_hour (at_beginning_of_hour)
end_of_hour
beginning_of_week (at_beginning_of_week)
end_of_week (at_end_of_week)
monday
sunday
weeks_ago
prev_week (last_week)
next_week
months_ago
months_since
beginning_of_month (at_beginning_of_month)
end_of_month (at_end_of_month)
prev_month (last_month)
next_month
beginning_of_quarter (at_beginning_of_quarter)
end_of_quarter (at_end_of_quarter)
beginning_of_year (at_beginning_of_year)
end_of_year (at_end_of_year)
years_ago
years_since
prev_year (last_year)
next_year
on_weekday?
on_weekend?
```

它们的作用与之前类似。详情参见前文，不过要知道下述区别：

*   `change` 额外接受 `:usec` 选项。
*   `Time` 支持夏令时，因此能正确计算夏令时。

    ```ruby
    Time.zone_default
    # => #<ActiveSupport::TimeZone:0x7f73654d4f38 @utc_offset=nil, @name="Madrid", ...>
    
    # 因为采用夏令时，在巴塞罗那，2010/03/28 02:00 +0100 变成 2010/03/28 03:00 +0200
    t = Time.local(2010, 3, 28, 1, 59, 59)
    # => Sun Mar 28 01:59:59 +0100 2010
    t.advance(seconds: 1)
    # => Sun Mar 28 03:00:00 +0200 2010
    ```


*   如果 `since` 或 `ago` 的目标时间无法使用 `Time` 对象表示，返回一个 `DateTime` 对象。

<a class="anchor" id="time-current"></a>

#### `Time.current`

Active Support 定义的 `Time.current` 方法表示当前时区中的今天。其作用类似于 `Time.now`，不过会考虑用户设定的时区（如果定义了时区的话）。Active Support 还定义了与 `Time.current` 有关的实例判断方法 `past?`、`today?` 和 `future?`。

比较时间时，如果要考虑用户设定的时区，应该使用 `Time.current`，而不是 `Time.now`。与系统的时区（`Time.now` 默认采用）相比，用户设定的时区可能超前，这意味着，`Time.now.to_date` 可能等于 `Date.yesterday`。

<a class="anchor" id="all-day-all-week-all-month-all-quarter-and-all-year"></a>

#### `all_day`、`all_week`、`all_month`、`all_quarter` 和 `all_year`

`all_day` 方法返回一个值域，表示当前时间的一整天。

```ruby
now = Time.current
# => Mon, 09 Aug 2010 23:20:05 UTC +00:00
now.all_day
# => Mon, 09 Aug 2010 00:00:00 UTC +00:00..Mon, 09 Aug 2010 23:59:59 UTC +00:00
```

类似地，`all_week`、`all_month`、`all_quarter` 和 `all_year` 分别生成相应的时间值域。

```ruby
now = Time.current
# => Mon, 09 Aug 2010 23:20:05 UTC +00:00
now.all_week
# => Mon, 09 Aug 2010 00:00:00 UTC +00:00..Sun, 15 Aug 2010 23:59:59 UTC +00:00
now.all_week(:sunday)
# => Sun, 16 Sep 2012 00:00:00 UTC +00:00..Sat, 22 Sep 2012 23:59:59 UTC +00:00
now.all_month
# => Sat, 01 Aug 2010 00:00:00 UTC +00:00..Tue, 31 Aug 2010 23:59:59 UTC +00:00
now.all_quarter
# => Thu, 01 Jul 2010 00:00:00 UTC +00:00..Thu, 30 Sep 2010 23:59:59 UTC +00:00
now.all_year
# => Fri, 01 Jan 2010 00:00:00 UTC +00:00..Fri, 31 Dec 2010 23:59:59 UTC +00:00
```

<a class="anchor" id="time-constructors"></a>

### 时间构造方法

Active Support 定义的 `Time.current` 方法，在用户设定了时区时，等价于 `Time.zone.now`，否则回落到 `Time.now`：

```ruby
Time.zone_default
# => #<ActiveSupport::TimeZone:0x7f73654d4f38 @utc_offset=nil, @name="Madrid", ...>
Time.current
# => Fri, 06 Aug 2010 17:11:58 CEST +02:00
```

与 `DateTime` 一样，判断方法 `past?` 和 `future?` 与 `Time.current` 相关。

如果要构造的时间超出了运行时平台对 `Time` 的支持范围，微秒会被丢掉，然后返回 `DateTime` 对象。

<a class="anchor" id="durations"></a>

#### 时间跨度

可以为时间增加或减去时间跨度：

```ruby
now = Time.current
# => Mon, 09 Aug 2010 23:20:05 UTC +00:00
now + 1.year
#  => Tue, 09 Aug 2011 23:21:11 UTC +00:00
now - 1.week
# => Mon, 02 Aug 2010 23:21:11 UTC +00:00
```

增加跨度会调用 `since` 或 `advance`。例如，跳跃时能正确考虑历法改革：

```ruby
Time.utc(1582, 10, 3) + 5.days
# => Mon Oct 18 00:00:00 UTC 1582
```

<a class="anchor" id="extensions-to-file"></a>

## `File` 的扩展

<a class="anchor" id="atomic-write"></a>

### `atomic_write`

使用类方法 `File.atomic_write` 写文件时，可以避免在写到一半时读取内容。

这个方法的参数是文件名，它会产出一个文件句柄，把文件打开供写入。块执行完毕后，`atomic_write` 会关闭文件句柄，完成工作。

例如，Action Pack 使用这个方法写静态资源缓存文件，如 `all.css`：

```ruby
File.atomic_write(joined_asset_path) do |cache|
  cache.write(join_asset_file_contents(asset_paths))
end
```

为此，`atomic_write` 会创建一个临时文件。块中的代码其实是向这个临时文件写入。写完之后，重命名临时文件，这在 POSIX 系统中是原子操作。如果目标文件存在，`atomic_write` 将其覆盖，并且保留属主和权限。不过，有时 `atomic_write` 无法修改文件的归属或权限。这个错误会被捕获并跳过，从而确保需要它的进程能访问它。

NOTE: `atomic_write` 会执行 chmod 操作，因此如果目标文件设定了 ACL，`atomic_write` 会重新计算或修改 ACL。

WARNING: 注意，不能使用 `atomic_write` 追加内容。

临时文件在存储临时文件的标准目录中，但是可以传入第二个参数指定一个目录。

NOTE: 在 `active_support/core_ext/file/atomic.rb` 文件中定义。

<a class="anchor" id="extensions-to-marshal"></a>

## `Marshal` 的扩展

<a class="anchor" id="load"></a>

### `load`

Active Support 为 `load` 增加了常量自动加载功能。

例如，文件缓存存储像这样反序列化：

```ruby
File.open(file_name) { |f| Marshal.load(f) }
```

如果缓存的数据指代那一刻未知的常量，自动加载机制会被触发，如果成功加载，会再次尝试反序列化。

WARNING: 如果参数是 `IO` 对象，要能响应 `rewind` 方法才会重试。常规的文件响应 `rewind` 方法。

NOTE: 在 `active_support/core_ext/marshal.rb` 文件中定义。

<a class="anchor" id="extensions-to-nameerror"></a>

## `NameError` 的扩展

Active Support 为 `NameError` 增加了 `missing_name?` 方法，测试异常是不是由于参数的名称引起的。

参数的名称可以使用符号或字符串指定。指定符号时，使用裸常量名测试；指定字符串时，使用完全限定常量名测试。

TIP: 符号可以表示完全限定常量名，例如 `:"ActiveRecord::Base"`，因此这里符号的行为是为了便利而特别定义的，不是说在技术上只能如此。

例如，调用 `ArticlesController` 的动作时，Rails 会乐观地使用 `ArticlesHelper`。如果那个模块不存在也没关系，因此，由那个常量名引起的异常要静默。不过，可能是由于确实是未知的常量名而由 `articles_helper.rb` 抛出的 `NameError` 异常。此时，异常应该抛出。`missing_name?` 方法能区分这两种情况：

```ruby
def default_helper_module!
  module_name = name.sub(/Controller$/, '')
  module_path = module_name.underscore
  helper module_path
rescue LoadError => e
  raise e unless e.is_missing? "helpers/#{module_path}_helper"
rescue NameError => e
  raise e unless e.missing_name? "#{module_name}Helper"
end
```

NOTE: 在 `active_support/core_ext/name_error.rb` 文件中定义。

<a class="anchor" id="extensions-to-loaderror"></a>

## `LoadError` 的扩展

Active Support 为 `LoadError` 增加了 `is_missing?` 方法。

`is_missing?` 方法判断异常是不是由指定路径名（不含“.rb”扩展名）引起的。

例如，调用 `ArticlesController` 的动作时，Rails 会尝试加载 `articles_helper.rb`，但是那个文件可能不存在。这没关系，辅助模块不是必须的，因此 Rails 会静默加载错误。但是，有可能是辅助模块存在，而它引用的其他库不存在。此时，Rails 必须抛出异常。`is_missing?` 方法能区分这两种情况：

```ruby
def default_helper_module!
  module_name = name.sub(/Controller$/, '')
  module_path = module_name.underscore
  helper module_path
rescue LoadError => e
  raise e unless e.is_missing? "helpers/#{module_path}_helper"
rescue NameError => e
  raise e unless e.missing_name? "#{module_name}Helper"
end
```

NOTE: 在 `active_support/core_ext/load_error.rb` 文件中定义。
