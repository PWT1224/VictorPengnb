#!/bin/bash

# 替代访问方法脚本 - 当8000端口无法访问时使用

# 配置变量
ALTERNATIVE_PORT=8080
UWSGI_CONFIG="uwsgi.ini"
DJANGO_SETTINGS_MODULE="mblog.settings"

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

# 方法1: 使用Django开发服务器临时访问
start_django_dev_server() {
    echo -e "\n=== 方法1: 启动Django开发服务器 ==="
    echo "注意: 开发服务器仅用于测试，不建议生产环境使用"
    echo "正在启动Django开发服务器在端口 $ALTERNATIVE_PORT..."
    python manage.py runserver 0.0.0.0:$ALTERNATIVE_PORT --insecure &
    DEV_SERVER_PID=$!
    echo "Django开发服务器已启动，PID: $DEV_SERVER_PID"
    echo "访问地址: http://服务器IP:$ALTERNATIVE_PORT"
    echo "按Ctrl+C停止开发服务器"
    wait $DEV_SERVER_PID
}

# 方法2: 检查uWSGI配置并使用其他端口启动
check_uwsgi_config() {
    echo -e "\n=== 方法2: 检查uWSGI配置并使用其他端口启动 ==="
    if [ ! -f "$UWSGI_CONFIG" ]; then
        echo "错误: 找不到uWSGI配置文件 $UWSGI_CONFIG!"
        return 1
    fi

    echo "查看当前uWSGI配置..."
    grep -E 'socket|http|port|chdir|wsgi-file' "$UWSGI_CONFIG"

    echo -e "\n正在修改uWSGI配置使用端口 $ALTERNATIVE_PORT..."
    # 创建临时配置文件
    TEMP_CONFIG="temp_uwsgi.ini"
    sed "s/8000/$ALTERNATIVE_PORT/g" "$UWSGI_CONFIG" > "$TEMP_CONFIG"
    echo "临时配置文件已创建: $TEMP_CONFIG"

    echo "正在停止可能运行的uWSGI进程..."
    pkill -f uwsgi || true
    sleep 2

    echo "正在使用临时配置启动uWSGI服务..."
    uwsgi --ini "$TEMP_CONFIG" --daemonize "uwsgi_$ALTERNATIVE_PORT.log"
    echo "uWSGI服务已启动在端口 $ALTERNATIVE_PORT"
    echo "日志文件: uwsgi_$ALTERNATIVE_PORT.log"
    echo "访问地址: http://服务器IP:$ALTERNATIVE_PORT"
    echo "注意: 测试完成后请删除临时配置文件: rm $TEMP_CONFIG"
}

# 方法3: 检查网络连接和防火墙
check_network() {
    echo -e "\n=== 方法3: 检查网络连接和防火墙 ==="
    echo "检查服务器IP地址..."
    ip addr

    echo -e "\n检查防火墙状态..."
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --list-ports
    elif command -v ufw &> /dev/null; then
        ufw status
    else
        echo "无法确定防火墙状态，建议手动检查"
    fi

    echo -e "\n检查路由和网络连通性..."
    ping -c 3 www.baidu.com
    if [ $? -ne 0 ]; then
        echo "警告: 服务器网络连接可能存在问题"
    else
        echo "服务器网络连接正常"
    fi
}

# 主菜单
main_menu() {
    echo "=== 无法访问网站替代方法工具 ==="
    echo "1. 使用Django开发服务器临时访问"
    echo "2. 检查uWSGI配置并使用其他端口启动"
    echo "3. 检查网络连接和防火墙"
    echo "4. 退出"
    read -p "请选择操作 (1-4): " choice

    case $choice in
        1)
            check_venv
            start_django_dev_server
            ;;
        2)
            check_venv
            check_uwsgi_config
            ;;
        3)
            check_network
            ;;
        4)
            echo "退出脚本"
            exit 0
            ;;
        *)
            echo "无效选择，请重新输入"
            main_menu
            ;;
    esac
}

# 执行主菜单
echo "=== 网站访问问题排查工具 ==="
echo "当无法访问8000端口时，可尝试以下替代方法"
main_menu