# 测试


ssh-keygen -t rsa -P ''
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
tail /var/log/secure -n 20

|       hostname       |       ip       |        service         |
| -------------------- | -------------- | ---------------------- |
| hbase1.panhongfa.com | 192.168.36.217 | namenode+HMaster       |
| hbase2.panhongfa.com | 192.168.36.117 | datanode+HRegionServer |
| hbase2.panhongfa.com | 192.168.36.198 | datanode+HRegionServer |
