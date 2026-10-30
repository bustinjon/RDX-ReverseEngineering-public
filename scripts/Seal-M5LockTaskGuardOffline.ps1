param([Parameter(Mandatory=$true)][string]$SessionDirectory)
# Host file verification/sealing only. No ADB executable or vehicle commands.
$ErrorActionPreference='Stop';$root=Split-Path $PSScriptRoot -Parent
$s=(Resolve-Path -LiteralPath $SessionDirectory).Path
if(-not$s.StartsWith((Join-Path $root 'analysis/parallel-aa-receiver/m5-locktask-guard-'),[StringComparison]::OrdinalIgnoreCase)){throw 'Expected local guard session directory'}
$base=Join-Path $root 'analysis/parallel-aa-receiver'
function Rel([string]$Path){return [IO.Path]::GetRelativePath($root,$Path).Replace('\','/')}
function Row([string]$Path){$f=Get-Item -LiteralPath $Path;return [pscustomobject]@{path=Rel $f.FullName;size=$f.Length;sha256=(Get-FileHash -LiteralPath $f.FullName).Hash}}
$allowed=@('NOTES.md','tools/m5/Invoke-M5FutureSession.ps1','analysis/parallel-aa-receiver/PROJECT-STATE.json','analysis/parallel-aa-receiver/NEXT-CAR-SESSION-CHECKLIST.md','analysis/parallel-aa-receiver/NEXT-LIVE-DECISION-TREE.md','analysis/parallel-aa-receiver/INDEX.md','analysis/parallel-aa-receiver/OFFLINE-FOUNDATION-FREEZE.md','analysis/parallel-aa-receiver/BUILD-VALIDATION-MATRIX.md')
$before=@(Get-Content "$s/integrity-before.json" -Raw|ConvertFrom-Json);$critical=@{};$changes=@();$unchanged=0
foreach($f in $before){$row=Row (Join-Path $root $f.path);if($row.sha256-ne$f.sha256){if($f.path-notin$allowed){throw "Unexpected baseline change: $($f.path)"};$changes+=$row}else{$unchanged++};$critical[$row.path]=$row}
foreach($f in (Get-Content "$s/protected-source-warning.json" -Raw|ConvertFrom-Json)){if((Get-FileHash -LiteralPath $f.Path).Hash-ne$f.Hash){throw "Source/warning artifact changed: $($f.Path)"}}
$tests=Get-Content "$s/tests-final-repeat/summary.json" -Raw|ConvertFrom-Json
if(-not$tests.PASS-or$tests.deterministic-ne57-or$tests.randomized-ne1000-or$tests.actualADBInvocations-ne0){throw 'Final suite does not match reviewed expectations'}
$new=@('scripts/Test-M5ArmReadiness.ps1','scripts/Seal-M5LockTaskGuardOffline.ps1','tools/m5/M5ArmReadiness.ps1','tools/m5/Test-M5ArmReadinessOffline.ps1','tools/m5/m5-arm-readiness.schema.json','analysis/parallel-aa-receiver/latest-m5-locktask-guard.txt','analysis/parallel-aa-receiver/M5-LOCKTASK-LIVE-FAILURE-RECONSTRUCTION.md','analysis/parallel-aa-receiver/M5-RETRY-LOCKTASK-GUARD-PLAN.md')
$evidence=@('SESSION-RESULTS.md','OFFLINE-COMMANDS.md','preservation.json','contract-and-reproducibility.json','schema-validation-final.json','freshness-evidence.json','static-getter-evidence.json','getter-dispatch-excerpt.txt','am-lock-task-mutator-excerpt.txt','m5-host-tests-final.txt','tests-final-repeat/summary.json','tests-final-repeat/deterministic-cases.json','tests-final-repeat/static-audit.json')
foreach($p in $new){$r=Row (Join-Path $root $p);$critical[$r.path]=$r};foreach($p in $evidence){$r=Row "$s/$p";$critical[$r.path]=$r}
$docs=@("$base/M5-LOCKTASK-LIVE-FAILURE-RECONSTRUCTION.md","$base/M5-RETRY-LOCKTASK-GUARD-PLAN.md","$base/NEXT-CAR-SESSION-CHECKLIST.md","$base/NEXT-LIVE-DECISION-TREE.md","$base/INDEX.md","$s/SESSION-RESULTS.md")
$links=@()
foreach($d in $docs){foreach($m in [regex]::Matches((Get-Content $d -Raw),'(?<!!)\[[^\]]*\]\((?<p>[^)\s]+)\)')){$target=$m.Groups['p'].Value;if($target-match'^[a-zA-Z][a-zA-Z0-9+.-]*:|^#'){continue};$p=Join-Path (Split-Path $d -Parent) ($target-split'#')[0];$ok=Test-Path -LiteralPath $p;$links+=[pscustomobject]@{document=Rel $d;target=$target;exists=$ok};if(-not$ok){throw "Missing current doc reference $d -> $target"}}}
$links|ConvertTo-Json -Depth 4|Set-Content "$s/link-audit.json"
@($critical.Values|Sort-Object path)|ConvertTo-Json -Depth 5|Set-Content "$base/PROJECT-INTEGRITY.json"
& "$root/tools/Test-RdxOfflineIntegrity.ps1" -Manifest "$base/PROJECT-INTEGRITY.json" | Set-Content "$s/final-integrity.txt"
$files=@($allowed|ForEach-Object {Join-Path $root $_})+@($new|ForEach-Object {Join-Path $root $_})+@("$base/PROJECT-INTEGRITY.json")+@(Get-ChildItem $s -Recurse -File|Where-Object {$_.Name-notin@('FILE-INVENTORY.csv','SHA256-MANIFEST.json','SEAL.json')}|ForEach-Object FullName)
$inventory=@($files|Sort-Object -Unique|ForEach-Object {$row=Row $_;$category=if($row.path-like'*m5-locktask-guard-*'){'LOCAL EVIDENCE/TEST/ANALYSIS'}elseif($row.path-like'*.ps1'-or$row.path-like'*schema.json'){'HOST ORCHESTRATION/TEST'}else{'CURRENT REPORT/STATE/INDEX'};$row|Add-Member NoteProperty category $category;$row|Add-Member NoteProperty reason 'Offline lock-task readiness preparation; no production APK/source rebuild';$row})
$inventory|Export-Csv "$s/FILE-INVENTORY.csv" -NoTypeInformation
$inventory|Select-Object path,size,sha256|ConvertTo-Json -Depth 4|Set-Content "$s/SHA256-MANIFEST.json"
[ordered]@{schema=1;utc=[DateTime]::UtcNow.ToString('o');scope='OFFLINE ONLY';ADBInvocations=0;baselineFiles=$before.Count;baselineUnchanged=$unchanged;authorizedCurrentChanges=$changes.Count;criticalFiles=$critical.Count;inventoryFiles=$inventory.Count;inventoryExclusions='This inventory, its JSON hash manifest and this seal excluded to avoid recursive hashing';inventorySHA256=(Get-FileHash "$s/FILE-INVENTORY.csv").Hash;hashManifestSHA256=(Get-FileHash "$s/SHA256-MANIFEST.json").Hash;projectIntegritySHA256=(Get-FileHash "$base/PROJECT-INTEGRITY.json").Hash;guardChecks=57;randomized=1000;seed=20261025;getterRuntime='UNTESTED; mismatch/unknown refuses';M5='FROZEN; latest live INCONCLUSIVE; not armed';M6='DISABLED';M7='NOT AUTHORIZED';next='Car + phone and separate M5 retry authorization required; no automatic live action'}|ConvertTo-Json -Depth 5|Set-Content "$s/SEAL.json"
Get-Content "$s/final-integrity.txt"
Write-Output "OFFLINE GUARD SEAL PASS: $($inventory.Count) files inventoried; $unchanged baseline files unchanged; $($changes.Count) authorized current edits. No ADB."
