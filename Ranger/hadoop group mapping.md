# LDAP用户组在Ranger中的授权
## 实践中的现象
Ranger从LDAP中同步用户和用户组之后，就可以基于用户及用户组来进行授权，但经过试验之后就会发现，基于用户的授权是有效果的，但基于用户组的授权无效，通过观察Ranger的Audit页面日志会发现Access Enforcer的类型仍然是hadoop-acl，并没有如我们所愿的采用ranger-acl来进行权限判定。

## 那这是什么原因呢？
通过阅读Hadoop文档和资料，我们知道在默认情况下，Hadoop将从集群节点主机的Linux操作系统中获取user/group映射，因此，如果我们尚未将LDAP管理的user+group在集群每个OS节点上进行标识，则Hadoop将无法感知到user和group的存在和关联关系，也就没办法执行相关的组策略。

## 那应该怎么解决呢？
或者换一个问法，那如何让集群内的所有主机都知道LDAP中不断变化的user、group、以及它们的关系呢？
* 方法一: 将LDAP中的user/group实时或者定时的克隆到所有主机的OS中。
* 方法二：换个思路，主机先从OS中匹配，然后通过网络在LDAP中查询并匹配。

很明显，方法一能够解决问题，但是需要人为的不断干预并且还引入了新的用户安全的问题，方法二却是一次配置，终生受用，相对来说即简单又高效。

## 那如何实现OS从LDAP中获取user/group？
我们通过nss-pam-ldapd的NSS(名字服务交换模块)，完成从name到id之间的转换，让OS识别到LDAP中的user+group。

## 编写我们自己的脚本
首先我们需要安装ldap client和nss-pam-ldapd软件包，接下来再完成LDAP相关的配置，最后完成NSS名字交换服务的配置。
编辑安装和配置脚本nss.sh如下：
```shell
cat << 'eof' > nss.sh
#!/usr/bin/env bash

LDAP_HOST_NAME="sldap.daowoo.com"
LDAP_ROOT_ENTRY="dc=daowoo,dc=com"
LDAP_HOST_PORT=389

# 安装LDAP客户端
yum install openldap-clients -y

# 修改/etc/openldap/ldap.conf
echo 'modify ldap.conf'
cp /etc/openldap/ldap.conf /etc/openldap/ldap.conf.bak
sed -i -e '/^#\?BASE/s/^#*//' -e "/BASE/s@ .*@ ${LDAP_ROOT_ENTRY}@" /etc/openldap/ldap.conf
sed -i -e '/^#\?URI/s/^#*//' -e "/URI/s@ .*@ ldap://${LDAP_HOST_NAME}:${LDAP_HOST_PORT}@" /etc/openldap/ldap.conf
[[ `grep 'pam_password.*' /etc/openldap/ldap.conf` ]] || sed -i -e '$a\pam_password md5' /etc/openldap/ldap.conf
[[ `grep 'ssl.*' /etc/openldap/ldap.conf` ]] || sed -i -e '$a\ssl no' /etc/openldap/ldap.conf

#sed -n '/^#\?BASE.*/p' /etc/openldap/ldap.conf| sed -e '/^#\?BASE/s/^#*//' -e "/BASE/s@ .*@ ${LDAP_ROOT_ENTRY}@"
#sed -n '/^#\?URI.*/p' /etc/openldap/ldap.conf| sed -e '/^#\?URI/s/^#*//' -e "/URI/s@ .*@ ldap://${LDAP_HOST_NAME}:${LDAP_HOST_PORT}@"


# 安装NSS和PAM模块
yum install nss-pam-ldapd -y

# 修改/etc/nslcd.conf
echo 'modify nslcd.conf'
cp /etc/nslcd.conf /etc/nslcd.conf.bak
sed -i -e '/^#\?base/s/^#*//' -e "/base/s@ .*@ ${LDAP_ROOT_ENTRY}@" /etc/nslcd.conf
sed -i -e '/^#\?uri/s/^#*//' -e "/uri/s@ .*@ ldap://${LDAP_HOST_NAME}/@" /etc/nslcd.conf
sed -i -e '/^#\?ssl/s/^#*//' -e "/ssl/s@ .*@ no@" /etc/nslcd.conf
sed -i -e '/^#\?tls_cacertdir/s/^#*//' -e "/tls_cacertdir/s@ .*@ /etc/openldap/cacerts@" /etc/nslcd.conf

# 修改nsswitch.conf为ldap，当匹配不到用户信息时，会通过后端配置的LDAP认证服务进行匹配
cp /etc/nsswitch.conf /etc/nsswitch.conf.bak
echo 'modify nsswitch.conf'
sed -i -e "/^passwd:/s@ .*@ files ldap@"  /etc/nsswitch.conf
sed -i -e "/^shadow:/s@ .*@ files ldap@"  /etc/nsswitch.conf
sed -i -e "/^group:/s@ .*@  files ldap@"  /etc/nsswitch.conf
eof
```

执行脚本nss.sh，重启nslcd服务。
```shell
cat << 'eof' > down_nss.sh
#!/usr/bin/env bash

echo 'download nss.sh'
curl -o nss.sh http://192.168.85.200/resource/nss.sh

# 添加权限并执行
. nss.sh

# 配置自启动并重启服务
systemctl enable nslcd.service
systemctl restart nslcd.service

# 通过id命令来测试是否能从ldap获取用户
echo 'Test################################################Test'
id panhongfa
eof

chmod +x down_nss.sh
./down_nss.sh
```
