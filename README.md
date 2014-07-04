Rails 指南翻译
=============

翻译准备工作
----------

使用 `curl`：

```bash
ruby -e "$(curl -sSL https://rawgithub.com/ruby-china/guides/master/install.rb)"
```

或使用 `wget`：

```bash
ruby <(wget --no-check-certificate https://rawgithub.com/ruby-china/guides/master/install.rb -O -)
```

会抓取 `ruby-china/rails` 与 `ruby-china/guides` 这两个代码库。

`ruby-china/rails`：更新原文用。

`ruby-china/guides`：存放译文用。

这俩个代码库默认会存放在：

```
~/docs/rails-guides-translation-cn
```

若是手动抓取，需修改这两个代码库存放的位置，并存成 `BASE_PATH` 文件。

翻译流程
-------

* 1. 先更新原文。

比如 `getting_started.md`：

```ruby
$ rake guides:update_guide getting_started.md
```

这样 `source/getting_started.md` 便是最新的，拷贝原文内容到 `source/zh-CN/getting_started.md` 下便可开始翻译。

* 2. 进行翻译。

### 预览

```ruby
$ GUIDES_LANGUAGE=zh-CN rake guides:generate
```

命令过长可在 `~/.bashrc` 或 `~/.zshrc` 设别名：

```bash
alias gen="GUIDES_LANGUAGE=zh-CN rake guides:generate"`。
```

* 3. 翻译完成发送 Pull Request。

**注意，翻译完成的译文必须与原文是相同版本。**

### 无力翻译

把目前的工作成果发送 Pull Request，让其他人接手。

更新翻译
-------

使用：

```bash
$ rake guides:update_guides
```

来看所有上游有更新的原文。

### 更新“已完成”的翻译

**以 `getting_started.md` 为例。**

运行：

```bash
$ rake guides:update_guide getting_started.md

$ git status
```

开新分支：

```bash
$ git checkout -b new-branch-name
```

将原文更动的部份，翻译、修正到 `source/zh-CN/getting_started.md`，提交、发送 Pull Request。

### 更新“未开始”的翻译

**以 `getting_started.md` 为例。**

```bash
$ rake guides:update_guides

$ git status
```

开新分支：

```bash
$ git checkout -b new-branch-name
```

把原文 `source/getting_started.md` 的内容拷贝到 `source/zh-CN/getting_started.md` ，提交，发送 Pull Request。

勘误
----

翻译的错误，可以修正后发 Pull Request；或是[回报](https://github.com/ruby-china/guides/issues/new)等别人修正也可以。

若不是翻译的错误，是原文的错误，请检查 http://edgeguides.rubyonrails.org 是否已经修正了，没有的话可以去 [rails/rails][rails] 帮忙修正。记得有关文件的改动，在提交信息要加上 `[ci skip]`。

在 [rails/rails][rails] 提报或修正前，最好先阅读：[Contributing to Ruby on Rails](http://edgeguides.rubyonrails.org/contributing_to_ruby_on_rails.html)。

部署
----

```ruby
$ rake guides:deploy
```

会把 `ruby-china/guides/output/zh-CN/*` 的静态文件，拷贝到 `ruby-china/ruby-china.github.io`。

建议
----

[欢迎提意见](https://github.com/ruby-china/guides/issues/new)

其它格式
-------

> PDF, MOBI, EPUB 格式

请支持安道所翻译的 [Rails 指南](https://selfstore.io/products/13)

协议
----

![CC-BY-SA](CC-BY-SA.png)

简体译文以 @Andor_Chen 翻译的基础着手进行。

译文授权协议为 [Creative Commons Attribution-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-sa/4.0/)。

代码来自 [rails/rails][rails]，采用相同的 [MIT license](http://opensource.org/licenses/MIT) 协议。

[rails]: https://github.com/rails/rails
