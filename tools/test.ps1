param(
    [string]$GodotPath = 'C:\Program Files (x86)\Godot\Godot_v4.7.2-stable_win64.exe',
    [switch]$Visual,
    [switch]$Stress,
    [switch]$Soak,
    [switch]$Tariffs,
    [ValidateRange(1, 3600)][int]$SuiteTimeoutSeconds = 120
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$runtimeRoot = Join-Path $projectRoot '.runtime'
New-Item -ItemType Directory -Force -Path $runtimeRoot | Out-Null
$previousAppData = $env:APPDATA
$suiteResults = [Collections.Generic.List[object]]::new()
$reportPath = Join-Path $runtimeRoot 'test-run-report.json'
$report = [ordered]@{
    startedUtc = [DateTime]::UtcNow.ToString('o')
    sourceRevision = (git -C $projectRoot rev-parse HEAD).Trim()
    sourceDirtyStart = [bool](git -C $projectRoot status --porcelain)
    enginePath = $GodotPath
    engineSha256 = (Get-FileHash -LiteralPath $GodotPath -Algorithm SHA256).Hash.ToLowerInvariant()
    options = [ordered]@{ visual = [bool]$Visual; stress = [bool]$Stress; soak = [bool]$Soak; tariffs = [bool]$Tariffs; suiteTimeoutSeconds = $SuiteTimeoutSeconds }
    status = 'running'
    steps = $suiteResults
}

function Invoke-TestEngine([string]$Name, [string[]]$GodotArguments, [string]$Log) {
    $step = [ordered]@{ name = $Name; startedUtc = [DateTime]::UtcNow.ToString('o'); log = $Log; status = 'running' }
    $suiteResults.Add($step)
    $timer = [Diagnostics.Stopwatch]::StartNew()
    try {
        $quoted = $GodotArguments | ForEach-Object { '"' + $_ + '"' }
        $process = Start-Process -FilePath $GodotPath -ArgumentList $quoted -WindowStyle Hidden -PassThru
        if (-not $process.WaitForExit($SuiteTimeoutSeconds * 1000)) {
            $process.Kill()
            $step.status = 'timeout'
            throw "Timeout: $Name. Inspect $Log"
        }
        $step.exitCode = $process.ExitCode
        if (-not (Test-Path -LiteralPath $Log)) { throw "Missing log: $Name" }
        $step.logSha256 = (Get-FileHash -LiteralPath $Log -Algorithm SHA256).Hash.ToLowerInvariant()
        $step.summaries = @(Get-Content -LiteralPath $Log | Where-Object { $_ -match '^\{' } | ForEach-Object { $_ | ConvertFrom-Json })
        Get-Content -LiteralPath $Log | Select-String -Pattern '^\{|^\[SAVE\]' | ForEach-Object { $_.Line }
        if ($process.ExitCode -ne 0 -or (Select-String -LiteralPath $Log -Pattern 'SCRIPT ERROR:|^ERROR:|leaked at exit|resources still in use' -Quiet)) { throw "Suite failed: $Name. Inspect $Log" }
        if ($Name -ne 'import' -and -not @($step.summaries | Where-Object { $_.suite }).Count) { throw "Missing suite summary: $Name" }
        $step.status = 'passed'
    } catch {
        if ($step.status -ne 'timeout') { $step.status = 'failed' }
        $step.error = $_.Exception.Message
        throw
    } finally {
        $timer.Stop()
        $step.durationSeconds = $timer.Elapsed.TotalSeconds
        $step.completedUtc = [DateTime]::UtcNow.ToString('o')
    }
}

try {
    $env:APPDATA = $runtimeRoot
    $importLog = Join-Path $runtimeRoot 'import.log'
    Invoke-TestEngine 'import' @('--headless', '--editor', '--path', $projectRoot, '--log-file', $importLog, '--quit') $importLog
    $suites = @('foundation_test', 'construction_test', 'simulation_test', 'save_test', 'management_test', 'lodging_value_test', 'reviews_test', 'progression_test', 'content_test', 'analytics_test', 'checkin_diagnostics_test')
    if ($Stress) { $suites += @('save_multiseed_test', 'stress_test', 'admission_equivalence_test') }
    if ($Soak) { $suites += @('long_run_test') }
    if ($Tariffs) { $suites += @('departure_observer_test', 'tariff_scenarios') }
    if ($Visual) { $suites += @('ui_smoke', 'ui_resume', 'ui_management', 'ui_action_icons', 'ui_management_icons', 'ui_progression', 'ui_content', 'ui_operations', 'ui_reviews', 'ui_art', 'ui_culling', 'ui_actor_presentation', 'ui_new_game', 'ui_exit', 'ui_help', 'ui_recovery', 'ui_checkin_diagnostics') }
    foreach ($suite in $suites) {
        $testLog = Join-Path $runtimeRoot ($suite + '.log')
        $arguments = @('--path', $projectRoot, '--script', ('res://tests/' + $suite + '.gd'), '--log-file', $testLog)
        if ($suite -notlike 'ui_*') { $arguments += '--headless' }
        Invoke-TestEngine $suite $arguments $testLog
    }
    $report.status = 'passed'
    Write-Output 'All requested suites passed.'
} catch {
    $report.status = 'failed'
    $report.error = $_.Exception.Message
    throw
} finally {
    $env:APPDATA = $previousAppData
    $report.completedUtc = [DateTime]::UtcNow.ToString('o')
    $report.sourceRevisionEnd = (git -C $projectRoot rev-parse HEAD).Trim()
    $report.sourceDirtyEnd = [bool](git -C $projectRoot status --porcelain)
    $report | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $reportPath -Encoding utf8
    Write-Output "Report: $reportPath"
}
