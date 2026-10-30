$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/m5-permission'
$session=(Get-Content "$project/latest-retry-session.txt" -Raw).Trim()
$hostDir=(Get-Content "$project/latest-host-test.txt" -Raw).Trim()
$out=Join-Path $session ('dump-tests-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory $out | Out-Null
$converter=Join-Path $root 'scripts/Convert-RdxM5Dump.ps1'
$token='01234567-89ab-cdef-0123-456789abcdef'
function Fixture([byte[]]$Data,[string]$Token=$token){
 $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Data)).ToLowerInvariant()
 $rows=@("DUMP_BEGIN token=$Token run=synthetic-test bytes=$($Data.Length) sha256=$hash")
 $index=0
 for($offset=0;$offset -lt $Data.Length;$offset+=1200){
  $length=[Math]::Min(1200,$Data.Length-$offset)
  $rows+="DUMP_CHUNK token=$Token index=$index base64=$([Convert]::ToBase64String($Data,$offset,$length))";$index++
 }
 $rows+="DUMP_END token=$Token chunks=$index"
 return $rows
}
$results=@()
function Reject([string]$Name,[string[]]$Rows,[string]$RequestedRun='synthetic-test'){
 $inputFile=Join-Path $out "$Name.log"; $Rows|Set-Content $inputFile
 $rejected=$false
 try { & $converter -LogFile $inputFile -RunId $RequestedRun -OutputDirectory "$out/$Name-output" *> "$out/$Name-result.log" }
 catch { $rejected=$true; $_.ToString()|Set-Content "$out/$Name-error.txt" }
 if(-not$rejected){throw "Malformed dump accepted: $Name"}
 return [pscustomobject]@{case=$Name;PASS=$true;outcome='REJECTED'}
}
$data=[IO.File]::ReadAllBytes("$hostDir/data/journal-tests/m5-granted-result.txt")
$valid=@(Fixture $data);$valid|Set-Content "$out/valid.log"
$positive=(& $converter -LogFile "$out/valid.log" -RunId synthetic-test -OutputDirectory "$out/positive"|ConvertFrom-Json)
if([Convert]::ToBase64String([IO.File]::ReadAllBytes($positive.file)) -cne [Convert]::ToBase64String($data)){throw 'Valid reconstruction bytes differ'}
$results+=[pscustomobject]@{case='multi-chunk persisted result';PASS=$true;outcome='EXACT_BYTES'}
$max=[IO.File]::ReadAllBytes("$hostDir/data/journal-bounds/m5-byte-bound.txt")
@(Fixture $max)|Set-Content "$out/maximum.log"
$maximum=(& $converter -LogFile "$out/maximum.log" -RunId synthetic-test -OutputDirectory "$out/maximum"|ConvertFrom-Json)
if($maximum.bytes -ne 65536){throw 'Maximum reconstruction mismatch'}
$results+=[pscustomobject]@{case='maximum 65536 bytes /55 chunks';PASS=$true;outcome='EXACT_BYTES'}
$results+=Reject 'missing-chunk' @($valid|Where-Object {$_ -notmatch 'DUMP_CHUNK.*index=0 '})
$results+=Reject 'missing-end' @($valid|Where-Object {$_ -notmatch 'DUMP_END'})
$results+=Reject 'wrong-run' $valid 'wrong-run'
$bad=@($valid);$bad[0]=$bad[0] -replace 'sha256=[a-f0-9]{64}',('sha256='+('0'*64))
$results+=Reject 'wrong-hash' $bad
$conflict=@($valid)+@("DUMP_CHUNK token=$token index=0 base64=YQ==")
$results+=Reject 'conflicting-duplicate' $conflict
$second=@(Fixture $data '11234567-89ab-cdef-0123-456789abcdef')
$results+=Reject 'newest-incomplete-no-old-substitution' (@($valid)+@($second|Where-Object {$_ -notmatch 'DUMP_END'}))
$results|ConvertTo-Json|Set-Content "$out/results.json"
Set-Content "$project/latest-dump-test.txt" $out
$results|Format-Table
