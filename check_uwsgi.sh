#!/bin/bash

# 检查uWSGI进程状态
echo "检查uWSGI进程状态..."
ps aux | grep uwsgi

# 检查8000端口监听情况
echo "\n检查8000端口监听情况..."
netstat -tuln | grep 8000

# 确认配置文件存在并显示内容
echo "\n确认配置文件存在..."
ls -la /var/www/django_project/mblog/new_uwsgi.ini

echo "\n显示配置文件内容..."
cat /var/www/django_project/mblog/new_uwsgi.ini

# 尝试手动启动uWSGI服务（可选）
echo "\n是否手动启动uWSGI服务？(y/n)"
read choice
if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
    echo "启动uWSGI服务..."
    uwsgi --ini /var/www/django_project/mblog/new_uwsgi.ini
fi