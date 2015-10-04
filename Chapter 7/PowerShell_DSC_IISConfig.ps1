
# PowerShell DSC (from section 7.3.2.1)

# STEP 1: PowerShell DSC Configuration for IIS Web Server
# Copy this section to separate file and save as c:\temp\IISInstall.ps1
configuration InstallIIS
{ 
    Import-DscResource -Module xWebAdministration             

    # Install the IIS role 
    WindowsFeature IIS 
    { 
        Ensure = "Present" 
        Name = "Web-Server" 
    } 
    # Install the ASP .NET 4.5 role 
    WindowsFeature AspNet45 
    { 
        Ensure = "Present" 
        Name = "Web-Asp-Net45" 
    } 
} 


# STEP 2: Publish the DSC configuration to Azure.
 Publish-AzureVMDscConfiguration –ResourceGroupName 'VMResourceGroup' `
 –ConfigurationPath "C:\temp\IISInstall.ps1" –StorageAccountName "mystoracct006" 

# STEP 3: Apply the configuration to a target VM
Set-AzureVMDscExtension –ResourceGroupName "VMResourceGroup" `
–VMName VM001 –ArchiveBlobName IISInstall.ps1.zip `
–ArchiveStorageAccountName "mystoracct006" `
–ConfigurationName IISInstall –version 2.0 –Location "North Europe"

# STEP 4: Verify deployment status of the configuration 
$status = Get-AzureVM –ResourceGroupName "VMResourceGroup" `
–Name "VM001" –Status –Verbose
$status 