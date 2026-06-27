function Get-PiHoleInfoHost {
    <#
.SYNOPSIS
Get info about various host parameters
This API hook returns a collection of host infos.

    #>
    #Work In Progress
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/info/host')]
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