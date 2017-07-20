# TSV文件数据导入工具-Importtsv

Hbase官方提供了基于Mapreduce的批量数据导入工具`ImportTsv`和`CompleteBulkLoad`，下面就来介绍下ImportTsv的作用和使用方法。

## 作用
通常hbase用户会使用HBase API导入数据，但是如果一次性导入大批量数据，可能占用大量Regionserver资源，影响存储在该Regionserver上其他表的查询。

ImportTsv是Hbase提供的一个命令行工具，可以将存储在HDFS上的自定义分隔符（默认\t）的数据文件，通过一条命令方便的导入到HBase表中，对于大数据量导入非常实用，其中包含两种方式将数据导入到HBase表中：
* 第一种是使用TableOutputformat在reduce中插入数据；
* 第二种是先生成HFile格式的文件，再执行一个叫做CompleteBulkLoad的命令，将文件move到HBase表空间目录下，同时提供给client查询。

## 使用
* 首先需要在HBase中创建好表。

```
hbase(main):002:0> create 'ns1:t2','f1'
0 row(s) in 2.4320 seconds

=> Hbase::Table - ns1:t2

```

* 将tsv或csv文件上传到HDFS文件系统。

```
#需要切换到hdfs用户，否则会有权限问题
[hdfs@hdp ~]$ hdfs dfs -put -f /home/hdfs/edata.* /test
```

* 直接导入tsv文件

```
[root@hdp hdfs]# su hdfs
[hdfs@hdp ~]$ hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.columns=HBASE_ROW_KEY,f1:c1,f1:c2 ns1:t2 /test/edata.tsv
```
注意，HBASE_ROW_KEY可以不在第一列，如果在第二列，则第二列作为row key，例如：Dimporttsv.columns=fc1,HBASE_ROW_KEY,f1:c2。
并且，如果 csv文件中逗号分隔的列的数量比 Dimporttsv.columns= 中定义的列的数量少的话，会从左往右匹配。如果多的话，这条记录将不能被load到hbase表中。

* 先导入tsv文件至Hfile文件，然后再将Hfile导入Hbase

```
#job执行完后会在output目录输出指定的hfile文件
[hdfs@hdp ~]$ hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.bulk.output=/tmp/hfile_tmp -Dimporttsv.columns=HBASE_ROW_KEY,f1:c1,f1:c2 ns1:t2 /test/edata.tsv

#在利用completebulkload导入到hbase中
[hdfs@hdp ~]$ hbase org.apache.hadoop.hbase.mapreduce.LoadIncrementalHFiles /tmp/hfile_tmp ns1:t2
```

* 导入csv格式文件

```
#由参数Dimporttsv.separator来指明分隔字符
[hdfs@hdp ~]$ hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.separator="," -Dimporttsv.columns=HBASE_ROW_KEY,f1:c1,f1:c2 ns1:t2 /test/edata.csv
```
