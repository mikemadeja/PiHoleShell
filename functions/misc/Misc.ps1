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