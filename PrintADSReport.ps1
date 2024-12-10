$files = Get-ChildItem "D:\CACHESYS\mgr\user\ARReports*.*"

taskkill /f /pid soffice.bin

Get-ChildItem $files| Rename-Item -NewName {$_.Name -replace ".out", ".txt"}

Start-Sleep -Seconds 10

$files = Get-ChildItem "D:\CACHESYS\mgr\user\ARReports*.*"

foreach ($file in $files){
    start-process -FilePath $file.fullName -Verb Print
    }

Start-Sleep -Seconds 90

Remove-Item "D:\CACHESYS\mgr\user\ARReports*.*"