# Original script by jullienl available here: https://github.com/jullienl/HPE-Synergy-OneView-demos/blob/master/Powershell/Virtual%20Connect/Set-netopUser.ps1
# I only modified part for OV 5.0 and change type from webRequest for invokeRequest
#
#This script sets the password for the netop VC CLI user in the Synergy VC interconnects
#
# Note: netop user is only supported for Virtual Connect SE 40Gb F8 Modules and Virtual Connect SE 100Gb F32 Modules for Synergy.
#
# In OneView 4.20 we change the netop configuration because previously existing default/hardcoded password was considered a security issue. 
#
# New behavior is:
#
# - Existing LE update from earlier version to OV 4.20 or later will preserve the netop/netoppwd user/password combo for all modules
# - New LE in OV 4.20 or later will not have default netop user configured and will require REST API to enable it
#
# Script requirements: Composer 4.20
# OneView Powershell Library is not required
# 
# Note: If using a OneView Self-signed certificate, it is required to uncomment line 42


# Defining the netop VC CLI user password
$netoppwd = "netoppwd"


# Composer information
$username = "Administrator"
$password = "admin"
$composer = "synergy.demo.local"
 

function Failure {
    $global:helpme = $bodyLines
    $global:helpmoref = $moref
    $global:result = $_.Exception.Response.GetResponseStream()
    $global:reader = New-Object System.IO.StreamReader($global:result)
    $global:responseBody = $global:reader.ReadToEnd();
    Write-Host -BackgroundColor:Black -ForegroundColor:Red "`nStatus: A system exception was caught."
    Write-Host -BackgroundColor:Black -ForegroundColor:Red `n$global:responsebody
    Write-Host -BackgroundColor:Black -ForegroundColor:Red "`nThe request body has been saved to `$global:helpme"
    #break
}

# Uncomment the following line if facing the error: "The underlying connection was closed: Could not establish trust relationship for the SSL/TLS secure channel."  (usually due to using a OneView Self-signed certificate)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}


#Creation of the header
$headers = @{ } 
$headers.add("Accept-Language", "en_US")
$headers.add("X-Api-Version", "1200")


#Creation of the body
#$Body = @{userName = $username; password = $password; authLoginDomain = "Local"; loginMsgAck = "true" } | ConvertTo-Json 
$json1 = @{
      password=$password
      userName=$username
   }

$Body = (ConvertTo-Json $json1)

#Opening a login session with Composer
$result = Invoke-RestMethod -Uri "https://$composer/rest/login-sessions" -Body $Body -Method Post -Headers $headers -ContentType 'application/json'
$session=$result.sessionID
$session

#Capturing the Composer Session ID and adding it to the header
$headers.add("Auth", "$session")

#Retrieving interconnect URI information for all VC 40G modules
$interconnects = (invoke-webrequest -Uri "https://$composer/rest/interconnects" -Headers $headers -Method Get ).content | ConvertFrom-Json
$interconnecturis = ($interconnects.members | Where-Object model -match "Virtual Connect SE 40Gb F8 Module for Synergy").uri

#Preparing body to change the netop password
#$operation = '   { "op" : "replace", "path" : "/netOpPasswd", "value" : "' + $netoppwd + '" }'
#$payload = "[`n" + $operation + "`n]"

$payload = ConvertTo-Json  @( @{ op = "replace"; path = "/netOpPasswd" ; value = $netoppwd } ) 

#Setting up the netop user with the $netoppwd variable
Foreach ($interconnecturi in $interconnecturis) {
    
    $link = $composer + $interconnecturi

    try {
         Invoke-RestMethod -Uri "https://$link/" -Headers $headers -Body $payload -Method Patch -ContentType 'application/json'
         Write-Host -ForegroundColor Cyan "Change password for $netoppwd at $interconnecturi"
    }
    catch {

        failure

    }

}
