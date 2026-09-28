function Add-PiHoleConfigArrayItem {
    <#
.SYNOPSIS
Add config array item

.DESCRIPTION
Adds one item to an array-type Pi-hole configuration setting - for example, an upstream DNS
server (dns/upstreams), a local DNS record (dns/hosts), or a CNAME record (dns/cnameRecords).
Use Set-PiHoleConfig instead for non-array settings.

Requires your app password to have "app_sudo" enabled - Pi-hole blocks config changes from app
passwords by default. Enable it in your Pi-hole admin UI under Settings > All Settings by
searching for "app_sudo" and setting webserver.api.app_sudo to true.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Element
The array-type configuration setting to add to, as a slash-separated path (e.g.
"dns/upstreams", "dns/hosts", or "dns/cnameRecords")

.PARAMETER Value
The item to add. For dns/hosts this is "<ip> <hostname>"; for dns/cnameRecords this is
"<alias>,<target>[,<ttl>]"

.PARAMETER Restart
Whether to restart FTL immediately if this change requires it. Defaults to $true. Set to
$false to defer the restart, e.g. when adding several items independently rather than all at
once - you'll need to restart FTL manually later for the changes to take effect

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Add-PiHoleConfigArrayItem -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Element "dns/cnameRecords" -Value "alias.lan,target.lan"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#put-/config/-element-/-value-')]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Ignoring for now")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$Element,
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [Nullable[bool]]$Restart,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Uri = "$($PiHoleServer.OriginalString)/api/config/$($Element.Trim('/'))/$([System.Uri]::EscapeDataString($Value))"
        if ($PSBoundParameters.ContainsKey('Restart')) {
            $Uri += "?restart=$($Restart.ToString().ToLower())"
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = $Uri
            Method               = "Put"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            # A successful add returns 201 Created with no body, so there's no response to
            # build a rich object from.
            $Object = [PSCustomObject]@{
                Element = $Element
                Value   = $Value
                Status  = "Added"
            }
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
