$VPNName
$MerkiServer
$PerSharedKey
$ServerName
$ServerIP
[int]$ServerCount
[int]$SCounter = 0
$DesktopLocation

$VPNName = Read-Host -Prompt 'What do you want to name VPN'
$MerkiServer = Read-Host -Prompt 'Input DDNS Server address'
$PerSharedKey = Read-Host -Prompt 'Please enter Preshared key'

<#Adds Meraki VPN#>
Add-VpnConnection -Name "$VPNName" -ServerAddress "$MerkiServer" -TunnelType "L2tp" -AuthenticationMethod pap -SplitTunneling -AllUserConnection -L2tpPsk $PerSharedKey -PassThru


Try{
$ServerCount = Read-Host -Prompt 'How many servers do you want to add to the host file, press enter to skip?'
}
Catch{
    Write-host "Process skipped"
    }

<#Edit's Host file#>
While ($ServerCount -gt 0){
    $SCounter = $SCounter + 1
    $ServerName = Read-Host -Prompt "Please enter Server $SCounter"
    $ServerIP = Read-Host -Prompt ' Please enter Server IP'
    $ServerCount = $ServerCount - 1
    Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Exclude help* -Value "$ServerIP $ServerName"
    }


$DesktopLocation = Read-Host -Prompt "Please enter user desktop Location, Press Enter to skip" 

<# Adds Desktop Shortcut#>
Try{
  New-Item -ItemType SymbolicLink -Path "$DesktopLocation" -Name "Work VPN.lnk" -Value "C:\Windows\System32\rasphone.exe"
  }
  Catch{
    Write-Host "Process skipped"
    }

<# Create's Firewall rule#>
New-NetFirewallRule -DisplayName "Inbound 500/4500 UDP For Merki VPN" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 500,4500
New-NetFirewallRule -DisplayName "Outbound 500/4500 UDP For Merki VPN" -Direction Outbound -Action Allow -Protocol UDP -LocalPort 500,4500