Clear-Host

$KB = Get-Content "C:\Temp\patch.txt"

$results = Get-Hotfix | Where-Object {$_.hotfixid -eq $KB}
if($results){
echo True >> C:\Temp\results.txt
}else{
echo False >> C:\Temp\results.txt
}