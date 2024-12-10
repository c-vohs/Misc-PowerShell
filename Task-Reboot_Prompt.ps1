Set-ExecutionPolicy Bypass -Scope Process

function New-CustmbRebootPromptTask {
    $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-executionpolicy bypass -NoProfile -WindowStyle Hidden -command "& {C:\Paxis\Task-Reboot_Prompt.ps1}"'
    $trigger = New-ScheduledTaskTrigger -Once -At "00:00" 
    $User = "NT AUTHORITY\SYSTEM"
    $Settings = New-ScheduledTaskSettingsSet -Hidden -StartWhenAvailable
    
    Register-ScheduledTask -Action $action -Trigger $trigger -User $User -Settings $Settings -RunLevel Highest -TaskName "custmb-RebootPrompt" -Description "Prompts user to reboot" 
}

function Set-CustmbRebootPromptTask {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$delay
    )

    $currentTime = Get-date
    $newTime = switch ($delay) {
        'Exited' {$currentTime.AddHours(2)}
        '30m_delay' {$currentTime.AddMinutes(30)}
        '2h_delay' {$currentTime.AddHours(2)}
        '24h_delay' {$currentTime.AddDays(1)}
    }
    $trigger = New-ScheduledTaskTrigger -once -at $newTime

    Set-ScheduledTask -TaskName "custmb-RebootPrompt" -Trigger $trigger

}

$responsePath = "C:\Paxis\RebootResponse.txt"
$scriptblock = { C:\Paxis\custmb.exe header="Paxis Maintenance" Position=center Theme=win10 icon="C:\Paxis\pax_icon_yellow.ico" message="Your machine is currently pending a reboot. You may delay this or reboot now.\r\nMachine will automatically reboot in 15 minutes if no response chosen.\r\nPlease contact us at 865-588-9823 with questions or concerns." OnTop=1 button="Remind Me 24h|24h_delay" button="Remind Me 2h|2h_delay" button="Remind Me 30m|30m_delay" button="Reboot Now|reboot|900" | out-file "C:\Paxis\RebootResponse.txt" }

Invoke-AsCurrentUser -ScriptBlock $scriptblock -UseWindowsPowerShell

if (Test-Path -Path $responsePath) {
    $rebootResponse = get-content $responsePath -ErrorAction SilentlyContinue
} else {
    $rebootResponse = "2h"
}

if ($null -ne $rebootResponse) {
    write-host $rebootResponse
    
    if ($rebootResponse -eq "reboot") {
        remove-item -Path $responsePath
        Start-Process shutdown.exe -argumentlist "-r -f -t 30"
    } else {
        remove-item -Path $responsePath

        if (!(Get-ScheduledTask | ? TaskName -eq "custmb-RebootPrompt")) {
            Write-Output "Task not found"

            New-CustmbRebootPromptTask
        }

        Set-CustmbRebootPromptTask $rebootResponse
    }
}
