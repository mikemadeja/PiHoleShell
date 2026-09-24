function New-PiHoleGroup {
    <#
.SYNOPSIS
Creates a new group

.DESCRIPTION
Creates a new group in Pi-hole's groups object. Lists and clients can be assigned to groups
to apply blocking rules selectively rather than globally.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER GroupName
The name of the group to create

.PARAMETER Comment
An optional comment to store alongside the group

.PARAMETER Enabled
Whether the group is enabled immediately. Defaults to $true

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
New-PiHoleGroup -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -GroupName "Kids"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/groups')]
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