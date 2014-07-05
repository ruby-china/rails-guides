Action Mailer 基础
==================

本文全面介绍如何在程序中收发邮件，Action Mailer 的内部机理，以及如何测试“邮件程序”（mailer）。

读完本文后，你将学到：

* 如何在 Rails 程序内收发邮件；
* 如何生成及编辑 Action Mailer 类和邮件视图；
* 如何设置 Action Mailer；
* 如何测试 Action Mailer 类；

--------------------------------------------------------------------------------

## 简介

Rails 使用 Action Mailer 实现发送邮件功能，邮件由邮件程序和视图控制。邮件程序继承自 `ActionMailer::Base`，作用和控制器类似，保存在文件夹 `app/mailers` 中，对应的视图保存在文件夹 `app/views` 中。

## 发送邮件

本节详细介绍如何创建邮件程序及对应的视图。

### 生成邮件程序的步骤

#### 创建邮件程序

{:lang="bash"}
~~~
$ rails generate mailer UserMailer
create  app/mailers/user_mailer.rb
invoke  erb
create    app/views/user_mailer
invoke  test_unit
create    test/mailers/user_mailer_test.rb
~~~

如上所示，生成邮件程序的方法和使用其他生成器一样。邮件程序在某种程度上就是控制器。执行上述命令后，生成了一个邮件程序，一个视图文件夹和一个测试文件。

如果不想使用生成器，可以手动在 `app/mailers` 文件夹中新建文件，但要确保继承自 `ActionMailer::Base`：

{:lang="ruby"}
~~~
class MyMailer < ActionMailer::Base
end
~~~

#### 编辑邮件程序

邮件程序和控制器类似，也有称为“动作”的方法，以及组织内容的视图。控制器生成的内容，例如 HTML，发送给客户端；邮件程序生成的消息则通过电子邮件发送。

文件 `app/mailers/user_mailer.rb` 中有一个空的邮件程序：

{:lang="ruby"}
~~~
class UserMailer < ActionMailer::Base
  default from: 'from@example.com'
end
~~~

下面我们定义一个名为 `welcome_email` 的方法，向用户的注册 Email 中发送一封邮件：

{:lang="ruby"}
~~~
class UserMailer < ActionMailer::Base
  default from: 'notifications@example.com'

  def welcome_email(user)
    @user = user
    @url  = 'http://example.com/login'
    mail(to: @user.email, subject: 'Welcome to My Awesome Site')
  end
end
~~~

简单说明一下这段代码。可用选项的详细说明请参见“[Action Mailer 方法](#complete-list-of-action-mailer-methods)”一节。

* `default`：一个 Hash，该邮件程序发出邮件的默认设置。上例中我们把 `:from` 邮件头设为一个值，这个类中的所有动作都会使用这个值，不过可在具体的动作中重设。
* `mail`：用于发送邮件的方法，我们传入了 `:to` 和 `:subject` 邮件头。

和控制器一样，动作中定义的实例变量可以在视图中使用。

#### 创建邮件程序的视图

在文件夹 `app/views/user_mailer/` 中新建文件 `welcome_email.html.erb`。这个视图是邮件的模板，使用 HTML 编写：

{:lang="erb"}
~~~
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
~~~

我们再创建一个纯文本视图。因为并不是所有客户端都可以显示 HTML 邮件，所以最好发送两种格式。在文件夹 `app/views/user_mailer/` 中新建文件 `welcome_email.text.erb`，写入以下代码：

{:lang="erb"}
~~~
Welcome to example.com, <%= @user.name %>
===============================================

You have successfully signed up to example.com,
your username is: <%= @user.login %>.

To login to the site, just follow this link: <%= @url %>.

Thanks for joining and have a great day!
~~~

调用 `mail` 方法后，Action Mailer 会检测到这两个模板（纯文本和 HTML），自动生成一个类型为 `multipart/alternative` 的邮件。

#### 调用邮件程序

其实，邮件程序就是渲染视图的另一种方式，只不过渲染的视图不通过 HTTP 协议发送，而是通过 Email 协议发送。因此，应该由控制器调用邮件程序，在成功注册用户后给用户发送一封邮件。过程相当简单。

首先，生成一个简单的 `User` 脚手架：

{:lang="bash"}
~~~
$ rails generate scaffold user name email login
$ rake db:migrate
~~~

这样就有一个可用的用户模型了。我们需要编辑的是文件 `app/controllers/users_controller.rb`，修改 `create` 动作，成功保存用户后调用 `UserMailer.welcome_email` 方法，向刚注册的用户发送邮件：

{:lang="ruby"}
~~~
class UsersController < ApplicationController
  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        # Tell the UserMailer to send a welcome email after save
        UserMailer.welcome_email(@user).deliver

        format.html { redirect_to(@user, notice: 'User was successfully created.') }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
end
~~~

`welcome_email` 方法返回 `Mail::Message` 对象，在其上调用 `deliver` 方法发送邮件。

### 自动编码邮件头

Action Mailer 会自动编码邮件头和邮件主体中的多字节字符。

更复杂的需求，例如使用其他字符集和自编码文字，请参考 [Mail](https://github.com/mikel/mail) 库的用法。

### Action Mailer 方法

下面这三个方法是邮件程序中最重要的方法：

* `headers`：设置邮件头，可以指定一个由字段名和值组成的 Hash，或者使用 `headers[:field_name] = 'value'` 形式；
* `attachments`：添加邮件的附件，例如，`attachments['file-name.jpg'] = File.read('file-name.jpg')`；
* `mail`：发送邮件，传入的值为 Hash 形式的邮件头，`mail` 方法负责创建邮件内容，纯文本或多种格式，取决于定义了哪种邮件模板；

#### 添加附件

在 Action Mailer 中添加附件十分方便。

*   传入文件名和内容，Action Mailer 和 [Mail](https://github.com/mikel/mail) gem 会自动猜测附件的 MIME 类型，设置编码并创建附件。

    {:lang="ruby"}
    ~~~
    attachments['filename.jpg'] = File.read('/path/to/filename.jpg')
    ~~~

    触发 `mail` 方法后，会发送一个由多部分组成的邮件，附件嵌套在类型为 `multipart/mixed` 的顶级结构中，其中第一部分的类型为 `multipart/alternative`，包含纯文本和 HTML 格式的邮件内容。

NOTE: Mail gem 会自动使用 Base64 编码附件。如果想使用其他编码方式，可以先编码好，再把编码后的附件通过 Hash 传给 `attachments` 方法。

*   传入文件名，指定邮件头和内容，Action Mailer 和 Mail gem 会使用传入的参数添加附件。

    {:lang="ruby"}
    ~~~
    encoded_content = SpecialEncode(File.read('/path/to/filename.jpg'))
    attachments['filename.jpg'] = {mime_type: 'application/x-gzip',
                                   encoding: 'SpecialEncoding',
                                   content: encoded_content }
    ~~~

NOTE: 如果指定了 `encoding` 键，Mail 会认为附件已经编码了，不会再使用 Base64 编码附件。

#### 使用行间附件

在 Action Mailer 3.0 中使用行间附件比之前版本简单得多。

*   首先，在 `attachments` 方法上调用 `inline` 方法，告诉 Mail 这是个行间附件：

    {:lang="ruby"}
    ~~~
    def welcome
      attachments.inline['image.jpg'] = File.read('/path/to/image.jpg')
    end
    ~~~

*   在视图中，可以直接使用 `attachments` 方法，将其视为一个 Hash，指定想要使用的附件，在其上调用 `url` 方法，再把结果传给 `image_tag` 方法：

    {:lang="erb"}
    ~~~
    <p>Hello there, this is our image</p>

    <%= image_tag attachments['image.jpg'].url %>
    ~~~

*   因为我们只是简单的调用了 `image_tag` 方法，所以和其他图片一样，在附件地址之后，还可以传入选项 Hash：

    {:lang="erb"}
    ~~~
    <p>Hello there, this is our image</p>

    <%= image_tag attachments['image.jpg'].url, alt: 'My Photo',
                                                class: 'photos' %>
    ~~~

#### 发给多个收件人

要想把一封邮件发送给多个收件人，例如通知所有管理员有新用户注册网站，可以把 `:to` 键的值设为一组邮件地址。这一组邮件地址可以是一个数组；也可以是一个字符串，使用逗号分隔各个地址。

{:lang="ruby"}
~~~
class AdminMailer < ActionMailer::Base
  default to: Proc.new { Admin.pluck(:email) },
          from: 'notification@example.com'

  def new_registration(user)
    @user = user
    mail(subject: "New User Signup: #{@user.email}")
  end
end
~~~

使用类似的方式还可添加抄送和密送，分别设置 `:cc` 和 `:bcc` 键即可。

#### 在邮件中显示名字

有时希望收件人在邮件中看到自己的名字，而不只是邮件地址。实现这种需求的方法是把邮件地址写成 `"Full Name <email>"` 格式。

{:lang="ruby"}
~~~
def welcome_email(user)
  @user = user
  email_with_name = "#{@user.name} <#{@user.email}>"
  mail(to: email_with_name, subject: 'Welcome to My Awesome Site')
end
~~~

### 邮件程序的视图

邮件程序的视图保存在文件夹 `app/views/name_of_mailer_class` 中。邮件程序之所以知道使用哪个视图，是因为视图文件名和邮件程序的方法名一致。如前例，`welcome_email` 方法的 HTML 格式视图是 `app/views/user_mailer/welcome_email.html.erb`，纯文本格式视图是 `welcome_email.text.erb`。

要想修改动作使用的视图，可以这么做：

{:lang="ruby"}
~~~
class UserMailer < ActionMailer::Base
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
~~~

此时，邮件程序会在文件夹 `app/views/notifications` 中寻找名为 `another` 的视图。`template_path` 的值可以是一个数组，按照顺序查找视图。

如果想获得更多灵活性，可以传入一个代码块，渲染指定的模板，或者不使用模板，渲染行间代码或纯文本：

{:lang="ruby"}
~~~
class UserMailer < ActionMailer::Base
  default from: 'notifications@example.com'

  def welcome_email(user)
    @user = user
    @url  = 'http://example.com/login'
    mail(to: @user.email,
         subject: 'Welcome to My Awesome Site') do |format|
      format.html { render 'another_template' }
      format.text { render text: 'Render text' }
    end
  end
end
~~~

上述代码会使用 `another_template.html.erb` 渲染 HTML，使用 `'Render text'` 渲染纯文本。这里用到的 `render` 方法和控制器中的一样，所以选项也都是一样的，例如 `:text`、`:inline` 等。

### Action Mailer 布局

和控制器一样，邮件程序也可以使用布局。布局的名字必须和邮件程序类一样，例如 `user_mailer.html.erb` 和 `user_mailer.text.erb` 会自动识别为邮件程序的布局。

如果想使用其他布局文件，可以在邮件程序中调用 `layout` 方法：

{:lang="ruby"}
~~~
class UserMailer < ActionMailer::Base
  layout 'awesome' # use awesome.(html|text).erb as the layout
end
~~~

还是跟控制器布局一样，在邮件程序的布局中调用 `yield` 方法可以渲染视图。

在 `format` 代码块中可以把 `layout: 'layout_name'` 选项传给 `render` 方法，指定使用其他布局：

{:lang="ruby"}
~~~
class UserMailer < ActionMailer::Base
  def welcome_email(user)
    mail(to: user.email) do |format|
      format.html { render layout: 'my_layout' }
      format.text
    end
  end
end
~~~

上述代码会使用文件 `my_layout.html.erb` 渲染 HTML 格式；如果文件 `user_mailer.text.erb` 存在，会用来渲染纯文本格式。

### 在 Action Mailer 视图中生成 URL

和控制器不同，邮件程序不知道请求的上下文，因此要自己提供 `:host` 参数。

一个程序的 `:host` 参数一般是相同的，可以在 `config/application.rb` 中做全局设置：

{:lang="ruby"}
~~~
config.action_mailer.default_url_options = { host: 'example.com' }
~~~

#### 使用 `url_for` 方法生成 URL

使用 `url_for` 方法时必须指定 `only_path: false` 选项，这样才能确保生成绝对 URL，因为默认情况下如果不指定 `:host` 选项，`url_for` 帮助方法生成的是相对 URL。

{:lang="erb"}
~~~
<%= url_for(controller: 'welcome',
            action: 'greeting',
            only_path: false) %>
~~~

如果没全局设置 `:host` 选项，使用 `url_for` 方法时一定要指定 `only_path: false` 选项。

{:lang="erb"}
~~~
<%= url_for(host: 'example.com',
            controller: 'welcome',
            action: 'greeting') %>
~~~

NOTE: 如果指定了 `:host` 选项，Rails 会生成绝对 URL，没必要再指定 `only_path: false`。

#### 使用具名路由生成 URL

邮件客户端不能理解网页中的上下文，没有生成完整地址的基地址，所以使用具名路由帮助方法时一定要使用 `_url` 形式。

如果没有设置全局 `:host` 参数，一定要将其传给 URL 帮助方法。

{:lang="erb"}
~~~
<%= user_url(@user, host: 'example.com') %>
~~~

### 发送多种格式邮件

如果同一动作有多个模板，Action Mailer 会自动发送多种格式的邮件。例如前面的 `UserMailer`，如果在 `app/views/user_mailer` 文件夹中有 `welcome_email.text.erb` 和 `welcome_email.html.erb` 两个模板，Action Mailer 会自动发送 HTML 和纯文本格式的邮件。

格式的顺序由 `ActionMailer::Base.default` 方法的 `:parts_order` 参数决定。

### 发送邮件时动态设置发送选项

如果在发送邮件时想重设发送选项（例如，SMTP 密令），可以在邮件程序动作中使用 `delivery_method_options` 方法。

{:lang="ruby"}
~~~
class UserMailer < ActionMailer::Base
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
~~~

### 不渲染模板

有时可能不想使用布局，直接使用字符串渲染邮件内容，可以使用 `:body` 选项。但别忘了指定 `:content_type` 选项，否则 Rails 会使用默认值 `text/plain`。

{:lang="ruby"}
~~~
class UserMailer < ActionMailer::Base
  def welcome_email(user, email_body)
    mail(to: user.email,
         body: email_body,
         content_type: "text/html",
         subject: "Already rendered!")
  end
end
~~~

## 接收邮件

使用 Action Mailer 接收和解析邮件做些额外设置。接收邮件之前，要先设置系统，把邮件转发给程序。所以，在 Rails 程序中接收邮件要完成以下步骤：

* 在邮件程序中实现 `receive` 方法；

* 设置邮件服务器，把邮件转发到 `/path/to/app/bin/rails runner 'UserMailer.receive(STDIN.read)'`；

在邮件程序中定义 `receive` 方法后，Action Mailer 会解析收到的邮件，生成邮件对象，解码邮件内容，实例化一个邮件程序，把邮件对象传给邮件程序的 `receive` 实例方法。下面举个例子：

{:lang="ruby"}
~~~
class UserMailer < ActionMailer::Base
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
~~~

## Action Mailer 回调

在 Action Mailer 中也可设置 `before_action`、`after_action` 和 `around_action`。

*   和控制器中的回调一样，可以传入代码块，或者方法名的符号形式；

*   在 `before_action` 中可以使用 `defaults` 和 `delivery_method_options` 方法，或者指定默认邮件头和附件；

*   `after_action` 可以实现类似 `before_action` 的功能，而且在 `after_action` 中可以使用实例变量；

    {:lang="ruby"}
    ~~~
    class UserMailer < ActionMailer::Base
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
          # You have access to the mail instance,
          # @business and @user instance variables here
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
    ~~~

*   如果在回调中把邮件主体设为 `nil` 之外的值，会阻止执行后续操作；

## 使用 Action Mailer 帮助方法

Action Mailer 继承自 `AbstractController`，因此为控制器定义的帮助方法都可以在邮件程序中使用。

## 设置 Action Mailer

下述设置选项最好在环境相关的文件（`environment.rb`，`production.rb` 等）中设置。

| 设置项         | 说明        |
|---------------|-------------|
| `logger` | 运行邮件程序时生成日志信息。设为 `nil` 禁用日志。可设为 Ruby 自带的 `Logger` 或 `Log4r` 库。|
| `smtp_settings` | 设置 `:smtp` 发送方式的详情。 |
| `sendmail_settings` | 设置 `:sendmail` 发送方式的详情。 |
| `raise_delivery_errors` | 如果邮件发送失败，是否抛出异常。仅当外部邮件服务器设置为立即发送才有效。 |
| `delivery_method` | 设置发送方式，可设为 `:smtp`（默认）、`:sendmail`、`:file` 和 `:test`。详情参阅 [API 文档](http://api.rubyonrails.org/classes/ActionMailer/Base.html)。 |
| `perform_deliveries` | 调用 `deliver` 方法时是否真发送邮件。默认情况下会真的发送，但在功能测试中可以不发送。 |
| `deliveries` | 把通过 Action Mailer 使用 `:test` 方式发送的邮件保存到一个数组中，协助单元测试和功能测试。 |
| `default_options` | 为 `mail` 方法设置默认选项值（`:from`，`:reply_to` 等）。 |

完整的设置说明参见“设置 Rails 程序”一文中的“[设置 Action Mailer]({{ site.baseurl }}/configuring.html#configuring-action-mailer)”一节。

### Action Mailer 设置示例

可以把下面的代码添加到文件 `config/environments/$RAILS_ENV.rb` 中：

{:lang="ruby"}
~~~
config.action_mailer.delivery_method = :sendmail
# Defaults to:
# config.action_mailer.sendmail_settings = {
#   location: '/usr/sbin/sendmail',
#   arguments: '-i -t'
# }
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_options = {from: 'no-reply@example.com'}
~~~

### 设置 Action Mailer 使用 Gmail

Action Mailer 现在使用 [Mail](https://github.com/mikel/mail) gem，针对 Gmail 的设置更简单，把下面的代码添加到文件 `config/environments/$RAILS_ENV.rb`  中即可：

{:lang="ruby"}
~~~
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address:              'smtp.gmail.com',
  port:                 587,
  domain:               'example.com',
  user_name:            '<username>',
  password:             '<password>',
  authentication:       'plain',
  enable_starttls_auto: true  }
~~~

## 测试邮件程序

邮件程序的测试参阅“[Rails 程序测试指南]({{ site.baseurl}}、testing.html#testing-your-mailers)”。

## 拦截邮件

有时，在邮件发送之前需要做些修改。Action Mailer 提供了相应的钩子，可以拦截每封邮件。你可以注册一个拦截器，在交给发送程序之前修改邮件。

{:lang="ruby"}
~~~
class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ['sandbox@example.com']
  end
end
~~~

使用拦截器之前要在 Action Mailer 框架中注册，方法是在初始化脚本 `config/initializers/sandbox_email_interceptor.rb` 中添加以下代码：

{:lang="ruby"}
~~~
ActionMailer::Base.register_interceptor(SandboxEmailInterceptor) if Rails.env.staging?
~~~

NOTE: 上述代码中使用的是自定义环境，名为“staging”。这个环境和生产环境一样，但只做测试之用。关于自定义环境的详细介绍，参阅“[新建 Rails 环境]({{ site.baseurl }}/configuring.html#creating-rails-environments)”一节。
