# This is the first version of the script that monitor hardware at OneView and move Server profile to another HW by alert event
#
#--------------------uncomment this if you want to connect to OV------------
#write-host -ForegroundColor Yellow "You need to autorize at OneView.."
#$OVIP1 = Read-Host 'What is OV IP?'
#$OVuser1 = Read-Host 'What is OV Username?'
#$OVpass1 = Read-Host 'What is OV Username?' -AsSecureString
#$OVpass11 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($OVpass1))
#Connect-HPOVMgmt -Hostname $OVIP1 -UserName $OVuser1 -Password $OVpass11
#--------------------uncomment this if you want to connect to OV------------
#
$Name0=Get-HPOVServer
$Name10=$Name0.Name
$Name100=$Name0.Count
 
for ($j=0;$j -lt $Name100;$j++)
{
Write-Host -ForegroundColor DarkGreen "$j)" $Name10[$j]
}

#Let Customer choice what Server he want to use for monitoring
$Name100=$Name0.Count-1
$Num1=Read-Host "What Number of Server you want to monitor use 0-$Name100 ?"
$Name1=$Name0[$Num1].Name

$Profile1uri=$Name0[$Num1].serverProfileUri
$profile1=Get-HPOVServerProfile # Identify Server Profile name
foreach ($item in $profile1) {if ($item.uri -eq $Profile1uri ){$Profile1Name=$item.name}}

Write-Host -ForegroundColor Green "==========================="
Write-Host -ForegroundColor Green "We'll monitor - $Name1 with $Profile1Name Server Profile"
Write-Host -ForegroundColor Green "==========================="

$A1=0
$Alert1=0
do 
{
sleep 10
$Alert1=Get-HPOVServer -Name $Name1 | Get-HPOVAlert -Severity Critical -AlertState Active
$Alert2=$Alert1.alertState
$Alert2
if ($Alert2 -eq 'Active')
{
$Alert1
write-host -foreground Red "-------------------------------------------------------------"
write-host -foreground Red "We get error..."
write-host -foreground Red "-------------------------------------------------------------"
Get-HPOVServer -Name $Name1 | Stop-HPOVServer -force -confirm:$False
Sleep 5
write-host -foreground Red "-------------------------------------------------------------"
write-host -foreground Red "Change Profile for new server hardware..."
write-host -foreground Red "-------------------------------------------------------------"
$freeserver1=Get-HPOVServer -NoProfile | Select -first 1
Get-HPOVServerProfile -Name $Profile1Name  | New-HPOVServerProfileAssign -Server $freeserver1 | Wait-HPOVTaskComplete
Get-HPOVServerProfile -Name $Profile1Name  | Start-HPOVServer
$A1=1
}
else
{
write-host -foreground Green "-------------------------------------------------------------"
write-host -foreground Green "System 'RHEL74-VIP' is stable..."
write-host -foreground Green "-------------------------------------------------------------"
}
} until ($A1 -eq 1)
