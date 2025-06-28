#!/usr/bin/env bash
# 测试脚本 - Ubuntu兼容版本

echo "Ubuntu VM构建脚本测试"
echo "====================="

# 检查系统
echo "系统信息："
uname -a
echo ""

# 检查bash版本
echo "Bash版本："
bash --version | head -1
echo ""

# 检查当前目录
echo "当前目录："
pwd
echo ""

# 检查文件权限
echo "脚本文件权限："
ls -la quick-start.sh 2>/dev/null || echo "quick-start.sh 不存在"
ls -la build-with-local-iso.sh 2>/dev/null || echo "build-with-local-iso.sh 不存在"
echo ""

# 检查ISO文件路径
echo "检查ISO文件："
if [ -f "./downloads/Win10_22H2_x64.iso" ]; then
    echo "✅ 找到ISO文件"
    ls -lh "./downloads/Win10_22H2_x64.iso"
else
    echo "❌ 未找到ISO文件 ./downloads/Win10_22H2_x64.iso"
    echo "请创建downloads目录并放置ISO文件"
fi
echo ""

echo "测试完成！"