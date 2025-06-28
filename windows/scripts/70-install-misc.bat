REM Install QEMU Guest Agent
curl -O --ssl-no-revoke -L https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-qemu-ga/qemu-ga-x86_64.msi
start /wait msiexec /qb /i qemu-ga-x86_64.msi

REM Install virtio drivers (excluding network, as this breaks the WinRM connection)
curl -O --ssl-no-revoke -L https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win-gt-x64.msi
start /wait msiexec /qb /i virtio-win-gt-x64.msi ADDLOCAL=FE_balloon_driver,FE_pvpanic_driver,FE_fwcfg_driver,FE_qemupciserial_driver,FE_vioinput_driver,FE_viorng_driver,FE_vioscsi_driver,FE_vioserial_driver,FE_viostore_driver,FE_viofs_driver,FE_viogpudo_driver,FE_viomem_driver

REM Install NVidia drivers
curl -o nvidia-driver.exe --ssl-no-revoke -L https://us.download.nvidia.com/Windows/Quadro_Certified/573.06/573.06-quadro-rtx-desktop-notebook-win10-win11-64bit-international-dch-whql.exe
start /wait nvidia-driver.exe -s

REM Install sdelete in prep for zeroing unused space
choco install sdelete -y

REM Install other softwares here

REM Create file indicating system is not yet sysprepped
REM This is deleted using the Firstboot-Autounattend file
copy C:\windows\system32\cmd.exe C:\not-yet-finished