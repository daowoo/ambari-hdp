# Namespace
## 定义
对一组表的逻辑分组，同一组中的表有相似的用途，类似RDBMS中的database，方便对表在业务需求上有一定的划分。

命名空间的概念为即将到来的多租户特性打下基础。其作用包括：
- **配额管理**，限制一个namespace可以使用的资源，资源包括region和table等。
- **命名空间安全管理**，提供了另一个层面的多租户安全管理。
- **Region服务器组**，一个命名空间或一张表，可以被固定到在、一组RegionServers上，从而保证了数据隔离性。

## 默认
Hbase系统默认定义了两个缺省的namespace。
- **hbase**，系统命名空间，用于包含系统的内建表，如namespace和meta表。
- **default**，用户建表时所有未指定namespace的表都自动进入该命名空间。

表和命名空间的隶属关系在在创建表时决定，通过```<namespace>:<table>```的格式来指定，当为一张表指定命名空间之后，对表的操作都要加命名空间，否则会找不到表。

## 操作
- 创建namespace：```create_namespace 'ns'```
- 删除namespace：```drop_namespace 'ns'```
- 查看namespace：```describe_namespace 'ns'```
- 列出所有namespace：```list_namespace```
- 在namespace下创建表：```create 'ns:tables01', 'r1'```
- 查看namespace下的表：```list_namespace_tables 'ns'```