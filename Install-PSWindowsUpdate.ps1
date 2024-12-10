Install-packageProvider -name NuGet -MinimumVersion 2.8.5.201 -force -confirm:$false
If(-not(Get-InstalledModule PSWindowsUpdate -ErrorAction silentlycontinue)){
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    Install-Module -Name PSWindowsUpdate -Force -confirm:$false
}