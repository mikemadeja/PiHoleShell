@{
    RootModule           = 'PiHoleShell.psm1'
    ModuleVersion        = '0.0.0'
    GUID                 = 'b3cecc78-fe8f-49c6-9015-3d66ef5d49cb'
    Author               = 'Mike Madeja'
    Description          = 'A module to interact with the v6 version of PiHole API'
    CompatiblePSEditions = @('Core')

    PowerShellVersion    = '7.0'

    FunctionsToExport    = @(
        #Authentication.ps1
        'Remove-PiHoleCurrentAuthSession' , 'Get-PiHoleCurrentAuthSession', 'Remove-PiHoleAuthSession', `
            #GroupManagement.ps1
            'Get-PiHoleGroup', 'New-PiHoleGroup', 'Update-PiHoleGroup', 'Remove-PiHoleGroup', `
            #DnsControl.ps1
            'Get-PiHoleDnsBlockingStatus', 'Set-PiHoleDnsBlocking', `
            #Config.ps1
            'Get-PiHoleConfig', 'Get-PiHoleCurrentAuthSession', 'Remove-PiHoleAuthSession', `
            #Metrics.ps1
            'Get-PiHoleStatsRecentBlocked', 'Get-PiHoleStatsQueryType', 'Get-PiHoleStatsTopDomain', 'Get-PiHoleStatsSummary', `
            #ListManagement.ps1
            'Get-PiHoleList',
        #FTLInformation.ps1
        'Get-PiHoleInfoMessage', 'Get-PiHoleInfoHost')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()

    PrivateData          = @{
        PSData = @{
            Tags         = @('PiHole', 'PowerShell7')
            LicenseUri   = 'https://github.com/mikemadeja/PiHoleShell/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/mikemadeja/PiHoleShell'
            ReleaseNotes = 'Initial release targeting PowerShell 7+'
        }
    }
}
