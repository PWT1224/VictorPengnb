#!/bin/bash

# 公网访问修复工具
# 此脚本将帮助修复Django网站无法从外部访问的问题

# 日志文件
LOG_FILE="fix_django_access.log"
> "$LOG_FILE"  # 清空日志文件

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 打印函数
print_info() {
    echo -e "${BLUE}[信息]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1" | tee -a "$LOG_FILE"
}

# 检查是否以root用户运行
check_root() {
    if [ "$EUID" -ne 0 ]
    then
        print_error "请以root用户运行此脚本"
        exit 1
    fi
}

# 获取公网IP地址（多种方法）
get_public_ip() {
    print_info "正在尝试获取公网IP地址..."

    # 方法1: 使用curl获取
    PUBLIC_IP=$(curl -s ifconfig.me || echo "")
    if [ -n "$PUBLIC_IP" ] && [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_success "成功获取公网IP: $PUBLIC_IP"
        echo "$PUBLIC_IP"
        return 0
    fi

    # 方法2: 使用wget获取
    PUBLIC_IP=$(wget -qO- ifconfig.me || echo "")
    if [ -n "$PUBLIC_IP" ] && [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_success "成功获取公网IP: $PUBLIC_IP"
        echo "$PUBLIC_IP"
        return 0
    fi

    # 方法3: 使用dig获取（如果可用）
    if command -v dig &> /dev/null; then
        PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com || echo "")
        if [ -n "$PUBLIC_IP" ] && [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            print_success "成功获取公网IP: $PUBLIC_IP"
            echo "$PUBLIC_IP"
            return 0
        fi
    fi

    print_error "无法自动获取公网IP地址"
    print_info "请手动输入您的公网IP地址:"
    read -r PUBLIC_IP
    if [ -n "$PUBLIC_IP" ] && [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_success "使用手动输入的公网IP: $PUBLIC_IP"
        echo "$PUBLIC_IP"
        return 0
    else
        print_error "输入的IP地址无效"
        exit 1
    fi
}

# 检查并更新ALLOWED_HOSTS配置
update_allowed_hosts() {
    local PUBLIC_IP=$1
    local SETTINGS_FILE="mblog/settings.py"

    print_info "正在检查ALLOWED_HOSTS配置..."

    if [ ! -f "$SETTINGS_FILE" ]; then
        print_error "未找到settings.py文件: $SETTINGS_FILE"
        return 1
    fi

    # 检查当前ALLOWED_HOSTS配置
    CURRENT_HOSTS=$(grep -E '^ALLOWED_HOSTS =' "$SETTINGS_FILE" | cut -d'=' -f2-)
    print_info "当前ALLOWED_HOSTS: $CURRENT_HOSTS"

    # 检查是否已包含公网IP
    if [[ "$CURRENT_HOSTS" == *"$PUBLIC_IP"* ]]; then
        print_success "ALLOWED_HOSTS中已包含公网IP: $PUBLIC_IP"
        return 0
    fi

    # 备份settings.py
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak" || {
        print_error "无法备份settings.py文件"
        return 1
    }
    print_info "已创建settings.py备份: ${SETTINGS_FILE}.bak"

    # 更新ALLOWED_HOSTS
    if [[ "$CURRENT_HOSTS" == *"['"*"']"* ]]; then
        # 替换现有配置
        sed -i "s/^ALLOWED_HOSTS = \[.*\]/ALLOWED_HOSTS = ['$PUBLIC_IP', 'localhost', '127.0.0.1']/g" "$SETTINGS_FILE"
    else
        # 添加新配置
        echo -e "
# 添加公网IP到ALLOWED_HOSTS
ALLOWED_HOSTS = ['$PUBLIC_IP', 'localhost', '127.0.0.1']" >> "$SETTINGS_FILE"
    fi

    # 验证更新
    UPDATED_HOSTS=$(grep -E '^ALLOWED_HOSTS =' "$SETTINGS_FILE" | cut -d'=' -f2-)
    if [[ "$UPDATED_HOSTS" == *"$PUBLIC_IP"* ]]; then
        print_success "成功更新ALLOWED_HOSTS: $UPDATED_HOSTS"
        return 0
    else
        print_error "更新ALLOWED_HOSTS失败"
        print_info "尝试手动更新settings.py文件"
        return 1
    fi
}

# 检查Django服务状态
check_django_status() {
    print_info "正在检查Django服务状态..."

    # 检查是否有运行中的Django进程
    DJANGO_PID=$(ps aux | grep 'python manage.py runserver' | grep -v grep | awk '{print $2}')
    if [ -n "$DJANGO_PID" ]; then
        print_info "发现运行中的Django进程: $DJANGO_PID"
        print_warning "建议重启Django服务以应用配置更改"
        print_info "重启命令: kill $DJANGO_PID && python manage.py runserver 0.0.0.0:8000"
    else
        print_info "未发现运行中的Django进程"
        print_info "启动命令: python manage.py runserver 0.0.0.0:8000"
    fi
}

# 测试网络连接
test_network() {
    local PUBLIC_IP=$1

    print_info "正在执行网络连接测试..."

    # 检查本地8000端口是否监听
    print_info "检查本地8000端口监听状态..."
    if ss -tuln | grep -q ':8000'; then
        print_success "本地8000端口正在监听"
    else
        print_error "本地8000端口未监听"
        print_info "请确保Django服务器正在运行并监听8000端口"
    fi

    # 检查防火墙规则
    print_info "检查防火墙规则..."
    if command -v firewall-cmd &> /dev/null; then
        # 使用firewall-cmd
        if firewall-cmd --list-ports | grep -q '8000/tcp'; then
            print_success "防火墙已开放8000端口"
        else
            print_warning "防火墙未开放8000端口"
            print_info "执行命令开放端口: firewall-cmd --zone=public --add-port=8000/tcp --permanent && firewall-cmd --reload"
        fi
    elif command -v ufw &> /dev/null; then
        # 使用ufw
        if ufw status | grep -q '8000/tcp'; then
            print_success "防火墙已开放8000端口"
        else
            print_warning "防火墙未开放8000端口"
            print_info "执行命令开放端口: ufw allow 8000/tcp"
        fi
    else
        print_info "无法确定防火墙状态，请手动检查"
    fi

    # 提供测试命令
    print_info "\n外部连接测试建议:\n"
    print_info "1. 在本地计算机测试网络连通性: ping $PUBLIC_IP"
    print_info "2. 测试端口连通性: telnet $PUBLIC_IP 8000"
    print_info "3. 测试HTTP访问: curl http://$PUBLIC_IP:8000"
    print_info "4. 在浏览器中访问: http://$PUBLIC_IP:8000"
}

# 主函数
main() {
    echo -e "${BLUE}=== Django公网访问修复工具 ===${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}此工具将帮助修复Django网站无法从外部访问的问题${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}日志文件: $LOG_FILE${NC}\n" | tee -a "$LOG_FILE"

    # 检查root权限
    check_root

    # 获取公网IP
    PUBLIC_IP=$(get_public_ip)
    if [ -z "$PUBLIC_IP" ]; then
        print_error "无法获取公网IP，脚本退出"
        exit 1
    fi

    # 更新ALLOWED_HOSTS
    update_allowed_hosts "$PUBLIC_IP"

    # 检查Django状态
    check_django_status

    # 测试网络连接
    test_network "$PUBLIC_IP"

    echo -e "\n${GREEN}=== 修复完成 ===${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}1. 已获取公网IP: $PUBLIC_IP${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}2. 已更新ALLOWED_HOSTS配置${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}3. 已检查Django服务状态${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}4. 已提供网络连接测试建议${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}请重启Django服务器以应用更改${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}详细结果请查看日志文件: $LOG_FILE${NC}" | tee -a "$LOG_FILE"
}

# 执行主函数
main