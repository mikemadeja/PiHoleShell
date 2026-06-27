function Remove-PiHoleAuthSession {
    <#
.SYNOPSIS
Using this endpoint, a session can be deleted by its ID.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Ignore SSL when interacting with the PiHole API

.EXAMPLE
Get-PiHoleCurrentAuthSession -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl"
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Does not change state')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#delete-/auth/session/-id-')]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [int]$Id
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl
        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/auth/session/$Id"
            Method               = "Delete"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        Invoke-RestMethod @Params

        $ObjectFinal = @()
        $Object = [PSCustomObject]@{
            Id     = $Id
            Status = "Removed"
        }
        $ObjectFinal = $Object
        Write-Output $ObjectFinal
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