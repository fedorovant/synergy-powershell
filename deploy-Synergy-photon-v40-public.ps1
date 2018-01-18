# This is thrd version (3.1) of Profile full circle Infrastrucute management as code (IaaC).
# At this Script we're create ESXi host with Image Streamer, Deploy Photon-OS on it, pull and start containers
#Varibles:
# - $PhotonCredential1 - root credential for Photon VM.
# - $TempName1 - Name of Server profile template;
# - $server1 - first free server i the pool;
# - $ZoneName1 - name of DNS zone.
# - $ProfileName1 - Name of the Server Profile at OneView;
# - $IPESXi1 - IP address of provisioned ESXi Host;
# - $ova - OVA/OVF file with PhotonOS. 
# - $VMName1 - name of Phonton VM.
# - $IVCIP1 - IP of Photon VM.
Get-Module HPOneView.400
write-host -ForegroundColor Green "-----------------------------------------------------------------------------------------------------------------"
write-host -ForegroundColor Green "                                                                                                                 "
write-host -ForegroundColor Green "xx     xx  xxxxxxx   xxxxxxxx          xxxxxx  xx     xx  xxx      xx  xxxxxxxx  xxxxxx     xxxxxxxx    xx     xx"
write-host -ForegroundColor Green "xx     xx  xx    xx  xxxxxxxx         xxxxxx    xx   xx   xx xx    xx  xxxxxxxx  xx   xx   xxxxxxxxxx    xx   xx "
write-host -ForegroundColor Green "xx     xx  xx    xx  xx                xx        xx xx    xx  xx   xx  xx        xx   xx  xx              xx xx  "
write-host -ForegroundColor Green "xxxxxxxxx  xx    xx  xxxxxxxx           xx        xx      xx   xx  xx  xxxxxxxx  xxxxxx  xxx      xxxx      xx   "
write-host -ForegroundColor Green "xxxxxxxxx  xxxxxxx   xxxxxxxx            xxx      xx      xx    xx xx  xxxxxxxx  xxxxxx  xxx       xx       xx   "
write-host -ForegroundColor Green "xx     xx  xx        xx                   xxx     xx      xx     x xx  xx        xx   xx  xx       xx       xx   "
write-host -ForegroundColor Green "xx     xx  xx        xxxxxxxx          xxxxxx     xx      xx      xxx  xxxxxxxx  xx    xx  xxxxxxxxxx       xx   "
write-host -ForegroundColor Green "xx     xx  xx        xxxxxxxx         xxxxx       xx      xx       xx  xxxxxxxx  xx     xx  xxxxxxxx        xx   "
write-host -ForegroundColor Green "                                                                                                                 "
write-host -ForegroundColor DarkYellow "Created by Fedorov Anton                                                              "
write-host -ForegroundColor Green "-----------------------------------------------------------------------------------------------------------------"
#----------------------
#Input Photon VM credential
Write-Host -ForegroundColor Cyan "==========================="
Write-Host -ForegroundColor Cyan "Please input Photon VM credential"
Write-Host -ForegroundColor Cyan "==========================="
$PhotonCredential1=Get-Credential
#connect to OneView
#--------------------uncomment this if you want to connect to OV------------
#write-host -ForegroundColor Yellow "You need to autorize at OneView.."
#$OVIP1 = Read-Host 'What is OV IP?'
#$OVuser1 = Read-Host 'What is OV Username?'
#$OVpass1 = Read-Host 'What is OV Username?' -AsSecureString
#$OVpass11 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($OVpass1))
#Connect-HPOVMgmt -Hostname $OVIP1 -UserName $OVuser1 -Password $OVpass11
#--------------------uncomment this if you want to connect to OV------------

$TempName1=Get-HPOVServerProfileTemplate
$Name10=$TempName1.Name
$Name100=$TempName1.Count

if ($Name100 -gt 1)
{

# Show Server Profile Templates on the screen
for ($j=0;$j -lt $Name100;$j++)
{
Write-Host -ForegroundColor DarkGreen "$j)" $Name10[$j]
}

#Let Customer choice what Template he want to use for Deployment
$Name100=$TempName1.Count-1
$Num1=Read-Host "What Number of Profile Template you want to use 0-$Name100 ?"
$TempName=$TempName1[$Num1].Name
$TempName
Write-Host -ForegroundColor Cyan "==========================="
Write-Host -ForegroundColor Cyan "We'll use - $TempName - Template"
Write-Host -ForegroundColor Cyan "==========================="
}

else
{
$TempName=$TempName1[0].Name
$TempName
Write-Host -ForegroundColor Cyan "==========================="
Write-Host -ForegroundColor Cyan "You have only 1 Profile Template. We'll use - $TempName - Template"
Write-Host -ForegroundColor Cyan "==========================="
}

#Let Customer choice - How much hosts he want to deploy
$Numofpr1 = Read-Host 'How much Server Profiles do you want to create?'
$spt=Get-HPOVServerProfileTemplate -Name $TempName

#Servers Deployment
#Create HPE Synergy Profile
$ProfileName10 = Read-Host 'What is profile prefix prefered Name'

for ($i=1;$i -le $Numofpr1;$i++)
{
$ProfileName1="$ProfileName10"+0+"$i"
$server1=Get-HPOVServer -NoProfile -InputObject $spt | Select -first 1
New-HPOVServerProfile -Name $ProfileName1 -ServerProfileTemplate $spt -AssignmentType Server -Server $server1
Get-HPOVServerProfile -Name $ProfileName1 | Start-HPOVServer



#get IP address of ESXi host
$dataProfileName1=Get-HPOVServerProfile -Name $ProfileName1
$p2=$dataProfileName1.osDeploymentSettings.osCustomAttributes
foreach ($item in $p2) {if ($item.name -eq 'ManagementNIC.ipaddress'){$IPESXi1=$item.value}}

write-host -foreground Cyan "-------------------------------------------------------------"
write-host -foreground Cyan "I think that IP address of ESXihost is $IPESXi1"
write-host -foreground Cyan "-------------------------------------------------------------"

#Create DNS Record for ESXi Host:
$ZoneName1 = 'newsynergy.local'
Get-Module DNSServer -ListAvailable
Add-DnsServerResourceRecordA -IPv4Address $IPESXi1 -Name $ProfileName1 -ZoneName $ZoneName1
$serverName1 = "$ProfileName1" + '.' + "$ZoneName1"
}

write-host -foreground Cyan "-------------------------------------------------------------"
do 
{$ping1 = Test-Connection $IPESXi1 -Quiet
write-host -foreground Cyan "waiting for ESXi host boot..."
} until ($ping1 -contains "True")
write-host -foreground Cyan "-------------------------------------------------------------"
sleep 15

#Connect to vCenter 
#--------------------uncomment this if you want to connect to vCenter------------
#write-host -ForegroundColor Yellow "You need to autorize at vCenter Server.."
#$vCIP1 = Read-Host 'What is vCenter Server IP?'
#$vCuser1 = Read-Host 'What is vCenter Server Username?'
#$vCpass1 = Read-Host 'What is vCenter Server Username?' -AsSecureString
#$vCpass11 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($OVpass1))
#connect-viserver -Server $vCIP1 -User vCuser1 -Password $vCpass11
#--------------------uncomment this if you want to connect to vCenter------------

#Import PhotonOS OVA, please choice your own OVA
$ova = "PhotonOS-custom.ova"
$ovacfg = Get-OvfConfiguration $ova
$vmhost = Get-VMHost -Name $serverName1
$ds = get-datastore

write-host -foreground Cyan "-------------------------------------------------------------"
$VMName1 = Read-Host 'What is PhotonOS VM Name?'
write-host -foreground Cyan "-------------------------------------------------------------"

#Prepare some network
$ovacfg.NetworkMapping.Networking.Value = 'VLAN-3001'
Import-VApp -Source $ova -OvfConfiguration $ovacfg -Name $VMName1 -VMHost $vmhost -Datastore $ds -DiskStorageFormat Thin
get-vm -name $VMName1 | Start-VM

#Wait for PhotonOS boot
write-host -foreground Cyan "-------------------------------------------------------------"
$IVCIP=Get-VM -Name $VMName1
$IVCIP1=$IVCIP.Guest.IPAddress[0]
#do{
#sleep 10
#write-host -foreground Cyan "Wait for PhotonOs $VMName1 boot.."
#} until ($IVCIP1 -notlike '10.66*')
#write-host -foreground Cyan "-------------------------------------------------------------"
sleep 120

#Connect to PhotonOS 
$IVCIP=Get-VM -Name $VMName1 | Select @{N="IP Address";E={@($_.guest.IPAddress[0])}}
$IVCIP1=$IVCIP.'IP Address'
write-host -foreground Cyan "-------------------------------------------------------------"
Write-Host "I think that IP address of $VMName1 is $IVCIP1"
write-host -foreground Cyan "-------------------------------------------------------------"

#Create DNS Record for PhotonOS-VM Host:
Get-Module DNSServer -ListAvailable
Add-DnsServerResourceRecordA -IPv4Address $IVCIP1 -Name $VMName1 -ZoneName $ZoneName1
write-host -foreground Cyan "-------------------------------------------------------------"
write-host -foreground Cyan "I add ESXi host - $VMName1 to DNS Server"
write-host -foreground Cyan "-------------------------------------------------------------"
Get-DnsServerResourceRecord -ZoneName $ZoneName1 -Name $VMName1

write-host -foreground Cyan "-------------------------------------------------------------"
write-host -foreground Cyan "Please give PhotonOS Credentials"
write-host -foreground Cyan "-------------------------------------------------------------"

Get-Module Posh-SSH
#Import-Module C:\Users\Administrator\Documents\Posh-SSH\2.0.2\Posh-SSH.psd1
$SSHSession = New-SSHSession -ComputerName $IVCIP1 -Credential $PhotonCredential1 -Verbose
$SSH = $SSHSession | New-SSHShellStream
$SSH.WriteLine( "systemctl start docker" )
sleep 1
$SSH.read()
$SSH.WriteLine( "systemctl enable docker" )
sleep 1
$SSH.read()
$SSH.WriteLine( "docker pull owncloud" )
sleep 1

write-host -foreground Cyan "-------------------------------------------------------------"
write-host -foreground Cyan "Docker start OwnCloud contener..."
write-host -foreground Cyan "-------------------------------------------------------------"
$SSH.WriteLine( "docker run -d -p 80:80 owncloud" )
sleep 1
$SSH.read()

write-host -foreground Cyan "-------------------------------------------------------------"
write-host -foreground Cyan "Container started, You can use web browser" $IVCIP1 "for owncloud connection"
write-host -foreground Cyan "-------------------------------------------------------------"

Disconnect-HPOVMgmt
