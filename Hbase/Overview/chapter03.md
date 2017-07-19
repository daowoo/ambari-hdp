# HBase简介
HBase是典型的NoSQL数据库，通过行健(Rowkey)检索数据，仅支持单行事务，主要用于存储非结构化和半结构化的松散数据。与Hadoop相同，依靠横向扩展，通过不断增加廉价的商用服务器来增加计算和存储能力。

## 特性
- 容量巨大
单表可以有百亿行、百万列，数据矩阵横向和纵向两个维度所支持的数据量级都非常具有弹性。

- 面向列
数据在表中是按某列存储的，在查询只需要少数几个字段的时候，能大大减少读取的数据量，比如一个字段的数据聚集存储，那就更容易为这种聚集存储设计更好的压缩和解压算法。
列式数据库的优势：
```
数据按列存储，即每一列单独存放
数据即索引
只访问查询涉及的列，可以大量降低系统I/O
每一列由一个线程来处理，即查询的并发处理性能高
数据类型一致，数据特征相似，可以高效压缩
```

- 稀疏性
为空的列并不占用存储空间，表可以设计得非常稀疏。

- 扩展性 
底层文件系统依赖于HDFS，同时在HBase核心架构层面也具备可扩展性。

- 高可靠性
提供WAL日志和Replication机制，来保证写入异常和节点故障时不会丢失数据。

- 高性能
底层的LSM数据结构和Rowkey有序排列等架构上的独特设计，使其具备非常高的写入性能。Region切分，主键索引和缓存机制使得在海量数据下具备一定的随机读取性能。

## 在Hadoop生态圈中的位置
![](/assets/a1.png)

## 核心模块
![](/assets/a2.jpg)

- **Client**
 - 使用HBase的RPC机制与HMaster和HRegionServer进行通信。
 - 对于管理类操作，Client与HMaster进行RPC。
 - 对于数据读写类操作，Client与HRegionServer进行RPC。


- **Zookeeper**
 - 通过选举，保证任何时候，集群中只有一个master，Master与RegionServer启动时均会向ZooKeeper注册。
 - 实时监控Regionserver的上线和下线信息,并实时通知给Master，使得HMaster可以随时感知到各个HRegionServer的健康状态。
 - 存贮所有Region的寻址入口和HBase的schema和table元数据。
 - Zookeeper的引入实现HMaster主从节点的failover，避免了HMaster的单点问题。
 

- **HMaster**
 - HBase中可以启动多个HMaster，通过Zookeeper的选主机制保证总有一个Master运行
 - 处理schema更新请求 (创建、删除、修改Table的定义）。
 - 管理HRegionServer的负载均衡，调整Region分布。
 - 管理和分配HRegion，比如在HRegion split时分配新的HRegion；在HRegionServer退出时迁移其内的HRegion到其他HRegionServer上。
 - 监控集群中所有HRegionServer的状态(通过Heartbeat和监听ZooKeeper中的状态)。
 

- **HRegionServer**
 - 维护Master分配给它的region，处理对这些region的IO请求。
 - 负责切分在运行过程中变得过大的region。
 
 
 - **结论**
  - client访问hbase上数据的过程并不需要master参与（寻址访问zookeeper，数据读写访问regione server），master仅仅维护者table和region的元数据信息，负载很低。
  - HRegion所处理的数据尽量和数据所在的DataNode在一起，实现数据的本地化。

## 工作过程
HRegionServer负责打开Region，并创建HRegion实例，HRegion会为每个表的HColumnFamily（用户创建表时定义的）创建一个Store实例。每个Store实例包含一个或多个StoreFile实例，StoreFile是实际数据存储文件HFile的轻量级封装，每个Store会对应一个MemStore。

 写入数据时数据会先写入Hlog中，成功后再写入MemStore中。Memstore中的数据因为空间有限，所以需要定期flush到文件StoreFile中，每次flush都是生成新的StoreFile。HRegionServer在处理Flush请求时，将数据写成HFile文件永久存储到HDFS上，并且存储最后写入的数据序列号。