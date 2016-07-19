#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

echo "
#============================================
#   SYSTEM REQUIRED:  Ubuntu / Debian
#   DESCRIPTION:  Install ShadowSocks manyuser version
#   VERSION:   1.0
#   AUTHOR:    reruin <reruin@gmail.com>
#============================================

"

#init

read -p "Please input MYSQL Host(localhost):" mysqlhost
if [ "$mysqlhost" = "" ]; then
	mysqlhost="localhost"
fi

read -p "Please input MYSQL Port(3306):" mysqlport
if [ "$mysqlport" = "" ]; then
	mysqlport="3306"
fi


read -p "Please input MYSQL Database(ss):" mysqldb
if [ "$mysqldb" = "" ]; then
	mysqldb="ss"
fi

read -p "Please input MYSQL User(root):" mysqluser
if [ "$mysqluser" = "" ]; then
	mysqluser="root"
fi

read -p "Please input MYSQL Password(12345678):" mysqlpwd
if [ "$mysqlpwd" = "" ]; then
	mysqlpwd="12345678"
fi

read -p "Please input MYSQL Table(ss_user):" mysqltable
if [ "$mysqltable" = "" ]; then
	mysqltable="ss_user"
fi

read -p "Please input Node ID(0) use 0 for disabled:" nodeid
if [ "$nodeid" = "" ]; then
	nodeid="ss"
fi

read -p "Please input SS dedicated mode(n)" nodemode
if [ "$nodemode" = "" ]; then
    nodemode="n"
fi

clear
get_char()
{
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
echo ""
echo "Mysql Port        : $mysqlport"
echo "Mysql Host        : $mysqlhost"
echo "Mysql Database    : $mysqldb"
echo "Mysql User        : $mysqluser"
echo "Mysql Password    : $mysqlpwd"
echo "Mysql Table       : $mysqltable"
echo "Node ID           : $nodeid"
echo "SS dedicated mode : $nodemode"
echo ""
echo "Press any key to start...or Press Ctrl+c to cancel"
char=`get_char`
clear

#install some necessary tools 快速加解密库 进程守护 pip
{ apt-get update;apt-get upgrade -y; apt-get install -y wget python-m2crypto build-essential supervisor python-pip; } || { echo "依赖库没安装成功，程序暂停";exit 1; }

pip install cymysql

wget https://github.com/jedisct1/libsodium/releases/download/1.0.10/libsodium-1.0.10.tar.gz
tar xf libsodium* && cd libsodium*
./configure && make && make install
ldconfig


cd /usr/local/
wget https://raw.githubusercontent.com/reruin/shadowsocks-rm/mu/install/ss.tar.gz
tar vxf ss.tar.gz && cd shadowsocks

rm -f /usr/local/shadowsocks/config.py
# 配置 ss
cat >>/usr/local/shadowsocks/config.py<<EOF

import logging

#Config
MYSQL_HOST = '$mysqlhost'
MYSQL_PORT = $mysqlport
MYSQL_USER = '$mysqluser'
MYSQL_PASS = '$mysqlpwd'
MYSQL_DB = '$mysqldb'
MYSQL_TABLE = '$mysqltable'

MANAGE_PASS = 'passwd'
#if you want manage in other server you should set this value to global ip
MANAGE_BIND_IP = '127.0.0.1'
#make sure this port is idle
MANAGE_PORT = 23333
#BIND IP
#if you want bind ipv4 and ipv6 '[::]'
#if you want bind all of ipv4 if '0.0.0.0'
#if you want bind all of if only '4.4.4.4'
SS_BIND_IP = '0.0.0.0'
SS_METHOD = 'chacha20'
SS_ID = '$nodeid'
SS_DEDICATED = '$nodemode'

#LOG CONFIG
LOG_ENABLE = False
LOG_LEVEL = logging.DEBUG
LOG_FILE = '/var/log/shadowsocks.log'

EOF


# 配置守护进程
cat >>/etc/supervisor/conf.d/ss.conf<<EOF
[program:shadowsocks-manyuser]
command=python /usr/local/shadowsocks/servers.py
autostart=true
autorestart=true
EOF

/etc/init.d/supervisor restart


#clear
#end
echo "
  Enjoy !
"