# 安装ZK集群
## 机器环境
| 主机名               | IP地址         | 作用        | 端口 |
| -------------------- | -------------- | ----------- | ---- |
| node1.bigdata.wh.com | 192.168.37.101 | zk leader   |      |
| node2.bigdata.wh.com | 192.168.37.102 | zk follower |      |
| node3.bigdata.wh.com | 192.168.37.103 | zk follower |      |

## 安装ZK
```sh
tar -zxf /home/hadoop/zookeeper-3.4.11.tar.gz -C /home/hadoop/
sudo ln -s /home/hadoop/zookeeper-3.4.11/conf /etc/zookeeper
```

## ZK环境变量
```sql
zk_var=$(sed -n '/^#ZOOKEEPER_HOME$/'p /etc/profile)
if [ ! $zk_var ]; then
  echo "ZOOKEEPER_HOME UNSET"
  cat << 'eof' >> /etc/profile
#ZOOKEEPER_HOME
export ZOOKEEPER_HOME=/home/hadoop/zookeeper-3.4.11
export PATH=$ZOOKEEPER_HOME/bin:$ZOOKEEPER_HOME/conf:$PATH
eof
source /etc/profile
else
  echo "ZOOKEEPER_HOME EXIST"
fi
```

## 设置ID
```sh
mkdir /home/hadoop/zookeeper-3.4.11/data
sh -c 'echo "1" > /home/hadoop/zookeeper-3.4.11/data/myid'
```

## 配置zoo.cfg
```sh
cp -f /etc/zookeeper/zoo_sample.cfg /etc/zookeeper/zoo.cfg
sed -i '/^dataDir=.*/s@=.*@=/home/hadoop/zookeeper-3.4.11/data@' /etc/zookeeper/zoo.cfg
```

```sql
server_var=$(sed -n '/^#ServerList$/'p /etc/zookeeper/zoo.cfg)
if [ ! $server_var ]; then
  echo "ServerList UNSET"
  cat << 'eof' >> /etc/zookeeper/zoo.cfg
#ServerList
server.1=node1.bigdata.wh.com:2888:3888
server.2=node2.bigdata.wh.com:2888:3888
server.3=node3.bigdata.wh.com:2888:3888
#end
eof
else
  echo "ServerList EXIST"
fi
```

## 设置目录权限
```sh
sudo chown -R hadoop:hadoop /home/hadoop/zookeeper-3.4.11
sudo chmod -R u+w,g+w /home/hadoop/zookeeper-3.4.11
```

## 配置其他节点
在node2、node3上重复上述配置过程，或者拷贝node1上的ZOOKEEPER目录到节点上相同的目录，然后添加必要的符号链接和环境变量。
```sh
scp -r /home/hadoop/zookeeper-3.4.11 hadoop@node2.bigdata.wh.com:/home/hadoop/
scp -r /home/hadoop/zookeeper-3.4.11 hadoop@node3.bigdata.wh.com:/home/hadoop/

sudo ln -s /home/hadoop/zookeeper-3.4.11/etc/hadoop /etc/zookeeper
```

最后需要注意的是，node2和node3节点的data目录内的myid文件中的值必须根据实际情况进行自增。

## 启动ZK
```sh
zkServer.sh start
zkServer.sh status
```
