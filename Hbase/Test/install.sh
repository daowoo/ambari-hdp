#!/bin/bash

curl -O http://192.168.36.118/resource/initenv.sh
chmod +x initenv.sh
./initenv.sh

curl -O http://192.168.36.118/resource/inithadoop.sh
chmod +x inithadoop.sh
./inithadoop.sh

curl -O http://192.168.36.118/resource/initzookeeper.sh
chmod +x initzookeeper.sh
./initzookeeper.sh

curl -O http://192.168.36.118/resource/inithbase.sh
chmod +x inithbase.sh
./inithbase.sh

#namenode format
su hadoop
hdfs namenode -format

#start hadoop
start-all.sh
mr-jobhistory-daemon.sh start historyserver

#check hadoop web
wget --timeout=5 --tries=1 http://192.168.36.217:50070 -O /dev/null
wget --timeout=5 --tries=1 http://192.168.36.217:8088 -O /dev/null
wget --timeout=5 --tries=1 http://192.168.36.217:19888 -O /dev/null

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
wget --timeout=5 --tries=1 http://192.168.36.217:16010 -O /dev/null

#check proessce
jps
