$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\DNS\Parameters"
$Name = "TcpReceivePacketSize"
$value = "0xFF00"

IF(!(Test-Path $registryPath)){
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Path $RegistryPath -Name $Name -Value $value -PropertyType DWORD -Force | Out-Null
    }
Else {
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
    }

IF(Test-Path $registryPath){
    Restart-Service dns
    }
