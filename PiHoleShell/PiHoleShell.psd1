@{
    RootModule           = 'PiHoleShell.psm1'
    ModuleVersion        = '0.0.0'
    GUID                 = 'b3cecc78-fe8f-49c6-9015-3d66ef5d49cb'
    Author               = 'Mike Madeja'
    Description          = 'A module to interact with PiHole API'
    CompatiblePSEditions = @('Core')  # PowerShell 7+ only

    PowerShellVersion    = '7.0'

    FunctionsToExport    = @('Hello-World')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()

    PrivateData          = @{
        PSData = @{
            Tags         = @('Sample', 'HelloWorld', 'PowerShell7')
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ProjectUri   = 'https://github.com/yourname/MyModule'
            ReleaseNotes = 'Initial release targeting PowerShell 7+'
        }
    }
}