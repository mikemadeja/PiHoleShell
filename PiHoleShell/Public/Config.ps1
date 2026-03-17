function Get-PiHoleConfig {
    <#
.SYNOPSIS
https://TODO

    #>
    #Work In Progress
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
            Uri                  = "$($PiHoleServer.OriginalString)/api/config"
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
            $Dns = [PSCustomObject]@{
                Upstreams = $Response.config.dns.upstreams
            }

            $Dhcp = [PSCustomObject]@{
                Active               = $Response.config.dhcp.active
                Start                = $Response.config.dhcp.start
                End                  = $Response.config.dhcp.end
                Hosts                = $Response.config.dhcp.hosts
                IgnoreUnknownClients = $Response.config.dhcp.ignoreUnknownClients
                Ipv6                 = $Response.config.dhcp.ipv6
                LeaseTime            = $Response.config.dhcp.leaseTime
                Logging              = $Response.config.dhcp.logging
                MultiDNS             = $Response.config.dhcp.multiDNS
                Netmask              = $Response.config.dhcp.netmask
                RapidCommit          = $Response.config.dhcp.rapidCommit
                Router               = $Response.config.dhcp.router
            }

            $Object = [PSCustomObject]@{
                Dns  = $Dns
                Dhcp = $Dhcp
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