<#
.SYNOPSIS
Run one bounded Codex CLI task for the Claude (lead) -> Codex (subordinate) workflow.

.DESCRIPTION
review (default): read-only sandbox. Codex cannot write to the workspace.
write           : workspace-write sandbox. Use only for an explicitly scoped implementation task.

Never uses danger-full-access or any bypass flag. Approval policy is fixed to "never" (codex exec
0.163.0 has no --ask-for-approval flag, so it is set with -c approval_policy). The prompt is sent
over stdin to avoid Windows command-line quoting problems.

A before/after file-state snapshot (path, length, last-write) of the project tree excluding .git is
taken so the caller can see independently of Codex's own report whether anything changed.

.PARAMETER Prompt      Task text for Codex.
.PARAMETER Mode        review | write. Default review.
.PARAMETER OutputFile  Optional. Codex's final message is written here (codex --output-last-message).
#>
[CmdletBinding(DefaultParameterSetName = 'Inline')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Inline')][string]$Prompt,
    # Alternative to -Prompt for long prompts (avoids command-line quoting problems).
    [Parameter(Mandatory, ParameterSetName = 'File')][string]$PromptFile,
    [ValidateSet('review', 'write')][string]$Mode = 'review',
    [string]$OutputFile
)

$ErrorActionPreference = 'Stop'
if ($PSCmdlet.ParameterSetName -eq 'File') { $Prompt = Get-Content -LiteralPath $PromptFile -Raw }

$ProjectRoot = 'C:/Users/REDACTED\Desktop\RDX-ReverseEngineering'
$Model = 'gpt-6.1-sol'
$Sandbox = if ($Mode -eq 'write') { 'workspace-write' } else { 'read-only' }

if (-not (Get-Command codex -ErrorAction SilentlyContinue)) { throw 'codex CLI not found on PATH.' }
if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) { throw "Project root missing: $ProjectRoot" }

function Get-TreeSnapshot {
    # Cheap change detector: relative path -> "length|lastwrite ticks". Excludes .git.
    $map = @{}
    $rootLen = $ProjectRoot.Length + 1
    Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notlike "$ProjectRoot\.git\*" } |
        ForEach-Object { $map[$_.FullName.Substring($rootLen)] = '{0}|{1}' -f $_.Length, $_.LastWriteTimeUtc.Ticks }
    $map
}

$guard = @"
[Delegation rules - supplied by the lead agent, Claude]
- Mode: $Mode (sandbox: $Sandbox). Stay strictly inside the task below.
- Read PROJECT-RULES.md and AGENTS.md first.
- Never run adb/fastboot or touch any phone, car or USB device. Do not advance any milestone.
- Do not run git commit/push/add/reset/checkout/clean. Do not read or print key material.
- Your prose is not evidence: cite file paths, hashes, command output. Say UNKNOWN when unproven.
- Finish with the report format from AGENTS.md (files inspected/changed, commands, tests, findings,
  primary evidence, assumptions, uncertainties, diff summary, preservation checks).

[Task]
"@

$full = "$guard`n$Prompt"

$codexArgs = @(
    'exec',
    '--model', $Model,
    '--sandbox', $Sandbox,
    '--config', 'approval_policy="never"',
    '--config', 'model_reasoning_effort="high"',
    '--color', 'never',
    '-C', $ProjectRoot
)
if ($OutputFile) {
    $outDir = Split-Path -Parent $OutputFile
    if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    $codexArgs += @('--output-last-message', $OutputFile)
}
$codexArgs += '-'   # read prompt from stdin

Write-Host "[delegate] mode=$Mode sandbox=$Sandbox model=$Model root=$ProjectRoot"
$before = Get-TreeSnapshot

$full | & codex @codexArgs
$exit = $LASTEXITCODE

$after = Get-TreeSnapshot
$changed = New-Object System.Collections.Generic.List[string]
foreach ($k in $after.Keys) {
    if (-not $before.ContainsKey($k)) { $changed.Add("ADDED    $k") }
    elseif ($before[$k] -ne $after[$k]) { $changed.Add("MODIFIED $k") }
}
foreach ($k in $before.Keys) { if (-not $after.ContainsKey($k)) { $changed.Add("REMOVED  $k") } }

# An OutputFile that Codex wrote is an expected addition/modification.
$expected = if ($OutputFile) { (Resolve-Path -LiteralPath $OutputFile -ErrorAction SilentlyContinue).Path } else { $null }
$unexpected = $changed | Where-Object {
    -not ($expected -and ($_ -replace '^\w+\s+', '') -eq $expected.Substring($ProjectRoot.Length + 1))
}

Write-Host "[delegate] codex exit code: $exit"
if ($unexpected) {
    Write-Host "[delegate] FILE CHANGES DETECTED during $Mode run ($($unexpected.Count)):"
    $unexpected | Select-Object -First 50 | ForEach-Object { Write-Host "    $_" }
    if ($Mode -eq 'review') { Write-Warning 'Review mode must not change files. Investigate before accepting this review.' }
}
else {
    Write-Host '[delegate] no file changes detected outside the requested OutputFile.'
}
exit $exit
