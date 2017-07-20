# WAL日志查看工具-hlog

常用参数：
-p 输出所有内容
-r 指定只查看某个region的内容
-w 指定只查看某行的内容

```
[hdfs@hdp ~]$ hbase hlog hdfs://host1.bigdata.wh.com:8020/apps/hbase/data/WALs/host2.bigdata.wh.com,16020,1500519564686/host2.bigdata.wh.com%2C16020%2C1500519564686.default.1500530505971
Writer Classes: ProtobufLogWriter
Cell Codec Class: org.apache.hadoop.hbase.regionserver.wal.WALCellCodec
Sequence=5 , region=aec7958a02eb1db21880366fca94a5b7 at write timestamp=Thu Jul 20 14:05:07 CST 2017
row=\x00, column=METAFAMILY:HBASE::BULK_LOAD

[hdfs@hdp ~]$ hbase hlog -j hdfs://host1.bigdata.wh.com:8020/apps/hbase/data/WALs/host2.bigdata.wh.com,16020,1500519564686/host2.bigdata.wh.com%2C16020%2C1500519564686.default.1500530505971
[Writer Classes: ProtobufLogWriter
Cell Codec Class: org.apache.hadoop.hbase.regionserver.wal.WALCellCodec
{"sequence":5,"region":"aec7958a02eb1db21880366fca94a5b7","actions":[{"vlen":103,"row":"\\x00","family":"METAFAMILY","qualifier":"HBASE::BULK_LOAD","timestamp":1500530707966}],"table":{"name":"bnMxOnQy","nameAsString":"ns1:t2","namespace":"bnMx","namespaceAsString":"ns1","qualifier":"dDI=","qualifierAsString":"t2","systemTable":false,"nameWithNamespaceInclAsString":"ns1:t2","rowComparator":{"legacyKeyComparatorName":"org.apache.hadoop.hbase.KeyValue$KeyComparator"}}}]
```
