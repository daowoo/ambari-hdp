#!/usr/bin/env bash

#install Hbase
wget -N -P /home/hadoop/ http://server.panhongfa.com/resource/hbase-2.0.0-alpha-1-bin.tar.gz
tar -zxf /home/hadoop/hbase-2.0.0-alpha-1-bin.tar.gz -C /home/hadoop/

#config hbase env
hbase_var=$(sed -n '/^#HBASE_HOME$/'p /etc/profile)
if [ ! $hbase_var ]; then
  echo "HBASE_HOME UNSET"
  cat << 'eof' >> /etc/profile
#HBASE_HOME
export HBASE_HOME=/home/hadoop/hbase-2.0.0-alpha-1
export PATH=$HBASE_HOME/bin:$HBASE_HOME/conf:$PATH
eof
source /etc/profile
else
  echo "HBASE_HOME EXIST"
fi

#config hbase-site.xml
sed -i '/^<configuration/,/^<\/configuration/d' /home/hadoop/hbase-2.0.0-alpha-1/conf/hbase-site.xml
cat << eof >> /home/hadoop/hbase-2.0.0-alpha-1/conf/hbase-site.xml
<configuration>
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://hbase1.panhongfa.com:9000/hbase</value>
  </property>
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
  <property>
    <name>hbase.master</name>
    <value>hdfs://hbase1.panhongfa.com:60000</value>
  </property>
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>hbase1.panhongfa.com,hbase2.panhongfa.com,hbase3.panhongfa.com</value>
  </property>
</configuration>
eof

#config regionservers
cat << eof > /home/hadoop/hbase-2.0.0-alpha-1/conf/regionservers
hbase2.panhongfa.com
hbase3.panhongfa.com
eof

#config hbase-env.sh
sed -i -e '/^#.export JAVA_HOME=/s/^#//' -e '/export JAVA_HOME=.*/s@=.*@=/home/hadoop/java/jdk1.8.0_112@' /home/hadoop/hbase-2.0.0-alpha-1/conf/hbase-env.sh
sed -i -e '/^#.export HBASE_MANAGES_ZK=/s/^#//' -e '/export HBASE_MANAGES_ZK=.*/s@=.*@=false@' /home/hadoop/hbase-2.0.0-alpha-1/conf/hbase-env.sh

#chmod
sudo chown -R hadoop:hadoop /home/hadoop/hbase-2.0.0-alpha-1
sudo chmod -R 700 /home/hadoop/hbase-2.0.0-alpha-1

#log4j conflicts
rm -f /home/hadoop/hbase-2.0.0-alpha-1/lib/slf4j-log4j12-1.7.10.jar
