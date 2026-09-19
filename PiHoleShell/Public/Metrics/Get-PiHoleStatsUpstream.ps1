function Get-PiHoleStatsUpstream {
    <#
.SYNOPSIS
Get metrics about Pi-hole's upstream destinations

.DESCRIPTION
Request upstream metrics: which upstream destinations have been used, how many queries each
has handled, and their average response time.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleStatsUpstream -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/stats/upstreams')]
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
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/stats/upstreams"
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
