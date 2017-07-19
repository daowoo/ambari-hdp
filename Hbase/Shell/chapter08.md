# Command Script
将HBase Shell命令输入到文本文件中，每行一个命令，并将该文件传递给HBase Shell来执行。

## 创建script

```
create 'test', 'cf'
list 'test'
put 'test', 'row1', 'cf:a', 'value1'
put 'test', 'row2', 'cf:b', 'value2'
put 'test', 'row3', 'cf:c', 'value3'
put 'test', 'row4', 'cf:d', 'value4'
scan 'test'
get 'test', 'row1'
disable 'test'
enable 'test'
```

## 执行script
将script的路径作为hbase shell命令的唯一参数。 执行每个命令并显示其输出。 如果脚本中包含exit命令，则返回到HBase shell提示符。

```
$ ./hbase shell ./sample_commands.txt
0 row(s) in 3.4170 seconds

TABLE
test
1 row(s) in 0.0590 seconds

0 row(s) in 0.1540 seconds

0 row(s) in 0.0080 seconds

0 row(s) in 0.0060 seconds

0 row(s) in 0.0060 seconds

ROW                   COLUMN+CELL
 row1                 column=cf:a, timestamp=1407130286968, value=value1
 row2                 column=cf:b, timestamp=1407130286997, value=value2
 row3                 column=cf:c, timestamp=1407130287007, value=value3
 row4                 column=cf:d, timestamp=1407130287015, value=value4
4 row(s) in 0.0420 seconds

COLUMN                CELL
 cf:a                 timestamp=1407130286968, value=value1
1 row(s) in 0.0110 seconds

0 row(s) in 1.5630 seconds

0 row(s) in 0.4360 seconds
```

## 使用引用变量
引入了将表分配给Jruby(java的ruby解析器)变量的功能，表引用变量可以用于执行数据读写等操作。

```
hbase(main):001:0> tables = list('t.*')
TABLE                                                                                                                                        
t1                                                                                                                                           
t2                                                                                                                                           
t3                                                                                                                                           
test                                                                                                                                         
test1                                                                                                                                        
5 row(s) in 0.4110 seconds

=> ["t1", "t2", "t3", "test", "test1"]
hbase(main):002:0> tables.map { |t| disable t ; drop  t}
0 row(s) in 2.5130 seconds

0 row(s) in 1.2980 seconds

0 row(s) in 2.3090 seconds

0 row(s) in 1.3250 seconds

0 row(s) in 4.3000 seconds

0 row(s) in 1.2660 seconds

0 row(s) in 2.2600 seconds

0 row(s) in 1.2540 seconds

0 row(s) in 2.2910 seconds

0 row(s) in 2.2660 seconds

=> [nil, nil, nil, nil, nil]
```
