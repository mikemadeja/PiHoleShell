# Requires -Module Pester
Describe 'PiHoleShell module' {
    BeforeAll {
        $script:ModulePath = Resolve-Path (Join-Path $PSScriptRoot '..\PiHoleShell\PiHoleShell.psm1')
        $script:PublicPath = Resolve-Path (Join-Path $PSScriptRoot '..\PiHoleShell\Public')
        $script:PrivatePath = Resolve-Path (Join-Path $PSScriptRoot '..\PiHoleShell\Private')
    }

    It 'imports without error' {
        { Import-Module $script:ModulePath -Force } | Should -Not -Throw
    }

    It 'exports at least one function' {
        Import-Module $script:ModulePath -Force
        (Get-Module PiHoleShell).ExportedFunctions.Count | Should -BeGreaterThan 0
    }

    It 'has no duplicate names in the exported function list' {
        Import-Module $script:ModulePath -Force
        $names = (Get-Module PiHoleShell).ExportedFunctions.Keys
        ($names | Group-Object | Where-Object Count -gt 1).Count | Should -Be 0
    }

    It 'resolves every exported function name to a real, loadable command' {
        Import-Module $script:ModulePath -Force
        $names = (Get-Module PiHoleShell).ExportedFunctions.Keys

        foreach ($name in $names) {
            $command = Get-Command -Name $name -Module PiHoleShell -ErrorAction SilentlyContinue
            $command | Should -Not -BeNullOrEmpty -Because "exported function '$name' should be a real, loadable command (catches a typo in PiHoleShell.psm1's export list)"
        }
    }

    It 'exports every Public function, except ones explicitly marked internal or work-in-progress' {
        Import-Module $script:ModulePath -Force
        $exported = (Get-Module PiHoleShell).ExportedFunctions.Keys

        $publicFiles = Get-ChildItem -Path $script:PublicPath -Filter '*.ps1' -Recurse
        foreach ($file in $publicFiles) {
            $content = Get-Content -Path $file.FullName -Raw
            if ($content -match '#\s*INTERNAL FUNCTION' -or $content -match '#\s*Work In Progress') {
                continue
            }

            $exported | Should -Contain $file.BaseName -Because "$($file.Name) defines a public function that should be exported from PiHoleShell.psm1"
        }
    }

    It 'does not export a function with no matching definition under Public or Private' {
        Import-Module $script:ModulePath -Force
        $exported = (Get-Module PiHoleShell).ExportedFunctions.Keys

        # Matched by content (function <name>) rather than file name: most Public files define
        # exactly one same-named function, but Private/Misc.ps1 defines several per file (e.g.
        # Remove-PiHoleCurrentAuthSession, which is still deliberately exported).
        $allSource = Get-ChildItem -Path $script:PublicPath, $script:PrivatePath -Filter '*.ps1' -Recurse |
            Get-Content -Raw |
            Out-String

        foreach ($name in $exported) {
            $allSource | Should -Match "function\s+$name\b" -Because "exported function '$name' should have a matching definition under PiHoleShell/Public or PiHoleShell/Private (catches a stale export left behind after a rename/delete)"
        }
    }
}
