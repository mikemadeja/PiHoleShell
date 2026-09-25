function Update-PiHoleList {
    <#
.SYNOPSIS
Update a list

.DESCRIPTION
Updates an existing list's Comment, Group(s), and/or Enabled state. The underlying Pi-hole API
replaces the entire list on update, so any property you don't pass here is preserved by first
reading the list's current value and resending it - nothing is silently cleared just because
you only meant to change one property.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Address
The URL of the list to update

.PARAMETER Type
Whether this is an Allow list or a Block list

.PARAMETER Comment
The new comment for the list. Leave unset to keep the list's current comment

.PARAMETER Group
The group(s) this list should apply to. Leave unset to keep the list's current group(s)

.PARAMETER Enabled
Whether the list should be enabled. Leave unset to keep the list's current state

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Update-PiHoleList -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Address "https://hosts-file.net/ad_servers.txt" -Type Block -Enabled $false
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#put-/lists/-list-')]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Ignoring for now")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [System.Uri]$Address,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Allow", "Block")]
        [string]$Type,
        [string]$Comment,
        [string[]]$Group,
        [Nullable[bool]]$Enabled,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        if (-not $PSBoundParameters.ContainsKey('Comment') -and -not $PSBoundParameters.ContainsKey('Group') -and -not $PSBoundParameters.ContainsKey('Enabled')) {
            throw "To update $Address, you must specify the Comment, Group, and/or Enabled parameter"
        }

        $ExistingList = Get-PiHoleList -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -List $Address | Where-Object { $_.Type -eq $Type }

        if (-not $ExistingList) {
            throw "Cannot find $Address of type $Type on $PiHoleServer! Please use Add-PiHoleList to create it"
        }

        $AllGroups = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $GroupNamesToResolve = if ($PSBoundParameters.ContainsKey('Group')) { $Group } else { $ExistingList.Groups }

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

        # The API replaces the whole list on update, so any property not explicitly passed here
        # is resent using the list's current value to avoid silently clearing it.
        $Body = @{
            comment = if ($PSBoundParameters.ContainsKey('Comment')) { $Comment } else { $ExistingList.Comment }
            groups  = [Object[]]($AllGroupsIds)
            enabled = if ($PSBoundParameters.ContainsKey('Enabled')) { $Enabled } else { $ExistingList.Enabled }
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/lists/$Address`?type=$($Type.ToLower())"
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
            $ObjectFinal = foreach ($Item in $Response.lists) {
                if ($Item.date_updated -eq 0) {
                    $DateUpdated = $null
                }
                else {
                    $DateUpdated = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
                }

                [PSCustomObject]@{
                    Address        = $Item.address
                    Comment        = $Item.comment
                    Groups         = $AllGroupsNames
                    Enabled        = $Item.enabled
                    Id             = $Item.id
                    DateAdded      = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_added).LocalTime
                    DateModified   = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
                    Type           = $Item.type.SubString(0, 1).ToUpper() + $Item.type.SubString(1).ToLower()
                    DateUpdated    = $DateUpdated
                    Number         = $Item.number
                    InvalidDomains = $Item.invalid_domains
                    AbpEntries     = $Item.abp_entries
                    Status         = $Item.status
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
