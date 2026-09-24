function Get-PiHoleHistoryDatabaseClient {
    <#
.SYNOPSIS
Get per-client activity graph data (long-term data)

.DESCRIPTION
Request the long-term (on-disk database) data needed to generate the per-client activity
graph for a given time range. Due to privacy settings, the returned data may be empty.

Unlike Get-PiHoleHistoryClient (the live/last-24-hours version), the Pi-hole API keys this
endpoint's per-timestamp client breakdown by an internal numeric client ID rather than by IP
address, while the separate client summary it also returns is keyed by IP - there's no shared
key to join the two on. Because of this, ClientId below cannot be reliably resolved to an IP
or hostname and is returned as-is; use -RawOutput to inspect the full response if you need to
investigate further.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER From
Local date/time from when the data should be requested. Defaults to 8 hours ago.

.PARAMETER Until
Local date/time until when the data should be requested. Defaults to now.

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleHistoryDatabaseClient -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"

.EXAMPLE
Get-PiHoleHistoryDatabaseClient -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -From (Get-Date).AddDays(-7) -Until (Get-Date)
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/history/database/clients')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [datetime]$From = (Get-Date).AddHours(-8),
        [datetime]$Until = (Get-Date),
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $FromUnixTime = (Convert-LocalTimeToPiHoleUnixTime -Date $From).UnixTime
        $UntilUnixTime = (Convert-LocalTimeToPiHoleUnixTime -Date $Until).UnixTime

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/history/database/clients?from=$FromUnixTime&until=$UntilUnixTime"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            # The `data` keys here are internal numeric client IDs, not IPs - they don't match
            # the IP-keyed `clients` summary the API also returns, so names can't be resolved.
            $ObjectFinal = foreach ($Item in $Response.history) {
                $Clients = foreach ($Property in $Item.data.PSObject.Properties) {
                    [PSCustomObject]@{
                        ClientId = $Property.Name
                        Count    = $Property.Value
                    }
                }
                [PSCustomObject]@{
                    Timestamp = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.timestamp).LocalTime
                    Clients   = $Clients
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
