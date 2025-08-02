#!/bin/bash

# 诊断Django网站无法访问问题的脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 检查uWSGI服务状态
echo -e "${BLUE}=== 检查uWSGI服务状态 ===${NC}"
ps aux | grep uwsgi | grep -v grep
if [ $? -eq 0 ]; then
    echo -e "${GREEN}uWSGI服务正在运行${NC}"
else
    echo -e "${RED}uWSGI服务未运行${NC}"
    echo "请运行: uwsgi --ini uwsgi.ini"
fi

# 检查8000端口监听状态
echo -e "\n${BLUE}=== 检查8000端口监听状态 ===${NC}"
netstat -tuln | grep 8000
if [ $? -eq 0 ]; then
    echo -e "${GREEN}8000端口已被监听${NC}"
else
    echo -e "${RED}8000端口未被监听${NC}"
    echo "请检查uWSGI配置文件中的端口设置"
fi

# 检查防火墙状态 (适用于CentOS/RHEL)
echo -e "\n${BLUE}=== 检查防火墙状态 (firewalld) ===${NC}"
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --list-ports | grep 8000/tcp
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}8000端口已在firewalld中开放${NC}"
    else
        echo -e "${YELLOW}8000端口未在firewalld中开放${NC}"
        echo "请运行: sudo firewall-cmd --add-port=8000/tcp --permanent && sudo firewall-cmd --reload"
    fi
fi

# 检查防火墙状态 (适用于Ubuntu/Debian)
if command -v ufw &> /dev/null; then
    echo -e "\n${BLUE}=== 检查防火墙状态 (ufw) ===${NC}"
    ufw status | grep 8000
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}8000端口已在ufw中开放${NC}"
    else
        echo -e "${YELLOW}8000端口未在ufw中开放${NC}"
        echo "请运行: sudo ufw allow 8000/tcp"
    fi
fi

# 本地测试访问
echo -e "\n${BLUE}=== 本地测试访问 ===${NC}"
curl -I http://localhost:8000
if [ $? -eq 0 ]; then
    echo -e "${GREEN}本地访问成功${NC}"
else
    echo -e "${RED}本地访问失败${NC}"
    echo "请检查Django应用是否正常运行"
fi

# 检查SELinux状态 (如果适用)
if command -v getenforce &> /dev/null; then
    echo -e "\n${BLUE}=== 检查SELinux状态 ===${NC}"
    getenforce
    if [ "$(getenforce)" = "Enforcing" ]; then
        echo -e "${YELLOW}SELinux处于强制模式${NC}"
        echo "可能需要配置SELinux以允许8000端口访问"
        echo "临时关闭: sudo setenforce 0"
        echo "永久配置: 需要修改/etc/selinux/config文件"
    fi
fi

# 总结
 echo -e "\n${BLUE}=== 问题诊断总结 ===${NC}"
if [ $? -eq 0 ] && netstat -tuln | grep -q 8000 && curl -s http://localhost:8000; then
    echo -e "${GREEN}应用和服务运行正常，但外部仍无法访问${NC}"
    echo -e "${YELLOW}请重点检查:${NC}"
    echo "1. 云服务提供商的安全组规则是否开放8000端口"
    echo "2. 服务器网络配置是否正确"
    echo "3. 是否有其他网络设备(如路由器)阻止了8000端口"
else
    echo -e "${RED}应用或服务存在问题${NC}"
    echo -e "${YELLOW}请按照上述检查结果修复问题${NC}"
fi