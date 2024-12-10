param([String]$Path, [Int]$DaysToKeep)

#$Path = "C:\temp\test1"
#[Int]$DaysToKeep = 1

$logPath = Split-Path -Path $Path -Parent

$items = Get-ChildItem "$Path\*.*" 
$cutOffDate = (get-date).adddays(-$DaysToKeep).Date

get-date | out-file -Append "$logPath\deleteLog.txt"

if ($items) {
    foreach ($item in $items) {
        if ($item.LastAccessTime -lt $cutOffDate) {
            "$($item.name) last accessed on $($item.LastAccessTime)" | out-file -Append "$logPath\deleteLog.txt"
            Remove-Item $item.FullName
        }
    }
}
else {
    "No items in folder" | out-file -Append "$logPath\deleteLog.txt"
}

if (Test-Path "$logPath\deleteLog.txt") {
        if ((Get-item "$logPath\deleteLog.txt").Length -gt 3kb) {
            Remove-item "$logPath\deleteLog.txt"
        }
}