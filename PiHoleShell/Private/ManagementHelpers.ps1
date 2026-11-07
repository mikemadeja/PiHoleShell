function Resolve-PiHoleGroupName {
    #INTERNAL FUNCTION
    #
    # Maps group names to the group IDs the client/domain/list APIs expect, throwing on the first
    # name that doesn't exist. AllGroups is the caller's Get-PiHoleGroup result, so a function
    # resolving groups only fetches them once.
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        $AllGroups,
        $Name
    )

    $Names = @()
    $Ids = @()
    foreach ($GroupItem in $Name) {
        $FoundGroup = $AllGroups | Where-Object { $_.Name -eq $GroupItem }
        if ($FoundGroup) {
            $Names += $FoundGroup.Name
            $Ids += $FoundGroup.Id
            Write-Verbose -Message "Found Group $($FoundGroup.Name) with $($FoundGroup.Id)"
        }
        else {
            throw "Cannot find $GroupItem on $PiHoleServer! Please use Get-PiHoleGroup to list all groups"
        }
    }

    [PSCustomObject]@{
        Names = $Names
        Ids   = $Ids
    }
}

function ConvertTo-PiHoleClientObject {
    #INTERNAL FUNCTION
    #
    # Formats the clients in a New-/Update-PiHoleClient response. Groups is passed in rather than
    # read from the response, which only has group IDs.
    param (
        $Client,
        $Groups
    )

    foreach ($Item in $Client) {
        [PSCustomObject]@{
            Client       = $Item.client
            Name         = $Item.name
            Comment      = $Item.comment
            Groups       = $Groups
            Id           = $Item.id
            DateAdded    = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_added).LocalTime
            DateModified = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
        }
    }
}

function ConvertTo-PiHoleDomainObject {
    #INTERNAL FUNCTION
    #
    # Formats the domains in a New-/Update-PiHoleDomain response. Groups is passed in rather than
    # read from the response, which only has group IDs.
    param (
        $Domain,
        $Groups
    )

    foreach ($Item in $Domain) {
        [PSCustomObject]@{
            Domain       = $Item.domain
            Unicode      = $Item.unicode
            Type         = $Item.type.SubString(0, 1).ToUpper() + $Item.type.SubString(1).ToLower()
            Kind         = $Item.kind.SubString(0, 1).ToUpper() + $Item.kind.SubString(1).ToLower()
            Comment      = $Item.comment
            Groups       = $Groups
            Enabled      = $Item.enabled
            Id           = $Item.id
            DateAdded    = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_added).LocalTime
            DateModified = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
        }
    }
}

function ConvertTo-PiHoleGroupObject {
    #INTERNAL FUNCTION
    #
    # Formats the groups in a New-/Update-PiHoleGroup response.
    param (
        $Group
    )

    foreach ($Item in $Group) {
        [PSCustomObject]@{
            Name         = $Item.name
            Comment      = $Item.comment
            Enabled      = $Item.enabled
            Id           = $Item.id
            DateAdded    = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_added).LocalTime
            DateModified = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
        }
    }
}
