function New-PiHoleDomain {
    <#
.SYNOPSIS
Add a new domain

.DESCRIPTION
Adds a domain to Pi-hole's per-domain allow/deny list (the newer domain-based API, distinct
from the Lists functions which manage whole allow/block list subscriptions). Use -Kind Regex
to add a regular expression instead of an exact domain match.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Domain
The domain (or regular expression, if -Kind is Regex) to add

.PARAMETER Type
Whether this is an allowed or denied domain

.PARAMETER Kind
Whether -Domain is an exact match or a regular expression

.PARAMETER Comment
An optional comment to store alongside the domain

.PARAMETER Group
The group(s) this domain applies to. Defaults to "Default"

.PARAMETER Enabled
Whether the domain is enabled immediately. Defaults to $true

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
New-PiHoleDomain -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Domain "example.com" -Type Allow -Kind Exact
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/domains/-type-/-kind-')]
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
        [string]$Comment = $null,
        [string[]]$Group = "Default",
        [bool]$Enabled = $true,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $FindMatchingDomain = Get-PiHoleDomain -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Type $Type -Kind $Kind -Domain $Domain

        if ($FindMatchingDomain) {
            throw "Domain $Domain ($Type/$Kind) already exists on $PiHoleServer! Please use Update-PiHoleDomain to update it"
        }

        $AllGroups = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl
        $AllGroupsNames = @()
        $AllGroupsIds = @()
        foreach ($GroupItem in $Group) {
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

        $Body = @{
            domain  = $Domain
            comment = $Comment
            groups  = [Object[]]($AllGroupsIds)
            enabled = $Enabled
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/domains/$($Type.ToLower())/$($Kind.ToLower())"
            Method               = "Post"
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
