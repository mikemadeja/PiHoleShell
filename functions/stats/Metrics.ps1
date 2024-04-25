function Get-PiHoleStatsRecentBlocked {
    <#
.SYNOPSIS
https://ftl.pi-hole.net/development-v6/docs/#get-/stats/recent_blocked

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER MaxResult
How many results should be returned

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleStatsRecentBlocked -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl" -MaxResult 20
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        $PiHoleServer,
        $Password,
        [int]$MaxResult = 1,
        [bool]$RawOutput
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password
        Write-Verbose -Message "MaxResults - $MaxResult"
        $Params = @{
            Headers     = @{sid = $($Sid) }
            Uri         = "$PiHoleServer/api/stats/recent_blocked?count=$MaxResult"
            Method      = "Get"
            ContentType = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $ObjectFinal = @()
            foreach ($Item in $Response.blocked) {
                $Object = $null
                $Object = [PSCustomObject]@{
                    Blocked = $Item
                }
                Write-Verbose -Message "Blocked - $Item"
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
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid
        }
    }
}

Export-ModuleMember -Function Get-PiHoleStatsRecentBlocked