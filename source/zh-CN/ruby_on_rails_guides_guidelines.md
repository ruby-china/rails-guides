Ruby on Rails 指南指导方针
==========================

本文说明编写 Ruby on Rails 指南的指导方针。本文也遵守这一方针，本身就是个示例。

读完本文后，您将学到：

- Rails 文档使用的约定；

- 如何在本地生成指南。

Markdown
--------

指南使用 [GitHub Flavored Markdown](https://help.github.com/articles/github-flavored-markdown) 编写。Markdown 有[完整的文档](http://daringfireball.net/projects/markdown/syntax)，还有[速查表](http://daringfireball.net/projects/markdown/basics)。

序言
----

每篇文章的开头要有介绍性文字（蓝色区域中的简短介绍）。序言应该告诉读者文章的主旨，以及能让读者学到什么。可以以[Rails 路由全解](routing.html)为例。

标题
----

每篇文章的标题使用 `h1` 标签，文章中的小节使用 `h2` 标签，子节使用 `h3` 标签，以此类推。注意，生成的 HTML 从 `<h2>` 标签开始。

```md
Guide Title
===========

Section
-------

### Sub Section
```

标题中除了介词、连词、冠词和“to be”这种形式的动词之外，每个词的首字母大写：

```md
#### Middleware Stack is an Array
#### When are Objects Saved?
```

行内格式与正文一样：

```md
##### The `:content_type` Option
```

API 文档指导方针
----------------

指南和 API 应该连贯一致。尤其是[API 文档指导方针](api_documentation_guidelines.html)中的下述几节，同样适用于指南：

- [用词](api_documentation_guidelines.html#用词)

- [英语](api_documentation_guidelines.html#英语)

- [示例代码](api_documentation_guidelines.html#示例代码)

- [文件名](api_documentation_guidelines.html#文件名)

- [字体](api_documentation_guidelines.html#字体)

HTML 版指南
-----------

在生成指南之前，先确保你的系统中安装了 Bundler 的最新版。写作本文时，要在你的设备中安装 Bundler 1.3.5 或以上版本。

安装最新版 Bundler 的方法是，执行 `gem install bundler` 命令。

### 生成

若想生成全部指南，进入 `guides` 目录，执行 `bundle install` 命令之后再执行：

```sh
$ bundle exec rake guides:generate
```

或者

```sh
$ bundle exec rake guides:generate:html
```

得到的 HTML 文件在 `./output` 目录中。

如果只想处理 `my_guide.md`，使用 `ONLY` 环境变量：

```sh
$ touch my_guide.md
$ bundle exec rake guides:generate ONLY=my_guide
```

默认情况下，没有改动的文章不会处理，因此实际使用中很少用到 `ONLY`。

如果想强制处理所有文章，传入 `ALL=1`。

此外，建议你加上 `WARNINGS=1`。这样能检测到重复的 ID，遇到死链还会提醒。

如果想生成英语之外的指南，可以把译文放在 `source` 中的子目录里（如 `source/es`），然后使用 `GUIDES_LANGUAGE` 环境变量：

```sh
$ bundle exec rake guides:generate GUIDES_LANGUAGE=es
```

如果想查看可用于配置生成脚本的全部环境变量，只需执行：

```sh
$ rake
```

### 验证

请使用下述命令验证生成的 HTML：

```sh
$ bundle exec rake guides:validate
```

尤其要注意，ID 是从标题的内容中生成的，往往会重复。生成指南时请设定 `WARNINGS=1`，监测重复的 ID。提醒消息中有建议的解决方案。

Kindle 版指南
-------------

### 生成

如果想生成 Kindle 版指南，使用下述 Rake 任务：

```sh
$ bundle exec rake guides:generate:kindle
```
