function Add-PiHoleDnsRecord {
    <#
.SYNOPSIS
Add a local DNS record

.DESCRIPTION
Adds a local DNS record to Pi-hole: an A record (IPv4), AAAA record (IPv6), or CNAME record.
This is a DNS-specific convenience wrapper around Add-PiHoleConfigArrayItem, which it calls
internally - using that directly is equivalent, just less discoverable for this specific case.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Type
The kind of record to add: A (IPv4), AAAA (IPv6), or CNAME

.PARAMETER Hostname
The hostname to add. For -Type A or AAAA, this is the name that resolves to the given address.
For -Type CNAME, this is the alias being created

.PARAMETER IPv4Address
The IPv4 address -Hostname should resolve to. Required when -Type is "A"

.PARAMETER IPv6Address
The IPv6 address -Hostname should resolve to. Required when -Type is "AAAA"

.PARAMETER Target
The hostname -Hostname should be an alias for. Required when -Type is "CNAME"

.PARAMETER Ttl
Optional TTL (in seconds) for a CNAME record. Only used when -Type is "CNAME"

.PARAMETER Restart
Whether to restart FTL immediately if this change requires it. Defaults to $true. Set to
$false to defer the restart, e.g. when adding several records independently rather than all at
once - you'll need to restart FTL manually later for the changes to take effect

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Add-PiHoleDnsRecord -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Type A -Hostname "test.local" -IPv4Address "192.168.1.1"

.EXAMPLE
Add-PiHoleDnsRecord -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Type AAAA -Hostname "test.local" -IPv6Address "::1"

.EXAMPLE
Add-PiHoleDnsRecord -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Type CNAME -Hostname "alias.local" -Target "test.local" -Ttl 300
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#put-/config/-element-/-value-')]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Thin wrapper - Add-PiHoleConfigArrayItem (called internally) already carries this same suppression")]
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
                $ParsedAddress = $null
                if (-not [System.Net.IPAddress]::TryParse($IPv4Address, [ref]$ParsedAddress) -or $ParsedAddress.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
                    throw "'$IPv4Address' is not a valid IPv4 address"
                }
                $Element = 'dns/hosts'
                $Value = "$IPv4Address $Hostname"
            }
            'AAAA' {
                if (-not $IPv6Address) {
                    throw "-IPv6Address is required when -Type is 'AAAA'"
                }
                $ParsedAddress = $null
                if (-not [System.Net.IPAddress]::TryParse($IPv6Address, [ref]$ParsedAddress) -or $ParsedAddress.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
                    throw "'$IPv6Address' is not a valid IPv6 address"
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

        $InnerParams = @{
            PiHoleServer = $PiHoleServer
            Password     = $Password
            Element      = $Element
            Value        = $Value
            IgnoreSsl    = $IgnoreSsl
            RawOutput    = $RawOutput
        }
        if ($PSBoundParameters.ContainsKey('Restart')) {
            $InnerParams.Restart = $Restart
        }

        $Response = Add-PiHoleConfigArrayItem @InnerParams -ErrorAction Stop

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

    catch {
        Write-Error -Message $_.Exception.Message
    }
}
