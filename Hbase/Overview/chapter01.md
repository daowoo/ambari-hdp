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

## 数据模型
表是HBase表达数据的逻辑组织方式，而基于列的存储则是数据在底层的组织方式。
![](/assets/a3.png)

### Namespace
对一组表的逻辑分组，同一组中的表有相似的用途，类似RDBMS中的database，方便对表在业务需求上有一定的划分。

命名空间的概念为即将到来的多租户特性打下基础。其作用包括：
- **配额管理**，限制一个namespace可以使用的资源，资源包括region和table等。
- **命名空间安全管理**，提供了另一个层面的多租户安全管理。
- **Region服务器组**，一个命名空间或一张表，可以被固定到在、一组RegionServers上，从而保证了数据隔离性。

* 系统默认
Hbase系统默认定义了两个缺省的namespace。
- **hbase**，系统命名空间，用于包含系统的内建表，如namespace和meta表。
- **default**，用户建表时所有未指定namespace的表都自动进入该命名空间。

表和命名空间的隶属关系在在创建表时决定，通过```<namespace>:<table>```的格式来指定，当为一张表指定命名空间之后，对表的操作都要加命名空间，否则会找不到表。

* 操作方法
- 创建namespace：```create_namespace 'ns'```
- 删除namespace：```drop_namespace 'ns'```
- 查看namespace：```describe_namespace 'ns'```
- 列出所有namespace：```list_namespace```
- 在namespace下创建表：```create 'ns:tables01', 'r1'```
- 查看namespace下的表：```list_namespace_tables 'ns'```

### Table
 - 与传统关系型数据库类似，HBase以表(Table)的方式组织数据，应用程序将数据存入HBase表中。
 - 用户可以通过命令行或JAVA API来创建表。
 - 表名通常用JAVA string类型或byte[]类型表示，作为HDFS存储路径的一部分来使用，因此必须要符合文件名规范。

### Row
 - HBase表中的行通过 RowKey 进行唯一标识，不论是数字还是字符串，最终都会转换成字节数组进行存储。
 - 行是按RowKey字典顺序排列，按照二进制字节从左至右逐一对比形成最终的次序。如row-1xxx小于row-2xxx，无论后面的xxx如何变化，row-1xxx都排在row-2xxx之前。
 - Rowkey被冗余存储，所以其长度不宜过长，避免占用大量空间同时降低检索效率。
 - 还应该尽量分布均匀，防止产生热点现象。
 - 必须在设计上保证其唯一性。


### Column Family
 - 表由行和列共同组织，同时引入列族的概念，它将一列或多列组织在一起，HBase的列必须属于某一个列族，在创建表时只需指定表名和至少一个列族。
 - 列族影响表的物理结构，创建表后列族还可以更改，但比较麻烦。


### Cell
 - 行和列的交叉点称为单元格，单元格的内容就是列的值。
 - 以二进制形式存储，同时它是版本化的。


### version
 - 每个cell的值可保存数据的多个版本，到底支持几个版本可在建表时指定。
 - 按时间顺序倒序排列，时间戳是64位的整数，可在写入数据时赋值，也可由RegionServer自动赋值。


### 特点
 - HBase没有数据类型，任何列值都被转换成字符串进行存储。
 - 与RDBMS在创建表时需明确包含的列及类型不同，HBase表的每一行可以有不同的列。
 - 相同RowKey的插入操作被认为是同一行的操作。即相同RowKey的二次写入操作，第二次可被可为是对该行某些列的更新操作。
 - 列由列族和列名连接而成， 分隔符是`:`，如  d:Name  （d: 列族名， Name: 列名）


### 结论
 - HBase不支持条件查询和Order by等查询，读取记录只能按Row key（及其range）或全表扫描。
 - 在表创建时只需声明表名和至少一个列族名，每个Column Family为一个存储单元。
 - Column不用创建表时定义即可以动态新增，同一Column Family的Columns会群聚在一个存储单元上，并依Column key排序，因此设计时应将具有相同I/O特性的Column设计在一个Column Family上以提高性能。
 - 通过row和column确定一份数据，这份数据的值可能有多个版本，不同版本的值按照时间倒序排序，即最新的数据排在最前面，查询时默认返回最新版本。
 - 每个单元格值通过4个键唯一索引，tableName+RowKey+ColumnKey+Timestamp=>value。

### 存储类型
 - TableName 是字符串（Java 类型 String）
 - RowKey 和 ColumnName 是二进制值（Java 类型 byte[]）
 - Timestamp 是一个 64 位整数（Java 类型 long）
 - value 是一个字节数组（Java类型 byte[]）



## 工作过程
HRegionServer负责打开Region，并创建HRegion实例，HRegion会为每个表的HColumnFamily（用户创建表时定义的）创建一个Store实例。每个Store实例包含一个或多个StoreFile实例，StoreFile是实际数据存储文件HFile的轻量级封装，每个Store会对应一个MemStore。

 写入数据时数据会先写入Hlog中，成功后再写入MemStore中。Memstore中的数据因为空间有限，所以需要定期flush到文件StoreFile中，每次flush都是生成新的StoreFile。HRegionServer在处理Flush请求时，将数据写成HFile文件永久存储到HDFS上，并且存储最后写入的数据序列号。
