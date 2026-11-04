param([string]$Flutter = 'flutter', [string]$ApiBaseUrl = '', [string]$TtsBaseUrl = '')

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$mobileRoot = Join-Path $repoRoot 'smgs_mobile'
$buildRoot = Join-Path $mobileRoot 'build\web'
$visitorRoot = Join-Path $repoRoot 'smgs_web\public\visitor'

# The web portal currently deploys this checked-in Flutter build.
# Rebuild before copying, so a failed build can never replace the working preview.
Push-Location -LiteralPath $mobileRoot
try {
    $buildArguments = @('build', 'web', '--release', '--base-href', '/visitor/')
    if (![string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
        $backendAddress = $ApiBaseUrl.Trim().TrimEnd('/')
        if ($backendAddress.EndsWith('/api')) { $backendAddress = $backendAddress.Substring(0, $backendAddress.Length - 4) }
        $parsedAddress = [Uri]$backendAddress
        if (!$parsedAddress.IsAbsoluteUri -or $parsedAddress.Scheme -notin @('http', 'https')) {
            throw 'ApiBaseUrl cần là địa chỉ HTTP(S) của Backend.'
        }
        $buildArguments += "--dart-define=API_BASE_URL=$backendAddress"
    }
    if (![string]::IsNullOrWhiteSpace($TtsBaseUrl)) {
        $ttsAddress = $TtsBaseUrl.Trim().TrimEnd('/')
        $parsedTtsAddress = [Uri]$ttsAddress
        if (!$parsedTtsAddress.IsAbsoluteUri -or $parsedTtsAddress.Scheme -notin @('http', 'https')) {
            throw 'TtsBaseUrl cần là địa chỉ HTTP(S) của dịch vụ hoặc proxy giọng đọc.'
        }
        $buildArguments += "--dart-define=TTS_BASE_URL=$ttsAddress"
    }
    & $Flutter @buildArguments
    if ($LASTEXITCODE -ne 0) { throw 'Flutter build thất bại. Chưa cập nhật Visitor web.' }
} finally {
    Pop-Location
}
if (!(Test-Path -LiteralPath (Join-Path $buildRoot 'main.dart.js'))) {
    throw 'Không tìm thấy kết quả Flutter web.'
}
New-Item -ItemType Directory -Path $visitorRoot -Force | Out-Null
Get-ChildItem -LiteralPath $buildRoot -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $visitorRoot -Recurse -Force
}
$sourceHash = (Get-FileHash -LiteralPath (Join-Path $buildRoot 'main.dart.js')).Hash
$targetHash = (Get-FileHash -LiteralPath (Join-Path $visitorRoot 'main.dart.js')).Hash
if ($sourceHash -ne $targetHash) { throw 'Bundle Visitor sao chép không khớp.' }
Write-Host 'Đã cập nhật Flutter Visitor tại smgs_web/public/visitor. Chạy npm run build trong smgs_web để đóng gói portal.'
