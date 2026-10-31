# Security Policy

## Supported versions

Only the latest release on the [PowerShell Gallery](https://www.powershellgallery.com/packages/PiHoleShell) gets security fixes. Update with `Update-Module PiHoleShell` before reporting.

## Reporting a vulnerability

**Please don't open a public issue for security problems.**

Report them privately through GitHub: open the repository's [Security tab](https://github.com/mikemadeja/PiHoleShell/security) and click **Report a vulnerability**. Only the maintainer can see the report.

Please include:

- what the problem is and what someone could do with it
- steps to reproduce, with your PiHoleShell, PowerShell and Pi-hole versions
- any fix you'd suggest

Never include a real password, app password or session ID.

This is a spare-time project, so there's no guaranteed response time, but security reports are dealt with first. Once a fix is released, the report can be published with credit to you, if you'd like.

## Scope

This policy covers the PiHoleShell module itself, for example leaking credentials or session IDs, or sending them somewhere they shouldn't go. Vulnerabilities in Pi-hole itself should go to the [Pi-hole project](https://github.com/pi-hole/pi-hole/security).

Note that `-IgnoreSsl $true` turns off certificate checking on purpose, for servers with self-signed certificates. That's not a vulnerability, but avoid it on networks you don't trust.
