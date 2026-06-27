function Get-PiHoleStatsQueryType {
    <#
.SYNOPSIS
https://TODOFINDNEWAPILINK
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl
    Write-Verbose -Message "MaxResults - $MaxResult"
    $Params = @{
        Headers              = @{sid = $($Sid) }
        Uri                  = "$($PiHoleServer.OriginalString)/api/stats/query_types"
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