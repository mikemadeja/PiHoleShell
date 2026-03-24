function Get-PiHoleGroup {
    <#
.SYNOPSIS
Get groups

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
        break
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}