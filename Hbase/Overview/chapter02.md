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

- 客户端Client
整个HBase系统的入口，使用者直接通过Client操作HBase。
对于管理类操作，Client与HMaster进行RPC通信；
对于数据读写类操作，Client与RegionServer进行RPC交互。

- 协调服务组件Zookeeper
存储HBase元数据信息、实时监控RegionServer、存储所有Region的寻址入口，还有保证HBase集群中只有一个HMaster节点。

- 主节点HMaster
可以启动多个HMaster,通过ZooKeeper的Master选举机制保证总有一个Master正常运行并提供服务，其他的HMaster作为备选时刻准备，当目前的HMaster出现问题时提供服务。
HMaster主要负责的管理工作：
```
管理用户对Table的增、删、改、查操作
管理RegionServer的负载均衡，调整Region分布
在Region分裂后，负责新Region的分配
在RegionServer死机后，负责失效RegionServer上的Region迁移
HMaster失效仅会导致所有元数据无法修改，表的数据读写还是可以正常运行
```

- Region节点HRegionServer
其内部管理了一系列HRegion对象，每个HRegion对应了Table中的一个Region，region是hbase中分布式存储和负载均衡的最小单元，不同的regioon分布到不同的regionserver上。

 HRegion由多个HStore组成，每个HStore对应了Table中的一个HColumnFamily(列簇，用户创建表时定义的）。每个Column Family其实就是一个集中的存储单元,它包含若干个物理存储上的HFile，因此将具备共同I/O特性的列放在一个Column Family中，保证读写的高效率。
```
RegionServer维护region，处理这些region的IO请求
RegionServer负责切分在运行过程中变得过大的region
client访问HBase上数据的过程并不需要HMaster参与，寻址访问先ZooKeeper再Regionserver，数据读写访问Regioneserver
主要负责响应用户I/O请求，向HDFS文件系统中读写数据
```

- 工作过程
HRegionServer负责打开Region，并创建HRegion实例，HRegion会为每个表的HColumnFamily（用户创建表时定义的）创建一个Store实例。每个Store实例包含一个或多个StoreFile实例，StoreFile是实际数据存储文件HFile的轻量级封装，每个Store会对应一个MemStore。

 写入数据时数据会先写入Hlog中，成功后再写入MemStore中。Memstore中的数据因为空间有限，所以需要定期flush到文件StoreFile中，每次flush都是生成新的StoreFile。HRegionServer在处理Flush请求时，将数据写成HFile文件永久存储到HDFS上，并且存储最后写入的数据序列号。