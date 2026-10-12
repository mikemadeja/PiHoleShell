function Remove-PiHoleDnsRecord {
    <#
.SYNOPSIS
Remove a local DNS record

.DESCRIPTION
Removes a local DNS record from Pi-hole: an A record (IPv4), AAAA record (IPv6), or CNAME
record. This is a DNS-specific convenience wrapper around Remove-PiHoleConfigArrayItem, which
it calls internally - using that directly is equivalent, just less discoverable for this
specific case.

The values given must match the record exactly as it was created (see Get-PiHoleConfig,
under .Dns.Hosts or .Dns.CnameRecords, to check the exact value if removal fails) - for a CNAME
record created with a TTL, -Ttl must be passed here too, with the same value.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Type
The kind of record to remove: A (IPv4), AAAA (IPv6), or CNAME

.PARAMETER Hostname
The hostname of the record to remove. For -Type A or AAAA, this is the name that resolves to
the given address. For -Type CNAME, this is the alias being removed

.PARAMETER IPv4Address
The IPv4 address the record resolves to. Required when -Type is "A"

.PARAMETER IPv6Address
The IPv6 address the record resolves to. Required when -Type is "AAAA"

.PARAMETER Target
The hostname the record is an alias for. Required when -Type is "CNAME"

.PARAMETER Ttl
The TTL (in seconds) the CNAME record was created with, if any. Only used when -Type is
"CNAME" - must match exactly or the removal will not find the record

.PARAMETER Restart
Whether to restart FTL immediately if this change requires it. Defaults to $true. Set to
$false to defer the restart, e.g. when removing several records independently rather than all
at once - you'll need to restart FTL manually later for the changes to take effect

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Remove-PiHoleDnsRecord -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Type A -Hostname "test.local" -IPv4Address "192.168.1.1"

.EXAMPLE
Remove-PiHoleDnsRecord -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Type CNAME -Hostname "alias.local" -Target "test.local" -Ttl 300
    #>
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://ftl.pi-hole.net/master/docs/#delete-/config/-element-/-value-')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [ValidateSet('A', 'AAAA', 'CNAME')]
        [string]$Type,
        [Parameter(Mandatory = $true)]
        [string]$Hostname,
        [string]$IPv4Address,
        [string]$IPv6Address,
        [string]$Target,
        [Nullable[int]]$Ttl,
        [Nullable[bool]]$Restart,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        switch ($Type) {
            'A' {
                if (-not $IPv4Address) {
                    throw "-IPv4Address is required when -Type is 'A'"
                }
                $Element = 'dns/hosts'
                $Value = "$IPv4Address $Hostname"
            }
            'AAAA' {
                if (-not $IPv6Address) {
                    throw "-IPv6Address is required when -Type is 'AAAA'"
                }
                $Element = 'dns/hosts'
                $Value = "$IPv6Address $Hostname"
            }
            'CNAME' {
                if (-not $Target) {
                    throw "-Target is required when -Type is 'CNAME'"
                }
                $Element = 'dns/cnameRecords'
                $Value = "$Hostname,$Target"
                if ($PSBoundParameters.ContainsKey('Ttl')) {
                    $Value += ",$Ttl"
                }
            }
        }

        if ($PSCmdlet.ShouldProcess("Pi-Hole DNS record '$Value' ($Type)", "Remove DNS record")) {
            $InnerParams = @{
                PiHoleServer = $PiHoleServer
                Password     = $Password
                Element      = $Element
                Value        = $Value
                IgnoreSsl    = $IgnoreSsl
                RawOutput    = $RawOutput
                Confirm      = $false
            }
            if ($PSBoundParameters.ContainsKey('Restart')) {
                $InnerParams.Restart = $Restart
            }

            $Response = Remove-PiHoleConfigArrayItem @InnerParams -ErrorAction Stop

            if ($RawOutput) {
                Write-Output $Response
            }
            else {
                $Object = [PSCustomObject]@{
                    Type        = $Type
                    Hostname    = $Hostname
                    IPv4Address = $IPv4Address
                    IPv6Address = $IPv6Address
                    Target      = $Target
                    Ttl         = $Ttl
                    Status      = $Response.Status
                }
                Write-Output $Object
            }
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }
}
