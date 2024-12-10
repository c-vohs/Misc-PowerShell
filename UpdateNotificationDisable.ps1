$registryPath = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"
$Name = "UpdateNotificationLevel"
$value = "0x1"

IF(!(Test-Path $registryPath)){
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Path $RegistryPath -Name $Name -Value $value -PropertyType DWORD -Force | Out-Null
    }
Else {
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
    }
