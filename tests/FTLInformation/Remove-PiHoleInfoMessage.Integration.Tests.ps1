# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.
#
# NOTE: Diagnosis messages arise from real FTL warnings (e.g. rate-limiting a client) and can't
# be manufactured on demand, so there's no reliable way to test a genuine successful delete here.
# These tests instead verify the error paths, which still exercise the real request/auth flow.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Remove-PiHoleInfoMessage (Integration)' -Tag 'Integration' {
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

    It 'errors when the message does not exist' -Skip:(-not $script:ConfigAvailable) {
        $result = Remove-PiHoleInfoMessage -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -MessageId 999999 -Confirm:$false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Remove-PiHoleInfoMessage -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -MessageId 1 -Confirm:$false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
