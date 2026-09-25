function Get-PiHoleInfoFtl {
    <#
.SYNOPSIS
Get info about various FTL parameters

.DESCRIPTION
Request a collection of FTL process information: gravity database counts, privacy level,
query frequency, client counts, process ID/uptime/resource usage, whether destructive actions
are allowed, and metrics from the embedded dnsmasq resolver.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoFtl -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/info/ftl')]
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
            Uri                  = "$($PiHoleServer.OriginalString)/api/info/ftl"
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
                Database         = [PSCustomObject]@{
                    Gravity     = $Response.ftl.database.gravity
                    Antigravity = $Response.ftl.database.antigravity
                    Groups      = $Response.ftl.database.groups
                    Lists       = $Response.ftl.database.lists
                    Clients     = $Response.ftl.database.clients
                    Domains     = [PSCustomObject]@{
                        Allowed = [PSCustomObject]@{
                            Total   = $Response.ftl.database.domains.allowed.total
                            Enabled = $Response.ftl.database.domains.allowed.enabled
                        }
                        Denied  = [PSCustomObject]@{
                            Total   = $Response.ftl.database.domains.denied.total
                            Enabled = $Response.ftl.database.domains.denied.enabled
                        }
                    }
                    Regex       = [PSCustomObject]@{
                        Allowed = [PSCustomObject]@{
                            Total   = $Response.ftl.database.regex.allowed.total
                            Enabled = $Response.ftl.database.regex.allowed.enabled
                        }
                        Denied  = [PSCustomObject]@{
                            Total   = $Response.ftl.database.regex.denied.total
                            Enabled = $Response.ftl.database.regex.denied.enabled
                        }
                    }
                }
                PrivacyLevel     = $Response.ftl.privacy_level
                QueryFrequency   = $Response.ftl.query_frequency
                Clients          = [PSCustomObject]@{
                    Total  = $Response.ftl.clients.total
                    Active = $Response.ftl.clients.active
                }
                Pid              = $Response.ftl.pid
                Uptime           = $Response.ftl.uptime
                PercentMemory    = $Response.ftl.'%mem'
                PercentCpu       = $Response.ftl.'%cpu'
                AllowDestructive = $Response.ftl.allow_destructive
                Dnsmasq          = ConvertTo-PiHolePascalCaseObject -InputObject $Response.ftl.dnsmasq
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
