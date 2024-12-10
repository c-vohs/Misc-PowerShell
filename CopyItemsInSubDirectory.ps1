$RootDirectory = "C:\Users\cvohs\OneDrive - Paxis Technologies\PAXIS\NCENTRAL\System Templates\New folder\New folder"
$FileExtension = "*.xml"
$Destination = "C:\Users\cvohs\OneDrive - Paxis Technologies\PAXIS\NCENTRAL\System Templates\New folder\New folder (2)"

Get-ChildItem $RootDirectory -filter $FileExtension -Recurse -Force |
ForEach-Object {
    Copy-Item $_.FullName -Destination $Destination
    }