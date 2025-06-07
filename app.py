#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import websocket
from datetime import datetime, timezone
from flask import Flask, render_template, jsonify
import threading
import time
import schedule
import ssl

app = Flask(__name__)

# 8个币种配置
COINS = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'XRPUSDT', 'DOGEUSDT', 'BNBUSDT', 'ADAUSDT', 'TRXUSDT']
COIN_NAMES = {'BTCUSDT': 'BTC', 'ETHUSDT': 'ETH', 'SOLUSDT': 'SOL', 'XRPUSDT': 'XRP', 
              'DOGEUSDT': 'DOGE', 'BNBUSDT': 'BNB', 'ADAUSDT': 'ADA', 'TRXUSDT': 'TRX'}

# 存储价格数据
price_data = {}
open_prices = {}  # 存储开盘价（零点零分价格）

# WebSocket连接和价格数据存储
ws = None
real_time_prices = {}

def on_message(ws, message):
    """WebSocket消息处理"""
    try:
        data = json.loads(message)
        if 'stream' in data and 'data' in data:
            stream_data = data['data']
            symbol = stream_data['s']
            price = float(stream_data['c'])
            real_time_prices[symbol] = price
            # print(f"更新价格: {symbol} = {price}")
    except Exception as e:
        print(f"处理WebSocket消息失败: {e}")

def on_error(ws, error):
    """WebSocket错误处理"""
    print(f"WebSocket错误: {error}")

def on_close(ws, close_status_code, close_msg):
    """WebSocket关闭处理"""
    print("WebSocket连接已关闭，5秒后重新连接...")
    time.sleep(5)

def on_open(ws):
    """WebSocket连接打开"""
    print("WebSocket连接已建立")
    streams = [f"{coin.lower()}@ticker" for coin in COINS]
    print(f"已订阅价格推送: {streams}")

def connect_websocket():
    """连接WebSocket"""
    global ws
    while True:
        try:
            print("正在连接WebSocket...")
            websocket.enableTrace(False)
            # 使用多流订阅的正确URL格式
            streams = [f"{coin.lower()}@ticker" for coin in COINS]
            stream_names = '/'.join(streams)
            ws_url = f"wss://stream.binance.com:9443/stream?streams={stream_names}"
            ws = websocket.WebSocketApp(ws_url,
                                        on_open=on_open,
                                        on_message=on_message,
                                        on_error=on_error,
                                        on_close=on_close)
            ws.run_forever(sslopt={"cert_reqs": ssl.CERT_NONE})
        except Exception as e:
            print(f"WebSocket连接异常: {e}")
            print("5秒后重新连接...")
            time.sleep(5)

def get_binance_price(symbol):
    """从WebSocket缓存获取实时价格"""
    return real_time_prices.get(symbol)

def update_open_prices():
    """更新开盘价（每天零点零分执行）"""
    print("更新开盘价...")
    for symbol in COINS:
        price = get_binance_price(symbol)
        if price:
            open_prices[symbol] = price
            print(f"{symbol} 开盘价: {price}")
        else:
            print(f"无法获取{symbol}的开盘价")

def update_real_time_prices():
    """更新实时价格"""
    for symbol in COINS:
        current_price = get_binance_price(symbol)
        if current_price:
            open_price = open_prices.get(symbol, current_price)
            
            # 计算涨跌百分比
            if open_price > 0:
                change_percent = ((current_price - open_price) / open_price) * 100
            else:
                change_percent = 0
            
            price_data[symbol] = {
                'name': COIN_NAMES[symbol],
                'open_price': open_price,
                'current_price': current_price,
                'change_percent': round(change_percent, 3),
                'is_up': change_percent >= 0
            }

def price_update_worker():
    """价格更新工作线程"""
    try:
        # 启动WebSocket连接线程
        ws_thread = threading.Thread(target=connect_websocket, daemon=True)
        ws_thread.start()
        
        # 等待WebSocket连接建立并获取初始数据
        time.sleep(3)
        
        # 启动时先获取一次开盘价
        update_open_prices()
        
        # 设置定时任务：每天零点零分更新开盘价
        schedule.every().day.at("00:00").do(update_open_prices)
        
        while True:
            try:
                # 检查定时任务
                schedule.run_pending()
                
                # 更新实时价格（每1秒更新一次）
                update_real_time_prices()
                time.sleep(1)
            except Exception as e:
                print(f"价格更新异常: {e}")
                time.sleep(5)
    except Exception as e:
        print(f"价格更新工作线程异常: {e}")

@app.route('/')
def index():
    """主页面"""
    return render_template('index.html')

@app.route('/api/prices')
def get_prices():
    """获取价格数据API"""
    return jsonify(price_data)

if __name__ == '__main__':
    # 启动价格更新线程
    price_thread = threading.Thread(target=price_update_worker, daemon=True)
    price_thread.start()
    
    # 启动Flask应用
    app.run(host='0.0.0.0', port=8888, debug=False)