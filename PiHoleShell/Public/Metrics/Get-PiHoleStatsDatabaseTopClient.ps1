function Get-PiHoleStatsDatabaseTopClient {
    <#
.SYNOPSIS
Get top clients (long-term database)

.DESCRIPTION
Request the top clients for a given time range from the long-term (on-disk) database, rather
than the in-memory data returned by Get-PiHoleStatsTopClient.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER From
Local date/time from when the data should be requested

.PARAMETER Until
Local date/time until when the data should be requested

.PARAMETER MaxResult
How many results should be returned

.PARAMETER Blocked
If true, returns top clients by blocked queries instead of total queries

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleStatsDatabaseTopClient -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl" -From (Get-Date).AddDays(-7) -Until (Get-Date) -MaxResult 10
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/stats/database/top_clients')]
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
        [int]$MaxResult = 10,
        [bool]$Blocked = $false,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        switch ($Blocked) {
            $false { $BlockedParam = "false" }
            $true { $BlockedParam = "true" }
            Default { throw "ERROR" }
        }
        Write-Verbose "Blocked: $BlockedParam"
        Write-Verbose "MaxResult: $MaxResult"

        $FromUnixTime = (Convert-LocalTimeToPiHoleUnixTime -Date $From).UnixTime
        $UntilUnixTime = (Convert-LocalTimeToPiHoleUnixTime -Date $Until).UnixTime

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/stats/database/top_clients?from=$FromUnixTime&until=$UntilUnixTime&blocked=$BlockedParam&count=$MaxResult"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $ObjectFinal = @()
            foreach ($Item in $Response.clients) {
                $Object = [PSCustomObject]@{
                    IP    = $Item.ip
                    Name  = $Item.name
                    Count = $Item.count
                }
                Write-Verbose -Message "Client - $($Item.ip) ($($Item.name)): $($Item.count)"
                $ObjectFinal += $Object
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
