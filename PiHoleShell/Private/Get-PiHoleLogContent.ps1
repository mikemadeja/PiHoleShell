function Get-PiHoleLogContent {
    #INTERNAL FUNCTION
    #
    # Shared body of Get-PiHoleLogDnsmasq, Get-PiHoleLogFtl and Get-PiHoleLogWebserver: the three
    # /logs/* endpoints take the same nextID parameter and return the same shape.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        [Nullable[int]]$NextID,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        if ($null -ne $NextID) {
            $Endpoint += "?nextID=$NextID"
        }

        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint $Endpoint

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $Log = foreach ($Item in $Response.log) {
                [PSCustomObject]@{
                    Timestamp = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.timestamp).LocalTime
                    Message   = $Item.message
                    Priority  = $Item.prio
                }
            }

            $Object = [PSCustomObject]@{
                Log    = $Log
                NextID = $Response.nextID
                Pid    = $Response.pid
                File   = $Response.file
            }
            Write-Output $Object
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}
