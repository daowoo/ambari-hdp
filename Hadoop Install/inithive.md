# 安装Hive集群
## 机器环境
| 主机名               | IP地址         | 作用           | 端口 |
| -------------------- | -------------- | -------------- | ---- |
| node1.bigdata.wh.com | 192.168.37.101 | hiveserver2    |      |
| node2.bigdata.wh.com | 192.168.37.102 | hiveserver2    |      |
| node3.bigdata.wh.com | 192.168.37.103 | metastore + pg |      |

## 创建DB
这里我们采用pg作为hive的外部元数据库，在节点node3上启动pg数据库实例。pg的安装过程见`Other\postgresql install.md`中的描述。
```sh
#create postgres meta database
sudo -u postgres psql

CREATE DATABASE hive;
CREATE USER hive WITH PASSWORD '1';
GRANT ALL PRIVILEGES ON DATABASE hive TO hive;

\c hive
CREATE SCHEMA hive AUTHORIZATION hive;
ALTER SCHEMA hive OWNER TO hive;
ALTER ROLE hive SET search_path to 'hive', 'public';
```

测试是否能采用hive角色登录数据库
```sh
psql -U hive -d hive
```

## 创建Hive目录
在hdfs文件系统上创建hive将要使用的各个目录
```sh
#create dir on hdfs
su hadoop

hdfs dfs -mkdir -p /user/hive/root
hdfs dfs -mkdir -p /user/hive/tmp
hdfs dfs -mkdir -p /user/hive/log
```

我们将以hadoop用户来启动hive各个服务，所以目录的权限需要作出对应的修改
```sh
hdfs dfs -chown -R hadoop /user/hive
hdfs dfs -chmod -R u+w,g+w /user/hive
```

## 安装Hive
```sh
tar -zxf /home/hadoop/apache-hive-2.3.2-bin.tar.gz -C /home/hadoop/
sudo ln -s /home/hadoop/apache-hive-2.3.2-bin/conf /etc/hive
```

## 拷贝JDBC
```sh
cp postgresql-42.1.4.jar apache-hive-2.3.2-bin/lib/
sudo chown hadoop:hadoop apache-hive-2.3.2-bin/lib/postgresql-42.1.4.jar
```

## Hive环境变量
```sql
hive_var=$(sed -n '/^#HIVE_HOME$/'p /etc/profile)
if [ ! $hive_var ]; then
  echo "HIVE_HOME UNSET"
  cat << 'eof' >> /etc/profile
#HIVE_HOME
export HIVE_HOME=/home/hadoop/apache-hive-2.3.2-bin
export HIVE_CONF_DIR=/home/hadoop/apache-hive-2.3.2-bin/conf
export PATH=$HIVE_HOME/bin:$PATH
eof
source /etc/profile
else
  echo "HIVE_HOME EXIST"
fi
```

## 配置hive-env.sh
```sh
cp /etc/hive/hive-env.sh.template /etc/hive/hive-env.sh
sed -i -e '/^#.HADOOP_HOME=/s/^#//' -e '/HADOOP_HOME=.*/s@=.*@=/home/hadoop/hadoop-2.7.5@' /etc/hive/hive-env.sh
sed -i -e '/^#.export HIVE_CONF_DIR=/s/^#//' -e '/export HIVE_CONF_DIR=.*/s@=.*@=/home/hadoop/apache-hive-2.3.2-bin/conf@' /etc/hive/hive-env.sh
```

## 配置hive-log4j2.properties
```sh
cp /etc/hive/hive-log4j2.properties.template /etc/hive/hive-log4j2.properties
mkdir -p /home/hadoop/apache-hive-2.3.2-bin/log
sed -i '/property.hive.log.dir =.*/s@=.*@=apache-hive-2.3.2-bin/log@' /etc/hive/hive-log4j2.properties
```

## 复制到其他节点
在node2、node3上重复上述配置过程，或者拷贝node1上的HIVE目录到节点上相同的目录，然后添加必要的符号链接和环境变量。
```sh
scp -r /home/hadoop/apache-hive-2.3.2-bin hadoop@node2.bigdata.wh.com:/home/hadoop/
scp -r /home/hadoop/apache-hive-2.3.2-bin hadoop@node3.bigdata.wh.com:/home/hadoop/

sudo ln -s /home/hadoop/apache-hive-2.3.2-bin/conf /etc/hive
```

## 配置metastore
### 从配置模板拷贝hive-site.xml，并删除其中的所有配置内容
```sh
cp /etc/hive/hive-default.xml.template /etc/hive/hive-site.xml
sed -i 's/^-->/&\n/' /etc/hive/hive-site.xml
sed -i '/<configuration>/,/^<\/configuration>/d' /etc/hive/hive-site.xml
```

### 添加metastore server配置
```sh
cat << eof >> /etc/hive/hive-site.xml
<configuration>
<property>
  <name>javax.jdo.option.ConnectionURL</name>
  <value>jdbc:postgresql://node3.bigdata.wh.com:5432/hive?createDatabaseIfNotExist=true</value>
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
```

## 配置hiveserver2
### 从配置模板拷贝hive-site.xml，并删除其中的所有配置内容
```sh
cp /etc/hive/hive-default.xml.template /etc/hive/hive-site.xml
sed -i 's/^-->/&\n/' /etc/hive/hive-site.xml
sed -i '/<configuration>/,/^<\/configuration>/d' /etc/hive/hive-site.xml
```

### 添加hiveserver2配置
```sh
cat << eof >> /etc/hive/hive-site.xml
<configuration>
<property>
  <name>hive.metastore.uris</name>
  <value>thrift://node3.bigdata.wh.com:9083</value>
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
```

### 结合zk添加hiveserver2的HA配置
首先删除最后一行的`<\/configuration>`
```sh
sed -i '/^<\/configuration>/d' /etc/hive/hive-site.xml
```

然后追加HA配置项
```sh
cat << eof >> /etc/hive/hive-site.xml

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
  <value>node1.bigdata.wh.com:2181,node2.bigdata.wh.com:2181,node3.bigdata.wh.com:2181</value>
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
```

## 确认Hive目录所属用户
```sh
sudo chown -R hadoop:hadoop /home/hadoop/apache-hive-2.3.2-bin
sudo chmod -R u+w,g+w /home/hadoop/apache-hive-2.3.2-bin
```

## 启动HIVE各服务
### 启动metastore
先初始化hive数据库实例
```sh
# 确认能找到schematool命令
source /etc/profile

[hadoop@node3 ~]$ schematool --dbType postgres --initSchema
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/home/hadoop/apache-hive-2.3.2-bin/lib/log4j-slf4j-impl-2.6.2.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/home/hadoop/hadoop-2.7.5/share/hadoop/common/lib/slf4j-log4j12-1.7.10.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.apache.logging.slf4j.Log4jLoggerFactory]
Metastore connection URL:	 jdbc:postgresql://node3.bigdata.wh.com:5432/hive?createDatabaseIfNotExist=true
Metastore Connection Driver :	 org.postgresql.Driver
Metastore connection User:	 hive
Starting metastore schema initialization to 2.3.0
Initialization script hive-schema-2.3.0.postgres.sql
Initialization script completed
schemaTool completed
```
注意，如果遇到提示log4j12包冲突，可以删除hive目录的lib中的log4j12包解决

启动metastore
```sh
hive --service metastore &
ss -tpnl |grep 9083
```

启动hiveserver2
```sh
hive --service hiveserver2 &
```

通过beeline连接hive
```sh
!connect jdbc:hive2://hbase1.panhongfa.com:10000/default
!connect jdbc:hive2://hbase1.panhongfa.com:2181,hbase2.panhongfa.com:2181,hbase3.panhongfa.com:2181/default;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2_zk
```
#client
beeline
!connect jdbc:hive2://node1.bigdata.wh.com:10000/default
!connect jdbc:hive2://node1.bigdata.wh.com:2181,node2.bigdata.wh.com:2181,node3.bigdata.wh.com:2181/default;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2_zk
