#function Get-ActivationStatus {
 process {
 try {
 $wpa = Get-WmiObject SoftwareLicensingProduct `
 -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f'" `
 -Property Name, LicenseStatus -ErrorAction Stop
 } catch {
 $status = New-Object ComponentModel.Win32Exception ($_.Exception.ErrorCode)
 $wpa = $null 
 }
 $out = New-Object psobject -Property @{
 
 Name = [string]::Empty;
 Status = [string]::Empty;
 }
 if ($wpa) {
 :outer foreach($item in $wpa) {
 switch ($item.LicenseStatus) {
 0 {$out.Status = "Unlicensed"}
 1 {$out.Status = "Licensed"; break outer}
 2 {$out.Status = "Out-Of-Box Grace Period"; break outer}
 3 {$out.Status = "Out-Of-Tolerance Grace Period"; break outer}
 4 {$out.Status = "Non-Genuine Grace Period"; break outer}
 5 {$out.Status = "Notification"; break outer}
 6 {$out.Status = "Extended Grace"; break outer}
 default {$out.Status = "Unknown value"}
 }
 $out.Name = $item.Name
 }
 } else { $out.Status = $status.Message }
 
 $out.Status

 }
#}

#Get-ActivationStatus | fl *

