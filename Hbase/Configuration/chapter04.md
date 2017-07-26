# hbase-policy.xml

采用Hadoop SLA授权机制时，HBase内部的RPC服务器所使用的默认策略配置文件，对客户端的请求做出授权决策，它仅在'security'参数启用时使用。

Hadoop SLA基于Hadoop的各种服务（基于协议来划分）与Linux系统的用户、用户组来实现。Hadoop通过制定接口协议的方式来实现节点之间服务调用的逻辑，这样每一个协议所指定的一组服务就是一个认证单元，再基于底层linux系统的用户和用户组来限制用户（可能是节点服务）有权限执行某一种协议所包含的操作集合。

```
[root@nn conf]# cat hbase-policy.xml
  <configuration>

    <property>
      <name>security.admin.protocol.acl</name>
      <value>*</value>
    </property>

    <property>
      <name>security.client.protocol.acl</name>
      <value>*</value>
    </property>

    <property>
      <name>security.masterregion.protocol.acl</name>
      <value>*</value>
    </property>

  </configuration>
```
