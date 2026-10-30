param([string]$Manifest)
$ErrorActionPreference='Stop';$root=Split-Path $PSScriptRoot -Parent
if(-not$Manifest){$state=Get-Content "$root/analysis/parallel-aa-receiver/PROJECT-STATE.json" -Raw|ConvertFrom-Json;$Manifest=Join-Path $root $state.integrityManifest}
$rows=@(Get-Content -LiteralPath $Manifest -Raw|ConvertFrom-Json);if(-not$rows.Count){throw 'Empty integrity manifest'};$mismatches=@()
foreach($f in $rows){$p=[IO.Path]::GetFullPath((Join-Path $root $f.path));if(-not$p.StartsWith($root+[IO.Path]::DirectorySeparatorChar)){throw 'Manifest path outside project'};if(-not(Test-Path -LiteralPath $p -PathType Leaf)){$mismatches+=[pscustomobject]@{path=$f.path;problem='MISSING'};continue};$hash=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash;if($hash-ne$f.sha256){$mismatches+=[pscustomobject]@{path=$f.path;problem='SHA256 MISMATCH';expected=$f.sha256;actual=$hash}}}
if($mismatches.Count){$mismatches|ConvertTo-Json -Depth 4;throw 'INTEGRITY FAIL: exact mismatches above; no repair performed'}
Write-Output "INTEGRITY PASS: $($rows.Count) project files match; frozen M5, historical APKs, live reports, receiver DEX and qualifier included. HOST READS ONLY."
