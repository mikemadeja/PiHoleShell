if (-not $PSVersionTable -or $PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "This script requires PowerShell 7 or higher. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

# Import all the commands
Get-ChildItem $PSScriptRoot\functions\*.ps1 -Recurse | ForEach-Object { . $_.FullName }