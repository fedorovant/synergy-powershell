
#This is example of Rest request at PowerShell for add DL\appollo server in OneView with "force" option
#
#---configure self-signed certificate and https access---
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#----varibles---
$url0 = "https://192.168.143.210"
$url = "$url0/rest/login-sessions"

#----create session token---
$json1 = @{
      userName='administrator'
      password='admin'
      authLoginDomain='local'
   }

$header1 = @{}
$header1.add("Accept-Language", "en_US")
$header1.add("X-Api-Version", "2")
$body1 = (ConvertTo-Json $json1)
$result = Invoke-RestMethod -Uri $url -Body $body1 -Method Post -Headers $header1 -ContentType 'application/json'
$session1=$result.sessionID
#$session1

#-----add new server----
$json2 = @{
      hostname='192.168.143.202' #ILO IP and credentials
      username='hpadmin'
      password='password'
      force='true'
      licensingIntent='OneView'
      configurationState='Monitored'
   }
#
$url2 = "$url0/rest/server-hardware"
$header2 = @{}
$header2.add("Accept-Language", "en_US")
$header2.add("Auth", "$session1")
$header2.add("X-Api-Version", "2")
$body2 = (ConvertTo-Json $json2)
$result2 = Invoke-RestMethod -Uri $url2 -Body $body2 -Method Post -Headers $header2 -ContentType 'application/json'

return $result2

