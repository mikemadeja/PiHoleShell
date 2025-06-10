function Get-PiHoleGroup {
    <#
.SYNOPSIS
https://TODO

    #>
    #Work In Progress
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        $PiHoleServer,
        [Parameter(Mandatory = $true)]
        $Password,
        $GroupName = $null,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$PiHoleServer/api/groups"
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
                Write-Verbose -Message "Name - $($Item.groups.name)"
                Write-Verbose -Message "Comment - $($Item.groups.comment)"
                Write-Verbose -Message "Enabled - $($Item.groups.enabled)"
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
https://TODO

    #>
    #Work In Progress
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PiHoleServer,
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
                Uri                  = "$PiHoleServer/api/groups"
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
https://TODO

    #>
    #Work In Progress
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PiHoleServer,
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
            Uri                  = "$PiHoleServer/api/groups/$GroupName"
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
https://TODO

    #>
    #Work In Progress
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PiHoleServer,
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
            Uri                  = "$PiHoleServer/api/groups/$GroupName"
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

Export-ModuleMember -Function Get-PiHoleGroup, New-PiHoleGroup, Update-PiHoleGroup, Remove-PiHoleGroup