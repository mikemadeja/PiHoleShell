function Remove-PiHoleGroup {
    <#
.SYNOPSIS
Delete group

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

    #>
    #Work In Progress
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

        $Body = @{
            name = $GroupName
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/groups/$GroupName"
            Method               = "Delete"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
            Body                 = $Body | ConvertTo-Json -Depth 10
        }
        $GetGroupName = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -GroupName $GroupName

        if ($GetGroupName) {
            $Response = Invoke-RestMethod @Params

            if ($RawOutput) {
                Write-Output $Response
            }
            else {
                $ObjectFinal = @()
                $Object = [PSCustomObject]@{
                    Name   = $GroupName
                    Status = "Deleted"
                }
                $ObjectFinal = $Object
            }
            Write-Verbose -Message "Deleted $($Object.GroupName)"
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