function Update-PiHoleDomain {
    <#
.SYNOPSIS
Update a domain

.DESCRIPTION
Updates an existing domain's Comment, Group(s), and/or Enabled state. The underlying Pi-hole
API replaces the entire domain entry on update, so any property you don't pass here is
preserved by first reading the domain's current value and resending it - nothing is silently
cleared just because you only meant to change one property.

Note: the Pi-hole API documents moving a domain to a different -Type/-Kind by including those
fields in this same PUT request, but real-world testing against a live server showed this
leaves a stale duplicate at the original type/kind rather than actually moving it. This
function only ever updates Comment, Group, and Enabled in place; to change a domain's Type or
Kind, remove it with Remove-PiHoleDomain and add it again with New-PiHoleDomain.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Domain
The domain to update

.PARAMETER Type
Whether this is an allowed or denied domain

.PARAMETER Kind
Whether -Domain is an exact match or a regular expression

.PARAMETER Comment
The new comment for the domain. Leave unset to keep the domain's current comment

.PARAMETER Group
The group(s) this domain should apply to. Leave unset to keep the domain's current group(s)

.PARAMETER Enabled
Whether the domain should be enabled. Leave unset to keep the domain's current state

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Update-PiHoleDomain -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Domain "example.com" -Type Allow -Kind Exact -Enabled $false
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#put-/domains/-type-/-kind-/-domain-')]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Ignoring for now")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$Domain,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Allow", "Deny")]
        [string]$Type,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Exact", "Regex")]
        [string]$Kind,
        [string]$Comment,
        [string[]]$Group,
        [Nullable[bool]]$Enabled,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        if (-not $PSBoundParameters.ContainsKey('Comment') -and -not $PSBoundParameters.ContainsKey('Group') -and -not $PSBoundParameters.ContainsKey('Enabled')) {
            throw "To update $Domain, you must specify the Comment, Group, and/or Enabled parameter"
        }

        $ExistingDomain = Get-PiHoleDomain -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Type $Type -Kind $Kind -Domain $Domain

        if (-not $ExistingDomain) {
            throw "Cannot find $Domain of type $Type/$Kind on $PiHoleServer! Please use New-PiHoleDomain to create it"
        }

        $AllGroups = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $GroupNamesToResolve = if ($PSBoundParameters.ContainsKey('Group')) { $Group } else { $ExistingDomain.Groups }

        $AllGroupsNames = @()
        $AllGroupsIds = @()
        foreach ($GroupItem in $GroupNamesToResolve) {
            $FoundGroup = $AllGroups | Where-Object { $_.Name -eq $GroupItem }
            if ($FoundGroup) {
                $AllGroupsNames += $FoundGroup.Name
                $AllGroupsIds += $FoundGroup.Id
            }
            else {
                throw "Cannot find $GroupItem on $PiHoleServer! Please use Get-PiHoleGroup to list all groups"
            }
        }

        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        # The API replaces the whole domain entry on update, so any property not explicitly
        # passed here is resent using the domain's current value to avoid silently clearing it.
        # Type/Kind are always resent as-is - see the .DESCRIPTION note on why this never moves
        # a domain to a different Type/Kind.
        $Body = @{
            type    = $Type.ToLower()
            kind    = $Kind.ToLower()
            comment = if ($PSBoundParameters.ContainsKey('Comment')) { $Comment } else { $ExistingDomain.Comment }
            groups  = [Object[]]($AllGroupsIds)
            enabled = if ($PSBoundParameters.ContainsKey('Enabled')) { $Enabled } else { $ExistingDomain.Enabled }
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/domains/$($Type.ToLower())/$($Kind.ToLower())/$([System.Uri]::EscapeDataString($Domain))"
            Method               = "Put"
            SkipCertificateCheck = $IgnoreSsl
            Body                 = $Body | ConvertTo-Json -Depth 10
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $ObjectFinal = foreach ($Item in $Response.domains) {
                [PSCustomObject]@{
                    Domain       = $Item.domain
                    Unicode      = $Item.unicode
                    Type         = $Item.type.SubString(0, 1).ToUpper() + $Item.type.SubString(1).ToLower()
                    Kind         = $Item.kind.SubString(0, 1).ToUpper() + $Item.kind.SubString(1).ToLower()
                    Comment      = $Item.comment
                    Groups       = $AllGroupsNames
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
