# PiHoleShell

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/PiHoleShell?label=PowerShell%20Gallery)](https://www.powershellgallery.com/packages/PiHoleShell)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/PiHoleShell)](https://www.powershellgallery.com/packages/PiHoleShell)
[![CI](https://github.com/mikemadeja/PiHoleShell/actions/workflows/PSScriptAnalyzer.yml/badge.svg)](https://github.com/mikemadeja/PiHoleShell/actions/workflows/PSScriptAnalyzer.yml)
[![License: Apache 2.0](https://img.shields.io/github/license/mikemadeja/PiHoleShell)](LICENSE)
![PowerShell 7+](https://img.shields.io/badge/PowerShell-7%2B%20(Core)-blue)

A PowerShell module for automating and scripting against the **Pi-hole v6 REST API** — DNS blocking control, allow/deny lists, groups, stats, and server actions, all from PowerShell.

> This module targets Pi-hole's v6 API only. It will not work against Pi-hole v5 or earlier.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Getting an API Password](#getting-an-api-password)
- [Quick Start](#quick-start)
- [Command Reference](#command-reference)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## Features

- Enable/disable DNS blocking, optionally for a set duration
- Manage allow/deny lists and groups
- Trigger server actions: flush network table, restart DNS, update gravity
- Pull stats, summaries, and diagnostic info
- Every function authenticates and closes its own session automatically — no manual login/logout calls needed

## Requirements

- **PowerShell 7.0+ (Core edition)** — the module refuses to load on Windows PowerShell 5.1 or other editions
- A reachable Pi-hole v6 server and an API app password

## Installation

Install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/PiHoleShell):

```powershell
Install-Module -Name PiHoleShell -Scope CurrentUser
Import-Module -Name PiHoleShell
```

## Getting an API Password

1. Log into your Pi-hole web interface, then go to **Web Interface / API** settings and select **Configure app password**.

   <img src="https://raw.githubusercontent.com/mikemadeja/PiHoleShell/main/docs/images/webinterfance_api.png" alt="Pi-hole Web Interface / API settings" width="450"/>

2. Copy the generated password, then click **Enable new app password**.

   <img src="https://raw.githubusercontent.com/mikemadeja/PiHoleShell/main/docs/images/configure_app_password.png" alt="Configure app password dialog" width="450"/>

Keep this password secret — anyone with it has full API access to your Pi-hole.

## Quick Start

```powershell
$PiHoleServer = "https://pihole.example.com:8489"
$Password = "<your-app-password>"

# Check whether blocking is currently enabled
Get-PiHoleDnsBlockingStatus -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl:$true

# Disable blocking for 5 minutes, then it re-enables automatically
Set-PiHoleDnsBlocking -PiHoleServer $PiHoleServer -Password $Password -Blocking False -TimeInSeconds 300 -IgnoreSsl:$true
```

Every function accepts the same core parameters:

| Parameter | Description |
|---|---|
| `-PiHoleServer` | Base URL of your Pi-hole, e.g. `https://pihole.example.com:8489` |
| `-Password` | The app password from [Getting an API Password](#getting-an-api-password) |
| `-IgnoreSsl` | Skip TLS certificate validation (useful for self-signed certs) |
| `-RawOutput` | Return the unmodified API response instead of a formatted object |

## Command Reference

Functions marked 🚧 are still under active development — signatures and output shapes may change. This section is generated from the module's actual exported functions by `tools/Update-ReadmeCommandReference.ps1`, and kept in sync automatically on every `develop` → `main` pull request — don't hand-edit the block below.

<!-- COMMAND-REFERENCE:START -->
### Actions

| Function | Description |
|---|---|
| `Invoke-PiHoleFlushNetwork` | Flushes the network table. This includes removing both all known devices and their associated addresses. |
| `Restart-PiHoleDnsService` | Restarts the pihole-FTL service |
| `Update-PiHoleActionsGravity` | Update Pi-hole's adlists by running pihole -g |

### DNS Control

| Function | Description |
|---|---|
| `Get-PiHoleDnsBlockingStatus` | _No description yet_ |
| `Set-PiHoleDnsBlocking` | _No description yet_ |

### Group Management

| Function | Description |
|---|---|
| `Get-PiHoleGroup` | Get groups |
| `New-PiHoleGroup` | Creates a new group in the groups object. |
| `Remove-PiHoleGroup` 🚧 | Delete group |
| `Update-PiHoleGroup` | Items may be updated by replacing them. |

### List Management

| Function | Description |
|---|---|
| `Add-PiHoleList` 🚧 | Add new list |
| `Get-PiHoleList` 🚧 | Get lists |
| `Remove-PiHoleList` 🚧 | Deletes multiple lists in the lists object. |
| `Search-PiHoleListDomain` | _No description yet_ |

### Metrics

| Function | Description |
|---|---|
| `Get-PiHoleStatsDatabaseQueryType` | Get query types (long-term database) |
| `Get-PiHoleStatsDatabaseSummary` | Get database content details |
| `Get-PiHoleStatsDatabaseTopClient` | Get top clients (long-term database) |
| `Get-PiHoleStatsDatabaseTopDomain` | Get top domains (long-term database) |
| `Get-PiHoleStatsDatabaseUpstream` | Get metrics about Pi-hole's upstream destinations (long-term database) |
| `Get-PiHoleStatsQuerySuggestions` | Get query filter suggestions |
| `Get-PiHoleStatsQueryType` | Get query types Request a breakdown of query types (A, AAAA, ...) |
| `Get-PiHoleStatsRecentBlocked` | Request most recently blocked domain |
| `Get-PiHoleStatsSummary` | Get overview of Pi-hole activity Request various query, system, and FTL properties |
| `Get-PiHoleStatsTopClient` | Get top clients Request the top clients (by query count) |
| `Get-PiHoleStatsTopDomain` | Get top domains Request the top domains (by query count) |
| `Get-PiHoleStatsUpstream` | Get metrics about Pi-hole's upstream destinations |

### Configuration & Diagnostics

| Function | Description |
|---|---|
| `Get-PiHoleConfig` | Get current configuration of Pi-hole |
| `Get-PiHoleInfoHost` | Get information about the host system |
| `Get-PiHoleInfoMessage` | Get Pi-hole diagnosis messages Request Pi-hole diagnosis messages |
| `Get-PiHolePadd` | Get summarized data for PADD |

### Authentication

Session handling is automatic for every command above, but these are available for managing sessions directly:

| Function | Description |
|---|---|
| `Get-PiHoleCurrentAuthSession` | List of all current sessions including their validity and further information about the client such as the IP address and user agent. |
| `Remove-PiHoleAuthSession` | Using this endpoint, a session can be deleted by its ID. |
<!-- COMMAND-REFERENCE:END -->

## Testing

The module ships with two kinds of [Pester](https://pester.dev/) tests under `tests/`:

- **Unit tests** (`*.Tests.ps1`) mock the API and run anywhere:

  ```powershell
  Invoke-Pester -Path .\tests -ExcludeTagFilter Integration
  ```

- **Integration tests** (`*.Integration.Tests.ps1`) run against a real Pi-hole server and are skipped automatically unless configured. To run them, copy `tests/IntegrationConfig.example.ps1` to `tests/IntegrationConfig.local.ps1` (gitignored) and fill in your server URL and app password, then run:

  ```powershell
  Invoke-Pester -Path .\tests -TagFilter Integration
  ```

  These make real changes on the target server (they flush the network table, restart DNS, and rebuild gravity) — point them at a test instance, not production, if you'd rather not disrupt it.

## Contributing

This project is still early and growing. Issues, suggestions, and pull requests are welcome — see the 🚧 items in the [Command Reference](#command-reference) above for functions that could use testing or polish.

## License

[Apache License 2.0](LICENSE)
