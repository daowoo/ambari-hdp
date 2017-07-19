# Hbase Shell

## General

### status

输出集群当前的状态。

```
  hbase(main):032:0> status
  1 active master, 0 backup masters, 3 servers, 0 dead, 3.6667 average load

  hbase(main):001:0> help 'status'
  Show cluster status. Can be 'summary', 'simple', 'detailed', or 'replication'. The
  default is 'summary'. Examples:

    hbase> status
    hbase> status 'simple'        #以简明形式返回
    hbase> status 'summary'       #以摘要形式返回 （默认）
    hbase> status 'detailed'      #以详细形式返回
    hbase> status 'replication'   #输出主从Hbase集群之间的副本状态
    hbase> status 'replication', 'source' 
    hbase> status 'replication', 'sink'
```

### version

输出Hbase的当前版本。

```
  hbase(main):033:0> version
  1.1.2.2.6.1.0-129, r718c773662346de98a8ce6fd3b5f64e279cb87d4, Wed May 31 03:27:31 UTC 2017
```

### whoami

输出当前的Hbase用户和用户组。

```
  hbase(main):037:0> whoami
  root (auth:SIMPLE)
    groups: root
```

## NAMESPACE

### create\_namespace

创建命名空间。

```
# 创建命名空间ns1
hbase(main):008:0> create_namespace 'ns1'
0 row(s) in 0.3720 seconds

# 创建命名空间ns1, 并且配置自定义属性'cmp'='daowoo'
hbase(main):010:0> create_namespace 'ns2',{'cmp'=>'daowoo'}
0 row(s) in 0.0410 seconds
```

### describe\_namespace

查询命名空间Schema。

```
hbase(main):013:0> describe_namespace 'ns2'
DESCRIPTION                                                                                                                                                                                  
{NAME => 'ns2', cmp => 'daowoo'}                                                                                                                                                             
1 row(s) in 0.0070 seconds
```

### alter\_namespace

修改，添加，删除命名空间的属性。

```
# 设置命名空间ns2的属性
hbase(main):015:0> alter_namespace 'ns2', {METHOD=>'set','name'=>'testing'}
0 row(s) in 0.0630 seconds

# 删除命名空间ns2的属性
hbase(main):021:0> alter_namespace 'ns2', {METHOD=>'unset',NAME=>'name',NAME=>'cmp'}
0 row(s) in 0.0930 seconds
```

### drop\_namespace

删除命名空间，命名空间必须为空，即其中不包含任何表。

```
hbase(main):025:0> drop_namespace 'default'

ERROR: org.apache.hadoop.hbase.constraint.ConstraintException: Reserved namespace default cannot be removed.
Here is some help for this command:
Drop the named namespace. The namespace must be empty.
```

### list\_namespace

列出所有命名空间。

```
hbase(main):023:0> list_namespace
NAMESPACE                                                                                                                                                                                    
default                                                                                                                                                                                      
hbase                                                                                                                                                                                        
ns1                                                                                                                                                                                          
ns2                                                                                                                                                                                          
4 row(s) in 0.0510 seconds
```

### list\_namespace\_tables

列出指定命名空间下的所有表。

```
hbase(main):026:0> list_namespace_tables 'default'
TABLE                                                                                                                                                                                        
t1                                                                                                                                                                                           
t2                                                                                                                                                                                           
t3                                                                                                                                                                                           
test                                                                                                                                                                                         
test1                                                                                                                                                                                        
5 row(s) in 0.0260 seconds
```

## DDL

### create

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

### describe / desc

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

### list

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

### alter

修改，增加，删除表的列族信息、属性、配置等。

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

### alter\_async

异步的修改表结构，不用等待该表所有的regions都接收到shecma的变更请求，与alter的作用相同。

```
hbase(main):024:0> alter_async 't1', METHOD => 'table_att_unset', NAME => 'MAX_FILESIZE'
```

### disable

关闭指定的表，其后必须附带表名参数。

```
hbase(main):046:0> disable 'test1'
0 row(s) in 2.2900 seconds
```

### disable\_all

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

### is\_disabled

判断指定的表是否处于关闭状态。

```
hbase(main):028:0> is_disabled 'test'
true                                                                                                                                                                                         
0 row(s) in 0.0230 seconds
```

### drop

删除指定的表，删除之前必须先关闭该表。

```
hbase(main):029:0> drop 't3'

ERROR: Table t3 is enabled. Disable it first.

Here is some help for this command:
Drop the named table. Table must first be disabled:
  hbase> drop 't1'
  hbase> drop 'ns1:t1'
```

### drop\_all

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

### enable

与disble相反，打开指定的表，其后也必须附带表名参数。

```
hbase(main):047:0> enable 'test1'
0 row(s) in 2.2890 seconds
```

### enable\_all

打开满足正则表达式条件的所有表。

```
hbase(main):031:0> enable_all 'test.*'
test                                                                                                                                                                                         
test1                                                                                                                                                                                        

Enable the above 2 tables (y/n)?
y
2 tables successfully enabled
```

### is\_enabled

判断指定的表是否处于打开状态。

```
hbase(main):040:0> is_enabled 'test1'
true                                                                                                                                                                                         
0 row(s) in 0.0150 seconds
```

### exists

判断指定的表是否实际存在。

```
hbase(main):009:0> exists 'music'
Table music does not exist
0 row(s) in 0.0250 seconds

hbase(main):010:0> exists 'test'
Table test does exist
0 row(s) in 0.0120 seconds
```

### get\_table

返回一个表的引用对象。

```
# 将表t1的应用对象赋给tt
hbase(main):009:0> tt= get_table 't1'

#tt可直接进行如下操作
t1d.scan
t1d.describe
...
```

### show\_filters

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

### alter\_statu

返回alter命令的执行状态，指示在alter操作过程中表的regions中有那些region接收到了更新。

```
hbase(main):037:0> alter_status 't1'
1/1 regions updated.
Done.

hbase(main):038:0> alter_status 't2'
1/1 regions updated.
Done.
```

## DML

### scan

扫描某一个表，显示出满足条件的所有数据。

```
# 扫描命名空间hbase下的meta表，显示出meta表的所有数据
hbase> scan 'hbase:meta'

# 扫描命名空间hbase下的meta表的列族info的列regioninfo，显示出meta表的列族info下的regioninfo列的所有数据
hbase> scan 'hbase:meta', {COLUMNS => 'info:regioninfo'}

# 扫描命名空间ns1下表t1的列族'c1'和'c2'。显示出命名空间ns1下表t1的列族'c1'和'c2'的所有数据
hbase> scan 'ns1:t1', {COLUMNS => ['c1', 'c2']}

# 扫描命名空间ns1下表t1的列族'c1'和'c2'。显示出命名空间ns1下表t1的列族'c1'和'c2'，且只显示前10个rowkey的数据。
hbase> scan 'ns1:t1', {COLUMNS => ['c1', 'c2'], LIMIT => 10}

# 扫描命名空间ns1下表t1的列族'c1'和'c2'。显示出命名空间ns1下表t1的列族'c1'和'c2'，且只显示从rowkey=“xyz”开始的前10个rowkey的数据。
hbase> scan 'ns1:t1', {COLUMNS => ['c1', 'c2'], LIMIT => 10, STARTROW => 'xyz'} 

# 扫描默认命名空间下表t1的列族c1时间戳从'1303668804'到'1303668904'的数据
hbase> scan 't1', {COLUMNS => 'c1', TIMERANGE => [1303668804, 1303668904]}

# 反向显示表t1的数据
hbase> scan 't1', {REVERSED => true}

# 过滤显示表t1的数据
hbase> scan 't1', {FILTER => "(PrefixFilter ('row2') AND
    (QualifierFilter (>=, 'binary:xyz'))) AND (TimestampsFilter ( 123, 456))"}

# RAW为true，显示出表t1的所有数据，包括已经删除的
hbase> scan 't1', {RAW => true, VERSIONS => 10}

# 表t1的引用的扫描
hbase> t11 = get_table 't1'
hbase> t11.scan
```

### append

在表的Cell的值后面追加字符串。

```
# 向表t1的rowkey为r1的列c1的值后面添加字符串value
hbase> append 't1', 'r1', 'c1', 'value'

#表t1的引用对象t11使用append。
hbase> t11.append 'r1', 'c1', 'value'
```

### count

统计表的行数，其中参数的含义如下：INTERVAL设置多少行显示一次及对应的rowkey，默认1000；CACHE每次去取的缓存区大小，默认是10，调整该参可提高查询速度。

```
#统计表t1的行数
count 't1'

#查询表t1中的行数，每10条显示一次，缓存区为1000
count 't1', INTERVAL => 10, CACHE => 1000

#对应表的引用对象的用法
hbase> t.count
hbase> t.count INTERVAL => 100000
hbase> t.count CACHE => 1000
hbase> t.count INTERVAL => 10, CACHE => 1000
```

### delete

删除表中cell数据。

```
#删除命名空间ns1下的表t1的rowkey的r1的列c1，时间戳为ts1 
hbase> delete 'ns1:t1', 'r1', 'c1', ts1

#删除默认命名空间下的表t1的rowkey的r1的列c1，时间戳为ts1 
hbase> delete 't1', 'r1', 'c1', ts1

#引用对象的用法
hbase> t.delete 'r1', 'c1',  ts1
```

### deleteall

一次性删除多个cell数据。

```
#删除命名空间ns1下表t1的rowkey为r1的所有数据
hbase> deleteall 'ns1:t1', 'r1'

#删除默认命名空间下表t1的rowkey为r1的所有数据
hbase> deleteall 't1', 'r1'

#删除命名空间ns1下表t1的rowkey为r1的列c1的所有数据
hbase> deleteall 't1', 'r1', 'c1'

# 删除默认命名空间下的表t1的rowkey的r1的列c1，时间戳为ts1 
hbase> deleteall 't1', 'r1', 'c1', ts1

#引用对象的用法
hbase> t.deleteall 'r1'
hbase> t.deleteall 'r1', 'c1'
hbase> t.deleteall 'r1', 'c1', ts1
```

### get

得到某一列或cell的数据。

```
#得到命名空间ns1下表t1的rowkey为r1的数据
hbase> get 'ns1:t1', 'r1'

#得到默认命名空间下表t1的rowkey为r1的数据
hbase> get 't1', 'r1'

#得到默认命名空间下表t1的rowkey为r1，时间戳范围在ts1和ts2之间的数据
hbase> get 't1', 'r1', {TIMERANGE => [ts1, ts2]}

#得到默认命名空间下表t1的rowkey为r1的c1列的数据
hbase> get 't1', 'r1', {COLUMN => 'c1'}

#得到默认命名空间下表t1的rowkey为r1的c1,c2,c3列的数据
hbase> get 't1', 'r1', {COLUMN => ['c1', 'c2', 'c3']}

#得到默认命名空间下表t1的rowkey为r1的c1列，时间戳为ts1的数据
hbase> get 't1', 'r1', {COLUMN => 'c1', TIMESTAMP => ts1}

#得到默认命名空间下表t1的rowkey为r1的c1列，时间戳范围为ts1到ts2，版本数为4的数据
hbase> get 't1', 'r1', {COLUMN => 'c1', TIMERANGE => [ts1, ts2], VERSIONS => 4}

#应用对象的用法
hbase> t.get 'r1'
hbase> t.get 'r1', {TIMERANGE => [ts1, ts2]}
hbase> t.get 'r1', {COLUMN => 'c1'}
hbase> t.get 'r1', {COLUMN => ['c1', 'c2', 'c3']}
hbase> t.get 'r1', {COLUMN => 'c1', TIMESTAMP => ts1}
hbase> t.get 'r1', {COLUMN => 'c1', TIMERANGE => [ts1, ts2], VERSIONS => 4}
hbase> t.get 'r1', {COLUMN => 'c1', TIMESTAMP => ts1, VERSIONS => 4}
```

### put

往Cell中添加数据。

```
#向命名空间ns1下表t1的rowkey为r1的列c1添加数据
hbase> put 'ns1:t1', 'r1', 'c1', 'value'

#向默认命名空间下表t1的rowkey为r1的列c1添加数据
hbase> put 't1', 'r1', 'c1', 'value'

#向默认命名空间下表t1的rowkey为r1的列c1添加数据，并设置时间戳为ts1
hbase> put 't1', 'r1', 'c1', 'value', ts1

#向默认命名空间下表t1的rowkey为r1的列c1添加数据，并设置时间戳为ts1，并设置属性
hbase> put 't1', 'r1', 'c1', 'value', ts1, {ATTRIBUTES=>{'mykey'=>'myvalue'}}

#引用对象的用法
t.put 'r1', 'c1', 'value', ts1, {ATTRIBUTES=>{'mykey'=>'myvalue'}}
```

### truncate

强制删除表，不要求表已经disable。

```
hbase(main):041:0> truncate 't1'
Truncating 't1' table (it may take a while):
 - Disabling table...
 - Truncating table...
0 row(s) in 3.9850 seconds
```

### get\_counter

```

```

### incr

```

```

## SURGERY

### assign

```

```

### unassign

```

```

### balancer

```

```

### balance\_switch

```

```

### close\_region

```

```

### compact

```

```

### flush

```

```

### major\_compact

```

```

### move

```

```

### split

```

```

### hlog\_roll

```

```

### zk\_dump

```

```

## REPLICATION

### add\_peer

```

```

### remove\_peer

```

```

### list\_peers

```

```

### enable\_peer

```

```

### disable\_peer

```

```

### start\_replication

```

```

### stop\_replication

```

```

## SECURITY

### grant

```

```

### revoke

```

```

### user\_permission

```

```



