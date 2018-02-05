# This is second version (2.0) of Profile creation from Template script
#
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
Write-Host -ForegroundColor DarkGreen "$j)" $Name10[$j]
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
$Numofpr1 = Read-Host 'How much Server Profiles do you want to create?'
$spt=Get-HPOVServerProfileTemplate -Name $Name1

#Servers Deployment
for ($i=1;$i -le $Numofpr1;$i++)
{
$server1=Get-HPOVServer -NoProfile -InputObject $spt | Select -first 1
New-HPOVServerProfile -Name esxi-0$i -ServerProfileTemplate $spt -AssignmentType Server -Server $server1 -Async
#Get-HPOVServerProfile -Name esxi-0$i | Start-HPOVServer
}
