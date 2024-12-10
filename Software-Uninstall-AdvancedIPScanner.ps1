$reg32path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
$reg64path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

$regSearch = Get-ChildItem -Path $reg64path, $reg32path | Get-ItemProperty | Where-Object { $_.DisplayName -match "Advanced IP Scanner *" } | Select-Object -Property DisplayName, UninstallString

if($regSearch) {
    foreach ($result in $regSearch){
        write-host "$($result.DisplayName) exists, uninstall string: $($result.UninstallString)"
        & cmd /c $result.UninstallString /quiet
    }
}