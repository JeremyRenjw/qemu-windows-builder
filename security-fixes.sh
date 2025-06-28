#!/usr/bin/env bash
# =============================================================================
# 安全修复脚本 - 修复关键安全问题
# Security Fixes Script - Fix Critical Security Issues
# =============================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示横幅
show_banner() {
    echo -e "${BLUE}"
    echo "============================================================================="
    echo "                    VM镜像构建项目 - 安全修复脚本"
    echo "============================================================================="
    echo -e "${NC}"
    echo "此脚本将修复已识别的关键安全问题"
    echo "修复时间: $(date)"
    echo ""
}

# 创建环境变量模板
create_env_template() {
    log_info "创建环境变量模板..."
    
    cat > .env.template << 'EOF'
# VM镜像构建 - 环境变量配置
# 请复制此文件为 .env 并设置实际值

# 管理员账户配置
ADMIN_USER=philips
ADMIN_PASS=<请设置强密码>

# 普通用户账户配置  
NORMAL_USER=user
NORMAL_PASS=<请设置强密码>

# 构建配置
VM_NAME=windows_10
DISK_SIZE=512000
MEMORY_SIZE=16384
CPU_COUNT=12

# ISO文件配置
LOCAL_ISO_PATH=./downloads/Win10_22H2_x64.iso
ISO_CHECKSUM=sha256:8eb1743d1057791949b2bdc78390e48828a2be92780402daccd1a57326d70709

# 安全配置
ENABLE_BASIC_AUTH=false
FORCE_SSL=true
WINRM_TIMEOUT=30m
EOF

    log_success "环境变量模板已创建: .env.template"
}

# 创建密码生成函数
create_password_generator() {
    log_info "创建密码生成工具..."
    
    cat > generate-passwords.sh << 'EOF'
#!/usr/bin/env bash
# 密码生成工具

generate_password() {
    local length=${1:-16}
    openssl rand -base64 $((length * 3 / 4)) | tr -d "=+/" | cut -c1-${length}
}

echo "生成强密码..."
echo "管理员密码: $(generate_password 16)"
echo "普通用户密码: $(generate_password 12)"
echo ""
echo "请将这些密码保存到 .env 文件中"
EOF

    chmod +x generate-passwords.sh
    log_success "密码生成工具已创建: generate-passwords.sh"
}

# 修复脚本权限
fix_script_permissions() {
    log_info "修复脚本文件权限..."
    
    # 设置shell脚本权限
    find . -name "*.sh" -type f -exec chmod 755 {} \;
    
    # 设置Python脚本权限
    find . -name "*.py" -type f -exec chmod 755 {} \;
    
    # 确保Windows脚本有正确权限
    find windows/scripts -name "*.bat" -type f -exec chmod 644 {} \;
    find windows/scripts -name "*.ps1" -type f -exec chmod 644 {} \;
    
    log_success "脚本权限已修复"
}

# 创建安全的WinRM配置脚本
create_secure_winrm_config() {
    log_info "创建安全的WinRM配置..."
    
    cat > windows/scripts/51-secure-winrm.ps1 << 'EOF'
#Requires -Version 3.0
# 安全的WinRM配置脚本

# 禁用基本认证
Write-Output "禁用WinRM基本认证..."
Set-Item -Path "WSMan:\localhost\Service\Auth\Basic" -Value $false

# 禁用未加密连接
Write-Output "禁用WinRM未加密连接..."
Set-Item -Path "WSMan:\localhost\Service\AllowUnencrypted" -Value $false

# 设置最大并发连接数
Write-Output "设置WinRM安全参数..."
Set-Item -Path "WSMan:\localhost\Service\MaxConcurrentOperationsPerUser" -Value 5
Set-Item -Path "WSMan:\localhost\Service\MaxConnections" -Value 25

# 配置防火墙规则 - 仅允许本地连接
Write-Output "配置防火墙规则..."
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new remoteip=127.0.0.1
netsh advfirewall firewall set rule name="Allow WinRM HTTPS" new remoteip=127.0.0.1

Write-Output "WinRM安全配置完成"
EOF

    log_success "安全WinRM配置已创建: windows/scripts/51-secure-winrm.ps1"
}

# 创建文件完整性验证脚本
create_integrity_verification() {
    log_info "创建文件完整性验证脚本..."
    
    cat > verify-downloads.sh << 'EOF'
#!/usr/bin/env bash
# 文件完整性验证脚本

verify_file() {
    local file_path="$1"
    local expected_hash="$2"
    local hash_type="${3:-sha256}"
    
    if [ ! -f "$file_path" ]; then
        echo "错误: 文件不存在 - $file_path"
        return 1
    fi
    
    echo "验证文件: $(basename "$file_path")"
    
    local actual_hash
    case "$hash_type" in
        sha256)
            actual_hash=$(shasum -a 256 "$file_path" | cut -d' ' -f1)
            ;;
        sha1)
            actual_hash=$(shasum -a 1 "$file_path" | cut -d' ' -f1)
            ;;
        md5)
            actual_hash=$(md5sum "$file_path" | cut -d' ' -f1)
            ;;
        *)
            echo "错误: 不支持的哈希类型 - $hash_type"
            return 1
            ;;
    esac
    
    if [ "$actual_hash" = "$expected_hash" ]; then
        echo "✅ 文件完整性验证通过"
        return 0
    else
        echo "❌ 文件完整性验证失败"
        echo "   预期: $expected_hash"
        echo "   实际: $actual_hash"
        return 1
    fi
}

# 验证ISO文件
if [ -f "./downloads/Win10_22H2_x64.iso" ]; then
    verify_file "./downloads/Win10_22H2_x64.iso" "8eb1743d1057791949b2bdc78390e48828a2be92780402daccd1a57326d70709" "sha256"
else
    echo "警告: ISO文件不存在，跳过验证"
fi
EOF

    chmod +x verify-downloads.sh
    log_success "文件完整性验证脚本已创建: verify-downloads.sh"
}

# 创建安全检查脚本
create_security_checker() {
    log_info "创建安全检查脚本..."
    
    cat > security-check.sh << 'EOF'
#!/usr/bin/env bash
# 安全检查脚本

echo "🔒 执行安全检查..."

# 检查硬编码密码
echo "检查硬编码密码..."
if grep -r "philips" --include="*.sh" --include="*.hcl" . | grep -v ".env" | grep -v "security-check.sh"; then
    echo "❌ 发现硬编码密码"
else
    echo "✅ 未发现硬编码密码"
fi

# 检查文件权限
echo "检查文件权限..."
find . -name "*.sh" -not -perm 755 | while read file; do
    echo "❌ 权限错误: $file"
done

# 检查环境变量配置
echo "检查环境变量配置..."
if [ -f ".env" ]; then
    echo "✅ 环境变量文件存在"
else
    echo "⚠️ 环境变量文件不存在，请创建 .env 文件"
fi

echo "安全检查完成"
EOF

    chmod +x security-check.sh
    log_success "安全检查脚本已创建: security-check.sh"
}

# 备份原始文件
backup_original_files() {
    log_info "备份原始配置文件..."
    
    local backup_dir="backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份关键配置文件
    if [ -f "windows/win10_22h2.pkr.hcl" ]; then
        cp "windows/win10_22h2.pkr.hcl" "$backup_dir/"
    fi
    
    if [ -f "build-with-local-iso.sh" ]; then
        cp "build-with-local-iso.sh" "$backup_dir/"
    fi
    
    log_success "原始文件已备份到: $backup_dir"
}

# 主函数
main() {
    show_banner
    
    # 检查是否为root用户
    if [ "$EUID" -eq 0 ]; then
        log_warning "建议不要以root用户运行此脚本"
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    log_info "开始安全修复..."
    
    # 执行修复步骤
    backup_original_files
    create_env_template
    create_password_generator
    fix_script_permissions
    create_secure_winrm_config
    create_integrity_verification
    create_security_checker
    
    log_success "安全修复完成！"
    echo ""
    echo "下一步操作："
    echo "1. 运行 ./generate-passwords.sh 生成强密码"
    echo "2. 复制 .env.template 为 .env 并设置密码"
    echo "3. 运行 ./security-check.sh 验证修复结果"
    echo "4. 运行 ./verify-downloads.sh 验证文件完整性"
    echo ""
    echo "修复完成后，请重新测试构建流程"
}

# 执行主函数
main "$@"
