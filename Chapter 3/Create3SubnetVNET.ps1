

# Authenticate to Azure Account

Add-AzureAccount

# Authenticate with Azure AD credentials

$cred = Get-Credential

Add-AzureAccount `
    -Credential $cred

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



    # Create Resource Group

    New-AzureResourceGroup `
    -Name 'ContosoSampleRG' `
    -Location "West US"

    # Define Subnets
    
    $frontendSubnet = New-AzureVirtualNetworkSubnetConfig `
    -Name LB-Subnet-FE -AddressPrefix 10.1.2.0/24
    
    $midtierSubnet = New-AzureVirtualNetworkSubnetConfig `
    -Name LB-Subnet-MT -AddressPrefix 10.1.3.0/24
    
    $backendSubnet = New-AzureVirtualNetworkSubnetConfig `
    -Name LB-Subnet-BE -AddressPrefix 10.1.4.0/24

    
    #Deploy VNET and subnets 

    $vnet = New-AzurevirtualNetwork `
        -Name SampleVNet `
        -ResourceGroupName ContosoSampleRG `
        -Location "West US" `
        -AddressPrefix 10.0.0.0/8 `
        -Subnet $frontendSubnet,$midtierSubnet,$backendSubnet


