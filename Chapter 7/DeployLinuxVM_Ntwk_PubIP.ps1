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

New-AzureResourceGroup –Name "VMLinuxResourceGroup" `
–Location "North Europe"

New-AzureStorageAccount –ResourceGroupName `
"VMLinuxResourceGroup" –Name "mystoracct888" `
–Location "North Europe" –type standard_lrs


$subnet = New-AzureVirtualNetworkSubnetConfig –Name "LinuxProd" –AddressPrefix "10.0.60.0/24"

$vnet = New-AzureVirtualNetwork –Name "CloudLinuxVNet" –ResourceGroupName "VMLinuxResourceGroup" `
–Location "North Europe" –AddressPrefix "10.0.0.0/16" –Subnet $subnet

$subnet = Get-AzureVirtualNetworkSubnetConfig –Name "LinuxProd" –VirtualNetwork $vnet

# $subnet = New-AzureVirtualNetworkSubnetConfig `
# –Name "LinuxProd" –AddressPrefix "172.0.60.0/24"

# $vnet = New-AzureVirtualNetwork –Name "CloudLinuxVNet" `
# –ResourceGroupName "VMLinuxResourceGroup" –Location ` 
# "North Europe" –AddressPrefix "172.0.0.0/16" `
# –Subnet $subnet

# $subnet = Get-AzureVirtualNetworkSubnetConfig –Name "LinuxProd" –VirtualNetwork $vnet

$pip = New-AzurePublicIPaddress –ResourceGroupName "VMLinuxResourceGroup" –Name "LinuxVMPublicIP" `
–Location "North Europe" –AllocationMethod Dynamic

$netint = New-AzureNetworkInterface –ResourceGroupName "VMLinuxResourceGroup" –Name "LinuxVMNic" –subnet $subnet –Location "North Europe" –PublicIPaddress $pip –PrivateIPAddress "10.0.60.4"  

$cred = get-credential

$vmConfig = New-AzureVMConfig -VMName "LNX001" -VMSize "Standard_A1" | Set-AzureVMOperatingSystem -Linux –ComputerName "LNX001" -Credential $cred | Set-AzureVMSourceImage –PublisherName $vmimage.publishername -Offer $vmimage.offer -Skus $vmimage.skus -Version $vmimage.version | 

Set-AzureVMOSDisk -Name "LNX001" –VhdUri "https://mystoracct888.blob.core.windows.net/vhds/LNX001-os.vhd" -Caching ReadWrite –CreateOption fromImage |  Add-AzureVMNetworkInterface -Id $netint.Id 

New-AzureVM –ResourceGroupName "VMLinuxResourceGroup" –Location "North Europe" –VM $vmConfig
