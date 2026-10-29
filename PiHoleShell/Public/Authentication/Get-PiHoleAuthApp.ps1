function Get-PiHoleAuthApp {
    <#
.SYNOPSIS
Generate a new application password

.DESCRIPTION
Generates a new application password and its hash. The password is shown only once and cannot be
retrieved later, so store it somewhere safe.

This only generates the password - it does not activate it, and your current app password keeps
working. To switch to the new one, set the returned Hash as webserver.api.app_pwhash, e.g. with
Set-PiHoleConfig (see the second example). Doing so replaces your current app password and ends
all active sessions.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleAuthApp -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"

.EXAMPLE
$App = Get-PiHoleAuthApp -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
Set-PiHoleConfig -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Settings @{ webserver = @{ api = @{ app_pwhash = $App.Hash } } }

Generates a new app password and makes it the active one. From then on, use $App.Password.
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/auth/app')]
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
        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint 'auth/app'

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = [PSCustomObject]@{
                Password = $Response.app.password
                Hash     = $Response.app.hash
            }
            Write-Output $Object
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}
