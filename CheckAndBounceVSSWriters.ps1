#$forceFlag = "True"
$vssArray = New-Object -TypeName 'System.Collections.ArrayList'
$bounceArray = New-Object -TypeName 'System.Collections.ArrayList'

$serviceArray = @{
    'ASR Writer'                        = 'VSS';
    'BITS Writer'                       = 'BITS';
    'Certificate Authority'             = 'CertSvc';
    'COM+ REGDB Writer'                 = 'VSS';
    'DFS Replication service writer'    = 'DFSR';
    'DHCP Jet Writer'                   = 'DHCPServer';
    'FRS Writer'                        = 'NtFrs';
    'IIS Config Writer'                 = 'AppHostSvc';
    'IIS Metabase Writer'               = 'IISADMIN';
    'Microsoft Exchange Replica Writer' = 'MSExchangeRepl';
    'Microsoft Exchange Writer'         = 'MSExchangeIS';
    'Microsoft Hyper-V VSS Writer'      = 'vmms';
    'MSMQ Writer (MSMQ)'                = 'MSMQ';
    'MSSearch Service Writer'           = 'WSearch';
    'NPS VSS Writer'                    = 'EventSystem';
    'NTDS'                              = 'NTDS';
    'OSearch VSS Writer'                = 'OSearch';
    'OSearch14 VSS Writer'              = 'OSearch14';
    'Registry Writer'                   = 'VSS';
    'Shadow Copy Optimization Writer'   = 'VSS';
    'SMS Writer'                        = 'SMS_SITE_VSS_WRITER';
    'SPSearch VSS Writer'               = 'SPSearch';
    'SPSearch4 VSS Writer'              = 'SPSearch4';
    'SqlServerWriter'                   = 'SQLWriter';
    'System Writer'                     = 'CryptSvc';
    'TermServLicensing'                 = 'TermServLicensing';
    'WDS VSS Writer'                    = 'WDSServer';
    'WIDWriter'                         = 'WIDWriter';
    'WINS Jet Writer'                   = 'WINS';
    'WMIWriter'                         = 'Winmgmt';
}

$split = vssadmin list writers | Select-String -Context 0, 4 'Writer name:' | ? { $_.Context.PostContext[2].split(">") }

$split | ForEach-Object { if (($_.Context.DisplayPostContext[3] -notmatch "Last error: No error") `
            -or `
        ($_.Context.DisplayPostContext[3] -notmatch "State: [1] Stable")) { $vssArray.add($_.Line.tostring().Split("'")[1]) | out-null } }

foreach ($writer in $vssArray) {
    if ($serviceArray.Contains($writer)) {
        if (!($bounceArray.contains($serviceArray.$writer))) {
            $bounceArray.add($serviceArray.$writer) | out-null
            #Write-Output "$writer = $serviceArray.$writer"
        }
    }
}
if ($null -ne $bounceArray) {

    if ($null -eq $bounceArray[0]) {
        #Write-Output "Deleting null value at index 0"
        $bounceArray.Remove($bounceArray[0])
    }

    if ("True" -eq $forceFlag) {
        foreach ($writer in $bounceArray) {
            Restart-Service $writer -Force -WarningAction:SilentlyContinue
        }
    }
    else {
        foreach ($writer in $bounceArray) {
            Restart-Service $writer -WarningAction:SilentlyContinue
        }
    }
}