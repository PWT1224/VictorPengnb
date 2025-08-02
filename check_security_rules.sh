#!/bin/bash

# 检查云服务器安全组规则和网络连接问题的脚本

# 配置变量
SERVER_IP="$(hostname -I | cut -d' ' -f1)"
TEST_PORTS=(8000 8080 22)
LOG_FILE="security_check.log"

# 清屏并显示脚本信息
clear
 echo "=== 云服务器安全组规则和网络连接检查工具 ==="
 echo "此工具将帮助你检查云服务器的安全组规则和网络连接问题"
 echo "服务器IP: $SERVER_IP"
 echo "测试端口: ${TEST_PORTS[*]}"
 echo "日志文件: $LOG_FILE"
 echo "=========================="

# 函数: 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 函数: 检查服务器防火墙状态
check_firewall() {
    echo -e "\n=== 检查服务器防火墙状态 ==="

    if command_exists firewall-cmd; then
        # CentOS/RHEL 7+ 防火墙检查
        FIREWALL_STATUS=$(systemctl is-active firewalld)
        echo "防火墙服务状态: $FIREWALL_STATUS"

        if [ "$FIREWALL_STATUS" = "active" ]; then
            echo "防火墙规则:"
            firewall-cmd --list-all
        fi
    elif command_exists ufw; then
        # Ubuntu/Debian 防火墙检查
        UFW_STATUS=$(ufw status)
        echo "防火墙状态: $UFW_STATUS"
    else
        echo "未找到防火墙管理工具，无法检查防火墙状态"
    fi
}

# 函数: 检查端口监听状态
check_port_listening() {
    echo -e "\n=== 检查端口监听状态 ==="

    for PORT in "${TEST_PORTS[@]}"; do
        if command_exists ss; then
            PORT_STATUS=$(ss -tuln | grep :$PORT)
        elif command_exists netstat; then
            PORT_STATUS=$(netstat -tuln | grep :$PORT)
        else
            echo "✗ 未找到ss或netstat命令，无法检查端口状态"
            continue
        fi

        if [ -n "$PORT_STATUS" ]; then
            echo "✓ 端口 $PORT 正在监听:"
            echo "$PORT_STATUS"
        else
            echo "✗ 端口 $PORT 未被监听"
        fi
    done
}

# 函数: 检查Django服务状态
check_django_service() {
    echo -e "\n=== 检查Django服务状态 ==="

    # 检查是否有Django进程在运行
    if command_exists pgrep; then
        DJANGO_PID=$(pgrep -f "python manage.py runserver")
    else
        echo "✗ 未找到pgrep命令，无法检查Django进程"
        return
    fi

    if [ -n "$DJANGO_PID" ]; then
        echo "✓ 发现Django进程在运行，PID: $DJANGO_PID"
        echo "进程详细信息:"
        ps -p $DJANGO_PID -o command
    else
        echo "✗ 未发现运行中的Django进程"
        echo "建议启动Django服务器:"
        echo "nohup python manage.py runserver 0.0.0.0:8000 > django_server.log 2>&1 &"
    fi
}

# 函数: 本地连接测试
local_connection_test() {
    echo -e "\n=== 本地连接测试 ==="

    for PORT in "${TEST_PORTS[@]}"; do
        echo "测试连接到 localhost:$PORT..."
        if command_exists curl; then
            curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT
            HTTP_CODE=$?
            if [ $HTTP_CODE -eq 0 ] || [ $HTTP_CODE -eq 200 ]; then
                echo " ✓ 成功连接到 localhost:$PORT"
            else
                echo " ✗ 无法连接到 localhost:$PORT"
            fi
        elif command_exists wget; then
            wget -q -O /dev/null http://localhost:$PORT
            if [ $? -eq 0 ]; then
                echo " ✓ 成功连接到 localhost:$PORT"
            else
                echo " ✗ 无法连接到 localhost:$PORT"
            fi
        else
            echo "✗ 未找到curl或wget命令，无法进行本地连接测试"
            continue
        fi
    done
}

# 函数: 安全组规则检查建议
guide_security_rules() {
    echo -e "\n=== 安全组规则检查建议 ==="
    echo "根据提供的安全组配置截图，检查以下事项:"
    echo "1. 确认入方向规则是否允许8000和8080端口的TCP流量"
    echo "2. 确认源地址是否设置为0.0.0.0/0 (允许所有IP访问)"
    echo "3. 确认安全组规则已应用到正确的ECS实例"
    echo "4. 检查是否有网络ACL或其他安全策略限制流量"
    echo "5. 确认服务器IP地址是否正确"
}

# 主函数: 运行所有步骤
run_all_steps() {
    echo "开始安全组规则和网络连接检查..."
    echo "过程将保存到 $LOG_FILE"

    # 将输出重定向到日志文件和控制台
    { 
        check_firewall
        check_port_listening
        check_django_service
        local_connection_test
        guide_security_rules

        echo -e "\n=== 完成时间: $(date) ==="
        echo "=== 检查总结 ==="
        echo "1. 如果防火墙运行中，请确保已开放相关端口"
        echo "2. 确保Django服务器正在运行并监听正确的端口"
        echo "3. 确认安全组规则配置正确并已应用"
        echo "4. 如问题仍未解决，尝试重启服务器或联系云服务提供商支持"
    } | tee $LOG_FILE

    echo -e "\n检查完成！详细结果请查看 $LOG_FILE"
}

# 运行主函数
run_all_steps
</content>,"query_language":"Chinese"}}