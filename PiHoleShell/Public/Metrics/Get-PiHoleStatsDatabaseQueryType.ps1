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
Unix timestamp from when the data should be requested

.PARAMETER Until
Unix timestamp until when the data should be requested

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleStatsDatabaseQueryType -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl" -From 1672580025 -Until 1672666425
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/stats/database/query_types')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [int]$From,
        [Parameter(Mandatory = $true)]
        [int]$Until,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/stats/database/query_types?from=$From&until=$Until"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = [PSCustomObject]@{
                A      = $Response.types.A
                AAAA   = $Response.types.AAAA
                ANY    = $Response.types.ANY
                SRV    = $Response.types.SRV
                SOA    = $Response.types.SOA
                PTR    = $Response.types.PTR
                TXT    = $Response.types.TXT
                NAPTR  = $Response.types.NAPTR
                MX     = $Response.types.MX
                DS     = $Response.types.DS
                RRSIG  = $Response.types.RRSIG
                DNSKEY = $Response.types.DNSKEY
                NS     = $Response.types.NS
                SVCB   = $Response.types.SVCB
                HTTPS  = $Response.types.HTTPS
                OTHER  = $Response.types.OTHER
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
