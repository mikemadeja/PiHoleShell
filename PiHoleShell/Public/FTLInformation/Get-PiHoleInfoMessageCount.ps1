function Get-PiHoleInfoMessageCount {
    <#
.SYNOPSIS
Get count of Pi-hole diagnosis messages

.DESCRIPTION
Request the number of Pi-hole diagnosis messages currently outstanding. See
Get-PiHoleInfoMessage for the messages themselves, and Remove-PiHoleInfoMessage to dismiss one.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoMessageCount -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/info/messages/count')]
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
        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint 'info/messages/count'

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = [PSCustomObject]@{
                Count = $Response.count
            }
            Write-Output $Object
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}
