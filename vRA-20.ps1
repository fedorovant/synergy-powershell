# This is second version (2.0) of Cluster auto additional resources by memory utilization trigger.
# Based on Cluster profiles with ImageStreamer build plan
# Trigger set by 30% memory utilization

# Please complete yuor cluster and OV info

#VMware cluster
$clusterName = 'vRA'
$vcserver="vcsa.htcmsw.local"
$vCuser="administrator@vsphere.local"
$vCpass="HP1nvent@"
$trigger1=30

# Composer information
$username = "Administrator"
$password = "HP1nvent"
$composer = "synergy.htcmsw.local"
$resources=0
$uri2=0

Connect-VIServer -Server $vcserver -User $vCuser -Password $vCpass

function Failure {
    $global:helpme = $bodyLines
    $global:helpmoref = $moref
    $global:result = $_.Exception.Response.GetResponseStream()
    $global:reader = New-Object System.IO.StreamReader($global:result)
    $global:responseBody = $global:reader.ReadToEnd();
    Write-Host -BackgroundColor:Black -ForegroundColor:Red "`nStatus: A system exception was caught."
    Write-Host -BackgroundColor:Black -ForegroundColor:Red `n$global:responsebody
    Write-Host -BackgroundColor:Black -ForegroundColor:Red "`nThe request body has been saved to `$global:helpme"
    #break
}

do{
    $p1=Get-Cluster -Name $clusterName
    $p2=$p1.ExtensionData.Summary.UsageSummary
    $usagemem=$p2.MemEntitledMB
    $totalmem=$p2.TotalMemCapacityMB
    $percent=[int]($usagemem*100/$totalmem)
    if ($percent -lt $trigger1)
    {
    
        cls
        Write-Host -ForegroundColor Cyan "=========================================="
        Write-Host -ForegroundColor Cyan "We use only $percent % of memory resources"
        Write-Host -ForegroundColor Cyan "=========================================="
        sleep 5
    }
    else
    {
        cls
        Write-Host -ForegroundColor Yellow "============================================="
        Write-Host -ForegroundColor Yellow "We use $percent %. We overhead recources!!!"
        Write-Host -ForegroundColor Yellow "============================================="
        Write-Host -ForegroundColor Yellow "      We start new node provisioning!!!"
        Connect-HPOVMgmt -Hostname $composer -UserName $username -Password $password
        #Get information about hardware for new potential host
         $clusterinfo=Get-HPOVClusterProfile -Name $clusterName
         $sptiru=$clusterinfo.hypervisorHostProfileTemplate.serverProfileTemplateUri
         $templates=Get-HPOVServerProfileTemplate
         $num=$templates.count
         for ($j=0;$j -lt $num;$j++) {if ($templates[$j].uri -like $sptiru) {$serverhwuri=$templates[$j].serverHardwareTypeUri}}
         $servers=Get-HPOVServer
         $num=$servers.count
         for ($k=0;$k -lt $num;$k++) {if ($servers[$k].serverHardwareTypeUri -like $serverhwuri -and $servers[$k].serverProfileUri -eq $null) {$uri2=$servers[$k].uri}}
        
    # Uncomment the following line if facing the error: "The underlying connection was closed: Could not establish trust relationship for the SSL/TLS secure channel."  (usually due to using a OneView Self-signed certificate)
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    
    #Creation of the header
        $headers = @{ } 
        $headers.add("Accept-Language", "en_US")
        $headers.add("X-Api-Version", "1200")

    #Creation of the body
        $json1 = @{
                password=$password
                userName=$username
                }

        $Body = (ConvertTo-Json $json1)

        # Opening a login session with Composer
        $result = Invoke-RestMethod -Uri "https://$composer/rest/login-sessions" -Body $Body -Method Post -Headers $headers -ContentType 'application/json'
        $session=$result.sessionID
    
        # Capturing the Composer Session ID and adding it to the header
        $headers.add("Auth", "$session")
        sleep 2
    
        # Get RAW JSON cluster-profile
        
        $clusteruri=$clusterinfo.uri
        $resulturi = $composer + $clusteruri
        $result3=Invoke-WebRequest -Uri "https://$clusteruri" -Method Get -Headers $headers -ContentType 'application/json'
        
        # Convert from jSON and Add new host URI into array
        $p5=(ConvertFrom-Json $result3.Content)
        $p5.addHostRequests = @( @{"serverHardwareUri"="$uri2"})
    
        # Convert to JSON again with large Depth
        $payload = $p5 | ConvertTo-Json -Depth 8
    
        #Start adding host
        try {
        $finalurl = $composer + $uri2
        Invoke-RestMethod -Uri "https://$finaluri" -Method Put -Headers $headers -Body $payload -ContentType 'application/json' 
        #$resources=1
        }
    catch {

        failure
           }
        #Wait for CloudResources creation comlete
        
        $taskcompleted1=0
        for ($i=0;$i -lt 5;$i++) {sleep 2; Write-Host -ForegroundColor Yellow ".."}

        do
        {
            $task1=Get-HPOVTask -State Running | ?{$_.Name -match "Update"}
            if ($task1 -eq $null) 
            {
                $taskcompleted1=1
            }
            else
            {
                $task1percent=$task1[0].percentComplete
                write-host -ForegroundColor Yellow "$task1percent % - Wait for Cloud resoupces addition.."
                sleep 10
            }
        }until ($taskcompleted1 -eq 1)
    Disconnect-HPOVMgmt    
 }
 }until ($resources -eq 1)

Disconnect-VIServer -Confirm:$false
