# Action Cable 概览

本文介绍 Action Cable 的工作原理，以及在 Rails 应用中如何通过 WebSocket 实现实时功能。

读完本文后，您将学到：

*   Action Cable 是什么，以及对前后端的集成；
*   如何设置 Action Cable；
*   如何设置频道（channel）；
*   Action Cable 的部署和架构设置。

-----------------------------------------------------------------------------

<a class="anchor" id="introduction"></a>

## 简介

Action Cable 将 [WebSocket](https://en.wikipedia.org/wiki/WebSocket) 与 Rails 应用的其余部分无缝集成。有了 Action Cable，我们就可以用 Ruby 语言，以 Rails 风格实现实时功能，并且保持高性能和可扩展性。Action Cable 为此提供了全栈支持，包括客户端 JavaScript 框架和服务器端 Ruby 框架。同时，我们也能够通过 Action Cable 访问使用 Active Record 或其他 ORM 编写的所有模型。

<a class="anchor" id="what-is-pub-sub"></a>

## Pub/Sub 是什么

[Pub/Sub](https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern)，也就是发布/订阅，是指在消息队列中，信息发送者（发布者）把数据发送给某一类接收者（订阅者），而不必单独指定接收者。Action Cable 通过发布/订阅的方式在服务器和多个客户端之间通信。

<a class="anchor" id="server-side-components"></a>

## 服务器端组件

<a class="anchor" id="server-side-connections"></a>

### 连接

连接是客户端-服务器通信的基础。每当服务器接受一个 WebSocket，就会实例化一个连接对象。所有频道订阅（channel subscription）都是在继承连接对象的基础上创建的。连接本身并不处理身份验证和授权之外的任何应用逻辑。WebSocket 连接的客户端被称为连接用户（connection consumer）。每当用户新打开一个浏览器标签、窗口或设备，对应地都会新建一个用户-连接对（consumer-connection pair）。

连接是 `ApplicationCable::Connection` 类的实例。对连接的授权就是在这个类中完成的，对于能够识别的用户，才会继续建立连接。

<a class="anchor" id="connection-setup"></a>

#### 连接设置

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private
      def find_verified_user
        if current_user = User.find_by(id: cookies.signed[:user_id])
          current_user
        else
          reject_unauthorized_connection
        end
      end
  end
end
```

其中 `identified_by` 用于声明连接标识符，连接标识符稍后将用于查找指定连接。注意，在声明连接标识符的同时，在基于连接创建的频道实例上，会自动创建同名委托（delegate）。

上述例子假设我们已经在应用的其他部分完成了用户身份验证，并且在验证成功后设置了经过用户 ID 签名的 cookie。

尝试建立新连接时，会自动把 cookie 发送给连接实例，用于设置 `current_user`。通过使用 `current_user` 标识连接，我们稍后就能够检索指定用户打开的所有连接（如果删除用户或取消对用户的授权，该用户打开的所有连接都会断开）。

<a class="anchor" id="channels"></a>

### 频道

和常规 MVC 中的控制器类似，频道用于封装逻辑工作单元。默认情况下，Rails 会把 `ApplicationCable::Channel` 类作为频道的父类，用于封装频道之间共享的逻辑。

<a class="anchor" id="parent-channel-setup"></a>

#### 父频道设置

```ruby
# app/channels/application_cable/channel.rb
module ApplicationCable
  class Channel < ActionCable::Channel::Base
  end
end
```

接下来我们要创建自己的频道类。例如，可以创建 `ChatChannel` 和 `AppearanceChannel` 类：

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
end

# app/channels/appearance_channel.rb
class AppearanceChannel < ApplicationCable::Channel
end
```

这样用户就可以订阅频道了，订阅一个或两个都行。

<a class="anchor" id="subscriptions"></a>

#### 订阅

订阅频道的用户称为订阅者。用户创建的连接称为（频道）订阅。订阅基于连接用户（订阅者）发送的标识符创建，生成的消息将发送到这些订阅。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  # 当用户成为此频道的订阅者时调用
  def subscribed
  end
end
```

<a class="anchor" id="client-side-components"></a>

## 客户端组件

<a class="anchor" id="client-side-connections"></a>

### 连接

用户需要在客户端创建连接实例。下面这段由 Rails 默认生成的 JavaScript 代码，正是用于在客户端创建连接实例：

<a class="anchor" id="connect-consumer"></a>

#### 连接用户

```js
// app/assets/javascripts/cable.js
//= require action_cable
//= require_self
//= require_tree ./channels

(function() {
  this.App || (this.App = {});

  App.cable = ActionCable.createConsumer();
}).call(this);
```

上述代码会创建连接用户，并将通过默认的 `/cable` 地址和服务器建立连接。我们还需要从现有订阅中至少选择一个感兴趣的订阅，否则将无法建立连接。

<a class="anchor" id="subscriber"></a>

#### 订阅者

一旦订阅了某个频道，用户也就成为了订阅者：

```ruby
# app/assets/javascripts/cable/subscriptions/chat.coffee
App.cable.subscriptions.create { channel: "ChatChannel", room: "Best Room" }

# app/assets/javascripts/cable/subscriptions/appearance.coffee
App.cable.subscriptions.create { channel: "AppearanceChannel" }
```

上述代码创建了订阅，稍后我们还要描述如何处理接收到的数据。

作为订阅者，用户可以多次订阅同一个频道。例如，用户可以同时订阅多个聊天室：

```ruby
App.cable.subscriptions.create { channel: "ChatChannel", room: "1st Room" }
App.cable.subscriptions.create { channel: "ChatChannel", room: "2nd Room" }
```

<a class="anchor" id="client-server-interactions"></a>

## 客户端-服务器的交互

<a class="anchor" id="streams"></a>

### 流（stream）

频道把已发布内容（即广播）发送给订阅者，是通过所谓的“流”机制实现的。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end
end
```

有了和模型关联的流，就可以从模型和频道生成所需的广播。下面的例子用于订阅评论频道，以接收 `Z2lkOi8vVGVzdEFwcC9Qb3N0LzE` 这样的广播：

```ruby
class CommentsChannel < ApplicationCable::Channel
  def subscribed
    post = Post.find(params[:id])
    stream_for post
  end
end
```

向评论频道发送广播的方式如下：

```ruby
CommentsChannel.broadcast_to(@post, @comment)
```

<a class="anchor" id="broadcasting"></a>

### 广播

广播是指发布/订阅的链接，也就是说，当频道订阅者使用流接收某个广播时，发布者发布的内容会被直接发送给订阅者。

广播也是时间相关的在线队列。如果用户未使用流（即未订阅频道），稍后就无法接收到广播。

在 Rails 应用的其他部分也可以发送广播：

```ruby
WebNotificationsChannel.broadcast_to(
  current_user,
  title: 'New things!',
  body: 'All the news fit to print'
)
```

调用 `WebNotificationsChannel.broadcast_to` 将向当前订阅适配器（生产环境默认为 `redis`，开发和测试环境默认为 `async`）的发布/订阅队列推送一条消息，并为每个用户设置不同的广播名。对于 ID 为 1 的用户，广播名是 `web_notifications:1`。

通过调用 `received` 回调方法，频道会使用流把到达 `web_notifications:1` 的消息直接发送给客户端。

<a class="anchor" id="client-server-interactions-subscriptions"></a>

### 订阅

订阅频道的用户，称为订阅者。用户创建的连接称为（频道）订阅。订阅基于连接用户（订阅者）发送的标识符创建，收到的消息将被发送到这些订阅。

```coffee
# app/assets/javascripts/cable/subscriptions/chat.coffee
# 假设我们已经获得了发送 Web 通知的权限
App.cable.subscriptions.create { channel: "ChatChannel", room: "Best Room" },
  received: (data) ->
    @appendLine(data)

  appendLine: (data) ->
    html = @createLine(data)
    $("[data-chat-room='Best Room']").append(html)

  createLine: (data) ->
    """
    <article class="chat-line">
      <span class="speaker">#{data["sent_by"]}</span>
      <span class="body">#{data["body"]}</span>
    </article>
    """
```

<a class="anchor" id="passing-parameters-to-channels"></a>

### 向频道传递参数

创建订阅时，可以从客户端向服务器端传递参数。例如：

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end
end
```

传递给 `subscriptions.create` 方法并作为第一个参数的对象，将成为频道的参数散列。其中必需包含 `channel` 关键字：

```coffee
# app/assets/javascripts/cable/subscriptions/chat.coffee
App.cable.subscriptions.create { channel: "ChatChannel", room: "Best Room" },
  received: (data) ->
    @appendLine(data)

  appendLine: (data) ->
    html = @createLine(data)
    $("[data-chat-room='Best Room']").append(html)

  createLine: (data) ->
    """
    <article class="chat-line">
      <span class="speaker">#{data["sent_by"]}</span>
      <span class="body">#{data["body"]}</span>
    </article>
    """
```

```ruby
# 在应用的某个部分中调用，例如 NewCommentJob
ActionCable.server.broadcast(
  "chat_#{room}",
  sent_by: 'Paul',
  body: 'This is a cool chat app.'
)
```

<a class="anchor" id="rebroadcasting-a-message"></a>

### 消息重播

一个客户端向其他已连接客户端重播自己收到的消息，是一种常见用法。

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end

  def receive(data)
    ActionCable.server.broadcast("chat_#{params[:room]}", data)
  end
end
```

```coffee
# app/assets/javascripts/cable/subscriptions/chat.coffee
App.chatChannel = App.cable.subscriptions.create { channel: "ChatChannel", room: "Best Room" },
  received: (data) ->
    # data => { sent_by: "Paul", body: "This is a cool chat app." }

App.chatChannel.send({ sent_by: "Paul", body: "This is a cool chat app." })
```

所有已连接的客户端，包括发送消息的客户端在内，都将收到重播的消息。注意，重播时使用的参数与订阅频道时使用的参数相同。

<a class="anchor" id="full-stack-examples"></a>

## 全栈示例

本节的两个例子都需要进行下列设置：

1.  设置连接；
1.  设置父频道；
1.  连接用户。

<a class="anchor" id="example-one-user-appearances"></a>

### 例 1：用户在线状态（user appearance）

下面是一个关于频道的简单例子，用于跟踪用户是否在线，以及用户所在的页面。（常用于显示用户在线状态，例如当用户在线时，在用户名旁边显示绿色小圆点。）

在服务器端创建在线状态频道（appearance channel）：

```ruby
# app/channels/appearance_channel.rb
class AppearanceChannel < ApplicationCable::Channel
  def subscribed
    current_user.appear
  end

  def unsubscribed
    current_user.disappear
  end

  def appear(data)
    current_user.appear(on: data['appearing_on'])
  end

  def away
    current_user.away
  end
end
```

订阅创建后，会触发 `subscribed` 回调方法，这时可以提示说“当前用户上线了”。上线/下线 API 的后端可以是 Redis、数据库或其他解决方案。

在客户端创建在线状态频道订阅：

```coffee
# app/assets/javascripts/cable/subscriptions/appearance.coffee
App.cable.subscriptions.create "AppearanceChannel",
  # 当服务器上的订阅可用时调用
  connected: ->
    @install()
    @appear()

  # 当 WebSocket 连接关闭时调用
  disconnected: ->
    @uninstall()

  # 当服务器拒绝订阅时调用
  rejected: ->
    @uninstall()

  appear: ->
    # 在服务器上调用 `AppearanceChannel#appear(data)`
    @perform("appear", appearing_on: $("main").data("appearing-on"))

  away: ->
    # 在服务器上调用 `AppearanceChannel#away`
    @perform("away")


  buttonSelector = "[data-behavior~=appear_away]"

  install: ->
    $(document).on "turbolinks:load.appearance", =>
      @appear()

    $(document).on "click.appearance", buttonSelector, =>
      @away()
      false

    $(buttonSelector).show()

  uninstall: ->
    $(document).off(".appearance")
    $(buttonSelector).hide()
```

<a class="anchor" id="client-server-interaction"></a>

#### 客户端-服务器交互

1.  **客户端**通过 `App.cable = ActionCable.createConsumer("ws://cable.example.com")`（位于 `cable.js` 文件中）连接到**服务器**。**服务器**通过 `current_user` 标识此连接。
1.  **客户端**通过 `App.cable.subscriptions.create(channel: "AppearanceChannel")`（位于 `appearance.coffee` 文件中）订阅在线状态频道。
1.  **服务器**发现在线状态频道创建了一个新订阅，于是调用 `subscribed` 回调方法，也即在 `current_user` 对象上调用 `appear` 方法。
1.  **客户端**发现订阅创建成功，于是调用 `connected` 方法（位于 `appearance.coffee` 文件中），也即依次调用 `@install` 和 `@appear`。`@appear` 会调用服务器上的 `AppearanceChannel#appear(data)` 方法，同时提供 `{ appearing_on: $("main").data("appearing-on") }` 数据散列。之所以能够这样做，是因为服务器端的频道实例会自动暴露类上声明的所有公共方法（回调除外），从而使远程过程能够通过订阅的 `perform` 方法调用它们。
1.  **服务器**接收向在线状态频道的 `appear` 动作发起的请求，此频道基于连接创建，连接由 `current_user`（位于 `appearance_channel.rb` 文件中）标识。**服务器**通过 `:appearing_on` 键从数据散列中检索数据，将其设置为 `:on` 键的值并传递给 `current_user.appear`。

<a class="anchor" id="example-two-receiving-new-web-notifications"></a>

### 例 2：接收新的 Web 通知

上一节中在线状态的例子，演示了如何把服务器功能暴露给客户端，以便在客户端通过 WebSocket 连接调用这些功能。但是 WebSocket 的伟大之处在于，它是一条双向通道。因此，在本节的例子中，我们要看一看服务器如何调用客户端上的动作。

本节所举的例子是一个 Web 通知频道（Web notification channel），允许我们在广播到正确的流时触发客户端 Web 通知。

创建服务器端 Web 通知频道：

```ruby
# app/channels/web_notifications_channel.rb
class WebNotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end
end
```

创建客户端 Web 通知频道订阅：

```coffee
# app/assets/javascripts/cable/subscriptions/web_notifications.coffee
# 客户端假设我们已经获得了发送 Web 通知的权限
App.cable.subscriptions.create "WebNotificationsChannel",
  received: (data) ->
    new Notification data["title"], body: data["body"]
```

在应用的其他部分向 Web 通知频道实例发送内容广播：

```ruby
# 在应用的某个部分中调用，例如 NewCommentJob
WebNotificationsChannel.broadcast_to(
  current_user,
  title: 'New things!',
  body: 'All the news fit to print'
)
```

调用 `WebNotificationsChannel.broadcast_to` 将向当前订阅适配器的发布/订阅队列推送一条消息，并为每个用户设置不同的广播名。对于 ID 为 1 的用户，广播名是 `web_notifications:1`。

通过调用 `received` 回调方法，频道会用流把到达 `web_notifications:1` 的消息直接发送给客户端。作为参数传递的数据散列，将作为第二个参数传递给服务器端的广播调用，数据在传输前使用 JSON 进行编码，到达服务器后由 `received` 解码。

<a class="anchor" id="more-complete-examples"></a>

### 更完整的例子

关于在 Rails 应用中设置 Action Cable 并添加频道的完整例子，参见 [rails/actioncable-examples](https://github.com/rails/actioncable-examples) 仓库。

<a class="anchor" id="configuration"></a>

## 配置

使用 Action Cable 时，有两个选项必需配置：订阅适配器和允许的请求来源。

<a class="anchor" id="subscription-adapter"></a>

### 订阅适配器

默认情况下，Action Cable 会查找 `config/cable.yml` 这个配置文件。该文件必须为每个 Rails 环境指定适配器和 URL 地址。关于适配器的更多介绍，请参阅 [依赖关系](#action-cable-overview-dependencies)。

```yml
development:
  adapter: async

test:
  adapter: async

production:
  adapter: redis
  url: redis://10.10.3.153:6381
  channel_prefix: appname_production
```

<a class="anchor" id="adapter-configuration"></a>

#### 配置适配器

下面是终端用户可用的订阅适配器。

<a class="anchor" id="async-adapter"></a>

##### async 适配器

async 适配器只适用于开发和测试环境，不应该在生产环境使用。

<a class="anchor" id="redis-adapter"></a>

##### Redis 适配器

Action Cable 包含两个 Redis 适配器：常规的 Redis 和事件型 Redis。这两个适配器都要求用户提供指向 Redis 服务器的 URL。此外，多个应用使用同一个 Redis 服务器时，可以设定 `channel_prefix`，以免名称冲突。详情参见 [Redis PubSub 文档](https://redis.io/topics/pubsub#database-amp-scoping)。

<a class="anchor" id="postgresql-adapter"></a>

##### PostgreSQL 适配器

PostgreSQL 适配器使用 Active Record 的连接池，因此使用应用的 `config/database.yml` 数据库配置连接。以后可能会变。[#27214](https://github.com/rails/rails/issues/27214)

<a class="anchor" id="allowed-request-origins"></a>

### 允许的请求来源

Action Cable 仅接受来自指定来源的请求。这些来源是在服务器配置文件中以数组的形式设置的，每个来源既可以是字符串，也可以是正则表达式。对于每个请求，都要对其来源进行检查，看是否和允许的请求来源相匹配。

```ruby
config.action_cable.allowed_request_origins = ['http://rubyonrails.com', %r{http://ruby.*}]
```

若想禁用来源检查，允许任何来源的请求：

```ruby
config.action_cable.disable_request_forgery_protection = true
```

在开发环境中，Action Cable 默认允许来自 localhost:3000 的所有请求。

<a class="anchor" id="consumer-configuration"></a>

### 用户配置

要想配置 URL 地址，可以在 HTML 布局文件的 `<head>` 元素中添加 `action_cable_meta_tag` 标签。这个标签会使用环境配置文件中 `config.action_cable.url` 选项设置的 URL 地址或路径。

<a class="anchor" id="other-configurations"></a>

### 其他配置

另一个常见的配置选项，是应用于每个连接记录器的日志标签。下述示例在有用户账户时使用账户 ID，没有时则标记为“no-account”：

```ruby
config.action_cable.log_tags = [
  -> request { request.env['user_account_id'] || "no-account" },
  :action_cable,
  -> request { request.uuid }
]
```

关于所有配置选项的完整列表，请参阅 `ActionCable::Server::Configuration` 类的 API 文档。

还要注意，服务器提供的数据库连接在数量上至少应该和职程（worker）相等。职程池的默认大小为 100，也就是说数据库连接数量至少为 4。职程池的大小可以通过 `config/database.yml` 文件中的 `pool` 属性设置。

<a class="anchor" id="running-standalone-cable-servers"></a>

## 运行独立的 Cable 服务器

<a class="anchor" id="in-app"></a>

### 和应用一起运行

Action Cable 可以和 Rails 应用一起运行。例如，要想监听 `/websocket` 上的 WebSocket 请求，可以通过 `config.action_cable.mount_path` 选项指定监听路径：

```ruby
# config/application.rb
class Application < Rails::Application
  config.action_cable.mount_path = '/websocket'
end
```

在布局文件中调用 `action_cable_meta_tag` 后，就可以使用 `App.cable = ActionCable.createConsumer()` 连接到 Cable 服务器。可以通过 `createConsumer` 方法的第一个参数指定自定义路径（例如，`App.cable =
ActionCable.createConsumer("/websocket")`）。

对于我们创建的每个服务器实例，以及由服务器派生的每个职程，都会新建对应的 Action Cable 实例，通过 Redis 可以在不同连接之间保持消息同步。

<a class="anchor" id="standalone"></a>

### 独立运行

Cable 服务器可以和普通应用服务器分离。此时，Cable 服务器仍然是 Rack 应用，只不过是单独的 Rack 应用罢了。推荐的基本设置如下：

```ruby
# cable/config.ru
require_relative '../config/environment'
Rails.application.eager_load!

run ActionCable.server
```

然后用 `bin/cable` 中的一个 binstub 命令启动服务器：

```shell
#!/bin/bash
bundle exec puma -p 28080 cable/config.ru
```

上述代码在 28080 端口上启动 Cable 服务器。

<a class="anchor" id="notes"></a>

### 注意事项

WebSocket 服务器没有访问会话的权限，但可以访问 cookie，而在处理身份验证时需要用到 cookie。[这篇文章](http://www.rubytutorial.io/actioncable-devise-authentication)介绍了如何使用 Devise 验证身份。

<a class="anchor" id="action-cable-overview-dependencies"></a>

## 依赖关系

Action Cable 提供了用于处理发布/订阅内部逻辑的订阅适配器接口，默认包含异步、内联、PostgreSQL、事件 Redis 和非事件 Redis 适配器。新建 Rails 应用的默认适配器是异步（async）适配器。

对 Ruby gem 的依赖包括 [websocket-driver](https://github.com/faye/websocket-driver-ruby)、[nio4r](https://github.com/celluloid/nio4r) 和 [concurrent-ruby](https://github.com/ruby-concurrency/concurrent-ruby)。

<a class="anchor" id="deployment"></a>

## 部署

Action Cable 由 WebSocket 和线程组成。其中框架管道和用户指定频道的职程，都是通过 Ruby 提供的原生线程支持来处理的。这意味着，只要不涉及线程安全问题，我们就可以使用常规 Rails 线程模型的所有功能。

Action Cable 服务器实现了Rack 套接字劫持 API（Rack socket hijacking API），因此无论应用服务器是否是多线程的，都能够通过多线程模式管理内部连接。

因此，Action Cable 可以和流行的应用服务器一起使用，例如 Unicorn、Puma 和 Passenger。
