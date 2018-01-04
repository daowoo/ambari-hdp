# 安装Postgresql9.5
## 设置安装源
```sh
[root@localhost ~]# yum install https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-
```

## 安装二进制包
```sh
[root@localhost ~]# yum install postgresql95-server -y  #安装主程序
[root@localhost ~]# yum install postgresql95-contrib -y #安装第三方包和分布式包（可选）
[root@localhost ~]# yum install postgresql95-plpython.x86_64 -y #安装Postgresql python2扩展模块包（可选）
```

PG默认安装在/usr目录下，其软件的目录结构如下。
```sh
[root@localhost ~]# cd /usr/pgsql-9.5/
[root@localhost pgsql-9.5]# ls -l
total 16
drwxr-xr-x. 2 root root 4096 Oct 25 17:19 bin      #二进制可执行文件目录，该目录下有postgres、psql等可执行程序
drwxr-xr-x. 3 root root   22 Oct 25 17:19 doc      #文档目录，该目录下有一些帮助文档和示例文档
drwxr-xr-x. 2 root root 4096 Oct 25 17:19 lib      #动态库目录，程序运行所需要的动态库均在此目录下
drwxr-xr-x. 8 root root 4096 Oct 25 17:19 share    #配置文件模板文件以及一些扩展包的sql脚本文件
```

## 创建PG数据库目录
```sh
[root@localhost home]# mkdir -p /home/pgsql/data  #创建PG数据库目录
[root@localhost home]# chown -R postgres.postgres pgsql #更改目录所属用户和用户组structurestructure
[root@localhost home]# ls -al
total 8
drwxr-xr-x.  4 root     root       28 Oct 25 17:29 .
drwxr-xr-x. 17 root     root     4096 Jul 11 16:16 ..
drwxr-xr-x.  3 postgres postgres   17 Oct 25 17:29 pgsql
drwx------.  5 phf      phf      4096 Jul 12 10:32 phf
```

## 设置PG环境变量
### 添加bash环境变量
```sh
[root@localhost ~]# vim .bash_profile

# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

export PGHOME=/usr/pgsql-9.5              #添加PG主目录
export PGDATA=/home/pgsql/data            #添加PG默认的数据目录
export PATH=$PATH:$HOME/bin:$PGHOME/bin   #添加PG执行文件目录至PATH目录
```
注意：设置PGHOME和PGDATA环境变量是非必须的，如果需要使用pg_ctrl快速启动或systemctl自启动，它们才会直接使用这些默认值。

### 验证环境变量
重新加载.bash_profile文件，使修改的配置立即生效
```sh
[root@localhost ~]# source ~/.bash_profile
```
或者
```sh
[root@localhost ~]# exec bash --login
```

验证一下刚才的配置是否生效。
```sh
[root@localhost home]# export
declare -x HISTCONTROL="ignoredups"
declare -x HISTSIZE="1000"
declare -x HOME="/root"
declare -x HOSTNAME="localhost.localdomain"
declare -x LANG="en_US.UTF-8"
declare -x LESSOPEN="||/usr/bin/lesspipe.sh %s"
declare -x LOGNAME="root"
declare -x MAIL="/var/spool/mail/root"
declare -x OLDPWD="/home/pgsql"
declare -x PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:/bin:/root/bin:/bin:/root/bin:/usr/pgsql-9.5/bin"
declare -x PGDATA="/home/pgsql/data"
declare -x PGHOME="/usr/pgsql-9.5"
declare -x PWD="/home"
declare -x SELINUX_LEVEL_REQUESTED=""
declare -x SELINUX_ROLE_REQUESTED=""
declare -x SELINUX_USE_CURRENT_RANGE=""
declare -x SHELL="/bin/bash"
declare -x SHLVL="1"
declare -x SSH_CLIENT="192.168.127.1 50710 22"
declare -x SSH_CONNECTION="192.168.127.1 50710 192.168.127.134 22"
declare -x SSH_TTY="/dev/pts/1"
declare -x TERM="xterm"
declare -x USER="root"
```
或者
```sh
[root@localhost ~]# $PGHOME
bash: /usr/pgsql-9.5: Is a directory
[root@localhost ~]# $PGDATA
bash: /home/pgsql/data: Is a directory
```

## 初始化数据库
```sql
[root@localhost pgsql]# su postgres    #切换至安装PG时创建的Centos系统账户postgres
bash-4.2$ $PGDATA
bash: /home/pgsql/data: Is a directory
bash-4.2$ initdb -D /home/pgsql/data/ -U postgres -W  #初始化数据库
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /home/pgsql/data ... ok
creating subdirectories ... ok
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting dynamic shared memory implementation ... posix
creating configuration files ... ok
creating template1 database in /home/pgsql/data/base/1 ... ok
initializing pg_authid ... ok
Enter new superuser password:    #提示输入PG数据库超级管理员用户postgres的密码
Enter it again:
setting password ... ok
initializing dependencies ... ok
creating system views ... ok
loading system objects descriptions ... ok
creating collations ... ok
creating conversions ... ok
creating dictionaries ... ok
setting privileges on built-in objects ... ok
creating information schema ... ok
loading PL/pgSQL server-side language ... ok
vacuuming database template1 ... ok
copying template1 to template0 ... ok
copying template1 to postgres ... ok
syncing data to disk ... ok

WARNING: enabling "trust" authentication for local connections
You can change this by editing pg_hba.conf or using the option -A, or
--auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    pg_ctl -D /home/pgsql/data/ -l logfile start
```

## 修改数据库配置文件
数据库初始化后，在数据库目录data中会生成一系列的文件夹和文件。
```sh
bash-4.2$ ls -l
total 48
drwx------. 5 postgres postgres    38 Oct 25 19:01 base                  #默认表空间的目录，与每个数据库对应的子目录存储在该目录中
drwx------. 2 postgres postgres  4096 Oct 25 19:01 global                #集群范围的表存储在该目录中，比如‘pg_database’
drwx------. 2 postgres postgres    17 Oct 25 19:01 pg_clog               #包含事务提交状态数据的子目录
drwx------. 2 postgres postgres     6 Oct 25 19:01 pg_commit_ts          #？
drwx------. 2 postgres postgres     6 Oct 25 19:01 pg_dynshmem           #包含动态共享内存子系统使用的文件的子目录
drwx------. 4 postgres postgres    37 Oct 25 19:01 pg_logical            #包含逻辑解码状态数据的子目录
drwx------. 4 postgres postgres    34 Oct 25 19:01 pg_multixact          #包含多重事务状态数据的子目录(使用共享的行锁)
drwx------. 2 postgres postgres    17 Oct 25 19:01 pg_notify             #包含LISTEN/NOTIFY状态数据的子目录
drwx------. 2 postgres postgres     6 Oct 25 19:01 pg_replslot           #包含复制槽数据的子目录
drwx------. 2 postgres postgres     6 Oct 25 19:01 pg_serial             #包含已提交可串行化事务信息的子目录
drwx------. 2 postgres postgres     6 Oct 25 19:01 pg_snapshots          #包含输出快照的子目录
drwx------. 2 postgres postgres     6 Oct 25 19:01 pg_stat               #包含统计系统的永久文件的子目录
drwx------. 2 postgres postgres     6 Oct 25 19:01 pg_stat_tmp           #用于统计子系统的临时文件存储在该目录中
drwx------. 2 postgres postgres    17 Oct 25 19:01 pg_subtrans           #包含子事务状态数据的子目录
drwx------. 2 postgres postgres     6 Oct 25 19:01 pg_tblspc             #包含指向表空间的符号链接的子目录
drwx------. 2 postgres postgres     6 Oct 25 19:01 pg_twophase           #包含用于预备事务的状态文件的子目录
-rw-------. 1 postgres postgres     4 Oct 25 19:01 PG_VERSION            #一个包含PostgreSQL主版本号的文件
drwx------. 3 postgres postgres    58 Oct 25 19:01 pg_xlog               #包含WAL(预写日志)文件的子目录
-rw-------. 1 postgres postgres    88 Oct 25 19:01 postgresql.auto.conf  #用于存储ALTER SYSTEM设置的配置参数的文件
-rw-------. 1 postgres postgres 21256 Oct 25 19:01 postgresql.conf       #数据库实例的主配置文件，基本上所有的配置参数均在此文件中
-rw-------. 1 postgres postgres  4468 Oct 25 19:01 pg_hba.conf           #访问认证配置文件，包括允许哪些IP的主机访问，采用的认证方法是什么等信息
-rw-------. 1 postgres postgres  1636 Oct 25 19:01 pg_ident.conf         #‘ident’认证方式的用户映射文件
```

监听的IP和端口配置
```sh
bash-4.2$ vim postgresql.conf

# - Connection Settings -
listen_addresses = '*'         #监听所有ip的连接，默认是本机 (change requires restart)
port = 5432                            #这个不开也行，默认就是5432端口 (change requires restart)
```

访问权限配置
```sh
bash-4.2$ vim pg_hba.conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
host    all             all             0.0.0.0/0               md5      #这一行我加的，所有IP和用户，密码对都可以连接
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
#local   replication     postgres                                trust
#host    replication     postgres        127.0.0.1/32            trust
```

## 启动数据库
```sh
bash-4.2$ pg_ctl start -D /home/pgsql/data/     #利用pg_ctl启动指定数据库实例
server starting
bash-4.2$ < 2016-10-25 19:46:01.202 CST >LOG:  redirecting log output to logging collector process
< 2016-10-25 19:46:01.202 CST >HINT:  Future log output will appear in directory "pg_log".

bash-4.2$ ss -tpnl |grep 5432                   #查看数据库服务监听的端口是否正常
LISTEN     0      128                       *:5432                     *:*      users:(("postgres",3141,3))
LISTEN     0      128                      :::5432                    :::*      users:(("postgres",3141,4))
bash-4.2$ psql -U postgres                      #psql客户端采用postgres用户登陆数据库（当前登陆的是默认的全局数据库postgres）
psql (9.5.4)
Type "help" for help.

postgres=# \l                                   #执行psql客户端环境下提供的命令，该命令是列出该数据库实例中的所以数据库
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)

postgres=# \q                                    #退出psql客户端
bash-4.2$ exit                                   #退出postgres用户
exit
[root@localhost pgsql]#
```

## 管理登录并修改密码
```sh
bash-4.2$ psql -U postgres                      #psql客户端采用postgres用户登陆数据库（当前登陆的是默认的全局数据库postgres）
psql (9.5.4)
Type "help" for help.

postgres=# \l                                   #执行psql客户端环境下提供的命令，该命令是列出该数据库实例中的所以数据库
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)

postgres=# ALTER USER postgres WITH PASSWORD '1'; #修改管理员密码
ALTER ROLE
postgres=# \q                                     #退出psql客户端
bash-4.2$ exit                                    #退出postgres用户
exit
[root@localhost pgsql]#
```

## 利用数据库GUI工具连接PG
windows下的数据库GUI工具有很多，个人感觉与PG配合比较好用的主要是pgAdmin 3、pgAdmin 4和Navicat Premium了。
pgAdmin 4采用QT重新开发的，GUI非常赞，添加了性能实时监视图表相关的GUI,不过目前才第一版本，多语言和流畅性都还有点问题。

首先需要关闭系统自启动的防火墙
```sh
[root@localhost ~]# systemctl status firewalld.service
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2016-10-25 20:05:51 CST; 16min ago
 Main PID: 750 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─750 /usr/bin/python -Es /usr/sbin/firewalld --nofork --nopid

Oct 25 20:05:48 localhost.localdomain systemd[1]: Starting firewalld - dynamic firewall .....
Oct 25 20:05:51 localhost.localdomain systemd[1]: Started firewalld - dynamic firewall d...n.
Hint: Some lines were ellipsized, use -l to show in full.
[root@localhost ~]# systemctl stop firewalld.service
```

或者开放防火墙端口
```sh
[root@localhost ~]# firewall-cmd --version
0.3.9
[root@localhost ~]# firewall-cmd --zone=public --add-port=5432/tcp --permanent   #添加tcp端口，--permanent表永久生效，没有此参数重启后就失效了
success
[root@localhost ~]# firewall-cmd --reload                                        #重新载入
success
[root@localhost ~]# firewall-cmd --zone=public  --query-port=5432/tcp            #查看
yes
[root@localhost ~]#
```

- Navicat Premium
![](img\Navicat.png)

- pgAdmin 4
![](img\pgAdmin.png)

## 配置PG自启动
* 如果是二进制安装，postgres安装时会自动把postgresql-9.5.service配置文件拷贝到/lib/systemd/
* 如果是源码安装，在源码目录‘postgresql-9.5.0/contrib/start-scripts’中提供了Linux自启动的示例文件，需要手动将该文件拷贝至/etc/systemd/system下，以便systemctl读取相应的配置。

以上的两种方式，我们都需要对自启动Unit文件进行必要的修改来控制到底启动哪一个数据库实例。
打开postgresql-9.5.service文件如下：
```sh
[root@localhost system]# vim postgresql-9.5.service

# It's not recommended to modify this file in-place, because it will be
# overwritten during package upgrades.  If you want to customize, the
# best way is to create a file "/etc/systemd/system/postgresql-9.5.service",
# containing
#       .include /lib/systemd/system/postgresql-9.5.service
#       ...make your changes here...
# For more info about custom unit files, see
# http://fedoraproject.org/wiki/Systemd#How_do_I_customize_a_unit_file.2F_add_a_custom_unit_file.3F

# Note: changing PGDATA will typically require adjusting SELinux
# configuration as well.

# Note: do not use a PGDATA pathname containing spaces, or you will
# break postgresql-setup.
[Unit]
Description=PostgreSQL 9.5 database server
After=syslog.target
After=network.target

[Service]
Type=forking

User=postgres
Group=postgres

# Note: avoid inserting whitespace in these Environment= lines, or you may
# break postgresql-setup.

# Location of database directory
Environment=PGDATA=/var/lib/pgsql/9.5/data/
```

根据文件内的提示，我们不直接去修改‘/lib/systemd’目录下的‘postgresql-9.5.service’文件，而是将该文件拷贝至‘/etc/systemd/system/’目录，并进行如下修改：
```sh
[root@localhost system]# vim /etc/systemd/system/postgresql-9.5.service

# It's not recommended to modify this file in-place, because it will be
# overwritten during package upgrades.  If you want to customize, the
# best way is to create a file "/etc/systemd/system/postgresql-9.5.service",
# containing
#       .include /lib/systemd/system/postgresql-9.5.service
#       ...make your changes here...
# For more info about custom unit files, see
# http://fedoraproject.org/wiki/Systemd#How_do_I_customize_a_unit_file.2F_add_a_custom_unit_file.3F

# Note: changing PGDATA will typically require adjusting SELinux
# configuration as well.

# Note: do not use a PGDATA pathname containing spaces, or you will
# break postgresql-setup.
.include /lib/systemd/system/postgresql-9.5.service       #通过‘.include’指令包含源文件中的配置项

[Service]
Environment=PGDATA=/home/pgsql/data/                      #然后对指定配置项目进行修改
```

设置服务自启动:
```sh
[root@localhost ~]# systemctl list-unit-files |grep postgres
postgresql-9.5.service                      disabled
[root@localhost ~]# systemctl enable postgresql-9.5.service
Created symlink from /etc/systemd/system/multi-user.target.wants/postgresql-9.5.service to /etc/systemd/system/postgresql-9.5.service.
[root@localhost ~]# systemctl list-unit-files |grep postgres
postgresql-9.5.service                      enabled
[root@localhost ~]# systemctl start postgresql-9.5.service
[root@localhost ~]#
```

## 启动多个数据库实例
### 为数据库进程设置标示
在一些场景下，需要在一台机器上运行多个数据库实例，从postgresql-9.0开始可以通过'postgresql.conf'配置文件中的cluster_name参数来设置数据库实例进程的标示。
在系统中查看多个运行的PG实例额的时候，可以通过进程前的cluster_name区分，方便进行分析或者维护操作。

修改cluster_name参数之前，系统中运行一个PG数据库实例的相关进程信息：
```sh
[root@localhost ~]# ps -ef|grep postgres
postgres  2620     1  0 11:41 ?        00:00:00 /usr/pgsql-9.5/bin/postgres -D /home/pgsql/data
postgres  2621  2620  0 11:41 ?        00:00:00 postgres: logger process
postgres  2623  2620  0 11:41 ?        00:00:00 postgres: checkpointer process
postgres  2624  2620  0 11:41 ?        00:00:00 postgres: writer process
postgres  2625  2620  0 11:41 ?        00:00:00 postgres: wal writer process
postgres  2626  2620  0 11:41 ?        00:00:00 postgres: autovacuum launcher process
postgres  2627  2620  0 11:41 ?        00:00:00 postgres: stats collector process
root      2643  2107  0 11:51 pts/0    00:00:00 grep --color=auto postgres
```

修改'postgresql.conf'配置文件中cluster_name参数的值：
```sh
bash-4.2$ vim postgresql.conf
# - Process Title -

cluster_name = 'panhongfa-1'                    # added to process titles if nonempty
                                        # (change requires restart)
#update_process_title = on
```

重启数据库查看进程信息：
```sh
[root@localhost pgsql]# systemctl start postgresql-9.5.service
[root@localhost pgsql]# ps -ef|grep postgres
postgres  3337     1  0 14:16 ?        00:00:00 /usr/pgsql-9.5/bin/postgres -D /home/pgsql/data
postgres  3338  3337  0 14:16 ?        00:00:00 postgres: panhongfa-1: logger process
postgres  3340  3337  0 14:16 ?        00:00:00 postgres: panhongfa-1: checkpointer process
postgres  3341  3337  0 14:16 ?        00:00:00 postgres: panhongfa-1: writer process
postgres  3342  3337  0 14:16 ?        00:00:00 postgres: panhongfa-1: wal writer process
postgres  3343  3337  0 14:16 ?        00:00:00 postgres: panhongfa-1: autovacuum launcher process
postgres  3344  3337  0 14:16 ?        00:00:00 postgres: panhongfa-1: stats collector process
root      3347  2107  0 14:16 pts/0    00:00:00 grep --color=auto postgres
```

### 启动第二个数据库实例

创建第二个数据库实例的目录：
```sh
bash-4.2$ cd /home/pgsql/
bash-4.2$ mkdir -pv data2
mkdir: created directory ‘data2’
bash-4.2$ ls -al
total 4
drwxr-xr-x.  4 postgres postgres   29 Nov  9 14:21 .
drwxr-xr-x.  4 root     root       28 Oct 17 16:09 ..
drwx------. 20 postgres postgres 4096 Nov  9 14:16 data
drwxr-xr-x.  2 postgres postgres    6 Nov  9 14:21 data2
```

创建并初始化化新的数据库实例：
```sh
bash-4.2$ initdb -D data2/
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory data2 ... ok
creating subdirectories ... ok
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting dynamic shared memory implementation ... posix
creating configuration files ... ok
creating template1 database in data2/base/1 ... ok
initializing pg_authid ... ok
initializing dependencies ... ok
creating system views ... ok
loading system objects descriptions ... ok
creating collations ... ok
creating conversions ... ok
creating dictionaries ... ok
setting privileges on built-in objects ... ok
creating information schema ... ok
loading PL/pgSQL server-side language ... ok
vacuuming database template1 ... ok
copying template1 to template0 ... ok
copying template1 to postgres ... ok
syncing data to disk ... ok

WARNING: enabling "trust" authentication for local connections
You can change this by editing pg_hba.conf or using the option -A, or
--auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    pg_ctl -D data2/ -l logfile start
```

修改新实例的IP、端口（5433）以及进程标示：
```sh
bash-4.2$ vim postgresql.conf
# - Connection Settings -

listen_addresses = '*'          # what IP address(es) to listen on;
                                        # comma-separated list of addresses;
                                        # defaults to 'localhost'; use '*' for all
                                        # (change requires restart)
port = 5433                             # (change requires restart)
max_connections = 100                   # (change requires restart)

# - Process Title -

cluster_name = 'panhongfa-2'                    # added to process titles if nonempty
```

修改新实例的访问权限：
```sh
bash-4.2$ vim pg_hba.conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
host    all             all             0.0.0.0/0               md5
# IPv6 local connections:
host    all             all             ::1/128                 trust
```

启动第二个数据库实例并查看实例进程：
```sh
[root@localhost pgsql]# ps -ef|grep postgres
postgres  3337     1  0 14:16 ?        00:00:00 /usr/pgsql-9.5/bin/postgres -D /home/pgsql/data
postgres  3338  3337  0 14:16 ?        00:00:00 postgres: panhongfa-1: logger process
postgres  3340  3337  0 14:16 ?        00:00:00 postgres: panhongfa-1: checkpointer process
postgres  3341  3337  0 14:16 ?        00:00:00 postgres: panhongfa-1: writer process
postgres  3342  3337  0 14:16 ?        00:00:00 postgres: panhongfa-1: wal writer process
postgres  3343  3337  0 14:16 ?        00:00:00 postgres: panhongfa-1: autovacuum launcher process
postgres  3344  3337  0 14:16 ?        00:00:00 postgres: panhongfa-1: stats collector process
postgres  3488     1  0 14:36 pts/0    00:00:00 /usr/pgsql-9.5/bin/postgres -D data2
postgres  3489  3488  0 14:36 ?        00:00:00 postgres: panhongfa-2: logger process
postgres  3491  3488  0 14:36 ?        00:00:00 postgres: panhongfa-2: checkpointer process
postgres  3492  3488  0 14:36 ?        00:00:00 postgres: panhongfa-2: writer process
postgres  3493  3488  0 14:36 ?        00:00:00 postgres: panhongfa-2: wal writer process
postgres  3494  3488  0 14:36 ?        00:00:00 postgres: panhongfa-2: autovacuum launcher process
postgres  3495  3488  0 14:36 ?        00:00:00 postgres: panhongfa-2: stats collector process
root      3497  2107  0 14:37 pts/0    00:00:00 grep --color=auto postgres
```

分别登录这两个数据库实例
```sh
bash-4.2$ psql -p 5432
psql (9.5.4)
Type "help" for help.

postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
-----------+----------+----------+-------------+-------------+-----------------------
 account   | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(4 rows)

postgres=# \q
bash-4.2$ psql -p 5433
psql (9.5.4)
Type "help" for help.

postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)
```
