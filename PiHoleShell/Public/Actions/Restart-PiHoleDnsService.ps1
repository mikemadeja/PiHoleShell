function Restart-PiHoleDnsService {
    <#
.SYNOPSIS
Restarts the pihole-FTL service

.DESCRIPTION
Restarts the Pi-hole DNS resolver (FTL).

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Invoke-PiHoleRestartDns -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/action/restartdns')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    if (-not $PSCmdlet.ShouldProcess("Pi-Hole server at $PiHoleServer", "Restart DNS service")) {
        return
    }

    Invoke-PiHoleAction -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -RawOutput $RawOutput -Endpoint 'action/restartdns' -Status 'Restarted'
}