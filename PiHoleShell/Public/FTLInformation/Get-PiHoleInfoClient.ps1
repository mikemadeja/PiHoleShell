function Get-PiHoleInfoClient {
    <#
.SYNOPSIS
Get information about the requesting client

.DESCRIPTION
Returns information about how the Pi-hole server sees this request: your remote address, the
HTTP version and method used, and the request headers sent. This endpoint does not require
authentication.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoClient -PiHoleServer "http://pihole.domain.com:8080"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/info/client')]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Params = @{
            Uri                  = "$($PiHoleServer.OriginalString)/api/info/client"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Headers = foreach ($Item in $Response.headers) {
                [PSCustomObject]@{
                    Name  = $Item.name
                    Value = $Item.value
                }
            }

            $Object = [PSCustomObject]@{
                RemoteAddress = $Response.remote_addr
                HttpVersion   = $Response.http_version
                Method        = $Response.method
                Headers       = $Headers
            }
            Write-Output $Object
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }
}
