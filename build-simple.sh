#!/bin/bash
# 简化版VM构建脚本 - 只构建基础Windows 10系统

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINDOWS_DIR="${SCRIPT_DIR}/windows"
LOG_FILE="${SCRIPT_DIR}/build-simple-$(date +%Y%m%d-%H%M%S).log"

# VM配置 - 40GB磁盘
VM_NAME="windows_10"
DISK_SIZE="40960"     # 40GB
MEMORY_SIZE="16384"   # 16GB
CPU_COUNT="10"        # 10核
HEADLESS="false"

# 本地ISO配置
LOCAL_ISO_PATH="./downloads/Win10_22H2_x64.iso"
ISO_CHECKSUM="sha256:8eb1743d1057791949b2bdc78390e48828a2be92780402daccd1a57326d70709"

# 用户凭据
ADMIN_USER="philips"
ADMIN_PASS="philips"
NORMAL_USER="user"
NORMAL_PASS="vmuser123"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1" | tee -a "$LOG_FILE"
}

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    echo "============================================================================="
    echo "        简化版Windows 10 VM构建器"
    echo "============================================================================="
    echo -e "${NC}"
    echo "ISO文件: $(basename "$LOCAL_ISO_PATH")"
    echo "磁盘大小: 40GB"
    echo "内存配置: 16GB"
    echo "CPU配置: 10核"
    echo "构建时间: $(date)"
    echo ""
}

# 检查ISO文件
verify_iso() {
    log_step "步骤1: 验证ISO文件"
    
    if [ ! -f "$LOCAL_ISO_PATH" ]; then
        log_error "找不到ISO文件: $LOCAL_ISO_PATH"
        exit 1
    fi
    
    local iso_size=$(du -h "$LOCAL_ISO_PATH" | cut -f1)
    log_success "ISO文件验证通过: $iso_size"
}

# 创建简化的Packer配置
create_simple_config() {
    log_step "步骤2: 创建简化Packer配置"
    
    mkdir -p "$WINDOWS_DIR"
    local abs_iso_path=$(realpath "$LOCAL_ISO_PATH")
    
    cat > "${WINDOWS_DIR}/win10-simple.pkr.hcl" << EOF
packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

source "qemu" "win10_simple" {
  accelerator      = "kvm"
  boot_wait        = "3s"
  boot_command     = ["<enter>"]
  communicator     = "winrm"
  cpus             = "$CPU_COUNT"
  disk_compression = true
  disk_interface   = "virtio"
  disk_size        = "$DISK_SIZE"
  floppy_files     = [
    "./answer_files/10/Autounattend.xml",
    "./scripts/1-firstlogin.bat",
    "./scripts/2-fixnetwork.ps1",
    "./scripts/50-enable-winrm.ps1",
    "./scripts/simple-setup.bat",
    "./answer_files/Firstboot/Firstboot-Autounattend.xml",
    "./drivers/"
  ]
  format           = "qcow2"
  headless         = $HEADLESS
  iso_checksum     = "$ISO_CHECKSUM"
  iso_url          = "file://$abs_iso_path"
  memory           = "$MEMORY_SIZE"
  net_device       = "virtio-net"
  vnc_bind_address = "127.0.0.1"
  vga              = "qxl"
  efi_boot         = true
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
  shutdown_command = "%WINDIR%/system32/sysprep/sysprep.exe /generalize /oobe /shutdown /unattend:C:/Windows/Temp/Autounattend.xml"
  winrm_insecure   = true
  winrm_password   = "$ADMIN_PASS"
  winrm_timeout    = "30m"
  winrm_use_ssl    = true
  winrm_username   = "$ADMIN_USER"
  output_directory = "output-$VM_NAME"
}

build {
  sources = ["source.qemu.win10_simple"]

  # 只执行基础设置
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/simple-setup.bat"]
  }

  # 系统重启
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
    restart_timeout = "15m"
  }

  # 磁盘清理
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/90-compact.bat"]
  }
}
EOF
    
    log_success "简化配置文件创建完成"
}

# 创建简化安装脚本
create_simple_script() {
    log_step "步骤3: 创建简化安装脚本"
    
    mkdir -p "${WINDOWS_DIR}/scripts"
    
    cat > "${WINDOWS_DIR}/scripts/simple-setup.bat" << 'EOF'
@echo off
echo [INFO] 开始基础系统配置...

REM 创建用户账户
echo [INFO] 创建管理员账户 philips...
net user philips philips /add /comment:"系统管理员" 2>nul || echo [INFO] 用户 philips 已存在
net localgroup "Administrators" philips /add 2>nul || echo [INFO] philips 已在管理员组

echo [INFO] 创建普通用户账户 user...
net user user vmuser123 /add /comment:"普通用户"
net localgroup "Users" user /add

REM 基础系统配置
echo [INFO] 配置系统设置...
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

REM 禁用一些服务以提高性能
echo [INFO] 优化系统服务...
sc config "Themes" start= disabled
sc config "Spooler" start= demand

echo [SUCCESS] 基础系统配置完成！
EOF
    
    log_success "简化脚本创建完成"
}

# 运行构建
run_simple_build() {
    log_step "步骤4: 运行简化构建"
    
    cd "$WINDOWS_DIR"
    
    # 初始化Packer
    log_info "初始化Packer插件..."
    packer init win10-simple.pkr.hcl
    
    # 验证配置
    log_info "验证配置..."
    packer validate win10-simple.pkr.hcl
    
    # 开始构建
    log_info "开始简化构建..."
    log_info "构建开始时间: $(date)"
    
    if packer build win10-simple.pkr.hcl 2>&1 | tee -a "$LOG_FILE"; then
        log_success "简化VM构建完成！"
    else
        log_error "简化VM构建失败！"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
}

# 创建启动脚本
create_startup_script() {
    log_step "步骤5: 创建VM启动脚本"
    
    local output_dir="${WINDOWS_DIR}/output-${VM_NAME}"
    local vm_image="${output_dir}/${VM_NAME}"
    
    cat > "${SCRIPT_DIR}/start-simple-vm.sh" << EOF
#!/bin/bash
# 启动简化版Windows 10 VM

VM_IMAGE="$vm_image"
OUTPUT_DIR="$output_dir"

if [ ! -f "\$VM_IMAGE" ]; then
    echo "错误: 找不到VM镜像文件: \$VM_IMAGE"
    exit 1
fi

echo "启动简化版Windows 10 VM..."
echo "配置: 16GB内存, 10核CPU, 40GB磁盘"
echo ""

qemu-system-x86_64 \\
    -machine type=q35,accel=kvm \\
    -cpu host \\
    -smp $CPU_COUNT \\
    -m $MEMORY_SIZE \\
    -drive file="\$VM_IMAGE",if=virtio,format=qcow2 \\
    -netdev user,id=net0,hostfwd=tcp::3389-:3389,hostfwd=tcp::5985-:5985 \\
    -device virtio-net-pci,netdev=net0 \\
    -vga qxl \\
    -display gtk \\
    -usb -device usb-tablet \\
    -rtc base=localtime \\
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \\
    -drive if=pflash,format=raw,file=\${OUTPUT_DIR}/efivars.fd

echo "虚拟机已关闭"
EOF

    chmod +x "${SCRIPT_DIR}/start-simple-vm.sh"
    log_success "启动脚本创建完成"
}

# 显示完成信息
show_completion() {
    echo ""
    log_success "============================================================================="
    log_success "                    简化版Windows 10 VM构建完成！"
    log_success "============================================================================="
    echo ""
    
    echo "VM配置:"
    echo "  磁盘大小: 40GB"
    echo "  内存大小: 16GB"
    echo "  CPU核心: 10个"
    echo ""
    
    echo "用户账户:"
    echo "  管理员: philips / philips"
    echo "  普通用户: user / vmuser123"
    echo ""
    
    echo "启动方式:"
    echo "  ./start-simple-vm.sh"
    echo ""
}

# 主函数
main() {
    show_banner
    verify_iso
    create_simple_config
    create_simple_script
    run_simple_build
    create_startup_script
    show_completion
    
    log_success "简化版VM构建流程完成！"
}

# 执行主函数
main "$@"