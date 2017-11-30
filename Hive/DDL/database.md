# DATABASE/SCHEMA
## 创建数据库
* DATABASE和SCHEMA在Hive中是同一个概念的不同表述，可以混用
* Hive默认将db存放在`hive.metastore.warehouse.dir`定义的hdfs目录中，可用LOCATION来指定其他目录，不过要确保hive对该目录的操作权限
* WITH DBPROPERTIES用来定义若干db的properties

```sql
CREATE DATABASE IF NOT EXISTS panhongfa
COMMENT 'test database by phf'
LOCATION '/user/phf/panhongfa'
WITH DBPROPERTIES('creator'='hdfs','date'='2017-8-11');
```

## 列出数据库
* SCHEMAS和DATABASES含义相同，可互换
* LIKE子句使用正则表达式来过滤数据库列表，不过只能使用通配符'*'和'|'

```sql
SHOW DATABASES;
SHOW DATABASES LIKE 'p*|d*';
```

## 查看数据库
* 查看数据库的描述信息和文件位置信息
* EXTENDED参数额外显示db的properties

```sql
DESCRIBE DATABASE default;
DESCRIBE DATABASE panhongfa;
DESCRIBE DATABASE EXTENDED panhongfa;
```

## 修改数据库
* SET DBPROPERTIES用来添加/修改db的properties
* SET OWNER用来设置owner的鉴权类型和实际用户

```sql
ALTER DATABASE panhongfa SET DBPROPERTIES('role'='admin');
ALTER DATABASE panhongfa SET OWNER USER hdfs;
ALTER DATABASE panhongfa SET OWNER ROLE hive;
ALTER DATABASE panhongfa SET OWNER GROUP hadoop;
```

## 切换数据库
* 该设置在当前session中有效，重新连接后默认数据库恢复成default

```sql
USE panhongfa;
USE DEFAULT;
```

## 删除数据库
* RESTRICT是默认处理方式，db不为空时删除失败
* 设置为CASCADE方式，强制级联删除db和table

```sql
DROP DATABASE IF EXISTS panhongfa RESTRICT;
DROP DATABASE IF EXISTS panhongfa CASCADE;
```
