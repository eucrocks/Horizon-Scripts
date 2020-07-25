#This script demo's how to retrieve sessions from a specific pool
import-module vmware.powercli

function Get-ViewAPIService {
    param(
      [Parameter(Mandatory = $false)]
      $HvServer
    )
    if ($null -ne $hvServer) {
      if ($hvServer.GetType().name -ne 'ViewServerImpl') {
        $type = $hvServer.GetType().name
        Write-Error "Expected hvServer type is ViewServerImpl, but received: [$type]"
        return $null
      }
      elseif ($hvServer.IsConnected) {
        return $hvServer.ExtensionData
      }
    } elseif ($global:DefaultHVServers.Length -gt 0) {
       $hvServer = $global:DefaultHVServers[0]
       return $hvServer.ExtensionData
    }
    return $null
  }

function Get-HVDesktopPool
{
    param(
        [parameter(mandatory=$true)]
        $hvServer,
        $PoolName
    )
    $query_service_helper = New-Object VMware.Hv.QueryServiceService
    $query = New-Object VMware.Hv.QueryDefinition
    $query.queryEntityType = 'DesktopSummaryView'
    if($null -ne $PoolName){
        $filter = new-object VMware.Hv.QueryFilterContains
        $filter.MemberName= "desktopSummaryData.name"
        $filter.value = $PoolName
        $query.filter = $filter
    }
    $services = Get-ViewAPIService -hvServer $hvServer
    $query_service_helper.QueryService_Query($services, $query).results
}
function Get-HVSessionLocalSummaryView{
    param(
        [parameter(mandatory=$true)]
        $hvServer,
        [VMware.Hv.DesktopId]$DesktopPoolID
    )
    $Results=@()
    $query_service_helper = New-Object VMware.Hv.QueryServiceService
    $query = New-Object VMware.Hv.QueryDefinition
    $query.queryEntityType = 'SessionLocalSummaryView'
    if($null -ne $DesktopPoolID){
        $filter = new-object VMware.Hv.QueryFilterEquals
        $filter.MemberName= "referenceData.desktop"
        $filter.value = $DesktopPoolID
        $query.filter = $filter
    }
    $services = Get-ViewAPIService -hvServer $hvServer
    $queryResponse = $query_service_helper.QueryService_Create($services, $query)
    $results+=$queryResponse.Results
    if($queryResponse.RemainingCount -gt 0){
        Write-Verbose "Found further results to retrieve"
        $remaining=$queryResponse.RemainingCount
        do{
            
            $latestResponse = $query_service_helper.QueryService_GetNext($services,$queryResponse.Id)
            $results+= $latestResponse.Results
            Write-Verbose "Pulled an additional $($latestResponse.Results.Count) item(s)"
            $remaining = $latestResponse.RemainingCount
        }while($remaining -gt 0)
    }

    $query_service_helper.QueryService_Delete($services,$queryResponse.Id)
    $results
}

#Pool to unschedule
$lab="lab1"

#AD Group to remove entitlement
$classroom="classroom1"

#Setup Connection
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "eucrocks\administrator",(get-content .\password.txt | ConvertTo-SecureString)
$hvServer1=connect-hvserver -server cs01 -cred $cred

# shorter access to extensiondata:
$services1=$hvServer1.ExtensionData

#Get the unique pool ID to pump into session query
$pool = Get-HVDesktopPool -PoolName $lab -hvServer $hvserver1

#Query for local pod sessions speicific to the above pool
$sessions = Get-HVSessionLocalSummaryView -hvserver $hvserver1 -DesktopPool $pool.id


#Send initial warning and capture response in $response
$response = $services1.session.Session_SendMessages($sessions.id,"WARNING","Your session will end in 15 minutes. Please save you work and logoff before then")
Start-Sleep -Seconds 900

#Re Query for sessions in pool then send sencondary warning and capture response in $response

$sessions = Get-HVSessionLocalSummaryView -hvserver $hvserver1 -DesktopPool $pool.id
$response = $services1.session.Session_SendMessages($sessions.id,"ERROR","Your session will end in 5 minutes. Please save you work and logoff before then")
Start-Sleep -Seconds 300

Remove-HVEntitlement -ResourceName $lab -Type Group -User eucrocks.local\$classroom

# Query sessions one final time, then force a logoff
$sessions = Get-HVSessionLocalSummaryView -hvserver $hvserver1 -DesktopPool $pool.id
$response = $services1.Session.Session_LogoffSessionsForced($sessions.id)