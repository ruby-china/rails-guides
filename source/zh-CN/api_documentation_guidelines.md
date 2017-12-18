# API 文档指导方针

本文说明 Ruby on Rails 的 API 文档指导方针。

读完本文后，您将学到：

*   如何编写有效的文档；
*   为不同 Ruby 代码编写文档的风格指导方针。

-----------------------------------------------------------------------------

<a class="anchor" id="rdoc"></a>

## RDoc

[Rails API 文档](http://api.rubyonrails.org/)使用 [RDoc](http://docs.seattlerb.org/rdoc/) 生成。如果想生成 API 文档，要在 Rails 根目录中执行 `bundle install`，然后再执行：

```sh
$ bundle exec rake rdoc
```

得到的 HTML 文件在 `./doc/rdoc` 目录中。

RDoc 的[标记](http://docs.seattlerb.org/rdoc/RDoc/Markup.html)和[额外的指令](http://docs.seattlerb.org/rdoc/RDoc/Parser/Ruby.html)参见文档。

<a class="anchor" id="wording"></a>

## 用词

使用简单的陈述句。简短更好，要说到点子上。

使用现在时：“Returns a hash that...”，而非“Returned a hash that...”或“Will return a hash that...”。

注释的第一个字母大写，后续内容遵守常规的标点符号规则：

```sh
# Declares an attribute reader backed by an internally-named
# instance variable.
def attr_internal_reader(*attrs)
  ...
end
```

使用通行的方式与读者交流，可以直言，也可以隐晦。使用当下推荐的习语。如有必要，调整内容的顺序，强调推荐的方式。文档应该说明最佳实践和现代的权威 Rails 用法。

文档应该简洁全面，要指明边缘情况。如果模块是匿名的呢？如果集合是空的呢？如果参数是 nil 呢？

Rails 组件的名称在单词之间有个空格，如“Active Support”。`ActiveRecord` 是一个 Ruby 模块，而 Active Record 是一个 ORM。所有 Rails 文档都应该始终使用正确的名称引用 Rails 组件。如果你在下一篇博客文章或演示文稿中这么做，人们会觉得你很正规。

拼写要正确：Arel、Test::Unit、RSpec、HTML、MySQL、JavaScript、ERB。如果不确定，请查看一些权威资料，如各自的官方文档。

“SQL”前面使用不定冠词“an”，如“an SQL statement”和“an SQLite database”。

避免使用“you”和“your”。例如，较之

```
If you need to use `return` statements in your callbacks, it is recommended that you explicitly define them as methods.
```

这样写更好：

```
If `return` is needed it is recommended to explicitly define a method.
```

不过，使用代词指代虚构的人时，例如“有会话 cookie 的用户”，应该使用中性代词（they/their/them）。

*   不用 he 或 she，用 they
*   不用 him 或 her，用 them
*   不用 his 或 her，用 their
*   不用 his 或 hers，用 theirs
*   不用 himself 或 herself，用 themselves

<a class="anchor" id="english"></a>

## 英语

请使用美式英语（color、center、modularize，等等）。美式英语与英式英语之间的拼写差异参见[这里](http://en.wikipedia.org/wiki/American_and_British_English_spelling_differences)。

<a class="anchor" id="oxford-comma"></a>

## 牛津式逗号

请使用[牛津式逗号](http://en.wikipedia.org/wiki/Serial_comma)（“red, white, and blue”，而非“red, white and blue”）。

<a class="anchor" id="example-code"></a>

## 示例代码

选择有意义的示例，说明基本用法和有趣的点或坑。

代码使用两个空格缩进，即根据标记在左外边距的基础上增加两个空格。示例应该遵守 [Rails 编程约定](contributing_to_ruby_on_rails.html#follow-the-coding-conventions)。

简短的文档无需明确使用“Examples”标注引入代码片段，直接跟在段后即可：

```ruby
# Converts a collection of elements into a formatted string by
# calling +to_s+ on all elements and joining them.
#
#   Blog.all.to_formatted_s # => "First PostSecond PostThird Post"
```

但是大段文档可以单独有个“Examples”部分：

```ruby
# ==== Examples
#
#   Person.exists?(5)
#   Person.exists?('5')
#   Person.exists?(name: "David")
#   Person.exists?(['name LIKE ?', "%#{query}%"])
```

表达式的结果在表达式之后，使用 “# => ”给出，而且要纵向对齐：

```ruby
# For checking if an integer is even or odd.
#
#   1.even? # => false
#   1.odd?  # => true
#   2.even? # => true
#   2.odd?  # => false
```

如果一行太长，结果可以放在下一行：

```ruby
#   label(:article, :title)
#   # => <label for="article_title">Title</label>
#
#   label(:article, :title, "A short title")
#   # => <label for="article_title">A short title</label>
#
#   label(:article, :title, "A short title", class: "title_label")
#   # => <label for="article_title" class="title_label">A short title</label>
```

不要使用打印方法，如 `puts` 或 `p` 给出结果。

常规的注释不使用箭头：

```ruby
#   polymorphic_url(record)  # same as comment_url(record)
```

<a class="anchor" id="booleans"></a>

## 布尔值

在判断方法或旗标中，尽量使用布尔语义，不要用具体的值。

如果所用的“true”或“false”与 Ruby 定义的一样，使用常规字体。`true` 和 `false` 两个单例要使用等宽字体。请不要使用“truthy”，Ruby 语言定义了什么是真什么是假，“true”和“false”就能表达技术意义，无需使用其他词代替。

通常，如非绝对必要，不要为单例编写文档。这样能阻止智能的结构，如 `!!` 或三元运算符，便于重构，而且代码不依赖方法返回的具体值。

例如：

```
`config.action_mailer.perform_deliveries` specifies whether mail will actually be delivered and is true by default
```

用户无需知道旗标具体的默认值，因此我们只说明它的布尔语义。

下面是一个判断方法的文档示例：

```ruby
# Returns true if the collection is empty.
#
# If the collection has been loaded
# it is equivalent to <tt>collection.size.zero?</tt>. If the
# collection has not been loaded, it is equivalent to
# <tt>collection.exists?</tt>. If the collection has not already been
# loaded and you are going to fetch the records anyway it is better to
# check <tt>collection.length.zero?</tt>.
def empty?
  if loaded?
    size.zero?
  else
    @target.blank? && !scope.exists?
  end
end
```

这个 API 没有提到任何具体的值，知道它具有判断功能就够了。

<a class="anchor" id="file-names"></a>

## 文件名

通常，文件名相对于应用的根目录：

```ruby
config/routes.rb            # YES
routes.rb                   # NO
RAILS_ROOT/config/routes.rb # NO
```

<a class="anchor" id="fonts"></a>

## 字体

<a class="anchor" id="fixed-width-font"></a>

### 等宽字体

使用等宽字体编写：

*   常量，尤其是类名和模块名
*   方法名
*   字面量，如 `nil`、`false`、`true`、`self`
*   符号
*   方法的参数
*   文件名

```ruby
class Array
  # Calls +to_param+ on all its elements and joins the result with
  # slashes. This is used by +url_for+ in Action Pack.
  def to_param
    collect { |e| e.to_param }.join '/'
  end
end
```

WARNING: 只有简单的内容才能使用 `+...+` 标记使用等宽字体，如常规的方法名、符号、路径（含有正斜线），等等。其他内容应该使用 `<tt>...</tt>`，尤其是带有命名空间的类名或模块名，如 `<tt>ActiveRecord::Base</tt>`。


可以使用下述命令测试 RDoc 的输出：

```sh
$ echo "+:to_param+" | rdoc --pipe
# => <p><code>:to_param</code></p>
```

<a class="anchor" id="regular-font"></a>

### 常规字体

“true”和“false”是英语单词而不是 Ruby 关键字时，使用常规字体：

```ruby
# Runs all the validations within the specified context.
# Returns true if no errors are found, false otherwise.
#
# If the argument is false (default is +nil+), the context is
# set to <tt>:create</tt> if <tt>new_record?</tt> is true,
# and to <tt>:update</tt> if it is not.
#
# Validations with no <tt>:on</tt> option will run no
# matter the context. Validations with # some <tt>:on</tt>
# option will only run in the specified context.
def valid?(context = nil)
  ...
end
```

<a class="anchor" id="description-lists"></a>

## 描述列表

在选项、参数等列表中，在项目和描述之间使用一个连字符（而不是一个冒号，因为选项一般是符号）：

```ruby
# * <tt>:allow_nil</tt> - Skip validation if attribute is +nil+.
```

描述开头是大写字母，结尾有一个句号——这是标准的英语。

<a class="anchor" id="dynamically-generated-methods"></a>

## 动态生成的方法

使用 `(module|class)_eval(STRING)` 创建的方法在旁边有个注释，举例说明生成的代码。这种注释与模板之间相距两个空格。

```ruby
for severity in Severity.constants
  class_eval <<-EOT, __FILE__, __LINE__
    def #{severity.downcase}(message = nil, progname = nil, &block)  # def debug(message = nil, progname = nil, &block)
      add(#{severity}, message, progname, &block)                    #   add(DEBUG, message, progname, &block)
    end                                                              # end
                                                                     #
    def #{severity.downcase}?                                        # def debug?
      #{severity} >= @level                                          #   DEBUG >= @level
    end                                                              # end
  EOT
end
```

如果这样得到的行太长，比如说有 200 多列，把注释放在上方：

```ruby
# def self.find_by_login_and_activated(*args)
#   options = args.extract_options!
#   ...
# end
self.class_eval %{
  def self.#{method_id}(*args)
    options = args.extract_options!
    ...
  end
}
```

<a class="anchor" id="method-visibility"></a>

## 方法可见性

为 Rails 编写文档时，要区分公开 API 和内部 API。

与多数库一样，Rails 使用 Ruby 提供的 `private` 关键字定义内部 API。然而，公开 API 遵照的约定稍有不同。不是所有公开方法都旨在供用户使用，Rails 使用 `:nodoc:` 指令注解内部 API 方法。

因此，在 Rails 中有些可见性为 `public` 的方法不是供用户使用的。

`ActiveRecord::Core::ClassMethods#arel_table` 就是一例：

```sh
module ActiveRecord::Core::ClassMethods
  def arel_table #:nodoc:
    # do some magic..
  end
end
```

你可能想，“这是 `ActiveRecord::Core` 的一个公开类方法”，没错，但是 Rails 团队不希望用户使用这个方法。因此，他们把它标记为 `:nodoc:`，不包含在公开文档中。这样做，开发团队可以根据内部需要在发布新版本时修改这个方法。方法的名称可能会变，或者返回值有变化，也可能是整个类都不复存在——有太多不确定性，因此不应该在你的插件或应用中使用这个 API。如若不然，升级新版 Rails 时，你的应用或 gem 可能遭到破坏。

为 Rails 做贡献时一定要考虑清楚 API 是否供最终用户使用。未经完整的弃用循环之前，Rails 团队不会轻易对公开 API 做大的改动。如果没有定义为私有的（默认是内部 API），建议你使用 `:nodoc:` 标记所有内部的方法和类。API 稳定之后，可见性可以修改，但是为了向后兼容，公开 API 往往不宜修改。

使用 `:nodoc:` 标记一个类或模块表示里面的所有方法都是内部 API，不应该直接使用。

综上，Rails 团队使用 `:nodoc:` 标记供内部使用的可见性为公开的方法和类，对 API 可见性的修改要谨慎，必须先通过一个拉取请求讨论。

<a class="anchor" id="regarding-the-rails-stack"></a>

## 考虑 Rails 栈

为 Rails API 编写文档时，一定要记住所有内容都身处 Rails 栈中。

这意味着，方法或类的行为在不同的作用域或上下文中可能有所不同。

把整个栈考虑进来之后，行为在不同的地方可能有变。`ActionView::Helpers::AssetTagHelper#image_tag` 就是一例：

```ruby
# image_tag("icon.png")
#   # => <img alt="Icon" src="/assets/icon.png" />
```

虽然 `#image_tag` 的默认行为是返回 `/images/icon.png`，但是把整个 Rails 栈（包括 Asset Pipeline）考虑进来之后，可能会得到上述结果。

我们只关注考虑整个 Rails 默认栈的行为。

因此，我们要说明的是框架的行为，而不是单个方法。

如果你对 Rails 团队处理某个 API 的方式有疑问，别迟疑，在[问题追踪系统](https://github.com/rails/rails/issues)中发一个工单，或者提交补丁。
