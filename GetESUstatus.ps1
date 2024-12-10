
try {
$ESUStatus = Get-WmiObject SoftwareLicensingProduct `
-Filter "Name = 'Windows(R) 7, Client-ESU-Year2 add-on for Enterprise,EnterpriseE,EnterpriseN,Professional,ProfessionalE,ProfessionalN,Ultimate,UltimateE,UltimateN'" `
-Property LicenseStatus -ErrorAction Stop
} catch {
$status = New-Object ComponentModel.Win32Exception ($_.Exception.ErrorCode)
$ESUStatus = $null
}

 $out = New-Object psobject -Property @{
 Status = [string]::Empty;
 }
switch ($ESUStatus.LicenseStatus) {
 0 {$out.Status = "Unlicensed"}
 1 {$out.Status = "Licensed"}
 2 {$out.Status = "Out-Of-Box Grace Period"}
 3 {$out.Status = "Out-Of-Tolerance Grace Period"}
 4 {$out.Status = "Non-Genuine Grace Period"}
 5 {$out.Status = "Notification"}
 6 {$out.Status = "Extended Grace"}
 default {$out.Status = "Unknown value"}
 }

 $out.Status