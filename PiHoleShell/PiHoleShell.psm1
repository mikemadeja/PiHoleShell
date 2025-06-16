if ($PSVersionTable.PSEdition -ne 'Core') {
    throw "PiHoleShell module only supports PowerShell Core 7+. You are using $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)."
}

# Get all .ps1 files in the 'Public' directory and dot-source them
$PublicFunctions = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File

foreach ($File in $PublicFunctions) {
    . $File.FullName
}