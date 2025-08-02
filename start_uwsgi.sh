#!/bin/bash

# 停止当前运行的uWSGI进程
echo "停止当前uWSGI进程..."
ps aux | grep uwsgi | grep -v grep | awk '{print $2}' | xargs kill -9

# 等待进程终止
sleep 2

# 使用新配置文件启动uWSGI服务
echo "使用新配置文件启动uWSGI服务..."
uwsgi --ini /var/www/django_project/mblog/new_uwsgi.ini

# 检查端口监听情况
echo "检查端口监听情况..."
netstat -tuln | grep 8000

# 输出启动状态
echo "uWSGI服务启动完成，配置文件：/var/www/django_project/mblog/new_uwsgi.ini"