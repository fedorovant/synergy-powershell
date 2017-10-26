# This is first version (1.0) of Profile creation from Template script
#
#--------------------uncomment this if you want to connect to OV------------
#write-host -ForegroundColor Yellow "You need to autorize at OneView.."
#$OVIP1 = Read-Host 'What is OV IP?'
#$OVuser1 = Read-Host 'What is OV Username?'
#$OVpass1 = Read-Host 'What is OV Username?' -AsSecureString
#$OVpass11 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($OVpass1))
#Connect-HPOVMgmt -Hostname $OVIP1 -UserName $OVuser1 -Password $OVpass11
#--------------------uncomment this if you want to connect to OV------------

$Name1 = Read-Host 'Whhat is the name of ProfileTemplate?'
$Numofpr1 = Read-Host 'How much Server Profiles you want to create?'

$spt=Get-HPOVServerProfileTemplate -Name $Name1
for ($i=1;$i -like $Numofpr1;$i++)
{
$server1=Get-HPOVServer -NoProfile -InputObject $spt | Select -first 1
New-HPOVServerProfile -Name esxi-0$i -ServerProfileTemplate $spt -AssignmentType Server -Server $server1
Get-HPOVServerProfile -Name esxi-0$i | Start-HPOVServer
}
