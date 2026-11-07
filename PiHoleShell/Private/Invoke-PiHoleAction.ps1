function Invoke-PiHoleAction {
    #INTERNAL FUNCTION
    #
    # Shared body of the parameterless POST /action/* functions (Invoke-PiHoleFlushLogs,
    # Invoke-PiHoleFlushNetwork, Restart-PiHoleDnsService), which differ only in their endpoint
    # and the Status they report. Callers do their own ShouldProcess check first.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Every caller checks ShouldProcess before calling this")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        [Parameter(Mandatory = $true)]
        [string]$Status,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint $Endpoint -Method Post

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = [PSCustomObject]@{
                Status = $Status
            }
            Write-Output $Object
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}
