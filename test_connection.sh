#!/bin/bash

# 网络连接测试脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 检查服务器IP
 echo -e "${BLUE}=== 服务器信息 ===${NC}"
SERVER_IP=$(curl -s ifconfig.me)
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
fi
echo "服务器IP地址: $SERVER_IP"

# 检查uWSGI服务状态
 echo -e "${BLUE}=== uWSGI服务状态 ===${NC}"
if ps aux | grep uwsgi | grep -v grep &> /dev/null; then
    echo -e "${GREEN}uWSGI服务正在运行${NC}"
    ps aux | grep uwsgi | grep -v grep
else
    echo -e "${RED}uWSGI服务未运行${NC}"
    echo "请先运行: ./fix_access.sh"
    exit 1
fi

# 检查8000端口监听状态
 echo -e "${BLUE}=== 8000端口监听状态 ===${NC}"
if netstat -tuln | grep 8000 &> /dev/null; then
    echo -e "${GREEN}8000端口已被监听${NC}"
    netstat -tuln | grep 8000
else
    echo -e "${RED}8000端口未被监听${NC}"
    exit 1
fi

# 本地访问测试
 echo -e "${BLUE}=== 本地访问测试 ===${NC}"
curl -v http://localhost:8000
if [ $? -eq 0 ]; then
    echo -e "${GREEN}本地访问成功${NC}"
else
    echo -e "${RED}本地访问失败${NC}"
    echo "请检查Django应用和uWSGI配置"
    exit 1
fi

# 防火墙配置检查
 echo -e "${BLUE}=== 防火墙配置检查 ===${NC}"
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --list-ports | grep 8000/tcp
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}8000端口已在firewalld中开放${NC}"
    else
        echo -e "${YELLOW}8000端口未在firewalld中开放${NC}"
        echo "建议运行: firewall-cmd --add-port=8000/tcp --permanent && firewall-cmd --reload"
    fi
elif command -v ufw &> /dev/null; then
    ufw status | grep 8000
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}8000端口已在ufw中开放${NC}"
    else
        echo -e "${YELLOW}8000端口未在ufw中开放${NC}"
        echo "建议运行: ufw allow 8000/tcp"
    fi
else
    echo -e "${YELLOW}未检测到常用防火墙工具，无法确认端口开放状态${NC}"
fi

# 安全组配置提示
 echo -e "${BLUE}=== 安全组配置提示 ===${NC}"
echo -e "${YELLOW}请确保您的云服务器安全组已开放8000端口的入站流量${NC}"
echo "安全组规则参考:"
echo "- 协议: TCP"
echo "- 端口范围: 8000"
echo "- 源地址: 0.0.0.0/0 (或根据需求限制)"

# 外部访问测试建议
 echo -e "${BLUE}=== 外部访问测试建议 ===${NC}"
echo "在本地计算机上运行以下命令测试访问:"
echo "curl http://$SERVER_IP:8000"
echo -e "${YELLOW}如果外部访问失败但本地访问成功，请检查云服务器安全组配置${NC}"