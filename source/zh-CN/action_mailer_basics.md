# Action Mailer 基础

本文全面介绍如何在应用中收发邮件、Action Mailer 的内部机理，以及如何测试邮件程序（mailer）。

读完本文后，您将学到：

*   如何在 Rails 应用中收发邮件；
*   如何生成及编辑 Action Mailer 类和邮件视图；
*   如何配置 Action Mailer；
*   如何测试 Action Mailer 类。

-----------------------------------------------------------------------------

<a class="anchor" id="introduction"></a>

## 简介

Rails 使用 Action Mailer 实现发送邮件功能，邮件由邮件程序和视图控制。邮件程序继承自 `ActionMailer::Base`，作用与控制器类似，保存在 `app/mailers` 文件夹中，对应的视图保存在 `app/views` 文件夹中。

<a class="anchor" id="sending-emails"></a>

## 发送邮件

本节逐步说明如何创建邮件程序及其视图。

<a class="anchor" id="walkthrough-to-generating-a-mailer"></a>

### 生成邮件程序的步骤

<a class="anchor" id="create-the-mailer"></a>

#### 创建邮件程序

```sh
$ bin/rails generate mailer UserMailer
create  app/mailers/user_mailer.rb
create  app/mailers/application_mailer.rb
invoke  erb
create    app/views/user_mailer
create    app/views/layouts/mailer.text.erb
create    app/views/layouts/mailer.html.erb
invoke  test_unit
create    test/mailers/user_mailer_test.rb
create    test/mailers/previews/user_mailer_preview.rb
```

```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout 'mailer'
end

# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
end
```

如上所示，生成邮件程序的方法与使用其他生成器一样。邮件程序在某种程度上就是控制器。执行上述命令后，生成了一个邮件程序、一个视图文件夹和一个测试文件。

如果不想使用生成器，可以手动在 `app/mailers` 文件夹中新建文件，但要确保继承自 `ActionMailer::Base`：

```ruby
class MyMailer < ActionMailer::Base
end
```

<a class="anchor" id="edit-the-mailer"></a>

#### 编辑邮件程序

邮件程序和控制器类似，也有称为“动作”的方法，而且使用视图组织内容。控制器生成的内容，例如 HTML，发送给客户端；邮件程序生成的消息则通过电子邮件发送。

`app/mailers/user_mailer.rb` 文件中有一个空的邮件程序：

```ruby
class UserMailer < ApplicationMailer
end
```

下面我们定义一个名为 `welcome_email` 的方法，向用户注册时填写的电子邮件地址发送一封邮件：

```ruby
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome_email(user)
    @user = user
    @url  = 'http://example.com/login'
    mail(to: @user.email, subject: 'Welcome to My Awesome Site')
  end
end
```

下面简单说明一下这段代码。可用选项的详细说明请参见 [Action Mailer 方法详解](#complete-list-of-action-mailer-methods)。

*   `default`：一个散列，该邮件程序发出邮件的默认设置。上例中，我们把 `:from` 邮件头设为一个值，这个类中的所有动作都会使用这个值，不过可以在具体的动作中覆盖。
*   `mail`：用于发送邮件的方法，我们传入了 `:to` 和 `:subject` 邮件头。

与控制器一样，动作中定义的实例变量可以在视图中使用。

<a class="anchor" id="create-a-mailer-view"></a>

#### 创建邮件视图

在 `app/views/user_mailer/` 文件夹中新建文件 `welcome_email.html.erb`。这个视图是邮件的模板，使用 HTML 编写：

```erb
<!DOCTYPE html>
<html>
  <head>
    <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
  </head>
  <body>
    <h1>Welcome to example.com, <%= @user.name %></h1>
    <p>
      You have successfully signed up to example.com,
      your username is: <%= @user.login %>.<br>
    </p>
    <p>
      To login to the site, just follow this link: <%= @url %>.
    </p>
    <p>Thanks for joining and have a great day!</p>
  </body>
</html>
```

我们再创建一个纯文本视图。并不是所有客户端都可以显示 HTML 邮件，所以最好两种格式都发送。在 `app/views/user_mailer/` 文件夹中新建文件 `welcome_email.text.erb`，写入以下代码：

```erb
Welcome to example.com, <%= @user.name %>
===============================================

You have successfully signed up to example.com,
your username is: <%= @user.login %>.

To login to the site, just follow this link: <%= @url %>.

Thanks for joining and have a great day!
```

调用 `mail` 方法后，Action Mailer 会检测到这两个模板（纯文本和 HTML），自动生成一个类型为 `multipart/alternative` 的邮件。

<a class="anchor" id="calling-the-mailer"></a>

#### 调用邮件程序

其实，邮件程序就是渲染视图的另一种方式，只不过渲染的视图不通过 HTTP 协议发送，而是通过电子邮件协议发送。因此，应该由控制器调用邮件程序，在成功注册用户后给用户发送一封邮件。

过程相当简单。

首先，生成一个简单的 `User` 脚手架：

```sh
$ bin/rails generate scaffold user name email login
$ bin/rails db:migrate
```

这样就有一个可用的用户模型了。我们需要编辑的是文件 `app/controllers/users_controller.rb`，修改 `create` 动作，在成功保存用户后调用 `UserMailer.welcome_email` 方法，向刚注册的用户发送邮件。

Action Mailer 与 Active Job 集成得很好，可以在请求-响应循环之外发送电子邮件，因此用户无需等待。

```ruby
class UsersController < ApplicationController
  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        # 让 UserMailer 在保存之后发送一封欢迎邮件
        UserMailer.welcome_email(@user).deliver_later

        format.html { redirect_to(@user, notice: 'User was successfully created.') }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
end
```

NOTE: Active Job 的默认行为是通过 `:async` 适配器执行作业。因此，这里可以使用 `deliver_later`，异步发送电子邮件。 Active Job 的默认适配器在一个进程内线程池里运行作业。这一行为特别适合开发和测试环境，因为无需额外的基础设施，但是不适合在生产环境中使用，因为重启服务器后，待执行的作业会被丢弃。如果需要持久性后端，要使用支持持久后端的 Active Job 适配器（Sidekiq、Resque，等等）。

如果想立即发送电子邮件（例如，使用 cronjob），调用 `deliver_now` 即可：

```ruby
class SendWeeklySummary
  def run
    User.find_each do |user|
      UserMailer.weekly_summary(user).deliver_now
    end
  end
end
```

`welcome_email` 方法返回一个 `ActionMailer::MessageDelivery` 对象，在其上调用 `deliver_now` 或 `deliver_later` 方法即可发送邮件。`ActionMailer::MessageDelivery` 对象只是对 `Mail::Message` 对象的包装。如果想审查、调整或对 `Mail::Message` 对象做其他处理，可以在 `ActionMailer::MessageDelivery` 对象上调用 `message` 方法，获取 `Mail::Message` 对象。

<a class="anchor" id="auto-encoding-header-values"></a>

### 自动编码邮件头

Action Mailer 会自动编码邮件头和邮件主体中的多字节字符。

更复杂的需求，例如使用其他字符集和自编码文字，请参考 [Mail](https://github.com/mikel/mail) 库。

<a class="anchor" id="complete-list-of-action-mailer-methods"></a>

### Action Mailer 方法详解

下面这三个方法是邮件程序中最重要的方法：

*   `headers`：设置邮件头，可以指定一个由字段名和值组成的散列，也可以使用 `headers[:field_name] = 'value'` 形式；
*   `attachments`：添加邮件的附件，例如，`attachments['file-name.jpg'] = File.read('file-name.jpg')`；
*   `mail`：发送邮件，传入的值为散列形式的邮件头，`mail` 方法负责创建邮件——纯文本或多种格式，这取决于定义了哪种邮件模板；

<a class="anchor" id="adding-attachments"></a>

#### 添加附件

在 Action Mailer 中添加附件十分方便。

*   传入文件名和内容，Action Mailer 和 [Mail](https://github.com/mikel/mail) gem 会自动猜测附件的 MIME 类型，设置编码并创建附件。

    ```ruby
    attachments['filename.jpg'] = File.read('/path/to/filename.jpg')
    ```
    
    触发 `mail` 方法后，会发送一个由多部分组成的邮件，附件嵌套在类型为 `multipart/mixed` 的顶级结构中，其中第一部分的类型为 `multipart/alternative`，包含纯文本和 HTML 格式的邮件内容。
    
    NOTE: Mail gem 会自动使用 Base64 编码附件。如果想使用其他编码方式，可以先编码好，再把编码后的附件通过散列传给 `attachments` 方法。


*   传入文件名，指定邮件头和内容，Action Mailer 和 Mail gem 会使用传入的参数添加附件。

    ```ruby
    encoded_content = SpecialEncode(File.read('/path/to/filename.jpg'))
    attachments['filename.jpg'] = {
      mime_type: 'application/gzip',
      encoding: 'SpecialEncoding',
      content: encoded_content
    }
    ```
    
    NOTE: 如果指定编码，Mail gem 会认为附件已经编码了，不会再使用 Base64 编码附件。



<a class="anchor" id="making-inline-attachments"></a>

#### 使用行间附件

在 Action Mailer 3.0 中使用行间附件比之前版本简单得多。

*   首先，在 `attachments` 方法上调用 `inline` 方法，告诉 Mail 这是个行间附件：

    ```ruby
    def welcome
      attachments.inline['image.jpg'] = File.read('/path/to/image.jpg')
    end
    ```


*   在视图中，可以直接使用 `attachments` 方法，将其视为一个散列，指定想要使用的附件，在其上调用 `url` 方法，再把结果传给 `image_tag` 方法：

    ```erb
    <p>Hello there, this is our image</p>
    
    <%= image_tag attachments['image.jpg'].url %>
    ```


*   因为我们只是简单地调用了 `image_tag` 方法，所以和其他图像一样，在附件地址之后，还可以传入选项散列：

    ```erb
    <p>Hello there, this is our image</p>
    
    <%= image_tag attachments['image.jpg'].url, alt: 'My Photo', class: 'photos' %>
    ```



<a class="anchor" id="sending-email-to-multiple-recipients"></a>

#### 把邮件发给多个收件人

若想把一封邮件发送给多个收件人，例如通知所有管理员有新用户注册，可以把 `:to` 键的值设为一组邮件地址。这一组邮件地址可以是一个数组；也可以是一个字符串，使用逗号分隔各个地址。

```ruby
class AdminMailer < ApplicationMailer
  default to: Proc.new { Admin.pluck(:email) },
          from: 'notification@example.com'

  def new_registration(user)
    @user = user
    mail(subject: "New User Signup: #{@user.email}")
  end
end
```

使用类似的方式还可添加抄送和密送，分别设置 `:cc` 和 `:bcc` 键即可。

<a class="anchor" id="sending-email-with-name"></a>

#### 发送带名字的邮件

有时希望收件人在邮件中看到自己的名字，而不只是邮件地址。实现这种需求的方法是把邮件地址写成 `"Full Name <email>"` 格式。

```ruby
def welcome_email(user)
  @user = user
  email_with_name = %("#{@user.name}" <#{@user.email}>)
  mail(to: email_with_name, subject: 'Welcome to My Awesome Site')
end
```

<a class="anchor" id="mailer-views"></a>

### 邮件视图

邮件视图保存在 `app/views/name_of_mailer_class` 文件夹中。邮件程序之所以知道使用哪个视图，是因为视图文件名和邮件程序的方法名一致。在前例中，`welcome_email` 方法的 HTML 格式视图是 `app/views/user_mailer/welcome_email.html.erb`，纯文本格式视图是 `welcome_email.text.erb`。

若想修改动作使用的视图，可以这么做：

```ruby
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome_email(user)
    @user = user
    @url  = 'http://example.com/login'
    mail(to: @user.email,
         subject: 'Welcome to My Awesome Site',
         template_path: 'notifications',
         template_name: 'another')
  end
end
```

此时，邮件程序会在 `app/views/notifications` 文件夹中寻找名为 `another` 的视图。`template_path` 的值还可以是一个路径数组，按照顺序查找视图。

如果想获得更多灵活性，可以传入一个块，渲染指定的模板，或者不使用模板，渲染行间代码或纯文本：

```ruby
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome_email(user)
    @user = user
    @url  = 'http://example.com/login'
    mail(to: @user.email,
         subject: 'Welcome to My Awesome Site') do |format|
      format.html { render 'another_template' }
      format.text { render plain: 'Render text' }
    end
  end
end
```

上述代码会使用 `another_template.html.erb` 渲染 HTML，使用 `'Render text'` 渲染纯文本。这里用到的 `render` 方法和控制器中的一样，所以选项也都是一样的，例如 `:text`、`:inline` 等。

<a class="anchor" id="caching-mailer-view"></a>

#### 缓存邮件视图

在邮件视图中可以像在应用的视图中一样使用 `cache` 方法缓存视图。

```erb
<% cache do %>
  <%= @company.name %>
<% end %>
```

若想使用这个功能，要在应用中做下述配置：

```ruby
config.action_mailer.perform_caching = true
```

<a class="anchor" id="action-mailer-layouts"></a>

### Action Mailer 布局

和控制器一样，邮件程序也可以使用布局。布局的名称必须和邮件程序一样，例如 `user_mailer.html.erb` 和 `user_mailer.text.erb` 会自动识别为邮件程序的布局。

如果想使用其他布局文件，可以在邮件程序中调用 `layout` 方法：

```ruby
class UserMailer < ApplicationMailer
  layout 'awesome' # 使用 awesome.(html|text).erb 做布局
end
```

还是跟控制器视图一样，在邮件程序的布局中调用 `yield` 方法可以渲染视图。

在 `format` 块中可以把 `layout: 'layout_name'` 选项传给 `render` 方法，指定某个格式使用其他布局：

```ruby
class UserMailer < ApplicationMailer
  def welcome_email(user)
    mail(to: user.email) do |format|
      format.html { render layout: 'my_layout' }
      format.text
    end
  end
end
```

上述代码会使用 `my_layout.html.erb` 文件渲染 HTML 格式；如果 `user_mailer.text.erb` 文件存在，会用来渲染纯文本格式。

<a class="anchor" id="previewing-emails"></a>

### 预览电子邮件

Action Mailer 提供了预览功能，通过一个特殊的 URL 访问。对上述示例来说，`UserMailer` 的预览类是 `UserMailerPreview`，存储在 `test/mailers/previews/user_mailer_preview.rb` 文件中。如果想预览 `welcome_email`，实现一个同名方法，在里面调用 `UserMailer.welcome_email`：

```ruby
class UserMailerPreview < ActionMailer::Preview
  def welcome_email
    UserMailer.welcome_email(User.first)
  end
end
```

然后便可以访问 <http://localhost:3000/rails/mailers/user_mailer/welcome_email> 预览。

如果修改 `app/views/user_mailer/welcome_email.html.erb` 文件或邮件程序本身，预览会自动重新加载，立即让你看到新样式。预览列表可以访问 <http://localhost:3000/rails/mailers> 查看。

默认情况下，预览类存放在 `test/mailers/previews` 文件夹中。这个位置可以使用 `preview_path` 选项配置。假如想把它改成 `lib/mailer_previews`，可以在 `config/application.rb` 文件中这样配置：

```ruby
config.action_mailer.preview_path = "#{Rails.root}/lib/mailer_previews"
```

<a class="anchor" id="generating-urls-in-action-mailer-views"></a>

### 在邮件视图中生成 URL

与控制器不同，邮件程序不知道请求的上下文，因此要自己提供 `:host` 参数。

一个应用的 `:host` 参数一般是不变的，可以在 `config/application.rb` 文件中做全局配置：

```ruby
config.action_mailer.default_url_options = { host: 'example.com' }
```

鉴于此，在邮件视图中不能使用任何 `*_path` 辅助方法，而要使用相应的 `*_url` 辅助方法。例如，不能这样写：

```erb
<%= link_to 'welcome', welcome_path %>
```

而要这样写：

```erb
<%= link_to 'welcome', welcome_url %>
```

使用完整的 URL，电子邮件中的链接才有效。

<a class="anchor" id="generating-urls-with-url-for"></a>

#### 使用 `url_for` 方法生成 URL

默认情况下，`url_for` 在模板中生成完整的 URL。

如果没有配置全局的 `:host` 选项，别忘了把它传给 `url_for` 方法。

```erb
<%= url_for(host: 'example.com',
            controller: 'welcome',
            action: 'greeting') %>
```

<a class="anchor" id="generating-urls-with-named-routes"></a>

#### 使用具名路由生成 URL

电子邮件客户端不能理解网页的上下文，没有生成完整地址的基地址，所以使用具名路由辅助方法时一定要使用 `_url` 形式。

如果没有设置全局的 `:host` 选项，一定要将其传给 URL 辅助方法。

```erb
<%= user_url(@user, host: 'example.com') %>
```

NOTE: `GET` 之外的链接需要 [rails-ujs](https://github.com/rails/rails-ujs) 或 [jQuery UJS](https://github.com/rails/jquery-ujs)，在邮件模板中无法使用。如若不然，都会变成常规的 `GET` 请求。

<a class="anchor" id="adding-images-in-action-mailer-views"></a>

### 在邮件视图中添加图像

与控制器不同，邮件程序不知道请求的上下文，因此要自己提供 `:asset_host` 参数。

一个应用的 `:asset_host` 参数一般是不变的，可以在 `config/application.rb` 文件中做全局配置：

```ruby
config.action_mailer.asset_host = 'http://example.com'
```

现在可以在电子邮件中显示图像了：

```erb
<%= image_tag 'image.jpg' %>
```

<a class="anchor" id="sending-multipart-emails"></a>

### 发送多种格式邮件

如果一个动作有多个模板，Action Mailer 会自动发送多种格式的邮件。例如前面的 `UserMailer`，如果在 `app/views/user_mailer` 文件夹中有 `welcome_email.text.erb` 和 `welcome_email.html.erb` 两个模板，Action Mailer 会自动发送 HTML 和纯文本格式的邮件。

格式的顺序由 `ActionMailer::Base.default` 方法的 `:parts_order` 选项决定。

<a class="anchor" id="sending-emails-with-dynamic-delivery-options"></a>

### 发送邮件时动态设置发送选项

如果在发送邮件时想覆盖发送选项（例如，SMTP 凭据），可以在邮件程序的动作中设定 `delivery_method_options` 选项。

```ruby
class UserMailer < ApplicationMailer
  def welcome_email(user, company)
    @user = user
    @url  = user_url(@user)
    delivery_options = { user_name: company.smtp_user,
                         password: company.smtp_password,
                         address: company.smtp_host }
    mail(to: @user.email,
         subject: "Please see the Terms and Conditions attached",
         delivery_method_options: delivery_options)
  end
end
```

<a class="anchor" id="sending-emails-without-template-renderin"></a>

### 不渲染模板

有时可能不想使用布局，而是直接使用字符串渲染邮件内容，为此可以使用 `:body` 选项。但是别忘了指定 `:content_type` 选项，否则 Rails 会使用默认值 `text/plain`。

```ruby
class UserMailer < ApplicationMailer
  def welcome_email(user, email_body)
    mail(to: user.email,
         body: email_body,
         content_type: "text/html",
         subject: "Already rendered!")
  end
end
```

<a class="anchor" id="receiving-emails"></a>

## 接收电子邮件

使用 Action Mailer 接收和解析电子邮件是件相当麻烦的事。接收电子邮件之前，要先配置系统，把邮件转发给 Rails 应用，然后做监听。因此，在 Rails 应用中接收电子邮件要完成以下步骤：

*   在邮件程序中实现 `receive` 方法；
*   配置电子邮件服务器，把想通过应用接收的地址转发到 `/path/to/app/bin/rails runner 'UserMailer.receive(STDIN.read)'`；

在邮件程序中定义 `receive` 方法后，Action Mailer 会解析收到的原始邮件，生成邮件对象，解码邮件内容，实例化一个邮件程序，把邮件对象传给邮件程序的 `receive` 实例方法。下面举个例子：

```ruby
class UserMailer < ApplicationMailer
  def receive(email)
    page = Page.find_by(address: email.to.first)
    page.emails.create(
      subject: email.subject,
      body: email.body
    )

    if email.has_attachments?
      email.attachments.each do |attachment|
        page.attachments.create({
          file: attachment,
          description: email.subject
        })
      end
    end
  end
end
```

<a class="anchor" id="action-mailer-callbacks"></a>

## Action Mailer 回调

在 Action Mailer 中也可设置 `before_action`、`after_action` 和 `around_action`。

*   与控制器中的回调一样，可以指定块，或者方法名的符号形式；
*   在 `before_action` 中可以使用 `defaults` 和 `delivery_method_options` 方法，或者指定默认的邮件头和附件；
*   `after_action` 可以实现类似 `before_action` 的功能，而且在 `after_action` 中可以使用邮件程序动作中设定的实例变量；

    ```ruby
    class UserMailer < ApplicationMailer
      after_action :set_delivery_options,
                   :prevent_delivery_to_guests,
                   :set_business_headers
    
      def feedback_message(business, user)
        @business = business
        @user = user
        mail
      end
    
      def campaign_message(business, user)
        @business = business
        @user = user
      end
    
      private
    
        def set_delivery_options
          # 在这里可以访问 mail 实例，以及实例变量 @business 和 @user
          if @business && @business.has_smtp_settings?
            mail.delivery_method.settings.merge!(@business.smtp_settings)
          end
        end
    
        def prevent_delivery_to_guests
          if @user && @user.guest?
            mail.perform_deliveries = false
          end
        end
    
        def set_business_headers
          if @business
            headers["X-SMTPAPI-CATEGORY"] = @business.code
          end
        end
    end
    ```


*   如果在回调中把邮件主体设为 `nil` 之外的值，会阻止执行后续操作；

<a class="anchor" id="using-action-mailer-helpers"></a>

## 使用 Action Mailer 辅助方法

Action Mailer 继承自 `AbstractController`，因此为控制器定义的辅助方法都可以在邮件程序中使用。

<a class="anchor" id="action-mailer-configuration"></a>

## 配置 Action Mailer

下述配置选项最好在环境相关的文件（`environment.rb`、`production.rb`，等等）中设置。


完整的配置说明参见 [配置 Action Mailer](configuring.html#configuring-action-mailer)。

<a class="anchor" id="example-action-mailer-configuration"></a>

### Action Mailer 设置示例

可以把下面的代码添加到 `config/environments/$RAILS_ENV.rb` 文件中：

```ruby
config.action_mailer.delivery_method = :sendmail
# Defaults to:
# config.action_mailer.sendmail_settings = {
#   location: '/usr/sbin/sendmail',
#   arguments: '-i -t'
# }
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_options = {from: 'no-reply@example.com'}
```

<a class="anchor" id="action-mailer-configuration-for-gmail"></a>

### 配置 Action Mailer 使用 Gmail

Action Mailer 现在使用 [Mail](https://github.com/mikel/mail) gem，配置使用 Gmail 更简单，把下面的代码添加到 `config/environments/$RAILS_ENV.rb` 文件中即可：

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address:              'smtp.gmail.com',
  port:                 587,
  domain:               'example.com',
  user_name:            '<username>',
  password:             '<password>',
  authentication:       'plain',
  enable_starttls_auto: true  }
```

NOTE: 从 2014 年 7 月 15 日起，Google [增强了安全措施](https://support.google.com/accounts/answer/6010255)，会阻止它认为不安全的应用访问。你可以在[这里](https://www.google.com/settings/security/lesssecureapps)修改 Gmail 的设置，允许访问。如果你的 Gmail 账户启用了双因素身份验证，则要设定一个[应用密码](https://myaccount.google.com/apppasswords)，用它代替常规的密码。或者，你也可以使用其他 ESP 发送电子邮件：把上面的 `'smtp.gmail.com'` 换成提供商的地址。

<a class="anchor" id="mailer-testing"></a>

## 测试邮件程序

邮件程序的测试参阅 [测试邮件程序](testing.html#testing-your-mailers)。

<a class="anchor" id="intercepting-emails"></a>

## 拦截电子邮件

有时，在邮件发送之前需要做些修改。Action Mailer 提供了相应的钩子，可以拦截每封邮件。你可以注册一个拦截器，在交给发送程序之前修改邮件。

```ruby
class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ['sandbox@example.com']
  end
end
```

使用拦截器之前要在 Action Mailer 框架中注册，方法是在初始化脚本 `config/initializers/sandbox_email_interceptor.rb` 中添加以下代码：

```ruby
if Rails.env.staging?
  ActionMailer::Base.register_interceptor(SandboxEmailInterceptor)
end
```

NOTE: 上述代码中使用的是自定义环境，名为“staging”。这个环境和生产环境一样，但只做测试之用。关于自定义环境的详细说明，参阅 [创建 Rails 环境](configuring.html#creating-rails-environments)。
