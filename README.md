# FFmpeg SendTo for Windows

This repository now includes a Windows `Send to` utility named `roeversion` that uses `ffmpeg` to convert files from Explorer.

## What it does

- Right-click one or more files in Explorer.
- Choose `Send to`.
- Use `roeversion` to open a small dialog with detected output options for the selected files.

Supported presets:

- `mp3`
- `ogg`
- `wav`
- `flac`
- `mp4`
- `webm`
- `gif`

Examples:

- `mp3` to `ogg`
- `mp4` to `mp3`
- `mp4` to `gif`
- `wav` to `flac`

## Files

- [sendto/Convert-WithFFmpeg.ps1](C:\Users\roe\Documents\Playground\sendto\Convert-WithFFmpeg.ps1)
- [sendto/Launch-SendToFFmpeg.ps1](C:\Users\roe\Documents\Playground\sendto\Launch-SendToFFmpeg.ps1)
- [sendto/Install-SendToFFmpeg.ps1](C:\Users\roe\Documents\Playground\sendto\Install-SendToFFmpeg.ps1)

## Setup

1. Install `ffmpeg` and make sure `ffmpeg.exe` is on your `PATH`.
2. If it is not on `PATH`, set `FFMPEG_PATH` to the full path of `ffmpeg.exe`.
3. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\sendto\Install-SendToFFmpeg.ps1
```

## Usage

1. In Explorer, select one or more media files.
2. Right-click and choose `Send to`.
3. Pick `roeversion`.

Converted files are written next to the originals. If a filename already exists, the script appends `-1`, `-2`, and so on.
