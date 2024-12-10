#Script written by Chris Vohs
#Adds multiple local users
#Needs a userlist.csv saved to C:\temp\ directory
#Columns named as follows:
#username,password,admin
#admin column will add user to local administrators group if equal to yes
#Writes log file to C:\kworking\klogs\create_users.log

#Last revision: 2/14/20



$strComputer=$env:computername

$Logfile = "C:\kworking\Klogs\create_users.log"

Function LogWrite{
   Param ([string]$logstring)
   Add-content $Logfile -value $logstring
}

LogWrite ("------------------------------------------------------------")
LogWrite ("Running Create Multiple Users script. Date and time:")
LogWrite (Get-Date)

foreach ($user in (Import-CSV "C:\temp\userlist.csv")) {
    LogWrite ("Start loop for:")
    LogWrite ($user.username)

    $colUsers = ($Computer.psbase.children | Where-Object {$_.psBase.schemaClassName -eq "User"} | Select-Object -expand Name)

    If ($colUsers -contains $user.username){
        LogWrite ("The account already exists")
    }

    Else{
        LogWrite ("The account doesn't exist. Creating account.")
        $objOU = [adsi]"WinNT://."
        $objUser = $objOU.Create("User", $user.username)
        $objuser.setPassword($user.password)
        $objuser.setinfo()
        Set-LocalUser -Name $user.username -PasswordNeverExpires 1

        LogWrite ("User admin: ")
        LogWrite ($user.admin)

        if ($user.admin -eq "yes"){
            LogWrite ("Adding account to local administrators")
            $computer = [ADSI]("WinNT://" + $strComputer + ",computer") 
            $group = $computer.psbase.children.find("Administrators")  
            $group.Add("WinNT://" + $strComputer + "/" + $user.UserName) 
        }
    }
}