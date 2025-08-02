# Django uWSGI 部署与故障排除指南

本指南提供了在Linux服务器上部署Django应用与uWSGI的详细步骤，以及常见问题的故障排除方法。

## 目录
- [准备工作](#准备工作)
- [部署步骤](#部署步骤)
- [故障排除工具](#故障排除工具)
- [常见问题](#常见问题)
- [安全建议](#安全建议)

## 准备工作
1. 确保已在服务器上安装Python和虚拟环境
2. 上传Django项目到服务器（推荐路径：`/var/www/django_project/mblog/`）
3. 安装项目依赖：
   ```bash
   cd /var/www/django_project/mblog/
   python -m venv django_env
   source django_env/bin/activate
   pip install -r requirements.txt
   ```

## 部署步骤
1. **上传配置文件和脚本**：
   ```bash
   scp uwsgi.ini root@服务器IP:/var/www/django_project/mblog/
   scp fix_access.sh root@服务器IP:/var/www/django_project/mblog/
   scp test_django_uwsgi.sh root@服务器IP:/var/www/django_project/mblog/
   scp test_connection.sh root@服务器IP:/var/www/django_project/mblog/
   ```

2. **登录服务器并设置权限**：
   ```bash
   ssh root@服务器IP
   cd /var/www/django_project/mblog/
   chmod +x *.sh
   ```

3. **运行修复脚本**：
   ```bash
   source django_env/bin/activate
   ./fix_access.sh
   ```

4. **验证部署**：
   在本地浏览器中访问：`http://服务器IP:8000`

## 故障排除工具

### 1. 基础检查脚本: `check_uwsgi.sh`
   检查uWSGI进程状态、端口监听和配置文件。
   ```bash
   ./check_uwsgi.sh
   ```

### 2. 访问诊断脚本: `diagnose_access.sh`
   诊断无法访问网站的原因，包括服务状态、端口监听、防火墙配置等。
   ```bash
   ./diagnose_access.sh
   ```

### 3. 修复脚本: `fix_access.sh`
   自动修复常见问题，包括启动uWSGI服务、开放防火墙端口等。
   ```bash
   ./fix_access.sh
   ```

### 4. Django-uWSGI测试脚本: `test_django_uwsgi.sh`
   在调试模式下启动uWSGI，显示详细配置和错误信息。
   ```bash
   ./test_django_uwsgi.sh
   ```
   （在另一个终端中运行 `curl http://localhost:8000` 进行测试）

### 5. 网络连接测试脚本: `test_connection.sh`
   全面测试服务器连接，包括本地访问、防火墙配置和安全组建议。
   ```bash
   ./test_connection.sh
   ```

## 常见问题

### 1. uWSGI服务启动失败
- 检查配置文件路径是否正确
- 查看错误日志：`cat uwsgi.log`
- 确保虚拟环境已激活

### 2. 8000端口已被占用
- 查找占用端口的进程：`lsof -ti :8000`
- 终止占用进程：`kill -9 <进程ID>`
- 或使用脚本自动释放端口：`./fix_access.sh`

### 3. 本地访问成功但外部无法访问
- 检查服务器防火墙是否开放8000端口
- 检查云服务器安全组配置
- 确认服务器有公网IP地址

### 4. 访问时出现"Empty reply from server"
- 检查uWSGI日志中的错误信息
- 增大uWSGI缓冲区大小（已在配置文件中设置）
- 测试Django开发服务器是否正常：`python manage.py runserver 0.0.0.0:8000`

## 安全建议
1. 避免以root用户运行uWSGI服务，在`uwsgi.ini`中添加：
   ```ini
   uid = www-data
   gid = www-data
   ```

2. 配置Nginx作为反向代理，提高性能和安全性

3. 定期备份数据库和项目文件

4. 限制服务器安全组入站规则，只开放必要的端口

5. 保持系统和依赖包更新

## 联系方式
如有其他问题，请提供详细的错误日志和执行结果，以便进一步分析和解决。"# VictorPengnb" 
