Active Record 迁移
==================

迁移是 Active Record 的一个特性，允许我们按时间顺序管理数据库模式。有了迁移，就不必再用纯 SQL 来修改数据库模式，而是可以使用简单的 Ruby DSL 来描述对数据表的修改。

读完本文后，您将学到：

- 用于创建迁移的生成器；

- Active Record 提供的用于操作数据库的方法；

- 用于操作迁移和数据库模式的 `bin/rails` 任务；

- 迁移和 `schema.rb` 文件的关系。

迁移概述
--------

迁移是以一致和轻松的方式按时间顺序修改数据库模式的实用方法。它使用 Ruby DSL，因此不必手动编写 SQL，从而实现了数据库无关的数据库模式的创建和修改。

我们可以把迁移看做数据库的新“版本”。数据库模式一开始并不包含任何内容，之后通过一个个迁移来添加或删除数据表、字段和记录。 Active Record 知道如何沿着时间线更新数据库模式，使其从任何历史版本更新为最新版本。Active Record 还会更新 `db/schema.rb` 文件，以匹配最新的数据库结构。

下面是一个迁移的示例：

```ruby
class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

这个迁移用于添加 `products` 数据表，数据表中包含 `name` 字符串字段和 `description` 文本字段。同时隐式添加了 `id` 主键字段，这是所有 Active Record 模型的默认主键。`timestamps` 宏添加了 `created_at` 和 `updated_at` 两个字段。后面这几个特殊字段只要存在就都由 Active Record 自动管理。

注意这里定义的对数据库的修改是按时间进行的。在这个迁移运行之前，数据表还不存在。在这个迁移运行之后，数据表就被创建了。Active Record 还知道如何撤销这个迁移：如果我们回滚这个迁移，数据表就会被删除。

对于支持事务并提供了用于修改数据库模式的语句的数据库，迁移被包装在事务中。如果数据库不支持事务，那么当迁移失败时，已成功的那部分操作将无法回滚。这种情况下只能手动完成相应的回滚操作。

NOTE: 某些查询不能在事务内部运行。如果数据库适配器支持 DDL 事务，就可以使用 `disable_ddl_transaction!` 方法在某个迁移中临时禁用事务。

如果想在迁移中完成一些 Active Record 不知如何撤销的操作，可以使用 `reversible` 方法：

```ruby
class ChangeProductsPrice < ActiveRecord::Migration[5.0]
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

或者用 `up` 和 `down` 方法来代替 `change` 方法：

```ruby
class ChangeProductsPrice < ActiveRecord::Migration[5.0]
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

创建迁移
--------

### 创建独立的迁移

迁移文件储存在 `db/migrate` 文件夹中，一个迁移文件包含一个迁移类。文件名采用 `YYYYMMDDHHMMSS_create_products.rb` 形式，即 UTC 时间戳加上下划线再加上迁移的名称。迁移类的名称（驼峰式）应该匹配文件名中迁移的名称。例如，在 `20080906120000_create_products.rb` 文件中应该定义 `CreateProducts` 类，在 `20080906120001_add_details_to_products.rb` 文件中应该定义 `AddDetailsToProducts` 类。Rails 根据文件名的时间戳部分确定要运行的迁移和迁移运行的顺序，因此当需要把迁移文件复制到其他 Rails 应用，或者自己生成迁移文件时，一定要注意迁移运行的顺序。

当然，计算时间戳不是什么有趣的事，因此 Active Record 提供了生成器：

```sh
$ bin/rails generate migration AddPartNumberToProducts
```

上面的命令会创建空的迁移，并进行适当命名：

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[5.0]
  def change
  end
end
```

如果迁移名称是 `AddXXXToYYY` 或 `RemoveXXXFromYYY` 的形式，并且后面跟着字段名和类型列表，那么会生成包含合适的 `add_column` 或 `remove_column` 语句的迁移。

```sh
$ bin/rails generate migration AddPartNumberToProducts part_number:string
```

上面的命令会生成：

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :part_number, :string
  end
end
```

还可以像下面这样在新建字段上添加索引：

```sh
$ bin/rails generate migration AddPartNumberToProducts part_number:string:index
```

上面的命令会生成：

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :part_number, :string
    add_index :products, :part_number
  end
end
```

类似地，还可以生成用于删除字段的迁移：

```sh
$ bin/rails generate migration RemovePartNumberFromProducts part_number:string
```

上面的命令会生成：

```ruby
class RemovePartNumberFromProducts < ActiveRecord::Migration[5.0]
  def change
    remove_column :products, :part_number, :string
  end
end
```

还可以生成用于添加多个字段的迁移，例如：

```sh
$ bin/rails generate migration AddDetailsToProducts part_number:string price:decimal
```

上面的命令会生成：

```ruby
class AddDetailsToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :part_number, :string
    add_column :products, :price, :decimal
  end
end
```

如果迁移名称是 `CreateXXX` 的形式，并且后面跟着字段名和类型列表，那么会生成用于创建包含指定字段的 `XXX` 数据表的迁移。例如：

```sh
$ bin/rails generate migration CreateProducts name:string part_number:string
```

上面的命令会生成：

```ruby
class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string :name
      t.string :part_number
    end
  end
end
```

和往常一样，上面的命令生成的代码只是一个起点，我们可以修改 `db/migrate/YYYYMMDDHHMMSS_add_details_to_products.rb` 文件，根据需要增删代码。

生成器也接受 `references` 字段类型作为参数（还可使用 `belongs_to`），例如：

```sh
$ bin/rails generate migration AddUserRefToProducts user:references
```

上面的命令会生成：

```ruby
class AddUserRefToProducts < ActiveRecord::Migration[5.0]
  def change
    add_reference :products, :user, index: true, foreign_key: true
  end
end
```

这个迁移会创建 `user_id` 字段并添加索引。关于 `add_reference` 选项的更多介绍，请参阅 [API 文档](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_reference)。

如果迁移名称中包含 `JoinTable`，生成器会创建联结数据表：

```sh
$ bin/rails g migration CreateJoinTableCustomerProduct customer product
```

上面的命令会生成：

```ruby
class CreateJoinTableCustomerProduct < ActiveRecord::Migration[5.0]
  def change
    create_join_table :customers, :products do |t|
      # t.index [:customer_id, :product_id]
      # t.index [:product_id, :customer_id]
    end
  end
end
```

### 模型生成器

模型和脚手架生成器会生成适用于添加新模型的迁移。这些迁移中已经包含用于创建有关数据表的指令。如果我们告诉 Rails 想要哪些字段，那么添加这些字段所需的语句也会被创建。例如，运行下面的命令：

```sh
$ bin/rails generate model Product name:string description:text
```

上面的命令会创建下面的迁移：

```ruby
class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

我们可以根据需要添加“字段名称/类型”对，没有数量限制。

### 传递修饰符

可以直接在命令行中传递常用的[类型修饰符](#字段修饰符)。这些类型修饰符用大括号括起来，放在字段类型之后。例如，运行下面的命令：

```sh
$ bin/rails generate migration AddDetailsToProducts 'price:decimal{5,2}' supplier:references{polymorphic}
```

上面的命令会创建下面的迁移：

```ruby
class AddDetailsToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :price, :decimal, precision: 5, scale: 2
    add_reference :products, :supplier, polymorphic: true, index: true
  end
end
```

TIP: 关于传递修饰符的更多介绍，请参阅生成器的命令行帮助信息。

编写迁移
--------

使用生成器创建迁移后，就可以开始写代码了。

### 创建数据表

`create_table` 方法是最基础、最常用的方法，其代码通常是由模型或脚手架生成器生成的。典型的用法像下面这样：

```ruby
create_table :products do |t|
  t.string :name
end
```

上面的命令会创建包含 `name` 字段的 `products` 数据表（后面会介绍，数据表还包含自动创建的 `id` 字段）。

默认情况下，`create_table` 方法会创建 `id` 主键。可以用 `:primary_key` 选项来修改主键名称，还可以传入 `id: false` 选项以禁用主键。如果需要传递数据库特有的选项，可以在 `:options` 选项中使用 SQL 代码片段。例如：

```ruby
create_table :products, options: "ENGINE=BLACKHOLE" do |t|
  t.string :name, null: false
end
```

上面的代码会在用于创建数据表的 SQL 语句末尾加上 `ENGINE=BLACKHOLE`（如果使用 MySQL 或 MarialDB，默认选项是 `ENGINE=InnoDB`）。

还可以传递带有数据表描述信息的 `:comment` 选项，这些注释会被储存在数据库中，可以使用 MySQL Workbench、PgAdmin III 等数据库管理工具查看。对于大型数据库，强列推荐在应用的迁移中添加注释。目前只有 MySQL 和 PostgreSQL 适配器支持注释功能。

### 创建联结数据表

`create_join_table` 方法用于创建 HABTM（has and belongs to many）联结数据表。典型的用法像下面这样：

```ruby
create_join_table :products, :categories
```

上面的代码会创建包含 `category_id` 和 `product_id` 字段的 `categories_products` 数据表。这两个字段的 `:null` 选项默认设置为 `false`，可以通过 `:column_options` 选项覆盖这一设置：

```ruby
create_join_table :products, :categories, column_options: { null: true }
```

联结数据表的名称默认由 `create_join_table` 方法的前两个参数按字母顺序组合而来。可以传入 `:table_name` 选项来自定义联结数据表的名称：

```ruby
create_join_table :products, :categories, table_name: :categorization
```

上面的代码会创建 `categorization` 数据表。

`create_join_table` 方法也接受块作为参数，用于添加索引（默认未创建的索引）或附加字段：

```ruby
create_join_table :products, :categories do |t|
  t.index :product_id
  t.index :category_id
end
```

### 修改数据表

`change_table` 方法和 `create_table` 非常类似，用于修改现有的数据表。它的用法和 `create_table` 方法风格类似，但传入块的对象有更多用法。例如：

```ruby
change_table :products do |t|
  t.remove :description, :name
  t.string :part_number
  t.index :part_number
  t.rename :upccode, :upc_code
end
```

上面的代码删除 `description` 和 `name` 字段，创建 `part_number` 字符串字段并添加索引，最后重命名 `upccode` 字段。

### 修改字段

Rails 提供了与 `remove_column` 和 `add_column` 类似的 `change_column` 迁移方法。

```ruby
change_column :products, :part_number, :text
```

上面的代码把 `products` 数据表的 `part_number` 字段修改为 `:text` 字段。请注意 `change_column` 命令是无法撤销的。

除 `change_column` 方法之外，还有 `change_column_null` 和 `change_column_default` 方法，前者专门用于设置字段可以为空或不可以为空，后者专门用于修改字段的默认值。

```ruby
change_column_null :products, :name, false
change_column_default :products, :approved, from: true, to: false
```

上面的代码把 `products` 数据表的 `:name` 字段设置为 `NOT NULL` 字段，把 `:approved` 字段的默认值由 `true` 修改为 `false`。

注意：也可以把上面的 `change_column_default` 迁移写成 `change_column_default :products, :approved, false`，但这种写法是无法撤销的。

### 字段修饰符

字段修饰符可以在创建或修改字段时使用：

- `limit` 修饰符：设置 `string/text/binary/integer` 字段的最大长度。

- `precision` 修饰符：定义 `decimal` 字段的精度，表示数字的总位数。

- `scale` 修饰符：定义 `decimal` 字段的标度，表示小数点后的位数。

- `polymorphic` 修饰符：为 `belongs_to` 关联添加 `type` 字段。

- `null` 修饰符：设置字段能否为 `NULL` 值。

- `default` 修饰符：设置字段的默认值。请注意，如果使用动态值（如日期）作为默认值，那么默认值只会在第一次使时（如应用迁移的日期）计算一次。

- `index` 修饰符：为字段添加索引。

- `comment` 修饰符：为字段添加注释。

有的适配器可能支持附加选项，更多介绍请参阅相应适配器的 API 文档。

### 外键

尽管不是必需的，但有时我们需要使用外键约束以保证引用完整性。

```ruby
add_foreign_key :articles, :authors
```

上面的代码为 `articles` 数据表的 `author_id` 字段添加外键，这个外键会引用 `authors` 数据表的 `id` 字段。如果字段名不能从表名称推导出来，我们可以使用 `:column` 和 `:primary_key` 选项。

Rails 会为每一个外键生成以 `fk_rails_` 开头并且后面紧跟着 10 个字符的外键名，外键名是根据 `from_table` 和 `column` 推导出来的。需要时可以使用 `:name` 来指定外键名。

NOTE: Active Record 只支持单字段外键，要想使用复合外键就需要 `execute` 方法和 `structure.sql`。更多介绍请参阅 [数据库模式转储](#数据库模式转储)。

删除外键也很容易：

```ruby
# 让 Active Record 找出列名
remove_foreign_key :accounts, :branches

# 删除特定列上的外键
remove_foreign_key :accounts, column: :owner_id

# 通过名称删除外键
remove_foreign_key :accounts, name: :special_fk_name
```

### 如果辅助方法不够用

如果 Active Record 提供的辅助方法不够用，可以使用 `excute` 方法执行任意 SQL 语句：

```ruby
Product.connection.execute("UPDATE products SET price = 'free' WHERE 1=1")
```

关于各个方法的更多介绍和例子，请参阅 API 文档。尤其是 [`ActiveRecord::ConnectionAdapters::SchemaStatements`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html) 的文档（在 `change`、`up` 和 `down` 方法中可以使用的方法）、[`ActiveRecord::ConnectionAdapters::TableDefinition`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html) 的文档（在 `create_table` 方法的块中可以使用的方法）和 [`ActiveRecord::ConnectionAdapters::Table`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/Table.html) 的文档（在 `change_table` 方法的块中可以使用的方法）。

### 使用 `change` 方法

`change` 方法是编写迁移时最常用的。在大多数情况下，Active Record 知道如何自动撤销用 `change` 方法编写的迁移。目前，在 `change` 方法中只能使用下面这些方法：

- `add_column`

- `add_foreign_key`

- `add_index`

- `add_reference`

- `add_timestamps`

- `change_column_default`（必须提供 `:from` 和 `:to` 选项）

- `change_column_null`

- `create_join_table`

- `create_table`

- `disable_extension`

- `drop_join_table`

- `drop_table`（必须提供块）

- `enable_extension`

- `remove_column`（必须提供字段类型）

- `remove_foreign_key`（必须提供第二个数据表）

- `remove_index`

- `remove_reference`

- `remove_timestamps`

- `rename_column`

- `rename_index`

- `rename_table`

如果在块中不使用 `change`、`change_default` 和 `remove` 方法，那么 `change_table` 方法也是可撤销的。

如果提供了字段类型作为第三个参数，那么 `remove_column` 是可撤销的。别忘了提供原来字段的选项，否则 Rails 在回滚时就无法准确地重建字段了：

```ruby
remove_column :posts, :slug, :string, null: false, default: '', index: true
```

如果需要使用其他方法，可以用 `reversible` 方法或者 `up` 和 `down` 方法来代替 `change` 方法。

### 使用 `reversible` 方法

撤销复杂迁移所需的操作有一些是 Rails 无法自动完成的，这时可以使用 `reversible` 方法指定运行和撤销迁移所需的操作。例如：

```ruby
class ExampleMigration < ActiveRecord::Migration[5.0]
  def change
    create_table :distributors do |t|
      t.string :zipcode
    end

    reversible do |dir|
      dir.up do
        # 添加 CHECK 约束
        execute <<-SQL
          ALTER TABLE distributors
            ADD CONSTRAINT zipchk
              CHECK (char_length(zipcode) = 5) NO INHERIT;
        SQL
      end
      dir.down do
        execute <<-SQL
          ALTER TABLE distributors
            DROP CONSTRAINT zipchk
        SQL
      end
    end

    add_column :users, :home_page_url, :string
    rename_column :users, :email, :email_address
  end
end
```

使用 `reversible` 方法可以确保指令按正确的顺序执行。在上面的代码中，撤销迁移时，`down` 块会在删除 `home_page_url` 字段之后、删除 `distributors` 数据表之前运行。

有时，迁移执行的操作是无法撤销的，例如删除数据。在这种情况下，我们可以在 `down` 块中抛出 `ActiveRecord::IrreversibleMigration` 异常。这样一旦尝试撤销迁移，就会显示无法撤销迁移的出错信息。

### 使用 `up` 和 `down` 方法

可以使用 `up` 和 `down` 方法以传统风格编写迁移而不使用 `change` 方法。`up` 方法用于描述对数据库模式所做的改变，`down` 方法用于撤销 `up` 方法所做的改变。换句话说，如果调用 `up` 方法之后紧接着调用 `down` 方法，数据库模式不会发生任何改变。例如用 `up` 方法创建数据表，就应该用 `down` 方法删除这个数据表。在 `down` 方法中撤销迁移时，明智的做法是按照和 `up` 方法中操作相反的顺序执行操作。下面的例子和上一节中的例子的功能完全相同：

```ruby
class ExampleMigration < ActiveRecord::Migration[5.0]
  def up
    create_table :distributors do |t|
      t.string :zipcode
    end

    # 添加 CHECK 约束
    execute <<-SQL
      ALTER TABLE distributors
        ADD CONSTRAINT zipchk
        CHECK (char_length(zipcode) = 5);
    SQL

    add_column :users, :home_page_url, :string
    rename_column :users, :email, :email_address
  end

  def down
    rename_column :users, :email_address, :email
    remove_column :users, :home_page_url

    execute <<-SQL
      ALTER TABLE distributors
        DROP CONSTRAINT zipchk
    SQL

    drop_table :distributors
  end
end
```

对于无法撤销的迁移，应该在 `down` 方法中抛出 `ActiveRecord::IrreversibleMigration` 异常。这样一旦尝试撤销迁移，就会显示无法撤销迁移的出错信息。

### 撤销之前的迁移

Active Record 提供了 `revert` 方法用于回滚迁移：

```ruby
require_relative '20121212123456_example_migration'

class FixupExampleMigration < ActiveRecord::Migration[5.0]
  def change
    revert ExampleMigration

    create_table(:apples) do |t|
      t.string :variety
    end
  end
end
```

`revert` 方法也接受块，在块中可以定义用于撤销迁移的指令。如果只是想要撤销之前迁移的部分操作，就可以使用块。例如，假设有一个 `ExampleMigration` 迁移已经执行，但后来发现应该用 ActiveRecord 验证代替 `CHECK` 约束来验证邮编，那么可以像下面这样编写迁移：

```ruby
class DontUseConstraintForZipcodeValidationMigration < ActiveRecord::Migration[5.0]
  def change
    revert do
      # 从  ExampleMigration 中复制粘贴代码
      reversible do |dir|
        dir.up do
          # 添加 CHECK 约束
          execute <<-SQL
            ALTER TABLE distributors
              ADD CONSTRAINT zipchk
                CHECK (char_length(zipcode) = 5);
          SQL
        end
        dir.down do
          execute <<-SQL
            ALTER TABLE distributors
              DROP CONSTRAINT zipchk
          SQL
        end
      end

      # ExampleMigration 中的其他操作无需撤销
    end
  end
end
```

不使用 `revert` 方法也可以编写出和上面的迁移功能相同的迁移，但需要更多步骤：调换 `create_table` 方法和 `reversible` 方法的顺序，用 `drop_table` 方法代替 `create_table` 方法，最后对调 `up` 和 `down` 方法。换句话说，这么多步骤用一个 `revert` 方法就可以代替。

NOTE: 要想像上面的例子一样添加 `CHECK` 约束，必须使用 `structure.sql` 作为转储方式。请参阅 [数据库模式转储](#数据库模式转储)。

运行迁移
--------

Rails 提供了一套用于运行迁移的 `bin/rails` 任务。其中最常用的是 `rails db:migrate` 任务，用于调用所有未运行的迁移中的 `chagne` 或 `up` 方法。如果没有未运行的迁移，任务会直接退出。调用顺序是根据迁移文件名的时间戳确定的。

请注意，执行 `db:migrate` 任务时会自动执行 `db:schema:dump` 任务，这个任务用于更新 `db/schema.rb` 文件，以匹配数据库结构。

如果指定了目标版本，Active Record 会运行该版本之前的所有迁移（调用其中的 `change`、`up` 和 `down` 方法），其中版本指的是迁移文件名的数字前缀。例如，下面的命令会运行 `20080906120000` 版本之前的所有迁移：

```sh
$ bin/rails db:migrate VERSION=20080906120000
```

如果版本 `20080906120000` 高于当前版本（换句话说，是向上迁移），上面的命令会按顺序运行迁移直到运行完 `20080906120000` 版本，之后的版本都不会运行。如果是向下迁移（即版本 `20080906120000` 低于当前版本），上面的命令会按顺序运行 `20080906120000` 版本之前的所有迁移，不包括 `20080906120000` 版本。

### 回滚

另一个常用任务是回滚最后一个迁移。例如，当发现最后一个迁移中有错误需要修正时，就可以执行回滚任务。回滚最后一个迁移不需要指定这个迁移的版本，直接执行下面的命令即可：

```sh
$ bin/rails db:rollback
```

上面的命令通过撤销 `change` 方法或调用 `down` 方法来回滚最后一个迁移。要想取消多个迁移，可以使用 `STEP` 参数：

```sh
$ bin/rails db:rollback STEP=3
```

上面的命令会撤销最后三个迁移。

`db:migrate:redo` 任务用于回滚最后一个迁移并再次运行这个迁移。和 `db:rollback` 任务一样，如果需要重做多个迁移，可以使用 `STEP` 参数，例如：

```sh
$ bin/rails db:migrate:redo STEP=3
```

这些 `bin/rails` 任务可以完成的操作，通过 `db:migrate` 也都能完成，区别在于这些任务使用起来更方便，无需显式指定迁移的版本。

### 安装数据库

`rails db:setup` 任务用于创建数据库，加载数据库模式，并使用种子数据初始化数据库。

### 重置数据库

`rails db:reset` 任务用于删除并重新创建数据库，其功能相当于 `rails db:drop db:setup`。

NOTE: 重置数据库和运行所有迁移是不一样的。重置数据库只使用当前的 `db/schema.rb` 或 `db/structure.sql` 文件的内容。如果迁移无法回滚，使用 `rails db:reset` 任务可能也没用。关于转储数据库模式的更多介绍，请参阅 [数据库模式转储](#数据库模式转储)。

### 运行指定迁移

要想运行或撤销指定迁移，可以使用 `db:migrate:up` 和 `db:migrate:down` 任务。只需指定版本，对应迁移就会调用它的 `change` 、`up` 或 `down` 方法，例如：

```sh
$ bin/rails db:migrate:up VERSION=20080906120000
```

上面的命令会运行 `20080906120000` 这个迁移，调用它的 `change` 或 `up` 方法。`db:migrate:up` 任务会检查指定迁移是否已经运行过，如果已经运行过就不会执行任何操作。

### 在不同环境中运行迁移

`bin/rails db:migrate` 任务默认在开发环境中运行迁移。要想在其他环境中运行迁移，可以在执行任务时使用 `RAILS_ENV` 环境变量说明所需环境。例如，要想在测试环境中运行迁移，可以执行下面的命令：

```sh
$ bin/rails db:migrate RAILS_ENV=test
```

### 修改迁移运行时的输出

运行迁移时，默认会输出正在进行的操作，以及操作所花费的时间。例如，创建数据表并添加索引的迁移在运行时会生成下面的输出：

    ==  CreateProducts: migrating =================================================
    -- create_table(:products)
       -> 0.0028s
    ==  CreateProducts: migrated (0.0028s) ========================================

在迁移中提供了几种方法，允许我们修改迁移运行时的输出：

| 方法 | 用途 |
|----|----|
| `suppress_messages` | 参数是一个块，抑制块产生的任何输出。 |
| `say` | 接受信息文体作为参数并将其输出。方法的第二个参数是布尔值，用于说明输出结果是否缩进。 |
| `say_with_time` | 输出信息文本以及执行块所花费的时间。如果块返回整数，这个整数会被当作受块操作影响的记录的条数。 |
例如，下面的迁移：

```ruby
class CreateProducts < ActiveRecord::Migration[5.0]
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

会生成下面的输出：

    ==  CreateProducts: migrating =================================================
    -- Created a table
       -> and an index!
    -- Waiting for a while
       -> 10.0013s
       -> 250 rows
    ==  CreateProducts: migrated (10.0054s) =======================================

要是不想让 Active Record 生成任何输出，可以使用 `rails db:migrate VERBOSE=false`。

修改现有的迁移
--------------

在编写迁移时我们偶尔也会犯错误。如果已经运行过存在错误的迁移，那么直接修正迁移中的错误并重新运行这个迁移并不能解决问题：Rails 知道这个迁移已经运行过，因此执行 `rails db:migrate` 任务时不会执行任何操作。必须先回滚这个迁移（例如通过执行 `bin/rails db:rollback` 任务），再修正迁移中的错误，然后执行 `rails db:migrate` 任务来运行这个迁移的正确版本。

通常，直接修改现有的迁移不是个好主意。这样做会给我们和同事带来额外的工作量，如果这个迁移已经在生产服务器上运行过，还可能带来大麻烦。作为替代，可以编写一个新的迁移来执行我们想要的操作。修改还未提交到源代版本码控制系统（或者更一般地，还未传播到开发设备之外）的新生成的迁移是相对无害的。

在编写新的迁移来完全或部分撤销之前的迁移时，可以使用 `revert` 方法（请参阅前面 [撤销之前的迁移](#撤销之前的迁移)）。

数据库模式转储
--------------

### 数据库模式文件有什么用？

迁移尽管很强大，但并非数据库模式的可信来源。Active Record 通过检查数据库生成的 `db/schema.rb` 文件或 SQL 文件才是数据库模式的可信来源。这两个可信来源不应该被修改，它们仅用于表示数据库的当前状态。

当需要部署 Rails 应用的新实例时，不必把所有迁移重新运行一遍，直接加载当前数据库的模式文件要简单和快速得多。

例如，我们可以这样创建测试数据库：把当前的开发数据库转储为 `db/schema.rb` 或 `db/structure.sql` 文件，然后加载到测试数据库。

数据库模式文件还可以用于快速查看 Active Record 对象具有的属性。这些属性信息不仅在模型代码中找不到，而且经常分散在几个迁移文件中，还好在数据库模式文件中可以很容易地查看这些信息。[annotate\_models](https://github.com/ctran/annotate_models) gem 会在每个模型文件的顶部自动添加和更新注释，这些注释是对当前数据库模式的概述，如果需要可以使用这个 gem。

### 数据库模式转储的类型

数据库模式转储有两种方式，可以通过 `config/application.rb` 文件的 `config.active_record.schema_format` 选项来设置想要采用的方式，即 `:sql` 或 `:ruby`。

如果选择 `:ruby`，那么数据库模式会储存在 `db/schema.rb` 文件中。打开这个文件，会看到内容很多，就像一个巨大的迁移：

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

在很多情况下，我们看到的数据库模式文件就是上面这个样子。这个文件是通过检查数据库生成的，使用 `create_table`、`add_index` 等方法来表达数据库结构。这个文件是数据库无关的，因此可以加载到 Active Record 支持的任何一种数据库。如果想要分发使用多数据库的 Rails 应用，数据库无关这一特性就非常有用了。

尽管如此，`db/schema.rb` 在设计上也有所取舍：它不能表达数据库的特定项目，如触发器、存储过程或检查约束。尽管我们可以在迁移中执行定制的 SQL 语句，但是数据库模式转储工具无法从数据库中复原这些语句。如果我们使用了这类特性，就应该把数据库模式的格式设置为 `:sql`。

在把数据库模式转储到 `db/structure.sql` 文件时，我们不使用数据库模式转储工具，而是使用数据库特有的工具（通过执行 `db:structure:dump` 任务）。例如，对于 PostgreSQL，使用的是 `pg_dump` 实用程序。对于 MySQL 和 MariaDB，`db/structure.sql` 文件将包含各种数据表的 `SHOW CREATE TABLE` 语句的输出。

加载数据库模式实际上就是执行其中包含的 SQL 语句。根据定义，加载数据库模式会创建数据库结构的完美拷贝。`:sql` 格式的数据库模式，只能加载到和原有数据库类型相同的数据库，而不能加载到其他类型的数据库。

### 数据库模式转储和源码版本控制

数据库模式转储是数据库模式的可信来源，因此强烈建议将其纳入源码版本控制。

`db/schema.rb` 文件包含数据库的当前版本号，这样可以确保在合并两个包含数据库模式文件的分支时会发生冲突。一旦出现这种情况，就需要手动解决冲突，保留版本较高的那个数据库模式文件。

Active Record 和引用完整性
--------------------------

Active Record 在模型而不是数据库中声明关联。因此，像触发器、约束这些依赖数据库的特性没有被大量使用。

验证，如 `validates :foreign_key, uniqueness: true`，是模型强制数据完整性的一种方式。在关联中设置 `:dependent` 选项，可以保证父对象删除后，子对象也会被删除。和其他应用层的操作一样，这些操作无法保证引用完整性，因此有些人会在数据库中使用[外键约束](#外键)以加强数据完整性。

尽管 Active Record 并未提供用于直接处理这些特性的工具，但 `execute` 方法可以用于执行任意 SQL。

迁移和种子数据
--------------

Rails 迁移特性的主要用途是使用一致的进程调用修改数据库模式的命令。迁移还可以用于添加或修改数据。对于不能删除和重建的数据库，如生产数据库，这些功能非常有用。

```ruby
class AddInitialProducts < ActiveRecord::Migration[5.0]
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

使用 Rails 内置的“种子”特性可以快速简便地完成创建数据库后添加初始数据的任务。在开发和测试环境中，经常需要重新加载数据库，这时“种子”特性就更有用了。使用“种子”特性很容易，只要用 Ruby 代码填充 `db/seeds.rb` 文件，然后执行 `rails db:seed` 命令即可：

```ruby
5.times do |i|
  Product.create(name: "Product ##{i}", description: "A product.")
end
```

相比之下，这种设置新建应用数据库的方法更加干净利落。
