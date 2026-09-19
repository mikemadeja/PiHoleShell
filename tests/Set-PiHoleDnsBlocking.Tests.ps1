# Requires -Module Pester
Describe 'Set-PiHoleDnsBlocking' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        # Request-PiHoleAuth and Format-PiHoleSecond are internal helpers that aren't exported, and
        # every one of these is called from code running inside the module, so all need -ModuleName
        # for the mock to actually intercept those internal calls.
        Mock -CommandName Request-PiHoleAuth -ModuleName PiHoleShell -MockWith { return 'mock-sid' }
        Mock -CommandName Remove-PiHoleCurrentAuthSession -ModuleName PiHoleShell
        Mock -CommandName Format-PiHoleSecond -ModuleName PiHoleShell -MockWith {
            return @{ TimeInSeconds = 60 }
        }
        Mock -CommandName Invoke-RestMethod -ModuleName PiHoleShell -MockWith {
            return @{
                blocking = 'false'
                timer    = 60
            }
        }

        # Sample input values
        $server = [uri]'http://pihole.local'
        $password = 'mock-password'
    }

    It 'should call Request-PiHoleAuth and send correct POST body' {
        Set-PiHoleDnsBlocking -PiHoleServer $server -Password $password -Blocking 'False' -TimeInSeconds 60 | Out-Null

        # Assert internal functions were called correctly
        Should -Invoke Request-PiHoleAuth -ModuleName PiHoleShell -Times 1 -Exactly -Scope It
        Should -Invoke Invoke-RestMethod -ModuleName PiHoleShell -Times 1 -Exactly -Scope It
        Should -Invoke Remove-PiHoleCurrentAuthSession -ModuleName PiHoleShell -Times 1 -Exactly -Scope It
    }

    It 'should return a formatted PSCustomObject if RawOutput is $false' {
        $result = Set-PiHoleDnsBlocking -PiHoleServer $server -Password $password -Blocking 'False' -TimeInSeconds 60

        $result.Blocking | Should -Be 'false'
        $result.TimeInSeconds | Should -Be 60
    }

    It 'should return raw response if RawOutput is $true' {
        $result = Set-PiHoleDnsBlocking -PiHoleServer $server -Password $password -Blocking 'False' -TimeInSeconds 60 -RawOutput $true

        $result.blocking | Should -Be 'false'
        $result.timer | Should -Be 60
    }

    It 'should handle errors and output them' {
        Mock -CommandName Invoke-RestMethod -ModuleName PiHoleShell -MockWith { throw "Test error" }

        Set-PiHoleDnsBlocking -PiHoleServer $server -Password $password -Blocking 'False' -TimeInSeconds 60 -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
        $errOut[0].Exception.Message | Should -Be 'Test error'
    }
}
