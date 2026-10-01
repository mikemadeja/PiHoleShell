function Remove-PiHoleDhcpLease {
    <#
.SYNOPSIS
Remove a DHCP lease

.DESCRIPTION
Removes a currently active DHCP lease. Managing DHCP leases is only possible when the DHCP
server is enabled.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Ip
The IP address of the lease to remove, as shown by Get-PiHoleDhcpLease

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Remove-PiHoleDhcpLease -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Ip "192.168.1.50"
    #>
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://ftl.pi-hole.net/master/docs/#delete-/dhcp/leases/-ip-')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$Ip,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Target = "Pi-Hole DHCP lease $Ip"
        if ($PSCmdlet.ShouldProcess($Target, "Remove DHCP lease")) {
            $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

            $Params = @{
                Headers              = @{sid = $($Sid) }
                Uri                  = "$($PiHoleServer.OriginalString)/api/dhcp/leases/$Ip"
                Method               = "Delete"
                SkipCertificateCheck = $IgnoreSsl
                ContentType          = "application/json"
            }

            $Response = Invoke-RestMethod @Params

            if ($RawOutput) {
                Write-Output $Response
            }

            else {
                # A successful delete returns 204 No Content, so there's no response body to
                # build a rich object from.
                $Object = [PSCustomObject]@{
                    Ip     = $Ip
                    Status = "Removed"
                }
                Write-Output $Object
            }
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
