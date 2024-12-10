$tlsKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
$tlsValue = 'DisabledByDefault'
$enabledValue = 'Enabled'
$tlsPath1 = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2'
$tlsPath2 = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'
$valueExists = 'False'
$enabledExists = 'False'

$keyExists = Test-Path $tlsKey
$path1Exists = Test-Path $tlsPath1
$path2Exists = Test-Path $tlsPath2

if ($keyExists) {
    try {
        Get-ItemProperty -Path $tlsKey | Select-Object -ExpandProperty $tlsValue -ErrorAction Stop | Out-Null
        $valueExists = $true
    }
    catch {
        $valueExists =  $false
    }
} else {
    $valueExists = "False"
}
if ($keyExists) {
    try {
        Get-ItemProperty -Path $tlsKey | Select-Object -ExpandProperty $enabledValue -ErrorAction Stop | Out-Null
        $enabledExists = $true
    }
    catch {
        $enabledExists = $false
    }
}
else {
    $enabledExists = "False"
}

Write-Output "valueExists is $valueExists"
Write-Output "keyExists is $keyExists"
Write-Output "path1Exists is $path1Exists"
Write-Output "path2Exists is $path2Exists"
Write-Output "enabledExists is $enabledExists"

if ($path2Exists) {
    if ($path1Exists) {
        if ($keyExists) {
            if ($valueExists) {
                Set-ItemProperty -Path $tlsKey -Name $tlsValue -Value 0
            } else {
                New-ItemProperty -Path $tlsKey -Name $tlsValue -Value 0
            }

            if ($enabledExists) {
                Set-ItemProperty -Path $tlsKey -Name $enabledValue -Value 1
            } else {
                New-ItemProperty -Path $tlsKey -Name $enabledValue -Value 1
            } 
        } else {
            New-Item -Path $tlsPath1 -Name 'Client'
            New-ItemProperty -Path $tlsKey -Name $tlsValue -Value 0
            New-ItemProperty -Path $tlsKey -Name $enabledValue -Value 1
        }
    } else {
        New-Item -Path $tlsPath2 -Name 'TLS 1.2'
        New-Item -Path $tlsPath1 -Name 'Client'
        New-ItemProperty -Path $tlsKey -Name $tlsValue -Value 0
        New-ItemProperty -Path $tlsKey -Name $enabledValue -Value 1
    }
} else {
    Write-Output "Something broke"
}