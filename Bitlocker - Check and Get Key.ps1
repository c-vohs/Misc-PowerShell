$bitlockerKey = "test" #$bitlockerKeyIn
$bitlockerStatus = "Error"

if ((Get-WMIObject win32_operatingsystem).name -notlike "*Home*") { 
    if ([bool]((Get-WmiObject -namespace "Root\cimv2\security\MicrosoftVolumeEncryption" -Class "Win32_Encryptablevolume" -filter "DriveLetter = 'C:'").IsVolumeInitializedForProtection).Count) {
        if ([bool](C:\Windows\System32\bdehdcfg -driveinfo | select-string "This computer's hard drive is properly configured").count) {
            if ([bool]((Get-BitLockerVolume -MountPoint C).VolumeStatus | Select-String "FullyEncrypted").Count) {
                if ([bool](manage-bde -status C: | Select-String "Used Space Only Encrypted").Count) {
                    $bitlockerStatus = "Used Space Only Encrypted"
                }
                if ([bool](manage-bde -status C: | Select-String "Fully Encrypted").Count) {
                    $bitlockerStatus = "Fully Encrypted"
                }
                if ([bool]((Get-BitLockerVolume -MountPoint C).KeyProtector.KeyProtectorType | Select-String "RecoveryPassword").count) {
                    $bitlockerKey = (Get-BitLockerVolume -MountPoint C).KeyProtector.recoverypassword | Out-String
                }
                else {
                    $bitlockerKey = "No Recovery Password"
                }
            }
            else {
                $bitlockerStatus = "Ready But Not Protected"
            }
        }
        else {
            $bitlockerStatus = "Hard drive is not configured for Bitlocker, run bdehdcfg to configure"
        }
    }
    else {
        #"BITLOCKER NOT TURNED ON"
        if ($bitlockerKey -notmatch "-") {
            $bitlockerKey = "No Recovery Password"
        }
        $WinVer = (Get-WmiObject -class Win32_OperatingSystem).Caption
        if ($WinVer -like "*home*") {
            $bitlockerStatus = "Not Supported" 
        }
        else {
            $bitlockerStatus = "TPM Module is not enabled or not ready"
        }
    }
}
else {
    $bitlockerStatus = "Bitlocker not supported by OS"
}