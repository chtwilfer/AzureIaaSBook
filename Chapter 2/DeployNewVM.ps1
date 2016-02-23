$vmname = read-host “Please Enter VM Name”
import-module AzureRM
$rg = "SCDEMO"
$loc = "North Europe"

Select-AzureRmSubscription -SubscriptionName "testsubscription"

$storacct = Get-AzureRmStorageAccount -StorageAccountName “StorageAccount” -ResourceGroupName $rg

$diskname = $vmname + "_OSDisk"

$vhduri = $storacct.PrimaryEndpoints.Blob.OriginalString + "vhds/${diskname}.vhd"

$image = get-azurermvmimage -Location $loc -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version 4.0.20150916

$vNet = Get-AzureRmVirtualNetwork

$subnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vNet

$nic = New-AzureRmNetworkInterface -Name "${vmname}_nic1" -Subnet $subnet -Location $loc -ResourceGroupName $rg 

$secpassword = convertto-securestring "LS1setup!" -asplaintext -force

$username = "msadmin"

$creds = New-Object System.Management.Automation.PSCredential($username, $secpassword)

$vmconfig = New-AzureRmVMConfig  -VMName $vmname -VMSize "Standard_A2"

Set-AzureRmVMOperatingSystem -Windows -VM $vmconfig -ProvisionVMAgent -EnableAutoUpdate -Credential $creds -ComputerName $vmname

Set-AzureRmVMSourceImage -VM $vmconfig -PublisherName $image.PublisherName -Offer $image.Offer -Skus $image.Skus -Version $image.Version

Add-AzureRmVMNetworkInterface -VM $vmconfig -Id $nic.Id

Set-AzureRmVMOSDisk -VM $vmconfig -Name $diskname -VhdUri $vhduri -Caching ReadWrite -CreateOption fromImage

New-AzureRMVM -ResourceGroupName $rg -Location $loc -VM $vmconfig 
