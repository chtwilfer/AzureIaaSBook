#################################################
#
# This sample adds a NAT rule to an existing VM.
#
# works for Windows or Linux\UNIX VMs
#
# Assumes you are already authenticated and 
# connected to your Azure subscription. 
#
#################################################

$vip = New-AzurePublicIPaddress –ResourceGroupName "VMResourceGroup" `
–Name "VMNATPublicIP" –Location "North Europe" –AllocationMethod Dynamic

$feIPConf = New-AzureLoadBalancerFrontEndIPConfig `
–Name "ALBFEIP" –PublicIpAddress $vip

$httpnatrule = New-AzureLoadBalancerInboundNatRuleConfig `
–Name "Http" –FrontEndIPConfiguration $feIPConf –Protocol TCP `
–FrontEndPort 80 –BackendPort 80

$lbbepool = New-AzureLoadbalancerBackEndAddressPoolConfig `
–Name "BEPool01"

$lbrule = New-AzureLoadBalancerRuleConfig –Name "Http" `
–FrontEndIPConfiguration $feIPConf –BackEndAddresspool $lbbepool `
–Protocol TCP –FrontEndPort 80 –BackEndPort 80

$azurelb = New-AzureLoadBalancer -ResourceGroupName "VMResourceGroup" `
-Name "VM_LB" -Location "North Europe" -FrontendIpConfiguration $feIpConf `
-InboundNatRule $httpnatrule -LoadBalancingRule $lbrule `
-BackendAddressPool $lbbePool  

$vnet = Get-AzureVirtualNetwork –Name "CloudVNet" `
–ResourceGroupName "VMResourceGroup"

$subnet = Get-AzureVirtualNetworksubnetconfig `
–VirtualNetwork $vnet –Name "production"

$netint = Get-AzureNetworkInterface –Name "WinVMNic" `
–ResourceGroupName "VMResourceGroup"

$netint.ipconfigurations[0].LoadBalancerBackendAddressPools.Add($azurelb.backendaddresspools[0])

$netint | Set-AzureNetworkInterface 
