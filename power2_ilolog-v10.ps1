# This is the first version (1.0) of power rollback script. 
# It comeback power of the servers that was 'on' before blackout based on ILO power logs.
# Mandatory prerequisites: ILO power option must be always-off at all servers!
#autorization
$user1="Administrator"
$pass1="HP1nvent"
$hostname1="192.168.143.10"

Try
{
    Connect-HPOVMgmt -UserName $user1 -Password $pass1 -Hostname $hostname1
}
Catch
{
 Write-Host -ForegroundColor Red "OneView still not initialized!!"
 Break
}
$data1=Get-HPOVServer
Foreach ($Server1 in $data1)
{
# Get ILO session for inventory
    $ilosession = Get-HPOVServer -Name $Server1.name | Get-HPOVIloSso -IloRestSession
    $ilosession.rootUri = $ilosession.rootUri -replace 'rest','redfish'
    $serverdata1=Get-HPERedfishDataRaw -odataid '/redfish/v1/Chassis/1/power'-Session $iloSession -DisableCertificateAuthentication
    $p1=$Serverdata1.PowerControl.powermetrics.AverageConsumedWatts
    if ($p1 -ne 0) 
        {
        $s1=Get-HPOVServer -Name $Server1.Name
        Write-Host -ForegroundColor Green "Rollback server power for "$s1.Name""
        $server1 | Start-HPOVServer
        }
}

Disconnect-HPOVMgmt
