# Private folder Check
# Checks folder names to Active Directory accounts; ensuring they are present and active


import-module activedirectory
$ErrorActionPreference = "silentlycontinue"
$alert=0
$error.clear()

# Replace with UNC path of your private folders
$dir = get-childitem \\server\share
($dir).name | foreach-object {
    if ($_.length -gt 20)
    {
        get-aduser -identity "$_".Substring(0,20)  | foreach { 
            if ($_.enabled -like "False") {
                write-host "$_.name is disabled."
                $alert=1
                }
            elseif ($_.DistinguishedName -match "OU=DisabledUsers") {
                write-host "$_.name is in disabled users OU" 
                $alert=1
                }
            }
    }
    else 
    {
        get-aduser -identity $_ | foreach { 
            if ($_.enabled -like "False") {
                write-host "$_.name is disabled."
                $alert=1
                } 
            elseif ($_.DistinguishedName -match "OU=DisabledUsers") {
                write-host "$_.name is in disabled users OU" 
                $alert=1
                }
            }
    }
}
if ($error -ne $null) {
    write-host $error | select-string -pattern "identity"
    exit 1
    }
elseif ($alert -eq 1) {
    exit 1
    }
else {
    write-host "All Private folders match active accounts!"
    exit 0
    }