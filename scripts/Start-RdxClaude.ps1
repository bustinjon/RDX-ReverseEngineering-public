<#
.SYNOPSIS
Start or resume the RDX lead Claude session with unattended usage-limit recovery enabled.

.DESCRIPTION
Sets the Claude Code retry watchdog for THIS launch only (nothing global is changed):
  CLAUDE_CODE_RETRY_WATCHDOG=1                         wait out near-term usage limits instead of failing
  CLAUDE_CODE_RETRY_WATCHDOG_USAGE_LIMIT_RECHECK_MS    how often to probe for an early reset (5 min)
  CLAUDE_CODE_RETRY_WATCHDOG_MAX_USAGE_LIMIT_WAIT_MS   longest usage-limit wait (6 h): a normal 5-hour window
                                                       is waited out; a weekly limit stops the session
  CLAUDE_CODE_RETRY_WATCHDOG_MAX_WAIT_MS               overall cap on any one waiting episode (8 h)

Uses your Claude subscription login. ANTHROPIC_API_KEY is removed from the child environment (a warning is
printed if it was set). Never passes --dangerously-skip-permissions. One launcher at a time (lock file).

.PARAMETER Resume              Continue the most recent conversation in this project (claude --continue).
.PARAMETER ScheduleResumeAt    Create ONE one-time Windows scheduled task that runs -Resume at that local time.
.PARAMETER CancelScheduledResume  Remove that scheduled task.
.PARAMETER PermissionMode      Passed through to claude (bypassPermissions is refused).
.PARAMETER DryRun              Print what would run; start nothing.
#>
[CmdletBinding()]
param(
    [switch]$Resume,
    [datetime]$ScheduleResumeAt,
    [switch]$CancelScheduledResume,
    [string]$PermissionMode,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = 'C:/Users/REDACTED\Desktop\RDX-ReverseEngineering'
$StateDir = Join-Path $env:LOCALAPPDATA 'RdxClaude'          # outside the repo: never committed
$LockFile = Join-Path $StateDir 'launcher.lock'
$LogFile = Join-Path $StateDir 'launcher.log'
$TaskName = 'RdxClaudeOneShotResume'
$MinVersion = [version]'2.1.310'
New-Item -ItemType Directory -Force $StateDir | Out-Null

function Write-Log([string]$m) {
    $line = '{0:s} {1}' -f (Get-Date), $m
    Add-Content -LiteralPath $LogFile -Value $line
    Write-Host $line
}

# ---- scheduled one-shot resume management (no loops: the task runs once and is not recurring) ----
if ($CancelScheduledResume) {
    schtasks /Delete /TN $TaskName /F 2>&1 | Out-Host
    Write-Log "cancelled scheduled resume task $TaskName"
    return
}
if ($PSBoundParameters.ContainsKey('ScheduleResumeAt')) {
    if ($ScheduleResumeAt -le (Get-Date).AddMinutes(1)) { throw 'ScheduleResumeAt must be in the future.' }
    $self = $MyInvocation.MyCommand.Path
    $tr = 'pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" -Resume' -f $self
    if ($DryRun) { Write-Log "DRYRUN would schedule $TaskName at $ScheduleResumeAt : $tr"; return }
    schtasks /Create /TN $TaskName /SC ONCE /SD $ScheduleResumeAt.ToString('MM/dd/yyyy') /ST $ScheduleResumeAt.ToString('HH:mm') /TR $tr /F 2>&1 | Out-Host
    Write-Log "scheduled one-shot resume $TaskName at $ScheduleResumeAt (runs only while you are logged on)"
    return
}

# ---- preflight ----
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { throw 'claude CLI not found on PATH.' }
$verText = (& claude --version 2>&1 | Out-String)
if ($verText -notmatch '(\d+\.\d+\.\d+)') { throw "Cannot parse claude version: $verText" }
$ver = [version]$Matches[1]
if ($ver -lt $MinVersion) { Write-Warning "claude $ver is older than $MinVersion; watchdog variables may be unsupported." }
if ($PermissionMode -eq 'bypassPermissions') { throw 'bypassPermissions is not allowed by this launcher.' }
if ($env:ANTHROPIC_API_KEY) { Write-Warning 'ANTHROPIC_API_KEY is set in this shell; removing it for this launch (subscription login only).' }

# one launcher at a time
if (Test-Path -LiteralPath $LockFile) {
    $old = (Get-Content -LiteralPath $LockFile -ErrorAction SilentlyContinue) -split ','
    $oldPid = 0; [void][int]::TryParse($old[0], [ref]$oldPid)
    $alive = $oldPid -gt 0 -and (Get-Process -Id $oldPid -ErrorAction SilentlyContinue)
    if ($alive) { Write-Log "REFUSED: another launcher (PID $oldPid) holds the lock. Not starting a duplicate."; exit 3 }
    Write-Log "removing stale lock (PID $oldPid not running)"
    Remove-Item -LiteralPath $LockFile -Force
}
$others = @(Get-Process claude -ErrorAction SilentlyContinue)
if ($others.Count -gt 0) {
    Write-Warning ("{0} other claude process(es) already running (PIDs {1}). Make sure none is editing this project: one writer at a time." -f $others.Count, ($others.Id -join ','))
}

$resumePrompt = 'RESUME CHECK: Read analysis\agent-reviews\CLAUDE-CURRENT-WORK.md first. Then inspect actual state (git status, whether any codex process is still running, whether Codex output files exist). Do not repeat completed commands or launch duplicate Codex jobs. Continue only authorized OFFLINE work; no live car work, no M5 arm, no M6/M7, no git commit or push without explicit user approval.'

$claudeArgs = @()
if ($Resume) { $claudeArgs += '--continue' }
if ($PermissionMode) { $claudeArgs += @('--permission-mode', $PermissionMode) }
if ($Resume) { $claudeArgs += $resumePrompt }

$envPlan = [ordered]@{
    CLAUDE_CODE_RETRY_WATCHDOG                         = '1'
    CLAUDE_CODE_RETRY_WATCHDOG_USAGE_LIMIT_RECHECK_MS  = '300000'
    CLAUDE_CODE_RETRY_WATCHDOG_MAX_USAGE_LIMIT_WAIT_MS = '21600000'
    CLAUDE_CODE_RETRY_WATCHDOG_MAX_WAIT_MS             = '28800000'
}

if ($DryRun) {
    Write-Log "DRYRUN claude $ver in $ProjectRoot"
    $envPlan.GetEnumerator() | ForEach-Object { Write-Log "DRYRUN env $($_.Key)=$($_.Value)" }
    Write-Log "DRYRUN api-key-set=$([bool]$env:ANTHROPIC_API_KEY) (would be removed for child)"
    Write-Log ('DRYRUN args: claude ' + (($claudeArgs | ForEach-Object { if ($_.Length -gt 60) { $_.Substring(0, 57) + '...' } else { $_ } }) -join ' '))
    return
}

Set-Location -LiteralPath $ProjectRoot
"$PID,$(Get-Date -Format s)" | Set-Content -LiteralPath $LockFile
try {
    foreach ($kv in $envPlan.GetEnumerator()) { Set-Item -Path "Env:$($kv.Key)" -Value $kv.Value }
    Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
    Write-Log "starting claude $ver (resume=$([bool]$Resume)) watchdog on, usage-limit wait cap 6h"
    & claude @claudeArgs
    Write-Log "claude exited with code $LASTEXITCODE"
}
finally {
    Remove-Item -LiteralPath $LockFile -Force -ErrorAction SilentlyContinue
}
