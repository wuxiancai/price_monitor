#!/bin/bash

# 币安币价监控系统一键安装脚本
# 适用于Ubuntu Server 18.04+

set -e

echo "🚀 币安币价监控系统一键安装脚本"
echo "======================================"

# 检查是否为root用户
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  请不要使用root用户运行此脚本"
    echo "建议使用普通用户（如ubuntu）运行"
    exit 1
fi

# 获取当前用户和目录
CURRENT_USER=$(whoami)
INSTALL_DIR="/home/$CURRENT_USER/price_monitor"

echo "📋 安装信息:"
echo "   用户: $CURRENT_USER"
echo "   安装目录: $INSTALL_DIR"
echo "   端口: 8888"
echo ""

# 检查网络连接
echo "🌐 检查网络连接..."
if ! curl -s --connect-timeout 5 https://api.binance.com/api/v3/ping > /dev/null; then
    echo "❌ 无法连接到币安API，请检查网络连接"
    exit 1
fi
echo "✅ 网络连接正常"

# 更新系统包
echo "📦 更新系统包..."
sudo apt update

# 安装必要的系统包
echo "🔧 安装必要的系统包..."
sudo apt install -y python3 python3-venv python3-pip curl ufw

# 创建安装目录
echo "📁 创建安装目录..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 如果当前目录已有文件，询问是否继续
if [ "$(ls -A .)" ]; then
    echo "⚠️  目录 $INSTALL_DIR 不为空"
    read -p "是否继续安装？这将覆盖现有文件 (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "安装已取消"
        exit 1
    fi
fi

# 检查是否已有项目文件
if [ ! -f "app.py" ]; then
    echo "❌ 未找到项目文件"
    echo "请确保以下文件存在于 $INSTALL_DIR 目录中:"
    echo "  - app.py"
    echo "  - requirements.txt"
    echo "  - start.sh"
    echo "  - templates/index.html"
    echo ""
    echo "您可以通过以下方式获取项目文件:"
    echo "1. 使用scp上传文件到服务器"
    echo "2. 使用git克隆项目"
    echo "3. 手动创建文件"
    exit 1
fi

# 设置文件权限
echo "🔐 设置文件权限..."
chmod +x start.sh
chmod 644 app.py requirements.txt
if [ -f "templates/index.html" ]; then
    chmod 644 templates/index.html
fi

# 安装Python依赖
echo "🐍 安装Python依赖..."
./start.sh install

# 创建systemd服务文件
echo "⚙️  创建系统服务..."
sudo tee /etc/systemd/system/price-monitor.service > /dev/null <<EOF
[Unit]
Description=Binance Price Monitor
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/app.py
Restart=always
RestartSec=10
StandardOutput=append:$INSTALL_DIR/price_monitor.log
StandardError=append:$INSTALL_DIR/price_monitor.log

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd并启用服务
sudo systemctl daemon-reload
sudo systemctl enable price-monitor

# 启动服务
echo "🚀 启动服务..."
sudo systemctl start price-monitor

# 等待服务启动
sleep 3

# 检查服务状态
if sudo systemctl is-active --quiet price-monitor; then
    echo "✅ 服务启动成功！"
else
    echo "❌ 服务启动失败，尝试使用启动脚本..."
    ./start.sh start
    sleep 2
fi

# 获取服务器IP
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="your-server-ip"
fi

echo ""
echo "🎉 安装完成！"
echo "======================================"
echo "📊 访问地址: http://$SERVER_IP:8888"
echo "📝 日志文件: $INSTALL_DIR/price_monitor.log"
echo "🔧 管理命令:"
echo "   启动服务: sudo systemctl start price-monitor"
echo "   停止服务: sudo systemctl stop price-monitor"
echo "   重启服务: sudo systemctl restart price-monitor"
echo "   查看状态: sudo systemctl status price-monitor"
echo "   查看日志: tail -f $INSTALL_DIR/price_monitor.log"
echo ""
echo "或使用启动脚本:"
echo "   $INSTALL_DIR/start.sh [start|stop|restart|status|logs]"
echo ""
echo "💡 提示:"
echo "   - 如果无法访问，请检查云服务器安全组设置"
echo "   - 确保开放8888端口的入站规则"
echo "   - 服务会自动开机启动"
echo "======================================"

# 显示实时日志（可选）
read -p "是否查看实时日志？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "按 Ctrl+C 退出日志查看"
    tail -f "$INSTALL_DIR/price_monitor.log"
fi