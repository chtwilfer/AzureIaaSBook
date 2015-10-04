workflow TR_UpdateSharepoint
{
       
    <#
    Project Name: Invoke Orchestrator Runbook
    Runbook Name: Invoke-OrchestratorRunbook2
    Runbook Type: Process
    Runbook Tags: Type:Process, Proj:Invoke Orchestrator Runbook
    Runbook Description: Process Runbook for the "Invoke Orchestrator Runbook" Project
    Runbook Author: Tiander Turpijn
    Runbook Creation Date: 11/01/2013
    #>
    
        param
    (
        [Parameter(Mandatory=$true)]
        [string] $SRID
    )
    
    

    $SCOserverName = "SCO01" 
    $PSCredName = "Andersbe" 
    $PSUserCred = Get-AutomationPSCredential -Name $PSCredName 
    $MyRunbookPath = "\13. TR\13.1\13.1.2 Update SR"  
     
    # Get the url for the Orchestrator service 
    $url = Get-OrchestratorServiceUrl -Server $SCOserverName
    
    #Provide the Initialize Data activity parameters: 
    $param1name = "SRID" 
    $param1guid = "6EBA2B0A-FD53-4027-A213-86CDEA8C3BB8" 
    $runbook = Get-OrchestratorRunbook -serviceurl $url -runbookpath $MyRunbookPath -credentials $PSUserCred
    
    #Correlate the Initialize Data parameters with our values 
    foreach ($param in $runbook.Parameters) 
    { 
        if ($param.Name -eq $param1name) 
        { 
            $param1guid = $param.Id   
        } 
        
    } 
        
        #Provide the values for our Initialize Data parameters 
        [hashtable] $params = @{ 
            $param1guid = $SRID; 
        } 
        # Start the runbook with our params
         $job = Start-OrchestratorRunbook -runbook $runbook -parameters $params -credentials $PSUserCred
           
# Show the Runbook job information 
$job  

    
}