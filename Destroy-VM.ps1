<#
.SYNOPSIS
	 Completely removes a virtual machine and all of its related files.
.DESCRIPTION
	 Completely removes a virtual machine and all of its related files.
	 Removes any related cluster resources, virtual hard disk files, and folders created specially for this virtual machine.
.PARAMETER VM
	The virtual machine to be deleted.
	Accepts objects of type:
	* String: A name of a virtual machine.
	* VirtualMachine: An object from Get-VM.
	* System.GUID: A virtual machine ID. MUST be of type System.GUID to match.
	* ManagementObject: A WMI object of type Msvm_ComputerSystem
	* ManagementObject: A WMI object of type MSCluster_Resource
.PARAMETER ComputerName
	The name of the computer that currently hosts the virtual machine to remove. If not specified, the local computer is assumed.
	Ignored if VM is of type VirtualMachine or ManagementObject.
.PARAMETER Force
	Bypasses prompting. Also, if the oldest snapshot cannot be applied, attempts to delete all snapshots as they are. This could cause a long merging operation.
.NOTES
	 Author: Eric Siron
	 Copyright: (C) 2016 Altaro Software
	 Version 1.1
	 Authored Date: October 1, 2016

	 Revision History
	 ----------------
	 1.2
	 ---
	 More graceful error messaging when a virtual machine's component folders cannot be searched. Functionality is unchanged.

	 1.1
	 ---
	 * Changed testing process for items to be delete to accomodate more PS versions and hosts.
	 * Changed testing for existence of clustered resources to accommodate "empty but not null" conditions.
.EXAMPLE
	Clear-VM oldvm
	--------------
	Deletes the virtual machine "oldvm" from the local computer.

.EXAMPLE
	Clear-VM oldvm othercomputer
	----------------------------
	Deletes the virtual machine "oldvm" from the host named "othercomputer"

.EXAMPLE
	Get-VM | Clear-VM
	-----------------
	Deletes every virtual machine on the local computer.
#>
#requires -Version 4

#function Clear-VM		# Uncomment this line to use as dot-sourced function or in a profile. Also the next line and the very last line.
#{							# Uncomment this line to use as dot-sourced function or in a profile. Also the previous line and the very last line.
	[CmdletBinding(ConfirmImpact='High')]
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
		[Alias('VMName', 'Name')]
		[Object]
		$VM,

		[Parameter(ParameterSetName='ByName', Position=2)]
		[String]
		$ComputerName = $env:COMPUTERNAME,

		[Parameter()]
		[Switch]
		$IgnoreFolders,

		[Parameter()]
		[Switch]
		$Force,

		[Parameter()]
		[Switch]
		$WhatIf
	)
BEGIN {
	Set-StrictMode -Version Latest
	$FilterRemoteDisk = '^[A-Z]:\\'
	$FileSearchScriptBlock = {
		param(
			[Parameter(Mandatory=$true, Position=1)]
			[String[]]
			$FoldersToScan
		)

		foreach($FolderToScan in $FoldersToScan)
		{
			try
			{
				Get-ChildItem -Path $FolderToScan -File
			}
			catch
			{
				Write-Warning -Message ('Unable to enumerate files in {0}. Manual cleanup of this location may be necessary. Error: {0}' -f $_.Exception.Message)
			}
		}
	}

	$FileOrFolderDeleteScriptBlock = {
		param(
			[Parameter(Mandatory=$true, Position=1)]
			[String[]]
			$ItemsToDelete
		)

		foreach($ItemToDelete in $ItemsToDelete)
		{
			if ($ItemToDelete -and (Test-Path $ItemToDelete))
			{
				$FolderTest = Get-Item -Path $ItemToDelete
				if((Test-Path -Path $FolderTest -PathType Container) -and (Get-ChildItem -Path $FolderTest))
				{
					Write-Warning -Message ('Cannot remove folder {0} as it has children' -f $ItemToDelete)
					continue
				}
				try
				{
					Remove-Item -Path $ItemToDelete -Force -ErrorAction Stop
				}
				catch
				{
					Write-Warning -Message $_.Message
				}
			}
		}
	}

	$ProcessWMIJobScriptBlock = {
		param
		(
			[Parameter(ValueFromPipeline=$true)][System.Management.ManagementBaseObject]$WmiResponse,
			[Parameter()][String]$WmiClassPath = $null,
			[Parameter()][String]$MethodName = $null
		)

		$ErrorCode = 0

		if($WmiResponse.ReturnValue -eq 4096)
		{
			$Job = [WMI]$WmiResponse.Job

			while ($Job.JobState -eq 4)
			{
				Start-Sleep -Milliseconds 100
				$Job.PSBase.Get()
			}

			if($Job.JobState -ne 7)
			{
				if ($Job.ErrorDescription -ne '')
				{
					throw $Job.ErrorDescription
				}
				else
				{
					$ErrorCode = $Job.ErrorCode
				}
			}
		}
		elseif ($WmiResponse.ReturnValue -ne 0)
		{
			$ErrorCode = $WmiResponse.ReturnValue
		}

		if($ErrorCode -ne 0)
		{
			if($WmiClassPath -and $MethodName)
			{
				$PSWmiClass = [WmiClass]$WmiClassPath
				$PSWmiClass.PSBase.Options.UseAmendedQualifiers = $true
				$MethodQualifiers = $PSWmiClass.PSBase.Methods[$MethodName].Qualifiers
				$IndexOfError = [System.Array]::IndexOf($MethodQualifiers['ValueMap'].Value, [String]$ErrorCode)
				if($IndexOfError -ne -1)
				{
					'Error Code: {0}, Method: {1}, Error: {2}' -f $ErrorCode, $MethodName, $MethodQualifiers['Values'].Value[$IndexOfError]
				}
				else
				{
					'Error Code: {0}, Method: {1}, Error: Message Not Found' -f $ErrorCode, $MethodName
				}
			}
		}
	}
}

PROCESS {
	$VMObject = $null
	$ClusteredResources = $null
	$VMClusterGroup = $null
	Write-Progress -Activity 'Gathering information' -Status 'Loading the specified virtual machine' -PercentComplete 0
	switch($VM.GetType().FullName)
	{
		'Microsoft.HyperV.PowerShell.VirtualMachine' {
			$VMObject = Get-WmiObject -ComputerName $VM.ComputerName -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' -Filter ('Name="{0}"' -f $VM.Id) -ErrorAction Stop
		}

		'System.Guid' {
			$VMObject = Get-WmiObject -ComputerName $Computername -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' -Filter ('Name="{0}"' -f $VM) -ErrorAction Stop
		}

		'System.Management.ManagementObject' {
			switch ($VM.ClassPath.ClassName)
			{
				'Msvm_ComputerSystem' {
					$VMObject = $VM
				}
				'MSCluster_Resource' {
					$VMObject = Get-WmiObject -ComputerName $VM.ClassPath.Server -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' -Filter ('Name="{0}"' -f $VM.PrivateProprties.VmID) -ErrorAction Stop
				}
				default {
					$ArgEx = New-Object System.ArgumentException(('Cannot accept objects of type {0}' -f $VM.ClassPath.ClassName), 'VM')
					Write-Error -Exception $ArgEx
					return
				}
			}
		}

		'System.String' {
			if($VM -ne $ComputerName -and $VM -ne $env:COMPUTERNAME)
			{
				$VMObject = Get-WmiObject -ComputerName $ComputerName -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' -Filter ('ElementName="{0}"' -f $VM) -ErrorAction Stop | select -First 1
			}
		}

		default {
			$ArgEx = New-Object System.ArgumentException(('Unable to process objects of type {0}' -f $VM.GetType().FullName), 'VM')
			Write-Error -Exception $ArgEx
			return
		}
	}

	if($VMObject -eq $null)
	{
		$ArgEx = New-Object System.ArgumentException(('The specified virtual machine "{0}" could not be found' -f $VM), 'VM')
		Write-Error -Exception $ArgEx
		return
	}

	Write-Progress -Activity 'Gathering information' -Status ('Checking if {0} is replicating.' -f $VMObject.ElementName) -PercentComplete 10
	if($VMObject.ReplicationState -gt 0)
	{
		Write-Error -Message ('Replication is enabled for {0}. Please disable replication before deletion.' -f $VMObject.ElementName)
		return
	}

	$ComputerName = $VMObject.__SERVER
	Write-Progress -Activity 'Gathering information' -Status 'Loading virtual machine settings' -PercentComplete 20
	$RelatedVMSettings = $VMObject.GetRelated('Msvm_VirtualSystemSettingData') | select -Unique
	$VMSettings = $RelatedVMSettings | where -Property VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized'
	$Snapshots = $RelatedVMSettings | where -Property VirtualSystemType -ne 'Microsoft:Hyper-V:System:Realized'
	$HostIsRemote = $false
	$RemoteSession = $null
	if($env:COMPUTERNAME -ine ($ComputerName -replace '\..*', ''))
	{
		Write-Progress -Activity 'Gathering information' -Status ('Creating a PowerShell session on {0}' -f $ComputerName) -PercentComplete 30
		$HostIsRemote = $true
		$RemoteSession = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
	}
	else
	{
		$ComputerName = '.'
	}

	Write-Progress -Activity 'Gathering information' -Status ('Determining if {0} is clustered.' -f $VMObject.ElementName) -PercentComplete 40
	# There is a KVP item that contains this information but parsing it out is obnoxious. Since we'll need the cluster resource info anyway, we'll just assume it's clustered and quietly proceed if it's not.
	if(Get-WmiObject -Computer $ComputerName -Namespace 'root' -Class '__NAMESPACE' -Filter 'Name="MSCluster"')
	{
		$ClusteredResources = Get-WmiObject -ComputerName $ComputerName -Namespace 'root\MSCluster' -Class 'MSCluster_Resource' -Filter ('PrivateProperties.VmID="{0}"' -f $VMObject.Name | select -First 1)
		if($ClusteredResources)
		{
			$VMClusterGroup = Get-WmiObject -ComputerName $ComputerName -Namespace 'root\MSCluster' -Class 'MSCluster_ResourceGroup' -Filter ('Name="{0}"' -f $ClusteredResources.OwnerGroup)
		}
	}
	$IsClustered = $VMClusterGroup -ne $null

	Write-Progress -Activity 'Gathering information' -Status 'Determining VM file locations' -PercentComplete 50
	$AllFoldersToScan = @()
	$FileList = @()
	$LocalFoldersToScan = @()
	$LocalFilesToRemove = @()
	$RemoteFoldersToScan = @()
	$RemoteFilesToRemove = @()

	foreach ($RelatedObject in $RelatedVMSettings)
	{
		$AllFoldersToScan += $RelatedObject.ConfigurationDataRoot
		$AllFoldersToScan += Join-Path -Path $RelatedObject.ConfigurationDataRoot -ChildPath 'Virtual Machines'
		if(-not ([String]::IsNullOrEmpty($RelatedObject.SnapshotDataRoot)))
		{
			$AllFoldersToScan += $RelatedObject.SnapshotDataRoot
			$AllFoldersToScan += Join-Path -Path $RelatedObject.SnapshotDataRoot -ChildPath 'Snapshots'
		}
		$AllFoldersToScan += $RelatedObject.SwapFileDataRoot
		$AllFoldersToScan += Join-Path -Path $RelatedObject.ConfigurationDataRoot -ChildPath $RelatedObject.SuspendDataRoot	# this is a delicious yet dirty hack that always yields the folder that contains the BIN and VSV files
	}
	$AllFoldersToScan = $AllFoldersToScan | select -Unique
	if($HostIsRemote)
	{
		foreach($FolderToScan in $AllFoldersToScan)
		{
			if($HostIsRemote -and $FolderToScan -imatch $FilterRemoteDisk)
			{
				$RemoteFoldersToScan += $FolderToScan
			}
			else
			{
				$LocalFoldersToScan += $FolderToScan
			}
		}
	}
	else
	{
		$LocalFoldersToScan = $AllFoldersToScan
	}

	if($LocalFoldersToScan)
	{
		Write-Progress -Activity 'Gathering information' -Status 'Gathering a list of files to delete' -PercentComplete 60
		$FileList = Invoke-Command -ScriptBlock $FileSearchScriptBlock -ArgumentList @(, $LocalFoldersToScan)
	}
	if($HostIsRemote -and $RemoteFoldersToScan)
	{
		Write-Progress -Activity 'Gathering information' -Status ('Connecting to {0} to gather a list of files to delete' -f $ComputerName) -PercentComplete 70
		$FileList += Invoke-Command -Session $RemoteSession -ScriptBlock $FileSearchScriptBlock -ArgumentList @(, $RemoteFoldersToScan)
	}

	foreach ($FoundFile in $FileList)
	{
		foreach ($InstanceIDField in $RelatedVMSettings.InstanceId)
		{
			if($InstanceIDField -match 'Microsoft:(.*)')
			{
				$InstanceID = $Matches[1]
				if($FoundFile.BaseName -imatch ('^{0}(\.|\z)' -f $InstanceID) -and $FoundFile.Extension -imatch 'xml|bin|vsv|slp')
				{
					if($HostIsRemote -and $FoundFile -imatch $FilterRemoteDisk)
					{
						$RemoteFilesToRemove += $FoundFile
					}
					else
					{
						$LocalFilesToRemove += $FoundFile
					}
				}
			}
		}
	}

	Write-Progress -Activity 'Gathering information' -Status 'Building a list of virtual hard disks that must be deleted' -PercentComplete 80
	foreach ($VHDResource in ($RelatedVMSettings.GetRelated() | where -Property ResourceSubType -eq 'Microsoft:Hyper-V:Virtual Hard Disk' -ErrorAction SilentlyContinue))
	{
		foreach ($VirtualHardDiskPath in $VHDResource.HostResource)
		{
			if($HostIsRemote -and $VirtualHardDiskPath -imatch $FilterRemoteDisk)
			{
				$RemoteFilesToRemove += $VirtualHardDiskPath
			}
			else
			{
				$LocalFilesToRemove += $VirtualHardDiskPath
			}
			$VirtualHardDiskParentPath = Split-Path -Path $VirtualHardDiskPath -Parent
			if($HostIsRemote -and $VirtualHardDiskParentPath -imatch $FilterRemoteDisk)
			{
				$RemoteFoldersToScan += $VirtualHardDiskParentPath
			}
			else
			{
				$LocalFoldersToScan += $VirtualHardDiskParentPath
			}
		}
	}

	Write-Progress -Activity 'Gathering information' -Status 'Building a list of virtual floppy disks and ISOs that must be deleted' -PercentComplete 90
	foreach ($RemovableResource in ($RelatedVMSettings.GetRelated() | where -Property ResourceSubType -match 'Microsoft:Hyper-V:Virtual (CD/DVD|Floppy) Disk' -ErrorAction SilentlyContinue))
	{
		foreach ($RemovableResourcePath in $RemovableResource.HostResource)
		{
			$RemovableResourceParentPath = Split-Path -Path $RemovableResourcePath -Parent
			foreach ($Folder in $AllFoldersToScan)
			{
				if($Folder -imatch ($RemovableResourceParentPath -replace '\\', '\\')) # RemovableResourceParentPath must be a sub of an already-found folder to be eligible for removal
				{
					if($HostIsRemote -and $RemovableResourcePath -imatch $FilterRemoteDisk)
					{
						$RemoteFilesToRemove += $RemovableResourcePath
					}
					else
					{
						$LocalFilesToRemove += $RemovableResourcePath
					}
				}
			}
		}
	}

	Write-Progress -Activity 'Gathering information' -Status 'Determining important folders' -PercentComplete 95
	$ImportantFolders = @()

	$VSMSSD = Get-WmiObject -ComputerName $ComputerName -Namespace 'root\virtualization\v2' -Class 'Msvm_VirtualSystemManagementServiceSettingData'
	$ImportantFolders += $VSMSSD.DefaultExternalDataRoot
	$ImportantFolders += $VSMSSD.DefaultVirtualHardDiskPath

	$OtherVMSettingsData = Get-WmiObject -ComputerName $ComputerName -Namespace 'root\virtualization\v2' -Class 'Msvm_VirtualSystemSettingData' -Filter ('VirtualSystemIdentifier != "{0}"' -f $VMObject.Name)
	foreach($VMSettingData in $OtherVMSettingsData)
	{
		$ImportantFolders += $VMSettingData.ConfigurationDataRoot
		$ImportantFolders += Join-Path -Path $VMSettingData.ConfigurationDataRoot -ChildPath 'Virtual Machines'
		if(-not [String]::IsNullOrEmpty($VMSettingData.SnapshotDataRoot))
		{
			$ImportantFolders += $VMSettingData.SnapshotDataRoot
			$ImportantFolders += Join-Path -Path $VMSettingData.SnapshotDataRoot -ChildPath 'Snapshots'
		}
		$ImportantFolders += $VMSettingData.SwapFileDataRoot
	}

	$AllVHDs = Get-WmiObject -ComputerName $ComputerName -Namespace 'root\virtualization\v2' -Class 'Msvm_StorageAllocationSettingData'
	foreach ($VHD in $AllVHDs)
	{
		foreach($VHDPath in $VHD.HostResource)
		{
			if($VHDPath -notin $LocalFilesToRemove -and $VHDPath -notin $RemoteFilesToRemove)
			{
				$ImportantFolders += Split-Path -Path $VHDPath -Parent
			}
		}
	}
	$ImportantFolders = $ImportantFolders | select -Unique
	$RemoteFoldersToScan = $RemoteFoldersToScan | where { $_ -notin $ImportantFolders }
	$LocalFoldersToScan = $LocalFoldersToScan | where { $_ -notin $ImportantFolders }

	Write-Progress -Activity 'Gathinering information' -Status 'Finalizing folder delete list' -PercentComplete 99
	$RemoteFoldersToScan = $RemoteFoldersToScan | select -Unique
	$LocalFoldersToScan = $LocalFoldersToScan | select -Unique
	$AllFoldersToScan = $RemoteFoldersToScan + $LocalFoldersToScan
	try	# because we might have an open PowerShell session and because PS has no goto, we must encap the rest in a t/c/f
	{
		Write-Progress -Activity 'Gathering information' -Status ('Verifying that {0} can accept operations' -f $VMObject.ElementName) -PercentComplete 100
		$VMObject.Get()	# would save a bit of processing time to do this earlier, but safer to wait until the last second in case something changes
		if($VMObject.EnabledState -notin @(2, 3, 6) -or $VMObject.OperationalStatus[0] -ne 2)
		{
			throw('The current state of virtual machine {0} does not allow operations.' -f $VMObject.ElementName)
		}
		Write-Progress -Activity 'Gathering information' -Completed

		if($WhatIf)
		{
			Write-Host -ForegroundColor ([System.ConsoleColor]::Yellow) -Object ('WhatIf: Deleting virtual machine {0} from {1}' -f $VMObject.ElementName, $VMObject.__SERVER)
		}
		if($WhatIf -or -not $Force)
		{
			if($VMObject.EnabledState -eq 2)
			{
				Write-Host -ForegroundColor ([System.ConsoleColor]::Yellow) -Object 'Stop virtual machine'
			}
			elseif($VMObject.EnabledState -eq 6)
			{
				Write-Host -ForegroundColor ([System.ConsoleColor]::Yellow) -Object 'Discard saved state'
			}
			if($ClusteredResources)
			{
				Write-Host -ForegroundColor ([System.ConsoleColor]::Yellow) -Object 'Remove virtual machine from the cluster'
			}
			if($RelatedVMSettings.GetType().BaseType.Name -eq 'Array')
			{
				Write-Host -ForegroundColor ([System.ConsoleColor]::Yellow) -Object 'Apply oldest snapshot (to avoid merges)'
				Write-Host -ForegroundColor ([System.ConsoleColor]::Yellow) -Object 'Destroy snapshots'
			}
			Write-Host -ForegroundColor ([System.ConsoleColor]::Yellow) -Object 'Destroy virtual machine'
			foreach ($FileName in $RemoteFilesToRemove)
			{
				Write-Host -ForegroundColor ([System.ConsoleColor]::Yellow) -Object ('If it is still present, delete file {0} from {1}' -f $FileName, $ComputerName)
			}
			foreach ($FileName in $LocalFilesToRemove)
			{
				Write-Host -ForegroundColor ([System.ConsoleColor]::Yellow) -Object ('If it is still present, delete file {0}' -f $FileName)
			}
			foreach($FolderName in $RemoteFoldersToScan)
			{
				Write-Host -ForegroundColor ([System.ConsoleColor]::Yellow) -Object ('If it is still present AND empty, delete folder {0} from {1}' -f $FolderName, $ComputerName)
			}
			foreach($FolderName in $LocalFoldersToScan)
			{
				Write-Host -ForegroundColor ([System.ConsoleColor]::Yellow) -Object ('If it is still present AND empty, delete folder {0}' -f $FolderName)
			}
		}
		if(-not $WhatIf -and ($Force -or $PSCmdlet.ShouldProcess($VMObject.ElementName, 'Purge')))
		{
			Write-Progress -Activity ('Deleting virtual machine {0}' -f $VMObject.ElementName) -Status 'Loading the virtual machine management service' -PercentComplete 10
			$VMMS = Get-WmiObject -ComputerName $ComputerName -Namespace 'root\virtualization\v2' -Class Msvm_VirtualSystemManagementService
			Write-Progress -Activity ('Deleting virtual machine {0}' -f $VMObject.ElementName) -Status 'Loading the virtual machine snapshot service' -PercentComplete 20
			$VMSS = Get-WmiObject -ComputerName $ComputerName -Namespace 'root\virtualization\v2' -Class Msvm_VirtualSystemSnapshotService
			if($VMMS -eq $null -or $VMSS -eq $null)
			{
				throw ('Could not access virtual machine management service on {0}' -f $ComputerName)
			}

			if($VMObject.EnabledState -in @(2, 6))
			{
				Write-Progress -Activity ('Deleting virtual machine {0}' -f $VMObject.ElementName) -Status 'Stopping the virtual machine' -PercentComplete 30
				$Result = $VMObject.RequestStateChange(3)
				$Outcome = Invoke-Command -ScriptBlock $ProcessWMIJobScriptBlock -ArgumentList @($Result, $VMObject.ClassPath, 'RequestStateChange')
				if ($Outcome)
				{
					throw ('Could not turn off/discard saved state for {0}. {1}' -f $VMObject.ElementName, $Outcome)
				}
			}

			if($IsClustered)
			{
				try
				{
					Write-Progress -Activity ('Deleting virtual machine {0}' -f $VMObject.ElementName) -Status 'Removing from the cluster' -PercentComplete 40
					$VMClusterGroup.DestroyGroup(2)
				}
				catch
				{
					throw ('Cannot remove {0} from cluster. {1}' -f $VMObject.ElementName, $_.Message)
				}
			}

			$OldestSnapshot = $null
			foreach($VMSettingData in $RelatedVMSettings)
			{
				if($VMSettingData.Parent -eq $null -and $VMSettingData.VirtualSystemType -eq 'Microsoft:Hyper-V:Snapshot:Realized')
				{
					$OldestSnapshot = $VMSettingData
				}
			}
			if ($OldestSnapshot -ne $null)
			{
				Write-Progress -Activity ('Deleting virtual machine {0}' -f $VMObject.ElementName) -Status 'Applying the oldest snapshot' -PercentComplete 50
				$Result = $VMSS.ApplySnapshot($OldestSnapshot)
				$Outcome = Invoke-Command -ScriptBlock $ProcessWMIJobScriptBlock -ArgumentList @($Result, $VMSS.ClassPath, 'ApplySnapshot')
				if($Outcome)
				{
					Write-Error -Message ('Unable to apply oldest snapshot to {0}. {1}' -f $VMObject.ElementName, $Outcome)
					if(-not $Force -and -not ($PSCmdlet.ShouldProcess($VMObject.ElementName, 'Merge all snapshots before deleting')))
					{
						throw('Unable to apply oldest snapshot. Merging all snapshots disallowed by user input.')
					}
				}

				Write-Progress -Activity ('Deleting virtual machine {0}' -f $VMObject.ElementName) -Status 'Destroying all snapshots' -PercentComplete 60
				$Result = $VMSS.DestroySnapshotTree($OldestSnapshot)
				$Outcome = Invoke-Command -ScriptBlock $ProcessWMIJobScriptBlock -ArgumentList @($Result, $VMSS.ClassPath, 'DestroySnapshotTree')
				if($Outcome)
				{
					throw ('Unable to remove snapshot tree for {0}. {1}' -f $VMObject.ElementName, $Outcome)
				}
			}

			Write-Progress -Activity ('Deleting virtual machine {0}' -f $VMObject.ElementName) -Status 'Deleting the virtual machine' -PercentComplete 70
			$Result = $VMMS.DestroySystem($VMObject)
			$Outcome = Invoke-Command -ScriptBlock $ProcessWMIJobScriptBlock -ArgumentList @($Result, $VMMS.ClassPath, 'DestroySystem')
			if($Outcome)
			{
				throw ('Unable to delete {0}. {1}' -f $VMObject.ElementName, $Outcome)
			}

			Write-Progress -Activity ('Deleting virtual machine {0}' -f $VMObject.ElementName) -Status 'Deleting any surviving files' -PercentComplete 80
			if($LocalFilesToRemove)
			{
				Invoke-Command -ScriptBlock $FileOrFolderDeleteScriptBlock -ArgumentList @(, $LocalFilesToRemove)
			}
			if($HostIsRemote -and $RemoteFilesToRemove)
			{
				Invoke-Command -ScriptBlock $FileOrFolderDeleteScriptBlock -ArgumentList @(, $RemoteFilesToRemove) -ComputerName $ComputerName
			}

			Write-Progress -Activity ('Deleting virtual machine {0}' -f $VMObject.ElementName) -Status 'Deleting any surviving folders' -PercentComplete 90
			if($LocalFoldersToScan)
			{
				Invoke-Command -ScriptBlock $FileOrFolderDeleteScriptBlock -ArgumentList @(, ($LocalFoldersToScan | sort -Descending))
			}
			if($HostIsRemote -and $RemoteFoldersToScan)
			{
				Invoke-Command -ScriptBlock $FileOrFolderDeleteScriptBlock -ArgumentList @(, ($RemoteFoldersToScan | sort -Descending)) -ComputerName $ComputerName
			}
		} # delete process
	} # encapsulating try
	catch
	{
		Write-Error $_
	}
	finally
	{
		Write-Progress -Activity ('Deleting virtual machine {0}' -f $VMObject.ElementName) -Completed
		if($RemoteSession -ne $null)
		{
			Remove-PSSession -Session $RemoteSession
		}
	}
}
#}						# Uncomment this line to use as dot-sourced function or in a profile. Also the beginning two lines.