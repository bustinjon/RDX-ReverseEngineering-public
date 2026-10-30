param([Parameter(Mandatory=$true)][string]$Session)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$base=Join-Path $root 'analysis/parallel-aa-receiver'
$Session=(Resolve-Path -LiteralPath $Session).Path
if(-not$Session.StartsWith($base+[IO.Path]::DirectorySeparatorChar)){throw 'Session outside analysis root'}
$start=(Get-Item -LiteralPath $Session).CreationTimeUtc
function Relative([string]$Path){$full=[IO.Path]::GetFullPath($Path);if(-not$full.StartsWith($root+[IO.Path]::DirectorySeparatorChar)){throw 'Path outside project'};return $full.Substring($root.Length+1).Replace('\','/')}
function HashRow([string]$Path,[string]$Category,[string]$Reason){$f=Get-Item -LiteralPath $Path;return [pscustomobject]@{path=(Relative $f.FullName);size=$f.Length;sha256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash;category=$Category;reason=$Reason}}

# These snapshots existed before M6 implementation. Never re-baseline protected evidence.
$protectedCount=0
foreach($snapshot in @('apks-before.json','all-current-apks-before.json','live-reports-before.json','source-tests-before.json')){
    foreach($f in Get-Content "$Session/$snapshot" -Raw|ConvertFrom-Json){if((Get-FileHash -LiteralPath $f.Path).Hash-ne$f.Hash){throw "Protected mismatch: $($f.Path)"};$protectedCount++}
}
$state=Get-Content "$base/PROJECT-STATE.json" -Raw|ConvertFrom-Json
if($state.nextLive-ne'M5 RETRY ONLY'-or$state.M6enabled-or$state.M6.artifact.liveExecutionEnabled){throw 'Milestone/live gate mismatch'}
if((Get-FileHash (Join-Path $root $state.frozenM5.path)).Hash-ne'A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40'){throw 'Frozen M5 mismatch'}
if((Get-FileHash (Join-Path $root $state.M6.artifact.path)).Hash-ne$state.M6.artifact.sha256){throw 'Frozen M6 mismatch'}

$allowedChanged=@('NOTES.md','analysis/parallel-aa-receiver/BUILD-VALIDATION-MATRIX.md','analysis/parallel-aa-receiver/clean-receiver/README.md','analysis/parallel-aa-receiver/INDEX.md','analysis/parallel-aa-receiver/LIVE-FOUNDATION-READINESS.md','analysis/parallel-aa-receiver/M6-AOA-ONLY-TEST.md','analysis/parallel-aa-receiver/NEXT-LIVE-DECISION-TREE.md','analysis/parallel-aa-receiver/OFFLINE-FOUNDATION-FREEZE.md','analysis/parallel-aa-receiver/PROJECT-STATE.json')
$old=@{};$changed=@()
foreach($f in Get-Content "$Session/integrity-before.json" -Raw|ConvertFrom-Json){
    $old[$f.path]=$f
    $now=HashRow (Join-Path $root $f.path) $f.category $f.reason
    if($now.sha256-ne$f.sha256){if($f.path-notin$allowedChanged){throw "Unreviewed change to prior integrity manifest: $($f.path)"};$changed+=$f.path}
}

# Exact retained session scope; do not crawl/hash unrelated drives or research archives.
$files=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
function Include([string]$Path){if(Test-Path -LiteralPath $Path -PathType Leaf){[void]$files.Add([IO.Path]::GetFullPath($Path))}else{throw "Missing inventory input: $Path"}}
function IncludeTree([string]$Path){foreach($f in Get-ChildItem -LiteralPath $Path -Recurse -File){Include $f.FullName}}
IncludeTree "$base/m6-aoa"
foreach($build in Get-ChildItem "$base/clean-receiver/build" -Directory|Where-Object CreationTimeUtc -ge $start){IncludeTree $build.FullName}
foreach($dir in @("$root/scripts","$root/tools")){
    foreach($f in Get-ChildItem -LiteralPath $dir -Recurse -File){$rel=Relative $f.FullName;if($old.ContainsKey($rel)){if((Get-FileHash -LiteralPath $f.FullName).Hash-ne$old[$rel].sha256){Include $f.FullName}}elseif($f.CreationTimeUtc-ge$start-or$f.LastWriteTimeUtc-ge$start){Include $f.FullName}}
}
foreach($f in Get-ChildItem -LiteralPath $base -File){$rel=Relative $f.FullName;if($rel-eq'analysis/parallel-aa-receiver/PROJECT-INTEGRITY.json'){continue};if($rel-in$changed-or(-not$old.ContainsKey($rel)-and($f.CreationTimeUtc-ge$start-or$f.LastWriteTimeUtc-ge$start))){Include $f.FullName}}
foreach($rel in $changed){Include (Join-Path $root $rel)}

function Classify([string]$Path){
    $rel=Relative $Path
    if($rel-match'/m6-aoa/build/FINAL/'){return @('FROZEN M6 ARTIFACT','Disabled review artifact; never live-executed')}
    if($rel-match'/m6-aoa/(source|host|tests|fixtures|assets)/'){return @('M6 IMPLEMENTATION/TEST INPUT','New bounded core, Android glue, host oracle, fixtures or PUBLIC review certificate')}
    if($rel-match'/build/'){return @('BUILD/REGRESSION EVIDENCE','Retained build payload or diagnostic; FINAL/FROZEN identifies authoritative artifact')}
    if($rel-match'^(scripts|tools)/'){return @('HOST TOOL','Offline build/audit or prepared future gated tooling; no live stage executed')}
    if($rel.StartsWith((Relative $Session)+'/')){return @('SESSION EVIDENCE','Baseline, regression, preservation, tool safety or freeze diagnostic')}
    return @('DOCUMENT/STATUS','M6 findings, current status, schema, chronology or exact integrity metadata')
}

# Critical manifest retains the prior baseline and adds current authoritative M6 inputs/artifacts.
$critical=@{}
foreach($f in $old.Values){$critical[$f.path]=HashRow (Join-Path $root $f.path) $f.category $f.reason}
foreach($path in $files){$rel=Relative $path;if($rel-match'/m6-aoa/build/'-and$rel-notmatch'/m6-aoa/build/FINAL/'){continue};if($rel-match'/clean-receiver/build/'){continue};$c=Classify $path;$critical[$rel]=HashRow $path $c[0] $c[1]}
$dex=Join-Path $root $state.receiver.DEXpath;$critical[(Relative $dex)]=HashRow $dex 'CURRENT RECEIVER DEX' 'Unchanged production payload from final clean build'
foreach($name in @('session-results.json','receiver-reproducibility.json','observed-state-edges.csv','credential-cleanup.json')){$p=Join-Path $Session $name;$critical[(Relative $p)]=HashRow $p 'SESSION EVIDENCE' 'Final regression, state coverage, reproduction or disposable credential cleanup'}
$critical.Values|Sort-Object path|ConvertTo-Json -Depth 6|Set-Content "$base/PROJECT-INTEGRITY.json"
Include "$base/PROJECT-INTEGRITY.json"

# Every newly prepared PowerShell file is parsed; this performs no ADB/runtime action.
$parsed=@()
foreach($path in $files|Where-Object {$_-like'*.ps1'}){$tokens=$null;$errors=$null;[void][Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors);if($errors.Count){throw "PowerShell parse failure: $path $errors"};$parsed+=Relative $path}

$inventoryDoc=@'
# M6 exact retained-file inventory — 2026-10-25

[FILE-INVENTORY.csv](FILE-INVENTORY.csv) records each retained created/modified session file with relative path, size, SHA256, category and reason. This covers the separate M6 project (including intermediate builds), both new receiver builds, session evidence and changed/new current documents/tools. Unchanged protected files are separately checked against the pre-session snapshots and [PROJECT-INTEGRITY.json](../PROJECT-INTEGRITY.json).

The CSV and SEAL.json exclude their own bytes to avoid circular hashes. SEAL.json pins the CSV and project-integrity manifest. This document is included in the CSV. Nine newly generated test PKCS12 containers were deleted before sealing; credential-cleanup.json records hashes and paths. No raw private test keys are in the inventory/report. Intermediate failure diagnostics are preserved; they are not final PASS artifacts.

The main receiver remains57 modules with unchanged DEX; M6 is a separate9-module disabled APK. No ADB/hardware or live task was executed. Next LIVE M5 RETRY ONLY; M6 LIVE-DISABLED; M7 NOT AUTHORIZED.
'@
$inventoryDoc|Set-Content "$Session/FILE-INVENTORY.md"

# Audit current index/new M6 documents; historical reports are not rewritten.
$linkRows=@()
$docs=@($files|Where-Object {$_-like'*.md'-and$_-notmatch'/build/|\\build\\'})+@("$Session/FILE-INVENTORY.md")
foreach($doc in $docs|Sort-Object -Unique){
    foreach($m in [regex]::Matches((Get-Content -LiteralPath $doc -Raw),'(?<!!)\[[^\]]*\]\((?<p><[^>]+>|[^)\s]+)(?:\s+"[^"]*")?\)')){
        $target=$m.Groups['p'].Value.Trim('<','>');if($target-match'^[a-zA-Z][a-zA-Z0-9+.-]*:|^#'){continue};$target=($target-split'#',2)[0];$target=[Uri]::UnescapeDataString($target)
        $resolved=[IO.Path]::GetFullPath((Join-Path (Split-Path $doc -Parent) $target))
        $present=Test-Path -LiteralPath $resolved
        # These two exact reserved outputs are generated after QA and checked again at the end.
        if($resolved-in@("$Session\FILE-INVENTORY.csv","$Session\SEAL.json")){$present=$true}
        $linkRows+=[pscustomobject]@{document=(Relative $doc);target=$target;exists=$present}
    }
}
$linkRows|ConvertTo-Json -Depth 4|Set-Content "$Session/current-link-audit.json"
if(@($linkRows|Where-Object {-not$_.exists}).Count){$linkRows|Where-Object {-not$_.exists}|Format-Table|Out-String|Write-Output;throw 'Current-document link audit failed'}

$positive=(& "$root/tools/Test-RdxOfflineIntegrity.ps1"|Out-String).Trim()
$bad=@(Get-Content "$base/PROJECT-INTEGRITY.json" -Raw|ConvertFrom-Json)
$wrong=$bad|Where-Object path -eq $state.frozenM5.path
if(@($wrong).Count-ne1){throw 'Expected exact M5 protected manifest row'}
$wrong.sha256='0'*64
$bad|ConvertTo-Json -Depth 6|Set-Content "$Session/integrity-negative-fixture.json"
$negative=$false
try{& "$root/tools/Test-RdxOfflineIntegrity.ps1" -Manifest "$Session/integrity-negative-fixture.json" *> "$Session/integrity-negative-test.txt"}catch{$negative=$_.Exception.Message-match'INTEGRITY FAIL'}
if(-not$negative){throw 'Wrong-hash fixture was not rejected'}
$positiveAgain=(& "$root/tools/Test-RdxOfflineIntegrity.ps1"|Out-String).Trim()
[ordered]@{schema=1;PASS=$true;scope='HOST READ/WRITE ONLY; NO ADB, hardware, installation or live execution';protectedSnapshotRows=$protectedCount;authorizedPriorChanges=$changed;criticalFiles=$critical.Count;parsedScripts=$parsed;linksChecked=$linkRows.Count;brokenLinks=0;integrityPositive=$positive;wrongExpectedHashRefused=$negative;integrityPositiveAfter=$positiveAgain;frozenM5=$state.frozenM5.sha256;frozenM6=$state.M6.artifact.sha256}|ConvertTo-Json -Depth 6|Set-Content "$Session/closeout-qa.json"

# Seal last. Any subsequent change requires rerunning this script and re-verifying the seal.
IncludeTree $Session
$excluded=@("$Session/FILE-INVENTORY.csv","$Session/SEAL.json")
$rows=@(foreach($path in $files|Sort-Object){if($path-in$excluded){continue};$c=Classify $path;HashRow $path $c[0] $c[1]})
$rows|Sort-Object path|Export-Csv "$Session/FILE-INVENTORY.csv" -NoTypeInformation
foreach($row in $rows){$path=Join-Path $root $row.path;if((Get-Item -LiteralPath $path).Length-ne$row.size-or(Get-FileHash -LiteralPath $path).Hash-ne$row.sha256){throw "Inventory changed while sealing: $($row.path)"}}
[ordered]@{schema=1;session=(Relative $Session);retainedFiles=$rows.Count;inventoryCSV=(Relative "$Session/FILE-INVENTORY.csv");inventorySHA256=(Get-FileHash "$Session/FILE-INVENTORY.csv").Hash;projectIntegritySHA256=(Get-FileHash "$base/PROJECT-INTEGRITY.json").Hash;selfExclusions=@('FILE-INVENTORY.csv','SEAL.json');verification='Every inventory row rehashed after writing; no edits afterward';nextLive='M5 RETRY ONLY';M6='OFFLINE-PREPARED / LIVE-DISABLED';M7='NOT AUTHORIZED'}|ConvertTo-Json -Depth 5|Set-Content "$Session/SEAL.json"
foreach($link in $linkRows){$doc=Join-Path $root $link.document;if(-not(Test-Path -LiteralPath (Join-Path (Split-Path $doc -Parent) $link.target))){throw "Final link missing: $($link.document) -> $($link.target)"}}
Write-Output "M6 SEAL PASS: $($rows.Count) retained file rows; $($critical.Count) critical project files; $($linkRows.Count) current links; $($parsed.Count) scripts parsed; protected snapshots unchanged; wrong expected hash refused. NO ADB/hardware."
