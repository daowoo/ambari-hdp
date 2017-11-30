# RANGER验证

```shell
beeline -u "jdbc:hive2://host1.bigdata.wh.com:2181,host2.bigdata.wh.com:2181,host3.bigdata.wh.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" -n "hdfs" -p "hdfs"
```


项目描述：	基于公司已有的跨域分布式存储WooStor，结合开源的对象存储Swift、Ambry以及K-V数据库Redis、HBase的设计经验，开发适应于海量聊天日志、小图片、小视频等小文件的分布式对象存储，采用数据聚合分块，顺序并行写入，支持随机读。
generatedatageneratedata
责任描述：	索引模块设计和编码，对象存储服务调度引擎编码。



项目描述：	为某省安监局建立安全生产大数据平台，采集省安监局内部的已有业务数据，以及国家安全生产综合信息平台交换数据库、下属地市安监局交换数据库、安委会各成员单位交换数据库中的游离数据，利用数据服务及接口支撑，打通安全生产监管业务的数据流和业务流，建设规范统一的各类安监业务应用系统，对用户和业务系统提供通用的查询、分析、报表、统计等数据服务，并结合具体项目环境和用户需求提供各类业务数据的可视化展现。

责任描述：
对异构数据进行清洗、转换后汇集到大数据平台
抽取结构化数据、非结构化数据进行标准化后分类存储，归集到主题数据仓库;
根据不同应用场景和业务需求，开发和部署各类微服务

在centos7中添加磁盘/调整虚拟磁盘容量而不重启系统方法
```shell
# 查看系统当前磁盘大小
fdisk -l
df -h

# 不重新启动刷新系统总线上的设备
echo "- - -" > /sys/class/scsi_host/host0/scan
echo "- - -" > /sys/class/scsi_host/host1/scan
echo "- - -" > /sys/class/scsi_host/host2/scan

ls /sys/class/scsi_device/

# 这里按照scsi设备号进行必要的修改
echo 1 > /sys/class/scsi_device/1\:0\:0\:0/device/rescan
echo 1 > /sys/class/scsi_device/2\:0\:0\:0/device/rescan
echo 1 > /sys/class/scsi_device/3\:0\:0\:0/device/rescan

# 查看系统是否刷新了磁盘容量
fdisk -l

# 查看对应与磁盘硬件的物理分区pv
[root@dn002 ~]# pvdisplay
  --- Physical volume ---
  PV Name               /dev/sda2
  VG Name               centos
  PV Size               49.51 GiB / not usable 3.00 MiB
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              12674
  Free PE               0
  Allocated PE          12674
  PV UUID               My80UJ-4fSB-FKeN-mQIt-wKdi-TUdN-1Uqz4i

  --- Physical volume ---
  PV Name               /dev/sdb
  VG Name               centos
  PV Size               100.00 GiB / not usable 4.00 MiB
  Allocatable           yes
  PE Size               4.00 MiB
  Total PE              25599
  Free PE               10
  Allocated PE          25589
  PV UUID               wzw3cz-eODB-rNGB-hoJH-1lvP-KsJ0-xc1WFG

# 虚拟机扩大了磁盘/dev/sdb的容量为400G，首先要刷新该pv
[root@dn002 ~]# pvresize /dev/sdb
  Physical volume "/dev/sdb" changed
  1 physical volume(s) resized / 0 physical volume(s) not resized
[root@dn002 ~]# pvs
  PV         VG     Fmt  Attr PSize   PFree
  /dev/sda2  centos lvm2 a--   49.51g      0
  /dev/sdb   centos lvm2 a--  400.00g 300.04g

# pv容量增加后，实际上该pv所从属的vg就间接完成了扩容
[root@dn002 ~]# vgs
  VG     #PV #LV #SN Attr   VSize   VFree
  centos   2   2   0 wz--n- 449.50g 300.04g

# 然后再根据上面vg的free容量，进而给lv扩容
[root@dn002 ~]# lvextend -L +300G /dev/centos/root
  Size of logical volume centos/root changed from 145.59 GiB (37271 extents) to 445.59 GiB (114071 extents).
  Logical volume centos/root successfully resized.
[root@dn002 ~]# lvs
  LV   VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root centos -wi-ao---- 445.59g
  swap centos -wi-ao----   3.88g

# 此时在查看vg的容量，不难看出此前free的容量被划给了lv：(/dev/centos/root)
[root@dn002 ~]# vgs
  VG     #PV #LV #SN Attr   VSize   VFree
  centos   2   2   0 wz--n- 449.50g 40.00m

# 不过通过df命令来查看系统识别出的磁盘容量，却并没有出现变化，这是因为还要对文件系统进行扩容
[root@dn002 ~]# resize2fs /dev/mapper/centos-root
resize2fs 1.42.9 (28-Dec-2013)
resize2fs: Bad magic number in super-block while trying to open /dev/mapper/centos-root
Couldn't find valid filesystem superblock.

# 在centos7下以上命令报错，只需要使用xfs_growfs命令来替换就可以了
[root@dn002 ~]# xfs_growfs /dev/mapper/centos-root
meta-data=/dev/mapper/centos-root isize=256    agcount=13, agsize=2987776 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=0        finobt=0
data     =                       bsize=4096   blocks=38165504, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
log      =internal               bsize=4096   blocks=5835, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 38165504 to 116808704

# 最后通过df命令来验证文件系统容量是否完成了扩容
[root@dn002 ~]# df -TH
Filesystem              Type      Size  Used Avail Use% Mounted on
/dev/mapper/centos-root xfs       479G   13G  467G   3% /
devtmpfs                devtmpfs  4.1G     0  4.1G   0% /dev
tmpfs                   tmpfs     4.2G     0  4.2G   0% /dev/shm
tmpfs                   tmpfs     4.2G  8.9M  4.1G   1% /run
tmpfs                   tmpfs     4.2G     0  4.2G   0% /sys/fs/cgroup
/dev/sda1               xfs       521M  126M  396M  25% /boot
tmpfs                   tmpfs     821M     0  821M   0% /run/user/0

```

```shell
fdisk -l
pvs

pvcreate /dev/sdb
vgs
vgextend centos /dev/sdb

pvresize /dev/sdb
lvextend -L +300G /dev/centos/root
xfs_growfs /dev/mapper/centos-root

df -TH
```

timedatectl
timedatectl set-local-rtc 0
