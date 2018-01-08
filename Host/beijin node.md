# 北京大数据环境概述
## 机器描述
| IP            | HOSTNAME              | 作用                                     | 类型          |
| ------------- | --------------------- | ---------------------------------------- | ------------- |
| 172.16.16.67  | hive.bigdata.bj.com   | hiveserver2 + metadata + datanode        | 物理机        |
| 172.16.16.68  | ambari.bigdata.bj.com | ambariserver + namenode + secondnamenode | 物理机        |
| 172.16.16.69  | hbase.bigdata.bj.com  | Masterserver + Regionsserver + datanode  | 物理机        |
| 172.16.16.111 | repo.bigdata.bj.com   | httpd + dns + ntp                        | vagrant虚拟机 |
| 172.16.16.112 | proxy.bigdata.bj.com  | apt-cache                                | vagrant虚拟机 |


## 登录方式
* 其中67、68、69三台机器为物理机，目前在武汉可以通过VPN远程登录
```config
user: root
pswd: HadoopDw111111
```

* 111和112是在68机器上通过vagrant创建的两台虚拟机，该IP只在北京内网访问，武汉通过VPN无法直接远程登录。我们可以通过在68上使用`vagrant ssh`命令或者`ssh root@xxxx`命令登录
```sh
# vagrant方式登录
vagrant ssh repo
vagrant ssh proxy

# ssh方式登录，注意，宿主机必须为北京内网机器
ssh root@repo.bigdata.bj.com
ssh root@proxy.bigdata.bj.com
```

## 网络配置
```sh
NETMASK=255.255.248.0
GATEWAY=172.16.23.254
DNS1=172.16.30.200
```
