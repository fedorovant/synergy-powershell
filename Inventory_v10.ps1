# This is universal inventory script for (ILO4\ILO5) DL\ML\BL\Apollo\Synergy Servers
# It need HP Posh-OV 420 or higher cmdlet module
#
#autorization
$user1=" your OV user"
$pass1="your OV password"
$hostname1="OV IP address"
$csvpathresult='c:\temp\Rackinventory.csv' # your result inventory file

Connect-HPOVMgmt -UserName $user1 -Password $pass1 -Hostname $hostname1

# Create inventory array
$inventory1=@()
$inventory1+='SerialNumber;Power;Model;Processor;Memory(GB);ILOaddress;MACs;WWNs;RAIDs'

$data1=Get-HPOVServer

foreach($Server1 in $data1)
    {
    #Ethernet adapters MAC array
    $ethertenadapters1=''
    #FC adapters WWN array
    $fcadapters1=''
    #RAIDs array
    $localraids=''
    # Get ILO session for inventory
    $ilosession = Get-HPOVServer -Name $Server1.name | Get-HPOVIloSso -IloRestSession
    $ilosession.rootUri = $ilosession.rootUri -replace 'rest','redfish'
    $serverdata1=Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/1/'-Session $iloSession -DisableCertificateAuthentication
    
    #Ethernet inventory
    $interfaces= Get-HPERedfishDataRaw -odataid $serverdata1.EthernetInterfaces.'@odata.id'-Session $ilosession -DisableCertificateAuthentication
    foreach($int1 in $interfaces.members.'@odata.id')
        {
        $sysData = Get-HPERedfishDataRaw -odataid $int1 -Session $ilosession -DisableCertificateAuthentication
        $ethertenadapters1+=$sysData.MACAddress + ' '        
        }
    
    #FC inventory 
    $fcinterfaces=Get-HPERedfishDataRaw -odataid $serverdata1.NetworkInterfaces.'@odata.id' -Session $ilosession -DisableCertificateAuthentication
    foreach($fc1 in $fcinterfaces.members.'@odata.id')
        {
        $sysData1 = Get-HPERedfishDataRaw -odataid $fc1 -Session $ilosession -DisableCertificateAuthentication
        $sysData2 = Get-HPERedfishDataRaw -odataid $sysData1.NetworkPorts.'@odata.id' -Session $ilosession -DisableCertificateAuthentication
        foreach($fc2 in $sysData2.members.'@odata.id')
            {
            $FCData2=Get-HPERedfishDataRaw -odataid $fc2 -Session $ilosession -DisableCertificateAuthentication
            $fcadapters1+=$FCData2.AssociatedNetworkAddresses + ' '
            }
        }

    #RAID inventory
    $smartarrays1=Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/1/SmartStorage/ArrayControllers/' -Session $ilosession -DisableCertificateAuthentication
    foreach($array1 in $smartarrays1.members.'@odata.id')
        {
           $logicaldrive1=Get-HPERedfishDataRaw -odataid $array1"LogicalDrives/" -Session $ilosession -DisableCertificateAuthentication
           foreach($ld1 in $logicaldrive1.members.'@odata.id')
           {
           $lddata1=Get-HPERedfishDataRaw -odataid $ld1 -Session $ilosession -DisableCertificateAuthentication
           $localraids+="(" + "Name:" + $lddata1.LogicalDriveName + " " + "raid:" + $lddata1.Raid + " " + "capacity(MB):" + $lddata1.CapacityMiB + " " + "Status:" + $lddata1.Status.Health + ")"
           }
        }

    $inventory1+= $serverdata1.SerialNumber + ";" + $serverdata1.PowerState + ";" + $serverdata1.Model + ";" + $serverdata1.ProcessorSummary.Model + ";" + $serverdata1.MemorySummary.TotalSystemMemoryGiB + ";" + $Server1.mpHostInfo.mpIpAddresses[0].address + " " + $Server1.mpHostInfo.mpIpAddresses[1].address + ";" + $ethertenadapters1 + ";" + $fcadapters1 + ";" + $localraids
    }
Disconnect-HPOVMgmt
$inventory1 | Out-File $csvpathresult
