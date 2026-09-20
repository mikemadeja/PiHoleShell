function Get-PiHoleCurrentAuthSession {
    <#
.SYNOPSIS
List of all current sessions including their validity and further information about the client such as the IP address and user agent.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole v6 server

.PARAMETER IgnoreSsl
Ignore SSL when interacting with the PiHole API

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleCurrentAuthSession -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/auth/sessions')]
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
            Uri                  = "$($PiHoleServer.OriginalString)/api/auth/sessions"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $ObjectFinal = foreach ($Item in $Response.sessions) {
                [PSCustomObject]@{
                    Id             = $Item.id
                    CurrentSession = $Item.current_session
                    Valid          = $Item.valid
                    TlsLogin       = $Item.tls.login
                    TlsMixed       = $Item.tls.mixed
                    LoginAt        = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.login_at).LocalTime
                    LastActive     = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.last_active).LocalTime
                    ValidUntil     = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.valid_until).LocalTime
                    RemoteAddress  = $Item.remote_addr
                    UserAgent      = $Item.user_agent
                    XForwardedFor  = $Item.x_forwarded_for
                    App            = $Item.app
                    Cli            = $Item.cli
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
