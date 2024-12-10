param([String]$Path, [Int32]$NumberToSave, [String]$Regex)

$items = Get-ChildItem "$Path\*.*" |
Where-Object Name -match "$Regex" |
Sort-Object Name -Descending

if ($NumberToSave -lt $items.Count) {
    $items[$NumberToSave..($items.Count - 1)] | Remove-Item
}