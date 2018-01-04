# Zookeeper

## 功能
存储&&读取用户程序提交的数据（类似namenode中存放的metadata）
为用户程序提供数据节点监听服务

## 特性
一个leader，多个follower组成的集群
全局数据一致（每个server保存一份相同的数据副本，client无论连接到哪个server，数据都是一致的）
分布式读写，更新请求转发，由leader实施
更新请求顺序进行，来自同一个client的更新请求按其发送顺序依次执行
数据更新原子性，一次数据更新要么成功，要么失败
实时性，在一定时间范围内，client能读到最新数据

## 数据结构
 - 层次化的目录结构，命名符合常规文件系统规范(类似文件系统）
 - 每个节点在zookeeper中叫做znode,并且其有一个唯一的路径标识
 - 节点Znode可以包含数据和子节点（但是EPHEMERAL类型的节点不能有子节点）
   - Znode有两种类型，短暂（ephemeral）和持久（persistent）断开连接后zk删除ephemeral类型节点，不删除persistent类型节点
   - Znode有四种形式的目录节点，PERSISTENT、PERSISTENT_SEQUENTIAL、EPHEMERAL、EPHEMERAL_SEQUENTIAL
   - 创建znode时设置顺序标识，znode名称后会附加一个值，顺序号是一个单调递增的计数器，由父节点维护
   - 在分布式系统中，顺序号可以被用于为所有的事件进行全局排序，这样客户端可以通过顺序号推断事件的顺序

 - 客户端应用可以在节点上设置监视器
   - 监听数据变化
   - 监听节点及子节点变化

 ## 工作过程
 - 在HMaster和HRegionServer连接到ZooKeeper后创建Ephemeral节点，并使用Heartbeat机制维持这个节点的存活状态，如果某个Ephemeral节点失效，则HMaster会收到通知，并做相应的处理。

- HMaster通过监听ZooKeeper中的Ephemeral节点(默认：/hbase/rs/*)来监控HRegionServer的加入和宕机。

- 在第一个HMaster连接到ZooKeeper时会创建Ephemeral节点(默认：/hbasae/master)来表示Active的HMaster，其后加进来的HMaster则监听该Ephemeral节点，如果当前Active的HMaster宕机，则该节点消失，因而其他HMaster得到通知，而将自身转换成Active的HMaster，在变为Active的HMaster之前，它会创建在/hbase/back-masters/下创建自己的Ephemeral节点。
