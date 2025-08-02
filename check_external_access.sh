#!/bin/bash

# 排查公网IP和外部连接问题的脚本

# 配置变量
LOG_FILE="external_access_check.log"

# 清屏并显示脚本信息
clear
 echo "=== 公网IP和外部连接问题排查工具 ==="
 echo "此工具将帮助你排查公网IP配置和外部连接问题"
 echo "日志文件: $LOG_FILE"
 echo "=========================="

# 函数: 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 函数: 获取公网IP地址
get_public_ip() {
    echo -e "\n=== 获取公网IP地址 ==="

    if command_exists curl; then
        PUBLIC_IP=$(curl -s ifconfig.me)
    elif command_exists wget; then
        PUBLIC_IP=$(wget -qO- ifconfig.me)
    else
        echo "✗ 未找到curl或wget命令，无法获取公网IP"
        return 1
    fi

    if [ -n "$PUBLIC_IP" ]; then
        echo "✓ 公网IP地址: $PUBLIC_IP"
        echo "请确认此IP地址与你尝试访问的IP地址一致"
    else
        echo "✗ 无法获取公网IP地址"
        return 1
    fi
}

# 函数: 检查网络接口配置
check_network_interfaces() {
    echo -e "\n=== 检查网络接口配置 ==="

    if command_exists ip; then
        echo "网络接口信息:"
        ip addr show
    elif command_exists ifconfig; then
        echo "网络接口信息:"
        ifconfig
    else
        echo "✗ 未找到ip或ifconfig命令，无法检查网络接口"
        return 1
    fi
}

# 函数: 检查路由表
check_routing_table() {
    echo -e "\n=== 检查路由表 ==="

    if command_exists ip; then
        echo "路由表信息:"
        ip route show
    elif command_exists route; then
        echo "路由表信息:"
        route -n
    else
        echo "✗ 未找到ip或route命令，无法检查路由表"
        return 1
    fi
}

# 函数: 检查DNS解析
check_dns_resolution() {
    echo -e "\n=== 检查DNS解析 ==="

    if command_exists nslookup; then
        echo "测试DNS解析 google.com:"
        nslookup google.com
    elif command_exists dig; then
        echo "测试DNS解析 google.com:"
        dig google.com
    else
        echo "✗ 未找到nslookup或dig命令，无法检查DNS解析"
        return 1
    fi
}

# 函数: 检查安全组规则应用状态
guide_security_group_check() {
    echo -e "\n=== 安全组规则应用状态检查指南 ==="
    echo "1. 登录云服务提供商控制台"
    echo "2. 导航到ECS实例管理页面"
    echo "3. 选择当前实例，查看已应用的安全组"
    echo "4. 确认安全组规则是否包含以下内容:"
    echo "   - 协议: TCP"
    echo "   - 端口范围: 8000/8000"
    echo "   - 源地址: 0.0.0.0/0"
    echo "   - 动作: 允许"
    echo "5. 如果规则不存在或不正确，请添加或修改规则"
}

# 函数: 外部连接测试建议
guide_external_test() {
    echo -e "\n=== 外部连接测试建议 ==="
    echo "在本地计算机上执行以下命令测试连接:"
    echo "1. 测试网络连通性: ping $PUBLIC_IP"
    echo "2. 测试端口连通性: telnet $PUBLIC_IP 8000"
    echo "3. 测试HTTP访问: curl http://$PUBLIC_IP:8000"
    echo "4. 或者在浏览器中访问: http://$PUBLIC_IP:8000"
}

# 函数: 检查Django配置
check_django_config() {
    echo -e "\n=== 检查Django配置 ==="

    if [ -f "mblog/settings.py" ]; then
        echo "检查ALLOWED_HOSTS配置:"
        grep -A 1 "ALLOWED_HOSTS" mblog/settings.py
        echo -e "\n检查DEBUG模式:"
        grep -A 1 "DEBUG" mblog/settings.py
    else
        echo "✗ 未找到Django设置文件"
        return 1
    fi
}

# 主函数: 运行所有步骤
run_all_steps() {
    echo "开始公网IP和外部连接问题排查..."
    echo "过程将保存到 $LOG_FILE"

    # 将输出重定向到日志文件和控制台
    { 
        get_public_ip
        check_network_interfaces
        check_routing_table
        check_dns_resolution
        guide_security_group_check
        check_django_config
        guide_external_test

        echo -e "\n=== 完成时间: $(date) ==="
        echo "=== 排查总结 ==="
        echo "1. 确认公网IP地址是否正确"
        echo "2. 检查安全组规则是否正确应用"
        echo "3. 确认Django配置中的ALLOWED_HOSTS是否包含公网IP"
        echo "4. 在本地计算机上测试外部连接"
        echo "5. 如问题仍未解决，尝试重启服务器或联系云服务提供商支持"
    } | tee $LOG_FILE

    echo -e "\n排查完成！详细结果请查看 $LOG_FILE"
}

# 运行主函数
run_all_steps
</content>,"query_language":"Chinese"}}