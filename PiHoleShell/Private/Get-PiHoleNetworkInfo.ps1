function Get-PiHoleNetworkInfo {
    #INTERNAL FUNCTION
    #
    # Shared body of Get-PiHoleNetworkGateway, Get-PiHoleNetworkInterface and
    # Get-PiHoleNetworkRoute: each /network/* endpoint takes the same detailed parameter and
    # returns its data under one property (Property), converted to PascalCase as-is.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        [Parameter(Mandatory = $true)]
        [string]$Property,
        [Nullable[bool]]$Detailed,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        if ($null -ne $Detailed) {
            $Endpoint += "?detailed=$($Detailed.ToString().ToLower())"
        }

        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint $Endpoint

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $Object = ConvertTo-PiHolePascalCaseObject -InputObject $Response.$Property
            Write-Output $Object
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}
