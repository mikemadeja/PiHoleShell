function Get-PiHoleList {
    <#
.SYNOPSIS
Get Pi-hole allow/block lists.

.DESCRIPTION
Retrieves all lists configured on the Pi-hole server. Optionally filter by list address.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER List
The URL of a specific list to retrieve. If not specified, all lists are returned.

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleList -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD"
    #>
    #Work In Progress
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [System.URI]$List = $null,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Groups = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/lists/$List"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $ObjectFinal = @()
            foreach ($Item in $Response.lists) {
                $GroupNames = [System.Collections.ArrayList]@()
                foreach ($Group in $Item.groups) {
                    $GroupNames += ($Groups | Where-Object { $_.Id -eq $Group }).Name
                }

                $Object = $null
                if ($Item.date_updated -eq 0) {
                    $DateUpdated = $null
                }
                else {
                    $DateUpdated = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
                }
                $Object = [PSCustomObject]@{
                    Address        = $Item.address
                    Comment        = $Item.comment
                    Groups         = $GroupNames
                    Enabled        = $Item.enabled
                    Id             = $Item.id
                    DateAdded      = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_added).LocalTime
                    DateModified   = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
                    Type           = $Item.type
                    DateUpdated    = $DateUpdated
                    Number         = $Item.number
                    InvalidDomains = $Item.invalid_domains
                    AbpEntries     = $Item.abp_entries
                    Status         = $Item.status
                }
                if ($Object) {
                    $ObjectFinal += $Object
                }

            }
            Write-Output $ObjectFinal
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
        break
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}

function Search-PiHoleListDomain {
    <#
.SYNOPSIS
Search for a domain in Pi-hole lists.

.DESCRIPTION
Searches Pi-hole allow/block lists for a given domain name.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Domain
The domain name to search for

.PARAMETER PartialMatch
Set to $true to allow partial matches. Defaults to $false (exact match only).

.PARAMETER MaxResults
The maximum number of results to return. Defaults to 20.

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Search-PiHoleListDomain -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD" -Domain "ads.example.com"
    #>
    #Work In Progress
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [System.URI]$Domain,
        [bool]$PartialMatch = $false,
        [int]$MaxResults = 20,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Body = @{
            n       = $MaxResults
            partial = $PartialMatch
            name    = $GroupName
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/search/$Domain"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            Body                 = $Body
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $ObjectFinal = @()
            foreach ($Item in $Response.lists) {
            }
            Write-Output $ObjectFinal
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
        break
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}

function Add-PiHoleList {
    <#
.SYNOPSIS
Add a new allow or block list to Pi-hole.

.DESCRIPTION
Adds a new list URL to the Pi-hole server. Throws if the list already exists.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER Address
The URL of the list to add

.PARAMETER Type
Whether to add the list as an "Allow" or "Block" list

.PARAMETER Comment
An optional comment or description for the list

.PARAMETER Group
One or more group names to associate the list with. Defaults to "Default".

.PARAMETER Enabled
Whether the list should be enabled. Defaults to $true.

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Add-PiHoleList -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD" -Address "https://someblocklistprovider.example/list.txt" -Type "Block"
    #>
    #Work In Progress
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [System.Uri]$Address,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Allow", "Block")]
        [string]$Type,
        [string]$Comment = $null,
        [string[]]$Group = "Default",
        [bool]$Enabled = $true,
        [bool]$RawOutput = $false
    )
    try {
        $FindMatchingList = Get-PiHoleList -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl | Where-Object { $_.Address -eq $Address }

        if ($FindMatchingList) {
            throw "List $Address already exists on $PiHoleServer! Please use Update-PiHoleList to update the list"
        }

        $AllGroups = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl
        $AllGroupsNames = @()
        $AllGroupsIds = @()
        foreach ($GroupItem in $Group) {

            $FoundGroup = $AllGroups | Where-Object { $_.Name -eq $GroupItem }
            if ($FoundGroup) {
                $AllGroupsNames += $FoundGroup.Name
                $AllGroupsIds += $FoundGroup.Id
                Write-Verbose -Message "Found Group $($FoundGroup.Name) with $($FoundGroup.Id)"
            }
            else {
                throw "Cannot find $GroupItem on $PiHoleServer! Please use Get-PiHoleGroup to list all groups"
            }
        }

        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Body = @{
            address = $Address
            type    = $Type
            groups  = [Object[]]($AllGroupsIds)
            comment = $Comment
            enabled = $Enabled
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/lists"
            Method               = "Post"
            SkipCertificateCheck = $IgnoreSsl
            Body                 = $Body | ConvertTo-Json -Depth 10
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($Item.date_updated -eq 0) {
            $DateUpdated = $null
        }
        else {
            $DateUpdated = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
        }

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $ObjectFinal = @()
            $Object = $null
            foreach ($Item in $Response.lists) {

                $Object = [PSCustomObject]@{
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
                if ($Object) {
                    $ObjectFinal += $Object
                }

            }
            Write-Output $ObjectFinal
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
        break
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}

function Remove-PiHoleList {
    <#
.SYNOPSIS
Remove a list from Pi-hole.

.DESCRIPTION
Removes an allow or block list from the Pi-hole server by address and type.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER Address
The URL of the list to remove

.PARAMETER Type
The type of list to remove ("Allow" or "Block")

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Remove-PiHoleList -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD" -Address "https://someblocklistprovider.example/list.txt" -Type "Block"
    #>
    #Work In Progress (NEED TO FINISH)
    [CmdletBinding(SupportsShouldProcess = $true)]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [System.Uri]$Address,
        [string]$Type,
        [bool]$RawOutput = $false
    )
    try {
        $Target = "Pi-Hole list $Address of type $Type"
        if ($PSCmdlet.ShouldProcess($Target, "Remove list")) {
            $FindMatchingList = Get-PiHoleList -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl | Where-Object { $_.Address -eq $Address }

            if ($FindMatchingList) {

            }

            $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

            $Body = @(
                @{
                    item = $Address
                    type = $Type.ToLower()
                }
            )

            #For some reason this needs to be here to make it an array
            $Body = , $Body
            $Params = @{
                Headers              = @{sid = $($Sid) }
                Uri                  = "$($PiHoleServer.OriginalString)/api/lists:batchDelete"
                Method               = "Post"
                SkipCertificateCheck = $IgnoreSsl
                Body                 = $Body | ConvertTo-Json -Depth 10 -Compress
                ContentType          = "application/json"
            }

            $Response = Invoke-RestMethod @Params

            if ($RawOutput) {
                Write-Output $Response
            }

            else {
                $ObjectFinal = @()
                $Object = $null
                foreach ($Item in $Response.lists) {

                    $Object = [PSCustomObject]@{
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
                    if ($Object) {
                        $ObjectFinal += $Object
                    }

                }
                Write-Output $ObjectFinal
            }

        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
        break
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}