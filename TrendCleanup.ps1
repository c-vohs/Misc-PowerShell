function remove-regKey {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$path
    )

    if (test-path $path) {
        Remove-Item -Path $path -Recurse -Force
    }
}
function remove-folderAndSubs {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$path
    )

    if (test-path $path) {
        Get-ChildItem $path -Recurse -ev AccessErrors -ErrorAction SilentlyContinue | Remove-Item -Recurse
        Get-ChildItem $path -Recurse -ev AccessErrors -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse
        Remove-Item $path -Force -Recurse
    }
}

remove-regKey -path 'HKLM:\\SOFTWARE\\TrendMicro'


remove-folderAndSubs -path 'C:\Program Files (x86)\Trend Micro'
remove-folderAndSubs -path 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Trend Micro Security Agent'

$securityItems = get-WmiObject -namespace "ROOT\securitycenter2" -class "AntiVirusProduct"

if ($securityItems.Count -ge 1) {
    foreach ($securityItem in $securityItems) {
        $securityName = $securityItem.displayname
        if ($securityName -eq "Trend Micro Security Agent") {
            Write-Output "Deleting $regValue" >> "C:\Paxis\test.txt"
            $securityGuid = $securityItem.instanceGuid
            Remove-WmiObject -path \\localhost\ROOT\securitycenter2:AntivirusProduct.instanceGuid=$securityGuid
        }
    }
}

Write-Output "Finished" >> "C:\Paxis\test.txt"