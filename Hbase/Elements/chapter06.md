# BlockCache的引入
和其他数据库一样，优化IO也是HBase提升性能的不二法宝，而提供缓存更是优化的重中之重。最理想的情况是，所有数据都能够缓存到内存，这样就不会有任何文件IO请求，读写性能必然会提升到极致。然而现实是残酷的，随着请求数据的不断增多，将数据全部缓存到内存显得不合实际。幸运的是，我们并不需要将所有数据都缓存起来，根据二八法则，80%的业务请求都集中在20%的热点数据上，因此将这部分数据缓存起就可以极大地提升系统性能。

HBase在实现中提供了两种缓存结构：MemStore和BlockCache。

* MemStore：称为写缓存，HBase执行写操作首先会将数据写入MemStore，并顺序写入HLog，等满足一定条件后统一将MemStore中数据刷新到磁盘，这种设计可以极大地提升HBase的写性能。不仅如此，MemStore对于读性能也至关重要，假如没有MemStore，读取刚写入的数据就需要从文件中通过IO查找，这种代价显然是昂贵的！

* BlockCache：称为读缓存，HBase会将一次文件查找的Block块缓存到Cache中，以便后续同一请求或者邻近数据查找请求，可以直接从内存中获取，避免昂贵的IO操作。MemStore相关知识可以参考[Memstore Flush深度解析](/Hbase/Elements/chapter03.md)，本文将重点分析BlockCache。

在介绍BlockCache之前，简单地回顾一下HBase中Block的概念，详细介绍请查看[HFile结构解析](/Hbase/Elements/chapter04.md)。 Block是HBase中最小的数据存储单元，默认为64K，在建表语句中可以通过参数BlockSize指定。HBase中Block分为四种类型：Data Block，Index Block，Bloom Block和Meta Block。

* Data Block：用于存储实际数据，通常情况下每个Data Block可以存放多条KeyValue数据对；

* Index Block：用于优化随机读的查找路径，通过存储索引数据加快数据查找，

* Bloom Block：同样用于优化随机读的查找路径，但它是通过一定算法可以过滤掉部分一定不存在待查KeyValue的数据文件，减少不必要的IO操作；

* Meta Block：主要存储整个HFile的元数据。

BlockCache是Region Server级别的，一个Region Server只有一个Block Cache，在Region Server启动的时候完成Block Cache的初始化工作。到目前为止，HBase先后实现了3种Block Cache方案，LRUBlockCache是最初的实现方案，也是默认的实现方案；HBase 0.92版本实现了第二种方案SlabCache，见[HBASE-4027](https://issues.apache.org/jira/browse/HBASE-4027)；HBase 0.96之后官方提供了另一种可选方案BucketCache，见[HBASE-7404](https://issues.apache.org/jira/browse/HBASE-7404)。

这三种方案的不同之处在于对内存的管理模式，其中LRUBlockCache是将所有数据都放入JVM Heap中，交给JVM进行管理。而后两者采用了不同机制将部分数据存储在堆外，交给HBase自己管理。这种演变过程是因为LRUBlockCache方案中JVM垃圾回收机制经常会导致程序长时间暂停，而采用堆外内存对数据进行管理可以有效避免这种情况发生。

## LRUBlockCache
HBase默认的BlockCache实现方案。Block数据块都存储在 JVM heap内，由JVM进行垃圾回收管理。它将内存从逻辑上分为了三块：single-access区、mutil-access区、in-memory区，分别占到整个BlockCache大小的25%、50%、25%。

在一次随机读中，一个Block块从HDFS中加载出来之后首先放入signle区，后续如果有多次请求访问到这块数据的话，就会将这块数据移到mutil-access区。而in-memory区表示数据可以常驻内存，一般用来存放访问频繁、数据量小的数据，比如元数据，用户也可以在建表的时候通过设置列族属性IN-MEMORY= true将此列族放入in-memory区。

很显然，这种设计策略类似于JVM中young区、old区以及perm区。无论哪个区，系统都会采用严格的Least-Recently-Used算法，当BlockCache总量达到一定阈值之后就会启动淘汰机制，最少使用的Block会被置换出来，为新加载的Block预留空间。

## SlabCache
为了解决LRUBlockCache方案中因为JVM垃圾回收导致的服务中断，SlabCache方案使用Java NIO DirectByteBuffer技术实现了堆外内存存储，不再由JVM管理数据内存。

默认情况下，系统在初始化的时候会分配两个缓存区，分别占整个BlockCache大小的80%和20%，每个缓存区分别存储固定大小的Block块，其中前者主要存储小于等于64K大小的Block，后者存储小于等于128K Block，如果一个Block太大就会导致两个区都无法缓存。

与LRUBlockCache相同，SlabCache也使用Least-Recently-Used算法对过期Block进行淘汰。和LRUBlockCache不同的是，SlabCache淘汰Block的时候只需要将对应的bufferbyte标记为空闲，后续cache对其上的内存直接进行覆盖即可。

线上集群环境中，不同表不同列族设置的BlockSize都可能不同，很显然，默认只能存储两种固定大小Block的SlabCache方案不能满足部分用户场景，比如用户设置BlockSize = 256K，简单使用SlabCache方案就不能达到这部分Block缓存的目的。因此HBase实际实现中将SlabCache和LRUBlockCache搭配使用，称为DoubleBlockCache。一次随机读中，一个Block块从HDFS中加载出来之后会在两个Cache中分别存储一份；缓存读时首先在LRUBlockCache中查找，如果Cache Miss再在SlabCache中查找，此时如果命中再将该Block放入LRUBlockCache中。

经过实际测试，DoubleBlockCache方案有很多弊端。比如SlabCache设计中固定大小内存设置会导致实际内存使用率比较低，而且使用LRUBlockCache缓存Block依然会因为JVM GC产生大量内存碎片。因此在HBase 0.98版本之后，该方案已经被不建议使用。

## BucketCache
SlabCache方案在实际应用中并没有很大程度改善原有LRUBlockCache方案的GC弊端，还额外引入了诸如堆外内存使用率低的缺陷。然而它的设计并不是一无是处，至少在使用堆外内存这个方面给予了阿里大牛们很多启发。站在SlabCache的肩膀上，他们开发了BucketCache缓存方案并贡献给了社区。

BucketCache通过配置可以工作在三种模式下：heap，offheap和file。无论工作在那种模式下，BucketCache都会申请许多带有固定大小标签的Bucket，和SlabCache一样，一种Bucket存储一种指定BlockSize的数据块，但和SlabCache不同的是，BucketCache会在初始化的时候申请14个不同大小的Bucket，而且即使在某一种Bucket空间不足的情况下，系统也会从其他Bucket空间借用内存使用，不会出现内存使用率低的情况。接下来再来看看不同工作模式，heap模式表示这些Bucket是从JVM Heap中申请，offheap模式使用DirectByteBuffer技术实现堆外内存存储管理，而file模式使用类似SSD的高速缓存文件存储数据块。

实际实现中，HBase将BucketCache和LRUBlockCache搭配使用，称为CombinedBlockCache。和DoubleBlockCache不同，系统在LRUBlockCache中主要存储Index Block和Bloom Block，而将Data Block存储在BucketCache中。因此一次随机读需要首先在LRUBlockCache中查到对应的Index Block，然后再到BucketCache查找对应数据块。BucketCache通过更加合理的设计修正了SlabCache的弊端，极大降低了JVM GC对业务请求的实际影响，但也存在一些问题，比如使用堆外内存会存在拷贝内存的问题，一定程度上会影响读写性能。当然，在后来的版本中这个问题也得到了解决，见[HBASE-11425](https://issues.apache.org/jira/browse/HBASE-11425)。

## 结论
本文是HBase BlockCache系列文章的第一篇，主要概述了HBase中MemStore和BlockCache，再分别对三种BlockCache方案进行了基本介绍。接下来第二篇文章会主要对LRUBlockCache和BucketCache两种方案进行详细的介绍。