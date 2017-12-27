
#namenode format
su hadoop
hdfs namenode -format

#start hadoop
start-all.sh
mr-jobhistory-daemon.sh start historyserver

#check hadoop web
wget --timeout=5 --tries=1 http://hbase1.panhongfa.com:50070 -O /dev/null
wget --timeout=5 --tries=1 http://hbase1.panhongfa.com:8088 -O /dev/null
wget --timeout=5 --tries=1 http://hbase1.panhongfa.com:19888 -O /dev/null

#check hadoop MR
echo "My first hadoop example. Hello Hadoop in input. " > input
hadoop fs -mkdir -p /user/panhongfa
hadoop fs -put input /user/panhongfa
hadoop jar hadoop-2.7.4/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.4.jar wordcount /user/panhongfa/input /user/panhongfa/output
hadoop fs -cat /user/panhongfa/output/part-r-00000


#start zk
zkServer.sh start
zkServer.sh status


#start hbase
start-hbase.sh

#check hbase web
wget --timeout=5 --tries=1 http://hbase1.panhongfa.com:16010 -O /dev/null

#check proessce
jps


#start metastore
schematool --dbType postgres --initSchema
hive --service metastore &
ss -tpnl |grep 9083

#start hiveserver2
hive --service hiveserver2 &

#client
beeline
!connect jdbc:hive2://hbase1.panhongfa.com:10000/default
!connect jdbc:hive2://hbase1.panhongfa.com:2181,hbase2.panhongfa.com:2181,hbase3.panhongfa.com:2181/default;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2_zk
