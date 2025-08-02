#!/bin/bash

# 解决Django开发服务器端口被占用问题的脚本

# 配置变量
TARGET_PORT=8000
ALTERNATIVE_PORT=8080
LOG_FILE="port_issue.log"

# 清屏并显示脚本信息
clear
 echo "=== Django端口占用问题解决工具 ==="
 echo "此工具将帮助你解决Django开发服务器端口被占用的问题"
 echo "目标端口: $TARGET_PORT"
 echo "备选端口: $ALTERNATIVE_PORT"
 echo "日志文件: $LOG_FILE"
 echo "=========================="

# 函数: 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 函数: 检查端口是否被占用
check_port() {
    echo -e "\n=== 检查端口占用情况 ==="

    if command_exists lsof; then
        # 使用lsof检查端口占用
        PORT_PROCESS=$(lsof -i :$TARGET_PORT)
    elif command_exists netstat; then
        # 使用netstat检查端口占用
        PORT_PROCESS=$(netstat -tulpn | grep :$TARGET_PORT)
    else
        echo "✗ 无法检查端口占用情况，未找到lsof或netstat命令"
        return 1
    fi

    if [ -n "$PORT_PROCESS" ]; then
        echo "✗ 端口 $TARGET_PORT 已被占用!"
        echo "占用进程信息:"
        echo "$PORT_PROCESS"
        return 0
    else
        echo "✓ 端口 $TARGET_PORT 未被占用"
        return 1
    fi
}

# 函数: 终止占用端口的进程
kill_process() {
    echo -e "\n=== 终止占用端口的进程 ==="

    if command_exists lsof; then
        # 使用lsof查找进程ID
        PID=$(lsof -t -i :$TARGET_PORT)
    elif command_exists netstat; then
        # 使用netstat查找进程ID
        PID=$(netstat -tulpn | grep :$TARGET_PORT | awk '{print $7}' | cut -d'/' -f1)
    else
        echo "✗ 无法查找进程ID，未找到lsof或netstat命令"
        return 1
    fi

    if [ -n "$PID" ]; then
        echo "找到占用进程ID: $PID"
        read -p "是否终止该进程? (y/n): " confirm

        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            kill -9 $PID
            if [ $? -eq 0 ]; then
                echo "✓ 成功终止进程ID: $PID"
                return 0
            else
                echo "✗ 终止进程失败，请检查权限"
                return 1
            fi
        else
            echo "取消终止进程操作"
            return 1
        fi
    else
        echo "✗ 未找到占用进程ID"
        return 1
    fi
}

# 函数: 使用备选端口启动服务器
start_with_alternative_port() {
    echo -e "\n=== 使用备选端口启动服务器 ==="
    echo "备选端口: $ALTERNATIVE_PORT"

    read -p "是否使用 $ALTERNATIVE_PORT 端口启动服务器? (y/n): " confirm

    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo "正在使用 $ALTERNATIVE_PORT 端口启动Django服务器..."
        nohup python manage.py runserver 0.0.0.0:$ALTERNATIVE_PORT > django_server_$ALTERNATIVE_PORT.log 2>&1 &
        echo "✓ 服务器已在后台启动，日志文件: django_server_$ALTERNATIVE_PORT.log"
        echo "访问地址: http://$(hostname -I | cut -d' ' -f1):$ALTERNATIVE_PORT"
        return 0
    else
        echo "取消使用备选端口启动服务器"
        return 1
    fi
}

# 函数: 手动指定端口
manual_port_selection() {
    echo -e "\n=== 手动指定端口 ==="
    read -p "请输入要使用的端口号: " CUSTOM_PORT

    if [[ $CUSTOM_PORT =~ ^[0-9]+$ ]] && [ $CUSTOM_PORT -ge 1 ] && [ $CUSTOM_PORT -le 65535 ]; then
        # 检查自定义端口是否被占用
        if command_exists lsof; then
            CUSTOM_PORT_PROCESS=$(lsof -i :$CUSTOM_PORT)
        elif command_exists netstat; then
            CUSTOM_PORT_PROCESS=$(netstat -tulpn | grep :$CUSTOM_PORT)
        fi

        if [ -n "$CUSTOM_PORT_PROCESS" ]; then
            echo "✗ 端口 $CUSTOM_PORT 已被占用!"
            return 1
        else
            echo "正在使用 $CUSTOM_PORT 端口启动Django服务器..."
            nohup python manage.py runserver 0.0.0.0:$CUSTOM_PORT > django_server_$CUSTOM_PORT.log 2>&1 &
            echo "✓ 服务器已在后台启动，日志文件: django_server_$CUSTOM_PORT.log"
            echo "访问地址: http://$(hostname -I | cut -d' ' -f1):$CUSTOM_PORT"
            return 0
        fi
    else
        echo "✗ 无效的端口号，请输入1-65535之间的数字"
        return 1
    fi
}

# 主函数: 运行所有步骤
run_all_steps() {
    echo "开始解决端口占用问题..."
    echo "过程将保存到 $LOG_FILE"

    # 将输出重定向到日志文件和控制台
    { 
        # 检查端口是否被占用
        check_port
        PORT_OCCUPIED=$?

        if [ $PORT_OCCUPIED -eq 0 ]; then
            # 端口被占用，尝试终止进程
            kill_process
            KILL_SUCCESS=$?

            if [ $KILL_SUCCESS -eq 0 ]; then
                # 成功终止进程，使用原端口启动
                echo -e "\n=== 使用原端口启动服务器 ==="
                nohup python manage.py runserver 0.0.0.0:$TARGET_PORT > django_server.log 2>&1 &
                echo "✓ 服务器已在后台启动，日志文件: django_server.log"
                echo "访问地址: http://$(hostname -I | cut -d' ' -f1):$TARGET_PORT"
            else
                # 终止进程失败，提供备选方案
                echo -e "\n=== 备选方案 ==="
                echo "1. 使用备选端口 $ALTERNATIVE_PORT"
                echo "2. 手动指定其他端口"
                read -p "请选择 (1/2): " choice

                case $choice in
                    1)
                        start_with_alternative_port
                        ;;
                    2)
                        manual_port_selection
                        ;;
                    *)
                        echo "无效选择"
                        ;;
                esac
            fi
        else
            # 端口未被占用，直接启动
            echo -e "\n=== 启动服务器 ==="
            nohup python manage.py runserver 0.0.0.0:$TARGET_PORT > django_server.log 2>&1 &
            echo "✓ 服务器已在后台启动，日志文件: django_server.log"
            echo "访问地址: http://$(hostname -I | cut -d' ' -f1):$TARGET_PORT"
        fi

        echo -e "\n=== 完成时间: $(date) ==="
    } | tee $LOG_FILE

    echo -e "\n操作完成！详细结果请查看 $LOG_FILE"
}

# 运行主函数
run_all_steps
</content>,"query_language":"Chinese"}}