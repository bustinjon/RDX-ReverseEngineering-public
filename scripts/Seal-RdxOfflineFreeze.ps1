param([Parameter(Mandatory=$true)][ValidateSet('Links','Seal','Inventory')][string]$Operation)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path $root 'analysis/parallel-aa-receiver'
$session=(Get-Content "$base/latest-offline-freeze.txt" -Raw).Trim()
$stamp=(Get-Item -LiteralPath $session).CreationTimeUtc
$qual=Join-Path $base 'api22-tls-qualifier';$clean=Join-Path $base 'clean-receiver'
function Relative([string]$Path){$full=[IO.Path]::GetFullPath($Path);if(-not$full.StartsWith($root+[IO.Path]::DirectorySeparatorChar)){throw 'Path outside project'};return $full.Substring($root.Length+1).Replace('\','/')}
function ChangedPaths {
 $paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 $trees=@($session,$qual)+@(Get-ChildItem "$clean/build" -Directory|Where-Object CreationTimeUtc -ge $stamp|ForEach-Object FullName)
 foreach($tree in $trees){foreach($f in Get-ChildItem -LiteralPath $tree -Recurse -File){[void]$paths.Add($f.FullName)}}
 foreach($tree in @("$root/analysis","$root/scripts","$root/tools")){foreach($f in Get-ChildItem -LiteralPath $tree -Recurse -File|Where-Object LastWriteTimeUtc -ge $stamp){[void]$paths.Add($f.FullName)}}
 foreach($p in @("$root/NOTES.md","$base/latest-offline-freeze.txt","$clean/latest-build.txt")){[void]$paths.Add([IO.Path]::GetFullPath($p))}
 return @($paths|Sort-Object)
}
function Category([string]$Path){
 $r=Relative $Path
 if($r-like'*/assets/test-credentials/*'){return @('PUBLIC TEST MATERIAL','Reproducible disposable certificate/leaf-key fixture; not Honda credentials')}
 if($r.StartsWith((Relative $session)+'/')){return @('SESSION EVIDENCE','Retained baseline, audit, regression, model or host-tool output')}
 if($r-like'*/build/*'){return @('BUILD ARTIFACT','Clean build, payload comparison, frozen qualifier or preserved candidate')}
 if($r-like'tools/m5/*'){return @('FUTURE M5 KIT','Prepared and host-tested only; no live execution')}
 if($r-like'tools/api22/*'){return @('API22 TOOL','Local search, static audit, guarded future emulator runner or comparator')}
 if($r-like'*/tests/*'){return @('HOST TEST','New independent static provider shadow model; old tests preserved')}
 if([IO.Path]::GetExtension($Path)-in@('.md','.json')){return @('DOCUMENT/STATUS','Current evidence, freeze status, schema, golden expectation or chronology')}
 return @('BUILD/ANALYSIS SOURCE','Offline qualifier, packaging, audit or reproducibility tooling')
}
function FileRow([string]$Path,[string]$Kind,[string]$Reason){$f=Get-Item -LiteralPath $Path;return [pscustomobject]@{path=Relative $Path;size=$f.Length;sha256=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash;category=$Kind;reason=$Reason}}
if($Operation-eq'Links'){
 $docs=@('INDEX.md','README.md','OFFLINE-FOUNDATION-FREEZE.md','EXTENDED-OFFLINE-SESSION-RESULTS.md','LIVE-FOUNDATION-READINESS.md','NEXT-LIVE-DECISION-TREE.md','NEXT-CAR-SESSION-CHECKLIST.md','M7-ENTRY-GATES.md')|ForEach-Object {Join-Path $base $_}
 $docs+=@('README.md','API22-TLS-QUALIFIER-FROZEN.md','RUN-API22-QUALIFICATION-LATER.md','API22-PROVIDER-SHADOW-MODEL.md','LOCAL-API22-ASSET-ARCHAEOLOGY.md','GLOBAL-STATE-AUDIT.md','ASSUMPTION-CONSISTENCY-AUDIT.md','OFFLINE-FOUNDATION-FREEZE.md')|ForEach-Object {Join-Path $clean $_}
 $docs+=@("$qual/README.md","$session/FILE-INVENTORY.md")
 $rows=@(foreach($doc in $docs){foreach($m in [regex]::Matches((Get-Content -LiteralPath $doc -Raw),'\[[^\]]*\]\(([^)]+)\)')){$target=$m.Groups[1].Value.Trim().Trim('<','>');if($target-match'^[a-z]+://|^#|^mailto:'){continue};$path=Join-Path (Split-Path $doc -Parent) ([Uri]::UnescapeDataString(($target-split'#')[0]));[pscustomobject]@{source=Relative $doc;target=$target;exists=Test-Path -LiteralPath $path}}})
 $rows|Export-Csv "$session/current-link-audit.csv" -NoTypeInformation
 $missing=@($rows|Where-Object exists -ne $true);if($missing.Count){$missing|Format-Table|Out-String|Write-Output;throw 'Current local link failure'}
 Write-Output "LINK PASS: $($rows.Count) current local references";return
}
if($Operation-eq'Seal'){
 $state=Get-Content "$base/PROJECT-STATE.json" -Raw|ConvertFrom-Json
 $files=@{}
 foreach($snapshot in @('apks-before.json','live-before.json','source-tests-before.json')){foreach($r in Get-Content "$session/$snapshot" -Raw|ConvertFrom-Json){if((Get-FileHash -LiteralPath $r.Path).Hash-ne$r.Hash){throw "PROTECTED BASELINE CHANGED: $($r.Path)"};$files[$r.Path]=@('PROTECTED BASELINE','Original historical APK/live report/source/test unchanged')}}
 foreach($tree in @("$clean/source","$clean/tests","$clean/test-fixtures","$qual/source","$qual/assets","$qual/golden")){foreach($f in Get-ChildItem -LiteralPath $tree -Recurse -File){$files[$f.FullName]=@('CURRENT INPUT','Frozen receiver/qualifier source, fixture or semantic golden')}}
 foreach($p in ChangedPaths){$r=Relative $p;if([IO.Path]::GetExtension($p)-in@('.ps1','.py')-or([IO.Path]::GetExtension($p)-eq'.md'-and-not$r.StartsWith((Relative $session)+'/'))){$files[$p]=Category $p}}
 foreach($p in @("$base/PROJECT-STATE.json","$qual/FROZEN.json","$qual/results-schema.json","$qual/qualifier-reproducibility.json",(Join-Path $root $state.receiver.DEXpath),(Join-Path $root $state.qualifier.path))){$files[[IO.Path]::GetFullPath($p)]=@('FROZEN STATUS/ARTIFACT','Current authoritative status, binary or payload qualification')}
 $rows=@(foreach($p in $files.Keys|Sort-Object){FileRow $p $files[$p][0] $files[$p][1]})
 $rows|ConvertTo-Json -Depth 5|Set-Content "$base/PROJECT-INTEGRITY.json"
 Write-Output "SEALED: $($rows.Count) inputs/artifacts; self excluded; host reads and manifest write only";return
}
$excluded=@("$session/file-inventory.csv","$session/file-inventory-seal.json")|ForEach-Object {[IO.Path]::GetFullPath($_)}
$rows=@(foreach($p in ChangedPaths){if($p-in$excluded){continue};$c=Category $p;FileRow $p $c[0] $c[1]})
$out="$session/file-inventory.csv";$rows|Export-Csv -LiteralPath $out -NoTypeInformation
$seal=[ordered]@{path=Relative $out;sha256=(Get-FileHash $out).Hash;rows=$rows.Count;bytes=($rows|Measure-Object size -Sum).Sum;scope='Retained created/modified files; see FILE-INVENTORY.md';selfReferenceExclusions=@($excluded|ForEach-Object {Relative $_})}
$seal|ConvertTo-Json|Set-Content "$session/file-inventory-seal.json"
Write-Output "INVENTORY: $($seal.rows) files / $($seal.bytes) bytes; CSV SHA256 $($seal.sha256)"
