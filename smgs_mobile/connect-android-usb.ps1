# Run again after reconnecting USB or restarting adb/the phone.
$ErrorActionPreference = 'Stop'
$adbPath = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
& $adbPath -d reverse tcp:5169 tcp:5169
if ($LASTEXITCODE -ne 0) {
    throw 'Connect one Android phone with USB debugging enabled and accept its authorization prompt.'
}
Write-Host 'USB API forwarding ready: http://127.0.0.1:5169. Keep the backend running on port 5169.'
