function Get-PiHoleDnsBlockingStatus {
    <#
.SYNOPSIS
Get current blocking status

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Ignore SSL when interacting with the PiHole API

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleDnsBlockingStatus -PiHoleServer "http://pihole.domain.com:8080" -Password "APIPASSWORD"
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

function Set-PiHoleDnsBlocking {
    <#
.SYNOPSIS
https://ftl.pi-hole.net/development-v6/docs/#post-/dns/blocking

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Blocking
True or False, if you set it to False when Blocking was set to true, it will disable blocking

.PARAMETER TimeInSeconds
How long should the opposite setting last, if you do not set a time, it will be set forever until you change it

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Set-PiHoleDnsBlocking -PiHoleServer "http://pihole.domain.com:8080" -Password "APIPASSWORD" -Blocking $false -TimeInSeconds 60
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
        [int]$TimeInSeconds = $null,
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