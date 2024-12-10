$drives=Get-WmiObject Win32_LogicalDisk
$totalUsed=0

foreach ($drive in $drives){
            
    $freeSpace=[int]($drive.FreeSpace/1GB)
    $totalSpace=[int]($drive.Size/1GB)
    $usedSpace=$totalSpace - $freeSpace
    $totalUsed+=$usedSpace
}

$totalUsed