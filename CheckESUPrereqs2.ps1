$patches = gc C:\Paxis\kb_list.txt
 
foreach ($patch in $patches){
 
 Get-HotFix -id $patch -OutVariable results -ErrorAction SilentlyContinue | select Description, HotFixID, InstalledOn | Format-Table -HideTableHeaders
 
 if ($results -ne $null) {
 
 $results | Out-File C:\Paxis\kbresult.txt -Append -Force
 
 }
 
 else {
 
 Add-content "$Patch is not Present" -path "C:\Paxis\kbresult.txt"
 
 }
 
 }
 