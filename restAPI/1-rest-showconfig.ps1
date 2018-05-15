# This is example of Get configuration RestAPI request with PowerShell
#
# You need to get token for this request
$json1 = @{
      password='password'
      userName='administrator'
   }


$url = "https://<IP>/rest/login-sessions"
$header1 = @{}
$header1.add("Accept-Language", "en_US")
$header1.add("X-Api-Version", "600")
$body1 = (ConvertTo-Json $json1)
$result = Invoke-RestMethod -Uri $url -Body $body1 -Method Post -Headers $header1 -ContentType 'application/json'
$session1=$result.sessionID
$session1


$url2 = "https://<IP>/rest/global-settings"
$header2 = @{}
$header2.add("Accept-Language", "en_US")
$header2.add("Auth", "$session1")
$header2.add("X-Api-Version", "600")
$result2 = Invoke-RestMethod -Uri $url2 -Method Get -Headers $header2
return $result2
