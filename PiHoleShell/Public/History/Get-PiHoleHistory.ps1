function Get-PiHoleHistory {
    <#
.SYNOPSIS
Get activity graph data

.DESCRIPTION
Request the data needed to generate the "total queries over time" graph, covering roughly
the last 24 hours. The sum of Cached/Blocked/Forwarded for a given entry may be smaller than
Total - the remainder are queries that don't fit into any of those categories (e.g. a busy
database, or an unknown query status).

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleHistory -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/history')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint 'history'

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $ObjectFinal = foreach ($Item in $Response.history) {
                [PSCustomObject]@{
                    Timestamp = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.timestamp).LocalTime
                    Total     = $Item.total
                    Cached    = $Item.cached
                    Blocked   = $Item.blocked
                    Forwarded = $Item.forwarded
                }
            }
            Write-Output $ObjectFinal
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}
