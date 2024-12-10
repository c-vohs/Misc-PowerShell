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

#$url
#$username
#$password
#$localFolder
#$ftpTarget

$TLS12Protocol = [System.Net.SecurityProtocolType] 'Ssl3 , Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $TLS12Protocol

$credentials = New-Object System.Net.NetworkCredential($username, $password) 
DownloadFtpFile $url $credentials $localfolder $ftpTarget