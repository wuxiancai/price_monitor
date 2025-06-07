# Ubuntu服务器部署指南

本指南将帮助您在Ubuntu服务器上快速部署币安币价监控系统。

## 前置条件

- Ubuntu Server 18.04+ 
- 具有sudo权限的用户账户
- 服务器可以访问互联网
- 开放的端口（默认8888）

## 一键部署脚本

### 方法1：使用wget下载

```bash
# 下载项目文件（假设您已将文件上传到服务器或通过git克隆）
cd /home/ubuntu
mkdir price_monitor
cd price_monitor

# 如果您有项目压缩包的下载链接，可以使用：
# wget -O price_monitor.zip [您的下载链接]
# unzip price_monitor.zip
```

### 方法2：手动上传文件

使用SCP或SFTP将以下文件上传到服务器：
- `app.py`
- `requirements.txt` 
- `start.sh`
- `templates/index.html`

```bash
# 在本地机器上执行
scp -r price_monitor/ ubuntu@your-server-ip:/home/ubuntu/
```

## 快速部署步骤

### 1. 更新系统并安装依赖

```bash
# 更新包列表
sudo apt update

# 安装Python3和pip
sudo apt install python3 python3-pip -y

# 安装git（如果需要）
sudo apt install git -y
```

### 2. 进入项目目录并安装Python依赖

```bash
cd /home/ubuntu/price_monitor

# 使用启动脚本安装依赖
./start.sh install

# 或者手动安装
# pip3 install -r requirements.txt
```

### 3. 配置防火墙

```bash
# 启用UFW防火墙（如果未启用）
sudo ufw enable

# 允许SSH连接（重要！）
sudo ufw allow ssh

# 开放8888端口
sudo ufw allow 8888

# 查看防火墙状态
sudo ufw status
```

### 4. 启动服务

```bash
# 使用启动脚本启动
./start.sh start

# 查看服务状态
./start.sh status

# 查看日志
./start.sh logs
```

### 5. 测试访问

在浏览器中访问：`http://您的服务器IP:8888`

例如：`http://123.456.789.123:8888`

## 云服务器特定配置

### 阿里云ECS

1. 在安全组中开放8888端口
2. 确保实例可以访问外网

### 腾讯云CVM

1. 在安全组中添加入站规则，开放8888端口
2. 确保实例绑定了公网IP

### AWS EC2

1. 在Security Group中添加入站规则：
   - Type: Custom TCP
   - Port: 8888
   - Source: 0.0.0.0/0

### 华为云ECS

1. 在安全组中添加入方向规则，开放8888端口

## 设置开机自启动

### 方法1：使用systemd服务

```bash
# 创建服务文件
sudo tee /etc/systemd/system/price-monitor.service > /dev/null <<EOF
[Unit]
Description=Binance Price Monitor
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/price_monitor
ExecStart=/usr/bin/python3 /home/ubuntu/price_monitor/app.py
Restart=always
RestartSec=10
StandardOutput=append:/home/ubuntu/price_monitor/price_monitor.log
StandardError=append:/home/ubuntu/price_monitor/price_monitor.log

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable price-monitor

# 启动服务
sudo systemctl start price-monitor

# 查看服务状态
sudo systemctl status price-monitor
```

### 方法2：使用crontab

```bash
# 编辑crontab
crontab -e

# 添加以下行（在文件末尾）
@reboot cd /home/ubuntu/price_monitor && ./start.sh start
```

## 常用管理命令

```bash
# 启动服务
./start.sh start

# 停止服务
./start.sh stop

# 重启服务
./start.sh restart

# 查看状态
./start.sh status

# 查看日志
./start.sh logs

# 实时查看日志
tail -f price_monitor.log
```

## 性能优化建议

### 1. 调整更新频率

如果服务器性能较低，可以增加价格更新间隔：

编辑 `app.py`，修改：
```python
time.sleep(60)  # 改为60秒更新一次
```

### 2. 限制日志大小

```bash
# 创建日志轮转配置
sudo tee /etc/logrotate.d/price-monitor > /dev/null <<EOF
/home/ubuntu/price_monitor/price_monitor.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    copytruncate
}
EOF
```

## 故障排除

### 1. 端口被占用

```bash
# 查看端口占用
sudo netstat -tlnp | grep 8888

# 杀死占用进程
sudo kill -9 [PID]
```

### 2. 权限问题

```bash
# 确保文件权限正确
chmod +x start.sh
chmod 644 app.py requirements.txt
chmod 644 templates/index.html
```

### 3. Python依赖问题

```bash
# 升级pip
pip3 install --upgrade pip

# 重新安装依赖
pip3 install --force-reinstall -r requirements.txt
```

### 4. 网络连接问题

```bash
# 测试币安API连接
curl -s https://api.binance.com/api/v3/ping

# 应该返回: {}
```

## 安全建议

1. 定期更新系统：`sudo apt update && sudo apt upgrade`
2. 配置SSH密钥认证，禁用密码登录
3. 使用非root用户运行服务
4. 定期备份配置文件
5. 监控系统资源使用情况

## 监控和维护

### 设置监控脚本

```bash
# 创建健康检查脚本
tee /home/ubuntu/price_monitor/health_check.sh > /dev/null <<EOF
#!/bin/bash
response=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888)
if [ \$response -ne 200 ]; then
    echo "Service is down, restarting..."
    cd /home/ubuntu/price_monitor
    ./start.sh restart
fi
EOF

chmod +x /home/ubuntu/price_monitor/health_check.sh

# 添加到crontab，每5分钟检查一次
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ubuntu/price_monitor/health_check.sh") | crontab -
```

这样就完成了完整的部署配置！