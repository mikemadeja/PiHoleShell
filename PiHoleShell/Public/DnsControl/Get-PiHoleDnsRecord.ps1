function Get-PiHoleDnsRecord {
    <#
.SYNOPSIS
Get local DNS records

.DESCRIPTION
Returns Pi-hole's local DNS records (A, AAAA, and CNAME) as a flat list of objects shaped the
same way as Add-PiHoleDnsRecord/Remove-PiHoleDnsRecord, so the result can be piped straight into
Remove-PiHoleDnsRecord. This is a DNS-specific convenience wrapper around Get-PiHoleConfig,
which it calls internally - using that directly (.Dns.Hosts / .Dns.CnameRecords) is equivalent,
just not already split into A/AAAA/CNAME or filterable by -Type/-Hostname.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Type
Only return records of this kind: A (IPv4), AAAA (IPv6), or CNAME. If omitted, all are returned

.PARAMETER Hostname
Only return the record(s) for this exact hostname (the alias, for a CNAME). If omitted, every
record is returned

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleDnsRecord -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"

.EXAMPLE
Get-PiHoleDnsRecord -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Type CNAME

.EXAMPLE
Get-PiHoleDnsRecord -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Hostname "test.local" | Remove-PiHoleDnsRecord -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/config')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [ValidateSet('A', 'AAAA', 'CNAME')]
        [string]$Type,
        [string]$Hostname,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Config = Get-PiHoleConfig -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -ErrorAction Stop

        if ($RawOutput) {
            $Object = [PSCustomObject]@{
                Hosts        = $Config.Dns.Hosts
                CnameRecords = $Config.Dns.CnameRecords
            }
            Write-Output $Object
        }
        else {
            $Records = foreach ($Entry in $Config.Dns.Hosts) {
                # Each entry is "<ip> <hostname>" - hostnames never contain spaces, so splitting
                # into at most 2 parts on the first space is safe even if an IPv6 address itself
                # cannot contain one.
                $Parts = $Entry.Split(' ', 2)
                $Address = $Parts[0]
                $RecordHostname = $Parts[1]

                $ParsedAddress = $null
                $IsIPv6 = [System.Net.IPAddress]::TryParse($Address, [ref]$ParsedAddress) -and $ParsedAddress.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6

                [PSCustomObject]@{
                    Type        = if ($IsIPv6) { 'AAAA' } else { 'A' }
                    Hostname    = $RecordHostname
                    IPv4Address = if ($IsIPv6) { $null } else { $Address }
                    IPv6Address = if ($IsIPv6) { $Address } else { $null }
                    Target      = $null
                    Ttl         = $null
                }
            }

            $Records += foreach ($Entry in $Config.Dns.CnameRecords) {
                # Each entry is "<alias>,<target>[,<ttl>]" - the TTL segment is optional.
                $Parts = $Entry.Split(',')
                [PSCustomObject]@{
                    Type        = 'CNAME'
                    Hostname    = $Parts[0]
                    IPv4Address = $null
                    IPv6Address = $null
                    Target      = $Parts[1]
                    Ttl         = if ($Parts.Count -gt 2) { [int]$Parts[2] } else { $null }
                }
            }

            if ($PSBoundParameters.ContainsKey('Type')) {
                $Records = $Records | Where-Object { $_.Type -eq $Type }
            }
            if ($PSBoundParameters.ContainsKey('Hostname')) {
                $Records = $Records | Where-Object { $_.Hostname -eq $Hostname }
            }

            Write-Output $Records
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }
}
