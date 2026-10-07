# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.
#
# NOTE: The "real import" test below selectively restores only the groups table from a backup
# taken of the server's own current state, so it's a no-op restore rather than a destructive
# change - safe to run repeatedly. Confirmed by hand that Pi-hole briefly reloads internally
# right after any import (a transient 401/connection error on the very next call), so this file
# settles with a short delay afterward rather than asserting anything about server state
# immediately following an import.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Import-PiHoleTeleporter (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            $script:TestFolder = Join-Path ([System.IO.Path]::GetTempPath()) 'PiHoleShellPesterTeleporterImport'
            if (Test-Path $script:TestFolder) {
                Remove-Item -Path $script:TestFolder -Recurse -Force
            }
            New-Item -ItemType Directory -Path $script:TestFolder | Out-Null

            # -ErrorAction Stop so a real failure here fails BeforeAll loudly instead of leaving
            # $script:BackupFilePath silently $null (Get-PiHoleTeleporterDownload traps its own
            # errors internally and just writes a non-terminating error otherwise).
            $backup = Get-PiHoleTeleporterDownload -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -FolderPath $script:TestFolder -FileName 'import-fixture' -ErrorAction Stop
            $script:BackupFilePath = $backup.FilePath
        }
    }

    AfterAll {
        if ($script:TestFolder -and (Test-Path $script:TestFolder)) {
            Remove-Item -Path $script:TestFolder -Recurse -Force
        }
    }

    It 'imports a selected item from a real backup and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = Import-PiHoleTeleporter -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -FilePath $script:BackupFilePath -Group -Confirm:$false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Processed | Should -Not -BeNullOrEmpty
        $result.Processed | Should -Match 'group'

        # Pi-hole reloads internally right after an import - give it a moment before the next test.
        Start-Sleep -Seconds 5
    }

    It 'does not import anything when -WhatIf is set' -Skip:(-not $script:ConfigAvailable) {
        { Import-PiHoleTeleporter -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -FilePath $script:BackupFilePath -Group -WhatIf } | Should -Not -Throw
    }

    It 'errors when the file does not exist' -Skip:(-not $script:ConfigAvailable) {
        $result = Import-PiHoleTeleporter -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -FilePath (Join-Path $script:TestFolder 'does-not-exist.zip') -Confirm:$false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when the uploaded file is not a valid ZIP archive' -Skip:(-not $script:ConfigAvailable) {
        $badFile = Join-Path $script:TestFolder 'not-a-zip.zip'
        'this is not a zip file' | Set-Content -Path $badFile

        $result = Import-PiHoleTeleporter -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -FilePath $badFile -Confirm:$false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Import-PiHoleTeleporter -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -FilePath $script:BackupFilePath -Confirm:$false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
