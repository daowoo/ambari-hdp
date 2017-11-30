# 数据流测试
## 测试机器地址
```
ip:192.168.10.60
user:root
psw:111111
sot:ambari server

ip:192.168.10.55
user:root
psw:111111
sot:hadoop node

ip:192.168.10.59
user:root
psw:111111
sot:hadoop node
```

## HIVE配置
数据在HDFS上的目录
```shell
# 数据根目录
/topics/test_hdfs_4/

# 分区目录
partition=0

# 每个分区下若干avro数据文件
test_hdfs_4+0+0000000000+0000000002.avro

# schema文件所在的本地目录
/root/tools/schema.avsc

# schema文件在hdfs中的url
hdfs://ambari.bigdata.daowoo.com:8020/tmp/schema.avsc #绝对路径
/tmp/schema.avsc  #相对路径
```

hive client登录
```shell
su hdfs

# 利用beeline连接hiveserver2
beeline -u "jdbc:hive2://node2.bigdata.daowoo.com:2181,node1.bigdata.daowoo.com:2181,ambari.bigdata.daowoo.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -n "hdfs" -p "hdfs"
```

## 创建hive表，载入avro文件数据
创建database并切换到test数据库
```sql
CREATE DATABASE test;
USE test;
```

根据schema来定义表的各个字段名和类型，不指定分区
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS test1(STSN string, YWSN string, YWWT string, YWVALUE int, YWTIME string,
  WDSN string, WDWT string, WDVALUE int, WDTIME string,
  YLSN string, YLWT string, YLVALUE int, YLTIME string,
  LLSN string, LLWT string, LLVALUE int, LLDIRECT int, LLTIME string)
COMMENT 'ZHANG WEN PING TEST DATA'
STORED AS AVRO
LOCATION '/topics/test_hdfs_4/partition=0';

SELECT * FROM test1 LIMIT 100;
```

直接利用schema文件来定义表的各个字段，也不指定分区
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS test2
COMMENT 'ZHANG WEN PING TEST DATA'
STORED AS AVRO
LOCATION '/topics/test_hdfs_4/partition=0'
TBLPROPERTIES('avro.schema.url'='/tmp/schema.avsc');

SELECT * FROM test2 LIMIT 100;
```

建立带分区的表，利用ALTER关键字后续添加分区
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS test3
COMMENT 'ZHANG WEN PING TEST DATA'
PARTITIONED BY (ptn int)
STORED AS AVRO
TBLPROPERTIES('avro.schema.url'='/tmp/schema.avsc');

ALTER TABLE test3 ADD PARTITION (ptn=0)
LOCATION '/topics/test_hdfs_4/ptn=0';

SELECT * FROM test3 LIMIT 100;
```

根据表中字段名取值而进行分区的数据载入，表进行分区
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS test4
COMMENT 'ZHANG WEN PING TEST DATA'
PARTITIONED BY (STSN string)
STORED AS AVRO
TBLPROPERTIES('avro.schema.url'='/tmp/schema.avsc');

ALTER TABLE test4 ADD PARTITION (STSN='CXSNXXXXXX0000000000000000000000000000000000000001')
LOCATION '/topics/test_hdfs_5/STSN=CXSNXXXXXX0000000000000000000000000000000000000001';

SELECT * FROM test4 LIMIT 100;
```

根据表中字段名取值而进行分区的数据载入，表指定LOCATION，不分区，验证schema还是否有效
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS test5
COMMENT 'ZHANG WEN PING TEST DATA'
STORED AS AVRO
LOCATION '/topics/test_hdfs_5/STSN=CXSNXXXXXX0000000000000000000000000000000000000001'
TBLPROPERTIES('avro.schema.url'='/tmp/schema.avsc');

SELECT * FROM test5 LIMIT 100;
```


```sql
CREATE EXTERNAL TABLE IF NOT EXISTS test6
COMMENT 'ZHANG WEN PING TEST DATA'
PARTITIONED BY (id string)
STORED AS AVRO
LOCATION '/topics/test_hdfs_5'
TBLPROPERTIES('avro.schema.url'='/tmp/schema.avsc');

ALTER TABLE test6 ADD PARTITION (id='CXSNXXXXXX0000000000000000000000000000000000000001')
LOCATION '/topics/test_hdfs_5/STSN=CXSNXXXXXX0000000000000000000000000000000000000001';

SELECT id FROM test6 LIMIT 100;
```

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS test7
COMMENT 'ZHANG WEN PING TEST DATA'
PARTITIONED BY (year string,month string,day string,hour string)
STORED AS AVRO
LOCATION '/topics/test_hdfs_6'
TBLPROPERTIES('avro.schema.url'='/tmp/schema.avsc');

ALTER TABLE test7 ADD
PARTITION (year='2017',month='11',day='01',hour='16') LOCATION '/topics/test_hdfs_6/year=2017/month=11/day=01/hour=16'
PARTITION (year='2017',month='11',day='01',hour='17') LOCATION '/topics/test_hdfs_6/year=2017/month=11/day=01/hour=17'
PARTITION (year='2017',month='11',day='01',hour='18') LOCATION '/topics/test_hdfs_6/year=2017/month=11/day=01/hour=18';

ALTER TABLE test7 DROP PARTITION (year='2017',month='11',day='01',hour='16') IGNORE PROTECTION;

SHOW PARTITIONS test7;
SELECT * FROM test7 LIMIT 100;
```


beeline -u "jdbc:hive2://nn.daowoo.com:2181,snn.daowoo.com:2181,hive.daowoo.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -n "hive" -p "1"
beeline -u "jdbc:hive2://nn.daowoo.com:2181,snn.daowoo.com:2181,hive.daowoo.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -n "panhongfa" -p "1"

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS tbl_car(ts string,car_no string,station string)
PARTITIONED BY (data string)
ROW FORMAT
DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/group/bigdata/generatedata/car';

ALTER TABLE tbl_car ADD
PARTITION (data='2017-11-10') LOCATION '/group/bigdata/generatedata/car/car-2017-11-10.csv'
PARTITION (data='2017-11-11') LOCATION '/group/bigdata/generatedata/car/car-2017-11-11.csv'
PARTITION (data='2017-11-12') LOCATION '/group/bigdata/generatedata/car/car-2017-11-12.csv';

SELECT *, to_date(ts) day, hour(ts) hour FROM tbl_car WHERE ts LIKE '2017-11-%' LIMIT 10;

USE storage;

-- 创建车辆数据中间表
CREATE TABLE IF NOT EXISTS tbl_car_tmp(ts string,car_no string,hour int)
PARTITIONED BY (day string, station string)
STORED AS ORC;


-- 依照Select结果自动进行分区,注意以日期和站点分区时它们值需按照顺序放在select语句末尾
FROM tbl_car
INSERT OVERWRITE TABLE tbl_car_tmp PARTITION(day, station)
SELECT ts, car_no, hour(ts) hour, to_date(ts) day, station
WHERE ts LIKE '2017-%'
SORT BY ts;

-- 验证分区是否正常
SELECT day, station, count(hour) cc FROM tbl_car_tmp GROUP BY day,station;


-- 创建电话数据中间表
CREATE TABLE IF NOT EXISTS tbl_tel_tmp(ts string,IMSI string,hour int)
PARTITIONED BY (day string, station string)
STORED AS ORC;

-- 依照Select结果自动进行分区,以日期和站点来自动分区
FROM tbl_tel
INSERT OVERWRITE TABLE tbl_tel_tmp PARTITION(day, station)
SELECT ts, IMSI, hour(ts) hour, to_date(ts) day, station
WHERE ts LIKE '2017-%'
SORT BY ts;

-- 验证分区是否正常
SELECT day, count(1) FROM tbl_tel_tmp GROUP BY day;

drop table tbl_tel_tmp;
drop table tbl_car_tmp;

CREATE TABLE tbl_result AS
SELECT a.day,a.station,a.hour,a.ts ts1,b.ts ts2,abs((unix_timestamp(a.ts)-unix_timestamp(b.ts))) diff,a.car_no,b.IMSI
FROM tbl_car_tmp AS a CROSS JOIN tbl_tel_tmp AS b
ON (a.day='2017-11-10' AND a.station='中南路' AND a.hour=1 AND a.day=b.day AND a.station=b.station AND a.hour=b.hour);

SELECT *
FROM tbl_car_tmp AS a CROSS JOIN tbl_tel_tmp AS b
ON (a.day='2017-11-10' a.station='中南路' AND a.day=b.day AND a.station=b.station AND a.hour=b.hour);

CREATE TABLE IF NOT EXISTS tbl_jion_res(hour int,ts1 string,ts2 string,diff int,car_no string,IMSI string)
PARTITIONED BY (day string, station string)
STORED AS ORC;

FROM (
  SELECT a.day,a.station,a.hour,a.ts ts1,b.ts ts2,abs((unix_timestamp(a.ts)-unix_timestamp(b.ts))) diff,a.car_no,b.IMSI
  FROM tbl_car_tmp AS a CROSS JOIN tbl_tel_tmp AS b
  ON (a.day='2017-11-10' AND a.station='中南路' AND a.day=b.day AND a.station=b.station AND a.hour=b.hour)
) AS ab
INSERT OVERWRITE TABLE tbl_jion_res PARTITION(day='2017-11-10', station='中南路')
SELECT ab.hour,ab.ts1,ab.ts2,floor(ab.diff) diff,ab.car_no,ab.IMSI;

SELECT count(1) FROM tbl_jion_res WHERE diff < 5*60 GROUP BY car_no, IMSI;

```
