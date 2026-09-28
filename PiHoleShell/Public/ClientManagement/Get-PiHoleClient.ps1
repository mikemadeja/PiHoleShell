function Get-PiHoleClient {
    <#
.SYNOPSIS
Get clients

.DESCRIPTION
Request Pi-hole's configured clients (used to apply group-based rules to specific devices).
Omit -Client to get every configured client; specify it to get just that one.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Client
A specific client to return - an IP address, IP subnet (CIDR), MAC address, hostname, or
interface (prefixed with a colon, e.g. ":eth0"). Omit to return every configured client

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleClient -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"

.EXAMPLE
Get-PiHoleClient -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Client "192.168.1.50"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/clients/-client-')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [string]$Client,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Groups = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Uri = "$($PiHoleServer.OriginalString)/api/clients"
        if ($Client) {
            $Uri += "/$([System.Uri]::EscapeDataString($Client))"
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
            $ObjectFinal = foreach ($Item in $Response.clients) {
                $GroupNames = [System.Collections.ArrayList]@()
                foreach ($Group in $Item.groups) {
                    $GroupNames += ($Groups | Where-Object { $_.Id -eq $Group }).Name
                }

                [PSCustomObject]@{
                    Client       = $Item.client
                    Name         = $Item.name
                    Comment      = $Item.comment
                    Groups       = $GroupNames
                    Id           = $Item.id
                    DateAdded    = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_added).LocalTime
                    DateModified = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
                }
            }
            Write-Output $ObjectFinal
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
