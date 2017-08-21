# Hive概述

## DATABASE/SCHEMA
### 创建DB
* DATABASE和SCHEMA在Hive中是同一个概念的不同表述，可以混用
* Hive默认将db存放在`hive.metastore.warehouse.dir`定义的hdfs目录中，可用LOCATION来指定其他目录，不过要确保hive对该目录的操作权限
* WITH DBPROPERTIES用来定义若干db的properties

```sql
CREATE DATABASE IF NOT EXISTS panhongfa
COMMENT 'test database by phf'
LOCATION '/user/phf/panhongfa'
WITH DBPROPERTIES('creator'='hdfs','date'='2017-8-11');
```

### 查看DB
* 查看数据库的描述信息和文件位置信息
* EXTENDED参数额外显示db的properties

```sql
DESCRIBE DATABASE default;
DESCRIBE DATABASE panhongfa;
DESCRIBE DATABASE EXTENDED panhongfa;
```

### 修改DB
* SET DBPROPERTIES用来添加/修改db的properties
* SET OWNER用来设置owner的鉴权类型和实际用户

```sql
ALTER DATABASE panhongfa SET DBPROPERTIES('role'='admin');
ALTER DATABASE panhongfa SET OWNER USER hdfs;
ALTER DATABASE panhongfa SET OWNER ROLE hive;
ALTER DATABASE panhongfa SET OWNER GROUP hadoop;
```

### USE DB
* 该设置在当前session中有效，重新连接后默认数据库恢复成default

```sql
USE panhongfa;
USE DEFAULT;
```

### 删除DB
* RESTRICT是默认处理方式，db不为空时删除失败
* 设置为CASCADE方式，强制级联删除db和table

```sql
DROP DATABASE IF EXISTS panhongfa RESTRICT;
DROP DATABASE IF EXISTS panhongfa CASCADE;
```

## TABLE
### 创建TABLE
#### 名称约束
* 表名只允许字母+数字+[_]
* 列名允许除[.:]外的任何unicode字符，否则查询会出错
* ''包含的字符串均取字面量，其中的符号[']采用['']来转义
* 它们都是大小写不相关


#### TBLPROPERTIES
|                         属性                          |   取值   |                                         含义                                         |
| ----------------------------------------------------- | -------- | ------------------------------------------------------------------------------------ |
| comment                                               | String   | 可用来修改建表时输入的表注释文本                                                     |
| hbase.table.name                                      | String   | hive表在hbase中默认使用同样的表名，该property可修改成其他表名                        |
| immutable                                             | BOOLEAN  | 为true表示该表数据不可变，表为空时才能INSERT INTO，INSERT OVERWRITE不受此限制        |
| orc.compress                                          | compress | 采用ORCFile文件格式时需要配置压缩方式                                                |
| transactional                                         | BOOLEAN  | 为true表示是ACID表，允许行级的INSERT&UPDATE&DELETE操作，但ACID表不能再转化为非ACID表 |
| NO_AUTO_COMPACTION                                    | BOOLEAN  | 为true表示系统不自动进行压缩                                                         |
| compactor.mapreduce.map.memory.mb                     | INT      | compaction MR任务所使用的最大内存                                                    |
| compactorthreshold.hive.compactor.delta.num.threshold | INT      | delta目录数个数超过后，触发minor compaction                                          |
| compactorthreshold.hive.compactor.delta.pct.threshold | DOUBLE   | delta文件的size与基本文件size的比例超过后，触发major compaction                      |
| auto.purge                                            | BOOLEAN  | 为true表示DROP表之后不移动到trash中等待若干持续时间，而是立即删除                    |
| EXTERNAL                                              | BOOLEAN  | 为true表示为外部表                                                                   |

#### EXTERNAL
* 默认的托管表由Hive管理其元数据和数据，默认存放在`hive.metastore.warehouse.dir`参数指定的目录，DROP操作时一起被删除
* 外部表由Hive管理元数据，数据存放在HDFS上由`LOCATION`子命令指定的目录并由用户自己管理，DROP操作时只删除元数据
* 外部表的结构或分区发生更改后，使用MSCK REPAIR TABLE table来更新元数据
* 通过DESCRIBE FORMATTED table来查询表属于MANAGED_TABLE or EXTERNAL_TABLE


#### Storage
* hive读过程：HDFS files --> InputFileFormat --> <key, value> --> Deserializer --> Row object
* hive写过程：Row object --> Serializer --> <key, value> --> OutputFileFormat --> HDFS files


通过以下两个维度的命令来对表的存储进行管理：
```sql
CREATE TABLE ...
  [
   [ROW FORMAT row_format]
   [STORED AS file_format]
     | STORED BY 'storage.handler.class.name' [WITH SERDEPROPERTIES (...)]
  ]
```

* row_format: 行与行，以及一行中各个字段的组织方式和存储方式，对应于读/写流程的Serializer和Deserializer过程，由Hive中的SerDe模块来定义。
* file_format: 每一行中字段容器的格式，即用文本、二进制还是其他方式来持久化到hdfs文件中，对应与读/写流程的InputFileFormat和OutputFileFormat。

##### Row Format
```sql
CREATE TABLE ...
ROW FORMAT DELIMITED --表明文本的分隔方式，具体定义在下面
  [FIELDS TERMINATED BY char [ESCAPED BY char]] --定义字段与字段之间的分隔字符
  [COLLECTION ITEMS TERMINATED BY char]         --定义ARRAY或STRUCT中元素间的分隔符
  [MAP KEYS TERMINATED BY char]                 --定义MAP的键值对间的分隔符
  [LINES TERMINATED BY char]                    --定义行与行之间的分隔符
  [NULL DEFINED AS char]                        --定义NULL字符的表达方式
| SERDE serde_name  --定义使用哪个SerDe方式
  [WITH SERDEPROPERTIES (property_name=property_value, ...)] --为SerDe设置若干额外的属性
STORED AS TEXTFILE;
```

##### SERDE
* RegEx: SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
* JSON: SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
* CSV/TSV: SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'

##### File Format
```sql
SET hive.exec.compress.output=true; --设置压缩属性
SET mapred.output.compress=true;
SET mapred.output.compression.codec=org.apache.hadoop.io.compress.GzipCodec;
CREATE TABLE ...
STORED AS SEQUENCEFILE;
  | RCFILE
  | ORC
  | PARQUET
  | AVRO
  | INPUTFORMAT input_format_classname OUTPUTFORMAT output_format_classname
```

#### 主键约束
```sql
CREATE TABLE
(col_name data_type [COMMENT col_comment],...
  : [, PRIMARY KEY (col_name, ...) DISABLE NOVALIDATE ] --主键约束
    [, CONSTRAINT constraint_name FOREIGN KEY (col_name, ...) --组合主键约束
    REFERENCES table_name(col_name, ...) DISABLE NOVALIDATE ] --引入的外键约束
)
```

* ENABLE VALIDATE: 启用约束，创建索引，对已有及新加入的数据执行约束
* ENABLE NOVALIDATE：启动约束，创建索引，仅对新加入的数据强制执行约束，已有数据不执行
* DISABLE NOVALIDATE：关闭约束，删除索引，可以对约束列的数据进行修改等操作
* DISABLE VALIDATE：关闭约束，删除索引，不能对表进行写操作


#### Partition
为了可以让查询发生在小范围的数据上以提高效率，首先我们引入partition的概念，来对数据进行粗粒度的划分，它具有以下的特点：

* 根据一列或是几列的值将表划分为多个partition，每个partition在物理上对应一个表目录的子目录；
* 参与partition的列不能与CREATE时声明的常规数据列重名；
* 对于特定的行，partition列的值并没有显式地在行中存储，它隐含在目录路径中，但partition列和数据列的查询在用法上并无差别；
* 一条记录到底放到哪个分区，由用户决定，即用户在加载数据的时候必须显示的指定该部分数据放到哪个分区；

```sql
CREATE TABLE ...
 PARTITIONED BY(dt STRING, country STRING)
 STORED AS SEQUENCEFILE;
```

#### Bucket
对于每一个table或者partition， 可以进一步组织为bucket，进而更为细粒度的进行数据块划分，它具有的特点如下：

* 根据某一列以及指定的个数来划分为多个bucket,每个bucket在物理上对应一个表目录或partition目录里的文件；
* bucket中的数据还可以根据一个或多个列另外进行排序，这样每个bucket的连接变成了高效的归并排序，因此可进一步提高map连接的效率;
*



#### 表的引用
  - USER db来设置默认使用的数据库，否则使用默认数据库default
  - 使用db.table的方式在session中引用非默认数据库的表

#### 实例
```sql
CREATE TABLE IF NOT EXISTS panhongfa.test2(name STRING COMMENT 'your name', age INT COMMENT 'your age') COMMENT 'THIS IS EXAMPLE' LOCATION '/user/phf/panhongfa/test2' TBLPROPERTIES('transactional'='true','creator'='phf');

CREATE TABLE IF NOT EXISTS panhongfa.student(id INT, name STRING COMMENT 'your name', age INT COMMENT 'your age')
COMMENT 'THIS IS EXAMPLE'
CLUSTERED BY (name) INTO 2 BUCKETS STORED AS ORC
LOCATION '/user/phf/panhongfa/student'
TBLPROPERTIES('transactional'='true','creator'='phf');

insert into table test2 values(1,'panhongfa',18);

beeline -u 'jdbc:hive2://nn.daowoo.com:2181,snn.daowoo.com:2181,hive.daowoo.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2' --hivevar tablename=student --hivevar tablepath=/user/phf/panhongfa/student -f /home/panhongfa/hive_example/create_table.sql


```
