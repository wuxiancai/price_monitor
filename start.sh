#!/bin/bash

# 币安币价监控系统启动脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_FILE="$SCRIPT_DIR/app.py"
LOG_FILE="$SCRIPT_DIR/price_monitor.log"
PID_FILE="$SCRIPT_DIR/price_monitor.pid"

function start_service() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "服务已在运行中 (PID: $PID)"
            return 1
        else
            rm -f "$PID_FILE"
        fi
    fi
    
    echo "正在启动币价监控服务..."
    cd "$SCRIPT_DIR"
    
    # 检查虚拟环境是否存在
    if [ -d "$SCRIPT_DIR/venv" ]; then
        echo "使用虚拟环境启动..."
        nohup "$SCRIPT_DIR/venv/bin/python" "$APP_FILE" > "$LOG_FILE" 2>&1 &
    else
        echo "使用系统Python启动..."
        nohup python3 "$APP_FILE" > "$LOG_FILE" 2>&1 &
    fi
    echo $! > "$PID_FILE"
    
    sleep 2
    if ps -p $(cat "$PID_FILE") > /dev/null 2>&1; then
        echo "✅ 服务启动成功！"
        echo "📊 访问地址: http://$(hostname -I | awk '{print $1}'):8888"
        echo "📝 日志文件: $LOG_FILE"
        echo "🔧 进程ID: $(cat "$PID_FILE")"
    else
        echo "❌ 服务启动失败，请检查日志文件: $LOG_FILE"
        rm -f "$PID_FILE"
        return 1
    fi
}

function stop_service() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "正在停止服务 (PID: $PID)..."
            kill $PID
            sleep 2
            if ps -p $PID > /dev/null 2>&1; then
                echo "强制停止服务..."
                kill -9 $PID
            fi
            rm -f "$PID_FILE"
            echo "✅ 服务已停止"
        else
            echo "服务未运行"
            rm -f "$PID_FILE"
        fi
    else
        echo "服务未运行"
    fi
}

function restart_service() {
    stop_service
    sleep 1
    start_service
}

function status_service() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "✅ 服务正在运行 (PID: $PID)"
            echo "📊 访问地址: http://$(hostname -I | awk '{print $1}'):8888"
            echo "📝 日志文件: $LOG_FILE"
            echo "💾 内存使用: $(ps -p $PID -o rss= | awk '{print $1/1024 " MB"}')"
        else
            echo "❌ 服务未运行（PID文件存在但进程不存在）"
            rm -f "$PID_FILE"
        fi
    else
        echo "❌ 服务未运行"
    fi
}

function show_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo "📝 显示最近50行日志:"
        echo "----------------------------------------"
        tail -n 50 "$LOG_FILE"
    else
        echo "日志文件不存在: $LOG_FILE"
    fi
}

function install_deps() {
    echo "正在安装Python依赖..."
    cd "$SCRIPT_DIR"
    
    # 创建虚拟环境（如果不存在）
    if [ ! -d "venv" ]; then
        echo "创建Python虚拟环境..."
        python3 -m venv venv
        if [ $? -ne 0 ]; then
            echo "❌ 创建虚拟环境失败，请确保已安装python3-venv"
            echo "运行: sudo apt install python3-venv -y"
            return 1
        fi
    fi
    
    # 激活虚拟环境并安装依赖
    echo "激活虚拟环境并安装依赖..."
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    
    if [ $? -eq 0 ]; then
        echo "✅ 依赖安装完成"
    else
        echo "❌ 依赖安装失败"
        return 1
    fi
}

function show_help() {
    echo "币安币价监控系统管理脚本"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  start     启动服务"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  status    查看服务状态"
    echo "  logs      查看日志"
    echo "  install   安装Python依赖"
    echo "  help      显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 start    # 启动服务"
    echo "  $0 status   # 查看状态"
    echo "  $0 logs     # 查看日志"
}

# 主程序
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        status_service
        ;;
    logs)
        show_logs
        ;;
    install)
        install_deps
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        echo "请指定命令，使用 '$0 help' 查看帮助"
        ;;
    *)
        echo "未知命令: $1"
        echo "使用 '$0 help' 查看帮助"
        exit 1
        ;;
esac