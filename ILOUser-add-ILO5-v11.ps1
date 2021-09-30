#This is new version (1.1) of ILO5 user add script for all servers throught SSO token with POSH-OV module
#
#--------------------uncomment this if you want to connect to OV------------
#write-host -ForegroundColor Yellow "You need to autorize at OneView.."
#$OVIP1 = Read-Host 'What is OV IP?'
#$OVuser1 = Read-Host 'What is OV Username?'
#$OVpass1 = Read-Host 'What is OV Username?' -AsSecureString
#$OVpass11 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($OVpass1))
#Connect-HPOVMgmt -Hostname $OVIP1 -UserName $OVuser1 -Password $OVpass11
#--------------------uncomment this if you want to connect to OV------------

Disable-HPERedfishCertificateAuthentication #Use this one if you're using new HPERedfishCmdlets module
#Disable-HPRESTCertificateAuthentication #Use this one if you're using old HPRestCmdlet module

write-host -ForegroundColor Yellow "Please Choose ILO credentials...."

$ILOuser1 = Read-Host 'What is ILO Username?'
$ILOpass1 = Read-Host 'What is ILO password?' -AsSecureString
$ILOpass11 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ILOpass1))

$data1=Get-HPOVServer
foreach($Server1 in $data1)
   {
    $ilosession = Get-HPOVServer -Name $Server1.name | Get-HPOVIloSso -IloRestSession
    $ilosession.rootUri = $ilosession.rootUri -replace 'rest','redfish'
   
    $accData = Get-HPERedfishDataRaw -odataid '/redfish/v1/AccountService/' -Session $ilosession -DisableCertificateAuthentication
    $accOdataId = $accData.Accounts.'@odata.id'
      
    # add permissions
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
    # add login name
    $hp = @{}
    $hp.Add('LoginName',$ILOuser1)
    $hp.Add('Privileges',$priv)
    
    $oem = @{}
    
    # This string for iLO 5 only
    $oem.Add('Hpe',$hp)
    $user = @{}
    $user.Add('UserName',$ILOuser1)
    $user.Add('Password',$ILOpass11)
    $user.Add('Oem',$oem)
    $ret = Invoke-HPERedfishAction -odataid $accOdataId -Data $user -Session $ilosession -DisableCertificateAuthentication
    $ret
    }
Disconnect-HPOVMgmt
