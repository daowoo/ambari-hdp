# 性能指标

HBase Metrics是一种监控信息实时收集机制。它负责收集的信息有：
* 功能性信息（Compaction Queue、Store Files个数等）
* JVM使用信息 (Heap Memory 的变化)
* RPC交互信息

借助与Hadoop Metrics同样的方式，默认10秒统计一次然后向Ganglia汇报。

## metrics设置

通过编辑文件`conf/hadoop-metrics2-hbase.properties`配置region server的指标，如果想禁用某个region server的指标，注释相关行然后重启region server使其生效。

## metrics查看

* HMaster Web UI:

![](/assets/Metrics-web-ui.bmp)

* Metrics Dump:

[jmx](http://dn002.daowoo.com:16030/jmx)

* Jconsole远程查看:

TODO

## Master metrics

* hbase.master.numRegionServers

正常运行的RegionServer个数。

* hbase.master.numDeadRegionServers

已经离线的RegionServer个数。

* hbase.master.ritCount

发生transition的region个数。

* hbase.master.ritCountOverThreshold

transition过程消耗的时长超过门限值的region个数。

* hbase.master.ritOldestAge

所有的region，在transition过程中消耗的最长时间，单位为ms。

## RegionServer metrics

|metrics   |object   |desc   |
| -------- | ------- | ----- |
|OpenFileDescriptorCount   |Regionserver本机 |当前节点打开的文件数   |
|FreePhysicalMemorySize    |Regionserver本机 |空闲的物理内存大小  |
|AvailableProcessors       |Regionserver本机 |节点机器的可用cpu个数  |
|Region前缀--storeCount       |单个region |Store个数  |
|Region前缀--storeFileCount       |单个region |Storefile个数  |
|Region前缀--memStoreSize       |单个region |Memstore大小  |
|Region前缀--storeFileSize       |单个region |Storefile大小  |
|Region前缀--compactionsCompletedCount       |单个region |合并完成次数  |
|Region前缀--numBytesCompactedCount       |单个region |合并文件总大小  |
|Region前缀--numFilesCompactedCount       |单个region |合并完成文件个数  |
|totalRequestCount       |Regionserver |总请求数  |
|readRequestCount       |Regionserver |读请求数  |
|writeRequestCount       |Regionserver |写请求数  |
|compactedCellsCount       |Regionserver |合并cell个数  |
|majorCompactedCellsCount       |Regionserver |大合并cell个数  |
|flushedCellsSize       |Regionserver |	flush到磁盘的大小  |
|blockedRequestCount       |Regionserver |因memstore大于阈值而引发flush的次数  |
|splitRequestCount       |Regionserver |region分裂请求次数  |
|splitSuccessCounnt       |Regionserver |region分裂成功次数  |
|slowGetCount       |Regionserver |请求完成时间超过阈值的次数  |
|numActiveHandler       |Regionserver |rpc handler数  |
|receivedBytes       |Regionserver |收到数据量  |
|sentBytes       |Regionserver |发出数据量  |
|HeapMemoryUsage       |Regionserver |堆内存使用量  |
|SyncTime_mean       |Regionserver |WAL写hdfs的平均时间  |
|regionCount       |Regionserver |Regionserver管理region数量  |
|memStoreSize       |Regionserver |Regionserver管理的总memstoresize  |
|storeFileSize       |Regionserver |该Regionserver管理的storefile大小  |
|staticIndexSize       |Regionserver |regionserver所管理的表索引大小  |
|storeFileCount       |Regionserver |该regionserver所管理的storefile个数  |
|hlogFileSize       |Regionserver |WAL文件大小  |
|hlogFileCount       |Regionserver |WAL文件个数  |
|storeCount       |Regionserver |该regionserver所管理的store个数  |
|GcTimeMillis       |Regionserver |GC总时间  |
|GcTimeMillisParNew       |Regionserver |ParNew GC时间  |
|GcCount       |Regionserver |GC总次数  |
|GcCountConcurrentMarkSweep       |Regionserver |ConcurrentMarkSweep总次数  |
|GcTimeMillisConcurrentMarkSweep       |Regionserver |ConcurrentMarkSweep GC时间  |
|ThreadsBlocked       |Regionserver |Block线程数  |
|ThreadsWaiting       |Regionserver |等待线程数  |
