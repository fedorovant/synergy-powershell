# This is the first version (1.0) of power rollback script. It comeback power of the servers that was 'on' before blackout
# Mandatory prerequsite: ILO power option must be always-off at all servers!
#
#varibles
$ovip="your OV IP"
$user1="your user"
$pass1="yuor password"
$csvpathresult='c:\temp\serverpower.csv'
$event1=0

Connect-HPOVMgmt -Hostname $ovip -UserName $user1 -Password $pass1
sleep 10

while ($event1 -eq 0)
{
#create data array
$serverstatus= @()
$serverstatus+='ServerName;PowerState'
try 
{
    $conn=Get-HPOVApplianceServiceConsoleAccess
    $server1=Get-HPOVServer
    foreach($s in $server1)
    {
        $serverstatus+=$s.name + ';' + $s.powerstate
    }
    $serverstatus | Out-File $csvpathresult
    Write-Host -ForegroundColor Green "Successfully collect server power data at $csvpathresult"
    sleep 10
}

catch{
      $event1=1
      $event2=0
      Write-Host -ForegroundColor Red "No connection to the HPE OneView"
        while ($event2 -eq 0)
        {        
            sleep 3
        try
        {
            $event2=1
            $test=Get-HPOVEnclosure
            #Connect-HPOVMgmt -Hostname $ovip -UserName $user1 -Password $pass1
            sleep 120
            $serverdata=Import-Csv -Path $csvpathresult -Delimiter ';'
            foreach ($s1 in $serverdata)
            {
                if ($s1.PowerState -like 'On')
                {
                    $server1=Get-HPOVServer -Name $s1.ServerName
                    Write-Host -ForegroundColor Green "Rollback server power for "$s1.ServerName""
                    $server1 | Start-HPOVServer
                }
            }
        }
        catch
        {
            $event2=0
            Write-Host -ForegroundColor Yellow "trying to connect the HPE OneView"
        }
      }
     
       }
}
Disconnect-HPOVMgmt
