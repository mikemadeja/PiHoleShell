function Get-PiHoleTeleporterDownload {
    <#
.SYNOPSIS
Download a Pi-hole teleporter backup archive.

.DESCRIPTION
Downloads a Pi-hole configuration backup (teleporter) as a .tar.gz file to the specified folder.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER FolderPath
The local folder path where the backup file will be saved

.PARAMETER FileName
The base name of the output file. The .tar.gz extension will be appended automatically.

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleTeleporterDownload -PiHoleServer "http://pihole.domain.com:8080" -Password "P@$$W0RD" -FolderPath "C:\Backups" -FileName "pihole-backup"
    #>
    #Work In Progress
    [CmdletBinding()]
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
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        if (!(Test-Path -Path $FolderPath)) {
            throw "$FolderPath does not exist!"
        }
        $FileName = "$FileName.tar.gz"
        $OutFile = "$FolderPath\$FileName"
        if (Test-Path -Path $OutFile) {
            throw "$OutFile already exists!"
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/teleporter"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params -OutFile $OutFile

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $ObjectFinal = @()
            $Object = [PSCustomObject]@{
                FileName   = $FileName
                FilePath   = $OutFile
                RootFolder = $FolderPath
                FileSizeKB = [math]::Ceiling((Get-Item $OutFile).Length / 1KB)
            }
            $ObjectFinal += $Object
            Write-Output $ObjectFinal
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
        break
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}