# 生态系统应用VM镜像构建指南

本项目基于PDF文档《Build Ecosystem Application VM Image》要求，提供了完整的Windows 10 Enterprise生态系统应用虚拟机镜像构建解决方案。

## 🎯 项目概述

- **目标系统**: Windows 10 Enterprise 22H2
- **虚拟化平台**: QEMU/KVM on Ubuntu 24.04.2 LTS
- **构建工具**: Packer 1.12.0
- **磁盘大小**: 500GB (根据用户要求)
- **内存配置**: 16GB (增强配置)
- **CPU配置**: 12核 (增强配置)

## 📋 系统要求

### 硬件要求
- CPU: 支持Intel VT-x或AMD-V硬件虚拟化
- 内存: 至少32GB RAM (推荐)
- 存储: 至少600GB可用磁盘空间
- 网络: 稳定的互联网连接

### 软件要求
- Ubuntu 24.04.2 LTS
- 已启用BIOS虚拟化功能
- 具备sudo权限的用户账户

## 🚀 快速开始

### 方法一：一键构建 (推荐)

```bash
# 1. 赋予执行权限
chmod +x quick-build.sh

# 2. 运行快速构建
./quick-build.sh
```

### 方法二：完整构建

```bash
# 1. 赋予执行权限
chmod +x build-ecosystem-vm-complete.sh

# 2. 运行完整构建
./build-ecosystem-vm-complete.sh
```

## ⚙️ 构建配置

### 需要修改的配置

在运行构建脚本之前，请检查以下配置：

1. **ISO文件配置** (必须修改)
   ```bash
   # 在build-ecosystem-vm-complete.sh中修改
   ISO_URL="http://your-server/Windows10_Enterprise_22H2.iso"
   ISO_CHECKSUM="sha256:your_actual_checksum"
   ```

2. **Windows产品密钥** (可选)
   ```xml
   <!-- 在 windows/answer_files/10/Autounattend.xml 中修改 -->
   <ProductKey>
       <Key>YOUR-WINDOWS-PRODUCT-KEY</Key>
   </ProductKey>
   ```

### 默认用户账户

根据PDF文档要求，VM包含两个用户账户：

- **管理员账户**: `philips` / `philips`
- **普通用户**: `user` / `vmuser123`

## 📁 项目结构

```
windows/
├── answer_files/          # Windows无人值守安装配置
│   ├── 10/
│   │   └── Autounattend.xml
│   └── Firstboot/
│       └── Firstboot-Autounattend.xml
├── drivers/               # VirtIO虚拟化驱动
│   └── amd64/w10/
├── scripts/               # 自动化配置脚本
│   ├── 1-firstlogin.bat
│   ├── 2-fixnetwork.ps1
│   ├── 50-enable-winrm.ps1
│   ├── 70-install-misc.bat
│   ├── 75-install-ecosystem-tools.bat  # 新增
│   ├── 80-compile-dotnet-assemblies.bat
│   ├── 89-remove-philips-network.ps1
│   └── 90-compact.bat
└── win10_22h2.pkr.hcl     # Packer构建配置
```

## 🛠️ 构建流程

构建过程包含以下步骤：

1. **环境检查** - CPU虚拟化、磁盘空间
2. **软件安装** - Packer 1.12.0、KVM工具
3. **配置准备** - Packer配置文件
4. **镜像构建** - 自动化安装和配置
5. **后处理** - 创建启动脚本

### 构建时间预估

- **完整构建**: 2-4小时 (取决于网络速度和硬件性能)
- **仅软件安装**: 30-60分钟
- **磁盘压缩**: 20-30分钟

## 📦 已安装软件

### 开发环境
- **.NET SDK**: 6.0, 8.0
- **Java**: OpenJDK 17, Maven, Gradle
- **Node.js**: 最新LTS + Yarn
- **Python**: 最新版本

### 开发工具
- **IDE**: VS Code, IntelliJ IDEA Community
- **编辑器**: Notepad++
- **版本控制**: Git, GitHub Desktop

### 数据库工具
- **MySQL**: MySQL Workbench
- **PostgreSQL**: pgAdmin 4
- **MongoDB**: MongoDB Compass

### 容器和DevOps
- **容器**: Docker Desktop, Kubernetes CLI
- **基础设施**: Terraform
- **云工具**: AWS CLI, Azure CLI

### 浏览器和工具
- **浏览器**: Google Chrome, Firefox
- **API测试**: Postman, Insomnia
- **系统工具**: 7-Zip, Process Explorer, PuTTY

## 🖥️ 虚拟机使用

### 启动虚拟机

```bash
# 构建完成后，使用生成的启动脚本
./start-ecosystem-vm.sh
```

### 远程连接

- **RDP连接**: `localhost:3389`
- **WinRM连接**: `localhost:5985`

### 网络配置

虚拟机配置了端口转发：
- RDP: 主机3389 → 虚拟机3389
- WinRM: 主机5985 → 虚拟机5985

## 🔧 故障排除

### 常见问题

1. **CPU虚拟化未启用**
   ```bash
   # 检查虚拟化支持
   egrep -c '(vmx|svm)' /proc/cpuinfo
   # 如果输出为0，需要在BIOS中启用VT-x/AMD-V
   ```

2. **VNC连接失败**
   - 这是常见问题，通常重新运行构建命令即可解决
   - 或使用调试模式：`packer build -var=headless=false win10_22h2.pkr.hcl`

3. **磁盘空间不足**
   ```bash
   # 检查可用空间
   df -h .
   # 清理系统缓存
   sudo apt clean
   ```

4. **权限问题**
   ```bash
   # 将用户添加到libvirt组
   sudo usermod -a -G libvirt $USER
   # 重新登录或重启系统
   ```

### 调试模式

如果构建失败，可以启用调试模式：

```bash
cd windows
packer build -var=headless=false win10_22h2.pkr.hcl
```

## 📝 输出和交付

### 构建输出

构建完成后，会生成以下文件：

```
output-ecosystem-application-vm/
├── packer-ecosystem-application-vm    # 主要VM镜像文件
├── efivars.fd                         # EFI变量文件
└── OVMF_CODE_4M.fd                    # UEFI固件文件
```

### 交付要求

根据PDF文档要求：

1. 将 `output-ecosystem-application-vm` 目录打包成ZIP文件
2. 提交给Philips团队
3. 确保包含所有必要的文件和配置

```bash
# 打包命令示例
cd windows
zip -r ecosystem-vm-$(date +%Y%m%d).zip output-ecosystem-application-vm/
```

## 📞 支持和反馈

如果在构建过程中遇到问题：

1. 查看构建日志文件 (`build-YYYYMMDD-HHMMSS.log`)
2. 检查系统要求是否满足
3. 参考故障排除部分
4. 确保网络连接稳定

## 📄 许可和致谢

本项目基于原始Packer Windows模板开发，感谢：
- [ProactiveLabs Packer Windows](https://github.com/proactivelabs/packer-windows)
- HashiCorp Packer团队
- QEMU/KVM开发团队

---

**注意**: 请确保您拥有有效的Windows 10 Enterprise许可证，并遵守相关软件的许可协议。