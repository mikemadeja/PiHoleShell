if ($PSVersionTable.PSEdition -ne 'Core') {
    throw "PiHoleShell module only supports PowerShell Core 7+. You are using $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)."
}

# Get all .ps1 files in the 'Public' directory and dot-source them
$PublicFunctions = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File
$PrivateFunctions = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -File

foreach ($File in $PublicFunctions) {
    . $File.FullName
}

foreach ($File in $PrivateFunctions) {
    . $File.FullName
}

Export-ModuleMember -Function @(
    #Actions.ps1
    'Update-PiHoleActionsGravity' `
        #Authentication.ps1
        'Remove-PiHoleCurrentAuthSession' , 'Get-PiHoleCurrentAuthSession', 'Remove-PiHoleAuthSession', `
        #GroupManagement.ps1
        'Get-PiHoleGroup', 'New-PiHoleGroup', 'Update-PiHoleGroup', 'Remove-PiHoleGroup', `
        #DnsControl.ps1
        'Get-PiHoleDnsBlockingStatus', 'Set-PiHoleDnsBlocking', `
        #Config.ps1
        'Get-PiHoleConfig', 'Get-PiHoleCurrentAuthSession', 'Remove-PiHoleAuthSession', `
        #Padd.ps1
        'Get-PiHolePadd', `
        #Metrics.ps1
        'Get-PiHoleStatsRecentBlocked', 'Get-PiHoleStatsQueryType', 'Get-PiHoleStatsTopDomain', 'Get-PiHoleStatsSummary', `
        #ListManagement.ps1
        'Get-PiHoleList', 'Search-PiHoleListDomain', 'Add-PiHoleList', 'Remove-PiHoleList', `
        #FTLInformation.ps1
        'Get-PiHoleInfoMessage', 'Get-PiHoleInfoHost'
)