#!/usr/bin/env bash

#install ZooKeeper
wget -N -P /home/hadoop/ http://server.panhongfa.com/resource/zookeeper-3.4.10.tar.gz
tar -zxf /home/hadoop/zookeeper-3.4.10.tar.gz -C /home/hadoop/

#config zookeeper env
zk_var=$(sed -n '/^#ZOOKEEPER_HOME$/'p /etc/profile)
if [ ! $zk_var ]; then
  echo "ZOOKEEPER_HOME UNSET"
  cat << 'eof' >> /etc/profile
#ZOOKEEPER_HOME
export ZOOKEEPER_HOME=/home/hadoop/zookeeper-3.4.10
export PATH=$ZOOKEEPER_HOME/bin:$ZOOKEEPER_HOME/conf:$PATH
eof
source /etc/profile
else
  echo "ZOOKEEPER_HOME EXIST"
fi

#create myid
mkdir /home/hadoop/zookeeper-3.4.10/data
sh -c 'echo "1" > /home/hadoop/zookeeper-3.4.10/data/myid'

#update zoo.cfg
cp -f /home/hadoop/zookeeper-3.4.10/conf/zoo_sample.cfg /home/hadoop/zookeeper-3.4.10/conf/zoo.cfg
sed -i '/^dataDir=.*/s@=.*@=/home/hadoop/zookeeper-3.4.10/data@' /home/hadoop/zookeeper-3.4.10/conf/zoo.cfg

server_var=$(sed -n '/^#ServerList$/'p /home/hadoop/zookeeper-3.4.10/conf/zoo.cfg)
if [ ! $server_var ]; then
  echo "ServerList UNSET"
  cat << 'eof' >> /home/hadoop/zookeeper-3.4.10/conf/zoo.cfg
#ServerList
server.1=hbase1.panhongfa.com:2888:3888
server.2=hbase2.panhongfa.com:2888:3888
server.3=hbase3.panhongfa.com:2888:3888
#end
eof
else
  echo "ServerList EXIST"
fi

#chmod
sudo chown -R hadoop:hadoop /home/hadoop/zookeeper-3.4.10
sudo chmod -R 700 /home/hadoop/zookeeper-3.4.10
