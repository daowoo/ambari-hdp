# PerformanceEvaluation

PerformanceEvaluation是HBase自带的性能测试工具，该工具提供了顺序读写、随机读写、扫描等性能测试功能。

## sequentialWrite

往default namespace的TestTable表顺序写100000*30行数据，该表预分为30个region,30个客户端/线程并发写。
```
hbase pe --nomapred --rows=100000 --presplit=30 sequentialWrite 30
```

* hbase PE默认使用mapreduce作业进行读写扫描数据，如果使用多线程/客户端并发来代替mapreduce作业，需要加上选项 --nomapred。
* --presplit参数，只有在写数据时使用，读表时使用参数--presplit，会导致之前写的表数据被删除。
* 参数--rows设置每个客户端处理多少行记录。

## randomWrite

采用同样的条件随机写100000*30行数据。
```
hbase pe --nomapred --rows=100000 --presplit=30 randomWrite 30
```

## sequentialRead

与顺序写类似，sequentialRead参数指明有多少个客户端/线程来进行读操作。
```
hbase pe --nomapred --rows=100000 sequentialRead 30
```

## randomRead

```
hbase pe --nomapred --rows=100000 randomRead 30
```

## scan

Hbase读&扫描表数据，会优先读取内存数据，所以在写表操作结束后，可手动对表进行一次flush操作，以此清空内存中memstore数据。

```
# 读取所有行
hbase pe --nomapred --rows=100000 scan  30

# 每次随机读取10行
hbase pe --nomapred --rows=100000 scanRange10 30

# 每次随机读取1000行
hbase pe --nomapred --rows=100000 scanRange1000 30
```
