function Request-PiHoleAuth {
    #INTERNAL FUNCTION
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [CmdletBinding()]
        [System.URI]$PiHoleServer,
        [string]$Password,
        [bool]$IgnoreSsl = $false
    )

    try {
        $Params = @{
            Uri                  = "$($PiHoleServer.OriginalString)/api/auth"
            Method               = "Post"
            ContentType          = "application/json"
            SkipCertificateCheck = $IgnoreSsl
            Body                 = @{password = $Password } | ConvertTo-Json
        }

        $Response = Invoke-RestMethod @Params -Verbose: $false
        Write-Verbose -Message "Request-PiHoleAuth Successful!"

        Write-Output $Response.session.sid
    }

    catch {
        Write-Error -Message $_.Exception.Message
        break
    }
}

function Get-PiHoleCurrentAuthSession {
    <#
.SYNOPSIS
https://ftl.pi-hole.net/development-v6/docs/#get-/auth

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole v6 server

.PARAMETER IgnoreSsl
Ignore SSL when interacting with the PiHole API

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleCurrentAuthSession -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl"
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

    $Params = @{
        Headers              = @{sid = $($Sid) }
        Uri                  = "$($PiHoleServer.OriginalString)/api/auth/sessions"
        Method               = "Get"
        SkipCertificateCheck = $IgnoreSsl
        ContentType          = "application/json"
    }

    try {
        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            if ($Response.Sessions) {
                $ObjectFinal = @()
                foreach ($Item in $Response.Sessions) {
                    $Object = [PSCustomObject]@{
                        Id             = $Item.id
                        CurrentSession = $Item.current_session
                        Valid          = $Item.valid
                        TlsLogin       = $Item.tls.login
                        TlsMixed       = $Item.tls.mixed
                        LoginAt        = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.login_at).LocalTime
                        LastActive     = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.last_active).LocalTime
                        ValidUntil     = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.valid_until).LocalTime
                        RemoteAddress  = $Item.remote_addr
                        UserAgent      = $Item.user_agent
                        App            = $Item.app
                    }

                    $ObjectFinal += $Object
                    $Object = $null
                }
            }
            Write-Output $ObjectFinal | Where-Object { $_.CurrentSession -match "False" }
        }
        $ObjectFinal = @()
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid
        }
    }
}

function Remove-PiHoleAuthSession {
    <#
.SYNOPSIS
https://ftl.pi-hole.net/development-v6/docs/#get-/auth

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