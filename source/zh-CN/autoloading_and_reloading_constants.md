# 自动加载和重新加载常量

本文说明常量自动加载和重新加载机制。

读完本文后，您将学到：

*   Ruby 常量的关键知识；
*   `autoload_paths` 是什么；
*   常量是如何自动加载的；
*   `require_dependency` 是什么；
*   常量是如何重新加载的；
*   自动加载常见问题的解决方案。

-----------------------------------------------------------------------------

<a class="anchor" id="introduction"></a>

## 简介

编写 Ruby on Rails 应用时，代码会预加载。

在常规的 Ruby 程序中，类需要加载依赖：

```ruby
require 'application_controller'
require 'post'

class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

Ruby 程序员的直觉立即就能发现这样做有冗余：如果类定义所在的文件与类名一致，难道不能通过某种方式自动加载吗？我们无需扫描文件寻找依赖，这样不可靠。

而且，`Kernel#require` 只加载文件一次，如果修改后无需重启服务器，那么开发的过程就更为平顺。如果能在开发环境中使用 `Kernel#load`，而在生产环境使用 `Kernel#require`，那该多好。

其实，Ruby on Rails 就有这样的功能，我们刚才已经用到了：

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

本文说明这一机制的运作原理。

<a class="anchor" id="constants-refresher"></a>

## 常量刷新程序

在多数编程语言中，常量不是那么重要，但在 Ruby 中却是一个内容丰富的话题。

本文不会详解 Ruby 常量，但是会重点说明关键的概念。掌握以下几小节的内容对理解常量自动加载和重新加载有所帮助。

<a class="anchor" id="nesting"></a>

### 嵌套

类和模块定义可以嵌套，从而创建命名空间：

```ruby
module XML
  class SAXParser
    # (1)
  end
end
```

类和模块的嵌套由内向外展开。嵌套可以通过 `Module.nesting` 方法审查。例如，在上述示例中，(1) 处的嵌套是

```
[XML::SAXParser, XML]
```

注意，组成嵌套的是类和模块“对象”，而不是访问它们的常量，与它们的名称也没有关系。

例如，对下面的定义来说

```ruby
class XML::SAXParser
  # (2)
end
```

虽然作用跟前一个示例类似，但是 (2) 处的嵌套是

```
[XML::SAXParser]
```

不含“XML”。

从这个示例可以看出，嵌套中的类或模块的名称与所在的命名空间没有必然联系。

事实上，二者毫无关系。比如说：

```ruby
module X
  module Y
  end
end

module A
  module B
  end
end

module X::Y
  module A::B
    # (3)
  end
end
```

(3) 处的嵌套包含两个模块对象：

```
[A::B, X::Y]
```

可以看出，嵌套的最后不是“A”，甚至不含“A”，但是包含 `X::Y`，而且它与 `A::B` 无关。

嵌套是解释器维护的一个内部堆栈，根据下述规则修改：

*   执行 `class` 关键字后面的定义体时，类对象入栈；执行完毕后出栈。
*   执行 `module` 关键字后面的定义体时，模块对象入栈；执行完毕后出栈。
*   执行 `class << object` 打开的单例类时，类对象入栈；执行完毕后出栈。
*   调用 `instance_eval` 时如果传入字符串参数，接收者的单例类入栈求值的代码所在的嵌套层次。调用 `class_eval` 或 `module_eval` 时如果传入字符串参数，接收者入栈求值的代码所在的嵌套层次.
*   顶层代码中由 `Kernel#load` 解释嵌套是空的，除非调用 `load` 时把第二个参数设为真值；如果是这样，Ruby 会创建一个匿名模块，将其入栈。

注意，块不会修改嵌套堆栈。尤其要注意的是，传给 `Class.new` 和 `Module.new` 的块不会导致定义的类或模块入栈嵌套堆栈。由此可见，以不同的方式定义类和模块，达到的效果是有区别的。

<a class="anchor" id="class-and-module-definitions-are-constant-assignments"></a>

### 定义类和模块是为常量赋值

假设下面的代码片段是定义一个类（而不是打开类）：

```ruby
class C
end
```

Ruby 在 `Object` 中创建一个变量 `C`，并将一个类对象存储在 `C` 常量中。这个类实例的名称是“C”，一个字符串，跟常量名一样。

如下的代码：

```ruby
class Project < ApplicationRecord
end
```

这段代码执行的操作等效于下述常量赋值：

```ruby
Project = Class.new(ApplicationRecord)
```

而且有个副作用——设定类的名称：

```ruby
Project.name # => "Project"
```

这得益于常量赋值的一条特殊规则：如果被赋值的对象是匿名类或模块，Ruby 会把对象的名称设为常量的名称。

TIP: 自此之后常量和实例发生的事情无关紧要。例如，可以把常量删除，类对象可以赋值给其他常量，或者不再存储于常量中，等等。名称一旦设定就不会再变。


类似地，模块使用 `module` 关键字创建，如下所示：

```ruby
module Admin
end
```

这段代码执行的操作等效于下述常量赋值：

```ruby
Admin = Module.new
```

而且有个副作用——设定模块的名称：

```ruby
Admin.name # => "Admin"
```

WARNING: 传给 `Class.new` 或 `Module.new` 的块与 `class` 或 `module` 关键字的定义体不在完全相同的上下文中执行。但是两种方式得到的结果都是为常量赋值。


因此，当人们说“`String` 类”的时候，真正指的是 `Object` 常量中存储的一个类对象，它存储着常量“String”中存储的一个类对象。而 `String` 是一个普通的 Ruby 常量，与常量有关的一切，例如解析算法，在 `String` 常量上都适用。

同样地，在下述控制器中

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

`Post` 不是调用类的句法，而是一个常规的 Ruby 常量。如果一切正常，这个常量的求值结果是一个能响应 `all` 方法的对象。

因此，我们讨论的话题才是“常量”自动加载。Rails 提供了自动加载常量的功能。

<a class="anchor" id="constants-are-stored-in-modules"></a>

### 常量存储在模块中

按字面意义理解，常量属于模块。类和模块有常量表，你可以将其理解为哈希表。

下面通过一个示例来理解。通常我们都说“`String` 类”，这样方面，下面的阐述只是为了讲解原理。

我们来看看下述模块定义：

```ruby
module Colors
  RED = '0xff0000'
end
```

首先，处理 `module` 关键字时，解释器会在 `Object` 常量存储的类对象的常量表中新建一个条目。这个条目把“Colors”与一个新建的模块对象关联起来。而且，解释器把那个新建的模块对象的名称设为字符串“Colors”。

随后，解释模块的定义体时，会在 `Colors` 常量中存储的模块对象的常量表中新建一个条目。那个条目把“RED”映射到字符串“0xff0000”上。

注意，`Colors::RED` 与其他类或模块对象中的 `RED` 常量完全没有关系。如果存在这样一个常量，它在相应的常量表中，是不同的条目。

在前述各段中，尤其要注意类和模块对象、常量名称，以及常量表中与之关联的值对象之间的区别。

<a class="anchor" id="resolution-algorithms"></a>

### 解析算法

<a class="anchor" id="resolution-algorithm-for-relative-constants"></a>

#### 相对常量的解析算法

在代码中的特定位置，假如使用 cref 表示嵌套中的第一个元素，如果没有嵌套，则表示 `Object`。

简单来说，相对常量（relative constant）引用的解析算法如下：

1.  如果嵌套不为空，在嵌套中按元素顺序查找常量。元素的祖先忽略不计。
1.  如果未找到，算法向上，进入 cref 的祖先链。
1.  如果未找到，而且 cref 是个模块，在 `Object` 中查找常量。
1.  如果未找到，在 cref 上调用 `const_missing` 方法。这个方法的默认行为是抛出 `NameError` 异常，不过可以覆盖。

Rails 的自动加载机制没有仿照这个算法，查找的起点是要自动加载的常量名称，即 cref。详情参见 [相对引用](#autoloading-algorithms-relative-references)。

<a class="anchor" id="resolution-algorithm-for-qualified-constants"></a>

#### 限定常量的解析算法

限定常量（qualified constant）指下面这种：

```ruby
Billing::Invoice
```

`Billing::Invoice` 由两个常量组成，其中 `Billing` 是相对常量，使用前一节所属的算法解析。

TIP: 在开头加上两个冒号可以把第一部分的相对常量变成绝对常量，例如 `::Billing::Invoice`。此时，`Billing` 作为顶层常量查找。


而 `Invoice` 由 `Billing` 限定，下面说明它是如何解析的。假定 parent 是限定的类或模块对象，即上例中的 `Billing`。限定常量的解析算法如下：

1.  在 parent 及其祖先中查找常量。
1.  如果未找到，调用 parent 的 `const_missing` 方法。这个方法的默认行为是抛出 `NameError` 异常，不过可以覆盖。

可以看出，这个算法比相对常量的解析算法简单。毕竟这里不涉及嵌套，而且模块也不是特殊情况，如果二者及其祖先中都找不到常量，不会再查看 `Object`。

Rails 的自动加载机制没有仿照这个算法，查找的起点是要自动加载的常量名称和 parent。详情参见 [限定引用](#autoloading-algorithms-qualified-references)。

<a class="anchor" id="vocabulary"></a>

## 词汇表

<a class="anchor" id="parent-namespaces"></a>

### 父级命名空间

给定常量路径字符串，父级命名空间是把最右边那一部分去掉后余下的字符串。

例如，字符串“A::B::C”的父级命名空间是字符串“A::B”，“A::B”的父级命名空间是“A”，“A”的父级命名空间是“”（空）。

不过涉及类和模块的父级命名空间解释有点复杂。假设有个名为“A::B”的模块 M：

*   父级命名空间 “A” 在给定位置可能反应不出嵌套。
*   某处代码可能把常量 `A` 从 `Object` 中删除了，导致常量 `A` 不存在。
*   如果 `A` 存在，`A` 中原来有的类或模块可能不再存在。例如，把一个常量删除后再赋值另一个常量，那么存在的可能就不是同一个对象。
*   这种情形中，重新赋值的 `A` 可能是一个名为“A”的新类或模块。
*   在上述情况下，无法再通过 `A::B` 访问 `M`，但是模块对象本身可以继续存活于某处，而且名称依然是“A::B”。

父级命名空间这个概念是自动加载算法的核心，有助于以直观的方式解释和理解算法，但是并不严谨。由于有边缘情况，本文所说的“父级命名空间”真正指的是具体的字符串来源。

<a class="anchor" id="loading-mechanism"></a>

### 加载机制

如果 `config.cache_classes` 的值是 `false`（开发环境的默认值），Rails 使用 `Kernel#load` 自动加载文件，否则使用 `Kernel#require` 自动加载文件（生产环境的默认值）。

如果启用了[常量重新加载](#constant-reloading)，Rails 通过 `Kernel#load` 多次执行相同的文件。

本文使用的“加载”是指解释指定的文件，但是具体使用 `Kernel#load` 还是 `Kernel#require`，取决于配置。

<a class="anchor" id="autoloading-availability"></a>

## 自动加载可用性

只要环境允许，Rails 始终会自动加载。例如，`runner` 命令会自动加载：

```sh
$ bin/rails runner 'p User.column_names'
["id", "email", "created_at", "updated_at"]
```

控制台会自动加载，测试组件会自动加载，当然，应用也会自动加载。

默认情况下，在生产环境中，Rails 启动时会及早加载应用文件，因此开发环境中的多数自动加载行为不会发生。但是在及早加载的过程中仍然可能会触发自动加载。

例如：

```ruby
class BeachHouse < House
end
```

如果及早加载 `app/models/beach_house.rb` 文件之后，`House` 尚不可知，Rails 会自动加载它。

<a class="anchor" id="autoload-paths"></a>

## `autoload_paths`

或许你已经知道，使用 `require` 引入相对文件名时，例如

```ruby
require 'erb'
```

Ruby 在 `$LOAD_PATH` 中列出的目录里寻找文件。即，Ruby 迭代那些目录，检查其中有没有名为“erb.rb”“erb.so”“erb.o”或“erb.dll”的文件。如果在某个目录中找到了，解释器加载那个文件，搜索结束。否则，继续在后面的目录中寻找。如果最后没有找到，抛出 `LoadError` 异常。

后面会详述常量自动加载机制，不过整体思路是，遇到未知的常量时，如 `Post`，假如 `app/models` 目录中存在 `post.rb` 文件，Rails 会找到它，执行它，从而定义 `Post` 常量。

好吧，其实 Rails 会在一系列目录中查找 `post.rb`，有点类似于 `$LOAD_PATH`。那一系列目录叫做 `autoload_paths`，默认包含：

*   应用和启动时存在的引擎的 `app` 目录中的全部子目录。例如，`app/controllers`。这些子目录不一定是默认的，可以是任何自定义的目录，如 `app/workers`。`app` 目录中的全部子目录都自动纳入 `autoload_paths`。
*   应用和引擎中名为 `app/*/concerns` 的二级目录。
*   `test/mailers/previews` 目录。

此外，这些目录可以使用 `config.autoload_paths` 配置。例如，以前 `lib` 在这一系列目录中，但是现在不在了。应用可以在 `config/application.rb` 文件中添加下述配置，将其纳入其中：

```ruby
config.autoload_paths << "#{Rails.root}/lib"
```

在各个环境的配置文件中不能配置 `config.autoload_paths`。

`autoload_paths` 的值可以审查。在新创建的应用中，它的值是（经过编辑）：

```sh
$ bin/rails r 'puts ActiveSupport::Dependencies.autoload_paths'
.../app/assets
.../app/controllers
.../app/helpers
.../app/mailers
.../app/models
.../app/controllers/concerns
.../app/models/concerns
.../test/mailers/previews
```

TIP: `autoload_paths` 在初始化过程中计算并缓存。目录结构发生变化时，要重启服务器。


<a class="anchor" id="autoloading-algorithms"></a>

## 自动加载算法

<a class="anchor" id="autoloading-algorithms-relative-references"></a>

### 相对引用

相对常量引用可在多处出现，例如：

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

这里的三个常量都是相对引用。

<a class="anchor" id="constants-after-the-class-and-module-keywords"></a>

#### `class` 和 `module` 关键字后面的常量

Ruby 程序会查找 `class` 或 `module` 关键字后面的常量，因为要知道是定义类或模块，还是再次打开。

如果常量不被认为是缺失的，不会定义常量，也不会触发自动加载。

因此，在上述示例中，解释那个文件时，如果 `PostsController` 未定义，Rails 不会触发自动加载机制，而是由 Ruby 定义那个控制器。

<a class="anchor" id="top-level-constants"></a>

#### 顶层常量

相对地，如果 `ApplicationController` 是未知的，会被认为是缺失的，Rails 会尝试自动加载。

为了加载 `ApplicationController`，Rails 会迭代 `autoload_paths`。首先，检查 `app/assets/application_controller.rb` 文件是否存在，如果不存在（通常如此），再检查 `app/controllers/application_controller.rb` 是否存在。

如果那个文件定义了 `ApplicationController` 常量，那就没事，否则抛出 `LoadError` 异常：

```
unable to autoload constant ApplicationController, expected
<full path to application_controller.rb> to define it (LoadError)
```

TIP: Rails 不要求自动加载的常量是类或模块对象。假如在 `app/models/max_clients.rb` 文件中定义了 `MAX_CLIENTS = 100`，Rails 也能自动加载 `MAX_CLIENTS`。


<a class="anchor" id="namespaces"></a>

#### 命名空间

自动加载 `ApplicationController` 时直接检查 `autoload_paths` 里的目录，因为它没有嵌套。`Post` 就不同了，那一行的嵌套是 `[PostsController]`，此时就会使用涉及命名空间的算法。

对下述代码来说：

```ruby
module Admin
  class BaseController < ApplicationController
    @@all_roles = Role.all
  end
end
```

为了自动加载 `Role`，要分别检查当前或父级命名空间中有没有定义 `Role`。因此，从概念上讲，要按顺序尝试自动加载下述常量：

```
Admin::BaseController::Role
Admin::Role
Role
```

为此，Rails 在 `autoload_paths` 中分别查找下述文件名：

```
admin/base_controller/role.rb
admin/role.rb
role.rb
```

此外还会查找一些其他目录，稍后说明。

TIP: 不含扩展名的相对文件路径通过 `'Constant::Name'.underscore` 得到，其中 `Constant::Name` 是已定义的常量。


假设 `app/models/post.rb` 文件中定义了 `Post` 模型，下面说明 Rails 是如何自动加载 `PostsController` 中的 `Post` 常量的。

首先，在 `autoload_paths` 中查找 `posts_controller/post.rb`：

```
app/assets/posts_controller/post.rb
app/controllers/posts_controller/post.rb
app/helpers/posts_controller/post.rb
...
test/mailers/previews/posts_controller/post.rb
```

最后并未找到，因此会寻找一个类似的目录，[下一节](#automatic-modules)说明原因：

```
app/assets/posts_controller/post
app/controllers/posts_controller/post
app/helpers/posts_controller/post
...
test/mailers/previews/posts_controller/post
```

如果也未找到这样一个目录，Rails 会在父级命名空间中再次查找。对 `Post` 来说，只剩下顶层命名空间了：

```
app/assets/post.rb
app/controllers/post.rb
app/helpers/post.rb
app/mailers/post.rb
app/models/post.rb
```

这一次找到了 `app/models/post.rb` 文件。查找停止，加载那个文件。如果那个文件中定义了 `Post`，那就没问题，否则抛出 `LoadError` 异常。

<a class="anchor" id="autoloading-algorithms-qualified-references"></a>

### 限定引用

如果缺失限定常量，Rails 不会在父级命名空间中查找。但是有一点要留意：缺失常量时，Rails 不知道它是相对引用还是限定引用。

例如：

```ruby
module Admin
  User
end
```

和

```ruby
Admin::User
```

如果 `User` 缺失，在上述两种情况中 Rails 只知道缺失的是“Admin”模块中一个名为“User”的常量。

如果 `User` 是顶层常量，对前者来说，Ruby 会解析，但是后者不会。一般来说，Rails 解析常量的算法与 Ruby 不同，但是此时，Rails 尝试使用下述方式处理：

> 如果类或模块的父级命名空间中没有缺失的常量，Rails 假定引用的是相对常量。否则是限定常量。

例如，如果下述代码触发自动加载

```ruby
Admin::User
```

那么，`Object` 中已经存在 `User` 常量。但是下述代码不会触发自动加载

```ruby
module Admin
  User
end
```

如若不然，Ruby 就能解析出 `User`，也就无需自动加载了。因此，Rails 假定它是限定引用，只会在 `admin/user.rb` 文件和 `admin/user` 目录中查找。

其实，只要嵌套匹配全部父级命名空间，而且彼时适用这一规则的常量已知，这种机制便能良好运行。

然而，自动加载是按需执行的。如果碰巧顶层 `User` 尚未加载，那么 Rails 就假定它是相对引用。

在实际使用中，这种命名冲突很少发生。如果发生，`require_dependency` 提供了解决方案：确保做前述引文中的试探时，在有冲突的地方定义了常量。

<a class="anchor" id="automatic-modules"></a>

### 自动模块

把模块作为命名空间使用时，Rails 不要求应用为之定义一个文件，有匹配命名空间的目录就够了。

假设应用有个后台，相关的控制器存储在 `app/controllers/admin` 目录中。遇到 `Admin::UsersController` 时，如果 `Admin` 模块尚未加载，Rails 要先自动加载 `Admin` 常量。

如果 `autoload_paths` 中有个名为 `admin.rb` 的文件，Rails 会加载那个文件。如果没有这么一个文件，而且存在名为 `admin` 的目录，Rails 会创建一个空模块，自动将其赋值给 `Admin` 常量。

<a class="anchor" id="generic-procedure"></a>

### 一般步骤

相对引用在 cref 中报告缺失，限定引用在 parent 中报告缺失（cref 的指代参见 [相对常量的解析算法](#resolution-algorithm-for-relative-constants)开头，parent 的指代参见 [限定常量的解析算法](#resolution-algorithm-for-qualified-constants)开头）。

在任意的情况下，自动加载常量 C 的步骤如下：

```
if the class or module in which C is missing is Object
  let ns = ''
else
  let M = the class or module in which C is missing

  if M is anonymous
    let ns = ''
  else
    let ns = M.name
  end
end

loop do
  # 查找特定的文件
  for dir in autoload_paths
    if the file "#{dir}/#{ns.underscore}/c.rb" exists
      load/require "#{dir}/#{ns.underscore}/c.rb"

      if C is now defined
        return
      else
        raise LoadError
      end
    end
  end

  # 查找自动模块
  for dir in autoload_paths
    if the directory "#{dir}/#{ns.underscore}/c" exists
      if ns is an empty string
        let C = Module.new in Object and return
      else
        let C = Module.new in ns.constantize and return
      end
    end
  end

  if ns is empty
    # 到顶层了，还未找到常量
    raise NameError
  else
    if C exists in any of the parent namespaces
      # 以限定常量试探
      raise NameError
    else
      # 在父级命名空间中再试一次
      let ns = the parent namespace of ns and retry
    end
  end
end
```

<a class="anchor" id="require-dependency"></a>

## `require_dependency`

常量自动加载按需触发，因此使用特定常量的代码可能已经定义了常量，或者触发自动加载。具体情况取决于执行路径，二者之间可能有较大差异。

然而，有时执行到某部分代码时想确保特定常量是已知的。`require_dependency` 为此提供了一种方式。它使用目前的[加载机制](#loading-mechanism)加载文件，而且会记录文件中定义的常量，就像是自动加载的一样，而且会按需重新加载。

`require_dependency` 很少需要使用，不过 [自动加载和 STI](#autoloading-and-sti)和 [常量未缺失](#when-constants-aren-t-missed)有几个用例。

WARNING: 与自动加载不同，`require_dependency` 不期望文件中定义任何特定的常量。但是利用这种行为不好，文件和常量路径应该匹配。


<a class="anchor" id="constant-reloading"></a>

## 常量重新加载

`config.cache_classes` 设为 `false` 时，Rails 会重新自动加载常量。

例如，在控制台会话中编辑文件之后，可以使用 `reload!` 命令重新加载代码：

```irb
> reload!
```

在应用运行的过程中，如果相关的逻辑有变，会重新加载代码。为此，Rails 会监控下述文件：

*   `config/routes.rb`
*   本地化文件
*   `autoload_paths` 中的 Ruby 文件
*   `db/schema.rb` 和 `db/structure.sql`

如果这些文件中的内容有变，有个中间件会发现，然后重新加载代码。

自动加载机制会记录自动加载的常量。重新加载机制使用 `Module#remove_const` 方法把它们从相应的类和模块中删除。这样，运行代码时那些常量就变成未知了，从而按需重新加载文件。

TIP: 这是一个极端操作，Rails 重新加载的不只是那些有变化的代码，因为类之间的依赖极难处理。相反，Rails 重新加载一切。


<a class="anchor" id="module-autoload-isn-t-involved"></a>

## `Module#autoload` 不涉其中

`Module#autoload` 提供的是惰性加载常量方式，深置于 Ruby 的常量查找算法、动态常量 API，等等。这一机制相当简单。

Rails 内部在加载过程中大量采用这种方式，尽量减少工作量。但是，Rails 的常量自动加载机制不是使用 `Module#autoload` 实现的。

如果基于 `Module#autoload` 实现，可以遍历应用树，调用 `autoload` 把文件名和常规的常量名对应起来。

Rails 不采用这种实现方式有几个原因。

例如，`Module#autoload` 只能使用 `require` 加载文件，因此无法重新加载。不仅如此，它使用的是 `require` 关键字，而不是 `Kernel#require` 方法。

因此，删除文件后，它无法移除声明。如果使用 `Module#remove_const` 把常量删除了，不会触发 `Module#autoload`。此外，它不支持限定名称，因此有命名空间的文件要在遍历树时解析，这样才能调用相应的 `autoload` 方法，但是那些文件中可能有尚未配置的常量引用。

基于 `Module#autoload` 的实现很棒，但是如你所见，目前还不可能。Rails 的常量自动加载机制使用 `Module#const_missing` 实现，因此才有本文所述的独特算法。

<a class="anchor" id="common-gotchas"></a>

## 常见问题

<a class="anchor" id="nesting-and-qualified-constants"></a>

### 嵌套和限定常量

假如有下述代码

```ruby
module Admin
  class UsersController < ApplicationController
    def index
      @users = User.all
    end
  end
end
```

和

```ruby
class Admin::UsersController < ApplicationController
  def index
    @users = User.all
  end
end
```

为了解析 `User`，对前者来说，Ruby 会检查 `Admin`，但是后者不会，因为它不在嵌套中（参见 [嵌套](#nesting)和 [解析算法](#resolution-algorithms)）。

可惜，在缺失常量的地方，Rails 自动加载机制不知道嵌套，因此行为与 Ruby 不同。具体而言，在两种情况下，`Admin::User` 都能自动加载。

尽管严格来说某些情况下 `class` 和 `module` 关键字后面的限定常量可以自动加载，但是最好使用相对常量：

```ruby
module Admin
  class UsersController < ApplicationController
    def index
      @users = User.all
    end
  end
end
```

<a class="anchor" id="autoloading-and-sti"></a>

### 自动加载和 STI

单表继承（Single Table Inheritance，STI）是 Active Record 的一个功能，作用是在一个数据库表中存储具有层次结构的多个模型。这种模型的 API 知道层次结构的存在，而且封装了一些常用的需求。例如，对下面的类来说：

```ruby
# app/models/polygon.rb
class Polygon < ApplicationRecord
end

# app/models/triangle.rb
class Triangle < Polygon
end

# app/models/rectangle.rb
class Rectangle < Polygon
end
```

`Triangle.create` 在表中创建一行，表示一个三角形，而 `Rectangle.create` 创建一行，表示一个长方形。如果 `id` 是某个现有记录的 ID，`Polygon.find(id)` 返回的是正确类型的对象。

操作集合的方法也知道层次结构。例如，`Polygon.all` 返回表中的全部记录，因为所有长方形和三角形都是多边形。Active Record 负责为结果集合中的各个实例设定正确的类。

类型会按需自动加载。例如，如果 `Polygon.first` 是一个长方形，而 `Rectangle` 尚未加载，Active Record 会自动加载它，然后正确实例化记录。

目前一切顺利，但是如果在根类上执行查询，需要处理子类，这时情况就复杂了。

处理 `Polygon` 时，无需知道全部子代，因为表中的所有记录都是多边形。但是处理子类时， Active Record 需要枚举类型，找到所需的那个。下面看一个例子。

`Rectangle.all` 在查询中添加一个类型约束，只加载长方形：

```sql
SELECT "polygons".* FROM "polygons"
WHERE "polygons"."type" IN ("Rectangle")
```

下面定义一个 `Rectangle` 的子类：

```ruby
# app/models/square.rb
class Square < Rectangle
end
```

现在，`Rectangle.all` 返回的结果应该既有长方形，也有正方形：

```sql
SELECT "polygons".* FROM "polygons"
WHERE "polygons"."type" IN ("Rectangle", "Square")
```

但是这里有个问题：Active Record 怎么知道存在 `Square` 类呢？

如果 `app/models/square.rb` 文件存在，而且定义了 `Square` 类，但是没有代码使用它，`Rectangle.all` 执行的查询是

```sql
SELECT "polygons".* FROM "polygons"
WHERE "polygons"."type" IN ("Rectangle")
```

这不是缺陷，查询包含了所有已知的 `Rectangle` 子代。

为了确保能正确处理，而不管代码的执行顺序，可以在定义各个中间类的文件底部手动加载子类：

```ruby
# app/models/rectangle.rb
class Rectangle < Polygon
end
require_dependency 'square'
```

每个中间类（首尾之外的类）都要这么做。根类并没有通过类型限定查询，因此无需知道所有子代。

<a class="anchor" id="autoloading-and-require"></a>

### 自动加载和 `require`

通过自动加载机制加载的定义常量的文件一定不能使用 `require` 引入：

```ruby
require 'user' # 千万别这么做

class UsersController < ApplicationController
  ...
end
```

如果这么做，在开发环境中会导致两个问题：

1.  如果在执行 `require` 之前自动加载了 `User`，`app/models/user.rb` 会再次运行，因为 `load` 不会更新 `$LOADED_FEATURES`。
1.  如果 `require` 先执行了，Rails 不会把 `User` 标记为自动加载的常量，因此 `app/models/user.rb` 文件中的改动不会重新加载。

我们应该始终遵守规则，使用常量自动加载机制，一定不能混用自动加载和 `require`。底线是，如果一定要加载特定的文件，使用 `require_dependency`，这样能正确利用常量自动加载机制。不过，实际上很少需要这么做。

当然，在自动加载的文件中使用 `require` 加载第三方库没问题，Rails 会做区分，不把第三方库里的常量标记为自动加载的。

<a class="anchor" id="autoloading-and-initializers"></a>

### 自动加载和初始化脚本

假设 `config/initializers/set_auth_service.rb` 文件中有下述赋值语句：

```ruby
AUTH_SERVICE = if Rails.env.production?
  RealAuthService
else
  MockedAuthService
end
```

这么做的目的是根据所在环境为 `AUTH_SERVICE` 赋予不同的值。在开发环境中，运行这个初始化脚本时，自动加载 `MockedAuthService`。假如我们发送了几个请求，修改了实现，然后再次运行应用，奇怪的是，改动没有生效。这是为什么呢？

[从前文得知](#constant-reloading)，Rails 会删除自动加载的常量，但是 `AUTH_SERVICE` 存储的还是原来那个类对象。原来那个常量不存在了，但是功能完全不受影响。

下述代码概述了这种情况：

```ruby
class C
  def quack
    'quack!'
  end
end

X = C
Object.instance_eval { remove_const(:C) }
X.new.quack # => quack!
X.name      # => C
C           # => uninitialized constant C (NameError)
```

鉴于此，不建议在应用初始化过程中自动加载常量。

对上述示例来说，我们可以实现一个动态接入点：

```ruby
# app/models/auth_service.rb
class AuthService
  if Rails.env.production?
    def self.instance
      RealAuthService
    end
  else
    def self.instance
      MockedAuthService
    end
  end
end
```

然后在应用中使用 `AuthService.instance`。这样，`AuthService` 会按需加载，而且能顺利自动加载。

<a class="anchor" id="require-dependency-and-initializers"></a>

### `require_dependency` 和初始化脚本

前面说过，`require_dependency` 加载的文件能顺利自动加载。但是，一般来说不应该在初始化脚本中使用。

有人可能觉得在初始化脚本中调用 [`require_dependency`](#require-dependency) 能确保提前加载特定的常量，例如用于解决 [STI 问题](#autoloading-and-sti)。

问题是，在开发环境中，如果文件系统中有相关的改动，[自动加载的常量会被抹除](#constant-reloading)。这样就与使用初始化脚本的初衷背道而驰了。

`require_dependency` 调用应该写在能自动加载的地方。

<a class="anchor" id="when-constants-aren-t-missed"></a>

### 常量未缺失

<a class="anchor" id="when-constants-aren-t-missed-relative-references"></a>

#### 相对引用

以一个飞行模拟器为例。应用中有个默认的飞行模型：

```ruby
# app/models/flight_model.rb
class FlightModel
end
```

每架飞机都可以将其覆盖，例如：

```ruby
# app/models/bell_x1/flight_model.rb
module BellX1
  class FlightModel < FlightModel
  end
end

# app/models/bell_x1/aircraft.rb
module BellX1
  class Aircraft
    def initialize
      @flight_model = FlightModel.new
    end
  end
end
```

初始化脚本想创建一个 `BellX1::FlightModel` 对象，而且嵌套中有 `BellX1`，看起来这没什么问题。但是，如果默认飞行模型加载了，但是 Bell-X1 模型没有，解释器能解析顶层的 `FlightModel`，因此 `BellX1::FlightModel` 不会触发自动加载机制。

这种代码取决于执行路径。

这种歧义通常可以通过限定常量解决：

```ruby
module BellX1
  class Plane
    def flight_model
      @flight_model ||= BellX1::FlightModel.new
    end
  end
end
```

此外，使用 `require_dependency` 也能解决：

```ruby
require_dependency 'bell_x1/flight_model'

module BellX1
  class Plane
    def flight_model
      @flight_model ||= FlightModel.new
    end
  end
end
```

<a class="anchor" id="when-constants-aren-t-missed-qualified-references"></a>

#### 限定引用

对下述代码来说

```ruby
# app/models/hotel.rb
class Hotel
end

# app/models/image.rb
class Image
end

# app/models/hotel/image.rb
class Hotel
  class Image < Image
  end
end
```

`Hotel::Image` 这个表达式有歧义，因为它取决于执行路径。

[从前文得知](#resolution-algorithm-for-qualified-constants)，Ruby 会在 `Hotel` 及其祖先中查找常量。如果加载了 `app/models/image.rb` 文件，但是没有加载 `app/models/hotel/image.rb`，Ruby 在 `Hotel` 中找不到 `Image`，而在 `Object` 中能找到：

```ruby
$ bin/rails r 'Image; p Hotel::Image' 2>/dev/null
Image # 不是 Hotel::Image！
```

若想得到 `Hotel::Image`，要确保 `app/models/hotel/image.rb` 文件已经加载——或许是使用 `require_dependency` 加载的。

不过，在这些情况下，解释器会发出提醒：

```
warning: toplevel constant Image referenced by Hotel::Image
```

任何限定的类都能发现这种奇怪的常量解析行为：

```
2.1.5 :001 > String::Array
(irb):1: warning: toplevel constant Array referenced by String::Array
 => Array
```

WARNING: 为了发现这种问题，限定命名空间必须是类。`Object` 不是模块的祖先。


<a class="anchor" id="autoloading-within-singleton-classes"></a>

### 单例类中的自动加载

假如有下述类定义：

```ruby
# app/models/hotel/services.rb
module Hotel
  class Services
  end
end

# app/models/hotel/geo_location.rb
module Hotel
  class GeoLocation
    class << self
      Services
    end
  end
end
```

如果加载 `app/models/hotel/geo_location.rb` 文件时 `Hotel::Services` 是已知的，`Services` 由 Ruby 解析，因为打开 `Hotel::GeoLocation` 的单例类时，`Hotel` 在嵌套中。

但是，如果 `Hotel::Services` 是未知的，Rails 无法自动加载它，应用会抛出 `NameError` 异常。

这是因为单例类（匿名的）会触发自动加载，[从前文得知](#generic-procedure)，在这种边缘情况下，Rails 只检查顶层命名空间。

这个问题的简单解决方案是使用限定常量：

```ruby
module Hotel
  class GeoLocation
    class << self
      Hotel::Services
    end
  end
end
```

<a class="anchor" id="autoloading-in-basicobject"></a>

### `BasicObject` 中的自动加载

`BasicObject` 的直接子代的祖先中没有 `Object`，因此无法解析顶层常量：

```ruby
class C < BasicObject
  String # NameError: uninitialized constant C::String
end
```

如果涉及自动加载，情况稍微复杂一些。对下述代码来说

```ruby
class C < BasicObject
  def user
    User # 错误
  end
end
```

因为 Rails 会检查顶层命名空间，所以第一次调用 `user` 方法时，`User` 能自动加载。但是，如果 `User` 是已知的，尤其是第二次调用 `user` 方法时，情况就不同了：

```ruby
c = C.new
c.user # 奇怪的是能正常运行，返回 User
c.user # NameError: uninitialized constant C::User
```

因为此时发现父级命名空间中已经有那个常量了（参见 [限定引用](#autoloading-algorithms-qualified-references)）。

在纯 Ruby 代码中，在 `BasicObject` 的直接子代的定义体中应该始终使用绝对常量路径：

```ruby
class C < BasicObject
  ::String # 正确

  def user
    ::User # 正确
  end
end
```
