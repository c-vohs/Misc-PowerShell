# Load WinSCP .NET assembly
Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
 
# Session.FileTransferred event handler
 
function FileTransferred {
    param($e)
 
    if ($e.Error -eq $Null) {
        Write-Host "Upload of $($e.FileName) succeeded"
    }
    else {
        Write-Host "Upload of $($e.FileName) failed: $($e.Error)"
    }
 
    if ($e.Chmod -ne $Null) {
        if ($e.Chmod.Error -eq $Null) {
            Write-Host "Permissions of $($e.Chmod.FileName) set to $($e.Chmod.FilePermissions)"
        }
        else {
            Write-Host "Setting permissions of $($e.Chmod.FileName) failed: $($e.Chmod.Error)"
        }
 
    }
    else {
        Write-Host "Permissions of $($e.Destination) kept with their defaults"
    }
 
    if ($e.Touch -ne $Null) {
        if ($e.Touch.Error -eq $Null) {
            Write-Host "Timestamp of $($e.Touch.FileName) set to $($e.Touch.LastWriteTime)" 
        }
        else {
            Write-Host "Setting timestamp of $($e.Touch.FileName) failed: $($e.Touch.Error)"
        }
 
    }
    else {
        # This should never happen during "local to remote" synchronization
        Write-Host "Timestamp of $($e.Destination) kept with its default (current time)"
    }
}
 
# Main script
 
try {
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol              = [WinSCP.Protocol]::Sftp
        HostName              = "172.24.4.192"
        UserName              = "root"
        Password              = "DMI2023!"
        SshHostKeyFingerprint = "ssh-ed25519 255 rc25iW/xboZftGTdiBxpIuix12bXMHf72GIC1dIXxow"
    }
 
    $session = New-Object WinSCP.Session
    try {
        # Will continuously report progress of synchronization
        $session.add_FileTransferred( { FileTransferred($_) } )
 
        # Connect
        $session.Open($sessionOptions)
 
        # Synchronize files
        $synchronizationResult = $session.SynchronizeDirectories(
            [WinSCP.SynchronizationMode]::Local, "D:\Data\Knox7\Incremental\README\", "/media/nss/DATA/dmi/README", $True) #probably refers to removeFiles option. mirror defaults to false
 
        # Throw on any error
        $synchronizationResult.Check()
    }
    finally {
        # Disconnect, clean up
        $session.Dispose()
    }
 
    #exit 0
}
catch {
    Write-Host "Error: $($_.Exception.Message)"
    #exit 1
}






    #-----------------------------------------------------------------------------------------------------
<#
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol              = [WinSCP.Protocol]::Sftp
        HostName              = "example.com"
        UserName              = "user"
        Password              = "mypassword"
        #SshHostKeyFingerprint = "ssh-rsa 2048 xxxxxxxxxxx..."
        SshHostKeyFingerprint = "ssh-rsa 2048 xxxxxxxxxxx..."
    }
    #>