function Get-PiHoleClientSuggestion {
    <#
.SYNOPSIS
Get client suggestions

.DESCRIPTION
Returns a list of clients Pi-hole has seen making DNS queries but that aren't yet configured as
a client (see New-PiHoleClient to add one).

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleClientSuggestion -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/clients/_suggestions')]
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
        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint 'clients/_suggestions'

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $ObjectFinal = foreach ($Item in $Response.clients) {
                [PSCustomObject]@{
                    HwAddr    = $Item.hwaddr
                    MacVendor = $Item.macVendor
                    LastQuery = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.lastQuery).LocalTime
                    Addresses = $Item.addresses
                    Names     = $Item.names
                }
            }
            Write-Output $ObjectFinal
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}
