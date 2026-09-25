function Get-PiHoleInfoLogin {
    <#
.SYNOPSIS
Get login page information

.DESCRIPTION
Returns information used on Pi-hole's login page (the HTTPS port, and whether the DNS server
is currently running). This endpoint does not require authentication, since it's meant to be
usable before logging in.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoLogin -PiHoleServer "http://pihole.domain.com:8080"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/info/login')]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Params = @{
            Uri                  = "$($PiHoleServer.OriginalString)/api/info/login"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = [PSCustomObject]@{
                HttpsPort = $Response.https_port
                Dns       = $Response.dns
            }
            Write-Output $Object
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }
}
