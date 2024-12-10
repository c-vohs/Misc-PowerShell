function get-gitDownload { 
    $repo = "paxishub/automation"
    $file = "WFBS_Installer.msi"

    $tag = "installer"

    $download = "https://github.com/$repo/releases/download/$tag/$file"
    #$name = $file.Split(".")[0]
    $dir = "$env:localappdata\temp"

    Write-Host "Dowloading installer"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    curl.exe -L -O --output-dir $dir $download 
}

