function Remove-PiHoleGroup {
    <#
.SYNOPSIS
Delete a group

.DESCRIPTION
Deletes a group from Pi-hole. Any lists or clients assigned to it are unassigned, not deleted.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER GroupName
The name of the group to delete

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Remove-PiHoleGroup -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -GroupName "Kids"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#delete-/groups/-name-')]
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

        $GetGroupName = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -GroupName $GroupName

        if (-not $GetGroupName) {
            throw "Cannot find $GroupName on $PiHoleServer! Please use Get-PiHoleGroup to list all groups"
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/groups/$GroupName"
            Method               = "Delete"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = [PSCustomObject]@{
                Name   = $GroupName
                Status = "Deleted"
            }
            Write-Output $Object
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