# hadoop-metrics2-hbase.properties

HBase发布遵循Hadoop metrics API的metrics。

```
[root@nn conf]# cat hadoop-metrics2-hbase.properties

# HBase-specific configuration to reset long-running stats (e.g. compactions)
# If this variable is left out, then the default is no expiration.
hbase.extendedperiod = 3600


*.timeline.plugin.urls=file:///usr/lib/ambari-metrics-hadoop-sink/ambari-metrics-hadoop-sink.jar
*.sink.timeline.slave.host.name=nn.daowoo.com

hbase.class=org.apache.hadoop.metrics2.sink.timeline.HadoopTimelineMetricsSink
hbase.period=10
hbase.collector.hosts=yarn.daowoo.com
hbase.protocol=http
hbase.port=6188

jvm.class=org.apache.hadoop.metrics2.sink.timeline.HadoopTimelineMetricsSink
jvm.period=10
jvm.collector.hosts=yarn.daowoo.com
jvm.protocol=http
jvm.port=6188

rpc.class=org.apache.hadoop.metrics2.sink.timeline.HadoopTimelineMetricsSink
rpc.period=10
rpc.collector.hosts=yarn.daowoo.com
rpc.protocol=http
rpc.port=6188

hbase.sink.timeline.class=org.apache.hadoop.metrics2.sink.timeline.HadoopTimelineMetricsSink
hbase.sink.timeline.period=10
hbase.sink.timeline.sendInterval=60000
hbase.sink.timeline.collector.hosts=yarn.daowoo.com
hbase.sink.timeline.protocol=http
hbase.sink.timeline.port=6188

# HTTPS properties
hbase.sink.timeline.truststore.path = /etc/security/clientKeys/all.jks
hbase.sink.timeline.truststore.type = jks
hbase.sink.timeline.truststore.password = bigdata

# Disable HBase metrics for regions/tables/regionservers by default.
*.source.filter.class=org.apache.hadoop.metrics2.filter.RegexFilter
hbase.*.source.filter.exclude=.*(Regions|Users|Tables).*
```
