if ($PSVersionTable.PSEdition -ne 'Core') {
    throw "PiHoleShell module only supports PowerShell Core 7+. You are using $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)."
}

Get-ChildItem $PSScriptRoot\Private\*.ps1 -Recurse | ForEach-Object { . $_.FullName }
Get-ChildItem $PSScriptRoot\Public\*.ps1 -Recurse | ForEach-Object { . $_.FullName }