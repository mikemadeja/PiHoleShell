function Get-PiHoleStatsTopDomain {
    <#
.SYNOPSIS
https://TODOFINDNEWAPILINK
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [int]$MaxResult = 10,
        [bool]$Blocked = $false,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

    switch ($Blocked) {
        $false {
            $Blocked = "false"
        }
        $true {
            $Blocked = "true"
        }
        Default {
            throw "ERROR"
        }
    }
    Write-Verbose "Blocked: $Blocked"

    $Params = @{
        Headers              = @{sid = $($Sid) }
        Uri                  = "$($PiHoleServer.OriginalString)/api/stats/top_domains?blocked=$Blocked&count=$MaxResult"
        Method               = "Get"
        SkipCertificateCheck = $IgnoreSsl
        ContentType          = "application/json"
    }

    $Response = Invoke-RestMethod @Params

    if ($RawOutput) {
        Write-Output $Response
    }

    if ($Sid) {
        Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
    }
}