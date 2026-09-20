function Get-PiHoleStatsDatabaseQueryType {
    <#
.SYNOPSIS
Get query types (long-term database)

.DESCRIPTION
Request a breakdown of query types (A, AAAA, ...) for a given time range from the long-term
(on-disk) database, rather than the in-memory data returned by Get-PiHoleStatsQueryType.

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
Get-PiHoleStatsDatabaseQueryType -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"

.EXAMPLE
Get-PiHoleStatsDatabaseQueryType -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -From (Get-Date).AddDays(-7) -Until (Get-Date)
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/stats/database/query_types')]
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
            Uri                  = "$($PiHoleServer.OriginalString)/api/stats/database/query_types?from=$FromUnixTime&until=$UntilUnixTime"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $QueryTypes = @('A', 'AAAA', 'ANY', 'SRV', 'SOA', 'PTR', 'TXT', 'NAPTR', 'MX', 'DS', 'RRSIG', 'DNSKEY', 'NS', 'SVCB', 'HTTPS', 'OTHER')
            $ObjectFinal = foreach ($Type in $QueryTypes) {
                [PSCustomObject]@{
                    Type  = $Type
                    Count = $Response.types.$Type
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
