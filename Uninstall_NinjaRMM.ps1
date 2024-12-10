$UninstallString = (Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\NinjaRMMAgent*).UninstallString

if (!$UninstallString) { exit }
Start-Process -FilePath $UninstallString -ArgumentList "--mode", "unattended"

sleep -seconds 60

$Uninstall2 = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "NinjaRMMAgent" } | Select-Object -Property UninstallString | foreach { $_.UninstallString }

$Uninstall3 = $Uninstall2 -Replace "MsiExec.exe " , ""

Start-Process -FilePath MSIExec.exe -ArgumentList $Uninstall3, "/quiet", "/passive"