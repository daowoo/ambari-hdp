# DML
## scan
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
hbase> scan 't1', {FILTER => "PrefixFilter ('row2') AND
QualifierFilter(>=, 'binary:xyz') AND
TimestampsFilter(123, 456) AND
ValueFilter(=,'regexstring:^\\d2$') AND
ValueFilter(=,'binaryprefix:abc') AND
ValueFilter(!=,'substring:123') AND
DependentColumnFilter('f1','name',true,=,'substring:panhongfa')"}

# RAW为true，显示出表t1的所有数据，包括已经删除的
hbase> scan 't1', {RAW => true, VERSIONS => 10}

# 表t1的引用的扫描
hbase> t11 = get_table 't1'
hbase> t11.scan
```

tt.scan VERSIONS=>3,FILTER=>"RowFilter(<=,'binary:User00000005') AND SingleColumnValueFilter('f1','name',=,'substring:p')"

## append
在表的Cell的值后面追加字符串。

```
# 向表t1的rowkey为r1的列c1的值后面添加字符串value
hbase> append 't1', 'r1', 'c1', 'value'

#表t1的引用对象t11使用append。
hbase> t11.append 'r1', 'c1', 'value'
```

## count
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

## delete
删除表中cell数据。

```
#删除命名空间ns1下的表t1的rowkey的r1的列c1，时间戳为ts1
hbase> delete 'ns1:t1', 'r1', 'c1', ts1

#删除默认命名空间下的表t1的rowkey的r1的列c1，时间戳为ts1
hbase> delete 't1', 'r1', 'c1', ts1

#引用对象的用法
hbase> t.delete 'r1', 'c1',  ts1
```

## deleteall
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

## get
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

## put
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

## truncate
强制删除表，不要求表已经disable。

```
hbase(main):041:0> truncate 't1'
Truncating 't1' table (it may take a while):
 - Disabling table...
 - Truncating table...
0 row(s) in 3.9850
```

## incr
在表中新增一列作为计数器，或者计数器自增。

```
#在表ns1:t1的f2列族中新增计数器列c2
hbase(main):021:0> tt.incr 'r1','f2:c2'
COUNTER VALUE = 1
0 row(s) in 0.0140 seconds

#默认自增1
hbase(main):021:0> tt.incr 'r1','f2:c2'
COUNTER VALUE = 2
0 row(s) in 0.0140 seconds

#自增10
hbase(main):005:0> tt.incr 'r1','f2:c2', 10
COUNTER VALUE = 12
0 row(s) in 0.0200 seconds

#相当于自减10
hbase(main):006:0> tt.incr 'r1','f2:c2', -10
COUNTER VALUE = 2
0 row(s) in 0.0470 seconds
```

## get_counter
查询表中的计数器列的当前值，它不会触发计数器发生变化。

```
hbase(main):007:0> tt.get_counter 'r1','f2:c2'
COUNTER VALUE = 2
hbase(main):008:0> tt.get_counter 'r1','f2:c2'
COUNTER VALUE = 2
```
