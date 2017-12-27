# Postgresql流复制
| 主机名             | IP地址         | 作用      |
| ------------------ | -------------- | --------- |
| ser.bigdata.wh.com | 192.168.70.100 | PG Master |
| bak.bigdata.wh.com | 192.168.70.200 | PG Slaver |

## 必要条件
* 时间同步
* FQDN+DNS
* 关闭防火墙

## 创建postgres用户
```sh
#创建用户postgres
useradd postgres
passwd 1

#为postgres用户添加sudo权限
chmod u+w /etc/sudoers
[[ `sudo grep 'postgres*' /etc/sudoers` ]] || \
sudo sed -i -e '/^root.*ALL/a\postgres ALL=(ALL)      ALL' /etc/sudoers
```

## PG流复制
### 安装PG
分别在主备两台主机上安装pg9.5
```sh
yum install http://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-2.noarch.rpm
yum install -y postgresql95-server.x86_64 postgresql95-contrib.x86_64
```

然后分别配置`PGDATA`和`PATH`环境变量
```sh
echo 'CONFIG PG DATA'
cat << eof > /home/postgres/.bash_profile
[ -f /etc/profile ] && source /etc/profile
PGDATA=/var/lib/pgsql/9.5/data
export PGDATA
# If you want to customize your settings,
# Use the file below. This is not overridden
# by the RPMS.
[ -f /home/postgres/.pgsql_profile ] && source /home/postgres/.pgsql_profile
eof

echo 'CONFIG PG PATH'
cat << 'eof' > /home/postgres/.pgsql_profile
export PGHOME=/usr/pgsql-9.5
export PATH=$PATH:$PGHOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PGHOME/lib
'eof'

source .bash_profile
```

### 初始化Master数据库
首先切换到postgres用户，初始化PG数据库实例，并设置管理员密码
```sh
su postgres
initdb -D $PGDATA -U postgres -W
```

启动PG数据库实例，并创建专门用于同步的用户`replica`，并设置密码
```sh
echo 'START PG'
pg_ctl start -D $PGDATA
ss -tpnl |grep 5432

psql -U postgres
#USER为ROLE的别名，唯一的区别是USER默认带有LOGIN属性
CREATE USER replica REPLICATION ENCRYPTED PASSWORD 'replica';
CREATE ROLE replica LOGIN REPLICATION ENCRYPTED PASSWORD 'replica';
\q

pg_ctl stop
```

### Master访问授权
修改Master主节点数据目录中`pg_hba.conf`来增加用户授权
```sh
#允许所有用户通过密码登录后进行任何操作，包括远程登录、备份和流复制等
[[ `sudo grep 'host.*all.*md5' /var/lib/pgsql/9.5/data/pg_hba.conf` ]] || \
sed -i -e '/# IPv4 local.*/a\host   all           all       0.0.0.0/0          md5' \
/var/lib/pgsql/9.5/data/pg_hba.conf

#添加流复制的用户和IP访问授权
[[ `sudo grep 'host.*replication.*md5' /var/lib/pgsql/9.5/data/pg_hba.conf` ]] || \
sed -i -e '/host.*md5/a\host   replication   replica   bak.bigdata.wh.com  md5' \
/var/lib/pgsql/9.5/data/pg_hba.conf
```

### Master主库设置
修改Master主节点数据目录中的配置文件`postgresql.conf`相关的参数
```sh
# 监听本地所有的IP
sed -i -e '/^#listen_addresses =/s/^#//' -e "/listen_addresses =.*/s@=.*@= '*'@" \
/var/lib/pgsql/9.5/data/postgresql.conf

# 服务监听的端口
sed -i -e '/^#port =/s/^#//' -e "/port =.*/s@=.*@= 5432@" \
/var/lib/pgsql/9.5/data/postgresql.conf

# 这个是设置Hot Standby的必备参数
sed -i -e '/^#wal_level =/s/^#//' -e "/wal_level =.*/s@=.*@= hot_standby@" \
/var/lib/pgsql/9.5/data/postgresql.conf

# 这个设置了可以最多有几个流复制连接，差不多有几个从，就设置为几
sed -i -e '/^#max_wal_senders =/s/^#//' -e "/max_wal_senders =.*/s@=.*@= 3@" \
/var/lib/pgsql/9.5/data/postgresql.conf

# 设置流复制保留的最多的xlog数目
sed -i -e '/^#wal_keep_segments =/s/^#//' -e "/wal_keep_segments =.*/s@=.*@= 64@" \
/var/lib/pgsql/9.5/data/postgresql.conf

# 设置Master允许切换
sed -i -e '/^#hot_standby =/s/^#//' -e "/hot_standby =.*/s@=.*@= on@" \
/var/lib/pgsql/9.5/data/postgresql.conf

sed -i -e '/^#full_page_writes =/s/^#//' -e "/full_page_writes =.*/s@=.*@= on@" \
/var/lib/pgsql/9.5/data/postgresql.conf

sed -i -e '/^#wal_log_hints =/s/^#//' -e "/wal_log_hints =.*/s@=.*@= on@" \
/var/lib/pgsql/9.5/data/postgresql.conf
```

完成配置后再重启主数据库
```sh
echo 'ENABLE PG SERVICE'
sudo systemctl enable postgresql-9.5.service
sudo systemctl restart postgresql-9.5.service
```

### 在Slaver上创建备库
在Slaver备节点的postgres账户下对从库进行基础备份，这一步注意从库的数据目录必须手动清空
```sh
su postgres
pg_basebackup -h ser.bigdata.wh.com -p 5432 -U replica -Fp -Xs -v -P \
-D /var/lib/pgsql/9.5/data \
-l replbackup20171216

#参数含义：
# -h:指定所连接数据库的主机名或IP地址
# -p:指定所连接数据库的端口号
# -U:指定连接使用的用户名，比如专门用于复制的replica用户
# -F:指定输出的格式，p表示原样输出；t表示tar压缩包输出
# -x:备份开始后，启动另一个复制连接从从库接收WAL日志
# -P:允许打印备份过程中实时的完成进度
# -R:备份结束后自动生成recovery.conf文件
# -D:基础备份数据写到哪个目录，这个目录需要保证为空
# -l:给基础备份指定一个备份的标识
```

修改数据目录下的`pg_hba.conf`文件，在Slaver上配置流复制用户对Master的授权
```sh
sudo sed -i -e '/host.*replication.*md5/s@bak.bigdata.wh.com@ser.bigdata.wh.com@' \
/var/lib/pgsql/9.5/data/pg_hba.conf
```

### 配置recovery.conf
Master节点中的配置,注意拷贝到数据库目录时文件后缀为`.done`
```sh
cp -f /usr/pgsql-9.5/share/recovery.conf.sample /var/lib/pgsql/9.5/data/recovery.done

sed -i -e '/^#recovery_target_timeline =/s/^#//' -e "/recovery_target_timeline =.*/s@=.*@= 'latest'@" \
/var/lib/pgsql/9.5/data/recovery.done

sed -i -e '/^#standby_mode =/s/^#//' -e "/standby_mode =.*/s@=.*@= on@" \
/var/lib/pgsql/9.5/data/recovery.done

sed -i -e '/^#primary_conninfo =/s/^#//' \
-e "/primary_conninfo =.*/s@=.*@= 'user=replica password=replica host=bak.bigdata.wh.com port=5432'@" \
/var/lib/pgsql/9.5/data/recovery.done

sed -i -e '/^#trigger_file =/s/^#//' -e "/trigger_file =.*/s@=.*@= '/var/lib/pgsql/9.5/data/trigger_file'@" \
/var/lib/pgsql/9.5/data/recovery.done
```

Slaver节点中的配置如下：
```sh
cp -f /usr/pgsql-9.5/share/recovery.conf.sample /var/lib/pgsql/9.5/data/recovery.conf

sed -i -e '/^#recovery_target_timeline =/s/^#//' -e "/recovery_target_timeline =.*/s@=.*@= 'latest'@" \
/var/lib/pgsql/9.5/data/recovery.conf

sed -i -e '/^#standby_mode =/s/^#//' -e "/standby_mode =.*/s@=.*@= on@" \
/var/lib/pgsql/9.5/data/recovery.conf

sed -i -e '/^#primary_conninfo =/s/^#//' \
-e "/primary_conninfo =.*/s@=.*@= 'user=replica password=replica host=ser.bigdata.wh.com port=5432'@" \
/var/lib/pgsql/9.5/data/recovery.conf

# 通过检测trigger_file文件是否存在来激活standby为master
sed -i -e '/^#trigger_file =/s/^#//' -e "/trigger_file =.*/s@=.*@= '/var/lib/pgsql/9.5/data/trigger_file'@" \
/var/lib/pgsql/9.5/data/recovery.conf
```

### 配置.pgpass
创建Master上访问Slaver的密码参数配置文件
```sh
cat << eof > /home/postgres/.pgpass
bak.bigdata.wh.com:5432:replication:replica:replica
eof
sudo chmod 600 /home/postgres/.pgpass
```

创建Slaver上访问Master的密码参数配置文件
```sh
cat << eof > /home/postgres/.pgpass
ser.bigdata.wh.com:5432:replication:replica:replica
eof
sudo chmod 600 /home/postgres/.pgpass
```

### 重启Master和Slaver数据库
```sh
sudo systemctl restart postgresql-9.5.service
```

分别查看主库和备库进程信息
```sh
# 查看主库进程
[postgres@ser ~]$ sudo ps -ef|grep postgres
postgres  7069     1  0 17:38 ?        00:00:00 /usr/pgsql-9.5/bin/postgres -D /var/lib/pgsql/9.5/data
postgres  7070  7069  0 17:38 ?        00:00:00 postgres: logger process
postgres  7072  7069  0 17:38 ?        00:00:00 postgres: checkpointer process
postgres  7073  7069  0 17:38 ?        00:00:00 postgres: writer process
postgres  7074  7069  0 17:38 ?        00:00:00 postgres: wal writer process
postgres  7075  7069  0 17:38 ?        00:00:00 postgres: autovacuum launcher process
postgres  7076  7069  0 17:38 ?        00:00:00 postgres: stats collector process
postgres  7082  7069  0 17:38 ?        00:00:00 postgres: wal sender process replica 192.168.70.200(50288) streaming 0/8000878

# 查看从库进程
[postgres@bak ~]$ sudo ps -ef|grep postgres
postgres  4332     1  0 17:38 ?        00:00:00 /usr/pgsql-9.5/bin/postgres -D /var/lib/pgsql/9.5/data
postgres  4333  4332  0 17:38 ?        00:00:00 postgres: logger process
postgres  4334  4332  0 17:38 ?        00:00:00 postgres: startup process   recovering 000000010000000000000008
postgres  4335  4332  0 17:38 ?        00:00:00 postgres: checkpointer process
postgres  4336  4332  0 17:38 ?        00:00:00 postgres: writer process
postgres  4337  4332  0 17:38 ?        00:00:00 postgres: stats collector process
postgres  4338  4332  0 17:38 ?        00:00:00 postgres: wal receiver process   streaming 0/8000878
```

### 流复制验证
在Master上登录数据库，然后创建数据库和表
```sql
psql -U postgres

postgres=# create database panhongfa;
CREATE DATABASE

postgres=# \c panhongfa
You are now connected to database "panhongfa" as user "postgres"

panhongfa=# create table test1(a int,b int);
CREATE TABLE

panhongfa=# \dt
         List of relations
 Schema | Name  | Type  |  Owner
--------+-------+-------+----------
 public | test1 | table | postgres
(1 row)

panhongfa=# select * from test1;
 a | b
---+---
(0 rows)
```

在Slaver上登录数据库，然后查询新建的数据库和表是否同步正常
```sql
psql -U postgres

postgres=# \l
                                 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
-----------+----------+----------+------------+------------+-----------------------
 panhongfa | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
(4 rows)

postgres=# \c panhongfa
You are now connected to database "panhongfa" as user "postgres".

panhongfa=# \dt
         List of relations
 Schema | Name  | Type  |  Owner
--------+-------+-------+----------
 public | test1 | table | postgres
(1 row)

panhongfa=# select * from test1;
 a | b
---+---
(0 rows)
```

在Slaver上执行写命令，会发现提示该数据库是只读的，不允许写入或修改
```sql
postgres=# alter user postgres password 'postgres';
ERROR:  cannot execute ALTER ROLE in a read-only transaction
```

### 如何区分主备
* 通过`pg_controldata`命令查询，Master的cluster state是in production，Slaver的cluster state是in archive recovery
```sh
# 载入postgres环境变量
source /home/postgres/.bash_profile

# Master信息
[root@ser ~]# pg_controldata |grep 'cluster state'
Database cluster state:               in production

# Slaver信息
[root@bak ~]# pg_controldata |grep 'cluster state'
Database cluster state:               in archive recovery
```

* 通过全局的字典表`pg_stat_replication`来查询,Master主机的信息能够查询到，Slaver主机则不行
```sql
[postgres@ser ~]$ psql
psql (9.5.10)
Type "help" for help.

postgres=# select pid,application_name,client_addr,client_port,state,sync_state from pg_stat_replication;
 pid  | application_name |  client_addr   | client_port |   state   | sync_state
------+------------------+----------------+-------------+-----------+------------
 7082 | walreceiver      | 192.168.70.200 |       50288 | streaming | async
(1 row)
```

* 在各个主机上执行`sudo ps -ef|grep postgres`命令，进程中显示wal sender的是Master，显示wal receiver的是Slaver
```sh
# 查看主库进程
[postgres@ser ~]$ sudo ps -ef|grep postgres
postgres  7069     1  0 17:38 ?        00:00:00 /usr/pgsql-9.5/bin/postgres -D /var/lib/pgsql/9.5/data
postgres  7070  7069  0 17:38 ?        00:00:00 postgres: logger process
postgres  7072  7069  0 17:38 ?        00:00:00 postgres: checkpointer process
postgres  7073  7069  0 17:38 ?        00:00:00 postgres: writer process
postgres  7074  7069  0 17:38 ?        00:00:00 postgres: wal writer process
postgres  7075  7069  0 17:38 ?        00:00:00 postgres: autovacuum launcher process
postgres  7076  7069  0 17:38 ?        00:00:00 postgres: stats collector process
postgres  7082  7069  0 17:38 ?        00:00:00 postgres: wal sender process replica 192.168.70.200(50288) streaming 0/8000878

# 查看从库进程
[postgres@bak ~]$ sudo ps -ef|grep postgres
postgres  4332     1  0 17:38 ?        00:00:00 /usr/pgsql-9.5/bin/postgres -D /var/lib/pgsql/9.5/data
postgres  4333  4332  0 17:38 ?        00:00:00 postgres: logger process
postgres  4334  4332  0 17:38 ?        00:00:00 postgres: startup process   recovering 000000010000000000000008
postgres  4335  4332  0 17:38 ?        00:00:00 postgres: checkpointer process
postgres  4336  4332  0 17:38 ?        00:00:00 postgres: writer process
postgres  4337  4332  0 17:38 ?        00:00:00 postgres: stats collector process
postgres  4338  4332  0 17:38 ?        00:00:00 postgres: wal receiver process   streaming 0/8000878
```

* 通过PG的内置函数`pg_is_in_recovery()`来查询，Master是f;Slaver是t
```sh
# Master
postgres=# select pg_is_in_recovery();
 pg_is_in_recovery
-------------------
 f
(1 row)

# Slaver
postgres=# select pg_is_in_recovery();
 pg_is_in_recovery
-------------------
 t
(1 row)
```

### 主备切换
* 关闭Master数据库进程，模拟Master宕机
```sh
sudo systemctl stop postgresql-9.5.service
```

* 查看Slaver日志显示Master失去连接
```sh
[root@bak pg_log]# tail -f /var/lib/pgsql/9.5/data/pg_log/postgresql-Tue.log
		TCP/IP connections on port 5432?

< 2017-12-19 18:04:15.861 CST >FATAL:  could not connect to the primary server: could not connect to server: Connection refused
		Is the server running on host "ser.bigdata.wh.com" (192.168.70.100) and accepting
		TCP/IP connections on port 5432?

< 2017-12-19 18:04:20.873 CST >FATAL:  could not connect to the primary server: could not connect to server: Connection refused
		Is the server running on host "ser.bigdata.wh.com" (192.168.70.100) and accepting
		TCP/IP connections on port 5432?
```

* 通过在Slaver上创建`trigger_file`来触发备倒换为主
```sh
[postgres@bak data]$ touch /var/lib/pgsql/9.5/data/trigger_file
[postgres@bak data]$ pg_controldata
pg_control version number:            942
Catalog version number:               201510051
Database system identifier:           6501161577491128434
Database cluster state:               in production
pg_control last modified:             Tue 19 Dec 2017 06:13:36 PM CST
```

* Slaver的日志记录了倒换过程
```sh
[root@bak pg_log]# tail -f postgresql-Tue.log
		TCP/IP connections on port 5432?

< 2017-12-19 18:13:36.497 CST >LOG:  trigger file found: /var/lib/pgsql/9.5/data/trigger_file
< 2017-12-19 18:13:36.497 CST >LOG:  redo done at 0/8016C20
< 2017-12-19 18:13:36.498 CST >LOG:  last completed transaction was at log time 2017-12-19 17:40:12.851492+08
< 2017-12-19 18:13:36.499 CST >LOG:  selected new timeline ID: 2
< 2017-12-19 18:13:36.598 CST >LOG:  archive recovery complete
< 2017-12-19 18:13:36.601 CST >LOG:  MultiXact member wraparound protections are now enabled
< 2017-12-19 18:13:36.602 CST >LOG:  database system is ready to accept connections
< 2017-12-19 18:13:36.603 CST >LOG:  autovacuum launcher started
```

### 主机恢复
* 在经过倒换已成为新主机的Slaver上插入和删除部分数据
```sql
[postgres@bak data]$ psql panhongfa
psql (9.5.10)
Type "help" for help.

panhongfa=# \dt
         List of relations
 Schema | Name  | Type  |  Owner
--------+-------+-------+----------
 public | test1 | table | postgres
(1 row)

panhongfa=# \d test1
     Table "public.test1"
 Column |  Type   | Modifiers
--------+---------+-----------
 a      | integer |
 b      | integer |

panhongfa=# insert into test1 values (22,22222233);
INSERT 0 1
panhongfa=# DELETE FROM test1 WHERE a=11;
DELETE 4
panhongfa=# select * from test1;
 a  |    b
----+----------
 22 | 22222233
(5 rows)
```

* 如果Master数据库目录中的`recovery.done`没有变成`recovery.conf`，那就需要手动强制更改之后再启动Master数据库进程
```sh
# 强制修改recovery文件
mv /var/lib/pgsql/9.5/data/recovery.done /var/lib/pgsql/9.5/data/recovery.conf

# 重新启动Master
sudo systemctl start postgresql-9.5.service
```

* 如果在备库日志中出现由于Slaver数据发生变化导致Master与其`timeline`不一致的错误，需要在当前的备库上执行`pg_rewind`来同步时间线
```sh
# 错误信息
[root@bak pg_log]# tail -f postgresql-Tue.log
< 2017-12-20 15:13:25.267 CST >LOG:  new timeline 7 forked off current database system timeline 6 before current recovery point 0/C000258
< 2017-12-20 15:13:30.271 CST >LOG:  restarted WAL streaming at 0/C000000 on timeline 6
< 2017-12-20 15:13:30.271 CST >LOG:  replication terminated by primary server
< 2017-12-20 15:13:30.271 CST >DETAIL:  End of WAL reached on timeline 6 at 0/C0001B0.

# 关闭Master上此时的备库后再在Master上执行pg_rewind命令
pg_rewind --target-pgdata=/var/lib/pgsql/9.5/data \
--source-server='host=bak.bigdata.wh.com port=5432 user=postgres password=postgres dbname=postgres'

servers diverged at WAL position 0/C0001B0 on timeline 6
rewinding from last common checkpoint at 0/C000140 on timeline 6
Done!
```

* 需要注意的是，执行`pg_rewind`相当于将主库中的配置数据和历史数据又拷贝了一遍，以下的几个文件均需要重新编辑
```sh
cat pg_hba.conf

mv recovery.done recovery.conf
cat recovery.conf
```
