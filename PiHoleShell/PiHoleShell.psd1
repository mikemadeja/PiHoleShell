@{
    RootModule           = 'PiHoleShell.psm1'
    ModuleVersion        = '0.0.0'
    GUID                 = 'b3cecc78-fe8f-49c6-9015-3d66ef5d49cb'
    Author               = 'Mike Madeja'
    Description          = 'A module to interact with PiHole API'
    CompatiblePSEditions = @('Core')  # PowerShell 7+ only

    PowerShellVersion    = '7.0'

    FunctionsToExport    = @('Get-PiHoleGroup', 'New-PiHoleGroup', 'Update-PiHoleGroup', 'Remove-PiHoleGroup', 'Get-PiHoleDnsBlockingStatus', 'Set-PiHoleDnsBlocking', 'Get-PiHoleConfig', 'Get-PiHoleCurrentAuthSession', 'Remove-PiHoleAuthSession')
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