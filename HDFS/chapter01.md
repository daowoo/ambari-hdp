# HDFS的基本概念
## 设计原则
* 非常大的文件
> 这里的非常大是指几百MB,GB,TB.雅虎的hadoop集群已经可以存储PB级别的数据

* 流式数据访问：
> 基于一次写，多次读。

* 商用硬件：
> hdfs的高可用是用软件来解决，因此不需要昂贵的硬件来保障高可用性，各个生产商售卖的pc或者虚拟机即可。

## 不适用的场景
* 低延迟的数据访问
> hdfs的强项在于大量的数据传输，递延迟不适合他，10毫秒以下的访问可以无视hdfs，不过hbase可以弥补这个缺陷。

* 太多小文件
> namenode节点在内存中hold住了整个文件系统的元数据，因此文件的数量就会受到限制，每个文件的元数据大约150字节1百万个文件，每个文件只占一个block，那么就需要300MB内存。你的服务器可以hold住多少呢，你可以自己算算

* 多处写和随机修改
> 目前还不支持多处写入以及通过偏移量随机修改

## block
为了最小化查找时间比例，hdfs的块要比磁盘的块大很多。hdfs块的大小默认为64MB，和文件系统的块不同，hdfs的文件可以小于块大小，并且不会占满整个块大小。
假定查找时间在10ms左右，数据传输几率在100MB/s,为了使查找时间是传输时间的1%，块的大小必须在100MB左右一般都会设置为128MB。

有了块的抽象之后，hdfs有了三个优点：
* 可以存储比单个磁盘更大的文件
* 存储块比存储文件更加简单，每个块的大小都基本相同
* 使用块比文件更适合做容错性和高可用

## namenode和datanode
hdfs集群有两种类型的节点，一种为master及namenode，另一种为worker及datanodes。

namenode节点管理文件系统的命名空间。它包含一个文件系统的树，所有文件和目录的原数据都在这个树上，这些信息被存储在本地磁盘的两个文件中，image文件和edit log文件。文件相关的块存在哪个块中，块在哪个地方，这些信息都是在系统启动的时候通过加载image和edit log到namenode的内存中，并不会存储在磁盘中。

datanode节点在文件系统中充当的角色就是苦力，按照namenode和client的指令进行存储或者检索block，并且周期性的向namenode节点报告它存了哪些文件的block。

namenode节点如果不能使用了，那么整个hdfs就玩完了。为了防止这种情况，
* namenode配置元数据写到多个磁盘中，最好是独立的磁盘，或者NFS，以保证故障后快速的启用新的namenode节点。
* 使用secondary namenode，在HDFS中提供一个Checkpoint Node，通过设置一个Checkpoint来帮助namenode更好的工作，其主要工作内容就是定期根据编辑日志（edit log）合并命名空间的镜像(image),防止编辑日志过大，由于不是实时的，有数据上的损失是很可能发生的。
* 需要注意的是secondary namenode只是namenode的一个助手节点，它不是取代namenode，也不是namenode的备份。

## hdfs Federation
namenode节点持续load所有的文件和块的引用在内存中，这就意味着在一个拥有很多很多文件的很大的集群中，内存就成为了一个限制的条件，hdfs federation在hadoop 2.x的被实现了，允许hdfs有多个namenode节点，每个管hdfs的一部分，比如一个管/usr，另一个管/home，每个namenode节点是相互隔离的，一个挂掉不会影响另外一个。

## hdfs的HA
不管namenode节点的备份还是使用secondary namenode节点都只能保证数据的恢复，并不能保证hdfs的高可用性，一旦namenode节点挂掉就会产生SPOF(单点故障)，这时候要手动去数据备份恢复，或者启用新namenode节点，新的namenode节点在对外提供服务之前要做三件事：
* 把命名空间的镜像加载到内存中。
* 重新运行编辑日志。
* 接受各个datanode节点的block报告。
在一个大型一点的hdfs系统中，等这些做完需要30分钟左右。

hadoop 2.x已经支持了高可用性(HA)，在一个典型的HA集群，两个独立的物理节点配置为NameNodes。在任何时间点，其中之一NameNodes是处于Active状态，另一种是在Standby状态。 Active NameNode负责所有的客户端的操作，而Standby NameNode尽用来保存好足够多的状态，以提供快速的故障恢复能力。

为了保证Active NN与Standby NN节点状态同步，即元数据保持一致。除了DataNode需要向两个NN发送block位置信息外，还构建了一组独立的守护进程`JournalNodes`,用来FsEdits信息。当Active NN执行任何有关命名空间的修改，它需要持久化到一半以上的JournalNodes上。而Standby NN负责观察JNs的变化，读取从Active NN发送过来的FsEdits信息，并更新其内部的命名空间。一旦ActiveNN遇到错误，Standby NN需要保证从JNs中读出了全部的FsEdits,然后切换成Active状态。

需要注意的是，在HA集群中，Standby NameNodes还执行Checkpoint，因此不需要在HA群集中运行Secondary NameNode，CheckpointNode或BackupNode，如果运行了Secondary NameNode反而会带来错误。

## failover和fencing
* failover：将备份namenode激活的过程，管理激活备份namenode的系统叫做failover controller，zookeeper就可以担当这样的角色，可以保证只有一个节点处于激活状态。
* fencing：防止原来namenode活过来的过程，必须确认原来的namenode已经真的挂掉了，很多时候只是网络延迟，如果备份节点已经激活了，原来的节点又可以提供服务了，这样是不行的。
* 可以用STONITH实现，STONITH可以做到直接断电把原namenode节点fencing掉
