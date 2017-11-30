beeline -u "jdbc:hive2://nn.daowoo.com:2181,snn.daowoo.com:2181,hive.daowoo.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -n "hive" -p "hive"

hive --hiveconf hbase.master=nn.daowoo.com:16000
beeline --hivevar a=123 --hivevar b=234 --hiveconf hbase.master=nn.daowoo.com:16000

beeline --hiveconf hbase.master=nn.daowoo.com:16000

beeline -u "jdbc:hive2://nn.daowoo.com:2181,snn.daowoo.com:2181,hive.daowoo.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2"

jdbc:hive2://nn.daowoo.com:2181,snn.daowoo.com:2181,hive.daowoo.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2
jdbc:hive2://hive.daowoo.com:10000

```sql
CREATE TABLE hbase_table_1(key int, value string)
STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
WITH SERDEPROPERTIES ("hbase.columns.mapping" = ":key,cf1:val")
TBLPROPERTIES ("hbase.table.name" = "xyz", "hbase.mapred.output.outputtable" = "xyz");

drop table hbase_table_1;

set hiveconf:hbase.master;


add jar /usr/hdp/2.6.1.0-129/hbase/lib/hbase-server.jar
/usr/hdp/2.6.1.0-129/hbase/lib/hbase-client.jar
/usr/hdp/2.6.1.0-129/hbase/lib/hbase-annotations.jar
/usr/hdp/2.6.1.0-129/hbase/lib/hbase-common.jar
/usr/hdp/2.6.1.0-129/hbase/lib/hbase-hadoop-compat.jar
/usr/hdp/2.6.1.0-129/hbase/lib/hbase-it.jar
/usr/hdp/2.6.1.0-129/hbase/lib/hbase-procedure.jar;



ln -s /usr/hdp/2.6.1.0-129/hbase/lib/phoenix-server.jar /usr/hdp/2.6.1.0-129/hive/auxlib/phoenix-server.jar

ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-server.jar /usr/hdp/2.6.1.0-129/hive/auxlib/hbase-server.jar
ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-client.jar /usr/hdp/2.6.1.0-129/hive/auxlib/hbase-client.jar
ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-annotations.jar /usr/hdp/2.6.1.0-129/hive/auxlib/hbase-annotations.jar
ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-common.jar /usr/hdp/2.6.1.0-129/hive/auxlib/hbase-common.jar
ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-hadoop-compat.jar /usr/hdp/2.6.1.0-129/hive/auxlib/hbase-hadoop-compat.jar
ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-it.jar /usr/hdp/2.6.1.0-129/hive/auxlib/hbase-it.jar
ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-procedure.jar /usr/hdp/2.6.1.0-129/hive/auxlib/hbase-procedure.jar


ln -s /usr/hdp/2.6.1.0-129/hbase/lib/phoenix-server.jar /usr/hdp/2.6.1.0-129/hive/lib/phoenix-server.jar

ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-server.jar /usr/hdp/2.6.1.0-129/hive/lib/hbase-server.jar
ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-client.jar /usr/hdp/2.6.1.0-129/hive/lib/hbase-client.jar
ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-annotations.jar /usr/hdp/2.6.1.0-129/hive/lib/hbase-annotations.jar
ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-common.jar /usr/hdp/2.6.1.0-129/hive/lib/hbase-common.jar
ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-hadoop-compat.jar /usr/hdp/2.6.1.0-129/hive/lib/hbase-hadoop-compat.jar
ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-it.jar /usr/hdp/2.6.1.0-129/hive/lib/hbase-it.jar
ln -s /usr/hdp/2.6.1.0-129/hbase/lib/hbase-procedure.jar /usr/hdp/2.6.1.0-129/hive/lib/hbase-procedure.jar


```
