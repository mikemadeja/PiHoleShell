# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.
#
# NOTE: This only generates a candidate application password/hash pair - it has no effect until
# the returned Hash is explicitly set as webserver.api.app_pwhash in the Pi-hole configuration,
# which these tests deliberately never do, so there's nothing to clean up afterward and the
# server's real app password is left untouched.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'New-PiHoleAppPassword (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl
        }
    }

    It 'generates a new application password and hash as a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleAppPassword -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Password | Should -Not -BeNullOrEmpty
        $result.Hash | Should -Not -BeNullOrEmpty
    }

    # Generating a password only ever hands back a fresh candidate - confirms the real password
    # used throughout this suite still works afterward, i.e. generating one has no side effects
    # until its hash is explicitly applied via config.
    It 'does not invalidate the password used to generate it' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleAppPassword -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl | Out-Null

        $status = Get-PiHoleAuthStatus -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl
        $status.Valid | Should -BeTrue
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleAppPassword -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result.PSObject.Properties.Name | Should -Contain 'app'
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleAppPassword -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
