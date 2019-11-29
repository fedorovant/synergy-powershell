# This is first version of Get SSD firmware data
# You need Redfish PS module and ILO4/ILO5 for this script
#autorization
$iloaddr="your ILO4/ILO5 IP"
$user1="your login"
$pass1="your pass"

# Get session key
$Session = Connect-HPERedfish -Address $iloaddr -Password $pass1 -Username $user1 -DisableCertificateAuthentication

# Get server serial for report
$sysname= Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/1/'-Session $Session -DisableCertificateAuthentication
$serial=$sysname.SerialNumber

# Create array of data
$ssdfirm= @()
$ssdfirm+='Drives firmware'

$info = Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/1/smartstorage/arraycontrollers/' -Session $Session -DisableCertificateAuthentication
foreach($sys in $info.Members.'@odata.id')
{
    $sysData = Get-HPERedfishDataRaw -odataid $sys"diskdrives/" -Session $session -DisableCertificateAuthentication
    #$sysData
    foreach($drv in $sysdata.Members.'@odata.id')
    {
    $sysData1 = Get-HPERedfishDataRaw -odataid $drv -Session $session -DisableCertificateAuthentication
    if ($sysData1.MediaType -like "SSD"){
    $ssdfirm+=$sysData1.MediaType
    $ssdfirm+=$sysData1.FirmwareVersion}
}
}

return $ssdfirm

Disconnect-HPERedfish -DisableCertificateAuthentication -Session $Session 
