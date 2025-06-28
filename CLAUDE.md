# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Packer-based Windows 10 image building project that creates virtualized Windows environments for QEMU/KVM/libvirt. The project builds enterprise Windows 10 22H2 images with pre-configured software and drivers for virtualization environments.

## Key Commands

### Building Images
```bash
# Initialize Packer plugins (required first time)
packer init win10_22h2.pkr.hcl

# Build the standard image
packer build win10_22h2.pkr.hcl

# Build with UI for debugging
packer build -var=headless=false win10_22h2.pkr.hcl

# Build with custom ISO
packer build -var=iso_checksum=sha256:xxx -var=iso_url=http://foo.com win10_22h2.pkr.hcl

# Build without sysprep (for testing)
packer build -var=shutdown_command="shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
```

### Prerequisites
- QEMU 8.1.5+ (`sudo apt install qemu-system`)
- Packer 1.9.4+ (from HashiCorp)

## Architecture

### Core Configuration Files
- `win10_22h2.pkr.hcl` - Main Packer template with QEMU builder configuration
- `answer_files/10/Autounattend.xml` - Windows unattended installation configuration
- `answer_files/Firstboot/Firstboot-Autounattend.xml` - Post-sysprep configuration

### Provisioning Scripts (executed in order)
1. `scripts/1-firstlogin.bat` - Initial login setup
2. `scripts/2-fixnetwork.ps1` - Network configuration fixes
3. `scripts/50-enable-winrm.ps1` - WinRM/PowerShell remoting setup
4. `scripts/70-install-misc.bat` - Main software installation (QEMU guest agent, VirtIO drivers, NVIDIA drivers)
5. `scripts/80-compile-dotnet-assemblies.bat` - .NET optimization
6. `scripts/89-remove-philips-network.ps1` - Network cleanup
7. `scripts/90-compact.bat` - Disk space optimization with sdelete

### Build Process Flow
1. **Boot Phase**: UEFI boot with Windows PE using Autounattend.xml
2. **Installation Phase**: Automated Windows installation with partitioning
3. **Provisioning Phase**: Sequential script execution via WinRM
4. **Sysprep Phase**: System preparation for deployment (default behavior)
5. **Output**: QCOW2 image in `output-{vm_name}/` directory

### Key Variables
- `iso_url` - Windows ISO location (default: localhost:10086)
- `iso_checksum` - SHA256 verification hash
- `headless` - UI visibility (default: true)
- `vm_name` - Output directory name (default: "windows_10")
- `memory_size` - RAM allocation (default: 8192MB)
- `cpus` - CPU count (default: 8)
- `disk_size` - Disk size in MB (default: 61440)

### Default Credentials
- Username: `philips`
- Password: `philips`
- WinRM enabled on ports 5985 (HTTP) and 5986 (HTTPS)

### Build Optimization
- Comment out sdelete in `scripts/90-compact.bat` to save ~10 minutes build time
- Images compress from ~12-15GB to ~8-9GB with sdelete enabled

### System State Management
- Build creates `C:/not-yet-finished` file during provisioning
- File removed after sysprep completion indicates system ready
- Useful for automation to check VM readiness

### Drivers and Software
- VirtIO drivers for optimal virtualization performance
- QEMU guest agent for host-guest communication
- NVIDIA graphics drivers (Quadro certified)
- Chocolatey package manager
- Windows activation configured for Philips KMS servers