#Requires -Version 5.0

# Import all the commands
Get-ChildItem $PSScriptRoot\functions\*.ps1 -Recurse | ForEach-Object { . $_.FullName }