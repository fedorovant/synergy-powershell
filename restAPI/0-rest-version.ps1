#This is simple example for transfer Get-version Rest request at PowerShell
#
#function Get-RESTversion1
#{
#process
#    {
    $url = "https://16.52.176.102/rest/version"
    $header1 = @{}
    $header1.add("Accept-Language", "en_US")
    $body = @()
    $result = Invoke-RestMethod -Uri $url -Method Get -Headers $header1
    return $result
#    }
#}
