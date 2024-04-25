function Get-PiHoleStatsRecentBlocked {
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
    }

    finally {
        Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid
    }
}

Export-ModuleMember -Function Get-PiHoleStatsRecentBlocked