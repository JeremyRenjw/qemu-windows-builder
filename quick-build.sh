#!/bin/bash
# =============================================================================
# 快速构建脚本 - 生态系统应用VM镜像
# Quick Build Script for Ecosystem Application VM Image
# =============================================================================

echo "============================================================================="
echo "        生态系统应用VM镜像快速构建器"
echo "============================================================================="
echo ""

# 配置检查
echo "🔍 检查构建环境..."

# 检查是否在正确目录
if [ ! -f "build-ecosystem-vm-complete.sh" ]; then
    echo "❌ 错误: 请在包含build-ecosystem-vm-complete.sh的目录中运行此脚本"
    exit 1
fi

# 检查权限
if [ "$EUID" -eq 0 ]; then
    echo "❌ 错误: 请不要使用root权限运行此脚本"
    exit 1
fi

echo "✅ 环境检查通过"
echo ""

# 显示配置信息
echo "📋 构建配置:"
echo "   虚拟机名称: ecosystem-application-vm"
echo "   磁盘大小: 500GB"
echo "   内存大小: 16GB"
echo "   CPU核心: 12个"
echo "   目标系统: Windows 10 Enterprise 22H2"
echo ""

# 提示用户配置ISO
echo "⚠️  重要提示:"
echo "   1. 请确保你有有效的Windows 10 Enterprise 22H2 ISO文件"
echo "   2. 需要修改脚本中的ISO_URL和ISO_CHECKSUM变量"
echo "   3. 构建过程大约需要2-4小时，请确保网络稳定"
echo "   4. 需要至少600GB可用磁盘空间"
echo ""

# 询问是否继续
read -p "是否继续构建？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "构建已取消"
    exit 0
fi

echo ""
echo "🚀 开始构建生态系统应用VM镜像..."
echo "   构建日志将保存到 build-$(date +%Y%m%d-%H%M%S).log"
echo ""

# 执行完整构建脚本
./build-ecosystem-vm-complete.sh

echo ""
echo "✅ 快速构建脚本执行完成！"