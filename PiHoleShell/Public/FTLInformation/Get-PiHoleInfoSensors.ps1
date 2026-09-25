function Get-PiHoleInfoSensors {
    <#
.SYNOPSIS
Get info about various sensors

.DESCRIPTION
Request temperature sensor information, including Pi-hole's best guess at the CPU
temperature and the configured "hot" limit.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoSensors -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/info/sensors')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification = "Sensors matches the Pi-hole API's own endpoint name, /info/sensors")]
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
            Uri                  = "$($PiHoleServer.OriginalString)/api/info/sensors"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $List = foreach ($Item in $Response.sensors.list) {
                $Temps = foreach ($Temp in $Item.temps) {
                    [PSCustomObject]@{
                        Name   = $Temp.name
                        Value  = $Temp.value
                        Max    = $Temp.max
                        Crit   = $Temp.crit
                        Sensor = $Temp.sensor
                    }
                }
                [PSCustomObject]@{
                    Name   = $Item.name
                    Path   = $Item.path
                    Source = $Item.source
                    Temps  = $Temps
                }
            }

            $Object = [PSCustomObject]@{
                List     = $List
                CpuTemp  = $Response.sensors.cpu_temp
                HotLimit = $Response.sensors.hot_limit
                Unit     = $Response.sensors.unit
            }
            Write-Output $Object
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
