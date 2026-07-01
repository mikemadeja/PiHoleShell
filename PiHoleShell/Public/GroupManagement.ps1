function Get-PiHoleGroup {
    <#
.SYNOPSIS
Get Pi-hole groups.

.DESCRIPTION
Retrieves all groups configured on the Pi-hole server. Optionally filter by group name.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER GroupName
The name of a specific group to retrieve. If not specified, all groups are returned.

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleGroup -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD"

.EXAMPLE
Get-PiHoleGroup -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD" -GroupName "Default"
    #>
    #Work In Progress
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [string]$GroupName = $null,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/groups"
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
            foreach ($Item in $Response.Groups) {
                $Object = $null
                $Object = [PSCustomObject]@{
                    Name         = $Item.name
                    Comment      = $Item.comment
                    Enabled      = $Item.enabled
                    Id           = $Item.id
                    DateAdded    = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_added).LocalTime
                    DateModified = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime

                }
                Write-Verbose -Message "Name - $($Item.name)"
                Write-Verbose -Message "Comment - $($Item.comment)"
                Write-Verbose -Message "Enabled - $($Item.enabled)"
                Write-Verbose -Message "Id - $($Item.id)"
                Write-Verbose -Message "Date Added - $($Item.date_added)"
                Write-Verbose -Message "Date Date Modified - $(($Item.date_modified))"
                $ObjectFinal += $Object
            }

            if ($GroupName) {
                $GroupNameObject = $ObjectFinal | Where-Object { $_.Name -eq $GroupName }
                if ($GroupNameObject) {
                    Write-Output $GroupNameObject
                }
                else {
                    Write-Warning "Did not find $GroupName on $PiHoleServer"
                }
            }

            else {
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

function New-PiHoleGroup {
    <#
.SYNOPSIS
Create a new Pi-hole group.

.DESCRIPTION
Creates a new group on the Pi-hole server. Returns a warning if the group already exists.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER GroupName
The name of the group to create

.PARAMETER Comment
An optional comment or description for the group

.PARAMETER Enabled
Whether the group should be enabled. Defaults to $true.

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
New-PiHoleGroup -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD" -GroupName "MyGroup"
    #>
    #Work In Progress
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Ignoring for now")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$GroupName,
        [string]$Comment = $null,
        [bool]$Enabled = $true,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false

    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $GetGroupName = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -GroupName $GroupName

        if ($GetGroupName) {
            Write-Warning -Message "Group $GroupName already exists"
        }

        else {
            $Body = @{
                comment = $Comment
                enabled = $Enabled
                name    = $GroupName
            }

            $Params = @{
                Headers              = @{sid = $($Sid) }
                Uri                  = "$($PiHoleServer.OriginalString)/api/groups"
                Method               = "Post"
                SkipCertificateCheck = $IgnoreSsl
                ContentType          = "application/json"
                Body                 = $Body | ConvertTo-Json -Depth 10
            }

            $Response = Invoke-RestMethod @Params

            if ($RawOutput) {
                Write-Output $Response
            }

            else {
                $ObjectFinal = @()
                $Object = [PSCustomObject]@{
                    Name    = $GroupName
                    Comment = $Comment
                    Enabled = $Enabled
                }
                Write-Verbose -Message "Name - $($Object.GroupName)"
                Write-Verbose -Message "Comment - $($Object.Comment)"
                Write-Verbose -Message "Enabled - $($Object.Enabled)"
                $ObjectFinal = $Object
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

function Update-PiHoleGroup {
    <#
.SYNOPSIS
Update an existing Pi-hole group.

.DESCRIPTION
Updates the comment and/or enabled state of an existing group on the Pi-hole server. At least one of Comment or Enabled must be provided.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER GroupName
The name of the group to update

.PARAMETER Comment
The new comment or description for the group

.PARAMETER Enabled
Whether the group should be enabled or disabled

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Update-PiHoleGroup -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD" -GroupName "MyGroup" -Enabled $false
    #>
    #Work In Progress
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Ignoring for now")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$GroupName,
        [string]$Comment = $null,
        [bool]$Enabled,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false

    )
    #Enabled is weird here.. look into it
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Body = @{
            name = $GroupName
        }

        $GetGroupName = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -GroupName $GroupName

        if ($Comment -eq $null -and $Enabled -eq $null) {
            Write-Warning -Message "failed"
            throw -Message "To update $GroupName, you must either use the Comment and/or Enabled parameter"
        }

        if ($Comment) {
            $Body += @{
                comment = $Comment
            }
        }
        if ($Enabled -ne $null) {
            $Body += @{
                enabled = $Enabled
            }
        }
        else {
            switch ($GetGroupStatus) {
                "True" {
                    $true
                }
                "False" {
                    $false
                }
            }

            $Body += @{
                enabled = $GetGroupStatus
            }
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/groups/$GroupName"
            Method               = "Put"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
            Body                 = $Body | ConvertTo-Json -Depth 10
        }

        if ($GetGroupName) {
            $Response = Invoke-RestMethod @Params
            if ($RawOutput) {
                Write-Output $Response
            }
            else {
                $ObjectFinal = @()
                $Object = [PSCustomObject]@{
                    Name    = $GroupName
                    Comment = $Comment
                    Enabled = $Enabled
                }
                Write-Verbose -Message "Name - $($Object.GroupName)"
                Write-Verbose -Message "Comment - $($Object.Comment)"
                Write-Verbose -Message "Enabled - $($Object.Enabled)"
                $ObjectFinal = $Object
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

function Remove-PiHoleGroup {
    <#
.SYNOPSIS
Remove a Pi-hole group.

.DESCRIPTION
Deletes an existing group from the Pi-hole server.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER GroupName
The name of the group to remove

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Remove-PiHoleGroup -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD" -GroupName "MyGroup"
    #>
    #Work In Progress
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Ignoring for now")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$GroupName,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false

    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Body = @{
            name = $GroupName
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/groups/$GroupName"
            Method               = "Delete"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
            Body                 = $Body | ConvertTo-Json -Depth 10
        }
        $GetGroupName = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -GroupName $GroupName

        if ($GetGroupName) {
            $Response = Invoke-RestMethod @Params

            if ($RawOutput) {
                Write-Output $Response
            }
            else {
                $ObjectFinal = @()
                $Object = [PSCustomObject]@{
                    Name   = $GroupName
                    Status = "Deleted"
                }
                $ObjectFinal = $Object
            }
            Write-Verbose -Message "Deleted $($Object.GroupName)"
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