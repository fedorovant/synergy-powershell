# This is first version of Get SSD firmware data
# You need Redfish PS module and ILO4/ILO5 for this script
#autorization
$iloaddr="0"
$user1="your login"
$pass1="yourp ass"
$csvpath='c:\temp\ssdfirm.csv' # path to the ilocsvfile, example you can find in the same folder
$csvpathresult='c:\temp\ssdfirmresult1.csv' # resultfile, can be converted to excel

# Data array for results
$ssdfirm= @()
$ssdfirm+='Serials;Drives;Capacity;Firmware'

#Import ILO IP addresses
$iloip=Import-Csv -Path $csvpath

foreach($iloaddr in $iloip.ip)
{
    # Get session key
    $Session = Connect-HPERedfish -Address $iloaddr -Password $pass1 -Username $user1 -DisableCertificateAuthentication

    # Get server serial for report
    $sysname= Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/1/'-Session $Session -DisableCertificateAuthentication
    # Get data
    $info = Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/1/smartstorage/arraycontrollers/' -Session $Session -DisableCertificateAuthentication
    foreach($sys in $info.Members.'@odata.id')
    {
        $sysData = Get-HPERedfishDataRaw -odataid $sys"diskdrives/" -Session $session -DisableCertificateAuthentication
        foreach($drv in $sysdata.Members.'@odata.id')
        {
        $sysData1 = Get-HPERedfishDataRaw -odataid $drv -Session $session -DisableCertificateAuthentication
        if ($sysData1.MediaType -like "SSD"){
            $ssdfirm+=$sysname.SerialNumber + ";" + $sysData1.MediaType + ";" + $sysData1.CapacityGB + ";" + $sysData1.FirmwareVersion.Current.VersionString
            }
        } 
    }
}

return $ssdfirm | Out-File $csvpathresult 
Disconnect-HPERedfish -DisableCertificateAuthentication -Session $Session
