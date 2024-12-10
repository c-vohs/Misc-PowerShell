function Test-RegistryValue {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Path,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Value
    )

    try {
        Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
        return $true
    }
    catch {

        return $false

    }
}

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

$regPath2 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$Name2 = "SettingsPageVisibility"
$Value2 = "hide:backup;delivery-optimization;findmydevice;developers;signinoption-launchsecuritykeyenrollment;troubleshoot;windowsdefender;windowsinsider;windowsupdate;activation;recovery"

if(!(Test-RegistryValue -path $regPath2 -Value $Name2)){
    New-ItemProperty -Path $RegPath2 -Name $Name2 -Value $Value2 -PropertyType String -Force | Out-Null
}