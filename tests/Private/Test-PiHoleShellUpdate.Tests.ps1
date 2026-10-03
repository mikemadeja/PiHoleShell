# Requires -Module Pester
Describe 'Test-PiHoleShellUpdate' {
    BeforeAll {
        # Dot-sourced directly rather than through the full module: this is a self-contained
        # private helper with no Pi-hole server dependency, so testing it in isolation avoids
        # mocking through -ModuleName for a function that never calls anything module-internal.
        . .\PiHoleShell\Private\Test-PiHoleShellUpdate.ps1

        $testCachePath = Join-Path $TestDrive 'update-check.json'
    }

    BeforeEach {
        if (Test-Path $testCachePath) { Remove-Item $testCachePath -Force }
        Remove-Item Env:\PIHOLESHELL_SKIP_UPDATE_CHECK -ErrorAction SilentlyContinue
        Mock -CommandName Invoke-RestMethod -MockWith { return @{ tag_name = 'v1.2.3' } }
    }

    It 'does not check or warn for a dev-checkout version (0.0, from importing the .psm1 directly)' {
        Test-PiHoleShellUpdate -CurrentVersion ([version]'0.0') -CacheFilePath $testCachePath -WarningVariable warnOut -WarningAction SilentlyContinue

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
        $warnOut | Should -BeNullOrEmpty
        Test-Path $testCachePath | Should -BeFalse
    }

    It 'does not check or warn for a dev-checkout version (0.0.0, the manifest placeholder)' {
        Test-PiHoleShellUpdate -CurrentVersion ([version]'0.0.0') -CacheFilePath $testCachePath -WarningVariable warnOut -WarningAction SilentlyContinue

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
        $warnOut | Should -BeNullOrEmpty
    }

    It 'does not check or warn when the opt-out environment variable is set' {
        $env:PIHOLESHELL_SKIP_UPDATE_CHECK = '1'
        Test-PiHoleShellUpdate -CurrentVersion ([version]'0.0.1') -CacheFilePath $testCachePath -WarningVariable warnOut -WarningAction SilentlyContinue

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
        $warnOut | Should -BeNullOrEmpty
    }

    It 'warns and caches the result when a newer version is available' {
        Test-PiHoleShellUpdate -CurrentVersion ([version]'1.0.0') -CacheFilePath $testCachePath -WarningVariable warnOut -WarningAction SilentlyContinue

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly
        $warnOut | Should -Not -BeNullOrEmpty
        $warnOut[0] | Should -Match '1\.2\.3'
        $warnOut[0] | Should -Match '1\.0\.0'

        $cache = Get-Content $testCachePath -Raw | ConvertFrom-Json
        $cache.LatestVersion | Should -Be '1.2.3'
    }

    It 'does not warn when the current version is already the latest or newer' {
        Test-PiHoleShellUpdate -CurrentVersion ([version]'1.2.3') -CacheFilePath $testCachePath -WarningVariable warnOut -WarningAction SilentlyContinue
        $warnOut | Should -BeNullOrEmpty

        Test-PiHoleShellUpdate -CurrentVersion ([version]'2.0.0') -CacheFilePath $testCachePath -WarningVariable warnOut2 -WarningAction SilentlyContinue
        $warnOut2 | Should -BeNullOrEmpty
    }

    It 'reuses the cached result instead of calling the API again within the check interval' {
        Test-PiHoleShellUpdate -CurrentVersion ([version]'1.0.0') -CacheFilePath $testCachePath -WarningAction SilentlyContinue
        Test-PiHoleShellUpdate -CurrentVersion ([version]'1.0.0') -CacheFilePath $testCachePath -WarningVariable warnOut -WarningAction SilentlyContinue

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly
        $warnOut | Should -Not -BeNullOrEmpty
    }

    It 'calls the API again once the cached result has expired' {
        Test-PiHoleShellUpdate -CurrentVersion ([version]'1.0.0') -CacheFilePath $testCachePath -WarningAction SilentlyContinue

        $cache = Get-Content $testCachePath -Raw | ConvertFrom-Json
        $cache.LastChecked = (Get-Date).AddHours(-25).ToString('o')
        $cache | ConvertTo-Json | Set-Content $testCachePath

        Test-PiHoleShellUpdate -CurrentVersion ([version]'1.0.0') -CacheFilePath $testCachePath -CheckIntervalHours 24 -WarningAction SilentlyContinue

        Should -Invoke Invoke-RestMethod -Times 2 -Exactly
    }

    It 'never throws when the API call fails' {
        Mock -CommandName Invoke-RestMethod -MockWith { throw 'network error' }

        { Test-PiHoleShellUpdate -CurrentVersion ([version]'1.0.0') -CacheFilePath $testCachePath -WarningAction SilentlyContinue } | Should -Not -Throw
    }
}
