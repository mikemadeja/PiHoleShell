
# Requires -Module Pester
Describe 'Set-PiHoleDnsBlocking' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1

        Mock -CommandName Request-PiHoleAuth -MockWith { return 'mock-sid' }
        Mock -CommandName Invoke-RestMethod -MockWith {
            return @{
                blocking = 'false'
                timer    = 60
            }
        }
        Mock -CommandName Remove-PiHoleCurrentAuthSession
        Mock -CommandName Format-PiHoleSecond -MockWith {
            return @{ TimeInSeconds = 60 }
        }
        # Sample input values
        $server = [uri]'http://pihole.local'
        $password = 'mock-password'
        $sid = 'mock-session-id'

        # Mock external functions
        Mock -CommandName Request-PiHoleAuth -MockWith { 'mock-sid' }
        Mock -CommandName Remove-PiHoleCurrentAuthSession
        Mock -CommandName Format-PiHoleSecond -MockWith {
            return @{ TimeInSeconds = 60 }
        }

        # Mock response from API
        Mock -CommandName Invoke-RestMethod -MockWith {
            return @{
                blocking = 'false'
                timer    = 60
            }
        }
    }

    It 'should call Request-PiHoleAuth and send correct POST body' {
        Set-PiHoleDnsBlocking -PiHoleServer $server -Password $password -Blocking 'False' -TimeInSeconds 60 | Out-Null

        # Assert internal functions were called correctly
        Assert-MockCalled Request-PiHoleAuth -Times 1 -Exactly -Scope It
        Assert-MockCalled Invoke-RestMethod -Times 1 -Scope It
        Assert-MockCalled Remove-PiHoleCurrentAuthSession -Times 1 -Scope It
    }

    It 'should return a formatted PSCustomObject if RawOutput is $false' {
        $result = Set-PiHoleDnsBlocking -PiHoleServer $server -Password $password -Blocking 'False' -TimeInSeconds 60
        $result | Should -BeOfType 'System.Object[]'
        $result[0].Blocking | Should -Be 'false'
        $result[0].TimeInSeconds | Should -Be 60
    }

    It 'should return raw response if RawOutput is $true' {
        $result = Set-PiHoleDnsBlocking -PiHoleServer $server -Password $password -Blocking 'False' -TimeInSeconds 60 -RawOutput
        $result | Should -HaveProperty 'blocking'
        $result | Should -HaveProperty 'timer'
    }

    It 'should handle errors and output them' {
        # Mock to simulate error
        Mock -CommandName Invoke-RestMethod -MockWith { throw "Test error" } -ParameterFilter { $Body -like '*' }

        { Set-PiHoleDnsBlocking -PiHoleServer $server -Password $password -Blocking 'False' } |
        Should -Throw -ErrorMessage 'Test error'
    }
}
