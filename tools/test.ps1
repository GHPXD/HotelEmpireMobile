param(
    [string]$GodotPath = 'C:\Program Files (x86)\Godot\Godot_v4.7.2-stable_win64.exe',
    [switch]$Visual,
    [switch]$Stress,
    [switch]$Soak,
    [switch]$Tariffs
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$runtimeRoot = Join-Path $projectRoot '.runtime'
New-Item -ItemType Directory -Force -Path $runtimeRoot | Out-Null
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $runtimeRoot
    $importLog = Join-Path $runtimeRoot 'import.log'
    $run = Start-Process -FilePath $GodotPath -ArgumentList @('--headless', '--editor', '--path', $projectRoot, '--log-file', $importLog, '--quit') -WindowStyle Hidden -PassThru -Wait
    if ($run.ExitCode -ne 0 -or (Select-String -LiteralPath $importLog -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet)) { throw 'Godot import failed; inspect .runtime/import.log' }
    $suites = @('foundation_test', 'construction_test', 'simulation_test', 'save_test', 'management_test', 'lodging_value_test', 'reviews_test', 'progression_test', 'content_test', 'analytics_test', 'checkin_diagnostics_test')
    if ($Stress) { $suites += @('save_multiseed_test', 'stress_test', 'admission_equivalence_test') }
    if ($Soak) { $suites += @('long_run_test') }
    if ($Tariffs) { $suites += @('departure_observer_test', 'tariff_scenarios') }
    if ($Visual) { $suites += @('ui_smoke', 'ui_resume', 'ui_management', 'ui_progression', 'ui_content', 'ui_operations', 'ui_reviews', 'ui_art', 'ui_culling', 'ui_actor_presentation', 'ui_new_game', 'ui_exit', 'ui_help', 'ui_recovery', 'ui_checkin_diagnostics') }
    foreach ($suite in $suites) {
        $testLog = Join-Path $runtimeRoot ($suite + '.log')
        $arguments = @('--path', $projectRoot, '--script', ('res://tests/' + $suite + '.gd'), '--log-file', $testLog)
        if ($suite -notlike 'ui_*') { $arguments += '--headless' }
        $run = Start-Process -FilePath $GodotPath -ArgumentList $arguments -WindowStyle Hidden -PassThru -Wait
        Get-Content -LiteralPath $testLog | Select-String -Pattern '^\{|^\[SAVE\]'
        if ($run.ExitCode -ne 0 -or (Select-String -LiteralPath $testLog -Pattern 'SCRIPT ERROR:|^ERROR:|leaked at exit|resources still in use' -Quiet)) { throw "Suite failed: $suite. Inspect $testLog" }
    }
    Write-Output 'All requested suites passed.'
} finally {
    $env:APPDATA = $previousAppData
}
