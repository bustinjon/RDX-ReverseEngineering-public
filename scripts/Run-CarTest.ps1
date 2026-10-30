#Requires -Version 7.0
# Defaults to local preparation. Live use requires separate project authorization.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ApkPath,
    [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ApkSha256,
    [Parameter(Mandatory)][ValidateSet('HistoricalBaseline','CurrentSource')][string]$CandidateRole,
    [string]$BuildReportPath,
    [ValidateSet('Prepare','Live')][string]$Mode = 'Prepare',
    [ValidateSet('00000000')][string]$Serial = '00000000',
    [ValidateRange(60,300)][int]$SafetySeconds = 60,
    [ValidateSet('ForceStop','PhonePreference')][string]$HondaStrategy='ForceStop',
    [string]$PhoneSerial,
    [switch]$HondaPhoneDisabled,
    [string]$AdbPath = 'C:/Program Files (x86)/Android/android-sdk/platform-tools/adb.exe'
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $repoRoot 'tools/car-test/CarTest.Core.ps1')
if (-not $BuildReportPath) { $BuildReportPath = Join-Path (Split-Path $ApkPath -Parent) 'build-report.json' }
$plan = Get-CarTestArtifactPlan -RepoRoot $repoRoot -ApkPath $ApkPath -ExpectedHash $ApkSha256 -BuildReportPath $BuildReportPath -CandidateRole $CandidateRole
if ($HondaStrategy -eq 'PhonePreference') { Assert-CTPhonePreferencePlan $plan $PhoneSerial $HondaPhoneDisabled.IsPresent }
$plan | Add-Member -NotePropertyName SelectedHondaStrategy -NotePropertyValue $HondaStrategy
$plan | Add-Member -NotePropertyName ConfiguredPhoneSerial -NotePropertyValue $PhoneSerial
$plan | Add-Member -NotePropertyName HondaPreferenceOperatorConfirmed -NotePropertyValue $HondaPhoneDisabled.IsPresent
$runId = 'helper_' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmss') + '_' + [guid]::NewGuid().ToString('N')
$runDirectory = Join-Path $repoRoot "analysis/test-prep/runs/$runId"
$null = New-Item -ItemType Directory -Path $runDirectory
$plan | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $runDirectory 'artifact-plan.json') -Encoding utf8
if ($Mode -eq 'Prepare') {
    Write-Host "OFFLINE PREPARED: $runDirectory"
    Write-Host "Candidate: $CandidateRole; source differences: $(@($plan.SourceDifferences).Count); audit: $($plan.StaticAudit)"
    Write-Host 'No device command was invoked. This is not live readiness or authorization.'
    return
}
if (-not (Test-Path -LiteralPath $AdbPath -PathType Leaf)) { throw 'ADB executable not found.' }
$transport = {
    param([string[]]$Arguments)
    if ($Arguments.Count -lt 3 -or $Arguments[0] -ne '-s' -or $Arguments[1] -ne $Serial) { throw 'Missing explicit head-unit target.' }
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $AdbPath
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    try {
        $null = $process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(30000)) {
            $process.Kill($true)
            throw 'Target command exceeded 30 seconds; readiness refused.'
        }
        [pscustomobject]@{ ExitCode = $process.ExitCode; Output = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult() }
    } finally { $process.Dispose() }
}.GetNewClosure()
$result = Invoke-CarTestPreparation -Plan $plan -Serial $Serial -SafetySeconds $SafetySeconds -RunDirectory $runDirectory -RepoRoot $repoRoot -Transport $transport -HondaStrategy $HondaStrategy -PhoneSerial $PhoneSerial -HondaPhoneDisabled $HondaPhoneDisabled.IsPresent
if ($HondaStrategy -eq 'PhonePreference') {
    Write-Host "READY — plug in the configured phone now. Honda per-phone Disable selected; cleanup in approximately $($result.SafetyRemainingSeconds)s." -ForegroundColor Green
} else {
    Write-Host "READY — plug in the phone now. Estimated remaining windows: cleanup $($result.SafetyRemainingSeconds)s; Honda loop $($result.HondaRemainingSeconds)s." -ForegroundColor Green
}
Write-Host "Evidence: $runDirectory"
Write-Host "Device capture: $($result.RemoteDirectory)/capture.log"
Write-Host 'The watchdog remains active after laptop disconnect. Preserve the capture and watchdog log after the attempt.'
