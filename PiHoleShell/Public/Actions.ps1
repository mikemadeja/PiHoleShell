function Update-PiHoleActionsGravity {
    <#
.SYNOPSIS
Update Pi-hole's adlists by running pihole -g. The output of the process is streamed with chunked encoding.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Ignore SSL when interacting with the PiHole API

.EXAMPLE
Update-PiHoleActionsGravity -PiHoleServer "http://pihole.domain.com:8080" -Password "APIPASSWORD"
    #>
    #Work In Progress
    [CmdletBinding(SupportsShouldProcess = $true)]
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

function Restart-PiHoleDns {
    <#
.SYNOPSIS
Restarts the pihole-FTL service

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Ignore SSL when interacting with the PiHole API

.EXAMPLE
Restart-PiHoleDns -PiHoleServer "http://pihole.domain.com:8080" -Password "APIPASSWORD"
    #>
    #Work In Progress
    [CmdletBinding(SupportsShouldProcess = $true)]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    # if ($PSCmdlet.ShouldProcess("Pi-Hole server at $PiHoleServer", "Restart PiHole DNS")) {
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/action/restartdns"
            Method               = "Post"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params
    
        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $ObjectFinal = @()
            $Object = [PSCustomObject]@{
                Status = $Response.Status
                Took   = (Format-PiHoleSecond -TimeInSeconds $Response.took).TimeInSeconds
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
    #}
}