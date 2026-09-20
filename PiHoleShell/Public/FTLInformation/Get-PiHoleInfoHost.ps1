function Get-PiHoleInfoHost {
    <#
.SYNOPSIS
Get information about the host system

.DESCRIPTION
Request host system information: kernel/OS details (uname), the hardware model, and DMI
(motherboard/BIOS) details where available.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoHost -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/info/host')]
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
            Uri                  = "$($PiHoleServer.OriginalString)/api/info/host"
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
                DomainName     = $Response.host.uname.domainname
                Machine        = $Response.host.uname.machine
                NodeName       = $Response.host.uname.nodename
                Release        = $Response.host.uname.release
                SysName        = $Response.host.uname.sysname
                Version        = $Response.host.uname.version
                Model          = $Response.host.model
                BiosVendor     = $Response.host.dmi.bios.vendor
                BoardName      = $Response.host.dmi.board.name
                BoardVendor    = $Response.host.dmi.board.vendor
                BoardVersion   = $Response.host.dmi.board.version
                ProductName    = $Response.host.dmi.product.name
                ProductFamily  = $Response.host.dmi.product.family
                ProductVersion = $Response.host.dmi.product.version
                SysVendor      = $Response.host.dmi.sys.vendor
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
