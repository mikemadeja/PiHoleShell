function Update-PiHoleClient {
    <#
.SYNOPSIS
Update a client

.DESCRIPTION
Updates an existing client's Comment and/or Group(s). The underlying Pi-hole API replaces the
entire client entry on update, so any property you don't pass here is preserved by first
reading the client's current value and resending it - nothing is silently cleared just because
you only meant to change one property.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Client
The client to update - an IP address, IP subnet (CIDR), MAC address, hostname, or interface
(prefixed with a colon, e.g. ":eth0")

.PARAMETER Comment
The new comment for the client. Leave unset to keep the client's current comment

.PARAMETER Group
The group(s) this client should apply to. Leave unset to keep the client's current group(s)

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Update-PiHoleClient -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Client "192.168.1.50" -Comment "Kid's tablet"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#put-/clients/-client-')]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Ignoring for now")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$Client,
        [string]$Comment,
        [string[]]$Group,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        if (-not $PSBoundParameters.ContainsKey('Comment') -and -not $PSBoundParameters.ContainsKey('Group')) {
            throw "To update $Client, you must specify the Comment and/or Group parameter"
        }

        $ExistingClient = Get-PiHoleClient -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Client $Client

        if (-not $ExistingClient) {
            throw "Cannot find $Client on $PiHoleServer! Please use New-PiHoleClient to create it"
        }

        $AllGroups = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $GroupNamesToResolve = if ($PSBoundParameters.ContainsKey('Group')) { $Group } else { $ExistingClient.Groups }

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

        # The API replaces the whole client entry on update, so any property not explicitly
        # passed here is resent using the client's current value to avoid silently clearing it.
        $Body = @{
            comment = if ($PSBoundParameters.ContainsKey('Comment')) { $Comment } else { $ExistingClient.Comment }
            groups  = [Object[]]($AllGroupsIds)
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/clients/$([System.Uri]::EscapeDataString($Client))"
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
            $ObjectFinal = foreach ($Item in $Response.clients) {
                [PSCustomObject]@{
                    Client       = $Item.client
                    Name         = $Item.name
                    Comment      = $Item.comment
                    Groups       = $AllGroupsNames
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
