function Get-PiHoleDnsBlockingStatus {
    <#
.SYNOPSIS
https://ftl.pi-hole.net/master/docs/#get-/config

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Ignore SSL when interacting with the PiHole API

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleDnsBlockingStatus -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl"
    #>
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
            Uri                  = "$($PiHoleServer.OriginalString)/api/dns/blocking"
            Method               = "Get"
            ContentType          = "application/json"
            SkipCertificateCheck = $IgnoreSsl
        }

        $Data = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Data
        }
        else {
            $ObjectFinal = @()
            $Object = [PSCustomObject]@{
                Blocking = $Data.blocking
                Timer    = (Format-PiHoleSecond -TimeInSeconds $Data.timer).TimeInSeconds
            }

            $ObjectFinal += $Object
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