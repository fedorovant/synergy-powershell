#This is POST Network RestAPI request with PowerShell
#
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
    vlanId='11'
    purpose='General'
    name='vlan11'
    smartLink='true'
    privateNetwork='false'
    ethernetNetworkType='Tagged'
    type='ethernet-networkV4'
   }

$url2 = "https://16.52.176.102/rest/ethernet-networks"
$header2 = @{}
$header2.add("Accept-Language", "en_US")
$header2.add("Auth", "$session1")
$header2.add("X-Api-Version", "600")
$body2 = (ConvertTo-Json $json2)
$result2 = Invoke-RestMethod -Uri $url2 -Method Post -Headers $header2 -Body $body2 -ContentType 'application/json'
return $result2
