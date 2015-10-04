workflow SCSM__Deploy_New_VM
{

param (
		# Mandatory parameter of type String, name of new virtual machine
    	[parameter(Mandatory=$true)]
        [string]$VMName = "",
        
        		# Mandatory parameter of type String, size of new virtual machine
    	[parameter(Mandatory=$true)]
        [string]$InstanceSize = "",

        		# Mandatory parameter of type String, ID of activity
    	[parameter(Mandatory=$true)]
        [string]$ActivityID = ""

)

#
# Get password and username. 
#

### Account to use to join the domain

$JoinDomainCredential = Get-AutomationPSCredential -Name 'JoinDomainCredentials'  
$JoinDomainCredentialPassword = inlinescript {   
    $sstr = $Using:JoinDomainCredential.password 
    $marshal = [System.Runtime.InteropServices.Marshal]
    $ptr = $marshal::SecureStringToBSTR( $sstr )
    $str = $marshal::PtrToStringBSTR( $ptr )
    $marshal::ZeroFreeBSTR( $ptr )  
    Return $str
      }
      
### Local Administrator account

$LocalAdminCredentials = Get-AutomationPSCredential -Name 'LocalAdminCredentials'  
$LocalAdminCredentialsPassword = inlinescript {   
    $sstr = $Using:LocalAdminCredentials.password 
    $marshal = [System.Runtime.InteropServices.Marshal]
    $ptr = $marshal::SecureStringToBSTR( $sstr )
    $str = $marshal::PtrToStringBSTR( $ptr )
    $marshal::ZeroFreeBSTR( $ptr )  
    Return $str
      }
       
#
# Settings
#


$azuresettings = "C:\Azure\azure-credentials.publishsettings"
$subscriptionname = "contoso001" 
$storageaccount = "portalvhds001"
# $InstanceSize = "Medium" # Specifies the size of the virtual machine
$ServiceName = "Infrastructure" #Specifies the new or existing service name.

$adminuser = $LocalAdminCredentials.username # Local Windows Administrator Account on the new VM
$adminuserpassword = $LocalAdminCredentialsPassword #Specifies the password of the administrative account for the virtual machine.
$domain = 'CONTOSO'     # Specifies the domain of the user account that has permission to add the computer to a domain.
$domainjoin = 'CONTOSO.LOCAL' # Specifies the fully qualified domain name (FQDN) of the Windows domain to join.
$domainuser = $JoinDomainCredential.username # Used to join the domain
$domainuserpassword = $JoinDomainCredentialPassword # Specifies the password of the user account that has permission to add the computer to a domain.

#
# Get runbook ID and name
#

    $smaJobId = $PSPrivateMetadata.JobId.Guid    
    $job = Get-SmaJob -Id $smaJobId -WebServiceEndpoint https://wap01
    $rb = Get-SmaRunbook -Id $job.RunbookId -WebServiceEndpoint https://wap01
    $runbookName = $rb.RunbookName
        
#
# Build new Virtual Machine in Azure
#
    
   
InLineScript{
    
$ErrorActionPreference = "Stop"
    
Try {
    $id = $using:smaJobId
    $name = $using:runbookName
    Start-SMARunbook -WebServiceEndpoint https://wap01 -Name WriteLog -Parameters @{"Runbook"=$name; "Job"=$id; "Description"="Starting with $using:VMName "}
      
    Import-AzurePublishSettingsFile $using:azuresettings
    Set-AzureSubscription -SubscriptionName $using:subscriptionname -CurrentStorageAccount $using:storageaccount
    Select-AzureSubscription $using:subscriptionname
    $image = Get-AzureVMImage -ImageName a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201310.01-en.us-127GB.vhd
    $cloudservice = Get-AzureService -ServiceName $using:ServiceName
    New-AzureVMConfig -Name $using:VMName -InstanceSize $using:InstanceSize -ImageName $image.ImageName | Add-AzureProvisioningConfig -WindowsDomain -AdminUsername $using:adminuser -JoinDomain $using:domainjoin -Domain $using:domain -DomainPassword $using:domainuserpassword -Password $using:adminuserpassword -DomainUserName $using:domainuser  | New-AzureVM -ServiceName $using:ServiceName -WaitForBoot

Start-SMARunbook -WebServiceEndpoint https://wap01 -Name WriteLog -Parameters @{"Runbook"=$name; "Job"=$id; "Description"="Successfully deployed $using:VMName "}
    
} 
Catch { 
    $id = $using:smaJobId
    $name = $using:runbookName
    Start-SMARunbook -WebServiceEndpoint https://wap01 -Name WriteLog -Parameters @{"Runbook"=$name; "Job"=$id; "Description"="ERROR!! $_"}
    Return "ERROR!! $_"      
    }
Finally { 
    Start-SMARunbook -WebServiceEndpoint https://wap01 -Name WriteLog -Parameters @{"Runbook"=$name; "Job"=$id; "Description"="Runbook stopped working with $using:VMName "}
    
 }
    
}
   
    
    Inlinescript {
        $session = new-pssession -ComputerName SM01
        Invoke-Command -Session $session {
            $workitem = Get-SCSMObject -Class  (get-scsmclass -name Contoso.SMA.DeployVM) | Where-Object {$_.ID -eq "$using:ActivityID"}
            $workitem | Set-SCSMObject -Property Status -Value Completed
                                        }
}
}
