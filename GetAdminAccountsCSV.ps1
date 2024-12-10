#// Start of script 
#// Get year and month for csv export file 
$DateTime = Get-Date -f "yyyy-MM" 
 
#// Set CSV file name 
$CSVFile = "C:\windows\temp\AD_Admins" + $Date + ".csv" 
 
#// Create emy array for CSV data 
$CSVOutput = @() 

#// Ensure Members variable is empty 
$Members = "" 
 
#// Get group members which are also groups and add to string 
$MembersArr = Get-ADGroup -filter { Name -eq 'Domain Admins' } | Get-ADGroupMember |  select name, SamAccountName

foreach ($Member in $MembersArr) {
    $tempMember = [string]$Member.SamAccountName
    
    #// Set up hash table and add values 
    $HashTab = $NULL 
    $HashTab = [ordered]@{ 
        "Name"    = $Member.Name 
        "Logon"   = $Member.SamAccountName
        "Enabled" = (Get-ADUser -identity $tempMember).enabled
    }
    
    #// Add hash table to CSV data array 
    $CSVOutput += New-Object PSObject -Property $HashTab 
     
}
 
#// Export to CSV files 
$CSVOutput | Sort-Object Name | Export-Csv $CSVFile -NoTypeInformation 
 
#// End of script