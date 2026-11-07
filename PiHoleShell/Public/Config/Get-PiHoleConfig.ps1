function Get-PiHoleConfig {
    <#
.SYNOPSIS
Get current configuration of Pi-hole

.DESCRIPTION
Request Pi-hole's full configuration tree (dns, dhcp, ntp, resolver, database, webserver,
files, misc, and debug settings). The formatted output mirrors the API response as nested
objects with PascalCase property names, so the entire configuration is available for
inspection rather than a hand-picked subset. Pass -Element to request just one subset of
the tree instead of everything.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Element
Only return this part of the configuration tree, as a slash-separated path (e.g.
"dns/upstreams" or "dns/hosts"). Omit to return the entire configuration

.PARAMETER Detailed
Include detailed information about the configuration (e.g. value types and validation info)

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleConfig -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"

.EXAMPLE
(Get-PiHoleConfig -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password").Dns.Upstreams

.EXAMPLE
Get-PiHoleConfig -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Element "dns/upstreams"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/config')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [string]$Element,
        [Nullable[bool]]$Detailed,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Endpoint = 'config'
        if ($Element) {
            $Endpoint += "/$($Element.Trim('/'))"
        }
        if ($PSBoundParameters.ContainsKey('Detailed')) {
            $Endpoint += "?detailed=$($Detailed.ToString().ToLower())"
        }

        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint $Endpoint

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = ConvertTo-PiHolePascalCaseObject -InputObject $Response.config
            Write-Output $Object
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}
