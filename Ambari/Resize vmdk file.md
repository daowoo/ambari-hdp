# 如何为VirtualBox虚拟机磁盘文件扩容
VirtualBox在创建虚拟磁盘时可以选择动态扩展和固定大小两种方式，然后设定磁盘空间大小。
* 动态扩展类型: 最初只需占用非常小的物理硬盘空间。然后不断增加(最大到当前指定的大小)，具体大小根据虚拟电脑的实际需求动态分配。
* 固定大小类型: 一旦建立就需分配指定大小的物理磁盘空间给该虚拟硬盘使用，性能上有一定优势。建立这种类型的虚拟硬盘需花费较多的时间.

当动态扩展方式达到上限时，比较直接的方法就是通过增加虚拟磁盘来扩展存储空间，间接的方法就是通过vboxmanage的导入/导出功能调整磁盘空间，这里我们介绍一下vboxmanage的方法。

## vboxmanage扩容
* 记录原来磁盘文件的uuid
```sh
vboxmanage showhdinfo "centos-vm-disk1.vmdk"

UUID: c4d43703-0f2c-462a-bb0f-427d938b8c15
```

* Clone the .vmdk image to a .vdi
```sh
vboxmanage clonehd "centos-vm-disk1.vmdk" "new-virtualdisk.vdi" --format vdi
```

* Resize the new .vdi image (30720 == 30 GB)
```sh
vboxmanage modifyhd "new-virtualdisk.vdi" --resize 30720
```

* switch back to a .vmdk
```sh
vboxmanage clonehd "new-virtualdisk.vdi" "resized.vmdk" --format vmdk
vboxmanage showhdinfo "resized.vmdk"
```

* overwrite .vmdk
```sh
mv resized.vmdk centos-vm-disk1.vmdk
```

* 编辑.vbox文件把原来磁盘的uuid替换成新生产的磁盘uuid

## 磁盘分区
* 进入系统后通过cfdisk工具来创建主分区
```sh
cfdisk /dev/sda
```
> 需要主要的是分区type必须为Linux LVM(8e)

* 利用pvcreate命令给新的分区创建物理卷
```sh
pvcreate /dev/sda3
```

* 查看VG Name，我自己的VG Name是centos
```sh
pvdisplay
```

* 新分区扩展到centos这个组
```sh
vgextend centos /dev/sda3
```

* 扩展逻辑分区
```sh
lvextend /dev/mapper/centos-root /dev/sda3
```

* 变更生效
```sh
xfs_growfs /dev/mapper/centos-root
```
