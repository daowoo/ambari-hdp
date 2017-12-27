# Second NameNode的功能
在Hadoop中，有一些命名模块不那么尽人意，Secondary NameNode就是一个典型的例子之一。从它的名字上看，它给人的感觉就像是NameNode的备份节点，但实际上却不是。很多Hadoop的入门者都很疑惑，Secondary NameNode究竟在其中起什么作用，它在HDFS中所扮演的角色是什么。在深入了解Secondary NameNode之前，我们先来看看NameNode是做什么的。

## NameNode如何工作
NameNode主要是用来保存HDFS的元数据信息，比如命名空间信息，块信息等等。当它运行的时候，这些信息是存在内存中的。但是这些信息也可以持久化到磁盘上。如下图所示：
![](img\namenode01.png)

上图展示来NameNode怎么把元数据保存到磁盘上，这里有两个不同的文件：
* fsimage：它是NameNode启动时对整个文件系统的快照，注意，它不一定是最新的。
* edits：它是在NameNode启动后，对文件系统的改动序列。

## 存在哪些问题
只有在NameNode重启时，edits才会合并到fsimage文件中，从而得到一个文件系统的最新快照。但是在生产环境集群中的NameNode是很少重启的，这意味者当NameNode运行来很长时间后，edits文件会变的很大。在这种情况下就会出现下面这些问题：
* edits文件会变的很大，如何去管理这个文件。
* NameNode的重启会花费很长的时间，因为有很多改动要合并到fsimage文件上。
* 如果NameNode宕掉了，那我们就丢失了很多改动，因为此时的edits可能还有部分改动在内存中，没有进行持久化。

因此为了克服这个问题，我们需要一个易于管理的机制来帮助我们减小edits文件的大小和得到一个最新的fsimage文件，这样也会减小在NameNode上的压力。这跟Windows的恢复点是非常像的，Windows的恢复点机制允许我们对OS进行快照，这样当系统发生问题时，我们能够回滚到最新的一次恢复点上。

## 引入Second NameNode
Secondary NameNode就是为了帮助解决上述问题提出的，它的职责是合并NameNode的edits到fsimage文件中，其工作原理如图所示：
![](img\second-namenode01.png)

* 首先，它定时到NameNode去获取edits，并更新到fsimage上。
* 一旦它有新的fsimage文件，它将其拷贝回NameNode上。
* NameNode在下次重启时回使用这个新的fsimage文件，从而减少重启的时间。

Secondary NameNode的整个目的在HDFS中提供一个Checkpoint Node，它只是NameNode的一个助手节点，通过设置一个Checkpoint来帮助NameNode更好的工作；它不是取代NameNode，也不是NameNode的备份。

## 如何进行配置
Secondary NameNode的检查点进程启动，是由两个配置参数控制的：
* fs.checkpoint.period，指定连续两次检查点的最大时间间隔， 默认值是1小时。
* fs.checkpoint.size定义了edits日志文件的最大值，一旦超过这个值会导致强制执行检查点（即使没到检查点的最大时间间隔）。默认值是64MB。

如果NameNode上除了最新的检查点以外，所有的其他的历史镜像和edits文件都丢失了， NameNode可以引入这个最新的检查点。以下操作可以实现这个功能：
* 在配置参数dfs.name.dir指定的位置建立一个空文件夹；
* 把检查点目录的位置赋值给配置参数fs.checkpoint.dir；
* 启动NameNode，并加上-importCheckpoint。

NameNode会从fs.checkpoint.dir目录读取检查点，并把它保存在dfs.name.dir目录下。如果dfs.name.dir目录下有合法的镜像文件，NameNode会启动失败。 NameNode会检查fs.checkpoint.dir目录下镜像文件的一致性，但是不会去改动它。

NameNode什么时候将改动写到edits实际上是由DataNode的写操作触发的，当我们往DataNode写文件时，DataNode会跟NameNode通信，告诉NameNode什么文件的第几个block放在它那里，NameNode这个时候会将这些元数据信息写到edits文件中。
