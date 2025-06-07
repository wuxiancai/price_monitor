# 币安币价监控系统

一个轻量化的币安币价实时监控系统，支持8大主流数字货币价格监控。

## 功能特点

- 🚀 实时监控8个主流币种：BTC、ETH、SOL、XRP、DOGE、BNB、ADA、TRX
- 📊 显示开盘价（每日零点零分价格）、实时价格、涨跌百分比
- 🎨 美观的响应式Web界面，护眼配色
- ⚡ 轻量化设计，资源占用极低
- 🔄 自动1秒更新价格数据
- 📱 支持移动端访问

## 系统要求

- Ubuntu Server 18.04+
- Python 3.6+
- 网络连接（访问币安API）

## 快速部署

### 1. 下载代码

```bash
# 克隆或下载项目文件到服务器
wget -O price_monitor.zip [项目压缩包链接]
unzip price_monitor.zip
cd price_monitor
```

### 2. 安装Python依赖

```bash
# 更新系统包
sudo apt update

# 安装Python3和pip（如果未安装）
sudo apt install python3 python3-pip -y

# 安装项目依赖
pip3 install -r requirements.txt
```

### 3. 启动服务

```bash
# 直接启动（前台运行）
python3 app.py

# 后台运行（推荐）
nohup python3 app.py > price_monitor.log 2>&1 &
```

### 4. 配置防火墙

```bash
# 开放8888端口
sudo ufw allow 8888

# 如果使用其他防火墙，请相应开放端口
```

### 5. 访问系统

在浏览器中访问：`http://你的服务器IP:8888`

例如：`http://123.456.789.123:8888`

## 自定义配置

### 修改端口

编辑 `app.py` 文件，修改最后一行：

```python
app.run(host='0.0.0.0', port=8888, debug=False)  # 将8888改为你想要的端口
```

### 修改币种

编辑 `app.py` 文件，修改 `COINS` 和 `COIN_NAMES` 配置：

```python
COINS = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'XRPUSDT', 'DOGEUSDT', 'BNBUSDT', 'ADAUSDT', 'TRXUSDT']
COIN_NAMES = {'BTCUSDT': 'BTC', 'ETHUSDT': 'ETH', ...}
```

### 修改更新频率

编辑 `app.py` 文件，修改 `price_update_worker` 函数中的睡眠时间：

```python
time.sleep(30)  # 30秒更新一次，可以修改为其他值
```

## 系统服务配置（可选）

为了让程序开机自启动，可以创建systemd服务：

```bash
# 创建服务文件
sudo nano /etc/systemd/system/price-monitor.service
```

添加以下内容：

```ini
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

[Install]
WantedBy=multi-user.target
```

启用服务：

```bash
# 重新加载systemd配置
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable price-monitor

# 启动服务
sudo systemctl start price-monitor

# 查看服务状态
sudo systemctl status price-monitor
```

## 故障排除

### 1. 无法访问网页

- 检查防火墙设置
- 确认程序正在运行：`ps aux | grep python3`
- 检查端口是否被占用：`netstat -tlnp | grep 8888`

### 2. 价格数据不更新

- 检查网络连接
- 查看日志文件：`tail -f price_monitor.log`
- 确认币安API可访问：`curl https://api.binance.com/api/v3/ping`

### 3. 程序崩溃

- 查看错误日志：`tail -f price_monitor.log`
- 重启程序：`pkill -f app.py && nohup python3 app.py > price_monitor.log 2>&1 &`

## 技术架构

- **后端**：Python Flask 轻量级Web框架
- **前端**：原生HTML/CSS/JavaScript，无额外依赖
- **数据源**：币安公开API
- **部署**：单文件部署，资源占用极低

## 注意事项

1. 本系统使用币安公开API，无需API密钥
2. 建议在稳定的网络环境下运行
3. 开盘价每日零点零分自动更新
4. 系统设计为轻量化，适合低配置云服务器
5. 如需更高频率更新，请注意API调用限制

## 许可证

MIT License - 可自由使用和修改