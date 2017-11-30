# LDAP
## 概念
LDAP是轻量目录访问协议，Lightweight Directory Access Protocol，它从X.500目录访问协议的基础上发展过来，目前版本是3.0。
与LDAP一样提供类似的目录服务软件还有ApacheDS、Active Directory、Red Hat Directory Service。

## 目录服务
目录是一个为查询、浏览和搜索而优化的专业分布式数据库，它呈树状结构组织数据，就好象Linux/Unix系统中的文件目录一样。
目录数据库和关系数据库不同，它有优异的读性能，但写性能差，并且没有事务处理、回滚等复杂功能，不适于存储修改频繁的数据。所以目录天生是用来查询的，就好象它的名字一样。

目录服务是由目录数据库和一套访问协议组成的系统。类似以下的信息适合储存在目录中：
> 企业员工信息，如姓名、电话、邮箱等
> 公用证书和安全密钥
> 公司的物理设备信息，如服务器，它的IP地址、存放位置、厂商、购买时间等

## 特点
* LDAP的结构用树来表示，而不是用表格。正因为这样，就不能用SQL语句了
* LDAP可以很快地得到查询结果，不过在写方面，就慢得多
* LDAP提供了静态数据的快速查询方式
* Client/server模型，Server 用于存储数据，Client提供操作目录信息树的工具
* 这些工具可以将数据库的内容以文本格式（LDAP 数据交换格式，LDIF）呈现在您的面前
* LDAP是一种开放Internet标准，LDAP协议是跨平台的Interent协议

## 术语
### Entry
被称为条目，一个entry就是一条记录，是LDAP中一个基本的存储单元；也可以被看作是一个DN和一组属性的集合。注意，一条entry可以包含多个objectClass，例如zhang3可以存在于“电话薄”中，也可以同时存在于“同学录”中。

### DN
Distinguished Name，LDAP中entry的唯一辨别名，一条完整的DN写法：`uid=zhang3,ou=People,dc=163,dc=com`。LDAP中的entry只有DN是由LDAP Server来保证唯一的。

### Base DN
一条Base DN可以是`dc=163,dc=com`，也可以是`dc=People,dc=163,dc=com`。执行LDAP Search时一般要指定basedn，由于LDAP是树状数据结构，指定basedn后，搜索将从BaseDN开始，我们可以指定Search Scope来限定搜索范围：
* 只搜索basedn（base）
* basedn直接下级（one level）
* basedn全部下级（sub tree level）

### LDAP Search filter
Filter一般由 (attribute=value) 这样的单元组成，比如：`(&(uid=ZHANGSAN)(objectclass=person))` 表示搜索用户中，uid为ZHANGSAN的LDAP Entry．再比如：`(&(|(uid= ZHANGSAN)(uid=LISI))(objectclass=person))`，表示搜索uid为ZHANGSAN, 或者LISI的用户；也可以使用`*`来表示任意一个值，比如`(uid=ZHANG*SAN)`，搜索uid值以ZHANG开头SAN结尾的Entry。更进一步，根据不同的LDAP属性匹配规则，可以有如下的Filter： `(&（createtimestamp>=20050301000000）(createtimestamp<=20050302000000))`，表示搜索创建时间在20050301000000和20050302000000之间的entry。

Filter中 “&” 表示“与”；“!”表示“非”；“|”表示“或”。根据不同的匹配规则，我们还可以使用“=”，“~=”，“>=”以及“<=”等。

### Objectclass
LDAP内置的数据模型，一个条目(Entry)必须包含一个对象类(objectClass)属性，且需要赋予至少一个值。每一个值将用作一条LDAP条目进行数据存储的模板；模板中包含了一个条目必须被赋值的属性和可选的属性。objectClass还有着严格的等级之分，最顶层是top和alias。

objectClass可分为以下3类：
结构型（Structural）：如account、inetOrgPerson、person和organizationUnit；
辅助型（Auxiliary）：如extensibeObject；
抽象型（Abstract）：如top，抽象型的objectClass不能直接使用。

每种objectClass有自己的数据结构，比如我们有一种叫“电话薄”的objectClass，肯定会内置很多属性(attributes)，如姓名(uid)，身份证号(uidNumber)，单位名称(gid)，家庭地址(homeDirectory)等，同时，还有一种叫“同学录”的objectClass，具备“电话薄”里的一些attributes(如uid、homeDirectory)，还会具有“电话薄”没有的attributes(如description等)，这些属性(attributes)中，有些是必填的，例如，account就要求userid是必填项，而inetOrgPerson则要求cn(common name,常用名称)和sn(sure name,真实名称)是必填项。
