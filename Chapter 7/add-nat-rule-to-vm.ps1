<#
Chapter 6 - Creating a NAT Rule to an existing Virtual Machine - Example Code
#>

$VIP = New-AzureRmPublicIPaddress `
    –ResourceGroupName “iaas-vm-demo” `
    –Name “vm-nat-pub-ip” `
    –Location “West Europe” `
    –AllocationMethod Dynamic 

$FrontEndIPConfig = New-AzureRmLoadBalancerFrontEndIPConfig `
    –Name “LBFrontEndIP” `
    –PublicIpAddress $VIP

$HttpNATRule = New-AzureRmLoadBalancerInboundNatRuleConfig `
    –Name “http-nat-rule” `
    –FrontEndIPConfiguration $FrontEndIPConfig `
    –Protocol TCP `
    –FrontEndPort 443 `
    –BackendPort 80

$LBBEPool = New-AzureRmLoadBalancerBackEndAddressPoolConfig `
    –Name “BEPool01”  

$LBRule = New-AzureRmLoadBalancerRuleConfig `
    –Name “http-lb-rule” `
    –FrontEndIPConfiguration $FrontEndIPConfig `
    –BackEndAddresspool $LBBEPool `
    –Protocol TCP `
    –FrontEndPort 80 `
    –BackEndPort 80 

$HealthProbe = New-AzureRmLoadBalancerProbeConfig `
    -Name HealthProbe `
    -Protocol Tcp `
    -Port 80 `
    -IntervalInSeconds 15 `
    -ProbeCount 1 

$AzureLB = New-AzureRmLoadBalancer `
    -ResourceGroupName "iaas-vm-demo" `
    -Name "iaas-vm-lb" `
    -Location "west Europe" `
    -FrontendIpConfiguration $FrontEndIPConfig `
    -InboundNatRule $HttpNATRule `
    -LoadBalancingRule $LBRule `
    -BackendAddressPool $LBBEPool `
    -Probe $HealthProbe 

$VNet = Get-AzureRmVirtualNetwork `
    –Name “VNet-iaas-vm-demo” `
    –ResourceGroupName “iaas-vm-demo”

$Subnet = Get-AzureRmVirtualNetworkSubnetConfig `
    –VirtualNetwork $VNet `
    –Name “Subnet-iaas-vm-demo”

$NIC = Get-AzureRmNetworkInterface `
    –Name “iaas-vm-NIC” `
    –ResourceGroupName “iaas-vm-demo”

$NIC.ipconfigurations[0].LoadBalancerBackendAddressPools.Add($AzureLB.backendaddresspools[0])

$NIC | Set-AzureRmNetworkInterface  

