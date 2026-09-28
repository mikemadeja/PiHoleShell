function Get-PiHoleNetworkDevice {
    <#
.SYNOPSIS
Get info about the devices in your local network as seen by your Pi-hole

.DESCRIPTION
Returns the devices Pi-hole has seen on your network, ordered by most recent query first. Shown
devices default to 10; use -MaxDevices to change that.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER MaxDevices
Maximum number of devices to return. Defaults to 10

.PARAMETER MaxAddresses
Maximum number of addresses to return per device

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleNetworkDevice -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"

.EXAMPLE
Get-PiHoleNetworkDevice -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -MaxDevices 50
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/network/devices')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Nullable[int]]$MaxDevices,
        [Nullable[int]]$MaxAddresses,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $QueryParams = [System.Collections.ArrayList]@()
        if ($PSBoundParameters.ContainsKey('MaxDevices')) {
            $QueryParams.Add("max_devices=$MaxDevices") | Out-Null
        }
        if ($PSBoundParameters.ContainsKey('MaxAddresses')) {
            $QueryParams.Add("max_addresses=$MaxAddresses") | Out-Null
        }

        $Uri = "$($PiHoleServer.OriginalString)/api/network/devices"
        if ($QueryParams.Count -gt 0) {
            $Uri += "?" + ($QueryParams -join '&')
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = $Uri
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $ObjectFinal = foreach ($Item in $Response.devices) {
                $Ips = foreach ($IpItem in $Item.ips) {
                    [PSCustomObject]@{
                        Ip          = $IpItem.ip
                        Name        = $IpItem.name
                        LastSeen    = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $IpItem.lastSeen).LocalTime
                        NameUpdated = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $IpItem.nameUpdated).LocalTime
                    }
                }

                [PSCustomObject]@{
                    Id         = $Item.id
                    HwAddr     = $Item.hwaddr
                    Interface  = $Item.interface
                    FirstSeen  = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.firstSeen).LocalTime
                    LastQuery  = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.lastQuery).LocalTime
                    NumQueries = $Item.numQueries
                    MacVendor  = $Item.macVendor
                    Ips        = $Ips
                }
            }
            Write-Output $ObjectFinal
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
