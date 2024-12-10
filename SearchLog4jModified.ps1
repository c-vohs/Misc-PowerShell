
    $Computername = $env:COMPUTERNAME
    $ScriptBlock = {
        Function New-Runspace {
            [cmdletbinding()]
            param(
                [string]$BaseDir
                , [switch]$Recurse
            )
            $ScriptBlock = {
                Param(
                    $BaseDir
                    , [switch]$Recurse
                )
                begin {
                    Function Get-SpecificChildItem {
                        [CmdletBinding()]
                        Param(
                            [parameter(Mandatory = $true, ValueFromPipeline = $true)]
                            [string]
                            $Path,
                            [switch] $Recurse
                        )
                        begin {}
                        process {
                            if ( $Recurse ) {
                                Get-ChildItem $Path -Recurse -force -include *.jar -ErrorAction SilentlyContinue | ForEach-Object {
                                    if (select-string "JndiLookup.class" $_.FullName) {
                                        $_ | Select-Object -Property @{N = "Computername"; E = { $ENV:COMPUTERNAME } }, Name, FullName
                                    }
                                }
                                
                            } # files
                            else {
                                Get-ChildItem $Path  -force -include *.jar -ErrorAction SilentlyContinue | ForEach-Object {
                                    if (select-string "JndiLookup.class" $_.FullName) {
                                        $_ | Select-Object -Property @{N = "Computername"; E = { $ENV:COMPUTERNAME } }, Name, FullName
                                    }
                                }
                            } # else 
                        }
                        end {}
                    } # Function Get-SpecificChildItem
                }
                process {
                    if ( $Recurse ) {
                        Get-SpecificChildItem -Path $BaseDir -Recurse
                    }
                    else {
                        Get-SpecificChildItem -Path $BaseDir
                    }
                }
            } # ScriptBlock
            $PowerShell = [PowerShell]::Create()
            $PowerShell.RunspacePool = $Global:RunspacePool
            # What to run in the thread
            [void]$PowerShell.AddScript($ScriptBlock)
            # Parameters
            [void]$PowerShell.AddParameter("BaseDir", $BaseDir)
            if ( $Recurse ) {
                [void]$PowerShell.AddParameter("Recurse", $True)
            }
        } # Function New-Runspace

        $AllFiles = [System.Collections.ArrayList]@()

        # Set up runspace factory
        $MAX_THREADS = [int]$ENV:NUMBER_OF_PROCESSORS + 1
        if ($MAX_THREADS -lt 5 ) { $MAX_THREADS = 5 }
        Write-Host "Max Threads: $MAX_THREADS"
        $Global:RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $MAX_THREADS)
        $Global:RunspacePool.ApartmentState = "MTA"
        [void]$Global:RunspacePool.Open()

        #region enumerate files
        $DriveLetters = Get-WmiObject Win32_Logicaldisk | Where-Object { $_.DriveType -in @(2, 3, 5, 6) } | ForEach-Object { "$($_.DeviceId)\" }
        Write-Host $DriveLetters

        ForEach ( $DriveLetter in $DriveLetters ) {
            [array]$BaseDirectories = Get-ChildItem $DriveLetter -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty FullName
            New-RunSpace -BaseDir $DriveLetter
            # For each parent directory on each drive, including recycle bin - spawn a thread to enumerate files
            ForEach ($BaseDir in $BaseDirectories) {
                if ( $null -eq $BaseDir ) { continue }  # PSv2 always enters into the loop even if the loop item is null, so it will process 1 null entry.
                New-RunSpace -BaseDir $BaseDir
                
                [array]$SubDirectories = Get-ChildItem $BaseDir -Directory -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
                ForEach ( $SubDir in $SubDirectories ) {
                    if ( $null -eq $SubDir ) { continue }  # PSv2 always enters into the loop even if the loop item is null, so it will process 1 null entry.
                    New-RunSpace -BaseDir $SubDir -Recurse
                }
            } # ForEach ($BaseDir in $BaseDirectories)
        } # ForEach ( $DriveLetter in $DriveLetters )

        if ( $AllFiles.Count -gt 0 ) {
            $AllFiles
        }
        #endregion enumerate files

        $RunspacePool.Dispose()
    }

    $WorkingDir = (Get-Location).path
    $OutputFile = Join-Path $WorkingDir $("Log4Shell-{0}.csv" -f [datetime]::now.ToString("yyMMdd-HHmm"))
    $FailResultFile = Join-Path $WorkingDir $("Log4ShellFail-{0}.txt" -f [datetime]::now.ToString("yyMMdd-HHmm"))
    
    & $ScriptBlock | Export-Csv -NoTypeInformation $OutputFile -Append



    if (Test-Path -Path $OutputFile) {
        [int]$LinesInFile = -1
        $scriptResult = "No Data"
        $reader = New-Object IO.StreamReader $OutputFile
        while ($null -ne $reader.ReadLine()) { $LinesInFile++ }
        if ($LinesInFile -eq "-1") {
            Write-host "No instances found"
            $scriptResult = "No instances found"
        }
        else {
            Write-Host "Found $LinesInFile instances"
            $scriptResult = "Found $LinesInFile instances"
        }
    }
    else {
        Write-host "No file created"

    }

    if (Test-Path -Path $FailResultFile) {
        $failResult = Get-Content $FailResultFile | Measure-Object -Line
    }
    else {
        $failResult = "No failures"
    }
