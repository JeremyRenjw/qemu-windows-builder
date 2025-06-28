#!/usr/bin/env bash
# =============================================================================
# 生态系统应用VM镜像快速构建启动器
# 使用本地下载的Windows ISO文件
# =============================================================================

echo "🚀 生态系统应用VM镜像快速构建启动器"
echo "============================================================================="
echo ""

# 检查ISO文件
ISO_PATH="./downloads/Win10_22H2_x64.iso"

if [ ! -f "$ISO_PATH" ]; then
    echo "❌ 错误: 找不到Windows ISO文件"
    echo "   预期位置: $ISO_PATH"
    echo ""
    echo "请确保ISO文件存在于正确位置"
    exit 1
fi

echo "✅ 找到Windows ISO文件: $(basename "$ISO_PATH")"
echo "   文件大小: $(du -h "$ISO_PATH" | cut -f1)"
echo ""

# 显示构建配置
echo "📋 构建配置:"
echo "   虚拟机名称: windows_10"
echo "   输出目录: output-windows_10"
echo "   磁盘大小: 40GB"
echo "   内存大小: 16GB" 
echo "   CPU核心: 12个"
echo "   用户账户: philips/philips (管理员) + user/vmuser123 (普通用户)"
echo "   最终交付: 自动打包ZIP文件给飞利浦"
echo ""

# 显示预装软件
echo "📦 将安装的生态系统软件:"
echo "   • 开发环境: .NET 6/8, Java 17, Node.js, Python"
echo "   • 开发工具: VS Code, IntelliJ IDEA, Git"
echo "   • 数据库工具: MySQL Workbench, pgAdmin, MongoDB Compass"
echo "   • 容器工具: Docker Desktop, Kubernetes CLI"
echo "   • 云工具: AWS CLI, Azure CLI, Terraform"
echo "   • 浏览器: Chrome, Firefox"
echo "   • API工具: Postman, Insomnia"
echo "   • 系统工具: 7-Zip, Process Explorer, PuTTY"
echo ""

# 估计构建时间
echo "⏱️  预计构建时间: 1-2小时 (取决于网络速度和硬件性能)"
echo "💾 需要磁盘空间: 约90GB"
echo ""

# 环境检查（不清理现有环境）
echo "🔍 检查现有环境:"

# 检查现有VM
if [ -d "windows/output-windows_10" ]; then
    echo "   ⚠️  发现现有VM输出目录: windows/output-windows_10"
    echo "      如需重新构建，请手动删除该目录"
else
    echo "   ✅ 未发现现有VM，准备全新构建"
fi

# 检查现有Packer
if command -v packer &> /dev/null; then
    packer_version=$(packer version | head -n1)
    echo "   ✅ 检测到现有Packer: $packer_version"
else
    echo "   ℹ️  未检测到Packer，将安装最新版本"
fi

# 检查现有QEMU/KVM
if command -v qemu-system-x86_64 &> /dev/null; then
    qemu_version=$(qemu-system-x86_64 --version | head -n1)
    echo "   ✅ 检测到现有QEMU: $qemu_version"
else
    echo "   ℹ️  未检测到QEMU/KVM，将安装最新版本"
fi

echo ""
echo "🔍 系统要求检查:"

# 检查CPU虚拟化
if egrep -c '(vmx|svm)' /proc/cpuinfo > /dev/null 2>&1; then
    echo "   ✅ CPU虚拟化支持: 已启用"
else
    echo "   ❌ CPU虚拟化支持: 未检测到"
    echo "      请在BIOS中启用Intel VT-x或AMD-V"
    exit 1
fi

# 检查磁盘空间
available_space=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
if [ "$available_space" -gt 90 ]; then
    echo "   ✅ 磁盘空间: ${available_space}GB 可用"
else
    echo "   ❌ 磁盘空间不足: ${available_space}GB 可用 (需要至少90GB)"
    exit 1
fi

# 检查内存
total_mem=$(free -g | awk 'NR==2{print $2}')
if [ "$total_mem" -gt 24 ]; then
    echo "   ✅ 系统内存: ${total_mem}GB (充足)"
else
    echo "   ⚠️  系统内存: ${total_mem}GB (建议至少32GB)"
fi

echo ""

# 询问是否继续
read -p "是否开始构建生态系统应用VM镜像？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "构建已取消"
    exit 0
fi

echo ""
echo "🔥 开始构建..."
echo "   构建日志将保存到: build-$(date +%Y%m%d-%H%M%S).log"
echo "   可以随时按 Ctrl+C 停止构建"
echo ""

# 执行构建脚本
bash ./build-with-local-iso.sh

echo ""
echo "✅ 快速启动脚本执行完成！"