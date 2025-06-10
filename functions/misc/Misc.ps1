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

function Test-HttpPrefixForPiHole {
    param (
        [Parameter(Mandatory)]
        [string]$Url
    )

    Write-Output $Url -match '^https?://'
}

function Test-PiHoleServerAccess {
    param (
        [Parameter(Mandatory)]
        [string]$Url,
        [bool]$IgnoreSsl = $false
    )

    if (Test-HttpPrefixForPiHole -Url $Url) {
        $RawOutput = Invoke-WebRequest -Uri "$Url/admin/login" -Method Head -TimeoutSec 5 -ErrorAction Stop -SkipCertificateCheck
    }
}

# function Convert-EnabledBoolToString {
#     param (
#         [bool]$Bool
#     )

#     switch ($Bool) {
#         $false {
#             $Enabled = "false"
#         }
#         $true {
#             $Enabled = "true"
#         }
#     }

#     $Object = [PSCustomObject]@{
#         Bool = $Enabled
#     }

#     Write-Output $Object

# }