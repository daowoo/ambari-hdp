# 安装HADOOP集群
## 机器环境
| 主机名               | IP地址         | 作用                                                | 端口 |
| -------------------- | -------------- | --------------------------------------------------- | ---- |
| node1.bigdata.wh.com | 192.168.37.101 | namenode,second namenode,jobhistory,resourcemanager |      |
| node2.bigdata.wh.com | 192.168.37.102 | datanode,nodemanager                                |      |
| node3.bigdata.wh.com | 192.168.37.103 | datanode,nodemanager                                |      |

## 配置HOSTS文件
```sh
vi /etc/hosts

192.168.37.101 node1.bigdata.wh.com
192.168.37.102 node2.bigdata.wh.com
192.168.37.103 node3.bigdata.wh.com
```

## 新增用户和组
```sh
#add user and group
groupadd hadoop
useradd -d /home/hadoop -g hadoop hadoop
passwd hadoop
```

## 用户添加sudo权限
```sh
chmod u+w /etc/sudoers
[[ `sudo grep 'hadoop*' /etc/sudoers` ]] || \
sudo sed -i -e '/^root.*ALL/a\hadoop ALL=(ALL)      ALL' /etc/sudoers
```

## hadoop用户免密登录
```sh
#Master配置SSH免密登录
su - hadoop
ssh-keygen -t rsa -P ''
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

ssh-copy-id -i ~/.ssh/id_rsa.pub hadoop@node1.bigdata.wh.com
ssh-copy-id -i ~/.ssh/id_rsa.pub hadoop@node2.bigdata.wh.com
ssh-copy-id -i ~/.ssh/id_rsa.pub hadoop@node3.bigdata.wh.com

ssh hadoop@node2.bigdata.wh.com
```

## 安装JDK
```sh
#install JDK8
wget -N -P /home/hadoop/ http://192.168.70.200/resource/jdk-8u112-linux-x64.tar.gz
mkdir /home/hadoop/java
tar -zxf /home/hadoop/jdk-8u112-linux-x64.tar.gz -C /home/hadoop/java/
```

## 设置JAVA_HOME
```sql
java_var=$(sed -n '/^#JAVA_HOME$/'p /etc/profile)
if [ ! $java_var ]; then
  echo "JAVA_HOME UNSET"
cat << 'eof' >> /etc/profile
#JAVA_HOME
export JAVA_HOME=/home/hadoop/java/jdk1.8.0_112
export JRE_HOME=$JAVA_HOME/jre

export CLASSPATH=.:$JAVA_HOME/lib:$CLASSPATH
export PATH=$JAVA_HOME/bin:$PATH

eof
source /etc/profile
else
  echo "JAVA_HOME EXIST"
fi
```

## 安装HADOOP
```sh
su hadoop

mkdir -p /home/hadoop/tmp
mkdir -p /home/hadoop/dfs/name
mkdir -p /home/hadoop/dfs/data

tar -zxf /home/hadoop/hadoop-2.7.5.tar.gz -C /home/hadoop/
sudo ln -s /home/hadoop/hadoop-2.7.5/etc/hadoop /etc/hadoop
```

## HADOOP环境变量
```sql
hadoop_var=$(sed -n '/^#HADOOP_HOME$/'p /etc/profile)
if [ ! $hadoop_var ]; then
  echo "HADOOP_HOME UNSET"
cat << 'eof' >> /etc/profile
#HADOOP_HOME
export HADOOP_HOME=/home/hadoop/hadoop-2.7.5
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
```

## 修改core-site.xml
```sh
sed -i '/^<configuration/,/^<\/configuration/d' /etc/hadoop/core-site.xml
cat << eof >> /etc/hadoop/core-site.xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://node1.bigdata.wh.com:9000</value>
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
```

## 修改hdfs-site.xml
```sh
sed -i '/^<configuration/,/^<\/configuration/d' /etc/hadoop/hdfs-site.xml
cat << eof >> /etc/hadoop/hdfs-site.xml
<configuration>
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>node1.bigdata.wh.com:9001</value>
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
```

## 修改mapred-site.xml
```sh
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
      <value>node1.bigdata.wh.com:10020</value>
   </property>
   <property>
      <name>mapreduce.jobhistory.webapp.address</name>
      <value>node1.bigdata.wh.com:19888</value>
   </property>
</configuration>
eof
```

## 修改yarn-site.xml
```sh
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
    <value>node1.bigdata.wh.com:8032</value>
  </property>
  <property>
    <name>yarn.resourcemanager.scheduler.address</name>
    <value>node1.bigdata.wh.com:8030</value>
  </property>
  <property>
    <name>yarn.resourcemanager.resource-tracker.address</name>
    <value>node1.bigdata.wh.com:8031</value>
  </property>
  <property>
    <name>yarn.resourcemanager.admin.address</name>
    <value>node1.bigdata.wh.com:8033</value>
  </property>
  <property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>node1.bigdata.wh.com:8088</value>
  </property>
    <property>
    <name>yarn.log-aggregation-enable</name>
    <value>true</value>
  </property>
</configuration>
eof
```

## 配置从节点
```sh
cat << eof > /etc/hadoop/slaves
node2.bigdata.wh.com
node3.bigdata.wh.com
eof
```

## 配置env脚本
```sh
sed -i '/${JAVA_HOME}/s@${JAVA_HOME}@/home/hadoop/java/jdk1.8.0_112@' /etc/hadoop/hadoop-env.sh
sed -i -e '/^#.export JAVA_HOME=/s/^#//' -e '/export JAVA_HOME=.*/s@=.*@=/home/hadoop/java/jdk1.8.0_112@' /etc/hadoop/yarn-env.sh
```

## 设置目录权限
```sh
sudo chown -R hadoop:hadoop /home/hadoop/hadoop-2.7.5
sudo chmod -R u+w,g+w /home/hadoop/hadoop-2.7.5
```

## 配置其他节点
在node2、node3上重复上述配置过程，或者拷贝node1上的HADOOP目录到节点上相同的目录，然后添加必要的符号链接和环境变量。
```sh
scp -r /home/hadoop/hadoop-2.7.5 hadoop@node2.bigdata.wh.com:/home/hadoop/
scp -r /home/hadoop/hadoop-2.7.5 hadoop@node3.bigdata.wh.com:/home/hadoop/

sudo ln -s /home/hadoop/hadoop-2.7.5/etc/hadoop /etc/hadoop
```

## 格式化namenode
```sh
su hadoop
hdfs namenode -format
```

## 启动HADOOP
```sh
#start hadoop
start-all.sh
mr-jobhistory-daemon.sh start historyserver

#check hadoop web
wget --timeout=5 --tries=1 http://node1.bigdata.wh.com:50070 -O /dev/null
wget --timeout=5 --tries=1 http://node1.bigdata.wh.com:8088 -O /dev/null
wget --timeout=5 --tries=1 http://node1.bigdata.wh.com:19888 -O /dev/null

#check hadoop MR
echo "My first hadoop example. Hello Hadoop in input. " > input
hadoop fs -mkdir -p /user/panhongfa
hadoop fs -put input /user/panhongfa
hadoop jar hadoop-2.7.5/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.5.jar wordcount /user/panhongfa/input /user/panhongfa/output
hadoop fs -cat /user/panhongfa/output/part-r-00000
```
