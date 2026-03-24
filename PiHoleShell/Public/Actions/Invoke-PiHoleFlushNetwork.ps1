function Invoke-PiHoleFlushNetwork {
    <#
.SYNOPSIS
Flushes the network table. This includes removing both all known devices and their associated addresses.

.DESCRIPTION
Flushes the Pi-hole log file (/var/log/pihole/pihole.log).

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Invoke-PiHoleFlushNetwork -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/action/flush/network')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Flushes PiHole logs')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        $PiHoleServer,
        $Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$PiHoleServer/api/action/flush/logs"
            Method               = "Post"
            ContentType          = "application/json"
            SkipCertificateCheck = $IgnoreSsl
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = [PSCustomObject]@{
                Status = "Flushed"
            }
            Write-Output $Object
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