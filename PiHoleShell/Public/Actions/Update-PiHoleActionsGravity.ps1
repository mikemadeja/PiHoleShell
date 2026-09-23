function Update-PiHoleActionsGravity {
    <#
.SYNOPSIS
Update Pi-hole's adlists by running pihole -g

.DESCRIPTION
Triggers a Pi-hole gravity update (equivalent to running `pihole -g` on the server), which
re-downloads and rebuilds the adlists used for blocking. This can take anywhere from several
seconds to a few minutes depending on adlist size. The API streams back the raw `pihole -g`
console log as plain text rather than JSON, so -RawOutput returns that log verbatim.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the raw pihole -g console log instead of the formatted object

.EXAMPLE
Update-PiHoleActionsGravity -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
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

        if ($PSCmdlet.ShouldProcess("Pi-Hole server at $PiHoleServer", "Update gravity")) {
            $Response = Invoke-RestMethod @Params

            if ($RawOutput) {
                Write-Output $Response
            }
            else {
                $Object = [PSCustomObject]@{
                    Status = "Completed"
                }
                Write-Output $Object
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