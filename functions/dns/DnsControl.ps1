function Get-PiHoleDnsBlockingStatus {
    <#
.SYNOPSIS
https://ftl.pi-hole.net/development-v6/docs/#get-/dns/blocking

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleDnsBlockingStatus -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl"
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        $PiHoleServer,
        $Password,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password

        $Params = @{
            Headers     = @{sid = $($Sid) }
            Uri         = "$PiHoleServer/api/dns/blocking"
            Method      = "Get"
            ContentType = "application/json"
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
    }

    finally {
        Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid
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
Set-PiHoleDnsBlocking -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl" -Blocking $false -TimeInSeconds 60
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Does not change state')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        $PiHoleServer,
        $Password,
        [ValidateSet("True", "False")]
        $Blocking,
        [int]$TimeInSeconds = $null,
        [bool]$RawOutput = $false
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password

        $Blocking = $Blocking.ToLower()

        $Body = "{`"blocking`":$Blocking,`"timer`":$TimeInSeconds}"
        $Params = @{
            Headers     = @{sid = $($Sid)
                Accept      = "application/json"
            }
            Uri         = "$PiHoleServer/api/dns/blocking"
            Method      = "Post"
            ContentType = "application/json"
            Body        = $Body
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
        Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid
    }
}

Export-ModuleMember -Function Get-PiHoleDnsBlockingStatus, Set-PiHoleDnsBlocking