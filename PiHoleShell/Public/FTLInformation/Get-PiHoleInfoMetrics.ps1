function Get-PiHoleInfoMetrics {
    <#
.SYNOPSIS
Get metrics info

.DESCRIPTION
Request live DNS and DHCP metrics: DNS cache statistics (including a per-record-type
breakdown), reply-type counts, and DHCP message/lease counts.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoMetrics -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/info/metrics')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification = "Metrics matches the Pi-hole API's own endpoint name, /info/metrics")]
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
            Uri                  = "$($PiHoleServer.OriginalString)/api/info/metrics"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $CacheContent = foreach ($Item in $Response.metrics.dns.cache.content) {
                [PSCustomObject]@{
                    Type  = $Item.type
                    Name  = $Item.name
                    Count = [PSCustomObject]@{
                        Valid = $Item.count.valid
                        Stale = $Item.count.stale
                    }
                }
            }

            $Object = [PSCustomObject]@{
                Dns  = [PSCustomObject]@{
                    Cache    = [PSCustomObject]@{
                        Size     = $Response.metrics.dns.cache.size
                        Inserted = $Response.metrics.dns.cache.inserted
                        Evicted  = $Response.metrics.dns.cache.evicted
                        Expired  = $Response.metrics.dns.cache.expired
                        Immortal = $Response.metrics.dns.cache.immortal
                        Content  = $CacheContent
                    }
                    Replies  = [PSCustomObject]@{
                        Forwarded  = $Response.metrics.dns.replies.forwarded
                        Unanswered = $Response.metrics.dns.replies.unanswered
                        Local      = $Response.metrics.dns.replies.local
                        Optimized  = $Response.metrics.dns.replies.optimized
                        Auth       = $Response.metrics.dns.replies.auth
                        Sum        = $Response.metrics.dns.replies.sum
                    }
                }
                Dhcp = [PSCustomObject]@{
                    Ack       = $Response.metrics.dhcp.ack
                    Nak       = $Response.metrics.dhcp.nak
                    Decline   = $Response.metrics.dhcp.decline
                    Offer     = $Response.metrics.dhcp.offer
                    Discover  = $Response.metrics.dhcp.discover
                    Inform    = $Response.metrics.dhcp.inform
                    Request   = $Response.metrics.dhcp.request
                    Release   = $Response.metrics.dhcp.release
                    NoAnswer  = $Response.metrics.dhcp.noanswer
                    Bootp     = $Response.metrics.dhcp.bootp
                    Pxe       = $Response.metrics.dhcp.pxe
                    Leases    = [PSCustomObject]@{
                        Allocated4 = $Response.metrics.dhcp.leases.allocated_4
                        Pruned4    = $Response.metrics.dhcp.leases.pruned_4
                        Allocated6 = $Response.metrics.dhcp.leases.allocated_6
                        Pruned6    = $Response.metrics.dhcp.leases.pruned_6
                    }
                }
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
