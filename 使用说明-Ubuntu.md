# Ubuntu系统错误解决方案

## 错误："无法执行：找不到需要的文件"

这个错误通常是以下原因：

### 解决方案1：使用bash直接运行
```bash
bash quick-start.sh
```

### 解决方案2：检查shebang路径
```bash
# 检查bash位置
which bash

# 如果bash在不同位置，修改第一行
head -1 quick-start.sh
```

### 解决方案3：使用通用shebang
使用 `#!/usr/bin/env bash` 代替 `#!/bin/bash`

### 解决方案4：检查文件完整性 && 增加
```bash
# 测试脚本是否完整
./ubuntu-test.sh

# 或直接运行
bash ubuntu-test.sh
```

## 推荐运行方式（Ubuntu）

### 方式1：直接bash运行（推荐）
```bash
cd "windows 1"
bash quick-start.sh
```

### 方式2：创建downloads目录
```bash
mkdir -p downloads
# 复制Windows ISO到 downloads/Win10_22H2_x64.iso
```

### 方式3：分步执行
```bash
# 1. 测试环境
bash ubuntu-test.sh

# 2. 运行构建
bash quick-start.sh

# 3. 如果还有问题，直接运行主脚本
bash build-with-local-iso.sh
```

## 系统要求确认

```bash
# 检查虚拟化支持
egrep -c '(vmx|svm)' /proc/cpuinfo

# 检查磁盘空间（需要600GB+）
df -h .

# 检查内存（建议32GB+）
free -h

# 安装必要工具
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system
```

## 如果问题持续

使用以下命令获取详细错误信息：
```bash
strace -e trace=execve ./quick-start.sh 2>&1 | head -20
```

或查看系统日志：
```bash
dmesg | tail -20
```