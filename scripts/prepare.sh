#!/bin/bash
#
# RDP Honeypot dependency installation and environment preparation script
# This script installs all required system dependencies and Python packages
#
# 使用方法:
# chmod +x scripts/prepare.sh
# ./scripts/prepare.sh
#

set -e  # 遇到错误时退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
        elif [ -f /etc/arch-release ]; then
            OS="arch"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    log_info "检测到操作系统: $OS"
}

# 更新包管理器
update_package_manager() {
    log_step "更新包管理器..."
    case $OS in
        "debian")
            sudo apt-get update -y
            ;;
        "redhat")
            sudo yum update -y || sudo dnf update -y
            ;;
        "arch")
            sudo pacman -Sy
            ;;
        "macos")
            if ! command -v brew &> /dev/null; then
                log_info "安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew update
            ;;
        *)
            log_warn "未知操作系统，跳过包管理器更新"
            ;;
    esac
}

# 安装系统级依赖
install_system_dependencies() {
    log_step "安装系统级依赖..."
    
    case $OS in
        "debian")
            sudo apt-get install -y \
                python3 \
                python3-pip \
                python3-venv \
                python3-dev \
                build-essential \
                libssl-dev \
                libffi-dev \
                openssl \
                git \
                curl \
                wget \
                net-tools \
                tcpdump \
                sqlite3 \
                pkg-config \
                libcairo2-dev \
                libgirepository1.0-dev
            ;;
        "redhat")
            sudo yum install -y \
                python3 \
                python3-pip \
                python3-devel \
                gcc \
                gcc-c++ \
                make \
                openssl-devel \
                libffi-devel \
                openssl \
                git \
                curl \
                wget \
                net-tools \
                tcpdump \
                sqlite \
                pkgconfig \
                cairo-devel \
                gobject-introspection-devel || \
            sudo dnf install -y \
                python3 \
                python3-pip \
                python3-devel \
                gcc \
                gcc-c++ \
                make \
                openssl-devel \
                libffi-devel \
                openssl \
                git \
                curl \
                wget \
                net-tools \
                tcpdump \
                sqlite \
                pkgconf-pkg-config \
                cairo-devel \
                gobject-introspection-devel
            ;;
        "arch")
            sudo pacman -S --noconfirm \
                python \
                python-pip \
                base-devel \
                openssl \
                libffi \
                git \
                curl \
                wget \
                net-tools \
                tcpdump \
                sqlite \
                pkg-config \
                cairo \
                gobject-introspection
            ;;
        "macos")
            brew install \
                python@3.11 \
                openssl \
                libffi \
                git \
                curl \
                wget \
                sqlite \
                pkg-config \
                cairo \
                gobject-introspection
            ;;
        *)
            log_error "未支持的操作系统，请手动安装依赖"
            exit 1
            ;;
    esac
    
    log_info "系统依赖安装完成"
}

# 检查Python版本
check_python_version() {
    log_step "检查Python版本..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
        
        log_info "当前Python版本: $PYTHON_VERSION"
        
        if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 8 ]; then
            log_info "Python版本满足要求 (>= 3.8)"
            PYTHON_CMD="python3"
        else
            log_error "Python版本过低，需要Python 3.8或更高版本"
            exit 1
        fi
    else
        log_error "未找到Python3，请先安装Python"
        exit 1
    fi
}

# 创建Python虚拟环境
create_virtual_environment() {
    log_step "创建Python虚拟环境..."
    
    VENV_DIR="venv"
    
    if [ -d "$VENV_DIR" ]; then
        log_warn "虚拟环境已存在，删除并重新创建"
        rm -rf "$VENV_DIR"
    fi
    
    $PYTHON_CMD -m venv "$VENV_DIR"
    log_info "虚拟环境创建成功: $VENV_DIR"
    
    # 激活虚拟环境
    source "$VENV_DIR/bin/activate"
    log_info "虚拟环境已激活"
    
    # 升级pip
    pip install --upgrade pip setuptools wheel
    log_info "pip已升级到最新版本"
}

# Install Python dependencies
install_python_dependencies() {
    log_step "Install Python dependencies包..."
    
    # 确保在虚拟环境中
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        log_error "请先激活虚拟环境"
        exit 1
    fi
    
    # 安装基础依赖
    log_info "安装基础依赖..."
    pip install --upgrade \
        cryptography \
        pyOpenSSL \
        twisted \
        pyasn1 \
        pyasn1-modules \
        service-identity
    
    # 安装RDP相关依赖
    log_info "安装RDP相关依赖..."
    pip install --upgrade \
        pyrdp \
        scapy \
        construct
    
    # 安装Web和数据库相关
    log_info "安装Web和数据库相关依赖..."
    pip install --upgrade \
        flask \
        requests \
        sqlite3-to-mysql || true  # 可选依赖
    
    # 安装开发和测试工具
    log_info "安装开发工具..."
    pip install --upgrade \
        pytest \
        pytest-asyncio \
        black \
        flake8 \
        mypy \
        ipython
    
    # 从requirements.txt安装（如果存在其他依赖）
    if [ -f "requirements.txt" ]; then
        log_info "从requirements.txt安装额外依赖..."
        pip install -r requirements.txt
    fi
    
    log_info "Python依赖安装完成"
}

# 生成SSL证书
generate_ssl_certificates() {
    log_step "生成SSL证书..."
    
    CERT_FILE="server.crt"
    KEY_FILE="server.key"
    
    if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
        log_warn "SSL证书已存在，跳过生成"
        return 0
    fi
    
    log_info "生成自签名SSL证书..."
    
    # 生成私钥
    openssl genrsa -out "$KEY_FILE" 2048
    
    # 生成证书
    openssl req -new -x509 -key "$KEY_FILE" -out "$CERT_FILE" -days 365 -subj "/C=CN/ST=State/L=City/O=RDP-Honeypot/CN=localhost"
    
    # 设置适当的权限
    chmod 600 "$KEY_FILE"
    chmod 644 "$CERT_FILE"
    
    log_info "SSL证书生成完成: $CERT_FILE, $KEY_FILE"
}

# Create necessary directories
create_directories() {
    log_step "Create necessary directories..."
    
    DIRECTORIES=("logs" "data" "build" "__pycache__")
    
    for dir in "${DIRECTORIES[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "创建目录: $dir"
        fi
    done
}

# 设置权限
set_permissions() {
    log_step "设置文件权限..."
    
    # 给脚本文件执行权限
    find . -name "*.sh" -type f -exec chmod +x {} \;
    
    # 给Python主程序执行权限
    if [ -f "runner.py" ]; then
        chmod +x runner.py
    fi
    
    if [ -d "scripts" ]; then
        chmod +x scripts/*.sh 2>/dev/null || true
    fi
    
    log_info "权限Setup complete"
}

# 验证安装
verify_installation() {
    log_step "验证安装..."
    
    # 检查Python包
    REQUIRED_PACKAGES=("cryptography" "twisted" "pyOpenSSL" "pyrdp")
    
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if pip show "$package" &> /dev/null; then
            VERSION=$(pip show "$package" | grep Version | cut -d' ' -f2)
            log_info "✓ $package ($VERSION)"
        else
            log_error "✗ $package 未安装"
            exit 1
        fi
    done
    
    # 检查SSL证书
    if [ -f "server.crt" ] && [ -f "server.key" ]; then
        log_info "✓ SSL证书存在"
    else
        log_error "✗ SSL证书缺失"
        exit 1
    fi
    
    # 检查Python语法
    if [ -f "runner.py" ]; then
        if python3 -m py_compile runner.py; then
            log_info "✓ runner.py 语法检查通过"
        else
            log_error "✗ runner.py 语法错误"
            exit 1
        fi
    fi
    
    log_info "安装验证完成"
}

# 显示使用说明
show_usage() {
    log_step "显示使用说明..."
    
    echo ""
    echo "=========================================="
    echo "RDP Honeypot 安装完成！"
    echo "=========================================="
    echo ""
    echo "启动服务:"
    echo "  source venv/bin/activate"
    echo "  python runner.py --rdp-port 3101 --http-port 8080"
    echo ""
    echo "测试连接:"
    echo "  python test_rdp_client.py"
    echo ""
    echo "查看日志:"
    echo "  tail -f server.log"
    echo "  tail -f logs/*.log"
    echo ""
    echo "健康检查:"
    echo "  curl http://localhost:8080/"
    echo ""
    echo "配置文件:"
    echo "  config.py - 主要配置"
    echo "  requirements.txt - Python依赖"
    echo ""
    echo "=========================================="
}

# 主函数
main() {
    log_info "开始RDP Honeypot环境准备..."
    echo ""
    
    # 检查是否为root用户（部分操作需要sudo）
    if [[ $EUID -eq 0 ]]; then
        log_warn "检测到root用户，建议使用普通用户运行此脚本"
    fi
    
    # 确保在正确的目录
    if [ ! -f "requirements.txt" ]; then
        log_error "请在rdp-server项目根目录下运行此脚本"
        exit 1
    fi
    
    # 执行安装步骤
    detect_os
    update_package_manager
    install_system_dependencies
    check_python_version
    create_virtual_environment
    install_python_dependencies
    generate_ssl_certificates
    create_directories
    set_permissions
    verify_installation
    show_usage
    
    log_info "环境准备完成！"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
