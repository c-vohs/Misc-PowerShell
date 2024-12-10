$installStatus = "No"
if (!(get-module -ListAvailable | ? Name -eq "RunAsUser")) {
    write-host "Module not installed"

    if (!(Get-PackageProvider | ? Name -eq NuGet)) {
        write-host "Installing NuGet Package Provider"
        Install-PackageProvider NuGet -Force
    }

    if ((Get-PSRepository | ? Name -EQ PSGallery).InstallationPolicy -ne "Trusted") {
        Write-Host "Setting PSGallery as trusted"
        Set-PSRepository PSGallery -InstallationPolicy Trusted
    }

    if (find-module -name "RunAsUser") {
        write-host "Module found, installing"
        install-module "RunAsUser" -Repository PSGallery
    }

    if (!(get-module -name "RunAsUser")) {
        write-host "Module failed to install"
        $installStatus = "Failed"
    } else {
        $installStatus = "Yes"
    }
} else {
    $installStatus = "Yes"
}