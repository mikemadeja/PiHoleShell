function Invoke-PiHoleFlushLogs {
    <#
.SYNOPSIS
Flushes the DNS logs

.DESCRIPTION
Flushes the Pi-hole DNS logs. This empties the DNS log file and purges the most recent 24
hours of query history from both the long-term database and FTL's internal memory.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Invoke-PiHoleFlushLogs -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/action/flush/logs')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification = "Logs matches the Pi-hole API's own endpoint name, /action/flush/logs")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        if ($PSCmdlet.ShouldProcess("Pi-Hole server at $PiHoleServer", "Flush DNS logs")) {
            $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint 'action/flush/logs' -Method Post

            if ($RawOutput) {
                Write-Output $Response
            }
            else {
                $Object = [PSCustomObject]@{
                    Status = "Flushed"
                }
                Write-Output $Object
            }
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}
