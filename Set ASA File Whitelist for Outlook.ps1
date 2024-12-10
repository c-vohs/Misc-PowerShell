$UserKey = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI' -Name LastLoggedOnUserSID).LastLoggedOnUserSID
$Path = "HKU:\$UserKey\SOFTWARE\Microsoft\Office"
$Path2 = "Outlook\Security"

if (!(Test-Path -Path HKU:\)) {
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
}

if (Test-Path -Path "$Path\16.0") {
    Write-Output "16.0"
    $Path2 = "$Path\16.0"
} else {
    if (Test-Path -Path "$Path\15.0") {
        Write-Output "15.0"
        $Path2 = "$Path\15.0"
    }
    else {
        if (Test-Path -Path "$Path\14.0") {
            Write-Output "14.0"
            $Path2 = "$Path\14.0"
        }
        else {
            if (Test-Path -Path "$Path\12.0") {
                Write-Output "12.0"
                $Path2 = "$Path\12.0"
            }
        }
    }
}


if (!(Test-Path -Path "$Path2\Outlook")){
    New-Item -Path "$Path2\Outlook"
    New-Item -Path "$Path2\Outlook\Security"
} Else { 
    if (!(Test-Path -Path "$Path2\Outlook\Security")) {
        New-Item -Path "$Path2\Outlook\Security"
    }

}

$PathFinal = "$Path2\Outlook\Security"
Set-ItemProperty -Path $PathFinal -Name "Level1Remove" -Type "String" -Value ".asa"