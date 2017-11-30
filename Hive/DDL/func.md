# 大数据平台
* 大数据基础平台基于稳定的开源Hadoop版本，为上层应用提供数据存储和计算服务，我们持续地跟进Hadoop生态圈的演进和发展，针对安全性、易用性、容错性等方面着重进行改进，并为项目提供升级服务。

* 大数据平台采用C/S架构来管理和运维集群，提供了基于Web的操作维护平台来统一配置、管理和监控集群各个节点、服务以及组件，不仅实现了对HDFS、MapReduce、Yarn、Hive、Tez、Spark、HCatalog、HBase、ZooKeeper、Oozie、Pig等常用大数据组件的良好支持，还提供了一系列查看集群健康状态和组件工作状态的可视化页面，极大的方便了运营中的集群扩展、性能诊断和故障运维。

* 人性化的UI交互设计理念，渐进式的部署过程引导，结合丰富的输入信息提醒，使得部署过程可视化、向导化，只需人为输入少量的信息，极大的降低了大数据平台的部署难度以及出现错误的几率，部署成功后还会自动生成集群配置清单，方便导出和打印。

* 随着大数据技术的发展，现有组件版本不定期的进行升级，新技术组件也不断的涌现，我们通过长期持续的组件兼容性测试，多样化的应用场景案例，结合专家级的系统性能分析，使得组件选择简单化、智能化，不但增强了大数据平台的兼容性和稳定性，还会根据集群规模和硬件配置给出默认的配置建议。

* 通过Stack-Service-Component三层架构的组件安装包设计，自动化的安装脚本运用，结合高效的集群主机间数据同步方案，使得集群扩展完全自动化、傻瓜化，按照提示的若干步骤，只通过几个简单的按键或拖拽操作，就能够实现已有组件和集群主机的调整，即便在调整过程中出现严重错误而导致大数据平台无法正常工作，还可以利用回滚功能将集群恢复到之前的状态。

* 大数据平台还支持自定义编辑Blueprint和自动导出Blueprint，其简单的语法编辑规则，结合丰富的集群运维工具支持，使得备份现有集群部署方案非常简便，Blueprint可重复的在测试、集成、生产等环境部署，真正做到“一次构建，处处运行”。

* 支持自定义组件，第三方Service按照组件框架实现 start、stop、status、configure这些生命周期控制命令、生成Service对应的metainfi.xml配置文件，就可以在Web UI中通过添加组件的方式将Service纳入到大数据平台中进行统一管理。

* 大数据平台构建了一个配置共享中心，依照组件进行分类，条理清晰，并且为每个配置项提供详细的描述信息和建议值，特别地将若干直接影响集群计算能力和存储性能的核心配置项单独列出，采用开关量、滑动条、度量尺等可视化方式，配合不同的颜色来突出临界值，增加用户对配置影响范围的直观感受，并且引导用户完成组件配置。

* 配置更改版本化管理，针对每次配置更改，大数据平台都会自动构建并保存一个对应的版本并给予版本号，在不同版本之间可以进行对比，预览两者之间的差异时会以不同的颜色标识出来，如果集群环境没有发生变化，各个版本之间可以根据需要随时进行相互切换，极大的方便了后期优化和日常运维。

* 组件及其配置版本分组管理，针对不同的应场景或是业务需求，将若干组件以及指定的配置版本创建成为一个分组，随着场景或需求的变化来一键切换分组，批量的应用多个组件的配置，同时还为高可用、安全等功能制订了模板，一键化启用或禁止，这些手段有效地降低在整个平台上管理和配置多个组件的复杂性，有助降低遗漏几率，提高用户体验。

* 基于Master-Slave架构的Metrics指标体系，进行集群指标的采集、存储、聚集和提取，从而提炼出于集群主机相关的JVM、CPU、内存、磁盘等信息，以及大数据组件各个Service模块的CPU占用率、内存、网络状态等信息。

* 基于Grafana来分析Metrics收集到的性能信息，并在Web上导入用于展示Metrics的Widget，每一个Widget对应一个或多个指标项，它们的表现方式也不尽相同，有表达某个时间段内变化趋势的曲线图或柱状图；也有表达某类资源使用率的百分比图；还有用于直接显示实时状态的数值，并可以为其配置一个单位如GB、MB等。

* 为了帮助用户鉴别以及定位集群的问题，引入了Alert框架来实现告警机制，在平台中内置了很多最佳实践的预定义告警，这些告警被用于监测集群主机以及组件各个Service的状态，然后集中展示在Web的告警信息页面，并且在组件页面还会标识出那些组件出现了告警以及当前告警的数量。用户还可以根据实际情况来修改预定义告警的检测时间间隔、阈值、描述信息以及启用状态等，还可以通过配置邮件服务器来依照告警分组或告警等级实现邮件主动通知。

* 支持维护模式切换功能，提供针对基于主机、服务、组件三种级别的作用范围，让用户在调试或维护Service的时候，抑制不必要的告警信息，以及避免批量操作的影响。

* 提供全面丰富的REST API设计，通过REST API接口，可以在脚本中通过curl维护整个集群，并且还可以在不破坏平台功能的基础上与第三方的平台集成。

# 大数据组件
## Hive
* Hive是建立在Hadoop上的数据仓库基础构架。它提供了一系列的工具，将Hadoop上存储的结构化的数据文件映射为一张数据库表，并定义了被称为HQL的类SQL查询语言来提供完整的查询功能。

* 大多数情况下，可以通过HQL语句快速实现简单的MapReduce统计，不必开发专门的MapReduce应用，同时也允许熟悉MapReduce开发者的开发自定义的mapper和reducer来处理更为复杂的分析工作。

* 通过数据库表的Partition、Bucket机制，针对不同维度来对数据进行分类，减少不必要的全表数据扫描，进而提高查询性能。

* 提供偏斜数据的Skewed机制，将若干列大量重复的偏斜数据先分类再集中存储，以便skew task分解成多个task，最后再合并结果。

* 支持单表索引，提供了索引创建接口和调用方法，可由用户根据需要实现索引结构。

* 支持MapReduce、Tez和Spark计算框架，由用户根据业务需求和计算量的不同选择合适的查询引擎。

* 提供了丰富的分析窗口函数，用于完成负责的统计分析。

## HBase
* 数据按列存储，每一列单独存放，数据即索引，在查询只需要少数几个字段的时候，只访问涉及的列，大量降低系统I/O，更容易为这种聚集存储设计更好的压缩和解压算法。

* 通过Rowkey检索数据，仅支持单行事务，依靠横向扩展，通过不断增加存储节点来扩展存储能力。

* 单表可以有百亿行、百万列，数据矩阵横向和纵向两个维度所支持的数据量级都非常具有弹性。

* 为空的列并不占用存储空间，表可以设计得非常稀疏。

* 提供WAL日志和Replication机制，来保证写入异常和节点故障时不会丢失数据。

* 底层的LSM数据结构和Rowkey有序排列等架构设计，使其具备非常高的写入性能。

* Region切分，主键索引和缓存机制使得在海量数据下具备一定的毫秒级随机读取性能。

## Hive实例

su hdfs

hdfs dfs -mkdir /tmp/csv
hdfs dfs -put /home/hdfs/csv/*.csv /tmp/csv/

beeline -u "jdbc:hive2://nn.daowoo.com:2181,snn.daowoo.com:2181,hive.daowoo.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -n "hdfs" -p "hdfs"

```sql
use example;
set hive.execution.engine=mr;

CREATE TABLE IF NOT EXISTS test1(id INT, name STRING, age INT, phone STRING, address STRING, email STRING, vip STRING, level STRING)
COMMENT 'THIS IS EXAMPLE'
PARTITIONED BY (datatime STRING)
ROW FORMAT
DELIMITED FIELDS TERMINATED BY '|'
STORED AS TEXTFILE;

LOAD DATA INPATH '/tmp/csv/dataSep-2017-9-6.csv'
OVERWRITE INTO TABLE test1
PARTITION(datatime='20170906');

LOAD DATA INPATH '/tmp/csv/dataSep-2017-9-7.csv'
OVERWRITE INTO TABLE test1
PARTITION(datatime='20170907');

LOAD DATA INPATH '/tmp/csv/dataSep-2017-9-8.csv'
OVERWRITE INTO TABLE test1
PARTITION(datatime='20170908');

select count(*) from test1;


SELECT 1 AS GN, * FROM (SELECT * FROM storage.test1 WHERE datatime='20170906' LIMIT 1) AS t1
UNION ALL
SELECT 2 AS GN, * FROM (SELECT * FROM storage.test1 WHERE datatime='20170907' LIMIT 1) AS t2
UNION ALL
SELECT 3 AS GN, * FROM (SELECT * FROM storage.test1 WHERE datatime='20170908' LIMIT 1) AS t3
UNION ALL
SELECT 4 AS GN, * FROM (SELECT * FROM storage.test1 WHERE datatime='20170909' LIMIT 1) AS t4
UNION ALL
SELECT 5 AS GN, * FROM (SELECT * FROM storage.test1 WHERE datatime='20170910' LIMIT 1) AS t5


CREATE TABLE IF NOT EXISTS test3(id INT, name STRING, age INT, phone STRING, address STRING, email STRING, vip STRING, level STRING)
PARTITIONED BY (datatime STRING)
CLUSTERED by (level) INTO 10 BUCKETS
STORED AS ORC
TBLPROPERTIES ('transactional' = 'true');

CREATE TABLE IF NOT EXISTS storage.test11(id INT, name STRING, age INT, phone STRING, address STRING, email STRING, vip STRING, level STRING)
PARTITIONED BY (datatime STRING)
CLUSTERED by (level) INTO 10 BUCKETS
STORED AS ORC;

FROM storage.test1
INSERT OVERWRITE TABLE storage.test11 PARTITION (datatime)
SELECT id,name,age,phone,address,email,vip,level,datatime WHERE id IS NOT NULL;

SELECT INPUT__FILE__NAME,BLOCK__OFFSET__INSIDE__FILE FROM storage.test11 LIMIT 10;

FROM test1
INSERT INTO TABLE test3 PARTITION (datatime)
SELECT id,name,age,phone,address,email,vip,level,datatime WHERE id IS NOT NULL;


analyze table test1 partition(datatime='20170908') compute statistics;
analyze table test1 partition(datatime) compute statistics;

analyze table test1 partition(datatime='20170908') compute statistics for columns;
analyze table test1 partition(datatime) compute statistics for columns;

-- 创建索引
create index test_index on table test1(level)
as 'compact'
with deferred rebuild
in table test_index_table;

-- 生成索引
alter index test_index on test1 rebuild;

-- 查看索引
select * from test_index_table limit 10;
drop index test_index on test1;

-- insert values方式插入数据
insert into table test1 partition (datatime='20170908')
values (3101,'panhongfa',34,'(09) 9829 5354','Nulla facilisis','panhongfa@daowoo.com','Yes','nine');

-- ACID表支持update、delete和merge
CREATE TABLE IF NOT EXISTS test2(id INT, name STRING, age INT, phone STRING, address STRING, email STRING, vip STRING, level STRING)
PARTITIONED BY (datatime STRING)
CLUSTERED by (level) INTO 10 BUCKETS
STORED AS ORC
TBLPROPERTIES ('transactional' = 'true');

FROM test1
INSERT OVERWRITE TABLE test2 PARTITION (datatime)
SELECT id,name,age,phone,address,email,vip,level,datatime WHERE id IS NOT NULL;
update test2 set name = 'panhongfas',age = 36 where id = 3101;
delete from test2 where id = 3101;

alter table test1 set tblproperties ('transactional' = 'true');
alter table test2 set tblproperties ('transactional' = 'false');

CREATE TABLE IF NOT EXISTS test3(id INT, name STRING, datatime STRING)
CLUSTERED by (id) INTO 3 BUCKETS
STORED AS ORC
TBLPROPERTIES ('transactional' = 'true');

-- merge过程测试
CREATE DATABASE merge_data;

CREATE TABLE merge_data.transactions(ID int,TranValue string,last_update_user string)
PARTITIONED BY (tran_date string)
CLUSTERED BY (ID) into 5 buckets
STORED AS ORC TBLPROPERTIES ('transactional'='true');

CREATE TABLE merge_data.merge_source(ID int,TranValue string,tran_date string)
STORED AS ORC;

INSERT INTO merge_data.transactions PARTITION (tran_date) VALUES
(1, 'value_01', 'creation', '20170410'),
(2, 'value_02', 'creation', '20170410'),
(3, 'value_03', 'creation', '20170410'),
(4, 'value_04', 'creation', '20170410'),
(5, 'value_05', 'creation', '20170413'),
(6, 'value_06', 'creation', '20170413'),
(7, 'value_07', 'creation', '20170413'),
(8, 'value_08', 'creation', '20170413'),
(9, 'value_09', 'creation', '20170413'),
(10, 'value_10','creation', '20170413');

INSERT INTO merge_data.merge_source VALUES
(1, 'value_01', '20170410'),
(4, NULL, '20170410'),
(7, 'value_77777', '20170413'),
(8, NULL, '20170413'),
(8, 'value_08', '20170415'),
(11, 'value_11', '20170415');

MERGE INTO merge_data.transactions AS T
USING merge_data.merge_source AS S
ON T.ID = S.ID and T.tran_date = S.tran_date
WHEN MATCHED AND (T.TranValue != S.TranValue AND S.TranValue IS NOT NULL) THEN UPDATE SET TranValue = S.TranValue, last_update_user = 'merge_update'
WHEN MATCHED AND S.TranValue IS NULL THEN DELETE
WHEN NOT MATCHED THEN INSERT VALUES (S.ID, S.TranValue, 'merge_insert', S.tran_date);

-- VirtualColumns
-- INPUT__FILE__NAME: Map任务对应的输入文件名
-- BLOCK__OFFSET__INSIDE__FILE: 当前全局文件的位置，或者在块压缩文件中，当前block的文件偏移量即块第一个字节相对于文件头的偏移量

SELECT INPUT__FILE__NAME,BLOCK__OFFSET__INSIDE__FILE FROM storage.test2;
```


累积统计函数，支持WINDOW子句，WINDOW子句的定义如下:
* ROWS BETWEEN标识窗口作用范围，不指定时，默认为从起点到当前行
* 如果不指定ORDER BY，则将分组内所有值累加
* PRECEDING：往前
* FOLLOWING：往后
* CURRENT ROW：当前行
* UNBOUNDED：起点
* UNBOUNDED PRECEDING 表示从前面的起点
* UNBOUNDED FOLLOWING：表示到后面的终点


```sql
SELECT * FROM test2 WHERE datatime='20170908' LIMIT 3;

-- 按照VIP分组后按ID排序，最后指定窗口来求窗口范围内的记录累加和
SELECT vip, id, name, age,
SUM(age) OVER(PARTITION BY vip ORDER BY id) AS age1,
SUM(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS age2,
SUM(age) OVER(PARTITION BY vip) AS age3,
SUM(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS age4,
SUM(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN 3 PRECEDING AND 1 FOLLOWING) AS age5,
SUM(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS age6
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 10) AS T;

-- 按照VIP分组后按ID排序，最后指定窗口来求窗口范围内的记录个数
SELECT vip, id, name, age,
COUNT(age) OVER(PARTITION BY vip ORDER BY id) AS age1,
COUNT(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS age2,
COUNT(age) OVER(PARTITION BY vip) AS age3,
COUNT(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS age4,
COUNT(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN 3 PRECEDING AND 1 FOLLOWING) AS age5,
COUNT(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS age6
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 10) AS T;

-- 按照VIP分组后按ID排序，最后指定窗口来求窗口范围内的平均值
SELECT vip, id, age,
AVG(age) OVER(PARTITION BY vip ORDER BY id) AS age1,
AVG(age) OVER(PARTITION BY vip) AS age3,
AVG(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS age4,
AVG(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN 3 PRECEDING AND 1 FOLLOWING) AS age5,
AVG(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS age6
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 10) AS T;

-- 按照VIP分组后按ID排序，最后指定窗口来求窗口范围内的最小值
SELECT vip, id, age,
MIN(age) OVER(PARTITION BY vip ORDER BY id) AS age1,
MIN(age) OVER(PARTITION BY vip) AS age3,
MIN(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS age4,
MIN(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN 3 PRECEDING AND 1 FOLLOWING) AS age5,
MIN(age) OVER(PARTITION BY vip ORDER BY id ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS age6
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 20) AS T;
```

序列函数，它们不支持WINDOW子句
```sql
-- 将分组后的记录集按照顺序切分成指定片后返回切片序号
-- 注意，如果切片不均匀，则优先将剩余记录分配到序号小的切片中
SELECT vip, id, age,
NTILE(2) OVER(PARTITION BY vip ORDER BY age) AS rn1,
NTILE(6) OVER(PARTITION BY vip ORDER BY age) AS rn2,
NTILE(9) OVER(ORDER BY age) AS rn3
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;

-- 将分组后的记录按照规则进行排序，然后从1开始为分组记录生成序号
SELECT vip, id, age,
ROW_NUMBER() OVER(PARTITION BY vip ORDER BY age ASC) AS rn
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;

SELECT vip, id, age,
ROW_NUMBER() OVER(PARTITION BY vip ORDER BY id DESC) AS rn
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;

-- 将分组后的记录按照规则进行排序，生成数据项在分组中的排名，和记录序号比较其作用就一目了然
-- 注意，在遇到排名相等的项时，RANK会在名次中进行占位，后续累加，而DENSE_RANK则不会占位及累加
SELECT vip, id, age,
ROW_NUMBER() OVER(PARTITION BY vip ORDER BY age) AS rn1,
RANK() OVER(PARTITION BY vip ORDER BY age) AS rn2,
DENSE_RANK() OVER(PARTITION BY vip ORDER BY age) AS rn3
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;
```

```sql
-- 统计出小于等于排序列当前行值的记录在分组中所占的比例，结果是double值
-- 注意，如果没有指定分组，则所有行均视为一组
SELECT vip, id, age,
CUME_DIST() OVER(ORDER BY age) AS rn1,
CUME_DIST() OVER(PARTITION BY vip ORDER BY age) AS rn2
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;

-- 通过WHERE子句在MAP阶段过滤掉一部分数据
SELECT vip, id, age,
CUME_DIST() OVER(ORDER BY age) AS rn1,
CUME_DIST() OVER(PARTITION BY vip ORDER BY age) AS rn2
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T
WHERE age <= 20;

-- (分组内当前行的RANK值 - 1)/(分组内总行数 - 1)
-- 同样，如果没有指定分组，则所有行均视为一组
SELECT vip, id, age,
PERCENT_RANK() OVER(ORDER BY age) AS rn1,
RANK() OVER(ORDER BY age) AS rn11,
SUM(1) OVER(PARTITION BY NULL) AS rn12,
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;

SELECT vip, id, age,
PERCENT_RANK() OVER(PARTITION BY vip ORDER BY age) AS rn2,
RANK() OVER(PARTITION BY vip ORDER BY age) AS rn21,
SUM(1) OVER(PARTITION BY vip) AS rn22
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;

```

分析和统计函数，也不支持WINDOW子句:
```sql
-- 统计窗口内往上第N行的值，格式为LAG(col,n,DEFAULT)
-- col:列名; n:往上第几行; DEFAULT:当往上n行为NULL时取默认值，若不指定则直接去NULL
SELECT vip, id, age,
ROW_NUMBER() OVER(PARTITION BY vip ORDER BY age) AS rn1,
LAG(age,1,100) OVER(PARTITION BY vip ORDER BY age) AS rn2,
LAG(age,3) OVER(PARTITION BY vip ORDER BY age) AS rn3,
LAG(age,8) OVER(PARTITION BY vip ORDER BY age) AS rn4
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;

-- 与LAG相反，统计窗口内往下第N行的值，格式为LEAD(col,n,DEFAULT)
SELECT vip, id, age,
ROW_NUMBER() OVER(PARTITION BY vip ORDER BY age) AS rn1,
LEAD(age,1,100) OVER(PARTITION BY vip ORDER BY age) AS rn2,
LEAD(age,3) OVER(PARTITION BY vip ORDER BY age) AS rn3,
LEAD(age,8) OVER(PARTITION BY vip ORDER BY age) AS rn4
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;

-- 进行分组并排序后，取截止到当前行的第一个值
-- 注意，第一个值指的是第一个不为空的值，前面都为空则取NULL
SELECT vip, id, age,
ROW_NUMBER() OVER(PARTITION BY vip ORDER BY age) AS rn1,
FIRST_VALUE(age) OVER(PARTITION BY vip ORDER BY age) AS rn2,
FIRST_VALUE(name) OVER(PARTITION BY vip ORDER BY age) AS rn3,
FIRST_VALUE(level) OVER(PARTITION BY vip ORDER BY age) AS rn4
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;

-- 与FIRST_VALUE相反，去截止到当前行的最后一个值
-- 如果每行都不为空，实际上取的就是当前行的值
SELECT vip, id, age,
ROW_NUMBER() OVER(PARTITION BY vip ORDER BY age) AS rn1,
LAST_VALUE(age) OVER(PARTITION BY vip ORDER BY age) AS rn2,
LAST_VALUE(name) OVER(PARTITION BY vip ORDER BY age) AS rn3,
LAST_VALUE(level) OVER(PARTITION BY vip ORDER BY age) AS rn4
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;

-- 如果不指定ORDER BY排序，则默认按照记录在文件中的偏移量排序，此时得到的是错误结果
SELECT vip, id, age,
FIRST_VALUE(age) OVER(PARTITION BY vip) AS rn1,
LAST_VALUE(age) OVER(PARTITION BY vip) AS rn2
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;
--

-- 如果想取分组排序后，组内排序最后的一个值，可以通过使用DESC来指定逆序排序，从而得到结果
SELECT vip, id, age,
ROW_NUMBER() OVER(PARTITION BY vip ORDER BY age) AS rn1,
LAST_VALUE(age) OVER(PARTITION BY vip ORDER BY age ASC) AS rn2,
FIRST_VALUE(age) OVER(PARTITION BY vip ORDER BY age DESC) AS rn3
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T;
```

常用于OLAP中，不能累加，
```sql
-- GROUPING SETS指的是在一个GROUP BY(A,B)查询中，对如下维度(A,NULL)、(NULL,B)组合的结果集进行聚合（维度由逗号分隔）
-- GROUPING__ID表示结果属于哪一个分组集合的ID
SELECT vip, id,
COUNT(DISTINCT age) AS uv,
GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T
GROUP BY vip, id
GROUPING SETS (vip, id)
ORDER BY GROUPING__ID;

-- 等价于将不同维度的GROUP BY结果集进行UNION ALL
SELECT vip, NULL,
COUNT(DISTINCT age) AS uv,
1 AS GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T
GROUP BY vip
UNION ALL
SELECT NULL, id,
COUNT(DISTINCT age) AS uv,
2 AS GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T
GROUP BY id;

-- 为GROUP BY添加一个组合维度(vip, id)
SELECT vip, id,
COUNT(DISTINCT age) AS uv,
GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T
GROUP BY vip, id
GROUPING SETS (vip, id, (vip, id))
ORDER BY GROUPING__ID;

-- 上面的语句等价于以下三个子查询进行UNION ALL
-- 注意Hive2.1+版本，组合维度(vip, id)的GROUPING__ID值已修改为3

SELECT vip, id,
COUNT(DISTINCT age) AS uv,
0 AS GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T
GROUP BY vip, id
UNION ALL
SELECT vip, NULL,
COUNT(DISTINCT age) AS uv,
1 AS GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T
GROUP BY vip
UNION ALL
SELECT NULL, id,
COUNT(DISTINCT age) AS uv,
2 AS GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 30) AS T
GROUP BY id;

-- CUBE指的是在一个GROUP BY(A,B)查询中，对所有维度(NULL,NULL)、(A,NULL)、(NULL,B)、(A,B)组合的结果集进行聚合（维度由逗号分隔）
SELECT vip, id,
COUNT(DISTINCT age) AS uv,
GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 10) AS T
GROUP BY vip, id
WITH CUBE
ORDER BY GROUPING__ID;

-- 上面的语句等价于以下四个子查询进行UNION ALL
SELECT vip, id,
COUNT(DISTINCT age) AS uv,
0 AS GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 10) AS T
GROUP BY vip, id
UNION ALL
SELECT vip, NULL,
COUNT(DISTINCT age) AS uv,
1 AS GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 10) AS T
GROUP BY vip
UNION ALL
SELECT NULL, id,
COUNT(DISTINCT age) AS uv,
2 AS GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 10) AS T
GROUP BY id
UNION ALL
SELECT NULL, NULL,
COUNT(DISTINCT age) AS uv,
3 AS GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 10) AS T;

-- ROLLUP是CUBE的子集，以最左侧的维度为主，从该维度进行层级聚合
-- 在一个GROUP BY(A,B)查询中，聚合的过程以A为主，即(A,B)、(A,NULL)、(NULL,NULL)
SELECT vip, id,
COUNT(DISTINCT age) AS uv,
GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 10) AS T
GROUP BY vip, id
WITH ROLLUP
ORDER BY GROUPING__ID;

-- 如果是GROUP BY(B,A)查询中，聚合的过程则以B为主，即(B,A)、(B,NULL)、(NULL,NULL)
-- 注意观察与上面(A,B)方式的差别
SELECT vip, id,
COUNT(DISTINCT age) AS uv,
GROUPING__ID
FROM (SELECT * FROM test2 WHERE datatime='20170908' LIMIT 10) AS T
GROUP BY id, vip
WITH ROLLUP
ORDER BY GROUPING__ID;
```

## 典型案例分析

|   名称   |     字段     |  类型  |
| -------- | ------------ | ------ |
| 区域名称 | zone_name    | STRING |
| 商品类型 | item_type    | STRING |
| 商品质量 | item_quality | STRING |
| 消费者ID | user_id      | STRING |
| 购买数量 | amount       | INT    |
| 消费金额 | cost_usd     | DOUBLE |
| 消费时段 | hour         | INT    |
| 日期     | data         | STRING |



```sql

CREATE TABLE IF NOT EXISTS example1_src(zone_name STRING, item_type STRING, item_quality STRING, user_id STRING, amount INT, cost_usd DOUBLE, hour INT)
PARTITIONED BY (data STRING)
ROW FORMAT
DELIMITED FIELDS TERMINATED BY '|'
STORED AS TEXTFILE;

LOAD DATA INPATH '/tmp/csv2/dataOct-20170901.csv'
OVERWRITE INTO TABLE example1_src
PARTITION(data='20170901');

LOAD DATA INPATH '/tmp/csv2/dataOct-20170902.csv'
OVERWRITE INTO TABLE example1_src
PARTITION(data='20170902');

LOAD DATA INPATH '/tmp/csv2/dataOct-20170903.csv'
OVERWRITE INTO TABLE example1_src
PARTITION(data='20170903');

LOAD DATA INPATH '/tmp/csv2/dataOct-20170904.csv'
OVERWRITE INTO TABLE example1_src
PARTITION(data='20170904');

CREATE TABLE IF NOT EXISTS example1_dest(zone_name STRING, item_type STRING, item_quality STRING, user_id STRING, amount INT, cost_usd DOUBLE, hour INT)
PARTITIONED BY (data STRING)
CLUSTERED by (hour) INTO 24 BUCKETS
STORED AS ORC;

FROM example1_src
INSERT OVERWRITE TABLE example1_dest PARTITION (data)
SELECT zone_name,item_type,item_quality,user_id,amount,cost_usd,hour,data
WHERE amount IS NOT NULL AND hour IS NOT NULL;

SELECT zone_name AS zone_name, item_type AS item_type,
RANK() OVER (PARTITION BY item_type ORDER BY bsearches) AS rank_1,
bsearches
FROM (
SELECT zone_name, item_type, COUNT(DISTINCT user_id) AS bsearches
FROM example1_dest
WHERE data == '20170902'
GROUP BY zone_name, item_type
) AS T;

-- 各类商品按照销售总金额由大到小的方式进行排序
SELECT item_type AS item_type,
COUNT(DISTINCT user_id) AS bsearches,
COUNT(*) AS imps,
SUM(amount) AS amounts,
ROUND(SUM(cost_usd), 2) AS total,
ROUND(SUM(cost_usd)/SUM(amount), 7) AS ppc,
ROUND(SUM(amount)/COUNT(*), 7) AS ctr
FROM example1_dest
WHERE data >= '20170901' AND data <= '20170902'
GROUP BY item_type
HAVING bsearches > 0
ORDER BY total DESC;



USE storage;

-- 指定区域内各类商品的销售量、销售金额以及它们在总量和总金额中所占的比例
SELECT zone_name AS zone_name, item_type, item_type_amount, total_amount, item_type_cost, total_cost,
ROUND(item_type_amount/total_amount, 4) AS amount_per,
ROUND(item_type_cost/total_cost, 4) AS cost_per
FROM (
SELECT DISTINCT zone_name AS zone_name, item_type AS item_type,
SUM(amount) OVER (PARTITION BY item_type) AS item_type_amount,
SUM(cost_usd) OVER (PARTITION BY item_type) AS item_type_cost,
SUM(amount) OVER () AS total_amount,
SUM(cost_usd) OVER () AS total_cost
FROM example1_dest
WHERE data >= '20170901' AND data <= '20170902' AND zone_name = '洪山区'
) AS T
ORDER BY cost_per DESC
LIMIT 5;



-- 统计各个区域内消费者购买次数最多的前5类商品
SELECT *
FROM (
  SELECT zone_name AS zone_name, item_type AS item_type,
  RANK() OVER (PARTITION BY zone_name ORDER BY COUNT(DISTINCT user_id) DESC) AS rank_1,
  COUNT(DISTINCT user_id) AS bsearches,
  COUNT(*) AS imps,
  SUM(amount) AS amounts,
  ROUND(SUM(cost_usd), 2) AS total,
  ROUND(SUM(cost_usd)/SUM(amount), 2) AS ppc,
  ROUND(SUM(amount)/COUNT(*), 2) AS ctr
  FROM example1_dest
  WHERE data >= '20170901' AND data <= '20170910'
  GROUP BY zone_name, item_type
  HAVING bsearches > 0
) T
WHERE rank_1 <= 5
ORDER BY zone_name, rank_1;

-- 统计各类商品在不同时间段内，消费者关注度的排名
SELECT * FROM (
SELECT item_type, bsearche_rank, cur_bsearches, sum_bsearches, total_bsearches, hour,
ROUND(cur_bsearches/total_bsearches, 5) AS cur_bsearches_ratio,
ROUND(sum_bsearches/total_bsearches, 5) AS sum_bsearches_ratio
FROM(
SELECT hour AS hour, item_type AS item_type,
COUNT(DISTINCT user_id) AS cur_bsearches,
SUM(COUNT(DISTINCT user_id)) OVER (
  PARTITION BY item_type ORDER BY COUNT(DISTINCT user_id) DESC
  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS sum_bsearches,
SUM(COUNT(DISTINCT user_id)) OVER (
  PARTITION BY item_type
) AS total_bsearches,
RANK() OVER (
  PARTITION BY item_type ORDER BY COUNT(DISTINCT user_id) DESC
) AS bsearche_rank
FROM example1_dest
WHERE data >= '20170901' AND data <= '20170903'
GROUP BY hour, item_type
) AS T1
) AS T2
WHERE cur_bsearches_ratio <= 0.1
ORDER BY item_type, bsearche_rank



-- 查询洪山区销量最好的各类商品的详细信息
SELECT T1.zone_name, T1.item_type, T1.item_quality, T1.user_id, T1.amount, T1.cost_usd, T2.* FROM example1_dest AS T1
JOIN(
SELECT item_type, MAX(amount) AS max_amount
FROM example1_dest
WHERE data >= '20170901' AND data <= '20170902' AND zone_name = '洪山区'
GROUP BY item_type
) T2
ON (
  T1.item_type = T2.item_type AND T1.amount = T2.max_amount
)
WHERE data >= '20170901' AND data <= '20170902' AND zone_name = '洪山区'


SELECT * FROM(
SELECT zone_name, item_type, item_quality, user_id, amount, cost_usd,
RANK() OVER(PARTITION BY item_type ORDER BY amount DESC) AS rank_1
FROM example1_dest
WHERE data >= '20170901' AND data <= '20170902' AND zone_name = '洪山区'
) AS T
WHERE T.rank_1=2;



SELECT T1.*, T2.*
FROM (
SELECT item_type, MAX(amount) AS max_amount
FROM example1_dest
WHERE data >= '20170903' AND data <= '20170904' AND zone_name = '洪山区'
GROUP BY item_type
) AS T1
RIGHT JOIN(
SELECT item_type, MAX(amount) AS max_amount
FROM example1_dest
WHERE data >= '20170901' AND data <= '20170902' AND zone_name = '洪山区'
GROUP BY item_type
) T2
ON (
  T1.item_type = T2.item_type AND T1.max_amount = T2.max_amount
)




SELECT T1.zone_name, T1.item_type, T1.item_quality, T1.user_id, T1.amount, T1.cost_usd, T2.*
FROM (
  SELECT * FROM example1_dest
  WHERE data >= '20170901' AND data <= '20170902' AND zone_name = '洪山区'
) AS T1
JOIN(
SELECT item_type, MAX(amount) AS max_amount
FROM example1_dest
WHERE data >= '20170901' AND data <= '20170902' AND zone_name = '洪山区'
GROUP BY item_type
) T2
ON (
  T1.item_type = T2.item_type AND T1.amount = T2.max_amount
)


-- 通过LIKE '%xxx%'的通配符方式查询区域名包含'99'字的行
SELECT zone_name, user_id, hour,
CASE
WHEN hour = 0 THEN '无效 '
WHEN hour > 0 AND hour <= 12 THEN '上午'
WHEN hour > 12 AND hour < 24 THEN '下午'
WHEN hour = 24 THEN '凌晨'
ELSE NULL
END AS tts,
INPUT__FILE__NAME, BLOCK__OFFSET__INSIDE__FILE
FROM example1_dest WHERE data >= '20170901' AND data <= '20170902' AND user_id LIKE '%99%';

-- 通过RLIKE的正则表达式方式查询区域名包含'99'字的行
SELECT zone_name, user_id, hour,
CASE
WHEN hour = 0 THEN '无效 '
WHEN hour > 0 AND hour <= 12 THEN '上午'
WHEN hour > 12 AND hour < 24 THEN '下午'
WHEN hour = 24 THEN '凌晨'
ELSE NULL
END AS tts
FROM example1_dest WHERE data >= '20170901' AND data <= '20170902' AND user_id RLIKE '.*99.*' LIMIT 20;



```
