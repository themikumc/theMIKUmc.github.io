param(
    [string]$Preset,

    [string[]]$InputPaths
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Preset) {
    throw 'A preset is required.'
}

if (@('mp3', 'ogg', 'wav', 'flac', 'mp4', 'webm', 'gif') -notcontains $Preset) {
    throw "Unsupported preset '$Preset'."
}

if (-not $InputPaths -or $InputPaths.Count -eq 0) {
    throw 'At least one input file is required.'
}

function Resolve-FfmpegPath {
    if ($env:FFMPEG_PATH -and (Test-Path -LiteralPath $env:FFMPEG_PATH)) {
        return $env:FFMPEG_PATH
    }

    $command = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $commonPaths = @(
        'C:\ffmpeg\bin\ffmpeg.exe',
        'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
        'C:\Program Files (x86)\ffmpeg\bin\ffmpeg.exe'
    )

    foreach ($path in $commonPaths) {
        if (Test-Path -LiteralPath $path) {
            return $path
        }
    }

    throw "Unable to find ffmpeg.exe. Install FFmpeg, add it to PATH, or set the FFMPEG_PATH environment variable."
}

function Get-PresetDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $presets = @{
        mp3 = @{
            Extension = '.mp3'
            Description = 'Audio MP3'
            Arguments = @('-vn', '-c:a', 'libmp3lame', '-q:a', '2')
        }
        ogg = @{
            Extension = '.ogg'
            Description = 'Audio OGG Vorbis'
            Arguments = @('-vn', '-c:a', 'libvorbis', '-q:a', '5')
        }
        wav = @{
            Extension = '.wav'
            Description = 'Audio WAV'
            Arguments = @('-vn', '-c:a', 'pcm_s16le')
        }
        flac = @{
            Extension = '.flac'
            Description = 'Audio FLAC'
            Arguments = @('-vn', '-c:a', 'flac')
        }
        mp4 = @{
            Extension = '.mp4'
            Description = 'Video MP4'
            Arguments = @('-c:v', 'libx264', '-preset', 'medium', '-crf', '23', '-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart')
        }
        webm = @{
            Extension = '.webm'
            Description = 'Video WebM'
            Arguments = @('-c:v', 'libvpx-vp9', '-crf', '32', '-b:v', '0', '-c:a', 'libopus', '-b:a', '128k')
        }
        gif = @{
            Extension = '.gif'
            Description = 'Animated GIF'
            Arguments = @('-vf', 'fps=12,scale=720:-1:flags=lanczos', '-loop', '0')
        }
    }

    return $presets[$Name]
}

function Get-InputCapabilities {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FfprobePath,

        [Parameter(Mandatory = $true)]
        [string]$InputFile
    )

    $probeJson = & $FfprobePath -v error -show_streams -of json --% $InputFile | Out-String
    if ([string]::IsNullOrWhiteSpace($probeJson)) {
        throw "ffprobe returned no stream data for '$InputFile'."
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
        HasAudio = $hasAudio
        HasVideo = $hasVideo
    }
}

$ffmpeg = Resolve-FfmpegPath
$ffprobe = (Get-Command ffprobe -ErrorAction SilentlyContinue).Source
if (-not $ffprobe) {
    throw 'Unable to find ffprobe.exe. Install FFmpeg with ffprobe available on PATH.'
}
$presetDefinition = Get-PresetDefinition -Name $Preset
$resolvedInputs = New-Object System.Collections.Generic.List[string]

foreach ($path in $InputPaths) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        continue
    }

    if (-not (Test-Path -LiteralPath $path)) {
        Write-Warning "Skipping missing path: $path"
        continue
    }

    $item = Get-Item -LiteralPath $path
    if ($item.PSIsContainer) {
        Write-Warning "Skipping directory: $path"
        continue
    }

    $resolvedInputs.Add($item.FullName)
}

if ($resolvedInputs.Count -eq 0) {
    throw 'No valid input files were provided.'
}

foreach ($inputFile in $resolvedInputs) {
    $capabilities = Get-InputCapabilities -FfprobePath $ffprobe -InputFile $inputFile

    if ($Preset -in @('mp3', 'ogg', 'wav', 'flac') -and -not $capabilities.HasAudio) {
        throw "Cannot convert '$inputFile' to $Preset because it has no audio stream."
    }

    if ($Preset -in @('mp4', 'webm', 'gif') -and -not $capabilities.HasVideo) {
        throw "Cannot convert '$inputFile' to $Preset because it has no video stream."
    }

    $directory = [System.IO.Path]::GetDirectoryName($inputFile)
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
    $outputFile = [System.IO.Path]::Combine($directory, $baseName + $presetDefinition.Extension)
    $index = 1

    while (Test-Path -LiteralPath $outputFile) {
        $outputFile = [System.IO.Path]::Combine($directory, ("{0}-{1}{2}" -f $baseName, $index, $presetDefinition.Extension))
        $index++
    }

    $arguments = @(
        '-y',
        '-i', $inputFile
    ) + $presetDefinition.Arguments + @(
        $outputFile
    )

    Write-Host ("Converting '{0}' -> '{1}' ({2})" -f $inputFile, $outputFile, $presetDefinition.Description)
    & $ffmpeg @arguments

    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed while converting '$inputFile'."
    }
}

Write-Host ("Completed {0} conversion(s) to {1}." -f $resolvedInputs.Count, $Preset)
