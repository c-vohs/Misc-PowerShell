#trendUnlicensed and trendIdentifier are Ninja variables in custom fields

function get-gitDownload { 
    $repo = "paxishub/automation"
    $file = "WFBS_Installer.msi"

    $tag = "installer"

    $download = "https://github.com/$repo/releases/download/$tag/$file"
    $dir = "c:\windows\temp"

    Write-Output "Dowloading installer"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    curl.exe -L -O --output-dir $dir $download 
}

$program = Get-Package | Where-Object { $_.Name -eq "Trend Micro Security Agent" } 

$trendIdentifier = Ninja-Property-Get "trendIdentifier"
#Write-Output "trendIdentifier variable: $trendIdentifier"

if (!($program)) {
    Write-Output "Trend not found, starting installation"

    $trendUnlicensedObj = Ninja-Property-Get "trendUnlicensed" 

    if ($null -eq $trendUnlicensedObj) { [bool]$trendUnlicensed = $false }
    if ($trendUnlicensedObj -eq "0") { [bool]$trendUnlicensed = $false }
    if ($trendUnlicensedObj -eq "1") { [bool]$trendUnlicensed = $true }
    
    Write-Output "trendUnlicensed variable: $trendUnlicensed"

    if (!($trendUnlicensed)) {
        Write-Output "Machine licensed for Trend, starting installer download"

        get-gitDownload
  
        Write-Output "Installer downloaded, starting install"
        $MSIArgs = @(
            "/i"
            '"c:\windows\temp\WFBS_Installer.msi"'
            "IDENTIFIER=$trendIdentifier"
            "/L*v"
            '"c:\windows\temp\trend_msi.log"'
            "SILENTMODE=1"
        )

        Start-Process "msiexec.exe" -ArgumentList $MSIArgs -Wait -NoNewWindow
    }
}