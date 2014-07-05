Asset Pipeline
==============

本文介绍 Asset Pipeline。

读完后，你将学会：

* Asset Pipeline 是什么以及其作用；
* 如何合理组织程序的静态资源；
* Asset Pipeline 的优势；
* 如何向 Asset Pipeline 中添加预处理器；
* 如何在 gem 中打包静态资源；

--------------------------------------------------------------------------------

Asset Pipeline 是什么？
---------------------

Asset Pipeline 提供了一个框架，用于连接、压缩 JavaScript 和 CSS 文件。还允许使用其他语言和预处理器编写 JavaScript 和 CSS，例如 CoffeeScript、Sass 和 ERB。

严格来说，Asset Pipeline 不是 Rails 4 的核心功能，已经从框架中提取出来，制成了 [sprockets-rails](https://github.com/rails/sprockets-rails) gem。

Asset Pipeline 功能默认是启用的。

新建程序时如果想禁用 Asset Pipeline，可以在命令行中指定 `--skip-sprockets` 选项。

```bash
rails new appname --skip-sprockets
```

Rails 4 会自动把 `sass-rails`、`coffee-rails` 和 `uglifier` 三个 gem 加入 `Gemfile`。Sprockets 使用这三个 gem 压缩静态资源：

```ruby
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'
```

指定 `--skip-sprockets` 命令行选项后，Rails 4 不会把 `sass-rails` 和 `uglifier` 加入 `Gemfile`。如果后续需要使用 Asset Pipeline，需要手动添加这些 gem。而且，指定 `--skip-sprockets` 命令行选项后，生成的 `config/application.rb` 文件也会有点不同，把加载 `sprockets/railtie` 的代码注释掉了。如果后续启用 Asset Pipeline，要把这行前面的注释去掉：

```ruby
# require "sprockets/railtie"
```

`production.rb` 文件中有相应的选项设置静态资源的压缩方式：`config.assets.css_compressor` 针对 CSS，`config.assets.js_compressor` 针对 Javascript。

```ruby
config.assets.css_compressor = :yui
config.assets.js_compressor = :uglify
```

NOTE: 如果 `Gemfile` 中有 `sass-rails`，就会自动用来压缩 CSS，无需设置 `config.assets.css_compressor` 选项。

### 主要功能

Asset Pipeline 的第一个功能是连接静态资源，减少渲染页面时浏览器发起的请求数。浏览器对并行的请求数量有限制，所以较少的请求数可以提升程序的加载速度。

Sprockets 会把所有 JavaScript 文件合并到一个主 `.js` 文件中，把所有 CSS 文件合并到一个主 `.css` 文件中。后文会介绍，合并的方式可按需求随意定制。在生产环境中，Rails 会在文件名后加上 MD5 指纹，以便浏览器缓存，指纹变了缓存就会过期。修改文件的内容后，指纹会自动变化。

Asset Pipeline 的第二个功能是压缩静态资源。对 CSS 文件来说，会删除空白和注释。对 JavaScript 来说，可以做更复杂的处理。处理方式可以从内建的选项中选择，也可使用定制的处理程序。

Asset Pipeline 的第三个功能是允许使用高级语言编写静态资源，再使用预处理器转换成真正的静态资源。默认支持的高级语言有：用来编写 CSS 的 Sass，用来编写 JavaScript 的 CoffeeScript，以及 ERB。

### 指纹是什么，我为什么要关心它？

指纹可以根据文件内容生成文件名。文件内容变化后，文件名也会改变。对于静态内容，或者很少改动的内容，在不同的服务器之间，不同的部署日期之间，使用指纹可以区别文件的两个版本内容是否一样。

如果文件名基于内容而定，而且文件名是唯一的，HTTP 报头会建议在所有可能的地方（CDN，ISP，网络设备，网页浏览器）存储一份该文件的副本。修改文件内容后，指纹会发生变化，因此远程客户端会重新请求文件。这种技术叫做“缓存爆裂”（cache busting）。

Sprockets 使用指纹的方式是在文件名中加入内容的哈希值，一般加在文件名的末尾。例如，`global.css` 加入指纹后的文件名如下：

```
global-908e25f4bf641868d8683022a5b62f54.css
```

Asset Pipeline 使用的就是这种指纹实现方式。

以前，Rails 使用内建的帮助方法，在文件名后加上一个基于日期生成的请求字符串，如下所示：

```
/stylesheets/global.css?1309495796
```

使用请求字符串有很多缺点：

1.  **文件名只是请求字符串不同时，缓存并不可靠**<br>
    [Steve Souders 建议](http://www.stevesouders.com/blog/2008/08/23/revving-filenames-dont-use-querystring/)：不在要缓存的资源上使用请求字符串。他发现，使用请求字符串的文件不被缓存的可能性有 5-20%。有些 CDN 验证缓存时根本无法识别请求字符串。

2.  **在多服务器环境中，不同节点上的文件名可能不同**<br>
    在 Rails 2.x 中，默认的请求字符串由文件的修改时间生成。静态资源文件部署到集群后，无法保证时间戳都是一样的，得到的值取决于使用哪台服务器处理请求。

3.  **缓存验证失败过多**<br>
    部署新版代码时，所有静态资源文件的最后修改时间都变了。即便内容没变，客户端也要重新请求这些文件。

使用指纹就无需再用请求字符串了，而且文件名基于文件内容，始终保持一致。

默认情况下，指纹只在生产环境中启用，其他环境都被禁用。可以设置 `config.assets.digest` 选项启用或禁用。

扩展阅读：

* [Optimize caching](http://code.google.com/speed/page-speed/docs/caching.html)
* [Revving Filenames: don't use querystring](http://www.stevesouders.com/blog/2008/08/23/revving-filenames-dont-use-querystring/)

如何使用 Asset Pipeline
----------------------

在以前的 Rails 版本中，所有静态资源都放在 `public` 文件夹的子文件夹中，例如  `images`、`javascripts` 和 `stylesheets`。使用 Asset Pipeline 后，建议把静态资源放在 `app/assets` 文件夹中。这个文件夹中的文件会经由 Sprockets 中间件处理。

静态资源仍然可以放在 `public` 文件夹中，其中所有文件都会被程序或网页服务器视为静态文件。如果文件要经过预处理器处理，就得放在 `app/assets` 文件夹中。

默认情况下，在生产环境中，Rails 会把预先编译好的文件保存到 `public/assets` 文件夹中，网页服务器会把这些文件视为静态资源。在生产环境中，不会直接伺服 `app/assets` 文件夹中的文件。

### 控制器相关的静态资源

生成脚手架或控制器时，Rails 会生成一个 JavaScript 文件（如果 `Gemfile` 中有 `coffee-rails`，会生成 CoffeeScript 文件）和 CSS 文件（如果 `Gemfile` 中有 `sass-rails`，会生成 SCSS 文件）。生成脚手架时，Rails 还会生成 `scaffolds.css` 文件（如果 `Gemfile` 中有 `sass-rails`，会生成 `scaffolds.css.scss` 文件）。

例如，生成 `ProjectsController` 时，Rails 会新建 `app/assets/javascripts/projects.js.coffee` 和 `app/assets/stylesheets/projects.css.scss` 两个文件。默认情况下，这两个文件立即就可以使用 `require_tree` 引入程序。关于 `require_tree` 的介绍，请阅读“[清单文件和指令](#manifest-files-and-directives)”一节。

针对控制器的样式表和 JavaScript 文件也可只在相应的控制器中引入：

`<%= javascript_include_tag params[:controller] %>` 或 `<%= stylesheet_link_tag params[:controller] %>`

如果需要这么做，切记不要使用 `require_tree`。如果使用了这个指令，会多次引入相同的静态资源。

WARNING: 预处理静态资源时要确保同时处理控制器相关的静态资源。默认情况下，不会自动编译 `.coffee` 和 `.scss` 文件。在开发环境中没什么问题，因为会自动编译。但在生产环境中会得到 500 错误，因为此时自动编译默认是关闭的。关于预编译的工作机理，请阅读“[事先编译好静态资源](#precompiling-assets)”一节。

NOTE: 要想使用 CoffeeScript，必须安装支持 ExecJS 的运行时。如果使用 Mac OS X 和 Windows，系统中已经安装了 JavaScript 运行时。所有支持的 JavaScript 运行时参见 [ExecJS](https://github.com/sstephenson/execjs#readme) 的文档。

在 `config/application.rb` 文件中加入以下代码可以禁止生成控制器相关的静态资源：

```ruby
config.generators do |g|
  g.assets false
end
```

### 静态资源的组织方式

Asset Pipeline 的静态文件可以放在三个位置：`app/assets`，`lib/assets` 或 `vendor/assets`。

* `app/assets`：存放程序的静态资源，例如图片、JavaScript 和样式表；
* `lib/assets`：存放自己的代码库，或者共用代码库的静态资源；
* `vendor/assets`：存放他人的静态资源，例如 JavaScript 插件，或者 CSS 框架；

WARNING: 如果从 Rails 3 升级过来，请注意，`lib/assets` 和 `vendor/assets` 中的静态资源可以引入程序，但不在预编译的范围内。详情参见“[事先编译好静态资源](#precompiling-assets)”一节。

#### 搜索路径

在清单文件或帮助方法中引用静态资源时，Sprockets 会在默认的三个位置中查找对应的文件。

默认的位置是 `apps/assets` 文件夹中的 `images`、`javascripts` 和 `stylesheets` 三个子文件夹。这三个文件夹没什么特别之处，其实 Sprockets 会搜索 `apps/assets` 文件夹中的所有子文件夹。

例如，如下的文件：

```
app/assets/javascripts/home.js
lib/assets/javascripts/moovinator.js
vendor/assets/javascripts/slider.js
vendor/assets/somepackage/phonebox.js
```

在清单文件中可以这么引用：

```js
//= require home
//= require moovinator
//= require slider
//= require phonebox
```

子文件夹中的静态资源也可引用：

```
app/assets/javascripts/sub/something.js
```

引用方式如下：

```js
//= require sub/something
```

在 Rails 控制台中执行 `Rails.application.config.assets.paths`，可以查看所有的搜索路径。

除了标准的 `assets/*` 路径之外，还可以在 `config/application.rb` 文件中向 Asset Pipeline 添加其他路径。例如：

```ruby
config.assets.paths << Rails.root.join("lib", "videoplayer", "flash")
```

Sprockets 会按照搜索路径中各路径出现的顺序进行搜索。默认情况下，这意味着 `app/assets` 文件夹中的静态资源优先级较高，会遮盖 `lib` 和 `vendor` 文件夹中的相应文件。

有一点要注意，如果静态资源不会在清单文件中引入，就要添加到预编译的文件列表中，否则在生产环境中就无法访问文件。

#### 使用索引文件

在 Sprockets 中，名为 `index` 的文件（扩展名各异）有特殊作用。

例如，程序中使用了 jQuery 代码库和许多模块，都保存在 `lib/assets/javascripts/library_name` 文件夹中，那么 `lib/assets/javascripts/library_name/index.js` 文件的作用就是这个代码库的清单。清单文件中可以按顺序列出所需的文件，或者干脆使用 `require_tree` 指令。

在清单文件中，可以把这个库作为一个整体引入：

```js
//= require library_name
```

这么做可以减少维护成本，保持代码整洁。

### 链接静态资源

Sprockets 并没有为获取静态资源添加新的方法，还是使用熟悉的 `javascript_include_tag` 和 `stylesheet_link_tag`：

```erb
<%= stylesheet_link_tag "application", media: "all" %>
<%= javascript_include_tag "application" %>
```

如果使用 Turbolinks（Rails 4 默认启用），加上 `data-turbolinks-track` 选项后，Turbolinks 会检查静态资源是否有更新，如果更新了就会将其载入页面：

```erb
<%= stylesheet_link_tag "application", media: "all", "data-turbolinks-track" => true %>
<%= javascript_include_tag "application", "data-turbolinks-track" => true %>
```

在普通的视图中可以像下面这样获取 `public/assets/images` 文件夹中的图片：

```erb
<%= image_tag "rails.png" %>
```

如果程序启用了 Asset Pipeline，且在当前环境中没有禁用，那么这个文件会经由 Sprockets 伺服。如果文件的存放位置是 `public/assets/rails.png`，则直接由网页服务器伺服。

如果请求的文件中包含 MD5 哈希，处理的方式还是一样。关于这个哈希是怎么生成的，请阅读“[在生产环境中](#in-production)”一节。

Sprockets 还会检查 `config.assets.paths` 中指定的路径。`config.assets.paths` 包含标准路径和其他 Rails 引擎添加的路径。

图片还可以放入子文件夹中，获取时指定文件夹的名字即可：

```erb
<%= image_tag "icons/rails.png" %>
```

WARNING: 如果预编译了静态资源（参见“[在生产环境中](#in-production)”一节），链接不存在的资源（也包括链接到空字符串的情况）会在调用页面抛出异常。因此，在处理用户提交的数据时，使用 `image_tag` 等帮助方法要小心一点。

#### CSS 和 ERB

Asset Pipeline 会自动执行 ERB 代码，所以如果在 CSS 文件名后加上扩展名 `erb`（例如 `application.css.erb`），那么在 CSS 规则中就可使用 `asset_path` 等帮助方法。

```css
.class { background-image: url(<%= asset_path 'image.png' %>) }
```

Asset Pipeline 会计算出静态资源的真实路径。在上面的代码中，指定的图片要出现在加载路径中。如果在 `public/assets` 中有该文件带指纹版本，则会使用这个文件的路径。

如果想使用 [data URI](http://en.wikipedia.org/wiki/Data_URI_scheme)（直接把图片数据内嵌在 CSS 文件中），可以使用 `asset_data_uri` 帮助方法。

```css
#logo { background: url(<%= asset_data_uri 'logo.png' %>) }
```

`asset_data_uri` 会把正确格式化后的 data URI 写入 CSS 文件。

注意，关闭标签不能使用 `-%>` 形式。

#### CSS 和 Sass

使用 Asset Pipeline，静态资源的路径要使用 `sass-rails` 提供的 `-url` 和 `-path` 帮助方法（在 Sass 中使用连字符，在 Ruby 中使用下划线）重写。这两种帮助方法可用于引用图片，字体，视频，音频，JavaScript 和样式表。

* `image-url("rails.png")` 编译成 `url(/assets/rails.png)`
* `image-path("rails.png")` 编译成 `"/assets/rails.png"`.

还可使用通用方法：

* `asset-url("rails.png")` 编译成 `url(/assets/rails.png)`
* `asset-path("rails.png")` 编译成 `"/assets/rails.png"`

#### JavaScript/CoffeeScript 和 ERB

如果在 JavaScript 文件后加上扩展名 `erb`，例如 `application.js.erb`，就可以在 JavaScript 代码中使用帮助方法 `asset_path`：

```js
$('#logo').attr({ src: "<%= asset_path('logo.png') %>" });
```

Asset Pipeline 会计算出静态资源的真实路径。

类似地，如果在 CoffeeScript 文件后加上扩展名 `erb`，例如 `application.js.coffee.erb`，也可在代码中使用帮助方法 `asset_path`：

```js
$('#logo').attr src: "<%= asset_path('logo.png') %>"
```

### 清单文件和指令

Sprockets 通过清单文件决定要引入和伺服哪些静态资源。清单文件中包含一些指令，告知 Sprockets 使用哪些文件生成主 CSS 或 JavaScript 文件。Sprockets 会解析这些指令，加载指定的文件，如有需要还会处理文件，然后再把各个文件合并成一个文件，最后再压缩文件（如果 `Rails.application.config.assets.compress` 选项为 `true`）。只伺服一个文件可以大大减少页面加载时间，因为浏览器发起的请求数更少。压缩能减小文件大小，加快浏览器下载速度。

例如，新建的 Rails 4 程序中有个 `app/assets/javascripts/application.js` 文件，包含以下内容：

```js
// ...
//= require jquery
//= require jquery_ujs
//= require_tree .
```

在 JavaScript 文件中，Sprockets 的指令以 `//=` 开头。在上面的文件中，用到了 `require` 和 the `require_tree` 指令。`require` 指令告知 Sprockets 要加载的文件。在上面的文件中，加载了 Sprockets 搜索路径中的 `jquery.js` 和 `jquery_ujs.js` 两个文件。文件名后无需加上扩展名，在 `.js` 文件中 Sprockets 默认会加载 `.js` 文件。

`require_tree` 指令告知 Sprockets 递归引入指定文件夹中的所有 JavaScript 文件。文件夹的路径必须相对于清单文件。也可使用 `require_directory` 指令加载指定文件夹中的所有 JavaScript 文件，但不会递归。

Sprockets 会按照从上至下的顺序处理指令，但 `require_tree` 引入的文件顺序是不可预期的，不要设想能得到一个期望的顺序。如果要确保某些 JavaScript 文件出现在其他文件之前，就要先在清单文件中引入。注意，`require` 等指令不会多次加载同一个文件。

Rails 还会生成 `app/assets/stylesheets/application.css` 文件，内容如下：

```css
/* ...
*= require_self
*= require_tree .
*/
```

不管创建新程序时有没有指定 `--skip-sprockets` 选项，Rails 4 都会生成 `app/assets/javascripts/application.js` 和 `app/assets/stylesheets/application.css`。这样如果后续需要使用 Asset Pipelining，操作就方便了。

样式表中使用的指令和 JavaScript 文件一样，不过加载的是样式表而不是 JavaScript 文件。`require_tree` 指令在 CSS 清单文件中的作用和在 JavaScript 清单文件中一样，从指定的文件夹中递归加载所有样式表。

上面的代码中还用到了 `require_self`。这么做可以把当前文件中的 CSS 加入调用 `require_self` 的位置。如果多次调用 `require_self`，只有最后一次调用有效。

NOTE: 如果想使用多个 Sass 文件，应该使用 [Sass 中的 `@import` 规则](http://sass-lang.com/docs/yardoc/file.SASS_REFERENCE.html#import)，不要使用 Sprockets 指令。如果使用 Sprockets 指令，Sass 文件只出现在各自的作用域中，Sass 变量和混入只在定义所在文件中有效。为了达到 `require_tree` 指令的效果，可以使用通配符，例如 `@import "*"` 和 `@import "**/*"`。详情参见 [sass-rails 的文档](https://github.com/rails/sass-rails#features)。

清单文件可以有多个。例如，`admin.css` 和 `admin.js` 这两个清单文件包含程序管理后台所需的 JS 和 CSS 文件。

CSS 清单中的指令也适用前面介绍的加载顺序。分别引入各文件，Sprockets 会按照顺序编译。例如，可以按照下面的方式合并三个 CSS 文件：

```css
/* ...
*= require reset
*= require layout
*= require chrome
*/
```

### 预处理

静态资源的文件扩展名决定了使用哪个预处理器处理。如果使用默认的 gem，生成控制器或脚手架时，会生成 CoffeeScript 和 SCSS 文件，而不是普通的 JavaScript 和 CSS 文件。前文举过例子，生成 `projects` 控制器时会创建 `app/assets/javascripts/projects.js.coffee` 和 `app/assets/stylesheets/projects.css.scss` 两个文件。

在开发环境中，或者禁用 Asset Pipeline 时，这些文件会使用 `coffee-script` 和 `sass` 提供的预处理器处理，然后再发给浏览器。启用 Asset Pipeline 时，这些文件会先使用预处理器处理，然后保存到 `public/assets` 文件夹中，再由 Rails 程序或网页服务器伺服。

添加额外的扩展名可以增加预处理次数，预处理程序会按照扩展名从右至左的顺序处理文件内容。所以，扩展名的顺序要和处理的顺序一致。例如，名为 `app/assets/stylesheets/projects.css.scss.erb` 的样式表首先会使用 ERB 处理，然后是 SCSS，最后才以 CSS 格式发送给浏览器。JavaScript 文件类似，`app/assets/javascripts/projects.js.coffee.erb` 文件先由 ERB 处理，然后是 CoffeeScript，最后以 JavaScript 格式发送给浏览器。

记住，预处理器的执行顺序很重要。例如，名为 `app/assets/javascripts/projects.js.erb.coffee` 的文件首先由 CoffeeScript 处理，但是 CoffeeScript 预处理器并不懂 ERB 代码，因此会导致错误。

开发环境
--------

在开发环境中，Asset Pipeline 按照清单文件中指定的顺序伺服各静态资源。

清单 `app/assets/javascripts/application.js` 的内容如下：

```js
//= require core
//= require projects
//= require tickets
```

生成的 HTML 如下：

```html
<script src="/assets/core.js?body=1"></script>
<script src="/assets/projects.js?body=1"></script>
<script src="/assets/tickets.js?body=1"></script>
```

Sprockets 要求必须使用 `body` 参数。

### 检查运行时错误

默认情况下，在生产环境中 Asset Pipeline 会检查潜在的错误。要想禁用这一功能，可以做如下设置：

```ruby
config.assets.raise_runtime_errors = false
```

`raise_runtime_errors` 设为 `false` 时，Sprockets 不会检查静态资源的依赖关系是否正确。遇到下面这种情况时，必须告知 Asset Pipeline 其中的依赖关系。

如果在 `application.css.erb` 中引用了 `logo.png`，如下所示：

```css
#logo { background: url(<%= asset_data_uri 'logo.png' %>) }
```

就必须声明 `logo.png` 是 `application.css.erb` 的一个依赖件，这样重新编译图片时才会同时重新编译 CSS 文件。依赖关系可以使用 `//= depend_on_asset` 声明：

```css
//= depend_on_asset "logo.png"
#logo { background: url(<%= asset_data_uri 'logo.png' %>) }
```

如果没有这个声明，在生产环境中可能遇到难以查找的奇怪问题。`raise_runtime_errors` 设为 `true` 时，运行时会自动检查依赖关系。

### 关闭调试功能

在 `config/environments/development.rb` 中添加如下设置可以关闭调试功能：

```ruby
config.assets.debug = false
```

关闭调试功能后，Sprockets 会预处理所有文件，然后合并。关闭调试功能后，前文的清单文件生成的 HTML 如下：

```html
<script src="/assets/application.js"></script>
```

服务器启动后，首次请求发出后会编译并缓存静态资源。Sprockets 会把 `Cache-Control` 报头设为 `must-revalidate`。再次请求时，浏览器会得到 304 (Not Modified) 响应。

如果清单中的文件内容发生了变化，服务器会返回重新编译后的文件。

调试功能可以在 Rails 帮助方法中启用：

```erb
<%= stylesheet_link_tag "application", debug: true %>
<%= javascript_include_tag "application", debug: true %>
```

如果已经启用了调试模式，再使用 `:debug` 选项就有点多余了。

在开发环境中也可启用压缩功能，检查是否能正常运行。需要调试时再禁用压缩即可。

生产环境
-------

在生产环境中，Sprockets 使用前文介绍的指纹机制。默认情况下，Rails 认为静态资源已经事先编译好了，直接由网页服务器伺服。

在预先编译的过程中，会根据文件的内容生成 MD5，写入硬盘时把 MD5 加到文件名中。Rails 帮助方法会使用加上指纹的文件名代替清单文件中使用的文件名。

例如：

```erb
<%= javascript_include_tag "application" %>
<%= stylesheet_link_tag "application" %>
```

生成的 HTML 如下：

```html
<script src="/assets/application-908e25f4bf641868d8683022a5b62f54.js"></script>
<link href="/assets/application-4dd5b109ee3439da54f5bdfd78a80473.css" media="screen"
rel="stylesheet" />
```

注意，推出 Asset Pipeline 功能后不再使用 `:cache` 和 `:concat` 选项了，请从 `javascript_include_tag` 和 `stylesheet_link_tag` 标签上将其删除。

指纹由 `config.assets.digest` 初始化选项控制（生产环境默认为 `true`，其他环境为 `false`）。

NOTE: 一般情况下，请勿修改 `config.assets.digest` 的默认值。如果文件名中没有指纹，而且缓存报头的时间设置为很久以后，那么即使文件的内容变了，客户端也不会重新获取文件。

### 事先编译好静态资源

Rails 提供了一个 rake 任务用来编译清单文件中的静态资源和其他相关文件。

编译后的静态资源保存在 `config.assets.prefix` 选项指定的位置。默认是 `/assets` 文件夹。

部署时可以在服务器上执行这个任务，直接在服务器上编译静态资源。下一节会介绍如何在本地编译。

这个 rake 任务是：

```bash
$ RAILS_ENV=production bundle exec rake assets:precompile
```

Capistrano（v2.15.1 及以上版本）提供了一个配方，可在部署时编译静态资源。把下面这行加入 `Capfile` 文件即可：

```ruby
load 'deploy/assets'
```

这个配方会把 `config.assets.prefix` 选项指定的文件夹链接到 `shared/assets`。如果 `shared/assets` 已经占用，就要修改部署任务。

在多次部署之间共用这个文件夹是十分重要的，这样只要缓存的页面可用，其中引用的编译后的静态资源就能正常使用。

默认编译的文件包括 `application.js`、`application.css` 以及 gem 中 `app/assets` 文件夹中的所有非 JS/CSS 文件（会自动加载所有图片）：

```ruby
[ Proc.new { |path, fn| fn =~ /app\/assets/ && !%w(.js .css).include?(File.extname(path)) },
/application.(css|js)$/ ]
```

NOTE: 这个正则表达式表示最终要编译的文件。也就是说，JS/CSS 文件不包含在内。例如，因为 `.coffee` 和 `.scss` 文件能编译成 JS 和 CSS 文件，所以**不在**自动编译的范围内。

如果想编译其他清单，或者单独的样式表和 JavaScript，可以添加到 `config/application.rb` 文件中的 `precompile` 选项：

```ruby
config.assets.precompile += ['admin.js', 'admin.css', 'swfObject.js']
```

或者可以按照下面的方式，设置编译所有静态资源：

```ruby
# config/application.rb
config.assets.precompile << Proc.new do |path|
  if path =~ /\.(css|js)\z/
    full_path = Rails.application.assets.resolve(path).to_path
    app_assets_path = Rails.root.join('app', 'assets').to_path
    if full_path.starts_with? app_assets_path
      puts "including asset: " + full_path
      true
    else
      puts "excluding asset: " + full_path
      false
    end
  else
    false
  end
end
```

NOTE: 即便想添加 Sass 或 CoffeeScript 文件，也要把希望编译的文件名设为 .js 或 .css。

这个 rake 任务还会生成一个名为 `manifest-md5hash.json` 的文件，列出所有静态资源和对应的指纹。这样 Rails 帮助方法就不用再通过 Sprockets 获取指纹了。下面是一个 `manifest-md5hash.json` 文件内容示例：

```ruby
{"files":{"application-723d1be6cc741a3aabb1cec24276d681.js":{"logical_path":"application.js","mtime":"2013-07-26T22:55:03-07:00","size":302506,
"digest":"723d1be6cc741a3aabb1cec24276d681"},"application-12b3c7dd74d2e9df37e7cbb1efa76a6d.css":{"logical_path":"application.css","mtime":"2013-07-26T22:54:54-07:00","size":1560,
"digest":"12b3c7dd74d2e9df37e7cbb1efa76a6d"},"application-1c5752789588ac18d7e1a50b1f0fd4c2.css":{"logical_path":"application.css","mtime":"2013-07-26T22:56:17-07:00","size":1591,
"digest":"1c5752789588ac18d7e1a50b1f0fd4c2"},"favicon-a9c641bf2b81f0476e876f7c5e375969.ico":{"logical_path":"favicon.ico","mtime":"2013-07-26T23:00:10-07:00","size":1406,
"digest":"a9c641bf2b81f0476e876f7c5e375969"},"my_image-231a680f23887d9dd70710ea5efd3c62.png":{"logical_path":"my_image.png","mtime":"2013-07-26T23:00:27-07:00","size":6646,
"digest":"231a680f23887d9dd70710ea5efd3c62"}},"assets"{"application.js":
"application-723d1be6cc741a3aabb1cec24276d681.js","application.css":
"application-1c5752789588ac18d7e1a50b1f0fd4c2.css",
"favicon.ico":"favicona9c641bf2b81f0476e876f7c5e375969.ico","my_image.png":
"my_image-231a680f23887d9dd70710ea5efd3c62.png"}}
```

`manifest-md5hash.json` 文件的存放位置是 `config.assets.prefix` 选项指定位置（默认为 `/assets`）的根目录。

NOTE: 在生产环境中，如果找不到编译好的文件，会抛出 `Sprockets::Helpers::RailsHelper::AssetPaths::AssetNotPrecompiledError` 异常，并提示找不到哪个文件。

#### 把 Expires 报头设置为很久以后

编译好的静态资源存放在服务器的文件系统中，直接由网页服务器伺服。默认情况下，没有为这些文件设置一个很长的过期时间。为了能充分发挥指纹的作用，需要修改服务器的设置，添加相关的报头。

针对 Apache 的设置：

```conf
# The Expires* directives requires the Apache module
# `mod_expires` to be enabled.
<Location /assets/>
  # Use of ETag is discouraged when Last-Modified is present
  Header unset ETag FileETag None
  # RFC says only cache for 1 year
  ExpiresActive On ExpiresDefault "access plus 1 year"
</Location>
```

针对 Nginx 的设置：

```conf
location ~ ^/assets/ {
  expires 1y;
  add_header Cache-Control public;

  add_header ETag "";
  break;
}
```

#### GZip 压缩

Sprockets 预编译文件时还会创建静态资源的 [gzip](http://en.wikipedia.org/wiki/Gzip) 版本（.gz）。网页服务器一般使用中等压缩比例，不过因为预编译只发生一次，所以 Sprockets 会使用最大的压缩比例，尽量减少传输的数据大小。网页服务器可以设置成直接从硬盘伺服压缩版文件，无需直接压缩文件本身。

在 Nginx 中启动 `gzip_static` 模块后就能自动实现这一功能：

```nginx
location ~ ^/(assets)/  {
  root /path/to/public;
  gzip_static on; # to serve pre-gzipped version
  expires max;
  add_header Cache-Control public;
}
```

如果编译 Nginx 时加入了 `gzip_static` 模块，就能使用这个指令。Nginx 针对 Ubuntu/Debian 的安装包，以及 `nginx-light` 都会编译这个模块。否则就要手动编译：

```bash
./configure --with-http_gzip_static_module
```

如果编译支持 Phusion Passenger 的 Nginx，就必须加入这个命令行选项。

针对 Apache 的设置很复杂，请自行 Google。

### 在本地预编译

为什么要在本地预编译静态文件呢？原因如下：

* 可能无权限访问生产环境服务器的文件系统；
* 可能要部署到多个服务器，避免重复编译；
* 可能会经常部署，但静态资源很少改动；

在本地预编译后，可以把编译好的文件纳入版本控制系统，再按照常规的方式部署。

不过有两点要注意：

* 一定不能运行 Capistrano 部署任务来预编译静态资源；
* 必须修改下面这个设置；

在 `config/environments/development.rb` 中加入下面这行代码：

```ruby
config.assets.prefix = "/dev-assets"
```

修改 `prefix` 后，在开发环境中 Sprockets 会使用其他的 URL 伺服静态资源，把请求都交给 Sprockets 处理。但在生产环境中 `prefix` 仍是 `/assets`。如果没作上述修改，在生产环境中会从 `/assets` 伺服静态资源，除非再次编译，否则看不到文件的变化。

同时还要确保所需的压缩程序在生产环境中可用。

在本地预编译静态资源，这些文件就会出现在工作目录中，而且可以根据需要纳入版本控制系统。开发环境仍能按照预期正常运行。

### 实时编译

某些情况下可能需要实时编译，此时静态资源直接由 Sprockets 处理。

要想使用实时编译，要做如下设置：

```ruby
config.assets.compile = true
```

初次请求时，Asset Pipeline 会编译静态资源，并缓存，这一过程前文已经提过了。引用文件时，会使用加上 MD5 哈希的文件名代替清单文件中的名字。

Sprockets 还会把 `Cache-Control` 报头设为 `max-age=31536000`。这个报头的意思是，服务器和客户端浏览器之间的缓存可以存储一年，以减少从服务器上获取静态资源的请求数量。静态资源的内容可能存在本地浏览器的缓存或者其他中间缓存中。

实时编译消耗的内存更多，比默认的编译方式性能更低，因此不推荐使用。

如果要把程序部署到没有安装 JavaScript 运行时的服务器，可以在 `Gemfile` 中加入：

```ruby
group :production do
  gem 'therubyracer'
end
```

### CDN

如果用 CDN 分发静态资源，要确保文件不会被缓存，因为缓存会导致问题。如果设置了 `config.action_controller.perform_caching = true`，`Rack::Cache` 会使用 `Rails.cache` 存储静态文件，很快缓存空间就会用完。

每种缓存的工作方式都不一样，所以要了解你所用 CDN 是如何处理缓存的，确保能和 Asset Pipeline 和谐相处。有时你会发现某些设置能导致诡异的表现，而有时又不会。例如，作为 HTTP 缓存使用时，Nginx 的默认设置就不会出现什么问题。

定制 Asset Pipeline
-------------------

### 压缩 CSS

压缩 CSS 的方式之一是使用 YUI。[YUI CSS compressor](http://yui.github.io/yuicompressor/css.html) 提供了压缩功能。

下面这行设置会启用 YUI 压缩，在此之前要先安装 `yui-compressor` gem：

```ruby
config.assets.css_compressor = :yui
```

如果安装了 `sass-rails` gem，还可以使用其他的方式压缩 CSS：

```ruby
config.assets.css_compressor = :sass
```

### 压缩 JavaScript

压缩 JavaScript 的方式有：`:closure`，`:uglifier` 和 `:yui`。这三种方式分别需要安装 `closure-compiler`、`uglifier` 和 `yui-compressor`。

默认的 `Gemfile` 中使用的是 [uglifier](https://github.com/lautis/uglifier)。这个 gem 使用 Ruby 包装了 [UglifyJS](https://github.com/mishoo/UglifyJS)（为 NodeJS 开发）。uglifier 可以删除空白和注释，缩短本地变量名，还会做些微小的优化，例如把 `if...else` 语句改写成三元操作符形式。

下面这行设置使用 `uglifier` 压缩 JavaScript：

```ruby
config.assets.js_compressor = :uglifier
```

NOTE: 系统中要安装支持 [ExecJS](https://github.com/sstephenson/execjs#readme) 的运行时才能使用 `uglifier`。Mac OS X 和 Windows 系统中已经安装了 JavaScript 运行时。
I>
NOTE: `config.assets.compress` 初始化选项在 Rails 4 中不可用，即便设置了也没有效果。请分别使用 `config.assets.css_compressor` 和 `config.assets.js_compressor` 这两个选项设置 CSS 和 JavaScript 的压缩方式。

### 使用自己的压缩程序

设置压缩 CSS 和 JavaScript 所用压缩程序的选项还可接受对象，这个对象必须能响应 `compress` 方法。`compress` 方法只接受一个字符串参数，返回值也必须是字符串。

```ruby
class Transformer
  def compress(string)
    do_something_returning_a_string(string)
  end
end
```

要想使用这个压缩程序，请在 `application.rb` 中做如下设置：

```ruby
config.assets.css_compressor = Transformer.new
```

### 修改 `assets` 的路径

Sprockets 默认使用的公开路径是 `/assets`。

这个路径可以修改成其他值：

```ruby
config.assets.prefix = "/some_other_path"
```

升级没使用 Asset Pipeline 的旧项目时，或者默认路径已有其他用途，或者希望指定一个新资源路径时，可以设置这个选项。

### X-Sendfile 报头

X-Sendfile 报头的作用是让服务器忽略程序的响应，直接从硬盘上伺服指定的文件。默认情况下服务器不会发送这个报头，但在支持该报头的服务器上可以启用。启用后，会跳过响应直接由服务器伺服文件，速度更快。X-Sendfile 报头的用法参见 [API 文档](http://api.rubyonrails.org/classes/ActionController/DataStreaming.html#method-i-send_file)。

Apache 和 Nginx 都支持这个报头，可以在 `config/environments/production.rb` 中启用：

```ruby
# config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
# config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx
```

WARNING: 如果升级现有程序，请把这两个设置写入 `production.rb`，以及其他类似生产环境的设置文件中。不能写入 `application.rb`。

TIP: 详情参见生产环境所用服务器的文档：
T>
TIP: - [Apache](https://tn123.org/mod_xsendfile/)
TIP: - [Nginx](http://wiki.nginx.org/XSendfile)

静态资源缓存的存储方式
-------------------

在开发环境和生产环境中，Sprockets 使用 Rails 默认的存储方式缓存静态资源。可以使用 `config.assets.cache_store` 设置使用其他存储方式：

```ruby
config.assets.cache_store = :memory_store
```

静态资源缓存可用的存储方式和程序的缓存存储一样。

```ruby
config.assets.cache_store = :memory_store, { size: 32.megabytes }
```

在 gem 中使用静态资源
-------------------

静态资源也可由 gem 提供。

为 Rails 提供标准 JavaScript 代码库的 `jquery-rails` gem 是个很好的例子。这个 gem 中有个引擎类，继承自 `Rails::Engine`。添加这层继承关系后，Rails 就知道这个 gem 中可能包含静态资源文件，会把这个引擎中的 `app/assets`、`lib/assets` 和 `vendor/assets` 三个文件夹加入 Sprockets 的搜索路径中。

把代码库或者 gem 变成预处理器
--------------------------

Sprockets 使用 [Tilt](https://github.com/rtomayko/tilt) 作为不同模板引擎的通用接口。在你自己的 gem 中也可实现 Tilt 的模板协议。一般情况下，需要继承 `Tilt::Template` 类，然后重新定义 `prepare` 方法（初始化模板），以及 `evaluate` 方法（返回处理后的内容）。原始数据存储在 `data` 中。详情参见 [`Tilt::Template`](https://github.com/rtomayko/tilt/blob/master/lib/tilt/template.rb) 类的源码。

```ruby
module BangBang
  class Template < ::Tilt::Template
    def prepare
      # Do any initialization here
    end

    # Adds a "!" to original template.
    def evaluate(scope, locals, &block)
      "#{data}!"
    end
  end
end
```

上述代码定义了 `Template` 类，然后还需要关联模板文件的扩展名：

```ruby
Sprockets.register_engine '.bang', BangBang::Template
```

升级旧版本 Rails
---------------

从 Rails 3.0 或 Rails 2.x 升级，有一些问题要解决。首先，要把 `public/` 文件夹中的文件移到新位置。不同类型文件的存放位置参见“[静态资源的组织方式](#asset-organization)”一节。

其次，避免 JavaScript 文件重复出现。因为从 Rails 3.1 开始，jQuery 是默认的 JavaScript 库，因此不用把 `jquery.js` 复制到 `app/assets` 文件夹中。Rails 会自动加载 jQuery。

然后，更新各环境的设置文件，添加默认设置。

在 `application.rb` 中加入：

```ruby
# Version of your assets, change this if you want to expire all your assets
config.assets.version = '1.0'

# Change the path that assets are served from config.assets.prefix = "/assets"
```

在 `development.rb` 中加入：

```ruby
# Expands the lines which load the assets
config.assets.debug = true
```

在 `production.rb` 中加入：

```ruby
# Choose the compressors to use (if any) config.assets.js_compressor  =
# :uglifier config.assets.css_compressor = :yui

# Don't fallback to assets pipeline if a precompiled asset is missed
config.assets.compile = false

# Generate digests for assets URLs. This is planned for deprecation.
config.assets.digest = true

# Precompile additional assets (application.js, application.css, and all
# non-JS/CSS are already added) config.assets.precompile += %w( search.js )
```

Rails 4 不会在 `test.rb` 中添加 Sprockets 的默认设置，所以要手动添加。测试环境中以前的默认设置是：`config.assets.compile = true`，`config.assets.compress = false`，`config.assets.debug = false` 和 `config.assets.digest = false`。

最后，还要在 `Gemfile` 中加入以下 gem：

```ruby
gem 'sass-rails',   "~> 3.2.3"
gem 'coffee-rails', "~> 3.2.1"
gem 'uglifier'
```
