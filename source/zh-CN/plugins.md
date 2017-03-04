Rails 插件开发简介
==================

Rails 插件是对核心框架的扩展或修改。插件有下述作用：

- 供开发者分享突发奇想，但不破坏稳定的代码基

- 碎片式架构，代码自成一体，能按照自己的日程表修正或更新

- 核心开发者使用的外延工具，不必把每个新特性都集成到核心框架中

读完本文后，您将学到：

- 如何从零开始创建一个插件

- 如何编写插件的代码和测试

本文使用测试驱动开发方式编写一个插件，它具有下述功能：

- 扩展 Ruby 核心类，如 Hash 和 String

- 通过传统的 `acts_as` 插件形式为 `ApplicationRecord` 添加方法

- 说明生成器放在插件的什么位置

本文暂且假设你是热衷观察鸟类的人。你钟爱的鸟是绿啄木鸟（Yaffle），因此你想创建一个插件，供其他开发者分享心得。

NOTE: 本文原文尚未完工！

准备
----

目前，Rails 插件构建成 gem 的形式，叫做 gem 式插件（gemified plugin）。如果愿意，可以通过 RubyGems 和 Bundler 在多个 Rails 应用中共享。

### 生成 gem 式插件

Rails 自带一个 `rails plugin new` 命令，用于创建任何 Rails 扩展的骨架。这个命令还会生成一个虚设的 Rails 应用，用于运行集成测试。请使用下述命令创建这个插件：

```sh
$ rails plugin new yaffle
```

如果想查看用法和选项，执行下述命令：

```sh
$ rails plugin new --help
```

测试新生成的插件
----------------

进入插件所在的目录，运行 `bundle install` 命令，然后使用 `bin/test` 命令运行生成的一个测试。

你会看到下述输出：

    1 runs, 1 assertions, 0 failures, 0 errors, 0 skips

这表明一切都正确生成了，接下来可以添加功能了。

扩展核心类
----------

本节说明如何为 String 类添加一个方法，让它在整个 Rails 应用中都可以使用。

这里，我们为 String 添加的方法名为 `to_squawk`。首先，创建一个测试文件，写入几个断言：

```ruby
# yaffle/test/core_ext_test.rb

require 'test_helper'

class CoreExtTest < ActiveSupport::TestCase
  def test_to_squawk_prepends_the_word_squawk
    assert_equal "squawk! Hello World", "Hello World".to_squawk
  end
end
```

然后使用 `bin/test` 运行测试。这个测试应该失败，因为我们还没实现 `to_squawk` 方法。

    E

    Error:
    CoreExtTest#test_to_squawk_prepends_the_word_squawk:
    NoMethodError: undefined method `to_squawk' for "Hello World":String


    bin/test /path/to/yaffle/test/core_ext_test.rb:4

    .

    Finished in 0.003358s, 595.6483 runs/s, 297.8242 assertions/s.

    2 runs, 1 assertions, 0 failures, 1 errors, 0 skips

很好，下面可以开始开发了。

在 `lib/yaffle.rb` 文件中添加 `require 'yaffle/core_ext'`：

```ruby
# yaffle/lib/yaffle.rb

require 'yaffle/core_ext'

module Yaffle
end
```

最后，创建 `core_ext.rb` 文件，添加 `to_squawk` 方法：

```ruby
# yaffle/lib/yaffle/core_ext.rb

String.class_eval do
  def to_squawk
    "squawk! #{self}".strip
  end
end
```

为了测试方法的行为是否得当，在插件目录中使用 `bin/test` 运行单元测试：

    2 runs, 2 assertions, 0 failures, 0 errors, 0 skips

为了实测一下，进入 `test/dummy` 目录，打开控制台：

```sh
$ bin/rails console
>> "Hello World".to_squawk
=> "squawk! Hello World"
```

为 Active Record 添加“acts\_as”方法
-----------------------------------

插件经常为模型添加名为 `acts_as_something` 的方法。这里，我们要编写一个名为 `acts_as_yaffle` 的方法，为 Active Record 添加 `squawk` 方法。

首先，创建几个文件：

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
    # 在这里编写你的代码
  end
end
```

### 添加一个类方法

这个插件将为模型添加一个名为 `last_squawk` 的方法。然而，插件的用户可能已经在模型中定义了同名方法，做其他用途使用。这个插件将允许修改插件的名称，为此我们要添加一个名为 `yaffle_text_field` 的类方法。

首先，为预期行为编写一个失败测试：

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

执行 `bin/test` 命令，应该看到下述输出：

    # Running:

    ..E

    Error:
    ActsAsYaffleTest#test_a_wickwalls_yaffle_text_field_should_be_last_tweet:
    NameError: uninitialized constant ActsAsYaffleTest::Wickwall


    bin/test /path/to/yaffle/test/acts_as_yaffle_test.rb:8

    E

    Error:
    ActsAsYaffleTest#test_a_hickwalls_yaffle_text_field_should_be_last_squawk:
    NameError: uninitialized constant ActsAsYaffleTest::Hickwall


    bin/test /path/to/yaffle/test/acts_as_yaffle_test.rb:4



    Finished in 0.004812s, 831.2949 runs/s, 415.6475 assertions/s.

    4 runs, 2 assertions, 0 failures, 2 errors, 0 skips

输出表明，我们想测试的模型（Hickwall 和 Wickwall）不存在。为此，可以在 `test/dummy` 目录中运行下述命令生成：

```sh
$ cd test/dummy
$ bin/rails generate model Hickwall last_squawk:string
$ bin/rails generate model Wickwall last_squawk:string last_tweet:string
```

然后，进入虚设的应用，迁移数据库，创建所需的数据库表。首先，执行：

```sh
$ cd test/dummy
$ bin/rails db:migrate
```

同时，修改 Hickwall 和 Wickwall 模型，让它们知道自己的行为像绿啄木鸟。

```ruby
# test/dummy/app/models/hickwall.rb

class Hickwall < ApplicationRecord
  acts_as_yaffle
end

# test/dummy/app/models/wickwall.rb

class Wickwall < ApplicationRecord
  acts_as_yaffle yaffle_text_field: :last_tweet
end
```

再添加定义 `acts_as_yaffle` 方法的代码：

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

# test/dummy/app/models/application_record.rb

class ApplicationRecord < ActiveRecord::Base
  include Yaffle::ActsAsYaffle

  self.abstract_class = true
end
```

然后，回到插件的根目录（`cd ../..`），使用 `bin/test` 再次运行测试：

    # Running:

    .E

    Error:
    ActsAsYaffleTest#test_a_hickwalls_yaffle_text_field_should_be_last_squawk:
    NoMethodError: undefined method `yaffle_text_field' for #<Class:0x0055974ebbe9d8>


    bin/test /path/to/yaffle/test/acts_as_yaffle_test.rb:4

    E

    Error:
    ActsAsYaffleTest#test_a_wickwalls_yaffle_text_field_should_be_last_tweet:
    NoMethodError: undefined method `yaffle_text_field' for #<Class:0x0055974eb8cfc8>


    bin/test /path/to/yaffle/test/acts_as_yaffle_test.rb:8

    .

    Finished in 0.008263s, 484.0999 runs/s, 242.0500 assertions/s.

    4 runs, 2 assertions, 0 failures, 2 errors, 0 skips

快完工了……接下来实现 `acts_as_yaffle` 方法，让测试通过：

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

# test/dummy/app/models/application_record.rb

class ApplicationRecord < ActiveRecord::Base
  include Yaffle::ActsAsYaffle

  self.abstract_class = true
end
```

再次运行 `bin/test`，测试应该都能通过：

    4 runs, 4 assertions, 0 failures, 0 errors, 0 skips

### 添加一个实例方法

这个插件能为任何模型添加调用 `acts_as_yaffle` 方法的 `squawk` 方法。`squawk` 方法的作用很简单，设定数据库中某个字段的值。

首先，为预期行为编写一个失败测试：

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

运行测试，确保最后两个测试的失败消息中有“NoMethodError: undefined method \`squawk'”。然后，按照下述方式修改 `acts_as_yaffle.rb` 文件：

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

# test/dummy/app/models/application_record.rb

class ApplicationRecord < ActiveRecord::Base
  include Yaffle::ActsAsYaffle

  self.abstract_class = true
end
```

最后再运行一次 `bin/test`，应该看到：

    6 runs, 6 assertions, 0 failures, 0 errors, 0 skips

NOTE: 这里使用 `write_attribute` 写入模型中的字段，这只是插件与模型交互的方式之一，并不总是应该使用它。例如，也可以使用：
>
> ``` ruby
> send("#{self.class.yaffle_text_field}=", string.to_squawk)
> ```

生成器
------

gem 中可以包含生成器，只需将其放在插件的 `lib/generators` 目录中。创建生成器的更多信息参见[创建及定制 Rails 生成器和模板](generators.html)。

发布 gem
--------

正在开发的 gem 式插件可以通过 Git 仓库轻易分享。如果想与他人分享这个 Yaffle gem，只需把代码纳入一个 Git 仓库（如 GitHub），然后在想使用它的应用中，在 Gemfile 中添加一行代码：

```ruby
gem 'yaffle', git: 'git://github.com/yaffle_watcher/yaffle.git'
```

运行 `bundle install` 之后，应用就可以使用插件提供的功能了。

gem 式插件准备好正式发布之后，可以发布到 [RubyGems](http://www.rubygems.org/) 网站中。关于这个话题的详细信息，参阅“[Creating and Publishing Your First Ruby Gem](http://blog.thepete.net/2010/11/creating-and-publishing-your-first-ruby.html)”一文。

RDoc 文档
---------

插件稳定后可以部署了，为了他人使用方便，一定要编写文档！幸好，为插件编写文档并不难。

首先，更新 README 文件，说明插件的用法。要包含以下几个要点：

- 你的名字

- 插件用法

- 如何把插件的功能添加到应用中（举几个示例，说明常见用例）

- 提醒、缺陷或小贴士，这样能节省用户的时间

README 文件写好之后，为开发者将使用的方法添加 rdoc 注释。通常，还要为不在公开 API 中的代码添加 `#:nodoc:` 注释。

添加好注释之后，进入插件所在的目录，执行：

```sh
$ bundle exec rake rdoc
```

参考资料
--------

- [Developing a RubyGem using Bundler](https://github.com/radar/guides/blob/master/gem-development.md)

- [Using .gemspecs as Intended](http://yehudakatz.com/2010/04/02/using-gemspecs-as-intended/)

- [Gemspec Reference](http://guides.rubygems.org/specification-reference/)
