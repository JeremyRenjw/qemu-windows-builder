# Remove proxy settings for future sessions

[Environment]::SetEnvironmentVariable('http_proxy', [NullString]::Value, 'Machine')
[Environment]::SetEnvironmentVariable('https_proxy', [NullString]::Value, 'Machine')
[Environment]::SetEnvironmentVariable('no_proxy', [NullString]::Value, 'Machine')
[Environment]::SetEnvironmentVariable('HTTP_PROXY', [NullString]::Value, 'Machine')
[Environment]::SetEnvironmentVariable('HTTPS_PROXY', [NullString]::Value, 'Machine')
[Environment]::SetEnvironmentVariable('NO_PROXY', [NullString]::Value, 'Machine')

# Remove CISCO Umbrella trust
Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -match 'Cisco Umbrella' } | Remove-Item

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 0
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Force