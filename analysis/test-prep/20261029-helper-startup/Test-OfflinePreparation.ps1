#Requires -Version 7.0
# This is a local evidence check, not a car-test runner.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$receiver = 'analysis/parallel-aa-receiver'
$buildRelative = "$receiver/usb-helper/build/20261028-164612-233"
$apkRelative = "$buildRelative/rdx-usb-helper-0.1.0-usb-helper-development.apk"
$pinnedHash = 'C7943B4FD9194E6AAD3E2C28AE68F880519D8EC624148AA794FBE9CA97F80757'

function Read-LocalJson([string]$RelativePath) {
    Get-Content -LiteralPath (Join-Path $repoRoot $RelativePath) -Raw | ConvertFrom-Json
}

function Get-LocalHash([string]$RelativePath) {
    (Get-FileHash -LiteralPath (Join-Path $repoRoot $RelativePath) -Algorithm SHA256).Hash
}

$buildReport = Read-LocalJson "$buildRelative/build-report.json"
$priorEvidence = Read-LocalJson 'analysis/agent-reviews/claude-resume-20261102/evidence.json'
$apkHash = Get-LocalHash $apkRelative
$sources = @(foreach ($source in $buildReport.sourceHashes) {
    $fullPath = [IO.Path]::GetFullPath($source.Path)
    if (-not $fullPath.StartsWith($repoRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetExtension($fullPath) -ne '.java') {
        throw 'Build metadata points outside the expected local Java source scope.'
    }
    $relative = [IO.Path]::GetRelativePath($repoRoot, $fullPath).Replace('\', '/')
    $actual = Get-LocalHash $relative
    [ordered]@{ path = $relative; recorded = $source.Hash; actual = $actual; match = ($actual -eq $source.Hash) }
})
$frozen = @(foreach ($artifact in $priorEvidence.frozen_artifacts) {
    $actual = Get-LocalHash $artifact.path
    [ordered]@{ path = $artifact.path; expected = $artifact.expected; actual = $actual; match = ($actual -eq $artifact.expected) }
})
$changedExistingFiles = @(foreach ($file in $priorEvidence.preservation_baseline) {
    if ((Get-LocalHash $file.path) -ne $file.sha256) { $file.path }
})

$patterns = [ordered]@{
    permission_requested = 'RDX\.USB.*Calling UsbManager\.requestPermission'
    permission_rejected = 'RDX\.USB.*Permission callback: granted=false verified=false'
    permission_verified_callback = 'RDX\.USB.*Permission callback: granted=true verified=true'
    permission_exhausted = 'RDX\.USB.*FAILED after 15 attempts'
    a11y_connected = 'RDX\.A11Y.*PermissionClickService connected'
    a11y_click = 'RDX\.A11Y.*SUCCESS.*clicked permission'
    session_created = 'RDX\.SESSION.*AaSessionService created'
    usb_opened = 'RDX\.SESSION.*USB transport opened'
    discovery = 'RDX\.SESSION.*L4 service discovery'
    codec_setup = 'RDX\.SESSION.*Video codec setup callback'
    video_selected = 'RDX\.SESSION.*VIDEO SELECTED'
    decoder_started = 'RDX\.SESSION.*Decoder started'
    first_render_report = 'RDX\.SESSION.*FIRST FRAME RENDERED'
    gal_error = 'RDX\.SESSION.*GAL error='
    bad_mac = 'decryption failed or bad record mac'
}

$logs = @(foreach ($name in @('v6e', 'v6f', 'v6g-retry')) {
    $relative = "analysis/logs/car-test-20261028-$name.txt"
    $text = [IO.File]::ReadAllText((Join-Path $repoRoot $relative))
    $events = [ordered]@{}
    foreach ($pattern in $patterns.GetEnumerator()) {
        $hits = [regex]::Matches($text, '(?m)^.*' + $pattern.Value + '.*$')
        $first = $null
        $last = $null
        if ($hits.Count -gt 0) {
            $first = [ordered]@{
                line = ($text.Substring(0, $hits[0].Index) -split "`n").Count
                text = $hits[0].Value.TrimEnd("`r")
            }
            $last = [ordered]@{
                line = ($text.Substring(0, $hits[$hits.Count - 1].Index) -split "`n").Count
                text = $hits[$hits.Count - 1].Value.TrimEnd("`r")
            }
        }
        $events[$pattern.Key] = [ordered]@{ count = $hits.Count; first = $first; last = $last }
    }
    [ordered]@{ path = $relative; sha256 = (Get-LocalHash $relative); events = $events }
})

$runnerRelative = 'scripts/Run-CarTest.ps1'
$parseTokens = $null
$parseErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $repoRoot $runnerRelative), [ref]$parseTokens, [ref]$parseErrors)
$pointer = (Get-Content -LiteralPath (Join-Path $repoRoot "$receiver/usb-helper/latest-build.txt") -Raw).Trim()
$sourceDifferences = @($sources | Where-Object { -not $_.match })
$frozenDifferences = @($frozen | Where-Object { -not $_.match })
$integrityMatches = $apkHash -eq $pinnedHash -and $apkHash -eq $buildReport.sha256 -and $frozenDifferences.Count -eq 0

[ordered]@{
    schema = 1
    generated_utc = [DateTime]::UtcNow.ToString('o')
    scope = 'LOCAL FILES ONLY; no external programs, device access, build, signing, installation or live test'
    artifact_integrity_matches = $integrityMatches
    live_readiness = 'NOT_ESTABLISHED'
    disposition = 'REVIEW_REQUIRED_BEFORE_LIVE_USE'
    candidate = [ordered]@{
        role = 'Existing historical baseline; not a v6h or current-source build'
        path = $apkRelative
        pinned_sha256 = $pinnedHash
        actual_sha256 = $apkHash
        recorded_sha256 = $buildReport.sha256
        static_audit = $buildReport.staticAudit
        latest_pointer_matches_pinned_build = ([IO.Path]::GetFullPath($pointer) -eq [IO.Path]::GetFullPath((Join-Path $repoRoot $buildRelative)))
        source_files = $sources.Count
        source_matches = $sources.Count - $sourceDifferences.Count
        source_differences = $sourceDifferences
        installed_artifact = 'UNKNOWN'
    }
    runner = [ordered]@{
        path = $runnerRelative
        sha256 = (Get-LocalHash $runnerRelative)
        parse_errors = @($parseErrors).Count
        parse_error_messages = @($parseErrors | ForEach-Object { $_.Message })
        executed = $false
        operational_readiness = 'UNKNOWN; see README source review'
    }
    frozen_artifacts = $frozen
    preservation_against_previous_review = [ordered]@{
        inventory = 'analysis/agent-reviews/claude-resume-20261102/evidence.json:preservation_baseline'
        files_checked = @($priorEvidence.preservation_baseline).Count
        changed_existing_files = $changedExistingFiles
    }
    patterns = $patterns
    log_metrics = $logs
    limitations = @(
        'Counts are bounded to saved logs; absence of a marker is not proof of physical absence.',
        'bad_mac is a log-wide search and requires PID/session correlation before attribution.',
        'A click result is not a verified permission grant; a callback is not a successful transport open.',
        'FIRST FRAME RENDERED is an application report, not independent proof of visible fullscreen video.',
        'This check cannot establish live readiness or authorize any device action.'
    )
} | ConvertTo-Json -Depth 12

if (-not $integrityMatches -or @($parseErrors).Count -ne 0) {
    throw 'Local artifact integrity or runner syntax check failed. See JSON output.'
}
