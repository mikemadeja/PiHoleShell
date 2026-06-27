function Update-PiHoleActionsGravity {
    <#
.SYNOPSIS
Update Pi-hole's adlists by running pihole -g. The output of the process is streamed with chunked encoding. Use the optional color query parameter to include ANSI color escape codes in the output.

    #>
    #Work In Progress
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/action/gravity')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/action/gravity"
            Method               = "Post"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        if ($PSCmdlet.ShouldProcess("Pi-Hole server at $PiHoleServer", "Update gravity actions")) {
            $Response = Invoke-RestMethod @Params
        }

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $ObjectFinal = @()
            $Object = $null
            if ($Object) {
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