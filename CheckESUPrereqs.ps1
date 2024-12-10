$Patch = Get-Content -path "C:\paxis\kb_list.txt"
 
$data = ForEach ($kb in $patch) {
 
    Try {
        $result = get-hotfix -id $kb -ErrorAction Stop
        
        if ($result -ne $null){
        [PSCustomObject]@{
            KB = $kb
            Status = 'Installed'
        }}
 
    } Catch {
        [PSCustomObject]@{
            KB = $kb
            Status = 'Not Installed'
        }
    }
}

 
$data | Export-csv -Path C:\Paxis\kbresults.csv -notypeinformation