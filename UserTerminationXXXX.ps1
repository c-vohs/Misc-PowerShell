#Requires -Module ActiveDirectory
#Requires -Module AzureAD
#Requires -Version 5.0

<#
.SYNOPSIS
  Performs all needed functions to terminate a user from the ENERFAB.NET Domain.
    * $DisabledOU inside the Move-User function will need to be changed if any company
        other than BESCO uses this script, disabled OU is currently set to go to BESCO Disabled.

.DESCRIPTION
    This script was created to make offboarding any employee relatively east and pain free 
    for the IT department. 

    Below is a description of all functions in this script. 

    Connect-Resources - Connects to AzureAD and Exchange Online PowerShell
    Validate-User - Determines if the variable passed for $TermUser is valid and in AD
    Remove-O365Licenses - Gets and then removes assigned O365 licenses for the user specified
    Remove-Groups - Removes all groups the user is in except for the primary group
    Change-PW - Changes the password to a random 10 character password
    Convert-Mailbox - If the mailbox is not Shared, it converts it to a shared mailbox
    Change-Fields - Removes logon script and manager
    Disable-User - Disables the user in AD and O365 and blocks sign in
    Move-User - Moves the user from the OU they are in to the specified Disabled users OU
    User-Folder - FUNCTIONALITY NOT YET AVAILABLE - This will detect and move a users "U" Drive
    Terminate-User - Runs all of the above functions


.PARAMETER TermUser
    The USERNAME of the employee to be terminated will be processed using this parameter.
    
.PARAMETER AdminEmail
    This is the email address you use to login to the online Exchange Console, 
        should be the email of your Admin O365 account.

.NOTES
         Version: 1.3
          Author: Jason Witten, IT Manager, BESCO
   Creation Date: 8-5-2018
  Purpose/Change: To automate the termination process.
                   Shortened the script lengths and changed most Read-Host statements into passable parameters.
                   Converted most operations into functions.
     Requirement: This script must be run in the Microsoft Exchange Online PowerShell Module
                    MUST USE INTERNET EXPLORER... I know...
                    It can be downloaded from:
                    Office Portal->Admin->Exchange Admin Center->Hybrid->Configure Exchange Online Module (MFA)
  
.EXAMPLE
    Jason Witten processing the termination of user John Smith.
  .\<ScriptName>.ps1 -TermUser JSmith -AdminEmail jwitten@besco.com 

#>

param
(
    [parameter(mandatory=$true,
    HelpMessage="Enter the USERNAME of the user who was terminated.")]
    [String]$TermUser,
    [parameter(mandatory=$true,
    HelpMessage="Enter the email address of your Exchange Online account.")]
    [String]$AdminEmail
)
# Change the title and foreground/background colors
[Console]::Title = "XXXXX - Terminate User Script v1.3"
#[console]::ForegroundColor = "Green"
#[console]::BackgroundColor = "black"
#Clear-Host
#
# Do not show import progress
$ProgressPreference = "SilentlyContinue"
# Set default error action to stop
$ErrorActionPreference = "Stop"

# Connect to AzureAD and Exchange Online PowerShell
function Connect-Resources {
    param
    (
    [parameter(mandatory=$false,
    HelpMessage="Enter the email address of your Exchange Online account.")]
    [String]$AdminEmail
    )
    try {
        # Connects with an authenticated account to use Active Directory cmdlet requests.
        Clear 
        Write-Host "Attempting to connect to AzureAD..." -ForegroundColor Cyan
        Connect-AzureAD -ErrorAction Stop
        Write-Host "Done..." -ForegroundColor Green
        # Connect to Exchange Online PowerShell using multi-factor authentication.
        if(!($AdminEmail)) {
            Read-Host "What is your email address to connect to Exchange online?"
        }
        Write-Host "Attempting to connect to Exchange Online PowerShell..." -ForegroundColor Cyan
        Write-Host "This may take a minute to import the commands..." -ForegroundColor Yellow
        #
        # The $WarningAction variable is a workaround to suppress the warning that 
        # Connect-EXOPSSession gives about importing commands.
        $WarningPreference = "SilentlyContinue"
        Connect-EXOPSSession -UserPrincipalName $AdminEmail -ErrorAction Stop
        $WarningPreference = "Continue"
        Write-Host "Done..." -ForegroundColor Green
        Write-Host "Successfully connected. Continuing on..." -ForegroundColor Green
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-Host "There was a problem with the Connect-Resources function."
        Write-Host "Error: $($_)"
    }

} # END Connect-Resources FUNCTION


function Validate-User {
    param 
    (
    [parameter(mandatory=$false,
    HelpMessage="Enter the USERNAME of the user who was terminated.")]
    [String]$UserName
    ) 
    try {
        Do {
            if(!($UserName)) {
                clear
                $UserName = Read-Host "Enter USERNAME of the employee to terminate"
            }
            Write-Host "Checking if $TermUser is a valid user..." -ForegroundColor Green

            If ($(Get-ADUser -Filter {SamAccountName -eq $UserName})) {
                $Global:User = Get-ADUser $UserName -Properties *
                Write-host 
                Write-Host "======================================="
                Write-Host "              SELECTED USER            "
                Write-Host
                Write-Host "   Display name: " $User.DisplayName
                Write-Host " Principal Name: " $User.UserPrincipalName
                Write-Host "             OU: " $User.DistinguishedName
                Write-Host "        Enabled: " $User.Enabled
                Write-Host 
                Write-Host
                Write-Host "ARE YOU SURE THIS IS THE USER YOU ARE LOOKING FOR" -ForegroundColor Red
                Write-Host

                $Proceed = Read-Host "Continue? (y/n)"

                if ($Proceed -eq 'y') {
                    $Exit = $true
                    Write-Host "**WARNING**" -ForegroundColor Yellow
                    Write-Host "This is a big deal and will change a bunch off technical stuff you probably dont understand." -ForegroundColor Yellow
                    $Global:Continue = Read-Host "Do you wish to continue?(y/n)"
                    return $true
                } else {
                    Clear
                    $SearchAgain = Read-Host "Search for another user? (y/n)"
                    if ($SearchAgain -eq "y") {
                        $Exit = $false
                        $UserName = ""
                    } else {
                        $Exit = $true
                    }
                }
            } else {
                Write-Host "$UserName was not a valid user" -ForegroundColor Red
                Start-Sleep 4
                $Exit = $false
                return $false
            }
        } until ($Exit -eq $true)
    } catch {
        Write-Host "There was a problem with the Validate-User function."
        Write-Host "Error: $($_)"
    }
} # END Validate-User FUNCTION

function Remove-O365Licenses {
    try {
        # Get and then remove all assigned O365 licenses
        $Licenses = Get-AzureADUserLicenseDetail -ObjectId $User.UserPrincipalName 
        $Licenses | 
                foreach { 
                    $Body = @{
                            addLicenses = @() 
                            removeLicenses= @($_.SkuID)
                            }
                    Set-AzureADUserLicense -ObjectId $User.UserPrincipalName -AssignedLicenses $Body 
                    Write-Host "Removing license $($_.SkuPartNumber)"
                }
        # Force log off all current sessions
        Get-AzureADUser -ObjectId $User.UserPrincipalName | Revoke-AzureADUserAllRefreshToken
    } catch {
        Write-Host "There was a problem with the Remove-O365Licenses function."
        Write-Host "Error: $($_)"   
    }
} # END Remove-O365Licenses FUNCTION

function Remove-Groups {
    try {
        # Get the groups the selected user is a member of
        [array]$Groups = Get-ADPrincipalGroupMembership $User | Select-Object Name 
        Write-Host "Starting group removal..." -ForegroundColor Green
        # Remove user from all groups except Primary Gropup "Domain Users"
        foreach ($Group in $Groups) {
            if($Group.Name -ne "Domain Users") {
                Write-Host "Removing Group" $Group.Name -ForegroundColor Cyan
                Remove-ADGroupMember -Identity $Group.Name -Members $User -Confirm:$false
                Start-Sleep -Milliseconds 250
            }
        }
        Write-Host "Group removal complete." -ForegroundColor Green
    } catch {
        Write-Host "There was a problem with the Remove-Groups function."
        Write-Host "Error: $($_)"       
    }
} # END Remove-Groups FUNCTION

function Change-PW {
    try {
        # Generate new password 15 characters long with a minimum of 2 special characters
        $NewPW = [System.Web.Security.Membership]::GeneratePassword(15,2)
        Write-Host "Changing user PW to something random... $($NewPW)" -ForegroundColor Cyan
        Start-Sleep -Milliseconds 250
        # Convert NewPW to secure string or it will error out when setting
        $NewPW = ConvertTo-SecureString -String $NewPW -AsPlainText -Force
        # Set the users PW
        Set-ADAccountPassword -Identity $User -NewPassword $NewPW -Reset
        Write-Host "Done..." -ForegroundColor Green
    } catch {
        Write-Host "There was a problem with the Change-PW function."
        Write-Host "Error: $($_)"    
    }
} #END Change-PW FUNCTION

function Convert-Mailbox {
    try {
        # Determine the mailbox type
        Write-Host "Checking users mailbox type..." -ForegroundColor Cyan
        $MailboxType = Get-Mailbox -Identity $User.UserPrincipalName
        Write-Host "User $($User.UserPrincipalName) is $($MailboxType.RecipientTypeDetails)"
        # If the mailbox is not already Shared, convert it
        if(!($MailboxType.RecipientTypeDetails -eq "SharedMailbox")) {
            Write-Host "The users mailbox in not a shared mailbox." -ForegroundColor Cyan
            Write-Host "Converting it now..." -ForegroundColor Cyan
            Set-Mailbox -Identity $User.UserPrincipalName -Type Shared
            Write-Host "Done..." -ForegroundColor Green
        }
    } catch {
        Write-Host "There was a problem with the Convert-Mailbox function."
        Write-Host "Error: $($_)"        
    }
} # END Convert-Mailbox FUNCTION

function Change-Fields {
    try {
        # Clearing the logon script and manager
        Set-ADUser -Identity $User -Clear ScriptPath, Manager
        Write-Host "Removing logon script and Manager from user." -ForegroundColor Cyan
    } catch {
        Write-Host "There was a problem with the Change-Fields function."
        Write-Host "Error: $($_)"        
    }
} # END Change-Fields FUNCTION

function Disable-User {
    try {
        if($User.Enabled -eq $true) {
            Write-Host "Disabling user $($TermUser.Name)" -ForegroundColor Cyan
            # Disable AD account
            Set-ADUser -Identity $User -Enabled:$false
            # Disable user in O365, blocking sign-in immediately
            Set-AzureADUser -ObjectId $user.UserPrincipalName -AccountEnabled:$false
            Write-Host "Done..." -ForegroundColor Green
            # Changing the users description to "Disabled - <DATE>"
            Write-Host "Changing user description to Disabled - $(Get-Date -Format MM-dd-yyyy)"
            Set-ADUser -Identity $User -Description "Disabled - $(Get-Date -Format MM-dd-yyyy)"
            Set-ADUser $User -Add @{msExchHideFromAddressLists="TRUE"}
        } else {
            Write-Host "Account Already disabled." -ForegroundColor Red
        }
    } catch {
            Write-Host "There was a problem with the Disable-User function."
            Write-Host "Error: $($_)"
    }
} # END Disable-User FUNCTION

function Move-User {
    try {
        # Move user to specified disabled accounts OU
        $DisabledOU = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        Move-ADObject -Identity $User.DistinguishedName -TargetPath $DisabledOU
        Write-Host "Moving $($User.Name) to Disabled accounts."
        Write-Host "Location: $($DisabledOU)"
        Write-Host "Done ..." -ForegroundColor Green
    } catch {
        Write-Host "There was a problem with the Move-User function."
        Write-Host "Error: $($_)"
    }
} # END Move-User FUNCTION

function User-Folder {
    # determine if user has a U drive
    # remove permissions
    # move U drive to disabled folder

} # END User-Folder FUNCTION

function Terminate-User {
    Remove-Groups
    Change-PW
    Convert-Mailbox
    Remove-O365Licenses
    Change-Fields
    Disable-User
    Move-User
    # User-Folder - Functionality not yet created for this.

    # Logging functions
    $LogPath = "\\XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\Log\TerminateUser.log"
    $LogData = "$($AdminEmail) ran this script to terminate user $($TermUser) on $(Get-Date -Format g)" |
        Out-File -FilePath $LogPath -Append
} # END Terminate-User FUNCTION

$ConnectionSuccess = Connect-Resources -AdminEmail $AdminEmail

if($ConnectionSuccess) {
    $Valid = Validate-User -UserName $TermUser
    if($Valid -and $Continue -eq "y") {
        Terminate-User
    } else {
        Write-Host "Account was not changed for user $($User.Name)" -ForegroundColor Cyan
    }
} else {
    Clear
    Write-Host
    Write-Host "Exiting Program..." -ForegroundColor 
    Write-Host
}

Get-PSSession | Remove-PSSession
Disconnect-AzureAD