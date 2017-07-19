# SURGERY
## assign
手动分配一个region，如果region已分配，那么？

```
```

## unassign
手动取消一个region，通过true参数可强制取消

```
```

## balancer
手动触发负载均衡管理器，对集群负载进行调节。

```
hbase(main):004:0> balancer
true                                                                                                                                
0 row(s) in 0.0180 seconds
```

## balance_switch
打开/关闭负载均衡管理器，可选参数true/false。

```
hbase(main):030:0> balance_switch true
hbase(main):028:0> balance_switch false
```

## balancer_enabled
查看负载均衡管理器是否被启用。

```
hbase(main):006:0> balancer_enabled
false                                                                                                                               
0 row(s) in 0.0100 seconds
```

## close_region
关闭一个region，

```
```

## compact
手动触发合并指定的region，合并的类型是minor，可选参数设置合并类型： "NORMAL"或者"MOB"。

```
#表ns1:t1分布在任一regionserver上的region都进行minor合并
hbase(main):024:0> compact 'ns1:t1'
0 row(s) in 0.0360 seconds

#单个区域进行minor合并，区域的NAME从hbase:meta中获取
hbase(main):023:0> compact 'ns1:t1,,1500453071759.eac5fd48cc1fbbc4e385f3586628408c.'
0 row(s) in 0.0590 seconds

#单个区域中的某个列族进行minor合并
hbase(main):025:0> compact 'ns1:t1,,1500453071759.eac5fd48cc1fbbc4e385f3586628408c.', 'f1'
0 row(s) in 0.0210 seconds

#表ns1:t1分布在任一regionserver上的region的某个列族进行minor合并
hbase(main):026:0> compact 'ns1:t1', 'f1'
0 row(s) in 0.0340 seconds

#使用MOB类型进行合并
hbase(main):030:0> compact 'ns1:t1','f3','MOB'
ERROR: org.apache.hadoop.hbase.DoNotRetryIOException: Column family f3 is not a mob column family
```

## flush
flush指定region内memstore中的数据。

```
#flush表ns1:t1分布的所有区域
hbase(main):002:0> flush 'ns1:t1'
0 row(s) in 0.2900 seconds

#flush指定region_name的区域
hbase(main):003:0> flush 'ns1:t1,,1500453071759.eac5fd48cc1fbbc4e385f3586628408c.'
0 row(s) in 0.0870 seconds
```

## major_compact
手动将指定范围的region中的文件合并成一个文件，可选参数设置合并类型： "NORMAL"或者"MOB"。

```
#表ns1:t1分布在任一regionserver上的region都合并成一个文件
hbase(main):024:0> major_compact 'ns1:t1'
0 row(s) in 0.0360 seconds

#单个区域合并成一个文件，区域的ID从hbase:meta中获取
hbase(main):023:0> major_compact 'ns1:t1,,1500453071759.eac5fd48cc1fbbc4e385f3586628408c.'
0 row(s) in 0.0590 seconds

#单个区域中的某个列族合并成一个文件
hbase(main):025:0> major_compact 'ns1:t1,,1500453071759.eac5fd48cc1fbbc4e385f3586628408c.', 'f1'
0 row(s) in 0.0210 seconds

#表ns1:t1分布在任一regionserver上的region的某个列族合并成一个文件
hbase(main):026:0> major_compact 'ns1:t1', 'f1'
0 row(s) in 0.0340 seconds
```

## move
将指定的region移动到其他的regionserver上。
注意，其参数‘ENCODED_REGIONNAME’与‘REGIONNAME’不同，它是‘REGIONNAME’的末尾部分的哈希后缀；
参数‘SERVER_NAME’是主机名+端口号，再加起始码的拼接字符串。例如“host1.bigdata.wh.com,16020,1500427316025”

```
#将指定region编码的区域移动到指定的regionserver上。
hbase(main):014:0> move 'eac5fd48cc1fbbc4e385f3586628408c','host1.bigdata.wh.com,16020,1500427316025'
0 row(s) in 0.5410 seconds

#没有指定regionserver，将会随机选择一个作为目的地。
hbase(main):015:0> move 'eac5fd48cc1fbbc4e385f3586628408c'
0 row(s) in 1.0350 seconds

```

## split
触发分裂指定范围的的region，包括整个表格、指定region_name的区域等，若未达到分裂条件，就不变。

```
#分裂表所包含的所有region
hbase(main):007:0> split 'ns1:t1'
0 row(s) in 0.3310 seconds

#分裂指定region_id的区域
hbase(main):008:0> split 'ns1:t1,,1500453071759.eac5fd48cc1fbbc4e385f3586628408c.'
0 row(s) in 0.0270 seconds

#
split 'regionName' # format: 'tableName,startKey,id'
split 'tableName', 'splitKey'
split 'regionName', 'splitKey
```

## hlog_roll
Roll WAL日志记录器，也就是后续写请求写入新的WAL文件。

```
#该命令必须要附带一个regionserver的名称作为参数，名称一般是下面的格式
hbase(main):017:0> hlog_roll 'host3.bigdata.wh.com,16020,1500427314423'
0 row(s) in 0.0400 seconds
```

## zk_dump
查看zookeeper中保存的Hbase集群的dump信息，与Zookeeper ui中的信息相同。

```
hbase(main):018:0> zk_dump
HBase is rooted at /hbase-unsecure
Active master address: host2.bigdata.wh.com,16000,1500427332782
Backup master addresses:
Region server holding hbase:meta: host1.bigdata.wh.com,16020,1500427316025
Region servers:
 host3.bigdata.wh.com,16020,1500427314423
 host1.bigdata.wh.com,16020,1500427316025
 host2.bigdata.wh.com,16020,1500427319576
/hbase-unsecure/replication:
/hbase-unsecure/replication/peers:
/hbase-unsecure/replication/rs:
/hbase-unsecure/replication/rs/host2.bigdata.wh.com,16020,1500427319576:
/hbase-unsecure/replication/rs/host1.bigdata.wh.com,16020,1500427316025:
/hbase-unsecure/replication/rs/host3.bigdata.wh.com,16020,1500427314423:
Quorum Server Statistics:
 host1.bigdata.wh.com:2181
  Zookeeper version: 3.4.6-129--1, built on 05/31/2017 03:01 GMT
  Clients:
   /192.168.70.101:46380[1](queued=0,recved=2271,sent=2290)
   /192.168.70.103:42219[1](queued=0,recved=345,sent=351)
   /192.168.70.100:52082[1](queued=0,recved=161,sent=161)
   /192.168.70.100:52619[1](queued=0,recved=121,sent=121)
   /192.168.70.100:54039[0](queued=0,recved=1,sent=0)
   /192.168.70.103:42220[1](queued=0,recved=656,sent=663)
   /192.168.70.101:46386[1](queued=0,recved=2009,sent=2009)
   /192.168.70.102:35490[1](queued=0,recved=4254,sent=4540)

  Latency min/avg/max: 0/0/60
  Received: 15406
  Sent: 15748
  Connections: 8
  Outstanding: 0
  Zxid: 0xb000007db
  Mode: follower
  Node count: 124
 host2.bigdata.wh.com:2181
  Zookeeper version: 3.4.6-129--1, built on 05/31/2017 03:01 GMT
  Clients:
   /192.168.70.102:43517[1](queued=0,recved=716,sent=716)
   /192.168.70.102:57157[1](queued=0,recved=2006,sent=2006)
   /192.168.70.103:38906[1](queued=0,recved=2009,sent=2009)
   /192.168.70.102:57155[1](queued=0,recved=2015,sent=2015)
   /192.168.70.103:59538[1](queued=0,recved=135,sent=135)
   /192.168.70.100:39640[0](queued=0,recved=1,sent=0)

  Latency min/avg/max: 0/0/49
  Received: 16741
  Sent: 16805
  Connections: 6
  Outstanding: 0
  Zxid: 0xb000007db
  Mode: leader
  Node count: 124
 host3.bigdata.wh.com:2181
  Zookeeper version: 3.4.6-129--1, built on 05/31/2017 03:01 GMT
  Clients:
   /192.168.70.102:57568[1](queued=0,recved=2849,sent=2849)
   /192.168.70.102:57546[1](queued=0,recved=2009,sent=2009)
   /192.168.70.100:48907[0](queued=0,recved=1,sent=0)
   /192.168.70.101:42265[1](queued=0,recved=12062,sent=12062)
   /192.168.70.103:52922[1](queued=0,recved=2181,sent=2193)
   /192.168.70.102:57543[1](queued=0,recved=2343,sent=2360)
   /192.168.70.100:48904[1](queued=0,recved=16,sent=16)

  Latency min/avg/max: 0/1/944
  Received: 32181
  Sent: 32317
  Connections: 7
  Outstanding: 0
  Zxid: 0xb000007db
  Mode: follower
  Node count: 124
```
