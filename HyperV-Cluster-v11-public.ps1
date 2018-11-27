# This is first public version (1.1) of hyper-v cluster managemet with Synergy as a code (IaaC).
# At this Script we're create several hyper-v hosts with Image Streamer, create cluster and add nodes into it.
#Varibles:
# - $Numofpr1 - number of hyper-v hosts for deploy;
# - $winprefix1 - prefix of the hyper-v nodes name;
# - $NewORold1 - boolean for new cluster creation or add node to cluster only;
# - $WinCluster1 - name of the Cluster
# - $cluaddr1 - Cluster IP address;
#--------------------uncomment this if you want to connect to OV------------
#write-host -ForegroundColor Yellow "You need to autorize at OneView.."
#$OVIP1 = Read-Host 'What is OV IP?'
#$OVuser1 = Read-Host 'What is OV Username?'
#$OVpass1 = Read-Host 'What is OV Username?' -AsSecureString
#$OVpass11 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($OVpass1))
#Connect-HPOVMgmt -Hostname $OVIP1 -UserName $OVuser1 -Password $OVpass11
#--------------------uncomment this if you want to connect to OV------------

$Name0=Get-HPOVServerProfileTemplate
$Name10=$Name0.Name
$Name100=$Name0.Count

if ($Name100 -gt 1)
{

# Show Server Profile Templates on the screen
for ($j=0;$j -lt $Name100;$j++)
{
Write-Host -ForegroundColor Cyan "$j)" $Name10[$j]
}
#Let Customer choice what Template he want to use for Deployment
$Name100=$Name0.Count-1
$Num1=Read-Host "What Number of Profile Template you want to use 0-$Name100 ?"
$Name1=$Name0[$Num1].Name
$Name1
Write-Host -ForegroundColor Cyan "==========================="
Write-Host -ForegroundColor Cyan "We'll use - $Name1 - Template"
Write-Host -ForegroundColor Cyan "==========================="
}
else
{
$Name1=$Name0[0].Name
$Name1
Write-Host -ForegroundColor Cyan "==========================="
Write-Host -ForegroundColor Cyan "You have only 1 Profile Template. We'll use - $Name1 - Template"
Write-Host -ForegroundColor Cyan "==========================="
}

#Let Customer choice - How much hosts he want to deploy
$Numofpr1 = Read-Host 'How much Servers do you want to create?'
$Numofpr2=$Numofpr1+1
$spt=Get-HPOVServerProfileTemplate -Name $Name1

$winprefix1=Read-Host "what is the prefix name for nodes?"
$NewORold1=Read-Host "This will be new Cluster(n) or you want to add the nodes(a)?"
if ($NewORold1 -eq 'n') 
{
$NewORold2=1
}
if ($NewORold1 -eq 'a')
{
$NewORold2=0
}
$WinCluster1=Read-Host "What is the cluster name?"
$cluaddr1=Read-Host "What is the cluster IP address?"

#Servers Deployment
$ProfilesTemp1=@()
$ProfilesTemp1+='k'

for ($i=1;$i -le $Numofpr1;$i++)
{
$server1=Get-HPOVServer -NoProfile -InputObject $spt | Select -first 1
New-HPOVServerProfile -Name "$winprefix1-0$i" -ServerProfileTemplate $spt -AssignmentType Server -Server $server1 -Async
$ProfilesTemp1+="$winprefix1-0$i"
}
#wait for server profile creation complete
$taskcompleted1=0
Write-Host -ForegroundColor Red "Profiles Names - $ProfilesTemp1"
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
write-host -ForegroundColor Yellow "$task1percent % - Wait for server profiles creation."
sleep 10
}
}until ($taskcompleted1 -eq 1)
#start all hyper-v servers
for ($i=1;$i -le $Numofpr1;$i++)
{
Get-HPOVServerProfile -Name $winprefix1-0$i | Start-HPOVServer
$dataProfileName1=Get-HPOVServerProfile -Name $winprefix1-0$i
}
#get IP address of Hyper-V host
$p2=$dataProfileName1.osDeploymentSettings.osCustomAttributes
foreach ($item in $p2) {if ($item.name -eq 'ManagementNIC1.ipaddress'){$IPESXi1=$item.value}}
foreach ($item in $p2) {if ($item.name -eq 'DomainAccount'){$domainuser1=$item.value}}

#====================Wait for boot=========
for ($i=1;$i -le 5;$i++)
{
do 
{
  Write-Host -ForegroundColor Yellow "waiting for host boot..."
  sleep 5
} until(Test-NetConnection $IPESXi1 -Port 3389 | ? { $_.TcpTestSucceeded } )
sleep 60
}

write-host -ForegroundColor Cyan "========================================================="
write-host -ForegroundColor Cyan "               Servers boot successfully."
write-host -ForegroundColor Cyan "========================================================="
sleep 15
#Cluster Creation and add nodes
if ($NewORold2 -eq 1){
write-host -ForegroundColor Cyan "========================================================="
write-host -ForegroundColor Cyan "               WE ARE CREATING NEW CLUSTER."
write-host -ForegroundColor Cyan "========================================================="
Install-WindowsFeature –Name Hyper-V -ComputerName $ProfilesTemp1[1] -IncludeManagementTools
$ProfilesTemp2=$ProfilesTemp1[1]
write-host -ForegroundColor Cyan $domainuser1
$p2='WinNT://'+$ProfilesTemp2+'/Administrators,group'
$p3="WinNT://$domainuser1"
write-host -ForegroundColor Cyan $p3
$ro1 = [ADSI]"$p2"
$ro1.psbase.Invoke("Add",([ADSI]"$p3").path)
New-VMSwitch -Name Management -NetAdapterName mgmt_nw_team -AllowManagementOS $true -ComputerName $ProfilesTemp2
sleep 10
Write-Host -ForegroundColor Cyan "Cluster address - $cluaddr1"
New-Cluster -Name $WinCluster1 -Node $ProfilesTemp1[1] -StaticAddress $cluaddr1
sleep 30
for ($i=2;$i -le $Numofpr1;$i++)
{
write-host -ForegroundColor Cyan $ProfilesTemp1[$i]
$ProfilesTemp2=$ProfilesTemp1[$i]
Install-WindowsFeature –Name Hyper-V -ComputerName $ProfilesTemp2 -IncludeManagementTools
$p2='WinNT://'+$ProfilesTemp2+'/Administrators,group'
$p3="WinNT://$domainuser1"
$ro1 = [ADSI]"$p2"
$ro1.psbase.Invoke("Add",([ADSI]"$p3").path)
New-VMSwitch -Name Management -NetAdapterName mgmt_nw_team -AllowManagementOS $true -ComputerName $ProfilesTemp2
Add-ClusterNode -Name $ProfilesTemp2 -Cluster $WinCluster1
}
}
else
{
write-host -ForegroundColor Cyan "========================================================="
write-host -ForegroundColor Cyan "             WE ARE ADDING NODES TO CLUSTER."
write-host -ForegroundColor Cyan "========================================================="
for ($i=1;$i -le $Numofpr1;$i++)
{
write-host -ForegroundColor Cyan $ProfilesTemp1[$i]
$ProfilesTemp2=$ProfilesTemp1[$i]
$p2='WinNT://'+$ProfilesTemp2+'/Administrators,group'
$p3="WinNT://$domainuser1"
$ro1 = [ADSI]"$p2"
$ro1.psbase.Invoke("Add",([ADSI]"$p3").path)
Install-WindowsFeature –Name Hyper-V -ComputerName $ProfilesTemp2 -IncludeManagementTools
New-VMSwitch -Name Management -NetAdapterName mgmt_nw_team -AllowManagementOS $true -ComputerName $ProfilesTemp2
Add-ClusterNode -Name $ProfilesTemp2 -Cluster $WinCluster1
}
}
