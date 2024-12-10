$UserKey = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI' -Name LastLoggedOnUserSID).LastLoggedOnUserSID
$Path = "HKU:\$UserKey\Network"

if (!(Test-Path -Path HKU:\)) {
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
}

$MappedDrives = get-childitem -path $Path -Recurse | Get-ItemProperty | Select-Object pschildname, remotepath | % { "{0,-10}     {1,-60}`r`n" -f $_.PSChildName, $_.RemotePath }