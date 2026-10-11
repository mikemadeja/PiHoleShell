function Get-PiHoleGroup {
    <#
.SYNOPSIS
Get groups

.DESCRIPTION
Returns all groups configured on your Pi-hole. Lists and clients can be assigned to groups to
apply blocking rules selectively rather than globally.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER GroupName
The name of a specific group to return. If omitted, every group is returned

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleGroup -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"

.EXAMPLE
Get-PiHoleGroup -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -GroupName "Kids"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/groups/-name-')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
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
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}