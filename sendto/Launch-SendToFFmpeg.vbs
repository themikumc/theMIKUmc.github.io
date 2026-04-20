Set shell = CreateObject("WScript.Shell")

scriptPath = "C:\Users\roe\Documents\Playground\sendto\Launch-SendToFFmpeg.ps1"
command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File " & Quote(scriptPath)

For Each arg In WScript.Arguments
    command = command & " " & Quote(arg)
Next

shell.Run command, 0, False

Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function
