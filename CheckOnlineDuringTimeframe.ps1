$online = "No"

$min = get-date '03:00'
$max = get-date '04:00'

$now = Get-Date

if ($min.TimeOfDay -le $now.TimeOfDay -and $max.TimeOfDay -ge $now.TimeOfDay) {
    $online = "Yes"
}

Write-Output $online