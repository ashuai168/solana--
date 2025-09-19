#!/bin/bash

# ===============================================
# Solana 靓号地址生成器 - 自动启动脚本
# ===============================================

set -e

echo "========================================="
echo "🚀 Solana 靓号地址生成器"
echo "========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数：彩色输出
print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

# 函数：检查命令是否存在
check_command() {
    if command -v $1 &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 函数：检查Python依赖
check_python_deps() {
    python3 -c "import flask, flask_cors" 2>/dev/null
}

# 函数：安装Python依赖
install_python_deps() {
    print_info "正在安装Python依赖 (flask, flask-cors)..."
    if pip3 install flask flask-cors; then
        print_status "Python依赖安装成功"
        return 0
    else
        print_error "Python依赖安装失败"
        return 1
    fi
}

# 函数：检查并安装Rust
install_rust() {
    print_info "正在安装Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    print_status "Rust安装完成"
}

# 函数：编译Rust项目
build_rust_project() {
    print_info "正在编译Rust项目..."
    if cargo build --release; then
        print_status "Rust项目编译成功"
        return 0
    else
        print_error "Rust项目编译失败"
        return 1
    fi
}

echo "🔍 正在检查系统依赖..."
echo ""

# 检查Python3
if check_command python3; then
    print_status "Python3 已安装"
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo "   版本: $PYTHON_VERSION"
else
    print_error "Python3 未安装"
    print_info "请安装Python3 (建议版本3.8+):"
    print_info "  macOS: brew install python3"
    print_info "  Ubuntu: sudo apt install python3 python3-pip"
    print_info "  CentOS: sudo yum install python3 python3-pip"
    exit 1
fi

# 检查pip3
if check_command pip3; then
    print_status "pip3 已安装"
else
    print_error "pip3 未安装，请安装pip3"
    exit 1
fi

# 检查Python依赖
echo ""
print_info "检查Python依赖..."
if check_python_deps; then
    print_status "Python依赖 (flask, flask-cors) 已安装"
else
    print_warning "Python依赖未安装，正在自动安装..."
    if ! install_python_deps; then
        print_error "无法安装Python依赖，请手动运行: pip3 install flask flask-cors"
        exit 1
    fi
fi

# 检查Rust
echo ""
print_info "检查Rust环境..."
if check_command rustc && check_command cargo; then
    print_status "Rust 已安装"
    RUST_VERSION=$(rustc --version 2>&1)
    echo "   版本: $RUST_VERSION"
else
    print_warning "Rust 未安装，正在自动安装..."
    if ! install_rust; then
        print_error "Rust安装失败，请手动安装: https://rustup.rs/"
        exit 1
    fi
    # 重新加载环境变量
    source ~/.cargo/env
fi

# 检查Rust二进制文件
echo ""
print_info "检查Rust编译产物..."
if [ -f "target/release/solana-generator" ]; then
    print_status "Rust二进制文件已存在"
    BINARY_SIZE=$(ls -lh target/release/solana-generator | awk '{print $5}')
    echo "   文件大小: $BINARY_SIZE"
else
    print_warning "Rust二进制文件不存在，正在编译项目..."
    if ! build_rust_project; then
        print_error "编译失败，请检查Rust环境"
        exit 1
    fi
fi

echo ""
echo "========================================="
echo "🎉 所有依赖检查完成！"
echo "========================================="
echo ""

print_info "正在启动Web服务器..."
echo ""

# 启动 Python Flask 服务器
python3 server.py &
SERVER_PID=$!

# 等待服务器启动
sleep 2

print_status "服务器启动成功，进程ID: $SERVER_PID"
echo ""
echo "========================================="
echo "📱 请在浏览器中打开:"
echo -e "   ${BLUE}http://localhost:8080${NC}"
echo "========================================="
echo ""

# 自动打开浏览器
if check_command open; then
    print_info "正在自动打开浏览器..."
    sleep 1
    open "http://localhost:8080" &> /dev/null && print_status "浏览器已自动打开"
elif check_command xdg-open; then
    print_info "正在自动打开浏览器..."
    sleep 1
    xdg-open "http://localhost:8080" &> /dev/null && print_status "浏览器已自动打开"
else
    print_warning "无法自动打开浏览器，请手动打开上述地址"
fi

echo ""
echo "💡 使用说明:"
echo "   - 在网页中输入想要的地址前缀或后缀"
echo "   - 点击生成按钮开始搜索"
echo "   - 找到地址后立即保存私钥"
echo ""
echo "⚡ 性能提示:"
echo "   - 短模式 (1-3字符): 几秒钟"
echo "   - 中等模式 (4字符): 10-30秒"
echo "   - 长模式 (5+字符): 几分钟"
echo ""
echo "⚠️  重要提醒:"
echo "   - 私钥只显示一次，请立即保存"
echo "   - 建议先用短模式测试"
echo "   - 前缀+后缀难度会大大增加"
echo ""
echo -e "${RED}🛑 按 Ctrl+C 停止服务器${NC}"
echo ""

# 等待和处理关闭信号
trap "echo ''; echo '🛑 正在关闭服务器...'; kill $SERVER_PID 2>/dev/null; echo '✅ 服务器已关闭'; echo '💫 感谢使用！'; exit" INT TERM

# 保持脚本运行
wait $SERVER_PID