
# This script will create a 3-subnet VNET in Azure V2

# Authenticate to Azure Account

Add-AzureAccount 

# Authenticate with Azure AD credentials

$cred = Get-Credential

Add-AzureAccount -Credential $cred

# Switch to Azure Resource Manager mode

Switch-AzureMode `
    -Name AzureResourceManager


# Register the latest ARM Providers

Register-AzureProvider `
    -ProviderNamespace Microsoft.Compute `
    -Force

Register-AzureProvider `
    -ProviderNamespace Microsoft.Storage `
    -Force

Register-AzureProvider `
    -ProviderNamespace Microsoft.Network `
    -Force


# Confirm registered ARM Providers

Get-AzureProvider |
     Select-Object `
        -Property ProviderNamespace `
        -ExpandProperty ResourceTypes 
        
# Confirm registered ARM Providers

Get-AzureProvider |
     Select-Object `
        -Property ProviderNamespace `
        -ExpandProperty ResourceTypes


# Select an Azure subscription

$subscriptionId = 
    (Get-AzureSubscription |
     Out-GridView `
        -Title "Select a Subscription ..." `
        -PassThru).SubscriptionId

Select-AzureSubscription `
    -SubscriptionId $subscriptionId
    
# Deploy a Linux VM

Get-AzureVMImage –Location "North Europe" `
–PublisherName "Canonical" –Offer "UbuntuServer" `
–Skus "14.04.2-LTS"

$vmimage = Get-AzureVMImage –Location "North Europe" `
–PublisherName "Canonical" –Offer "UbuntuServer" `
–Skus "14.04.2-LTS" –Version 14.04.201507060


# After you have authenticated to your Azure subscription 
# Use this to retrieve the list of Windows 2012 images 
# Only necessary to identify pre-runtime to identify 
# the values you need in the next section
# Get-AzureVMImage –Location "North Europe" –PublisherName "MicrosoftWindowsServer" `
# –Offer "WindowsServer" –SKU "2012-R2-Datacenter"

# Retrieve VM image to deploy and save to variable. 
$vmimage = Get-AzureVMImage –Location "North Europe" –PublisherName "MicrosoftWindowsServer" `
–Offer "WindowsServer" –SKU "2012-R2-Datacenter" –Version 4.0.20150825

# Create a new resource group
New-AzureResourceGroup –Name "VMResourceGroup" –Location "North Europe"

# Create a new storage account. Remember, the storage account name must  
# be unique in all of Azure. 
New-AzureStorageAccount –ResourceGroupName "VMResourceGroup" `
–Name "mystoracct006" –Location "North Europe" –type standard_lrs


# Set values for vnet and subnet within the vnet.

$subnet = New-AzureVirtualNetworkSubnetConfig –Name "production" –AddressPrefix "10.0.50.0/24"

$vnet = New-AzureVirtualNetwork –Name "CloudVNet" –ResourceGroupName "VMResourceGroup" `
–Location "North Europe" –AddressPrefix "10.0.0.0/16" –Subnet $subnet

$subnet = Get-AzureVirtualNetworkSubnetConfig –Name "production" –VirtualNetwork $vnet

$pip = New-AzurePublicIPaddress –ResourceGroupName "VMResourceGroup" `
–Name "WinVMPublicIP" –Location "North Europe" –AllocationMethod Dynamic

$netint = New-AzureNetworkInterface –ResourceGroupName "VMResourceGroup" `
–Name "WinVMNic" –subnet $subnet –Location "North Europe" –PublicIPaddress $pip –PrivateIPAddress "10.0.50.4" 

# Capture credentials for local administrator account in VM guest OS.
$cred = get-credential

##############################
# Create VM configuration file 
##############################

# VM name and size 

$vmConfig = New-AzureVMConfig -VMName "VM001" -VMSize "Standard_A1" | `

Set-AzureVMOperatingSystem -Windows -ComputerName "VM001" `
-Credential $cred -ProvisionVMAgent -EnableAutoUpdate| `

# Source VM image (from Azure marketplace) 
Set-AzureVMSourceImage -PublisherName $vmimage.publishername `
-Offer $vmimage.offer -Skus $vmimage.skus -Version $vmimage.version | `

# URL to new Azure VHD for this VM. Storage account in the URL 
# matches the account name we created earlier. 
Set-AzureVMOSDisk -Name "VM001" -VhdUri "https://mystoracct006.blob.core.windows.net/vhds/VMM001-os.vhd" `
-Caching ReadWrite -CreateOption fromImage | ` 

# Add network interface to the VM configuration 
Add-AzureVMNetworkInterface -Id $netint.Id 


# Create VM 
New-AzureVM –ResourceGroupName “VMResourceGroup” –Location “North Europe” –VM $vmConfig
