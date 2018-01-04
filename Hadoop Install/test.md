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

## 1
```sh
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
```

## 2
```sh
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
```


```sql
ln -s /mnt/disk/apache-hive-2.3.2-bin /usr/local/share/hive

hive_var=$(sed -n '/^#HIVE_HOME$/'p /etc/profile)
if [ ! $hive_var ]; then
  echo "HIVE_HOME UNSET"
  cat << 'eof' >> /etc/profile
#HIVE_HOME
export HIVE_HOME=/usr/local/share/hive
export HIVE_CONF_DIR=$HIVE_HOME/conf
export PATH=$HIVE_HOME/bin:$PATH
eof
source /etc/profile
else
  echo "HIVE_HOME EXIST"
fi
```

```sh
cp /usr/local/share/hive/conf/hive-env.sh.template /usr/local/share/hive/conf/hive-env.sh

sed -i -e '/^#.HADOOP_HOME=/s/^#//' \
-e '/HADOOP_HOME=.*/s@=.*@=/mnt/disk/hadoop-2.7.3@' /usr/local/share/hive/conf/hive-env.sh

sed -i -e '/^#.export HIVE_CONF_DIR=/s/^#//' \
-e '/export HIVE_CONF_DIR=.*/s@=.*@=/usr/local/share/hive/conf@' /usr/local/share/hive/conf/hive-env.sh
```

```sh
cp /usr/local/share/hive/conf/hive-default.xml.template /usr/local/share/hive/conf/hive-site.xml

```

```sh
#config hive-log4j2.properties
cp /usr/local/share/hive/conf/hive-log4j2.properties.template /usr/local/share/hive/conf/hive-log4j2.properties

mkdir -p /mnt/disk/apache-hive-2.3.2-bin/log
sed -i '/property.hive.log.dir =.*/s@=.*@=/mnt/disk/apache-hive-2.3.2-bin/log@' /usr/local/share/hive/conf/hive-log4j2.properties
```

```sh
schematool -dbType derby -initSchema
schematool -dbType derby -info
```

```sh
hive --service hiveserver2 &
```
