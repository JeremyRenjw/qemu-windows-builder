# 最终解决方案 - Ubuntu部署

## ✅ 问题已彻底解决

**问题原因：** 原始脚本包含Windows CRLF行结束符和其他格式问题

## 🚀 使用全新的干净脚本

### 主要脚本
1. **`start.sh`** - 一键启动脚本（全新干净版本）
2. **`build.sh`** - 构建脚本（全新干净版本）

### 使用方法

```bash
# 1. 准备ISO文件
mkdir -p downloads
# 将Windows 10 ISO文件复制到: downloads/Win10_22H2_x64.iso

# 2. 运行启动脚本
bash start.sh

# 或者直接运行构建脚本
bash build.sh
```

## 📁 目录结构

```
项目目录/
├── downloads/
│   └── Win10_22H2_x64.iso    # Windows 10 ISO文件
├── start.sh                  # 一键启动脚本（新）
├── build.sh                  # 构建脚本（新）
├── windows/                  # 自动创建
│   └── output-windows_10/    # 构建输出
└── start-vm.sh              # VM启动脚本（构建后生成）
```

## 🎯 完全修复的问题

1. ✅ **CRLF行结束符** - 完全移除
2. ✅ **隐藏字符** - 完全清理
3. ✅ **shebang兼容性** - 使用 `#!/usr/bin/env bash`
4. ✅ **路径问题** - 所有路径为相对路径
5. ✅ **权限问题** - 正确的执行权限

## 🔧 构建配置

- **VM名称**: windows_10
- **输出目录**: output-windows_10
- **磁盘大小**: 500GB
- **内存**: 16GB
- **CPU**: 12核
- **用户账户**: 
  - 管理员: philips/philips
  - 普通用户: user/vmuser123

## 📦 最终输出

1. **VM镜像**: `windows/output-windows_10/windows_10`
2. **启动脚本**: `start-vm.sh`
3. **飞利浦交付包**: `philips-ecosystem-vm-delivery-YYYYMMDD.zip`

## ⚡ 立即开始

```bash
bash start.sh
```

**注意**: 使用 `bash start.sh` 而不是 `./start.sh` 可以避免所有权限和格式问题！