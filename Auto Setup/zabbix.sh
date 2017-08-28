#!/bin/bash

define_sys() {
	echo "开始安装epel源"
	rpm -ivh ./epel-release-7-8.noarch.rpm
#	echo "清理元数据缓存"
#	yum clean all
#	echo "缓存yum元数据"
#	yum makecache
	echo "安装必要软件包"
	yum install -y httpd php libxml2-* fping mariadb-server mariadb-devel mariadb gcc gcc-c++ autoconf net-snmp-devel curl-devel unixODBC-devel OpenIPMI-devel libssh2-devel.x86_64 php-gd gcc gcc-c++ autoconf  php-fpm  php-mysql mod_ssl php-gd php-xml php-mbstring php-ldap php-pear php-xmlrpc php-bcmath mysql-connector-odbc mysql-devel libdbi-dbd-mysql libjpeg* php-ldap php-odbc php-bcmath php-mhash 
	echo "修改php参数"
	sed -i 's#^;date.timezone =.*$#date.timezone = Asia/Shanghai#g' /etc/php.ini
	sed -i 's#^max_execution_time =.*$#max_execution_time = 300#g' /etc/php.ini
	sed -i 's#^post_max_size =.*$#post_max_size = 32M#g' /etc/php.ini
	sed -i 's#^max_input_time =.*$#max_input_time = 300#g' /etc/php.ini
	sed -i 's#memory_limit =.*$#memory_limit = 512M#g' /etc/php.ini
	echo "启动php-fpm"
	systemctl enable php-fpm
	systemctl start php-fpm
	echo "启动MariaDB"
	systemctl enable mariadb
	echo "启动HTTP"
	systemctl enable httpd
	systemctl start httpd
	echo "设置时区"
	cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	echo "关闭防火墙"
	systemctl disable firewalld
	systemctl stop firewalld
	echo "修改系统内核参数"
	echo '''fs.file-max = 10240000
kernel.pid_max = 132768
net.core.netdev_max_backlog =  32768
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.somaxconn = 32768
net.core.wmem_default = 8388608
net.core.wmem_max = 16777216
net.ipv4.conf.default.rp_filter = 1
net.ipv4.ip_forward = 0
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_max_tw_buckets = 3335000''' >/etc/sysctl.conf
	sysctl -p
	echo ''' * soft nproc 110000
* hard nproc 110000
* soft nofile 900000
* hard nofile 900000''' >>/etc/security/limits.conf
	echo "关闭SELINUX"
	sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
	setenforce 0
}

define_mariadb(){
	echo "修改MariaDB配置"
	echo '''[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
symbolic-links=0
default-storage-engine=InnoDB
innodb_file_per_table=1
back_log = 300                  #操作系统在监听队列中所能保持的连接数
max_connections = 3000          #MySQL服务所允许的同事会话数的上限     
max_connect_errors = 30         #每个客户端连接最大的错误数量table_cache = 4096              #所有线程锁打开表的数量
max_allowed_packet = 32M        #服务所能处理的请求包的最大大小
binlog_cache_size = 4M          #在一个事务中binlog为了记录SQL状态所持有的cache大小
max_heap_table_size = 128M      #独立的内存表所允许的最大容量
read_buffer_size = 2M           #
read_rnd_buffer_size = 16M      #
sort_buffer_size = 16M          #排序缓冲，用来处理类似ORDERBY以及GROUPBY队列所引起的排序
join_buffer_size = 16M          #此缓冲被用来优化全联合
thread_cache_size = 16          #cache中保留多少线程可用于重用
thread_concurrency = 8          #在同一时间给与渴望被运行的线程的熟练
query_cache_size = 128M         #缓冲SELECT的结果并且在下一次同样查询的时候直接返回结果
query_cache_limit = 4M          #只有小于此设定值的结果才会被缓冲
ft_min_word_len = 4             #被全文检索索引的最小的字长
thread_stack = 512K             #线程使用的对大小
transaction_isolation = REPEATABLE-READ #默认的事物隔离级别
tmp_table_size = 128M           #内部临时表的最大大小
slow_query_log                  #
long_query_time = 2             #所有比这个查询时间多的都会被认为是慢查询
server-id = 1
key_buffer_size = 32M
bulk_insert_buffer_size = 64M
myisam_sort_buffer_size = 128M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1
myisam_recover
innodb_additional_mem_pool_size = 64M   #附加的内存池被InnoDB用来保存metadata信息
innodb_buffer_pool_size = 4G            #缓冲池大小，数值越大所需要的磁盘I/O越少
innodb_data_file_path = ibdata1:10M:autoextend #将数据保存在一个或者多个数据文件中成为表 空间
innodb_file_io_threads = 4      #用来同步IO操作的IO线程的数量
innodb_thread_concurrency = 16  #允许线程数量
innodb_flush_log_at_trx_commit = 0 #事务日志
innodb_log_buffer_size = 16M    #用来缓冲日志数据的缓冲区的大小
innodb_log_file_size = 128M     #在日志组中每个日志文件的大小
innodb_log_files_in_group = 3   #在日志组中的文件综述
innodb_max_dirty_pages_pct = 90 #在InnoDB缓冲池中最大允许的脏页面的比例
innodb_lock_wait_timeout = 120  #在被回滚前,一个InnoDB的事务应该等待一个锁被批准多久

[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

!includedir /etc/my.cnf.d''' >/etc/my.cnf
	echo "设置DB最大连接数"
	mkdir -p /etc/systemd/system/mariadb.service.d/
	echo '''[Service]
LimitNOFILE=10000'''>/etc/systemd/system/mariadb.service.d/limits.conf
	echo "启动MariaDB"
	systemctl daemon-reload
	systemctl restart mariadb
	}


setup_zabbix(){
	echo "开始创建zabbix数据库"
	#create zabbixdb
	read -p "Enter Database password:" password
	echo "create zabbixdb"
	mysql -e "create database zabbix character set utf8"
	mysql -e "grant all privileges on zabbix.* to zabbix@localhost identified by '$password'"
	mysql -e "flush privileges"
	tar -zxvf zabbix-3.0.5.tar.gz
	cd ./zabbix-3.0.5/database/mysql
	mysql -uzabbix -p$password zabbix<./schema.sql
	mysql -uzabbix -p$password zabbix<./images.sql
	mysql -uzabbix -p$password zabbix<./data.sql
	echo "开始安装zabbix"
	useradd zabbix
	cd ../../
	./configure --prefix=/usr/local/zabbix --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2
	make && make install
	#复制启动脚本
	cp ./misc/init.d/fedora/core5/* /etc/init.d/
	systemctl enable zabbix_server
	systemctl enable zabbix_agentd
	#编辑修改zabbix_server配置文件
	echo '''LogFile=/tmp/zabbix_server.log
DBName=zabbix
DBUser=zabbix
DBPassword='$password'
StartPollers=250
StartPollersUnreachable=30
StartTrappers=50
StartPingers=300
StartDiscoverers=150
StartHTTPPollers=100
StartSNMPTrapper=1
HousekeepingFrequency=5
MaxHousekeeperDelete=50000
SenderFrequency=300
CacheSize=4096M
CacheUpdateFrequency=600
StartDBSyncers=50
HistoryCacheSize=512M
HistoryIndexCacheSize=128M
TrendCacheSize=128M
ValueCacheSize=256M
Timeout=4
LogSlowQueries=3000''' >/usr/local/zabbix/etc/zabbix_server.conf
	echo '''LogFile=/tmp/zabbix_agentd.log
EnableRemoteCommands=1
Server=127.0.0.1
ServerActive=127.0.0.1
Hostname=Zabbix server
UnsafeUserParameters=1'''>/usr/local/zabbix/etc/zabbix_agentd.conf
	#复制php文件到对应目
	cp -a ./frontends/php /var/www/html/zabbix
	chown -R apache:apache /var/www/html/zabbix
	sed -i 's#ZABBIX_BIN="/usr/local/sbin/zabbix_server"#ZABBIX_BIN="/usr/local/zabbix/sbin/zabbix_server"#g' /etc/init.d/zabbix_server
	sed -i 's#ZABBIX_BIN="/usr/local/sbin/zabbix_agentd"#ZABBIX_BIN="/usr/local/zabbix/sbin/zabbix_agentd"#g' /etc/init.d/zabbix_agentd
	systemctl daemon-reload
	systemctl restart httpd
	systemctl restart mariadb
	systemctl restart php-fpm
	systemctl restart zabbix_agentd
	systemctl restart zabbix_server
	echo "Zabbix 安装完毕，请在游览器中访问http://ip/zabbix,进行初次配置，默认登录密码为admin/zabbix"
}
define_sys
define_mariadb
setup_zabbix
