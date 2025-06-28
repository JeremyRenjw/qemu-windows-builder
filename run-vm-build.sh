#!/bin/bash
echo "生态系统VM构建器 - Ubuntu版本"
echo "=================================="

# 检查ISO文件
if [ ! -f "./downloads/Win10_22H2_x64.iso" ]; then
    echo "错误: 找不到ISO文件 ./downloads/Win10_22H2_x64.iso"
    echo "请创建downloads目录并放置Windows 10 ISO文件"
    exit 1
fi

echo "找到ISO文件，开始构建..."

# 检查系统要求
echo "检查系统..."
if ! egrep -c '(vmx|svm)' /proc/cpuinfo > /dev/null; then
    echo "错误: CPU不支持虚拟化"
    exit 1
fi

# 检查磁盘空间
space=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
if [ "$space" -lt 600 ]; then
    echo "错误: 磁盘空间不足，需要600GB"
    exit 1
fi

echo "系统检查通过"
echo "开始构建Windows 10 VM (500GB)..."

# 运行构建脚本
if [ -f "./build.sh" ]; then
    bash ./build.sh
elif [ -f "./build-with-local-iso.sh" ]; then
    bash ./build-with-local-iso.sh
else
    echo "错误: 找不到构建脚本"
    exit 1
fi

echo "构建完成！"