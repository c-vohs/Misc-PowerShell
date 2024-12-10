$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -command "& {C:\temp\script.ps1}"'

$trigger = New-ScheduledTaskTrigger -Once -At "00:00"

$User = "NT AUTHORITY\SYSTEM"

$Settings = New-ScheduledTaskSettingsSet -Hidden

Register-ScheduledTask -Action $action -Trigger $trigger -User $User -Settings $Settings -RunLevel Highest -TaskName "RunScript" -Description "This is a test" 



Start-ScheduledTask -TaskName "RunScript"