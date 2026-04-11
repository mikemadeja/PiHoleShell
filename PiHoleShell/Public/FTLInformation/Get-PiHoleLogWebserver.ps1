
function Get-PiHoleLogWebserver {
    <#
.SYNOPSIS
Get info about logs for webserver

    #>
    #Work In Progress
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/logs/webserver')] 
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [int]$NextID,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        if ($NextID) {
            $Uri = "$($PiHoleServer.OriginalString)/api/logs/webserver?nextId=$NextId"

        }
        else {
            $Uri = "$($PiHoleServer.OriginalString)/api/logs/webserver"
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = $Uri
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            #$ObjectFinal = @()
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