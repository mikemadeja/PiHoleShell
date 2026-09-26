# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Get-PiHoleTeleporterDownload (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl
        }

        $script:TestFolder = Join-Path ([System.IO.Path]::GetTempPath()) "PiHoleShellPesterTeleporter"
        if (Test-Path $script:TestFolder) {
            Remove-Item -Path $script:TestFolder -Recurse -Force
        }
        New-Item -ItemType Directory -Path $script:TestFolder | Out-Null
    }

    AfterAll {
        if (Test-Path $script:TestFolder) {
            Remove-Item -Path $script:TestFolder -Recurse -Force
        }
    }

    It 'downloads a real ZIP backup and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleTeleporterDownload -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -FolderPath $script:TestFolder -FileName 'pester-backup'
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.FileName | Should -Be 'pester-backup.zip'
        $result.FileSizeKB | Should -BeGreaterThan 0
        Test-Path $result.FilePath | Should -BeTrue

        # Confirm it's a genuine, openable ZIP archive, not just a file with a .zip name.
        $zip = [System.IO.Compression.ZipFile]::OpenRead($result.FilePath)
        try {
            $zip.Entries.Count | Should -BeGreaterThan 0
        }
        finally {
            $zip.Dispose()
        }
    }

    It 'errors when the destination file already exists' -Skip:(-not $script:ConfigAvailable) {
        Get-PiHoleTeleporterDownload -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -FolderPath $script:TestFolder -FileName 'duplicate-backup' | Out-Null

        $result = Get-PiHoleTeleporterDownload -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -FolderPath $script:TestFolder -FileName 'duplicate-backup' -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when the destination folder does not exist' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleTeleporterDownload -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -FolderPath (Join-Path $script:TestFolder 'does-not-exist') -FileName 'x' -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleTeleporterDownload -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -FolderPath $script:TestFolder -FileName 'bad-password-backup' -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
