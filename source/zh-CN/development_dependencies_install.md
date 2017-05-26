# 安装开发依赖

本文说明如何搭建 Ruby on Rails 核心开发环境。

读完本文后，您将学到：

*   如何设置你的设备供 Rails 开发；
*   如何运行 Rails 测试组件中特定的单元测试组；
*   Rails 测试组件中的 Active Record 部分是如何运作的。

-----------------------------------------------------------------------------

<a class="anchor" id="development-dependencies-install-the-easy-way"></a>

## 简单方式

搭建开发环境最简单、也是推荐的方式是使用 [Rails 开发虚拟机](https://github.com/rails/rails-dev-box)。

<a class="anchor" id="development-dependencies-install-the-hard-way"></a>

## 笨拙方式

如果你不便使用 Rails 开发虚拟机，参见下述说明。这些步骤说明如何自己动手搭建开发环境，供 Ruby on Rails 核心开发使用。

<a class="anchor" id="install-git"></a>

### 安装 Git

Ruby on Rails 使用 Git 做源码控制。Git 的安装说明参见[官网](http://git-scm.com/)。网上有很多学习 Git 的资源：

*   [Try Git](http://try.github.io/) 是个交互式课程，教你基本用法。
*   [官方文档](http://git-scm.com/documentation)十分全面，也有一些 Git 基本用法的视频。
*   [Everyday Git](http://schacon.github.io/git/everyday.html) 教你一些技能，足够日常使用。
*   [GitHub 帮助页面](http://help.github.com/)中有很多 Git 资源的链接。
*   [Pro Git](http://git-scm.com/book) 是一本讲解 Git 的书，基于知识共享许可证发布。

<a class="anchor" id="clone-the-ruby-on-rails-repository"></a>

### 克隆 Ruby on Rails 仓库

进入你想保存 Ruby on Rails 源码的文件夹，然后执行（会创建 `rails` 子目录）：

```sh
$ git clone git://github.com/rails/rails.git
$ cd rails
```

<a class="anchor" id="set-up-and-run-the-tests"></a>

### 准备工作和运行测试

提交的代码必须通过测试组件。不管你是编写新的补丁，还是评估别人的代码，都要运行测试。

首先，安装 `sqlite3` gem 所需的 SQLite3 及其开发文件 。macOS 用户这么做：

```sh
$ brew install sqlite3
```

Ubuntu 用户这么做：

```sh
$ sudo apt-get install sqlite3 libsqlite3-dev
```

Fedora 或 CentOS 用户这么做：

```sh
$ sudo yum install sqlite3 sqlite3-devel
```

Arch Linux 用户要这么做：

```sh
$ sudo pacman -S sqlite
```

FreeBSD 用户这么做：

```sh
# pkg install sqlite3
```

或者编译 `databases/sqlite3` port。

然后安装最新版 [Bundler](http://bundler.io/)：

```sh
$ gem install bundler
$ gem update bundler
```

再执行：

```sh
$ bundle install --without db
```

这个命令会安装除了 MySQL 和 PostgreSQL 的 Ruby 驱动之外的所有依赖。稍后再安装那两个驱动。

NOTE: 如果想运行使用 memcached 的测试，要安装并运行 memcached。

在 macOS 中可以使用 [Homebrew](http://brew.sh/) 安装 memcached：

```sh
$ brew install memcached
```

在 Ubuntu 中可以使用 apt-get 安装 memcached：

```sh
$ sudo apt-get install memcached
```

在 Fedora 或 CentOS 中这么做：

```sh
$ sudo yum install memcached
```

在 Arch Linux 中这么做：

```sh
$ sudo pacman -S memcached
```

在 FreeBSD 中这么做：

```sh
# pkg install memcached
```

或者编译 `databases/memcached` port。


安装好依赖之后，可以执行下述命令运行测试组件：

```sh
$ bundle exec rake test
```

还可以运行某个组件（如 Action Pack）的测试，方法是进入组件所在的目录，然后执行相同的命令：

```sh
$ cd actionpack
$ bundle exec rake test
```

如果想运行某个目录中的测试，使用 `TEST_DIR` 环境变量指定。例如，下述命令只运行 `railties/test/generators` 目录中的测试：

```sh
$ cd railties
$ TEST_DIR=generators bundle exec rake test
```

可以像下面这样运行某个文件中的测试：

```sh
$ cd actionpack
$ bundle exec ruby -Itest test/template/form_helper_test.rb
```

还可以运行某个文件中的某个测试：

```sh
$ cd actionpack
$ bundle exec ruby -Itest path/to/test.rb -n test_name
```

<a class="anchor" id="railties-setup"></a>

### 为 Railties 做准备

有些 Railties 测试依赖 JavaScript 运行时环境，因此要安装 [Node.js](https://nodejs.org/)。

<a class="anchor" id="active-record-setup"></a>

### 为 Active Record 做准备

Active Record 的测试组件运行三次：一次针对 SQLite3，一次针对 MySQL，还有一次针对 PostgreSQL。下面说明如何为这三种数据库搭建环境。

WARNING: 编写 Active Record 代码时，必须确保测试至少能在 MySQL、PostgreSQL 和 SQLite3 中通过。如果只使用 MySQL 测试，虽然测试能通过，但是不同适配器之间的差异没有考虑到。


<a class="anchor" id="database-configuration"></a>

#### 数据库配置

Active Record 测试组件需要一个配置文件：`activerecord/test/config.yml`。`activerecord/test/config.example.yml` 文件中有些示例。你可以复制里面的内容，然后根据你的环境修改。

<a class="anchor" id="mysql-and-postgresql"></a>

#### MySQL 和 PostgreSQL

为了运行针对 MySQL 和 PostgreSQL 的测试组件，要安装相应的 gem。首先安装服务器、客户端库和开发文件。

在 macOS 中可以这么做：

```sh
$ brew install mysql
$ brew install postgresql
```

然后按照 Homebrew 给出的说明做。

在 Ubuntu 中只需这么做：

```sh
$ sudo apt-get install mysql-server libmysqlclient-dev
$ sudo apt-get install postgresql postgresql-client postgresql-contrib libpq-dev
```

在 Fedora 或 CentOS 中只需这么做：

```sh
$ sudo yum install mysql-server mysql-devel
$ sudo yum install postgresql-server postgresql-devel
```

MySQL 不再支持 Arch Linux，因此你要使用 MariaDB（参见[这个声明](https://www.archlinux.org/news/mariadb-replaces-mysql-in-repositories/)）：

```sh
$ sudo pacman -S mariadb libmariadbclient mariadb-clients
$ sudo pacman -S postgresql postgresql-libs
```

FreeBSD 用户要这么做：

```sh
# pkg install mysql56-client mysql56-server
# pkg install postgresql94-client postgresql94-server
```

或者通过 port 安装（在 `databases` 文件夹中）。在安装 MySQL 的过程中如何遇到问题，请查阅 [MySQL 文档](http://dev.mysql.com/doc/refman/5.1/en/freebsd-installation.html)。

安装好之后，执行下述命令：

```sh
$ rm .bundle/config
$ bundle install
```

首先，我们要删除 `.bundle/config` 文件，因为 Bundler 记得那个文件中的配置。我们前面配置了，不安装“db”分组（此外也可以修改那个文件）。

为了使用 MySQL 运行测试组件，我们要创建一个名为 `rails` 的用户，并且赋予它操作测试数据库的权限：

```sh
$ mysql -uroot -p

mysql> CREATE USER 'rails'@'localhost';
mysql> GRANT ALL PRIVILEGES ON activerecord_unittest.*
       to 'rails'@'localhost';
mysql> GRANT ALL PRIVILEGES ON activerecord_unittest2.*
       to 'rails'@'localhost';
mysql> GRANT ALL PRIVILEGES ON inexistent_activerecord_unittest.*
       to 'rails'@'localhost';
```

然后创建测试数据库：

```sh
$ cd activerecord
$ bundle exec rake db:mysql:build
```

PostgreSQL 的身份验证方式有所不同。为了使用开发账户搭建开发环境，在 Linux 或 BSD 中要这么做：

```sh
$ sudo -u postgres createuser --superuser $USER
```

在 macOS 中这么做：

```sh
$ createuser --superuser $USER
```

然后，执行下述命令创建测试数据库：

```sh
$ cd activerecord
$ bundle exec rake db:postgresql:build
```

可以执行下述命令创建 PostgreSQL 和 MySQL 的测试数据库：

```sh
$ cd activerecord
$ bundle exec rake db:create
```

可以使用下述命令清理数据库：

```sh
$ cd activerecord
$ bundle exec rake db:drop
```

NOTE: 使用 rake 任务创建测试数据库能保障数据库使用正确的字符集和排序规则。


NOTE: 在 PostgreSQL 9.1.x 及早期版本中激活 HStore 扩展会看到这个提醒（或本地化的提醒）：“WARNING: => is deprecated as an operator”。


如果使用其他数据库，默认的连接信息参见 `activerecord/test/config.yml` 或 `activerecord/test/config.example.yml` 文件。如果有必要，可以在你的设备中编辑 `activerecord/test/config.yml` 文件，提供不同的凭据。不过显然，不应该把这种改动推送回 Rails 仓库。

<a class="anchor" id="action-cable-setup"></a>

### 为 Action Cable 做准备

Action Cable 默认使用 Redis 作为订阅适配器（[详情](action_cable_overview.html#broadcasting)），因此为了运行 Action Cable 的测试，要安装并运行 Redis。

<a class="anchor" id="install-redis-from-source"></a>

#### 从源码安装 Redis

Redis 的文档不建议通过包管理器安装，因为那里的包往往是过时的。[Redis 的文档](http://redis.io/download#installation)详细说明了如何从源码安装，以及如何运行 Redis 服务器。

<a class="anchor" id="install-redis-from-package-manager"></a>

#### 使用包管理器安装

在 macOS 中可以执行下述命令：

```sh
$ brew install redis
```

然后按照 Homebrew 给出的说明做。

在 Ubuntu 中只需运行：

```sh
$ sudo apt-get install redis-server
```

在 Fedora 或 CentOS（要启用 EPEL）中运行：

```sh
$ sudo yum install redis
```

如果使用 Arch Linux，运行：

```sh
$ sudo pacman -S redis
$ sudo systemctl start redis
```

FreeBSD 用户要运行下述命令：

```sh
# portmaster databases/redis
```
