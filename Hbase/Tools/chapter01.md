# 文件检测和修复工具-hbck

hbck可以检测Master、Regionserver内存中的状态以及HDFS上数据的状态之间的一致性问题。并且针对不同的情况，提供了多种的修复方式。

```
[hdfs@hdp ~]$ hbase hbck -help

-details 显示所有region的完整性
-timelag 只检测最近几秒内没有发生元数据更新的region
-summary 输出表和状态的总结信息
-metaonly 只检测hbase:meta表
```
