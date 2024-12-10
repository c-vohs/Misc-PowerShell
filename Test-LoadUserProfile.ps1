$username = "paxis\rmmtech"
$password = "$8V!!gM)31h8AThqr"

[securestring]$secStringPassword = ConvertTo-SecureString $password -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($username, $secStringPassword)

#start-process -FilePath C:\temp\test.txt -LoadUserProfile -Credential $credObject
#Start-Process -FilePath notepad.exe -ArgumentList '/P C:\Temp\test.txt'
Get-Content -Path C:\temp\test.txt | Out-Printer