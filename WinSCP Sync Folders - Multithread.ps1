<#
param (
    $sessionUrl = "sftp://user:password;fingerprint=ssh-rsa-xxxxxxxxxxx...@example.com/",
    $remotePath = "/media/nss/DATA/dmi/README/",
    $localPath = "D:\Data\Knox7\Incremental\DATA\dmi\README",
    $removeFiles = $False,
    $connections = 3
)
#>

$ErrorActionPreference = 'SilentlyContinue'

try {
    $assemblyFilePath = "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
    # Load WinSCP .NET assembly
    Add-Type -Path $assemblyFilePath
 
    # Setup session options

    #new
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol              = [WinSCP.Protocol]::Sftp
        HostName              = "172.24.4.192"
        UserName              = "root"
        Password              = "DMI2023!"
        SshHostKeyFingerprint = "ssh-ed25519 255 rc25iW/xboZftGTdiBxpIuix12bXMHf72GIC1dIXxow"
    }
    
    $remotePath = "/media/nss/DATA/"
    $localPath = "D:\Data\Knox7\Incremental\DATA\"
    $removeFiles = $True
    $connections = 6
    $logfile = "C:\Paxis\syncLog.log"

    #$sessionOptions = New-Object WinSCP.SessionOptions
    #$sessionOptions.ParseUrl($sessionUrl)
 
    $started = Get-Date
    "Start time: $started" >> $logfile
    # Plain variables cannot be modified in job threads
    $stats = @{
        count = 0
    }
 
    try {
        # Connect
        Write-Host "Connecting..."
        $session = New-Object WinSCP.Session
        $session.Open($sessionOptions)
        
        Write-Host "Comparing directories..."
        $differences =
        $session.CompareDirectories(
            [WinSCP.SynchronizationMode]::Local, $localPath, $remotePath, $removeFiles)
        if ($differences.Count -eq 0) {
            Write-Host "No changes found."   
        }
        else {
            if ($differences.Count -lt $connections) {
                $connections = $differences.Count;
            }
            $differenceEnumerator = $differences.GetEnumerator()
     
            for ($i = 1; $i -le $connections; $i++) {
                Start-ThreadJob -Name "Connection $i" -ArgumentList $i {
                    param ($no)
     
                    try {
                        Write-Host "Starting connection $no..."
     
                        $syncSession = New-Object WinSCP.Session
                        $syncSession.Open($using:sessionOptions)
     
                        while ($True) {
                            [System.Threading.Monitor]::Enter($using:differenceEnumerator)
                            try {
                                if (!($using:differenceEnumerator).MoveNext()) {
                                    break
                                }
     
                                $difference = ($using:differenceEnumerator).Current
                                ($using:stats).count++
                            }
                            finally {
                                [System.Threading.Monitor]::Exit($using:differenceEnumerator)
                            }
 
                            Write-Host "$difference in $no..."
                            $difference.Resolve($syncSession) | Out-Null
                        }
     
                        Write-Host "Connection $no done"
                    }
                    finally {
                        $syncSession.Dispose()
                    }
                } | Out-Null
            }
     
            Write-Host "Waiting for connections to complete..."
            Get-Job | Receive-Job -Wait -ErrorAction Stop
     
            Write-Host "Done"
        }
 
        $ended = Get-Date
        "End time: $ended" >> $logfile
        Write-Host "Took $(New-TimeSpan -Start $started -End $ended)"
        "Took $(New-TimeSpan -Start $started -End $ended)" >> $logfile
        Write-Host "Synchronized $($stats.count) differences"
        "Synchronized $($stats.count) differences" >> $logfile
    }
    finally {
        # Disconnect, clean up
        $session.Dispose()
    }
 
    exit 0
}
catch {
    Write-Host "Error: $($_.Exception.Message)"
    "Error: $($_.Exception.Message)" >> $logfile
    exit 1
}