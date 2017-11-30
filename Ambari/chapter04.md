# Rollback NameNode HA
export AMBARI_USER=admin
export AMBARI_PW=admin
export AMBARI_PORT=8080
export AMBARI_PROTO=http
export CLUSTER_NAME=changsha
export NAMENODE_HOSTNAME=hdp.bigdata.wh.com
export ADDITIONAL_NAMENODE_HOSTNAME=host1.bigdata.wh.com
export SECONDARY_NAMENODE_HOSTNAME=host1.bigdata.wh.com
export JOURNALNODE1_HOSTNAME=host1.bigdata.wh.com
export JOURNALNODE2_HOSTNAME=host2.bigdata.wh.com
export JOURNALNODE3_HOSTNAME=host3.bigdata.wh.com

# Delete ZooKeeper Failover Controllers
curl -u admin:admin -H "X-Requested-By: ambari" -i http://192.168.70.100:8080/api/v1/clusters/ changsha/host_components?HostRoles/component_name=ZKFC

curl -u admin:admin -H "X-Requested-By: ambari" -i -X DELETE http://localhost:8080/api/v1/clusters/changsha/hosts/hdp.bigdata.wh.com/host_components/ZKFC curl -u admin:admin -H "X-Requested-By: ambari" -i -X DELETE http://localhost:8080/api/v1/clusters/changsha/hosts/host1.bigdata.wh.com/host_components/ZKFC

curl -u admin:admin -H "X-Requested-By: ambari" -i -X DELETE http://localhost:8080/api/v1/clusters/changsha/hosts/hdp.bigdata.wh.com/host_components/ZKFC curl -u admin:admin -H "X-Requested-By: ambari" -i -X DELETE http://localhost:8080/api/v1/clusters/changsha/hosts/host2.bigdata.wh.com/host_components/ZKFC

# Modify HDFS Configurations
/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p admin -port 8080 get localhost changsha hdfs-site
/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p admin -port 8080 delete localhost changsha hdfs-site dfs.nameservices

/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p admin -port 8080 get localhost changsha core-site
/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p admin -port 8080 delete localhost changsha core-site ha.zookeeper.quorum
/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p admin -port 8080 set localhost changsha core-site fs.defaultFS hdfs://hdp.bigdata.wh.com:8020

# Recreate the Standby NameNode
## check
curl -u admin:admin -H "X-Requested-By:ambari" -i -X GET http://localhost:8080/api/v1/clusters/changsha/host_components?HostRoles/component_name=SECONDARY_NAMENODE

## recreate
curl -u admin:admin -H "X-Requested-By: ambari" -i -X POST -d '{"host_components" : [{"HostRoles":{"component_name":"SECONDARY_NAMENODE"}}] }' http://localhost:8080/api/v1/clusters/changsha/hosts?Hosts/host_name=host1.bigdata.wh.com

## Re-enable the Standby NameNode
curl -u admin:admin -H "X-Requested-By: ambari" -i -X PUT -d '{"RequestInfo":{"context":"Enable Secondary NameNode"},"Body":{"HostRoles":{"state":"INSTALLED"}}}' http://localhost:8080/api/v1/clusters/changsha/hosts/host1.bigdata.wh.com/host_components/SECONDARY_NAMENODE

# Delete All JournalNodes
## check
curl -u admin:admin -H "X-Requested-By:ambari" -i -X GET http://localhost:8080/api/v1/clusters/changsha/host_components?HostRoles/component_name=JOURNALNODE

## delete
curl -u admin:admin -H "X-Requested-By: ambari" -i -X DELETE http://localhost:8080/api/v1/clusters/changsha/hosts/host1.bigdata.wh.com/host_components/JOURNALNODE
curl -u admin:admin -H "X-Requested-By: ambari" -i -X DELETE http://localhost:8080/api/v1/clusters/changsha/hosts/host2.bigdata.wh.com/host_components/JOURNALNODE
curl -u admin:admin -H "X-Requested-By: ambari" -i -X DELETE http://localhost:8080/api/v1/clusters/changsha/hosts/host3.bigdata.wh.com/host_components/JOURNALNODE

# Delete the Additional NameNode
## check
curl -u admin:admin -H "X-Requested-By: ambari" -i -X GET http://localhost:8080/api/v1/clusters/changsha/host_components?HostRoles/component_name=NAMENODE

## delete
curl -u admin:admin -H "X-Requested-By: ambari" -i -X DELETE http://localhost:8080/api/v1/clusters/changsha/hosts/host1.bigdata.wh.com/host_components/NAMENODE
curl -u admin:admin -H "X-Requested-By: ambari" -i -X DELETE http://localhost:8080/api/v1/clusters/changsha/hosts/host2.bigdata.wh.com/host_components/NAMENODE
