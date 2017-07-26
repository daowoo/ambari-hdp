# 配置

hbase的所有配置文件都位于节点主机的`conf/`目录下，需要注意的是每个节点的配置文件需要保持同步，更改后需手动拷贝到所有的Master和Regionserver。

```
[root@dn001 conf]# pwd
/etc/hbase/conf
[root@dn001 conf]# ll -al
total 44
drwxr-xr-x 2 hbase hadoop 4096 Jul 19 14:07 .
drwxr-xr-x 3 root  root     14 Jul 19 14:07 ..
-rw-r--r-- 1 hbase root   2732 Jul 19 14:23 hadoop-metrics2-hbase.properties
-rw-r--r-- 1 root  root   4537 May 31 11:17 hbase-env.cmd
-rw-r--r-- 1 hbase hadoop 3083 Jul 19 14:23 hbase-env.sh
-rw-r--r-- 1 hbase hadoop  367 Jul 19 14:23 hbase-policy.xml
-rw-r--r-- 1 hbase hadoop 5362 Jul 21 10:00 hbase-site.xml
-rw-r--r-- 1 hbase hadoop 4235 Jul 19 14:23 log4j.properties
-rw-r--r-- 1 hbase root     52 Jul 19 14:23 regionservers
```
