function Get-PiHoleAuthStatus {
    <#
.SYNOPSIS
Check if authentication is required

.DESCRIPTION
Checks whether your Pi-hole requires a login for the calling client. Some Pi-hole
configurations skip authentication entirely for trusted local clients, in which case this
reports a valid session without needing a password at all. Pass -Password to instead check
the status of a real login with that password.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server. Optional - omit it to check whether
your Pi-hole requires a login at all for this client, without authenticating.

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleAuthStatus -PiHoleServer "http://pihole.domain.com:8080"

.EXAMPLE
Get-PiHoleAuthStatus -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/auth')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        if ($PSBoundParameters.ContainsKey('Password')) {
            $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl
        }

        $Params = @{
            Uri                  = "$($PiHoleServer.OriginalString)/api/auth"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }
        if ($Sid) {
            $Params.Headers = @{sid = $($Sid) }
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = [PSCustomObject]@{
                Valid    = $Response.session.valid
                Totp     = $Response.session.totp
                Sid      = $Response.session.sid
                Csrf     = $Response.session.csrf
                Validity = $Response.session.validity
                Message  = $Response.session.message
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
