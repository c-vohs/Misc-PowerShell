function DownloadFtpFile ($url, $credentials, $localPath, $name) {
    $localFilePath = Join-Path $localPath $name
    $fileUrl = ($url + $name)

    #Write-Host "Downloading $fileUrl to $localFilePath"

    $downloadRequest = [Net.WebRequest]::Create($fileUrl)
    $downloadRequest.EnableSsl = $true
    $downloadRequest.Method =
        [System.Net.WebRequestMethods+Ftp]::DownloadFile
    $downloadRequest.Credentials = $credentials

    $downloadResponse = $downloadRequest.GetResponse()
    $sourceStream = $downloadResponse.GetResponseStream()
    $targetStream = [System.IO.File]::Create($localFilePath)
    $buffer = New-Object byte[] 10240
    while (($read = $sourceStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $targetStream.Write($buffer, 0, $read);
    }
    $targetStream.Dispose()
    $sourceStream.Dispose()
    $downloadResponse.Dispose() 
}

$credentials = New-Object System.Net.NetworkCredential("NCentral", "bsP#LR&57h)j08^kT") 
$url = "ftp://pandora.paxistech.com/"
DownloadFtpFile $url $credentials "C:\temp\ftp" "BEST_uninstallTool.exe"