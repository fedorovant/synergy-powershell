#This is first version (1.0) of new network creation and update of Logical Enclosure with POSH-OV module
#
#This is varibles used at script:
#-------------varibles---
$pwd="HP1nvent"
$ovip1="172.28.10.50"
$LIGname="LIG-ETH-FC"
$LE1="LE-Synergy"
$Uplinkset1="Trunk"
#------------------------
Connect-HPOVMgmt -Hostname $ovip1 -UserName administrator -Password $pwd

$uplinkset=Get-HPOVUplinkSet -name $Uplinkset1
$uplinkset2=$uplinkset.name

$vlan1=Read-Host "VLAN number?"
$newNetwork1="vlan_$vlan1"

New-HPOVNetwork -type Ethernet -name $newNetwork1 -vlanid $vlan1 -typicalbandwidth 10000 -maximumbandwidth 20000
$net=Get-HPOVNetwork -Name $newNetwork1

#Adding network "vlan_#" to uplinkset "Trunk" on LIG "LIG-ETH-FC" 
$lig = Get-HPOVLogicalInterconnectGroup -Name $LIGname 

foreach ($us in $lig.uplinkSets) 
{
    if ($us.name -match $uplinkset2) 
    {
    $us.networkUris += $net.uri
    }
}
Set-HPOVResource $lig | Wait-HPOVTaskComplete


#Update LE from group 
Get-HPOVLogicalEnclosure -name $LE1 | Update-HPOVLogicalEnclosure -Update -Confirm:$false

Disconnect-HPOVMgmt
