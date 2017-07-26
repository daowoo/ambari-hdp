# regionservers

这个文件罗列了所有region server的主机名(FQDN)，它的格式是纯文本文件，文件中的每一行都是一台region server的主机的FQDN。Hbase的运维脚本会依次迭代访问每一行来启动所有的regionserver进程。

```
[root@dn001 0]# cat regionservers

dn003.daowoo.com
dn002.daowoo.com
dn001.daowoo.com
```
