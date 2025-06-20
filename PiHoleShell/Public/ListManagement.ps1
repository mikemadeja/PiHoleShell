function Get-PiHoleList {
    <#
.SYNOPSIS
https://TODO

    #>
    #Work In Progress
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [System.URI]$List = $null,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl
        $Groups = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/lists/$List"
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
            foreach ($Item in $Response.lists) {
                $GroupNames = [System.Collections.ArrayList]@()
                foreach ($Group in $Item.Groups) {
                    $GroupNames += ($Groups | Where-Object { $_.Id -eq $Group }).Name
                }
  
                $Object = $null
                if ($Item.date_updated -eq 0) {
                    $DateUpdated = $null
                }
                else {
                    $DateUpdated = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
                } 
                $Object = [PSCustomObject]@{
                    Address        = $Item.address
                    Comment        = $Item.comment
                    Groups         = $GroupNames
                    Enabled        = $Item.enabled
                    Id             = $Item.id
                    DateAdded      = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_added).LocalTime
                    DateModified   = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
                    Type           = $Item.type
                    DateUpdated    = $DateUpdated
                    Number         = $Item.number
                    InvalidDomains = $Item.invalid_domains
                    AbpEntries     = $Item.abp_entries
                    Status         = $Item.status
                }
                
                $ObjectFinal += $Object
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