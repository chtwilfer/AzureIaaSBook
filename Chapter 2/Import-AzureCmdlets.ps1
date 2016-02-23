Function Import-AzureCmdlets
{
# Test or create scripts directory
If (!(Test-Path "C:\Scripts")) {New-Item "C:\Scripts" -Type Directory}
 
# Changes to root of drive
Set-Location "C:\Scripts"
 
# Checks for Azure PowerShell Module, imports if it exists
if (Test-Path "C:\Program Files (x86)\Microsoft SDKs\Microsoft Azure\PowerShell\Azure\Azure.psd1") 
    {
        Write-Output "Importing Azure Management PowerShell cmdlets..."
        Import-Module "C:\Program Files (x86)\Microsoft SDKs\Microsoft Azure\PowerShell\Azure\Azure.psd1"
    }
# Checks for Azure AD Module, imports if it exists
if (Test-Path "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\MSOnline\MSOnline.psd1") 
    {
        Write-Output "Importing Microsoft Azure AD management cmdlets..."
        Import-Module "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\MSOnline\MSOnline.psd1"
    }
} 
