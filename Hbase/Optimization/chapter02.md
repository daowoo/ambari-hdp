# 知识点补充
## tombstone markers
删除cell、column以及column family时，不会立即删除它们，而是记录下删除标记，在进行major compaction时再统一清除。

tombstone根据其作用的范围不同，可以划分成三种类型
* Version delete marker: 删除指定行中某个Cell的指定版本
* Column delete marker: 删除指定行中某个某列的所有版本
* Family delete marker: 删除指定行中的某个列族

## JVM优化
* stop-the-world意味着从应用中停下来并进入到GC执行过程中去，此时除了GC所需的线程外，其他线程都将挂起，直到GC任务结束才继续它们的任务。
* JAVA堆内存越来越大，GC导致的stop-the-world时间变得越来越长。
* 弱分代假设
  * 大多数对象很快就会变得不可达
  * 只有极少数情况会出现旧对象斥候新对象的引用
* VM中物理内存划分
  * young generate,大部分的新创建对象分配在新生代，它们很快就会变得不可达，所以它们被分配在young区，然后消失不再。当对象从新生代移除时，称为minor GC
  * old generate,存活在新生代中但未变为不可达的对象会被复制到老年代，老年代的内存空间比较大，所以old区发生GC的频率比较低。档对象从老年代移除时，称为major GC
* old区的对象需持有young区对象的引用时怎么办？
  * old区内有card table，是一个512字节的数据块，记录着old区持有的young区对象的引用
  * young区执行GC时，搜索此表决定对象是否为GC的目标对象，从而降低遍所有old对象进行检查的代价

## JVM参数
-Xmx8g -Xms8g -Xmn128m
-XX:+UseParNewGC
-XX:+UseConcMarkSweepGC
-XX:CMSInitiatingOccupancyFraction=70
-verbose:gc -XX:+PrintGCDetails -XX+PrintGCTimeStamps -Xloggc:$HBASE+HOME/logs/gc-$(hostname)-hbase.log
