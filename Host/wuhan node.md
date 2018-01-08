# 武汉IDC机房环境概述
## 物理机分配
根据目前公司关于服务器和网络资源的分配方式，数据分析部在IDC机房可以使用56、57、58、60这四台机器，它们均是曙光的服务器，配置基本相同，59是超威的双节点服务器，目前只能启动一个节点，另外一个节点有故障无法正常启动。实体机器配置和IP地址分配如下所述。

| IP            | CPU                                 | 内存       |
| ------------- | ----------------------------------- | ---------- |
| 192.168.80.56 | Intel(R) Xeon(R) CPU E5606 2.1GHZ   | 28662.8 MB |
| 192.168.80.57 | Intel(R) Xeon(R) CPU E5606 2.1GHZ   | 32758.8 MB |
| 192.168.80.58 | Intel(R) Xeon(R) CPU E5606 2.1GHZ   | 32758.8 MB |
| 192.168.80.59 | Intel(R) Xeon(R) CPU E5-2420 1.9GHZ | 48934.3 MB |
| 192.168.80.60 | Intel(R) Xeon(R) CPU E5606 2.1GHZ   | 32758.8 MB |

各个机器的详细配置信息参考 [大数据IDC服务器汇总.xlsx](大数据IDC服务器汇总.xlsx)

## 物理机管理
### SSH
所有服务器上均安装了VMware ESXi 6.0操作系统，配置了80网段的固定IP，能够访问外网，并且开放了ssh登录。80网段与公司内网36和37网段在物理上是隔离的，目前配置的VPN已经通过外网完成了它们之间的互联，我们可以在办公环境下使用root用户登录，通过“ESXi Shell”相关命令来完成查询或管理操作。
```config
user: root
pswd: daowoo123
```

## vSphere
这些服务器还通过虚拟机192.168.80.72上的vCenter Server来集中管理，通常情况下，我们在本机上安装“VMware vSphere Client”客户端，然后使用用户administrator@vsphere.local来登录192.168.80.72，在vSphere GUI环境中来管理主机、存储和虚拟机。
```config
ip: 192.168.80.72
user: administrator@vsphere.local
pswd: DaoWoo-123
```

![](img\vsphere.png)

## 虚拟机管理
### 虚拟机分配
| Host               | IP                 | URL                            | 作用                                                           |
| ------------------ | ------------------ | ------------------------------ | -------------------------------------------------------------- |
| repo.daowoo.com    | 192.168.85.200     | http://repo.daowoo.com:80      | 提供本地源http服务、DNS服务、NTP服务                           |
| proxy.daowoo.com   | 192.168.85.190     | http://proxy.daowoo.com:3142/  | 为yum提供rpm缓存代理服务                                       |
| db.daowoo.com      | 192.168.85.191     |                                | 提供独立的postgresql数据库服务，服务和组件使用各自的数据库实例 |
| kdc.daowoo.com     | 192.168.85.192     |                                | 为启用Kerbero提供的kdc验证服务器                               |
| sldap.daowoo.com   | 192.168.85.196     | http://sldap.daowoo.com/ldap   |                                                                |
|                    |                    |                                |                                                                |
| hdp.daowoo.com     | 192.168.85.100     | http://hdp.daowoo.com:8080     | HDP平台bigdata集群的ambari服务主机                             |
| nn.daowoo.com      | 192.168.85.101     |                                |                                                                |
| nn.daowoo.com      | 192.168.85.102     |                                |                                                                |
| gw.daowoo.com      | 192.168.85.103     |                                | HDP平台bigdata集群的用户接入网关，用户操作均在该节点进行       |
| yarn.daowoo.com    | 192.168.85.104     |                                |                                                                |
| hive.daowoo.com    | 192.168.85.105     |                                |                                                                |
| storm.daowoo.com   | 192.168.85.106     |                                |                                                                |
| spark.daowoo.com   | 192.168.85.107     |                                |                                                                |
| node*.daowoo.com   | 192.168.85.108/111 |                                |                                                                |
|                    |                    |                                |                                                                |
| nifisvr.daowoo.com | 192.168.85.120     | http://nifisvr.daowoo.com:8080 | HDF平台dataflow集群的ambari服务主机                            |
| nifi*.daowoo.com   | 192.168.85.121/129 |                                | HDF平台dataflow集群的组件节点                                  |

### 虚拟机登录
这些虚拟机均可以通过root用户使用密码登录
```config
user: root
pswd: 111111
```

### LDAP登录
用户通过登录LDAP管理页面来进行用户创建和修改
```config
urls: http://sldap.daowoo.com/ldap
user: admin
pswd: bigdata
```

LAM服务配置管理员密码
```config
pswd: lam
```

### gateway作用
日常使用通过SSH终端工具登录集群中的gateway节点来进行数据操作，用户通过LDAP管理页面LAM来进行创建和修改
```config
node: gw.daowoo.com
user: xxx
pswd: xxxxxx
```

### mstsc
IDC机房本地网络环境中已经安装好了很多windows虚拟机，在需要进行大文件上/下载或其他消耗流量较大的操作时，由于VPN带宽有限，可以通过远程登录的方式登录到这些window虚拟机，在IDC本地环境中进行操作。
```config
cmd: mstsc -v 192.168.80.74
user: bigdata
pswd: ABCabc123
```
