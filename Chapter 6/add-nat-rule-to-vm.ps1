<#
Chapter 6 - Creating a NAT Rule to an existing Virtual Machine - Example Code
#>

# Create a new Public IP Address
$VIP = New-AzureRmPublicIPaddress `
    –ResourceGroupName “iaas-vm-demo” `
    –Name “vm-nat-pub-ip” `
    –Location “West Europe” `
    –AllocationMethod Dynamic 

# Create a front end IP configuration for the load balancer and use the public IP address to bind to it.
$FrontEndIPConfig = New-AzureRmLoadBalancerFrontEndIPConfig `
    –Name “LBFrontEndIP” `
    –PublicIpAddress $VIP

# Create the Inbound NAT Rule that will translate secure web traffic from port 443 to Port 80.
$HttpNATRule = New-AzureRmLoadBalancerInboundNatRuleConfig `
    –Name “http-nat-rule” `
    –FrontEndIPConfiguration $FrontEndIPConfig `
    –Protocol TCP `
    –FrontEndPort 443 `
    –BackendPort 80

# Give the load balancer the backend subnet where the Windows VM will reside on.
$LBBEPool = New-AzureRmLoadBalancerBackEndAddressPoolConfig `
    –Name “BEPool01”  

# Create the Load Balancer Rule.
$LBRule = New-AzureRmLoadBalancerRuleConfig `
    –Name “http-lb-rule” `
    –FrontEndIPConfiguration $FrontEndIPConfig `
    –BackEndAddresspool $LBBEPool `
    –Protocol TCP `
    –FrontEndPort 80 `
    –BackEndPort 80 

# Create a health probe rule to check the availability of the Windows VM instance in the back-end address pool.
$HealthProbe = New-AzureRmLoadBalancerProbeConfig `
    -Name HealthProbe `
    -Protocol Tcp `
    -Port 80 `
    -IntervalInSeconds 15 `
    -ProbeCount 1 

# Create the load balancer itself and use the rules and items we configure as base items.
$AzureLB = New-AzureRmLoadBalancer `
    -ResourceGroupName "iaas-vm-demo" `
    -Name "iaas-vm-lb" `
    -Location "west Europe" `
    -FrontendIpConfiguration $FrontEndIPConfig `
    -InboundNatRule $HttpNATRule `
    -LoadBalancingRule $LBRule `
    -BackendAddressPool $LBBEPool `
    -Probe $HealthProbe 

# Associate the Windows VM network interface to the load balancer rule using the following code snippets.
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
