# Windows Qemu (KVM/Libvirt) Packer Template

> These templates are based on unlicensed work published in https://github.com/proactivelabs/packer-windows

Builds Windows 10 (22h2) windows image suitable for consumption in QEMU and libvirt.

## Intent

Images have the following:

* Access mechanisms:
  * winrm and rdp enabled by default
  * username / password is "philips/philips"
* Installed packages
  * Chocolatey
  * QEMU guest additions
  * VirtIO drivers

## Prerequisites

* QEMU 8.1.5 or above  (`sudo apt install qemu-system`)
* Packer 1.9.4 or above (https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli)

## Building

```bash
# We need to initialise plugins first
# any file will do, as they all have the same plugin
packer init win10_22h2.pkr.hcl 

# Build
packer build win10_22h2.pkr.hcl 

# Alternative: Build with UI support, useful for debugging
packer build -var=headless=false win10_22h2.pkr.hcl

# Build with a different image
# Ensure to specify a new checksum!
packer build -var=iso_checksum=sha256:xxx -var=iso_url=http://foo.com win10_22h2.pkr.hcl
```

## Building faster

* Comment out the `sdelete` command in `scripts/90-compact.bat`
  * This will save about 10 minutes on build time

## Activating

To activate this VM on the Philips network using the Philips KMS servers:

### First configure the Philips network timeserver

```CMD
w32tm /config /update /manualpeerlist:"ntp1.emi.philips.com,ntp2.emi.philips.com"
```

### Activate to Philips KMS server

```CMD
slmgr /skms 130.139.56.153
```

_Note: If this KMS doesn't work in your region, use the following command to uncover all KMS servers on the network_

```cmd
nslookup -type=srv _vlmcs._tcp
```

## Customisations

### General customisations

Most of the time, you want to edit `scripts/70-install-misc.bat`

### Toggling sysprep

These images will sysprep on first boot, this can be disabled by specifying the following:

```bash
packer build -var=shutdown_command="shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
```



### Checking host prepared-ness

A file based lock is implemented, which creates the text
file `C:/not-yet-finished` in `70-install-misc.bat`, and is
deleted once the `Firstboot-Autounattend.xml` has finished
running (i.e. post sysprep). A simple check has been implemented
in the `Makefile` to check for this condition.

It is recommended to check for `C:/not-yet-finished` file,
if it is not present, the host has finished sysprepping
and is ready to be used (although depending on time, you *could*
hit a situation where sysprep has run the specialise phase,
but has not yet done one final reboot.)
