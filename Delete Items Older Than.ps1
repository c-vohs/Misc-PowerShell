# Written by Chris Vohs
# Last Edited 2/5/25
# Script will take an input $path and $DaysToKeep variables to check for items that are older than $DaysToKeep old.
# Any items older will be purged and added to the log written in the same folder $Path.

param([String]$Path, [Int]$DaysToKeep)

# These are test variables
#$Path = "C:\temp\test1"
#[Int]$DaysToKeep = 1

$logPath = Split-Path -Path $Path -Parent

# Gets a list of items in the $Path and the $cutOffDate based on the $DaysToKeep
$items = Get-ChildItem "$Path\*.*" 
$cutOffDate = (get-date).adddays(-$DaysToKeep).Date

# Check if the log is too large and purge if it is.
if (Test-Path "$logPath\deleteLog.txt") {
        if ((Get-item "$logPath\deleteLog.txt").Length -gt 3kb) {
            Remove-item "$logPath\deleteLog.txt"
        }
}

# Initialize the logfile with current date
get-date | out-file -Append "$logPath\deleteLog.txt"

# Check each item in $items and remove if they are past the $cutOffDate. Write log of $item and last accessed date. If no items, just write to log.
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
