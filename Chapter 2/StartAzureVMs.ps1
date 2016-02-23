workflow StartVMs 
{    
      param() 
 
       $Connection = "Azure Account Conn" 
       $Cert = "Azure Cert" 
       $vmname = "TestVM"
       $resourcegroupname = "VM Resources"
 
 
   
    $Con = Get-AutomationConnection -Name $Connection 
    if ($Con -eq $null) 
    { 
        Write-Output "$Connection does not exist as an item in the automation service. Please contact your admin to publish one"    
    } 
    else 
    { 
        $SubID = $Con.SubscriptionID 
        $mgmtCert = $Con.AutomationCertificateName 
        
    }    
 
  
    $AutoCert = Get-AutomationCertificate -Name $Cert 
    if ($AutoCert -eq $null) 
    { 
        Write-Output "$Cert does not exist as an item in the automation service. Please contact your admin to publish one"    
    } 
    else 
    { 
        $To = $Cert.Thumbprint 
    } 
 
         
         Set-AzureRMSubscription -SubscriptionName "Azure Subscription" -Certificate $Cert -SubscriptionId $SubID 
         Select-AzureRMSubscription -SubscriptionName "Azure Subscription" 
         Start-AzureRMVM -ResourceGroupName $resourcegroupname -Name $VMName

} 
