#Requires -Module Pester

Describe 'Set-PiHoleDnsBlocking' {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\..\PiHoleShell\PiHoleShell.psm1" -Force

        $script:server   = [uri]$env:PIHOLE_SERVER
        $script:password = $env:PIHOLE_PASSWORD

        if (-not $script:server -or -not $script:password) {
            throw 'PIHOLE_SERVER and PIHOLE_PASSWORD environment variables must be set for integration tests'
        }

        $initial = Get-PiHoleDnsBlockingStatus -PiHoleServer $script:server -Password $script:password
        $script:originalBlocking = $initial[0].Blocking
    }

    AfterAll {
        $restoreValue = if ($script:originalBlocking -eq 'true') { 'True' } else { 'False' }
        Set-PiHoleDnsBlocking -PiHoleServer $script:server -Password $script:password -Blocking $restoreValue | Out-Null
    }

    It 'disables DNS blocking' {
        $result = Set-PiHoleDnsBlocking -PiHoleServer $script:server -Password $script:password -Blocking 'False'
        $result.Blocking | Should -Be 'false'
    }

    It 'enables DNS blocking' {
        $result = Set-PiHoleDnsBlocking -PiHoleServer $script:server -Password $script:password -Blocking 'True'
        $result.Blocking | Should -Be 'true'
    }

    It 'disables DNS blocking with a timer' {
        $result = Set-PiHoleDnsBlocking -PiHoleServer $script:server -Password $script:password -Blocking 'False' -TimeInSeconds 30
        $result.Blocking | Should -Be 'false'
        $result.TimeInSeconds | Should -Be 30
    }
}
