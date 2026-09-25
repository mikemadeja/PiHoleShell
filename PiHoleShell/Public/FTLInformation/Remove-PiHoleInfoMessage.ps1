function Remove-PiHoleInfoMessage {
    <#
.SYNOPSIS
Delete a Pi-hole diagnosis message

.DESCRIPTION
Dismisses one or more Pi-hole diagnosis messages by ID. See Get-PiHoleInfoMessage to list
messages and find their IDs.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER MessageId
The ID (or IDs) of the message(s) to delete

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Remove-PiHoleInfoMessage -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -MessageId 3

.EXAMPLE
Remove-PiHoleInfoMessage -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -MessageId 1,2,3
    #>
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://ftl.pi-hole.net/master/docs/#delete-/info/messages/-message_id-')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [int[]]$MessageId,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $MessageIdPath = $MessageId -join ','

        if ($PSCmdlet.ShouldProcess("Pi-Hole diagnosis message(s) $MessageIdPath on $PiHoleServer", "Delete")) {
            $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

            $Params = @{
                Headers              = @{sid = $($Sid) }
                Uri                  = "$($PiHoleServer.OriginalString)/api/info/messages/$MessageIdPath"
                Method               = "Delete"
                SkipCertificateCheck = $IgnoreSsl
                ContentType          = "application/json"
            }

            $Response = Invoke-RestMethod @Params

            if ($RawOutput) {
                Write-Output $Response
            }
            else {
                # A successful delete is HTTP 204 No Content, so there's no response body to parse.
                $Object = [PSCustomObject]@{
                    MessageId = $MessageId
                    Status    = "Deleted"
                }
                Write-Output $Object
            }
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}
