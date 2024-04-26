# PiHoleShell
A PowerShell module for PiHole v6 API.

## Installation

It is recommended to pull this down as a git and pull down updates from main as this is activly developed before it becomes released

To import this module, you can do ```Import-Module .\PiHoleShell.psm1``` in the directory of PiHoleShell

To remove the module, you can do ```Remove-Module PiHoleShell```

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
PS CD D:\PiHoleShell

PS Import-Module .\PiHoleShell.psm1

PS D:\PiHoleShell> Get-PiHoleDnsBlockingStatus -PiHoleServer http://PIHOLESERVER.DOMAIN.COM -Password "APPPASSWORD"


Blocking Timer
-------- -----
enabled      0
```
