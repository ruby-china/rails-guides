Rails 插件入门
====================================

一个Rails插件既可是是一个功能扩展也可以是对核心框架库的修改。插件提供了如下功能：


* 为开发者分享新奇特性又保证不影响稳定版本功能提供了支持；

* 松散代码组织架构为修复，更新局部模块提供了支持；

* 为核心成员开发局部功能特性提供了支持；


读完本章节，您将学到：

* 如何构造一个简单的插件；

* 如何为插件编写和运行测试用例；


本指南将叙述如何通过测试驱动的方式开发插件：

* 扩展核心类库功能，比如`Hash`和`String`；

* 给`ActiveRecord::Base`添加`acts_as`插件功能；

* 提供创建自定义插件必需的信息；



假定你是一名狂热的鸟类观察爱好者，你最喜欢的鸟是Yaffle，你希望创建一个插件和开发者们分享有关Yaffle的信息。

--------------------------------------------------------------------------------

准备工作
-----

目前，Rails插件是被当作gem来使用的(gem化的插件)。不同Rails应用可以通过RubyGems和Bundler命令来使用他们。

### 生成一个gem化的插件


Rails使用`rails plugin new`命令为开发者创建各种Rails扩展，以确保它能使用一个简单Rails应用进行测试。创建插件的命令如下：

```bash
$ bin/rails plugin new yaffle
```

如下命令可以获取创建插件命令的使用方式：

```bash
$ bin/rails plugin --help
```

让新生成的插件支持测试
-----------------------------------

 打开包插件所在的文件目录，然后在命令行模式下运行`bundle install`命令，使用`rake`命令生成测试环境。

你将看到如下代码：

```bash
  2 tests, 2 assertions, 0 failures, 0 errors, 0 skips
```

上述内容告诉你一切就绪，可以开始为插件添加新特性了。

扩展核心类库
----------------------

本章节将介绍如何为`String`添加一个方法，并让它在你的Rails应用中生效。

下面我们将为`String`添加一个名为`to_squawk`的方法。开始前，我们可以先创建一些简单的测试函数：

```ruby
# yaffle/test/core_ext_test.rb

require 'test_helper'

class CoreExtTest < ActiveSupport::TestCase
  def test_to_squawk_prepends_the_word_squawk
    assert_equal "squawk! Hello World", "Hello World".to_squawk
  end
end
```

运行`rake`命令运行测试，测试将返回错误信息，因为我们还没有完成`to_squawk`方法的功能实现：

```bash
    1) Error:
  test_to_squawk_prepends_the_word_squawk(CoreExtTest):
  NoMethodError: undefined method `to_squawk' for [Hello World](String)
      test/core_ext_test.rb:5:in `test_to_squawk_prepends_the_word_squawk'
```

好吧，现在开始进入正题：

在`lib/yaffle.rb`文件中, 添加 `require 'yaffle/core_ext'`：

```ruby
# yaffle/lib/yaffle.rb

require 'yaffle/core_ext'

module Yaffle
end
```

最后，新建一个`core_ext.rb`文件，并添加`to_squawk`方法：

```ruby
# yaffle/lib/yaffle/core_ext.rb

String.class_eval do
  def to_squawk
    "squawk! #{self}".strip
  end
end
```

为了测试你的方法是否符合预期，可以在插件目录下运行`rake`命令，来测试一下。

```bash
  3 tests, 3 assertions, 0 failures, 0 errors, 0 skips
```

看到上述内容后，用命令行导航到test/dummy目录，然后使用Rails控制台来做个测试：

```bash
$ bin/rails console
>> "Hello World".to_squawk
=> "squawk! Hello World"
```

为Active Record添加"acts_as"方法
----------------------------------------

一般来说，在插件中为某模块添加方法的命名方式是`acts_as_something`，本例中我们将为Active Record添加一个名为`acts_as_yaffle`的方法实现`squawk` 功能。

首先，新建一些文件：

```ruby
# yaffle/test/acts_as_yaffle_test.rb

require 'test_helper'

class ActsAsYaffleTest < ActiveSupport::TestCase
end
```

```ruby
# yaffle/lib/yaffle.rb

require 'yaffle/core_ext'
require 'yaffle/acts_as_yaffle'

module Yaffle
end
```

```ruby
# yaffle/lib/yaffle/acts_as_yaffle.rb

module Yaffle
  module ActsAsYaffle
    # your code will go here
  end
end
```

### 添加一个类方法

假如插件的模块中有一个名为 `last_squawk` 的方法，与此同时，插件的使用者在其他模块也定义了一个名为 `last_squawk` 的方法，那么插件允许你添加一个类方法 `yaffle_text_field` 来改变插件内的 `last_squawk` 方法的名称。

开始之前，可以先写一些测试用例来保证函数拥有符合预期的行为。

```ruby
# yaffle/test/acts_as_yaffle_test.rb

require 'test_helper'

class ActsAsYaffleTest < ActiveSupport::TestCase

  def test_a_hickwalls_yaffle_text_field_should_be_last_squawk
    assert_equal "last_squawk", Hickwall.yaffle_text_field
  end

  def test_a_wickwalls_yaffle_text_field_should_be_last_tweet
    assert_equal "last_tweet", Wickwall.yaffle_text_field
  end

end
```

运行`rake`命令，你将看到如下结果：

```
    1) Error:
  test_a_hickwalls_yaffle_text_field_should_be_last_squawk(ActsAsYaffleTest):
  NameError: uninitialized constant ActsAsYaffleTest::Hickwall
      test/acts_as_yaffle_test.rb:6:in `test_a_hickwalls_yaffle_text_field_should_be_last_squawk'

    2) Error:
  test_a_wickwalls_yaffle_text_field_should_be_last_tweet(ActsAsYaffleTest):
  NameError: uninitialized constant ActsAsYaffleTest::Wickwall
      test/acts_as_yaffle_test.rb:10:in `test_a_wickwalls_yaffle_text_field_should_be_last_tweet'

  5 tests, 3 assertions, 0 failures, 2 errors, 0 skips
```

上述内容告诉我们，我们没有提供必要的模块（Hickwall and Wickwall）进行测试。我们可以在 test/dummy 目录下使用命令生成必要的模块：

```bash
$ cd test/dummy
$ bin/rails generate model Hickwall last_squawk:string
$ bin/rails generate model Wickwall last_squawk:string last_tweet:string
```

接下来为简单应用创建测试数据库并做数据迁移：

```bash
$ cd test/dummy
$ bin/rake db:migrate
```

至此，修改Hickwall和Wickwall模块，把他们和yaffles关联起来：

```ruby
# test/dummy/app/models/hickwall.rb

class Hickwall < ActiveRecord::Base
  acts_as_yaffle
end

# test/dummy/app/models/wickwall.rb

class Wickwall < ActiveRecord::Base
  acts_as_yaffle yaffle_text_field: :last_tweet
end

```

同时定义`acts_as_yaffle`方法：

```ruby
# yaffle/lib/yaffle/acts_as_yaffle.rb
module Yaffle
  module ActsAsYaffle
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_yaffle(options = {})
        # your code will go here
      end
    end
  end
end

ActiveRecord::Base.send :include, Yaffle::ActsAsYaffle
```

在插件的根目录下运行`rake`命令：

```
    1) Error:
  test_a_hickwalls_yaffle_text_field_should_be_last_squawk(ActsAsYaffleTest):
  NoMethodError: undefined method `yaffle_text_field' for #<Class:0x000001016661b8>
      /Users/xxx/.rvm/gems/ruby-1.9.2-p136@xxx/gems/activerecord-3.0.3/lib/active_record/base.rb:1008:in `method_missing'
      test/acts_as_yaffle_test.rb:5:in `test_a_hickwalls_yaffle_text_field_should_be_last_squawk'

    2) Error:
  test_a_wickwalls_yaffle_text_field_should_be_last_tweet(ActsAsYaffleTest):
  NoMethodError: undefined method `yaffle_text_field' for #<Class:0x00000101653748>
      Users/xxx/.rvm/gems/ruby-1.9.2-p136@xxx/gems/activerecord-3.0.3/lib/active_record/base.rb:1008:in `method_missing'
      test/acts_as_yaffle_test.rb:9:in `test_a_wickwalls_yaffle_text_field_should_be_last_tweet'

  5 tests, 3 assertions, 0 failures, 2 errors, 0 skips

```

现在离目标已经很近了，我们来完成`acts_as_yaffle`方法，以便通过测试。

```ruby
# yaffle/lib/yaffle/acts_as_yaffle.rb

module Yaffle
  module ActsAsYaffle
   extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_yaffle(options = {})
        cattr_accessor :yaffle_text_field
        self.yaffle_text_field = (options[:yaffle_text_field] || :last_squawk).to_s
      end
    end
  end
end

ActiveRecord::Base.send :include, Yaffle::ActsAsYaffle
```

运行`rake`命令后，你将看到所有测试都通过了:

```bash
  5 tests, 5 assertions, 0 failures, 0 errors, 0 skips
```

### 添加一个实例方法

本插件将为所有Active Record对象添加一个名为`squawk`的方法，Active Record 对象通过调用`acts_as_yaffle`方法来间接调用插件的`squawk`方法。
`squawk`方法将被作为一个可赋值的字段与数据库关联起来。

开始之前，可以先写一些测试用例来保证函数拥有符合预期的行为。：

```ruby
# yaffle/test/acts_as_yaffle_test.rb
require 'test_helper'

class ActsAsYaffleTest < ActiveSupport::TestCase

  def test_a_hickwalls_yaffle_text_field_should_be_last_squawk
    assert_equal "last_squawk", Hickwall.yaffle_text_field
  end

  def test_a_wickwalls_yaffle_text_field_should_be_last_tweet
    assert_equal "last_tweet", Wickwall.yaffle_text_field
  end

  def test_hickwalls_squawk_should_populate_last_squawk
    hickwall = Hickwall.new
    hickwall.squawk("Hello World")
    assert_equal "squawk! Hello World", hickwall.last_squawk
  end

  def test_wickwalls_squawk_should_populate_last_tweet
    wickwall = Wickwall.new
    wickwall.squawk("Hello World")
    assert_equal "squawk! Hello World", wickwall.last_tweet
  end
end
```

运行测试后，确保测试结果中包含2个"NoMethodError: undefined method `squawk'"的测试错误，那么我可以修改'acts_as_yaffle.rb'中的代码：

```ruby
# yaffle/lib/yaffle/acts_as_yaffle.rb

module Yaffle
  module ActsAsYaffle
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_yaffle(options = {})
        cattr_accessor :yaffle_text_field
        self.yaffle_text_field = (options[:yaffle_text_field] || :last_squawk).to_s

        include Yaffle::ActsAsYaffle::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      def squawk(string)
        write_attribute(self.class.yaffle_text_field, string.to_squawk)
      end
    end
  end
end

ActiveRecord::Base.send :include, Yaffle::ActsAsYaffle
```

运行`rake`命令后，你将看到如下结果：
```
  7 tests, 7 assertions, 0 failures, 0 errors, 0 skips
```

提示： 使用`write_attribute`方法写入字段只是举例说明插件如何与模型交互，并非推荐的使用方法，你也可以用如下方法实现：
```ruby
send("#{self.class.yaffle_text_field}=", string.to_squawk)
```

生成器
----------

插件可以方便的引用和创建生成器。关于创建生成器的更多信息，可以参考[Generators Guide](generators.html)

发布Gem
-------------------

Gem插件可以通过Git代码托管库方便的在开发者之间分享。如果你希望分享Yaffle插件，那么可以将Yaffle放在Git代码托管库上。如果你希望在你的应用中使用Yaffle插件，那么可以在Rails应用的Gem文件中添加如下代码：


```ruby
gem 'yaffle', git: 'git://github.com/yaffle_watcher/yaffle.git'
```

运行`bundle install`命令后，你的Yaffle插件就可以在你的Rails应用中使用了。


当gem作为一个正式版本分享时，那么它就可以被发布到[RubyGems](http://www.rubygems.org)上了。想要了解更多关于发布gem到RubyGems信息，可以参考[Creating and Publishing Your First Ruby Gem](http://blog.thepete.net/2010/11/creating-and-publishing-your-first-ruby.html)。


RDoc 文档
------------------

插件功能稳定并准备发布时，为用户提供一个使用说明文档是必要的。很幸运，为你的插件写一个文档很容易。

首先更新说明文件以及如何使用你的插件等详细信息。文档主要包括以下几点：

* 你的名字
* 安装指南
* 如何安装gem到应用中(一些使用例子)
* 警告,使用插件时需要注意的地方，这将为用户提供方便。

当你的README文件写好以后，为用户提供所有与插件方法相关的rdoc注释。通常我们使用'#:nodoc:'来注释不包含在公共API中的代码。

当你的注释编写好以后，可以到你的插件目录下运行如下命令：

```bash
$ bin/rake rdoc
```

### 参考文献

* [Developing a RubyGem using Bundler](https://github.com/radar/guides/blob/master/gem-development.md)
* [Using .gemspecs as Intended](http://yehudakatz.com/2010/04/02/using-gemspecs-as-intended/)
* [Gemspec Reference](http://docs.rubygems.org/read/chapter/20)
* [GemPlugins: A Brief Introduction to the Future of Rails Plugins](http://www.intridea.com/blog/2008/6/11/gemplugins-a-brief-introduction-to-the-future-of-rails-plugins)
