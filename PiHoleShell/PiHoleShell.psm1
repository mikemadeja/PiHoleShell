if ($PSVersionTable.PSEdition -ne 'Core') {
    throw "PiHoleShell module only supports PowerShell Core 7+. You are using $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)."
}

# Get all .ps1 files in the 'Public' directory and dot-source them
$PublicFunctions = Get-ChildItem  -Verbose -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File -Recurse
$PrivateFunctions = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -File -Recurse

foreach ($File in $PublicFunctions) {
    . $File.FullName
}

foreach ($File in $PrivateFunctions) {
    . $File.FullName
}

Export-ModuleMember -Function @(
    #Actions
    'Update-PiHoleActionsGravity', 'Invoke-PiHoleFlushNetwork', 'Restart-PiHoleDnsService' `
        #Authentication
        'Remove-PiHoleCurrentAuthSession' , 'Get-PiHoleCurrentAuthSession', 'Remove-PiHoleAuthSession', `
        #GroupManagement
        'Get-PiHoleGroup', 'New-PiHoleGroup', 'Update-PiHoleGroup', 'Remove-PiHoleGroup', `
        #DnsControl
        'Get-PiHoleDnsBlockingStatus', 'Set-PiHoleDnsBlocking', `
        #Config
        'Get-PiHoleConfig', `
        #Padd
        'Get-PiHolePadd', `
        #Metrics
        'Get-PiHoleStatsRecentBlocked', 'Get-PiHoleStatsQueryType', 'Get-PiHoleStatsTopDomain', 'Get-PiHoleStatsSummary', 'Get-PiHoleStatsTopClient' `
        #ListManagement
        'Get-PiHoleList', 'Search-PiHoleListDomain', 'Add-PiHoleList', 'Remove-PiHoleList', `
        #FTLInformation
        'Get-PiHoleInfoMessage', 'Get-PiHoleInfoHost'
)