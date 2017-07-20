# HFile查看工具-hfile

常用参数：
-v 输出详细信息
-p 输出keyvalue中的数据

```
[hdfs@hdp ~]$ hbase hfile -v -p -f hdfs://host1.bigdata.wh.com:8020/apps/hbase/data/data/ns1/t2/aec7958a02eb1db21880366fca94a5b7/f1/e70d1c290b024c18be2aecb6453d6ebf_SeqId_4_
Scanning -> hdfs://host1.bigdata.wh.com:8020/apps/hbase/data/data/ns1/t2/aec7958a02eb1db21880366fca94a5b7/f1/e70d1c290b024c18be2aecb6453d6ebf_SeqId_4_
2017-07-20 14:09:32,762 INFO  [main] hfile.CacheConfig: CacheConfig:disabled
K: r1/f1:c1/1500530303774/Put/vlen=3/seqid=0 V: c11
K: r1/f1:c2/1500530303774/Put/vlen=3/seqid=0 V: c12
K: r2/f1:c1/1500530303774/Put/vlen=3/seqid=0 V: c21
K: r2/f1:c2/1500530303774/Put/vlen=3/seqid=0 V: c22
K: r3/f1:c1/1500530303774/Put/vlen=3/seqid=0 V: c31
K: r3/f1:c2/1500530303774/Put/vlen=3/seqid=0 V: c32
K: r4/f1:c1/1500530303774/Put/vlen=3/seqid=0 V: c41
K: r4/f1:c2/1500530303774/Put/vlen=3/seqid=0 V: c42
K: r5/f1:c1/1500530303774/Put/vlen=3/seqid=0 V: c51
K: r5/f1:c2/1500530303774/Put/vlen=3/seqid=0 V: c52
K: r6/f1:c1/1500530303774/Put/vlen=3/seqid=0 V: c61
K: r6/f1:c2/1500530303774/Put/vlen=3/seqid=0 V: c62
K: r7/f1:c1/1500530303774/Put/vlen=3/seqid=0 V: c71
K: r7/f1:c2/1500530303774/Put/vlen=3/seqid=0 V: c72
K: r8/f1:c1/1500530303774/Put/vlen=3/seqid=0 V: c81
K: r8/f1:c2/1500530303774/Put/vlen=3/seqid=0 V: c82
K: r9/f1:c1/1500530303774/Put/vlen=3/seqid=0 V: c91
K: r9/f1:c2/1500530303774/Put/vlen=3/seqid=0 V: c92

```
