Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

function New-SendToShortcut {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ShortcutPath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.Arguments = $Arguments
    $shortcut.WorkingDirectory = $WorkingDirectory
    $shortcut.Description = $Description
    $shortcut.IconLocation = $script:shortcutIconPath
    $shortcut.Save()
}

function New-RoeversionIcon {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IconPath
    )

    $bitmap = New-Object System.Drawing.Bitmap 64, 64
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(110, 255, 110), 5.0)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    try {
        $graphics.DrawLine($pen, 10, 18, 40, 18)
        $graphics.DrawLine($pen, 32, 10, 40, 18)
        $graphics.DrawLine($pen, 32, 26, 40, 18)

        $graphics.DrawLine($pen, 54, 46, 24, 46)
        $graphics.DrawLine($pen, 32, 38, 24, 46)
        $graphics.DrawLine($pen, 32, 54, 24, 46)

        $pngStream = New-Object System.IO.MemoryStream
        $bitmap.Save($pngStream, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngBytes = $pngStream.ToArray()
        $pngStream.Dispose()

        $fileStream = [System.IO.File]::Create($IconPath)
        $writer = New-Object System.IO.BinaryWriter($fileStream)

        try {
            $writer.Write([UInt16]0)
            $writer.Write([UInt16]1)
            $writer.Write([UInt16]1)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([UInt16]1)
            $writer.Write([UInt16]32)
            $writer.Write([UInt32]$pngBytes.Length)
            $writer.Write([UInt32]22)
            $writer.Write($pngBytes)
        }
        finally {
            $writer.Dispose()
            $fileStream.Dispose()
        }
    }
    finally {
        $pen.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcherScript = Join-Path -Path $scriptRoot -ChildPath 'Launch-SendToFFmpeg.ps1'
$launcherWrapper = Join-Path -Path $scriptRoot -ChildPath 'Launch-SendToFFmpeg.vbs'
$script:shortcutIconPath = Join-Path -Path $scriptRoot -ChildPath 'roeversion.ico'
$sendToFolder = Join-Path -Path $env:APPDATA -ChildPath 'Microsoft\Windows\SendTo'
$wscriptExe = Join-Path -Path $env:WINDIR -ChildPath 'System32\wscript.exe'

if (-not (Test-Path -LiteralPath $sendToFolder)) {
    throw "SendTo folder not found: $sendToFolder"
}

New-RoeversionIcon -IconPath $script:shortcutIconPath

$obsoleteShortcuts = @(
    'FFmpeg Convert....lnk',
    'FFmpeg Convert Menu.lnk',
    'FFmpeg to MP3.lnk',
    'FFmpeg to OGG.lnk',
    'FFmpeg to GIF.lnk',
    'FFmpeg to MP4.lnk',
    '! roeversion.lnk',
    'roeversion.lnk'
)

foreach ($obsoleteShortcut in $obsoleteShortcuts) {
    $obsoletePath = Join-Path -Path $sendToFolder -ChildPath $obsoleteShortcut
    if (Test-Path -LiteralPath $obsoletePath) {
        Remove-Item -LiteralPath $obsoletePath -Force
    }
}

$shortcutPath = Join-Path -Path $sendToFolder -ChildPath 'roeversion.lnk'
New-SendToShortcut `
    -ShortcutPath $shortcutPath `
    -TargetPath $wscriptExe `
    -Arguments "`"$launcherWrapper`"" `
    -WorkingDirectory $scriptRoot `
    -Description 'Open the roeversion conversion picker for selected files.'

Write-Host "Installed $shortcutPath"
Write-Host ''
Write-Host 'SendTo shortcut installed.'
Write-Host 'If ffmpeg is not on PATH, set FFMPEG_PATH to the full path of ffmpeg.exe.'
