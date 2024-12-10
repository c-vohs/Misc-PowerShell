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

$registryPath = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
$Name = "RestrictDriverInstallationToAdministrators"
$value = "0x0"

IF(!(Test-Path $registryPath)){
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Path $RegistryPath -Name $Name -Value $value -PropertyType DWORD -Force | Out-Null
    }
Else {
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
    }