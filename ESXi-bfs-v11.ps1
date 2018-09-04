# This is the first version of modify ESXi "gold volume" from Storage array.
# This script create server profile, show WWNs and wait for user export boot volume with ESXi golden image for modify.
#$tempVMhostIP - temporary IP address of VMware server
#$profilename1 -  server profile name
#$hostIP1 - IP address of new VMware server
#$wwn1 - WWNs of new VMware server
#--------------------uncomment this if you want to connect to OV------------
#write-host -ForegroundColor Yellow "You need to autorize at OneView.."
#$OVIP1 = Read-Host 'What is OV IP?'
#$OVuser1 = Read-Host 'What is OV Username?'
#$OVpass1 = Read-Host 'What is OV Username?' -AsSecureString
#$OVpass11 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($OVpass1))
#Connect-HPOVMgmt -Hostname $OVIP1 -UserName $OVuser1 -Password $OVpass11
#--------------------uncomment this if you want to connect to OV------------

$tempVMhostIP='192.168.1.99'

$profilename1 = Read-Host 'What is new server profile name?'
$hostIP1 = Read-Host 'What is new host management ip?'

$Name0=Get-HPOVServerProfileTemplate
$Name10=$Name0.Name
$Name100=$Name0.Count

if ($Name100 -gt 1)
{

# Show Server Profile Templates on the screen
for ($j=0;$j -lt $Name100;$j++)
{
Write-Host -ForegroundColor DarkGreen "$j)" $Name10[$j]
}

#Let Customer choice what Template he want to use for Deployment
$Name100=$Name0.Count-1
$Num1=Read-Host "What Number of Profile Template you want to use 0-$Name100 ?"
$Name1=$Name0[$Num1].Name
Write-Host -ForegroundColor Cyan "==========================="
Write-Host -ForegroundColor Cyan "We'll use - $Name1 - Template"
Write-Host -ForegroundColor Cyan "==========================="
}

else
{
$Name1=$Name0[0].Name
Write-Host -ForegroundColor Cyan "==========================="
Write-Host -ForegroundColor Cyan "You have only 1 Profile Template. We'll use - $Name1 - Template"
Write-Host -ForegroundColor Cyan "==========================="
}

$server1=Get-HPOVServer -NoProfile -InputObject $spt | Select -first 1
#$task1=New-HPOVServerProfile -Name esxi-bfs-01 -ServerProfileTemplate $spt -AssignmentType Server -Server $server1 -Async
New-HPOVServerProfile -Name $profilename1 -ServerProfileTemplate $Name1 -AssignmentType Server -Server $server1 -Async
sleep 5
$wwn1temp=Get-HPOVServerProfile -Name $profilename1
$wwn1=$wwn1temp.connectionSettings.connections.wwpn
write-host -ForegroundColor Cyan "========================================================="
write-host -ForegroundColor Cyan "Your wwns - $wwn1"
write-host -ForegroundColor Cyan "========================================================="
$taskcompleted1=0

do
{
$task1=Get-HPOVTask -State Running | ?{$_.Name -eq "Create"}
$task1percent=$task1.percentComplete
if ($task1 -eq $null) 
{
$taskcompleted1=1
}
else
{
write-host -ForegroundColor Yellow "$task1percent % - Wait for server profile creation. You still have time for zoning and lun presenting"
sleep 10
}
}until ($taskcompleted1 -eq 1)

#Check for 'Critical' state of Profile
$profilestate1temp=Get-HPOVServerProfile -Name $profilename1
$profilestate1=$profilestate1temp.status
if ($profilestate1 -eq "Critical")
{
$taskcompleted1=0
write-host -ForegroundColor Red "========================================================="
write-host -ForegroundColor Red "Profile with Errors!"
do
{
$question1=Read-Host 'Do you still need a time for volume creatin?(y/n)'
if ($question1 -eq 'y') {$taskcompleted1=0}
elseif ($question1 -eq 'n') {$taskcompleted1=1;Get-HPOVServerProfile -Name $profilename1 |  New-HPOVServerProfileAssign}
else {$taskcompleted1=0; Write-Host -ForegroundColor Red 'You need to write y or n'}
}until ($taskcompleted1 -eq 1)
write-host -ForegroundColor Red "========================================================="
}
else
{
write-host -ForegroundColor Cyan "========================================================="
write-host -ForegroundColor Cyan "Profile created successfully."
write-host -ForegroundColor Cyan "========================================================="
}
write-host -ForegroundColor Cyan "Powering on the server $profilename1"
write-host -ForegroundColor Cyan "========================================================="
Get-HPOVServerProfile -Name $profilename1 | Start-HPOVServer
Write-Host -ForegroundColor Cyan "==========================="
Write-Host -ForegroundColor Cyan "We'll use - $tempVMhostIP - as temp IP for ESXi"
Write-Host -ForegroundColor Cyan "==========================="

#====================Wait for boot=========
do {
  Write-Host -ForegroundColor Yellow "waiting for host boot..."
  sleep 5
} until(Test-NetConnection $tempVMhostIP -Port 22 | ? { $_.TcpTestSucceeded } )
sleep 120
write-host -ForegroundColor Cyan "========================================================="
write-host -ForegroundColor Cyan "Server $profilename1 boot successfully."
write-host -ForegroundColor Cyan "========================================================="



Connect-VIServer -Server 192.168.1.99 -User root -Password HP1nvent -Force
Get-VMHostNetworkAdapter -VMKernel | Set-VMHostNetworkAdapter -IP $hostIP1 -SubnetMask 255.255.255.0 -confirm:$False -ErrorAction SilentlyContinue
Disconnect-VIServer -Confirm:$false
write-host -ForegroundColor Yellow "IP address changed successfully.."
