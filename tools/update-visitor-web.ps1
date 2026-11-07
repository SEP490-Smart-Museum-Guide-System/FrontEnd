param([string]$Flutter = 'flutter', [string]$ApiBaseUrl = '', [string]$TtsBaseUrl = '')

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$mobileRoot = Join-Path $repoRoot 'smgs_mobile'
$buildRoot = Join-Path $mobileRoot 'build\web'
$visitorRoot = Join-Path $repoRoot 'smgs_web\public\visitor'

Push-Location -LiteralPath $mobileRoot
try {
    $buildArguments = @('build', 'web', '--release', '--base-href', '/visitor/')
    if (![string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
        $backendAddress = $ApiBaseUrl.Trim().TrimEnd('/')
        if ($backendAddress.EndsWith('/api')) { $backendAddress = $backendAddress.Substring(0, $backendAddress.Length - 4) }
        $parsedAddress = [Uri]$backendAddress
        if (!$parsedAddress.IsAbsoluteUri -or $parsedAddress.Scheme -notin @('http', 'https')) {
            throw 'ApiBaseUrl must be an HTTP(S) address.'
        }
        $buildArguments += "--dart-define=API_BASE_URL=$backendAddress"
    }
    if (![string]::IsNullOrWhiteSpace($TtsBaseUrl)) {
        $ttsAddress = $TtsBaseUrl.Trim().TrimEnd('/')
        $parsedTtsAddress = [Uri]$ttsAddress
        if (!$parsedTtsAddress.IsAbsoluteUri -or $parsedTtsAddress.Scheme -notin @('http', 'https')) {
            throw 'TtsBaseUrl must be an HTTP(S) address.'
        }
        $buildArguments += "--dart-define=TTS_BASE_URL=$ttsAddress"
    }
    & $Flutter @buildArguments
    if ($LASTEXITCODE -ne 0) { throw 'Flutter build failed. Visitor web not updated.' }
} finally {
    Pop-Location
}
if (!(Test-Path -LiteralPath (Join-Path $buildRoot 'main.dart.js'))) {
    throw 'Could not find Flutter web build output.'
}
New-Item -ItemType Directory -Path $visitorRoot -Force | Out-Null
Get-ChildItem -LiteralPath $buildRoot -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $visitorRoot -Recurse -Force
}
Write-Host 'Updated Flutter Visitor build at smgs_web/public/visitor successfully.'
