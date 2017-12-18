# Asset Pipeline

本文介绍 Asset Pipeline。

读完本文后，您将学到：

*   Asset Pipeline 是什么，有什么用处；
*   如何合理组织应用的静态资源文件；
*   使用 Asset Pipeline 的好处；
*   如何为 Asset Pipeline 添加预处理器；
*   如何用 gem 打包静态资源文件。

-----------------------------------------------------------------------------

<a class="anchor" id="what-is-the-asset-pipeline"></a>

## Asset Pipeline 是什么

Asset Pipeline 提供了用于连接、简化或压缩 JavaScript 和 CSS 静态资源文件的框架。有了 Asset Pipeline，我们还可以使用其他语言和预处理器，例如 CoffeeScript、Sass 和 ERB，编写这些静态资源文件。应用中的静态资源文件还可以自动与其他 gem 中的静态资源文件合并。例如，与 `jquery-rails` gem 中包含的 `jquery.js` 文件合并，从而使 Rails 能够支持 AJAX 特性。

Asset Pipeline 是通过 [sprockets-rails](https://github.com/rails/sprockets-rails) gem 实现的，Rails 默认启用了这个 gem。在新建 Rails 应用时，通过 `--skip-sprockets` 选项可以禁用这个 gem。

```sh
$ rails new appname --skip-sprockets
```

在新建 Rails 应用时，Rails 自动在 Gemfile 中添加了 `sass-rails`、`coffee-rails` 和 `uglifier` gem，Sprockets 通过这些 gem 来压缩静态资源文件：

```ruby
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'
```

使用 `--skip-sprockets` 选项时，Rails 不会在 Gemfile 中添加这些 gem。因此，之后如果想要启用 Asset Pipeline，就需要手动在 Gemfile 中添加这些 gem。此外，使用 `--skip-sprockets` 选项时生成的 `config/application.rb` 也略有不同，用于加载 `sprockets/railtie` 的代码被注释掉了，因此要启用 Asset Pipeline，还需要取消注释：

```ruby
# require "sprockets/railtie"
```

在 `production.rb` 配置文件中，通过 `config.assets.css_compressor` 和 `config.assets.js_compressor` 选项可以分别为 CSS 和 JavaScript 静态资源文件设置压缩方式：

```ruby
config.assets.css_compressor = :yui
config.assets.js_compressor = :uglifier
```

NOTE: 如果 Gemfile 中包含 `sass-rails` gem，Rails 就会自动使用这个 gem 压缩 CSS 静态资源文件，而无需设置 `config.assets.css_compressor` 选项。

<a class="anchor" id="main-features"></a>

### 主要特性

Asset Pipeline 的特性之一是连接静态资源文件，目的是减少渲染网页时浏览器发起的请求次数。Web 浏览器能够同时发起的请求次数是有限的，因此更少的请求次数可能意味着更快的应用加载速度。

Sprockets 把所有 JavaScript 文件连接为一个主 `.js` 文件，把所有 CSS 文件连接为一个主 `.css` 文件。后文会介绍，我们可以按需定制连接文件的方式。在生产环境中，Rails 会在每个文件名中插入 SHA256 指纹，以便 Web 浏览器缓存文件。当我们修改了文件内容，Rails 会自动修改文件名中的指纹，从而让原有缓存失效。

Asset Pipeline 的特性之二是简化或压缩静态资源文件。对于 CSS 文件，会删除空格和注释。对于 JavaScript 文件，可以进行更复杂的处理，我们可以从内置选项中选择处理方式，也可以自定义处理方式。

Asset Pipeline 的特性之三是可以使用更高级的语言编写静态资源文件，再通过预编译转换为实际的静态资源文件。默认支持的高级语言有：用于编写 CSS 的 Sass，用于编写 JavaScript 的 CoffeeScript，以及 ERB。

<a class="anchor" id="what-is-fingerprinting-and-why-should-i-care"></a>

### 指纹识别是什么，为什么要关心指纹？

指纹是一项根据文件内容修改文件名的技术。一旦文件内容发生变化，文件名就会发生变化。对于静态文件或内容很少发生变化的文件，这项技术提供了确定文件的两个版本是否相同的简单方法，特别是在跨服务器和多次部署的情况下。

当一个文件的文件名能够根据文件内容发生变化，并且能够保证不会出现重名时，就可以通过设置 HTTP 首部来建议所有缓存（CDN、ISP、网络设备或 Web 浏览器的缓存）都保存该文件的副本。一旦文件内容更新，文件名中的指纹就会发生变化，从而使远程客户端发起对文件新副本的请求。这项技术称为“缓存清除”（cache busting）。

Sprockets 使用指纹的方式是在文件名中添加文件内容的哈希值，并且通常会添加到文件名末尾。例如，对于 CSS 文件 `global.css`，添加哈希值后文件名可能变为：

```
global-908e25f4bf641868d8683022a5b62f54.css
```

Rails 的 Asset Pipeline 也采取了这种策略。

以前 Rails 采用的策略是，通过内置的辅助方法，为每一个指向静态资源文件的链接添加基于日期生成的查询字符串。在网页源代码中，会生成下面这样的链接：

```
/stylesheets/global.css?1309495796
```

使用查询字符串的策略有如下缺点：

**1. 如果一个文件的两个版本只是文件名的查询参数不同，这时不是所有缓存都能可靠地更新该文件的缓存。**

[Steve Souders](http://www.stevesouders.com/blog/2008/08/23/revving-filenames-dont-use-querystring/) 建议，“……避免在可缓存的资源上使用查询字符串”。他发现，在使用查询字符串的情况下，有 5—20% 的请求不会被缓存。对于某些 CDN，通过修改查询字符串根本无法使缓存失效。

**2. 在多服务器环境中，不同节点上的文件名有可能发生变化。**

在 Rails 2.x 中，默认基于文件修改时间生成查询字符串。当静态资源文件被部署到某个节点上时，无法保证文件的时间戳保持不变，这样，对于同一个文件的请求，不同服务器可能返回不同的文件名。

**3. 缓存失效的情况过多。**

每次部署代码的新版本时，静态资源文件都会被重新部署，这些文件的最后修改时间也会发生变化。这样，不管其内容是否发生变化，客户端都不得不重新获取这些文件。

使用指纹可以避免使用查询字符串的这些缺点，并且能够确保文件内容相同时文件名也相同。

在开发环境和生产环境中，指纹都是默认启用的。通过 `config.assets.digest` 配置选项，可以启用或禁用指纹。

扩展阅读：

*   [优化缓存](http://code.google.com/speed/page-speed/docs/caching.html)
*   [为文件名添加版本号：请不要使用查询字符串](http://www.stevesouders.com/blog/2008/08/23/revving-filenames-dont-use-querystring/)

<a class="anchor" id="how-to-use-the-asset-pipeline"></a>

## 如何使用 Asset Pipeline

在 Rails 的早期版本中，所有静态资源文件都放在 `public` 文件夹的子文件夹中，例如 `images`、`javascripts` 和 `stylesheets` 子文件夹。当 Rails 开始使用 Asset Pipeline 后，就推荐把静态资源文件放在 `app/assets` 文件夹中，并使用 Sprockets 中间件处理这些文件。

当然，静态资源文件仍然可以放在 `public` 文件夹及其子文件夹中。只要把 `config.public_file_server.enabled` 选项设置为 `true`，Rails 应用或 Web 服务器就会处理 `public` 文件夹及其子文件夹中的所有静态资源文件。但对于需要预处理的文件，都应该放在 `app/assets` 文件夹中。

在生产环境中，Rails 默认会对 `public/assets` 文件夹中的文件进行预处理。经过预处理的静态资源文件将由 Web 服务器直接处理。在生产环境中，`app/assets` 文件夹中的文件不会直接交由 Web 服务器处理。

<a class="anchor" id="controller-specific-assets"></a>

### 针对控制器的静态资源文件

当我们使用生成器生成脚手架或控制器时，Rails 会同时为控制器生成 JavaScript 文件（如果 Gemfile 中包含了 `coffee-rails` gem，那么生成的是 CoffeeScript 文件）和 CSS 文件（如果 Gemfile 中包含了 `sass-rails` gem，那么生成的是 SCSS 文件）。此外，在生成脚手架时，Rails 还会生成 `scaffolds.css` 文件（如果 Gemfile 中包含了 `sass-rails` gem，那么生成的是 `scaffolds.scss` 文件）。

例如，当我们生成 `ProjectsController` 时，Rails 会新建 `app/assets/javascripts/projects.coffee` 文件和 `app/assets/stylesheets/projects.scss` 文件。默认情况下，应用会通过 `require_tree` 指令引入这两个文件。关于 `require_tree` 指令的更多介绍，请参阅 [清单文件和指令](#manifest-files-and-directives)。

针对控制器的 JavaScript 文件和 CSS 文件也可以只在相应的控制器中引入：

`<%= javascript_include_tag params[:controller] %>` 或 `<%= stylesheet_link_tag params[:controller] %>`

此时，千万不要使用 `require_tree` 指令，否则就会重复包含这些静态资源文件。

WARNING: 在进行静态资源文件预编译时，请确保针对控制器的静态文件是在按页加载时进行预编译的。默认情况下，Rails 不会自动对 `.coffee` 和 `.scss` 文件进行预编译。关于预编译工作原理的更多介绍，请参阅 [预编译静态资源文件](#precompiling-assets)。

NOTE: 要使用 CoffeeScript，就必须安装支持 ExecJS 的运行时。macOS 和 Windows 已经预装了此类运行时。关于所有可用运行时的更多介绍，请参阅 [ExecJS](https://github.com/rails/execjs#readme) 文档。

通过在 `config/application.rb` 配置文件中添加下述代码，可以禁止生成针对控制器的静态资源文件：

```ruby
config.generators do |g|
  g.assets false
end
```

<a class="anchor" id="asset-organization"></a>

### 静态资源文件的组织方式

应用的 Asset Pipeline 静态资源文件可以储存在三个位置：`app/assets`、`lib/assets` 和 `vendor/assets`。

*   `app/assets` 文件夹用于储存应用自有的静态资源文件，例如自定义图像、JavaScript 文件和 CSS 文件。
*   `lib/assets` 文件夹用于储存自有代码库的静态资源文件，这些代码库或者不适合放在当前应用中，或者需要在多个应用间共享。
*   `vendor/assets` 文件夹用于储存第三方代码库的静态资源文件，例如 JavaScript 插件和 CSS 框架。如果第三方代码库中引用了同样由 Asset Pipeline 处理的静态资源文件（图像、CSS 文件等），就必须使用 `asset_path` 这样的辅助方法重新编写相关代码。

WARNING: 从 Rails 3 升级而来的用户需要注意，通过设置应用的清单文件， 我们可以包含 `lib/assets` 和 `vendor/assets` 文件夹中的静态资源文件，但是这两个文件夹不再是预编译数组的一部分。更多介绍请参阅 [预编译静态资源文件](#precompiling-assets)。

<a class="anchor" id="search-paths"></a>

#### 搜索路径

当清单文件或辅助方法引用了静态资源文件时，Sprockets 会在静态资源文件的三个默认存储位置中进行查找。

这三个默认存储位置分别是 `app/assets` 文件夹的 `images`、`javascripts` 和 `stylesheets` 子文件夹，实际上这三个文件夹并没有什么特别之处，所有的 `app/assets/*` 文件夹及其子文件夹都会被搜索。

例如，下列文件：

```
app/assets/javascripts/home.js
lib/assets/javascripts/moovinator.js
vendor/assets/javascripts/slider.js
vendor/assets/somepackage/phonebox.js
```

在清单文件中可以像下面这样进行引用：

```javascript
//= require home
//= require moovinator
//= require slider
//= require phonebox
```

这些文件夹的子文件夹中的静态资源文件：

```
app/assets/javascripts/sub/something.js
```

可以像下面这样进行引用：

```javascript
//= require sub/something
```

通过在 Rails 控制台中检查 `Rails.application.config.assets.paths` 变量，我们可以查看搜索路径。

除了标准的 `app/assets/*` 路径，还可以在 `config/application.rb` 配置文件中为 Asset Pipeline 添加其他路径。例如：

```ruby
config.assets.paths << Rails.root.join("lib", "videoplayer", "flash")
```

Rails 会按照路径在搜索路径中出现的先后顺序，对路径进行遍历。因此，在默认情况下，`app/assets` 中的文件优先级最高，将会遮盖 `lib` 和 `vendor` 文件夹中的同名文件。

千万注意，在清单文件之外引用的静态资源文件必须添加到预编译数组中，否则无法在生产环境中使用。

<a class="anchor" id="using-index-files"></a>

#### 使用索引文件

对于 Sprockets，名为 `index`（带有相关扩展名）的文件具有特殊用途。

例如，假设应用中使用的 jQuery 库及多个模块储存在 `lib/assets/javascripts/library_name` 文件夹中，那么 `lib/assets/javascripts/library_name/index.js` 文件将作为这个库的清单文件。在这个库的清单文件中，应该按顺序列出所有需要加载的文件，或者干脆使用 `require_tree` 指令。

在应用的清单文件中，可以把这个库作为一个整体加载：

```javascript
//= require library_name
```

这样，相关代码总是作为整体在应用中使用，降低了维护成本，并使代码保持简洁。

<a class="anchor" id="coding-links-to-assets"></a>

### 创建指向静态资源文件的链接

Sprockets 没有为访问静态资源文件添加任何新方法，而是继续使用我们熟悉的 `javascript_include_tag` 和 `stylesheet_link_tag` 辅助方法：

```erb
<%= stylesheet_link_tag "application", media: "all" %>
<%= javascript_include_tag "application" %>
```

如果使用了 Rails 默认包含的 `turbolinks` gem，并使用了 `data-turbolinks-track` 选项，Turbolinks 就会检查静态资源文件是否有更新，如果有更新就加载到页面中：

```erb
<%= stylesheet_link_tag "application", media: "all", "data-turbolinks-track" => "reload" %>
<%= javascript_include_tag "application", "data-turbolinks-track" => "reload" %>
```

在常规视图中，我们可以像下面这样访问 `app/assets/images` 文件夹中的图像：

```erb
<%= image_tag "rails.png" %>
```

如果在应用中启用了 Asset Pipeline，并且未在当前环境中禁用 Asset Pipeline，那么这个图像文件将由 Sprockets 处理。如果图像的位置是 `public/assets/rails.png`，那么将由 Web 服务器处理。

如果文件请求包含 SHA256 哈希值，例如 `public/assets/rails-f90d8a84c707a8dc923fca1ca1895ae8ed0a09237f6992015fef1e11be77c023.png`，处理的方式也是一样的。关于如何生成哈希值的介绍，请参阅 [在生产环境中](#in-production)。

Sprockets 还会检查 `config.assets.paths` 中指定的路径，其中包括 Rails 应用的标准路径和 Rails 引擎添加的路径。

也可以把图像放在子文件夹中，访问时只需加上子文件夹的名称即可：

```erb
<%= image_tag "icons/rails.png" %>
```

WARNING: 如果对静态资源文件进行了预编译（请参阅 [在生产环境中](#in-production)），那么在页面中链接到并不存在的静态资源文件或空字符串将导致该页面抛出异常。因此，在使用 `image_tag` 等辅助方法处理用户提供的数据时一定要小心。

<a class="anchor" id="css-and-erb"></a>

#### CSS 和 ERB

Asset Pipeline 会自动计算 ERB 的值。也就是说，只要给 CSS 文件添加 `.erb` 扩展名（例如 `application.css.erb`），就可以在 CSS 规则中使用 `asset_path` 等辅助方法。

```erb
.class { background-image: url(<%= asset_path 'image.png' %>) }
```

上述代码中的 `asset_path` 辅助方法会返回指向图像真实路径的链接。图像必须位于静态文件加载路径中，例如 `app/assets/images/image.png`，以便在这里引用。如果在 `public/assets` 文件夹中已经存在此图像的带指纹的版本，那么将引用这个带指纹的版本。

要想使用 [data URI](http://en.wikipedia.org/wiki/Data_URI_scheme)（用于把图像数据直接嵌入 CSS 文件中），可以使用 `asset_data_uri` 辅助方法：

```erb
#logo { background: url(<%= asset_data_uri 'logo.png' %>) }
```

`asset_data_uri` 辅助方法会把正确格式化后的 data URI 插入 CSS 源代码中。

注意，关闭标签不能使用 `-%>` 形式。

<a class="anchor" id="css-and-sass"></a>

#### CSS 和 Sass

在使用 Asset Pipeline 时，静态资源文件的路径都必须重写，为此 `sass-rails` gem 提供了 `-url` 和 `-path` 系列辅助方法（在 Sass 中使用连字符，在 Ruby 中使用下划线），用于处理图像、字体、视频、音频、JavaScript 和 CSS 等类型的静态资源文件。

*   `image-url("rails.png")` 会返回 `url(/assets/rails.png)`
*   `image-path("rails.png")` 会返回 `"/assets/rails.png"`

或使用更通用的形式：

*   `asset-url("rails.png")` 返回 `url(/assets/rails.png)`
*   `asset-path("rails.png")` 返回 `"/assets/rails.png"`

<a class="anchor" id="javascript-coffeescript-and-erb"></a>

#### JavaScript/CoffeeScript 和 ERB

只要给 JavaScript 文件添加 `.erb` 扩展名（例如 `application.js.erb`），就可以在 JavaScript 源代码中使用 `asset_path` 辅助方法：

```erb
$('#logo').attr({ src: "<%= asset_path('logo.png') %>" });
```

上述代码中的 `asset_path` 辅助方法会返回指向图像真实路径的链接。

同样，只要给 CoffeeScript 文件添加 `.erb` 扩展名（例如 `application.coffee.erb`），就可以在 CoffeeScript 源代码中使用 `asset_path` 辅助方法：

```erb
$('#logo').attr src: "<%= asset_path('logo.png') %>"
```

<a class="anchor" id="manifest-files-and-directives"></a>

### 清单文件和指令

Sprockets 使用清单文件来确定需要包含和处理哪些静态资源文件。这些清单文件中的指令会告诉 Sprockets，要想创建 CSS 或 JavaScript 文件需要加载哪些文件。通过这些指令，可以让 Sprockets 加载指定文件，对这些文件进行必要的处理，然后把它们连接为单个文件，最后进行压缩（压缩方式取决于 `Rails.application.config.assets.js_compressor` 选项的值）。这样在页面中只需处理一个文件而非多个文件，减少了浏览器的请求次数，大大缩短了页面的加载时间。通过压缩还能使文件变小，使浏览器可以更快地下载。

例如，在默认情况下，新建 Rails 应用的 `app/assets/javascripts/application.js` 文件包含下面几行代码：

```javascript
// ...
//= require jquery
//= require jquery_ujs
//= require_tree .
```

在 JavaScript 文件中，Sprockets 指令以 `//=.` 开头。上述代码中使用了 `require` 和 `require_tree` 指令。`require` 指令用于告知 Sprockets 哪些文件需要加载。这里加载的是 Sprockets 搜索路径中的 `jquery.js` 和 `jquery_ujs.js` 文件。我们不必显式提供文件的扩展名，因为 Sprockets 假定在 `.js` 文件中加载的总是 `.js` 文件。

`require_tree` 指令告知 `Sprockets` 以递归方式包含指定文件夹中的所有 JavaScript 文件。在指定文件夹路径时，必须使用相对于清单文件的相对路径。也可以通过 `require_directory` 指令包含指定文件夹中的所有 JavaScript 文件，此时将不会采取递归方式。

清单文件中的指令是按照从上到下的顺序处理的，但我们无法确定 `require_tree` 指令包含文件的顺序，因此不应该依赖于这些文件的顺序。如果想要确保连接文件时某些 JavaScript 文件出现在其他 JavaScript 文件之前，可以在清单文件中先行加载这些文件。注意，`require` 系列指令不会重复加载文件。

在默认情况下，新建 Rails 应用的 `app/assets/stylesheets/application.css` 文件包含下面几行代码：

```css
/* ...
*= require_self
*= require_tree .
*/
```

无论新建 Rails 应用时是否使用了 `--skip-sprockets` 选项，Rails 都会创建 `app/assets/javascripts/application.js` 和 `app/assets/stylesheets/application.css` 文件。因此，之后想要使用 Asset Pipeline 非常容易。

我们在 JavaScript 文件中使用的指令同样可以在 CSS 文件中使用，此时加载的是 CSS 文件而不是 JavaScript 文件。在 CSS 清单文件中，`require_tree` 指令的工作原理和在 JavaScript 清单文件中相同，会加载指定文件夹中的所有 CSS 文件。

上述代码中使用了 `require_self` 指令，用于把当前文件中的 CSS 代码（如果存在）插入调用这个指令的位置。

NOTE: 要想使用多个 Sass 文件，通常应该使用 [Sass @import 规则](http://sass-lang.com/docs/yardoc/file.SASS_REFERENCE.html#import)，而不是 Sprockets 指令。如果使用 Sprockets 指令，这些 Sass 文件将拥有各自的作用域，这样变量和混入只能在定义它们的文件中使用。

和使用 `require_tree` 指令相比，使用 `@import "*"` 和 `@import "**/*"` 的效果完全相同，都能加载指定文件夹中的所有文件。更多介绍和注意事项请参阅 [sass-rails 文档](https://github.com/rails/sass-rails#features)。

我们可以根据需要使用多个清单文件。例如，可以用 `admin.js` 和 `admin.css` 清单文件分别包含应用管理后台的 JS 和 CSS 文件。

CSS 清单文件中指令的执行顺序类似于前文介绍的 JavaScript 清单文件，尤其是加载的文件都会按照指定顺序依次编译。例如，我们可以像下面这样把 3 个 CSS 文件连接在一起：

```css
/* ...
*= require reset
*= require layout
*= require chrome
*/
```

<a class="anchor" id="preprocessing"></a>

### 预处理

静态资源文件的扩展名决定了预处理的方式。在使用默认的 Rails gemset 生成控制器或脚手架时，会生成 CoffeeScript 和 SCSS 文件，而不是普通的 JavaScript 和 CSS 文件。在前文的例子中，生成 `projects` 控制器时会生成 `app/assets/javascripts/projects.coffee` 和 `app/assets/stylesheets/projects.scss` 文件。

在开发环境中，或 Asset Pipeline 被禁用时，会使用 `coffee-script` 和 `sass` gem 提供的处理器分别处理相应的文件请求，并把生成的 JavaScript 和 CSS 文件发给浏览器。当 Asset Pipeline 可用时，会对这些文件进行预处理，然后储存在 `public/assets` 文件夹中，由 Rails 应用或 Web 服务器处理。

通过添加其他扩展名，可以对文件进行更多预处理。对扩展名的解析顺序是从右到左，相应的预处理顺序也是从右到左。例如，对于 `app/assets/stylesheets/projects.scss.erb` 文件，会先处理 ERB，再处理 SCSS，最后作为 CSS 文件处理。同样，对于 `app/assets/javascripts/projects.coffee.erb` 文件，会先处理 ERB，再处理 CoffeeScript，最后作为 JavaScript 文件处理。

记住预处理顺序很重要。例如，如果我们把文件名写为 `app/assets/javascripts/projects.erb.coffee`，就会先处理 CoffeeScript，这时一旦遇到 ERB 代码就会出错。

<a class="anchor" id="in-development"></a>

## 在开发环境中

在开发环境中，Asset Pipeline 会按照清单文件中指定的顺序处理静态资源文件。

对于清单文件 `app/assets/javascripts/application.js`：

```javascript
//= require core
//= require projects
//= require tickets
```

会生成下面的 HTML：

```html
<script src="/assets/core.js?body=1"></script>
<script src="/assets/projects.js?body=1"></script>
<script src="/assets/tickets.js?body=1"></script>
```

其中 `body` 参数是使用 Sprockets 时必须使用的参数。

<a class="anchor" id="runtime-error-checking"></a>

### 检查运行时错误

在生产环境中，Asset Pipeline 默认会在运行时检查潜在错误。要想禁用此行为，可以设置：

```ruby
config.assets.raise_runtime_errors = false
```

当此选项设置为 `true` 时，Asset Pipeline 会检查应用中加载的所有静态资源文件是否都已包含在 `config.assets.precompile` 列表中。如果此时 `config.assets.digest` 也设置为 `true`，Asset Pipeline 会要求所有对静态资源文件的请求都包含指纹（digest）。

<a class="anchor" id="raise-an-error-when-an-asset-is-not-found"></a>

### 找不到静态资源时抛出错误

如果使用的 sprockets-rails 是 3.2.0 或以上版本，可以配置找不到静态资源时的行为。如果禁用了“静态资源后备机制”，找不到静态资源时抛出错误。

```ruby
config.assets.unknown_asset_fallback = false
```

如果启用了“静态资源后备机制”，找不到静态资源时，输出路径，而不抛出错误。静态资源后备机制默认启用。

<a class="anchor" id="turning-digests-off"></a>

### 关闭指纹

通过修改 `config/environments/development.rb` 配置文件，我们可以关闭指纹：

```ruby
config.assets.digest = false
```

当此选项设置为 `true` 时，Rails 会为静态资源文件的 URL 生成指纹。

<a class="anchor" id="turning-debugging-off"></a>

### 关闭调试

通过修改 `config/environments/development.rb` 配置文件，我们可以关闭调式模式：

```ruby
config.assets.debug = false
```

当调试模式关闭时，Sprockets 会对所有文件进行必要的预处理，然后把它们连接起来。此时，前文的清单文件会生成下面的 HTML：

```html
<script src="/assets/application.js"></script>
```

当服务器启动后，静态资源文件将在第一次请求时进行编译和缓存。Sprockets 通过设置 `must-revalidate Cache-Control` HTTP 首部，来减少后续请求造成的开销，此时对于后续请求浏览器会得到 304（未修改）响应。

如果清单文件中的某个文件在两次请求之间发生了变化，服务器会使用新编译的文件作为响应。

还可以通过 Rails 辅助方法启用调试模式：

```erb
<%= stylesheet_link_tag "application", debug: true %>
<%= javascript_include_tag "application", debug: true %>
```

当然，如果已经启用了调式模式，再使用 `:debug` 选项就完全是多余的了。

在开发模式中，我们也可以启用压缩功能以检查其工作是否正常，在需要进行调试时再禁用压缩功能。

<a class="anchor" id="in-production"></a>

## 在生产环境中

在生产环境中，Sprockets 会使用前文介绍的指纹机制。默认情况下，Rails 假定静态资源文件都经过了预编译，并将由 Web 服务器处理。

在预编译阶段，Sprockets 会根据静态资源文件的内容生成 SHA256 哈希值，并在保存文件时把这个哈希值添加到文件名中。Rails 辅助方法会用这些包含指纹的文件名代替清单文件中的文件名。

例如，下面的代码：

```erb
<%= javascript_include_tag "application" %>
<%= stylesheet_link_tag "application" %>
```

会生成下面的 HTML：

```html
<script src="/assets/application-908e25f4bf641868d8683022a5b62f54.js"></script>
<link href="/assets/application-4dd5b109ee3439da54f5bdfd78a80473.css" media="screen"
rel="stylesheet" />
```

NOTE: Rails 开始使用 Asset Pipeline 后，不再使用 `:cache` 和 `:concat` 选项，因此在调用 `javascript_include_tag` 和 `stylesheet_link_tag` 辅助方法时需要删除这些选项。

可以通过 `config.assets.digest` 初始化选项（默认为 `true`）启用或禁用指纹功能。

NOTE: 在正常情况下，请不要修改默认的 `config.assets.digest` 选项（默认为 `true`）。如果文件名中未包含指纹，并且 HTTP 头信息的过期时间设置为很久以后，远程客户端将无法在文件内容发生变化时重新获取文件。

<a class="anchor" id="precompiling-assets"></a>

### 预编译静态资源文件

Rails 提供了一个 Rake 任务，用于编译 Asset Pipeline 清单文件中的静态资源文件和其他相关文件。

经过编译的静态资源文件将储存在 `config.assets.prefix` 选项指定的路径中，默认为 `/assets` 文件夹。

部署 Rails 应用时可以在服务器上执行这个 Rake 任务，以便直接在服务器上完成静态资源文件的编译。关于本地编译的介绍，请参阅下一节。

这个 Rake 任务是：

```sh
$ RAILS_ENV=production bin/rails assets:precompile
```

Capistrano（v2.15.1 及更高版本）提供了对这个 Rake 任务的支持。只需把下面这行代码添加到 `Capfile` 中：

```ruby
load 'deploy/assets'
```

就会把 `config.assets.prefix` 选项指定的文件夹链接到 `shared/assets` 文件夹。当然，如果 `shared/assets` 文件夹已经用于其他用途，我们就得自己编写部署任务了。

需要注意的是，`shared/assets` 文件夹会在多次部署之间共享，这样引用了这些静态资源文件的远程客户端的缓存页面在其生命周期中就能正常工作。

编译文件时的默认匹配器（matcher）包括 `application.js`、`application.css`，以及 `app/assets` 文件夹和 gem 中的所有非 JS/CSS 文件（会自动包含所有图像）：

```ruby
[ Proc.new { |filename, path| path =~ /app\/assets/ && !%w(.js .css).include?(File.extname(filename)) },
/application.(css|js)$/ ]
```

NOTE: 这个匹配器（及预编译数组的其他成员；见后文）会匹配编译后的文件名，这意味着无论是 JS/CSS 文件，还是能够编译为 JS/CSS 的文件，都将被排除在外。例如，`.coffee` 和 `.scss` 文件能够编译为 JS/CSS，因此被排除在默认的编译范围之外。

要想包含其他清单文件，或单独的 JavaScript 和 CSS 文件，可以把它们添加到 `config/initializers/assets.rb` 配置文件的 `precompile` 数组中：

```ruby
Rails.application.config.assets.precompile += %w( admin.js admin.css )
```

NOTE: 添加到 `precompile` 数组的文件名应该以 `.js` 或 `.css` 结尾，即便实际添加的是 CoffeeScript 或 Sass 文件也是如此。

`assets:precompile` 这个 Rake 任务还会成生 `.sprockets-manifest-md5hash.json` 文件（其中 `md5hash` 是一个 MD5 哈希值），其内容是所有静态资源文件及其指纹的列表。有了这个文件，Rails 辅助方法不需要 Sprockets 就能获得静态资源文件对应的指纹。下面是一个典型的 `.sprockets-manifest-md5hash.json` 文件的例子：

```json
{"files":{"application-aee4be71f1288037ae78b997df388332edfd246471b533dcedaa8f9fe156442b.js":{"logical_path":"application.js","mtime":"2016-12-23T20:12:03-05:00","size":412383,
"digest":"aee4be71f1288037ae78b997df388332edfd246471b533dcedaa8f9fe156442b","integrity":"sha256-ruS+cfEogDeueLmX3ziDMu39JGRxtTPc7aqPn+FWRCs="},
"application-86a292b5070793c37e2c0e5f39f73bb387644eaeada7f96e6fc040a028b16c18.css":{"logical_path":"application.css","mtime":"2016-12-23T19:12:20-05:00","size":2994,
"digest":"86a292b5070793c37e2c0e5f39f73bb387644eaeada7f96e6fc040a028b16c18","integrity":"sha256-hqKStQcHk8N+LA5fOfc7s4dkTq6tp/lub8BAoCixbBg="},
"favicon-8d2387b8d4d32cecd93fa3900df0e9ff89d01aacd84f50e780c17c9f6b3d0eda.ico":{"logical_path":"favicon.ico","mtime":"2016-12-23T20:11:00-05:00","size":8629,
"digest":"8d2387b8d4d32cecd93fa3900df0e9ff89d01aacd84f50e780c17c9f6b3d0eda","integrity":"sha256-jSOHuNTTLOzZP6OQDfDp/4nQGqzYT1DngMF8n2s9Dto="},
"my_image-f4028156fd7eca03584d5f2fc0470df1e0dbc7369eaae638b2ff033f988ec493.png":{"logical_path":"my_image.png","mtime":"2016-12-23T20:10:54-05:00","size":23414,
"digest":"f4028156fd7eca03584d5f2fc0470df1e0dbc7369eaae638b2ff033f988ec493","integrity":"sha256-9AKBVv1+ygNYTV8vwEcN8eDbxzaequY4sv8DP5iOxJM="}},
"assets":{"application.js":"application-aee4be71f1288037ae78b997df388332edfd246471b533dcedaa8f9fe156442b.js",
"application.css":"application-86a292b5070793c37e2c0e5f39f73bb387644eaeada7f96e6fc040a028b16c18.css",
"favicon.ico":"favicon-8d2387b8d4d32cecd93fa3900df0e9ff89d01aacd84f50e780c17c9f6b3d0eda.ico",
"my_image.png":"my_image-f4028156fd7eca03584d5f2fc0470df1e0dbc7369eaae638b2ff033f988ec493.png"}}
```

`.sprockets-manifest-md5hash.json` 文件默认位于 `config.assets.prefix` 选项所指定的位置的根目录（默认为 `/assets` 文件夹）。

NOTE: 在生产环境中，如果有些预编译后的文件丢失了，Rails 就会抛出 `Sprockets::Helpers::RailsHelper::AssetPaths::AssetNotPrecompiledError` 异常，提示所丢失文件的文件名。

<a class="anchor" id="far-future-expires-header"></a>

#### 在 HTTP 首部中设置为很久以后才过期

预编译后的静态资源文件储存在文件系统中，并由 Web 服务器直接处理。默认情况下，这些文件的 HTTP 首部并不会在很久以后才过期，为了充分发挥指纹的作用，我们需要修改服务器配置中的请求头过期时间。

对于 Apache：

```apache
# 在启用 Apache 模块 `mod_expires` 的情况下，才能使用
# Expires* 系列指令。
<Location /assets/>
  # 在使用 Last-Modified 的情况下，不推荐使用 ETag
  Header unset ETag
  FileETag None
  # RFC 规定缓存时间为 1 年
  ExpiresActive On
  ExpiresDefault "access plus 1 year"
</Location>
```

对于 Nginx：

```nginx
location ~ ^/assets/ {
  expires 1y;
  add_header Cache-Control public;

  add_header ETag "";
}
```

<a class="anchor" id="local-precompilation"></a>

### 本地预编译

在本地预编译静态资源文件的理由如下：

*   可能没有生产环境服务器文件系统的写入权限；
*   可能需要部署到多台服务器，不想重复编译；
*   部署可能很频繁，但静态资源文件很少变化。

本地编译允许我们把编译后的静态资源文件纳入源代码版本控制，并按常规方式部署。

有三个注意事项：

*   不要运行用于预编译静态资源文件的 Capistrano 部署任务；
*   开发环境中必须安装压缩或简化静态资源文件所需的工具；
*   必须修改下面这个设置：

在 `config/environments/development.rb` 配置文件中添加下面这行代码：

```ruby
config.assets.prefix = "/dev-assets"
```

在开发环境中，通过修改 `prefix`，可以让 Sprockets 使用不同的 URL 处理静态资源文件，并把所有请求都交给 Sprockets 处理。在生产环境中，`prefix` 仍然应该设置为 `/assets`。在开发环境中，如果不修改 `prefix`，应用就会优先读取 `/assets` 文件夹中预编译后的静态资源文件，这样对静态资源文件进行修改后，除非重新编译，否则看不到任何效果。

实际上，通过修改 `prefix`，我们可以在本地预编译静态资源文件，并把这些文件储存在工作目录中，同时可以根据需要随时将其纳入源代码版本控制。开发模式将按我们的预期正常工作。

<a class="anchor" id="live-compilation"></a>

### 实时编译

在某些情况下，我们需要使用实时编译。在实时编译模式下，Asset Pipeline 中的所有静态资源文件都由 Sprockets 直接处理。

通过如下设置可以启用实时编译：

```ruby
config.assets.compile = true
```

如前文所述，静态资源文件会在首次请求时被编译和缓存，辅助方法会把清单文件中的文件名转换为带 SHA256 哈希值的版本。

Sprockets 还会把 `Cache-Control` HTTP 首部设置为 `max-age=31536000`，意思是服务器和客户端浏览器的所有缓存的过期时间是 1 年。这样在本地浏览器缓存或中间缓存中找到所需静态资源文件的可能性会大大增加，从而减少从服务器上获取静态资源文件的请求次数。

但是实时编译模式会使用更多内存，性能也比默认设置更差，因此并不推荐使用。

如果部署应用的生产服务器没有预装 JavaScript 运行时，可以在 Gemfile 中添加一个：

```ruby
group :production do
  gem 'therubyracer'
end
```

<a class="anchor" id="cdns"></a>

### CDN

CDN 的意思是[内容分发网络](http://en.wikipedia.org/wiki/Content_delivery_network)，主要用于缓存全世界的静态资源文件。当 Web 浏览器请求静态资源文件时，CDN 会从地理位置最近的 CDN 服务器上发送缓存的文件副本。如果我们在生产环境中让 Rails 直接处理静态资源文件，那么在应用前端使用 CDN 将是最好的选择。

使用 CDN 的常见模式是把生产环境中的应用设置为“源”服务器，也就是说，当浏览器从 CDN 请求静态资源文件但缓存未命中时，CDN 将立即从“源”服务器中抓取该文件，并对其进行缓存。例如，假设我们在 `example.com` 上运行 Rails 应用，并在 `mycdnsubdomain.fictional-cdn.com` 上配置了 CDN，在处理对 `mycdnsubdomain.fictional-cdn.com/assets/smile.png` 的首次请求时，CDN 会抓取 `example.com/assets/smile.png` 并进行缓存。之后再请求 `mycdnsubdomain.fictional-cdn.com/assets/smile.png` 时，CDN 会直接提供缓存中的文件副本。对于任何请求，只要 CDN 能够直接处理，就不会访问 Rails 服务器。由于 CDN 提供的静态资源文件由地理位置最近的 CDN 服务器提供，因此对请求的响应更快，同时 Rails 服务器不再需要花费大量时间处理静态资源文件，因此可以专注于更快地处理应用代码。

<a class="anchor" id="set-up-a-cdn-to-serve-static-assets"></a>

#### 设置用于处理静态资源文件的 CDN

要设置 CDN，首先必须在公开的互联网 URL 地址上（例如 `example.com`）以生产环境运行 Rails 应用。下一步，注册云服务提供商的 CDN 服务。然后配置 CDN 的“源”服务器，把它指向我们的网站 `example.com`，具体配置方法请参考云服务提供商的文档。

CDN 提供商会为我们的应用提供一个自定义子域名，例如 `mycdnsubdomain.fictional-cdn.com`（注意 `fictional-cdn.com` 只是撰写本文时杜撰的一个 CDN 提供商）。完成 CDN 服务器配置后，还需要告诉浏览器从 CDN 抓取静态资源文件，而不是直接从 Rails 服务器抓取。为此，需要在 Rails 配置中，用静态资源文件的主机代替相对路径。通过 `config/environments/production.rb` 配置文件的 `config.action_controller.asset_host` 选项，我们可以设置静态资源文件的主机：

```ruby
config.action_controller.asset_host = 'mycdnsubdomain.fictional-cdn.com'
```

NOTE: 这里只需提供“主机”，即前文提到的子域名，而不需要指定 HTTP 协议，例如 `http://` 或 `https://`。默认情况下，Rails 会使用网页请求的 HTTP 协议作为指向静态资源文件链接的协议。

还可以通过[环境变量](http://en.wikipedia.org/wiki/Environment_variable)设置静态资源文件的主机，这样可以方便地在不同的运行环境中使用不同的静态资源文件：

```ruby
config.action_controller.asset_host = ENV['CDN_HOST']
```

NOTE: 这里还需要把服务器上的 `CDN_HOST` 环境变量设置为 `mycdnsubdomain.fictional-cdn.com`。

服务器和 CDN 配置好后，就可以像下面这样引用静态资源文件：

```erb
<%= asset_path('smile.png') %>
```

这时返回的不再是相对路径 `/assets/smile.png`（出于可读性考虑省略了文件名中的指纹），而是指向 CDN 的完整路径：

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile.png
```

如果 CDN 上有 `smile.png` 文件的副本，就会直接返回给浏览器，而 Rails 服务器甚至不知道有浏览器请求了 `smile.png` 文件。如果 CDN 上没有 `smile.png` 文件的副本，就会先从“源”服务器上抓取 `example.com/assets/smile.png` 文件，再返回给浏览器，同时保存文件的副本以备将来使用。

如果只想让 CDN 处理部分静态资源文件，可以在调用静态资源文件辅助方法时使用 `:host` 选项，以覆盖 `config.action_controller.asset_host` 选项中设置的值：

```erb
<%= asset_path 'image.png', host: 'mycdnsubdomain.fictional-cdn.com' %>
```

<a class="anchor" id="customize-cdn-caching-behavior"></a>

#### 自定义 CDN 缓存行为

CDN 的作用是为内容提供缓存。如果 CDN 上有过期或不良内容，那么不仅不能对应用有所助益，反而会造成负面影响。本小节将介绍大多数 CDN 的一般缓存行为，而我们使用的 CDN 在特性上可能会略有不同。

<a class="anchor" id="cdn-request-caching"></a>

##### CDN 请求缓存

我们常说 CDN 对于缓存静态资源文件非常有用，但实际上 CDN 缓存的是整个请求。其中既包括了静态资源文件的请求体，也包括了其首部。其中，`Cache-Control` 首部是最重要的，用于告知 CDN（和 Web 浏览器）如何缓存文件内容。假设用户请求了 `/assets/i-dont-exist.png` 这个并不存在的静态资源文件，并且 Rails 应用返回的是 404，那么只要设置了合法的 `Cache-Control` 首部，CDN 就会缓存 404 页面。

<a class="anchor" id="cdn-header-debugging"></a>

##### 调试 CDN 首部

检查 CDN 是否正确缓存了首部的方法之一是使用 [curl](http://explainshell.com/explain?cmd=curl+-I+http%3A%2F%2Fwww.example.com)。我们可以分别从 Rails 服务器和 CDN 获取首部，然后确认二者是否相同：

```sh
$ curl -I http://www.example/assets/application-
d0e099e021c95eb0de3615fd1d8c4d83.css
HTTP/1.1 200 OK
Server: Cowboy
Date: Sun, 24 Aug 2014 20:27:50 GMT
Connection: keep-alive
Last-Modified: Thu, 08 May 2014 01:24:14 GMT
Content-Type: text/css
Cache-Control: public, max-age=2592000
Content-Length: 126560
Via: 1.1 vegur
```

CDN 中副本的首部：

```sh
$ curl -I http://mycdnsubdomain.fictional-cdn.com/application-
d0e099e021c95eb0de3615fd1d8c4d83.css
HTTP/1.1 200 OK Server: Cowboy Last-
Modified: Thu, 08 May 2014 01:24:14 GMT Content-Type: text/css
Cache-Control:
public, max-age=2592000
Via: 1.1 vegur
Content-Length: 126560
Accept-Ranges:
bytes
Date: Sun, 24 Aug 2014 20:28:45 GMT
Via: 1.1 varnish
Age: 885814
Connection: keep-alive
X-Served-By: cache-dfw1828-DFW
X-Cache: HIT
X-Cache-Hits:
68
X-Timer: S1408912125.211638212,VS0,VE0
```

在 CDN 文档中可以查询 CDN 提供的额外首部，例如 `X-Cache`。

<a class="anchor" id="cdns-and-the-cache-control-header"></a>

##### CDN 和 `Cache-Control` 首部

[Cache-Control 首部](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9)是一个 W3C 规范，用于描述如何缓存请求。当未使用 CDN 时，浏览器会根据 `Cache-Control` 首部来缓存文件内容。在静态资源文件未修改的情况下，浏览器就不必重新下载 CSS 或 JavaScript 等文件了。通常，Rails 服务器需要告诉 CDN（和浏览器）这些静态资源文件是“公共的”，这样任何缓存都可以保存这些文件的副本。此外，通常还会通过 `max-age` 字段来设置缓存失效前储存对象的时间。`max-age` 字段的单位是秒，最大设置为 31536000，即一年。在 Rails 应用中设置 `Cache-Control` 首部的方法如下：

```ruby
config.public_file_server.headers = {
  'Cache-Control' => 'public, max-age=31536000'
}
```

现在，在生产环境中，Rails 应用的静态资源文件在 CDN 上会被缓存长达 1 年之久。由于大多数 CDN 会缓存首部，静态资源文件的 `Cache-Control` 首部会被传递给请求该静态资源文件的所有浏览器，这样浏览器就会长期缓存该静态资源文件，直到缓存过期后才会重新请求该文件。

<a class="anchor" id="cdns-and-url-based-cache-invalidation"></a>

##### CDN 和基于 URL 地址的缓存失效

大多数 CDN 会根据完整的 URL 地址来缓存静态资源文件的内容。因此，缓存

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile-123.png
```

和缓存

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile.png
```

被认为是两个完全不同的静态资源文件的缓存。

如果我们把 `Cache-Control` HTTP 首部的 `max-age` 值设得很大，那么当静态资源文件的内容发生变化时，应同时使原有缓存失效。例如，当我们把黄色笑脸图像更换为蓝色笑脸图像时，我们希望网站的所有访客看到的都是新的蓝色笑脸图像。如果我们使用了 CDN，并使用了 Rails Asset Pipeline `config.assets.digest` 选项的默认值 `true`，一旦静态资源文件的内容发生变化，其文件名就会发生变化。这样，我们就不需要每次手动使某个静态资源文件的缓存失效。通过使用唯一的新文件名，我们就能确保用户访问的总是静态资源文件的最新版本。

<a class="anchor" id="customizing-the-pipeline"></a>

## 自定义 Asset Pipeline

<a class="anchor" id="css-compression"></a>

### 压缩 CSS

压缩 CSS 的可选方式之一是使用 YUI。通过 [YUI CSS 压缩器](http://yui.github.io/yuicompressor/css.html)可以缩小 CSS 文件的大小。

在 Gemfile 中添加 `yui-compressor` gem 后，通过下面的设置可以启用 YUI 压缩：

```ruby
config.assets.css_compressor = :yui
```

如果我们在 Gemfile 中添加了 `sass-rails` gem，那么也可以使用 Sass 压缩：

```ruby
config.assets.css_compressor = :sass
```

<a class="anchor" id="javascript-compression"></a>

### 压缩 JavaScript

压缩 JavaScript 的可选方式有 `:closure`、`:uglifier` 和 `:yui`，分别要求在 Gemfile 中添加 `closure-compiler`、`uglifier` 和 `yui-compressor` gem。

默认情况下，Gemfile 中包含了 [uglifier](https://github.com/lautis/uglifier) gem，这个 gem 使用 Ruby 包装 [UglifyJS](https://github.com/mishoo/UglifyJS)（使用 NodeJS 开发），作用是通过删除空白和注释、缩短局部变量名及其他微小优化（例如在可能的情况下把 `if...else` 语句修改为三元运算符）压缩 JavaScript 代码。

使用 `uglifier` 压缩 JavaScript 需进行如下设置：

```ruby
config.assets.js_compressor = :uglifier
```

NOTE: 要使用 `uglifier` 压缩 JavaScript，就必须安装支持 [ExecJS](https://github.com/rails/execjs#readme) 的运行时。macOS 和 Windows 已经预装了此类运行时。

<a class="anchor" id="serving-gzipped-version-of-assets"></a>

### 用 GZip 压缩静态资源文件

默认情况下，Sprockets 会用 GZip 压缩编译后的静态资源文件，同时也会保留未压缩的版本。通过 GZip 压缩可以减少对带宽的占用。设置 GZip 压缩的方式如下：

```ruby
config.assets.gzip = false # 禁止用 GZip 压缩静态资源文件
```

<a class="anchor" id="using-your-own-compressor"></a>

### 自定义压缩工具

在设置 CSS 和 JavaScript 压缩工具时还可以使用对象。这个对象要能响应 `compress` 方法，这个方法接受一个字符串作为唯一参数，并返回一个字符串。

```ruby
class Transformer
  def compress(string)
    do_something_returning_a_string(string)
  end
end
```

要使用这个压缩工具，需在 `application.rb` 配置文件中做如下设置：

```ruby
config.assets.css_compressor = Transformer.new
```

<a class="anchor" id="changing-the-assets-path"></a>

### 修改静态资源文件的路径

默认情况下，Sprockets 使用 `/assets` 作为静态资源文件的公开路径。

我们可以修改这个路径：

```ruby
config.assets.prefix = "/some_other_path"
```

通过这种方式，在升级未使用 Asset Pipeline 但使用了 `/assets` 路径的老项目时，我们就可以轻松为新的静态资源文件设置另一个公开路径。

<a class="anchor" id="x-sendfile-headers"></a>

### `X-Sendfile` 首部

`X-Sendfile` 首部的作用是让 Web 服务器忽略应用对请求的响应，直接返回磁盘中的指定文件。默认情况下 Rails 不会发送这个首部，但在支持这个首部的服务器上可以启用这一特性，以提供更快的响应速度。关于这一特性的更多介绍，请参阅 [`send_file` 方法的文档](http://api.rubyonrails.org/classes/ActionController/DataStreaming.html#method-i-send_file)。

Apache 和 NGINX 支持 `X-Sendfile` 首部，启用方法是在 `config/environments/production.rb` 配置文件中进行设置：

```ruby
# config.action_dispatch.x_sendfile_header = "X-Sendfile" # 用于 Apache
# config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # 用于 NGINX
```

WARNING: 要想在升级现有应用时使用上述选项，可以把这两行代码粘贴到 `production.rb` 配置文件中，或其他类似的生产环境配置文件中。

TIP: 更多介绍请参阅生产服务器的相关文档：[Apache](https://tn123.org/mod_xsendfile/)、[NGINX](http://wiki.nginx.org/XSendfile)。

<a class="anchor" id="assets-cache-store"></a>

## 静态资源文件缓存的存储方式

在开发环境和生产环境中，Sprockets 默认在 `tmp/cache/assets` 文件夹中缓存静态资源文件。修改这一设置的方式如下：

```ruby
config.assets.configure do |env|
  env.cache = ActiveSupport::Cache.lookup_store(:memory_store,
                                                { size: 32.megabytes })
end
```

禁用静态资源文件缓存的方式如下：

```ruby
config.assets.configure do |env|
  env.cache = ActiveSupport::Cache.lookup_store(:null_store)
end
```

<a class="anchor" id="adding-assets-to-your-gems"></a>

## 通过 gem 添加静态资源文件

我们还可以通过 gem 添加静态资源文件。

为 Rails 提供标准 JavaScript 库的 `jquery-rails` gem 就是很好的例子。这个 gem 中包含了继承自 `Rails::Engine` 类的引擎类，这样 Rails 就知道这个 gem 中可能包含静态资源文件，于是会把其中的 `app/assets`、`lib/assets` 和 `vendor/assets` 文件夹添加到 Sprockets 的搜索路径中。

<a class="anchor" id="making-your-library-or-gem-a-pre-processor"></a>

## 使用代码库或 gem 作为预处理器

Sprockets 使用 Processors、Transformers、Compressors 和 Exporters 扩展功能。详情参阅“[Extending Sprockets](https://github.com/rails/sprockets/blob/master/guides/extending_sprockets.md)”一文。下述示例注册一个预处理器，在 text/css 文件（.css）默认添加一个注释。

```ruby
module AddComment
  def self.call(input)
    { data: input[:data] + "/* Hello From my sprockets extension */" }
  end
end
```

有了修改输入数据的模块后，还要把它注册为指定 MIME 类型的预处理器：

```ruby
Sprockets.register_preprocessor 'text/css', AddComment
```

<a class="anchor" id="upgrading-from-old-versions-of-rails"></a>

## 从旧版本的 Rails 升级

从 Rails 3.0 或 Rails 2.x 升级时有一些问题需要解决。首先，要把 `public/` 文件夹中的文件移动到新位置。关于不同类型文件储存位置的介绍，请参阅 [静态资源文件的组织方式](#asset-organization)。

其次，要避免出现重复的 JavaScript 文件。从 Rails 3.1 开始，jQuery 成为默认的 JavaScript 库，Rails 会自动加载 `jquery.js`，不再需要手动把 `jquery.js` 复制到 `app/assets` 文件夹中。

再次，要使用正确的默认选项更新各种环境配置文件。

在 `application.rb` 配置文件中：

```ruby
# 静态资源文件的版本，通过修改这个选项可以使原有的静态资源文件缓存全部过期
config.assets.version = '1.0'

# 通过 onfig.assets.prefix = "/assets" 修改静态资源文件的路径
```

在 `development.rb` 配置文件中：

```ruby
# 展开用于加载静态资源文件的代码
config.assets.debug = true
```

在 `production.rb` 配置文件中：

```ruby
# 选择（可用的）压缩工具
config.assets.js_compressor = :uglifier
# config.assets.css_compressor = :yui

# 在找不到已编译的静态资源文件的情况下，不退回到 Asset Pipeline
config.assets.compile = false

# 为静态资源文件的 URL 地址生成指纹
config.assets.digest = true

# 预编译附加的静态资源文件（application.js、application.css 和所有
# 已添加的非 JS/CSS 文件）
# config.assets.precompile += %w( admin.js admin.css )
```

Rails 4 及更高版本不会再在 `test.rb` 配置文件中添加 Sprockets 的默认设置，因此需要手动完成。需要添加的默认设置包括 `config.assets.compile = true`、`config.assets.compress = false`、`config.assets.debug = false` 和 `config.assets.digest = false`。

最后，还要在 Gemfile 中加入下列 gem：

```ruby
gem 'sass-rails',   "~> 3.2.3"
gem 'coffee-rails', "~> 3.2.1"
gem 'uglifier'
```
