#!/usr/bin/env bash

#create postgres meta database
sudo -u hive psql

CREATE DATABASE hive;
CREATE USER hive WITH PASSWORD '1';
GRANT ALL PRIVILEGES ON DATABASE hive TO hive;

\c hive
CREATE SCHEMA hive AUTHORIZATION hive;
ALTER SCHEMA hive OWNER TO hive;
ALTER ROLE hive SET search_path to 'hive', 'public';

psql -U hive -d hive

#create dir on hdfs
hdfs dfs -mkdir -p /user/hive/root
hdfs dfs -mkdir -p /user/hive/tmp
hdfs dfs -mkdir -p /user/hive/log
hdfs dfs -chown -R hadoop /user/hive
hdfs dfs -chmod -R u+w,g+w /user/hive


#install Hbase
wget -N -P /home/hadoop/ http://server.panhongfa.com/resource/apache-hive-2.2.0-bin.tar.gz
tar -zxf /home/hadoop/apache-hive-2.2.0-bin.tar.gz -C /home/hadoop/
mv /home/hadoop/apache-hive-2.2.0-bin /home/hadoop/hive-2.2.0

wget -N -P /home/hadoop/hive-2.2.0/lib http://server.panhongfa.com/resource/postgresql-42.1.4.jar

#config hive env
hive_var=$(sed -n '/^#HIVE_HOME$/'p /etc/profile)
if [ ! $hive_var ]; then
  echo "HIVE_HOME UNSET"
  cat << 'eof' >> /etc/profile
#HIVE_HOME
export HIVE_HOME=/home/hadoop/hive-2.2.0
export HIVE_CONF_DIR=/home/hadoop/hive-2.2.0/conf
export PATH=$HIVE_HOME/bin:$PATH
'eof'
source /etc/profile
else
  echo "HIVE_HOME EXIST"
fi

#config hive-env.sh
cp /home/hadoop/hive-2.2.0/conf/hive-env.sh.template /home/hadoop/hive-2.2.0/conf/hive-env.sh
sed -i -e '/^#.HADOOP_HOME=/s/^#//' -e '/HADOOP_HOME=.*/s@=.*@=/home/hadoop/hadoop-2.7.4@' /home/hadoop/hive-2.2.0/conf/hive-env.sh
sed -i -e '/^#.export HIVE_CONF_DIR=/s/^#//' -e '/export HIVE_CONF_DIR=.*/s@=.*@=/home/hadoop/hive-2.2.0/conf@' /home/hadoop/hive-2.2.0/conf/hive-env.sh

#config hive-site.xml
cp /home/hadoop/hive-2.2.0/conf/hive-default.xml.template /home/hadoop/hive-2.2.0/conf/hive-site.xml
sed -i 's/^-->/&\n/' /home/hadoop/hive-2.2.0/conf/hive-site.xml
sed -i '/<configuration>/,/^<\/configuration>/d' /home/hadoop/hive-2.2.0/conf/hive-site.xml

#metastore server configuration
cat << eof >> /home/hadoop/hive-2.2.0/conf/hive-site.xml
<configuration>
<property>
  <name>javax.jdo.option.ConnectionURL</name>
  <value>jdbc:postgresql://server.panhongfa.com:5432/hive?createDatabaseIfNotExist=true</value>
</property>

<property>
  <name>javax.jdo.option.ConnectionDriverName</name>
  <value>org.postgresql.Driver</value>
</property>

<property>
  <name>javax.jdo.option.ConnectionUserName</name>
  <value>hive</value>
</property>

<property>
  <name>javax.jdo.option.ConnectionPassword</name>
  <value>1</value>
</property>

<property>
 <name>hive.metastore.warehouse.dir</name>
 <value>/user/hive/root</value>
</property>

<property>
  <name>hive.exec.scratchdir</name>
  <value>/user/hive/tmp</value>
</property>

<property>
  <name>hive.querylog.location</name>
  <value>/user/hive/log</value>
</property>
</configuration>
eof


#hiveserver2 configuration
cat << eof >> /home/hadoop/hive-2.2.0/conf/hive-site.xml
<configuration>
<property>
  <name>hive.metastore.uris</name>
  <value>thrift://hbase2.panhongfa.com:9083</value>
</property>

<property>
 <name>hive.metastore.warehouse.dir</name>
 <value>/user/hive/root</value>
</property>

<property>
  <name>hive.exec.scratchdir</name>
  <value>/user/hive/tmp</value>
</property>

<property>
  <name>hive.querylog.location</name>
  <value>/user/hive/log</value>
</property>

<property>
  <name>hive.server2.enable.doAs</name>
  <value>false</value>
</property>
</configuration>
eof

#config hive-log4j2.properties
cp /home/hadoop/hive-2.2.0/conf/hive-log4j2.properties.template /home/hadoop/hive-2.2.0/conf/hive-log4j2.properties
mkdir -p /home/hadoop/hive-2.2.0/log
sed -i '/property.hive.log.dir =.*/s@=.*@=/home/hadoop/hive-2.2.0/log@' /home/hadoop/hive-2.2.0/conf/hive-log4j2.properties

#config hiveserver2 HA
sed -i '/^<\/configuration>/d' /home/hadoop/hive-2.2.0/conf/hive-site.xml
cat << eof >> /home/hadoop/hive-2.2.0/conf/hive-site.xml

<property>
  <name>hive.metastore.uris</name>
  <value>thrift://hbase2.panhongfa.com:9083</value>
</property>

<property>
  <name>hive.server2.support.dynamic.service.discovery</name>
  <value>true</value>
</property>

<property>
  <name>hive.server2.zookeeper.namespace</name>
  <value>hiveserver2_zk</value>
</property>

<property>
  <name>hive.zookeeper.quorum</name>
  <value>hbase1.panhongfa.com:2181,hbase2.panhongfa.com:2181,hbase3.panhongfa.com:2181</value>
</property>

<property>
  <name>hive.zookeeper.client.port</name>
  <value>2181</value>
</property>

<property>
  <name>hive.server2.thrift.bind.host</name>
  <value>0.0.0.0</value>
</property>

<property>
  <name>hive.server2.thrift.port</name>
  <value>10000</value>
</property>
</configuration>
eof

#chmod
sudo chown -R hadoop:hadoop /home/hadoop/hive-2.2.0
sudo chmod -R u+w,g+w /home/hadoop/hive-2.2.0
