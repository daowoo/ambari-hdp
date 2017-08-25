# Hbase系统配置
## 文档
* hbase官网：https://hbase.apache.org/book.html#_configuration_files
* 个人笔记：https://panhongfa.gitbooks.io/hdp/content/Hbase/Configuration/README.md
* 书籍章节：Hbase实战12.7小节、Hbase权威指南11.8小节及附录A

## 规划
* 期望目的：了解hbase配置参数的分类和作用，掌握常用的可优化点
* 具体内容
  * 配置文件分类介绍
  * 目录相关参数
  * Zookeeper相关参数
  * IP、端口相关参数
  * Handler与Queue参数
  * WAL参数
  * Flush参数
  * Client参数
  * Split参数
  * Compact参数
  * BlockCache参数
  * Balancer参数
  * Coprocessor参数
  * Rest API参数
  * Snapshot参数
  * Mob参数
  * Thrift参数
  * Security参数
  * Kerberos参数
* 时间安排
  * 2017-8-22 下午2:30 ~ 3:30
  * Mob和Thrift较少使用，没进行深入了解，本次不介绍
  * Security和Kerberos，后期学习Kerberos时再集中介绍

## 前期准备
* hbase集群环境，单机版，伪分布式版均可
* 大致浏览官网主页和书籍章节

## 遗留问题
* hbase.tmp.dir,hbase.rootdir,hbase.fs.tmp.dir,hbase.local.dir存储的是啥?

* hbase.master.logcleaner.plugins作用的是WAL还是HMaster LOG?
定义的WAL清理程序，定义多个类时它们之间以逗号来分隔，之后会被LogsCleaner服务按定义的顺序来逐个调用，用以删除最早的HLOG文件。用户可以设置为自定义的清理程序，并将其完整的类名设置到classpath中。

* hbase中ipc相关的配置参数的作用？
标识为hbase.

* hbase.regionserver.logroll.errors.tolerated的含义，以及logroll是干什么的？


* client中Task和Request有什么区别？

* hbase.hstore.compactionThreshold和hbase.hstore.compaction.min关系？
后台线程CompactionChecker定期触发检查是否需要执行compaction，首先检查HStore（某个列族）中的Hfile数量是否大于hbase.hstore.compaction.min，

* hbase.hregion.majorcompaction和hbase.hregion.majorcompaction.jitter?
假设store中hfile的最早更新时间早于某个值mcTime，就会触发major compaction，HBase预想通过这种机制定期删除过期数据，mcTime是一个浮动值，浮动区间默认为`[7-7*0.2，7+7*0.2]`，其中7为hbase.hregion.majorcompaction，0.2为hbase.hregion.majorcompaction.jitter，也就是默认在7天左右就会执行一次major compaction。

* procedure是什么？

* http Filter和REST Filter有什么作用?

* onwrite
