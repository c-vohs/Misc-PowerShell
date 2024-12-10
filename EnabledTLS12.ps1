$TLS_Eval = "Failed to find SID"

$UserKey = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI' -Name LastLoggedOnUserSID).LastLoggedOnUserSID
$Path = "HKU:\$UserKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"

if (!(Test-Path -Path HKU:\)) {
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
}

if (Test-Path -Path $Path) {

    $TLS_Value = (Get-ItemProperty $Path -Name SecureProtocols).SecureProtocols

    [string]$TLS_Eval = switch ($TLS_Value) {
        0 { '0' }
        8 { '2.0' }
        32 { '3.0' }
        40 { '2.0, 3.0' }
        128 { '1.0' }
        136 { '2.0, 1.0' }
        160 { '3.0, 1.0' }
        168 { '2.0, 3.0, 1.0' }
        512 { '1.1' }
        520 { '2.0, 1.1' }
        544 { '3.0, 1.1' }
        552 { '2.0, 3.0, 1.1' }
        640 { '1.0, 1.1' }
        648 { '2.0, 1.0, 1.1' }
        672 { '3.0, 1.0, 1.1' }
        680 { '2.0, 3.0, 1.0, 1.1' }
        2048 { '1.2' }
        2056 { '2.0, 1.2' }
        2080 { '3.0, 1.2' }
        2088 { '2.0, 3.0, 1.2' }
        2176 { '1.0, 1.2' }
        2184 { '2.0, 1.0, 1.2' }
        2208 { '3.0, 1.0, 1.2' }
        2216 { '2.0, 3.0, 1.0, 1.2' }
        2560 { '1.1, 1.2' }
        2568 { '2.0, 1.1, 1.2' }
        2592 { '3.0, 1.1, 1.2' }
        2600 { '2.0, 3.0, 1.1, 1.2' }
        2688 { '1.0, 1.1, 1.2' }
        2696 { '2.0, 1.0, 1.1, 1.2' }
        2720 { '3.0, 1.0, 1.1, 1.2' }
        2728 { '2.0, 3.0, 1.0, 1.1, 1.2' }
        8192 { '1.3' }
        8200 { '2.0, 1.3' }
        8224 { '3.0, 1.3' }
        8232 { '2.0, 3.0, 1.3' }
        8320 { '1.0, 1.3' }
        8328 { '2.0, 1.0, 1.3' }
        8352 { '3.0, 1.0, 1.3' }
        8360 { '2.0, 3.0, 1.0, 1.3' }
        8704 { '1.1, 1.3' }
        8712 { '2.0, 1.1, 1.3' }
        8736 { '3.0, 1.1, 1.3' }
        8744 { '2.0, 3.0, 1.1, 1.3' }
        8832 { '1.0, 1.1, 1.3' }
        8840 { '2.0, 1.0, 1.1, 1.3' }
        8864 { '3.0, 1.0, 1.1, 1.3' }
        8872 { '2.0, 3.0, 1.0, 1.1, 1.3' }
        10240 { '1.2, 1.3' }
        10248 { '2.0, 1.2, 1.3' }
        10272 { '3.0, 1.2, 1.3' }
        10280 { '2.0, 3.0, 1.2, 1.3' }
        10368 { '1.0, 1.2, 1.3' }
        10376 { '2.0, 1.0, 1.2, 1.3' }
        10400 { '3.0, 1.0, 1.2, 1.3' }
        10408 { '2.0, 3.0, 1.0, 1.2, 1.3' }
        10752 { '1.1, 1.2, 1.3' }
        10760 { '2.0, 1.1, 1.2, 1.3' }
        10784 { '3.0, 1.1, 1.2, 1.3' }
        10792 { '2.0, 3.0, 1.1, 1.2, 1.3' }
        10880 { '1.0, 1.1, 1.2, 1.3' }
        10888 { '2.0, 1.0, 1.1, 1.2, 1.3' }
        10912 { '3.0, 1.0, 1.1, 1.2, 1.3' }
        10920 { '2.0, 3.0, 1.0, 1.1, 1.2, 1.3' }
        default { 'Could not determine' }
    }
}

if ($TLS_Eval -like "*.*") {
    if (!($TLS_Eval.Contains("1.2"))) {
        Write-Host "1.2 not found, TLS_Eval is $TLS_Eval"
        
        $TLS_Value = [int]$TLS_Value + 2048
        Set-ItemProperty -Path $Path -Name SecureProtocols -Value $TLS_Value
    } else {
        Write-Host "No action required, TLS_Eval is $TLS_Eval"
    }
} else {
    Write-Host "Could not complete task"
}