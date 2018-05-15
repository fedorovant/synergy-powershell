# This is POST new pofile RestAPI request with PowerShell
#
# You need token for this request
$json1 = @{
      password='HP1nvent'
      userName='administrator'
   }


$url = "https://16.52.176.102/rest/login-sessions"
$header1 = @{}
$header1.add("Accept-Language", "en_US")
$header1.add("X-Api-Version", "600")
$body1 = (ConvertTo-Json $json1)
$result = Invoke-RestMethod -Uri $url -Body $body1 -Method Post -Headers $header1 -ContentType 'application/json'
$session1=$result.sessionID
$session1


$json2 = @{
        type='ServerProfileV8'
        name='Profile101-rest'
        serverHardwareTypeUri='/rest/server-hardware-types/1CE1EABC-5CA8-446C-A506-7F334B4CBBA9'
        enclosureGroupUri='/rest/enclosure-groups/bcf9b58d-aa0f-4f24-b0dd-d9892a77d795'
   }

$url2 = "https://16.52.176.102/rest/server-profiles"
$header2 = @{}
$header2.add("Accept-Language", "en_US")
$header2.add("Auth", "$session1")
$header2.add("X-Api-Version", "600")
$body2 = (ConvertTo-Json $json2)
$result2 = Invoke-RestMethod -Uri $url2 -Method Post -Headers $header2 -Body $body2 -ContentType 'application/json'
return $result2
