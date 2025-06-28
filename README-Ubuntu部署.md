# Ubuntu系统部署说明

## 目录结构要求

在Ubuntu系统中运行此脚本，需要确保以下目录结构：

```
项目根目录/
├── downloads/                    # 必须创建此目录
│   └── Win10_22H2_x64.iso      # Windows ISO文件（从Microsoft官网下载）
├── windows/                     # 将自动创建
│   ├── output-windows_10/       # 构建输出目录（自动生成）
│   ├── scripts/                 # 构建脚本目录（自动生成）
│   └── answer_files/            # 来自现有项目
├── quick-start.sh               # 一键启动脚本
├── build-with-local-iso.sh      # 主构建脚本
└── start-windows-vm.sh          # VM启动脚本（构建后生成）
```

## 部署步骤

### 1. 准备ISO文件
```bash
# 创建downloads目录
mkdir -p downloads

# 下载Windows 10 ISO文件到downloads目录
# ISO文件名必须是: Win10_22H2_x64.iso
```

### 2. 确保权限
```bash
chmod +x quick-start.sh
chmod +x build-with-local-iso.sh
```

### 3. 运行构建
```bash
./quick-start.sh
```

## 系统要求

- **操作系统**: Ubuntu 20.04+ LTS
- **CPU**: 支持虚拟化技术（Intel VT-x / AMD-V）
- **内存**: 32GB+ 推荐
- **磁盘**: 600GB+ 可用空间
- **网络**: 用于下载依赖包

## 输出结果

构建完成后将生成：

1. **VM镜像**: `windows/output-windows_10/windows_10`（QCOW2格式）
2. **启动脚本**: `start-windows-vm.sh`
3. **飞利浦交付包**: `philips-ecosystem-vm-delivery-YYYYMMDD.zip`

## 用户账户

- **管理员**: `philips` / `philips`
- **普通用户**: `user` / `vmuser123`

## 预装软件

- 开发环境: .NET 6/8, Java 17, Node.js, Python
- 开发工具: VS Code, IntelliJ IDEA, Git
- 数据库工具: MySQL Workbench, pgAdmin, MongoDB Compass
- 容器工具: Docker Desktop, Kubernetes CLI
- 云工具: AWS CLI, Azure CLI, Terraform
- 浏览器: Chrome, Firefox
- API工具: Postman, Insomnia
- 系统工具: 7-Zip, Process Explorer, PuTTY

## 故障排除

### ISO文件路径错误
确保ISO文件位于 `./downloads/Win10_22H2_x64.iso`

### 虚拟化未启用
在BIOS中启用Intel VT-x或AMD-V

### 磁盘空间不足
确保至少有600GB可用磁盘空间

### 权限问题
```bash
sudo usermod -a -G kvm $USER
sudo usermod -a -G libvirt $USER
# 重新登录或重启
```