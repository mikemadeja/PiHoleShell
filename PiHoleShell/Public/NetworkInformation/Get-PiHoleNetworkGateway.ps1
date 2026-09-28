function Get-PiHoleNetworkGateway {
    <#
.SYNOPSIS
Get info about the gateway of your Pi-hole

.DESCRIPTION
Returns information about your Pi-hole's network gateway(s). The response shape varies by
address family and interface type, so it's returned as nested objects with PascalCase property
names rather than a hand-picked subset - use -RawOutput to see the untouched API response.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Detailed
Include detailed information about the individual interfaces and routes. Available fields
depend on the interface type and state

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleNetworkGateway -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/network/gateway')]
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
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Uri = "$($PiHoleServer.OriginalString)/api/network/gateway"
        if ($PSBoundParameters.ContainsKey('Detailed')) {
            $Uri += "?detailed=$($Detailed.ToString().ToLower())"
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = $Uri
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = ConvertTo-PiHolePascalCaseObject -InputObject $Response.gateway
            Write-Output $Object
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}
