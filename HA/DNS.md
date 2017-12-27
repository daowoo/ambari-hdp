# DNS主从方案
## DNS简介
### 实现工具
* bind: 实现提供DNS服务的主程序包
* bind-libs: bind程序包所需要的库文件
* bind-utils: 包含一系列用于测试和查询DNS的命令,如：dig, host, nslookup

### 配置文件
#### 主配置文件named.conf
* 一台物理服务器可同时为多个区域提供解析
* 必须要有根区域文件 named.ca
* 应该有两个（如果包括IPv6，应该更多）实现 localhost 和 本地回环地址的解析库

```sh
# options 为全局配置
options {
        # 监听端口 53 在 localhost和192.168.70.100 地址上
        listen-on port 53 { 127.0.0.1; 192.168.70.100; };

        # 监听端口 53 在 ipv6 回环接口上
        listen-on-v6 port 53 { ::1; };

        # 区域配置文件目录
        directory       "/var/named";

        # 解析过的内容的缓存
        dump-file       "/var/named/data/cache_dump.db";

        # 静态缓存
        statistics-file "/var/named/data/named_stats.txt";

        # 静态缓存（内存中）
        memstatistics-file "/var/named/data/named_mem_stats.txt";

        # 允许进行DNS查询客户机的地址，any表示运行所有主机查询
        allow-query     { localhost; any; };

        # 是否允许客户机进行递归查询
        recursion yes;

        # 是否开启 dnssec，建议测试时关闭
        dnssec-enable yes;

        # 是否开启 dnssec 验证
        dnssec-validation yes;

        /* Path to ISC DLV key */
        bindkeys-file "/etc/named.iscdlv.key";

        # 管理密钥文件的位置
        managed-keys-directory "/var/named/dynamic";
};

# logging 为日志
logging {
        # channel 定义通道名
        channel default_debug {
                # 日志文件 位于 /var/named/data/named.run
                file "data/named.run";

                # 控制日志级别
                severity dynamic;
        };
};

# 定义区域名为"."
zone "." IN {
        # 类型为 根
        type hint;
        # 区域解析库文件名，此处为默认根服务器地址
        file "named.ca";
};

# 扩展区域配置文件
include "/etc/named.rfc1912.zones";
# 根区域的 key
include "/etc/named.root.key";
```

#### 扩展区域配置文件named.rfc1912.zones
添加特定zone的正反解析区域定义。
```sh
zone "localhost.localdomain" IN {
        type master;
        file "named.localhost";
        allow-update { none; };
};

zone "localhost" IN {
        type master;
        file "named.localhost";
        allow-update { none; };
};

zone "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa" IN {
        type master;
        file "named.loopback";
        allow-update { none; };
};

zone "1.0.0.127.in-addr.arpa" IN {
        type master;
        file "named.loopback";
        allow-update { none; };
};

zone "0.in-addr.arpa" IN {
        type master;
        file "named.empty";
        allow-update { none; };
};
```

区域定义格式。
```sh
# ZONE_NMAE 为定义的区域名
zone "ZONE_NAME" IN {
    # type 定义区域类型
    # master 为主
    # slave 为从
    # hint 为根
    # forward 为转发
    type {master|slave|hint|forward};

    # file 定义区域解析库文件名
    # 存放位置 绝对路径为 /var/named/[ZONE_NAME.zone]
    file "ZONE_NANE.zone";
}
```

#### 区域解析库文件
* 无论正反向解析都各需要一个解析库分别负责本地域名的正向和反向解析
* 区域解析库由众多 RR（Resource Recodr） 组成
  - SOA：起始授权记录
  - A：Internet Address，作用，FQDN 到 IP
  - AAAA：FQDN 到 IPv6
  - PTR：PoinTeR，IP 到 FQDN
  - NS：Name Server，专用于表明当前区域的DNS服务器
  - CNAME：Canonical Name，别名记录
  - MX：Mail eXchanger，邮件交换器


正向解析文件`test.com.zone`定义
```sh
#宏定义TTL值为 86400 秒，记录省略未填写的 TTL值的记录，将自动代入该TTL值
$TTL 86400

#宏定义 ORIGIN（当前区域的名字），以便于 @ 引用，或 自动代入
$ORIGIN test.com.

#@ 引用当前区域名"test.com."
#SOA 指明 ns1.test.com. 为当前区域权威服务器（主DNS服务器）
#admin.test.com 当前区域管理员的邮箱地址，但地址中不能使用@符号，一般用.替换
@       IN      SOA     ns1.test.com.   admin.test.com. (
        2017011301  #序列号
        1H          #刷新时间
        5M          #重试时间
        7D          #过期时间
        1D          #否定答案的TTL值
)
#DNS服务器的NS记录
        IN      NS      ns1

#管理员添加的A记录
ns1     IN      A       192.168.80.130
www     IN      A       192.168.80.130
        IN      A       192.168.80.130
*       IN      A       192.168.80.130
```

反向解析文件`192.168.80.zone`定义
```sh
$TTL 86400

#通常反向解析区域名，约定俗成的规则为该网络地址反写拼接 “.in-addr.arpa”
$ORIGIN 80.168.192.in-addr.arpa.

#此时@ 引用的是当前区域名"80.168.192.in-addr.arpa."
@       IN      SOA     ns1.test.com.   admin.test.com. (
        2017011301
        1H
        5M
        7D
        1D
)

#DNS服务器的NS记录
        IN      NS      ns1.test.com.

#管理员添加的PTR记录
130     IN      PTR     ns1.test.com.
130     IN      PTR     www.test.com.
```

注意事项
* 在 /var/named 目录下新创建的区域解析文件默认所属组属于root，named用户将无法读取，我们需要修改用户和用户组为named
* 区域解析库文件中 第一条必须为 SOA，一个区域解析库有且仅能有一个SOA记录，而必须为解析库的第一条记录
* 在资源记录定义的 代表为 根的 . （点号）必不可少

## 主从方案
为了提高DNS服务的可用性，可以部署DNS主从同步以实现数据备份，或用以实现读写分离，DNS可以部署为一主多从，同步范围可以控制到具体的zone。

### 主从角色
* master：维护所负责解析的zone内解析库的服务器；解析库由管理员维护
* slave：从master服务器或其它的slave服务器那里“复制”（区域传递）一份解析库

### 主从结构
![主从结构](img\dns.png)

### 同步过程
* master更新完配置后，首先会向slave发送notify消息
* 随后slave向master发送SOA查询请求
* master将SOA记录应答返回给slave
* slave对比返回信息中的serial，如果小于自己的serial就结束同步过程，如果大于则向master发送zone transfer请求
* master响应后会发送结果，slave接收数据，完成更新

### 配置过程
#### DNS Master
安装并修改主配置文件named.conf
```sh
echo "define variable"
domain="bigdata.wh.com"
ip_arpa="168.192.in-addr.arpa"

master_ip="192.168.70.100"
slaver_ip="192.168.70.200"
public_ip="192.168.30.1"

master_host="ser."${domain}
slaver_host="bak."${domain}

ip_arpa_master="100.70"
ip_arpa_slaver="200.70"

sudo yum install -y bind
sudo cp -f /etc/named.conf /etc/named.conf.bak

[[ `sudo grep "${master_ip};" /etc/named.conf` ]] || \
sudo sed -i -e "/listen-on port/s@127.0.0.1;@127.0.0.1; ${master_ip};@" /etc/named.conf

[[ `sudo grep "any;" /etc/named.conf` ]] || \
sudo sed -i -e "/allow-query/s@localhost;@localhost; any;@" /etc/named.conf
```

添加正向区域文件和反向区域文件配置项
```sh
[[ `sudo grep "${domain}" /etc/named.rfc1912.zones` ]] || \
sudo cat << eof >> /etc/named.rfc1912.zones
zone "${domain}" IN {
    type master;
    file "${domain}.zone";
    notify yes;
    also-notify { ${slaver_ip}; };
    allow-transfer { ${slaver_ip}; };
};

eof

[[ `sudo grep "${ip_arpa}" /etc/named.rfc1912.zones` ]] || \
sudo cat << eof >> /etc/named.rfc1912.zones
zone "${ip_arpa}" IN {
    type master;
    file "${ip_arpa}.zone";
    notify yes;
    also-notify { ${slaver_ip}; };
    allow-transfer { ${slaver_ip}; };
};
eof
```

创建正向解析文件与反向解析文件
```sh
sudo cat << eof > /var/named/${domain}.zone
\$TTL 600
\$ORIGIN ${domain}.
@ IN SOA ${master_host}. admin.${domain}. (
20170703
1H
5M
1W
10M )
        IN  NS  ser
        IN  NS  bak
ser     IN  A   ${master_ip}
bak     IN  A   ${slaver_ip}

master  IN  CNAME  ser
slaver  IN  CNAME  bak

*       IN  A      ${public_ip}
eof

sudo cat << eof > /var/named/${ip_arpa}.zone
\$TTL 600
\$ORIGIN ${ip_arpa}.
@ IN SOA ${master_host}. admin.${domain}. (
20170703
1H
5M
1W
10M )
        IN  NS   ${master_host}.
        IN  NS   ${slaver_host}.
${ip_arpa_master}  IN  PTR  ${master_host}.
${ip_arpa_slaver}  IN  PTR  ${slaver_host}.
eof
```

修改新增zone文件的owner属性
```sh
sudo chown named:named /var/named/${domain}.zone
sudo chmod 640 /var/named/${domain}.zone

sudo chown named:named /var/named/${ip_arpa}.zone
sudo chmod 640 /var/named/${ip_arpa}.zone
```

检查主配置和区域配置是否有词法错误
```sh
sudo named-checkconf
named-checkzone ${domain} /var/named/${domain}.zone
named-checkzone ${ip_arpa} /var/named/${ip_arpa}.zone
```

确认无误后重启DNS服务
```sh
echo 'restart named.service'
sudo systemctl restart named.service
sudo systemctl enable named.service
```

对Master DNS中定义的信息进行查询验证
```sh
sudo yum install -y bind-utils

host -t NS $domain $master_ip
host -t A $master_host $master_ip
host -t A $slaver_host $master_ip
host -t PTR $master_ip $master_ip
host -t PTR $slaver_ip $master_ip
```

Master DNS配置中的注意事项
* 主服务器应该为一台独立的名称服务器
* 主服务器的区域解析库文件中必须有一条NS记录是指向从服务器
* 主服务器必须允许从服务器作区域传送复制

#### DNS Slaver
安装并修改主配置文件named.conf
```sh
echo "define variable"
domain="bigdata.wh.com"
ip_arpa="168.192.in-addr.arpa"

master_ip="192.168.70.100"
slaver_ip="192.168.70.200"
public_ip="192.168.30.1"

master_host="ser."${domain}
slaver_host="bak."${domain}

ip_arpa_master="100.70"
ip_arpa_slaver="200.70"

sudo yum install -y bind
sudo cp -f /etc/named.conf /etc/named.conf.bak

[[ `sudo grep "${slaver_ip};" /etc/named.conf` ]] || \
sudo sed -i -e "/listen-on port/s@127.0.0.1;@127.0.0.1; ${slaver_ip};@" /etc/named.conf

[[ `sudo grep "any;" /etc/named.conf` ]] || \
sudo sed -i -e "/allow-query/s@localhost;@localhost; any;@" /etc/named.conf
```

添加正向区域文件和反向区域文件配置项
```sh
[[ `sudo grep "${domain}" /etc/named.rfc1912.zones` ]] || \
sudo cat << eof >> /etc/named.rfc1912.zones
zone "${domain}" IN {
    type slave;
    file "slaves/${domain}.zone";
    masters { ${master_ip}; };
};
eof

[[ `sudo grep "${ip_arpa}" /etc/named.rfc1912.zones` ]] || \
sudo cat << eof >> /etc/named.rfc1912.zones
zone "${ip_arpa}" IN {
    type slave;
    file "slaves/${ip_arpa}.zone";
    masters { ${master_ip}; };
};
eof
```

检查主配置是否有词法错误
```sh
sudo named-checkconf
```

确认无误后重启DNS服务
```sh
echo 'restart named.service'
sudo systemctl restart named.service
sudo systemctl enable named.service
```

最后在`/var/named/slaves/`目录能看到同步过来的区域解析库文件
```sh
sudo ls -al /var/named/slaves
```

对Slaver DNS进行查询验证
```sh
sudo yum install -y bind-utils

host -t NS $domain $slaver_ip
host -t A $master_host $slaver_ip
host -t A $slaver_host $slaver_ip
host -t PTR $master_ip $slaver_ip
host -t PTR $slaver_ip $slaver_ip
```

Slaver DNS配置中的注意事项
* 从服务器只需要定义区域，而无须提供解析库文件；解析库文件应该放置于/var/named/slaves/目录中
* bind程序的版本应该保持一致；否则，应该从高，主低
* 如果未能同步，请检查主服务器的位于/var/named/目录下区域解析库的所属组权限是否正确
* 可以使用 tail -f /var/log/messages 查看DNS服务日志来解决问题

### 测试主备同步过程
主备同步的过程分为两类：
* axfr: 完全区域传送-------->传送区域内的所有解析信息------------->第一次完成主从配置后进行全量同步
* ixfr: 部分区域传送-------->只传输发生了变化的内容--------------->初始全量同步完成后，后续均采用增量同步

也就是说当/var/named/slaves内没有从Master同步过来的zone文件时，启动Slaver会进行一次全量同步把所有的信息同步过来，但后续如果在Master内修改了zone解析信息，Slaver首先会比较`serail number`,如果发现其值比Slaver当前值要大，才会进行增量同步，否则不会同步。

所以如下面的实例所示，我们每次对Master的zone解析文件修改后，都必须要对其`serail number`进行自增操作。

首先将hdp集群的三个节点的A记录和PTR记录添加到Master DNS主机的正向解析文件和反向解析文件中
```sh
ip_arpa="168.192.in-addr.arpa"

master_ip="192.168.70.100"
slaver_ip="192.168.70.200"
node1_ip="192.168.70.101"
node2_ip="192.168.70.102"
node3_ip="192.168.70.103"
public_ip="192.168.30.1"

master_host="ser."${domain}
slaver_host="bak."${domain}
node1_host="node1."${domain}
node2_host="node2."${domain}
node3_host="node3."${domain}

ip_arpa_master="100.70"
ip_arpa_slaver="200.70"
ip_arpa_node1="101.70"
ip_arpa_node2="102.70"
ip_arpa_node3="103.70"

sudo cat << eof >> /var/named/${domain}.zone
node1     IN  A   ${node1_ip}
node2     IN  A   ${node2_ip}
node3     IN  A   ${node3_ip}
eof

sudo cat << eof >> /var/named/${ip_arpa}.zone
${ip_arpa_node1}  IN  PTR  ${node1_host}.
${ip_arpa_node2}  IN  PTR  ${node2_host}.
${ip_arpa_node3}  IN  PTR  ${node3_host}.
eof
```

如果不修改zone文件中的`serail number`，直接重启Master，此时Slaver日志显示和测试命令结果如下:
```sh
# 日志
tail -f /var/log/messages
Dec 13 17:01:01 bak systemd: Started Session 5 of user root.
Dec 13 17:01:01 bak systemd: Starting Session 5 of user root.
Dec 13 17:01:18 bak named[1460]: client 192.168.70.100#14180: received notify for zone 'bigdata.wh.com'
Dec 13 17:01:18 bak named[1460]: zone bigdata.wh.com/IN: notify from 192.168.70.100#14180: zone is up to date
Dec 13 17:01:19 bak named[1460]: client 192.168.70.100#31310: received notify for zone '168.192.in-addr.arpa'
Dec 13 17:01:19 bak named[1460]: zone 168.192.in-addr.arpa/IN: notify from 192.168.70.100#31310: zone is up to date

# 测试结果
host -t A $node3_host $master_ip
Using domain server:
Name: 192.168.70.100
Address: 192.168.70.100#53
Aliases:

node3.bigdata.wh.com has address 192.168.70.103
host -t A $node3_host $slaver_ip
Using domain server:
Name: 192.168.70.200
Address: 192.168.70.200#53
Aliases:

node3.bigdata.wh.com has address 192.168.30.1

host -t PTR $node3_ip $master_ip
Using domain server:
Name: 192.168.70.100
Address: 192.168.70.100#53
Aliases:

103.70.168.192.in-addr.arpa domain name pointer node3.bigdata.wh.com.

host -t PTR $node3_ip $slaver_ip
Using domain server:
Name: 192.168.70.200
Address: 192.168.70.200#53
Aliases:

Host 103.70.168.192.in-addr.arpa. not found: 3(NXDOMAIN)
```

如果对zone文件中的`serail number`进行自增操作，然后再重启Master，此时Slaver日志显示和测试命令结果如下:
```sh
# 日志
tail -f /var/log/messages
Dec 13 17:11:08 bak named[1460]: client 192.168.70.100#6755: received notify for zone 'bigdata.wh.com'
Dec 13 17:11:08 bak named[1460]: zone bigdata.wh.com/IN: Transfer started.
Dec 13 17:11:08 bak named[1460]: transfer of 'bigdata.wh.com/IN' from 192.168.70.100#53: connected using 192.168.70.200#34643
Dec 13 17:11:08 bak named[1460]: zone bigdata.wh.com/IN: transferred serial 20170705
Dec 13 17:11:08 bak named[1460]: transfer of 'bigdata.wh.com/IN' from 192.168.70.100#53: Transfer completed: 1 messages, 12 records, 304 bytes, 0.001 secs (304000 bytes/sec)
Dec 13 17:11:08 bak named[1460]: zone bigdata.wh.com/IN: sending notifies (serial 20170705)
Dec 13 17:11:09 bak named[1460]: client 192.168.70.100#13141: received notify for zone '168.192.in-addr.arpa'
Dec 13 17:11:09 bak named[1460]: zone 168.192.in-addr.arpa/IN: Transfer started.
Dec 13 17:11:09 bak named[1460]: transfer of '168.192.in-addr.arpa/IN' from 192.168.70.100#53: connected using 192.168.70.200#58615
Dec 13 17:11:09 bak named[1460]: zone 168.192.in-addr.arpa/IN: transferred serial 20170705
Dec 13 17:11:09 bak named[1460]: transfer of '168.192.in-addr.arpa/IN' from 192.168.70.100#53: Transfer completed: 1 messages, 9 records, 277 bytes, 0.001 secs (277000 bytes/sec)
Dec 13 17:11:09 bak named[1460]: zone 168.192.in-addr.arpa/IN: sending notifies (serial 20170705)

# 测试结果
host -t A $node3_host $slaver_ip
Using domain server:
Name: 192.168.70.200
Address: 192.168.70.200#53
Aliases:

node3.bigdata.wh.com has address 192.168.70.103
host -t PTR $node3_ip $slaver_ip
Using domain server:
Name: 192.168.70.200
Address: 192.168.70.200#53
Aliases:

103.70.168.192.in-addr.arpa domain name pointer node3.bigdata.wh.com.
```

### 测试主备切换过程
在hdp集群的各个节点上配置DNS
```sh
#dns config
echo 'modify dns config'
sudo cat << eof > /etc/NetworkManager/NetworkManager.conf
[main]
plugins=ifcfg-rh
dns=none

[logging]
#level=DEBUG
#domains=ALL
eof

sudo systemctl restart NetworkManager.service
sudo cat << eof > /etc/resolv.conf
# Generated by NetworkManager
search $domain
nameserver $master_ip
nameserver $slaver_ip
eof
```

测试是否识别FQDN
```sh
ping ${master_host}
PING ser.bigdata.wh.com (192.168.70.100) 56(84) bytes of data.
64 bytes from ser.bigdata.wh.com (192.168.70.100): icmp_seq=1 ttl=64 time=0.548 ms
64 bytes from ser.bigdata.wh.com (192.168.70.100): icmp_seq=2 ttl=64 time=0.555 ms

ping ${slaver_host}
PING bak.bigdata.wh.com (192.168.70.200) 56(84) bytes of data.
64 bytes from bak.bigdata.wh.com (192.168.70.200): icmp_seq=1 ttl=64 time=0.237 ms
64 bytes from bak.bigdata.wh.com (192.168.70.200): icmp_seq=2 ttl=64 time=1.06 ms

ping ${node2_host}
PING node2.bigdata.wh.com (192.168.70.102) 56(84) bytes of data.
64 bytes from node2.bigdata.wh.com (192.168.70.102): icmp_seq=1 ttl=64 time=0.486 ms
64 bytes from node2.bigdata.wh.com (192.168.70.102): icmp_seq=2 ttl=64 time=1.22 ms
```

关闭Master DNS，测试是否识别FQDN
```sh
ping ${master_host}
PING ser.bigdata.wh.com (192.168.70.100) 56(84) bytes of data.
From node1.bigdata.wh.com (192.168.70.101) icmp_seq=5 Destination Host Unreachable
From node1.bigdata.wh.com (192.168.70.101) icmp_seq=6 Destination Host Unreachable
From node1.bigdata.wh.com (192.168.70.101) icmp_seq=7 Destination Host Unreachable

ping ${slaver_host}
PING bak.bigdata.wh.com (192.168.70.200) 56(84) bytes of data.
64 bytes from bak.bigdata.wh.com (192.168.70.200): icmp_seq=1 ttl=64 time=0.256 ms
64 bytes from bak.bigdata.wh.com (192.168.70.200): icmp_seq=2 ttl=64 time=0.112 ms
64 bytes from bak.bigdata.wh.com (192.168.70.200): icmp_seq=3 ttl=64 time=0.612 ms

ping ${node2_host}
PING node2.bigdata.wh.com (192.168.70.102) 56(84) bytes of data.
64 bytes from node2.bigdata.wh.com (192.168.70.102): icmp_seq=1 ttl=64 time=0.233 ms
64 bytes from node2.bigdata.wh.com (192.168.70.102): icmp_seq=2 ttl=64 time=0.249 ms
64 bytes from node2.bigdata.wh.com (192.168.70.102): icmp_seq=3 ttl=64 time=0.197 ms
```
