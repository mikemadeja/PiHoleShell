function Format-PiHoleSecond {
    param (
        [int]$TimeInSeconds
    )

    $Data = [math]::Round($TimeInSeconds)

    $Object = [PSCustomObject]@{
        TimeInSeconds = $Data
    }

    $ObjectFinal = $Object
    Write-Output $ObjectFinal
}

function Convert-PiHoleUnixTimeToLocalTime {
    param (
        [int]$UnixTime
    )

    $ConvertedTime = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixTime))

    $ObjectFinal = @()

    $Object = [PSCustomObject]@{
        LocalTime = $ConvertedTime
        UnixTime  = $UnixTime
    }

    $ObjectFinal = $Object
    Write-Output $ObjectFinal
}

function Convert-LocalTimeToPiHoleUnixTime {
    param (
        [datetime]$Date
    )

    $ConvertedTime = [int64](Get-Date $Date -UFormat %s)

    $Object = [PSCustomObject]@{
        LocalTime = $Date
        UnixTime  = $ConvertedTime
    }

    $ObjectFinal = $Object
    Write-Output $ObjectFinal
}

function ConvertTo-PiHolePascalCase {
    #INTERNAL FUNCTION
    param (
        [string]$Name
    )

    if ([string]::IsNullOrEmpty($Name)) {
        return $Name
    }

    $Segments = $Name -split '_' | Where-Object { $_.Length -gt 0 }
    $PascalSegments = foreach ($Segment in $Segments) {
        $Segment.Substring(0, 1).ToUpper() + $Segment.Substring(1)
    }
    return ($PascalSegments -join '')
}

function ConvertTo-PiHolePascalCaseObject {
    #INTERNAL FUNCTION
    #
    # Recursively rebuilds an API response as nested PSCustomObjects/arrays with PascalCase
    # property names (e.g. EXTERNAL_BLOCKED_IP / app_pwhash -> ExternalBlockedIp / AppPwhash),
    # so deep/wide response trees don't need every field hardcoded by hand to be PowerShell
    # object friendly - and so newly added API fields show up automatically instead of being
    # silently dropped.
    param (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )
    process {
        if ($null -eq $InputObject) {
            return $null
        }

        if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
            $Result = [ordered]@{}
            foreach ($Prop in $InputObject.PSObject.Properties) {
                $Key = ConvertTo-PiHolePascalCase -Name $Prop.Name
                $Result[$Key] = ConvertTo-PiHolePascalCaseObject -InputObject $Prop.Value
            }
            return [PSCustomObject]$Result
        }

        if (($InputObject -is [System.Collections.IEnumerable]) -and ($InputObject -isnot [string])) {
            return @($InputObject | ForEach-Object { ConvertTo-PiHolePascalCaseObject -InputObject $_ })
        }

        return $InputObject
    }
}

function Remove-PiHoleCurrentAuthSession {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Justification = "It removes sessions from PiHole only")]
    [CmdletBinding()]
    param (
        [System.URI]$PiHoleServer,
        [string]$Sid,
        [bool]$IgnoreSsl = $false
    )
    $Params = @{
        Headers              = @{sid = $($Sid) }
        Uri                  = "$($PiHoleServer.OriginalString)/api/auth"
        Method               = "Delete"
        SkipCertificateCheck = $IgnoreSsl
        ContentType          = "application/json"
    }

    try {
        $null = Invoke-RestMethod @Params
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }
}