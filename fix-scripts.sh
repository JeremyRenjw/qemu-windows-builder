#!/bin/bash
echo "修复所有脚本的格式问题..."

# 修复函数
fix_script() {
    local file="$1"
    echo "修复: $file"
    
    # 移除CRLF和其他Windows格式问题
    if [ -f "$file" ]; then
        sed -i 's/\r$//' "$file" 2>/dev/null || tr -d '\r' < "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
        chmod +x "$file"
        echo "✓ $file 已修复"
    else
        echo "× $file 不存在"
    fi
}

# 修复所有shell脚本
for script in *.sh; do
    if [ -f "$script" ]; then
        fix_script "$script"
    fi
done

echo ""
echo "格式修复完成！"
echo ""
echo "现在可以运行："
echo "  bash run-vm-build.sh     # 新的干净脚本"
echo "  bash start.sh            # 或者这个"
echo "  bash build.sh            # 直接运行构建"