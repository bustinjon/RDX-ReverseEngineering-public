$ErrorActionPreference='Stop'
$out='./analysis/recovery-root-evidence'
$documents=@('./NOTES.md','./analysis/RECOVERY-FIRST-PLAN.md','./analysis/ROOT-FEASIBILITY.md','./analysis/ROOT-VS-NONROOT-AA-TEST.md','./analysis/FIRST-LIVE-TEST-CANDIDATES.md','./analysis/OFFICIAL-D-SERIES-ARTIFACTS-NEEDED.md','./analysis/recovery-root-evidence/README.md','./analysis/DEPLOYMENT-PATHS.md','./analysis/TEMPORARY-EXECUTION.md','./analysis/2022-reference-needed.md')
$links=0
foreach($document in $documents){
    $base=Split-Path (Resolve-Path -LiteralPath $document).Path
    foreach($match in [regex]::Matches((Get-Content -LiteralPath $document -Raw),'\[[^\]\r\n]*\]\(([^)\r\n]+)\)')){
        $target=$match.Groups[1].Value.Trim('<','>')
        if($target-match'^[a-zA-Z]+://|^#'){continue}
        $target=($target-split'#',2)[0]
        if(-not(Test-Path -LiteralPath (Join-Path $base $target))){throw "Unresolved report link in ${document}: $target"}
        $links++
    }
}
$previous=Get-Content './analysis/current-update-stack/final-validation.json' -Raw|ConvertFrom-Json
$preserved=@(foreach($record in @($previous.preservedNotes)+@($previous.preservedAAArtifacts)){
    $hash=(Get-FileHash -LiteralPath $record.path -Algorithm SHA256).Hash
    if($hash-ne$record.sha256){throw "Preserved original/candidate changed: $($record.path)"}
    [pscustomobject]@{path=$record.path;sha256=$hash;unchanged=$true}
})
$capture=@(Get-Content './apks/current-update-stack/metadata/files.json' -Raw|ConvertFrom-Json)
foreach($record in $capture){
    $path=Join-Path './apks/current-update-stack' $record.localPath
    if((Get-Item -LiteralPath $path).Length-ne$record.bytes -or (Get-FileHash -LiteralPath $path).Hash-ne$record.sha256){throw "Current original changed: $path"}
}
$parsed=@(foreach($script in Get-ChildItem './scripts' -Filter '*.ps1'){
    $tokens=$null;$errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($script.FullName,[ref]$tokens,[ref]$errors)
    if($errors.Count){throw "Script parse errors: $($script.Name)"}
    $script.Name
})
$summary=Get-Content "$out/search-summary.json" -Raw|ConvertFrom-Json
if($summary.errors-ne0){throw 'Review search errors'}
$emptyPaths=@('./adb/aa-backup.ab','./adb/RDX-Audit/pulls/init.rc','./adb/RDX-Audit/pulls/init.environ.rc','./adb/RDX-Audit/pulls/init.trace.rc','./adb/RDX-Audit/pulls/init.usb.rc')
foreach($path in $emptyPaths){if((Get-Item -LiteralPath $path).Length-ne0){throw "Empty artifact finding changed: $path"}}
$policy=Get-Content "$out/policy-structure.json" -Raw|ConvertFrom-Json
$policyPath='./adb/RDX-Audit/security/sepolicy'
if((Get-FileHash -LiteralPath $policyPath).Hash-ne$policy.policySHA256){throw 'Policy provenance mismatch'}
$bytes=[IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $policyPath))
$checked=@(foreach($expect in @(@{source='system_app';offset=66439},@{source='system_server';offset=126535})){
    $record=$policy.selectedDirectEntries|Where-Object {$_.offset-eq$expect.offset -and $_.source-eq$expect.source -and $_.target-eq'default_prop' -and $_.class-eq'property_service' -and $_.specified-eq1}
    if(@($record).Count-ne1){throw 'Policy clue mismatch'}
    $sourceId=[BitConverter]::ToUInt16($bytes,$record.offset)
    $targetId=[BitConverter]::ToUInt16($bytes,$record.offset+2)
    $source=$policy.types|Where-Object {$_.value-eq$sourceId -and $_.primary-ne0}|Select-Object -First 1
    $target=$policy.types|Where-Object {$_.value-eq$targetId -and $_.primary-ne0}|Select-Object -First 1
    if($source.name-ne$expect.source -or $target.name-ne'default_prop' -or [BitConverter]::ToUInt16($bytes,$record.offset+4)-ne84 -or [BitConverter]::ToUInt16($bytes,$record.offset+6)-ne1 -or [BitConverter]::ToUInt32($bytes,$record.offset+8)-ne1){throw 'Raw policy entry check failed'}
    [pscustomobject]@{source=$source.name;target=$target.name;offset=$record.offset;rawEntryMatches=$true;effectivePolicyVerdict='Not claimed'}
})
$result=[ordered]@{verifiedUtc=[DateTime]::UtcNow.ToString('o');scope='Host-only artifact/report validation; no vehicle/network calls';documents=$documents;relativeLinksResolved=$links;preservedArtifacts=$preserved;currentCollectedFilesUnchanged=$capture.Count;powershellScriptsParsed=$parsed;surveyInputFiles=$summary.files;surveyArchiveContainers=$summary.archiveContainers;surveyErrors=$summary.errors;confirmedEmptyArtifacts=$emptyPaths;rawPolicyCluesChecked=$checked;decision='No candidate passes recovery/entry gate. No live root or modified-AA test recommended.'}
$result|ConvertTo-Json -Depth 7|Set-Content "$out/final-validation.json"
[pscustomobject]$result|Select-Object verifiedUtc,scope,relativeLinksResolved,currentCollectedFilesUnchanged,surveyInputFiles,surveyArchiveContainers,surveyErrors,decision|ConvertTo-Json
