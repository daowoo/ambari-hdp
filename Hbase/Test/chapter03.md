# 兼容性
## hadoop与hbase兼容性
* url: http://hbase.apache.org/book.html#basic.prerequisites
* 章节: `4.1. Hadoop`
* 结论：Hadoop-2.7.1+ and HBase-2.0.x

## hbase与zookeeper兼容性
* url: http://hbase.apache.org/book.html#perf.zookeeper
* 章节: `97. ZooKeeper`
* 结论：Hbase1.0.0以后对应ZooKeeper 3.4.x，此后越新越好

## hadoop与hive兼容性
* url: https://hive.apache.org/downloads.html
* 章节：`News`
* 结论：Hive2.2.0 and Hadoop 2.x.y

## hbase与hive兼容性
* url: https://cwiki.apache.org/confluence/display/Hive/HBaseIntegration
* 章节：`Version information`
* 结论：Hive2.x and HBase1.x+

# 搭建环境
## 版本选择
根据以上的兼容性描述，最终选择的版本如下：
|   组件    |  版本  |
| --------- | ------ |
| hadoop    | 2.7.4  |
| hbase     | 2.0.0  |
| hive      | 2.2.0  |
| zookeeper | 3.4.10 |
| java      | jdk8   |

## 系统初始化
