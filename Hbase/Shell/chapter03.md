# DDL

## create

创建一个表，其语法一般为`create <table>, {NAME => <family>, VERSIONS => <VERSIONS>...}`

```
 #在命名空间ns1下，创建表t1，其中有一个列族f1，f1的版本数为5
hbase(main):042:0> create 'ns1:t1', {NAME => 'f1', VERSIONS => 5}

 #在默认命名空间下，创建表t1，有三个列族f1,f2,f3
hbase(main):042:0> create 't1', {NAME => 'f1'}, {NAME => 'f2'}, {NAME => 'f3'}
 #等价于
hbase(main):042:0> create 't1', 'f1', 'f2', 'f3'

#创建表t1，列族f1，并设置列族f1的版本数为1，属性TTL为2592000，属性BLOCKCACHE为true
hbase(main):042:0> create 't1', {NAME => 'f1', VERSIONS => 1, TTL => 2592000, BLOCKCACHE => true}

# 创建表t1,列族f1，并设置列族f1的配置hbase.hstore.blockingStoreFiles 为 10
hbase(main):042:0> create 't1', {NAME => 'f1', CONFIGURATION => {'hbase.hstore.blockingStoreFiles' => '10'}}

# 创建表t1，列族f2, 设置各种属性，并完成预分配
hbase(main):042:0> create 't1',{NAME=>'f2',VERSIONS=>1,BLOCKCACHE=>true,BLOOMFILTER=>'ROW',COMPRESSION=>'SNAPPY',TTL=>'259200'},\
{SPLITS=>['1','2','3','4','5','6','7','8','9','a','b','c','d','e','f']}

#创建表时，配置信息放在最末尾
hbase(main):042:0> create 't1', 'f1', SPLITS_FILE => 'splits.txt', OWNER => 'johndoe'
hbase(main):042:0> create 't1', {NAME => 'f1', VERSIONS => 5}, METADATA => { 'mykey' => 'myvalue' }

#指定Pre-splitting的region的块数，和分割函数。
hbase(main):042:0> create 't1', 'f1', {NUMREGIONS => 15, SPLITALGO => 'HexStringSplit'}
hbase(main):042:0> create 't1', 'f1', {NUMREGIONS => 15, SPLITALGO => 'HexStringSplit', REGION_REPLICATION => 2, CONFIGURATION => {'hbase.hregion.scan.loadColumnFamiliesOnDemand' => 'true'}}

#创建表t1，并且设置tt为表t1的引用
hbase(main):042:0> tt = create 't1', 'f1', 'f2', 'f3'

#用另一个表t2的引用去创建一个新表t1，t1表具有t2的所有列族，并且加上f1列族。
hbase(main):042:0> t1 = create 't2', 'f1'
```

## describe / desc
查看表的结构、属性和列族的属性。

```
# 查看默认命名空间'default'下的表test1的结构和属性
hbase(main):013:0> desc 'test1'
Table test1 is ENABLED                                                                                                              
test1                                                                                                                               
COLUMN FAMILIES DESCRIPTION                                                                                                         
{NAME => 'Toutiao', BLOOMFILTER => 'ROW', VERSIONS => '1', IN_MEMORY => 'false', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING 
=> 'NONE', TTL => '259200 SECONDS (3 DAYS)', COMPRESSION => 'SNAPPY', MIN_VERSIONS => '0', BLOCKCACHE => 'true', BLOCKSIZE => '65536
', REPLICATION_SCOPE => '0'}                                                                                                        
1 row(s) in 0.0230 seconds
```

##　list
列出所有表，可选参数通过正则表达式来过滤输出。

```
#显示所有命名空间的所有表
hbase(main):038:0> list

#显示表名以abc开头的表
hbase(main):038:0> list 'abc.*'

#显示命名空间ns1下的表名以abc开头的表
hbase(main):038:0> list 'ns1:abc.*'

#显示命名空间ns1下的所有表
hbase(main):038:0> list 'ns1:.*'
```

## alter
修改，增加，删除表的列族信息、属性、配置等。

```
#对于表t1，如果t1含有f1列族，则将f1列族的版本数设为5.
# 如果t1不含f1列数，则添加f1列族到表t1上，并将f1的版本数设置为5.
hbase(main):014:0> alter 't1', NAME => 'f1', VERSIONS => 5

#添加或修改列族f2和f3，列族f1保持不变
hbase(main):014:0> alter 't1', 'f1', {NAME => 'f2', IN_MEMORY => true}, {NAME => 'f3', VERSIONS => 5}

#删除名空间ns1中的表t1的列族f1的两种方法
hbase(main):014:0> alter 'ns1:t1', NAME => 'f1', METHOD => 'delete'
hbase(main):014:0> alter 'ns1:t1', 'delete' => 'f1'

#比如 `MAX_FILESIZE`,`READONLY`,`MEMSTORE_FLUSHSIZE`, `DEFERRED_LOG_FLUSH`
#等在表范围内生效的属性，此时会覆盖全局配置中的默认属性
#修改表t1的MAX_FILESIZE属性的值。
hbase(main):014:0> alter 't1', MAX_FILESIZE => '134217728'

# 修改表t1或者列族f2的配置
hbase(main):014:0> alter 't1', CONFIGURATION => {'hbase.hregion.scan.loadColumnFamiliesOnDemand' => 'true'}
hbase(main):014:0> alter 't1', {NAME => 'f2', CONFIGURATION => {'hbase.hstore.blockingStoreFiles' => '10'}}

#删除属性
hbase(main):014:0> alter 't1', METHOD => 'table_att_unset', NAME => 'MAX_FILESIZE'

#一次性修改多个属性值
hbase(main):014:0> alter 't1', { NAME => 'f1', VERSIONS => 3 }, 
  { MAX_FILESIZE => '134217728' }, { METHOD => 'delete', NAME => 'f2' },
  OWNER => 'johndoe', METADATA => { 'mykey' => 'myvalue' }
```

## alter_async
异步的修改表结构，不用等待该表所有的regions都接收到shecma的变更请求，与alter的作用相同。

```
hbase(main):024:0> alter_async 't1', METHOD => 'table_att_unset', NAME => 'MAX_FILESIZE'

```

## disable
关闭指定的表，其后必须附带表名参数。

```
hbase(main):046:0> disable 'test1'
0 row(s) in 2.2900 seconds
```

## disable_all
关闭满足正则表达式条件的所有表。

```
# 关闭所有以test开头的表
hbase(main):027:0> disable_all 'test.*'
test                                                                                                                                                                                         
test1                                                                                                                                                                                        

Disable the above 2 tables (y/n)?
y
2 tables successfully disabled
```

## is_disabled
判断指定的表是否处于关闭状态。

```
hbase(main):028:0> is_disabled 'test'
true                                                                                                                                                                                         
0 row(s) in 0.0230 seconds
```

## drop
删除指定的表，删除之前必须先关闭该表。

```
hbase(main):029:0> drop 't3'

ERROR: Table t3 is enabled. Disable it first.

Here is some help for this command:
Drop the named table. Table must first be disabled:
  hbase> drop 't1'
  hbase> drop 'ns1:t1'
```

## drop_all
删除满足正则表达式条件的所有表，这些表都必须处于关闭状态。

```
hbase(main):030:0> drop_all 't.*'
t1                                                                                                                                                                                           
t2                                                                                                                                                                                           
t3                                                                                                                                                                                           
test                                                                                                                                                                                         
test1                                                                                                                                                                                        

Drop the above 5 tables (y/n)?
n
```

## enable
与disble相反，打开指定的表，其后也必须附带表名参数。

```
hbase(main):047:0> enable 'test1'
0 row(s) in 2.2890 seconds
```

## enable_all
打开满足正则表达式条件的所有表。

```
hbase(main):031:0> enable_all 'test.*'
test                                                                                                                                                                                         
test1                                                                                                                                                                                        

Enable the above 2 tables (y/n)?
y
2 tables successfully enabled
```

## is_enabled
判断指定的表是否处于打开状态。

```
hbase(main):040:0> is_enabled 'test1'
true                                                                                                                                                                                         
0 row(s) in 0.0150 seconds
```

## exists
判断指定的表是否实际存在。

```
hbase(main):009:0> exists 'music'
Table music does not exist
0 row(s) in 0.0250 seconds

hbase(main):010:0> exists 'test'
Table test does exist
0 row(s) in 0.0120 seconds
```

## get_table
返回一个表的引用对象。

```
# 将表t1的应用对象赋给tt
hbase(main):009:0> tt= get_table 't1'

#tt可直接进行如下操作
t1d.scan
t1d.describe
...
```

## show_filters
显示所有的过滤器。

```
hbase(main):034:0> show_filters 
DependentColumnFilter   
KeyOnlyFilter   
ColumnCountGetFilter  
SingleColumnValueFilter  
PrefixFilter 
SingleColumnValueExcludeFilter 
FirstKeyOnlyFilter 
ColumnRangeFilter 
TimestampsFilter 
FamilyFilter 
QualifierFilter 
ColumnPrefixFilter 
RowFilter 
MultipleColumnPrefixFilter 
InclusiveStopFilter 
PageFilter 
ValueFilter 
ColumnPaginationFilter
```

## alter_statu
返回alter命令的执行状态，指示在alter操作过程中表的regions中有那些region接收到了更新。

```
hbase(main):037:0> alter_status 't1'
1/1 regions updated.
Done.

hbase(main):038:0> alter_status 't2'
1/1 regions updated.
Done.
```