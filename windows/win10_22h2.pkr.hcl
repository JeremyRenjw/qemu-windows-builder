packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "accelerator" {
  type    = string
  default = "kvm"
}

variable "autounattend" {
  type    = string
  default = "./answer_files/10/Autounattend.xml"
}

variable "cpus" {
  type    = string
  default = "8"
}

variable "disk_size" {
  type    = string
  default = "61440"
}

variable "headless" {
  type    = string
  default = "true"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:2654d20e2f7cdc5949c0dcf1271892ce97c9e5482624459ff377cb5f742b41c7"
}

variable "iso_url" {
  type    = string
  default = "http://localhost:10086/Windows10_enterprise_22H2_KMS.iso"
}

variable "memory_size" {
  type    = string
  default = "8192"
}

variable "shutdown_command" {
  type    = string
  default = "%WINDIR%/system32/sysprep/sysprep.exe /generalize /oobe /shutdown /unattend:C:/Windows/Temp/Autounattend.xml"
}

variable "vm_name" {
  type    = string
  default = "windows_10"
}

source "qemu" "win10_22h2" {
  accelerator      = "${var.accelerator}"
  boot_wait        = "-1s"
  boot_command     = ["f u n w i t h p a c k e r"]
  communicator     = "winrm"
  cpus             = "${var.cpus}"
  disk_compression = "true"
  disk_interface   = "virtio"
  disk_size        = "${var.disk_size}"
  floppy_files     = ["${var.autounattend}", "./scripts/1-firstlogin.bat", "./scripts/2-fixnetwork.ps1", "./scripts/70-install-misc.bat", "./scripts/50-enable-winrm.ps1", "./answer_files/Firstboot/Firstboot-Autounattend.xml", "./drivers/"]
  format           = "qcow2"
  headless         = "${var.headless}"
  iso_checksum     = "${var.iso_checksum}"
  iso_url          = "${var.iso_url}"
  memory           = "${var.memory_size}"
  net_device       = "virtio-net"
  vnc_bind_address = "0.0.0.0"
  vga              = "qxl"
  efi_boot         = true
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
  shutdown_command = "${var.shutdown_command}"
  winrm_insecure   = "true"
  winrm_password   = "philips"
  winrm_timeout    = "30m"
  winrm_use_ssl    = "true"
  winrm_username   = "philips"
  output_directory = "output-${var.vm_name}"
}

build {
  sources = ["source.qemu.win10_22h2"]

  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/70-install-misc.bat", "./scripts/80-compile-dotnet-assemblies.bat"]
  }

  # Reboot after doing our first stages
  # This is to give the windows-update provisioner a chance
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
  }

  provisioner "powershell" {
    script            = "./scripts/89-remove-philips-network.ps1"
    elevated_user     = "philips"
    elevated_password = "philips"
  }

  # Without this step, your images will be ~12-15GB
  # With this step, roughly ~8-9GB
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/90-compact.bat"]
  }
}
