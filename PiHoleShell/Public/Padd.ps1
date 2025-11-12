function Get-PiHolePadd {
    <#
.SYNOPSIS
Methods used to query Pi-hole from PADD

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Ignore SSL when interacting with the PiHole API

.EXAMPLE
Get-PiHolePadd -PiHoleServer "http://pihole.domain.com:8080" -Password "APIPASSWORD"
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
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/padd"
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
            $Object = $null
            $IFaceV4RxBytes = [PSCustomObject]@{
                Value = $Response.iface.v4.rx_bytes.value
                Unit  = $Response.iface.v4.rx_bytes.unit
            }
            $IFaceV4TxBytes = [PSCustomObject]@{
                Value = $Response.iface.v4.tx_bytes.value
                Unit  = $Response.iface.v4.tx_bytes.unit
            }
            $IFaceV4 = [PSCustomObject]@{
                Addr     = $Response.iface.v4.addr
                RxBytes  = $IFaceV4RxBytes
                TxBytes  = $IFaceV4TxBytes
                NumAddrs = $Response.iface.v4.num_addrs
                Name     = $Response.iface.v4.name
                GwAddr   = $Response.iface.v4.gw_addr
            }
            $IFaceV6 = [PSCustomObject]@{
                Addr     = $Response.iface.v6.addr
                NumAddrs = $Response.iface.v6.num_addrs
                Name     = $Response.iface.v6.name
                GwAddr   = $Response.iface.b6.gw_addr
            }
            $IFace = [PSCustomObject]@{
                v4 = $IfaceV4
                v6 = $IfaceV6
            }
            $Queries = [PSCustomObject]@{
                Total          = $Response.queries.total
                Blocked        = $Response.queries.blocked
                PercentBlocked = $Response.queries.percent_blocked
            }
            $Sensors = [PSCustomObject]@{
                CpuTemp  = $Response.sensors.cpu_temp
                HotLimit = $Response.sensors.hot_limit
                Unit     = $Response.sensors.unit
            }
            $Cache = [PSCustomObject]@{
                Size     = $Response.cache.size
                Inserted = $Response.cache.inserted
                Evicted  = $Reponse.cache.evicted
            }

            $Object = [PSCustomObject]@{
                CpuPercent    = $Response."%cpu"
                MemoryPercent = $Response."%mem"
                ActiveClients = $Response.active_clients
                Blocking      = $Response.blocking
                Cache         = $Cache
                Config        = [PSCustomObject]@{
                    DhcpActive          = $Response.config.dhcp_active
                    DhcpStart           = $Response.config.dhcp_start
                    DhcpEnd             = $Response.config.dhcp_end
                    DhcpIpv6            = $Response.config.dhcp_ipv6
                    DnsDnssec           = $Response.config.dns_dnssec
                    DnsDomain           = $Response.config.dns_domain
                    DnsNumUpstreams     = $Response.config.dns_num_upstreams
                    DnsPort             = $Response.config.dns_port
                    DnsrevServerAactive = $Response.config.dns_revServer_active
                    PrivacyLevel        = $Response.config.privacy_level
                }
                GravitySize   = $Response.gravity_size
                HostModel     = $Response.host_model
                IFace         = $IFace
                NodeName      = $Response.node_name
                Pid           = $Response.pid
                Queries       = $Queries
                RecentBlocked = $Response.recent_blocked
                Sensors       = $Sensors
                System        = $Response.system
                TopBlocked    = $Response.top_blocked
                TopClient     = $Response.top_client
                TopDomain     = $Response.top_domain
                Version       = $Response.version
            }
            if ($Object) {
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