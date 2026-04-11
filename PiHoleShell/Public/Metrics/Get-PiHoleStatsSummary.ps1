function Get-PiHoleStatsSummary {
    <#
.SYNOPSIS
Get overview of Pi-hole activity
Request various query, system, and FTL properties

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server


This will dump the response instead of the formatted object

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleStatsSummary -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl"
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/stats/summary"
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
                Total          = $Response.queries.total
                Blocked        = $Response.queries.blocked
                PercentBlocked = $Response.queries.percent_blocked
                Types          = [PSCustomObject]@{
                    A      = $Response.queries.types.A
                    AAAA   = $Response.queries.types.AAAA
                    ANY    = $Response.queries.types.ANY
                    SRV    = $Response.queries.types.SRV
                    SOA    = $Response.queries.types.SOA
                    PTR    = $Response.queries.types.PTR
                    TXT    = $Response.queries.types.TXT
                    NAPTR  = $Response.queries.types.NAPTR
                    MX     = $Response.queries.types.MX
                    DS     = $Response.queries.types.DS
                    RRSIG  = $Response.queries.types.RRSIG
                    DNSKEY = $Response.queries.types.DNSKEY
                    NS     = $Response.queries.types.NS
                    SVCB   = $Response.queries.types.SVCB
                    HTTPS  = $Response.queries.types.HTTPS
                    OTHER  = $Response.queries.types.OTHER
                }
                Status         = [PSCustomObject]@{
                    Unknown              = $Response.queries.status.UNKNOWN
                    Gravity              = $Response.queries.status.GRAVITY
                    Forwarded            = $Response.queries.status.FORWARDED
                    Cache                = $Response.queries.status.CACHE
                    Regex                = $Response.queries.status.REGEX
                    DenyList             = $Response.queries.status.DENYLIST
                    ExternalBlockedIp    = $Response.queries.status.EXTERNAL_BLOCKED_IP
                    ExternalBlockedNull  = $Response.queries.status.EXTERNAL_BLOCKED_NULL
                    ExternalBlockedNxra  = $Response.queries.status.EXTERNAL_BLOCKED_NXRA
                    GravityCname         = $Response.queries.status.GRAVITY_CNAME
                    RegexCname           = $Response.queries.status.REGEX_CNAME
                    DenyListCname        = $Response.queries.status.DENYLIST_CNAME
                    Retired              = $Response.queries.status.RETRIED
                    RetiredDnssec        = $Response.queries.status.RETRIED_DNSSEC
                    InProgress           = $Response.queries.status.IN_PROGRESS
                    Dbbusy               = $Response.queries.status.DBBUSY
                    SpecialDomain        = $Response.queries.status.SPECIAL_DOMAIN
                    CacheStale           = $Response.queries.status.CACHE_STALE
                    ExternalBlockedEde15 = $Response.queries.status.EXTERNAL_BLOCKED_EDE15
                }
                Replies        = [PSCustomObject]@{
                    Unknown  = $Response.queries.replies.UNKNOWN
                    Nodata   = $Response.queries.replies.NODATA
                    Nxdomain = $Response.queries.replies.NXDOMAIN
                    Cname    = $Response.queries.replies.CNAME
                    Ip       = $Response.queries.replies.IP
                    Domain   = $Response.queries.replies.DOMAIN
                    Rrname   = $Response.queries.replies.RRNAME
                    ServFail = $Response.queries.replies.SERVFAIL
                    Refused  = $Response.queries.replies.REFUSED
                    Notimp   = $Response.queries.replies.NOTIMP
                    Other    = $Response.queries.replies.OTHER
                    Dnssec   = $Response.queries.replies.DNSSEC
                    None     = $Response.queries.replies.NONE
                    Blob     = $Response.queries.replies.BLOB
                }
            }
            $ObjectFinal += $Object
            Write-Output $ObjectFinal
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
        break
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}