<#

.SYNOPSIS
This script will deploy a Windows VM into Azure on an unmanaged disk.

.DESCRIPTION
This Script must be executed using an Account that is either a Co-Administrator or an Azure Organizational Account to the Subscription that
is being targeted. Additionally, Azure PowerShell 1.0 or higher is required.

Once this script is launched and the user is logged in and the Subscription ID to work with is set, the following actions will occur:

- A GUID is generated for unique naming of the VM and its Storage Account.
- A new Resource Group is created.
- A new Storage Account is created.
- The latest VM IMage version of Windows Server 2012 R2 Datacenter is located and is what will be deployed on the VM.
- A new Azure VM Configuration is created.
- A new Subnet is created.
- A new VNet is created.
- A new Public IP Address is created.
- A new NIC card is created.
- The NIC card is assocated to the VM.
- The VM OS Disk Settings are configured.
- The local login Credentials are added into a PSCredential Object.
- The VM VM Operating System Settings are set.
- The OS Image Settings that will be installed on the VM are set.
- The Operating System Disk settings for the VM are set.
- The New VM is deployed.

.PARAMETER SubscriptionId
The ID of the Azure Subscription you are deploying to, i.e. - 838f045f5-e37a-5156-8e82-0c1ecd17a682

.PARAMETER VMName
The Name of the Virtual Machine you are deploying.

.PARAMETER VMSize
The Size of the Virtual Machine you are deploying, i.e. - Standard_DS1_v2, Standard_DS2_v2, etc.

.PARAMETER ResourceGroupName
The Name of the Resource Group with the Azure Storage Account that will be storing deployment resources, i.e. DSC Modules and Scripts.

.PARAMETER StorageAccountName
The Name of the Storage Account being created for the VM, i.e. - Standard_LRS, Standard_GRS, Premium_LRS, etc.

.PARAMETER StorageAccountType
The Type of Storage Account being created for the VM.

.PARAMETER LocalAdminUsername
The Local Administrator Username that will be used by default in VM Deployments. This value is added to the Azure Key Vault.

.PARAMETER LocalAdminPassword
The Local Administrator Password that will be used by default in VM Deployments. This value is added to the Azure Key Vault.

.PARAMETER Location
The Location where the VM is being deployed, i.e. westeurope, northeurope, eastus, etc...

.NOTES
Filename:   deploy-unique-windows-vm-to-azure-unmanaged-disk.ps1
Author:     Ryan Irujo (https://github.com/starkfell)
Language:   PowerShell 5.0

Syntax:           ./deploy-unique-windows-vm-to-azure-unmanaged-disk.ps1 `
                  -SubscriptionId <AZURE_SUBSCRIPTION_ID> `
                  -VMName <VM_NAME> `
                  -VMSize <VM_SIZE> `
                  -ResourceGroupName <RESOURCE_GROUP_NAME> `
                  -StorageAccountName <STORAGE_ACCOUNT_NAME> `
                  -StorageAccountType <STORAGE_ACCOUNT_TYPE> `
		  -LocalAdminUsername <LOCAL_ADMIN_USERNAME> `
		  -LocalAdminPassword <LOCAL_ADMIN_PASSWORD> `
                  -Location <DEPLOYMENT_LOCATION>

Example:          ./deploy-unique-windows-vm-to-azure-unmanaged-disk.ps1 `
                  -SubscriptionID 1e8f6ef4-93cf-48c9-a1f9-1436e81e6fec `
                  -VMName iaas-vm `
                  -VMSize Standard_DS1_v2 `
                  -ResourceGroupName iaas-vm `
                  -StorageAccountName iaasvmdemo `
                  -StorageAccountType Standard_LRS `
                  -LocalAdminUsername localadmin `
                  -LocalAdminPassword LetMeInNow1! `
                  -Location westeurope

#>

param
(
    [Parameter(Mandatory)]
    [String]$SubscriptionId,
    
    [Parameter(Mandatory)]
    [String]$VMName,

    [Parameter(Mandatory)]
    [String]$VMSize,

    [Parameter(Mandatory)]
    [String]$ResourceGroupName,

    [Parameter(Mandatory)]
    [String]$StorageAccountName,

    [Parameter(Mandatory)]
    [String]$StorageAccountType,

	[Parameter(Mandatory)]
    [String]$LocalAdminUsername,

	[Parameter(Mandatory)]
    [String]$LocalAdminPassword,

	[Parameter(Mandatory)]
    [String]$Location
)

# Suppressing Warning messages while the script is running.
$WarningPreference = "silentlycontinue"

# Logging into Azure Resource Manager.
Add-AzureRMAccount `
    -Verbose:$false `
    -ErrorAction SilentlyContinue `
    -ErrorVariable AzureLoginFail `
    | Out-Null

If (!$AzureLoginFail)
{
    Write-Output "Successfully logged into Azure (ARM)."
}

If ($AzureLoginFail)
{
	Write-Error -Message "Failed to log into Azure (ARM)."
    exit 2
}

# Selecting the Azure Subscription to work with.
Select-AzureRmSubscription `
    -SubscriptionId $SubscriptionId `
    -ErrorAction SilentlyContinue `
    -ErrorVariable SelectSubFail `
    | Out-Null

If (!$SelectSubFail)
{
    Write-Output "Successfully set to work with Subscription ID: $SubscriptionID."
}

If ($SelectSubFail)
{
	Write-Error -Message "Failed to associate with Subscription ID: $SubscriptionID."
    exit 2
}

# Generating a Guid and utilizing the first four characters from it to change the names of the Deployed Resources that are required to be unique.
$Guid     = [guid]::NewGuid().ToString()
$UniqueID = $Guid.Substring(0,$_.length+4)

If ($?)
{
    Write-Output "Successfully generated new Guid and retrieved the first 4 characters from it."
}

If (!$?)
{
	Write-Error -Message "Failed to generate a new Guid and retrieve the first 4 characters from it."
    exit 2
}

# Renaming Resources so they are unique in Azure.

$VMName             = "$VMName" + "-" + "$UniqueID"
$StorageAccountName = "$StorageAccountName" + "$UniqueID"

Write-Output "New VMName Name: $VMName"
Write-Output "New StorageAccount Name: $StorageAccountName"

# Creating a New Azure Resource Group for the VM.
New-AzureRmResourceGroup `
    -Name $ResourceGroupName `
    -Location $Location `
    -ErrorAction SilentlyContinue `
    -ErrorVariable DeployRGFail `
    | Out-Null

If (!$DeployRGFail)
{
    Write-Output "Successfully created a new Resource Group for the VM: $VMName."
}

If ($DeployRGFail)
{
	Write-Error -Message "Failed to create a new Resource Group for the VM: $VMName"
    exit 2
}

# Creating a new Azure Storage Account for the VM.
$VMStorageAccount = New-AzureRmStorageAccount `
    -ResourceGroupName $ResourceGroupName `
    -AccountName $StorageAccountName `
    -Location $Location `
    -Type $StorageAccountType `
    -ErrorAction SilentlyContinue `
    -ErrorVariable CreateNewStorageFail

If (!$CreateNewStorageFail)
{
    Write-Output "Successfully created a new Storage Account: $StorageAccountName."
}

If ($CreateNewStorageFail)
{
	Write-Error -Message "Failed to create a new Storage Account: $StorageAccountName"
    exit 2
}

# Retrieving the latest version of Windows Server 2012 R2 Datacenter that is avialable in the Location being deployed to.
$VMImage = Get-AzureRmVMImage `
    -Location $Location `
    -PublisherName MicrosoftWindowsServer `
    -Offer WindowsServer `
    -Skus 2012-R2-Datacenter `
    -ErrorAction SilentlyContinue `
    -ErrorVariable RetrieveVMImageFail `
    | Sort-Object Version -Descending `
    | Select-Object -First 1 `

If (!$RetrieveVMImageFail)
{
    Write-Output "Successfully retrieved the lastest VM Image for Windows Server 2012 R2 Datacenter."
}

If ($RetrieveVMImageFail)
{
	Write-Error -Message "Failed to retrieve the lastest VM Image for Windows Server 2012 R2 Datacenter."
    exit 2
}

# Creating a new Azure VM Configuration.
$VMConfig = New-AzureRMVMConfig `
    -VMName $VMName `
    -VMSize $VMSize `
    -ErrorAction SilentlyContinue `
    -ErrorVariable NewVMConfigFail

If (!$NewVMConfigFail)
{
    Write-Output "Successfully created the new VM Configuration."
}

If ($NewVMConfigFail)
{
	Write-Error -Message "Failed to create the new VM Configuration."
    exit 2
}

# Creating a new Subnet for the new Azure VM.
$Subnet = New-AzureRmVirtualNetworkSubnetConfig `
    -Name Subnet-$ResourceGroupName `
    -AddressPrefix "10.0.0.0/24" `
    -ErrorAction SilentlyContinue `
    -ErrorVariable CreateNewSubnetFail

If (!$CreateNewSubnetFail)
{
    Write-Output "Successfully created a new Subnet: $($Subnet.Name)."
}

If ($CreateNewSubnetFail)
{
	Write-Error -Message "Failed to create a new Subnet: $($Subnet.Name)."
    exit 2
}

# Creating a new VNet for the new Azure VM.
$VNet = New-AzureRmVirtualNetwork `
    -Name VNet-$ResourceGroupName `
    -AddressPrefix $Subnet.AddressPrefix `
    -Subnet $Subnet `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -ErrorAction SilentlyContinue `
    -ErrorVariable CreateNewVNetFail

If (!$CreateNewVNetFail)
{
    Write-Output "Successfully created a new VNet: $($VNet.Name)."
}

If ($CreateNewVNetFail)
{
	Write-Error -Message "Failed to create a new VNet: $($VNet.Name)."
    exit 2
}

# Creating a new Public IP Address for RDP Access.
$PublicIP = New-AzureRmPublicIpAddress `
    -Name $VMName-pip `
    -ResourceGroupName $ResourceGroupName `
    -AllocationMethod Dynamic `
    -DomainNameLabel "$VMName-pip" `
    -Location $Location `
    -ErrorAction SilentlyContinue `
    -ErrorVariable CreateNewPublicIPFail

If (!$CreateNewPublicIPFail)
{
    Write-Output "Successfully created a new Public IP Address: $($PublicIP.Name)."
}

If ($CreateNewPublicIPFail)
{
	Write-Error -Message "Failed to create a new Public IP Address: $($PublicIP.Name)."
    exit 2
}

# Creating a new NIC Card for the VM.
$NIC = New-AzureRmNetworkInterface `
    -Name "$VMName-NIC" `
    -ResourceGroupName $ResourceGroupName `
    -SubnetId $VNet.Subnets[0].id `
    -PublicIpAddressId $PublicIP.Id `
    -Location $Location `
    -ErrorAction SilentlyContinue `
    -ErrorVariable CreateNewNICFail

If (!$CreateNewNICFail)
{
    Write-Output "Successfully created a new NIC Card: $($NIC.Name)."
}

If ($CreateNewNICFail)
{
	Write-Error -Message "Failed to create a new NIC Card: $($NIC.Name)."
    exit 2
}

# Assocating the NIC Card to the VM.
$VM = Add-AzureRmVMNetworkInterface `
    -VM $VMConfig `
    -Id $NIC.Id `
    -ErrorAction SilentlyContinue `
    -ErrorVariable AddNICtoVMFail

If (!$AddNICtoVMFail)
{
    Write-Output "Successfully added the NIC Card to the VM: $VMName."
}

If ($AddNICtoVMFail)
{
	Write-Error -Message "Failed to add the NIC Card to the VM: $VMName."
    exit 2
}

# Configuring the VM OS Disk Settings.
$OSDiskName    = "$VMName" + "_OS_Disk"
$OSDiskCaching = "ReadWrite"
$OSDiskVhdUri  = "https://$StorageAccountName.blob.core.windows.net/vhds/$OSDiskName.vhd"

# Encrypting the local administrator Password.
$SecureLocalAdminPassword = ConvertTo-SecureString $LocalAdminPassword -AsPlainText -Force

# Adding the Credentials from earlier into a PSCredential Object.
$Credentials = New-Object System.Management.Automation.PSCredential ($LocalAdminUsername, $SecureLocalAdminPassword)

# Setting the VM Operating System Settings.
$VM = Set-AzureRmVMOperatingSystem `
    -VM $VM `
    -Windows `
    -ComputerName $VMName `
    -Credential $Credentials `
    -ErrorAction SilentlyContinue `
    -ErrorVariable SetOSSettingsFail

If (!$SetOSSettingsFail)
{
    Write-Output "Successfully configured the VM Operating System Settings."
}

If ($SetOSSettingsFail)
{
	Write-Error -Message "Failed to configure the VM Operating System Settings."
    exit 2
}

# Setting OS Image that will be installed on the VM.
$VM = Set-AzureRmVMSourceImage `
    -VM $VM `
    -PublisherName $VMImage.PublisherName `
    -Offer $VMImage.Offer `
    -Skus $VMIMage.Skus `
    -Version $VMImage.Version `
    -ErrorAction SilentlyContinue `
    -ErrorVariable SetVMSourceImageFail

If (!$SetVMSourceImageFail)
{
    Write-Output "Successfully configured the VM Source Image Setting."
}

If ($SetVMSourceImageFail)
{
	Write-Error -Message "Failed to configure the VM Source Image Setting."
    exit 2
}

# Setting the Operating System Disk settings for the VM.
$VM = Set-AzureRmVMOSDisk `
    -VM $VM `
    -VhdUri $OSDiskVhdUri `
    -Name $OSDiskName `
    -CreateOption FromImage `
    -Caching $OSDiskCaching `
    -ErrorAction SilentlyContinue `
    -ErrorVariable SetVMOSDiskFail

If (!$SetVMOSDiskFail)
{
    Write-Output "Successfully configured the VM OS Disk Settings."
}

If ($SetVMOSDiskFail)
{
	Write-Error -Message "Failed to configure the VM OS Disk Settings."
    exit 2
}

# Deploying the VM.
New-AzureRmVM `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -VM $VM `
    -ErrorAction SilentlyContinue `
    -ErrorVariable DeployVMFail

If (!$DeployVMFail)
{
    Write-Output "Successfully deployed the new VM to Azure: $VMName."
}

If ($DeployVMFail)
{
	Write-Error -Message "Failed to deploy the new VM to Azure: $VMName."
    exit 2
}
