function Get-LastReboot {
    [int] $DaysFromToday = 13
    [int] $MaxEvents = 9999

    try {
        $EventList = Get-WinEvent -FilterHashTable @{
            Logname = 'system'
            Id = '1074', '6008'
            StartTime = (Get-Date).AddDays(-$DaysFromToday)
        } -MaxEvents $MaxEvents -ErrorAction Stop

        foreach ($Event in $EventList) {
            if ($Event.Id -eq 1074) {
                [PSCustomObject]@{
                    TimeStamp    = $Event.TimeCreated
                    UserName     = $Event.Properties.value[6]
                    ShutdownType = $Event.Properties.value[4]
                }
            } 
            if ($Event.Id -eq 6008) {
                [PSCustomObject]@{
                    TimeStamp    = $Event.TimeCreated
                    UserName     = $null
                    ShutdownType = 'unexpected shutdown'
                }
            }
        } 
    }
    catch {
        return $null
     }
}

$Reboots = Get-LastReboot

$ScheduledTaskRun = Get-ScheduledTask -TaskName "custmb-RebootPrompt"

if ($null -ne $Reboots) {
    if ($Reboots[0].TimeStamp -lt )

    Write-Output "success"
} else {
    Write-Output "fail"
}