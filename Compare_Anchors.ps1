clear-host

$username  = ""  #like jsmith
$wholename = "" #like "John Smith"

$array1 = @()
$localresult = ""
$cloudresult = ""

#local ldap query

#necessary conversion to "decode" the ObjectGUID
$guid =(Get-ADUser $username).Objectguid
$immutableID=[system.convert]::ToBase64String($guid.tobytearray())

#if you want to get everyone
# Get-ADUser -properties * -LDAPFilter '(&(objectClass=User)(whenChanged>=20240213170000.0Z))' | fl DisplayName, EmailAddress, whenChanged, ObjectGUID, objectSID

#for a single user
$localresult = get-aduser $username -property * | select DisplayName, EmailAddress, WhenChanged, ObjectGUID, @{name="ObjectGUID Converted to ImmutableId";expression={$immutableID}}, ObjectSID | fl


#azure/entra query

try {
    # Check if already connected
    if ((Get-AzureADUser) -ne $null) {
        Write-Output "Already connected to Azure AD."
    } else {
        Connect-AzureAD -ErrorAction Stop
        Write-Output "Successfully connected to Azure AD."
    }
} catch {
    Connect-AzureAD -ErrorAction Stop
#Write-Output "Failed to connect to Azure AD. Error: $_"
}


$cloudresult = Get-AzureADUser -All $true | Where-Object {$_.DisplayName -like "*" + $wholename + "*"} | select DisplayName, UserPrincipalName, LastDirSyncTime, ImmutableId, OnPremisesSecurityIdentifier

$array1 += "LOCAL AD"
$array1 += $localresult
$array1 += "`n`n`n"
$array1 += "AZURE/ENTRA AD"
$array1 += $cloudresult

clear-host
write-output $array1
#dont use write-host as it wont preserve formatting


#need a blank line to run
