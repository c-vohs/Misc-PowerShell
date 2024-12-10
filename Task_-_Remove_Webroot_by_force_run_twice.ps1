# Removes Webroot by force
# Run the script once, let it reboot, then run again

# Webroot services
$Services = @('WRSA','WRCore','WRCoreService','WRkrn','WRSkyClient','WRSVC')

# Webroot registry keys
$RegKeys = @(
	"HKLM:\SOFTWARE\Classes\``*\shellex\ContextMenuHandlers\WRShellExt",
	"HKLM:\SOFTWARE\Classes\Folder\shellex\ContextMenuHandlers\WRShellExt",
	"HKLM:\SOFTWARE\Microsoft\Internet Explorer\Extensions\{43699cd0-e34f-11de-8a39-0800200c9a66}",
	"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{c8d5d964-2be8-4c5b-8cf5-6e975aa88504}",
	"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WRUNINST",
	"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WRUNINST",
	"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Internet Explorer\Extensions\{43699cd0-e34f-11de-8a39-0800200c9a66}",
	"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{c8d5d964-2be8-4c5b-8cf5-6e975aa88504}",
	"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\WRUNINST",
	"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\WRUNINST",
	"HKLM:\SOFTWARE\WOW6432Node\WRData",
	"HKLM:\SOFTWARE\WOW6432Node\Webroot",
	"HKLM:\SOFTWARE\WRData",
	"HKLM:\SOFTWARE\Webroot",
	"HKLM:\SYSTEM\ControlSet001\Services\WRBoot",
	"HKLM:\SYSTEM\ControlSet001\Services\WRSVC",
	"HKLM:\SYSTEM\ControlSet001\Services\WRkrn",
	"HKLM:\SYSTEM\ControlSet001\Services\wrUrlFlt",
	"HKLM:\SYSTEM\ControlSet002\Services\WRBoot",
	"HKLM:\SYSTEM\ControlSet002\Services\WRSVC",
	"HKLM:\SYSTEM\ControlSet002\Services\WRkrn",
	"HKLM:\SYSTEM\ControlSet002\Services\wrUrlFlt",
	"HKLM:\SYSTEM\CurrentControlSet\Services\WRBoot",
	"HKLM:\SYSTEM\CurrentControlSet\Services\WRCore",
	"HKLM:\SYSTEM\CurrentControlSet\Services\WRCoreService",
	"HKLM:\SYSTEM\CurrentControlSet\Services\WRSVC",
	"HKLM:\SYSTEM\CurrentControlSet\Services\WRSkyClient",
	"HKLM:\SYSTEM\CurrentControlSet\Services\WRkrn",
	"HKLM:\SYSTEM\CurrentControlSet\Services\wrUrlFlt",
	"HKLM:\SYSTEM\CurrentSet001\Services\WRCore",
	"HKLM:\SYSTEM\CurrentSet001\Services\WRCoreService",
	"HKLM:\SYSTEM\CurrentSet001\Services\WRSkyClient",
	"HKLM:\SYSTEM\CurrentSet002\Services\WRCore",
	"HKLM:\SYSTEM\CurrentSet002\Services\WRCoreService",
	"HKLM:\SYSTEM\CurrentSet002\Services\WRSkyClient"
)

# Webroot startup registry item paths
$RegStartupPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
	"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
)

# Webroot folders
$Folders = @(
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Webroot",    
    "$env:ProgramData\WRCore",
    "$env:ProgramData\WRData",
    "$env:ProgramFiles\Common Files\Webroot\WebFiltering\wrflt.dll",
	"$env:ProgramFiles\Webroot",
	"${Env:ProgramFiles(x86)}\Common Files\Webroot",
    "${Env:ProgramFiles(x86)}\Webroot",
	"$env:SystemDrive\Users\All Users\WRCore",
	"$env:SystemDrive\Users\All Users\WRData",
	"$env:SystemDrive\Windows\System32\WRDll.x64.dll",
	"$env:SystemDrive\Windows\System32\wrusr.dll"
)

# Stop & delete Webroot services
function Kill-Services {
	ForEach ($Service in $Services) {
		Write-Host "Killing $Service"
		Stop-Process -Name $Service -Force -ErrorAction SilentlyContinue
		sc delete $Service
	}
}
# Let's run it twice to be sure
Kill-Services
Kill-Services

# Remove Webroot registry keys
ForEach ($RegKey in $RegKeys) {
    Write-Host "Removing $RegKey"
    Remove-Item -Path $RegKey -Force -Recurse -ErrorAction SilentlyContinue
}

# Remove Webroot registry startup items
ForEach ($RegStartupPath in $RegStartupPaths) {
    Write-Host "Removing WRSVC from $RegStartupPath"
    Remove-ItemProperty -Path $RegStartupPath -Name "WRSVC" -ErrorAction SilentlyContinue
}

# Remove Webroot folders
ForEach ($Folder in $Folders) {
    Write-Host "Removing $Folder"
    Remove-Item -Path "$Folder" -Force -Recurse -ErrorAction SilentlyContinue
}

# Remove other leftovers
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Toolbar" -Name "{97ab88ef-346b-4179-a0b1-7445896547a5}" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Internet Explorer\Toolbar" -Name "{97ab88ef-346b-4179-a0b1-7445896547a5}" -ErrorAction SilentlyContinue
Remove-Item "C:\Program Files (x86)\Common Files\wruninstall.exe" -ErrorAction SilentlyContinue
Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Install LastPass IE RunOnce.lnk" -ErrorAction SilentlyContinue

# Gentle restart (reopens apps)
shutdown /g /f