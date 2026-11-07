function Get-PiHoleStatsRecentBlocked {
    <#
.SYNOPSIS
Get most recently blocked domain

.DESCRIPTION
Request most recently blocked domain

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER MaxResult
How many results should be returned

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleStatsRecentBlocked -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -MaxResult 20
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/stats/recent_blocked')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [int]$MaxResult = 1,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        Write-Verbose -Message "MaxResults - $MaxResult"
        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint "stats/recent_blocked?count=$MaxResult"

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
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
        break
    }
}

