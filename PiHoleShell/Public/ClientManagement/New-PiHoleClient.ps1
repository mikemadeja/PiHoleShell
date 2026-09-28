function New-PiHoleClient {
    <#
.SYNOPSIS
Add a new client

.DESCRIPTION
Adds a client to Pi-hole so group-based rules can be applied to it specifically. A client may
be identified by IP address, IP subnet (CIDR notation), MAC address, hostname, or the interface
it connects through (prefixed with a colon, e.g. ":eth0"). IP-based recognition is preferred -
MAC address, hostname, and interface recognition only work for devices Pi-hole has already seen.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Client
The client to add - an IP address, IP subnet (CIDR), MAC address, hostname, or interface
(prefixed with a colon, e.g. ":eth0")

.PARAMETER Comment
An optional comment to store alongside the client

.PARAMETER Group
The group(s) this client applies to. Defaults to "Default"

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
New-PiHoleClient -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Client "192.168.1.50" -Comment "Kid's tablet"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/clients')]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Ignoring for now")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$Client,
        [string]$Comment = $null,
        [string[]]$Group = "Default",
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $FindMatchingClient = Get-PiHoleClient -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Client $Client

        if ($FindMatchingClient) {
            throw "Client $Client already exists on $PiHoleServer! Please use Update-PiHoleClient to update it"
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
            client  = $Client
            comment = $Comment
            groups  = [Object[]]($AllGroupsIds)
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/clients"
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
