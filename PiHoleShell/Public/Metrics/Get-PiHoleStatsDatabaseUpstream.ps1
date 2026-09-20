function Get-PiHoleStatsDatabaseUpstream {
    <#
.SYNOPSIS
Get metrics about Pi-hole's upstream destinations (long-term database)

.DESCRIPTION
Request upstream metrics from the long-term (on-disk) database for a given time range, rather
than the in-memory data returned by Get-PiHoleStatsUpstream.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER From
Local date/time from when the data should be requested

.PARAMETER Until
Local date/time until when the data should be requested

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleStatsDatabaseUpstream -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl" -From (Get-Date).AddDays(-7) -Until (Get-Date)
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/stats/database/upstreams')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [datetime]$From,
        [Parameter(Mandatory = $true)]
        [datetime]$Until,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $FromUnixTime = (Convert-LocalTimeToPiHoleUnixTime -Date $From).UnixTime
        $UntilUnixTime = (Convert-LocalTimeToPiHoleUnixTime -Date $Until).UnixTime

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/stats/database/upstreams?from=$FromUnixTime&until=$UntilUnixTime"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Upstreams = foreach ($Item in $Response.upstreams) {
                [PSCustomObject]@{
                    Ip           = $Item.ip
                    Name         = $Item.name
                    Port         = $Item.port
                    Count        = $Item.count
                    ResponseTime = $Item.statistics.response
                    Variance     = $Item.statistics.variance
                }
            }
            $Object = [PSCustomObject]@{
                TotalQueries     = $Response.total_queries
                ForwardedQueries = $Response.forwarded_queries
                Upstreams        = $Upstreams
            }
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
