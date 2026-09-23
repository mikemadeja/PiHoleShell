function Add-PiHoleList {
    <#
.SYNOPSIS
Add a new list

.DESCRIPTION
Subscribes Pi-hole to a new allow or block list. The list is fetched and applied the next
time gravity runs (see Update-PiHoleActionsGravity).

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER Address
The URL of the list to subscribe to

.PARAMETER Type
Whether this is an Allow list or a Block list

.PARAMETER Comment
An optional comment to store alongside the list

.PARAMETER Group
The group(s) this list applies to. Defaults to "Default"

.PARAMETER Enabled
Whether the list is enabled immediately. Defaults to $true

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Add-PiHoleList -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Address "https://hosts-file.net/ad_servers.txt" -Type Block
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/lists')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [Parameter(Mandatory = $true)]
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
            groups  = [Object[]]($AllGroupsIds)
            comment = $Comment
            enabled = $Enabled
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/lists?type=$($Type.ToLower())"
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
            $ObjectFinal = @()
            foreach ($Item in $Response.lists) {
                if ($Item.date_updated -eq 0) {
                    $DateUpdated = $null
                }
                else {
                    $DateUpdated = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
                }

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
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}