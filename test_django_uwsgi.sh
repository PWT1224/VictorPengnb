#!/bin/bash

# 测试Django和uWSGI连接的脚本

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

# 测试Django应用是否正常
 echo -e "${BLUE}=== 测试Django应用 ===${NC}"
 echo "正在运行Django检查..."
 python manage.py check
if [ $? -ne 0 ]; then
    echo -e "${RED}Django应用检查失败${NC}"
    exit 1
else
    echo -e "${GREEN}Django应用检查通过${NC}"
fi

# 检查uWSGI配置文件
 echo -e "${BLUE}=== 检查uWSGI配置 ===${NC}"
if [ -f "uwsgi.ini" ]; then
    echo "uWSGI配置文件存在，内容如下："
    cat uwsgi.ini | grep -v "^#" | grep -v "^$"
else
    echo -e "${RED}uWSGI配置文件不存在${NC}"
    exit 1
fi

# 测试uWSGI服务
 echo -e "${BLUE}=== 测试uWSGI服务 ===${NC}"

# 确保8000端口未被占用
if netstat -tuln | grep 8000 &> /dev/null; then
    echo -e "${YELLOW}8000端口已被占用，正在释放...${NC}"
    lsof -ti :8000 | xargs kill -9 || true
    sleep 2
fi

# 启动uWSGI服务（非后台模式，便于查看输出）
echo "正在启动uWSGI服务（调试模式）..."
uwsgi --ini uwsgi.ini --http :8000 --show-config --catch-exceptions

# 提示用户在另一个终端测试访问
echo -e "\n${YELLOW}请在另一个终端中运行以下命令测试访问：${NC}"
echo "curl http://localhost:8000"
echo -e "${YELLOW}按Ctrl+C停止uWSGI服务${NC}"