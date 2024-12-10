if(-not(Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f'" | 
    where licensestatus -eq 1  |   
    Select name, description |
    Format-List  name, description)){
        return "Not Licensed"
        }
else {
    return "Licensed"
    }