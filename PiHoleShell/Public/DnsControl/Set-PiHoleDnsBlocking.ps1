function Set-PiHoleDnsBlocking {
    <#
.SYNOPSIS
Enable or disable Pi-hole's DNS blocking

.DESCRIPTION
Turns Pi-hole's DNS blocking on or off. Optionally pass -TimeInSeconds to have Pi-hole
automatically revert to the opposite setting after that many seconds - for example,
disabling blocking for 60 seconds to temporarily let all DNS queries through, after which
blocking resumes on its own.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Blocking
True or False, if you set it to False when Blocking was set to true, it will disable blocking

.PARAMETER TimeInSeconds
How long the opposite setting should last, in seconds

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Set-PiHoleDnsBlocking -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Blocking $false -TimeInSeconds 60
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Does not change state')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [ValidateSet("True", "False")]
        $Blocking,
        [Parameter(Mandatory = $true)]
        [int]$TimeInSeconds,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Body = @{
            blocking = $Blocking
            timer    = $TimeInSeconds
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/dns/blocking"
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
            if ($Response) {
                $ObjectFinal = @()
                $Object = [PSCustomObject]@{
                    Blocking      = $Response.blocking
                    TimeInSeconds = (Format-PiHoleSecond -TimeInSeconds $Response.timer).TimeInSeconds
                }
                $ObjectFinal = $Object
            }
            Write-Output $ObjectFinal
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