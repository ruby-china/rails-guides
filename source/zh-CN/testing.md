Rails 程序测试指南
================

本文介绍 Rails 内建对测试的支持。

读完后，你将学会：

* Rails 测试术语；
* 如何为程序编写单元测试，功能测试和集成测试；
* 常用的测试方法和插件；

--------------------------------------------------------------------------------

## 为什么要为 Rails 程序编写测试？

在 Rails 中编写测试非常简单，生成模型和控制器时，已经生成了测试代码骨架。

即便是大范围重构后，只需运行测试就能确保实现了所需功能。

Rails 中的测试还可以模拟浏览器请求，无需打开浏览器就能测试程序的响应。

## 测试简介

测试是 Rails 程序的重要组成部分，不是处于尝鲜和好奇才编写测试。基本上每个 Rails 程序都要频繁和数据库交互，所以测试时也要和数据库交互。为了能够编写高效率的测试，必须要了解如何设置数据库以及导入示例数据。

### 测试环境

默认情况下，Rails 程序有三个环境：开发环境，测试环境和生产环境。每个环境所需的数据库在 `config/database.yml` 文件中设置。

测试使用的数据库独立于其他环境，不会影响开发环境和生产环境的数据库。

### Rails Sets up for Testing from the Word Go

执行 `rails new` 命令生成新程序时，Rails 会创建一个名为 `test` 的文件夹。这个文件夹中的内容如下：

{:lang="bash"}
~~~
$ ls -F test
controllers/    helpers/        mailers/        test_helper.rb
fixtures/       integration/    models/
~~~

`modles` 文件夹存放模型测试，`controllers` 文件夹存放控制器测试，`integration` 文件夹存放多个控制器之间交互的测试。

`fixtures` 文件夹中存放固件。固件是一种组织测试数据的方式。

`test_helper.rb` 文件中保存测试的默认设置。

### 固件详解

好的测试应该应该具有提供测试数据的方式。在 Rails 中，测试数据由固件提供。

#### 固件是什么？

固件代指示例数据，在运行测试之前，把预先定义好的数据导入测试数据库。固件相互独立，一个文件对应一个模型，使用 YAML 格式编写。

固件保存在文件夹 `test/fixtures` 中，执行 `rails generate model` 命令生成新模型时，会在这个文件夹中自动创建一个固件文件。

#### YAML

使用 YAML 格式编写的固件可读性极高，文件的扩展名是 `.yml`，例如 `users.yml`。

下面举个例子：

{:lang="yaml"}
~~~
# lo & behold! I am a YAML comment!
david:
  name: David Heinemeier Hansson
  birthday: 1979-10-15
  profession: Systems development

steve:
  name: Steve Ross Kellock
  birthday: 1974-09-27
  profession: guy with keyboard
~~~

每个附件都有名字，后面跟着一个缩进后的键值对列表。记录之间往往使用空行分开。在固件中可以使用注释，在行首加上 `#` 符号即可。如果键名使用了 YAML 中的关键字，必须使用引号，例如 `'yes'` 和 `'no'`，这样 YAML 解析程序才能正确解析。

如果涉及到关联，定义一个指向其他固件的引用即可。例如，下面的固件针对 `belongs_to/has_many` 关联：

{:lang="yaml"}
~~~
# In fixtures/categories.yml
about:
  name: About

# In fixtures/articles.yml
one:
  title: Welcome to Rails!
  body: Hello world!
  category: about
~~~

#### 使用 ERB 增强固件

ERB 允许在模板中嵌入 Ruby 代码。Rails 加载 YAML 格式的固件时，会先使用 ERB 进行预处理，因此可使用 Ruby 代码协助生成示例数据。例如，下面的代码会生成一千个用户：

{:lang="erb"}
~~~
<% 1000.times do |n| %>
user_<%= n %>:
  username: <%= "user#{n}" %>
  email: <%= "user#{n}@example.com" %>
<% end %>
~~~

#### 固件实战

默认情况下，运行模型测试和控制器测试时会自动加载 `test/fixtures` 文件夹中的所有固件。加载的过程分为三步：

* 从数据表中删除所有和固件对应的数据；
* 把固件载入数据表；
* 把固件中的数据赋值给变量，以便直接访问；

#### 固件是 Active Record 对象

固件是 Active Record 实例，如前一节的第 3 点所述，在测试用例中可以直接访问这个对象，因为固件中的数据会赋值给一个本地变量。例如：

{:lang="ruby"}
~~~
# this will return the User object for the fixture named david
users(:david)

# this will return the property for david called id
users(:david).id

# one can also access methods available on the User class
email(david.girlfriend.email, david.location_tonight)
~~~

## 为模型编写单元测试

在 Rails 中，单元测试用来测试模型。

本文会使用 Rails 脚手架生成模型、迁移、控制器、视图和遵守 Rails 最佳实践的完整测试组件。我们会使用自动生成的代码，也会按需添加其他代码。

NOTE: 关于 Rails 脚手架的详细介绍，请阅读“[Rails 入门]({{ site.baseurl }}/getting_started.html)”一文。

执行 `rails generate scaffold` 命令生成资源时，也会在 `test/models` 文件夹中生成单元测试文件：

{:lang="bash"}
~~~
$ rails generate scaffold post title:string body:text
...
create  app/models/post.rb
create  test/models/post_test.rb
create  test/fixtures/posts.yml
...
~~~

`test/models/post_test.rb` 文件中默认的测试代码如下：

{:lang="ruby"}
~~~
require 'test_helper'

class PostTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
~~~

下面逐行分析这段代码，熟悉 Rails 测试的代码和相关术语。

{:lang="ruby"}
~~~
require 'test_helper'
~~~

现在你已经知道，`test_helper.rb` 文件是测试的默认设置，会载入所有测试，因此在所有测试中都可使用其中定义的方法。

{:lang="ruby"}
~~~
class PostTest < ActiveSupport::TestCase
~~~

`PostTest` 继承自 `ActiveSupport::TestCase`，定义了一个测试用例，因此可以使用 `ActiveSupport::TestCase` 中的所有方法。后文会介绍其中一些方法。

`MiniTest::Unit::TestCase`（`ActiveSupport::TestCase` 的父类）子类中每个以 `test` 开头（区分大小写）的方法都是一个测试，所以，`test_password`、`test_valid_password` 和 `testValidPassword` 都是合法的测试名，运行测试用例时会自动运行这些测试。

Rails 还提供了 `test` 方法，接受一个测试名作为参数，然后跟着一个代码块。`test` 方法会生成一个 `MiniTest::Unit` 测试，方法名以 `test_` 开头。例如：

{:lang="ruby"}
~~~
test "the truth" do
  assert true
end
~~~

和下面的代码是等效的

{:lang="ruby"}
~~~
def test_the_truth
  assert true
end
~~~

不过前者的测试名可读性更高。当然，使用方法定义的方式也没什么问题。

NOTE: 生成的方法名会把空格替换成下划线。最终得到的结果可以不是合法的 Ruby 标示符，名字中可以包含标点符号等。因为在 Ruby 中，任何字符串都可以作为方法名，奇怪的方法名需要调用 `define_method` 或 `send` 方法，所以没有限制。

{:lang="ruby"}
~~~
assert true
~~~

这行代码叫做“断言”（assertion）。断言只有一行代码，把指定对象或表达式和期望的结果进行对比。例如，断言可以检查：

* 两个值是够相等；
* 对象是否为 `nil`；
* 这行代码是否抛出异常；
* 用户的密码长度是否超过 5 个字符；

每个测试中都有一个到多个断言。只有所有断言都返回真值，测试才能通过。

### 维护测试数据库的模式

为了能运行测试，测试数据库要有程序当前的数据库结构。测试帮助方法会检查测试数据库中是否有尚未运行的迁移。如果有，会尝试把 `db/schema.rb` 或 `db/structure.sql` 载入数据库。之后如果迁移仍处于待运行状态，会抛出异常。

### 运行测试

运行测试执行 `rake test` 命令即可，在这个命令中还要指定要运行的测试文件。

{:lang="bash"}
~~~
$ rake test test/models/post_test.rb
.

Finished tests in 0.009262s, 107.9680 tests/s, 107.9680 assertions/s.

1 tests, 1 assertions, 0 failures, 0 errors, 0 skips
~~~

上述命令会运行指定文件中的所有测试方法。注意，`test_helper.rb` 在 `test` 文件夹中，因此这个文件夹要使用 `-I` 旗标添加到加载路径中。

还可以指定测试方法名，只运行相应的测试。

{:lang="bash"}
~~~
$ rake test test/models/post_test.rb test_the_truth
.

Finished tests in 0.009064s, 110.3266 tests/s, 110.3266 assertions/s.

1 tests, 1 assertions, 0 failures, 0 errors, 0 skips
~~~

上述代码中的点号（`.`）表示一个通过的测试。如果测试失败，会看到一个 `F`。如果测试抛出异常，会看到一个 `E`。输出的最后一行是测试总结。

要想查看失败测试的输出，可以在 `post_test.rb` 中添加一个失败测试。

{:lang="ruby"}
~~~
test "should not save post without title" do
  post = Post.new
  assert_not post.save
end
~~~

我们来运行新添加的测试：

{:lang="bash"}
~~~
$ rake test test/models/post_test.rb test_should_not_save_post_without_title
F

Finished tests in 0.044632s, 22.4054 tests/s, 22.4054 assertions/s.

  1) Failure:
test_should_not_save_post_without_title(PostTest) [test/models/post_test.rb:6]:
Failed assertion, no message given.

1 tests, 1 assertions, 1 failures, 0 errors, 0 skips
~~~

在输出中，`F` 表示失败测试。你会看到相应的调用栈和测试名。随后还会显示断言实际得到的值和期望得到的值。默认的断言消息提供了足够的信息，可以帮助你找到错误所在。要想让断言失败的消息更具可读性，可以使用断言可选的消息参数，例如：

{:lang="ruby"}
~~~
test "should not save post without title" do
  post = Post.new
  assert_not post.save, "Saved the post without a title"
end
~~~

运行这个测试后，会显示一个更友好的断言失败消息：

{:lang="bash"}
~~~
  1) Failure:
test_should_not_save_post_without_title(PostTest) [test/models/post_test.rb:6]:
Saved the post without a title
~~~

如果想让这个测试通过，可以在模型中为 `title` 字段添加一个数据验证：

{:lang="ruby"}
~~~
class Post < ActiveRecord::Base
  validates :title, presence: true
end
~~~

现在测试应该可以通过了，再次运行这个测试来验证一下：

{:lang="bash"}
~~~
$ rake test test/models/post_test.rb test_should_not_save_post_without_title
.

Finished tests in 0.047721s, 20.9551 tests/s, 20.9551 assertions/s.

1 tests, 1 assertions, 0 failures, 0 errors, 0 skips
~~~

你可能注意到了，我们首先编写一个检测所需功能的测试，这个测试会失败，然后编写代码，实现所需功能，最后再运行测试，确保测试可以通过。这一过程，在软件开发中称为“测试驱动开发”（Test-Driven Development，TDD）。

T> 很多 Rails 开发者都会使用 TDD，这种开发方式可以确保程序的每个功能都能正确运行。本文不会详细介绍 TDD，如果想学习，可以从 [15 TDD steps to create a Rails application](http://andrzejonsoftware.blogspot.com/2007/05/15-tdd-steps-to-create-rails.html) 这篇文章开始。

要想查看错误的输出，可以在测试中加入一处错误：

{:lang="ruby"}
~~~
test "should report error" do
  # some_undefined_variable is not defined elsewhere in the test case
  some_undefined_variable
  assert true
end
~~~

运行测试，很看到以下输出：

{:lang="bash"}
~~~
$ rake test test/models/post_test.rb test_should_report_error
E

Finished tests in 0.030974s, 32.2851 tests/s, 0.0000 assertions/s.

  1) Error:
test_should_report_error(PostTest):
NameError: undefined local variable or method `some_undefined_variable' for #<PostTest:0x007fe32e24afe0>
    test/models/post_test.rb:10:in `block in <class:PostTest>'

1 tests, 0 assertions, 0 failures, 1 errors, 0 skips
~~~

注意上面输出中的 `E`，表示测试出错了。

NOTE: 如果测试方法出现错误或者断言检测失败就会终止运行，继续运行测试组件中的下个方法。测试按照字母顺序运行。

测试失败后会看到相应的调用栈。默认情况下，Rails 会过滤调用栈，只显示和程序有关的调用栈。这样可以减少输出的内容，集中精力关注程序的代码。如果想查看完整的调用栈，可以设置 `BACKTRACE` 环境变量：

{:lang="bash"}
~~~
$ BACKTRACE=1 rake test test/models/post_test.rb
~~~

### 单元测试要测试什么

理论上，应该测试一切可能出问题的功能。实际使用时，建议至少为每个数据验证编写一个测试，至少为模型中的每个方法编写一个测试。

### 可用的断言

读到这，详细你已经大概知道一些断言了。断言是测试的核心，是真正用来检查功能是否符合预期的工具。

断言有很多种，下面列出了可在 Rails 默认测试库 `minitest` 中使用的断言。方法中的 `[msg]` 是可选参数，指定测试失败时显示的友好消息。

| 断言                                                             | 作用  |
|------------------------------------------------------------------|-------|
| `assert( test, [msg] )`                                          | 确保 `test` 是真值 |
| `assert_not( test, [msg] )`                                      | 确保 `test` 是假值 |
| `assert_equal( expected, actual, [msg] )`                        | 确保 `expected == actual` 返回 `true` |
| `assert_not_equal( expected, actual, [msg] )`                    | 确保 `expected != actual` 返回 `true` |
| `assert_same( expected, actual, [msg] )`                         | 确保 `expected.equal?(actual)` 返回 `true` |
| `assert_not_same( expected, actual, [msg] )`                     | 确保 `expected.equal?(actual)` 返回 `false` |
| `assert_nil( obj, [msg] )`                                       | 确保 `obj.nil?` 返回 `true` |
| `assert_not_nil( obj, [msg] )`                                   | 确保 `obj.nil?` 返回 `false` |
| `assert_match( regexp, string, [msg] )`                          | 确保字符串匹配正则表达式 |
| `assert_no_match( regexp, string, [msg] )`                       | 确保字符串不匹配正则表达式 |
| `assert_in_delta( expecting, actual, [delta], [msg] )`           | 确保数字 `expected` 和 `actual` 之差在 `delta` 指定的范围内 |
| `assert_not_in_delta( expecting, actual, [delta], [msg] )`       | 确保数字 `expected` 和 `actual` 之差不在 `delta` 指定的范围内 |
| `assert_throws( symbol, [msg] ) { block }`                       | 确保指定的代码块会抛出一个 Symbol |
| `assert_raises( exception1, exception2, ... ) { block }`         | 确保指定的代码块会抛出其中一个异常 |
| `assert_nothing_raised( exception1, exception2, ... ) { block }` | 确保指定的代码块不会抛出其中一个异常 |
| `assert_instance_of( class, obj, [msg] )`                        | 确保 `obj` 是 `class` 的实例 |
| `assert_not_instance_of( class, obj, [msg] )`                    | 确保 `obj` 不是 `class` 的实例 |
| `assert_kind_of( class, obj, [msg] )`                            | 确保 `obj` 是 `class` 或其子类的实例 |
| `assert_not_kind_of( class, obj, [msg] )`                        | 确保 `obj` 不是 `class` 或其子类的实例 |
| `assert_respond_to( obj, symbol, [msg] )`                        | 确保 `obj` 可以响应 `symbol` |
| `assert_not_respond_to( obj, symbol, [msg] )`                    | 确保 `obj` 不可以响应 `symbol` |
| `assert_operator( obj1, operator, [obj2], [msg] )`               | 确保 `obj1.operator(obj2)` 返回真值 |
| `assert_not_operator( obj1, operator, [obj2], [msg] )`           | 确保 `obj1.operator(obj2)` 返回假值 |
| `assert_send( array, [msg] )`                                    | 确保在 `array[0]` 指定的方法上调用 `array[1]` 指定的方法，并且把 `array[2]` 及以后的元素作为参数传入，该方法会返回真值。这个方法很奇特吧？ |
| `flunk( [msg] )`                                                 | 确保测试会失败，用来标记测试还没编写完 |

Rails 使用的测试框架完全模块化，因此可以自己编写新的断言。Rails 本身就是这么做的，提供了很多专门的断言，可以简化测试。

NOTE: 自己编写断言属于进阶话题，本文不会介绍。

### Rails 提供的断言

Rails 为 `test/unit` 框架添加了很多自定义的断言：
Rails adds some custom assertions of its own to the `test/unit` framework:

| 断言                                                                              | 作用  |
|-----------------------------------------------------------------------------------|-------|
| `assert_difference(expressions, difference = 1, message = nil) {...}`             | 测试 `expressions` 的返回数值和代码块的返回数值相差是否为 `difference` |
| `assert_no_difference(expressions, message = nil, &amp;block)`                    | 测试 `expressions` 的返回数值和代码块的返回数值相差是否不为 `difference` |
| `assert_recognizes(expected_options, path, extras={}, message=nil)`               | 测试 `path` 指定的路由是否正确处理，以及 `expected_options` 指定的参数是够由 `path` 处理。也就是说 Rails 是否能识别 `expected_options` 指定的路由 |
| `assert_generates(expected_path, options, defaults={}, extras = {}, message=nil)` | 测试指定的 `options` 能否生成 `expected_path` 指定的路径。这个断言是 `assert_recognizes` 的逆测试。`extras` 指定额外的请求参数。`message` 指定断言失败时显示的错误消息。 |
| `assert_response(type, message = nil)`                                            | 测试响应是否返回指定的状态码。可用 `:success` 表示 200-299，`:redirect` 表示 300-399，`:missing` 表示 404，`:error` 表示 500-599。状态码可用具体的数字表示，也可用相应的符号表示。详细信息参见[完整的状态码列表](http://rubydoc.info/github/rack/rack/master/Rack/Utils#HTTP_STATUS_CODES-constant)，以及状态码数字和符号的[对应关系](http://rubydoc.info/github/rack/rack/master/Rack/Utils#SYMBOL_TO_STATUS_CODE-constant)。 |
| `assert_redirected_to(options = {}, message=nil)`                                 | 测试 `options` 是否匹配所执行动作的转向设定。这个断言可以匹配局部转向，所以 `assert_redirected_to(controller: "weblog")` 可以匹配转向到 `redirect_to(controller: "weblog", action: "show")` 等。还可以传入具名路由，例如 `assert_redirected_to root_path`，以及 Active Record 对象，例如 `assert_redirected_to @article`。 |
| `assert_template(expected = nil, message=nil)`                                    | 测试请求是否由指定的模板文件渲染 |

下一节会介绍部分断言的用法。

## 为控制器编写功能测试

在 Rails 中，测试控制器各动作需要编写功能测试。控制器负责处理程序接收的请求，然后使用视图渲染响应。

### 功能测试要测试什么

应该测试一下内容：

* 请求是否成功；
* 是否转向了正确的页面；
* 用户是否通过了身份认证；
* 是否把正确的对象传给了渲染响应的模板；
* 是否在视图中显示了相应的消息；

前面我们已经使用 Rails 脚手架生成了 `Post` 资源，在生成的文件中包含了控制器和测试。你可以看一下 `test/controllers` 文件夹中的 `posts_controller_test.rb` 文件。

我们来看一下这个文件中的测试，首先是 `test_should_get_index`。

{:lang="ruby"}
~~~
class PostsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:posts)
  end
end
~~~

在 `test_should_get_index` 测试中，Rails 模拟了一个发给 `index` 动作的请求，确保请求成功，而且赋值了一个合法的 `posts` 实例变量。

`get` 方法会发起请求，并把结果传入响应中。可接受 4 个参数：

* 所请求控制器的动作，可使用字符串或 Symbol；
* 可选的 Hash，指定传入动作的请求参数（例如，请求字符串参数或表单提交的参数）；
* 可选的 Hash，指定随请求一起传入的会话变量；
* 可选的 Hash，指定 Flash 消息的值；

举个例子，请求 `:show` 动作，请求参数为 `'id' => "12"`，会话参数为 `'user_id' => 5`：

{:lang="ruby"}
~~~
get(:show, {'id' => "12"}, {'user_id' => 5})
~~~

再举个例子：请求 `:view` 动作，请求参数为 `'id' => '12'`，这次没有会话参数，但指定了 Flash 消息：

{:lang="ruby"}
~~~
get(:view, {'id' => '12'}, nil, {'message' => 'booya!'})
~~~

NOTE: 如果现在运行 `posts_controller_test.rb` 文件中的 `test_should_create_post` 测试会失败，因为前文在模型中添加了数据验证。

我们来修改 `posts_controller_test.rb` 文件中的 `test_should_create_post` 测试，让所有测试都通过：

{:lang="ruby"}
~~~
test "should create post" do
  assert_difference('Post.count') do
    post :create, post: {title: 'Some title'}
  end

  assert_redirected_to post_path(assigns(:post))
end
~~~

现在你可以运行所有测试，都应该通过。

### 功能测试中可用的请求类型

如果熟悉 HTTP 协议就会知道，`get` 是请求的一种类型。在 Rails 功能测试中可以使用 6 种请求：

* `get`
* `post`
* `patch`
* `put`
* `head`
* `delete`

这几种请求都可作为方法调用，不过前两种最常用。

NOTE: 功能测试不检测动作是否能接受指定类型的请求。如果发起了动作无法接受的请求类型，测试会直接退出。

### 可用的四个 Hash

使用上述 6 种请求之一发起请求并经由控制器处理后，会产生 4 个 Hash 供使用：

* `assigns`：动作中创建在视图中使用的实例变量；
* `cookies`：设置的 cookie；
* `flash`：Flash 消息中的对象；
* `session`：会话中的对象；

和普通的 Hash 对象一样，可以使用字符串形式的键获取相应的值。除了 `assigns` 之外，另外三个 Hash 还可使用 Symbol 形式的键。例如：

{:lang="ruby"}
~~~
flash["gordon"]               flash[:gordon]
session["shmession"]          session[:shmession]
cookies["are_good_for_u"]     cookies[:are_good_for_u]

# Because you can't use assigns[:something] for historical reasons:
assigns["something"]          assigns(:something)
~~~

### 可用的实例变量

在功能测试中还可以使用下面三个实例变量：

* `@controller`：处理请求的控制器；
* `@request`：请求对象；
* `@response`：响应对象；

### 设置报头和 CGI 变量

[HTTP 报头](http://tools.ietf.org/search/rfc2616#section-5.3) 和 [CGI 变量](http://tools.ietf.org/search/rfc3875#section-4.1)可以通过 `@request` 实例变量设置：

{:lang="ruby"}
~~~
# setting a HTTP Header
@request.headers["Accept"] = "text/plain, text/html"
get :index # simulate the request with custom header

# setting a CGI variable
@request.headers["HTTP_REFERER"] = "http://example.com/home"
post :create # simulate the request with custom env variable
~~~

### 测试模板和布局

如果想测试响应是否使用正确的模板和布局渲染，可以使用 `assert_template` 方法：

{:lang="ruby"}
~~~
test "index should render correct template and layout" do
  get :index
  assert_template :index
  assert_template layout: "layouts/application"
end
~~~

注意，不能在 `assert_template` 方法中同时测试模板和布局。测试布局时，可以使用正则表达式代替字符串，不过字符串的意思更明了。即使布局保存在标准位置，也要包含文件夹的名字，所以 `assert_template layout: "application"` 不是正确的写法。

如果视图中用到了局部视图，测试布局时必须指定局部视图，否则测试会失败。所以，如果用到了 `_form` 局部视图，下面的断言写法才是正确的：

{:lang="ruby"}
~~~
test "new should render correct layout" do
  get :new
  assert_template layout: "layouts/application", partial: "_form"
end
~~~

如果没有指定 `:partial`，`assert_template` 会报错。

### 完整的功能测试示例

下面这个例子用到了 `flash`、`assert_redirected_to` 和 `assert_difference`：

{:lang="ruby"}
~~~
test "should create post" do
  assert_difference('Post.count') do
    post :create, post: {title: 'Hi', body: 'This is my first post.'}
  end
  assert_redirected_to post_path(assigns(:post))
  assert_equal 'Post was successfully created.', flash[:notice]
end
~~~

### 测试视图

测试请求的响应中是否出现关键的 HTML 元素和相应的内容是测试程序视图的一种有效方式。`assert_select` 断言可以完成这种测试，其句法简单而强大。

NOTE: 你可能在其他文档中见到过 `assert_tag`，因为 `assert_select` 断言的出现，`assert_tag` 现已弃用。

`assert_select` 有两种用法：

`assert_select(selector, [equality], [message])` 测试 `selector` 选中的元素是否符合 `equality` 指定的条件。`selector` 可以是 CSS 选择符表达式（字符串），有代入值的表达式，或者 `HTML::Selector` 对象。

`assert_select(element, selector, [equality], [message])` 测试 `selector` 选中的元素和 `element`（`HTML::Node` 实例）及其子元素是否符合 `equality` 指定的条件。

例如，可以使用下面的断言检测 `title` 元素的内容：

{:lang="ruby"}
~~~
assert_select 'title', "Welcome to Rails Testing Guide"
~~~

`assert_select` 的代码块还可嵌套使用。这时内层的 `assert_select` 会在外层 `assert_select` 块选中的元素集合上运行断言：

{:lang="ruby"}
~~~
assert_select 'ul.navigation' do
  assert_select 'li.menu_item'
end
~~~

除此之外，还可以遍历外层 `assert_select` 选中的元素集合，这样就可以在集合的每个元素上运行内层 `assert_select` 了。假如响应中有两个有序列表，每个列表中都有 4 各列表项，那么下面这两个测试都会通过：

{:lang="ruby"}
~~~
assert_select "ol" do |elements|
  elements.each do |element|
    assert_select element, "li", 4
  end
end

assert_select "ol" do
  assert_select "li", 8
end
~~~

`assert_select` 断言很强大，高级用法请参阅[文档](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/SelectorAssertions.html)。

#### 其他视图相关的断言

There are more assertions that are primarily used in testing views:

| 断言                                                      | 作用   |
|-----------------------------------------------------------|--------|
| `assert_select_email`                                     | 检测 Email 的内容 |
| `assert_select_encoded`                                   | 检测编码后的 HTML，先解码各元素的内容，然后在代码块中调用每个解码后的元素 |
| `css_select(selector)` 或 `css_select(element, selector)` | 返回由 `selector` 选中的所有元素组成的数组，在后一种用法中，首先会找到 `element`，然后在其中执行 `selector` 表达式查找元素，如果没有匹配的元素，两种用法都返回空数组 |

下面是 `assert_select_email` 断言的用法举例：

{:lang="ruby"}
~~~
assert_select_email do
  assert_select 'small', 'Please click the "Unsubscribe" link if you want to opt-out.'
end
~~~

## 集成测试

继承测试用来测试多个控制器之间的交互，一般用来测试程序中重要的工作流程。

与单元测试和功能测试不同，集成测试必须单独生成，保存在 `test/integration` 文件夹中。Rails 提供了一个生成器用来生成集成测试骨架。

{:lang="bash"}
~~~
$ rails generate integration_test user_flows
      exists  test/integration/
      create  test/integration/user_flows_test.rb
~~~

新生成的集成测试如下：

{:lang="ruby"}
~~~
require 'test_helper'

class UserFlowsTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
end
~~~

集成测试继承自 `ActionDispatch::IntegrationTest`，因此可在测试中使用一些额外的帮助方法。在集成测试中还要自行引入固件，这样才能在测试中使用。

### 集成测试中可用的帮助方法

除了标准的测试帮助方法之外，在集成测试中还可使用下列帮助方法：

| 帮助方法                                                           | 作用 |
|--------------------------------------------------------------------|------|
| `https?`                                                           | 如果模拟的是 HTTPS 请求，返回 `true`          |
| `https!`                                                           | 模拟 HTTPS 请求                               |
| `host!`                                                            | 设置下次请求使用的主机名                      |
| `redirect?`                                                        | 如果上次请求是转向，返回 `true`               |
| `follow_redirect!`                                                 | 跟踪一次转向                                  |
| `request_via_redirect(http_method, path, [parameters], [headers])` | 发起一次 HTTP 请求，并跟踪后续全部转向        |
| `post_via_redirect(path, [parameters], [headers])`                 | 发起一次 HTTP POST 请求，并跟踪后续全部转向   |
| `get_via_redirect(path, [parameters], [headers])`                  | 发起一次 HTTP GET 请求，并跟踪后续全部转向    |
| `patch_via_redirect(path, [parameters], [headers])`                | 发起一次 HTTP PATCH 请求，并跟踪后续全部转向  |
| `put_via_redirect(path, [parameters], [headers])`                  | 发起一次 HTTP PUT 请求，并跟踪后续全部转向    |
| `delete_via_redirect(path, [parameters], [headers])`               | 发起一次 HTTP DELETE 请求，并跟踪后续全部转向 |
| `open_session`                                                     | 创建一个新会话实例                            |

### 集成测试示例

下面是个简单的集成测试，涉及多个控制器：

{:lang="ruby"}
~~~
require 'test_helper'

class UserFlowsTest < ActionDispatch::IntegrationTest
  fixtures :users

  test "login and browse site" do
    # login via https
    https!
    get "/login"
    assert_response :success

    post_via_redirect "/login", username: users(:david).username, password: users(:david).password
    assert_equal '/welcome', path
    assert_equal 'Welcome david!', flash[:notice]

    https!(false)
    get "/posts/all"
    assert_response :success
    assert assigns(:products)
  end
end
~~~

如上所述，集成测试涉及多个控制器，而且用到整个程序的各种组件，从数据库到调度程序都有。而且，在同一个测试中还可以创建多个会话实例，还可以使用断言方法创建一种强大的测试 DSL。

下面这个例子用到了多个会话和 DSL：

{:lang="ruby"}
~~~
require 'test_helper'

class UserFlowsTest < ActionDispatch::IntegrationTest
  fixtures :users

  test "login and browse site" do

    # User david logs in
    david = login(:david)
    # User guest logs in
    guest = login(:guest)

    # Both are now available in different sessions
    assert_equal 'Welcome david!', david.flash[:notice]
    assert_equal 'Welcome guest!', guest.flash[:notice]

    # User david can browse site
    david.browses_site
    # User guest can browse site as well
    guest.browses_site

    # Continue with other assertions
  end

  private

    module CustomDsl
      def browses_site
        get "/products/all"
        assert_response :success
        assert assigns(:products)
      end
    end

    def login(user)
      open_session do |sess|
        sess.extend(CustomDsl)
        u = users(user)
        sess.https!
        sess.post "/login", username: u.username, password: u.password
        assert_equal '/welcome', sess.path
        sess.https!(false)
      end
    end
end
~~~

## 运行测试使用的 Rake 任务

你不用一个一个手动运行测试，Rails 提供了很多运行测试的命令。下表列出了新建 Rails 程序后，默认的 `Rakefile` 中包含的用来运行测试的命令。

| 任务                    | 说明      |
|-------------------------|-----------|
| `rake test`             | 运行所有单元测试，功能测试和继承测试。还可以直接运行 `rake`，因为默认的 Rake 任务就是运行所有测试。 |
| `rake test:controllers` | 运行 `test/controllers` 文件夹中的所有控制器测试 |
| `rake test:functionals` | 运行文件夹 `test/controllers`、`test/mailers` 和 `test/functional` 中的所有功能测试 |
| `rake test:helpers`     | 运行 `test/helpers` 文件夹中的所有帮助方法测试 |
| `rake test:integration` | 运行 `test/integration` 文件夹中的所有集成测试 |
| `rake test:mailers`     | 运行 `test/mailers` 文件夹中的所有邮件测试 |
| `rake test:models`      | 运行 `test/models` 文件夹中的所有模型测试 |
| `rake test:units`       | 运行文件夹 `test/models`、`test/helpers` 和 `test/unit` 中的所有单元测试 |
| `rake test:all`         | 不还原数据库，快速运行所有测试 |
| `rake test:all:db`      | 还原数据库，快速运行所有测试 |

## MiniTest 简介

Ruby 提供了很多代码库，Ruby 1.8 提供有 `Test::Unit`，这是个单元测试框架。前文介绍的所有基本断言都在 `Test::Unit::Assertions` 中定义。在单元测试和功能测试中使用的 `ActiveSupport::TestCase` 继承自 `Test::Unit::TestCase`，因此可在测试中使用所有的基本断言。

Ruby 1.9 引入了 `MiniTest`，这是 `Test::Unit` 的改进版本，兼容 `Test::Unit`。在 Ruby 1.8 中安装 `minitest` gem 就可使用 `MiniTest`。

NOTE: 关于 `Test::Unit` 更详细的介绍，请参阅其[文档](http://ruby-doc.org/stdlib/libdoc/test/unit/rdoc/)。关于 `MiniTest` 更详细的介绍，请参阅其[文档](http://ruby-doc.org/stdlib-1.9.3/libdoc/minitest/unit/rdoc/)。

## 测试前准备和测试后清理

如果想在每个测试运行之前以及运行之后运行一段代码，可以使用两个特殊的回调。我们以 `Posts` 控制器的功能测试为例，说明这两个回调的用法：

{:lang="ruby"}
~~~
require 'test_helper'

class PostsControllerTest < ActionController::TestCase

  # called before every single test
  def setup
    @post = posts(:one)
  end

  # called after every single test
  def teardown
    # as we are re-initializing @post before every test
    # setting it to nil here is not essential but I hope
    # you understand how you can use the teardown method
    @post = nil
  end

  test "should show post" do
    get :show, id: @post.id
    assert_response :success
  end

  test "should destroy post" do
    assert_difference('Post.count', -1) do
      delete :destroy, id: @post.id
    end

    assert_redirected_to posts_path
  end

end
~~~

在上述代码中，运行各测试之前都会执行 `setup` 方法，所以在每个测试中都可使用 `@post`。Rails 以 `ActiveSupport::Callbacks` 的方式实现 `setup` 和 `teardown`，因此这两个方法不仅可以作为方法使用，还可以这么用：

* 代码块
* 方法（如上例所示）
* 用 Symbol 表示的方法名
* Lambda

下面重写前例，为 `setup` 指定一个用 Symbol 表示的方法名：

{:lang="ruby"}
~~~
require 'test_helper'

class PostsControllerTest < ActionController::TestCase

  # called before every single test
  setup :initialize_post

  # called after every single test
  def teardown
    @post = nil
  end

  test "should show post" do
    get :show, id: @post.id
    assert_response :success
  end

  test "should update post" do
    patch :update, id: @post.id, post: {}
    assert_redirected_to post_path(assigns(:post))
  end

  test "should destroy post" do
    assert_difference('Post.count', -1) do
      delete :destroy, id: @post.id
    end

    assert_redirected_to posts_path
  end

  private

    def initialize_post
      @post = posts(:one)
    end
end
~~~

## 测试路由

和 Rails 程序的其他部分一样，也建议你测试路由。针对前文 `Posts` 控制器中默认生成的 `show` 动作，其路由测试如下：

{:lang="ruby"}
~~~
test "should route to post" do
  assert_routing '/posts/1', {controller: "posts", action: "show", id: "1"}
end
~~~

## 测试邮件程序

测试邮件程序需要一些特殊的工具才能完成。

### 确保邮件程序在管控内

和其他 Rails 程序的组件一样，邮件程序也要做测试，确保其能正常工作。

测试邮件程序的目的是：

* 确保处理了邮件（创建及发送）
* 确保邮件内容正确（主题，发件人，正文等）
* 确保在正确的时间发送正确的邮件；

#### 要全面测试

针对邮件程序的测试分为两部分：单元测试和功能测试。在单元测试中，单独运行邮件程序，严格控制输入，然后和已知值（固件）对比。在功能测试中，不用这么细致的测试，只要确保控制器和模型正确的使用邮件程序，在正确的时间发送正确的邮件。

### 单元测试

要想测试邮件程序是否能正常使用，可以把邮件程序真正得到的记过和预先写好的值进行对比。

#### 固件的另一个用途

在单元测试中，固件用来设定期望得到的值。因为这些固件是示例邮件，不是 Active Record 数据，所以要和其他固件分开，放在单独的子文件夹中。这个子文件夹位于 `test/fixtures` 文件夹中，其名字来自邮件程序。例如，邮件程序 `UserMailer` 使用的固件保存在 `test/fixtures/user_mailer` 文件夹中。

生成邮件程序时，会为其中每个动作生成相应的固件。如果没使用生成器，就要手动创建固件。

#### 基本测试

下面的单元测试针对 `UserMailer` 的 `invite` 动作，这个动作的作用是向朋友发送邀请。这段代码改进了生成器为 `invite` 动作生成的测试。

{:lang="ruby"}
~~~
require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test "invite" do
    # Send the email, then test that it got queued
    email = UserMailer.create_invite('me@example.com',
                                     'friend@example.com', Time.now).deliver
    assert_not ActionMailer::Base.deliveries.empty?

    # Test the body of the sent email contains what we expect it to
    assert_equal ['me@example.com'], email.from
    assert_equal ['friend@example.com'], email.to
    assert_equal 'You have been invited by me@example.com', email.subject
    assert_equal read_fixture('invite').join, email.body.to_s
  end
end
~~~

在这个测试中，我们发送了一封邮件，并把返回对象赋值给 `email` 变量。在第一个断言中确保邮件已经发送了；在第二段断言中，确保邮件包含了期望的内容。`read_fixture` 这个帮助方法的作用是从指定的文件中读取固件。

`invite` 固件的内容如下：

~~~
Hi friend@example.com,

You have been invited.

Cheers!
~~~

现在我们稍微深入一点地介绍针对邮件程序的测试。在文件 `config/environments/test.rb` 中，有这么一行设置：`ActionMailer::Base.delivery_method = :test`。这行设置把发送邮件的方法设为 `:test`，所以邮件并不会真的发送出去（避免测试时骚扰用户），而是添加到一个数组中（`ActionMailer::Base.deliveries`）。

NOTE: `ActionMailer::Base.deliveries` 数组只会在 `ActionMailer::TestCase` 测试中自动重设，如果想在测试之外使用空数组，可以手动重设：`ActionMailer::Base.deliveries.clear`。

### 功能测试

功能测试不只是测试邮件正文和收件人等是否正确这么简单。在针对邮件程序的功能测试中，要调用发送邮件的方法，检查相应的邮件是否出现在发送列表中。你可以尽情放心地假定发送邮件的方法本身能顺利完成工作。你需要重点关注的是程序自身的业务逻辑，确保能在期望的时间发出邮件。例如，可以使用下面的代码测试要求朋友的操作是否发出了正确的邮件：

{:lang="ruby"}
~~~
require 'test_helper'

class UserControllerTest < ActionController::TestCase
  test "invite friend" do
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      post :invite_friend, email: 'friend@example.com'
    end
    invite_email = ActionMailer::Base.deliveries.last

    assert_equal "You have been invited by me@example.com", invite_email.subject
    assert_equal 'friend@example.com', invite_email.to[0]
    assert_match(/Hi friend@example.com/, invite_email.body)
  end
end
~~~

## 测试帮助方法

针对帮助方法的测试，只需检测帮助方法的输出和预想的值是否一致，所需的测试文件保存在 `test/helpers` 文件夹中。Rails 提供了一个生成器，用来生成帮助方法和测试文件：

{:lang="bash"}
~~~
$ rails generate helper User
      create  app/helpers/user_helper.rb
      invoke  test_unit
      create    test/helpers/user_helper_test.rb
~~~

生成的测试文件内容如下：

{:lang="ruby"}
~~~
require 'test_helper'

class UserHelperTest < ActionView::TestCase
end
~~~

帮助方法就是可以在视图中使用的方法。要测试帮助方法，要按照如下的方式混入相应的模块：

{:lang="ruby"}
~~~
class UserHelperTest < ActionView::TestCase
  include UserHelper

  test "should return the user name" do
    # ...
  end
end
~~~

而且，因为测试类继承自 `ActionView::TestCase`，所以在测试中可以使用 Rails 内建的帮助方法，例如 `link_to` 和 `pluralize`。

## 其他测试方案

Rails 内建基于 `test/unit` 的测试并不是唯一的测试方式。Rails 开发者发明了很多方案，开发了很多协助测试的代码库，例如：

* [NullDB](http://avdi.org/projects/nulldb/)：提升测试速度的一种方法，不使用数据库；
* [Factory Girl](https://github.com/thoughtbot/factory_girl/tree/master)：固件的替代品；
* [Machinist](https://github.com/notahat/machinist/tree/master)：另一个固件替代品；
* [Fixture Builder](https://github.com/rdy/fixture_builder)：运行测试前把预构件（factory）转换成固件的工具
* [MiniTest::Spec Rails](https://github.com/metaskills/minitest-spec-rails)：在 Rails 测试中使用 MiniTest::Spec 这套 DSL；
* [Shoulda](http://www.thoughtbot.com/projects/shoulda)：对 `test/unit` 的扩展，提供了额外的帮助方法，断言等；
* [RSpec](http://relishapp.com/rspec)：行为驱动开发（Behavior-Driven Development，BDD）框架；
