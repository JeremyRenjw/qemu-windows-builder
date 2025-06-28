#!/bin/bash
# =============================================================================
# 生态系统应用VM镜像一键构建脚本 (基于PDF文档要求)
# Build Ecosystem Application VM Image - Complete Deployment Script
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

# VM配置 - 根据PDF要求和用户需求
VM_NAME="ecosystem-application-vm"
DISK_SIZE="512000"    # 500GB (用户要求)
MEMORY_SIZE="16384"   # 16GB (增强配置，PDF默认4GB)
CPU_COUNT="12"        # 12核 (增强配置，PDF默认设置)
HEADLESS="false"      # PDF建议调试时设为false

# ISO配置 - 用户需要修改为实际值
ISO_URL="http://localhost:10086/Windows10_enterprise_22H2_KMS.iso"
ISO_CHECKSUM="sha256:2654d20e2f7cdc5949c0dcf1271892ce97c9e5482624459ff377cb5f742b41c7"

# 用户凭据配置 - 根据PDF文档
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
    echo "        生态系统应用VM镜像构建器 (Ecosystem Application VM Builder)"
    echo "============================================================================="
    echo -e "${NC}"
    echo "基于文档: Build Ecosystem Application VM Image.pdf"
    echo "目标系统: Windows 10 Enterprise 22H2"
    echo "构建时间: $(date)"
    echo ""
}

# 步骤1: 检查CPU虚拟化支持
check_virtualization() {
    log_step "步骤一: 检查CPU虚拟化支持"
    
    if egrep -c '(vmx|svm)' /proc/cpuinfo > /dev/null; then
        local virt_support=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
        log_success "CPU支持硬件虚拟化技术 (检测到 $virt_support 个核心)"
    else
        log_error "CPU不支持硬件虚拟化技术 (VT-x/AMD-V)"
        log_error "请在BIOS中启用虚拟化功能"
        exit 1
    fi
}

# 步骤2: 更新软件包列表
update_packages() {
    log_step "步骤二: 更新Ubuntu软件包列表"
    
    if sudo apt update; then
        log_success "软件包列表更新完成"
    else
        log_error "软件包更新失败"
        exit 1
    fi
}

# 步骤3: 安装Packer
install_packer() {
    log_step "步骤三: 安装Packer 1.12.0"
    
    if command -v packer &> /dev/null; then
        local packer_version=$(packer -version)
        log_info "Packer已安装: $packer_version"
        return 0
    fi
    
    log_info "从HashiCorp官方下载Packer 1.12.0..."
    
    # 下载Packer 1.12.0 (根据PDF要求)
    local packer_url="https://releases.hashicorp.com/packer/1.12.0/packer_1.12.0_linux_amd64.zip"
    
    wget "$packer_url" -O packer_1.12.0_linux_amd64.zip
    unzip packer_1.12.0_linux_amd64.zip
    sudo mv packer /usr/local/bin/
    rm packer_1.12.0_linux_amd64.zip
    
    # 验证安装
    if packer -version; then
        log_success "Packer安装成功"
    else
        log_error "Packer安装失败"
        exit 1
    fi
}

# 步骤4: 安装KVM相关工具
install_kvm() {
    log_step "步骤四: 安装KVM虚拟化工具"
    
    log_info "安装KVM和相关组件..."
    sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
    
    # 启动并启用libvirtd服务
    log_info "启动libvirtd服务..."
    sudo systemctl start libvirtd
    sudo systemctl enable libvirtd
    
    # 验证KVM安装
    if sudo virsh list --all &> /dev/null; then
        log_success "KVM安装成功"
    else
        log_warning "KVM可能需要重启后才能正常工作"
    fi
}

# 步骤5: 检查磁盘空间
check_disk_space() {
    log_step "步骤五: 检查磁盘空间"
    
    local required_space=600  # GB (500GB镜像 + 100GB缓冲)
    local available_space=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
    
    log_info "需要磁盘空间: ${required_space}GB"
    log_info "可用磁盘空间: ${available_space}GB"
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_error "磁盘空间不足: 需要${required_space}GB，可用${available_space}GB"
        exit 1
    else
        log_success "磁盘空间充足"
    fi
}

# 步骤6: 配置Packer文件和脚本
configure_packer() {
    log_step "步骤六: 配置Packer文件和脚本"
    
    # 确保windows目录存在
    if [ ! -d "$WINDOWS_DIR" ]; then
        log_error "找不到windows目录: $WINDOWS_DIR"
        exit 1
    fi
    
    # 备份原始配置
    if [ -f "${WINDOWS_DIR}/win10_22h2.pkr.hcl" ]; then
        cp "${WINDOWS_DIR}/win10_22h2.pkr.hcl" "${WINDOWS_DIR}/win10_22h2.pkr.hcl.backup.$(date +%Y%m%d-%H%M%S)"
        log_info "已备份原始Packer配置文件"
    fi
    
    # 创建优化的Packer配置文件
    create_optimized_packer_config
    
    # 更新Windows产品密钥配置
    update_windows_product_key
    
    # 创建增强的安装脚本
    create_enhanced_install_scripts
    
    log_success "Packer配置文件创建完成"
}

# 创建优化的Packer配置
create_optimized_packer_config() {
    log_info "创建优化的Packer配置文件..."
    
    cat > "${WINDOWS_DIR}/win10_22h2.pkr.hcl" << EOF
packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

# 变量定义 - 根据PDF文档和用户需求优化
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
  description = "设置虚拟机的虚拟CPU数量。更多的CPU可以提供更好的性能，但需要根据主机系统的能力进行设置。"
}

variable "disk_size" {
  type    = string
  default = "$DISK_SIZE"
  description = "设置虚拟机硬盘的大小，以MB为单位。"
}

variable "headless" {
  type    = string
  default = "$HEADLESS"
  description = "是否以无头模式运行。设为false可以显示构建过程。"
}

variable "iso_checksum" {
  type    = string
  default = "$ISO_CHECKSUM"
  description = "用于校验ISO文件的完整性，建议使用sha256格式。"
}

variable "iso_url" {
  type    = string
  default = "$ISO_URL"
  description = "指定Windows ISO文件的位置，用于安装操作系统。"
}

variable "memory_size" {
  type    = string
  default = "$MEMORY_SIZE"
  description = "设置虚拟机的内存容量，以MB为单位。"
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
  vnc_bind_address = "127.0.0.1"  # 安全性改进：仅本地访问
  vga              = "qxl"
  efi_boot         = true
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
  shutdown_command = "\${var.shutdown_command}"
  winrm_insecure   = true
  winrm_password   = "$ADMIN_PASS"
  winrm_timeout    = "45m"  # 增加超时时间适应大磁盘
  winrm_use_ssl    = true
  winrm_username   = "$ADMIN_USER"
  output_directory = "output-\${var.vm_name}"
}

# 构建配置
build {
  sources = ["source.qemu.win10_22h2"]

  # 第一阶段：安装生态系统工具和基础软件
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = [
      "./scripts/70-install-misc.bat", 
      "./scripts/75-install-ecosystem-tools.bat"
    ]
  }

  # 系统重启以确保驱动和软件正确安装
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

  # 第四阶段：磁盘压缩优化 (重要：将镜像从12-15GB压缩到8-9GB)
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/90-compact.bat"]
  }
}
EOF
}

# 更新Windows产品密钥
update_windows_product_key() {
    log_info "配置Windows产品密钥..."
    
    local autounattend_file="${WINDOWS_DIR}/answer_files/10/Autounattend.xml"
    
    if [ -f "$autounattend_file" ]; then
        # 检查是否需要设置产品密钥
        if grep -q "SET_KEY_HERE" "$autounattend_file"; then
            log_warning "检测到需要设置Windows产品密钥"
            log_warning "请编辑 $autounattend_file 文件"
            log_warning "将 SET_KEY_HERE 替换为有效的Windows 10 Enterprise密钥"
        else
            log_info "产品密钥配置检查完成"
        fi
    fi
}

# 创建生态系统工具安装脚本
create_enhanced_install_scripts() {
    log_info "创建生态系统工具安装脚本..."
    
    # 创建生态系统工具安装脚本
    cat > "${WINDOWS_DIR}/scripts/75-install-ecosystem-tools.bat" << 'EOF'
@echo off
REM =============================================================================
REM 生态系统应用和开发工具安装脚本 (根据PDF要求)
REM =============================================================================

echo [INFO] 开始安装生态系统应用和开发工具...

REM 创建普通用户账户 (根据PDF文档要求)
echo [INFO] 创建普通用户账户 user...
net user user vmuser123 /add /comment:"生态系统普通用户"
net localgroup "Users" user /add

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
choco install googlechrome -y

REM 配置开发环境
echo [INFO] 配置开发环境...

REM 配置Git全局设置
git config --global init.defaultBranch main
git config --global user.name "Ecosystem Developer"
git config --global user.email "developer@ecosystem.local"

REM 配置环境变量
setx JAVA_HOME "C:\Program Files\Eclipse Adoptium\jdk-17.0.8.101-hotspot" /M
setx PATH "%PATH%;%JAVA_HOME%\bin" /M

echo [SUCCESS] 生态系统工具安装完成！
EOF

    # 使脚本可执行
    chmod +x "${WINDOWS_DIR}/scripts/75-install-ecosystem-tools.bat"
    
    log_success "生态系统工具安装脚本创建完成"
}

# 步骤7: 检查目录和文件
verify_project_structure() {
    log_step "步骤七: 检查项目目录和文件"
    
    local required_dirs=("answer_files" "drivers" "scripts")
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "${WINDOWS_DIR}/$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [ ${#missing_dirs[@]} -ne 0 ]; then
        log_error "缺少必需的目录: ${missing_dirs[*]}"
        log_error "请确保包含 answer_files、drivers 和 scripts 文件夹中包含所需代码和资源。"
        exit 1
    fi
    
    log_success "项目目录结构验证通过"
}

# 步骤8: 运行构建
run_build() {
    log_step "步骤八: 构建虚拟机"
    
    cd "$WINDOWS_DIR"
    
    # 准备环境
    log_info "确保Ubuntu 24.04.2 LTS已设置完毕，并确保配置文件和目录结构正确..."
    
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
    echo "磁盘大小: ${DISK_SIZE}MB ($(( DISK_SIZE / 1024 ))GB)"
    echo "内存大小: ${MEMORY_SIZE}MB ($(( MEMORY_SIZE / 1024 ))GB)"
    echo "CPU核心数: $CPU_COUNT"
    echo "显示模式: $HEADLESS"
    echo "管理员账户: $ADMIN_USER"
    echo "普通用户账户: $NORMAL_USER"
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
    
    # 根据PDF建议，可以使用不同的构建选项
    local build_cmd="packer build"
    
    # 如果需要调试，使用非headless模式
    if [ "$HEADLESS" = "false" ]; then
        build_cmd="$build_cmd -var=headless=false"
    fi
    
    build_cmd="$build_cmd win10_22h2.pkr.hcl"
    
    log_info "执行构建命令: $build_cmd"
    
    if eval "$build_cmd" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "VM镜像构建完成！"
        log_info "构建完成时间: $(date)"
    else
        log_error "VM镜像构建失败！"
        log_error "查看日志文件: $LOG_FILE"
        
        # 提供调试建议
        echo ""
        log_warning "调试建议："
        echo "1. 如果遇到VNC连接失败，这是由于VNC启动速度有时候会慢的缘故，重新执行一次往往就正常了"
        echo "2. 使用调试模式: packer build -var=headless=false win10_22h2.pkr.hcl"
        echo "3. 检查日志文件: $LOG_FILE"
        
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
}

# 步骤9: 检查生成的虚拟机镜像
verify_build_output() {
    log_step "步骤九: 检查生成的虚拟机镜像"
    
    local output_dir="${WINDOWS_DIR}/output-${VM_NAME}"
    
    if [ -d "$output_dir" ]; then
        log_success "找到输出目录: $output_dir"
        
        # 检查关键文件
        local vm_image="${output_dir}/packer-${VM_NAME}"
        local efi_vars="${output_dir}/efivars.fd"
        
        if [ -f "$vm_image" ]; then
            local image_size=$(du -h "$vm_image" | cut -f1)
            log_success "VM镜像文件: $vm_image (大小: $image_size)"
        else
            log_warning "未找到主要镜像文件"
        fi
        
        if [ -f "$efi_vars" ]; then
            log_info "EFI变量文件: $efi_vars"
        fi
        
        # 列出所有文件
        log_info "输出目录内容:"
        ls -la "$output_dir"
        
    else
        log_error "未找到输出目录: $output_dir"
        exit 1
    fi
}

# 步骤10: 运行生成的虚拟机
create_vm_runner() {
    log_step "步骤十: 创建虚拟机运行脚本"
    
    local output_dir="${WINDOWS_DIR}/output-${VM_NAME}"
    local vm_image="${output_dir}/packer-${VM_NAME}"
    
    # 复制OVMF固件到输出目录
    if [ -f "/usr/share/OVMF/OVMF_CODE_4M.fd" ]; then
        cp /usr/share/OVMF/OVMF_CODE_4M.fd "${output_dir}/" 2>/dev/null || true
    fi
    
    # 创建虚拟机启动脚本
    cat > "${SCRIPT_DIR}/start-ecosystem-vm.sh" << EOF
#!/bin/bash
# 启动生态系统应用VM脚本

VM_IMAGE="$vm_image"
OUTPUT_DIR="$output_dir"

if [ ! -f "\$VM_IMAGE" ]; then
    echo "错误: 找不到VM镜像文件: \$VM_IMAGE"
    exit 1
fi

echo "启动生态系统应用VM..."
echo "VM配置:"
echo "  - 内存: ${MEMORY_SIZE}MB"
echo "  - CPU: ${CPU_COUNT}核"
echo "  - 镜像: \$VM_IMAGE"
echo ""

# 启动QEMU虚拟机
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
    -drive if=pflash,format=raw,readonly=on,file=\${OUTPUT_DIR}/OVMF_CODE_4M.fd \\
    -drive if=pflash,format=raw,file=\${OUTPUT_DIR}/efivars.fd

echo ""
echo "虚拟机已关闭"
EOF

    chmod +x "${SCRIPT_DIR}/start-ecosystem-vm.sh"
    
    log_success "虚拟机启动脚本已创建: start-ecosystem-vm.sh"
}

# 最终说明
show_final_instructions() {
    echo ""
    log_success "============================================================================="
    log_success "                    生态系统应用VM构建完成！"
    log_success "============================================================================="
    echo ""
    
    echo -e "${CYAN}虚拟机信息:${NC}"
    echo "  名称: $VM_NAME"
    echo "  磁盘: 500GB"
    echo "  内存: 16GB"
    echo "  CPU: 12核"
    echo ""
    
    echo -e "${CYAN}用户账户:${NC}"
    echo "  管理员: $ADMIN_USER / $ADMIN_PASS"
    echo "  普通用户: $NORMAL_USER / $NORMAL_PASS"
    echo ""
    
    echo -e "${CYAN}如何使用:${NC}"
    echo "  1. 启动VM: ./start-ecosystem-vm.sh"
    echo "  2. RDP连接: localhost:3389"
    echo "  3. WinRM连接: localhost:5985"
    echo ""
    
    echo -e "${CYAN}已安装的软件:${NC}"
    echo "  - 开发工具: VS Code, IntelliJ IDEA, Git"
    echo "  - 运行环境: .NET 6/8, Java 17, Node.js, Python"
    echo "  - 数据库工具: MySQL Workbench, pgAdmin, MongoDB Compass"
    echo "  - 容器工具: Docker Desktop, Kubernetes CLI"
    echo "  - 云工具: AWS CLI, Azure CLI, Terraform"
    echo "  - 浏览器: Chrome, Firefox"
    echo "  - API工具: Postman, Insomnia"
    echo ""
    
    echo -e "${CYAN}重要提示:${NC}"
    echo "  - 确保应用不需要使用管理员权限运行"
    echo "  - 虚拟机正常启动后，可以开始手动安装需要的软件"
    echo "  - 构建日志保存在: $LOG_FILE"
    echo ""
    
    echo -e "${YELLOW}Todo: 将output-${VM_NAME}目录打包成zip文件提交给Philips${NC}"
    echo ""
}

# 错误处理
handle_error() {
    local exit_code=$?
    log_error "构建过程中发生错误 (退出代码: $exit_code)"
    log_error "查看详细日志: $LOG_FILE"
    
    echo ""
    log_warning "常见问题解决方案:"
    echo "1. CPU虚拟化: 确保在BIOS中启用VT-x或AMD-V"
    echo "2. 权限问题: 确保用户在libvirt组中"
    echo "3. 网络问题: 检查防火墙设置"
    echo "4. 磁盘空间: 确保有足够的存储空间"
    echo "5. VNC问题: 重新运行构建命令"
    
    exit $exit_code
}

# 主函数
main() {
    # 设置错误处理
    trap handle_error ERR
    
    # 开始构建流程
    show_banner
    check_virtualization
    update_packages
    install_packer
    install_kvm
    check_disk_space
    configure_packer
    verify_project_structure
    run_build
    verify_build_output
    create_vm_runner
    show_final_instructions
    
    log_success "所有步骤完成！生态系统应用VM构建成功！"
}

# 执行主函数
main "$@"