# Requires -Module Pester
Describe 'Invoke-PiHoleApiRequest' {
    BeforeAll {
        # Dot-sourced directly with the real login (Request-PiHoleAuth) and logout
        # (Remove-PiHoleCurrentAuthSession, in Misc.ps1), so only the HTTP layer is mocked and the
        # tests see the actual order of login, request and logout.
        . .\PiHoleShell\Private\Invoke-PiHoleApiRequest.ps1
        . .\PiHoleShell\Private\Misc.ps1
        . .\PiHoleShell\Public\Authentication\Request-PiHoleAuth.ps1

        $server = [uri]'http://pihole.local'
    }

    BeforeEach {
        # Every HTTP call is recorded as "<Method> <path> sid=<sid>", in the order it was made.
        $script:Calls = [System.Collections.Generic.List[string]]::new()
        $script:LoginFails = $false
        $script:RequestFails = $false

        Mock -CommandName Invoke-RestMethod -MockWith {
            $path = ([string]$Uri) -replace '^http://pihole\.local/api/', ''
            $script:Calls.Add("$Method $path sid=$($Headers.sid)")

            if ($path -eq 'auth' -and $Method -eq 'Post') {
                if ($script:LoginFails) { throw 'Unauthorized' }
                return @{ session = @{ sid = 'test-sid' } }
            }
            if ($path -eq 'auth') {
                return
            }
            if ($script:RequestFails) { throw 'Request failed' }
            return @{ version = 'v6' }
        }
    }

    It 'logs in, sends the request with that session, then logs out - in that order' {
        $result = Invoke-PiHoleApiRequest -PiHoleServer $server -Password 'pw' -Endpoint 'info/version'

        $result.version | Should -Be 'v6'
        $script:Calls | Should -Be @(
            'Post auth sid='
            'Get info/version sid=test-sid'
            'Delete auth sid=test-sid'
        )
    }

    It 'still logs out when the request fails, and passes the error on' {
        $script:RequestFails = $true

        { Invoke-PiHoleApiRequest -PiHoleServer $server -Password 'pw' -Endpoint 'info/version' } | Should -Throw 'Request failed'

        $script:Calls | Should -Be @(
            'Post auth sid='
            'Get info/version sid=test-sid'
            'Delete auth sid=test-sid'
        )
    }

    It 'stops after a failed login, without sending the request or a logout' {
        $script:LoginFails = $true

        { Invoke-PiHoleApiRequest -PiHoleServer $server -Password 'wrong' -Endpoint 'info/version' } | Should -Throw 'Unauthorized'

        $script:Calls | Should -Be @('Post auth sid=')
    }

    It 'passes Method and Body through, and leaves ContentType off a Form upload' {
        Invoke-PiHoleApiRequest -PiHoleServer $server -Password 'pw' -Endpoint 'groups' -Method 'Post' -Body '{"name":"g"}' | Out-Null
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Post' -and $Body -eq '{"name":"g"}' -and $ContentType -eq 'application/json'
        }

        Invoke-PiHoleApiRequest -PiHoleServer $server -Password 'pw' -Endpoint 'teleporter' -Method 'Post' -Form @{ file = 'x' } | Out-Null
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Form.file -eq 'x' -and -not $ContentType
        }
    }
}
