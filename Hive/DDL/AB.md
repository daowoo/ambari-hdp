```sql
-- 登录beeline client
su hdfs
beeline -u "jdbc:hive2://nn.daowoo.com:2181,snn.daowoo.com:2181,hive.daowoo.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -n "hdfs" -p "hdfs"

-- 创建数据库bigdata
CREATE DATABASE IF NOT EXISTS bigdata
LOCATION '/user/phf/bigdata';

select * from src_11 limit 10;

-- 切换数据库
USE bigdata;

-- 上传本地数据至HDFS
`hdfs dfs -put /home/hdfs/python-data/python/*.txt /tmp/python/`

-- 创建源数据表
CREATE TABLE IF NOT EXISTS src_x(type STRING, val STRING)
PARTITIONED BY (file STRING)
ROW FORMAT
DELIMITED FIELDS TERMINATED BY ':'
STORED AS TEXTFILE;

CREATE TABLE IF NOT EXISTS src_y(type STRING, val STRING)
PARTITIONED BY (file STRING)
ROW FORMAT
DELIMITED FIELDS TERMINATED BY ':'
STORED AS TEXTFILE;

-- 导入数据
LOAD DATA INPATH '/tmp/python/11.txt'
OVERWRITE INTO TABLE src_x
PARTITION(file='11-txt');

LOAD DATA INPATH '/tmp/python/21.txt'
OVERWRITE INTO TABLE src_y
PARTITION(file='21-txt');

SELECT * FROM src_x LIMIT 10;
SELECT * FROM src_y LIMIT 10;

SELECT type, cast(trim(regexp_replace(val,"\\.","")) AS BIGINT) new_val FROM src_x LIMIT 10;

-- 合并源数据表，并将浮点数转换成BIGINT
CREATE TABLE IF NOT EXISTS src_xy(val BIGINT)
COMMENT 'THIS IS DEST TABLE'
PARTITIONED BY (file STRING, type STRING)
CLUSTERED BY (val) INTO 20 BUCKETS
STORED AS AVRO;

WITH q1 AS (SELECT type, cast(trim(regexp_replace(val,"\\.","")) AS BIGINT) new_val FROM src_x)
FROM q1
INSERT OVERWRITE TABLE src_xy PARTITION(file='11-txt', type)
SELECT new_val, type WHERE type IS NOT NULL
GROUP BY type, new_val
SORT BY new_val;

WITH q1 AS (SELECT type, cast(trim(regexp_replace(val,"\\.","")) AS BIGINT) new_val FROM src_y)
FROM q1
INSERT OVERWRITE TABLE src_xy PARTITION(file='21-txt', type)
SELECT new_val, type WHERE type IS NOT NULL
GROUP BY type, new_val
SORT BY new_val;

-- 合并后记录的个数
SELECT count(*) FROM src_xy WHERE file='11-txt' AND type='A';
SELECT count(*) FROM src_xy WHERE file='21-txt' AND type='B';
SELECT * FROM src_xy LIMIT 10;

-- 创建存放cross操作结果的dest表
CREATE TABLE IF NOT EXISTS dest(val_x BIGINT, val_y BIGINT, diff BIGINT)
PARTITIONED BY (file STRING, type STRING)
CLUSTERED BY (diff) INTO 20 BUCKETS
STORED AS AVRO;

WITH x AS (SELECT * FROM src_xy WHERE file='11-txt' AND type='A'),
y AS (SELECT * FROM src_xy WHERE file='21-txt' AND type='A')
FROM (SELECT x.val v1, y.val v2, (x.val - y.val) diff FROM x CROSS JOIN y) AS xy
INSERT OVERWRITE TABLE dest PARTITION(file='11-21', type='A')
SELECT *;

SELECT diff, count(diff) cnt FROM dest WHERE file='11-21' AND type='A' GROUP BY diff SORT BY cnt DESC LIMIT 10;



-- 使用MR引擎
CREATE TABLE IF NOT EXISTS result(diff BIGINT,count BIGINT)
PARTITIONED BY (file STRING, type STRING)
STORED AS AVRO;

set hive.execution.engine=mr;
WITH x AS (SELECT * FROM src_xy WHERE file='11-txt' AND type='A'),
y AS (SELECT * FROM src_xy WHERE file='21-txt' AND type='A')
FROM
(SELECT x.val v1, y.val v2, (x.val - y.val) diff FROM x CROSS JOIN y) AS xy
INSERT OVERWRITE TABLE result PARTITION(file='11-21', type='A')
SELECT diff, count(diff) cnt GROUP BY diff ORDER BY cnt DESC;

SELECT * FROM result WHERE file='11-21' AND type='A' LIMIT 20;



select * from tbl_jion_res where station='广埠屯' limit 100;


```
