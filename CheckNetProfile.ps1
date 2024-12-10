$logFile = "C:\Paxis\service-nlasvc-check.log"

Function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string] $message
    )

    $timestamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")

    Add-Content -path $logFile -Value "$timestamp - $message"
}

$profileStatus = (Get-NetConnectionProfile | ? IPv4Connectivity -eq "Internet").NetworkCategory

if (!($profileStatus -like "DomainAuthenticated")) {
    Write-Log -message "Profile status is: $profileStatus"

    for ($var = 1; $var -le 3; $var++) {
        $domainName = (Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem).Domain
        $pingResult = (Test-NetConnection $DomainName).PingSucceeded

        if ($pingResult) {
            Restart-Service -Name "nlasvc" -Force
            Write-Log -message "Restarting services"
        } else {
            Write-Log -message "Failed to reach domain controller, waiting 5 minutes. Failure $var of 3."
            Start-Sleep -s 300
        }
    }
}


