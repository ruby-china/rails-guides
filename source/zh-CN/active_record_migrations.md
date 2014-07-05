Active Record 数据库迁移
=======================

迁移是 Active Record 提供的一个功能，按照时间顺序管理数据库模式。使用迁移，无需编写 SQL，使用简单的 Ruby DSL 就能修改数据表。

读完本文，你将学到：

* 生成迁移文件的生成器；
* Active Record 提供用来修改数据库的方法；
* 管理迁移和数据库模式的 Rake 任务；
* 迁移和 `schema.rb` 文件的关系；

--------------------------------------------------------------------------------

## 迁移简介

迁移使用一种统一、简单的方式，按照时间顺序修改数据库的模式。迁移使用 Ruby DSL 编写，因此不用手动编写 SQL 语句，对数据库的操作和所用的数据库种类无关。

你可以把每个迁移看做数据库的一个修订版本。数据库中一开始什么也没有，各个迁移会添加或删除数据表、字段或记录。Active Record 知道如何按照时间线更新数据库，不管数据库现在的模式如何，都能更新到最新结构。同时，Active Record 还会更新 `db/schema.rb` 文件，匹配最新的数据库结构。

下面是一个迁移示例：

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

这个迁移创建了一个名为 `products` 的表，然后在表中创建字符串字段 `name` 和文本字段 `description`。名为 `id` 的主键字段会被自动创建。`id` 字段是所有 Active Record 模型的默认主键。`timestamps` 方法创建两个字段：`created_at` 和 `updated_at`。如果数据表中有这两个字段，Active Record 会负责操作。

注意，对数据库的改动按照时间向前 推移。运行迁移之前，数据表还不存在。运行迁移后，才会创建数据表。Active Record 知道如何撤销迁移，如果回滚这次迁移，数据表会被删除。

在支持事物的数据库中，对模式的改动会在一个事物中执行。如果数据库不支持事物，迁移失败时，成功执行的操作将无法回滚。如要回滚，必须手动改回来。

I> 某些查询无法在事物中运行。如果适配器支持 DDL 事物，可以在某个迁移中调用 `disable_ddl_transaction!` 方法禁用。

如果想在迁移中执行 Active Record 不知如何撤销的操作，可以使用 `reversible` 方法：

```ruby
class ChangeProductsPrice < ActiveRecord::Migration
  def change
    reversible do |dir|
      change_table :products do |t|
        dir.up   { t.change :price, :string }
        dir.down { t.change :price, :integer }
      end
    end
  end
end
```

或者不用 `change` 方法，分别使用 `up` 和 `down` 方法：

```ruby
class ChangeProductsPrice < ActiveRecord::Migration
  def up
    change_table :products do |t|
      t.change :price, :string
    end
  end

  def down
    change_table :products do |t|
      t.change :price, :integer
    end
  end
end
```

## 创建迁移

### 单独创建迁移

迁移文件存储在 `db/migrate` 文件夹中，每个迁移保存在一个文件中。文件名采用 `YYYYMMDDHHMMSS_create_products.rb` 形式，即一个 UTC 时间戳后加以下划线分隔的迁移名。迁移的类名（驼峰式）要和文件名时间戳后面的部分匹配。例如，在 `20080906120000_create_products.rb` 文件中要定义 `CreateProducts` 类；在 `20080906120001_add_details_to_products.rb` 文件中要定义 `AddDetailsToProducts` 类。文件名中的时间戳决定要运行哪个迁移，以及按照什么顺序运行。从其他程序中复制迁移，或者自己生成迁移时，要注意运行的顺序。

自己计算时间戳不是件简单的事，所以 Active Record 提供了一个生成器：

```bash
$ rails generate migration AddPartNumberToProducts
```

这个命令生成一个空的迁移，但名字已经起好了：

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
  end
end
```

如果迁移的名字是“AddXXXToYYY”或者“RemoveXXXFromYYY”这种格式，而且后面跟着一个字段名和类型列表，那么迁移中会生成合适的 `add_column` 或 `remove_column` 语句。

```bash
$ rails generate migration AddPartNumberToProducts part_number:string
```

这个命令生成的迁移如下：

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
  end
end
```

如果想为新建的字段创建添加索引，可以这么做：

```bash
$ rails generate migration AddPartNumberToProducts part_number:string:index
```

这个命令生成的迁移如下：

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
    add_index :products, :part_number
  end
end
```

类似地，还可以生成删除字段的迁移：

```bash
$ rails generate migration RemovePartNumberFromProducts part_number:string
```

这个命令生成的迁移如下：

```ruby
class RemovePartNumberFromProducts < ActiveRecord::Migration
  def change
    remove_column :products, :part_number, :string
  end
end
```

迁移生成器不单只能创建一个字段，例如：

```bash
$ rails generate migration AddDetailsToProducts part_number:string price:decimal
```

生成的迁移如下：

```ruby
class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
    add_column :products, :price, :decimal
  end
end
```

如果迁移名是“CreateXXX”形式，后面跟着一串字段名和类型声明，迁移就会创建名为“XXX”的表，以及相应的字段。例如：

```bash
$ rails generate migration CreateProducts name:string part_number:string
```

生成的迁移如下：

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :part_number
    end
  end
end
```

生成器生成的只是一些基础代码，你可以根据需要修改 `db/migrate/YYYYMMDDHHMMSS_add_details_to_products.rb` 文件，增删代码。

在生成器中还可把字段类型设为 `references`（还可使用 `belongs_to`）。例如：

```bash
$ rails generate migration AddUserRefToProducts user:references
```

生成的迁移如下：

```ruby
class AddUserRefToProducts < ActiveRecord::Migration
  def change
    add_reference :products, :user, index: true
  end
end
```

这个迁移会创建 `user_id` 字段，并建立索引。

如果迁移名中包含 `JoinTable`，生成器还会创建联合数据表：

```bash
rails g migration CreateJoinTableCustomerProduct customer product
```

生成的迁移如下：

```ruby
class CreateJoinTableCustomerProduct < ActiveRecord::Migration
  def change
    create_join_table :customers, :products do |t|
      # t.index [:customer_id, :product_id]
      # t.index [:product_id, :customer_id]
    end
  end
end
```

### 模型生成器

模型生成器和脚手架生成器会生成合适的迁移，创建模型。迁移中会包含创建所需数据表的代码。如果在生成器中指定了字段，还会生成创建字段的代码。例如，运行下面的命令：

```bash
$ rails generate model Product name:string description:text
```

会生成如下的迁移：

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

字段的名字和类型数量不限。

### 支持的类型修饰符

在字段类型后面，可以在花括号中添加选项。可用的修饰符如下：

* `limit`：设置 `string/text/binary/integer` 类型字段的最大值；
* `precision`：设置 `decimal` 类型字段的精度，即数字的位数；
* `scale`：设置 `decimal` 类型字段小数点后的数字位数；
* `polymorphic`：为 `belongs_to` 关联添加 `type` 字段；
* `null`：是否允许该字段的值为 `NULL`；

例如，执行下面的命令：

```bash
$ rails generate migration AddDetailsToProducts 'price:decimal{5,2}' supplier:references{polymorphic}
```

生成的迁移如下：

```ruby
class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :price, :decimal, precision: 5, scale: 2
    add_reference :products, :supplier, polymorphic: true, index: true
  end
end
```

## 编写迁移

使用前面介绍的生成器生成迁移后，就可以开始写代码了。

### 创建数据表

`create_table` 方法最常用，大多数时候都会由模型或脚手架生成器生成。典型的用例如下：

```ruby
create_table :products do |t|
  t.string :name
end
```

这个迁移会创建 `products` 数据表，在数据表中创建 `name` 字段（后面会介绍，还会自动创建 `id` 字段）。

默认情况下，`create_table` 方法会创建名为 `id` 的主键。通过 `:primary_key` 选项可以修改主键名（修改后别忘了修改相应的模型）。如果不想生成主键，可以传入 `id: false` 选项。如果设置数据库的选项，可以在 `:options` 选择中使用 SQL。例如：

```ruby
create_table :products, options: "ENGINE=BLACKHOLE" do |t|
  t.string :name, null: false
end
```

这样设置之后，会在创建数据表的 SQL 语句后面加上 `ENGINE=BLACKHOLE`。（MySQL 默认的选项是 `ENGINE=InnoDB`）

### 创建联合数据表

`create_join_table` 方法用来创建 HABTM 联合数据表。典型的用例如下：

```ruby
create_join_table :products, :categories
```

这段代码会创建一个名为 `categories_products` 的数据表，包含两个字段：`category_id` 和 `product_id`。这两个字段的 `:null` 选项默认情况都是 `false`，不过可在 `:column_options` 选项中设置。

```ruby
create_join_table :products, :categories, column_options: {null: true}
```

这段代码会把 `product_id` 和 `category_id` 字段的 `:null` 选项设为 `true`。

如果想修改数据表的名字，可以传入 `:table_name` 选项。例如：

```ruby
create_join_table :products, :categories, table_name: :categorization
```

创建的数据表名为 `categorization`。

`create_join_table` 还可接受代码库，用来创建索引（默认无索引）或其他字段。

```ruby
create_join_table :products, :categories do |t|
  t.index :product_id
  t.index :category_id
end
```

### 修改数据表

有一个和 `create_table` 类似地方法，名为 `change_table`，用来修改现有的数据表。其用法和 `create_table` 类似，不过传入块的参数知道更多技巧。例如：

```ruby
change_table :products do |t|
  t.remove :description, :name
  t.string :part_number
  t.index :part_number
  t.rename :upccode, :upc_code
end
```

这段代码删除了 `description` 和 `name` 字段，创建 `part_number` 字符串字段，并建立索引，最后重命名 `upccode` 字段。

### 如果帮助方法不够用

如果 Active Record 提供的帮助方法不够用，可以使用 `excute` 方法，执行任意的 SQL 语句：

```ruby
Product.connection.execute('UPDATE `products` SET `price`=`free` WHERE 1')
```

各方法的详细用法请查阅 API 文档：

- [`ActiveRecord::ConnectionAdapters::SchemaStatements`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html)：包含可在 `change`，`up` 和 `down` 中使用的方法；
- [`ActiveRecord::ConnectionAdapters::TableDefinition`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html)：包含可在 `create_table` 方法的块参数上调用的方法；
- [`ActiveRecord::ConnectionAdapters::Table`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/Table.html)：包含可在 `change_table` 方法的块参数上调用的方法；

### 使用 `change` 方法

`change` 是迁移中最常用的方法，大多数情况下都能完成指定的操作，而且 Active Record 知道如何撤这些操作。目前，在 `change` 方法中只能使用下面的方法：

* `add_column`
* `add_index`
* `add_reference`
* `add_timestamps`
* `create_table`
* `create_join_table`
* `drop_table`（必须提供代码块）
* `drop_join_table`（必须提供代码块）
* `remove_timestamps`
* `rename_column`
* `rename_index`
* `remove_reference`
* `rename_table`

只要在块中不使用 `change`、`change_default` 或 `remove` 方法，`change_table` 中的操作也是可逆的。

如果要使用任何其他方法，可以使用 `reversible` 方法，或者不定义 `change` 方法，而分别定义 `up` 和 `down` 方法。

### 使用 `reversible` 方法

Active Record 可能不知如何撤销复杂的迁移操作，这时可以使用 `reversible` 方法指定运行迁移和撤销迁移时怎么操作。例如：

```ruby
class ExampleMigration < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.references :category
    end

    reversible do |dir|
      dir.up do
        #add a foreign key
        execute <<-SQL
          ALTER TABLE products
            ADD CONSTRAINT fk_products_categories
            FOREIGN KEY (category_id)
            REFERENCES categories(id)
        SQL
      end
      dir.down do
        execute <<-SQL
          ALTER TABLE products
            DROP FOREIGN KEY fk_products_categories
        SQL
      end
    end

    add_column :users, :home_page_url, :string
    rename_column :users, :email, :email_address
  end
```

使用 `reversible` 方法还能确保操作按顺序执行。在上面的例子中，如果撤销迁移，`down` 代码块会在 `home_page_url` 字段删除后、`products` 数据表删除前运行。

有时，迁移的操作根本无法撤销，例如删除数据。这是，可以在 `down` 代码块中抛出 `ActiveRecord::IrreversibleMigration` 异常。如果有人尝试撤销迁移，会看到一个错误消息，告诉他无法撤销。

### 使用 `up` 和 `down` 方法

在迁移中可以不用 `change` 方法，而用 `up` 和 `down` 方法。`up` 方法定义要对数据库模式做哪些操作，`down` 方法用来撤销这些操作。也就是说，如果执行 `up` 后立即执行 `down`，数据库的模式应该没有任何变化。例如，在 `up` 中创建了数据表，在 `down` 方法中就要将其删除。撤销时最好按照添加的相反顺序进行。前一节中的 `reversible` 用法示例代码可以改成：

```ruby
class ExampleMigration < ActiveRecord::Migration
  def up
    create_table :products do |t|
      t.references :category
    end

    # add a foreign key
    execute <<-SQL
      ALTER TABLE products
        ADD CONSTRAINT fk_products_categories
        FOREIGN KEY (category_id)
        REFERENCES categories(id)
    SQL

    add_column :users, :home_page_url, :string
    rename_column :users, :email, :email_address
  end

  def down
    rename_column :users, :email_address, :email
    remove_column :users, :home_page_url

    execute <<-SQL
      ALTER TABLE products
        DROP FOREIGN KEY fk_products_categories
    SQL

    drop_table :products
  end
end
```

如果迁移不可撤销，应该在 `down` 方法中抛出 `ActiveRecord::IrreversibleMigration` 异常。如果有人尝试撤销迁移，会看到一个错误消息，告诉他无法撤销。

### 撤销之前的迁移

Active Record 提供了撤销迁移的功能，通过 `revert` 方法实现：

```ruby
require_relative '2012121212_example_migration'

class FixupExampleMigration < ActiveRecord::Migration
  def change
    revert ExampleMigration

    create_table(:apples) do |t|
      t.string :variety
    end
  end
end
```

`revert` 方法还可接受一个块，定义撤销操作。`revert` 方法可用来撤销以前迁移的部分操作。例如，`ExampleMigration` 已经执行，但后来觉得最好还是序列化产品列表。那么，可以编写下面的代码：

```ruby
class SerializeProductListMigration < ActiveRecord::Migration
  def change
    add_column :categories, :product_list

    reversible do |dir|
      dir.up do
        # transfer data from Products to Category#product_list
      end
      dir.down do
        # create Products from Category#product_list
      end
    end

    revert do
      # copy-pasted code from ExampleMigration
      create_table :products do |t|
        t.references :category
      end

      reversible do |dir|
        dir.up do
          #add a foreign key
          execute <<-SQL
            ALTER TABLE products
              ADD CONSTRAINT fk_products_categories
              FOREIGN KEY (category_id)
              REFERENCES categories(id)
          SQL
        end
        dir.down do
          execute <<-SQL
            ALTER TABLE products
              DROP FOREIGN KEY fk_products_categories
          SQL
        end
      end

      # The rest of the migration was ok
    end
  end
end
```

上面这个迁移也可以不用 `revert` 方法，不过步骤就多了：调换 `create_table` 和 `reversible` 的顺序，把 `create_table` 换成 `drop_table`，还要对调 `up` 和 `down` 中的代码。这些操作都可交给 `revert` 方法完成。

## 运行迁移

Rails 提供了很多 Rake 任务，用来执行指定的迁移。

其中最常使用的是 `rake db:migrate`，执行还没执行的迁移中的 `change` 或 `up` 方法。如果没有未运行的迁移，直接退出。`rake db:migrate` 按照迁移文件名中时间戳顺序执行迁移。

注意，执行 `db:migrate` 时还会执行 `db:schema:dump`，更新 `db/schema.rb` 文件，匹配数据库的结构。

如果指定了版本，Active Record 会运行该版本之前的所有迁移。版本就是迁移文件名前的数字部分。例如，要运行 20080906120000 这个迁移，可以执行下面的命令：

```bash
$ rake db:migrate VERSION=20080906120000
```

如果 20080906120000 比当前的版本高，上面的命令就会执行所有 20080906120000 之前（包括 20080906120000）的迁移中的 `change` 或 `up` 方法，但不会运行 20080906120000 之后的迁移。如果回滚迁移，则会执行 20080906120000 之前（不包括 20080906120000）的迁移中的 `down` 方法。

### 回滚

还有一个常用的操作时回滚到之前的迁移。例如，迁移代码写错了，想纠正。我们无须查找迁移的版本号，直接执行下面的命令即可：

```bash
$ rake db:rollback
```

这个命令会回滚上一次迁移，撤销 `change` 方法中的操作，或者执行 `down` 方法。如果想撤销多个迁移，可以使用 `STEP` 参数：

```bash
$ rake db:rollback STEP=3
```

这个命令会撤销前三次迁移。

`db:migrate:redo` 命令可以回滚上一次迁移，然后再次执行迁移。和 `db:rollback` 一样，如果想重做多次迁移，可以使用 `STEP` 参数。例如：

```bash
$ rake db:migrate:redo STEP=3
```

这些 Rake 任务的作用和 `db:migrate` 一样，只是用起来更方便，因为无需查找特定的迁移版本号。

### 搭建数据库

`rake db:setup` 任务会创建数据库，加载模式，并填充种子数据。

### 重建数据库

`rake db:reset` 任务会删除数据库，然后重建，等价于 `rake db:drop db:setup`。

I> 这个任务和执行所有迁移的作用不同。`rake db:reset` 使用的是 `schema.rb` 文件中的内容。如果迁移无法回滚，`rake db:reset` 起不了作用。详细介绍参见“[导出模式](#schema-dumping-and-you)”一节。

### 运行指定的迁移

如果想执行指定迁移，或者撤销指定迁移，可以使用 `db:migrate:up` 和 `db:migrate:down` 任务，指定相应的版本号，就会根据需求调用 `change`、`up` 或 `down` 方法。例如：

```bash
$ rake db:migrate:up VERSION=20080906120000
```

这个命令会执行 20080906120000 迁移中的 `change` 方法或 `up` 方法。`db:migrate:up` 首先会检测指定的迁移是否已经运行，如果 Active Record 任务已经执行，就不会做任何操作。

### 在不同的环境中运行迁移

默认情况下，`rake db:migrate` 任务在 `development` 环境中执行。要在其他环境中运行迁移，执行命令时可以使用环境变量 `RAILS_ENV` 指定环境。例如，要在 `test` 环境中运行迁移，可以执行下面的命令：

```bash
$ rake db:migrate RAILS_ENV=test
```

### 修改运行迁移时的输出

默认情况下，运行迁移时，会输出操作了哪些操作，以及花了多长时间。创建数据表并添加索引的迁移产生的输出如下：

```bash
==  CreateProducts: migrating =================================================
-- create_table(:products)
   -> 0.0028s
==  CreateProducts: migrated (0.0028s) ========================================
```

在迁移中可以使用很多方法，控制输出：

| 方法                 | 作用 |
| -------------------- | ------- |
| suppress_messages    | 接受一个代码块，禁止代码块中所有操作的输出 |
| say                  | 接受一个消息字符串作为参数，将其输出。第二个参数是布尔值，指定输出结果是否缩进 |
| say_with_time        | 输出文本，以及执行代码块中操作所用时间。如果代码块的返回结果是整数，会当做操作的记录数量 |

例如，下面这个迁移：

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    suppress_messages do
      create_table :products do |t|
        t.string :name
        t.text :description
        t.timestamps
      end
    end

    say "Created a table"

    suppress_messages {add_index :products, :name}
    say "and an index!", true

    say_with_time 'Waiting for a while' do
      sleep 10
      250
    end
  end
end
```

输出结果是：

```bash
==  CreateProducts: migrating =================================================
-- Created a table
   -> and an index!
-- Waiting for a while
   -> 10.0013s
   -> 250 rows
==  CreateProducts: migrated (10.0054s) =======================================
```

如果不想让 Active Record 输出任何结果，可以使用 `rake db:migrate VERBOSE=false`。

## 修改现有的迁移

有时编写的迁移中可能有错误，如果已经运行了迁移，不能直接编辑迁移文件再运行迁移。Rails 认为这个迁移已经运行，所以执行 `rake db:migrate` 任务时什么也不会做。这种情况必须先回滚迁移（例如，执行 `rake db:rollback` 任务），编辑迁移文件后再执行 `rake db:migrate` 任务执行改正后的版本。

一般来说，直接修改现有的迁移不是个好主意。这么做会为你以及你的同事带来额外的工作量，如果这个迁移已经在生产服务器上运行过，还可能带来不必要的麻烦。你应该编写一个新的迁移，做所需的改动。编辑新生成还未纳入版本控制的迁移（或者更宽泛地说，还没有出现在开发设备之外），相对来说是安全的。

在新迁移中撤销之前迁移中的全部操作或者部分操作可以使用 `revert` 方法。（参见前面的 [撤销之前的迁移](#reverting-previous-migrations) 一节）

## 导出模式

### 模式文件的作用

迁移的作用并不是为数据库模式提供可信的参考源。`db/schema.rb` 或由 Active Record 生成的 SQL 文件才有这个作用。`db/schema.rb` 这些文件不可修改，其目的是表示数据库的当前结构。

部署新程序时，无需运行全部的迁移。直接加载数据库结构要简单快速得多。

例如，测试数据库是这样创建的：导出开发数据库的结构（存入文件 `db/schema.rb` 或 `db/structure.sql`），然后导入测试数据库。

模式文件还可以用来快速查看 Active Record 中有哪些属性。模型中没有属性信息，而且迁移会频繁修改属性，但是模式文件中有最终的结果。[annotate_models](https://github.com/ctran/annotate_models) gem 会在模型文件的顶部加入注释，自动添加并更新模型的模式。

### 导出的模式文件类型

导出模式有两种方法，由 `config/application.rb` 文件中的 `config.active_record.schema_format` 选项设置，可以是 `:sql` 或 `:ruby`。

如果设为 `:ruby`，导出的模式保存在 `db/schema.rb` 文件中。打开这个文件，你会发现内容很多，就像一个很大的迁移：

```ruby
ActiveRecord::Schema.define(version: 20080906171750) do
  create_table "authors", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", force: true do |t|
    t.string   "name"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "part_number"
  end
end
```

大多数情况下，文件的内容都是这样。这个文件使用 `create_table`、`add_index` 等方法审查数据库的结构。这个文件盒使用的数据库类型无关，可以导入任何一种 Active Record 支持的数据库。如果开发的程序需要兼容多种数据库，可以使用这个文件。

不过 `db/schema.rb` 也有缺点：无法执行数据库的某些操作，例如外键约束，触发器，存储过程。在迁移文件中可以执行 SQL 语句，但导出模式的程序无法从数据库中重建这些语句。如果你的程序用到了前面提到的数据库操作，可以把模式文件的格式设为 `:sql`。

`:sql` 格式的文件不使用 Active Record 的模式导出程序，而使用数据库自带的导出工具（执行 `db:structure:dump` 任务），把数据库模式导入 `db/structure.sql` 文件。例如，PostgreSQL 使用 `pg_dump` 导出模式。如果使用 MySQL，`db/structure.sql` 文件中会出现多个 `SHOW CREATE TABLE` 用来创建数据表的语句。

加载模式时，只要执行其中的 SQL 语句即可。按预期，导入后会创建一个完整的数据库结构。使用 `:sql` 格式，就不能把模式导入其他类型的数据库中了。

### 模式导出和版本控制

因为导出的模式文件时数据库模式的可信源，强烈推荐将其纳入版本控制。

## Active Record 和引用完整性

Active Record 在模型中，而不是数据库中设置关联。因此，需要在数据库中实现的功能，例如触发器、外键约束，不太常用。

`validates :foreign_key, uniqueness: true` 这个验证是模型保证数据完整性的一种方法。在关联中设置 `:dependent` 选项，可以保证父对象删除后，子对象也会被删除。和任何一种程序层的操作一样，这些无法完全保证引用完整性，所以很多人还是会在数据库中使用外键约束。

Active Record 并没有为使用这些功能提供任何工具，不过 `execute` 方法可以执行任意的 SQL 语句。还可以使用 [foreigner](https://github.com/matthuhiggins/foreigner) 等 gem，为 Active Record 添加外键支持（还能把外键导出到 `db/schema.rb` 文件）。

## 迁移和种子数据

有些人使用迁移把数据存入数据库：

```ruby
class AddInitialProducts < ActiveRecord::Migration
  def up
    5.times do |i|
      Product.create(name: "Product ##{i}", description: "A product.")
    end
  end

  def down
    Product.delete_all
  end
end
```

Rails 提供了“种子”功能，可以把初始化数据存入数据库。这个功能用起来很简单，在 `db/seeds.rb` 文件中写一些 Ruby 代码，然后执行 `rake db:seed` 命令即可：

```ruby
5.times do |i|
  Product.create(name: "Product ##{i}", description: "A product.")
end
```

填充新建程序的数据库，使用这种方法操作起来简洁得多。
