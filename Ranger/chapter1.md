# 安装

## 前置需求
  * Ranger默认将审核数据`audits`存储在Ambari Infra service组件提供的`Infra Solr`共享实例中，所以该组件必须被安装并且实例被成功启动。
  
  * 可以通过LDAP、ACTIVE_DIRECTORY、UNIX的方式来进行组和用户级别的授权，或者直接关闭授权。
  
  * Ranger需要使用一个数据库来存储必要的信息，支持MySQL，Oracle，PostgreSQL或Amazon RDS数据库。在安装过程中将创建rangeradmin和rangerlogger两个默认的新用户，以及创建ranger和ranger_audit两个默认的新数据库。

## 安装过程




