function Import-PiHoleTeleporter {
    <#
.SYNOPSIS
Import Pi-hole settings

.DESCRIPTION
Uploads a Teleporter archive (as produced by Get-PiHoleTeleporterDownload) to restore Pi-hole
from it. This overwrites your current configuration, so unlike most functions in this module it
prompts for confirmation by default - pass -Confirm:$false to skip the prompt, or -WhatIf to see
what would happen without making any change.

By default every importable item in the archive is restored. Pass one or more of the switch
parameters below to import only those specific items instead - anything not switched on is left
alone.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER FilePath
Path to the Teleporter .zip archive to upload

.PARAMETER Config
Import Pi-hole's configuration

.PARAMETER DhcpLeases
Import Pi-hole's DHCP leases

.PARAMETER Group
Import Pi-hole's groups table

.PARAMETER Adlist
Import Pi-hole's adlist table

.PARAMETER AdlistByGroup
Import Pi-hole's table relating adlist entries to groups

.PARAMETER Domainlist
Import Pi-hole's domainlist table

.PARAMETER DomainlistByGroup
Import Pi-hole's table relating domainlist entries to groups

.PARAMETER Client
Import Pi-hole's client table

.PARAMETER ClientByGroup
Import Pi-hole's table relating client entries to groups

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Import-PiHoleTeleporter -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -FilePath "C:\Backups\pihole-backup.zip"

.EXAMPLE
Import-PiHoleTeleporter -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -FilePath "C:\Backups\pihole-backup.zip" -Group -Adlist -AdlistByGroup

.EXAMPLE
Import-PiHoleTeleporter -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -FilePath "C:\Backups\pihole-backup.zip" -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/teleporter')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$FilePath,
        [switch]$Config,
        [switch]$DhcpLeases,
        [switch]$Group,
        [switch]$Adlist,
        [switch]$AdlistByGroup,
        [switch]$Domainlist,
        [switch]$DomainlistByGroup,
        [switch]$Client,
        [switch]$ClientByGroup,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        if (-not (Test-Path -Path $FilePath)) {
            throw "$FilePath does not exist!"
        }

        # Flat switches rather than Pi-hole's own nested { config, dhcp_leases, gravity: {...} }
        # shape - whether any were passed at all decides whether an "import" field is sent; if
        # none were, the field is omitted entirely so Pi-hole imports everything (its own default
        # when the field is missing), matching this function's own "import everything" default.
        $ImportSwitchNames = 'Config', 'DhcpLeases', 'Group', 'Adlist', 'AdlistByGroup', 'Domainlist', 'DomainlistByGroup', 'Client', 'ClientByGroup'
        $AnySwitchSpecified = $false
        foreach ($Name in $ImportSwitchNames) {
            if ($PSBoundParameters.ContainsKey($Name)) {
                $AnySwitchSpecified = $true
                break
            }
        }

        $Target = "Pi-Hole at $PiHoleServer"
        $Action = "Import Teleporter archive '$FilePath' (this will overwrite your current configuration)"
        if ($PSCmdlet.ShouldProcess($Target, $Action)) {
            $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

            $FormData = @{
                file = Get-Item -Path $FilePath
            }

            if ($AnySwitchSpecified) {
                $ImportBody = [ordered]@{
                    config      = [bool]$Config
                    dhcp_leases = [bool]$DhcpLeases
                    gravity     = [ordered]@{
                        group               = [bool]$Group
                        adlist              = [bool]$Adlist
                        adlist_by_group     = [bool]$AdlistByGroup
                        domainlist          = [bool]$Domainlist
                        domainlist_by_group = [bool]$DomainlistByGroup
                        client              = [bool]$Client
                        client_by_group     = [bool]$ClientByGroup
                    }
                }
                $FormData['import'] = $ImportBody | ConvertTo-Json -Depth 5 -Compress
            }

            $Params = @{
                Headers              = @{sid = $($Sid) }
                Uri                  = "$($PiHoleServer.OriginalString)/api/teleporter"
                Method               = "Post"
                SkipCertificateCheck = $IgnoreSsl
                Form                 = $FormData
            }

            $Response = Invoke-RestMethod @Params

            if ($RawOutput) {
                Write-Output $Response
            }
            else {
                # The live API returns this array under "files", despite the OpenAPI spec
                # documenting the field as "processed" - confirmed against a real server.
                $Object = [PSCustomObject]@{
                    Processed = $Response.files
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
