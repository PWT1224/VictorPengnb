#!/bin/bash

# 确保在正确的目录
cd /var/www/django_project/mblog/

# 检查当前目录下的文件
 echo "当前目录文件列表："
ls -la

# 创建或覆盖uWSGI配置文件
 echo "创建uWSGI配置文件..."
cat > uwsgi.ini << EOF
[uwsgi]
chdir = /var/www/django_project/mblog
wsgi-file = mblog/wsgi.py
socket = 0.0.0.0:8000
processes = 4
threads = 2
master = true
pidfile = /tmp/uwsgi.pid
vacuum = true
die-on-term = true
EOF

# 停止当前运行的uWSGI进程
 echo "停止当前uWSGI进程..."
ps aux | grep uwsgi | grep -v grep | awk '{print $2}' | xargs -r kill -9

sleep 2

# 启动uWSGI服务
 echo "启动uWSGI服务..."
uwsgi --ini uwsgi.ini

# 检查端口监听情况
 echo "检查端口监听情况..."
netstat -tuln | grep 8000

# 输出状态信息
 echo "启动完成，请检查以上输出确认服务是否正常运行。"