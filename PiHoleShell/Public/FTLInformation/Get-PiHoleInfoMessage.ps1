function Get-PiHoleInfoMessage {
    <#
.SYNOPSIS
Get Pi-hole diagnosis messages

.DESCRIPTION
Request Pi-hole's diagnosis messages - warnings FTL has generated about its own configuration
or operation (e.g. rate-limiting a noisy client). See Get-PiHoleInfoMessageCount for just the
count, and Remove-PiHoleInfoMessage to dismiss one.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoMessage -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/info/messages')]
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
        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint 'info/messages'

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $ObjectFinal = @()
            foreach ($Item in $Response.messages) {
                $Object = $null
                $Object = [PSCustomObject]@{
                    Id        = $Item.id
                    Timestamp = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.timestamp).LocalTime
                    Type      = $Item.type
                    Plain     = $Item.plain
                    Html      = $Item.html

                }

                Write-Verbose -Message "Name - $($Object.Id)"
                Write-Verbose -Message "Timestamp - $($Object.Timestamp)"
                Write-Verbose -Message "Type - $($Object.Type)"
                Write-Verbose -Message "Plain - $($Object.Plain)"
                Write-Verbose -Message "Html - $($Object.Html)"
                $ObjectFinal += $Object
            }

            Write-Output $ObjectFinal
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}