write-host "SolarWinds Windows Agent Uninstaller"

function getGUID ($product, $vendor) {
    set-content "UninstallNable.vbs" -value 'Set installer = CreateObject("WindowsInstaller.Installer")
On Error Resume Next'
    add-content "UninstallNable.vbs" -value "strProductSearch = `"$product`""
    add-content "UninstallNable.vbs" -value "strVendorSearch = `"$vendor`""
    add-content "UninstallNable.vbs" -value 'For Each product In installer.ProductsEx("", "", 7)
name = product.InstallProperty("ProductName")
vendor = product.InstallProperty("Publisher")
productcode = product.ProductCode
If InStr(1, name, strProductSearch) > 0 then
If InStr(1, vendor, strVendorSearch) > 0 then
wscript.echo (productcode)
End if
End if
Next'

    cscript /nologo UninstallNable.vbs
    remove-item UninstallNable.vbs -force
}

if ([intptr]::Size -eq 4) {
    $varProgramFiles = $env:ProgramFiles
}
else {
    $varProgramFiles = ${env:ProgramFiles(x86)}
}

foreach ($guid in getGuid "Windows Agent" "N-able Technologies") {
    write-host "- Uninstalling $guid..."
    msiexec /X$guid /qn /norestart
}


$uninstallRHA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
Get-ItemProperty |
Where-Object { $_.DisplayName -match "Request Handler Agent" } |
Select-Object -Property DisplayName, UninstallString

ForEach ($ver in $uninstallRHA) {

    If ($ver.UninstallString) {

        $uninst = $ver.UninstallString
        & cmd /c $uninst /SILENT /norestart
    }

}

Write-Host "Uninstall Patch Management Service Controller"
$uninstallPME = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
Get-ItemProperty |
Where-Object { $_.DisplayName -match "Patch Management Service Controller" } |
Select-Object -Property DisplayName, UninstallString

ForEach ($ver in $uninstallPME) {

    If ($ver.UninstallString) {

        $uninst = $ver.UninstallString
        & cmd /c $uninst /SILENT /norestart
    }

}

Write-Host "Uninstall File Cache Service Agent"
$uninstallFCSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
Get-ItemProperty |
Where-Object { $_.DisplayName -match "File Cache Service Agent" } |
Select-Object -Property DisplayName, UninstallString

ForEach ($ver in $uninstallFCSA) {

    If ($ver.UninstallString) {

        $uninst = $ver.UninstallString
        & cmd /c $uninst /SILENT /norestart
    }

}

Write-Host "Uninstall Ecosystem Agent"
$uninstallEA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
Get-ItemProperty |
Where-Object { $_.DisplayName -match "Ecosystem Agent" } |
Select-Object -Property DisplayName, UninstallString

ForEach ($ver in $uninstallEA) {

    If ($ver.UninstallString) {

        $uninst = $ver.UninstallString
        & cmd /c $uninst /SILENT /norestart
    }

}