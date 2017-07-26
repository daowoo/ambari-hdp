# log4j.properties

修改这个文件中的参数可以改变Hbase的日志级别，改变后需要重启新的配置才能生效，此外还可以通过Hbase提供的UI界面来更改特定守护进程的日志级别。

## log4j配置简介
### 配置根Logger

语法为:
```
log4j.rootLogger = [level],appenderName,appenderName2,...
```

* level是日志记录的优先级，分为OFF,TRACE,DEBUG,INFO,WARN,ERROR,FATAL,ALL，Log4j建议只使用四个级别，优先级从低到高分是DEBUG,INFO,WARN,ERROR通过在这里定义的级别，可以控制到应用程序中相应级别的日志信息的开关。比如在这里定义了INFO级别，则应用程序中所有DEBUG级别的日志信息将不被打印出来。

* appenderName就是指定日志信息输出到哪个地方。可同时指定多个输出目的。

### 配置日志信息输出目的地Appender32131

其语法为:
```
log4j.appender.appenderName = fully.qualified.name.of.appender.class
log4j.appender.appenderName.optionN = valueN
```

* Log4j提供的appender有以下几种：

 - org.apache.log4j.ConsoleAppender(输出到控制台)
 - org.apache.log4j.FileAppender(输出到文件)
 - org.apache.log4j.DailyRollingFileAppender(每天产生一个日志文件)
 - org.apache.log4j.RollingFileAppender(文件大小到达指定尺寸的时候产生一个新的文件)
 - org.apache.log4j.WriterAppender(将日志信息以流格式发送到任意指定的地方)


* ConsoleAppender项属性

 - -Threshold = DEBUG，指定日志消息的输出最低层次
 - -ImmediateFlush = TRUE，默认值是true，所有的消息都会被立即输出
 - -Target = System.err，默认值System.out，输出到控制台(err为红色,out为黑色)


* FileAppender选项属性

 - -Threshold = INFO，指定日志消息的输出最低层次
 - -ImmediateFlush = TRUE，默认值是true，所有的消息都会被立即输出
 - -File = C:\log4j.log，指定消息输出到C:\log4j.log文件
 - -Append = FALSE，默认值true，将消息追加到指定文件中，false指将消息覆盖指定的文件内容
 - -Encoding = UTF-8，可以指定文件编码格式


* DailyRollingFileAppender选项属性

 - -Threshold = WARN，指定日志消息的输出最低层次
 - -ImmediateFlush = TRUE，默认值是true，所有的消息都会被立即输出
 - -File = C:\log4j.log，指定消息输出到C:\log4j.log文件
 - -Append = FALSE，默认值true，将消息追加到指定文件中，false指将消息覆盖指定的文件内容
 - -DatePattern='.'yyyy-ww，每周滚动一次文件，即每周产生一个新的文件。
```
 '.'yyyy-MM:每月
 '.'yyyy-ww:每周
 '.'yyyy-MM-dd:每天
 '.'yyyy-MM-dd-a:每天两次
 '.'yyyy-MM-dd-HH:每小时
 '.'yyyy-MM-dd-HH-mm:每分钟
```
 - -Encoding = UTF-8，可以指定文件编码格式


* RollingFileAppender选项属性

 - -Threshold = ERROR，指定日志消息的输出最低层次
 - -ImmediateFlush = TRUE，默认值是true，所有的消息都会被立即输出
 - -File = C:/log4j.log，指定消息输出到C:/log4j.log文件
 - -Append = FALSE，默认值true，将消息追加到指定文件中，false指将消息覆盖指定的文件内容
 - -MaxFileSize = 100KB，后缀可以是KB、MB、GB，在日志文件到达该大小时，将会自动滚动，如:log4j.log.1
 - -MaxBackupIndex = 2，指定可以产生的滚动文件的最大数
 - -Encoding = UTF-8，可以指定文件编码格式

### 配置日志信息的格式(layout)

语法为:
```
log4j.appender.appenderName.layout = fully.qualified.name.of.layout.class
log4j.appender.appenderName.layout.optionN = valueN
```

* Log4j提供的layout有以下几种：

 - org.apache.log4j.HTMLLayout(以HTML表格形式布局)
 - org.apache.log4j.PatternLayout(可以灵活地指定布局模式)
 - org.apache.log4j.SimpleLayout(包含日志信息的级别和信息字符串)
 - org.apache.log4j.TTCCLayout(包含日志产生的时间、线程、类别等等信息)
 - org.apache.log4j.xml.XMLLayout(以XML形式布局)


* HTMLLayout选项属性

 - -LocationInfo = TRUE，默认值false，输出Java文件名称和行号
 - -Title=Struts Log Message，默认值“Log4J Log Messages”


* PatternLayout选项属性

 - -ConversionPattern = %m%n:格式化指定的消息，参数类似于printf函数中的格式化字符串定义。
 ```
 %m 输出代码中指定的消息
 %p 输出优先级，即DEBUG,INFO,WARN,ERROR,FATAL
 %r 输出自应用启动到输出该log信息耗费的毫秒数
 %c 输出所属的类目,通常就是所在类的全名
 %t 输出产生该日志事件的线程名
 %n 输出一个回车换行符，Windows平台为“\r\n”，Unix平台为“\n”
 %d 输出日志时间点的日期或时间，默认格式为ISO8601，也可以在其后指定格式，如：%d{yyyy年MM月dd日 HH:mm:ss,SSS}，输出类似：2012年01月05日 22:10:28,921
 %l 输出日志事件的发生位置，包括类目名、发生的线程，以及在代码中的行数，如：Testlog.main(TestLog.java:10)
 %F 输出日志消息产生时所在的文件名称
 %L 输出代码中的行号
 %x 输出和当前线程相关联的NDC(嵌套诊断环境),像java servlets多客户多线程的应用中
 %% 输出一个"%"字符
 还可以在%与模式字符之间加上修饰符来控制其最小宽度、最大宽度、和文本的对齐方式。如：
 %5c: 输出category名称，最小宽度是5，category<5，默认的情况下右对齐
 %-5c:输出category名称，最小宽度是5，category<5，"-"号指定左对齐,会有空格
 %.5c:输出category名称，最大宽度是5，category>5，就会将左边多出的字符截掉，<5不会有空格
 %20.30c:category名称<20补空格，并且右对齐，>30字符，就从左边交远销出的字符截掉
 ```


* XMLLayout选项属性

 - -LocationInfo = TRUE:默认值false,输出java文件名称和行号


### 特定包输出特定的级别

语法为:
```
log4j.logger.org.springframework=DEBUG
log4j.logger.org.xxxx=INFO
```

## 实例解析

```
# Hbase默认属性值定义
hbase.root.logger=INFO,console
hbase.security.logger=INFO,console
hbase.log.dir=.
hbase.log.file=hbase.log

# 使用默认值设置rootLogger
log4j.rootLogger=${hbase.root.logger}

# 全局设置输出所有层级的日志
log4j.threshold=ALL

#
# 以时间粒度来更新日志的Appender
#
log4j.appender.DRFA=org.apache.log4j.DailyRollingFileAppender
log4j.appender.DRFA.File=${hbase.log.dir}/${hbase.log.file}

# 设定DRFA以天为单位Roll文件
log4j.appender.DRFA.DatePattern=.yyyy-MM-dd

# 30-day backup
#log4j.appender.DRFA.MaxBackupIndex=30
# 设定DRFA的layout方式
log4j.appender.DRFA.layout=org.apache.log4j.PatternLayout

# 设定DRFA每行日志的输出格式: Date LogLevel LoggerName LogMessage
log4j.appender.DRFA.layout.ConversionPattern=%d{ISO8601} %-5p [%t] %c{2}: %m%n

# RFA appender的属性定义
hbase.log.maxfilesize=256MB  #文件大小阈值
hbase.log.maxbackupindex=20  #文件个数阈值，超过后开始覆盖

# 设定RFA以文件大小为单位roll新文件
log4j.appender.RFA=org.apache.log4j.RollingFileAppender
log4j.appender.RFA.File=${hbase.log.dir}/${hbase.log.file}

log4j.appender.RFA.MaxFileSize=${hbase.log.maxfilesize}
log4j.appender.RFA.MaxBackupIndex=${hbase.log.maxbackupindex}

# 设定RFA的layout
log4j.appender.RFA.layout=org.apache.log4j.PatternLayout
log4j.appender.RFA.layout.ConversionPattern=%d{ISO8601} %-5p [%t] %c{2}: %m%n

#
# Security audit appender
#
hbase.security.log.file=SecurityAuth.audit
hbase.security.log.maxfilesize=256MB
hbase.security.log.maxbackupindex=20
log4j.appender.RFAS=org.apache.log4j.RollingFileAppender
log4j.appender.RFAS.File=${hbase.log.dir}/${hbase.security.log.file}
log4j.appender.RFAS.MaxFileSize=${hbase.security.log.maxfilesize}
log4j.appender.RFAS.MaxBackupIndex=${hbase.security.log.maxbackupindex}
log4j.appender.RFAS.layout=org.apache.log4j.PatternLayout
log4j.appender.RFAS.layout.ConversionPattern=%d{ISO8601} %p %c: %m%n
log4j.category.SecurityLogger=${hbase.security.logger}
log4j.additivity.SecurityLogger=false
#log4j.logger.SecurityLogger.org.apache.hadoop.hbase.security.access.AccessController=TRACE

#
# Null Appender
#
log4j.appender.NullAppender=org.apache.log4j.varia.NullAppender

#
# console
# Add "console" to rootlogger above if you want to use this
#
log4j.appender.console=org.apache.log4j.ConsoleAppender
log4j.appender.console.target=System.err
log4j.appender.console.layout=org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern=%d{ISO8601} %-5p [%t] %c{2}: %m%n

# Custom Logging levels

log4j.logger.org.apache.zookeeper=INFO
#log4j.logger.org.apache.hadoop.fs.FSNamesystem=DEBUG
log4j.logger.org.apache.hadoop.hbase=INFO
# Make these two classes INFO-level. Make them DEBUG to see more zk debug.
log4j.logger.org.apache.hadoop.hbase.zookeeper.ZKUtil=INFO
log4j.logger.org.apache.hadoop.hbase.zookeeper.ZooKeeperWatcher=INFO
#log4j.logger.org.apache.hadoop.dfs=DEBUG
# Set this class to log INFO only otherwise its OTT
# Enable this to get detailed connection error/retry logging.
# log4j.logger.org.apache.hadoop.hbase.client.HConnectionManager$HConnectionImplementation=TRACE


# Uncomment this line to enable tracing on _every_ RPC call (this can be a lot of output)
#log4j.logger.org.apache.hadoop.ipc.HBaseServer.trace=DEBUG

# Uncomment the below if you want to remove logging of client region caching'
# and scan of .META. messages
# log4j.logger.org.apache.hadoop.hbase.client.HConnectionManager$HConnectionImplementation=INFO
# log4j.logger.org.apache.hadoop.hbase.client.MetaScanner=INFO
```
