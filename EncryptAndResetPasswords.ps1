$BitLockKey = "No Recovery Password"


$netsvcPW = "netsvcPW"
$rmmtechPW = "rmmtechPW"
$defaultPW = "defaultPW"


$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"

if (Test-Path -Path $Path) {
    Set-ItemProperty -Path $Path -Name NoLocalPasswordResetQuestions -Value 1
}

$users = Get-LocalUser | ? Enabled -eq True

foreach ($user in $users) {
    $userPassword = "ChuckNorris123!"
    switch ($user.Name) {
        netsvc { $userPassword = $netsvcPW }
        rmmtech { $userPassword = $rmmtechPW }
        Default { $userPassword = $defaultPW }
    }
    Write-Host $user.Name " $userPassword"
    Set-LocalUser -Name $user.Name -Password $userPassword
}

if ([bool]((Get-BitLockerVolume -MountPoint C).KeyProtector.KeyProtectorType | Select-String "RecoveryPassword").count) {
    $BitLockKey = (Get-BitLockerVolume -MountPoint C).KeyProtector.recoverypassword | Out-String
    }
    else {
        Add-BitLockerKeyProtector -MountPoint C: -RecoveryPasswordProtector
        $BitLockKey = (Get-BitLockerVolume -MountPoint C).KeyProtector.recoverypassword | Out-String
}

Write-Output $BitLockKey

Enable-BitLocker -MountPoint C: -TpmProtector -EncryptionMethod Aes256 -SkipHardwareTest

Start-Sleep -Seconds 5

$encryptStatus = (Get-BitLockerVolume).VolumeStatus

Do {
    Write-Output $encryptStatus
    Start-Sleep -Seconds 300
    $encryptStatus = (Get-BitLockerVolume).VolumeStatus
} while ($encryptStatus -eq "EncryptionInProgress")

Restart-Computer -Force