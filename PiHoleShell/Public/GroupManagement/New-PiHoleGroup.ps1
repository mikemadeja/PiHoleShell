function New-PiHoleGroup {
    <#
.SYNOPSIS
Creates a new group in the groups object.

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
                $ObjectFinal = @()
                $Object = [PSCustomObject]@{
                    Name    = $GroupName
                    Comment = $Comment
                    Enabled = $Enabled
                }
                Write-Verbose -Message "Name - $($Object.GroupName)"
                Write-Verbose -Message "Comment - $($Object.Comment)"
                Write-Verbose -Message "Enabled - $($Object.Enabled)"
                $ObjectFinal = $Object
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