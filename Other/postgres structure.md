# 数据库逻辑结构
- 数据库： 一个Postgresql数据库服务（或者叫实例）管理多个数据库，当应用连接到一个数据库时，一般只能访问这个数据库中的数据，而不能访问其他数据库中的内容，除非使用dblink等其他手段。
- 表、索引：一个数据库中有很多表和索引。PG中表的术语为Relation，而其他数据库中则叫Table。
- 数据行：每张表中有很多行数据。PG中行的术语为Tuple，而在其他数据库中则叫Row。

# 基本操作
## 创建数据库
```
CREATE DATABASE account
  WITH OWNER = postgres            #指定新建的数据库属于哪个用户。如果不指定，新建的数据库就属于当前执行命令的用户
       ENCODING = 'UTF8'           #创建新数据库使用的字符编码。PG不支持通常的汉字字符集‘GBK’、‘GB18030’，所以一般都是使用‘UTF8’字符集来支持中文
       TABLESPACE = pg_default     #指定和新数据库关联的表空间（base目录下的一个表空间目录）
       LC_COLLATE = 'en_US.UTF-8'  #?
       LC_CTYPE = 'en_US.UTF-8'    #?
       CONNECTION LIMIT = -1;      #数据库可以接受多少并发链接，默认为：-1，表示没有限制
```
注意：TEMPLATE：模板名，表示从哪个模板创建新数据库，若不指定，将使用默认模板数据库（template0 / template1）。

## 修改数据库
```
ALTER DATABASE test           #修改数据库名称
  RENAME TO tests;
ALTER DATABASE tests          #修改数据库所属用户
  OWNER TO postgres;
COMMENT ON DATABASE tests     #修改数据库描述信息
  IS '测试数据库';
ALTER DATABASE tests          #修改数据库所属表空间
  SET TABLESPACE pg_default;
ALTER DATABASE tests          #修改数据库的最大连接数为n
  WITH CONNECTION LIMIT = 5;
```

## 删除数据库
```
DROP DATABASE test;           #直接删除一个数据库
DROP DATABASE IF EXISTS test; #如果一个数据库存在，则将其删除
```
注意：如果还有人连接在这个数据库上，将不能删除该数据库。不能在事务块中创建或删除数据库，但是可以修改数据库。

## 查询数据库
```
postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)
```

# 模式
## 定义
模式（Schema）是数据库中的一个概念，可以理解为一个命名空间或目录，不同的模式下可以有相同名称的表、函数等对象且互相不冲突。
一个数据库包含一个或多个模式，模式中又包含了表、函数及操作符等数据库对象。不能在同一个连接中访问不同数据库中的对象，但可以访问不同的模式对象。

## 作用
1. 允许多个用户在使用同一个数据库时彼此互不干扰
2. 把数据库对象放在不同的模式下，然后组织成逻辑组，让他们更便于管理
3. 第三方应用可以放在不同的模式中，这样就不会和其他对象的名字冲突了

## 操作
### 新建模式
```
CREATE SCHEMA test             #新建一个名为‘test’的模式
       AUTHORIZATION postgres; #指定模式的宿主
COMMENT ON SCHEMA test         #设置模式的注释
  IS 'test schema';
```

### 修改模式
```
ALTER SCHEMA test             #修改模式名称
  RENAME TO test11;
ALTER SCHEMA test11           #修改模式宿主
  OWNER TO phf;
```

### 删除模式
```
DROP SCHEMA phf;               #删除模式
```

### 查询模式
```
postgres=# \dn
  List of schemas
  Name  |  Owner
--------+----------
 phf    | postgres
 public | postgres
 test   | postgres
(3 rows)
```

### 组合创建
在创建一个模式的同时，还可以在这个模式下创建一些表和视图。
```
CREATE SCHEMA test2
CREATE TABLE t1 (x_id INT, x_name TEXT)    #同时创建表t1
CREATE TABLE t2 (x_id INT, x_desc TEXT)    #同时创建表t2
CREATE VIEW v1 AS                          #同时创建视图v1
SELECT a.x_id, a.x_name, b.x_desc          #由表t1和t2中id相同的行聚合
FROM t1 a, t2 b
WHERE a.x_id = b.x_id;
```

## 公共模式
如果要创建或者访问模式中的特定对象，需要通过'SCHEMA_NAME.OBJECT_NAME'的方式来访问。
实际情况下，我们通常创建和访问表的时候都不用指定模式，实际上这时候访问的都是‘public’模式。每当我们创建一个新的数据库时，Postgresql都会自动创建一个名为‘public’的模式。当登录到该数据库时，如果没有特殊的指定，都是以‘public’模式操作各种数据对象的。

## 模式的搜索路径
访问数据库对象时，虽然我们可以通过它的全称（SCHEMA_NAME.OBJECT_NAME）来定位对象，但不得不每次都得键入模式名和对象名，这显然很繁琐。于是，Postgresql提供了模式搜索路径，它类似于Linux中的$PATH环境变量，提供了直接使用数据库对象名访问的能力。
查找一个搜索路径来判断某个表究竟是哪个模式下，这个路径是一个需要查找的模式列表，在搜索路径里找到的第一个表将被当做选定的表。
如果在所有搜索路径中都没有找到匹配的表，就会报告一个错误，即使在数据库其他的模式中真正存在着匹配的表也是如此。
在搜索路径中的第一个模式叫做当前模式，他除了是搜索的第一个模式之外，它还是在CREATE TABLE没有声明模式名时新建表所属于的模式。

显示当前搜索路径，使用如下命令。
```
postgres=# SHOW search_path;
   search_path
-----------------
 "$user", public
(1 row)

```

## 模式的权限
默认情况下，用户无法访问模式中不属于他们的对象。若要访问，模式的所有者必须在模式上赋予他们‘USAGE’权限。
用户也可以在别人的模式里创建对象，这需要被赋予了在该模式上的‘CREATE’权限。默认情况下，每个用户在‘public’模式上都有‘CREATE’和‘USAGE’权限，如果想取消这些权限，可以使用‘REVOKE’撤销命令来撤销这个权限。
```
REVOKE CREATE ON SCHEMA public FROM PUBLIC;  #第一个‘public’是模式的名称（标识符），第二个‘PUBLIC’表示所有用户（关键字）
```

# 数据表



# 用户&权限管理
## 定义
- 角色是一系列相关数据库访问权限的集合，通常会把一系列相关的数据库权限赋予给一个角色，如果哪个用户需要这些权限，就把角色赋给相应的用户。
- 在Postgresql中，为了简化管理，角色与用户是没有区别的，一个用户也是一个角色，我们可以把一个用户的权限赋给另一个用户。
- 用户和角色在整个数据库实例中都是全局的，并且在同一数据库实例中的不同数据库中，看到的用户也都是相同的。
- 在Postgresql初始化数据库系统时，有一个预定义的超级用户'postgres'，我们可以用这个超级用户连接数据库然后创建更多的用户。

## 操作
### 创建角色
```
CREATE ROLE panhongfa                                                       #创建角色&用户
  LOGIN/NOLOGIN                                                             #该用户是否可以登录数据库
  ENCRYPTED/UNENCRYPTED  PASSWORD 'md5fbc1b9ff612b4b7aa59f03058619d4ef'     #设置用户密码，可通过`ENCRYPTED/UNENCRYPTED`来配置是否加密保存
  SUPERUSER/NOSUPERUSER                                                     #该用户是否具有超级管理员权限
  INHERIT/NOINHERIT                                                         #用户panhongfa是否自动拥有角色panhongfa的权限
  CREATEDB/NOCREATEDB                                                       #该用户是否可以创建新数据库
  CREATEROLE/NOCREATEROLE                                                   #该用户是否可以创建新角色
  CREATEUSER/NOCREATEUSER                                                   #该用户是否可以创建新用户
  REPLICATION/NOREPLICATION                                                 #该用户是否可以进行流复制
  CONNECTION LIMIT 20                                                       #设置该用户可以使用的并发链接数量，默认为`-1`,表示不限制
  VALID UNTIL '2016-11-30 00:00:00';                                        #设置该用户的密码失效时间，如果不指定该字句，那么密码将永久有效
```
在Postgresql中，用户与角色是没有区别的。除了'CREATE USER'默认创建出来的用户有'LOGIN'的权限，而'CREATE ROLE'创建出来的用户需要主动指定'LOGIN'权限以外，两条命令之间没有任何的区别。

### 修改角色
```
ALTER ROLE panhongfa                                                        #修改角色
  ENCRYPTED PASSWORD 'md54293a8c97c72716e2e5a7712a047cf6c'                  #修改用户密码
  NOCREATEDB                                                                #该用户不能新建数据库
  NOCREATEROLE                                                              #该用户不能新建角色
  VALID UNTIL 'infinity';                                                   #该用户密码永不过期
```

### 删除角色
```
DROP ROLE panhongfa;  #删除角色
```

## 角色权限
每个数据库的逻辑结构对象（包括数据库自身）都有一个所有者，即任何数据库对象都是属于某个用户的，所有者默认就拥有所有权限。当然，所有者出于安全考虑也可以选择废弃一些自己的权限。但是，删除对象和修改对象的权限都不能赋予给其他用户，它们是所有者固有的，不能被赋予或撤销。

用户的权限分为两类，一类是在创建用户时就指定的权限，修改权限时需要使用'ALTER ROLE'命令，这些权限如下
> 超级用户的权限
> 创建数据库的权限
> 创建用户的权限
> 是否允许LOGIN的权限
> 是否可以进行流复制的权限

还有一类权限，是由授权命令GRANT和撤销命令REVOKE来管理的，这些权限如下
> 在数据库中创建模式
> 允许在指定的数据库中创建临时表
> 连接某个数据库
> 在模式中创建数据库对象，如创建表、视图、函数等
> 在一些表中做SELECT、UPDATE、INSERT、DELETE等操作
> 在一张表的具体列上进行SELECT、UPDATE、INSERT等操作
> 对序列进行查询（执行序列的currval函数）、使用（执行序列的currval函数和nextval函数）、更新等操作
> 在声明表上创建触发器
> 可以把表、索引等建到指定的表空间

从语法上可以看出，授权命令GRANT具有两个作用，一个是让某个用户成为某个角色的成员，从而使其拥有角色的权限
```
GRANT "debugGroup" TO panhongfa;  #将用户panhongfa设置为组角色debugGroup的成员，从而拥有debugGroup所被赋予的权限
```

另一个作用是把某些数据库逻辑结构对象的操作权限赋予某个用户&角色
```
GRANT ALL ON SCHEMA test2 TO public;                                                     #给予所有用户（此处的public表示所有用户）操作模式test2的创建和访问对象权限
GRANT CREATE ON SCHEMA test2 TO GROUP "debugGroup";                                      #给予debugGroup组角色中所有用户操作模式test2的创建对象权限
GRANT SELECT, UPDATE, INSERT, DELETE, TRIGGER ON TABLE test2.t1 TO GROUP "debugGroup";   #给予debugGroup组角色中所有用户操作模式test2中t1表的查询、更新、插入、删除和使用触发器权限
GRANT SELECT(x_id), INSERT(x_id) ON test2.t1 TO GROUP "debugGroup";                      #给予debugGroup组角色中所有用户操作模式test2中t1表x_id列的查询和插入权限
```

撤销命令REVOKE与GRANT命令类似，其用法如下
```
REVOKE ALL ON SCHEMA test2 FROM public;                                     #撤销所有用户操作模式test2的创建和访问对象权限
REVOKE UPDATE, INSERT, DELETE ON TABLE test2.t1 FROM panhongfa;             #撤销用户panhongfa操作模式test2中t1表的更新、插入和删除权限
REVOKE UPDATE, INSERT, DELETE ON TABLE test2.t1 FROM GROUP "debugGroup";    #撤销debugGroup组角色中所有用户操作模式test2中t1表的更新、插入和删除权限
```

## 权限的说明
|权限名称   |权限使用说明   |
| ------------ | ------------ |
|SELECT   |对表和视图来说，表示允许查询；如果限制了列，则允许查询这些列；对于大对象来说，表示允许读取大对象；对于序列来说，表示允许使用currval函数   |
|INSERT   |表示允许往特定表中插入行；如果特定列被列出，插入行时仅允许指定这些特定列的值，其他列均使用默认值；拥有这个权限表示也允许使用语句COPY FROM往表中插入数据   |
|UPDATE   |对表来说，如果没有指定特定的列，则表示允许更新表中任意列的数据；如果指定了特定的列，则只允许更新特定列的数据；对于序列来说，该权限允许使用nextval和setval函数；对于大对象来说，该允许写大对象和截断大对象   |
|DELETE   |允许删除表中的数据   |
|TRUNCATE   |允许在指定的表上执行TRUNCATE操作   |
|REFERENCES   |为了创建外检约束，有必要时参照列和被参照列都有该权限。可以将该权限授给一个表的所有列或仅仅是特定列   |
|TRIGGER   |允许在指定的表上创建触发器   |
|CREATE   |对于数据库，表示允许在该数据库里创建新的模式；对模式来说，表示允许在模式中创建各种数据库对象，如表、视图、索引、函数等；对表空间来说，此权限表示允许把表、索引创建到此表空间，或使用ALTER命令把表、索引移到此表空间，需要注意的是撤销这个权限不会改变现有表的存放位置   |
|CONNECT   |表示允许用户连接到指定的数据库，该权限将在连接启动时检查（除了检测pg_hba.conf中的限制之外）   |
|TEMPORARY或TEMP   |表示在使用指定数据库的时候创建临时表   |
|EXECUTE   |表示允许使用指定的函数，包括利用这些函数实现的任何操作符。这是可用于函数上的唯一权限，该权限同样适用于聚集函数   |
|USAGE   |对于过程语言来说，表示允许使用指定的过程语言（PL/PGSQL、PL/Python）创建相应的函数；对于模式来说，表示允许被授权者'查找'模式中的对象（可见）。当然，如果要查询一个模式中的表，实际上还需要有表的'SELECT'权限。不过，即使没有这个USAGE权限仍然可以看见这些对象的名字，比如通过查询系统视图来查看。   |
|ALL PRIVILEGES   |表示一次性给予所有可以赋予的权限。PRIVILEGES关键字可以省略，但在其他数据库中可能需要有这个关键字   |

## 函数和触发器的权限
在创建了用户自定义的函数和触发器后，其他用户就可能在无意思的情况下执行这些函数或触发器了。有些PL编程语言允许无检查的内存访问（如PL/Python），这会导致较大的安全漏洞，所以PG只允许超级用户使用这样的PL语言写函数。

## 权限的总结
PG中的权限是从整体到局部的方式按照层次进行管理的
- 首先管理赋在用户特殊属性上的权限，如超级用户权限、创建数据库权限、创建用户权限、LOGIN权限等；
- 然后管理在数据库中创建模式的权限；
- 接着是在模式中创建数据库对象的权限，如创建表、创建索引等等；
- 之后是查询表、往表中插入数据、更新表、删除表中数据的权限；
- 最后是操作表中某些字段的权限。
