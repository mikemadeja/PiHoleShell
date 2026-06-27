# PiHoleShell
A PowerShell module for PiHole v6 API.

## Installation

It is recommended to install this from https://www.powershellgallery.com/packages/PiHoleShell

## Contributions

I am in the beginning stages of developing this. I am open to suggestions or contributors and am learning as I go. I hope this will bring some value to people :-).

## How to use

Generate an app password by logging into your PiHole server. 

Click Web Interface / Api

Click Configure app password

<img src="docs\images\webinterfance_api.png" alt="drawing" width="450"/>

Copy your password, then click Enable new app password.

<img src="docs\images\configure_app_password.png" alt="drawing" width="450"/>

```
PS Install-Module -Name PiHoleShell
PS Import-Module -Name PiHoleShell
PS Get-PiHoleDnsBlockingStatus -PiHoleServer http://PIHOLESERVER.DOMAIN.COM -Password "APPPASSWORD" -IgnoreSsl:$true

Blocking Timer
-------- -----
enabled      0
```