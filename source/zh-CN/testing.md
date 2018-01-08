# Rails 应用测试指南

本文介绍 Rails 内建对测试的支持。

读完本文后，您将学到：

*   Rails 测试术语；
*   如何为应用编写单元测试、功能测试、集成测试和系统测试；
*   其他常用的测试方法和插件。

-----------------------------------------------------------------------------

<a class="anchor" id="why-write-tests-for-your-rails-applications-questionmark"></a>

## 为什么要为 Rails 应用编写测试？

在 Rails 中编写测试非常简单，生成模型和控制器时，已经生成了测试代码骨架。

即便是大范围重构后，只需运行测试就能确保实现了所需的功能。

Rails 测试还可以模拟浏览器请求，无需打开浏览器就能测试应用的响应。

<a class="anchor" id="introduction-to-testing"></a>

## 测试简介

测试是 Rails 应用的重要组成部分，不是为了尝鲜和好奇而编写的。

<a class="anchor" id="rails-sets-up-for-testing-from-the-word-go"></a>

### Rails 内建对测试的支持

使用 `rails new application_name` 命令创建一个 Rails 项目时，Rails 会生成 `test` 目录。如果列出这个目录里的内容，你会看到下述目录和文件：

```sh
$ ls -F test
controllers/           helpers/               mailers/               system/                test_helper.rb
fixtures/              integration/           models/                application_system_test_case.rb
```

`helpers` 目录存放视图辅助方法的测试，`mailers` 目录存放邮件程序的测试，`models` 目录存放模型的测试，`controllers` 目录存放控制器的测试，`integration` 目录存放涉及多个控制器交互的测试。此外，还有一个目录用于存放辅助方法的测试。

`system` 目录存放系统测试，在浏览器中全面测试应用。系统测试模拟用户的交互，还能测试 JavaScript。系统测试源自 Capybara，在浏览器中测试应用。

测试数据使用固件（fixture）组织，存放在 `fixtures` 目录中。

如果先期生成了作业测试，还会创建 `jobs` 目录。

`test_helper.rb` 文件存储测试的默认配置。

`application_system_test_case.rb` 文件存储系统测试的默认配置。

<a class="anchor" id="the-test-environment"></a>

### 测试环境

默认情况下，Rails 应用有三个环境：开发环境、测试环境和生产环境。

各个环境的配置通过类似的方式修改。这里，如果想配置测试环境，可以修改 `config/environments/test.rb` 文件中的选项。

NOTE: 运行测试时，`RAILS_ENV` 环境变量的值是 `test`。


<a class="anchor" id="rails-meets-minitest"></a>

### 使用 Minitest 测试 Rails 应用

还记得我们在[Rails 入门](getting_started.html)用过的 `rails generate model` 命令吗？我们使用这个命令生成了第一个模型，这个命令会生成很多内容，其中就包括在 `test` 目录中创建的测试：

```ruby
$ bin/rails generate model article title:string body:text
...
create  app/models/article.rb
create  test/models/article_test.rb
create  test/fixtures/articles.yml
...
```

默认在 `test/models/article_test.rb` 文件中生成的测试如下：

```ruby
require 'test_helper'

class ArticleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
```

下面逐行说明这段代码，让你初步了解 Rails 测试代码和相关的术语。

```ruby
require 'test_helper'
```

这行代码引入 `test_helper.rb` 文件，即加载默认的测试配置。我们编写的所有测试都会引入这个文件，因此这个文件中定义的代码在所有测试中都可用。

```ruby
class ArticleTest < ActiveSupport::TestCase
```

`ArticleTest` 类定义一个测试用例（test case），它继承自 `ActiveSupport::TestCase`，因此继承了后者的全部方法。本文后面会介绍其中几个。

在继承自 `Minitest::Test`（`ActiveSupport::TestCase` 的超类）的类中定义的方法，只要名称以 `test_` 开头（区分大小写），就是一个“测试”。因此，名为 `test_password` 和 `test_valid_password` 的方法是有效的测试，运行测试用例时会自动运行。

此外，Rails 定义了 `test` 方法，它接受一个测试名称和一个块。`test` 方法在测试名称前面加上 `test_`，生成常规的 `Minitest::Unit` 测试。因此，我们无需费心为方法命名，可以像下面这样写：

```ruby
test "the truth" do
  assert true
end
```

这段代码几乎与下述代码一样：

```ruby
def test_the_truth
  assert true
end
```

虽然可以像普通的方法那样定义测试，但是使用 `test` 宏能指定更易读的测试名称。

NOTE: 生成方法名时，空格会替换成下划线。不过，结果无需是有效的 Ruby 标识符，名称中可以包含标点符号等。这是因为，严格来说，在 Ruby 中任何字符串都可以作为方法的名称。这样，可能需要使用 `define_method` 和 `send` 才能让方法其作用，不过在名称形式上的限制较少。


接下来是我们遇到的第一个断言（assertion）：

```ruby
assert true
```

断言求值对象（或表达式），然后与预期结果比较。例如，断言可以检查：

*   两个值是否相等
*   对象是否为 `nil`
*   一行代码是否抛出异常
*   用户的密码长度是否超过 5 个字符

一个测试中可以有一个或多个断言，对断言的数量没有限制。只有全部断言都成功，测试才能通过。

<a class="anchor" id="your-first-failing-test"></a>

#### 第一个失败测试

为了了解失败测试是如何报告的，下面在 `article_test.rb` 测试用例中添加一个失败测试：

```ruby
test "should not save article without title" do
  article = Article.new
  assert_not article.save
end
```

然后运行这个新增的测试（其中，6 是测试定义所在的行号）：

```sh
$ bin/rails test test/models/article_test.rb:6
Run options: --seed 44656

# Running:

F

Failure:
ArticleTest#test_should_not_save_article_without_title [/path/to/blog/test/models/article_test.rb:6]:
Expected true to be nil or false


bin/rails test test/models/article_test.rb:6



Finished in 0.023918s, 41.8090 runs/s, 41.8090 assertions/s.

1 runs, 1 assertions, 1 failures, 0 errors, 0 skips
```

输出中的 F 表示失败（failure）。可以看到，`Failure` 下面显示了相应的路径和失败测试的名称。下面几行是堆栈跟踪，以及传入断言的具体值和预期值。默认的断言消息足够用于定位错误了。如果想让断言失败消息提供更多的信息，可以使用每个断言都有的可选参数定制消息，如下所示：

```ruby
test "should not save article without title" do
  article = Article.new
  assert_not article.save, "Saved the article without a title"
end
```

现在运行测试会看到更加友好的断言消息：

```ruby
Failure:
ArticleTest#test_should_not_save_article_without_title [/path/to/blog/test/models/article_test.rb:6]:
Saved the article without a title
```

为了让测试通过，我们可以为 `title` 字段添加一个模型层验证：

```ruby
class Article < ApplicationRecord
  validates :title, presence: true
end
```

现在测试应该能通过了。再次运行测试，确认一下：

```ruby
$ bin/rails test test/models/article_test.rb:6
Run options: --seed 31252

# Running:

.

Finished in 0.027476s, 36.3952 runs/s, 36.3952 assertions/s.

1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
```

你可能注意到了，我们先编写一个测试检查所需的功能，它失败了，然后我们编写代码，添加功能，最后确认测试能通过。这种开发软件的方式叫做[测试驱动开发](http://c2.com/cgi/wiki?TestDrivenDevelopment)（Test-Driven Development，TDD）。

<a class="anchor" id="what-an-error-looks-like"></a>

#### 失败的样子

为了查看错误是如何报告的，下面编写一个包含错误的测试：

```ruby
test "should report error" do
  # 测试用例中没有定义 some_undefined_variable
  some_undefined_variable
  assert true
end
```

然后运行测试，你会看到更多输出：

```sh
$ bin/rails test test/models/article_test.rb
Run options: --seed 1808

# Running:

.E

Error:
ArticleTest#test_should_report_error:
NameError: undefined local variable or method `some_undefined_variable' for #<ArticleTest:0x007fee3aa71798>
    test/models/article_test.rb:11:in `block in <class:ArticleTest>'


bin/rails test test/models/article_test.rb:9



Finished in 0.040609s, 49.2500 runs/s, 24.6250 assertions/s.

2 runs, 1 assertions, 0 failures, 1 errors, 0 skips
```

注意输出中的“E”，它表示测试有错误（error）。

NOTE: 执行各个测试方法时，只要遇到错误或断言失败，就立即停止，然后接着运行测试组件中的下一个测试方法。测试方法以随机顺序执行。测试顺序可以使用 [`config.active_support.test_order` 选项](configuring.html#configuring-active-support)配置。


测试失败时会显示相应的回溯信息。默认情况下，Rails 会过滤回溯信息，只打印与应用有关的内容。这样不会被框架相关的内容搅乱，有助于集中精力排查代码中的错误。不过，有时需要查看完整的回溯信息。此时，只需设定 `-b`（或 `--backtrace`）参数就能启用这一行为：

```sh
$ bin/rails test -b test/models/article_test.rb
```

若想让这个测试通过，可以使用 `assert_raises` 修改，如下：

```ruby
test "should report error" do
  # 测试用例中没有定义 some_undefined_variable
  assert_raises(NameError) do
    some_undefined_variable
  end
end
```

现在这个测试应该能通过了。

<a class="anchor" id="available-assertions"></a>

### 可用的断言

我们大致了解了几个可用的断言。断言是测试的核心所在，是真正执行检查、确保功能符合预期的执行者。

下面摘录部分可以在 [Minitest](https://github.com/seattlerb/minitest)（Rails 默认使用的测试库）中使用的断言。`[msg]` 参数是可选的消息字符串，能让测试失败消息更明确。

| 断言 | 作用  |
|---|---|
| `assert( test, [msg] )` | 确保 `test` 是真值。  |
| `assert_not( test, [msg] )` | 确保 `test` 是假值。  |
| `assert_equal( expected, actual, [msg] )` | 确保 `expected == actual` 成立。  |
| `assert_not_equal( expected, actual, [msg] )` | 确保 `expected != actual` 成立。  |
| `assert_same( expected, actual, [msg] )` | 确保 `expected.equal?(actual)` 成立。  |
| `assert_not_same( expected, actual, [msg] )` | 确保 `expected.equal?(actual)` 不成立。  |
| `assert_nil( obj, [msg] )` | 确保 `obj.nil?` 成立。  |
| `assert_not_nil( obj, [msg] )` | 确保 `obj.nil?` 不成立。  |
| `assert_empty( obj, [msg] )` | 确保 `obj` 是空的。  |
| `assert_not_empty( obj, [msg] )` | 确保 `obj` 不是空的。  |
| `assert_match( regexp, string, [msg] )` | 确保字符串匹配正则表达式。  |
| `assert_no_match( regexp, string, [msg] )` | 确保字符串不匹配正则表达式。  |
| `assert_includes( collection, obj, [msg] )` | 确保 `obj` 在 `collection` 中。  |
| `assert_not_includes( collection, obj, [msg] )` | 确保 `obj` 不在 `collection` 中。  |
| `assert_in_delta( expected, actual, [delta], [msg] )` | 确保 `expected` 和 `actual` 的差值在 `delta` 的范围内。  |
| `assert_not_in_delta( expected, actual, [delta], [msg] )` | 确保 `expected` 和 `actual` 的差值不在 `delta` 的范围内。  |
| `assert_throws( symbol, [msg] ) { block }` | 确保指定的块会抛出指定符号表示的异常。  |
| `assert_raises( exception1, exception2, &#8230;&#8203; ) { block }` | 确保指定块会抛出指定异常中的一个。  |
| `assert_instance_of( class, obj, [msg] )` | 确保 `obj` 是 `class` 的实例。  |
| `assert_not_instance_of( class, obj, [msg] )` | 确保 `obj` 不是 `class` 的实例。  |
| `assert_kind_of( class, obj, [msg] )` | 确保 `obj` 是 `class` 或其后代的实例。  |
| `assert_not_kind_of( class, obj, [msg] )` | 确保 `obj` 不是 `class` 或其后代的实例。  |
| `assert_respond_to( obj, symbol, [msg] )` | 确保 `obj` 能响应 `symbol` 对应的方法。  |
| `assert_not_respond_to( obj, symbol, [msg] )` | 确保 `obj` 不能响应 `symbol` 对应的方法。  |
| `assert_operator( obj1, operator, [obj2], [msg] )` | 确保 `obj1.operator(obj2)` 成立。  |
| `assert_not_operator( obj1, operator, [obj2], [msg] )` | 确保 `obj1.operator(obj2)` 不成立。  |
| `assert_predicate( obj, predicate, [msg] )` | 确保 `obj.predicate` 为真，例如 `assert_predicate str, :empty?`。  |
| `assert_not_predicate( obj, predicate, [msg] )` | 确保 `obj.predicate` 为假，例如 `assert_not_predicate str, :empty?`。  |
| `flunk( [msg] )` | 确保失败。可以用这个断言明确标记未完成的测试。  |

以上是 Minitest 支持的部分断言，完整且最新的列表参见 [Minitest API 文档](http://docs.seattlerb.org/minitest/)，尤其是 [`Minitest::Assertions` 模块的文档](http://docs.seattlerb.org/minitest/Minitest/Assertions.html)。

Minitest 这个测试框架是模块化的，因此还可以自己创建断言。事实上，Rails 就这么做了。Rails 提供了一些专门的断言，能简化测试。

NOTE: 自己创建断言是高级话题，本文不涉及。


<a class="anchor" id="rails-specific-assertions"></a>

### Rails 专有的断言

在 Minitest 框架的基础上，Rails 添加了一些自定义的断言。

| 断言 | 作用  |
|---|---|
| `assert_difference(expressions, difference = 1, message = nil) {&#8230;&#8203;}` | 运行代码块前后数量变化了多少（通过 `expression` 表示）。  |
| `assert_no_difference(expressions, message = nil, &block)` | 运行代码块前后数量没变多少（通过 `expression` 表示）。  |
| `assert_nothing_raised { block }` | 确保指定的块不会抛出任何异常。  |
| `assert_recognizes(expected_options, path, extras={}, message=nil)` | 断言正确处理了指定路径，而且解析的参数（通过 `expected_options` 散列指定）与路径匹配。基本上，它断言 Rails 能识别 `expected_options` 指定的路由。  |
| `assert_generates(expected_path, options, defaults={}, extras = {}, message=nil)` | 断言指定的选项能生成指定的路径。作用与 `assert_recognizes` 相反。`extras` 参数用于构建查询字符串。`message` 参数用于为断言失败定制错误消息。  |
| `assert_response(type, message = nil)` | 断言响应的状态码。可以指定表示 200-299 的 `:success`，表示 300-399 的 `:redirect`，表示 404 的 `:missing`，或者表示 500-599 的 `:error`。此外，还可以明确指定数字状态码或对应的符号。详情参见[完整的状态码列表](http://rubydoc.info/github/rack/rack/master/Rack/Utils#HTTP_STATUS_CODES-constant)及其[与符号的对应关系](http://rubydoc.info/github/rack/rack/master/Rack/Utils#SYMBOL_TO_STATUS_CODE-constant)。  |
| `assert_redirected_to(options = {}, message=nil)` | 断言传入的重定向选项匹配最近一个动作中的重定向。重定向参数可以只指定部分，例如 `assert_redirected_to(controller: "weblog")`，也可以完整指定，例如 `redirect_to(controller: "weblog", action: "show")`。此外，还可以传入具名路由，例如 `assert_redirected_to root_path`，以及 Active Record 对象，例如 `assert_redirected_to @article`。  |

在接下来的内容中会用到其中一些断言。

<a class="anchor" id="a-brief-note-about-test-cases"></a>

### 关于测试用例的简要说明

`Minitest::Assertions` 模块定义的所有基本断言，例如 `assert_equal`，都可以在我们编写的测试用例中使用。Rails 提供了下述几个类供你继承：

*   [`ActiveSupport::TestCase`](http://api.rubyonrails.org/classes/ActiveSupport/TestCase.html)
*   [`ActionMailer::TestCase`](http://api.rubyonrails.org/classes/ActionMailer/TestCase.html)
*   [`ActionView::TestCase`](http://api.rubyonrails.org/classes/ActionView/TestCase.html)
*   [`ActionDispatch::IntegrationTest`](http://api.rubyonrails.org/classes/ActionDispatch/IntegrationTest.html)
*   [`ActiveJob::TestCase`](http://api.rubyonrails.org/classes/ActiveJob/TestCase.html)
*   [`ActionDispatch::SystemTestCase`](http://api.rubyonrails.org/classes/ActionDispatch/SystemTestCase.html)

这些类都引入了 `Minitest::Assertions`，因此可以在测试中使用所有基本断言。

NOTE: Minitest 的详情参见[文档](http://docs.seattlerb.org/minitest)。


<a class="anchor" id="the-rails-test-runner"></a>

### Rails 测试运行程序

全部测试可以使用 `bin/rails test` 命令统一运行。

也可以单独运行一个测试，方法是把测试用例所在的文件名传给 `bin/rails test` 命令。

```sh
$ bin/rails test test/models/article_test.rb
Run options: --seed 1559

# Running:

..

Finished in 0.027034s, 73.9810 runs/s, 110.9715 assertions/s.

2 runs, 3 assertions, 0 failures, 0 errors, 0 skips
```

上述命令运行测试用例中的所有测试方法。

也可以运行测试用例中特定的测试方法：指定 `-n` 或 `--name` 旗标和测试方法的名称。

```sh
$ bin/rails test test/models/article_test.rb -n test_the_truth
Run options: -n test_the_truth --seed 43583

# Running:

.

Finished tests in 0.009064s, 110.3266 tests/s, 110.3266 assertions/s.

1 tests, 1 assertions, 0 failures, 0 errors, 0 skips
```

也可以运行某一行中的测试，方法是指定行号。

```sh
$ bin/rails test test/models/article_test.rb:6 # 运行某一行中的测试
```

也可以运行整个目录中的测试，方法是指定目录的路径。

```sh
$ bin/rails test test/controllers # 运行指定目录中的所有测试
```

此外，测试运行程序还有很多功能，例如快速失败、测试运行结束后统一输出，等等。详情参见测试运行程序的文档，如下：

```sh
$ bin/rails test -h
minitest options:
    -h, --help                       Display this help.
    -s, --seed SEED                  Sets random seed. Also via env. Eg: SEED=n rake
    -v, --verbose                    Verbose. Show progress processing files.
    -n, --name PATTERN               Filter run on /regexp/ or string.
        --exclude PATTERN            Exclude /regexp/ or string from run.

Known extensions: rails, pride

Usage: bin/rails test [options] [files or directories]
You can run a single test by appending a line number to a filename:

    bin/rails test test/models/user_test.rb:27

You can run multiple files and directories at the same time:

    bin/rails test test/controllers test/integration/login_test.rb

By default test failures and errors are reported inline during a run.

Rails options:
    -e, --environment ENV            Run tests in the ENV environment
    -b, --backtrace                  Show the complete backtrace
    -d, --defer-output               Output test failures and errors after the test run
    -f, --fail-fast                  Abort test run on first failure or error
    -c, --[no-]color                 Enable color in the output
```

<a class="anchor" id="the-test-database"></a>

## 测试数据库

几乎每个 Rails 应用都经常与数据库交互，因此测试也需要这么做。为了有效编写测试，你要知道如何搭建测试数据库，以及如何使用示例数据填充。

默认情况下，每个 Rails 应用都有三个环境：开发环境、测试环境和生产环境。各个环境中的数据库在 `config/database.yml` 文件中配置。

为测试专门提供一个数据库方便我们单独设置和与测试数据交互。这样，我们可以放心地处理测试数据，不必担心会破坏开发数据库或生产数据库中的数据。

<a class="anchor" id="maintaining-the-test-database-schema"></a>

### 维护测试数据库的模式

为了能运行测试，测试数据库要有应用当前的数据库结构。测试辅助方法会检查测试数据库中是否有尚未运行的迁移。如果有，会尝试把 `db/schema.rb` 或 `db/structure.sql` 载入数据库。之后，如果迁移仍处于待运行状态，会抛出异常。通常，这表明数据库模式没有完全迁移。在开发数据库中运行迁移（`bin/rails db:migrate`）能更新模式。

NOTE: 如果修改了现有的迁移，要重建测试数据库。方法是执行 `bin/rails db:test:prepare` 命令。


<a class="anchor" id="the-low-down-on-fixtures"></a>

### 固件详解

好的测试应该具有提供测试数据的方式。在 Rails 中，测试数据由固件（fixture）提供。关于固件的全面说明，参见 [API 文档](http://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html)。

<a class="anchor" id="what-are-fixtures-questionmark"></a>

#### 固件是什么？

固件代指示例数据，在运行测试之前，使用预先定义好的数据填充测试数据库。固件与所用的数据库没有关系，使用 YAML 格式编写。一个模型有一个固件文件。

NOTE: 固件不是为了创建测试中用到的每一个对象，需要公用的默认数据时才应该使用。


固件保存在 `test/fixtures` 目录中。执行 `rails generate model` 命令生成新模型时，Rails 会在这个目录中自动创建固件文件。

<a class="anchor" id="yaml"></a>

#### YAML

使用 YAML 格式编写的固件可读性高，能更好地表述示例数据。这种固件文件的扩展名是 `.yml`（如 `users.yml`）。

下面举个例子：

```yaml
# lo & behold! I am a YAML comment!
david:
  name: David Heinemeier Hansson
  birthday: 1979-10-15
  profession: Systems development

steve:
  name: Steve Ross Kellock
  birthday: 1974-09-27
  profession: guy with keyboard
```

每个固件都有名称，后面跟着一个缩进的键值对（以冒号分隔）列表。记录之间往往使用空行分开。在固件中可以使用注释，在行首加上 `#` 符号即可。

如果涉及到[关联](association_basics.html)，定义一个指向其他固件的引用即可。例如，下面的固件针对 `belongs_to/has_many` 关联：

```yaml
# In fixtures/categories.yml
about:
  name: About

# In fixtures/articles.yml
first:
  title: Welcome to Rails!
  body: Hello world!
  category: about
```

注意，在 `fixtures/articles.yml` 文件中，`first` 文章的 `category` 是 `about`，这告诉 Rails，要加载 `fixtures/categories.yml` 文件中的 `about` 分类。

NOTE: 在固件中创建关联时，引用的是另一个固件的名称，而不是 `id` 属性。Rails 会自动分配主键。关于这种关联行为的详情，参阅[固件的 API 文档](http://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html)。


<a class="anchor" id="erb-in-it-up"></a>

#### 使用 ERB 增强固件

ERB 用于在模板中嵌入 Ruby 代码。Rails 加载 YAML 格式的固件时，会先使用 ERB 进行预处理，因此可使用 Ruby 代码协助生成示例数据。例如，下面的代码会生成一千个用户：

```erb
<% 1000.times do |n| %>
user_<%= n %>:
  username: <%= "user#{n}" %>
  email: <%= "user#{n}@example.com" %>
<% end %>
```

<a class="anchor" id="fixtures-in-action"></a>

#### 固件实战

默认情况下，Rails 会自动加载 `test/fixtures` 目录中的所有固件。加载的过程分为三步：

1.  从数据表中删除所有和固件对应的数据；
1.  把固件载入数据表；
1.  把固件中的数据转储成方法，以便直接访问。

TIP: 为了从数据库中删除现有数据，Rails 会尝试禁用引用完整性触发器（如外键和约束检查）。运行测试时，如果见到烦人的权限错误，确保数据库用户有权在测试环境中禁用这些触发器。（对 PostgreSQL 来说，只有超级用户能禁用全部触发器。关于 PostgreSQL 权限的详细说明参阅[这篇文章](http://blog.endpoint.com/2012/10/postgres-system-triggers-error.html)。）


<a class="anchor" id="fixtures-are-active-record-objects"></a>

#### 固件是 Active Record 对象

固件是 Active Record 实例。如前一节的第 3 点所述，在测试用例中可以直接访问这个对象，因为固件中的数据会转储成测试用例作用域中的方法。例如：

```ruby
# 返回 david 固件对应的 User 对象
users(:david)

# 返回 david 的 id 属性
users(:david).id

# 还可以调用 User 类的方法
david = users(:david)
david.call(david.partner)
```

如果想一次获取多个固件，可以传入一个固件名称列表。例如：

```ruby
# 返回一个数组，包含 david 和 steve 两个固件
users(:david, :steve)
```

<a class="anchor" id="model-testing"></a>

## 模型测试

模型测试用于测试应用中的各个模型。

Rails 模型测试存储在 `test/models` 目录中。Rails 提供了一个生成器，可用它生成模型测试骨架。

```sh
$ bin/rails generate test_unit:model article title:string body:text
create  test/models/article_test.rb
create  test/fixtures/articles.yml
```

模型测试没有专门的超类（如 `ActionMailer::TestCase`），而是继承自 [`ActiveSupport::TestCase`](http://api.rubyonrails.org/classes/ActiveSupport/TestCase.html)。

<a class="anchor" id="system-testing"></a>

## 系统测试

系统测试用于测试用户与应用的交互，可以在真正的浏览器中运行，也可以在无界面浏览器中运行。系统测试建立在 Capybara 之上。

系统测试存放在应用的 `test/system` 目录中。Rails 为创建系统测试骨架提供了一个生成器：

```sh
$ bin/rails generate system_test users
      invoke test_unit
      create test/system/users_test.rb
```

下面是一个新生成的系统测试：

```ruby
require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  # test "visiting the index" do
  #   visit users_url
  #
  #   assert_selector "h1", text: "Users"
  # end
end
```

默认情况下，系统测试使用 Selenium 驱动在 Chrome 浏览器中运行，界面尺寸为 1400x1400。下一节说明如何修改默认设置。

<a class="anchor" id="changing-the-default-settings"></a>

### 修改默认设置

修改系统测试的默认设置十分简单。所有配置都做了抽象，你只需关注测试本身。

创建新应用或生成脚手架时，会在 `test` 目录中创建 `application_system_test_case.rb` 文件。系统测试的配置都在这个文件中。

如果想修改默认设置，只需修改系统测试使用的驱动。假如你想把 Selenium 驱动换成 Poltergeist。首先，在 `Gemfile` 中添加 Poltergeist gem。然后，在 `application_system_test_case.rb` 文件中这么做：

```ruby
require "test_helper"
require "capybara/poltergeist"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :poltergeist
end
```

驱动名称是 `driven_by` 必须的参数。`driven_by` 接受的可选参数有：`:using`，指定使用的浏览器（仅供 Selenium 使用）；`:screen_size`，修改截图的尺寸；`:options`，设定驱动支持的选项。

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :firefox
end
```

如果所需的 Capybara 配置比 Rails 提供的多，可以把额外配置放在 `application_system_test_case.rb` 文件中。

其他设置参见 [Capybara 的文档](https://github.com/teamcapybara/capybara#setup)。

<a class="anchor" id="screenshot-helper"></a>

### 截图辅助方法

`ScreenshotHelper` 用于截取测试的截图。这有助于查看测试失败时的界面，或者以后通过截图调试。

这个模块提供了两个方法：`take_screenshot` 和 `take_failed_screenshot`。Rails 在 `after_teardown` 中调用了 `take_failed_screenshot`。

`take_screenshot` 辅助方法可以放在测试的任何位置，用于捕获浏览器的截图。

<a class="anchor" id="implementing-a-system-test"></a>

### 编写系统测试

下面我们为前面开发的博客应用添加一个系统测试。这个系统测试访问首页，然后新建一篇博客文章。

如果使用的是脚手架生成器，已经自动创建了系统测试骨架。否则，先生成系统测试骨架：

```sh
$ bin/rails generate system_test articles
```

这个命令会为你创建一个测试文件，在命令行中的输出如下：

```
invoke  test_unit
create    test/system/articles_test.rb
```

打开那个文件，编写第一个断言：

```ruby
require "application_system_test_case"

class ArticlesTest < ApplicationSystemTestCase
  test "viewing the index" do
    visit articles_path
    assert_selector "h1", text: "Articles"
  end
end
```

如果这个测试在文章索引页面发现有一级标题，便能通过。

运行系统测试：

```sh
$ bin/rails test:system
```

NOTE: 如果只运行 `bin/rails test`，系统测试不会运行。若想运行系统测试，必须使用 `bin/rails test:system`。

<a class="anchor" id="creating-articles-system-test"></a>

#### 编写新建文章的系统测试

下面测试在博客中新建文章的流程。

```ruby
test "creating an article" do
  visit articles_path

  click_on "New Article"

  fill_in "Title", with: "Creating an Article"
  fill_in "Body", with: "Created this article successfully!"

  click_on "Create Article"

  assert_text "Creating an Article"
end
```

首先，调用 `visit` 访问 `articles_path`，进入文章索引页面。

然后，`click_on "New Article"` 在索引页面上找到“New Article”按钮，转到 `/articles/new` 页面。

接着，测试在标题和正文框中填入指定的文本。填完之后，点击“Create Article”，发送 POST 请求，在数据库中新建一篇文章。

此时会重定向回到文章索引页面，我们再断言页面中有那篇文章的标题。

<a class="anchor" id="implementing-a-system-test-taking-it-further"></a>

#### 继续测试

系统测试与集成测试类似，可以测试用户与控制器、模型和视图的交互，但是系统测试更强健，能模拟用户使用应用的真实过程。你可以继续测试，测试用户在应用中可能执行的任何操作，例如发表评论、删除文章、发布草稿，等等。

<a class="anchor" id="integration-testing"></a>

## 集成测试

集成测试用于测试应用中不同部分之间的交互，一般用于测试应用中重要的工作流程。

集成测试存储在 `test/integration` 目录中。Rails 提供了一个生成器，使用它可以生成集成测试骨架。

```sh
$ bin/rails generate integration_test user_flows
      exists  test/integration/
      create  test/integration/user_flows_test.rb
```

上述命令生成的集成测试如下：

```ruby
require 'test_helper'

class UserFlowsTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
end
```

这个测试继承自 `ActionDispatch::IntegrationTest` 类，因此可以在集成测试中使用一些额外的辅助方法。

<a class="anchor" id="helpers-available-for-integration-tests"></a>

### 集成测试可用的辅助方法

除了标准的测试辅助方法之外，由于集成测试继承自 `ActionDispatch::IntegrationTest`，因此在集成测试中还可使用一些额外的辅助方法。下面简要介绍三类辅助方法。

集成测试运行程序的说明参阅 [`ActionDispatch::Integration::Runner` 模块的文档](http://api.rubyonrails.org/classes/ActionDispatch/Integration/Runner.html)。

执行请求的方法参见 [`ActionDispatch::Integration::RequestHelpers` 模块的文档](http://api.rubyonrails.org/classes/ActionDispatch/Integration/RequestHelpers.html)。

如果需要修改会话或集成测试的状态，参阅 [`ActionDispatch::Integration::Session` 类的文档](http://api.rubyonrails.org/classes/ActionDispatch/Integration/Session.html)。

<a class="anchor" id="implementing-an-integration-test"></a>

### 编写一个集成测试

下面为博客应用添加一个集成测试。我们将执行基本的工作流程，新建一篇博客文章，确认一切都能正常运作。

首先，生成集成测试骨架：

```sh
$ bin/rails generate integration_test blog_flow
```

这个命令会创建一个测试文件。在上述命令的输出中应该看到：

```
invoke  test_unit
create    test/integration/blog_flow_test.rb
```

打开那个文件，编写第一个断言：

```ruby
require 'test_helper'

class BlogFlowTest < ActionDispatch::IntegrationTest
  test "can see the welcome page" do
    get "/"
    assert_select "h1", "Welcome#index"
  end
end
```

`assert_select` 用于查询请求得到的 HTML，[测试视图](#testing-views)说明。我们使用它测试请求的响应：断言响应的内容中有关键的 HTML 元素。

访问根路径时，应该使用 `welcome/index.html.erb` 渲染视图。因此，这个断言应该通过。

<a class="anchor" id="creating-articles-integration"></a>

#### 测试发布文章的流程

下面测试在博客中新建文章以及查看结果的功能。

```ruby
test "can create an article" do
  get "/articles/new"
  assert_response :success

  post "/articles",
    params: { article: { title: "can create", body: "article successfully." } }
  assert_response :redirect
  follow_redirect!
  assert_response :success
  assert_select "p", "Title:\n  can create"
end
```

我们来分析一下这段测试。

首先，我们调用 `Articles` 控制器的 `new` 动作。应该得到成功的响应。

然后，我们向 `Articles` 控制器的 `create` 动作发送 `POST` 请求：

```ruby
post "/articles",
  params: { article: { title: "can create", body: "article successfully." } }
assert_response :redirect
follow_redirect!
```

请求后面两行的作用是处理创建文章后的重定向。

NOTE: 重定向后如果还想发送请求，别忘了调用 `follow_redirect!`。


最后，我们断言得到的是成功的响应，而且页面中显示了新建的文章。

<a class="anchor" id="taking-it-further"></a>

#### 更进一步

我们刚刚测试了访问博客和新建文章功能，这只是工作流程的一小部分。如果想更进一步，还可以测试评论、删除文章或编辑评论。集成测试就是用来检查应用的各种使用场景的。

<a class="anchor" id="functional-tests-for-your-controllers"></a>

## 为控制器编写功能测试

在 Rails 中，测试控制器各动作需要编写功能测试（functional test）。控制器负责处理应用收到的请求，然后使用视图渲染响应。功能测试用于检查动作对请求的处理，以及得到的结果或响应（某些情况下是 HTML 视图）。

<a class="anchor" id="what-to-include-in-your-functional-tests"></a>

### 功能测试要测试什么

应该测试以下内容：

*   请求是否成功；
*   是否重定向到正确的页面；
*   用户是否通过身份验证；
*   是否把正确的对象传给渲染响应的模板；
*   是否在视图中显示相应的消息；

如果想看一下真实的功能测试，最简单的方法是使用脚手架生成器生成一个控制器：

```sh
$ bin/rails generate scaffold_controller article title:string body:text
...
create  app/controllers/articles_controller.rb
...
invoke  test_unit
create    test/controllers/articles_controller_test.rb
...
```

上述命令会为 `Articles` 资源生成控制器和测试。你可以看一下 `test/controllers` 目录中的 `articles_controller_test.rb` 文件。

如果已经有了控制器，只想为默认的七个动作生成测试代码的话，可以使用下述命令：

```sh
$ bin/rails generate test_unit:scaffold article
...
invoke  test_unit
create test/controllers/articles_controller_test.rb
...
```

下面分析一个功能测试：`articles_controller_test.rb` 文件中的 `test_should_get_index`。

```ruby
# articles_controller_test.rb
class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get articles_url
    assert_response :success
  end
end
```

在 `test_should_get_index` 测试中，Rails 模拟了一个发给 `index` 动作的请求，确保请求成功，而且生成了正确的响应主体。

`get` 方法发起请求，并把结果传入响应中。这个方法可接受 6 个参数：

*   所请求控制器的动作，可使用字符串或符号。
*   `params`：一个选项散列，指定传入动作的请求参数（例如，查询字符串参数或文章变量）。
*   `headers`：设定随请求发送的首部。
*   `env`：按需定制请求环境。
*   `xhr`：指明是不是 Ajax 请求；设为 `true` 表示是 Ajax 请求。
*   `as`：使用其他内容类型编码请求；默认支持 `:json`。

所有关键字参数都是可选的。

举个例子。调用 `:show` 动作，把 `params` 中的 `id` 设为 12，并且设定 `HTTP_REFERER` 首部：

```ruby
get :show, params: { id: 12 }, headers: { "HTTP_REFERER" => "http://example.com/home" }
```

再举个例子。调用 `:update` 动作，把 `params` 中的 `id` 设为 12，并且指明是 Ajax 请求：

```ruby
patch update_url, params: { id: 12 }, xhr: true
```

NOTE: 如果现在运行 `articles_controller_test.rb` 文件中的 `test_should_create_article` 测试，它会失败，因为前文添加了模型层验证。


我们来修改 `articles_controller_test.rb` 文件中的 `test_should_create_article` 测试，让所有测试都通过：

```ruby
test "should create article" do
  assert_difference('Article.count') do
    post articles_url, params: { article: { body: 'Rails is awesome!', title: 'Hello Rails' } }
  end

  assert_redirected_to article_path(Article.last)
end
```

现在你可以运行所有测试，应该都能通过。

NOTE: 如果你按照 [基本身份验证](getting_started.html#basic-authentication)的操作做了，要在 `setup` 块中添加下述代码，这样测试才能全部通过：

```ruby
request.headers['Authorization'] = ActionController::HttpAuthentication::Basic.
  encode_credentials('dhh', 'secret')
```


<a class="anchor" id="available-request-types-for-functional-tests"></a>

### 功能测试中可用的请求类型

如果熟悉 HTTP 协议就会知道，`get` 是请求的一种类型。在 Rails 功能测试中可以使用 6 种请求：

*   `get`
*   `post`
*   `patch`
*   `put`
*   `head`
*   `delete`

这几种请求都有相应的方法可用。在常规的 CRUD 应用中，最常使用 `get`、`post`、`put` 和 `delete`。

NOTE: 功能测试不检测动作是否能接受指定类型的请求，而是关注请求的结果。如果想做这样的测试，应该使用请求测试（request test）。


<a class="anchor" id="testing-xhr-ajax-requests"></a>

### 测试 XHR（Ajax）请求

如果想测试 Ajax 请求，要在 `get`、`post`、`patch`、`put` 或 `delete` 方法中设定 `xhr: true` 选项。例如：

```ruby
test "ajax request" do
  article = articles(:one)
  get article_url(article), xhr: true

  assert_equal 'hello world', @response.body
  assert_equal "text/javascript", @response.content_type
end
```

<a class="anchor" id="the-three-hashes-of-the-apocalypse"></a>

### 可用的三个散列

请求发送并处理之后，有三个散列对象可供我们使用：

*   `cookies`：设定的 cookie
*   `flash`：闪现消息中的对象
*   `session`：会话中的对象

和普通的散列对象一样，可以使用字符串形式的键获取相应的值。此外，也可以使用符号形式的键。例如：

```ruby
flash["gordon"]               flash[:gordon]
session["shmession"]          session[:shmession]
cookies["are_good_for_u"]     cookies[:are_good_for_u]
```

<a class="anchor" id="instance-variables-available"></a>

### 可用的实例变量

在功能测试中，发送请求之后还可以使用下面三个实例变量：

*   `@controller`：处理请求的控制器
*   `@request`：请求对象
*   `@response`：响应对象

```ruby
class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get articles_url

    assert_equal "index", @controller.action_name
    assert_equal "application/x-www-form-urlencoded", @request.media_type
    assert_match "Articles", @response.body
  end
end
```

<a class="anchor" id="setting-headers-and-cgi-variables"></a>

### 设定首部和 CGI 变量

[HTTP 首部](http://tools.ietf.org/search/rfc2616#section-5.3) 和 [CGI 变量](http://tools.ietf.org/search/rfc3875#section-4.1)可以通过 `headers` 参数传入：

```ruby
# 设定一个 HTTP 首部
get articles_url, headers: { "Content-Type": "text/plain" } # 模拟有自定义首部的请求

# 设定一个 CGI 变量
get articles_url, headers: { "HTTP_REFERER": "http://example.com/home" } # 模拟有自定义环境变量的请求
```

<a class="anchor" id="testing-flash-notices"></a>

### 测试闪现消息

你可能还记得，在功能测试中可用的三个散列中有一个是 `flash`。

我们想在这个博客应用中添加一个闪现消息，在成功发布新文章之后显示。

首先，在 `test_should_create_article` 测试中添加一个断言：

```ruby
test "should create article" do
  assert_difference('Article.count') do
    post article_url, params: { article: { title: 'Some title' } }
  end

  assert_redirected_to article_path(Article.last)
  assert_equal 'Article was successfully created.', flash[:notice]
end
```

现在运行测试，应该会看到有一个测试失败：

```sh
$ bin/rails test test/controllers/articles_controller_test.rb -n test_should_create_article
Run options: -n test_should_create_article --seed 32266

# Running:

F

Finished in 0.114870s, 8.7055 runs/s, 34.8220 assertions/s.

  1) Failure:
ArticlesControllerTest#test_should_create_article [/test/controllers/articles_controller_test.rb:16]:
--- expected
+++ actual
@@ -1 +1 @@
-"Article was successfully created."
+nil

1 runs, 4 assertions, 1 failures, 0 errors, 0 skips
```

接下来，在控制器中添加闪现消息。现在，`create` 控制器应该是下面这样：

```ruby
def create
  @article = Article.new(article_params)

  if @article.save
    flash[:notice] = 'Article was successfully created.'
    redirect_to @article
  else
    render 'new'
  end
end
```

再运行测试，应该能通过：

```sh
$ bin/rails test test/controllers/articles_controller_test.rb -n test_should_create_article
Run options: -n test_should_create_article --seed 18981

# Running:

.

Finished in 0.081972s, 12.1993 runs/s, 48.7972 assertions/s.

1 runs, 4 assertions, 0 failures, 0 errors, 0 skips
```

<a class="anchor" id="putting-it-together"></a>

### 测试其他动作

至此，我们测试了 `Articles` 控制器的 `index`、`new` 和 `create` 三个动作。那么，怎么处理现有数据呢？

下面为 `show` 动作编写一个测试：

```ruby
test "should show article" do
  article = articles(:one)
  get article_url(article)
  assert_response :success
end
```

还记得前文对固件的讨论吗？我们可以使用 `articles()` 方法访问 `Articles` 固件。

怎么删除现有的文章呢？

```ruby
test "should destroy article" do
  article = articles(:one)
  assert_difference('Article.count', -1) do
    delete article_url(article)
  end

  assert_redirected_to articles_path
end
```

我们还可以为更新现有文章这一操作编写一个测试。

```ruby
test "should update article" do
  article = articles(:one)

  patch article_url(article), params: { article: { title: "updated" } }

  assert_redirected_to article_path(article)
  # 重新加载关联，获取最新的数据，然后断定标题更新了
  article.reload
  assert_equal "updated", article.title
end
```

可以看到，这三个测试中开始有重复了：都访问了同一个文章固件数据。为了避免自我重复，我们可以使用 `ActiveSupport::Callbacks` 提供的 `setup` 和 `teardown` 方法清理。

清理后的测试如下。为了行为简洁，我们暂且不管其他测试。

```ruby
require 'test_helper'

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  # 在各个测试之前调用
  setup do
    @article = articles(:one)
  end

  # 在各个测试之后调用
  teardown do
    # 如果控制器使用缓存，最好在后面重设
    Rails.cache.clear
  end

  test "should show article" do
    # 复用 setup 中定义的 @article 实例变量
    get article_url(@article)
    assert_response :success
  end

  test "should destroy article" do
    assert_difference('Article.count', -1) do
      delete article_url(@article)
    end

    assert_redirected_to articles_path
  end

  test "should update article" do
    patch article_url(@article), params: { article: { title: "updated" } }

    assert_redirected_to article_path(@article)
    # 重新加载关联，获取最新的数据，然后断定标题更新了
    @article.reload
    assert_equal "updated", @article.title
  end
end
```

与 Rails 中的其他回调一样，`setup` 和 `teardown` 也接受块、lambda 或符号形式的方法名。

<a class="anchor" id="test-helpers"></a>

### 测试辅助方法

为了避免代码重复，可以自定义测试辅助方法。下面实现用于登录的辅助方法：

```ruby
# test/test_helper.rb

module SignInHelper
  def sign_in_as(user)
    post sign_in_url(email: user.email, password: user.password)
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
```

```ruby
require 'test_helper'

class ProfileControllerTest < ActionDispatch::IntegrationTest

  test "should show profile" do
    # 辅助方法在任何控制器测试用例中都可用
    sign_in_as users(:david)

    get profile_url
    assert_response :success
  end
end
```

<a class="anchor" id="testing-routes"></a>

## 测试路由

与 Rails 应用中其他各方面内容一样，路由也可以测试。路由测试存放在 `test/controllers/` 目录中，或者与控制器测试写在一起。

NOTE: 应用的路由复杂也不怕，Rails 提供了很多有用的测试辅助方法。


关于 Rails 中可用的路由断言，参见 [`ActionDispatch::Assertions::RoutingAssertions` 模块的 API 文档](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html)。

<a class="anchor" id="testing-views"></a>

## 测试视图

测试请求的响应中是否出现关键的 HTML 元素和相应的内容是测试应用视图的一种常见方式。与路由测试一样，视图测试放在 `test/controllers/` 目录中，或者直接写在控制器测试中。`assert_select` 方法用于查询响应中的 HTML 元素，其句法简单而强大。

`assert_select` 有两种形式。

`assert_select(selector, [equality], [message])` 测试 `selector` 选中的元素是否符合 `equality` 指定的条件。`selector` 可以是 CSS 选择符表达式（字符串），或者是有代入值的表达式。

`assert_select(element, selector, [equality], [message])` 测试 `selector` 选中的元素和 `element`（`Nokogiri::XML::Node` 或 `Nokogiri::XML::NodeSet` 实例）及其子代是否符合 `equality` 指定的条件。

例如，可以使用下面的断言检测 `title` 元素的内容：

```ruby
assert_select 'title', "Welcome to Rails Testing Guide"
```

`assert_select` 的代码块还可嵌套使用。

在下述示例中，内层的 `assert_select` 会在外层块选中的元素集合中查询 `li.menu_item`：

```ruby
assert_select 'ul.navigation' do
  assert_select 'li.menu_item'
end
```

除此之外，还可以遍历外层 `assert_select` 选中的元素集合，这样就可以在集合的每个元素上运行内层 `assert_select` 了。

假如响应中有两个有序列表，每个列表中都有 4 个列表项，那么下面这两个测试都会通过：

```ruby
assert_select "ol" do |elements|
  elements.each do |element|
    assert_select element, "li", 4
  end
end

assert_select "ol" do
  assert_select "li", 8
end
```

`assert_select` 断言很强大，高级用法请参阅[文档](https://github.com/rails/rails-dom-testing/blob/master/lib/rails/dom/testing/assertions/selector_assertions.rb)。

<a class="anchor" id="additional-view-based-assertions"></a>

### 其他视图相关的断言

还有一些断言经常在视图测试中使用：

| 断言 | 作用  |
|---|---|
| `assert_select_email` | 检查电子邮件的正文。  |
| `assert_select_encoded` | 检查编码后的 HTML。先解码各元素的内容，然后在代码块中处理解码后的各个元素。  |
| `css_select(selector)` 或 `css_select(element, selector)` | 返回由 `selector` 选中的所有元素组成的数组。在后一种用法中，首先会找到 `element`，然后在其中执行 `selector` 表达式查找元素，如果没有匹配的元素，两种用法都返回空数组。  |

下面是 `assert_select_email` 断言的用法举例：

```ruby
assert_select_email do
  assert_select 'small', 'Please click the "Unsubscribe" link if you want to opt-out.'
end
```

<a class="anchor" id="testing-helpers"></a>

## 测试辅助方法

辅助方法是简单的模块，其中定义的方法可在视图中使用。

针对辅助方法的测试，只需检测辅助方法的输出和预期值是否一致。相应的测试文件保存在 `test/helpers` 目录中。

假设我们定义了下述辅助方法：

```ruby
module UserHelper
  def link_to_user(user)
    link_to "#{user.first_name} #{user.last_name}", user
  end
end
```

我们可以像下面这样测试它的输出：

```ruby
class UserHelperTest < ActionView::TestCase
  test "should return the user's full name" do
    user = users(:david)

    assert_dom_equal %{<a href="/user/#{user.id}">David Heinemeier Hansson</a>}, link_to_user(user)
  end
end
```

而且，因为测试类继承自 `ActionView::TestCase`，所以在测试中可以使用 Rails 内置的辅助方法，例如 `link_to` 和 `pluralize`。

<a class="anchor" id="testing-your-mailers"></a>

## 测试邮件程序

测试邮件程序需要一些特殊的工具才能完成。

<a class="anchor" id="keeping-the-postman-in-check"></a>

### 确保邮件程序在管控内

和 Rails 应用的其他组件一样，邮件程序也应该测试，确保能正常工作。

测试邮件程序的目的是：

*   确保处理了电子邮件（创建及发送）
*   确保邮件内容正确（主题、发件人、正文等）
*   确保在正确的时间发送正确的邮件

<a class="anchor" id="from-all-sides"></a>

#### 要全面测试

针对邮件程序的测试分为两部分：单元测试和功能测试。在单元测试中，单独运行邮件程序，严格控制输入，然后和已知值（固件）对比。在功能测试中，不用这么细致的测试，只要确保控制器和模型正确地使用邮件程序，在正确的时间发送正确的邮件。

<a class="anchor" id="unit-testing"></a>

### 单元测试

为了测试邮件程序是否能正常使用，可以把邮件程序真正得到的结果和预先写好的值进行比较。

<a class="anchor" id="revenge-of-the-fixtures"></a>

#### 固件的另一个用途

在单元测试中，固件用于设定期望得到的值。因为这些固件是示例邮件，不是 Active Record 数据，所以要和其他固件分开，放在单独的子目录中。这个子目录位于 `test/fixtures` 目录中，其名称与邮件程序对应。例如，邮件程序 `UserMailer` 使用的固件保存在 `test/fixtures/user_mailer` 目录中。

生成邮件程序时，生成器会为其中每个动作生成相应的固件。如果没使用生成器，要手动创建这些文件。

<a class="anchor" id="the-basic-test-case"></a>

#### 基本的测试用例

下面的单元测试针对 `UserMailer` 的 `invite` 动作，这个动作的作用是向朋友发送邀请。这段代码改进了生成器为 `invite` 动作生成的测试。

```ruby
require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test "invite" do
    # 创建邮件，将其存储起来，供后面的断言使用
    email = UserMailer.create_invite('me@example.com',
                                     'friend@example.com', Time.now)

    # 发送邮件，测试有没有入队
    assert_emails 1 do
      email.deliver_now
    end

    # 测试发送的邮件中有没有预期的内容
    assert_equal ['me@example.com'], email.from
    assert_equal ['friend@example.com'], email.to
    assert_equal 'You have been invited by me@example.com', email.subject
    assert_equal read_fixture('invite').join, email.body.to_s
  end
end
```

在这个测试中，我们发送了一封邮件，并把返回对象赋值给 `email` 变量。首先，我们确保邮件已经发送了；随后，确保邮件中包含预期的内容。`read_fixture` 这个辅助方法的作用是从指定的文件中读取内容。

NOTE: 仅当邮件内容只有一种格式时（HTML 或纯文本）才可使用 `email.body.to_s`。如果邮件程序提供了两种格式，可以使用 `email.text_part.body.to_s` 和 `email.html_part.body.to_s` 分别测试。

`invite` 固件的内容如下：

```
Hi friend@example.com,

You have been invited.

Cheers!
```

现在我们稍微深入一点地介绍针对邮件程序的测试。在 `config/environments/test.rb` 文件中，有这么一行设置：`ActionMailer::Base.delivery_method = :test`。这行设置把发送邮件的方法设为 `:test`，所以邮件并不会真的发送出去（避免测试时骚扰用户），而是添加到一个数组中（`ActionMailer::Base.deliveries`）。

NOTE: `ActionMailer::Base.deliveries` 数组只会在 `ActionMailer::TestCase` 和 `ActionDispatch::IntegrationTest` 测试中自动重设，如果想在这些测试之外使用空数组，可以手动重设：`ActionMailer::Base.deliveries.clear`。


<a class="anchor" id="functional-testing"></a>

### 功能测试

邮件程序的功能测试不只是测试邮件正文和收件人等是否正确这么简单。在针对邮件程序的功能测试中，要调用发送邮件的方法，检查相应的邮件是否出现在发送列表中。你可以尽情放心地假定发送邮件的方法本身能顺利完成工作。你需要重点关注的是应用自身的业务逻辑，确保能在预期的时间发出邮件。例如，可以使用下面的代码测试邀请朋友的操作是否发出了正确的邮件：

```ruby
require 'test_helper'

class UserControllerTest < ActionDispatch::IntegrationTest
  test "invite friend" do
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      post invite_friend_url, params: { email: 'friend@example.com' }
    end
    invite_email = ActionMailer::Base.deliveries.last

    assert_equal "You have been invited by me@example.com", invite_email.subject
    assert_equal 'friend@example.com', invite_email.to[0]
    assert_match(/Hi friend@example.com/, invite_email.body.to_s)
  end
end
```

<a class="anchor" id="testing-jobs"></a>

## 测试作业

因为自定义的作业在应用的不同层排队，所以我们既要测试作业本身（入队后的行为），也要测试是否正确入队了。

<a class="anchor" id="a-basic-test-case"></a>

### 一个基本的测试用例

默认情况下，生成作业时也会生成相应的测试，存储在 `test/jobs` 目录中。下面是付款作业的测试示例：

```ruby
require 'test_helper'

class BillingJobTest < ActiveJob::TestCase
  test 'that account is charged' do
    BillingJob.perform_now(account, product)
    assert account.reload.charged_for?(product)
  end
end
```

这个测试相当简单，只是断言作业能做预期的事情。

默认情况下，`ActiveJob::TestCase` 把队列适配器设为 `:test`，因此作业是内联执行的。此外，在运行任何测试之前，它会清理之前执行的和入队的作业，因此我们可以放心假定在当前测试的作用域中没有已经执行的作业。

<a class="anchor" id="custom-assertions-and-testing-jobs-inside-other-components"></a>

### 自定义断言和测试其他组件中的作业

Active Job 自带了很多自定义的断言，可以简化测试。可用的断言列表参见 [`ActiveJob::TestHelper` 模块的 API 文档](http://api.rubyonrails.org/classes/ActiveJob/TestHelper.html)。

不管作业是在哪里调用的（例如在控制器中），最好都要测试作业能正确入队或执行。这时就体现了 Active Job 提供的自定义断言的用处。例如，在模型中：

```ruby
require 'test_helper'

class ProductTest < ActiveJob::TestCase
  test 'billing job scheduling' do
    assert_enqueued_with(job: BillingJob) do
      product.charge(account)
    end
  end
end
```

<a class="anchor" id="additional-testing-resources"></a>

## 其他测试资源

<a class="anchor" id="testing-time-dependent-code"></a>

### 测试与时间有关的代码

Rails 提供了一些内置的辅助方法，便于我们测试与时间有关的代码。

下述示例用到了 [`travel_to`](http://api.rubyonrails.org/classes/ActiveSupport/Testing/TimeHelpers.html#method-i-travel_to) 辅助方法：

```ruby
# 假设用户在注册一个月内可以获取礼品
user = User.create(name: 'Gaurish', activation_date: Date.new(2004, 10, 24))
assert_not user.applicable_for_gifting?
travel_to Date.new(2004, 11, 24) do
  assert_equal Date.new(2004, 10, 24), user.activation_date # 在 travel_to 块中， `Date.current` 是拟件
  assert user.applicable_for_gifting?
end
assert_equal Date.new(2004, 10, 24), user.activation_date # 改动只在 travel_to 块中可见
```

可用的时间辅助方法详情参见 [`ActiveSupport::Testing::TimeHelpers` 模块的 API 文档](http://api.rubyonrails.org/classes/ActiveSupport/Testing/TimeHelpers.html)。
