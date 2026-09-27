function Get-PiHoleDomain {
    <#
.SYNOPSIS
Get domains

.DESCRIPTION
Request Pi-hole's per-domain allow/deny list entries (the newer domain-based API, distinct
from the Lists functions which manage whole allow/block list subscriptions). Omit all filters
to get every domain; narrow the results with -Type, -Kind, and -Domain.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Domain
Only return this domain. Requires -Type and -Kind to also be specified

.PARAMETER Type
Only return domains of this type (Allow or Deny). Required if -Kind or -Domain is specified

.PARAMETER Kind
Only return domains of this kind (Exact match or Regex). Requires -Type to also be specified

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleDomain -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"

.EXAMPLE
Get-PiHoleDomain -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Type Allow -Kind Exact -Domain "example.com"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/domains')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [string]$Domain,
        [ValidateSet("Allow", "Deny")]
        [string]$Type,
        [ValidateSet("Exact", "Regex")]
        [string]$Kind,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        if ($Kind -and -not $Type) {
            throw "-Type must be specified when -Kind is specified"
        }
        if ($Domain -and (-not $Type -or -not $Kind)) {
            throw "-Type and -Kind must both be specified when -Domain is specified"
        }

        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Groups = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Uri = "$($PiHoleServer.OriginalString)/api/domains"
        if ($Type) {
            $Uri += "/$($Type.ToLower())"
        }
        if ($Kind) {
            $Uri += "/$($Kind.ToLower())"
        }
        if ($Domain) {
            $Uri += "/$([System.Uri]::EscapeDataString($Domain))"
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = $Uri
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $ObjectFinal = foreach ($Item in $Response.domains) {
                $GroupNames = [System.Collections.ArrayList]@()
                foreach ($Group in $Item.groups) {
                    $GroupNames += ($Groups | Where-Object { $_.Id -eq $Group }).Name
                }

                [PSCustomObject]@{
                    Domain       = $Item.domain
                    Unicode      = $Item.unicode
                    Type         = $Item.type
                    Kind         = $Item.kind
                    Comment      = $Item.comment
                    Groups       = $GroupNames
                    Enabled      = $Item.enabled
                    Id           = $Item.id
                    DateAdded    = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_added).LocalTime
                    DateModified = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
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
