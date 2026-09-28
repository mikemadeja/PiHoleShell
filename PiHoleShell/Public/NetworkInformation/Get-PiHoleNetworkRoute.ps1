function Get-PiHoleNetworkRoute {
    <#
.SYNOPSIS
Get info about the routes of your Pi-hole

.DESCRIPTION
Returns information about your Pi-hole's networking routes. Not every field applies to every
route type, so the response is returned as nested objects with PascalCase property names
rather than a hand-picked subset - use -RawOutput to see the untouched API response.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Detailed
Include more detailed information about the individual routes. Available fields depend on the
route type and state

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleNetworkRoute -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/network/routes')]
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

        $Uri = "$($PiHoleServer.OriginalString)/api/network/routes"
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
            $Object = ConvertTo-PiHolePascalCaseObject -InputObject $Response.routes
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
