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
                $Object = [PSCustomObject]@{
                    Address         = $Item.address
                    comment         = $Item.comment
                    Groups          = $GroupNames
                    Enabled         = $Item.enabled
                    Id              = $Item.id
                    date_added      = $Item.date_added
                    date_modified   = $Item.date_modified
                    type            = $Item.type
                    date_updated    = $Item.date_updated
                    number          = $Item.number
                    invalid_domains = $Item.invalid_domains
                    abp_entries     = $Item.abp_entries
                    status          = $Item.status

                }
                $ObjectFinal += $Object
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