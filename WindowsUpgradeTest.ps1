<#
.SYNOPSIS
	Windows 10 Upgrade Pre-Check
.DESCRIPTION 
	The purpose of the script is to ensure there are no easily identifiable issues that may cause the Win10Upgrade to fail
.NOTES
	Stolen & Modified by: SecDudeWithATude
	Version: 0.01
	Date: 2019-06-04
#>
#check for minimum W7 SP1
[int]$varKernel = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo("C:\Windows\system32\kernel32.dll")).FileBuildPart
if ($varKernel -lt 7601) {
    write-host "`- Error code 1:" -ForegroundColor Red
    write-host "  This component requires Microsoft Windows 7 SP1 or higher to proceed."
    exit 1
}

write-host "+ Target device OS is Windows 7 SP1 or greater." -ForegroundColor Cyan


#find edition of windows, fail if not Professional
$varEdition = (cscript /nologo C:\windows\system32\slmgr.vbs /dli | select-string -quiet "Professional")
if (!$varEdition) {
    write-host "`- Error code 2:" -ForegroundColor Red
    write-host "  This component installs Windows 10 Professional and can thus only be run on"
    write-host "  Professional builds of Windows 7 SP1, 8/8.1 or 10."
    exit 2
}

write-host "+ Target device OS edition matches that of the Windows 10 installer." -ForegroundColor Cyan


#make sure it's licensed (v2)
$varLicence = Get-WmiObject SoftwareLicensingProduct | Where-Object { $_.LicenseStatus -eq 1 } | Select-Object -ExpandProperty Description | select "Windows"
if (!$varLicence) {
    write-host "`- Error code 3:" -ForegroundColor Red
    write-host "  Windows 10 can only be installed on devices with an active Windows licence."
    exit 3
}

write-host "+ Target device has a valid Windows licence." -ForegroundColor Cyan

#make sure we have enough disk space - installation plus iso hosting
$varSysFree = [Math]::Round((Get-WMIObject -Class Win32_Volume | Where-Object { $_.DriveLetter -eq $env:SystemDrive } | Select -expand FreeSpace) / 1GB)
if ($varSysFree -le 25) {
    write-host "`- Error code 4:" -ForegroundColor Red
    write-host "  System drive requires at least 20GB: 13 for installation, 7 for the disc image."
    exit 4
}

write-host "+ Target device has at least 20GB of free hard disk space." -ForegroundColor Cyan

$result = (get-disk | where bustype -eq 'usb')
if ($result -ne $NULL) {
    Write-Host "`- Error code 5:" -ForegroundColor Red
    Write-Host " A USB drive has been detected.`nPlease have the USB drive dismounted prior to Upgrade."
    exit 5
}
Write-Host "++ No USB drive was detected in the target device." -ForegroundColor Green
exit 0


#download the image
import-module BitsTransfer -Force

if (!$?) {
    write-host "`- Error code 6:" -ForegroundColor Red
    write-host "  Import of PowerShell module BitsTransfer failed."
    write-host "  The script uses BITS to download the ISO."
    write-host "  Execution cannot continue. Script aborted."
    exit 6
}

write-host "+ BitsTransfer PowerShell module applied." -ForegroundColor Cyan
write-host "++ All Checks have been passed successfully.`n++ This device is ready to upgrade." -ForegroundColor Green

exit 0