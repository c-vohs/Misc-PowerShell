<#	
	.NOTES
	===========================================================================
	 Created on:   	20200701
	 Created by:   	x
	 Organization: 	x
	 Filename:     	RemoveAllAV.0.3
	===========================================================================
	.DESCRIPTION
		This will remove the software listed below with no GUI or reboots.

		Malwarebytes (all versions)
		McAfee: (In the order listed below)
			McAfee Endpoint Security Adaptive Threat Prevention
			McAfee Endpoint Security Web Control
			McAfee Endpoint Security Threat Prevention
			McAfee Endpoint Security Firewall
			McAfee Endpoint Security Platform
			McAfee VirusScan Enterprise
			McAfee Agent
		Microsoft Security Essentials
		Sophos: (In the order listed below)
			Sophos Remote Management System
 			Sophos Network Threat Protection
 			Sophos Client Firewall
 			Sophos Anti-Virus
 			Sophos AutoUpdate
 			Sophos Diagnostic Utility
 			Sophos Exploit Prevention
 			Sophos Clean
 			Sophos Patch Agent
 			Sophos Endpoint Defense
#>

Write-Host "Setting up..." -ForegroundColor Yellow

$ScriptVersion = "RemoveAllAV.0.3"

Write-Host "Checking OS version..." -ForegroundColor Yellow 
If ((Get-WmiObject Win32_OperatingSystem).Caption -like '*server*')
{
	Write-Warning "This script is not designed to run on a Server OS. The script will now close."
	## Removing all script files for security reasons.
	Write-Warning "Removing script files for security purposes..."
	## Self destructs script.
	Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force
	Write-Host "File deletion completed" -ForegroundColor Green
	Write-Warning "Press any key to exit...";
	$x = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown");
}
else
{
	Write-Host "OS Version verified. Continuing..." -ForegroundColor Green
}

Write-Host "Checking for administrative rights..." -ForegroundColor Yellow
## Get the ID and security principal of the current user account.
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID);

## Get the security principal for the administrator role.
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;

## Check to see if we are currently running as an administrator.
if ($myWindowsPrincipal.IsInRole($adminRole))
{
	## We are running as an administrator, so change the title and background colour to indicate this.
	Write-Host "We are running as administrator, changing the title to indicate this." -ForegroundColor Green
	$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)";
}
else
{
	Write-Host "We are not running as administrator. Relaunching as administrator." -ForegroundColor Yellow
	## We are not running as admin, so relaunch as admin.
	$NewProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
	## Specify the current script path and name as a parameter with added scope and support for scripts with spaces in it's path.
	$NewProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
	## Indicate that the process should be elevated.
	$NewProcess.Verb = "runas";
	## Start the new process
	[System.Diagnostics.Process]::Start($newProcess);
	## Exit from the current, unelevated, process.
	Exit;
}

Write-Host "Continuing with setup..." -ForegroundColor Yellow

## Start log.
if ($PSVersionTable.PSVersion.Major -ge 3)
{
	Write-Host "We are running Powershell version 3 or greater. Logging enabled." -ForegroundColor Green
	If ((Test-Path C:\Logs\) -eq $false)
	{
		New-Item C:\Logs\ -ItemType Directory
	}
	Start-Transcript -Path "C:\Logs\$ScriptVersion.$(Get-Date -UFormat %Y%m%d).log"
}

$INFO = "
Anti-Virus Removal script written by x.
Please contact the author if you have any questions or concerns.
Contact info: x
**For complete ChangeLog, please contact the author.**

Script version: $ScriptVersion
"

## Modules
if (Get-Module -ListAvailable -Name PackageManagement)
{
	
}
Else
{
	Install-PackageProvider -Name NuGet -Force
	Install-Module -Name PackageManagement -Force
}


## Variables
$SophosSoftware = Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "*Sophos*" }
$SophosSoftware += Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "*Sophos*" }

$MbAMCheck1 = (Resolve-Path -Path C:\Prog*\Malw*).Path
$MbAMCheck1 += (Resolve-Path -Path C:\Prog*\Malw*\Ant*).Path
## if Statement required due to Join-Path erroring if $MvAMCheck1 is $null. ErrorAction did not suppress error.
if (($MbAMCheck1) -ne $null)
{
	$MbAMCheck2 = Test-Path -Path (Join-Path -Path $MbAMCheck1 -ChildPath unins000.exe)
	$MbAMCheck2 += Test-Path -Path (Join-Path -Path $MbAMCheck1 -ChildPath mbuns.exe)
}

$McAfeeSoftware = Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "*McAfee*" }
$McAfeeSoftware += Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "*McAfee*" }
$McAfeeCheck =
## Temporarily leaving some McAfee software out of this script.

Write-Host "Checking for all installations of Malwarebytes..." -ForegroundColor Yellow
## Official Malwarebytes command line uninstaller
if (($MbAMCheck2) -eq $true)
{
	Write-Host "Found Malwarebytes software..." -ForegroundColor Green
	Write-Host "Checking for Malwarebytes Uninstaller..." -ForegroundColor Yellow
	if ((Test-Path -Path C:\Temp\mbstcmd.exe) -eq $true)
	{
		Write-Host "Found Command line Malwarebytes Uninstaller." -ForegroundColor Green
		Write-Host "Running Command line Malwarebytes Uninstaller Silently..." -ForegroundColor Yellow
		Start-Process -FilePath C:\Temp\mbstcmd.exe -ArgumentList "/y", "/cleanup", "/noreboot" -Wait
		Write-Host "Removed Malwarebytes." -ForegroundColor Green
		Write-Host "Checking for any other installations..." -ForegroundColor Yellow
	}
	else
	{
		Write-Host "Uninstaller not found! Manually checking for other installations..." -ForegroundColor Yellow
	}
	
	## Checking for all installations of Malwarebytes. Installations have changed paths over version changes. Removing if found.
	if ((Test-Path -Path "C:\Program Files\Malwarebytes' Anti-Malware\unins000.exe") -eq $true)
	{
		Write-Host "Found Malwarebytes..." -ForegroundColor Green
		Write-Host "Removing Malwarebytes..." -ForegroundColor Yellow
		Start-Process -FilePath "C:\Program Files\Malwarebytes' Anti-Malware\unins000.exe" -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
		Write-Host "Removed Malwarebytes." -ForegroundColor Green
	}
	
	if ((Test-Path -Path "C:\Program Files (x86)\Malwarebytes' Anti-Malware\unins000.exe") -eq $true)
	{
		Write-Host "Found Malwarebytes..." -ForegroundColor Green
		Write-Host "Removing Malwarebytes..." -ForegroundColor Yellow
		Start-Process -FilePath "C:\Program Files (x86)\Malwarebytes' Anti-Malware\unins000.exe" -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
		Write-Host "Removed Malwarebytes." -ForegroundColor Green
	}
	
	if ((Test-Path -Path "C:\Program Files\Malwarebytes Anti-Malware\unins000.exe") -eq $true)
	{
		Write-Host "Found Malwarebytes..." -ForegroundColor Green
		Write-Host "Removing Malwarebytes..." -ForegroundColor Yellow
		Start-Process -FilePath "C:\Program Files\Malwarebytes Anti-Malware\unins000.exe" -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
		Write-Host "Removed Malwarebytes." -ForegroundColor Green
	}
	
	if ((Test-Path -Path "C:\Program Files (x86)\Malwarebytes Anti-Malware\unins000.exe") -eq $true)
	{
		Write-Host "Found Malwarebytes..." -ForegroundColor Green
		Write-Host "Removing Malwarebytes..." -ForegroundColor Yellow
		Start-Process -FilePath "C:\Program Files (x86)\Malwarebytes Anti-Malware\unins000.exe" -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
		Write-Host "Removed Malwarebytes." -ForegroundColor Green
	}
	
	if ((Test-Path -Path "C:\Program Files\Malwarebytes\Anti-Malware\unins000.exe") -eq $true)
	{
		Write-Host "Found Malwarebytes..." -ForegroundColor Green
		Write-Host "Removing Malwarebytes..." -ForegroundColor Yellow
		Start-Process -FilePath "C:\Program Files\Malwarebytes\Anti-Malware\unins000.exe" -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
		Write-Host "Removed Malwarebytes." -ForegroundColor Green
	}
	
	if ((Test-Path -Path "C:\Program Files (x86)\Malwarebytes\Anti-Malware\unins000.exe") -eq $true)
	{
		Write-Host "Found Malwarebytes..." -ForegroundColor Green
		Write-Host "Removing Malwarebytes..." -ForegroundColor Yellow
		Start-Process -FilePath "C:\Program Files (x86)\Malwarebytes\Anti-Malware\unins000.exe" -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
		Write-Host "Removed Malwarebytes." -ForegroundColor Green
	}
	
	if ((Test-Path -Path "C:\Program Files (x86)\Malwarebytes\Anti-Malware\mbuns.exe") -eq $true)
	{
		Write-Host "Found Malwarebytes..." -ForegroundColor Green
		Write-Host "Removing Malwarebytes..." -ForegroundColor Yellow
		Start-Process -FilePath "C:\Program Files (x86)\Malwarebytes\Anti-Malware\mbuns.exe" -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
		Write-Host "Removed Malwarebytes." -ForegroundColor Green
	}
	
	if ((Test-Path -Path "C:\Program Files\Malwarebytes\Anti-Malware\mbuns.exe") -eq $true)
	{
		Write-Host "Found Malwarebytes..." -ForegroundColor Green
		Write-Host "Removing Malwarebytes..." -ForegroundColor Yellow
		Start-Process -FilePath "C:\Program Files\Malwarebytes\Anti-Malware\mbuns.exe" -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
		Write-Host "Removed Malwarebytes." -ForegroundColor Green
	}
	
	if ((Get-Package -Name Malwarebytes*) -eq $true)
	{
		Write-Host "Found Malwarebytes..." -ForegroundColor Green
		Write-Host "Removing Malwarebytes..." -ForegroundColor Yellow
		Get-Package -Name Malwarebytes* | Uninstall-Package -AllVersions -Force
	}
	Write-Host "Malwarebytes removal completed." -ForegroundColor Green
}
else
{
	Write-Host "No Malwarebytes software found." -ForegroundColor Yellow
	Write-Host "Continuing..." -ForegroundColor Green
}


Write-Host "Checking for McAfee software (Check 1)..." -ForegroundColor Yellow
if (($McAfeeSoftware) -ne $null)
{
	Write-Host "Found McAfee software..." -ForegroundColor Green
	foreach ($Software in @("McAfee Endpoint Security Adaptive Threat Prevention", "McAfee Endpoint Security Web Control",
			"McAfee Endpoint Security Threat Prevention", "McAfee Endpoint Security Firewall", "McAfee Endpoint Security Platform",
			"McAfee VirusScan Enterprise", "McAfee Agent"))
	{
		if ($McAfeeSoftware | Where-Object DisplayName -like $Software)
		{
			$McAfeeSoftware | Where-Object DisplayName -like $Software | ForEach-Object {
				Write-Host "Uninstalling $($_.DisplayName)"
				
				if ($_.uninstallstring -like "msiexec*")
				{
					Write-Debug "Uninstall string: Start-Process $($_.UninstallString.split(' ')[0]) -ArgumentList `"$($_.UninstallString.split(' ', 2)[1]) /qn REBOOT=SUPPRESS`" -Wait"
					Start-Process $_.UninstallString.split(" ")[0] -ArgumentList "$($_.UninstallString.split("  ", 2)[1]) /qn" -Wait
				}
				else
				{
					Write-Debug "Uninstall string: Start-Process $($_.UninstallString) -Wait"
					Start-Process $_.UninstallString -Wait
				}
			}
		}
	}
	Write-Host "Finished removing McAfee." -ForegroundColor Green
}
else
{
	Write-Host "McAfee software not found..." -ForegroundColor Yellow
	Write-Host "Continuing..." -ForegroundColor Green
}

## 20200716.x.Temporarily commenting out this portion of the removal.
Write-Host "Skipping McAfee Check 2..." -ForegroundColor Yellow
<#
	## Removing Specific McAfee software.
Write-Host "Checking for McAfee (Check 2)..." -ForegroundColor Yellow
If ((WMIC product where "Name Like '%%McAfee%%'") -ne "No Instance(s) Available.")
{
	Write-Host "Removing McAfee VirusScan Enterprise..." -ForegroundColor Yellow
	WMIC product where "description= 'McAfee VirusScan Enterprise' " uninstall
	
	Write-Host "Removing McAfee Agent..." -ForegroundColor Yellow
	WMIC product where "description= 'McAfee Agent' " uninstall
}
else
{
	Write-Host "No removable McAfee software found..." -ForegroundColor Yellow
	Write-Host "Continuing..." -ForegroundColor Green
}
#>

## Attempting to remove other McAfee software that isn't Tamper protected
Write-Host "Checking for McAfee (Check 3)..." -ForegroundColor Yellow
if ((Get-Package -Name McAfee*) -ne $null)
{
	Write-Host "Found McAfee Software..." -ForegroundColor Green
	Write-Host "Removing McAfee software..." -ForegroundColor Yellow
	Get-Package -Name McAfee* | Uninstall-Package -AllVersions -Force
	
}
else
{
	Write-Host "No removable McAfee software found..." -ForegroundColor Yellow
	Write-Host "Continuing..." -ForegroundColor Green
}

## Removing Microsoft Security Essentials
Write-Host "Checking for Microsoft Security Essentials..." -ForegroundColor Yellow
if ((Test-Path "C:\Program FIles\Microsoft Security Client\Setup.exe") -eq $true)
{
	Write-Host "Found Microsoft Security Essentials..." -ForegroundColor Green
	Write-Host "Removing Microsoft Security Essentials..." -ForegroundColor Yellow
	Start-Process -FilePath "C:\Program FIles\Microsoft Security Client\Setup.exe" -ArgumentList "/x", "/u", "/s" -Wait
	Write-Host "Finished removing Microsoft Security Essentials." -ForegroundColor Green
}
else
{
	Write-Host "Microsoft Security Essentials not found..." -ForegroundColor Yellow
	Write-Host "Continuing..." -ForegroundColor Green
}

## Removing Sophos AV suite, in a specific order. 
Write-Host "Checking for Sophos software..." -ForegroundColor Yellow
if (($SophosSoftware) -ne $null)
{
	Write-Host "Found Sophos software..." -ForegroundColor Green
	Stop-Service -Name "Sophos Anti-Virus" -Force
	Stop-Service -Name "Sophos AutoUpdate Service" -Force
	foreach ($Software in @("Sophos Remote Management System", "Sophos Network Threat Protection", "Sophos Client Firewall", "Sophos Anti-Virus",
			"Sophos AutoUpdate", "Sophos Diagnostic Utility", "Sophos Exploit Prevention", "Sophos Clean", "Sophos Patch Agent", "Sophos Endpoint Defense",
			"Sophos Management Communication System", "Sophos Compliance Agent", "Sophos System Protection"))
	{
		if ($SophosSoftware | Where-Object DisplayName -like $Software)
		{
			$SophosSoftware | Where-Object DisplayName -like $Software | ForEach-Object {
				Write-Host "Uninstalling $($_.DisplayName)"
				
				if ($_.uninstallstring -like "msiexec*")
				{
					Write-Debug "Uninstall string: Start-Process $($_.UninstallString.split(' ')[0]) -ArgumentList `"$($_.UninstallString.split(' ', 2)[1]) /qn REBOOT=SUPPRESS`" -Wait"
					Start-Process $_.UninstallString.split(" ")[0] -ArgumentList "$($_.UninstallString.split("  ", 2)[1]) /qn REBOOT=SUPPRESS" -Wait
				}
				else
				{
					Write-Debug "Uninstall string: Start-Process $($_.UninstallString) -Wait"
					Start-Process $_.UninstallString -Wait
				}
			}
		}
	}
	Write-Host "Finished removing Sophos." -ForegroundColor Green
}
else
{
	Write-Host "Sophos software not found..." -ForegroundColor Yellow
	Write-Host "Continuing..." -ForegroundColor Green
}

## Removing all script files for security reasons.
Write-Warning "Removing script files for security purposes..."
## Self destructs script.
Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force
Remove-Item -Path "C:\Temp\mbstcmd.exe" -Force
Write-Host "File deletion completed" -ForegroundColor Green

## Stops Log.
if ($PSVersionTable.PSVersion.Major -ge 3)
{
	Write-Warning "Stopping log.."
	Stop-Transcript
}