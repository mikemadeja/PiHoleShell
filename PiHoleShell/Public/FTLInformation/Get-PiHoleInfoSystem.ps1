function Get-PiHoleInfoSystem {
    <#
.SYNOPSIS
Get info about various system parameters

.DESCRIPTION
Request system information: uptime, RAM/swap memory usage, process count, and CPU usage/load
averages, including FTL's own share of memory and CPU.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoSystem -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/info/system')]
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
            Uri                  = "$($PiHoleServer.OriginalString)/api/info/system"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = [PSCustomObject]@{
                Uptime = $Response.system.uptime
                Memory = [PSCustomObject]@{
                    Ram  = [PSCustomObject]@{
                        Total        = $Response.system.memory.ram.total
                        Free         = $Response.system.memory.ram.free
                        Used         = $Response.system.memory.ram.used
                        Available    = $Response.system.memory.ram.available
                        PercentUsed  = $Response.system.memory.ram.'%used'
                    }
                    Swap = [PSCustomObject]@{
                        Total       = $Response.system.memory.swap.total
                        Free        = $Response.system.memory.swap.free
                        Used        = $Response.system.memory.swap.used
                        PercentUsed = $Response.system.memory.swap.'%used'
                    }
                }
                Procs  = $Response.system.procs
                Cpu    = [PSCustomObject]@{
                    NumProcessors = $Response.system.cpu.nprocs
                    PercentCpu    = $Response.system.cpu.'%cpu'
                    Load          = [PSCustomObject]@{
                        Raw     = $Response.system.cpu.load.raw
                        Percent = $Response.system.cpu.load.percent
                    }
                }
                Ftl    = [PSCustomObject]@{
                    PercentMemory = $Response.system.ftl.'%mem'
                    PercentCpu    = $Response.system.ftl.'%cpu'
                }
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
