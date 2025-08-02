#!/bin/bash

# 修复Django网站无法访问问题的脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 检查Python虚拟环境
echo -e "${BLUE}=== 检查Python虚拟环境 ===${NC}"
if [[ -z "$VIRTUAL_ENV" ]]; then
    echo -e "${YELLOW}警告：未激活Python虚拟环境${NC}"
    echo "请先运行: source django_env/bin/activate"
    exit 1
else
    echo -e "${GREEN}已激活虚拟环境: $VIRTUAL_ENV${NC}"
fi

# 停止现有uWSGI进程
 echo -e "${BLUE}=== 停止现有uWSGI进程 ===${NC}"
 if ps aux | grep uwsgi | grep -v grep &> /dev/null; then
     echo "正在停止uWSGI进程..."
     # 安全停止uWSGI进程
     if [ -f /tmp/uwsgi.pid ]; then
         uwsgi --stop /tmp/uwsgi.pid
         sleep 3
     fi
     # 强制终止剩余进程
     pkill -f uwsgi || true
     sleep 2
 fi

# 检查8000端口是否被占用
 echo -e "${BLUE}=== 检查8000端口占用情况 ===${NC}"
 if netstat -tuln | grep 8000 &> /dev/null; then
     echo -e "${YELLOW}8000端口已被占用${NC}"
     echo "正在尝试释放端口..."
     # 查找并终止占用8000端口的进程
     lsof -ti :8000 | xargs kill -9 || true
     sleep 2
 fi

# 启动uWSGI服务
 echo -e "${BLUE}=== 启动uWSGI服务 ===${NC}"
 echo "正在启动uWSGI服务..."
 uwsgi --ini uwsgi.ini --daemonize uwsgi.log
 sleep 5  # 等待服务启动
 if ps aux | grep uwsgi | grep -v grep &> /dev/null; then
     echo -e "${GREEN}uWSGI服务启动成功${NC}"
 else
     echo -e "${RED}uWSGI服务启动失败${NC}"
     echo "请检查uwsgi.ini配置文件"
     exit 1
 fi

# 检查8000端口监听状态
echo -e "\n${BLUE}=== 检查8000端口监听状态 ===${NC}"
netstat -tuln | grep 8000
if [ $? -eq 0 ]; then
    echo -e "${GREEN}8000端口已被监听${NC}"
else
    echo -e "${RED}8000端口未被监听${NC}"
    echo "请检查uWSGI配置文件中的端口设置"
    exit 1
fi

# 开放8000端口 (适用于CentOS/RHEL)
echo -e "\n${BLUE}=== 开放8000端口 ===${NC}"
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --list-ports | grep 8000/tcp
    if [ $? -ne 0 ]; then
        echo "正在开放8000端口..."
        firewall-cmd --add-port=8000/tcp --permanent
        firewall-cmd --reload
        if firewall-cmd --list-ports | grep 8000/tcp &> /dev/null; then
            echo -e "${GREEN}8000端口已在firewalld中开放${NC}"
        else
            echo -e "${RED}开放8000端口失败${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}8000端口已在firewalld中开放${NC}"
    fi
fi

# 本地测试访问
echo -e "\n${BLUE}=== 本地测试访问 ===${NC}"
echo "正在尝试本地访问..."
curl -v http://localhost:8000
if [ $? -eq 0 ]; then
    echo -e "${GREEN}本地访问成功${NC}"
else
    echo -e "${RED}本地访问失败${NC}"
    echo -e "\n${BLUE}=== 检查Django应用状态 ===${NC}"
    python manage.py check
    if [ $? -ne 0 ]; then
        echo -e "${RED}Django应用检查失败${NC}"
        echo "请修复Django应用中的问题"
        exit 1
    else
        echo -e "${GREEN}Django应用检查通过${NC}"
        echo -e "\n${BLUE}=== 查看uWSGI日志 ===${NC}"
        if [ -f "uwsgi.log" ]; then
            echo "uWSGI日志最后10行:"
            tail -n 10 uwsgi.log
        else
            echo -e "${YELLOW}uWSGI日志文件不存在${NC}"
        fi
        exit 1
    fi
fi

# 总结
echo -e "\n${BLUE}=== 修复总结 ===${NC}"
echo -e "${GREEN}1. uWSGI服务已启动${NC}"
echo -e "${GREEN}2. 8000端口已监听${NC}"
echo -e "${GREEN}3. 8000端口已在防火墙中开放${NC}"
echo -e "${GREEN}4. 本地访问测试成功${NC}"
echo -e "\n${YELLOW}请确保云服务提供商的安全组已开放8000端口${NC}"
echo "现在可以尝试通过 http://服务器IP:8000 访问网站"