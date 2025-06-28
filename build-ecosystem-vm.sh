#!/bin/bash
# =============================================================================
# Ecosystem Application VM Image Builder - One-Click Script
# 生态系统应用虚拟机镜像一键构建脚本
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

# 配置参数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINDOWS_DIR="${SCRIPT_DIR}/windows"
OUTPUT_DIR="${SCRIPT_DIR}/output-ecosystem-vm"
LOG_FILE="${SCRIPT_DIR}/build-$(date +%Y%m%d-%H%M%S).log"

# VM配置 - 生态系统应用增强配置
VM_NAME="ecosystem-application-vm"
DISK_SIZE="512000"  # 500GB in MB
MEMORY_SIZE="16384"  # 16GB RAM for development workloads
CPU_COUNT="12"       # 12 cores for compilation and development
ISO_URL="http://localhost:10086/Windows10_enterprise_22H2_KMS.iso"
ISO_CHECKSUM="sha256:2654d20e2f7cdc5949c0dcf1271892ce97c9e5482624459ff377cb5f742b41c7"

# 检查依赖项
check_dependencies() {
    log_info "检查构建依赖项..."
    
    local deps=("packer" "qemu-system-x86_64")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖项: ${missing_deps[*]}"
        log_info "请安装："
        echo "  sudo apt install qemu-system-x86_64 qemu-utils"
        echo "  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -"
        echo "  sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com \$(lsb_release -cs) main\""
        echo "  sudo apt install packer"
        exit 1
    fi
    
    # 检查OVMF固件
    if [ ! -f "/usr/share/OVMF/OVMF_CODE_4M.fd" ]; then
        log_error "缺少OVMF UEFI固件文件"
        log_info "请安装: sudo apt install ovmf"
        exit 1
    fi
    
    log_success "所有依赖项检查通过"
}

# 检查磁盘空间
check_disk_space() {
    log_info "检查磁盘空间..."
    
    local required_space=600  # GB
    local available_space=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_error "磁盘空间不足: 需要${required_space}GB，可用${available_space}GB"
        exit 1
    fi
    
    log_success "磁盘空间充足: ${available_space}GB 可用"
}

# 备份现有配置
backup_config() {
    if [ -f "${WINDOWS_DIR}/win10_22h2.pkr.hcl" ]; then
        log_info "备份现有Packer配置..."
        cp "${WINDOWS_DIR}/win10_22h2.pkr.hcl" "${WINDOWS_DIR}/win10_22h2.pkr.hcl.backup.$(date +%Y%m%d-%H%M%S)"
        log_success "配置文件已备份"
    fi
}

# 创建增强的Packer配置
create_enhanced_config() {
    log_info "创建生态系统应用VM配置..."
    
    cat > "${WINDOWS_DIR}/ecosystem-vm.pkr.hcl" << 'EOF'
packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

# 生态系统应用VM变量配置
variable "accelerator" {
  type    = string
  default = "kvm"
}

variable "vm_name" {
  type    = string
  default = "ecosystem-application-vm"
}

variable "disk_size" {
  type    = string
  default = "512000"  # 500GB
}

variable "memory_size" {
  type    = string
  default = "16384"   # 16GB
}

variable "cpus" {
  type    = string
  default = "12"      # 12 cores
}

variable "headless" {
  type    = string
  default = "false"   # 显示构建过程便于调试
}

variable "iso_url" {
  type    = string
  default = "http://localhost:10086/Windows10_enterprise_22H2_KMS.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:2654d20e2f7cdc5949c0dcf1271892ce97c9e5482624459ff377cb5f742b41c7"
}

variable "autounattend" {
  type    = string
  default = "./answer_files/10/Autounattend.xml"
}

variable "shutdown_command" {
  type    = string
  default = "%WINDIR%/system32/sysprep/sysprep.exe /generalize /oobe /shutdown /unattend:C:/Windows/Temp/Autounattend.xml"
}

# QEMU构建源配置
source "qemu" "ecosystem_vm" {
  # 基础配置
  accelerator      = "${var.accelerator}"
  vm_name          = "${var.vm_name}"
  disk_size        = "${var.disk_size}"
  memory           = "${var.memory_size}"
  cpus             = "${var.cpus}"
  headless         = "${var.headless}"
  
  # 磁盘和网络配置
  disk_compression = true
  disk_interface   = "virtio"
  net_device       = "virtio-net"
  format           = "qcow2"
  
  # UEFI固件配置
  efi_boot         = true
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
  
  # 显示配置
  vga              = "qxl"
  vnc_bind_address = "127.0.0.1"  # 安全性：仅本地访问
  
  # ISO配置
  iso_url          = "${var.iso_url}"
  iso_checksum     = "${var.iso_checksum}"
  
  # 启动配置
  boot_wait        = "3s"
  boot_command     = ["<enter>"]
  
  # 文件传输配置
  floppy_files     = [
    "${var.autounattend}", 
    "./scripts/1-firstlogin.bat", 
    "./scripts/2-fixnetwork.ps1", 
    "./scripts/50-enable-winrm.ps1",
    "./scripts/70-install-ecosystem-apps.bat",
    "./scripts/75-install-development-tools.bat", 
    "./scripts/80-compile-dotnet-assemblies.bat",
    "./scripts/89-remove-philips-network.ps1", 
    "./scripts/90-compact.bat",
    "./answer_files/Firstboot/Firstboot-Autounattend.xml", 
    "./drivers/"
  ]
  
  # WinRM通信配置
  communicator     = "winrm"
  winrm_username   = "philips"
  winrm_password   = "philips"
  winrm_timeout    = "45m"      # 增加超时时间
  winrm_use_ssl    = true
  winrm_insecure   = true
  
  # 输出配置
  output_directory = "output-${var.vm_name}"
  shutdown_command = "${var.shutdown_command}"
}

# 构建配置
build {
  sources = ["source.qemu.ecosystem_vm"]
  
  # 第一阶段：基础软件安装
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = [
      "./scripts/70-install-ecosystem-apps.bat",
      "./scripts/75-install-development-tools.bat"
    ]
  }
  
  # 系统重启
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'System restarted successfully'}\""
    restart_timeout = "15m"
  }
  
  # 第二阶段：.NET优化
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/80-compile-dotnet-assemblies.bat"]
  }
  
  # 第三阶段：网络清理
  provisioner "powershell" {
    script            = "./scripts/89-remove-philips-network.ps1"
    elevated_user     = "philips"
    elevated_password = "philips"
  }
  
  # 第四阶段：磁盘压缩
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/90-compact.bat"]
  }
}
EOF
    
    log_success "增强配置文件已创建"
}

# 创建生态系统应用安装脚本
create_ecosystem_scripts() {
    log_info "创建生态系统应用安装脚本..."
    
    # 生态系统应用安装脚本
    cat > "${WINDOWS_DIR}/scripts/70-install-ecosystem-apps.bat" << 'EOF'
@echo off
REM =============================================================================
REM 生态系统应用软件安装脚本
REM =============================================================================

echo [INFO] 开始安装生态系统应用软件...

REM 安装QEMU Guest Agent
echo [INFO] 安装QEMU Guest Agent...
curl -O --ssl-no-revoke -L https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-qemu-ga/qemu-ga-x86_64.msi
start /wait msiexec /qb /i qemu-ga-x86_64.msi

REM 安装VirtIO驱动 (排除网络驱动避免中断WinRM连接)
echo [INFO] 安装VirtIO驱动...
curl -O --ssl-no-revoke -L https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win-gt-x64.msi
start /wait msiexec /qb /i virtio-win-gt-x64.msi ADDLOCAL=FE_balloon_driver,FE_pvpanic_driver,FE_fwcfg_driver,FE_qemupciserial_driver,FE_vioinput_driver,FE_viorng_driver,FE_vioscsi_driver,FE_vioserial_driver,FE_viostore_driver,FE_viofs_driver,FE_viogpudo_driver,FE_viomem_driver

REM 安装NVIDIA驱动
echo [INFO] 安装NVIDIA驱动...
curl -o nvidia-driver.exe --ssl-no-revoke -L https://us.download.nvidia.com/Windows/Quadro_Certified/573.06/573.06-quadro-rtx-desktop-notebook-win10-win11-64bit-international-dch-whql.exe
start /wait nvidia-driver.exe -s

REM 安装常用运行库
echo [INFO] 安装Microsoft Visual C++ 运行库...
choco install vcredist-all -y

echo [INFO] 安装.NET Framework和Core...
choco install dotnet-6.0-runtime dotnet-6.0-sdk -y
choco install dotnetcore-3.1-runtime dotnetcore-3.1-sdk -y

REM 安装Java运行环境
echo [INFO] 安装Java运行环境...
choco install openjdk17 -y

REM 安装Node.js和Python
echo [INFO] 安装Node.js和Python...
choco install nodejs python -y

REM 安装数据库客户端
echo [INFO] 安装数据库工具...
choco install mysql.workbench postgresql -y

REM 安装SDelete磁盘清理工具
echo [INFO] 安装SDelete...
choco install sdelete -y

REM 创建系统未完成标记
echo [INFO] 创建构建状态标记...
copy C:\windows\system32\cmd.exe C:\not-yet-finished

echo [SUCCESS] 生态系统应用软件安装完成！
EOF

    # 开发工具安装脚本
    cat > "${WINDOWS_DIR}/scripts/75-install-development-tools.bat" << 'EOF'
@echo off
REM =============================================================================
REM 开发工具安装脚本
REM =============================================================================

echo [INFO] 开始安装开发工具...

REM 安装Git
echo [INFO] 安装Git版本控制...
choco install git -y

REM 安装文本编辑器
echo [INFO] 安装文本编辑器...
choco install notepadplusplus vscode -y

REM 安装压缩工具
echo [INFO] 安装压缩工具...
choco install 7zip -y

REM 安装浏览器
echo [INFO] 安装浏览器...
choco install googlechrome firefox -y

REM 安装Docker Desktop
echo [INFO] 安装Docker Desktop...
choco install docker-desktop -y

REM 安装Postman API测试工具
echo [INFO] 安装Postman...
choco install postman -y

REM 安装远程桌面增强工具
echo [INFO] 安装远程访问工具...
choco install putty winscp -y

REM 安装系统监控工具
echo [INFO] 安装系统工具...
choco install procexp procmon -y

REM 配置Git全局设置
echo [INFO] 配置Git默认设置...
git config --global init.defaultBranch main
git config --global user.name "Ecosystem User"
git config --global user.email "user@ecosystem.local"

echo [SUCCESS] 开发工具安装完成！
EOF

    log_success "生态系统脚本已创建"
}

# 初始化Packer插件
init_packer() {
    log_info "初始化Packer插件..."
    cd "${WINDOWS_DIR}"
    
    if packer init ecosystem-vm.pkr.hcl; then
        log_success "Packer插件初始化完成"
    else
        log_error "Packer插件初始化失败"
        exit 1
    fi
    
    cd "${SCRIPT_DIR}"
}

# 验证构建配置
validate_config() {
    log_info "验证Packer配置..."
    cd "${WINDOWS_DIR}"
    
    if packer validate ecosystem-vm.pkr.hcl; then
        log_success "Packer配置验证通过"
    else
        log_error "Packer配置验证失败"
        exit 1
    fi
    
    cd "${SCRIPT_DIR}"
}

# 开始构建VM镜像
build_vm() {
    log_info "开始构建生态系统应用VM镜像..."
    log_info "构建配置:"
    echo "  - 虚拟机名称: ${VM_NAME}"
    echo "  - 磁盘大小: ${DISK_SIZE}MB ($(( DISK_SIZE / 1024 ))GB)"
    echo "  - 内存大小: ${MEMORY_SIZE}MB ($(( MEMORY_SIZE / 1024 ))GB)"
    echo "  - CPU核心: ${CPU_COUNT}"
    echo "  - 输出目录: ${OUTPUT_DIR}"
    
    cd "${WINDOWS_DIR}"
    
    # 开始构建并记录日志
    log_info "构建开始时间: $(date)"
    
    if packer build \
        -var "vm_name=${VM_NAME}" \
        -var "disk_size=${DISK_SIZE}" \
        -var "memory_size=${MEMORY_SIZE}" \
        -var "cpus=${CPU_COUNT}" \
        -var "iso_url=${ISO_URL}" \
        -var "iso_checksum=${ISO_CHECKSUM}" \
        ecosystem-vm.pkr.hcl 2>&1 | tee "${LOG_FILE}"; then
        
        log_success "VM镜像构建完成！"
        log_info "构建完成时间: $(date)"
        
        # 显示构建结果
        if [ -d "output-${VM_NAME}" ]; then
            log_success "输出文件位置: $(pwd)/output-${VM_NAME}/"
            log_info "镜像文件大小: $(du -h "output-${VM_NAME}/${VM_NAME}" | cut -f1)"
        fi
        
    else
        log_error "VM镜像构建失败！"
        log_error "查看日志文件: ${LOG_FILE}"
        exit 1
    fi
    
    cd "${SCRIPT_DIR}"
}

# 构建后处理
post_build() {
    log_info "执行构建后处理..."
    
    # 创建启动脚本
    cat > "${SCRIPT_DIR}/start-ecosystem-vm.sh" << EOF
#!/bin/bash
# 启动生态系统应用VM

VM_IMAGE="${WINDOWS_DIR}/output-${VM_NAME}/${VM_NAME}"

if [ ! -f "\$VM_IMAGE" ]; then
    echo "错误: VM镜像文件不存在: \$VM_IMAGE"
    exit 1
fi

echo "启动生态系统应用VM..."
qemu-system-x86_64 \\
    -enable-kvm \\
    -cpu host \\
    -smp ${CPU_COUNT} \\
    -m ${MEMORY_SIZE} \\
    -drive file="\$VM_IMAGE",format=qcow2,if=virtio \\
    -netdev user,id=net0,hostfwd=tcp::3389-:3389,hostfwd=tcp::5985-:5985 \\
    -device virtio-net,netdev=net0 \\
    -vga qxl \\
    -display gtk \\
    -usb -device usb-tablet \\
    -rtc base=localtime \\
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \\
    -drive if=pflash,format=raw,file=/usr/share/OVMF/OVMF_VARS_4M.fd
EOF
    
    chmod +x "${SCRIPT_DIR}/start-ecosystem-vm.sh"
    
    log_success "启动脚本已创建: start-ecosystem-vm.sh"
}

# 显示使用信息
show_usage() {
    log_info "生态系统应用VM构建完成！"
    echo ""
    echo "使用说明:"
    echo "1. 启动VM: ./start-ecosystem-vm.sh"
    echo "2. 默认凭据: philips/philips"
    echo "3. RDP端口: 3389 (主机端口转发)"
    echo "4. WinRM端口: 5985 (主机端口转发)"
    echo ""
    echo "已安装的软件:"
    echo "- 开发工具: Git, VS Code, Notepad++"
    echo "- 运行环境: .NET 6.0, Java 17, Node.js, Python"
    echo "- 数据库工具: MySQL Workbench, PostgreSQL"
    echo "- 容器工具: Docker Desktop"
    echo "- 浏览器: Chrome, Firefox"
    echo "- 其他工具: Postman, PuTTY, 7-Zip"
    echo ""
    echo "VM配置:"
    echo "- 磁盘: 500GB"
    echo "- 内存: 16GB"
    echo "- CPU: 12核"
}

# 主函数
main() {
    log_info "=== 生态系统应用VM镜像构建器 ==="
    log_info "开始时间: $(date)"
    
    # 执行构建步骤
    check_dependencies
    check_disk_space
    backup_config
    create_enhanced_config
    create_ecosystem_scripts
    init_packer
    validate_config
    build_vm
    post_build
    show_usage
    
    log_success "=== 构建流程全部完成！ ==="
}

# 错误处理
trap 'log_error "构建过程中发生错误，退出代码: $?"' ERR

# 执行主函数
main "$@"