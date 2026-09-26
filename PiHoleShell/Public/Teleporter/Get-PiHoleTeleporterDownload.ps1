function Get-PiHoleTeleporterDownload {
    <#
.SYNOPSIS
Export Pi-hole settings

.DESCRIPTION
Downloads an archived copy of Pi-hole's current configuration (a Teleporter backup) to disk.
The API always returns a binary application/zip archive, not JSON, so there's no -RawOutput
option here - the downloaded file is the only output.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER FolderPath
The folder to save the backup file into. Must already exist

.PARAMETER FileName
The name to give the backup file, without an extension - ".zip" is appended automatically

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.EXAMPLE
Get-PiHoleTeleporterDownload -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -FolderPath "C:\Backups" -FileName "pihole-backup"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/teleporter')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$FolderPath,
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        [bool]$IgnoreSsl = $false
    )
    try {
        if (!(Test-Path -Path $FolderPath)) {
            throw "$FolderPath does not exist!"
        }
        $FileName = "$FileName.zip"
        $OutFile = "$FolderPath\$FileName"
        if (Test-Path -Path $OutFile) {
            throw "$OutFile already exists!"
        }

        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/teleporter"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            OutFile              = $OutFile
        }

        Invoke-RestMethod @Params

        $Object = [PSCustomObject]@{
            FileName   = $FileName
            FilePath   = $OutFile
            RootFolder = $FolderPath
            FileSizeKB = [math]::Ceiling((Get-Item $OutFile).Length / 1KB)
        }
        Write-Output $Object
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}
