# NTP主备方案
## 时间和时区
| 名称 | 含义         | 描述                                                                  |
| ---- | ------------ | --------------------------------------------------------------------- |
| UTC  | 协调世界时   | 以原子时秒长为基础，在时刻上尽量接近于世界时的一种时间计量系统        |
| GMT  | 格林威治时间 | 引入时区概念划分后的0时区时间，可以认为UTC和GMT的值相等(误差相当之小) |
| CST  | 北京时间     | 时区上位于东八区，即UTC+8                                             |
|      |              |                                                                       |

> 含义：
* 不管通过任何渠道我们想要同步系统的时间,通常提供方只会给出UTC+0的时间值而不会提供时区(因为它不知道你在哪里).所以当我们设置系统时间的时候,设置好时区是首先要做的工作;
* 如果我们设置了正确的时区,当需要改变时间的时候系统就会自动替我们调整。

## 硬件时钟和系统时钟
| 名称 | 含义     | 描述                                                                                           |
| ---- | -------- | ---------------------------------------------------------------------------------------------- |
| RTC  | 硬件时钟 | 指嵌在主板上的特殊的电路, 它的存在就是平时我们关机之后还可以计算时间的原因                     |
| SYC  | 系统时钟 | 操作系统的kernel所用来计算时间的时钟. 它从1970年1月1日00:00:00 UTC时间到目前为止秒数总和的值。 |
|      |          |                                                                                                |

> 含义
* Linux系统在开机的时候，系统会同步硬件时钟，默认把BIOS时间当成UTC时间，即GMT+0时间，之后它们就各自独立地运行了;
* Windows系统与Linux系统类似，开机同步硬件时钟，不过它把BIOS时间当成本地时间（随着设定时区的不同而不同），即GMT+X时间；
* 可以使用`hwclock`命令来读/写硬件时间，还可以进行硬件时间与系统时间之间的相互转化。

## NTP时钟层数
NTP通过时钟层数来定义时钟的准确度。时钟层数的取值范围为1～16，取值越小，时钟准确度越高。层数为1～15的时钟处于同步状态；层数为16的时钟处于未同步状态。

通常将从权威时钟（如原子时钟）获得时间同步的NTP服务器的层数设置为1，并将其作为主时间服务器，为网络中其他设备的时钟提供时间同步。网络中的设备与主时间服务器的NTP距离，即NTP同步链上NTP服务器的数目，决定了设备上时钟的层数。例如，从主时间服务器获得时间同步的设备的时钟层数为2，即比主时间服务器的时钟层数大1；从时钟层数为2的时间服务器获得时间同步的设备的时钟层数为3，以此类推。

![ntp结构](img\ntp-level.png)

客户端上需要手工指定NTP服务器的地址。
客户端向NTP服务器发送NTP时间同步报文。
NTP服务器收到报文后会自动工作在服务器模式，并回复应答报文。
如果客户端可以从多个时间服务器获取时间同步，则客户端收到应答报文后，进行时钟过滤和选择，并与优选的时钟进行时间同步。

## NTP工作模式
| 模式         | 工作工程 | 同步方向 | 应用场景 |
| ------------ | -------- | -------- | -------- |
| C/S          | 客户端上需要手工指定NTP服务器的地址。客户端向NTP服务器发送NTP时间同步报文。NTP服务器收到报文后会自动工作在服务器模式，并回复应答报文。如果客户端可以从多个时间服务器获取时间同步，则客户端收到应答报文后，进行时钟过滤和选择，并与优选的时钟进行时间同步。         | 客户端能够与NTP服务器的时间同步,NTP服务器无法与客户端的时间同步         |  常用于下级的设备从上级的时间服务器获取时间同步        |
| Peer         | 主动对等体（Symmetricactivepeer）上需要手工指定被动对等体（Symmetricpassivepeer）的地址。主动对等体向被动对等体发送NTP时间同步报文。被动对等体收到报文后会自动工作在被动对等体模式，并回复应答报文。如果主动对等体可以从多个时间服务器获取时间同步，则主动对等体收到应答报文后，进行时钟过滤和选择，并与优选的时钟进行时间同步。         | 主动对等体和被动对等体的时间可以互相同步,如果双方的时钟都处于同步状态，则层数大的时钟与层数小的时钟的时间同步         |  通常用于同级的设备间互相同步，以便在同级的设备间形成备份。如果某台设备与所有上级时间服务器的通信出现故障，则该设备仍然可以从同级的时间服务器获得时间同步        |
| Broadcast    | 广播服务器周期性地向广播地址255.255.255.255发送NTP时间同步报文。广播客户端侦听来自广播服务器的广播报文，根据接收的广播报文将设备的时间与广播服务器的时间进行同步。广播客户端接收到广播服务器发送的第一个NTP报文后，会与广播服务器进行报文交互，以获得报文的往返时延，为时间同步提供必要的参数。之后，只有广播服务器单方向发送报文         |  广播客户端能够与广播服务器的时间同步,广播服务器无法与广播客户端的时间同步        |  广播服务器广播发送时间同步报文，可以同时同步同一个子网中多个广播客户端的时间,但是广播模式的时间准确度不如客户端/服务器模式和对等体模式      |
| Multicasting | 组播服务器周期性地向指定的组播地址发送NTP时间同步报文。客户端侦听来自服务器的组播报文，根据接收的组播报文将设备的时间与组播服务器的时间进行同步         | 组播客户端能够与组播服务器的时间同步，组播服务器无法与组播客户端的时间同步         | 组播模式对广播模式进行了扩展，组播服务器可以同时为同一子网、不同子网的多个组播客户端提供时间同步         |

## 方案设计
* 现有的`外网时钟源->ntp server->hdp nodes`的层次结构不变，原ntp server节点作为master，再添加一个ntp server节点作为slaver;
* master和slave均从外网时钟源更新时间，同时启用本地时间服务器，设置相同的层数并配置为对等体;
* HDP集群中的节点均只设置master和slave为时钟源，并利用`prefer`选项设置优先从master更新时间;

## 组织结构图
![组织结构](img\ntp-struct.png)

## 期望结果
| 故障类型                | master                           | slaver                              | client                                 |
| ----------------------- | -------------------------------- | ----------------------------------- | -------------------------------------- |
| master外网断开          | 启用本地时间作为时钟源，层级为10 | 继续使用外网NTP时钟源，层级远小于10 | 选取最靠近权威时钟源的Slaver作为当前源 |
| master和slave外网均断开 | 启用本地时间作为时钟源，层级为10 | 启用本地时间作为时钟源，层级为10    |                                        |

## 配置过程
### master
安装ntp服务
```sh
echo 'install ntpd.service'
sudo yum install -y ntp
sudo cp -f /etc/ntp.conf /etc/ntp.conf.bak
```

尝试关闭`chronyd`服务，该服务会抑制ntp自启动
```sh
sudo systemctl stop chronyd.service
sudo systemctl disable chronyd.service
```

配置Master允许更新时钟的网段
```sh
[[ `sudo grep 'restrict 192.168.0.0 *' /etc/ntp.conf` ]] || \
sudo sed -i -e "/^#[# ]*Hosts on/a\restrict 192.168.0.0 mask 255.255.0.0 nomodify notrap" \
/etc/ntp.conf
```

配置master与slaver为对等体
```sh
[[ `sudo grep 'peer 192.168.70.*' /etc/ntp.conf` ]] || \
sudo sed -i -e '/^server 3.*/a\peer 192.168.70.200' \
/etc/ntp.conf
```

配置Master在外部时钟源连接异常后，允许启用本地UTC时间作为时钟源
```sh
[[ `sudo grep 'server  127.127.1.0*' /etc/ntp.conf` ]] || \
sudo sed -i -e '/^#[# ]*manycastclient/a\\nserver  127.127.1.0\nfudge   127.127.1.0 stratum 10' \
/etc/ntp.conf
```

重启ntp服务
```sh
sudo systemctl restart ntpd.service
sudo systemctl enable ntpd.service
```

### slaver
安装ntp服务
```sh
echo 'install ntpd.service'
sudo yum install -y ntp
sudo cp -f /etc/ntp.conf /etc/ntp.conf.bak
```

配置Master允许更新时钟的网段
```sh
[[ `sudo grep 'restrict 192.168.0.0 *' /etc/ntp.conf` ]] || \
sudo sed -i -e "/^#[# ]*Hosts on/a\restrict 192.168.0.0 mask 255.255.0.0 nomodify notrap" \
/etc/ntp.conf
```

配置master与slaver为对等体
```sh
[[ `sudo grep 'peer 192.168.70.*' /etc/ntp.conf` ]] || \
sudo sed -i -e '/^server 3.centos.*/a\peer 192.168.70.100' \
/etc/ntp.conf
```

配置Master在外部时钟源连接异常后，允许启用本地UTC时间作为时钟源
```sh
[[ `sudo grep 'server  127.127.1.0*' /etc/ntp.conf` ]] || \
sudo sed -i -e '/^#[# ]*manycastclient/a\\nserver  127.127.1.0\nfudge   127.127.1.0 stratum 10' \
/etc/ntp.conf
```

重启ntp服务
```sh
sudo systemctl restart ntpd.service
sudo systemctl enable ntpd.service
```

### client
安装ntp服务
```sh
echo 'install ntpd.service'
sudo yum install -y ntp
sudo cp -f /etc/ntp.conf /etc/ntp.conf.bak
```

配置客户端时钟源
```sh
sudo sed -i '/server [0-3].centos.*/s/^/#/' /etc/ntp.conf
[[ `sudo grep 'server 192.168.70.*' /etc/ntp.conf` ]] || \
sudo sed -i -e '/^server 3.centos.*/a\server 192.168.70.100 prefer\nserver 192.168.70.200' \
/etc/ntp.conf
```

重启ntp服务
```sh
sudo systemctl restart ntpd.service
sudo systemctl enable ntpd.service
```

## 测试过程
ntpq结果表头字段含义：
* remote: 用于同步的远程节点或服务器。“LOCAL”表示本机 **（当没有远程服务器可用时会出现）**
* refid: 远程的服务器进行同步的更高一级服务器地址
* st: 远程节点或服务器的 Stratum（级别，NTP 时间同步是分层的）
* t: 类型 (u: unicast（单播）, b: broadcast（广播）, l: 本地时钟, s: 对称节点（用于备份）
* when: 最后一次同步到现在的时间 (默认单位为秒, “h”表示小时，“d”表示天)
* poll: 同步的频率

ntpq结果特殊符号含义：
* `*`当前作为优先主同步对象的远程节点或服务器
* `+`表示良好的且优先使用的远程节点或服务器（包含在组合算法中）
* `-`表示已不再使用
* ` `表示无状态

等待一段时间后，各个节点间正常的时钟同步状态如下
```sh
#  master
[root@ser ~]# ntpq -p
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
-ntp1.flashdance 192.36.143.154   2 u   54   64  117  356.720   17.946   2.760
*120.25.115.20   10.137.38.86     2 u   58   64  177   23.023    2.887   2.844
+darwin.kenyonra 127.67.113.92    2 u   56   64  157  163.814    4.953   1.419
+time5.aliyun.co 10.137.38.86     2 u   53   64  177   24.597    3.584   1.299
 bak.bigdata.wh. LOCAL(0)        11 u   29   64    6    1.150    1.061   0.250
 LOCAL(0)        .LOCL.          10 l  264   64  360    0.000    0.000   0.000

# Slaver
[root@bak ~]# ntpq -p
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
+ntp2.itcomplian 5.103.128.88     3 u   30   64   37  328.295   10.215   0.861
*biisoni.miuku.n 207.224.49.219   2 u   26   64   37  197.790   -7.496   0.443
 ntp.wdc1.us.lea .INIT.          16 u    -   64    0    0.000    0.000   0.000
+192.168.70.100  120.25.115.20    3 u   11   64   37    0.038    1.832   2.413
 LOCAL(0)        .LOCL.          10 l   39   64   37    0.000    0.000   0.000

# Client
[root@node1 ~]# ntpq -p
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
*ser.bigdata.wh. 120.25.115.20    3 u   39   64   17    0.196   -2.179   1.318
 bak.bigdata.wh. LOCAL(0)        11 u   40   64    7    0.169   -3.135   0.498
```

关闭Master主机NTP服务，恢复后的时钟同步状态如下
```sh
# Slaver
[root@bak ~]# ntpq -p
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
+ntp1.flashdance 194.58.202.148   2 u  118   64  176  356.945   17.489  28.647
*leontp.ccgs.wa. .GPS.            1 u  235   64  370  361.590   -2.983   3.323
 gus.buptnet.edu .INIT.          16 u  112   64  370   61.270   14.437  11.017
+time6.aliyun.co 10.137.38.86     2 u   49   64  371   21.218    0.429   2.952
 192.168.70.100  .INIT.          16 u    -  512    0    0.000    0.000   0.000
 LOCAL(0)        .LOCL.          10 l 1397   64    0    0.000    0.000   0.000

 # Client
 [root@node1 ~]# ntpq -p
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
 ser.bigdata.wh. .INIT.          16 u    -  512    0    0.000    0.000   0.000
*bak.bigdata.wh. 203.135.184.123  2 u    1   64  377    0.192   -2.576   0.797
```

关闭Master主机NTP服务的同时断开Slaver主机外网，恢复后的时钟同步状态如下
```sh
# Client
[root@node1 ~]# ntpq -p
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
 ser.bigdata.wh. .INIT.          16 u    -   64    0    0.000    0.000   0.000
*bak.bigdata.wh. LOCAL(0)        11 u   42   64    1    0.284   -2.073   0.000
```

重新启动Master主机NTP服务，恢复后的时钟同步状态如下
```sh
[root@node1 ~]# ntpq -p
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
*ser.bigdata.wh. LOCAL(0)        11 u    2   64    1    0.183   -0.308   0.000
 bak.bigdata.wh. LOCAL(0)        11 u   65   64    1    0.209   -2.632   0.000
```
