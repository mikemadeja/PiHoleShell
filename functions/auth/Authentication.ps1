function Request-PiHoleAuth {
    #INTERNAL FUNCTION
    param (
        [CmdletBinding()]
        [System.URI]$PiHoleServer,
        [string]$Password
    )
    try {
        $Params = @{
            Uri         = "$($PiHoleServer.OriginalString)/api/auth"
            Method      = "Post"
            ContentType = "application/json"
            Body        = @{password = $Password } | ConvertTo-Json
        }
        $Response = Invoke-RestMethod @Params
        Write-Output $Response.session.sid
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }
}

function Get-PiHoleCurrentAuthSession {
    <#
.SYNOPSIS
https://ftl.pi-hole.net/development-v6/docs/#get-/auth

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.EXAMPLE
Get-PiHoleCurrentAuthSession -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl"
    #>
    [CmdletBinding()]
    param (
        $PiHoleServer,
        $Password,
        [bool]$RawOutput = $false
    )

    $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password

    $Params = @{
        Headers     = @{sid = $($Sid) }
        Uri         = "$PiHoleServer/api/auth/sessions"
        Method      = "Get"
        ContentType = "application/json"
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
        Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid
    }
}

function Remove-PiHoleCurrentAuthSession {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Justification = "It removes sessions from PiHole only")]
    #INTERNAL FUNCTION
    [CmdletBinding()]
    param (
        $PiHoleServer,
        $Sid
    )
    $Params = @{
        Headers     = @{sid = $($Sid) }
        Uri         = "$PiHoleServer/api/auth"
        Method      = "Delete"
        ContentType = "application/json"
    }

    try {
        Invoke-RestMethod @Params
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }
}

function Remove-PiHoleAuthSession {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Justification = "It removes sessions from PiHole only")]
    param (
        $PiHoleServer,
        $Password,
        [int]$Id
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password
        $Params = @{
            Headers     = @{sid = $($Sid) }
            Uri         = "$PiHoleServer/api/auth/session/$Id"
            Method      = "Delete"
            ContentType = "application/json"
        }

        Invoke-RestMethod @Params
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }

    finally {
        Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid
    }
}

Export-ModuleMember -Function Get-PiHoleCurrentAuthSession, Remove-PiHoleAuthSession