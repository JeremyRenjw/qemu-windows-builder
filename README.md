# QEMU Windows Builder

Automated Windows 10 Ecosystem Application VM image building using Packer and QEMU/KVM.

## Overview

This project automates the creation of Windows 10 22H2 virtual machine images optimized for QEMU/KVM environments with pre-installed ecosystem applications for enterprise development and deployment.

## Features

- ✅ Automated Windows 10 22H2 installation
- ✅ VirtIO drivers for optimal performance  
- ✅ Pre-configured enterprise user accounts
- ✅ Complete ecosystem application suite
- ✅ Ready-to-use development environment

## Quick Start

### Prerequisites

```bash
# Ubuntu/Debian
sudo apt install qemu-system packer

# Download Windows 10 ISO to downloads/ directory
```

### Build Ecosystem VM Image

```bash
# Complete ecosystem build with all applications
./build-ecosystem-vm-complete.sh

# Standard ecosystem build
./build-ecosystem-vm.sh

# Build with local ISO file
./build-with-local-iso.sh
```

## Main Build Scripts

| Script | Description | Features |
|--------|-------------|----------|
| `build-ecosystem-vm-complete.sh` | Complete ecosystem | All dev tools + applications |
| `build-with-local-iso.sh` | Local ISO build | Custom configuration |
| `build.sh` | Standard build | Basic Windows + essentials |

## Configuration

### Default Credentials
- **Admin**: `philips` / `philips`
- **User**: `user` / `vmuser123`

### VM Specifications
- **Memory**: 16GB
- **CPU**: 8-12 cores
- **Storage**: QCOW2 format
- **Network**: VirtIO-Net

## Architecture

```
├── windows/                    # Packer configurations
│   ├── win10_22h2.pkr.hcl     # Main template
│   ├── answer_files/          # Unattended install
│   ├── scripts/               # Provisioning scripts
│   └── drivers/               # VirtIO drivers
├── build-*.sh                # Build scripts
└── start-*.sh                # VM startup scripts
```

## Documentation

- [Ubuntu Deployment Guide](README-Ubuntu部署.md)
- [Build Instructions](README_BUILD.md)
- [Usage Guide](使用说明.md)

## Requirements

- **OS**: Ubuntu 20.04+ or similar Linux
- **Memory**: 32GB+ recommended
- **Storage**: 100GB+ free space
- **CPU**: Hardware virtualization support (VT-x/AMD-V)

## License

MIT License - See LICENSE file for details.

## Contributing

1. Fork the repository
2. Create feature branch
3. Submit pull request

## Support

For issues and questions, please open a GitHub issue.