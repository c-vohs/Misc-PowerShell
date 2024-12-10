$GlobalBitLockStatus = "Test"

function BitEncrypt {
    
}


if ([bool]((Get-WmiObject -namespace "Root\cimv2\security\MicrosoftVolumeEncryption" -Class "Win32_Encryptablevolume" -filter "DriveLetter = 'C:'").IsVolumeInitializedForProtection).Count) {
    if (Test-Path -Path "C:\Windows\System32\bdehdcfg.exe") {
        if ([bool](C:\Windows\System32\bdehdcfg.exe -driveinfo | select-string "This computer's hard drive is properly configured").count) {
            if ([bool]((Get-BitLockerVolume -MountPoint C).VolumeStatus | Select-String "FullyEncrypted").Count) {
                if ([bool](manage-bde -status C: | Select-String "Used Space Only Encrypted").Count) {
                    $BitlockerStatus = "Used Space Only Encrypted"
                }
                if ([bool](manage-bde -status C: | Select-String "Fully Encrypted").Count) {
                    $BitlockerStatus = "Fully Encrypted"
                }
                if ([bool]((Get-BitLockerVolume -MountPoint C).KeyProtector.KeyProtectorType | Select-String "RecoveryPassword").count) {
                    $BitLockKey = (Get-BitLockerVolume -MountPoint C).KeyProtector.recoverypassword | Out-String
                }
                #else {
                 #   $BitLockKey = "No Recovery Password"
                #}
            }
            else {
                $BitlockerStatus = "Ready But Not Protected"
            }
        }
        else {
            $BitlockerStatus = "Hard drive is not configured for Bitlocker, run bdehdcfg to configure"
        }
    }
    else {
        $BitlockerStatus = "bdehdcfg not found"
    }
}
else {
    #"BITLOCKER NOT TURNED ON"
    if ($BitLockKey -notmatch "-") {
        $BitLockKey = "No Recovery Password"
    }
    $WinVer = (Get-WmiObject -class Win32_OperatingSystem).Caption
    if ($WinVer -like "*home*") {
        $BitlockerStatus = "Not Supported" 
    }
    else {
        $BitlockerStatus = "TPM Module is not enabled or not ready"
    }
}


(Get-BitLockerVolume -MountPoint C).AutoUnlockEnabled
