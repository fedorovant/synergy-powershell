# This is manual return script that get encrypted password and return power state of nodes from CSV file
# Mandatory parameter is CSV file 
#Parameters
[CmdletBinding()]
Param (
[Parameter (Mandatory=$true, Position=1)]
[string]$csvfile
)
#varibles
$user1="administrator"
$pass1 = Get-Content c:\temp\passfile.txt | ConvertTo-SecureString -Key (get-content c:\temp\password_aes.key)
$csvpathresult="c:\temp\power\$csvfile" #need to be param

try{$serverdata=Import-Csv -Path $csvpathresult -Delimiter ';'}
catch{Write-Host -ForegroundColor Red "I can't connect to this CSV file"; break}

$ovip=$serverdata[0].Appliance

Connect-HPOVMgmt -Hostname $ovip -UserName $user1 -Password $pass1

foreach ($s1 in $serverdata)
            {                
                if ($s1.PowerState -like 'On' -or $s1.PowerState -like 'PoweringOn')
                {
                    $server2=Get-HPOVServer
                    foreach ($s2 in $server2)
                    {
                        if ($s2.Name -like $s1.ServerName)
                        {
                            $notempty1=1
                        }
                    }
                    if ($notempty1 -eq 1)
                    {
                        $server1=Get-HPOVServer -Name $s1.ServerName
                        Write-Host -ForegroundColor Green "Rollback server power for "$s1.ServerName""
                        $server1 | Start-HPOVServer
                        $notempty1=0
                    }
                    else
                    {
                        Write-Host -ForegroundColor Yellow "There is no "$s1.ServerName" at this Frame anymore"
                    }
                }
            }

Disconnect-HPOVMgmt
