#!/usr/bin/env bash

#install HADOOP
mkdir -p /home/hadoop/tmp
mkdir -p /home/hadoop/dfs/name
mkdir -p /home/hadoop/dfs/data

wget -N -P /home/hadoop/ http://server.panhongfa.com/resource/hadoop-2.7.4.tar.gz
tar -zxf /home/hadoop/hadoop-2.7.4.tar.gz -C /home/hadoop/
ln -s /home/hadoop/hadoop-2.7.4/etc/hadoop /etc/hadoop

#config hadoop env
hadoop_var=$(sed -n '/^#HADOOP_HOME$/'p /etc/profile)
if [ ! $hadoop_var ]; then
  echo "HADOOP_HOME UNSET"
  cat << 'eof' >> /etc/profile
#HADOOP_HOME
export HADOOP_HOME=/home/hadoop/hadoop-2.7.4
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_YARN_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

export CLASSPATH=.:$HADOOP_HOME/lib:$CLASSPATH
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

eof
source /etc/profile
else
  echo "HADOOP_HOME EXIST"
fi

#config core-site.xml
sed -i '/^<configuration/,/^<\/configuration/d' /etc/hadoop/core-site.xml
cat << eof >> /etc/hadoop/core-site.xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://hbase1.panhongfa.com:9000</value>
    </property>
    <property>
        <name>io.file.buffer.size</name>
        <value>131072</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>file:/home/hadoop/tmp</value>
    </property>
</configuration>
eof

#config hdfs-site.xml
sed -i '/^<configuration/,/^<\/configuration/d' /etc/hadoop/hdfs-site.xml
cat << eof >> /etc/hadoop/hdfs-site.xml
<configuration>
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>hbase1.panhongfa.com:9001</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:/home/hadoop/dfs/name</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:/home/hadoop/dfs/data</value>
    </property>
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>
    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>
</configuration>
eof

#config mapred-site.xml
cp -f /etc/hadoop/mapred-site.xml.template /etc/hadoop/mapred-site.xml
sed -i '/^<configuration/,/^<\/configuration/d' /etc/hadoop/mapred-site.xml
cat << eof >> /etc/hadoop/mapred-site.xml
<configuration>
   <property>
      <name>mapreduce.framework.name</name>
      <value>yarn</value>
   </property>
   <property>
      <name>mapreduce.jobhistory.address</name>
      <value>hbase1.panhongfa.com:10020</value>
   </property>
   <property>
      <name>mapreduce.jobhistory.webapp.address</name>
      <value>hbase1.panhongfa.com:19888</value>
   </property>
</configuration>
eof

#config yarn-site.xml
sed -i '/^<configuration/,/^<\/configuration/d' /etc/hadoop/yarn-site.xml
cat << eof >> /etc/hadoop/yarn-site.xml
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
  </property>
  <property>
    <name>yarn.resourcemanager.address</name>
    <value>hbase1.panhongfa.com:8032</value>
  </property>
  <property>
    <name>yarn.resourcemanager.scheduler.address</name>
    <value>hbase1.panhongfa.com:8030</value>
  </property>
  <property>
    <name>yarn.resourcemanager.resource-tracker.address</name>
    <value>hbase1.panhongfa.com:8031</value>
  </property>
  <property>
    <name>yarn.resourcemanager.admin.address</name>
    <value>hbase1.panhongfa.com:8033</value>
  </property>
  <property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>hbase1.panhongfa.com:8088</value>
  </property>
    <property>
    <name>yarn.log-aggregation-enable</name>
    <value>true</value>
  </property>
</configuration>
eof

#config slave node
cat << eof > /etc/hadoop/slaves
hbase2.panhongfa.com
hbase3.panhongfa.com
eof

#config env.sh
sed -i '/${JAVA_HOME}/s@${JAVA_HOME}@/home/hadoop/java/jdk1.8.0_112@' /etc/hadoop/hadoop-env.sh
sed -i -e '/^#.export JAVA_HOME=/s/^#//' -e '/export JAVA_HOME=.*/s@=.*@=/home/hadoop/java/jdk1.8.0_112@' /etc/hadoop/yarn-env.sh

#chmod
sudo chown -R hadoop:hadoop /home/hadoop
sudo chmod -R u+w,g+w /home/hadoop/hadoop-2.7.4
