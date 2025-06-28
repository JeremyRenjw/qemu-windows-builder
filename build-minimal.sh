#!/bin/bash
# 最小化VM构建脚本 - 只安装基础Windows，手动启用WinRM

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINDOWS_DIR="${SCRIPT_DIR}/windows"
LOG_FILE="${SCRIPT_DIR}/build-minimal-$(date +%Y%m%d-%H%M%S).log"

# VM配置
VM_NAME="windows_10_minimal"
DISK_SIZE="40960"     # 40GB
MEMORY_SIZE="16384"   # 16GB
CPU_COUNT="10"        # 10核
HEADLESS="false"      # 显示界面，方便调试

# 本地ISO配置
LOCAL_ISO_PATH="./downloads/Win10_22H2_x64.iso"

# 检查空间函数
check_disk_space() {
    local required_gb=90
    local available_gb=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
    
    if [ $available_gb -lt $required_gb ]; then
        echo -e "${RED}[ERROR] 磁盘空间不足！${NC}"
        echo "需要: ${required_gb}GB"
        echo "可用: ${available_gb}GB"
        exit 1
    fi
    
    echo -e "${GREEN}磁盘空间检查通过: ${available_gb}GB 可用${NC}"
}

# 检查ISO文件
check_iso_file() {
    if [ ! -f "$LOCAL_ISO_PATH" ]; then
        echo -e "${RED}[ERROR] ISO文件不存在: $LOCAL_ISO_PATH${NC}"
        echo "请确保Windows 10 ISO文件存在于 downloads/ 目录"
        exit 1
    fi
    
    local iso_size=$(du -h "$LOCAL_ISO_PATH" | cut -f1)
    echo -e "${GREEN}ISO文件检查通过: $iso_size${NC}"
}

# 创建最小Packer配置
create_minimal_packer_config() {
    cat > "${WINDOWS_DIR}/win10_minimal.pkr.hcl" << 'EOF'
packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.9"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "iso_url" {
  type    = string
  default = "./downloads/Win10_22H2_x64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "file:./downloads/Win10_22H2_x64.iso.sha256"
}

variable "vm_name" {
  type    = string
  default = "windows_10_minimal"
}

variable "memory_size" {
  type    = string
  default = "16384"
}

variable "cpus" {
  type    = string
  default = "10"
}

variable "disk_size" {
  type    = string
  default = "40960"
}

variable "headless" {
  type    = bool
  default = false
}

source "qemu" "win10_minimal" {
  accelerator      = "kvm"
  boot_wait        = "2s"
  communicator     = "none"
  cpus             = var.cpus
  disk_size        = var.disk_size
  floppy_files     = [
    "./answer_files/10/Autounattend.xml",
    "./drivers/amd64/w10/"
  ]
  format           = "qcow2"
  headless         = var.headless
  iso_checksum     = var.iso_checksum
  iso_url          = var.iso_url
  memory           = var.memory_size
  output_directory = "output-${var.vm_name}"
  shutdown_timeout = "30m"
  vm_name          = "${var.vm_name}.qcow2"
  
  efi_boot         = true
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS.fd"
  
  qemuargs = [
    ["-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd"],
    ["-drive", "if=pflash,format=raw,file=/tmp/my_vars.fd"],
    ["-device", "virtio-net,netdev=user.0"],
    ["-netdev", "user,id=user.0,hostfwd=tcp::{{ .SSHHostPort }}-:22"],
  ]
}

build {
  sources = ["source.qemu.win10_minimal"]
}
EOF

    echo -e "${GREEN}创建了最小化Packer配置${NC}"
}

# 创建简化的Autounattend.xml
create_minimal_autounattend() {
    cat > "${WINDOWS_DIR}/answer_files/10/Autounattend-minimal.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Setup"
                   processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral"
                   versionScope="nonSxS">
            <DiskConfiguration>
                <Disk wcm:action="add">
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Size>100</Size>
                            <Type>EFI</Type>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>2</Order>
                            <Extend>true</Extend>
                            <Type>Primary</Type>
                        </CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add">
                            <Order>1</Order>
                            <PartitionID>1</PartitionID>
                            <Format>FAT32</Format>
                            <Label>System</Label>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Order>2</Order>
                            <PartitionID>2</PartitionID>
                            <Format>NTFS</Format>
                            <Label>Windows</Label>
                        </ModifyPartition>
                    </ModifyPartitions>
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                </Disk>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>2</PartitionID>
                    </InstallTo>
                    <WillShowUI>OnError</WillShowUI>
                    <InstallFrom>
                        <MetaData wcm:action="add">
                            <Key>/IMAGE/NAME</Key>
                            <Value>Windows 10 Enterprise</Value>
                        </MetaData>
                    </InstallFrom>
                </OSImage>
            </ImageInstall>
        </component>
        <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64"
                   publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <SetupUILanguage>
                <UILanguage>en-US</UILanguage>
            </SetupUILanguage>
            <InputLocale>0409:00020409</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
            <UserLocale>en-US</UserLocale>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Shell-Setup"
                   processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral"
                   versionScope="nonSxS">
            <UserAccounts>
                <AdministratorPassword>
                    <Value>philips</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value>philips</Value>
                            <PlainText>true</PlainText>
                        </Password>
                        <Description>philips User</Description>
                        <DisplayName>philips</DisplayName>
                        <Group>administrators</Group>
                        <Name>philips</Name>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <SkipUserOOBE>true</SkipUserOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <ProtectYourPC>1</ProtectYourPC>
            </OOBE>
            <AutoLogon>
                <Password>
                    <Value>philips</Value>
                    <PlainText>true</PlainText>
                </Password>
                <Username>philips</Username>
                <Enabled>true</Enabled>
                <LogonCount>3</LogonCount>
            </AutoLogon>
            <ShowWindowsLive>false</ShowWindowsLive>
        </component>
    </settings>
</unattend>
EOF

    echo -e "${GREEN}创建了简化的Autounattend.xml${NC}"
}

# 主执行流程
main() {
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}    最小化Windows 10 VM构建${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo ""
    
    # 预检查
    check_disk_space
    check_iso_file
    
    # 进入工作目录
    cd "$WINDOWS_DIR"
    
    # 创建配置文件
    create_minimal_packer_config
    create_minimal_autounattend
    
    echo ""
    echo -e "${YELLOW}构建配置:${NC}"
    echo "VM名称: $VM_NAME"
    echo "磁盘大小: 40GB"
    echo "内存: 16GB"
    echo "CPU: 10核"
    echo "模式: 有界面（方便调试）"
    echo ""
    
    echo -e "${YELLOW}注意：此构建将创建纯净的Windows系统，无WinRM自动配置${NC}"
    echo -e "${YELLOW}安装完成后需要手动登录并配置网络连接${NC}"
    echo ""
    
    read -p "按Enter开始构建，或Ctrl+C取消..."
    
    # 初始化并构建
    echo -e "${GREEN}初始化Packer插件...${NC}"
    packer init win10_minimal.pkr.hcl
    
    echo -e "${GREEN}开始构建（这将需要约30-45分钟）...${NC}"
    packer build \
        -var="iso_url=../downloads/Win10_22H2_x64.iso" \
        -var="vm_name=$VM_NAME" \
        -var="memory_size=$MEMORY_SIZE" \
        -var="cpus=$CPU_COUNT" \
        -var="disk_size=$DISK_SIZE" \
        -var="headless=$HEADLESS" \
        win10_minimal.pkr.hcl 2>&1 | tee "$LOG_FILE"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}======================================${NC}"
        echo -e "${GREEN}    构建成功完成！${NC}"
        echo -e "${GREEN}======================================${NC}"
        echo ""
        echo "输出文件: output-${VM_NAME}/${VM_NAME}.qcow2"
        echo "日志文件: $LOG_FILE"
        echo ""
        echo "用户账户:"
        echo "  管理员: philips / philips"
        echo ""
        echo -e "${YELLOW}注意：此镜像需要手动配置网络和WinRM${NC}"
    else
        echo -e "${RED}======================================${NC}"
        echo -e "${RED}    构建失败！${NC}"
        echo -e "${RED}======================================${NC}"
        echo "请查看日志: $LOG_FILE"
        exit 1
    fi
}

# 执行主函数
main "$@"