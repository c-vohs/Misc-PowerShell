$chromeCheck = tasklist /fi "ImageName eq chrome.exe"
if ($chromeCheck -like "*chrome.exe*"){
    write-host "found chrome"
    }
else {write-host "did not find chrome"}