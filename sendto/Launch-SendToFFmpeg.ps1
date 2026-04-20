param(
    [string]$Preset,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$InputPaths
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Preset -and @('mp3', 'ogg', 'wav', 'flac', 'mp4', 'webm', 'gif') -notcontains $Preset) {
    if (-not $InputPaths) {
        $InputPaths = @()
    }
    $InputPaths = @($Preset) + $InputPaths
    $Preset = $null
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$converterScript = Join-Path -Path $scriptRoot -ChildPath 'Convert-WithFFmpeg.ps1'
$presetDescriptions = [ordered]@{
    mp3  = 'Convert to MP3 audio'
    ogg  = 'Convert to OGG audio'
    wav  = 'Convert to WAV audio'
    flac = 'Convert to FLAC audio'
    mp4  = 'Convert to MP4 video'
    webm = 'Convert to WebM video'
    gif  = 'Convert video to GIF'
}

$audioExtensions = @('.mp3', '.ogg', '.wav', '.flac', '.m4a', '.aac', '.wma', '.opus')
$videoExtensions = @('.mp4', '.m4v', '.mov', '.mkv', '.avi', '.wmv', '.webm', '.flv', '.mpeg', '.mpg', '.ts', '.m2ts', '.gif')

if (-not $InputPaths -or $InputPaths.Count -eq 0) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        'This tool expects one or more files from Explorer''s Send to menu.',
        'FFmpeg SendTo',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
    exit 1
}

function Get-SelectionProfile {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    $allowedTargets = $null
    $typeLabels = New-Object System.Collections.Generic.HashSet[string]
    $unsupportedPaths = New-Object System.Collections.Generic.List[string]
    $extensionToPreset = @{
        '.mp3'  = 'mp3'
        '.ogg'  = 'ogg'
        '.wav'  = 'wav'
        '.flac' = 'flac'
        '.mp4'  = 'mp4'
        '.webm' = 'webm'
        '.gif'  = 'gif'
    }

    foreach ($path in $Paths) {
        $extension = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
        $sameFormatPreset = $extensionToPreset[$extension]
        $probe = Get-MediaCapabilities -Path $path

        if (-not $probe.IsSupported) {
            $currentTargets = @()
            [void]$typeLabels.Add('unsupported')
            [void]$unsupportedPaths.Add($path)
        }
        elseif ($probe.HasVideo -and $probe.HasAudio) {
            $currentTargets = @('mp3', 'ogg', 'wav', 'flac', 'mp4', 'webm', 'gif')
            [void]$typeLabels.Add('video')
        }
        elseif ($probe.HasVideo) {
            $currentTargets = @('mp4', 'webm', 'gif')
            [void]$typeLabels.Add('video')
        }
        elseif ($probe.HasAudio) {
            $currentTargets = @('mp3', 'ogg', 'wav', 'flac')
            [void]$typeLabels.Add('audio')
        }
        else {
            $currentTargets = @()
            [void]$typeLabels.Add('unsupported')
            [void]$unsupportedPaths.Add($path)
        }

        if ($sameFormatPreset) {
            $currentTargets = @($currentTargets | Where-Object { $_ -ne $sameFormatPreset })
        }

        if ($null -eq $allowedTargets) {
            $allowedTargets = @($currentTargets)
            continue
        }

        $allowedTargets = @($allowedTargets | Where-Object { $currentTargets -contains $_ })
    }

    if ($unsupportedPaths.Count -gt 0) {
        return @{
            AllowedTargets = @()
            Summary = 'unsupported'
            UnsupportedPaths = @($unsupportedPaths)
        }
    }

    if (-not $allowedTargets -or $allowedTargets.Count -eq 0) {
        return @{
            AllowedTargets = @()
            Summary = (@($typeLabels) | Sort-Object) -join ', '
            UnsupportedPaths = @()
        }
    }

    return @{
        AllowedTargets = $allowedTargets
        Summary = (@($typeLabels) | Sort-Object) -join ', '
        UnsupportedPaths = @()
    }
}

function Get-MediaCapabilities {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    if ($audioExtensions -notcontains $extension -and $videoExtensions -notcontains $extension) {
        return @{
            IsSupported = $false
            HasAudio = $false
            HasVideo = $false
        }
    }

    $ffprobeCommand = Get-Command ffprobe -ErrorAction SilentlyContinue
    if (-not $ffprobeCommand) {
        return @{
            IsSupported = $audioExtensions -contains $extension -or $videoExtensions -contains $extension
            HasAudio = $audioExtensions -contains $extension
            HasVideo = $videoExtensions -contains $extension
        }
    }

    try {
        $probeJson = & $ffprobeCommand.Source -v error -show_streams -of json --% $Path | Out-String
        if ([string]::IsNullOrWhiteSpace($probeJson)) {
            throw 'ffprobe returned no data.'
        }

        $probe = $probeJson | ConvertFrom-Json
        $streams = @($probe.streams)
        $hasAudio = $false
        $hasVideo = $false

        foreach ($stream in $streams) {
            if ($stream.codec_type -eq 'audio') {
                $hasAudio = $true
            }
            elseif ($stream.codec_type -eq 'video') {
                $hasVideo = $true
            }
        }

        return @{
            IsSupported = ($hasAudio -or $hasVideo)
            HasAudio = $hasAudio
            HasVideo = $hasVideo
        }
    }
    catch {
        return @{
            IsSupported = $audioExtensions -contains $extension -or $videoExtensions -contains $extension
            HasAudio = $audioExtensions -contains $extension
            HasVideo = $videoExtensions -contains $extension
        }
    }
}

function Get-OptionTextBounds {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.ListBox]$ListBox,

        [Parameter(Mandatory = $true)]
        [int]$Index,

        [Parameter(Mandatory = $true)]
        [System.Drawing.Rectangle]$ItemBounds
    )

    $text = [string]$ListBox.Items[$Index]
    $flags = [System.Windows.Forms.TextFormatFlags]::NoPadding -bor `
        [System.Windows.Forms.TextFormatFlags]::SingleLine -bor `
        [System.Windows.Forms.TextFormatFlags]::NoPrefix
    $textSize = [System.Windows.Forms.TextRenderer]::MeasureText($text, $ListBox.Font, [System.Drawing.Size]::Empty, $flags)
    $textX = $ItemBounds.Left + 24

    return New-Object System.Drawing.Rectangle($textX, $ItemBounds.Top, $textSize.Width, $ItemBounds.Height)
}

if (-not $Preset) {
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class RoeversionNative {
    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern IntPtr CreateRoundRectRgn(
        int nLeftRect,
        int nTopRect,
        int nRightRect,
        int nBottomRect,
        int nWidthEllipse,
        int nHeightEllipse
    );

    [DllImport("user32.dll")]
    public static extern bool ReleaseCapture();

    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
}
"@

$profile = Get-SelectionProfile -Paths $InputPaths

if (-not $profile.AllowedTargets -or $profile.AllowedTargets.Count -eq 0) {
    $unsupportedNames = @($profile.UnsupportedPaths | ForEach-Object { [System.IO.Path]::GetFileName($_) })
    $message = if ($unsupportedNames.Count -gt 0) {
        "roeversion only supports audio and video inputs. Unsupported file(s): " + ($unsupportedNames -join ', ')
    }
    else {
        'No compatible conversions are available for the selected file(s).'
    }

    [System.Windows.Forms.MessageBox]::Show(
        $message,
        'roeversion',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
    exit 1
}

$form = New-Object System.Windows.Forms.Form
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(220, 126)
$form.FormBorderStyle = 'None'
$form.ControlBox = $false
$form.ShowIcon = $false
$form.ShowInTaskbar = $false
$form.KeyPreview = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font('EB Garamond', 10)
$form.TopMost = $true
$dragOrigin = $null
$suppressNextSelectionChange = $false
$lastSelectedIndex = -1
$optionHitBoxes = @{}
$dragWindow = {
    [void][RoeversionNative]::ReleaseCapture()
    [void][RoeversionNative]::SendMessage($form.Handle, 0xA1, 0x2, 0)
}
$form.Add_Shown({
    $regionHandle = [RoeversionNative]::CreateRoundRectRgn(0, 0, $form.Width + 1, $form.Height + 1, 18, 18)
    $form.Region = [System.Drawing.Region]::FromHrgn($regionHandle)
})
$form.Add_MouseDown({
    param($sender, $eventArgs)
    if ($eventArgs.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        & $dragWindow
    }
})

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(18, 18)
$listBox.Size = New-Object System.Drawing.Size(170, 86)
$listBox.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
$listBox.ItemHeight = 30
$listBox.BorderStyle = 'None'
$listBox.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
$listBox.ForeColor = [System.Drawing.Color]::White
$listBox.Font = New-Object System.Drawing.Font('EB Garamond', 15, [System.Drawing.FontStyle]::Regular)
$listBox.IntegralHeight = $true
$listBox.ScrollAlwaysVisible = $false
foreach ($presetName in $profile.AllowedTargets) {
    [void]$listBox.Items.Add($presetName.ToUpperInvariant())
}
$listBox.Height = ($listBox.ItemHeight * $listBox.Items.Count) + 4
$listBox.SelectedIndex = 0
$lastSelectedIndex = $listBox.SelectedIndex
$listBox.Add_DrawItem({
    param($sender, $e)

    if ($e.Index -lt 0 -or $e.Index -ge $sender.Items.Count) {
        return
    }

    $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(10, 10, 10))), $e.Bounds)

    $isSelected = ($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -ne 0
    $text = [string]$sender.Items[$e.Index]
    $foreground = if ($isSelected) { [System.Drawing.Color]::FromArgb(110, 255, 110) } else { [System.Drawing.Color]::White }
    $textBrush = New-Object System.Drawing.SolidBrush($foreground)
    $arrowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(110, 255, 110))
    $textX = $e.Bounds.Left + 24
    $textY = $e.Bounds.Top + 2
    $optionBounds = Get-OptionTextBounds -ListBox $sender -Index $e.Index -ItemBounds $e.Bounds
    $script:optionHitBoxes[$e.Index] = $optionBounds

    try {
        $e.Graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
        if ($isSelected) {
            $iconPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(110, 255, 110), 1.5)
            $iconPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $iconPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
            $iconPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
            try {
                $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                $e.Graphics.DrawLine($iconPen, $e.Bounds.Left + 1, $e.Bounds.Top + 9, $e.Bounds.Left + 13, $e.Bounds.Top + 9)
                $e.Graphics.DrawLine($iconPen, $e.Bounds.Left + 10, $e.Bounds.Top + 6, $e.Bounds.Left + 13, $e.Bounds.Top + 9)
                $e.Graphics.DrawLine($iconPen, $e.Bounds.Left + 10, $e.Bounds.Top + 12, $e.Bounds.Left + 13, $e.Bounds.Top + 9)

                $e.Graphics.DrawLine($iconPen, $e.Bounds.Left + 17, $e.Bounds.Top + 19, $e.Bounds.Left + 5, $e.Bounds.Top + 19)
                $e.Graphics.DrawLine($iconPen, $e.Bounds.Left + 8, $e.Bounds.Top + 16, $e.Bounds.Left + 5, $e.Bounds.Top + 19)
                $e.Graphics.DrawLine($iconPen, $e.Bounds.Left + 8, $e.Bounds.Top + 22, $e.Bounds.Left + 5, $e.Bounds.Top + 19)
            }
            finally {
                $iconPen.Dispose()
            }
        }
        $e.Graphics.DrawString($text, $sender.Font, $textBrush, $textX, $textY)
    }
    finally {
        $textBrush.Dispose()
        $arrowBrush.Dispose()
    }
})
$form.Controls.Add($listBox)
$form.Height = $listBox.Bottom + 16

$startDragTracking = {
    param($eventArgs)
    if ($eventArgs.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:dragOrigin = New-Object System.Drawing.Point($eventArgs.X, $eventArgs.Y)
    }
}

$continueDragTracking = {
    param($sender, $eventArgs)
    if ($eventArgs.Button -ne [System.Windows.Forms.MouseButtons]::Left -or -not $script:dragOrigin) {
        return
    }

    $deltaX = [Math]::Abs($eventArgs.X - $script:dragOrigin.X)
    $deltaY = [Math]::Abs($eventArgs.Y - $script:dragOrigin.Y)
    if ($deltaX -ge 4 -or $deltaY -ge 4) {
        $script:dragOrigin = $null
        & $dragWindow
    }
}

$stopDragTracking = {
    $script:dragOrigin = $null
}

$form.Add_MouseDown({
    param($sender, $eventArgs)
    & $startDragTracking $eventArgs
})
$form.Add_MouseMove({
    param($sender, $eventArgs)
    & $continueDragTracking $sender $eventArgs
})
$form.Add_MouseUp({
    param($sender, $eventArgs)
    & $stopDragTracking
})

$listBox.Add_MouseDown({
    param($sender, $eventArgs)

    $hitIndex = $sender.IndexFromPoint($eventArgs.Location)
    if ($hitIndex -ge 0) {
        $itemBounds = $sender.GetItemRectangle($hitIndex)
        $optionBounds = Get-OptionTextBounds -ListBox $sender -Index $hitIndex -ItemBounds $itemBounds
        $script:optionHitBoxes[$hitIndex] = $optionBounds

        if ($optionBounds.Contains($eventArgs.Location)) {
            $script:suppressNextSelectionChange = $false
            $sender.SelectedIndex = $hitIndex
            $script:lastSelectedIndex = $hitIndex
            & $startDragTracking $eventArgs
            return
        }
        else {
            $script:suppressNextSelectionChange = $true
            if ($script:lastSelectedIndex -ge 0 -and $script:lastSelectedIndex -lt $sender.Items.Count) {
                $sender.SelectedIndex = $script:lastSelectedIndex
            }
            & $startDragTracking $eventArgs
            return
        }
    }

    $script:suppressNextSelectionChange = $false
    & $startDragTracking $eventArgs
})
$listBox.Add_MouseMove({
    param($sender, $eventArgs)
    & $continueDragTracking $sender $eventArgs
})
$listBox.Add_MouseUp({
    param($sender, $eventArgs)
    & $stopDragTracking
})
$listBox.Add_SelectedIndexChanged({
    param($sender, $eventArgs)

    if ($script:suppressNextSelectionChange) {
        $script:suppressNextSelectionChange = $false
        if ($script:lastSelectedIndex -ge 0 -and $script:lastSelectedIndex -lt $sender.Items.Count) {
            $sender.SelectedIndex = $script:lastSelectedIndex
        }
        return
    }

    $script:lastSelectedIndex = $sender.SelectedIndex
})

    $convertSelection = {
        if ($listBox.SelectedItem) {
            $selected = $listBox.SelectedItem.ToString().ToLowerInvariant()
        }
        else {
            $selected = $null
        }

        if (-not $selected) {
            return
        }

        $form.Tag = $selected
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    }

    $listBox.Add_DoubleClick({
        & $convertSelection
    })

    $form.Add_KeyDown({
        param($sender, $eventArgs)

        switch ($eventArgs.KeyCode) {
            'Escape' {
                $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
                $form.Close()
                $eventArgs.Handled = $true
            }
            'Down' {
                if ($listBox.Items.Count -eq 0) {
                    return
                }
                if ($listBox.SelectedIndex -lt ($listBox.Items.Count - 1)) {
                    $listBox.SelectedIndex++
                }
                else {
                    $listBox.SelectedIndex = 0
                }
                $eventArgs.Handled = $true
            }
            'Up' {
                if ($listBox.Items.Count -eq 0) {
                    return
                }
                if ($listBox.SelectedIndex -gt 0) {
                    $listBox.SelectedIndex--
                }
                else {
                    $listBox.SelectedIndex = $listBox.Items.Count - 1
                }
                $eventArgs.Handled = $true
            }
            'Enter' {
                & $convertSelection
                $eventArgs.Handled = $true
            }
        }
    })

    $result = $form.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        exit 0
    }

    $Preset = [string]$form.Tag
}

try {
    & $converterScript -Preset $Preset -InputPaths $InputPaths
    Add-Type -AssemblyName System.Windows.Forms
    [System.Media.SystemSounds]::Asterisk.Play()
}
catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        $_.Exception.Message,
        'roeversion',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}
