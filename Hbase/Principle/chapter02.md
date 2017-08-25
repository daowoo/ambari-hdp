# Hbase Shell and Tool
## 文档
* WIKI：https://learnhbase.wordpress.com/2013/03/02/hbase-shell-commands/
* 官网：https://hbase.apache.org/book.html#tools
* 书籍：Hbase实战5.2小节 + 11.1~11.2小节

## 规划
* 期望目标：理解shell命令格式，能使用常用命令，了解各tool的功能和用法
* 内容安排
  * Shell
    * General
    * NAMESPACE
    * DDL
    * DML
    * SURGERY
    * Script
  * Tools
    * hbck
    * hfile
    * snapshot
    * wal
    * zkcli
    * pe
    * canary
  * Drivers
    * RowCounter
    * CellCounter
    * ImportTsv
    * completebulkload
    * import&&export
* 时间安排
  * 2017-8-24 下午17:30 ~ 18:30

## 准备
* 使用本机上搭建好的三节点Hbase集群
* 确保能通过hbase运行参考书中部分命令实例

## 遗留问题
TODO

## 示例
* General
```hbase
status 'summary'
status 'simple'
status 'detailed'

version

table_help

whoami
```

* namespace
```hbase
create_namespace 'ns1', {'hbase.namespace.quota.maxtables'=>'5'}
create_namespace 'ns1', {'hbase.namespace.quota.maxregions'=>'10','myname'=>'phf'}

describe_namespace 'ns1'

alter_namespace 'ns1', {METHOD=>'set','cmp'=>'tttt'}, {METHOD=>'set','myname'=>'ycq'}
alter_namespace 'ns1', {METHOD=>'unset',NAME=>'cmp'}, {METHOD=>'unset',NAME=>'myname'}

drop_namespace 'ns1'

list_namespace
list_namespace '^n'

list_namespace_tables 'ns1'
```

* DDL
```hbase
create 'ns1:t1', {NAME => 'f1', VERSIONS => 3}
create 't1', 'f1', 'f2', 'f3' <=> create 'default:t1', {NAME => 'f1'}, {NAME => 'f2'}, {NAME => 'f3'}
create 'ns1:t1',{NAME=>'f2',VERSIONS=>1,BLOCKCACHE=>true,BLOOMFILTER=>'ROW',TTL=>'259200'},{SPLITS=>['1','2','3','4','5','6','7','8','9','a','b','c','d','e','f']}
create 'ns1:t1', {NAME => 'f1', CONFIGURATION => {'hbase.hstore.blockingStoreFiles' => '10'}}, METADATA => { 'mykey' => 'myvalue' }

describe 'ns1:t1'

list '^ns.*'
list '.*2$'

alter 'ns1:t1', NAME => 'f1', VERSIONS => 5
alter 'ns1:t1', 'f1', {NAME => 'f2', IN_MEMORY => true}, {NAME => 'f3', VERSIONS => 5}
alter 'ns1:t1', NAME => 'f1', METHOD => 'delete' <=> alter 'ns1:t1', 'delete' => 'f1'
alter 't1', { NAME => 'f1', VERSIONS => 3 },{ MAX_FILESIZE => '134217728' }, { METHOD => 'delete', NAME => 'f2' },OWNER => 'johndoe', METADATA => { 'mykey' => 'myvalue' }

alter_async 'ns1:t1', NAME => 'f1', VERSIONS => 5

disable 'ns1:t1'
is_disabled 'ns1:t1'
enable 'ns1:t1'
is_enabled 'ns1:t1'
exists 'ns1:t1'
drop 'ns1:t1'

disable_all '^ns.*'
enable_all '^ns.*'
drop_all '^ns.*'

truncate 'ns1:t1'

get_table 'ns1:t1'
show_filters
```

* DML
```hbase
create 'ns1:t1', {NAME => 'f1', VERSIONS => 5}
put 'ns1:t1', 'r1', 'f1:c1', '1'
put 'ns1:t1', 'r2', 'f1:c1', '2', 1
put 'ns1:t1', 'r3', 'f1:c1', '3', 1, {ATTRIBUTES=>{'mykey'=>'myvalue'}}

incr 'ns1:t1', 'r4', 'f1:c2', {ATTRIBUTES=>{'ccc'=>'1111'}}
incr 'ns1:t1', 'r4', 'f1:c2', 10
incr 'ns1:t1', 'r4', 'f1:c2', -10

get_counter 'ns1:t1', 'r4', 'f1:c2'

get 'ns1:t1', 'r4', 'f1:c2'
get 'ns1:t1', 'r2', {TIMERANGE => [0, 2]}
get 'ns1:t1', 'r3', {COLUMN => 'f1:c1', TIMESTAMP => 1}
get 'ns1:t1', 'r3', {COLUMN => 'f1:c1', TIMERANGE =>[0, 2]}
get 'ns1:t1', 'r3', {COLUMN => 'f1:c1', TIMERANGE =>[0, 2], VERSIONS => 3}

delete 'ns1:t1', 'r2', 'f1:c1',1
deleteall 'ns1:t1', 'r2', 'f1:c1'
deleteall 'ns1:t1', 'r2'

count 'ns1:t1'
count 'ns1:t1', INTERVAL => 2, CACHE => 10

get 'ns1:t1', 'r1', 'f1:c1'
append 'ns1:t1', 'r1', 'f1:c1', '-1'

scan 'hbase:meta'
scan 'ns1:t1', {COLUMNS => ['f1', 'f2']}
scan 'ns1:t1', {COLUMNS => ['f1', 'f2'], LIMIT => 3}
scan 'ns1:t1', {COLUMNS => ['f1', 'f2'], LIMIT => 3, STARTROW => '2'}
scan 'ns1:t1', {COLUMNS => 'f1', TIMERANGE => [1, 3]}
scan 'ns1:t1', {REVERSED => true}
scan 'ns1:t1', {RAW => true, VERSIONS => 10}

scan 't1', {FILTER => "PrefixFilter ('row2') AND
QualifierFilter(>=, 'binary:xyz') AND
TimestampsFilter(123, 456) AND
ValueFilter(=,'regexstring:^\\d2$') AND
ValueFilter(=,'binaryprefix:abc') AND
ValueFilter(!=,'substring:123') AND
DependentColumnFilter('f1','name',true,=,'substring:panhongfa')"}
```

* SURGERY
```hbase
balance_switch false
balance_switch true
balancer_enabled

compact 'ns1:t1'
compact 'ns1:t1', 'f1'
compact 'ns1:t1,,1503559836827.dba72c647184e39817db4f7aeb472239.'

major_compact 'ns1:t1'
major_compact 'ns1:t1', 'f1'
major_compact 'ns1:t1,,1503559836827.dba72c647184e39817db4f7aeb472239.'
major_compact 'ns1:t1,,1503559836827.dba72c647184e39817db4f7aeb472239.', 'f1'

flush 'ns1:t1'
flush 'ns1:t1,,1503559836827.dba72c647184e39817db4f7aeb472239.'

move 'ns1:t1,,1503559836827.dba72c647184e39817db4f7aeb472239.'
move 'ns1:t1,,1503559836827.dba72c647184e39817db4f7aeb472239.','hbase2.panhongfa.com,16020,1503542286488'

split 'ns1:t1'
split 'ns1:t1,,1503559836827.dba72c647184e39817db4f7aeb472239.'

merge_region ‘region1’,’region2’

hlog_roll 'hbase2.panhongfa.com,16020,1503542286488'

zk_dump
```

* Script
```hbase
cat << eof > sample_commands.txt
create 'test', 'cf1'
list 'test'
put 'test', 'row1', 'cf:a', 'value1'
put 'test', 'row2', 'cf:b', 'value2'
put 'test', 'row3', 'cf:c', 'value3'
put 'test', 'row4', 'cf:d', 'value4'
scan 'test'
get 'test', 'row1'
disable 'test'
enable 'test'
eof

hbase shell ./sample_commands.txt

cat << 'eof' > /home/hadoop/Example/create_table.txt
tablename = 'ns1:t1'
disable tablename
drop tablename
tt = create tablename,{NAME=>'info', VERSIONS=>10},{NAME=>'status', VERSIONS=>3},'ext',{SPLITS=>['1','2','3','4','5','6','7','8','9','a','b','c','d','e','f']}

$i = 1
$num = 20
while $i < $num do
rowk = ('%08x' % $i).reverse

id = $i
name = 'phf'
name << ('-%08d' % $i)
age = 180
desc = 'panhongfa.com'
desc << ('-%08d' % $i)

for j in 1..10
tt.put rowk, 'info:id', id, j
tt.put rowk, 'info:name', name + ('-%04d' % j), j
tt.put rowk, 'info:age', age + j, j
tt.put rowk, 'info:desc', desc + ('-%02d' % j), j
end

$i += 1
end
eof

hbase shell /home/hadoop/Example/create_table.txt
```


* Tool
```pe
hbase pe --nomapred --rows=10000 --presplit=6 sequentialWrite 2
hbase pe --nomapred --rows=10000 --presplit=6 randomWrite 2

hbase pe --nomapred --rows=10000 sequentialRead 2
hbase pe --nomapred --rows=10000 randomRead 2
```

```hbck
hbase hbck -details

assign 'ns1:t1,,1503559836827.dba72c647184e39817db4f7aeb472239.'
unassign 'ns1:t1,,1503559836827.dba72c647184e39817db4f7aeb472239.'
close_region 'ns1:t1,,1503559836827.dba72c647184e39817db4f7aeb472239.'

hbase hbck 'ns1:t1'
hbase hbck -fixAssignments
```

```hfile
hbase hfile -v -f hdfs://hbase1.panhongfa.com:9000/hbase/data/default/TestTable/a86a720e5e946f516654460d70b5df24/info/cac61aa054f540838f0b8ec672bee4ce

hbase hfile -s -f hdfs://hbase1.panhongfa.com:9000/hbase/data/default/TestTable/a86a720e5e946f516654460d70b5df24/info/cac61aa054f540838f0b8ec672bee4ce

hbase hfile -p -f hdfs://hbase1.panhongfa.com:9000/hbase/data/default/TestTable/a86a720e5e946f516654460d70b5df24/info/cac61aa054f540838f0b8ec672bee4ce

hbase hfile -e -f hdfs://hbase1.panhongfa.com:9000/hbase/data/default/TestTable/a86a720e5e946f516654460d70b5df24/info/cac61aa054f540838f0b8ec672bee4ce

hbase hfile -m -f /hbase/data/default/TestTable/a86a720e5e946f516654460d70b5df24/info/cac61aa054f540838f0b8ec672bee4ce
```

```wal
hbase hlog -j /hbase/WALs/hbase3.panhongfa.com,16020,1503575974309/hbase3.panhongfa.com%2C16020%2C1503575974309.1503576144883

hbase hlog -j /hbase/WALs/hbase3.panhongfa.com,16020,1503575974309/hbase3.panhongfa.com%2C16020%2C1503575974309.1503576220912 -r 'eee53ad07cf99840d55ae54c1f13416d'
```

```snapshot

```

```canary

```

```clean
hbase clean --cleanZk
hbase clean --cleanHdfs
hbase clean --cleanAll
```

* Drivers
```Counter
hbase org.apache.hadoop.hbase.mapreduce.RowCounter ns1:t1
hbase org.apache.hadoop.hbase.mapreduce.RowCounter TestTable --starttime=1 --endtime=100

hdfs dfs -mkdir /usr/test/cellcount
hbase org.apache.hadoop.hbase.mapreduce.CellCounter TestTable /usr/test/cellcount/tmp1
```

```ImportTsv
cat << eof > /home/hadoop/Example/data1.csv
1,'phf1','panhongfa ss 1'
2,'phf2','panhongfa ss 2'
3,'phf3','panhongfa ss 3'
4,'phf4','panhongfa ss 4'
5,'phf5','panhongfa ss 5'
6,'phf6','panhongfa ss 6'
7,'phf7','panhongfa ss 7'
8,'phf8','panhongfa ss 8'
eof
hdfs dfs -put -f /home/hadoop/Example/data1.csv /usr/test

create 't2', 'f1'
hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.separator="," -Dimporttsv.columns=HBASE_ROW_KEY,f1:c1,f1:c2 t2 /usr/test/data1.csv
```

```CompleteBulkLoad
cat << eof > /home/hadoop/Example/data2.csv
1.'phf1'.'panhongfa ss 1'
2.'phf2'.'panhongfa ss 2'
3.'phf3'.'panhongfa ss 3'
4.'phf4'.'panhongfa ss 4'
5.'phf5'.'panhongfa ss 5'
6.'phf6'.'panhongfa ss 6'
7.'phf7'.'panhongfa ss 7'
8.'phf8'.'panhongfa ss 8'
eof
hdfs dfs -put -f /home/hadoop/Example/data2.csv /usr/test

hdfs dfs -mkdir /usr/test/hfiles
hbase org.apache.hadoop.hbase.mapreduce.ImportTsv -Dimporttsv.separator="." -Dimporttsv.bulk.output=/usr/test/hfiles/tmp1 -Dimporttsv.columns=HBASE_ROW_KEY,f1:c1,f2:c1 t4 /usr/test/data2.csv

hadoop jar /home/hadoop/hbase-1.3.1/lib/hbase-server-1.3.1.jar completebulkload /usr/test/hfiles/tmp1 t4
hbase org.apache.hadoop.hbase.mapreduce.LoadIncrementalHFiles /usr/test/hfiles/tmp1 t4
```

```import&&export
hdfs dfs -mkdir /usr/test/seqfiles
hbase org.apache.hadoop.hbase.mapreduce.Export t4 /usr/test/seqfiles/tmp1

create 't5', 'f1', 'f2'
hbase org.apache.hadoop.hbase.mapreduce.Import t5 /usr/test/seqfiles/tmp1
```
