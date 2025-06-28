#!/bin/bash
echo "=== ISO文件检查脚本 ==="
echo "当前目录: $(pwd)"
echo ""

echo "检查可能的ISO位置："
echo "1. ./downloads/Win10_22H2_x64.iso"
if [ -f "./downloads/Win10_22H2_x64.iso" ]; then
    echo "   ✅ 找到！"
    ls -lh "./downloads/Win10_22H2_x64.iso"
else
    echo "   ❌ 未找到"
fi

echo ""
echo "2. downloads/Win10_22H2_x64.iso"
if [ -f "downloads/Win10_22H2_x64.iso" ]; then
    echo "   ✅ 找到！"
    ls -lh "downloads/Win10_22H2_x64.iso"
else
    echo "   ❌ 未找到"
fi

echo ""
echo "3. 当前目录下的ISO文件："
find . -name "*.iso" -type f 2>/dev/null || echo "   未找到任何ISO文件"

echo ""
echo "4. downloads目录内容："
if [ -d "downloads" ]; then
    ls -la downloads/
elif [ -d "./downloads" ]; then
    ls -la ./downloads/
else
    echo "   downloads目录不存在"
fi

echo ""
echo "请确保："
echo "1. 创建downloads目录: mkdir -p downloads"
echo "2. 将Windows ISO文件放到: downloads/Win10_22H2_x64.iso"
echo "3. 文件名必须完全匹配: Win10_22H2_x64.iso"