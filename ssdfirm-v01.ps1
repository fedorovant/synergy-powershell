# This is first version of Get SSD firmware data. It got all your servers ILO and return CSV with affected SSD drives.
# (c) Fedorov Anton.
# You need Redfish PS module and ILO4/ILO5 for this script. ILO4 fw vwersion must be 2.62+.
#autorization
$iloaddr="0"
$user1="your user"
$pass1="your pass"
$csvpath='c:\temp\ssdfirm.csv'
$csvpathresult='c:\temp\ssdfirmresult1.csv'

# Data array for results
$ssdfirm= @()
$ssdfirm+='Server_Serial;Drive;Capacity;Drive_Model;Firmware;Status'

#data of BAD models
$baddata1= @("VO0480JFDGT","VO0960JFDGU","VO1920JFDGV","VO3840JFDHA","MO0400JFFCF","MO0800JFFCH","MO1600JFFCK","MO3200JFFCL","VO000480JWDAR","VO000960JWDAT","VO001920JWDAU","VO003840JWDAV","VO007680JWCNK","VO015300JWCNL","VK000960JWSSQ","VK001920JWSSR","VK003840JWSST","VK003840JWSST","VK007680JWSSU","VO015300JWSSV")
$numofbad=0

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
        #if ($sysData1.MediaType -like "SSD")
            foreach($model1 in $baddata1)
            {
                if ($sysData1.Model -like $model1)
                {
                $numofbad=$numofbad+1
                $ssdfirm+=$sysname.SerialNumber + ";" + $sysData1.MediaType + ";" + $sysData1.CapacityGB + ";" + $sysData1.Model +";" + $sysData1.FirmwareVersion.Current.VersionString + ";BAD"
                }
            }
        } 
    }
}
if ($numofbad -eq 0){Write-Host -ForegroundColor Green "congratulations! You have no any affected SSD drives"}
    else 
    {
    $ssdfirm | Out-File $csvpathresult
    Write-Host -ForegroundColor Red "unfortunately you have $numofbad affected SSD drives. The the list was loaded at $csvpathresult"}
Disconnect-HPERedfish -DisableCertificateAuthentication -Session $Session
