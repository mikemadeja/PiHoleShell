function Get-PiHoleNetworkInterface {
    <#
.SYNOPSIS
Get info about the interfaces of your Pi-hole

.DESCRIPTION
Returns information about your Pi-hole's networking interfaces. Not every field applies to
every interface type, so the response is returned as nested objects with PascalCase property
names rather than a hand-picked subset - use -RawOutput to see the untouched API response.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Detailed
Include more detailed information about the individual interfaces. Available fields depend on
the interface type and state

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleNetworkInterface -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/network/interfaces')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Nullable[bool]]$Detailed,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    Get-PiHoleNetworkInfo -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -RawOutput $RawOutput -Endpoint 'network/interfaces' -Property 'interfaces' -Detailed $Detailed
}
