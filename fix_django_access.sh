#!/bin/bash

# Django访问问题修复脚本

# 配置变量
SERVER_PORT=8000
SERVER_IP=$(hostname -I | awk '{print $1}')
DJANGO_SETTINGS_FILE="mblog/settings.py"
LOG_FILE="fix_django_access.log"

# 清屏并显示脚本信息
clear
 echo "=== Django访问问题修复工具 ==="
 echo "此工具将修复Linux环境下Django开发服务器无法访问的问题"
 echo "服务器IP: $SERVER_IP"
 echo "服务器端口: $SERVER_PORT"
 echo "设置文件: $DJANGO_SETTINGS_FILE"
 echo "日志文件: $LOG_FILE"
 echo "=========================="

# 函数: 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 函数: 备份设置文件
backup_settings() {
    echo -e "\n=== 备份设置文件 ==="
    BACKUP_FILE="${DJANGO_SETTINGS_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    cp $DJANGO_SETTINGS_FILE $BACKUP_FILE
    if [ $? -eq 0 ]; then
        echo "✓ 设置文件已备份到: $BACKUP_FILE"
    else
        echo "✗ 备份设置文件失败"
        exit 1
    fi
}

# 函数: 修改ALLOWED_HOSTS
fix_allowed_hosts() {
    echo -e "\n=== 修改ALLOWED_HOSTS设置 ==="

    # 检查当前ALLOWED_HOSTS
    CURRENT_ALLOWED_HOSTS=$(grep -A 1 "ALLOWED_HOSTS" $DJANGO_SETTINGS_FILE | tail -n 1 | tr -d '[:space:]')
    echo "当前ALLOWED_HOSTS: $CURRENT_ALLOWED_HOSTS"

    # 修改ALLOWED_HOSTS
    NEW_ALLOWED_HOSTS="ALLOWED_HOSTS = ['$SERVER_IP', 'localhost', '127.0.0.1']"
    sed -i "s/^ALLOWED_HOSTS.*/$NEW_ALLOWED_HOSTS/" $DJANGO_SETTINGS_FILE

    if [ $? -eq 0 ]; then
        echo "✓ ALLOWED_HOSTS已更新为: $NEW_ALLOWED_HOSTS"
    else
        echo "✗ 更新ALLOWED_HOSTS失败"
        exit 1
    fi
}

# 函数: 启用DEBUG模式
enable_debug_mode() {
    echo -e "\n=== 启用DEBUG模式 ==="

    # 检查当前DEBUG模式
    CURRENT_DEBUG=$(grep -A 1 "DEBUG" $DJANGO_SETTINGS_FILE | tail -n 1 | tr -d '[:space:]')
    echo "当前DEBUG设置: $CURRENT_DEBUG"

    # 启用DEBUG模式
    sed -i "s/^DEBUG.*/DEBUG = True/" $DJANGO_SETTINGS_FILE

    if [ $? -eq 0 ]; then
        echo "✓ DEBUG模式已启用"
    else
        echo "✗ 启用DEBUG模式失败"
        exit 1
    fi
}

# 函数: 停止正在运行的Django服务器
stop_django_server() {
    echo -e "\n=== 停止正在运行的Django服务器 ==="

    # 查找Django服务器进程
    SERVER_PIDS=$(ps aux | grep 'python manage.py runserver' | grep -v grep | awk '{print $2}')

    if [ -n "$SERVER_PIDS" ]; then
        echo "找到Django服务器进程: $SERVER_PIDS"
        # 终止进程
        kill -9 $SERVER_PIDS
        echo "✓ Django服务器进程已终止"
    else
        echo "✓ 未找到运行中的Django服务器进程"
    fi
}

# 函数: 启动Django服务器
start_django_server() {
    echo -e "\n=== 启动Django服务器 ==="

    # 确保绑定到所有IP
    echo "启动命令: python manage.py runserver 0.0.0.0:$SERVER_PORT"
    nohup python manage.py runserver 0.0.0.0:$SERVER_PORT > django_server.log 2>&1 &
    SERVER_PID=$!

    echo "✓ Django服务器已启动，PID: $SERVER_PID"
    echo "服务器日志: django_server.log"

    # 等待服务器启动
    sleep 3

    # 检查服务器状态
    if ps -p $SERVER_PID > /dev/null; then
        echo "✓ Django服务器运行正常"
    else
        echo "✗ Django服务器启动失败，请查看日志: django_server.log"
        exit 1
    fi
}

# 函数: 检查端口占用
check_port() {
    echo -e "\n=== 检查端口 $SERVER_PORT 占用情况 ==="

    if command_exists lsof; then
        PORT_USAGE=$(lsof -i :$SERVER_PORT)
        if [ -n "$PORT_USAGE" ]; then
            echo "✗ 端口 $SERVER_PORT 已被占用:"
            echo "$PORT_USAGE"
        else
            echo "✓ 端口 $SERVER_PORT 未被占用"
        fi
    else
        echo "无法检查端口占用: 未找到lsof命令"
    fi
}

# 函数: 验证修复结果
verify_fix() {
    echo -e "\n=== 验证修复结果 ==="

    # 检查本地访问
    if command_exists curl; then
        echo "测试本地访问 http://127.0.0.1:$SERVER_PORT..."
        curl -o /dev/null -s -w "本地访问状态: %{http_code}\n" "http://127.0.0.1:$SERVER_PORT"
    elif command_exists wget; then
        echo "测试本地访问 http://127.0.0.1:$SERVER_PORT..."
        wget -q -O /dev/null "http://127.0.0.1:$SERVER_PORT" && echo "本地访问状态: 200 (成功)" || echo "本地访问状态: 失败"
    else
        echo "无法测试本地访问: 未找到curl或wget命令"
    fi

    echo -e "\n修复完成！请尝试从外部浏览器访问: http://$SERVER_IP:$SERVER_PORT"
    echo "如果仍然无法访问，请检查:"
    echo "1. 服务器防火墙设置"
    echo "2. 网络连接和路由"
    echo "3. 云服务器安全组规则"
}

# 主函数: 运行所有修复步骤
run_all_fixes() {
    echo "开始Django访问问题修复..."
    echo "修复过程将保存到 $LOG_FILE"

    # 将输出重定向到日志文件和控制台
    { 
        backup_settings
        fix_allowed_hosts
        enable_debug_mode
        stop_django_server
        check_port
        start_django_server
        verify_fix
        echo -e "\n=== 修复完成时间: $(date) ==="
    } | tee $LOG_FILE

    echo -e "\n修复完成！详细结果请查看 $LOG_FILE"
}

# 运行主函数
run_all_fixes
</content>}}}