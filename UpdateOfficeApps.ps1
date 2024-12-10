$file = "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe"

if (test-path $file) {
    & "$env:CommonProgramFiles\microsoft shared\ClickToRun\OfficeC2RClient.exe" /update user displaylevel=false updatepromptuser=false forceappshutdown=true
} else {
    Write-Host "File does not exist"
}







