function Set-PiHoleConfig {
    <#
.SYNOPSIS
Change configuration of your Pi-hole

.DESCRIPTION
Updates one or more Pi-hole configuration settings in a single call. -Settings takes a
hashtable shaped like the configuration tree returned by Get-PiHoleConfig - only include the
properties you want to change; everything else is left untouched. Some changes require FTL to
restart to take effect; this happens automatically unless -Restart is set to $false.

Requires your app password to have "app_sudo" enabled - Pi-hole blocks config changes from app
passwords by default. Enable it in your Pi-hole admin UI under Settings > All Settings by
searching for "app_sudo" and setting webserver.api.app_sudo to true. Some settings can never be
changed via the API at all (only in pihole.toml, or via an environment variable) - see
Get-PiHoleConfigProperty for the current list.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Settings
A hashtable of the configuration properties to change, shaped like the tree returned by
Get-PiHoleConfig (e.g. @{ dns = @{ CNAMEdeepInspect = $true } })

.PARAMETER Restart
Whether to restart FTL immediately if this change requires it. Defaults to $true. Set to
$false to defer the restart, e.g. when making several changes independently rather than all at
once - you'll need to restart FTL manually later for the changes to take effect

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Set-PiHoleConfig -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Settings @{ dns = @{ CNAMEdeepInspect = $true } }
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#patch-/config')]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Ignoring for now")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,
        [Nullable[bool]]$Restart,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Uri = "$($PiHoleServer.OriginalString)/api/config"
        if ($PSBoundParameters.ContainsKey('Restart')) {
            $Uri += "?restart=$($Restart.ToString().ToLower())"
        }

        $Body = @{
            config = $Settings
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = $Uri
            Method               = "Patch"
            SkipCertificateCheck = $IgnoreSsl
            Body                 = $Body | ConvertTo-Json -Depth 10
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = ConvertTo-PiHolePascalCaseObject -InputObject $Response.config
            Write-Output $Object
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}
