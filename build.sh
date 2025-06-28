#!/usr/bin/env bash
# =============================================================================
# 生态系统应用VM镜像构建脚本 - 使用本地ISO文件
# Build Ecosystem Application VM Image - Using Local ISO
# =============================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINDOWS_DIR="${SCRIPT_DIR}/windows"
LOG_FILE="${SCRIPT_DIR}/build-$(date +%Y%m%d-%H%M%S).log"

# VM配置 - 40GB磁盘配置（输出目录改为windows_10）
VM_NAME="windows_10"
DISK_SIZE="40960"     # 40GB
MEMORY_SIZE="16384"   # 16GB
CPU_COUNT="12"        # 12核
HEADLESS="false"      # 显示构建过程

# 本地ISO配置 - 使用已下载的ISO文件
LOCAL_ISO_PATH="./downloads/Win10_22H2_x64.iso"
ISO_CHECKSUM="sha256:8eb1743d1057791949b2bdc78390e48828a2be92780402daccd1a57326d70709"

# 用户凭据配置
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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
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
    echo "        生态系统应用VM镜像构建器 - 本地ISO版本"
    echo "============================================================================="
    echo -e "${NC}"
    echo "ISO文件: $(basename "$LOCAL_ISO_PATH")"
    echo "磁盘大小: 40GB"
    echo "内存配置: 16GB"
    echo "CPU配置: 12核"
    echo "构建时间: $(date)"
    echo ""
}

# 检查本地ISO文件
verify_local_iso() {
    log_step "步骤2: 验证本地ISO文件"
    
    if [ ! -f "$LOCAL_ISO_PATH" ]; then
        log_error "找不到ISO文件: $LOCAL_ISO_PATH"
        log_error "请确保ISO文件存在于指定位置"
        exit 1
    fi
    
    local iso_size=$(du -h "$LOCAL_ISO_PATH" | cut -f1)
    log_info "ISO文件大小: $iso_size"
    
    # 验证校验和
    log_info "验证ISO文件完整性..."
    local actual_checksum=$(shasum -a 256 "$LOCAL_ISO_PATH" | cut -d' ' -f1)
    local expected_checksum=$(echo "$ISO_CHECKSUM" | cut -d':' -f2)
    
    if [ "$actual_checksum" = "$expected_checksum" ]; then
        log_success "ISO文件校验和验证通过"
    else
        log_warning "ISO文件校验和不匹配"
        log_warning "预期: $expected_checksum"
        log_warning "实际: $actual_checksum"
        read -p "是否继续构建？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 检查CPU虚拟化支持
check_virtualization() {
    log_step "步骤3: 检查CPU虚拟化支持"
    
    if egrep -c '(vmx|svm)' /proc/cpuinfo > /dev/null; then
        local virt_support=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
        log_success "CPU支持硬件虚拟化技术 (检测到 $virt_support 个核心)"
    else
        log_error "CPU不支持硬件虚拟化技术 (VT-x/AMD-V)"
        log_error "请在BIOS中启用虚拟化功能"
        exit 1
    fi
}

# 检查和安装依赖（如果存在则跳过）
install_dependencies() {
    log_step "步骤4: 检查和安装构建依赖"
    
    # 检查Packer是否已安装
    if command -v packer &> /dev/null; then
        local packer_version=$(packer version | head -n1)
        log_info "检测到已安装的Packer: $packer_version"
    else
        log_info "安装Packer..."
        sudo apt update
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install -y packer
    fi
    
    # 检查QEMU/KVM是否已安装
    if command -v qemu-system-x86_64 &> /dev/null; then
        local qemu_version=$(qemu-system-x86_64 --version | head -n1)
        log_info "检测到已安装的QEMU: $qemu_version"
        
        # 确保libvirtd服务运行
        if ! systemctl is-active --quiet libvirtd; then
            log_info "启动libvirtd服务..."
            sudo systemctl enable --now libvirtd
        else
            log_info "libvirtd服务已运行"
        fi
    else
        log_info "安装QEMU/KVM..."
        sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf
        sudo systemctl enable --now libvirtd
    fi
    
    # 验证安装
    log_info "验证工具安装..."
    if ! command -v packer &> /dev/null; then
        log_error "Packer不可用"
        exit 1
    fi
    
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        log_error "QEMU不可用"
        exit 1
    fi
    
    log_success "构建依赖检查完成"
}

# 检查磁盘空间
check_disk_space() {
    log_step "步骤5: 检查磁盘空间"
    
    local required_space=100  # GB
    local available_space=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
    
    log_info "需要磁盘空间: ${required_space}GB"
    log_info "可用磁盘空间: ${available_space}GB"
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_error "磁盘空间不足"
        exit 1
    else
        log_success "磁盘空间充足"
    fi
}

# 创建优化的Packer配置
create_packer_config() {
    log_step "步骤6: 创建Packer配置文件"
    
    # 确保windows目录存在
    mkdir -p "$WINDOWS_DIR"
    
    # 备份原配置
    if [ -f "${WINDOWS_DIR}/win10_22h2.pkr.hcl" ]; then
        cp "${WINDOWS_DIR}/win10_22h2.pkr.hcl" "${WINDOWS_DIR}/win10_22h2.pkr.hcl.backup.$(date +%Y%m%d-%H%M%S)"
    fi
    
    # 获取ISO绝对路径
    local abs_iso_path=$(realpath "$LOCAL_ISO_PATH")
    
    cat > "${WINDOWS_DIR}/win10_22h2.pkr.hcl" << EOF
packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

# 变量定义
variable "accelerator" {
  type    = string
  default = "kvm"
}

variable "autounattend" {
  type    = string
  default = "./answer_files/10/Autounattend.xml"
}

variable "cpus" {
  type    = string
  default = "$CPU_COUNT"
}

variable "disk_size" {
  type    = string
  default = "$DISK_SIZE"
}

variable "headless" {
  type    = string
  default = "$HEADLESS"
}

variable "iso_checksum" {
  type    = string
  default = "$ISO_CHECKSUM"
}

variable "iso_url" {
  type    = string
  default = "file://$abs_iso_path"
}

variable "memory_size" {
  type    = string
  default = "$MEMORY_SIZE"
}

variable "shutdown_command" {
  type    = string
  default = "%WINDIR%/system32/sysprep/sysprep.exe /generalize /oobe /shutdown /unattend:C:/Windows/Temp/Autounattend.xml"
}

variable "vm_name" {
  type    = string
  default = "$VM_NAME"
}

# QEMU构建源配置
source "qemu" "win10_22h2" {
  accelerator      = "\${var.accelerator}"
  boot_wait        = "3s"
  boot_command     = ["<enter>"]
  communicator     = "winrm"
  cpus             = "\${var.cpus}"
  disk_compression = true
  disk_interface   = "virtio"
  disk_size        = "\${var.disk_size}"
  floppy_files     = [
    "\${var.autounattend}", 
    "./scripts/1-firstlogin.bat", 
    "./scripts/2-fixnetwork.ps1", 
    "./scripts/70-install-misc.bat", 
    "./scripts/75-install-ecosystem-tools.bat",
    "./scripts/50-enable-winrm.ps1", 
    "./answer_files/Firstboot/Firstboot-Autounattend.xml", 
    "./drivers/"
  ]
  format           = "qcow2"
  headless         = "\${var.headless}"
  iso_checksum     = "\${var.iso_checksum}"
  iso_url          = "\${var.iso_url}"
  memory           = "\${var.memory_size}"
  net_device       = "virtio-net"
  vnc_bind_address = "127.0.0.1"
  vga              = "qxl"
  efi_boot         = true
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
  shutdown_command = "\${var.shutdown_command}"
  winrm_insecure   = true
  winrm_password   = "$ADMIN_PASS"
  winrm_timeout    = "45m"
  winrm_use_ssl    = true
  winrm_username   = "$ADMIN_USER"
  output_directory = "output-\${var.vm_name}"
}

# 构建配置
build {
  sources = ["source.qemu.win10_22h2"]

  # 第一阶段：基础软件安装
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = [
      "./scripts/70-install-misc.bat", 
      "./scripts/75-install-ecosystem-tools.bat"
    ]
  }

  # 系统重启
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
    restart_timeout = "15m"
  }

  # 第二阶段：.NET性能优化
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/80-compile-dotnet-assemblies.bat"]
  }

  # 第三阶段：网络配置清理
  provisioner "powershell" {
    script            = "./scripts/89-remove-philips-network.ps1"
    elevated_user     = "$ADMIN_USER"
    elevated_password = "$ADMIN_PASS"
  }

  # 第四阶段：磁盘压缩优化
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/90-compact.bat"]
  }
}
EOF
    
    log_success "Packer配置文件创建完成"
}

# 创建生态系统工具安装脚本
create_ecosystem_script() {
    log_step "步骤7: 创建生态系统工具安装脚本"
    
    # 确保脚本目录存在
    mkdir -p "${WINDOWS_DIR}/scripts"
    
    cat > "${WINDOWS_DIR}/scripts/75-install-ecosystem-tools.bat" << 'EOF'
@echo off
REM =============================================================================
REM 生态系统应用和开发工具安装脚本
REM =============================================================================

echo [INFO] 开始安装生态系统应用和开发工具...

REM 严格按照PDF文档要求创建两个用户账户
echo [INFO] 创建管理员账户 philips (如果不存在)...
net user philips philips /add /comment:"生态系统管理员" 2>nul || echo [INFO] 用户 philips 已存在
net localgroup "Administrators" philips /add 2>nul || echo [INFO] philips 已在管理员组

echo [INFO] 创建普通用户账户 user...
net user user vmuser123 /add /comment:"生态系统普通用户"
net localgroup "Users" user /add

echo [INFO] 确保只有两个用户账户配置完成
echo [INFO] 管理员: philips/philips
echo [INFO] 普通用户: user/vmuser123

REM 安装开发环境
echo [INFO] 安装.NET开发环境...
choco install dotnet-6.0-sdk dotnet-8.0-sdk -y

echo [INFO] 安装Java开发环境...
choco install openjdk17 maven gradle -y

echo [INFO] 安装Node.js和Python...
choco install nodejs python -y
choco install yarn -y

REM 安装数据库工具
echo [INFO] 安装数据库客户端工具...
choco install mysql.workbench postgresql pgadmin4 -y
choco install mongodb-compass -y

REM 安装容器和DevOps工具
echo [INFO] 安装容器和DevOps工具...
choco install docker-desktop kubernetes-cli -y
choco install terraform -y

REM 安装IDE和编辑器
echo [INFO] 安装开发IDE和编辑器...
choco install vscode intellijidea-community -y
choco install notepadplusplus -y

REM 安装版本控制工具
echo [INFO] 安装Git和相关工具...
choco install git gitextensions -y
choco install github-desktop -y

REM 安装浏览器
echo [INFO] 安装浏览器...
choco install googlechrome firefox -y

REM 安装API测试工具
echo [INFO] 安装API测试工具...
choco install postman insomnia-rest-api-client -y

REM 安装系统工具
echo [INFO] 安装系统工具...
choco install 7zip procexp procmon -y
choco install putty winscp filezilla -y

REM 安装云工具
echo [INFO] 安装云平台工具...
choco install awscli azure-cli -y

REM 配置开发环境
echo [INFO] 配置开发环境...
git config --global init.defaultBranch main
git config --global user.name "Ecosystem Developer"
git config --global user.email "developer@ecosystem.local"

echo [SUCCESS] 生态系统工具安装完成！
EOF
    
    log_success "生态系统工具安装脚本创建完成"
}

# 运行构建
run_build() {
    log_step "步骤8: 运行VM镜像构建"
    
    cd "$WINDOWS_DIR"
    
    # 初始化Packer插件
    log_info "初始化Packer插件..."
    if ! packer init win10_22h2.pkr.hcl; then
        log_error "Packer插件初始化失败"
        exit 1
    fi
    
    # 验证配置
    log_info "验证Packer配置..."
    if ! packer validate win10_22h2.pkr.hcl; then
        log_error "Packer配置验证失败"
        exit 1
    fi
    
    # 显示构建信息
    echo ""
    log_info "========== 构建配置信息 =========="
    echo "虚拟机名称: $VM_NAME"
    echo "磁盘大小: ${DISK_SIZE}MB (40GB)"
    echo "内存大小: ${MEMORY_SIZE}MB (16GB)"  
    echo "CPU核心数: $CPU_COUNT"
    echo "ISO文件: $LOCAL_ISO_PATH"
    echo "管理员账户: $ADMIN_USER / $ADMIN_PASS"
    echo "普通用户: $NORMAL_USER / $NORMAL_PASS"
    echo "==============================="
    echo ""
    
    read -p "是否开始构建？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "构建已取消"
        exit 0
    fi
    
    # 开始构建
    log_info "开始构建生态系统应用VM镜像..."
    log_info "构建开始时间: $(date)"
    
    if packer build win10_22h2.pkr.hcl 2>&1 | tee -a "$LOG_FILE"; then
        log_success "VM镜像构建完成！"
        log_info "构建完成时间: $(date)"
    else
        log_error "VM镜像构建失败！"
        log_error "查看日志文件: $LOG_FILE"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
}

# 创建启动脚本
create_startup_script() {
    log_step "步骤9: 创建VM启动脚本"
    
    local output_dir="${WINDOWS_DIR}/output-${VM_NAME}"
    local vm_image="${output_dir}/${VM_NAME}"
    
    cat > "${SCRIPT_DIR}/start-vm.sh" << EOF
#!/usr/bin/env bash
# 启动生态系统应用VM

VM_IMAGE="$vm_image"
OUTPUT_DIR="$output_dir"

if [ ! -f "\$VM_IMAGE" ]; then
    echo "错误: 找不到VM镜像文件: \$VM_IMAGE"
    exit 1
fi

echo "启动生态系统应用VM..."
echo "配置: 16GB内存, 12核CPU, 500GB磁盘"
echo ""

# 启动虚拟机
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

    chmod +x "${SCRIPT_DIR}/start-vm.sh"
    log_success "VM启动脚本创建完成"
}

# 创建飞利浦交付包
create_delivery_package() {
    log_step "步骤10: 创建飞利浦交付包"
    
    local output_dir="${WINDOWS_DIR}/output-${VM_NAME}"
    local delivery_zip="philips-ecosystem-vm-delivery-$(date +%Y%m%d).zip"
    
    if [ ! -d "$output_dir" ]; then
        log_warning "VM输出目录不存在，跳过打包"
        return
    fi
    
    log_info "准备飞利浦交付包..."
    cd "$WINDOWS_DIR"
    
    # 创建交付包内容
    log_info "打包VM镜像和相关文件..."
    zip -r "$delivery_zip" "output-${VM_NAME}/" 2>&1 | tee -a "$LOG_FILE"
    
    if [ -f "$delivery_zip" ]; then
        local zip_size=$(du -h "$delivery_zip" | cut -f1)
        log_success "飞利浦交付包创建完成: $delivery_zip ($zip_size)"
        
        # 创建交付说明
        cat > "delivery-readme.txt" << EOF
飞利浦生态系统应用VM镜像交付包
=======================================

交付内容:
- VM镜像文件: ${VM_NAME} (QCOW2格式)
- EFI变量文件: efivars.fd
- UEFI固件: OVMF_CODE_4M.fd (如有)

VM规格:
- 磁盘大小: 500GB
- 内存配置: 16GB
- CPU核心: 12个
- 操作系统: Windows 10 Enterprise 22H2

用户账户 (严格按照PDF文档):
- 管理员: philips / philips
- 普通用户: user / vmuser123

预装软件:
- 开发环境: .NET 6/8, Java 17, Node.js, Python
- 开发工具: VS Code, IntelliJ IDEA, Git
- 数据库工具: MySQL Workbench, pgAdmin, MongoDB Compass
- 容器工具: Docker Desktop, Kubernetes CLI
- 云工具: AWS CLI, Azure CLI, Terraform
- 浏览器: Chrome, Firefox
- API工具: Postman, Insomnia
- 系统工具: 7-Zip, Process Explorer, PuTTY

使用方法:
1. 解压此ZIP文件到目标服务器
2. 使用提供的启动脚本启动VM
3. 通过RDP连接: localhost:3389
4. 使用上述用户账户登录

构建时间: $(date)
构建版本: 飞利浦生态系统应用VM v1.0
EOF
        
        log_info "创建交付说明文档..."
        zip "$delivery_zip" "delivery-readme.txt"
        rm "delivery-readme.txt"
        
        cd "$SCRIPT_DIR"
        mv "${WINDOWS_DIR}/$delivery_zip" "./"
        
        log_success "飞利浦交付包准备完成: $delivery_zip"
    else
        log_error "交付包创建失败"
    fi
}

# 显示完成信息
show_completion() {
    echo ""
    log_success "============================================================================="
    log_success "                    生态系统应用VM构建完成！"
    log_success "============================================================================="
    echo ""
    
    echo -e "${CYAN}构建结果:${NC}"
    echo "  VM名称: $VM_NAME"
    echo "  磁盘大小: 500GB"
    echo "  内存大小: 16GB"
    echo "  CPU核心: 12个"
    echo ""
    
    echo -e "${CYAN}用户账户:${NC}"
    echo "  管理员: $ADMIN_USER / $ADMIN_PASS"
    echo "  普通用户: $NORMAL_USER / $NORMAL_PASS"
    echo ""
    
    echo -e "${CYAN}如何使用:${NC}"
    echo "  1. 启动VM: ./start-vm.sh"
    echo "  2. RDP连接: localhost:3389"
    echo "  3. WinRM连接: localhost:5985"
    echo ""
    
    echo -e "${CYAN}飞利浦交付:${NC}"
    if [ -f "philips-ecosystem-vm-delivery-$(date +%Y%m%d).zip" ]; then
        local zip_file="philips-ecosystem-vm-delivery-$(date +%Y%m%d).zip"
        local zip_size=$(du -h "$zip_file" | cut -f1)
        echo "  交付包: $zip_file ($zip_size)"
        echo "  包含: VM镜像、启动脚本、使用说明"
    fi
    echo ""
}

# 错误处理
handle_error() {
    local exit_code=$?
    log_error "构建过程中发生错误 (退出代码: $exit_code)"
    log_error "查看详细日志: $LOG_FILE"
    exit $exit_code
}

# 检查现有环境（不清理）
check_existing_environment() {
    log_step "步骤1: 检查现有构建环境"
    
    # 检查是否有现有VM输出目录
    if [ -d "${WINDOWS_DIR}/output-${VM_NAME}" ]; then
        log_warning "发现现有VM输出目录: ${WINDOWS_DIR}/output-${VM_NAME}"
        log_warning "如需重新构建，请手动删除该目录"
    else
        log_info "未发现现有VM输出目录，准备进行全新构建"
    fi
    
    # 检查旧的日志文件
    if ls build-*.log 1> /dev/null 2>&1; then
        local log_count=$(ls build-*.log | wc -l)
        log_info "发现 $log_count 个旧的构建日志文件"
    fi
    
    # 检查Packer缓存
    if [ -d "$HOME/.packer.d" ]; then
        log_info "发现Packer缓存目录，将重用现有插件"
    else
        log_info "未发现Packer缓存，首次构建将下载插件"
    fi
    
    log_success "环境检查完成"
}

# 主函数
main() {
    # 设置错误处理
    trap handle_error ERR
    
    # 执行构建流程
    show_banner
    check_existing_environment
    verify_local_iso
    check_virtualization
    install_dependencies
    check_disk_space
    create_packer_config
    create_ecosystem_script
    run_build
    create_startup_script
    create_delivery_package
    show_completion
    
    log_success "生态系统应用VM构建流程完成！"
}

# 执行主函数
main "$@"