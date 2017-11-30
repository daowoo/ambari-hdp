# TABLE
* tablename只允许字母+数字+_
* columname允许除.和:外的任何unicode字符，否则查询时会出错
* tablename中以''来包含的字符串均取字面量，其中的符号'采用''来转义
* dbname和tablename都是大小写不相关的
* `USER db`来设置默认使用的数据库，否则使用默认数据库default
* 使用`db.table`的方式在session中引用非默认数据库的表
* 可通过设置`set hive.execution.engine=mr;`来将HQL语句直接解析为MR job, 通过设置`set hive.execution.engine=tez;`来恢复HQL语句的解析器为TEZ

## 列出表
* 使用IN子句指定列出哪个数据库的表
* 指定正则表达式可以过滤表名

```sql
SHOW TABLES;
SHOW TABLES IN panhongfa;
SHOW TABLES IN panhongfa 'd*';
```

## 查看表
* EXTENDED: 以Thrift序列化形式显示表的所有元数据
* FORMATTED: 以表格方式显示表的所有元数据

```sql
DESCRIBE test1;
DESCRIBE EXTENDED panhongfa.test1;
DESCRIBE FORMATTED panhongfa.test1;
```

## 创建表
### 语法
```sql
CREATE [TEMPORARY] [EXTERNAL] TABLE [IF NOT EXISTS] [db_name.]table_name    -- (Note: TEMPORARY available in Hive 0.14.0 and later)
  [(col_name data_type [COMMENT col_comment], ... [constraint_specification])]
  [COMMENT table_comment]
  [PARTITIONED BY (col_name data_type [COMMENT col_comment], ...)]
  [CLUSTERED BY (col_name, col_name, ...) [SORTED BY (col_name [ASC|DESC], ...)] INTO num_buckets BUCKETS]
  [SKEWED BY (col_name, col_name, ...)                  -- (Note: Available in Hive 0.10.0 and later)]
     ON ((col_value, col_value, ...), (col_value, col_value, ...), ...)
     [STORED AS DIRECTORIES]
  [
   [ROW FORMAT row_format]
   [STORED AS file_format]
     | STORED BY 'storage.handler.class.name' [WITH SERDEPROPERTIES (...)]  -- (Note: Available in Hive 0.6.0 and later)
  ]
  [LOCATION hdfs_path]
  [TBLPROPERTIES (property_name=property_value, ...)]   -- (Note: Available in Hive 0.6.0 and later)
  [AS select_statement];   -- (Note: Available in Hive 0.5.0 and later; not supported for external tables)

CREATE [TEMPORARY] [EXTERNAL] TABLE [IF NOT EXISTS] [db_name.]table_name
  LIKE existing_table_or_view_name
  [LOCATION hdfs_path];
```

### 类型
#### MANAGED
托管表由Hive管理其元数据和数据，默认存放在`hive.metastore.warehouse.dir`参数指定的目录，DROP操作时元数据和数据被一起被删除

#### TEMPORARY
* 临时表，只对当前session有效，session退出后，该表自动删除
* 临时表和原始表冲突时，在当前session中引用的总是临时表，除非drop或rename该临时表才能使用原始表
* 临时表不支持分区和索引

#### EXTERNAL
* 外部表由Hive管理元数据，数据则存放在HDFS上由`LOCATION`子命令指定的目录并由用户自己管理，DROP操作时只删除元数据
* 外部表的结构或分区发生更改后，使用MSCK REPAIR TABLE table来更新元数据
* 通过DESCRIBE FORMATTED table来查询表属于MANAGED_TABLE还是EXTERNAL_TABLE

#### 使用场景
* 处理由其他组件或工具生成的，存储在HDFS的原始数据，Hive转换这些数据并将结果存放在托管表
* 针对一个数据集，关联多个Schema，也就是一表多用，分别对应不同的处理逻辑

```sql
-- 上传测试数据
cd /home/hdfs/csv
hdfs dfs -put * /tmp/

-- 创建默认的托管表
CREATE TABLE IF NOT EXISTS test1(id INT, name STRING COMMENT 'your name', age INT, phone STRING, address STRING, email STRING, vip STRING, level STRING)
COMMENT 'THIS IS EXAMPLE';
ROW FORMAT
DELIMITED FIELDS TERMINATED BY '|'
STORED AS TEXTFILE;

-- load数据
LOAD DATA INPATH '/tmp/dataSep-2017-9-6.csv' OVERWRITE INTO TABLE test1;
SELECT * FROM test1 LIMIT 100;

-- 通过CTAS方式创建临时表，临时表存储在Hive的临时目录
CREATE TEMPORARY TABLE IF NOT EXISTS test2
AS
SELECT * FROM test1 LIMIT 100;

-- 创建外部表，指定HDFS上的存储位置
CREATE EXTERNAL TABLE IF NOT EXISTS test3(id INT, name STRING, age INT, phone STRING COMMENT 'telephone number', address STRING, email STRING, vip STRING, level STRING)
ROW FORMAT
DELIMITED FIELDS TERMINATED BY '|'
STORED AS TEXTFILE
LOCATION '/user/phf/external/test3';

-- 上传csv文件到LOCATION目录
hdfs dfs -put dataSep-2017-9-7.csv /user/phf/external/test3/

-- 更新外部表元数据
MSCK REPAIR TABLE test3;

-- 更新行数、数据大小、存储大小、最后操作时间等Statistics
ANALYZE TABLE test3 COMPUTE STATISTICS;
```

### 主键约束
Hive2.1版本新增的特性，目前HDP2.6使用的Hive版本是1.2.2，以下示例语句没有经过验证。

```sql
CREATE TABLE
(col_name data_type [COMMENT col_comment],
    [, PRIMARY KEY (col_name, ...) DISABLE NOVALIDATE ] --主键约束
    [, CONSTRAINT constraint_name FOREIGN KEY (col_name, ...) REFERENCES table_name(col_name, ...) DISABLE NOVALIDATE ] --组合建+外键约束
...)
```

* ENABLE VALIDATE: 启用约束，创建索引，对已有及新加入的数据执行约束
* ENABLE NOVALIDATE：启动约束，创建索引，仅对新加入的数据强制执行约束，已有数据不执行
* DISABLE NOVALIDATE：关闭约束，删除索引，可以对约束列的数据进行修改等操作
* DISABLE VALIDATE：关闭约束，删除索引，不能对表进行写操作

```sql
CREATE TABLE IF NOT EXISTS test1(id INT, name STRING, age INT, PRIMARY KEY(id) DISABLE NOVALIDATE)
COMMENT 'THIS IS EXAMPLE';

CREATE TABLE IF NOT EXISTS test2(id INT, name STRING, age INT, CONSTRAINT sid FOREIGN KEY (id,name) DISABLE NOVALIDATE)
COMMENT 'THIS IS EXAMPLE';
```

### PARTITION
为了可以让查询发生在小范围的数据上以提高效率，首先我们引入partition的概念，来对数据进行粗粒度的划分，它具有以下的特点：

* 根据一列或是几列的值将表划分为多个partition，每个partition在物理上对应一个表目录的子目录
* 参与partition的列不能与CREATE时声明的常规数据列重名
* 一条记录到底放到哪个分区，由用户决定，即用户在加载数据的时候必须显示的指定该部分数据放到哪个分区
* 对于特定的行，partition列的值并没有显式地在行中存储，它隐含在目录路径中，但partition列和数据列的查询在用法上并无差别

```sql
-- 创建按照时间和国别来进行分区的分区表
CREATE TABLE IF NOT EXISTS test1(id INT, name STRING, age INT, phone STRING, address STRING, email STRING, vip STRING, level STRING)
COMMENT 'THIS IS EXAMPLE'
PARTITIONED BY (country STRING, datatime STRING)
ROW FORMAT
DELIMITED FIELDS TERMINATED BY '|'
STORED AS TEXTFILE;

-- 将数据load到指定的分区
LOAD DATA INPATH '/tmp/dataSep-2017-9-6.csv' OVERWRITE INTO TABLE test1 PARTITION (country='CN', datatime='2017-09-06');
LOAD DATA INPATH '/tmp/dataSep-2017-9-7.csv' OVERWRITE INTO TABLE test1 PARTITION (country='CN', datatime='2017-09-07');
LOAD DATA INPATH '/tmp/dataSep-2017-9-8.csv' OVERWRITE INTO TABLE test1 PARTITION (country='CN', datatime='2017-09-08');
LOAD DATA INPATH '/tmp/dataSep-2017-9-9.csv' OVERWRITE INTO TABLE test1 PARTITION (country='EN', datatime='2017-09-09');
LOAD DATA INPATH '/tmp/dataSep-2017-9-10.csv' OVERWRITE INTO TABLE test1 PARTITION (country='EN', datatime='2017-09-10');
LOAD DATA INPATH '/tmp/dataSep-2017-9-11.csv' OVERWRITE INTO TABLE test1 PARTITION (country='EN', datatime='2017-09-11');

-- 查询数据，Partition列像普通列一样在查询中使用
SELECT * FROM test1 LIMIT 100;
SELECT count(*) FROM test1 WHERE country='CN' AND datatime='2017-09-06';
SELECT count(*) FROM test1 WHERE country='CN';
```

### BUCKETS
对于每一个table或者partition，可进一步组织为bucket，进而更为细粒度的进行数据块划分，它具有的特点如下：
* 根据某一列以及指定的个数来划分为多个bucket,每个bucket在物理上对应一个表目录或partition目录里的文件
* hive根据字段哈希取余数来决定数据应该放在哪个bucket，因此每个bucket都是整体数据的随机抽样，整体来看数据是在bucket中均匀分布
* bucket中的数据还可以根据一个或多个列另外进行排序，这样每个bucket的连接变成了高效的归并排序，因此可进一步提高map连接的效率
* 在hive 0.x和1.x版本中，必须显式的设置`set hive.enforce.bucketing = true;`才能自动控制上一轮reduce的数量从而设配bucket的个数，否则需要`set mapred.reduce.tasks=100`来手动设置reduce的数量并且需要在select语句后面加上CLUSTER BY来实现INSERT查询
* 不要尝试把数据手动载入bucket，最好通过`INSERT OVERWRITE`自动将原始表数据填入至划分了bucket的表中

```sql
-- 分别采用不同的列来创建bucket表，并且采用与源数据相同的分区
CREATE TABLE IF NOT EXISTS test2(id INT, name STRING COMMENT 'your name', age INT COMMENT 'your age', phone STRING COMMENT 'telephone number', vip STRING, level STRING)
COMMENT 'THIS IS EXAMPLE'
PARTITIONED BY (country STRING, datatime STRING)
CLUSTERED BY (age) INTO 20 BUCKETS
ROW FORMAT
DELIMITED FIELDS TERMINATED BY '|'
STORED AS TEXTFILE;

CREATE TABLE IF NOT EXISTS test3(id INT, name STRING COMMENT 'your name', age INT COMMENT 'your age', phone STRING COMMENT 'telephone number', address STRING, email STRING)
COMMENT 'THIS IS EXAMPLE'
PARTITIONED BY (country STRING, datatime STRING)
CLUSTERED BY (id, age) INTO 20 BUCKETS
ROW FORMAT
DELIMITED FIELDS TERMINATED BY '|'
STORED AS TEXTFILE;

CREATE TABLE IF NOT EXISTS test4(id INT, name STRING COMMENT 'your name', age INT COMMENT 'your age', phone STRING COMMENT 'telephone number')
COMMENT 'THIS IS EXAMPLE'
PARTITIONED BY (country STRING, datatime STRING)
CLUSTERED BY (id, age) INTO 36 BUCKETS
STORED AS AVRO;

-- 将源数据表的一次查询结果导入到多个bucket表
set hive.enforce.bucketing = true;
FROM test1
INSERT OVERWRITE TABLE test2 PARTITION (country='CN', datatime='2017-09-06')
SELECT id,name,age,phone,vip,level WHERE country='CN' AND datatime='2017-09-06'
INSERT OVERWRITE TABLE test3 PARTITION (country='CN', datatime)
SELECT id,name,age,phone,address,email,datatime WHERE country='CN' AND datatime IS NOT NULL
INSERT OVERWRITE TABLE test4 PARTITION (country, datatime)
SELECT id,name,age,phone,country,datatime WHERE country IS NOT NULL AND datatime IS NOT NULL;

-- 手动设置reduce数量
set mapred.reduce.tasks=36;
FROM test1
INSERT OVERWRITE TABLE test4 PARTITION (country, datatime)
SELECT id,name,age,phone,country,datatime WHERE country IS NOT NULL AND datatime IS NOT NULL CLUSTER BY(id, age);

-- 验证bucket表数据导入是否成功
SELECT count(*) FROM test2;
SELECT count(*) FROM test3;
SELECT count(*) FROM test4;

SELECT * FROM test4 TABLESAMPLE(BUCKET 1 OUT OF 18);
```

### SKEWED
* 一列或几列数据中经常出现某些值，这些值与其他值相比所在的比重应该要很大，否则就失去了其设计意义
* 若还是按照列来划分bucket，很明显，出现概率大的值会全部挤在几个bucket中，导致数据分布极不均匀
* 使用偏斜表将那些出现概率大的值分割存储到单独的文件，剩下的值存储到其他文件，这样在对偏斜值进行查询时就可以有效的跳过无关文件，从而提高性能

限制条件
* 不能在划分bucket的表和外部表中使用
* 不能使用CTAS方式来创建表
* 不能使用load data和insert into方式更新数据，只能使用insert overwrite...select...

```sql
-- 不带PARTITION的单列偏斜
CREATE TABLE IF NOT EXISTS test5(id INT, name STRING COMMENT 'your name', age INT COMMENT 'your age', phone STRING COMMENT 'telephone number', vip STRING, level STRING)
COMMENT 'THIS IS EXAMPLE'
SKEWED BY (age) ON (30) STORED AS DIRECTORIES
STORED AS AVRO;

-- 往偏斜表中覆盖写入数据，写入过程中会检查原始表中偏斜列的每一个值，此时若出现取值异常就会导致导入失败
FROM test1
INSERT OVERWRITE TABLE test5
SELECT id,name,age,phone,vip,level WHERE id IS NOT NULL AND age IS NOT NULL AND country='CN' AND datatime='2017-09-06';

-- 具有PARTITION的单列偏斜
CREATE TABLE IF NOT EXISTS test6(id INT, name STRING COMMENT 'your name', age INT COMMENT 'your age', phone STRING COMMENT 'telephone number', vip STRING, level STRING)
COMMENT 'THIS IS EXAMPLE'
PARTITIONED BY (country STRING, datatime STRING)
SKEWED BY (age) ON (30) STORED AS DIRECTORIES
STORED AS AVRO;

-- 往偏斜表中插入写数据，与OVERWRITE不同，它会进行追加操作
FROM test1
INSERT INTO TABLE test6 PARTITION (country='CN', datatime='2017-09-06')
SELECT id,name,age,phone,vip,level WHERE id IS NOT NULL AND age IS NOT NULL AND country='CN' AND datatime='2017-09-06';

-- 具有PARTITION的多列偏斜
CREATE TABLE IF NOT EXISTS test7(id INT, name STRING COMMENT 'your name', age INT COMMENT 'your age', phone STRING COMMENT 'telephone number', vip STRING, level STRING)
COMMENT 'THIS IS EXAMPLE'
PARTITIONED BY (country STRING, datatime STRING)
SKEWED BY (age,level) ON ((30,'nine'),(20,'three')) STORED AS DIRECTORIES
STORED AS AVRO;

-- 执行会报错，提示不能采用load data的方式来导入数据
LOAD DATA INPATH '/tmp/dataSep-2017-9-6.csv' OVERWRITE INTO TABLE test7;
```

### STORAGE

hive中数据操作对应于k-v字段的序列化过程以及持久化至文件系统的过程，官方给出的读取/写入步骤如下：
|  过程  |     1      |        2        |        3         |        4         |     5      |
| ------ | ---------- | --------------- | ---------------- | ---------------- | ---------- |
| 写过程 | Row object | Serializer      | list<key, value> | OutputFileFormat | HDFS files |
| 读过程 | HDFS files | InputFileFormat | list<key, value> | Deserializer     | Row object |

个人总结后，理解如下：
* 读数据时，调用inputFormat，将文件切成不同的K-V段落，每个段落即称为一个Row
* 然后调用SerDe中的Deserializer，将Row切分成为各个字段，生成RowObject
* 写数据时，调用SerDe中的Serializer，将RowObject序列化成为Row，即一个K-V段落
* 然后调用OutputFileFormat，将所有Row组合到HDFS上的文件中

同时，通过以下命令选项来对表的存储方式进行管理：
* row_format:  设置文本模式下行与行之间、各个字段之间的组织方式和分隔标志，或是设置自定义的SerDe以及额外的属性
* file_format: 设置数据持久时采用的内置或自定义文件格式

```sql
CREATE TABLE ...
  [
   [ROW FORMAT row_format]
   [STORED AS file_format]
     | STORED BY 'storage.handler.class.name' [WITH SERDEPROPERTIES (...)]
  ]
...
```

#### ROW FORMAT
行格式通过SerDe来定义，代表序列化和反序列化的具体实现。
* 当查询表数据时，SerDe扮演反序列化的角色，将文件中行的字节数据反序列化为对象
* 当数据插入时候，将数据序列化为行的字节格式，写入到文件中
* 在创建表的时候，ROW FORMAT指定的就是行的格式，DELIMITED子句表示采用文本格式时字段间分隔符、容器内部元素分隔符，行与行分隔符等
* 还可以直接通过SERDE子句设置自定义的SerDe类以及通过WITH SERDEPROPERTIES子句设置若干额外属性

```sql
CREATE TABLE ...
ROW FORMAT
: DELIMITED                                     --定义TEXTFILE分隔符
  [FIELDS TERMINATED BY char [ESCAPED BY char]] --定义字段与字段之间的分隔字符
  [COLLECTION ITEMS TERMINATED BY char]         --定义ARRAY或STRUCT中元素间的分隔符
  [MAP KEYS TERMINATED BY char]                 --定义MAP的键值对间的分隔符
  [LINES TERMINATED BY char]                    --定义行与行之间的分隔符
  [NULL DEFINED AS char]                        --定义NULL字符的表达方式

| SERDE serde_name                              --设置自定义的SerDe类名
  [WITH SERDEPROPERTIES (property_name=property_value, ...)] --为SerDe设置若干额外的属性
...
```

#### FILE FORMAT
文件格式则侧重于描述整个数据文件的格式，比如行列如何组织、是否进行分块、是否包含索引等等，其中最简单的格式是纯文本格式。
* 在创建表的时候，STORED AS从句用于指定文件格式
* 默认情况下，也就是没有指定STORED AS时，格式为文本格式TEXTFILE

```sql
CREATE TABLE ...
STORED AS
  : TEXTFILE         --文本格式
  | SEQUENCEFILE     --二进制格式，行式存储，添加索引排序后就是mapfile
  | AVRO             --二进制格式，行式存储，格式更为紧凑，数据文件自带Schema,不需要开发者实现自己的Writable对象
  | RCFILE           --二进制格式，列式存储，先划分为Row Group，在按列划分存储
  | ORC              --二进制格式，列式存储，比RCFile更加高效
  | PARQUET          --二进制格式，通用的列式存储，特别擅长处理深度嵌套的数据
  | INPUTFORMAT input_format_classname   --Hive内置格式默认已注册，自定义文件输入格式需显式指定
    OUTPUTFORMAT output_format_classname --Hive内置格式默认已注册，自定义文件输出格式需显式指定
```

##### 文本格式
创建表时，如果没有指定ROW FORAMT或者STORED AS子句，Hive默认使用分隔字段的文本格式，每行对应一条记录。文本形式的文件方便与其他工具对接来进行数据处理，例如MapReduce和Straming。同时Hive提供了更加紧凑和高效的结构。

```sql
-- 默认写法
CREATE TABLE storage.test1(id INT, name STRING, age INT, phone STRING, vip STRING, level STRING);
等价于
CREATE TABLE storage.test1(id INT, name STRING, age INT, phone STRING, vip STRING, level STRING)
ROW FORMAT DELIMITED
 FIELDS TERMINATED BY '\001'
 COLLECTION ITEMS TERMINATED BY '\002'
 MAP KEYS TERMINATED BY '\003'
 LINES TERMINATED BY '\n'
STORED AS TEXTFILE;

-- 通过CTAS方式创建文本格式的表
CREATE TABLE storage.test2
ROW FORMAT DELIMITED
  FIELDS TERMINATED BY '#'
  LINES TERMINATED BY '\n'
STORED AS TEXTFILE
AS SELECT id,name,age,phone,vip,level FROM panhongfa.test1
WHERE id IS NOT NULL AND age IS NOT NULL AND country='CN' AND datatime='2017-09-06';

CREATE TABLE storage.test3
ROW FORMAT DELIMITED
  FIELDS TERMINATED BY '#'
  LINES TERMINATED BY '\n'
STORED AS TEXTFILE
AS
SELECT (id * 10) new_id,name,age,phone,vip,level FROM test1
WHERE id IS NOT NULL AND age IS NOT NULL AND country='CN' AND datatime='2017-09-06';
SORT BY new_id;

-- 将表格中的数据按指定格式导出到文件
INSERT OVERWRITE DIRECTORY '/user/phf'
ROW FORMAT DELIMITED
 FIELDS TERMINATED BY '|'
SELECT * FROM test1;

```

##### 二进制格式
* 建表的时候指定STORED AS从句，不需要指定ROW FORMAT，因为行的格式完全由对应的二进制文件控制。
* 二进制的存储格式可以分为两类：面向行和面向列。如果查询只需要用到部分列，面向列的格式比较合适。如果需要处理的是行中的大部分数据，则面向行的格式是更好的选择。
* 还可以通过SET子句配置二进制格式是否启用压缩，使用何种方式压缩等。

```sql
CREATE TABLE panhongfa.test12(id STRING, name STRING) STORED AS PARQUET;

SET hive.exec.compress.output=true;
SET avro.output.codec=snappy;
CREATE TABLE panhongfa.test13(id STRING, name STRING) STORED AS AVRO;
```

##### 基于文本格式的自定义SerDe
ROW FORMAR SERDE指定文本格式使用系统预定义的几种SerDe方案，SERDEPROPERTIES指定与方案相关的属性。
主要包括以下三类：
* RegEx: org.apache.hadoop.hive.serde2.RegexSerDe
* JSON: org.apache.hive.hcatalog.data.JsonSerDe
* CSV/TSV: org.apache.hadoop.hive.serde2.OpenCSVSerde

```sql
CREATE TABLE panhongfa.test14(id STRING, name STRING, desc STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.contrib.serde2.RegexSerDe'
WITH SERDEPROPERTIES(
  "input.regex"="(\\d{6}) (\\d{5}) (.{29}) .*"
)
STORED AS TEXTFILE;

CREATE TABLE panhongfa.test15(id STRING, name STRING, desc STRING)
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
STORED AS TEXTFILE;

CREATE TABLE panhongfa.test16(id STRING, name STRING, desc STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
   "separatorChar" = "\t",
   "quoteChar"     = "'",
   "escapeChar"    = "\\"
)
STORED AS TEXTFILE;
```

##### 完全模式的自定义SerDe
* 首先拆分行
  * 自定义InputFormat来实现数据读取业务逻辑，需编码
  * 自定义OutputFormat来实现数据写入业务逻辑，需编码

* 利用UDF来将Row拆分为K-V对，以Map<K,V>返回
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS panhongfa.test17
(
  doc STRING
)
STORED AS
  INPUTFORMAT 'com.coder4.hive.DocFileInputFormat'
  OUTPUTFORMAT 'com.coder4.hive.DocFileOutputFormat'
LOCATION '/user/heyuan.lhy/doc/'
;

CREATE TEMPORARY FUNCTION doc_to_map AS 'com.coder4.hive.DocToMap';

SELECT
    raw['id'],
    raw['name']
FROM
(
    SELECT
        doc_to_map(doc) raw
    FROM
        test_table
) t;
```

* 自定义SerDe将Row直接转化为Table对应的字段
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS panhongfa.test18
(
  id BIGINT,
  name STRING
)
ROW FORMAT SERDE 'com.coder4.hive.MySerDe'
STORED AS
  INPUTFORMAT 'com.coder4.hive.DocFileInputFormat'
  OUTPUTFORMAT 'com.coder4.hive.DocFileOutputFormat'
LOCATION '/user/heyuan.lhy/doc/'
```

#### LOCATION
通过该关键字来自定义table在hdfs上所存放的路径，使用外部表时必须使用该关键字，对于托管表可选地指定存储目录

```sql
CREATE TABLE IF NOT EXISTS test1(id INT, name STRING COMMENT 'your name', age INT COMMENT 'your age')
COMMENT 'THIS IS EXAMPLE'
LOCATION '/user/phf/external/test1';
```

#### TBLPROPERTIES
通过TBLPROPERTIES子句来增加或是修改若干表属性，以下是一些系统预定义的表属性及其含义。

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

#### CTAS
通过子查询来创建新的表，该操作时原子的，在填充所有查询结果之前，该表对其他用户是隐藏的，
该命令有两个部分，SELECT部分可以是任何SELECT语句，CREATE部分获取SELECT结果模式，并默认原始表的表属性来创建目标表，比如SerDe和文件格式等。
与SQL语句一样，Hive同样支持对查询结果集中的数据进行一定的运算，指定相应的别名，设置特定SerDe和文件格式从而创建独立于原始表的新表。

* 目标表不能是partition表
* 目标表不能是external 表
* 目标表不能是bucket表

```sql
CREATE TABLE new_key_value_store
   ROW FORMAT SERDE "org.apache.hadoop.hive.serde2.columnar.ColumnarSerDe"
   STORED AS RCFile
   AS
SELECT (key % 1024) new_key, concat(key, value) key_value_pair
FROM key_value_store
SORT BY new_key, key_value_pair;
```

#### Create Table Like
复制原始表的表定义，而不复制数据，产生的新表的定义除了表名以外均与原始表相同，但并不包含任何行。
如果是从视图来复制，那么将使用默认的SerDe和文件格式结合视图的schema来创建一个新表。

```sql
CREATE TABLE empty_key_value_store
LIKE key_value_store;
```


### Dorp
* 删除EXTERNAL表只删除metadata,不删数据
* 删除MANAGED表删除metadata,数据移到用户垃圾箱（可以重建metadata并移回数据来恢复）
* 指定perge选项，强制删除不可恢复

```sql
DROP TABLE IF EXISTS panhongfa.test1;
DROP TABLE IF EXISTS panhongfa.test2 PURGE;
```

### Truncate
清空表数据，指定partition时只清空特定partition的数据。

```sql
TRUNCATE TABLE panhongfa.test3;
TRUNCATE TABLE panhongfa.test6 PARTITION (datatime = 20170909, datatime = 20170910, country = ch);
```

### Alter
#### Rename Table
```sql
ALTER TABLE panhongfa.test3 RENAME TO panhongfa.test3-3;
```

#### Alter Table Properties
```sql
ALTER TABLE panhongfa.test3-3 SET TBLPROPERTIES ('comment' = 'test properties', 'transactional' = true);
```

#### Add SerDe Properties
```sql
ALTER TABLE panhongfa.test6 PARTITION (datatime = 20170909, country = ch) SET SERDEPROPERTIES serde_properties;

ALTER TABLE panhongfa.test6 PARTITION (datatime = 20170909, country = ch) SET SERDE serde_class_name [WITH SERDEPROPERTIES serde_properties];
```

#### Alter Table Storage Properties
该语句只修改metadata，用户需要自己确保实际数据的格式与改完后的metadata相符，不建议这样使用

```sql
ALTER TABLE table_name CLUSTERED BY (col_name, col_name, ...) [SORTED BY (col_name, ...)]
  INTO num_buckets BUCKETS;
```

#### Alter Table Skewed
原始非倾斜表修改为倾斜表

```sql
ALTER TABLE table_name SKEWED BY (col_name1, col_name2, ...)
  ON ([(col_name1_value, col_name2_value, ...) [, (col_name1_value, col_name2_value), ...]
  [STORED AS DIRECTORIES];
```

#### Alter Table Not Skewed
倾斜表修改为非倾斜表

```sql
ALTER TABLE table_name NOT SKEWED;
```

#### Alter Table Not Stored as Directories
改为不单独存储倾斜列

```sql
ALTER TABLE table_name NOT STORED AS DIRECTORIES;
```

#### Alter Table Set Skewed Location
修改倾斜表存储位置

```sql
ALTER TABLE table_name SET SKEWED LOCATION (col_name1="location1" [, col_name2="location2", ...] );
```

#### Alter Table Constraints
2.1.0版本呢新增功能，只做记录，后期使用该版本时再进行验证

```sql
ALTER TABLE table_name ADD CONSTRAINT constraint_name PRIMARY KEY (column, ...) DISABLE NOVALIDATE;
ALTER TABLE table_name ADD CONSTRAINT constraint_name FOREIGN KEY (column, ...) REFERENCES table_name(column, ...) DISABLE NOVALIDATE RELY;
ALTER TABLE table_name DROP CONSTRAINT constraint_name;
```

#### Add Partitions
与修改bucket类似，修改分区仅修改metadata，实际数据需要用户自己修改

```sql
ALTER TABLE table_name ADD PARTITION (dt='2008-08-08', country='us') location '/path/to/us/part080808'
                           PARTITION (dt='2008-08-09', country='us') location '/path/to/us/part080809';
```

#### Dynamic Partitions
从其他表中通过子查询的方式导入数据至当前表的若干分区

* SP Columns: 在HQL语句提交编译时已经由用户指定取值的列称为静态分区列
* DP Columns: 在HQL语句执行期间根据上下文才能确定取值的列称为动态分区列

```sql
-- 全部基于DP使用，数据按照ds值做主分区，按照hr值做第二层子分区
INSERT OVERWRITE TABLE T PARTITION (ds, hr)
SELECT key, value, ds, hr FROM srcpart WHERE ds is not null and hr>10;

-- SP和DP混合使用，DP是SP的子目录，数据全放在'2010-03-03'主分区，然后按照hr值做第二层子分区
INSERT OVERWRITE TABLE T PARTITION (ds='2010-03-03', hr)
SELECT key, value, /*ds,*/ hr FROM srcpart WHERE ds is not null and hr>10;

-- 不允许出现SP是DP的子目录的这种用法，因为无法在DML语句中调换父子目录的关系
INSERT OVERWRITE TABLE T PARTITION (ds, hr = 11)
SELECT key, value, ds/*, hr*/ FROM srcpart WHERE ds is not null and hr=11;

-- 把一个表的数据导入到多个表的分区，此时需要采用FROM前置的写法
FROM S
INSERT OVERWRITE TABLE T PARTITION (ds='2010-03-03', hr)
SELECT key, value, ds, hr FROM srcpart WHERE ds is not null and hr>10
INSERT OVERWRITE TABLE R PARTITION (ds='2010-03-04', hr=12)
SELECT key, value, ds, hr from srcpart where ds is not null and hr = 12;

-- CTAS
CREATE TABLE T (key int, value string) PARTITIONED BY (ds string, hr int) AS
SELECT key, value, ds, hr+1 hr1 FROM srcpart WHERE ds is not null and hr>10;

--
CREATE TABLE T (key int, value string) PARTITIONED BY (ds string, hr int) AS
SELECT key, value, "2010-03-03", hr+1 hr1 FROM srcpart WHERE ds is not null and hr>10;
```

#### Rename Partition
相当于更改了分区对应的那个列的值，原分区目录下的子目录以及文件会剪切到新的分区目录，在HDFS上实际上只调整了元数据映射关系，数据块并没有移动

```sql
ALTER TABLE table_name PARTITION partition_spec RENAME TO PARTITION partition_spec;
```

#### Exchange Partition
将分区从一个表迁移到另一个表，要求两个表结构一致且目标表没有这个分区

```sql
-- 迁移单个分区
ALTER TABLE table_name_2 EXCHANGE PARTITION (partition_spec) WITH TABLE table_name_1;

-- 迁移多个分区
ALTER TABLE table_name_2 EXCHANGE PARTITION (partition_spec, partition_spec2, ...) WITH TABLE table_name_1;
```

#### Recover Partitions
当我们手动传数据到hdfs作为一个分区时，或者在原有数据基础上手动做了修改，需要在metadata进行设置以便能够识别。
需要注意的是，属性`hive.msck.repair.batch.size`可以设置每次repair动作批量处理多个分区，默认是0，表示一次执行所有分区，但当存在大量新添加或被修改的分区时，很有可能会引起OOME(内存不足错误)，此时就需要通过该参数来限制分区数量了。

```sql
MSCK REPAIR TABLE table_name;
```

#### Drop Partitions
删除分区时同时删除metadata和data，删除的data到用户垃圾箱，与Drop table一样，也可以使用PURGE直接完全删除

```sql
ALTER TABLE table_name DROP [IF EXISTS] PARTITION partition_spec[, PARTITION partition_spec, ...]
  [IGNORE PROTECTION] [PURGE];

-- 对于设置了NO_DROP CASCADE属性的受保护分区，可以选择使用IGNORE来跳过，进而可以删除其他分区
ALTER TABLE table_name DROP [IF EXISTS] PARTITION partition_spec IGNORE PROTECTION;
```

#### (Un)Archive Partition
将分区的文件移动到HAR压缩文档中，实际上只是减少了文件数量，hadoop并没有进行任何的压缩/解压缩操作

```sql
ALTER TABLE table_name ARCHIVE PARTITION partition_spec;
ALTER TABLE table_name UNARCHIVE PARTITION partition_spec;
```

#### Alter Table/Partition File Format
修改表或者分区的文件存储格式

```sql
ALTER TABLE table_name [PARTITION partition_spec] SET FILEFORMAT file_format;
```

#### Alter Table/Partition Location
修改表或者分区的文件存储位置

```sql
ALTER TABLE table_name [PARTITION partition_spec] SET LOCATION "new location";
```

#### Alter Table/Partition Touch
？

```sql
ALTER TABLE table_name TOUCH [PARTITION partition_spec];
```

#### Alter Table/Partition Protections
设置表或分区的数据保护标志。

* NO_DROP: 防止表或分区被删除
* OFFLINE: 不允许查询表或分区中的数据，但元数据仍然能够访问
* 如果某表的任一分区启用了NO_DROP，那么该表也不能被删除
* 但是就算某表启用了NO_DROP，该表的分区还是可能被删除
* 对于使用NO_DROP CASCADE修饰的分区，只能采用IGNORE PROTECTION的DROP命令才能够删除

```sql
ALTER TABLE table_name [PARTITION partition_spec] ENABLE|DISABLE NO_DROP [CASCADE];

ALTER TABLE table_name [PARTITION partition_spec] ENABLE|DISABLE OFFLINE;
```

#### Alter Table/Partition Compact


#### Alter Table/Partition Concatenate


#### Alter Rules for Column Names




### Load
```sql
LOAD DATA [LOCAL] INPATH 'filepath' [OVERWRITE] INTO TABLE tablename [PARTITION (partcol1=val1, partcol2=val2 ...)]
```

* load数据时不会进行任何转换，只是将数据文件拷贝或移动到Hive表对应的目录位置
* load的目标可以是table或partition，必须指定所有分区列的值来确定放到哪一个分区
* 输入的filepath可以是文件或目录，若是目录则移动其下所有文件，但filepath不能包含子目录
* LOCAL用于先从本地文件系统复制到hive所在的文件系统，然后添加到hive表目录中，LOCAL根目录为用户当前目录
* 不使用LOCAL时，filepath与Hive必在同一文件系统中，其根目录是/user/<username>
* OVERWRITE时，table或分区的内容被删除，filepath的内容替换或被添加
