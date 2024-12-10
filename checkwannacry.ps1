# KB4012598 KB4012212 - Windows Server 2008
# KB4012212 KB4012215 KB4019264 - Windows Server 2008 R2
# KB4012214 KB4012217 KB4019216 KB4012220 KB4015551 KB4015554 - Windows Server 2012
# KB4012213 KB4012216 KB4015550 KB4019215 - Windows Server 2012 R2
# KB4012598 - Windows Vista
# KB4012212 KB4012215 KB4019264 KB4015549 - Windows 7
# KB4012213 KB4012216 KB4015550 KB4019215 - Windows 8.1
# KB4012598 - Windows XP
# KB4012598 - Windows 2003
# KB4012598 - Windows 8

# Windows 10 32-bit and 64-bit: KB4012606 KB4015221 KB4016637 KB4019474
# Windows 10 version 1511 32-bit and 64-bit: KB4013198 KB4015219 KB4016636 KB4019473 KB4016871 
# Windows 10 version 1607 32-bit and 64-bit, Windows Server 2016 64-bit: KB4013429 KB4015217 KB4015438 KB4016635 KB4019472 KB4079472 

# Removed! Win10 'should not be susceptible to Wannacry, but still has an SMB vulnerability - Exception for Windows 10 / Server 2016 Devices
# https://support.microsoft.com/en-us/help/4013389/title 
#
# if (((Get-WmiObject Win32_OperatingSystem).Name -match 'Windows 10') -or ((Get-WmiObject Win32_OperatingSystem).Name -match '2016'))
#{
#	$HotfixInstalled = '1'
#	$HotfixName = "Found Windows 10 or 2016 which are prepatched."
#	exit
#}


# List of all HotFixes containing the patch
$hotfixes =	"KB4012212", "KB4012213", "KB4012214", "KB4012215", "KB4012216", "KB4012217", "KB4012220", "KB4012598", "KB4012606", "KB4013198", "KB4013429", "KB4015217", "KB4015219", "KB4015221", "KB4015438", "KB4015549", "KB4015550", "KB4015551", "KB4015554", "KB4016635", "KB4016636", "KB4016637", "KB4016871", "KB4019215", "KB4019216", "KB4019264", "KB4019472", "KB4019473", "KB4019474", "KB4079472"

# Search for the HotFixes
$hotfix = Get-HotFix -ComputerName $env:computername | Where-Object {$hotfixes -contains $_.HotfixID} | Select-Object -property "HotFixID"

# See if the HotFix was found
if ($hotfix) {

	$IDs = ""
	$hotfix | %{$IDs += ($(if($IDs){", "}) + $_.HotFixID)}

	Write-Host "Found HotFix(es): " + $IDs
	$HotfixInstalled = '1'
	$HotfixName = "$IDs"

} else {

    Write-Host "Did not Find HotFix. Please check and update this device."
	$HotfixInstalled = '0'
	$HotfixName = 'N/A'
}