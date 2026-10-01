param(
    [string]$GodotPath = $env:GDA_GODOT,
    [ValidatePattern('^[a-z_]+$')][string]$Suite = 'shell_layout_test',
    [ValidateRange(1, 600)][int]$TimeoutSeconds = 120
)
$ErrorActionPreference = 'Stop'
if (-not $GodotPath) { throw 'Set GDA_GODOT or pass -GodotPath.' }
$projectRoot = Split-Path $PSScriptRoot -Parent
$testScript = Join-Path $projectRoot ('tests/mobile/' + $Suite + '.gd')
if (-not (Test-Path -LiteralPath $testScript)) { throw 'Unknown mobile suite.' }
$runRoot = Join-Path $projectRoot ('.runtime/mobile-render/' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'))
New-Item -ItemType Directory -Force -Path $runRoot | Out-Null
$log = Join-Path $runRoot 'godot.log'
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $runRoot
    $engineArguments = @('--path', $projectRoot, '--script', ('res://tests/mobile/' + $Suite + '.gd'), '--log-file', $log, '--audio-driver', 'Dummy')
    $quotedArguments = $engineArguments | ForEach-Object { '"' + $_ + '"' }
    $process = Start-Process -FilePath $GodotPath -ArgumentList $quotedArguments -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill()
        throw "Render test timeout. Inspect $log"
    }
    $lines = Get-Content -LiteralPath $log
    $summaries = @($lines | Where-Object { $_ -match '^\{' } | ForEach-Object { $_ | ConvertFrom-Json })
    $summary = $summaries | Where-Object { $_.suite } | Select-Object -Last 1
    $passed = $process.ExitCode -eq 0 -and $summary -and $summary.failures -eq 0 -and $summary.rendered -and -not ($lines | Select-String 'SCRIPT ERROR:|^ERROR:|leaked at exit|resources still in use')
    $captures = @($summary.screenshots | ForEach-Object { [ordered]@{ path = $_; sha256 = (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash.ToLowerInvariant() } })
    $report = [ordered]@{ passed = [bool]$passed; engine = $GodotPath; engineSha256 = (Get-FileHash -LiteralPath $GodotPath -Algorithm SHA256).Hash.ToLowerInvariant(); revision = (git -C $projectRoot rev-parse HEAD).Trim(); dirty = [bool](git -C $projectRoot status --porcelain); summary = $summary; captures = $captures; log = $log }
    $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $runRoot 'report.json') -Encoding utf8
    Write-Output ($report | ConvertTo-Json -Depth 10 -Compress)
    if (-not $passed) { throw "Rendered mobile test failed. Inspect $log" }
} finally {
    $env:APPDATA = $previousAppData
}
