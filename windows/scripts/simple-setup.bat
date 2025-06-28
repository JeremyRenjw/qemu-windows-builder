@echo off
echo [INFO] Starting basic system configuration...

REM Create user accounts
echo [INFO] Creating admin account philips...
net user philips philips /add /comment:"System Administrator" 2>nul || echo [INFO] User philips already exists
net localgroup "Administrators" philips /add 2>nul || echo [INFO] philips already in admin group

echo [INFO] Creating normal user account user...
net user user vmuser123 /add /comment:"Normal User"
net localgroup "Users" user /add

REM Basic system configuration
echo [INFO] Configuring system settings...
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

REM Disable some services for better performance
echo [INFO] Optimizing system services...
sc config "Themes" start= disabled
sc config "Spooler" start= demand

echo [SUCCESS] Basic system configuration completed!
