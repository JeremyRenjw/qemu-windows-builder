packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

source "qemu" "win10_simple" {
  accelerator      = "kvm"
  boot_wait        = "3s"
  boot_command     = ["<enter>"]
  communicator     = "winrm"
  cpus             = "10"
  disk_compression = true
  disk_interface   = "virtio"
  disk_size        = "40960"
  floppy_files     = [
    "./answer_files/10/Autounattend.xml",
    "./scripts/1-firstlogin.bat",
    "./scripts/2-fixnetwork.ps1",
    "./scripts/50-enable-winrm.ps1",
    "./scripts/simple-setup.bat",
    "./answer_files/Firstboot/Firstboot-Autounattend.xml",
    "./drivers/"
  ]
  format           = "qcow2"
  headless         = false
  iso_checksum     = "sha256:8eb1743d1057791949b2bdc78390e48828a2be92780402daccd1a57326d70709"
  iso_url          = "file:///Users/renjiawei/Library/Containers/com.tencent.WeWorkMac/Data/Documents/Profiles/96B95168ABBD72A62C02E42D3B83604F/Caches/Files/2025-06/331b0df6432332ce5bc8c5a53ebdc64f/windows 1/downloads/Win10_22H2_x64.iso"
  memory           = "16384"
  net_device       = "virtio-net"
  vnc_bind_address = "127.0.0.1"
  vga              = "qxl"
  efi_boot         = true
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
  shutdown_command = "%WINDIR%/system32/sysprep/sysprep.exe /generalize /oobe /shutdown /unattend:C:/Windows/Temp/Autounattend.xml"
  winrm_insecure   = true
  winrm_password   = "philips"
  winrm_timeout    = "30m"
  winrm_use_ssl    = true
  winrm_username   = "philips"
  output_directory = "output-windows_10"
}

build {
  sources = ["source.qemu.win10_simple"]

  # 只执行基础设置
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/simple-setup.bat"]
  }

  # 系统重启
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
    restart_timeout = "15m"
  }

  # 磁盘清理
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/90-compact.bat"]
  }
}
