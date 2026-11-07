function Remove-PiHoleAuthSession {
    <#
.SYNOPSIS
Delete session by ID

.DESCRIPTION
Deletes a session by its ID, as shown by Get-PiHoleCurrentAuthSession, rather than the caller's
own current session.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Ignore SSL when interacting with the PiHole API

.PARAMETER Id
The ID of the session to delete, as shown by Get-PiHoleCurrentAuthSession

.EXAMPLE
Remove-PiHoleAuthSession -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Id 3
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://ftl.pi-hole.net/master/docs/#delete-/auth/session/-id-')]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [int]$Id
    )

    try {
        if ($PSCmdlet.ShouldProcess("Pi-Hole session $Id", "Remove session")) {
            Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint "auth/session/$Id" -Method Delete

            $ObjectFinal = @()
            $Object = [PSCustomObject]@{
                Id     = $Id
                Status = "Removed"
            }
            $ObjectFinal = $Object
            Write-Output $ObjectFinal
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}