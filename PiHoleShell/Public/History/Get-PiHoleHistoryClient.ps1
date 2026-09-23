function Get-PiHoleHistoryClient {
    <#
.SYNOPSIS
Get per-client activity graph data

.DESCRIPTION
Request the data needed to generate the "client activity over the last 24 hours" graph. This
returns the top N clients (by total query count within the last 24 hours); pass -MaxResult 0
to return all clients. Client names are only available if the client's IP address can be
resolved to a hostname. Due to privacy settings, the returned data may be empty.

The last client returned is always a special entry with the name "other clients" and IP
"0.0.0.0", representing the combined total of any clients outside the top N.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER MaxResult
The maximum number of clients to return. Set to 0 to return all clients. Defaults to 20

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleHistoryClient -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/history/clients')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [int]$MaxResult = 20,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/history/clients?N=$MaxResult"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $ClientNames = @{}
            foreach ($Property in $Response.clients.PSObject.Properties) {
                $ClientNames[$Property.Name] = $Property.Value.name
            }

            $ObjectFinal = foreach ($Item in $Response.history) {
                $Clients = foreach ($Property in $Item.data.PSObject.Properties) {
                    [PSCustomObject]@{
                        IP    = $Property.Name
                        Name  = $ClientNames[$Property.Name]
                        Count = $Property.Value
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
