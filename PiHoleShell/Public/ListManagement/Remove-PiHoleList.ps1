function Remove-PiHoleList {
    <#
.SYNOPSIS
Deletes multiple lists in the lists object.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted objec

    #>
    #Work In Progress (NEED TO FINISH)
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/lists-batchDelete')]
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