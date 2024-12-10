$ipAddress = (get-netipaddress | ? AddressFamily -eq "IPv4" | ? PrefixOrigin -eq "DHCP").IPAddress
$ipSplit = $ipAddress.split(".")
$ipPreOcts = $ipSplit[0] + "." + $ipSplit[1] + "." + $ipSplit[2] + "."
$ipLastOct = $ipSplit[3]
[string]$minIPlast = [int]$ipLastOct - "10"
[string]$maxIPlast = [int]$ipLastOct + "10"

$ping = New-Object System.Net.NetworkInformation.Ping

$ipListLast = $minIPlast..$maxIPlast

$ipList = $ipListLast | ForEach-object {
    $ipPreOcts + $_
}

Resolve-DnsName -Name "10.10.81.25" -NoHostsFile