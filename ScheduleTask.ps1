$powershell_code_to_run = {
    # ALL CODE TO RUN GOES HERE
    $source = "PowerShellScript"
    $log_sources = (Get-EventLog -LogName "Application").Source | Select-Object -Unique
    if($log_sources -notcontains $source) {
        New-EventLog -LogName Application -Source $source
    }
    Write-EventLog -LogName Application -Source $source -EntryType Error -EventId 1337 -Message "This is a message."
    # AND END HERE.
}

# Base64 encode code to run.
$encodedCommand = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($powershell_code_to_run.ToString()))

# Action, using EncodedCommand removes the need to escape quotes etc.
$action = New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument "-WindowStyle Hidden -EncodedCommand $encodedCommand"

# Task trigger                                  Start :00 next hour                             Repeat every 30 minutes, repeat forever
$triggers = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(60 - (Get-Date).Minute)) -RepetitionInterval (New-TimeSpan -Minutes 30)
#                                                Start 1 minute from now          Repeat every 30 minutes, repeat forever
# $triggers = New-ScheduledTaskTrigger -Once -At ([datetime]::Now.AddMinutes(1)) -RepetitionInterval (New-TimeSpan -Minutes 30)

# Settings for the task.
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Other settings
$principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId "LOCALSERVICE" -LogonType ServiceAccount

# Name of the task
$taskName = 'Some task name'

# The actual task object
$task = New-ScheduledTask -Action $action -Settings $settings -Trigger $triggers -Description 'Check a folder if there has been any changes in the last 30 minutes.' -Principal $principal

# Remove the old task
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

#  Create new
Register-ScheduledTask -TaskName $taskName -InputObject $task -TaskPath '\'