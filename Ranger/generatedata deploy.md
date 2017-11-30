# 模拟数据生成器generatedata
generatedata是基于php开发，可自定义复杂的数据格式，支持多种文件导出的随机数据生成工具，它以列为单位来定义数据类型和取值范围，最终随机生成每一行数据。

## 下载
下载最新版本的[generatedata](http://benkeen.github.io/generatedata/install.html)webServer包。

## 部署
### 环境依赖
* php 5.3以上版本
* Mysql 4以上版本
* apache http服务

### 安装过程
安装mysql数据库
```shell
yum -y install mariadb mariadb-serve
```

完成mysql初始化配置
```shell
[root@repo yum.repos.d]# mysql_secure_installation

Enter current password for root (enter for none):    #首次运行直接回车进入mysql
OK, successfully used password, moving on...

Setting the root password ensures that nobody can log into the MariaDB
root user without the proper authorisation.

Set root password? [Y/n] y        #是否设置root用户密码，输入y并回车或直接回车
New password:                     #设置root用户的密码
Re-enter new password:
Password updated successfully!
Reloading privilege tables..
 ... Success

Remove anonymous users? [Y/n] y   #是否删除匿名用户
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] n  #是否禁止root远程登录
 ... skipping.

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] n   #是否删除test数据库
 ... skipping.

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] y  #是否重新加载权限表
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!
```

登录mysql并创建数据库
```shell
[root@repo yum.repos.d]# mysql -u root -p
MariaDB [(none)]> create database csv_db;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| csv_db             |
| mysql              |
| performance_schema |
| test               |
+--------------------+
5 rows in set (0.00 sec)
```

安装php和httpd
```shell
yum install -y php httpd
```

配置webServer
```shell
# 解压generatedata包
tar -zxvf benkeen-generatedata-3.2.8-1-ga5d6fea.tar.gz
mv benkeen-generatedata-a5d6fea generatedata
mv generatedata /home/

# 添加虚拟主机
vi /etc/httpd/conf.d/generate_data.conf
<VirtualHost *:8008>
 DocumentRoot "/home/generatedata"
 <Directory "/home/generatedata">
  Options FollowSymLinks
  AllowOverride None
  Require all granted
 </Directory>
</VirtualHost>

# 在httpd主配置文件中插入新增的虚拟主机配置文件
vi /etc/httpd/conf/httpd.conf
# Supplemental configuration
#
# Load config files in the "/etc/httpd/conf.d" directory, if any.
IncludeOptional conf.d/autoindex.conf
IncludeOptional conf.d/php.conf             #http新版本调整了主配置文件中关于php的配置项，需要手动加载
IncludeOptional conf.d/generate_data.conf
IncludeOptional conf.d/repos.conf
```
