#!/bin/bash

# 检查服务器8000端口占用情况
check_port_usage() {
    echo "=== 检查8000端口占用情况 ==="
    # 使用netstat检查端口监听情况
    netstat -tuln | grep :8000
    if [ $? -ne 0 ]; then
        echo "8000端口未被监听"
    else
        echo "8000端口已被监听"
    fi

    # 使用lsof检查占用端口的进程（如果lsof可用）
    if command -v lsof &> /dev/null; then
        echo -e "\n=== 使用lsof检查占用8000端口的进程 ==="
        lsof -i :8000
    else
        echo -e "\n=== lsof命令不可用，尝试使用fuser ==="
        if command -v fuser &> /dev/null; then
            fuser 8000/tcp
        else
            echo "无法确定占用8000端口的进程，建议安装lsof或fuser"
        fi
    fi
}

# 检查uWSGI进程状态
check_uwsgi_process() {
    echo -e "\n=== 检查uWSGI进程 ==="
    ps aux | grep uwsgi | grep -v grep
    if [ $? -ne 0 ]; then
        echo "未找到uWSGI进程"
    else
        echo "找到uWSGI进程"
    fi
}

# 检查Django应用状态
check_django_status() {
    echo -e "\n=== 检查Django应用状态 ==="
    if [ -f "manage.py" ]; then
        python manage.py check
        if [ $? -ne 0 ]; then
            echo "Django应用检查失败"
        else
            echo "Django应用检查通过"
        fi
    else
        echo "未找到manage.py文件"
    fi
}

# 检查防火墙配置
check_firewall() {
    echo -e "\n=== 检查防火墙配置 ==="
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --list-ports | grep 8000
        if [ $? -ne 0 ]; then
            echo "8000端口未在防火墙中开放"
        else
            echo "8000端口已在防火墙中开放"
        fi
    elif command -v ufw &> /dev/null; then
        ufw status | grep 8000
        if [ $? -ne 0 ]; then
            echo "8000端口未在防火墙中开放"
        else
            echo "8000端口已在防火墙中开放"
        fi
    else
        echo "无法确定防火墙状态，建议手动检查"
    fi
}

# 执行所有检查
check_port_usage
check_uwsgi_process
check_django_status
check_firewall

echo -e "\n=== 诊断完成 ==="