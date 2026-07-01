function Get-PiHoleInfoMessage {
    <#
.SYNOPSIS
Get Pi-hole diagnosis messages.

.DESCRIPTION
Retrieves Pi-hole diagnosis messages from the server.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoMessage -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD"
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
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/info/messages"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

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
        Write-Error -Message $_.Exception.Message
        break
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}

function Get-PiHoleInfoHost {
    <#
.SYNOPSIS
Get info about various host parameters.

.DESCRIPTION
Returns a collection of host information from the Pi-hole server.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoHost -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD"
    #>
    #Work In Progress
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
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/info/host"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $ObjectFinal = @()
            foreach ($Item in $Response.host) {
                $Object = $null
                $Object = [PSCustomObject]@{
                    DomainName = $Item.uname.domainname
                    Machine    = $Item.uname.machine
                    NodeName   = $Item.uname.nodename
                    Release    = $Item.uname.release
                    SysName    = $Item.uname.sysname
                    Version    = $Item.uname.version

                }
                $ObjectFinal += $Object
                Write-Output $ObjectFinal
            }
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
        break
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}

function Get-PiHoleLogWebserver {
    <#
.SYNOPSIS
Get webserver log entries from the Pi-hole server.

.DESCRIPTION
Retrieves webserver log entries. Optionally provide a NextID to page through results.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER NextID
The log entry ID to start from, used for paginating through log results

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleLogWebserver -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD"
    #>
    #Work In Progress
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [int]$NextID,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        if ($NextID) {
            $Uri = "$($PiHoleServer.OriginalString)/api/logs/webserver?nextId=$NextId"

        }
        else {
            $Uri = "$($PiHoleServer.OriginalString)/api/logs/webserver"
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = $Uri
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            #$ObjectFinal = @()
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
        break
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}