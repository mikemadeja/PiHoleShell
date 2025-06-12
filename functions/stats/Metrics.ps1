function Get-PiHoleStatsRecentBlocked {
    <#
.SYNOPSIS
Get most recently blocked domain
Request most recently blocked domain

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER MaxResult
How many results should be returned

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleStatsRecentBlocked -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl" -MaxResult 20
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [int]$MaxResult = 1,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl
        Write-Verbose -Message "MaxResults - $MaxResult"
        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$PiHoleServer/api/stats/recent_blocked?count=$MaxResult"
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
            foreach ($Item in $Response.blocked) {
                $Object = $null
                $Object = [PSCustomObject]@{
                    Blocked = $Item
                }
                Write-Verbose -Message "Blocked - $Item"
                $ObjectFinal += $Object
            }
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

function Get-PiHoleStatsQueryType {
    <#
.SYNOPSIS
https://TODOFINDNEWAPILINK
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl
    Write-Verbose -Message "MaxResults - $MaxResult"
    $Params = @{
        Headers              = @{sid = $($Sid) }
        Uri                  = "$PiHoleServer/api/stats/query_types"
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
        $ObjectFinal += $Object
        Write-Output $ObjectFinal
    }
}

function Get-PiHoleStatsTopDomain {
    <#
.SYNOPSIS
https://TODOFINDNEWAPILINK
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [int]$MaxResult = 10,
        [bool]$Blocked = $false,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

    switch ($Blocked) {
        $false {
            $Blocked = "false"
        }
        $true {
            $Blocked = "true"
        }
        Default {
            throw "ERROR"
        }
    }
    Write-Verbose "Blocked: $Blocked"

    $Params = @{
        Headers              = @{sid = $($Sid) }
        Uri                  = "$PiHoleServer/api/stats/top_domains?blocked=$Blocked&count=$MaxResult"
        Method               = "Get"
        SkipCertificateCheck = $IgnoreSsl
        ContentType          = "application/json"
    }

    $Response = Invoke-RestMethod @Params

    if ($RawOutput) {
        Write-Output $Response
    }

    if ($Sid) {
        Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
    }
}

function Get-PiHoleStatsSummary {
    <#
.SYNOPSIS
Get overview of Pi-hole activity
Request various query, system, and FTL properties

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
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
        [string]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$PiHoleServer/api/stats/summary"
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

Export-ModuleMember -Function Get-PiHoleStatsRecentBlocked, Get-PiHoleStatsQueryType, Get-PiHoleStatsTopDomain, Get-PiHoleStatsSummary