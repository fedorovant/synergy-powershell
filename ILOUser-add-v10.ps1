#This is first version (1.0) of ILO user add script for all servers throught SSO token with POSH-OV module
#
#--------------------uncomment this if you want to connect to OV------------
#write-host -ForegroundColor Yellow "You need to autorize at OneView.."
#$OVIP1 = Read-Host 'What is OV IP?'
#$OVuser1 = Read-Host 'What is OV Username?'
#$OVpass1 = Read-Host 'What is OV Username?' -AsSecureString
#$OVpass11 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($OVpass1))
#Connect-HPOVMgmt -Hostname $OVIP1 -UserName $OVuser1 -Password $OVpass11
#--------------------uncomment this if you want to connect to OV------------

Disable-HPRESTCertificateAuthentication

write-host -ForegroundColor Yellow "Please Choose ILO credentials...."

$ILOuser1 = Read-Host 'What is ILO Username?'
$ILOpass1 = Read-Host 'What is ILO password?' -AsSecureString
$ILOpass11 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ILOpass1))

$Num1=Get-HPOVServer | Measure-Object
$Num2=$Num1.Count

write-host -ForegroundColor Yellow "You have $Num2 Servers...."
sleep 1

$server1=Get-HPOVServer
for ($i=0;$i -lt $Num2; $i++) {
$IloSession = Get-HPOVServer -Name $server1[$i].name | Get-HPOVIloSso -IloRestSession
#$UserILO1=Get-HPRESTDataRaw -Href "/rest/v1/AccountService/Accounts" -Session $IloSession

##---User data---
$PrivList = @(
    'RemoteConsolePriv',
    'iLOConfigPriv',
    'VirtualMediaPriv',
    'UserConfigPriv',
    'VirtualPowerAndResetPriv')
$priv = @{}
    foreach ($p in $PrivList)
    {
      $priv.Add($p,$true)
    }
$hp = @{}
    $hp.Add('LoginName',$ILOuser1)
    $hp.Add('Privileges',$priv)
$oem = @{}
    $oem.Add('Hp',$hp)
$Headers = @{}
    $Headers.Add("UserName" , $ILOuser1)                            
    $Headers.Add("Password" , $ILOpass11)   
    $Headers.Add('Oem',$oem)

Invoke-HPRESTAction -href "/rest/v1/AccountService/Accounts" -data $headers -Session $IloSession
Disconnect-HPREST -Session $IloSession
}
