# Copy this file to 'IntegrationConfig.local.ps1' (same folder) and fill in your own
# server details. IntegrationConfig.local.ps1 is gitignored so your token is never committed.
#
# These values are consumed by the *.Integration.Tests.ps1 files, which make real calls
# against a live Pi-hole server.

$PiHoleServer = [uri]'https://pihole.example.com:8489'
$PiHoleToken = 'your-api-token-here'
$PiHoleIgnoreSsl = $true
