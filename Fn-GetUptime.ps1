Function Get-SystemUptime
{
param($computer = "$env:computername")
$lastboot = [System.Management.ManagementDateTimeconverter]::ToDateTime(
    "$((gwmi  Win32_OperatingSystem -computername $computer).LastBootUpTime)")
    $uptime = (Get-Date) - $lastboot
    Write-Host "System Uptime for $computer is: " $uptime.days "days" $uptime.hours `
    "hours" $uptime.minutes "minutes" $uptime.seconds "seconds"
}
