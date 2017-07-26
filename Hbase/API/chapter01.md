# Filter

Hbase中两种主要的数据读取函数是get()和scan()，我们可以通过指定起/止行键，指定列族、列、时间戳以及版本号来限定查询得到数据量,但是这些方法缺少一些细粒度的筛选功能，比如基于正则表达式对行键或值进行筛选。

## Filter特性

* 对行键、列名、列值进行更细粒度的筛选和过滤
* 所有的过滤器都在服务端生效，减少服务端往客户端的数据传输量

## Filter实现

* 底层是Filter接口和FilterBase抽象类，由它们实现`Filter`的空壳和骨架
* `Filter`实体直接或间接继承自FilterBase
* 定义`Filter`实例后传递给Get或Scan实例，即: Get.setFilter(filter)
* `Filter`实例化时，需要提供一些参数来设定它的用途

### CompareFilter

特殊的`Filter`，它需要同时提供至少两个特定的参数，这两个参数会被基类用于执行它的任务。

* 比较运算符，compare()由该参数来确定如何进行比较
  * LESS，匹配小于设定值的值
  * LESS_OR_EQUAL，匹配小于或等于设定值的值
  * EQUAL，匹配等于设定值的值
  * NOT_EQUAL，匹配不等于设定值的值
  * GREATER_OR_EQUAL，匹配大于或等于设定值的值
  * GREATER，匹配大于设定值的值
  * NO_OP，排除一切值

* 比较器，都继承自WritableByteArrayComparable，提供了多种方法来比较不同的键值
  * BinaryComparator，使用二进制方式比较当前值与阈值
  * BinaryPrefixCompatator，使用二进制方式由左端开始的前缀匹配
  * NullCompatator，只判断当前值是否为NULL
  * BitCompatator，通过BitwiseOp类提供的按位与、或、异或操作来进行二进制位级比较
  * RegexStringCompatator，根据一个正则表达式去匹配表中的数据
  * SubStringCompatator，把阈值和表中数据当作String实例，然后通过contains()操作匹配字符串

## Filter分类
### Comparison Filter

创建比较过滤器实例时需要一个比较运算符和一个比较器实例，每个比较过滤器的构造方法都有一个从CompareFilter继承来的签名方法：
```java
CompareFilter(CompareOp valueCompareOP, WritableByteArraryComparable valueComparator)
```

需要注意的是，Hbase中过滤器本来的目的是为了在服务端筛除掉无用的信息，被过滤掉的信息不会被传送到客户端，但是所有基于CompareFilter的过滤器处理过程却刚好相反，它们都是从服务端返回匹配的值。

* RowFilter

行过滤器基于行键来过滤数据，可以使用多种比较运算符来返回符合条件的行键，同时会过滤掉不符合条件的行键。

```java
Scan scan = new Scan();
scan.addColumn(Bytes.toBytes("colfam1"),Bytes.toBytes("col-1"));

# 以二进制方式比较，在table中匹配行键小于或等于'row-22'的行，并返回给客户端
Filter filter1 = new RowFilter(CompareFilter.CompareOp.LESS_OR_EQUAL, new BinaryComparator(Bytes.toBytes("row-22")));
scan.setFilter(filter1);
ResultScanner scanner1 = table.getScanner(scan);

# 以正则表达式方式比较，在table中匹配行键的字符串满足'row-05'、'row-15'等后缀只有2位数字并以5结尾的行，并返回给客户端
Filter filter2 = new RowFilter(CompareFilter.CompareOp.EQUAL, new RegexStringComparator(".*-.5"));
scan.setFilter(filter2);
ResultScanner scanner2 = table.getScanner(scan);

# 以字符串包含子串方式比较，在table中匹配行键的字符串满足包含子串'-5'的行，并返回给客户端
Filter filter3 = new RowFilter(CompareFilter.CompareOp.EQUAL, new SubStringComparator("-5"));
scan.setFilter(filter3);
ResultScanner scanner3 = table.getScanner(scan);
```

* FamilyFilter

列族过滤器基于列族来过滤数据，与行键过滤器类似，可以在列族一级筛选所需的数据。

```java
Filter filter1 = new FamilyFilter(CompareFilter.CompareOp.LESS, )
```
