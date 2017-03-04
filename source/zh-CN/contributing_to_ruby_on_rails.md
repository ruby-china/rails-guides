为 Ruby on Rails 做贡献
=======================

本文介绍几种参与 Ruby on Rails 开发的方式。

读完本文后，您将学到：

- 如何使用 GitHub 报告问题；

- 如果克隆 master，运行测试组件；

- 如何帮助解决现有问题；

- 如何为 Ruby on Rails 文档做贡献；

- 如何为 Ruby on Rails 代码做贡献。

Ruby on Rails 不是某一个人的框架。这些年，有成百上千个人为 Ruby on Rails 做贡献，小到修正一个字符，大到调整重要的架构或文档——目的都是把 Ruby on Rails 变得更好，适合所有人使用。即便你现在不想编写代码或文档，也能通过其他方式做贡献，例如报告问题和测试补丁。

[Rails 的自述文件](https://github.com/rails/rails/blob/master/README.md)说道，参与 Rails 及其子项目代码基开发的人，参与问题追踪系统、聊天室和邮件列表的人，都要遵守 Rails 的[行为准则](http://rubyonrails.org/conduct/)。

报告错误
--------

Ruby on Rails 使用 [GitHub 的问题追踪系统](https://github.com/rails/rails/issues)追踪问题（主要是解决缺陷和贡献新代码）。如果你发现 Ruby on Rails 有缺陷，首先应该发布到这个系统中。若想提交问题、评论问题或创建拉取请求， 你要注册一个 GitHub 账户（免费）。

NOTE: Ruby on Rails 最新版的缺陷最受关注。此外，Rails 核心团队始终欢迎能对最新开发版做测试的人反馈。本文后面会说明如何测试最新开发版。

### 创建一个缺陷报告

如果你在 Ruby on Rails 中发现一个没有安全风险的问题，在 [GitHub 的问题追踪系统](https://github.com/rails/rails/issues)中搜索一下，说不定已经有人报告了。如果之前没有人报告，接下来你要[创建一个](https://github.com/rails/rails/issues/new)。（报告安全问题的方法参见下一节。）

问题报告应该包含标题，而且要使用简洁的语言描述问题。你应该尽量多提供相关的信息，而且至少要有一个代码示例，演示所述的问题。如果能提供一个单元测试，说明预期行为更好。你的目标是让你自己以及其他人能重现缺陷，找出修正方法。

然后，耐心等待。除非你报告的是紧急问题，会导致世界末日，否则你要等待可能有其他人也遇到同样的问题，与你一起去解决。不要期望你报告的问题能立即得到关注，有人立刻着手解决。像这样报告问题基本上是让自己迈出修正问题的第一步，并且让其他遇到同样问题的人复议。

### 创建可执行的测试用例

提供重现问题的方式有助于别人帮你确认、研究并最终解决问题。为此，你可以提供可执行的测试用例。为了简化这一过程，我们准备了几个缺陷报告模板供你参考：

- 报告 Active Record（模型、数据库）问题的模板：[gem](https://github.com/rails/rails/blob/master/guides/bug_report_templates/active_record_gem.rb) / [master](https://github.com/rails/rails/blob/master/guides/bug_report_templates/active_record_master.rb)

- 报告 Action Pack（控制器、路由）问题的模板：[gem](https://github.com/rails/rails/blob/master/guides/bug_report_templates/action_controller_gem.rb) / [master](https://github.com/rails/rails/blob/master/guides/bug_report_templates/action_controller_master.rb)

- 其他问题的通用模板：[gem](https://github.com/rails/rails/blob/master/guides/bug_report_templates/generic_gem.rb) / [master](https://github.com/rails/rails/blob/master/guides/bug_report_templates/generic_master.rb)

这些模板包含样板代码，供你着手编写测试用例，分别针对 Rails 的发布版（`*_gem.rb`）和最新开发版（`*_master.rb`）。

你只需把相应模板中的内容复制到一个 `.rb` 文件中，然后做必要的改动，说明问题。如果想运行测试，只需在终端里执行 `ruby the_file.rb`。如果一切顺利，测试用例应该失败。

随后，可以通过一个 [gist](https://gist.github.com/) 分享你的可执行测试用例，或者直接粘贴到问题描述中。

### 特殊对待安全问题

WARNING: 请不要在公开的 GitHub 问题报告中报告安全漏洞。安全问题的报告步骤在 [Rails 安全方针页面](http://rubyonrails.org/security)中有详细说明。

### 功能请求怎么办？

请勿在 GitHub 问题追踪系统中请求新功能。如果你想把新功能添加到 Ruby on Rails 中，你要自己编写代码，或者说服他人与你一起编写代码。本文后面会详述如何为 Ruby on Rails 提请补丁。如果在 GitHub 问题追踪系统发布希望含有的功能，但是没有提供代码，在审核阶段会将其标记为“无效”。

有时，很难区分“缺陷”和“功能”。一般来说，功能是为了添加新行为，而缺陷是导致不正确行为的缘由。有时，核心团队会做判断。尽管如此，区别通常影响的是补丁放在哪个发布版中。我们十分欢迎你提交功能！只不过，新功能不会添加到维护分支中。

如果你想在着手打补丁之前征询反馈，请向 [rails-core 邮件列表](https://groups.google.com/forum/?fromgroups#!forum/rubyonrails-core)发送电子邮件。你可能得不到回应，这表明大家是中立的。你可能会发现有人对你提议的功能感兴趣；可能会有人说你的提议不可行。但是新想法就应该在那里讨论。GitHub 问题追踪系统不是集中讨论特性请求的正确场所。

帮助解决现有问题
----------------

除了报告问题之外，你还可以帮助核心团队解决现有问题。如果查看 GitHub 中的[问题列表](https://github.com/rails/rails/issues)，你会发现很多问题都得到了关注。为此你能做些什么呢？其实，你能做的有很多。

### 确认缺陷报告

对新人来说，帮助确认缺陷报告就行了。你能在自己的电脑中重现报告的问题吗？如果能，可以在问题的评论中说你发现了同样的问题。

如果问题描述不清，你能帮忙说得更具体些吗？或许你可以提供额外的信息，帮助重现缺陷，或者去掉说明问题所不需要的步骤。

如果发现缺陷报告中没有测试，你可以贡献一个失败测试。这是学习源码的好机会：查看现有的测试文件能让你学到如何编写更好的测试。新测试最好以补丁的形式提供，详情参阅 [为 Rails 代码做贡献](#为 Rails 代码做贡献)。

不管你自己写不写代码，只要你能把缺陷报告变得更简洁、更便于重现，就能为尝试修正缺陷的人提供帮助。

### 测试补丁

你还可以帮忙检查通过 GitHub 为 Ruby on Rails 提交的拉取请求。在使用别人的改动之前，你要创建一个专门的分支：

```sh
$ git checkout -b testing_branch
```

然后可以使用他们的远程分支更新代码基。假如 GitHub 用户 JohnSmith 派生了 Rails 源码，地址是 https://github.com/JohnSmith/rails，然后推送到主题分支“orange”：

```sh
$ git remote add JohnSmith https://github.com/JohnSmith/rails.git
$ git pull JohnSmith orange
```

然后，使用主题分支中的代码做测试。下面是一些考虑的事情：

- 改动可用吗？

- 你对测试满意吗？你能理解测试吗？缺少测试吗？

- 有适度的文档覆盖度吗？其他地方的文档需要更新吗？

- 你喜欢他的实现方式吗？你能以更好或更快的方式实现部分改动吗？

拉取请求中的改动让你满意之后，在 GitHub 问题追踪系统中发表评论，表明你赞成。你的评论应该说你喜欢这个改动，以及你的观点。比如说：

> 我喜欢你对 generate\_finder\_sql 这部分代码的调整，现在更好了。测试也没问题。

如果你的评论只是说“+1”，其他评审很难严肃对待。你要表明你花时间审查拉取请求了。

为 Rails 文档做贡献
-------------------

Ruby on Rails 主要有两份文档：这份指南，帮你学习 Ruby on Rails；API，作为参考资料。

你可以帮助改进这份 Rails 指南，把它变得更简单、更为一致，也更易于理解。你可以添加缺少的信息、更正错误、修正错别字或者针对最新的 Rails 开发版做更新。

如果经常做贡献，可以向 [Rails](http://github.com/rails/rails) 发送拉取请求，或者向 [Rails 核心团队](http://rubyonrails.org/core)索要 docrails 的提交权限。请勿直接向 docrails 发送拉取请求，如果想征询别人对你的改动有何意见，在 Rails 的问题追踪系统中询问。

docrails 定期合并到 master 分支，因此 Ruby on Rails 的文档能得到及时更新。

如果你对文档的改动有疑问，可以在 Rails 的问题追踪系统发工单。

如果你想为文档做贡献，请阅读[API 文档指导方针](api_documentation_guidelines.html)和[Ruby on Rails 指南指导方针](ruby_on_rails_guides_guidelines.html)。

前面说过，常规的代码补丁应该有适当的文档覆盖度。docrails 项目只是为了在单独的地方改进文档。

NOTE: 为了减轻 CI 服务器的压力，关于文档的提交消息中应该包含 `[ci skip]`，跳过构建步骤。只修改文档的提交一定要这么做。

WARNING: docrails 有个十分严格的方针：不能触碰任何代码，不管改动有多小都不行。通过 docrails 只能编辑 RDoc 和指南。此外，在 docrails 中也不能编辑 CHANGELOG。

翻译 Rails 指南
---------------

我们欢迎人们自发把 Rails 指南翻译成其他语言。如果你想把 Rails 指南翻译成你的母语，请遵照下述步骤：

- 派生项目（rails/rails）

- 为你的语言添加一个文件夹，例如针对意大利语的 guides/source/it-IT

- 把 guides/source 中的内容复制到你创建的文件夹中，然后翻译

- 不要翻译 HTML 文件，因为那是自动生成的

如果想生成这份指南的 HTML 格式，进入 guides 目录，然后执行（以 it-IT 为例）：

```sh
$ bundle install
$ bundle exec rake guides:generate:html GUIDES_LANGUAGE=it-IT
```

上述命令在 output 目录中生成这份指南。

NOTE: 上述说明针对 Rails 4 及以上版本。Redcarpet gem 无法在 JRuby 中使用。

已知的翻译成果：

- 意大利语：<https://github.com/rixlabs/docrails>

- 西班牙语：<http://wiki.github.com/gramos/docrails>

- 波兰语：<http://github.com/apohllo/docrails/tree/master>

- 法语：<http://github.com/railsfrance/docrails>

- 捷克语：<https://github.com/rubyonrails-cz/docrails/tree/czech>

- 土耳其语：<https://github.com/ujk/docrails/tree/master>

- 韩语：<https://github.com/rorlakr/rails-guides>

- 简体中文：<https://github.com/AndorChen/rails-guides>

- 繁体中文：<https://github.com/docrails-tw/guides>

- 俄语：<https://github.com/morsbox/rusrails>

- 日语：<https://github.com/yasslab/railsguides.jp>

为 Rails 代码做贡献
-------------------

### 搭建开发环境

过了提交缺陷这个初级阶段之后，若想帮助解决现有问题，或者为 Ruby on Rails 贡献自己的代码，必须要能运行测试组件。这一节教你在自己的电脑中搭建测试的环境。

#### 简单方式

搭建开发环境最简单、也是推荐的方式是使用 [Rails 开发虚拟机](https://github.com/rails/rails-dev-box)。

#### 笨拙方式

如果你不便使用 Rails 开发虚拟机，请阅读[安装开发依赖](development_dependencies_install.html)。

### 克隆 Rails 仓库

若想贡献代码，需要克隆 Rails 仓库：

```sh
$ git clone https://github.com/rails/rails.git
```

然后创建一个专门的分支：

```sh
$ cd rails
$ git checkout -b my_new_branch
```

分支的名称无关紧要，因为这个分支只存在于你的本地电脑和你在 GitHub 上的个人仓库中，不会出现在 Rails 的 Git 仓库里。

### bundle install

安装所需的 gem：

```sh
$ bundle install
```

### 使用本地分支运行应用

如果想使用虚拟的 Rails 应用测试改动，执行 `rails new` 命令时指定 `--dev` 旗标，使用本地分支生成一个应用：

```sh
$ cd rails
$ bundle exec rails new ~/my-test-app --dev
```

上述命令使用本地分支在 `~/my-test-app` 目录中生成一个应用，重启服务器后便能看到改动的效果。

### 编写你的代码

现在可以着手添加和编辑代码了。你处在自己的分支中，可以编写任何你想编写的代码（使用 `git branch -a` 确定你处于正确的分支中）。不过，如果你打算把你的改动提交到 Rails 中，要注意几点：

- 代码要写得正确。

- 使用 Rails 习惯用法和辅助方法。

- 包含测试，在没有你的代码时失败，添加之后则通过。

- 更新（相应的）文档、别处的示例和指南。只要受你的代码影响，都更新。

TIP: 装饰性的改动，没有为 Rails 的稳定性、功能或可测试性做出实质改进的改动一般不会接受（关于这一决定的讨论参见[这里](https://github.com/rails/rails/pull/13771#issuecomment-32746700)）。

#### 遵守编程约定

Rails 遵守下述简单的编程风格约定：

- （缩进）使用两个空格，不用制表符。

- 行尾没有空白。空行不能有任何空白。

- 私有和受保护的方法多一层缩进。

- 使用 Ruby 1.9 及以上版本采用的散列句法。使用 `{ a: :b }`，而非 `{ :a => :b }`。

- 较之 `and`/`or`，尽量使用 `&&`/`||`。

- 编写类方法时，较之 `self.method`，尽量使用 `class << self`。

- 使用 `my_method(my_arg)`，而非 `my_method( my_arg )` 或 `my_method my_arg`。

- 使用 `a = b`，而非 `a=b`。

- 使用 `assert_not` 方法，而非 `refute`。

- 编写单行块时，较之 `method{do_stuff}`，尽量使用 `method { do_stuff }`。

- 遵照源码中在用的其他约定。

以上是指导方针，使用时请灵活应变。

### 对你的代码做基准测试

如果你的改动对 Rails 的性能有影响，请使用 [benchmark-ips](https://github.com/evanphx/benchmark-ips) gem 做基准测试，并提供测试结果以供比较。

下面是使用 benchmark-ips 的一个示例：

```ruby
require 'benchmark/ips'

Benchmark.ips do |x|
  x.report('addition') { 1 + 2 }
  x.report('addition with send') { 1.send(:+, 2) }
end
```

上述代码会生成一份报告，包含下述信息：

    Calculating -------------------------------------
                addition   132.013k i/100ms
      addition with send   125.413k i/100ms
    -------------------------------------------------
                addition      9.677M (± 1.7%) i/s -     48.449M
      addition with send      6.794M (± 1.1%) i/s -     33.987M

详情参见 benchmark-ips 的[自述文件](https://github.com/evanphx/benchmark-ips/blob/master/README.md)。

### 运行测试

在推送改动之前，通常不运行整个测试组件。railties 的测试组件所需的时间特别长，如果按照推荐的工作流程，使用 [rails-dev-box](https://github.com/rails/rails-dev-box) 把源码挂载到 `/vagrant`，时间更长。

作为一种折中方案，应该测试明显受到影响的代码；如果不是改动 railties，运行受影响的组件的整个测试组件。如果所有测试都能通过，表明你可以提请你的贡献了。为了捕获别处预料之外的问题，我们配备了 [Travis CI](https://travis-ci.org/rails/rails)，作为一个安全保障。

#### 整个 Rails

运行全部测试：

```sh
$ cd rails
$ bundle exec rake test
```

#### 某个组件

可以只运行某个组件（如 Action Pack）的测试。例如，运行 Action Mailer 的测试：

```sh
$ cd actionmailer
$ bundle exec rake test
```

#### 运行单个测试

可以通过 `ruby` 运行单个测试。例如：

```sh
$ cd actionmailer
$ bundle exec ruby -w -Itest test/mail_layout_test.rb -n test_explicit_class_layout
```

`-n` 选项指定运行单个方法，而非整个文件。

#### 测试 Active Record

首先，创建所需的数据库。对 MySQL 和 PostgreSQL 来说，运行 SQL 语句 `create database activerecord_unittest` 和 `create database activerecord_unittest2` 就行。SQLite3 无需这一步。

只使用 SQLite3 运行 Active Record 的测试组件：

```sh
$ cd activerecord
$ bundle exec rake test:sqlite3
```

然后分别运行：

    test:mysql2
    test:postgresql

最后，一次运行前述三个测试：

```sh
$ bundle exec rake test
```

也可以单独运行某个测试：

```sh
$ ARCONN=sqlite3 bundle exec ruby -Itest test/cases/associations/has_many_associations_test.rb
```

使用全部适配器运行某个测试：

```sh
$ bundle exec rake TEST=test/cases/associations/has_many_associations_test.rb
```

此外，还可以调用 `test_jdbcmysql`、`test_jdbcsqlite3` 或 `test_jdbcpostgresql`。针对其他数据库的测试参见 `activerecord/RUNNING_UNIT_TESTS.rdoc` 文件，持续集成服务器运行的测试组件参见 `ci/travis.rb` 文件。

### 提醒

运行测试组件的命令启用了提醒。理想情况下，Ruby on Rails 不应该发出提醒，不过你可能会见到一些，其中部分可能来自第三方库。如果看到提醒，请忽略（或修正），然后提交不发出提醒的补丁。

如果确信自己在做什么，想得到干净的输出，可以覆盖这个旗标：

```sh
$ RUBYOPT=-W0 bundle exec rake test
```

### 更新 CHANGELOG

CHANGELOG 是每次发布的重要一环，保存着每个 Rails 版本的改动列表。

如果添加或删除了功能、提交了缺陷修正，或者添加了弃用提示，应该在框架的 CHANGELOG 顶部添加一条记录。重构和文档修改一般不应该在 CHANGELOG 中记录。

CHANGELOG 中的记录应该概述所做的改动，并且在末尾加上作者的名字。如果需要，可以写成多行，也可以缩进四个空格，添加代码示例。如果改动与某个工单有关，应该加上工单号。下面是一条 CHANGELOG 记录示例：

    *   Summary of a change that briefly describes what was changed. You can use multiple
        lines and wrap them at around 80 characters. Code examples are ok, too, if needed:

            class Foo
              def bar
                puts 'baz'
              end
            end

        You can continue after the code example and you can attach issue number. GH#1234

        *Your Name*

如果没有代码示例，或者没有分成多行，可以直接在最后一个词后面加上作者的名字。否则，最好新起一段。

### 更新 Gemfile.lock

有些改动需要更新依赖。此时，要执行 `bundle update` 命令，获取依赖的正确版本，并且随改动一起提交 `Gemfile.lock` 文件。

### 健全性检查

在提交之前，你不一定是唯一查看代码的人。如果你认识其他使用 Rails 的人，试着邀请他们检查你的代码。如果不认识使用 Rails 的人，可以在 IRC 聊天室中找人帮忙，或者在 rails-core 邮件列表中发布你的想法。在公开补丁之前做检查是一种“冒烟测试”：如果你不能让另一个开发者认同你的代码，核心团队可能也不会认同。

### 提交改动

在自己的电脑中对你的代码满意之后，要把改动提交到 Git 仓库中：

```sh
$ git commit -a
```

上述命令会启动编辑器，让你编写一个提交消息。写完之后，保存并关闭编辑器，然后继续往下做。

行文好，而且具有描述性的提交消息有助于别人理解你为什么做这项改动，因此请认真对待提交消息。

好的提交消息类似下面这样：

    Short summary (ideally 50 characters or less)

    More detailed description, if necessary. It should be wrapped to
    72 characters. Try to be as descriptive as you can. Even if you
    think that the commit content is obvious, it may not be obvious
    to others. Add any description that is already present in the
    relevant issues; it should not be necessary to visit a webpage
    to check the history.

    The description section can have multiple paragraphs.

    Code examples can be embedded by indenting them with 4 spaces:

        class ArticlesController
          def index
            render json: Article.limit(10)
          end
        end

    You can also add bullet points:

    - make a bullet point by starting a line with either a dash (-)
      or an asterisk (*)

    - wrap lines at 72 characters, and indent any additional lines
      with 2 spaces for readability

TIP: 如果合适，请把多条提交压缩成一条提交。这样便于以后挑选，而且能保持 Git 日志整洁。

### 更新你的分支

你在改动的过程中，master 分支很有可能有变化。请获取这些变化：

```sh
$ git checkout master
$ git pull --rebase
```

然后在最新的改动上重新应用你的补丁：

```sh
$ git checkout my_new_branch
$ git rebase master
```

没有冲突？测试依旧能通过？你的改动依然合理？那就往下走。

### 派生

打开 [GitHub 中的 Rails 仓库](https://github.com/rails/rails)，点击右上角的“Fork”按钮。

把派生的远程仓库添加到本地设备中的本地仓库里：

```sh
$ git remote add mine https://github.com:<your user name>/rails.git
```

推送到你的远程仓库：

```sh
$ git push mine my_new_branch
```

你可能已经把派生的仓库克隆到本地设备中了，因此想把 Rails 仓库添加为远程仓库。此时，要这么做。

在你克隆的派生仓库的目录中：

```sh
$ git remote add rails https://github.com/rails/rails.git
```

从官方仓库中下载新提交和分支：

```sh
$ git fetch rails
```

合并新内容：

```sh
$ git checkout master
$ git rebase rails/master
```

更新你派生的仓库：

```sh
$ git push origin master
```

如果想更新另一个分支：

```sh
$ git checkout branch_name
$ git rebase rails/branch_name
$ git push origin branch_name
```

### 创建拉取请求

打开你刚刚推送的目标仓库（例如 https://github.com/your-user-name/rails），点击“New pull request”按钮。

如果需要修改比较的分支（默认比较 master 分支），点击“Edit”，然后点击“Click to create a pull request for this comparison”。

确保包含你所做的改动。填写补丁的详情，以及一个有意义的标题。然后点击“Send pull request”。Rails 核心团队会收到关于此次提交的通知。

### 获得反馈

多数拉取请求在合并之前会经过几轮迭代。不同的贡献者有时有不同的观点，而且有些补丁要重写之后才能合并。

有些 Rails 贡献者开启了 GitHub 的邮件通知，有些则没有。此外，Rails 团队中（几乎）所有人都是志愿者，因此你的拉取请求可能要等几天才能得到第一个反馈。别失望！有时快，有时慢。这就是开源世界的日常。

如果过了一周还是无人问津，你可以尝试主动推进。你可以在 [rubyonrails-core 邮件列表](http://groups.google.com/group/rubyonrails-core/)中发消息，也可以在拉取请求中发一个评论。

在你等待反馈的过程中，可以再创建其他拉取请求，也可以给别人的拉取请求反馈。我想，他们会感激你的，正如你会感激给你反馈的人一样。

### 必要时做迭代

很有可能你得到的反馈是让你修改。别灰心，为活跃的开源项目做贡献就要跟上社区的步伐。如果有人建议你调整代码，你应该做调整，然后重新提交。如果你得到的反馈是，你的代码不应该添加到核心中，或许你可以考虑发布成一个 gem。

#### 压缩提交

我们要求你做的一件事可能是让你“压缩提交”，把你的全部提交合并成一个提交。我们喜欢只有一个提交的拉取请求。这样便于把改动逆向移植（backport）到稳定分支中，压缩后易于还原不良提交，而且 Git 历史条理更清晰。Rails 是个大型项目，过多无关的提交容易扰乱视线。

为此，Git 仓库中要有一个指向官方 Rails 仓库的远程仓库。这样做是有必要的，如果你还没有这么做，确保先执行下述命令：

```sh
$ git remote add upstream https://github.com/rails/rails.git
```

这个远程仓库的名称随意，如果你使用的不是 `upstream`，请相应修改下述说明。

假设你的远程分支是 `my_pull_request`，你要这么做：

```sh
$ git fetch upstream
$ git checkout my_pull_request
$ git rebase -i upstream/master

< Choose 'squash' for all of your commits except the first one. >
< Edit the commit message to make sense, and describe all your changes. >

$ git push origin my_pull_request -f
```

此时，GitHub 中的拉取请求会刷新，更新为最新的提交。

#### 更新拉取请求

有时，你得到的反馈是让你修改已经提交的代码。此时可能需要修正现有的提交。在这种情况下，Git 不允许你推送改动，因为你推送的分支和本地分支不匹配。你无须重新发起拉取请求，而是可以强制推送到 GitHub 中的分支，如前一节的压缩提交命令所示：

```sh
$ git push origin my_pull_request -f
```

这个命令会更新 GitHub 中的分支和拉取请求。不过注意，强制推送可能会导致远程分支中的提交丢失。使用时要小心。

### 旧版 Ruby on Rails

如果想修正旧版 Ruby on Rails，要创建并切换到本地跟踪分支（tracking branch）。下例切换到 4-0-stable 分支：

```sh
$ git branch --track 4-0-stable origin/4-0-stable
$ git checkout 4-0-stable
```

TIP: 为了明确知道你处于代码的哪个版本，可以[把 Git 分支名放到 shell 提示符中](http://qugstart.com/blog/git-and-svn/add-colored-git-branch-name-to-your-shell-prompt/)。

#### 逆向移植

合并到 master 分支中的改动针对 Rails 的下一个主发布版。有时，你的改动可能需要逆向移植到旧的稳定分支中。一般来说，安全修正和缺陷修正会做逆向移植，而新特性和引入行为变化的补丁不会这么做。如果不确定，在逆向移植之前最好询问一位 Rails 团队成员，以免浪费精力。

对简单的修正来说，逆向移植最简单的方法是根据 master 分支的改动提取差异（diff），然后在目标分支应用改动。

首先，确保你的改动是当前分支与 master 分支之间的唯一差别：

```sh
$ git log master..HEAD
```

然后，提取差异：

```sh
$ git format-patch master --stdout > ~/my_changes.patch
```

切换到目标分支，然后应用改动：

```sh
$ git checkout -b my_backport_branch 3-2-stable
$ git apply ~/my_changes.patch
```

简单的改动可以这么做。然而，如果改动较为复杂，或者 master 分支的代码与目标分支之间差异巨大，你可能要做更多的工作。逆向移植的工作量有大有小，有时甚至不值得为此付出精力。

解决所有冲突，并且确保测试都能通过之后，推送你的改动，然后为逆向移植单独发起一个拉取请求。还应注意，旧分支的构建目标可能与 master 分支不同。如果可能，提交拉取请求之前最好在本地使用 `.travis.yml` 文件中给出的 Ruby 版本测试逆向移植。

然后……可以思考下一次贡献了！

Rails 贡献者
------------

所有贡献者，不管是通过 master 还是 docrails 贡献的，都在 [Rails Contributors 页面](http://contributors.rubyonrails.org/)中列出。
