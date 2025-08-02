#!/bin/bash

# 启动uWSGI服务并监控状态的脚本

# 配置变量
UWSGI_CONFIG="uwsgi.ini"
LOG_FILE="uwsgi.log"
PID_FILE="uwsgi.pid"
PORT=8000

# 检查是否已在虚拟环境中
check_venv() {
    if [ -z "$VIRTUAL_ENV" ]; then
        echo "错误: 未激活Python虚拟环境!"
        echo "请先运行: source django_env/bin/activate"
        exit 1
    else
        echo "已激活虚拟环境: $VIRTUAL_ENV"
    fi
}

# 检查配置文件是否存在
check_config() {
    if [ ! -f "$UWSGI_CONFIG" ]; then
        echo "错误: 找不到uWSGI配置文件 $UWSGI_CONFIG!"
        exit 1
    else
        echo "找到uWSGI配置文件: $UWSGI_CONFIG"
    fi
}

# 停止现有uWSGI进程（如果有）
stop_existing_uwsgi() {
    echo "检查是否有正在运行的uWSGI进程..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        echo "找到uWSGI进程PID: $PID"
        echo "尝试停止进程..."
        kill -TERM $PID
        sleep 2
        # 强制终止仍在运行的进程
        if ps -p $PID > /dev/null; then
            echo "进程未正常停止，强制终止..."
            kill -9 $PID
            sleep 1
        fi
        rm -f "$PID_FILE"
        echo "已清理PID文件"
    else
        echo "未找到uWSGI PID文件，跳过停止步骤"
    fi
}

# 检查端口是否被占用
check_port() {
    echo "检查$PORT端口是否被占用..."
    if netstat -tuln | grep :$PORT > /dev/null; then
        echo "错误: $PORT端口已被占用!"
        echo "找到占用进程:"
        lsof -i :$PORT || fuser $PORT/tcp
        exit 1
    else
        echo "$PORT端口未被占用"
    fi
}

# 启动uWSGI服务
start_uwsgi() {
    echo "启动uWSGI服务..."
    uwsgi --ini "$UWSGI_CONFIG" --pidfile "$PID_FILE" --daemonize "$LOG_FILE"
    if [ $? -ne 0 ]; then
        echo "错误: uWSGI服务启动失败!"
        echo "查看日志获取详细信息: tail -n 50 $LOG_FILE"
        exit 1
    else
        echo "uWSGI服务启动成功"
        echo "PID文件: $PID_FILE"
        echo "日志文件: $LOG_FILE"
    fi
}

# 验证服务是否启动成功
verify_service() {
    echo "验证uWSGI服务是否启动成功..."
    sleep 3
    if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null; then
        echo "uWSGI进程正在运行"
        echo "检查端口监听情况..."
        netstat -tuln | grep :$PORT
        if [ $? -ne 0 ]; then
            echo "警告: uWSGI进程运行中，但未监听$PORT端口"
            echo "可能是配置问题，请检查$UWSGI_CONFIG和$LOG_FILE"
        else
            echo "uWSGI服务已成功监听$PORT端口"
        fi
    else
        echo "错误: uWSGI服务未启动成功"
        echo "查看日志获取详细信息: tail -n 50 $LOG_FILE"
        exit 1
    fi
}

# 主流程
echo "=== uWSGI服务启动脚本 ==="
check_venv
check_config
stop_existing_uwsgi
check_port
start_uwsgi
verify_service
echo "=== 脚本执行完成 ==="