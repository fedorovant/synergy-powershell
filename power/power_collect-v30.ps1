# This script collect power state of Synergy nodes and react for appliance status. 
# If the status offline - script start to collect individual appliance file with power status of servers.
#varibles
$gdip="your GD IP"
$user1="yuor GD user"
$pass1 = Get-Content c:\temp\passfile.txt | ConvertTo-SecureString -Key (get-content c:\temp\password_aes.key)
$csvpath='c:\temp\power\'
$csvpathresult ='c:\temp\power\serverpowerGD.csv'
$csvalarm='zero.csv'
$event1=0
$encstatus=@()
#$encstatus+='zero'
$N=0

#Comments
#Lag for Composer offline ~2:30 min
#Lag for Composer online ~7:30 min

function CollectServerInfo
{
    #create data array
    $serverstatus= @()
    $serverstatus+='ServerName;PowerState;ServerSerial;FrameSerial'
    $server1=Get-OVGDServerHardware
    foreach($s in $server1)
    {
        # Get only Synergy or Blades information
        if ($s.name -match 'bay ')
        {
            $enc1=Get-OVGDEnclosure
            foreach ($e in $enc1)
            {
                if ($e.Name -like $s.applianceName){$esn=$e.SerialNumber}
            }
            $serverstatus+=$s.name + ';' + $s.powerstate + ';' + $s.serialNumber + ';' + $esn
        }
    }
    $serverstatus | Out-File $csvpathresult
    Write-Host -ForegroundColor Green "Successfully collect server power data at $csvpathresult"
}

#---------------main script-----------
Connect-OVGD -Server $gdip -UserName $user1 -Password $pass1 -Directory local

while ($event1 -eq 0)
{
CollectServerInfo

$ovoff=Get-OVGDAppliance -State Offline
if ($ovoff -ne $null)
{
    $server2=Get-OVGDServerHardware
    Write-Host -ForegroundColor Red "We have this appliances offline:", $ovoff.name
    
    foreach ($c in $ovoff)
    {
        $enc2=Get-OVGDEnclosure
            foreach ($e2 in $enc2)
            {
                if ($e2.Name -like $c.applianceName){$esn2=$e2.SerialNumber}
            }
        $serverstatusalarm= @()
        $serverstatusalarm+="ServerName;PowerState;Appliance"
        $csvalarm = $csvpath + $c.name + $esn2 + '.csv'
        foreach ($s2 in $server2)
        {
            if ($s2.applianceName -like $c.name)
            {
               $serverstatusalarm+=$s2.name + ';' + $s2.powerstate + ';' + $c.applianceLocation
            }
        }
    $serverstatusalarm | Out-File $csvalarm
    $name1=$c.name
    Write-Host -ForegroundColor Yellow "We save emergency CSV for $name1 at $csvalarm"
    }
}
sleep 10
}
Disconnect-OVGD
