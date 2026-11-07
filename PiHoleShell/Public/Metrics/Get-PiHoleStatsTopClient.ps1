function Get-PiHoleStatsTopClient {
    <#
.SYNOPSIS
Get top clients

.DESCRIPTION
Request the top clients (by query count)

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER MaxResult
How many results should be returned

.PARAMETER Blocked
If true, returns top clients by blocked queries instead of total queries

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleStatsTopClient -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -MaxResult 10
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [int]$MaxResult = 10,
        [bool]$Blocked = $false,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        switch ($Blocked) {
            $false { $BlockedParam = "false" }
            $true { $BlockedParam = "true" }
            Default { throw "ERROR" }
        }
        Write-Verbose "Blocked: $BlockedParam"
        Write-Verbose "MaxResult: $MaxResult"

        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint "stats/top_clients?blocked=$BlockedParam&count=$MaxResult"

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $ObjectFinal = @()
            foreach ($Item in $Response.clients) {
                $Object = $null
                $Object = [PSCustomObject]@{
                    IP    = $Item.ip
                    Name  = $Item.name
                    Count = $Item.count
                }
                Write-Verbose -Message "Client - $($Item.ip) ($($Item.name)): $($Item.count)"
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