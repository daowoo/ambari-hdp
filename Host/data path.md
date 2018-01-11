# IDC机房现存的数据目录

## 社保数据
市场提供的长沙社保数据总大小为`93Gb`,其内容均是从不同的数据表中导出的csv格式的数据文件，每个表存储位一个单独的文件，文件比较大。

* 本地数据保存在IDC机房的`gw.daowoo.com`主机的`/home/panhongfa/shebao_data`目录内。
```sh
[root@gw panhongfa]# pwd
/home/panhongfa
[root@gw panhongfa]# du -h
119M	./shebao_data/kc22_error
93G	./shebao_data
20K	./.beeline
93G	.
```


* 平台数据存储在HDFS文件系统的`/group/bigdata/generatedata`目录内
```sh
[hdfs@gw ~]$ hdfs dfs -ls /group/bigdata/shebao_data
Found 9 items
drwx------   - panhongfa hdfs           0 2017-11-13 16:53 /group/bigdata/shebao_data/kc22_error
-rw-------   3 panhongfa hdfs 10140221508 2017-11-13 16:55 /group/bigdata/shebao_data/kc22_table_2016_1.csv
-rw-------   3 panhongfa hdfs  8004279835 2017-11-13 17:02 /group/bigdata/shebao_data/kc22_table_2016_2.csv
-rw-------   3 panhongfa hdfs 14144182419 2017-11-13 17:15 /group/bigdata/shebao_data/kc22_table_2016_3.csv
-rw-------   3 panhongfa hdfs 13720527035 2017-11-13 17:26 /group/bigdata/shebao_data/kc22_table_2016_4.csv
-rw-------   3 panhongfa hdfs 13802676846 2017-11-13 17:38 /group/bigdata/shebao_data/kc22_table_2016_5.csv
-rw-------   3 panhongfa hdfs 12921392464 2017-11-13 17:50 /group/bigdata/shebao_data/kc22_table_2016_6.csv
-rw-------   3 panhongfa hdfs 13066350266 2017-11-13 18:04 /group/bigdata/shebao_data/kc22_table_2017_1.csv
-rw-------   3 panhongfa hdfs 13136113034 2017-11-13 18:15 /group/bigdata/shebao_data/kc22_table_2017_2.csv
```

## 热点数据
根据热点融合项目需要通过`generatedata`自定义生成的模拟数据总大小为`119m`，总体上分为两部分：即车辆数据`car`和手机号码数据`tel`，它们均以日期为单位存储在不同的文件中。

* 本地数据保存在IDC机房的`gw.daowoo.com`主机的`/home/panhongfa`目录内。
```sh
[root@gw panhongfa]# pwd
/home/panhongfa
[root@gw panhongfa]# du -h
4.0K	./.oracle_jre_usage
48M	./generatedata/car
55M	./generatedata/tel
102M	./generatedata

```

* 平台数据存储在HDFS文件系统的`/group/bigdata/generatedata`目录内
```sh
[hdfs@gw ~]$ hdfs dfs -ls /group/bigdata/generatedata
Found 3 items
drwx------   - panhongfa hdfs          0 2017-11-13 16:13 /group/bigdata/generatedata/car
-rw-------   3 panhongfa hdfs        118 2017-11-13 16:13 /group/bigdata/generatedata/compart.bat
drwx------   - panhongfa hdfs          0 2017-11-13 16:13 /group/bigdata/generatedata/tel
```
