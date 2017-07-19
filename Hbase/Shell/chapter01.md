# General
## status

输出集群当前的状态。

```
  hbase(main):032:0> status
  1 active master, 0 backup masters, 3 servers, 0 dead, 3.6667 average load

  hbase(main):001:0> help 'status'
  Show cluster status. Can be 'summary', 'simple', 'detailed', or 'replication'. The
  default is 'summary'. Examples:

    hbase> status
    hbase> status 'simple'        #以简明形式返回
    hbase> status 'summary'       #以摘要形式返回 （默认）
    hbase> status 'detailed'      #以详细形式返回
    hbase> status 'replication'   #输出主从Hbase集群之间的副本状态
    hbase> status 'replication', 'source' 
    hbase> status 'replication', 'sink'
```

## version

输出Hbase的当前版本。

```
  hbase(main):033:0> version
  1.1.2.2.6.1.0-129, r718c773662346de98a8ce6fd3b5f64e279cb87d4, Wed May 31 03:27:31 UTC 2017
```

## whoami

输出当前的Hbase用户和用户组。

```
  hbase(main):037:0> whoami
  root (auth:SIMPLE)
    groups: root
```