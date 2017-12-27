# Rollback NameNode HA
通过ambari页面提供的`namenode HA`模板可以为HDFS添加namenode的高可用方案，可以根据该模板提供的向导页面一步步完成配置。遗憾的是，当配置过程中出现错误后，ambari并没有提供可视化的redo方案，如果集群的元数据信息(ambari所使用的数据库)没有进行备份的话，整个集群就将无法使用。不过我们可以通过手动调用REST API来进行redo，以下是具体的步骤，参考文档 https://docs.hortonworks.com/HDPDocuments/Ambari-2.6.0.0/bk_ambari-operations/content/how_to_roll_back_namenode_ha.html


## 定义shell变量(可选)
```sh
export AMBARI_USER=admin
export AMBARI_PW=ambari
export AMBARI_PORT=8080
export CLUSTER_NAME=changsha
export NAMENODE_HOSTNAME=hdp.bigdata.wh.com
export ADDITIONAL_NAMENODE_HOSTNAME=host1.bigdata.wh.com
export SECONDARY_NAMENODE_HOSTNAME=host1.bigdata.wh.com
export JOURNALNODE1_HOSTNAME=host1.bigdata.wh.com
export JOURNALNODE2_HOSTNAME=host2.bigdata.wh.com
export JOURNALNODE3_HOSTNAME=host3.bigdata.wh.com
```

## Delete ZooKeeper Failover Controllers
在ambari server所在的节点执行以下查询
```sh
curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By: ambari" \
-i http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/host_components?HostRoles/component_name=ZKFC
```

查询的结果如不是空的`items`数组，则需要使用如下的命令删除`ZooKeeper (ZK) Failover Controllers`，直到上述查询结果为空为止
```sh
curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By: ambari" \
-i -X DELETE http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/hosts/$NAMENODE_HOSTNAME/host_components/ZKFC

curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By: ambari" \
-i -X DELETE http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/hosts/$ADDITIONAL_NAMENODE_HOSTNAME/host_components/ZKFC
```

## Modify HDFS Configurations
首先查询`hdfs-site`配置项，将与namenode HA相关的配置项全部删除，具体包含哪些配置项参考章节 https://docs.hortonworks.com/HDPDocuments/Ambari-2.6.0.0/bk_ambari-operations/content/modify_hdfs_configurations.html
```sh
/var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PW \
-port $AMBARI_PORT get localhost $CLUSTER_NAME hdfs-site
```

删除的命令如下，继续下一步之前确保列出的配置属性已被全部删除
```sh
/var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PW \
-port $AMBARI_PORT delete localhost changsha hdfs-site dfs.nameservices
```

然后查询`core-site`配置项，删除`ha.zookeeper.quorum`配置项,并且重置`fs.defaultFS`配置项
```sh
/var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PW \
-port $AMBARI_PORT get localhost changsha core-site

/var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PW \
-port $AMBARI_PORT delete localhost changsha core-site ha.zookeeper.quorum

/var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PW \
-port $AMBARI_PORT set localhost changsha core-site fs.defaultFS hdfs://hdp.bigdata.wh.com:8020
```

## Recreate the Standby NameNode
### check
```sh
curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By:ambari" -i \
-X GET http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/host_components?HostRoles/component_name=SECONDARY_NAMENODE
```

### recreate
```sh
curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By: ambari" -i \
-X POST -d '{"host_components" : [{"HostRoles":{"component_name":"SECONDARY_NAMENODE"}}] }' \
http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/hosts?Hosts/host_name=$SECONDARY_NAMENODE_HOSTNAME
```

## Re-enable the Standby NameNode
```sh
curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By: ambari" -i \
-X PUT -d '{"RequestInfo":{"context":"Enable Secondary NameNode"},"Body":{"HostRoles":{"state":"INSTALLED"}}}'\ http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/hosts/$SECONDARY_NAMENODE_HOSTNAME/host_components/SECONDARY_NAMENODE
```

## Delete All JournalNodes
### check
```sh
curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By:ambari" -i \
-X GET http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/host_components?HostRoles/component_name=JOURNALNODE
```

### delete
```sh
curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By: ambari" -i \
-X DELETE http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/hosts/host1.bigdata.wh.com/host_components/JOURNALNODE

curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By: ambari" -i \
-X DELETE http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/hosts/host2.bigdata.wh.com/host_components/JOURNALNODE

curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By: ambari" -i \
-X DELETE http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/hosts/host3.bigdata.wh.com/host_components/JOURNALNODE
```

## Delete the Additional NameNode
### check
```sh
curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By: ambari" -i \
-X GET http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/host_components?HostRoles/component_name=NAMENODE
```

### delete
```sh
curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By: ambari" -i \
-X DELETE http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/hosts/host1.bigdata.wh.com/host_components/NAMENODE

curl -u $AMBARI_USER:$AMBARI_PW -H "X-Requested-By: ambari" -i \
-X DELETE http://localhost:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/hosts/host2.bigdata.wh.com/host_components/NAMENODE
```
