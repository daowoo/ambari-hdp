# 实现Hadoop集群基于LDAP的统一认证和基于Ranger的统一授权
## 基于LDAP的统一认证
在Hadoop集群中选择一个节点主机作为访问整个集群的入口，在这台主机上安装`NfsGateWay`组件，并且安装所有组件的Client端，限制用户对资源的所有操作均只能在`GW`上进行，然后通过对操作入口GW、认证中心LDAP、授权系统Ranger、Hadoop管理平台Ambari等各自独立的系统进行整合，达到基于LDAP和Ranger来完成统一认证和统一授权的目的。

### Ambari与LDAP的整合
Ambari Server支持从LDAP中`手动同步`用户和组信息，并且通过与`HOOK`脚本配合，能够自动地为新增用户(无论是本地用户还是通过过来的LDAP用户)在HDFS中创建HOME目录，其实现的具体过程如下：

通过ambari-server脚本提供的`setup-ldap`子命令来配置LDAP信息。
```shell
[root@hdp ~]# ambari-server setup-ldap
Using python  /usr/bin/python
Setting up LDAP properties...
Primary URL* {host:port} (sldap.daowoo.com:389):     #LDAP服务器url
Secondary URL {host:port} :                          #主备模式下填入备用LDAP的url
Use SSL* [true/false] (false):                       #不使用ssl加密
User object class* (posixAccount):                   #对照导入LDAP的系统账号类型填写
User name attribute* (uid):                          #一般为uid
Group object class* (posixGroup):                    #对照导入LDAP的系统组类型填写
Group name attribute* (cn):                          #一般为cn
Group member attribute* (memberUid):                 #对应LDAP中组内成员的管理属性填写
Distinguished name attribute* (dn):                  #一般为dn
Base DN* (dc=daowoo,dc=com):                         #根域的名称
Referral method [follow/ignore] (ignore):
Bind anonymously* [true/false] (false):              #是否允许匿名访问
Handling behavior for username collisions [convert/skip] for LDAP sync* (convert):
Manager DN* (cn=admin,dc=daowoo,dc=com):             #LDAP管理员节点
Enter Manager Password* :                            #LDAP配置的管理员密码
Re-enter password:
====================
Review Settings
====================
authentication.ldap.managerDn: cn=admin,dc=daowoo,dc=com
authentication.ldap.managerPassword: *****
Save settings [y/n] (y)? y
Saving...done
Ambari Server 'setup-ldap' completed successfully.
```

编辑Ambari配置文件`ambari.properties`来启用为新增用户创建HOME目录的功能。
```shell
cat /etc/ambari-server/conf/ambari.properties

#添加一下配置项
ambari.post.user.creation.hook.enabled=true
ambari.post.user.creation.hook=/var/lib/ambari-server/resources/scripts/post-user-creation-hook.sh
```

重新启动ambari-server。
```shell
ambari-server restart
```

通过ambari-serve提供的命令来从LDAP同步用户。
```shell
# 从LDAP同步所有用户
ambari-server sync-ldap --all
# 只同步当下存在于ambari中的用户，LDAP已删除的用户此时也会被删除掉
ambari-server sync-ldap --existing
```

### GW与LDAP的整合
关闭`sssd`系统服务。
```shell
systemctl disable sssd.service
systemctl stop sssd.service
```

安装LDAP客户端，并完成`ldap.conf`的配置。
```shell
yum install openldap-clients -y

# 修改/etc/openldap/ldap.conf中的LDAP配置
cp /etc/openldap/ldap.conf /etc/openldap/ldap.conf.bak

cat /etc/openldap/ldap.conf
BASE   dc=daowoo,dc=com
URI    ldap://ldap.daowoo.com:389

TLS_CACERTDIR   /etc/openldap/certs
pam_password md5
ssl no
```

然后安装大名鼎鼎的nss-pam-ldapd，它包含一下两个模块插件和一个后台进程：
* NSS，名字服务交换模块，完成从name到id之间的转换，让OS识别到LDAP中的user和group。
* PAM，插入式验证模块，它集成了很多中认证方法，pam_ldap只是其中的一种，条用LDAP验证user的身份。
* nslcd，服务守护进程，保障与LDAP的持久连接，调用以上两个插件完成user+group名字交互和密码验证。

```shell
# 安装NSS和PAM模块
yum install nss-pam-ldapd -y

# 修改/etc/nslcd.conf中的LDAP的基础配置
cp /etc/nslcd.conf /etc/nslcd.conf.bak

cat /etc/nslcd.conf
uri ldap://ldap.daowoo.com/
base dc=daowoo,dc=com
ssl no
tls_cacertdir /etc/openldap/cacerts
```

配置NSS模块，在nsswitch.conf中增加ldap方式，当files模式匹配不到用户信息时，会通过后端配置的LDAP认证服务进行匹配。
```shell
cp /etc/nsswitch.conf /etc/nsswitch.conf.bak

cat /etc/nsswitch.conf
passwd:     files ldap
shadow:     files ldap
group:      files ldap
```

配置`nslcd`自启动并重启服务。
```shell
systemctl enable nslcd.service
systemctl restart nslcd.service
```

通过id命令来测试是否能从ldap获取用户。
```shell
id panhongfa
```

配置PAM模块，修改/etc/pam.d/system-auth，如果存在`sss`标识的行，先将其注释掉，再增加ldap的配置。
```shell
cp /etc/pam.d/system-auth /etc/pam.d/system-auth.bak

cat /etc/pam.d/system-auth
#%PAM-1.0
# This file is auto-generated.
# User changes will be destroyed the next time authconfig is run.
auth        required      pam_env.so
auth        sufficient    pam_fprintd.so
auth        sufficient    pam_unix.so nullok try_first_pass
auth        sufficient    pam_ldap.so use_first_pass
auth        required      pam_deny.so

account     required      pam_unix.so
account     sufficient    pam_localuser.so
account     sufficient    pam_succeed_if.so uid < 1000 quiet
account     [default=bad success=ok user_unknown=ignore]        pam_ldap.so
account     required      pam_permit.so

password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
password    sufficient    pam_ldap.so use_authtok
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
-session     optional      pam_systemd.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     optional      pam_ldap.so
session     required      pam_unix.so
```

检测系统的/etc/sysconfig/authconfig文件配置，确保以下的标记为yes。
```shell
cat /etc/sysconfig/authconfig

USESHADOW=yes 启用密码验证
PASSWDALGORITHM=md5 密码验证方式为md5
USELDAPAUTH=yes 启用OpenLDAP验证
USELDAP=yes  启用LDAP认证协议
USELOCAUTHORIZE=yes 启用本地验证
```

如果需要调试nslcd服务，需要如下方式手动打开nslcd进程。
```shell
# 停止nslcd服务
systemctl restart nslcd

# 在debug模式下运行nslcd
$(which nslcd) -d

# 查看LDAP服务日志文件slapd.log的内容
tail -f /var/log/slapd/slapd.log
```

在LAM中创建新用户，然后进行以下测试，可以看到已经成功的添加了`panhongfa`的用户，这是OpenLDAP添加的，在本地是没有的。
```shell
[root@hdp ~]# su - panhongfa
Last login: Fri Oct 27 16:21:35 CST 2017 on pts/0
su: warning: cannot change directory to /home/panhongfa: No such file or directory
-bash-4.2$
```

不过此时提示用户没有home directory，通过增加如下配置来解决。
```shell
vi /etc/pam.d/system-auth
session     optional      pam_mkhomedir.so skel=/etc/skel/ umask=0022

[root@hdp ~]# su - panhongfa
Last login: Mon Oct 30 16:42:17 CST 2017 on pts/0
[panhongfa@hdp ~]$ pwd
/home/panhongfa
[panhongfa@hdp ~]$ ls -al
total 20
drwxr-xr-x   3 panhongfa hdfs  103 Oct 30 16:06 .
drwxr-xr-x. 17 root      root 4096 Oct 30 16:01 ..
-rw-------   1 panhongfa hdfs  219 Oct 30 16:42 .bash_history
-rw-r--r--   1 panhongfa hdfs   18 Oct 30 16:01 .bash_logout
-rw-r--r--   1 panhongfa hdfs  193 Oct 30 16:01 .bash_profile
-rw-r--r--   1 panhongfa hdfs  231 Oct 30 16:01 .bashrc
```

为了让LAM新增的用户可以使用ssh方式登录GW，还需要安装openssh的LDAP插件，并完成以下配置。
```shell
yum install openssh-ldap.x86_64 -y

cat /etc/ssh/sshd_config
UsePAM yes
```

接下来修改`/etc/pam.d/sshd`文件。
```shell
cat /etc/pam.d/sshd

# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    required     pam_mkhomedir.so
```

然后修改`/etc/pam.d/password-auth`来配置ldap相关项。
```shell
cat /etc/pam.d/password-auth

#%PAM-1.0
# This file is auto-generated.
# User changes will be destroyed the next time authconfig is run.
auth        required      pam_env.so
auth        sufficient    pam_unix.so nullok try_first_pass
auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success
auth        sufficient    pam_ldap.so use_first_pass
auth        required      pam_deny.so

account     required      pam_unix.so
account     sufficient    pam_localuser.so
account     sufficient    pam_succeed_if.so uid < 1000 quiet
account     [default=bad success=ok user_unknown=ignore] pam_ldap.so
account     required      pam_permit.so

password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
password    sufficient    pam_ldap.so use_authtok
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
-session     optional      pam_systemd.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.so
session     optional      pam_ldap.so
session     optional      pam_mkhomedir.so skel=/etc/skel/ umask=0022
```

最后重启sshd服务。
```shell
systemctl restart sshd
```

通过SSH方式使用LDAP中的用户`panhongfa`来登录GW主机
```shell
[root@hdp ~]# ssh panhongfa@192.168.70.100
panhongfa@192.168.70.100's password:
Last login: Mon Oct 30 16:43:54 2017 from hdp.bigdata.wh.com
[panhongfa@hdp ~]$ pwd
/home/panhongfa
[panhongfa@hdp ~]$ ls -al
total 20
drwxr-xr-x   3 panhongfa hdfs  103 Oct 30 16:06 .
drwxr-xr-x. 17 root      root 4096 Oct 30 16:01 ..
-rw-------   1 panhongfa hdfs  244 Oct 30 16:44 .bash_history
-rw-r--r--   1 panhongfa hdfs   18 Oct 30 16:01 .bash_logout
-rw-r--r--   1 panhongfa hdfs  193 Oct 30 16:01 .bash_profile
-rw-r--r--   1 panhongfa hdfs  231 Oct 30 16:01 .bashrc
```

### Ranger与LDAP的整合
#### 前置需求
* Ranger默认将审核数据`audits`存储在Ambari Infra service组件提供的`Infra Solr`共享实例中，所以该组件必须被安装并且实例被成功启动。
* 通过LDAP方式来进行组和用户级别的授权，需要先配置好可用的LDAP服务。
* Ranger需要使用一个数据库来存储必要的信息，支持MySQL，Oracle，PostgreSQL或Amazon RDS数据库。在安装过程中将创建rangeradmin和rangerlogger两个默认的新用户，以及创建ranger和ranger_audit两个默认的新数据库。

#### 包含的组件
* Ranger Admin：提供一套web ui来完成授权的管理，并且可视化存储在`Infra Solr`中的审核日志。
* Ranger UersSync：连接UNIX系统或LDAP服务器来完成用户和用户组同步。
* Ranger Key Manager：基于Hadoop的KeyProvider API的加密密钥管理服务器，它提供了使用REST API通过HTTP进行通信的客户端和服务器组件。


#### 注意事项
* Kafka和Storm需要先启用Kerberos来完成身份验证，之后再启用Ranger进行授权；
* 2.6版本开始，DB初始化Schema在第一次启动服务时进行，以前都是在安装过程中完成，所以在感觉上
* 安装Ambari Infra之后会启动Solr实例，结合ZK生成solrCloud，Ranger通过zk地址访问solrCloud

#### 如何工作
HDFS Ranger首先检测是否存在对应的授权策略对应用户授权，如果存在那么用户权限检测通过。如果没有这样的策略，那么Ranger插件会启用HDFS原生的权限体系进行权限检查（POSIX or HDFS ACL）。这种模型在Ranger中适用于HDFS和YARN服务。而对于Hive或者HBase，Ranger是作为唯一的有效授权依据

* 如果在界面上“Access Enforcer”列的内容为“Ranger-acl”，那说明Ranger的策略被应用到了用户身上
* 如果“Access Enforcer”列的内容为“Hadoop-acl”,表示该访问是由HDFS原生的POSIX权限和HDFS ACL提供的。

#### 安装部署
首先安装PG数据库，并创建Ranger组件的元信息数据库ranger以及登录用户ranger。
```sql
echo 'CREATE RANGER DATABASE'
sudo -u postgres psql
CREATE DATABASE ranger;
CREATE USER ranger WITH PASSWORD '1';
GRANT ALL PRIVILEGES ON DATABASE ranger TO ranger;

\c ranger
CREATE SCHEMA ranger AUTHORIZATION ranger;
ALTER SCHEMA ranger OWNER TO ranger;
ALTER ROLE ranger SET search_path to 'ranger', 'public';
\q
```

然后，通过ambari UI添加Ranger组件，详细过程请参考`hortonworks`官网文档[Ranger Installation](https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.1/bk_security/content/ranger_install.html)章节。

#### LDAP配置
* 进入ambrai ui->ranger->Ranger User Info页面;
* 设置`Enable User Sync`, 启用用户同步;
* 设置`LDAP/AD`,将同步的源设置为LDAP方式；
* 在Common Configs选项页面中设置`LDAP/AD URL=ldap://sldap.daowoo.com:389`
* 在Common Configs选项页面中设置`​Bind User=cn=admin,dc=daowoo,dc=com`并配置验证密码`Bind User Password=xxx`
* 在User Configs选项页面中设置`Username Attribute=uid`、`User Object Class​=posixAccount`、`User Search Base=ou=People,dc=daowoo,dc=com`、`User Search Scope=sub`、`User Group Name Attribute=gidNumber`
* 在User Configs选项页面中使能`Group User Map Sync`选项
* 在Group Configs选项页面中设置`Group Member Attribute=memberUid`、`Group Name Attribute=cn`、`Group Object Class=posixGroup`、`Group Search Base=ou=Group,dc=daowoo,dc=com`
* 在Group Configs选项页面中使能`Enable Group Sync`选项

#### 配置授权
通过ambari UI启用Ranger插件，以及Infra Solr的配置，最后根据从LDAP同步过来的用户和组来进行授权，详细过程请参考`hortonworks`官网文档[Using Ranger to Provide Authorization in Hadoop](https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.1/bk_security/content/using_ranger_to_provide_authorization_in_hadoop.html)章节。

#### HDFS中的Ranger实践方案
Ranger安装和配置完成之后，如何结合HDFS文件系统的ACL机制来完成对各个目录的授权，请参考`hortonworks`博客文档[Best Practices](https://hortonworks.com/blog/best-practices-in-hdfs-authorization-with-apache-ranger/)章节。

### Hive与LDAP的整合
