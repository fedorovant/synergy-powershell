#This is simple script for Servers migration between OneView in Monitoring mode
#
#-------- Part need to be filled ------
#autorization
$user1=" your OV user"
$pass1="your OV password"
$hostname1="OV IP address"

$user2=" your new OV user"
$pass2="your  new OV password"
$hostname2="OV new IP address"

$ilologin = "your ilo login for all servers"
$ilopass = "your ilo password for all servers"

#CSV file path
$csvpathresult='c:\temp\OV-inventory.csv'
#-------- Part need to be filled ------

# Create inventory array
$inventory1=@()
$inventory1+='ServerName;ILO_address'

#---Part1: collect data from old OV------
Connect-HPOVMgmt -Hostname $hostname1 -Password $pass1 -UserName $user1
$data1=Get-HPOVServer
Foreach ($Server1 in $data1)
{
# Get Server for inventory
$sName = Get-HPOVServer -Name $Server1.name
$sILO= $Server1.mpHostInfo.mpIpAddresses[0].address
$inventory1+= $sName.name + ";" + $sILO
}

Disconnect-HPOVMgmt
$inventory1 | Out-File $csvpathresult
#---End of Part1------

#---Part 2: deploy all servers at new OV
Connect-HPOVMgmt -UserName $user2 -Password $pass2 -Hostname $hostname2

$serverdata2=Import-Csv -Path $csvpathresult -Delimiter ';'
$num=$serverdata2.Count

for ($i=0;$i -lt $num-1;$i++)
{
$p1=$serverdata2[$i].ILO_address
Add-HPOVServer -Hostname $p1 -Username $ilologin -Password $ilopass -Monitored -Confirm:$false
}
Disconnect-HPOVMgmt
#---End of Part2------
