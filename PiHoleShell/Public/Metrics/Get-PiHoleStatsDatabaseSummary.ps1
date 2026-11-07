function Get-PiHoleStatsDatabaseSummary {
    <#
.SYNOPSIS
Get database content details

.DESCRIPTION
Request various database content details (total/blocked queries, percent blocked, total
clients) for a given time range from the long-term (on-disk) database.

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
Get-PiHoleStatsDatabaseSummary -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"

.EXAMPLE
Get-PiHoleStatsDatabaseSummary -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -From (Get-Date).AddDays(-7) -Until (Get-Date)
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/stats/database/summary')]
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
        $FromUnixTime = (Convert-LocalTimeToPiHoleUnixTime -Date $From).UnixTime
        $UntilUnixTime = (Convert-LocalTimeToPiHoleUnixTime -Date $Until).UnixTime

        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint "stats/database/summary?from=$FromUnixTime&until=$UntilUnixTime"

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = [PSCustomObject]@{
                SumQueries     = $Response.sum_queries
                SumBlocked     = $Response.sum_blocked
                PercentBlocked = $Response.percent_blocked
                TotalClients   = $Response.total_clients
            }
            Write-Output $Object
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}
