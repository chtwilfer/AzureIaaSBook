#################################################
#
# This sample adds a data disk to an existing VM
#
# works for Windows or Linux\UNIX VMs
#
# Assumes you are already authenticated and 
# connected to your Azure subscription. 
#
#################################################

# Retrieve the VM we want to update
$VM = Get-AzureVM –ResourceGroupName `
"VMLinuxResourceGroup" -Name "LNX001"

# Retrieve storage acct the VM resides in
$storacct = $VM.StorageProfile.OsDisk.VirtualHardDisk.URI.split("/")[2]

# Construct the URI for the new data disk
$datadiskURI = "https://$storacct/vhds/" + $vm.name + "-data-disk1.vhd"

# Create the new data disk 
Add-AzureVMDataDisk –VM $vm –Name "Data-Disk1" `
–DisksizeInGB "100" –VhdURI $datadiskURI `
–CreateOption empty

# update the VM 
Update-AzureVM –VM $vm `
–ResourceGroupName "VMLinuxResourceGroup"