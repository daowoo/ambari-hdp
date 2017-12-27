# Hive实例

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
