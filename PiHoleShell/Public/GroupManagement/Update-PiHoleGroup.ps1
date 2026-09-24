function Update-PiHoleGroup {
    <#
.SYNOPSIS
Update a group

.DESCRIPTION
Updates a group's Comment and/or Enabled state. The underlying Pi-hole API replaces the
entire group on update, so any property you don't pass here is preserved by first reading
the group's current value and resending it - Comment and Enabled are never silently cleared
just because you only meant to change the other one.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER GroupName
The name of the group to update

.PARAMETER Comment
The new comment for the group. Leave unset to keep the group's current comment

.PARAMETER Enabled
Whether the group should be enabled. Leave unset to keep the group's current state

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Update-PiHoleGroup -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -GroupName "Kids" -Enabled $false
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Ignoring for now")]
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#put-/groups/-name-')]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$GroupName,
        [string]$Comment,
        [Nullable[bool]]$Enabled,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false

    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $GetGroupName = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -GroupName $GroupName

        if (-not $GetGroupName) {
            throw "Cannot find $GroupName on $PiHoleServer! Please use Get-PiHoleGroup to list all groups"
        }

        if (-not $PSBoundParameters.ContainsKey('Comment') -and -not $PSBoundParameters.ContainsKey('Enabled')) {
            throw "To update $GroupName, you must specify the Comment and/or Enabled parameter"
        }

        # The API replaces the whole group on update, so any property not explicitly passed
        # here is resent using the group's current value to avoid silently clearing it.
        $Body = @{
            name    = $GroupName
            comment = if ($PSBoundParameters.ContainsKey('Comment')) { $Comment } else { $GetGroupName.Comment }
            enabled = if ($PSBoundParameters.ContainsKey('Enabled')) { $Enabled } else { $GetGroupName.Enabled }
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/groups/$GroupName"
            Method               = "Put"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
            Body                 = $Body | ConvertTo-Json -Depth 10
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $ObjectFinal = foreach ($Item in $Response.groups) {
                [PSCustomObject]@{
                    Name         = $Item.name
                    Comment      = $Item.comment
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