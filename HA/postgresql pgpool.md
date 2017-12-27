# Postgresql主备HA自切换
基于PG的流复制能实现热备切换，但是是要手动建立触发文件实现。但对于一些HA场景来说，需要当主机down了后，备机自动切换，官方发布的pgpool-II可以实现这种功能。

## 必要条件
* 时间同步
* FQDN+DNS
* 关闭防火墙
* 在两台主机上配置好PG流复制，关于流复制配置参考前文`PG流复制`

## 组网结构
![结构](img\pgpool-struct.png)

## 过程说明
PG主节点和备节点实现流复制热备，pgpool1，pgpool2作为中间件，将主备pg节点加入集群，实现异步流复制、负载均衡和HA故障自动切换。
两pgpool节点委托一个虚拟ip节点作为应用程序访问的地址，两节点之间通过watchdog进行监控，当pgpool1宕机时，pgpool2会自动接管虚拟ip继续对外提供不间断服务。

## 机器环境
| 主机名             | IP地址         | 作用       | 端口 |
| ------------------ | -------------- | ---------- | ---- |
| ser.bigdata.wh.com | 192.168.70.100 | PG Master  | 5432 |
|                    | 192.168.70.200 | pgpool1    | 9999 |
| bak.bigdata.wh.com | 192.168.70.200 | PG Slaver  | 5432 |
|                    | 192.168.70.200 | pgpool2    | 9999 |
| vip.bigdata.wh.com | 192.168.70.150 | virtual ip | 9999 |

## 设置FQDN
* 采用DNS方式时，在DNS主服务器的`/var/named`目录，在正向解析/反向解析区域文件中添加ip与hostname的对应关系
* 采用Hosts文件方式时，在`/etc/hosts`文件中添加ip与hostname的对应关系
* 虚拟ip同样需要添加到DNS和HOSTS文件中

## 主机免密登录
为了使得pgpool2能登录Master和Slaver数据库实例所在的主机，需要在两台主机之间互相配置ssh免密登录，以便`failover_command`的顺利脚本执行
```sh
#Master配置SSH免密登录
su - postgres
ssh-keygen -t rsa -P ''
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
scp -p ~/.ssh/id_rsa.pub postgres@bak.bigdata.wh.com:~/.ssh/authorized_keys
ssh postgres@bak.bigdata.wh.com

#Slaver配置SSH免密登录
su - postgres
ssh-keygen -t rsa -P ''
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
scp -p ~/.ssh/id_rsa.pub postgres@ser.bigdata.wh.com:~/.ssh/authorized_keys
ssh postgres@ser.bigdata.wh.com
```

试验下在`root`用户下通过`su - postgres -c`方式切换到`postgres`用户下通过ssh远程执行命令是否成功，避免后面进行主备切换时由于权限问题出错
```sh
su - postgres -c "ssh -t ser.bigdata.wh.com 'ls -al /home'"
su - postgres -c "ssh -t bak.bigdata.wh.com 'ls -al /home'"
```

## 安装pgpool2
在Master和Slaver上分别安装pgpool-II源rpm包，然后再安装pgpool-II
```sh
sudo rpm -ivh http://www.pgpool.net/yum/rpms/3.6/redhat/rhel-6-x86_64/pgpool-II-release-3.6-1.noarch.rpm
sudo yum -y install pgpool-II-pg95
sudo yum -y install pgpool-II-pg95-debuginfo
sudo yum -y install pgpool-II-pg95-devel
sudo yum -y install pgpool-II-pg95-extensions
```

## 添加函数支持
在Master库上安装`extension`函数支持，参考文章`http://www.pgpool.net/docs/latest/en/html/install-pgpool-recovery.html`
* pgpool-regclass
> 根据pgpool2官网的描述，pg9.4以后Postgresql核心中已经整合了相同to_regclass函数，
> 并且pgpool-extensions目录`/usr/pgsql-9.5/share/extension`已经没有提供pgpool-regclass.sql脚本了

* pgpool_recovery
将pgpool_recovery导入到模板template1中
```sh
[postgres@ser extension]$ psql template1
psql (9.5.10)
Type "help" for help.

# 导入函数
template1=# CREATE EXTENSION pgpool_recovery;
CREATE EXTENSION

# 查看新增函数
template1=# \df
                                 List of functions
 Schema |        Name         | Result data type |  Argument data types   |  Type
--------+---------------------+------------------+------------------------+--------
 public | pgpool_pgctl        | boolean          | text, text             | normal
 public | pgpool_recovery     | boolean          | text, text, text, text | normal
 public | pgpool_remote_start | boolean          | text, text             | normal
 public | pgpool_switch_xlog  | text             | text                   | normal
(4 rows)
```

至于Slaver库，如果流复制工作正常，添加的函数会自动的同步过去

## 创建必要角色
在Master库上创建监控角色，该角色在后面配置`pool.conf`是需要设置
```sql
CREATE USER srcheck PASSWORD 'srcheck';
CREATE USER healcheck PASSWORD 'healcheck';

# 从全局的用户表中查询角色是否正常创建
postgres=# SELECT rolname, rolpassword FROM pg_authid;
  rolname  |             rolpassword
-----------+-------------------------------------
 replica   | md5a28004efa9973e28807c49c166594b9d
 postgres  | md53175bce1d3201d16594cebf9d7eb3f9d
 srcheck   | md57535ba2e04de102b8c3089e84b0d0d3b
 healcheck | md54a52a07445b008c94064b3af329f6f07
(4 rows)

# 验证新建的用户能否正常登录
psql -d postgres -U srcheck -W
psql -d postgres -U healcheck -W
```

同样，如果流复制工作正常，新建的监控角色会自动的同步到Slaver库中

### 配置PCP管理账号
Pgpool-II有一个用于管理的接口，名为PCP,可通过网络获取数据库的节点信息，并且还可以远程关闭pgpool2服务等。要使用PCP命令和操作Pgpool-II的工具必须先进行用户认证，这种认证和PG数据库的用户认证不同，它需要在`pcp.conf`配置文件中定义一个用户和密码对。
```sh
# 计算密码字符串`pgadmin`的MD5值
pg_md5 pgadmin
b63d220aa4fcfcfb2b581071967490d9

# pcp.conf是pgpool管理器自己的用户名和密码，用于管理集群
[[ `sudo grep 'pgadmin:*' /etc/pgpool-II/pcp.conf` ]] || \
sudo sed -i -e '/USERID:MD5PASSWD.*/a\pgadmin:b63d220aa4fcfcfb2b581071967490d9' \
/etc/pgpool-II/pcp.conf
```

## 选择主配置文件
Pgpool-II的主配置文件是`pgpool.conf`，我们启动Pgpool-II时可以使用`-f`参数指定pgpool.conf路径， 默认是使用`/etc/pgpool-II/pgpool.conf`，Pgpool-II每钟工作模式都有与之对应的配置文件模板
![主配置文件](img\pgpool-conf.png)

以`pgpool.conf.sample-stream`为模板生成`pgpool.conf`主配置文件
```sh
sudo cp /etc/pgpool-II/pgpool.conf.sample-stream /etc/pgpool-II/pgpool.conf
```

## 配置Pgpool-II认证方式
Pgpool-II的`pool_hba.conf`是对登录用户进行验证的，要和PG的p`g_hba.conf`保持一致，要么都是trust，要么都是md5验证方式。
```sh
# 客户端认证启用hba方式，可在pool_hba.conf文件中为用户访问进行授权
sudo sed -i -e '/^#enable_pool_hba =/s/^#//' -e "/enable_pool_hba =.*/s@=.*@= on@" \
/etc/pgpool-II/pgpool.conf

[[ `sudo grep 'host.*md5' /etc/pgpool-II/pool_hba.conf` ]] || \
sudo sed -i -e '$a\host   all           all       0.0.0.0/0          md5' \
/etc/pgpool-II/pool_hba.conf

# "local" is for Unix domain socket connections only
local   all         all                            md5
# IPv4 local connections:
host    all         all         0.0.0.0/0          md5
host    all         all         0/0                md5
```

## 在Pgpool-II中添加PG数据库用户和密码
可以通过`pg_md5 -p -m -u postgres pool_passwd`命令生成pool_passwd文件，或通过`SELECT rolname, rolpassword FROM pg_authid`查询`postgres`用户密码，然后编辑pool_passwd文件
```sh
# 启用pool_passwd文件
sudo sed -i -e '/^#pool_passwd =/s/^#//' -e "/pool_passwd =.*/s@=.*@= 'pool_passwd'@" /etc/pgpool-II/pgpool.conf

# 创建pool_passwd文件
[root@ser pgpool-II]# pg_md5 -p -m -u postgres /etc/pgpool-II/pool_passwd
password:
[root@ser pgpool-II]# ls /etc/pgpool-II/
pcp.conf     pgpool.conf.sample-master-slave  pgpool.conf.sample-stream  pool_passwd
pgpool.conf  pgpool.conf.sample-replication   pool_hba.conf
[root@ser pgpool-II]# cat /etc/pgpool-II/pool_passwd
postgres:md53175bce1d3201d16594cebf9d7eb3f9d
```

## 配置操作系统命令的权限
在执行`failover_stream.sh`需要用到`ifconfig`和`arping`命令，首先检查命令是否存在，不存在就安装net-tools包
```sh
sudo yum install -y net-tools.x86_64
```

如果采用`postgres`等非`root`用户来启动pgpool，我们还需要配置普通用户对该命令的执行权限
```sh
sudo chmod u+s /sbin/ifconfig
sudo chmod u+s /usr/sbin
```

## 完成连接相关的配置
* 编辑pgpool连接池的连接选项
```sh
sudo sed -i -e '/^#listen_addresses =/s/^#//' -e "/listen_addresses =.*/s@=.*@= '*'@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#port =/s/^#//' -e "/port =.*/s@=.*@= 9999@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#pcp_listen_addresses =/s/^#//' -e "/pcp_listen_addresses =.*/s@=.*@= '*'@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#pcp_port =/s/^#//' -e "/pcp_port =.*/s@=.*@= 9898@" \
/etc/pgpool-II/pgpool.conf
```

* 编辑pgpool与后端Master和Slaver数据库的连接选项
```sh
sudo sed -i -e '/^#backend_hostname0 =/s/^#//' -e "/backend_hostname0 =.*/s@=.*@= 'ser.bigdata.wh.com'@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#backend_port0 =/s/^#//' -e "/backend_port0 =.*/s@=.*@= 5432@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#backend_weight0 =/s/^#//' -e "/backend_weight0 =.*/s@=.*@= 1@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#backend_data_directory0 =/s/^#//' -e "/backend_data_directory0 =.*/s@=.*@= '/var/lib/pgsql/9.5/data'@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#backend_flag0 =/s/^#//' -e "/backend_flag0 =.*/s@=.*@= 'ALLOW_TO_FAILOVER'@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#backend_hostname1 =/s/^#//' -e "/backend_hostname1 =.*/s@=.*@= 'bak.bigdata.wh.com'@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#backend_port1 =/s/^#//' -e "/backend_port1 =.*/s@=.*@= 5432@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#backend_weight1 =/s/^#//' -e "/backend_weight1 =.*/s@=.*@= 1@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#backend_data_directory1 =/s/^#//' -e "/backend_data_directory1 =.*/s@=.*@= '/var/lib/pgsql/9.5/data'@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#backend_flag1 =/s/^#//' -e "/backend_flag1 =.*/s@=.*@= 'ALLOW_TO_FAILOVER'@" \
/etc/pgpool-II/pgpool.conf
```

* 编辑pgpool运行模式选项
```sh
sudo sed -i -e '/^#replication_mode =/s/^#//' -e "/replication_mode =.*/s@=.*@= off@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#load_balance_mode =/s/^#//' -e "/load_balance_mode =.*/s@=.*@= on@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#master_slave_mode =/s/^#//' -e "/master_slave_mode =.*/s@=.*@= on@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#master_slave_sub_mode =/s/^#//' -e "/master_slave_sub_mode =.*/s@=.*@= 'stream'@" \
/etc/pgpool-II/pgpool.conf
```

* 编辑Streaming Replication check选项,这需要保证在后端的主库和备库中均存在该用户(专门用来做Streaming Replication check)
```sh
sudo sed -i -e '/^#sr_check_period =/s/^#//' -e "/sr_check_period =.*/s@=.*@= 5@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#sr_check_user =/s/^#//' -e "/sr_check_user =.*/s@=.*@= 'srcheck'@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#sr_check_password =/s/^#//' -e "/sr_check_password =.*/s@=.*@= 'srcheck'@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#sr_check_database =/s/^#//' -e "/sr_check_database =.*/s@=.*@= 'postgres'@" \
/etc/pgpool-II/pgpool.conf
```

* 编辑Health check选项,这里同样需要保证在后端的主库和备库中均存在该用户(专门用来做Health check),该选项必须设置，否则primary数据库down了，pgpool不知道，不能及时切换。只有下次使用pgpool登录时，发现连接不上，然后报错，这时候，才知道挂了，pgpool进行切换
```sh
sudo sed -i -e '/^#health_check_period =/s/^#//' -e "/health_check_period =.*/s@=.*@= 10@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#health_check_user =/s/^#//' -e "/health_check_user =.*/s@=.*@= 'healcheck'@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#health_check_password =/s/^#//' -e "/health_check_password =.*/s@=.*@= 'healcheck'@" \
/etc/pgpool-II/pgpool.conf
sudo sed -i -e '/^#health_check_database =/s/^#//' -e "/health_check_database =.*/s@=.*@= 'postgres'@" \
/etc/pgpool-II/pgpool.conf
```

## 开启日志输出
* 输出日志重定向到指定文件
```sh
# 配置LOGS中定义的日志输出设备
sudo sed -i -e '/^#log_destination =/s/^#//' -e "/log_destination =.*/s@=.*@= 'syslog'@" \
/etc/pgpool-II/pgpool.conf

# 在/etc/rsyslog.conf中加入配置行
[[ `sudo grep '#pgpool' /etc/rsyslog.conf` ]] || \
sudo sed -i -e '$a\#pgpool\nlocal0.*    /var/log/pgpool.log' /etc/rsyslog.conf

# 重启rsyslog服务
sudo systemctl restart rsyslog.service
```

* 打开日志选项，获取更多日志信息
```sh
sudo sed -i -e '/^#log_statement =/s/^#//' -e "/log_statement =.*/s@=.*@= on@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#log_min_messages =/s/^#//' -e "/log_min_messages =.*/s@=.*@= debug1@" \
/etc/pgpool-II/pgpool.conf
```

## 配置FAILOVER处理
故障处理配置的是`failover_command`选项,需要在`/home/postgres`目录中创建failover_stream.sh脚本
```sh
# 配置FAILOVER倒换脚本选项
sudo sed -i -e '/^#failover_command =/s/^#//' \
-e "/failover_command =.*/s@=.*@= '/home/postgres/failover_stream.sh %H'@" \
/etc/pgpool-II/pgpool.conf

# 创建failover_command脚本
cat << 'eof' > /home/postgres/failover_stream.sh
#! /bin/sh
# Failover command for streaming replication.
# Arguments: $1: new master hostname.

export PGHOME=/usr/pgsql-9.5
export PGDATA=/var/lib/pgsql/9.5/data
export PGUSER=postgres

new_master=$1
trigger_command="$PGHOME/bin/pg_ctl promote -D $PGDATA"

# Prompte standby database.
su - $PGUSER -c "/usr/bin/ssh -T $new_master $trigger_command"

exit 0;
'eof'
```

修改owner并添加可执行权限
```sh
sudo chown postgres:postgres /home/postgres/failover_stream.sh
sudo chmod 777  /home/postgres/failover_stream.sh
```

## 配置WATCHDOG监控
以上的配置在pgpool1和pgpool2中均是相同的，后续在配置watchdog时，就要根据本端和对端主机的不同而做出相应的修改

### 启用watchdog及配置主机名
* pgpool1(Master)
```sh
sudo sed -i -e '/^#use_watchdog =/s/^#//' -e "/use_watchdog =.*/s@=.*@= on@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#wd_hostname =/s/^#//' -e "/wd_hostname =.*/s@=.*@= 'ser.bigdata.wh.com'@" \
/etc/pgpool-II/pgpool.conf
```

* pgpool2(Slaver)
```sh
sudo sed -i -e '/^#use_watchdog =/s/^#//' -e "/use_watchdog =.*/s@=.*@= on@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#wd_hostname =/s/^#//' -e "/wd_hostname =.*/s@=.*@= 'bak.bigdata.wh.com'@" \
/etc/pgpool-II/pgpool.conf
```

### 查看本机网卡
配置后面的`delegate_IP`需要根据本端的`ifconfig`命令执行结果，替换成实际存在的网卡
```sh
[root@ser pgpool-II]# ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.15  netmask 255.255.255.0  broadcast 10.0.2.255
        inet6 fe80::5054:ff:feca:e48b  prefixlen 64  scopeid 0x20<link>
        ether 52:54:00:ca:e4:8b  txqueuelen 1000  (Ethernet)
        RX packets 716  bytes 620098 (605.5 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 450  bytes 34246 (33.4 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.70.100  netmask 255.255.255.0  broadcast 192.168.70.255
        inet6 fe80::a00:27ff:fe7f:9d8  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:7f:09:d8  txqueuelen 1000  (Ethernet)
        RX packets 8157  bytes 739862 (722.5 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 7118  bytes 1183354 (1.1 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1  (Local Loopback)
        RX packets 3172  bytes 1120051 (1.0 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 3172  bytes 1120051 (1.0 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

### 配置虚拟ip相关命令
虚拟ip相关的命令在本端和对端都是相同的
```sh
sudo sed -i -e '/^#delegate_IP =/s/^#//' -e "/delegate_IP =.*/s@=.*@= 'vip.bigdata.wh.com'@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#if_cmd_path =/s/^#//' -e "/if_cmd_path =.*/s@=.*@= '/sbin'@" \
/etc/pgpool-II/pgpool.conf

# 根据本端的实际情况替换相应的网卡设备号和子网掩码
sudo sed -i -e '/^#if_up_cmd =/s/^#//' -e "/if_up_cmd =.*/s@=.*@= 'ifconfig eth1:0 inet \$_IP_\$ netmask 255.255.255.0'@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#if_down_cmd =/s/^#//' -e "/if_down_cmd =.*/s@=.*@= 'ifconfig eth1:0 down'@" \
/etc/pgpool-II/pgpool.conf

# 根据本端的实际情况替换相应的网卡设备号
sudo sed -i -e '/^#arping_path =/s/^#//' -e "/arping_path =.*/s@=.*@= '/usr/sbin'@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#arping_cmd =/s/^#//' -e "/arping_cmd =.*/s@=.*@= 'arping -U \$_IP_\$ -I eth1 -w 1'@" \
/etc/pgpool-II/pgpool.conf
```

### 配置heartbeat相关参数
* pgpool1(Master)
```sh
sudo sed -i -e '/^#heartbeat_destination0 =/s/^#//' -e "/heartbeat_destination0 =.*/s@=.*@= 'bak.bigdata.wh.com'@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#heartbeat_device0 =/s/^#//' -e "/heartbeat_device0 =.*/s@=.*@= 'eth1'@" \
/etc/pgpool-II/pgpool.conf
```

* pgpool2(Slaver)
```sh
sudo sed -i -e '/^#heartbeat_destination0 =/s/^#//' -e "/heartbeat_destination0 =.*/s@=.*@= 'ser.bigdata.wh.com'@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#heartbeat_device0 =/s/^#//' -e "/heartbeat_device0 =.*/s@=.*@= 'eth1'@" \
/etc/pgpool-II/pgpool.conf
```

### 配置Other pgpool选项
* pgpool1(Master)
```sh
sudo sed -i -e '/^#other_pgpool_hostname0 =/s/^#//' -e "/other_pgpool_hostname0 =.*/s@=.*@= 'bak.bigdata.wh.com'@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#other_pgpool_port0 =/s/^#//' -e "/other_pgpool_port0 =.*/s@=.*@= 9999@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#other_wd_port0 =/s/^#//' -e "/other_wd_port0 =.*/s@=.*@= 9000@" \
/etc/pgpool-II/pgpool.conf
```

* pgpool2(Slaver)
```sh
sudo sed -i -e '/^#other_pgpool_hostname0 =/s/^#//' -e "/other_pgpool_hostname0 =.*/s@=.*@= 'ser.bigdata.wh.com'@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#other_pgpool_port0 =/s/^#//' -e "/other_pgpool_port0 =.*/s@=.*@= 9999@" \
/etc/pgpool-II/pgpool.conf

sudo sed -i -e '/^#other_wd_port0 =/s/^#//' -e "/other_wd_port0 =.*/s@=.*@= 9000@" \
/etc/pgpool-II/pgpool.conf
```

## 管理和使用
* 服务启动
```
sudo pgpool -n -d 2>&1 &

sudo systemctl start pgpool.service
```

* 服务停止
```sh
sudo pgpool -m fast stop

sudo systemctl stop pgpool.service
```

* 打开日志
```sh
# postgresql日志
tail -f /var/lib/pgsql/9.5/data/pg_log/postgresql-Fri.log

# pgpool日志
tail -f /var/log/pgpool.log
```

* 查看状态
```sh
[root@ser ~]# su postgres
[postgres@ser root]$ cd ~
[postgres@ser ~]$ psql -h vip.bigdata.wh.com -p 9999
psql (9.5.10)
Type "help" for help.

postgres=# show pool_nodes;
 node_id |      hostname      | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay
---------+--------------------+------+--------+-----------+---------+------------+-------------------+-------------------
 0       | ser.bigdata.wh.com | 5432 | up     | 0.500000  | primary | 0          | false             | 0
 1       | bak.bigdata.wh.com | 5432 | up     | 0.500000  | standby | 0          | true              | 0
(2 rows)
```

注意：在查看状态时，如果发现某个节点状态为`down`，而查询Master和Slaver的状态又显示正常，那么极有可能是pgpool启动时默认读取了`/tmp/pgpool_status`文件中记录的过期状态，此时最简单的办法就是删除该状态文件，然后重新启动pgpool服务; 或者通过PCP提供的`pcp_attach_node`客户端命令来添加相应的节点以便改变状态，参考文档 http://www.pgpool.net/mantisbt/view.php?id=274

## 验证过程
### Master端的pgpool宕机
在master节点上停止pgpool服务，等待几秒钟，待slaver节点的pgpool接管vip和集群服务后，继续正常访问pg集群
```sh
# 关闭master上的pgpool
[root@ser ~]# systemctl stop pgpool.service

# slaver节点pgpool日志展示的切换过程
Dec 25 15:23:48 bak atchdog[1636]: [21-1] 2017-12-25 15:23:48: pid 1636: LOG:  remote node "ser.bigdata.wh.com:9999 Linux ser.bigdata.wh.com" is shutting down
Dec 25 15:23:48 bak atchdog[1636]: [22-1] 2017-12-25 15:23:48: pid 1636: LOG:  watchdog cluster has lost the coordinator node
Dec 25 15:23:48 bak atchdog[1636]: [23-1] 2017-12-25 15:23:48: pid 1636: LOG:  unassigning the remote node "ser.bigdata.wh.com:9999 Linux ser.bigdata.wh.com" from watchdog cluster master
Dec 25 15:23:48 bak atchdog[1636]: [24-1] 2017-12-25 15:23:48: pid 1636: LOG:  We have lost the cluster master node "ser.bigdata.wh.com:9999 Linux ser.bigdata.wh.com"
Dec 25 15:23:48 bak atchdog[1636]: [25-1] 2017-12-25 15:23:48: pid 1636: LOG:  watchdog node state changed from [STANDBY] to [JOINING]
Dec 25 15:23:52 bak atchdog[1636]: [26-1] 2017-12-25 15:23:52: pid 1636: LOG:  watchdog node state changed from [JOINING] to [INITIALIZING]
Dec 25 15:23:53 bak atchdog[1636]: [27-1] 2017-12-25 15:23:53: pid 1636: LOG:  I am the only alive node in the watchdog cluster
Dec 25 15:23:53 bak atchdog[1636]: [27-2] 2017-12-25 15:23:53: pid 1636: HINT:  skiping stand for coordinator state
Dec 25 15:23:53 bak atchdog[1636]: [28-1] 2017-12-25 15:23:53: pid 1636: LOG:  watchdog node state changed from [INITIALIZING] to [MASTER]
Dec 25 15:23:53 bak atchdog[1636]: [29-1] 2017-12-25 15:23:53: pid 1636: LOG:  I am announcing my self as master/coordinator watchdog node
Dec 25 15:23:57 bak atchdog[1636]: [30-1] 2017-12-25 15:23:57: pid 1636: LOG:  I am the cluster leader node
Dec 25 15:23:57 bak atchdog[1636]: [30-2] 2017-12-25 15:23:57: pid 1636: DETAIL:  our declare coordinator message is accepted by all nodes
Dec 25 15:23:57 bak atchdog[1636]: [31-1] 2017-12-25 15:23:57: pid 1636: LOG:  setting the local node "bak.bigdata.wh.com:9999 Linux bak.bigdata.wh.com" as watchdog cluster master
Dec 25 15:23:57 bak atchdog[1636]: [32-1] 2017-12-25 15:23:57: pid 1636: LOG:  I am the cluster leader node. Starting escalation process
Dec 25 15:23:57 bak atchdog[1636]: [33-1] 2017-12-25 15:23:57: pid 1636: LOG:  escalation process started with PID:1717
Dec 25 15:23:57 bak atchdog[1636]: [34-1] 2017-12-25 15:23:57: pid 1636: LOG:  new IPC connection received
Dec 25 15:23:57 bak journal: atchdog escalation[1717]: [33-1] 2017-12-25 15:23:57: pid 1717: LOG:  watchdog: escalation started
Dec 25 15:24:01 bak journal: atchdog escalation[1717]: [34-1] 2017-12-25 15:24:01: pid 1717: LOG:  successfully acquired the delegate IP:"vip.bigdata.wh.com"
Dec 25 15:24:01 bak journal: atchdog escalation[1717]: [34-2] 2017-12-25 15:24:01: pid 1717: DETAIL:  'if_up_cmd' returned with success
Dec 25 15:24:01 bak atchdog[1636]: [35-1] 2017-12-25 15:24:01: pid 1636: LOG:  watchdog escalation process with pid: 1717 exit with SUCCESS.

# 继续通过vip访问pg集群
[postgres@ser ~]$ psql -h vip.bigdata.wh.com -p 9999
```

### Master端的primary数据库宕机
```sh
# 关闭master上的pg
[root@ser ~]# systemctl stop postgresql-9.5.service

# master上pg日志
< 2017-12-25 16:41:24.231 CST >DEBUG:  performing replication slot checkpoint
< 2017-12-25 16:41:24.276 CST >LOG:  database system is shut down
< 2017-12-25 16:41:24.387 CST >DEBUG:  logger shutting down

# slaver上pgpool日志
< 2017-12-25 16:41:24.380 CST >LOG:  received promote request
< 2017-12-25 16:41:24.383 CST >FATAL:  terminating walreceiver process due to administrator command
< 2017-12-25 16:41:24.384 CST >LOG:  redo done at 0/12000AB0
< 2017-12-25 16:41:24.384 CST >DEBUG:  resetting unlogged relations: cleanup 0 init 1
< 2017-12-25 16:41:24.389 CST >LOG:  selected new timeline ID: 8
< 2017-12-25 16:41:24.441 CST >LOG:  archive recovery complete
< 2017-12-25 16:41:24.443 CST >DEBUG:  MultiXactId wrap limit is 2147483648, limited by database with OID 1
< 2017-12-25 16:41:24.443 CST >LOG:  MultiXact member wraparound protections are now enabled
< 2017-12-25 16:41:24.443 CST >DEBUG:  MultiXact member stop limit is now 4294914944 based on MultiXact 1
< 2017-12-25 16:41:24.444 CST >LOG:  database system is ready to accept connections
< 2017-12-25 16:41:24.445 CST >LOG:  autovacuum launcher started
< 2017-12-25 16:41:24.447 CST >DEBUG:  performing replication slot checkpoint
< 2017-12-25 16:41:24.450 CST >DEBUG:  archived transaction log file "00000008.history"

# slaver上pg日志
Dec 25 16:41:24 bak journal: ostgres postgres 192.168.70.100(45012) idle[4562]: [14-1] 2017-12-25 16:41:24: pid 4562: LOG:  reading and processing packets
Dec 25 16:41:24 bak journal: ostgres postgres 192.168.70.100(45012) idle[4562]: [14-2] 2017-12-25 16:41:24: pid 4562: DETAIL:  postmaster on DB node 0 was shutdown by administrative command
Dec 25 16:41:24 bak journal: ostgres postgres 192.168.70.100(45012) idle[4562]: [15-1] 2017-12-25 16:41:24: pid 4562: LOG:  received degenerate backend request for node_id: 0 from pid [4562]
Dec 25 16:41:24 bak atchdog[4542]: [39-1] 2017-12-25 16:41:24: pid 4542: LOG:  new IPC connection received
Dec 25 16:41:24 bak atchdog[4542]: [40-1] 2017-12-25 16:41:24: pid 4542: LOG:  watchdog received the failover command from local pgpool-II on IPC interface
Dec 25 16:41:24 bak atchdog[4542]: [41-1] 2017-12-25 16:41:24: pid 4542: LOG:  watchdog is processing the failover command [DEGENERATE_BACKEND_REQUEST] received from local pgpool-II on IPC interface
Dec 25 16:41:24 bak atchdog[4542]: [42-1] 2017-12-25 16:41:24: pid 4542: LOG:  I am the only pgpool-II node in the watchdog cluster
Dec 25 16:41:24 bak atchdog[4542]: [42-2] 2017-12-25 16:41:24: pid 4542: DETAIL:  no need to propagate the failover command [DEGENERATE_BACKEND_REQUEST]
Dec 25 16:41:24 bak pgpool[4541]: [12-1] 2017-12-25 16:41:24: pid 4541: LOG:  Pgpool-II parent process has received failover request
Dec 25 16:41:24 bak atchdog[4542]: [43-1] 2017-12-25 16:41:24: pid 4542: LOG:  new IPC connection received
Dec 25 16:41:24 bak atchdog[4542]: [44-1] 2017-12-25 16:41:24: pid 4542: LOG:  received the failover command lock request from local pgpool-II on IPC interface
Dec 25 16:41:24 bak atchdog[4542]: [45-1] 2017-12-25 16:41:24: pid 4542: LOG:  local pgpool-II node "bak.bigdata.wh.com:9999 Linux bak.bigdata.wh.com" is requesting to become a lock holder for failover ID: 0
Dec 25 16:41:24 bak atchdog[4542]: [46-1] 2017-12-25 16:41:24: pid 4542: LOG:  local pgpool-II node "bak.bigdata.wh.com:9999 Linux bak.bigdata.wh.com" is the lock holder
Dec 25 16:41:24 bak pgpool[4541]: [13-1] 2017-12-25 16:41:24: pid 4541: LOG:  starting degeneration. shutdown host ser.bigdata.wh.com(5432)
Dec 25 16:41:24 bak pgpool[4541]: [14-1] 2017-12-25 16:41:24: pid 4541: LOG:  Restart all children
Dec 25 16:41:24 bak pgpool[4541]: [15-1] 2017-12-25 16:41:24: pid 4541: LOG:  execute command: /home/postgres/failover_stream.sh bak.bigdata.wh.com
Dec 25 16:41:24 bak atchdog[4542]: [47-1] 2017-12-25 16:41:24: pid 4542: LOG:  new IPC connection received
Dec 25 16:41:24 bak atchdog[4542]: [48-1] 2017-12-25 16:41:24: pid 4542: LOG:  received the failover command lock request from local pgpool-II on IPC interface
Dec 25 16:41:24 bak atchdog[4542]: [49-1] 2017-12-25 16:41:24: pid 4542: LOG:  local pgpool-II node "bak.bigdata.wh.com:9999 Linux bak.bigdata.wh.com" is requesting to release [FAILOVER] lock for failover ID 0
Dec 25 16:41:24 bak atchdog[4542]: [50-1] 2017-12-25 16:41:24: pid 4542: LOG:  local pgpool-II node "bak.bigdata.wh.com:9999 Linux bak.bigdata.wh.com" has released the [FAILOVER] lock for failover ID 0
Dec 25 16:41:24 bak pgpool[4541]: [16-1] 2017-12-25 16:41:24: pid 4541: LOG:  find_primary_node_repeatedly: waiting for finding a primary node
Dec 25 16:41:24 bak pgpool[4541]: [17-1] 2017-12-25 16:41:24: pid 4541: LOG:  find_primary_node: checking backend no 0
Dec 25 16:41:24 bak pgpool[4541]: [18-1] 2017-12-25 16:41:24: pid 4541: LOG:  find_primary_node: checking backend no 1
Dec 25 16:41:25 bak pgpool[4541]: [19-1] 2017-12-25 16:41:25: pid 4541: LOG:  find_primary_node: checking backend no 0
Dec 25 16:41:25 bak pgpool[4541]: [20-1] 2017-12-25 16:41:25: pid 4541: LOG:  find_primary_node: checking backend no 1
Dec 25 16:41:25 bak pgpool[4541]: [21-1] 2017-12-25 16:41:25: pid 4541: LOG:  find_primary_node: primary node id is 1
Dec 25 16:41:25 bak atchdog[4542]: [51-1] 2017-12-25 16:41:25: pid 4542: LOG:  new IPC connection received
Dec 25 16:41:25 bak atchdog[4542]: [52-1] 2017-12-25 16:41:25: pid 4542: LOG:  received the failover command lock request from local pgpool-II on IPC interface
Dec 25 16:41:25 bak atchdog[4542]: [53-1] 2017-12-25 16:41:25: pid 4542: LOG:  local pgpool-II node "bak.bigdata.wh.com:9999 Linux bak.bigdata.wh.com" is requesting to release [FOLLOW MASTER] lock for failover ID 0
Dec 25 16:41:25 bak atchdog[4542]: [54-1] 2017-12-25 16:41:25: pid 4542: LOG:  local pgpool-II node "bak.bigdata.wh.com:9999 Linux bak.bigdata.wh.com" has released the [FOLLOW MASTER] lock for failover ID 0
Dec 25 16:41:25 bak pgpool[4541]: [22-1] 2017-12-25 16:41:25: pid 4541: LOG:  failover: set new primary node: 1
Dec 25 16:41:25 bak pgpool[4541]: [23-1] 2017-12-25 16:41:25: pid 4541: LOG:  failover: set new master node: 1
Dec 25 16:41:25 bak journal: orker process[4577]: [11-1] 2017-12-25 16:41:25: pid 4577: LOG:  worker process received restart request
```

从以上日志中可以很清晰的观察到pgpool往slaver主机通过ssh执行倒换命令，以及slaver的切换过程，稍等几秒后访问集群，查询节点状态
```sh
postgres=# show pool_nodes;
 node_id |      hostname      | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay
---------+--------------------+------+--------+-----------+---------+------------+-------------------+-------------------
 0       | ser.bigdata.wh.com | 5432 | down   | 0.500000  | standby | 0          | false             | 0
 1       | bak.bigdata.wh.com | 5432 | up     | 0.500000  | primary | 0          | true              | 0
(2 rows)
```

### Master修复并重新加入集群
master节点down机后，slave节点已经被切换成了primary，修复好master后应重新加入节点，作为primary的standby

修复master端并启动pg实例，这里注意一定要把.done改为.conf，否则master将仍然以primary身份启动，会导致master与slaver之间的WAL时间线不一致的错误，并且最后只能通过pg_rewind命令来同步
```sh
[postgres@ser data]$ cd $PGDATA
[postgres@ser data]$ mv recovery.done recovery.conf
[postgres@ser data]$ sudo systemctl start postgresql-9.5.service
```

通过PCP客户端工具，将master节点添加到pgpool集群中
```sh
# 注意master的node_id是0，所以这里是-n 0
# 使用的用户前面添加的PCP管理用户pgadmin，密码pdadmin
[postgres@ser data]$ pcp_attach_node -d -U pgadmin -h vip.bigdata.wh.com -p 9898 -n 0
Password:
DEBUG: recv: tos="m", len=8
DEBUG: recv: tos="r", len=21
DEBUG: send: tos="C", len=6
DEBUG: recv: tos="c", len=20
pcp_attach_node -- Command Successful
DEBUG: send: tos="X", len=4

# 然后查看集群当前状态
postgres=# show pool_nodes;
 node_id |      hostname      | port | status  | lb_weight |  role   | select_cnt | load_balance_node | replication_delay
---------+--------------------+------+---------+-----------+---------+------------+-------------------+-------------------
 0       | ser.bigdata.wh.com | 5432 | waiting | 0.500000  | standby | 0          | false             | 0
 1       | bak.bigdata.wh.com | 5432 | up      | 0.500000  | primary | 0          | true              | 0
(2 rows)
```

## PG时间线同步
在主备切换时，修复节点并重启后，由于primary数据发生变化，或修复的节点数据发生变化再按照流复制模式加入集群，很可能出现时间线不同步的错误
```sh
< 2017-12-25 16:10:50.036 CST >DEBUG:  received replication command: START_REPLICATION 0/12000000 TIMELINE 5
< 2017-12-25 16:10:50.037 CST >ERROR:  requested starting point 0/12000000 on timeline 5 is not in this server's history
< 2017-12-25 16:10:50.037 CST >DETAIL:  This server's history forked from timeline 5 at 0/11000098.
< 2017-12-25 16:10:55.040 CST >DEBUG:  received replication command: IDENTIFY_SYSTEM
< 2017-12-25 16:10:55.040 CST >DEBUG:  received replication command: START_REPLICATION 0/12000000 TIMELINE 5
< 2017-12-25 16:10:55.040 CST >ERROR:  requested starting point 0/12000000 on timeline 5 is not in this server's history
< 2017-12-25 16:10:55.040 CST >DETAIL:  This server's history forked from timeline 5 at 0/11000098.
< 2017-12-25 16:11:00.050 CST >DEBUG:  received replication command: IDENTIFY_SYSTEM
< 2017-12-25 16:11:00.050 CST >DEBUG:  received replication command: START_REPLICATION 0/12000000 TIMELINE 5
< 2017-12-25 16:11:00.050 CST >ERROR:  requested starting point 0/12000000 on timeline 5 is not in this server's history
< 2017-12-25 16:11:00.050 CST >DETAIL:  This server's history forked from timeline 5 at 0/11000098.
```

产生这种情况，需要根据pg_rewind工具同步数据时间线，具体过程包含以下几个步骤
* 停掉需要同步的目标节点的PG服务
```sh
[postgres@ser data]$ sudo systemctl stop postgresql-9.5.service
```

* 同步目标节点上时间线
```sh
[postgres@ser data]$ pg_rewind --target-pgdata=/var/lib/pgsql/9.5/data \
--source-server='host=bak.bigdata.wh.com port=5432 user=postgres password=postgres dbname=postgres'

servers diverged at WAL position 0/C0001B0 on timeline 6
rewinding from last common checkpoint at 0/C000140 on timeline 6
Done!
```

* 修改pg_hba.conf文件和recovery.done文件
```sh
#pg_hba.conf与 recovery.done都是同步master上来的，要改成slave自己的
[postgres@ser data]$ cd $PGDATA
[postgres@ser data]$ mv recovery.done recovery.conf
[postgres@ser data]$ vi pg_hba.conf
#slave改成master（相当于slave的流复制对端）
host   replication   replica   bak.bigdata.wh.com  md5
[postgres@ser data]$ vi recovery.conf
#slave改成master（相当于slave的流复制对端）
primary_conninfo = 'user=replica password=replica host=bak.bigdata.wh.com port=5432'
```

* 重启PG服务
```sh
[postgres@ser data] sudo systemctl start postgresql-9.5.service
```

* 重新加入集群
```sh
[postgres@ser data]$ pcp_attach_node -d -U pgadmin -h vip.bigdata.wh.com -p 9898 -n 0
Password:
DEBUG: recv: tos="m", len=8
DEBUG: recv: tos="r", len=21
DEBUG: send: tos="C", len=6
DEBUG: recv: tos="c", len=20
pcp_attach_node -- Command Successful
DEBUG: send: tos="X", len=4
```

* 查看集群状态
```sh
postgres=# show pool_nodes;
 node_id |      hostname      | port | status  | lb_weight |  role   | select_cnt | load_balance_node | replication_delay
---------+--------------------+------+---------+-----------+---------+------------+-------------------+-------------------
 0       | ser.bigdata.wh.com | 5432 | up      | 0.500000  | standby | 0          | false             | 0
 1       | bak.bigdata.wh.com | 5432 | up      | 0.500000  | primary | 0          | true              | 0
(2 rows)
```
