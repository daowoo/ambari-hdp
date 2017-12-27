# HDFS文件系统权限和ACL
## 权限模型概述
HDFS的文件和目录权限模型共享了`POSIX`（Portable Operating System Interface，可移植操作系统接口）模型的很多部分，比如每个文件和目录与一个拥有者和组相关联，文件或者目录对于其拥有者、组内的其它用户以及组外的其它用户有不同的权限等。

但是，与POSIX模型不同的是，HDFS中的文件没有可执行文件的概念，虽然目录保留着可执行目录的概念（x），但对于目录却没有`setuid`和`setgid`。`sticky bit`(粘连)可以用在目录上，用于阻止除`root`和`owner`以外的任何用户删除或移动目录中的文件，不过文件上的粘贴位却完全不起作用。

## 用户认定和权限检查
当创建文件或目录时，拥有者为运行客户端进程的用户，组为父目录所属的组。每个访问HDFS的客户端进程有一个由用户姓名和组列表两部分组的成标识，无论何时HDFS必须对由客户端进程访问的文件或目录进行权限检查，规则如下：
* 如果进程的用户名匹配文件或目录的拥有者，那么测试拥有者权限
* 否则如果文件或目录所属的组匹配组列表中任何组，那么测试组权限
* 否则测试其它权限

如果权限检查失败，则客户端操作失败。

## 确定用户所采用的模式
hadoop支持两种不同的操作模式以确定用户，分别为`simple`和`kerberos`，具体使用哪个方式由参数`hadoop.security.authentication`设置，该参数位于`core-site.xml`文件中，默认值为simple。
* 在`simple`模式下，客户端进程的身份由主机的操作系统确定，比如在类Unix系统中，用户名为命令`whoami`的输出。
* 在`kerberos`模式下，客户端进程的身份由Kerberos凭证确定，比如在一个Kerberized环境中，用户可能使用`kinit`工具得到了一个TGT且使用`klist`确定当前的principal。当映射一个`Kerberosprincipal`到HDFS的用户名时，除了最主要的部分外其余部分都被丢弃，比如一个principal为`todd/foobar@CORP.COMPANY.COM`，将映射为HDFS上的todd。

无论哪种操作模式，对于HDFS来说用户标识机制都是外部的，HDFS本身没有创建用户标，建立组或者处理用户凭证的规定。

## 确定用户组的方法
用户组是通过由参数`hadoop.security.group.mapping`设置的组映射服务确定的，默认实现是`org.apache.hadoop.security.JniBasedUnixGroupsMappingWithFallback`，该实现首先确定Java本地接口（JNI）是否可用，如果JNI可用，该实现将使用hadoop中的API为用户解析用户组列表。如果JNI不可用，那么使用`ShellBasedUnixGroupsMapping`，该实现将使用Linux/Unix中的`bash –c groups`命令为用户解析用户组列表。其它实现还有`LdapGroupsMapping`，通过直接连接LDAP服务器来解析用户组列表。对HDFS来说，用户到组的映射是在NameNode上执行的，因而NameNode的主机系统配置决定了用户的组映射。HDFS将文件或目录的用户和组存储为字符串，并且不像Linux/Unix那样可以将用户和组转换为数字。

## 超级用户怎么来的
HDFS中超级用户与通常熟悉的Linux或Unix中的root用户不同，HDFS的超级用户是与NameNode进程有相同标示的用户，更简单易懂些，启动NameNode的用户就为超级用户。对于谁是超级用户没有固定的定义，当NameNode启动后，该进程的标示决定了谁是超级用户。HDFS的超级用户不必是NameNode主机的超级用户，也需用所有的集群使用相同的超级用户，出于实验目的在个人工作站上运行HDFS的人自然而然的称为超级用户而不需要任何配置。另外参数`dfs.permissions.superusergroup`设置了超级用户组，该组中的所有用户也为超级用户。超级用户在HDFS中可以执行任何操作而针对超级用户的权限检查永远不会失败。

## 访问控制列表
HDFS也提供了对POSIX ACL（访问控制列表）支持来为特定的用户或者用户组提供更加细粒度的文件权限。ACL是不同于用户和组的自然组织层次的有用的权限控制方式，ACL可以为特定的用户和组设置不同的权限，而不仅仅是文件的拥有者和文件所属的组。默认情况下，HDFS禁用ACL，因此NameNode禁止ACL的创建，为了启用ACL，需要在hdfs-site.xml中将参数`dfs.namenode.acls.enabled`设置为true。

访问控制列表由一组ACL项组成，每个ACL项命名了特定的用户或组，并为其授予或拒绝读，写和执行的权限，每个ACL项由类型，由可选的名称和权限字符串组成，它们之间使用冒号（:）来分隔，例如：
```shell
user::rw-
user:bruce:rwx                  #effective:r--
group::r-x                      #effective:r--
group:sales:rwx                 #effective:r--
mask::r--
other::r--
```

在上面的例子中文件的拥有者具有读写权限，文件所属的组具有读和执行的权限，其他用户具有读权限，这些设置与将文件设置为654等价（6表示拥有者的读写权限，5表示组的读和执行权限，4表示其他用户的读权限）。

除此之外，还有两个扩展的ACL项，分别为用户`bruce`和组`sales`，并都授予了读写和执行的权限。还有mask，它是一个特殊的项，用于过滤授予所有命名用户，命名组及未命名组的权限，即过滤除文件拥有者和其他用户(other)之外的任何ACL项。

在该例子中，mask值有读权限，则bruce用户、sales组和文件所属的组只具有读权限。每个ACL必须有mask项，如果用户在设置ACL时没有使用mask项，一个mask项被自动加入到ACL中，该mask项是通过计算所有被mask过滤项的权限与（&运算）得出的。对拥有ACL的文件执行chmod实际改变的是mask项的权限，因为mask项扮演的是过滤器的角色，这将有效地约束所有扩展项的权限，而不是仅改变组的权限而可能漏掉其它扩展项的权限。

## 默认访问控制列表
访问控制列表和默认访问控制列表存在着不同，前者定义了在执行权限检查实施的规则，后者定义了新文件或者子目录创建时自动接收的ACL项，例如：
```shell
user::rwx
group::r-x
other::r-x
default:user::rwx
default:user:bruce:rwx          #effective:r-x
default:group::r-x
default:group:sales:rwx         #effective:r-x
default:mask::r-x
default:other::r-x
```

只有目录可能拥有默认访问控制列表，当创建新文件或者子目录时，自动拷贝父辈的默认访问控制列表到自己的访问控制列表中，新的子目录也拷贝父辈默认的访问控制列表到自己的默认访问控制列表中。这样，当创建子目录时默认ACL将沿着文件系统树被任意深层次地拷贝。在新的子ACL中，准确的权限由模式参数过滤。

默认的umask为022，通常新目录权限为755，新文件权限为644。模式参数为未命名用户（文件的拥有者），mask及其他用户过滤拷贝的权限值。在上面的例子中，创建权限为755的子目录时，模式对最终结果没有影响，但是如果创建权限为644的文件时，模式过滤器导致新文件的ACL中文件拥有者的权限为读写，mask的权限为读以及其他用户权限为读。mask的权限意味着用户bruce和组sales只有读权限。拷贝ACL发生在文件或子目录的创建时，后面如果修改父辈的默认ACL将不再影响已存在子类的ACL。

默认ACL必须包含所有最小要求的ACL项，包括文件拥有者项，文件所属的组项和其它用户项。如果用户没有在默认ACL中配置上述三项中的任何一个，那么该项将通过从访问ACL拷贝对应的权限来自动插入，或者如果没有访问ACL则自动插入权限位。默认ACL也必须拥有mask，如果mask没有被指定，通过计算所有被mask过滤项的权限与（&运算）自动插入mask。当一个文件拥有ACL时，权限检查的算法变为：
* 如果用户名匹配文件的拥有者，则测试拥有者权限
* 否则，如果用户名匹配命名用户项中的用户名，则测试由mask权限过滤后的该项的权限
* 否则，如果文件所属的组匹配组列表中的任何组，并且如果这些被mask过滤的权限具有访问权限，那么使用这么权限
* 否则，如果存在命名组项匹配组列表中的成员，并且如果这些被mask过滤的权限具有访问权限，那么使用这么权限
* 否则，如果文件所属的组或者任何命名组项匹配组列表中的成员，但不具备访问权限，那么访问被拒绝
* 否则测试文件的其他用户权限

## 权限和ACL相关参数
| 参数名                         | 位置          | 用途                                                                                          |
| ------------------------------ | ------------- | --------------------------------------------------------------------------------------------- |
| dfs.permissions.enabled        | hdfs-site.xml | 默认值为true，即启用权限检查。如果为 false，则禁用权限检查。                                  |
| hadoop.http.staticuser.user    | core-site.xml | 默认值为dr.who，查看web UI的用户                                                              |
| dfs.permissions.superusergroup | hdfs-site.xml | 超级用户的组名称，默认为supergroup                                                            |
| fs.permissions.umask-mode      | core-site.xml | 创建文件和目录时使用的umask，默认值为八进制022，每位数字对应了拥有者，组和其他用户。该值既可以使用八进制数字，如022，也可以使用符号，如u=rwx,g=r-x,o=r-x(对应022)                                                                                              |
| dfs.cluster.administrators     | hdfs-site.xml | 被指定为ACL的集群管理员                                                                       |
| dfs.namenode.acls.enabled      | hdfs-site.xml | 默认值为false，禁用ACL，设置为true则启用ACL。当ACL被禁用时，NameNode拒绝设置或者获取ACL的请求 |
