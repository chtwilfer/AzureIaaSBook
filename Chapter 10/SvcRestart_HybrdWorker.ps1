Workflow RestartWinService
{
	param (
		[Parameter(Mandatory=$false)]
			[string] $servername,
		[Parameter(Mandatory=$false)]
			[string] $servicename
	)

    $login = Get-AutomationPSCredential -Name `
    'SKYNET Super User'
    
    $restart = inlinescript {
    $s = New-PSSession -ComputerName $using:servername `
    -credential $using:login 

    $remoterestart = Invoke-command -session $s `
    -Scriptblock {

    Restart-service -Name $args[0]

    } -ArgumentList $using:servicename

    Remove-PSSession $s

    }
}
