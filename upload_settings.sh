#!/bin/bash

# 上传settings.py文件到服务器脚本

# 配置变量
LOCAL_SETTINGS_FILE="d:\学习笔记·\Django4\dj4ch02\mblog\mblog\settings.py"
REMOTE_DIR="/path/to/mblog/mblog/"
SERVER_IP="39.104.71.209"
SERVER_USER="root"
LOG_FILE="upload_settings.log"

# 清屏并显示脚本信息
clear
 echo "=== settings.py文件上传工具 ==="
 echo "此工具将帮助你将修改后的settings.py文件上传到服务器"
 echo "本地文件: $LOCAL_SETTINGS_FILE"
 echo "服务器地址: $SERVER_USER@$SERVER_IP"
 echo "远程目录: $REMOTE_DIR"
 echo "日志文件: $LOG_FILE"
 echo "=========================="

# 函数: 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 函数: 检查本地文件是否存在
check_local_file() {
    echo -e "\n=== 检查本地文件 ==="

    if [ -f "$LOCAL_SETTINGS_FILE" ]; then
        echo "✓ 本地文件存在: $LOCAL_SETTINGS_FILE"
        echo "文件大小: $(du -h "$LOCAL_SETTINGS_FILE")"
        echo "最后修改时间: $(stat -c %y "$LOCAL_SETTINGS_FILE")"
    else
        echo "✗ 本地文件不存在: $LOCAL_SETTINGS_FILE"
        echo "请检查文件路径是否正确"
        exit 1
    fi
}

# 函数: 上传文件
upload_file() {
    echo -e "\n=== 上传文件到服务器 ==="

    # 提示用户确认服务器信息
    echo "请确认服务器信息:"
    echo "服务器IP: $SERVER_IP"
    echo "用户名: $SERVER_USER"
    echo "远程目录: $REMOTE_DIR"
    read -p "是否继续? (y/n): " confirm

    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "取消上传操作"
        exit 0
    fi

    # 执行scp命令上传文件
    echo "正在上传文件..."
    scp "$LOCAL_SETTINGS_FILE" "$SERVER_USER@$SERVER_IP:$REMOTE_DIR"

    if [ $? -eq 0 ]; then
        echo "✓ 文件上传成功"
    else
        echo "✗ 文件上传失败"
        echo "请检查以下事项:"
        echo "1. 服务器IP和用户名是否正确"
        echo "2. 远程目录是否存在"
        echo "3. 网络连接是否正常"
        echo "4. 服务器是否允许SSH连接"
        exit 1
    fi
}

# 函数: 验证上传结果
verify_upload() {
    echo -e "\n=== 验证上传结果 ==="

    # 检查远程文件是否存在
    echo "检查远程服务器上的文件..."
    ssh "$SERVER_USER@$SERVER_IP" "ls -l $REMOTE_DIR/settings.py"

    if [ $? -eq 0 ]; then
        echo "✓ 远程文件存在，上传验证成功"
        echo "远程文件信息:"
        ssh "$SERVER_USER@$SERVER_IP" "stat $REMOTE_DIR/settings.py"
    else
        echo "✗ 远程文件不存在，上传验证失败"
        exit 1
    fi
}

# 函数: 重启Django服务器
guide_restart() {
    echo -e "\n=== 重启Django服务器指南 ==="
    echo "文件上传成功后，建议重启Django服务器以应用更改"
    echo "重启命令:"
    echo "ssh $SERVER_USER@$SERVER_IP"
    echo "cd /path/to/mblog/"
    echo "# 停止正在运行的服务器进程"
    echo "pkill -f 'python manage.py runserver'"
    echo "# 启动服务器"
    echo "nohup python manage.py runserver 0.0.0.0:8000 > django_server.log 2>&1 &"
}

# 主函数: 运行所有步骤
run_all_steps() {
    echo "开始settings.py文件上传..."
    echo "上传过程将保存到 $LOG_FILE"

    # 将输出重定向到日志文件和控制台
    { 
        check_local_file
        upload_file
        verify_upload
        guide_restart
        echo -e "\n=== 上传完成时间: $(date) ==="
    } | tee $LOG_FILE

    echo -e "\n上传完成！详细结果请查看 $LOG_FILE"
}

# 运行主函数
run_all_steps
</content>}}}