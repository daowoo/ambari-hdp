# NAMESPACE

## create\_namespace

创建命名空间。

```
# 创建命名空间ns1
hbase(main):008:0> create_namespace 'ns1'
0 row(s) in 0.3720 seconds

# 创建命名空间ns1, 并且配置自定义属性'cmp'='daowoo'
hbase(main):010:0> create_namespace 'ns2',{'cmp'=>'daowoo'}
0 row(s) in 0.0410 seconds
```

## describe\_namespace

查询命名空间Schema。

```
hbase(main):013:0> describe_namespace 'ns2'
DESCRIPTION                                                                                                                                                                                  
{NAME => 'ns2', cmp => 'daowoo'}                                                                                                                                                             
1 row(s) in 0.0070 seconds
```

## alter\_namespace

修改，添加，删除命名空间的属性。

```
# 设置命名空间ns2的属性
hbase(main):015:0> alter_namespace 'ns2', {METHOD=>'set','name'=>'testing'}
0 row(s) in 0.0630 seconds

# 删除命名空间ns2的属性
hbase(main):021:0> alter_namespace 'ns2', {METHOD=>'unset',NAME=>'name',NAME=>'cmp'}
0 row(s) in 0.0930 seconds
```

## drop\_namespace

删除命名空间，命名空间必须为空，即其中不包含任何表。

```
hbase(main):025:0> drop_namespace 'default'

ERROR: org.apache.hadoop.hbase.constraint.ConstraintException: Reserved namespace default cannot be removed.
Here is some help for this command:
Drop the named namespace. The namespace must be empty.
```

## list\_namespace

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

## list\_namespace\_tables

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