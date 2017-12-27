#!/usr/bin/env bash

sudo yum install http://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
sudo yum install -y puppet-agent

chown -R vagrant /etc/puppetlabs

# manifests
puppet代码目录，文件以pp为后缀

#读取过程
site->nodes->modules templete->modules resource

#数据定义工具
hiera

#什么是resource
file
package
service

#什么是Facter
