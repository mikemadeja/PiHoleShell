function Remove-PiHoleClient {
    <#
.SYNOPSIS
Remove a client

.DESCRIPTION
Removes a client from Pi-hole. The Pi-hole API deletes clients in a batch, so this sends a
single-item batch containing just the client you specify.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Client
The client to remove - an IP address, IP subnet (CIDR), MAC address, hostname, or interface
(prefixed with a colon, e.g. ":eth0")

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Remove-PiHoleClient -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Client "192.168.1.50"
    #>
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/clients-batchDelete')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$Client,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Target = "Pi-Hole client $Client"
        if ($PSCmdlet.ShouldProcess($Target, "Remove client")) {
            $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

            $Body = @(
                @{
                    item = $Client
                }
            )

            #For some reason this needs to be here to make it an array
            $Body = , $Body
            $Params = @{
                Headers              = @{sid = $($Sid) }
                Uri                  = "$($PiHoleServer.OriginalString)/api/clients:batchDelete"
                Method               = "Post"
                SkipCertificateCheck = $IgnoreSsl
                Body                 = $Body | ConvertTo-Json -Depth 10 -Compress
                ContentType          = "application/json"
            }

            $Response = Invoke-RestMethod @Params

            if ($RawOutput) {
                Write-Output $Response
            }

            else {
                # A successful delete returns 204 No Content, so there's no response body to
                # build a rich object from.
                $Object = [PSCustomObject]@{
                    Client = $Client
                    Status = "Removed"
                }
                Write-Output $Object
            }
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
