#$ParamPrimaryDrives="C:" #Supports C:,D:,etc.
$ParamPrimaryDrives = $ScSelDrvLst

$OtherDriveOn = "No Other Drives have Bitlocker On"
$OtherDriveOff = "No Other Drives have Bitlocker Off"
$OtherDriveStatusCode = 1 #1 = OK, 2 = Fail, 3 = warning (BitLockerNotSupported)

$PrimDriveOn = "No Selected Drives have Bitlocker On"
$PrimDriveOff = "No Selected Drives have Bitlocker Off"
$PrimDriveStatusCode = 1 #1 = OK, 2 = Fail, 3 = warning (BitLockerNotSupported)

$BitlockerStatus = 2 #1 = OK, 2 = Fail, 3 = warning (BitLockerNotSupported)
$PrimaryDriveList = $ParamPrimaryDrives.Split(",")



if (Get-Command "Get-BitLockerVolume" -errorAction SilentlyContinue) {

    #IF ENABLED, SET BITLOCKERFEATURESTATUS TO OK
    $BitLockerFeature = "Turned On"
    $BitlockerStatus = 1

    #GET BITLOCKER STATUS
    $Bitlocklist = Get-BitLockerVolume 
    
    #GO THROUGH DRIVES
    foreach ($bitlockinfo in $Bitlocklist) {
        #IF IT IS THE PRIMARY DRIVE (C), TAKE THE INFO
        if ($bitlockinfo.MountPoint -in $PrimaryDriveList) {
            if ($bitlockinfo.VolumeStatus -ne "FullyEncrypted") {
                $PrimDriveStatusCode = 2
                if ($PrimDriveOff -eq "No Selected Drives have Bitlocker Off") {
                    $PrimDriveOff = $bitlockinfo.MountPoint + " is " + $bitlockinfo.VolumeStatus

                }
                else {
                    if ([bool](manage-bde -status $bitlockinfo.MountPoint | Select-String "Used Space Only Encrypted").Count) {
                        $PrimDriveOff = $PrimDriveOff + ", " + $bitlockinfo.MountPoint + " is Used Space Only Encrypted"
                    }
                    else {
                        $PrimDriveOff = $PrimDriveOff + ", " + $bitlockinfo.MountPoint + " is " + $bitlockinfo.VolumeStatus
                    }
                }
            }
            else {
                if ($PrimDriveOn -eq "No Selected Drives have Bitlocker On") {
                    if ([bool](manage-bde -status $bitlockinfo.MountPoint | Select-String "Used Space Only Encrypted").Count) {
                        $PrimDriveOn = $bitlockinfo.MountPoint + " is Used Space Only Encrypted"
                    }
                    else {
                        $PrimDriveOn = $bitlockinfo.MountPoint + " is " + $bitlockinfo.VolumeStatus
                    }

                }
                else {
                    if ([bool](manage-bde -status $bitlockinfo.MountPoint | Select-String "Used Space Only Encrypted").Count) {
                        $PrimDriveOn = $PrimDriveOn + ", " + $bitlockinfo.MountPoint + " is Used Space Only Encrypted"
                    }
                    else {
                        $PrimDriveOn = $PrimDriveOn + ", " + $bitlockinfo.MountPoint + " is " + $bitlockinfo.VolumeStatus
                    }

                }
            }
        }
        #IF IT IS NOT (C), CAPTURE INTO IN A GROUP. THIS IS SECONDARY PARTITIONS, EXTERNAL DRIVES, ETC
        else {
            if ($bitlockinfo.VolumeStatus -ne "FullyEncrypted") {
                $OtherDriveStatusCode = 2
                if ($OtherDriveOff -eq "No Other Drives have Bitlocker Off") {
                    $OtherDriveOff = $bitlockinfo.MountPoint + " is " + $bitlockinfo.VolumeStatus

                }
                else {
                    $OtherDriveOff = $OtherDriveOff + ", " + $bitlockinfo.MountPoint + " is " + $bitlockinfo.VolumeStatus

                }
            }
            else {
                if ($OtherDriveOn -eq "No Other Drives have Bitlocker On") {
                    if ([bool](manage-bde -status $bitlockinfo.MountPoint | Select-String "Used Space Only Encrypted").Count) {
                        $OtherDriveOn = $bitlockinfo.MountPoint + " is Used Space Only Encrypted"
                    }
                    else {
                    $OtherDriveOn = $bitlockinfo.MountPoint + " is " + $bitlockinfo.VolumeStatus
                    }
                }
                else {
                    if ([bool](manage-bde -status $bitlockinfo.MountPoint | Select-String "Used Space Only Encrypted").Count) {
                        $OtherDriveOn = $OtherDriveOn + ", " + $bitlockinfo.MountPoint + " is Used Space Only Encrypted"
                    }
                    else {
                    $OtherDriveOn = $OtherDriveOn + ", " + $bitlockinfo.MountPoint + " is " + $bitlockinfo.VolumeStatus
                    }
                }
            }
        
        }

    }

}
else {
    #"BITLOCKER NOT TURNED ON"
    $WinVer = (Get-WmiObject -class Win32_OperatingSystem).Caption
    if ($WinVer -like "*home*") {
        $BitlockerStatus = 2
        $BitLockerFeature = $WinVer + " does not support Bitlocker"

        $OtherDriveOn = "Bitlocker not enabled, no information returned"
        $OtherDriveOff = "Bitlocker not enabled, no information returned"
        $OtherDriveStatusCode = 2 #1 = OK, 2 = Fail, 3 = warning (BitLockerNotSupported)

        $PrimDriveOn = "Bitlocker not enabled, no information returned"
        $PrimDriveOff = "Bitlocker not enabled, no information returned"
        $PrimDriveStatusCode = 2 #1 = OK, 2 = Fail, 3 = warning (BitLockerNotSupported)    
    }
    else {
        $BitlockerStatus = 3
        $BitLockerFeature = $WinVer + "Supports BitLocker but the feature is not installed"

        $OtherDriveOn = "Bitlocker not enabled, no information returned"
        $OtherDriveOff = "Bitlocker not enabled, no information returned"
        $OtherDriveStatusCode = 3 

        $PrimDriveOn = "Bitlocker not enabled, no information returned"
        $PrimDriveOff = "Bitlocker not enabled, no information returned"
        $PrimDriveStatusCode = 3 
    }
}

"BitlockerFeatureStatusCode : " + $BitlockerStatus
"BitlockerFeatureDetails : " + $BitLockerFeature

"Selected Drive With BitLocker On : " + $PrimDriveOn
"Selected Drive With BitLocker Off: " + $PrimDriveOff
"Selected Drive Status Code : " + $PrimDriveStatusCode

"Other Drive With BitLocker On : " + $OtherDriveOn
"Other Drive With BitLocker Off: " + $OtherDriveOff
"Other Drive Status Code : " + $OtherDriveStatusCode





$scBitFeatStatDtl = $BitLockerFeature
$scBitFeatStatCode = $BitlockerStatus
$scSelDrvLstOn = $PrimDriveOn
$scSelDrvLstOff = $PrimDriveOff
$scSelDrvCode = $PrimDriveStatusCode
$scOthDrvLstOn = $OtherDriveOn
$scOthDrvLstOff = $OtherDriveOff
$scOthDrvCode = $OtherDriveStatusCode

