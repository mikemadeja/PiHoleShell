function Get-PiHoleInfoVersion {
    <#
.SYNOPSIS
Get Pi-hole version

.DESCRIPTION
Request the local and remote (latest available) versions of each Pi-hole component: Core,
Web, FTL, and the Docker image (if running in Docker).

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoVersion -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/info/version')]
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
            Uri                  = "$($PiHoleServer.OriginalString)/api/info/version"
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
                Core   = [PSCustomObject]@{
                    Local  = [PSCustomObject]@{
                        Branch  = $Response.version.core.local.branch
                        Version = $Response.version.core.local.version
                        Hash    = $Response.version.core.local.hash
                    }
                    Remote = [PSCustomObject]@{
                        Version = $Response.version.core.remote.version
                        Hash    = $Response.version.core.remote.hash
                    }
                }
                Web    = [PSCustomObject]@{
                    Local  = [PSCustomObject]@{
                        Branch  = $Response.version.web.local.branch
                        Version = $Response.version.web.local.version
                        Hash    = $Response.version.web.local.hash
                    }
                    Remote = [PSCustomObject]@{
                        Version = $Response.version.web.remote.version
                        Hash    = $Response.version.web.remote.hash
                    }
                }
                Ftl    = [PSCustomObject]@{
                    Local  = [PSCustomObject]@{
                        Branch  = $Response.version.ftl.local.branch
                        Version = $Response.version.ftl.local.version
                        Hash    = $Response.version.ftl.local.hash
                        Date    = $Response.version.ftl.local.date
                    }
                    Remote = [PSCustomObject]@{
                        Version = $Response.version.ftl.remote.version
                        Hash    = $Response.version.ftl.remote.hash
                    }
                }
                Docker = [PSCustomObject]@{
                    Local  = $Response.version.docker.local
                    Remote = $Response.version.docker.remote
                }
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
