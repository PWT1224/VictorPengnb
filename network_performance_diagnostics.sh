#!/bin/bash

# 网络性能诊断脚本 - 分析访问延迟过高问题

# 配置变量
SERVER_IP="$(hostname -I | awk '{print $1}')"  # 获取服务器IP
TARGET_PORT=8000
ALTERNATIVE_PORT=8080
TEST_DURATION=5  # 测试持续时间(秒)
LOG_FILE="network_diagnostics.log"

# 清屏并显示脚本信息
clear
 echo "=== 网络性能诊断工具 ==="
 echo "此工具将帮助分析网站访问延迟过高的问题"
 echo "服务器IP: $SERVER_IP"
 echo "测试端口: $TARGET_PORT, $ALTERNATIVE_PORT"
 echo "日志文件: $LOG_FILE"
 echo "========================"

# 函数: 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 函数: 网络连接基础测试
basic_network_test() {
    echo -e "\n=== 基础网络连接测试 ==="
    echo "测试日期和时间: $(date)"

    # 检查DNS解析
    echo -e "\n1. DNS解析测试:"
    if command_exists nslookup; then
        nslookup www.baidu.com | tail -n 5
    elif command_exists dig; then
        dig www.baidu.com +short
    else
        echo "无法进行DNS测试: 未找到nslookup或dig命令"
    fi

    # 测试网络连通性
    echo -e "\n2. 网络连通性测试 (ping):"
    if command_exists ping; then
        ping -c 5 www.baidu.com
    else
        echo "无法进行ping测试: 未找到ping命令"
    fi

    # 测试路由追踪
    echo -e "\n3. 路由追踪测试:"
    if command_exists traceroute; then
        traceroute -m 10 www.baidu.com
    elif command_exists tracert; then
        tracert -d -h 10 www.baidu.com
    else
        echo "无法进行路由追踪: 未找到traceroute或tracert命令"
    fi
}

# 函数: 端口响应时间测试
port_response_test() {
    local port=$1
    echo -e "\n=== 端口 $port 响应时间测试 ==="

    if command_exists nc; then
        echo "使用nc测试TCP连接时间..."
        start_time=$(date +%s.%N)
        if nc -z -w 2 $SERVER_IP $port; then
            end_time=$(date +%s.%N)
            duration=$(echo "$end_time - $start_time" | bc)
            echo "TCP连接成功，响应时间: ${duration}秒"
        else
            echo "TCP连接失败: 无法连接到 $SERVER_IP:$port"
        fi
    else
        echo "无法进行TCP连接测试: 未找到nc命令"
    fi

    if command_exists curl; then
        echo -e "\n使用curl测试HTTP响应时间..."
        curl -o /dev/null -s -w "连接时间: %{time_connect}秒\n下载时间: %{time_total}秒\n" "http://$SERVER_IP:$port"
    else
        echo "无法进行HTTP响应测试: 未找到curl命令"
    fi
}

# 函数: 服务器资源使用情况
server_resources_test() {
    echo -e "\n=== 服务器资源使用情况 ==="

    # CPU使用率
    if command_exists mpstat; then
        echo "CPU使用率:"
        mpstat | tail -n 1
    elif command_exists top; then
        echo "CPU使用率 (来自top命令):"
        top -bn1 | grep "%Cpu" | awk '{print "用户: "$2"%, 系统: "$4"%, 空闲: "$8"%"}'
    else
        echo "无法获取CPU使用率: 未找到mpstat或top命令"
    fi

    # 内存使用情况
    if command_exists free; then
        echo -e "\n内存使用情况:"
        free -h
    else
        echo "无法获取内存使用情况: 未找到free命令"
    fi

    # 磁盘空间
    if command_exists df; then
        echo -e "\n磁盘空间使用情况:"
        df -h | head -n 5
    else
        echo "无法获取磁盘空间: 未找到df命令"
    fi
}

# 函数: Django应用性能测试
django_performance_test() {
    echo -e "\n=== Django应用性能测试 ==="

    if [ -f "manage.py" ]; then
        echo "检查Django应用状态..."
        python manage.py check

        echo -e "\n收集静态文件大小..."
        static_size=$(du -sh static/ 2>/dev/null || echo "无法获取")
        echo "静态文件大小: $static_size"

        echo -e "\n检查数据库连接..."
        if command_exists sqlite3 && [ -f "db.sqlite3" ]; then
            echo "数据库大小: $(du -h db.sqlite3)"
            sqlite3 db.sqlite3 "SELECT name FROM sqlite_master WHERE type='table';" | echo "数据库表数量: $(wc -l)"
        else
            echo "无法检查数据库: 未找到sqlite3命令或数据库文件"
        fi
    else
        echo "未找到manage.py文件，无法进行Django应用测试"
    fi
}

# 函数: uWSGI性能配置检查
uwsgi_config_check() {
    echo -e "\n=== uWSGI配置检查 ==="

    if [ -f "uwsgi.ini" ]; then
        echo "uWSGI配置参数:"
        grep -E 'processes|threads|buffer-size|limit-post|logto|daemonize' uwsgi.ini

        echo -e "\n检查uWSGI日志..."
        if [ -f "uwsgi.log" ]; then
            echo "最近10行日志:"
            tail -n 10 uwsgi.log
        else
            echo "未找到uWSGI日志文件: uwsgi.log"
        fi
    else
        echo "未找到uWSGI配置文件: uwsgi.ini"
    fi
}

# 函数: 提供优化建议
optimization_suggestions() {
    echo -e "\n=== 性能优化建议 ==="
    echo "1. 网络优化:"
    echo "   - 检查服务器网络带宽使用情况"
    echo "   - 考虑使用CDN加速静态资源"
    echo "   - 优化DNS解析时间"

    echo "2. 服务器优化:"
    echo "   - 增加服务器内存和CPU资源"
    echo "   - 优化数据库查询性能"
    echo "   - 启用缓存机制(如Redis、Memcached)"

    echo "3. uWSGI优化:"
    echo "   - 调整processes和threads参数"
    echo "   - 增加buffer-size和limit-post值"
    echo "   - 启用uWSGI缓存"

    echo "4. Django优化:"
    echo "   - 启用Django缓存框架"
    echo "   - 优化数据库查询(使用select_related、prefetch_related)"
    echo "   - 压缩静态资源"
    echo "   - 使用异步任务处理耗时操作(如Celery)"
}

# 主函数: 运行所有测试
run_all_tests() {
    echo "开始全面网络性能诊断..."
    echo "诊断结果将保存到 $LOG_FILE"

    # 将输出重定向到日志文件和控制台
    { 
        basic_network_test
        port_response_test $TARGET_PORT
        port_response_test $ALTERNATIVE_PORT
        server_resources_test
        django_performance_test
        uwsgi_config_check
        optimization_suggestions
        echo -e "\n=== 诊断完成时间: $(date) ==="
    } | tee $LOG_FILE

    echo -e "\n诊断完成！详细结果请查看 $LOG_FILE"
    echo "根据诊断结果和优化建议进行调整后，重新测试访问性能"
}

# 运行主函数
run_all_tests
</content>