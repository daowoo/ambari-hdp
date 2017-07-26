# hbase-site.xml

与Hadoop中特定node的HDFS配置添加到hdfs-site.xml文件类似，对于Hbase，每个node的自定义选项存放在hbase-site.xml中。它基于hbase-default.xml而生成，Hbase在启动过程中会用hbase-site.xml中的配置覆盖hbase-default.xml。

需要注意的是，hbase-site.xml修改后，集群中的所有节点主机都需要重启后才能正常使用。

## 目录相关

* hbase.tmp.dir

默认值：${java.io.tmpdir}/hbase-${user.name}

本地文件系统的临时文件夹，一般建议将其修改到其它能持久存在的目录，因为/tmp会在重启时清除数据。

* hbase.rootdir

默认值：${hbase.tmp.dir}/hbase

region server的共享目录，用来持久化HBase。URL需要是'完全正确'的，还要包含文件系统的scheme。例如，要表示hdfs中的'/hbase'目录，namenode 运行在namenode.example.org的9090端口。则需要设置为hdfs://namenode.example.org:9000/hbase。默认情况下HBase是写到/tmp的。不改这个配置，数据会在重启的时候丢失。


* hbase.fs.tmp.dir

默认值：/user/${user.name}/hbase-staging

用于保留临时数据的默认文件系统（HDFS）中的暂存目录。


* hbase.local.dir

默认值：${hbase.tmp.dir}/local/

使用本地存储时，位于本地文件系统的数据存储的路径。

* hbase.cluster.distributed

默认值：false

HBase的运行模式。false是单机模式，true是分布式模式。若为false,HBase和Zookeeper会运行在同一个JVM里面。


## Zookeeper相关

* hbase.zookeeper.quorum

默认值：localhost

Zookeeper集群的地址列表，用逗号分割。默认是localhost，是给伪分布式用的。要修改成'snn.daowoo.com,hive.daowoo.com,nn.daowoo.com'类型的值才能在完全分布式的情况下使用。如果在hbase-env.sh设置了HBASE_MANAGES_ZK，这些ZooKeeper节点就会和HBase一起启动。

* zookeeper.recovery.retry.maxsleeptime

默认值：60000ms

如果HBase集群出现问题，每次重试操作都会重试ZK的操作，重试ZK的总数是`hbase.client.retries.number * zookeeper.recovery.retry`，并且休眠时间每次重试都会进一步增加，为了限制休眠时间的无限增长，该参数给定了ZK重试操作的最大休眠时长。

* zookeeper.session.timeout

默认值：90000ms

ZooKeeper会话超时间隔，Hbase使用其作为连接zookeeper的会话超时时长。

* zookeeper.znode.parent

默认值：/hbase

ZooKeeper中的HBase的根ZNode。所有配置有相对路径的HBase的ZooKeeper文件都位于此目录下面。

* zookeeper.znode.acl.parent

默认值：acl

root znode的访问控制方式

* hbase.zookeeper.dns.interface

默认值：default

当使用DNS的时候，ZooKeeper server用来上报的IP地址的网络接口名字（使用哪个网卡）。

* hbase.zookeeper.dns.nameserver

默认值：default

当使用DNS的时候，ZooKeeper server使用的DNS的域名或者IP地址。

* hbase.zookeeper.peerport

默认值：2888

ZooKeeper节点使用的端口。

* hbase.zookeeper.leaderport

默认值：3888

ZooKeeper用来选择Leader的端口。

* hbase.zookeeper.property.initLimit

默认值：10

ZooKeeper的zoo.conf中的配置，初始化synchronization阶段的ticks数量限制。

* hbase.zookeeper.property.syncLimit

默认值：5

ZooKeeper的zoo.conf中的配置，送一个请求到获得承认之间的ticks的数量限制。

* hbase.zookeeper.property.dataDir

默认值：${hbase.tmp.dir}/zookeeper

ZooKeeper的zoo.conf中的配置，快照的存储位置。

* hbase.zookeeper.property.clientPort

默认值：2181

ZooKeeper的zoo.conf中的配置，Hbase客户端连接的端口。

* hbase.zookeeper.property.maxClientCnxns

默认值：300

ZooKeeper的zoo.conf中的配置，ZooKeeper集群中的单个节点接受的单个Client(以IP区分)的请求的并发数。
这个值可以调高一点，防止在单机和伪分布式模式中出问题。


## 接口相关

* hbase.master.port

默认值：16000

HMaster提供服务的端口。

* hbase.master.info.port

默认值：16010

HMaster的Web UI端口，如果设置为-1，意味着关闭UI。

* hbase.master.info.bindAddress

默认值：0.0.0.0

HMaster的Web UI绑定的IP地址，默认监听节点主机的所有IP地址。

* hbase.master.infoserver.redirect

默认值：true

Master是否监听其Web UI并将请求重定向到Master和和RegionServer共享的Web UI服务器。

* hbase.regionserver.port

默认值：16020

Regionserver的RESET API服务端口。

* hbase.regionserver.info.port

默认值：16030

Regionserver的Web UI端口，如果设置为-1，意味着关闭UI。

* hbase.regionserver.info.bindAddress

默认值：0.0.0.0

Regionserver的Web UI绑定的IP地址，默认监听节点主机的所有IP地址。

* hbase.regionserver.info.port.auto

默认值：false

Master或RegionServer是否要动态搜一个可以用的端口来绑定界面。当hbase.regionserver.info.port已经被占用的时候，可以搜一个空闲的端口绑定。这个功能在测试的时候很有用。


## WAL相关

* hbase.server.thread.wakefrequency

默认值：10000ms

后台维护线程的sleep时间，默认10000毫秒，比如log roller。

* hbase.master.logcleaner.plugins

默认值：org.apache.hadoop.hbase.master.cleaner.TimeToLiveLogCleaner

LogsCleaner服务会执行的一组Hlog清理代理程序，值用逗号分隔的文本表示。这些WAL/HLog cleaners会按顺序调用。可以把先调用的放在前面。你可以实现自己的LogCleanerDelegat，加到Classpath下，然后在这里写下类的全称。一般都是加在默认值的前面。

* hbase.master.logcleaner.ttl

默认值：600000ms

Hlog存在于.oldlogdir 文件夹的最长时间, 超过了就会被Master的线程清理掉。

* hbase.master.hfilecleaner.plugins

默认值：org.apache.hadoop.hbase.master.cleaner.TimeToLiveHFileCleaner

代表的是HFile的清理插件列表，逗号分隔，被HFileService调用，可以自定义HFile的清理策略，使用方法与WAL清理插件配置项类似。

* hbase.regionserver.logroll.period

默认值：3600000ms

WAL日志对象Hlog执行commit的周期，不管有没有写足够的值。

* hbase.regionserver.logroll.errors.tolerated

默认值：2

在关闭WAL过程中，如果连续出现关闭错误，且错误次数大于该值，就会触发Regionserver异常。

* hbase.regionserver.hlog.reader.impl

默认值：org.apache.hadoop.hbase.regionserver.wal.ProtobufLogReader

HLog file reader 的实现类。

* hbase.regionserver.hlog.writer.impl

默认值：org.apache.hadoop.hbase.regionserver.wal.ProtobufLogWriter

HLog file writer 的实现类。


## handler与queue相关

* hbase.regionserver.handler.count

默认值：30

RegionServer请求处理的I/O线程数，对于Master来说，是Master受理的handler数量。

* hbase.ipc.server.callqueue.handler.factor

默认值：0.1

确定RPC请求队列个数的运算因子，队列数 = handler.factor * handler.count，其中，值为0表示在所有handler之间共享的单个队列，值1表示每个handler都有自己的队列。

* hbase.ipc.server.callqueue.read.ratio

默认值：0

将RPC请求队列划分成读&&写队列的分配比例，该值将乘以上面计算出的队列数量后进行判读。
假如给定队列的总数为10。
read.ratio为0表示：10个队列将同时包含读/写请求。
read.ratio为0.3表示：3个队列将只包含读取请求，7个队列将仅包含写入请求。 read.ratio为0.5表示：5个队列将只包含读请求，5个队列将只包含写请求。
read.ratio为0.8表示：8个队列只包含读取请求，2个队列只包含写入请求。
read.ratio为1表示：9个队列只包含读请求，1个队列将只包含写请求。

* hbase.ipc.server.callqueue.scan.ratio

默认值：0

scan.ratio将上面计算出的读取队列又进一步划分为small-read队列和long-read队列，同样地，该参数也代表着分配的比例，需要将该值乘以上面计算出的读队列数量后进行判读。
假如给定的读队列的总数为10。
scan.ratio为0或者1均表示：10个队列将同时包含long-read和small-read的读请求。
scan.ratio为0.3表示：3个long-read队列和7个small-read队列。
scan.ratio为0.5表示：5个long-read队列和5个small-read队列。
scan.ratio为0.8表示：8个long-read队列和2个small-read队列。


## Client相关

* hbase.client.write.buffer

默认值：2097152（2M）

客户端写buffer，设置autoFlush为false时，当客户端写满buffer才flush

* hbase.client.pause

默认值：100ms

客户端暂停时间，客户端在重试前的等待时间。比如失败的get操作和region查询操作等都很可能用到。

* hbase.client.pause.cqtbe

默认值：none

是否为CallQueueTooBigException（cqtbe）使用特殊的客户端暂停。如果您观察到来自同一RegionServer的频繁CQTBE，并且队列总是被填充满，一般将此属性设置为比hbase.client.pause更高的值。

* hbase.client.retries.number

默认值：35

Client最大重试次数，所有需重试操作的最大值。例如从root region服务器获取root region；Get单元值；行Update操作等等。

* hbase.client.max.total.tasks

默认值：100

单个客户端最大并发写请求数。

* hbase.client.max.perserver.tasks

默认值：5

客户端每个HRegionServer的最大并发写请求数

* hbase.client.max.perregion.tasks

默认值：1

客户端每个HRegion最大并发写请求数

* hbase.client.perserver.requests.threshold

默认值：2147483647

客户端每个HRegionServer挂起并发请求的最大数量，这是进程级别门限值。

* hbase.client.scanner.caching

默认值：2147483647

当调用Scanner的next方法，而值又不在缓存里的时候，从服务端一次获取的行数。越大的值意味着Scanner会快一些，但是会占用更多的内存。当缓冲被占满的时候，next方法调用会越来越慢。慢到一定程度，可能会导致超时。例如超过了hbase.regionserver.lease.period。

* hbase.client.keyvalue.maxsize

默认值：10485760（10M）

一个KeyValue实例的最大size，这个是用来设置存储文件中的单个entry的大小上界。因为一个KeyValue是不能分割的，所以可以避免因为数据过大导致region不可分割。明智的做法是把它设为可以被最大region size整除的数。如果设置为0或者更小，就会禁用这个检查。

* hbase.server.keyvalue.maxsize

默认值：10485760（10M）

单个单元格的最大允许大小，包括Value和Key的所有组成部分，值为0或更小将禁用检查。

* hbase.client.scanner.timeout.period

默认值：60000ms

客户端scan请求的超时时长。

* hbase.client.localityCheck.threadPoolSize

默认值：2

做localityCheck的线程池大小。

* hbase.rpc.timeout

默认值：60000ms

Hbase client发起远程调用时的超时时限，使用ping来确认连接，但是最终会抛出一个TimeoutException。

* hbase.client.operation.timeout


Hbase client发起的操作用时的超时时限。

* hbase.rpc.shortoperation.timeout

默认值：10000ms

另一个版本的hbase.rpc.timeout，控制短操作的超时时限，比如region server 汇报master的操作的超时时限可以设置小，这样有利于master的failover


## flush相关

* hbase.hregion.memstore.flush.size

默认值：134217728（128MB）

当memstore的大小超过这个值的时候，就会触发其所属的Region执行flush操作，这个值被一个线程每隔hbase.server.thread.wakefrequency检查一下。

* hbase.hregion.memstore.block.multiplier

默认值：2

一个Region中所有memstore大小的总和达到了`hbase.hregion.memstore.block.multiplier * hbase.hregion.flush.size`的大小时，就会短时间阻塞update操作，并马上触发flush操作。实际上就是，内存操作的速度和磁盘不匹配，需要等一等。

* hbase.regionserver.global.memstore.size

默认值：40%

一台ReigonServer可能有成百上千个memstore，每个memstore也许未达到flush.size，jvm的heap就不够用了。这个参数就是为了限制memstores占用的总内存。当单个region server的全部memtores的最大值（0.4 * HBASE_HEAPSIZE），超过这个值，update操作会被挂起，强制在所有region上执行flush操作。

旧版本中该参数为hbase.regionserver.global.memstore.upperLimit。

* hbase.regionserver.global.memstore.size.lower.limit

默认值：95%

当region server强制执行flush操作的时候，此时根据region中memstore的大小，先flush最大的，再继续flush次大的，直到当全部memtores之和低于这个值（0.95 * hbase.regionserver.global.memstore.size * HBASE_HEAPSIZE）的时候，flush才会停止。

旧版本中该参数为hbase.regionserver.global.memstore.lowerLimit。

* hbase.regionserver.maxlogs

默认值：32

当一个Region Server中HLog数量达到该上限时，系统会选取最早的一个 HLog对应的一个或多个Region进行flush。

该参数目前版本已经不支持外部修改，只能在代码中修改。

* hbase.regionserver.optionalcacheflushinterval

默认值：3600000s

HBase定期刷新Memstore，确保Memstore不会长时间没有持久化。同时，为避免所有的MemStore在同一时间都进行flush导致的问题，定期的flush操作有20000左右的随机延时。

* hbase.hregion.memstore.flush.size

默认值：134217728b

Memstore写磁盘的flush阈值，超过这个大小就flush。

* hbase.hregion.preclose.flush.size

默认值：5242880b

如果一个region的memstore的大小等于或超过这个参数的量，在关闭region时（放置关闭flag），要提前flush，然后region关闭下线。

* hbase.hstore.flusher.count

默认值：2

flusher启动的线程个数，线程数过少会导致大量的flush积压在队列，线程过多，并发刷新也会导致HDFS负载过大。


## split相关

* hbase.regionserver.region.split.policy

默认值：org.apache.hadoop.hbase.regionserver.SteppingSplitPolicy

确定何时应该对Region进行split操作的策略配置，目前可用的策略如下。
ConstantSizeRegionSplitPolicy：仅仅当region大小超过常量值（hbase.hregion.max.filesize大小）时，才进行拆分。
DisabledRegionSplitPolicy：禁止手动拆分
DelimitedKeyPrefixRegionSplitPolicy：保证以分隔符前面的前缀为splitPoint，保证相同RowKey前缀的数据在一个Region中。
KeyPrefixRegionSplitPolicy：保证具有相同前缀的row在一个region中（要求设计中前缀具有同样长度）。指定rowkey前缀位数划分region，通过读取table的prefix_split_key_policy.prefix_length属性，该属性为数字类型，表示前缀长度，在进行split时，按此长度对splitPoint进行截取。此种策略比较适合固定前缀的rowkey。
IncreasingToUpperBoundRegionSplitPolicy：根据公式min(r^2*flush.size，maxFileSize)确定split的maxFileSize，其中r为在线region个数，maxFileSize由hbase.hregion.max.filesize指定。

* hbase.regionserver.regionSplitLimit

默认值：1000

region的数量到了这个值后就不会在分裂了。注意，这不是一个region数量的硬性限制，只是起到了一定建议作用。默认是MAX_INT，就是说不限制分裂个数。

* hbase.hregion.max.filesize

默认值：10737418240

HFile的最大容量，当一个region里的列族的任意一个HFile超过这个大小，那么将触发region进行split。



## compact相关

* hbase.hregion.majorcompaction

默认值：604800000ms(7d)

region中所有的HFile进行major compact的时间周期。

* hbase.hregion.majorcompaction.jitter

默认值：0.5

major compaction的触发抖动范围，上一个参数不是一个严格周期，会有上/下抖动，这个参数就是这个抖动的比例。


* hbase.hstore.compactionThreshold

默认值：3

HStore存储HFile的个数阈值，超过这个阈值则所有的HFile会被compact到一个新的HFile。


* hbase.hstore.blockingStoreFiles

默认值：10

每个Store中包含的HFile文件最大个数，在执行flush的操作前，如果HStore的HFile数超过了该值，就会触发compact操作，阻塞flush。


* hbase.hstore.blockingWaitTime

默认值：90000ms

flush之前，由于HStore的HFile数超过了blockingStoreFiles设定而触发compact操作过程中，若超过该设定的时长还未完成compact，则恢复对flush的阻塞。

* hbase.hstore.compaction.min

默认值：3

触发minor compaction时，满足条件的Hfile文件个数的最小值，避免频繁的进行少量文件的compact。


* hbase.hstore.compaction.max

默认值：10

触发minor compaction之后，一次compact操作最多选取的HFile文件个数。


* hbase.hstore.compaction.min.size

默认值：134217728(128M)

Hfile容量小于该值时将直接符合minor compaction的判断条件，不再进行其他判断。

* hbase.hstore.compaction.max.size

默认值：9223372036854775807

Hfile容量大于该值时将不再纳入minor compaction的判断范围。

* hbase.hstore.compaction.ratio

默认值：1.2F

此值用于确定大于compaction.min.size的给定StoreFile是否直接符合minor compaction的判断条件。

* hbase.hstore.compaction.ratio.offpeak

默认值：5.0F

在非高峰时段，通过该值来放宽compaction.ratio所配置的值范围，不过该值仅仅在hbase.offpeak.start.hour和hbase.offpeak.end.hour之间的时间段有效。


* hbase.hstore.time.to.purge.deletes

默认值：0

在进行major compaction操作时，延迟清除附带删除标记的Cell。

* hbase.offpeak.start.hour

默认值：-1

每天非业务高峰时段的起始时间，取值为0~23。

* hbase.offpeak.end.hour

默认值：-1

每天非业务高峰时段的截止时间，取值为0~23。


* hbase.regionserver.thread.compaction.throttle

默认值：2684354560（256M）

regionserver默认有两个不同的compaction的线程池，一个用于大数据量的合并，另一个用于小数据量的合并，根据该值结合待合并的数据量来判断使用哪个线程池。


* hbase.hstore.compaction.kv.max

默认值：10

在flushing或者compacting时允许的最大keyvalue个数，如果有大的KeyValue则配置一个小的值，如果行数多且小则配置大值。


## BlockCache相关

* hbase.storescanner.parallel.seek.enable

默认值：false

执行scan过程中，是否启用并行查找。

* hbase.storescanner.parallel.seek.threads

默认值：10

执行scan过程中，并行查找开启后的线程池大小。


* hfile.block.cache.size

默认值：0.4

一个配置比例，允许heap的对应比例的内存作为HStoreFile的block cache，设置为0则disable这个比例。


* hfile.block.index.cacheonwrite

默认值：false

在index写入的时候是否允许put无根（non-root）的多级索引块到block cache里。

* hfile.index.block.max.size

默认值：131072b

在多级索引的树形结构里，如果任何一层的block index达到这个配置大小，则block写出，同时替换上新的block。

* hbase.bucketcache.ioengine

默认值：none

bucketcache使用的存储空间所在的物理位置，可选择heap、offheap、file三种。


* hbase.bucketcache.combinedcache.enabled

默认值：true

是否在LRU缓存中联合使用bucketcache，在这种模式下，indices和blooms保存在LRU中，数据块保存在bucketcache中。


* hbase.bucketcache.size

默认值：none

给予bucketcache的内存大小占总内存的百分比。


* hfile.format.version

默认值：3

HFile格式版本，除非为了测试兼容性，否则不建议修改。

* hfile.block.bloom.cacheonwrite

默认值：false

对联合布隆过滤器的内联block开启cache-on-writ

* io.storefile.bloom.block.size

默认值：131072b

联合布隆过滤器的单一块（chunk）的大小，这个值是一个逼近值。

* hbase.rs.cacheblocksonwrite

默认值：false

当一个HFile block完成时是否写入block cache。

* hbase.cells.scanned.per.heartbeat.check

默认值：10000ms

在进行scan操作期间，为了在长时间的scan过程中保证客户端和服务器之间的链接，scan操作会利用该时间间隔完成heartbeat验证。


## balancer相关

* hbase.master.balancer.maxRitPercent

默认值：1.0（表示不限制）

在进行负载均衡操作时，能够允许参与transition的region所占的百分比。

* hbase.balancer.period

默认值：300000ms

Master执行region balancer的间隔。

* hbase.regions.slop

默认值：0.001

假设集群内regionserver所管理region的平均数量是average，如果有regionserver的region数目超过average + (average*slop)，则触发rebalance操作。

* hbase.master.loadbalancer.class

默认值：org.apache.hadoop.hbase.master.balancer.StochasticLoadBalancer

进行balancer操作时具体执行的算法类，包括`SimpleLoadBalancer`和`StochasticLoadBalancer`，可以自定义实现。


## 功能配置

* hbase.regionserver.msginterval

默认值：3000ms

RegionServer 发消息给 Master 时间间隔。

* hbase.regionserver.dns.interface

默认值：default

当使用DNS的时候，RegionServer用来上报的IP地址的网络接口名字（使用哪个网卡）。

* hbase.regionserver.dns.nameserver

默认值：default

当使用DNS的时候，RegionServer使用的DNS的域名或者IP地址。

* hbase.bulkload.retries.number

默认值：10

做bulk load的最大重试次数，若设置为0，则代表不断重试。

* hbase.normalizer.period

默认值：1800000ms

normalizer的概念不知道是什么

* hbase.server.versionfile.writeattempts

默认值：3

退出前写version file的重试次数，每次尝试的间隔由thread.wakefrequency定义。

* hbase.hregion.memstore.mslab.enabled

默认值：true

开启MemStore-Local Allocation Buffer，这个配置可以避免在高写入的情况下的堆内存碎片，可以降低在大堆情况下的stop-the-world GC频率。

* hbase.master.normalizer.class

默认值：org.apache.hadoop.hbase.master.normalizer.SimpleRegionNormalizer

进行normalizer操作时具体执行的类，可以自定义实现。

* hbase.rest.csrf.enabled

默认值：false

启动CSRF，浏览器过滤。

* hbase.rest-csrf.browser-useragents-regex

默认值：Mozilla.,Opera.

支持的浏览器列表，以逗号分隔，只响应列出的浏览器所发出的REST请求。

* hbase.display.keys

默认值：true

当设置为true时，webUI将会显示region的开始/结束键作为表的详细信息，并且将rowkey作为region名称的一部分。当这被设置为false时，这些rowkey将被隐藏。

* hbase.ipc.client.tcpnodelay

默认值：true

在tcp socket连接时设置 no delay。

* hbase.defaults.for.version.skip

默认值：false

是否跳过hbase.defaults.for.version的检查

* hbase.table.lock.enable

默认值：true

设置为true来允许在schema变更时zk锁表，锁表可以阻止并发的schema变更导致的表状态不一致。


## coprocessor相关

* hbase.coprocessor.enabled

默认值：true

所有协处理器的启用/禁止开关。

* hbase.coprocessor.user.enabled

默认值：true

用户定义的协处理器的启用/禁止开关。

* hbase.coprocessor.region.classes

默认值：none

逗号分隔的Coprocessores列表，会被加载到默认所有表上。在自己实现了一个Coprocessor后，将其添加到Hbase的classpath并加入全限定名。也可以延迟加载，由HTableDescriptor指定

* hbase.coprocessor.master.classes

默认值：none

由HMaster进程加载的coprocessors，逗号分隔，同coprocessor类似，加入classpath及全限定名

* hbase.coprocessor.abortonerror

默认值：true

如果coprocessor加载失败或者初始化失败或者抛出Throwable对象，则主机退出。设置为false会让系统继续运行，但是coprocessor的状态会不一致，所以一般debug时才会设置为false


# security相关

* hbase.security.exec.permission.checks

默认值：false

启用acl权限验证。

* hadoop.policy.file

默认值：hbase-policy.xml

RPC服务器做权限认证时需要的安全策略配置文件，在Hbase security开启后使用

* hbase.superuser

默认值：none

Hbase security 开启后的超级用户配置，一系列由逗号隔开的user或者group

* hbase.auth.key.update.interval

默认值：86400000ms

Hbase security开启后服务端更新认证key的间隔时间

* hbase.auth.token.max.lifetime

默认值：604800000

Hbase security开启后，认证token下发后的生存周期

* hbase.ipc.client.fallback-to-simple-auth-allowed

默认值：false

client使用安全连接去链接一台非安全服务器时，服务器提示client切换到SASL SIMPLE认证模式（非安全），如果设置为true，则client同意切换到非安全连接，如果false，则退出连接。


* hbase.ipc.server.fallback-to-simple-auth-allowed

client使用非安全连接去链接一台安全服务器时，如果设置为true，允许接入该client的连接，如果false，则拒绝连接。


## kerberos相关

* hbase.master.keytab.file

默认值：none

kerberos keytab 文件的全路径名，用来为HMaster做log

* hbase.master.kerberos.principal

默认值：none

运行HMaster进程时需要kerberos的principal name，这个配置就是这个name的值，比如：`hbase/_HOST@EXAMPLE.COM`。

* hbase.regionserver.keytab.file

默认值：none

kerberos keytab 文件的全路径名，用来为HRegionServer做log


* hbase.regionserver.kerberos.principal

默认值：none

运行HRegionServer进程时需要kerberos的principal name，跟master.kerberos.principal类似。


## Rest相关

* hbase.rest.port

默认值：8080

Hbase REST服务器的端口，默认是8080

* hbase.rest.readonly

默认值：false

定义REST服务器启动的模式，有两种方式，false：所有http方法都将被通过-GET/PUT/POST/DELETE，true：只有get方法ok。

* hbase.rest.threads.max

默认值：100

REST服务器线程池的最大线程数，池满的话新请求会自动排队，限制这个配置可以控制服务器的内存量。

* hbase.rest.threads.min

默认值：2

同上类似，最小线程数，为了确保服务器的服务状态，默认是2。


* hbase.rest.support.proxyuser

默认值：false

使REST服务器支持proxy-user 模式。


## snapshot相关

* hbase.snapshot.enabled


* hbase.snapshot.restore.take.failsafe.snapshot


* hbase.snapshot.restore.failsafe.name


* hbase.snapshot.master.timeout.millis


* hbase.snapshot.region.timeout


## mob相关

* hbase.mob.file.cache.size


* hbase.mob.cache.evict.period


* hbase.mob.cache.evict.remain.ratio


* hbase.master.mob.ttl.cleaner.period


* hbase.mob.compaction.mergeable.threshold


* hbase.mob.delfile.max.count


* hbase.mob.compaction.batch.size


* hbase.mob.compaction.chore.period


* hbase.mob.compactor.class


* hbase.mob.compaction.threads.max


## thrift相关

* hbase.thrift.minWorkerThreads


* hbase.thrift.maxWorkerThreads


* hbase.thrift.maxQueuedRequests


* hbase.regionserver.thrift.framed


* hbase.regionserver.thrift.framed.max_frame_size_in_mb


* hbase.regionserver.thrift.compact
