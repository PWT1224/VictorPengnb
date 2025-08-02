#!/bin/bash

# Django开发服务器访问问题诊断脚本

# 配置变量
SERVER_PORT=8000
DJANGO_PROJECT_DIR="$(pwd)"
LOG_FILE="django_access_diagnostics.log"

# 清屏并显示脚本信息
clear
 echo "=== Django开发服务器访问问题诊断工具 ==="
 echo "此工具将帮助分析Linux环境下无法访问Django开发服务器的问题"
 echo "项目目录: $DJANGO_PROJECT_DIR"
 echo "测试端口: $SERVER_PORT"
 echo "日志文件: $LOG_FILE"
 echo "=========================="

# 函数: 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 函数: 检查Django开发服务器是否运行
django_server_check() {
    echo -e "\n=== Django开发服务器状态检查 ==="

    # 检查是否有python进程运行manage.py runserver
    echo "检查是否有Django开发服务器进程运行..."
    SERVER_PID=$(ps aux | grep 'python manage.py runserver' | grep -v grep | awk '{print $2}')

    if [ -n "$SERVER_PID" ]; then
        echo "找到Django开发服务器进程，PID: $SERVER_PID"
        echo "进程详细信息:"
        ps -p $SERVER_PID -f

        # 检查绑定的IP和端口
        echo -e "\n检查服务器绑定的IP和端口..."
        NETSTAT_OUTPUT=$(netstat -tulpn 2>/dev/null | grep $SERVER_PID | grep LISTEN)
        if [ -n "$NETSTAT_OUTPUT" ]; then
            echo "服务器绑定信息:"
            echo "$NETSTAT_OUTPUT"
            # 提取绑定地址
            BIND_ADDRESS=$(echo "$NETSTAT_OUTPUT" | awk '{print $4}' | cut -d: -f1)
            BIND_PORT=$(echo "$NETSTAT_OUTPUT" | awk '{print $4}' | cut -d: -f2)
            echo "绑定地址: $BIND_ADDRESS"
            echo "绑定端口: $BIND_PORT"

            # 检查是否绑定到0.0.0.0(允许外部访问)
            if [ "$BIND_ADDRESS" = "0.0.0.0" ] || [ "$BIND_ADDRESS" = "::" ]; then
                echo "✓ 服务器允许外部访问(绑定到所有IP)"
            elif [ "$BIND_ADDRESS" = "127.0.0.1" ] || [ "$BIND_ADDRESS" = "::1" ]; then
                echo "✗ 服务器仅允许本地访问(绑定到回环地址)"
                echo "  提示: 使用命令 'python manage.py runserver 0.0.0.0:$SERVER_PORT' 允许外部访问"
            else
                echo "✗ 服务器仅绑定到特定IP: $BIND_ADDRESS"
                echo "  提示: 确认该IP可从外部网络访问"
            fi
        else
            echo "无法获取服务器绑定信息"
        fi
    else
        echo "未找到运行中的Django开发服务器进程"
        echo "提示: 请先运行 'python manage.py runserver 0.0.0.0:$SERVER_PORT' 启动服务器"
    fi
}

# 函数: 检查网络和防火墙设置
network_firewall_check() {
    echo -e "\n=== 网络和防火墙设置检查 ==="

    # 检查本地端口是否可访问
    echo "测试本地访问端口 $SERVER_PORT..."
    if command_exists curl; then
        curl -o /dev/null -s -w "本地访问状态: %{http_code}\n" "http://127.0.0.1:$SERVER_PORT"
    elif command_exists wget; then
        wget -q -O /dev/null "http://127.0.0.1:$SERVER_PORT" && echo "本地访问状态: 200 (成功)" || echo "本地访问状态: 失败"
    else
        echo "无法测试本地访问: 未找到curl或wget命令"
    fi

    # 检查防火墙设置
    echo -e "\n检查防火墙设置..."
    if command_exists ufw; then
        echo "UFW防火墙状态:"
        ufw status | grep $SERVER_PORT || echo "未找到端口 $SERVER_PORT 的规则"
    elif command_exists firewall-cmd; then
        echo "firewalld状态:"
        firewall-cmd --list-ports | grep $SERVER_PORT || echo "未找到端口 $SERVER_PORT 的规则"
    else
        echo "无法检查防火墙: 未找到ufw或firewall-cmd命令"
        echo "提示: 手动检查防火墙是否允许端口 $SERVER_PORT 的入站连接"
    fi

    # 检查网络连接
    echo -e "\n检查网络连接..."
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "服务器IP地址: $SERVER_IP"

    if command_exists ping; then
        echo "测试网络连通性 (ping $SERVER_IP)..."
        ping -c 3 $SERVER_IP
    else
        echo "无法测试网络连通性: 未找到ping命令"
    fi
}

# 函数: 检查Django配置
django_config_check() {
    echo -e "\n=== Django配置检查 ==="

    if [ -f "manage.py" ]; then
        echo "检查ALLOWED_HOSTS设置..."
        ALLOWED_HOSTS=$(grep -A 1 "ALLOWED_HOSTS" mblog/settings.py | tail -n 1 | tr -d '[:space:]' | sed 's/ALLOWED_HOSTS=//' | sed "s/['\[\]]//g")
        echo "当前ALLOWED_HOSTS: $ALLOWED_HOSTS"

        if [ -z "$ALLOWED_HOSTS" ] || [ "$ALLOWED_HOSTS" = "localhost,127.0.0.1,[::1]" ]; then
            echo "✗ ALLOWED_HOSTS可能配置不当，仅允许本地访问"
            echo "  建议修改为: ALLOWED_HOSTS = ['$SERVER_IP', 'localhost', '127.0.0.1']"
        else
            echo "✓ ALLOWED_HOSTS已配置，包含: $ALLOWED_HOSTS"
        fi

        echo -e "\n检查DEBUG模式..."
        DEBUG_MODE=$(grep -A 1 "DEBUG" mblog/settings.py | tail -n 1 | tr -d '[:space:]' | sed 's/DEBUG=//')
        echo "当前DEBUG模式: $DEBUG_MODE"

        if [ "$DEBUG_MODE" = "True" ]; then
            echo "✓ DEBUG模式已启用，这在开发环境中是正常的"
        else
            echo "✗ DEBUG模式已禁用，可能会影响错误显示"
        fi
    else
        echo "未找到manage.py文件，无法检查Django配置"
    fi
}

# 函数: 提供解决方案建议
solution_suggestions() {
    echo -e "\n=== 解决方案建议 ==="
    echo "1. 确保Django开发服务器正确启动并绑定到所有IP:"
    echo "   python manage.py runserver 0.0.0.0:$SERVER_PORT"

    echo "2. 检查并修改ALLOWED_HOSTS设置:"
    echo "   在settings.py中添加服务器IP: ALLOWED_HOSTS = ['$SERVER_IP', 'localhost', '127.0.0.1']"

    echo "3. 检查防火墙设置，确保允许端口$SERVER_PORT的入站连接:"
    if command_exists ufw; then
        echo "   sudo ufw allow $SERVER_PORT/tcp"
    elif command_exists firewall-cmd; then
        echo "   sudo firewall-cmd --add-port=$SERVER_PORT/tcp --permanent"
        echo "   sudo firewall-cmd --reload"
    fi

    echo "4. 检查网络连接和路由设置，确保客户端可以访问服务器IP"

    echo "5. 尝试使用其他浏览器或清除浏览器缓存"

    echo "6. 检查是否有其他进程占用了端口$SERVER_PORT:"
    echo "   sudo lsof -i :$SERVER_PORT"
}

# 主函数: 运行所有测试
run_all_tests() {
    echo "开始Django开发服务器访问问题诊断..."
    echo "诊断结果将保存到 $LOG_FILE"

    # 将输出重定向到日志文件和控制台
    { 
        django_server_check
        network_firewall_check
        django_config_check
        solution_suggestions
        echo -e "\n=== 诊断完成时间: $(date) ==="
    } | tee $LOG_FILE

    echo -e "\n诊断完成！详细结果请查看 $LOG_FILE"
    echo "根据诊断结果和解决方案建议进行调整后，重新测试访问"
}

# 运行主函数
run_all_tests
</content>}}}