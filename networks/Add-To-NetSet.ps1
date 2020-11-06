#This is first version (1.0) of script that add network to the network set with POSH-OV module
#
#This is varibles used at script:
#-------------varibles---
$pwd="HP1nvent"
$ovip1="172.28.10.50"
$NetSet="RP_Trunk"
$NetworkToAdd="VLAN_103"
#------------------------
Connect-HPOVMgmt -Hostname $ovip1 -UserName administrator -Password $pwd
Get-HPOVNetworkSet -Name $NetSet | Set-HPOVNetworkSet -AddNetwork $NetworkToAdd
Disconnect-HPOVMgmt
