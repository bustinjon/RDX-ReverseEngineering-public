$ErrorActionPreference='Stop'
$root='./analysis/parallel-aa-receiver/live-test-01'
$reports=@('./analysis/parallel-aa-receiver/LIVE-TEST-01-RESULTS.md','./analysis/parallel-aa-receiver/NEXT-LIVE-TEST.md','./analysis/PARALLEL-AA-RECEIVER-FEASIBILITY.md','./analysis/PARALLEL-AA-FIRST-LIVE-TEST.md','./analysis/parallel-aa-receiver/README.md','./NOTES.md')
$links=0
foreach($path in $reports){
    $body=Get-Content -LiteralPath $path -Raw
    if($body-match'-----BEGIN (?:RSA |EC )?PRIVATE KEY-----'){throw 'Private credential in report'}
    foreach($match in [regex]::Matches($body,'\[[^\]]+\]\(([^)]+)\)')){
        $target=$match.Groups[1].Value.Trim('<','>')
        if($target-match'^(https?:|#)'){continue}
        $target=($target-split'#',2)[0]
        if(-not(Test-Path -LiteralPath (Join-Path (Split-Path $path) $target))){throw "Broken local link: $path -> $target"}
        $links++
    }
}
$summary=Get-Content "$root/summary.json" -Raw|ConvertFrom-Json
if($summary.milestones.M0-notlike'PASS*' -or $summary.milestones.M1-notlike'BLOCKED*' -or -not$summary.cleanup.uninstallSuccess){throw 'Unexpected outcome'}
$commands=@(Get-Content "$root/commands.json" -Raw|ConvertFrom-Json)
if($commands.Count-ne45 -or @($summary.stateChangingCommands).Count-ne4){throw 'Unexpected command audit'}
$manifest=@(Get-Content "$root/evidence-hashes.json" -Raw|ConvertFrom-Json)
foreach($record in $manifest){
    $path=Join-Path $root $record.name
    if((Get-Item -LiteralPath $path).Length-ne$record.bytes -or (Get-FileHash -LiteralPath $path).Hash-ne$record.sha256){throw "Raw evidence integrity mismatch: $($record.name)"}
}
$baseline=Get-Content './analysis/current-update-stack/final-validation.json' -Raw|ConvertFrom-Json
foreach($record in @($baseline.preservedNotes)+@($baseline.preservedAAArtifacts)){
    if((Get-FileHash -LiteralPath $record.path).Hash-ne$record.sha256){throw 'Original notes/factory/Candidate artifacts changed'}
}
$hashes=Get-Content './analysis/parallel-aa-receiver/hashes.json' -Raw|ConvertFrom-Json
foreach($record in $hashes.files){
    if((Get-FileHash -LiteralPath $record.path).Hash-ne$record.sha256){throw 'Previously built prototype source/APK/native changed'}
}
$scripts=@('Invoke-RdxLive01Adb','Analyze-RdxLive01','Verify-RdxLive01Final')
foreach($name in $scripts){
    $tokens=$null;$parseErrors=$null
    [void][Management.Automation.Language.Parser]::ParseFile((Resolve-Path "./scripts/$name.ps1"),[ref]$tokens,[ref]$parseErrors)
    if($parseErrors.Count){throw "Parse errors in $name"}
}
foreach($name in 'stock-before','stock-after','installed'){
    $signature=Get-Content -LiteralPath "$root/$name-signature.txt" -Raw
    if($signature-notmatch'Verified using v1 scheme \(JAR signing\): true'){throw 'Missing API22 signer validation'}
}
$milestones=Get-Content './analysis/parallel-aa-receiver/milestones.json' -Raw|ConvertFrom-Json
if($milestones.liveTest01.M0-ne'PASS' -or $milestones.liveTest01.M1-notlike'BLOCKED*'){throw 'Live milestone status missing'}
$result=[ordered]@{
    utc=[DateTime]::UtcNow.ToString('o');scope='Host-only verification after completed live cleanup; no ADB calls'
    reportsChecked=$reports.Count;localLinksChecked=$links;rawEvidenceHashesChecked=$manifest.Count
    auditedDeviceCommands=$commands.Count;stateChangingCommands='Only new-package install, own Activity launch attempt, own force-stop, own uninstall'
    originalNotesFactoryAndCandidateABUnchanged=$true;testedPrototypeSourcesAndAPKUnchanged=$true
    API22Signatures='Before/after factory Windriver; installed custom independent development signer'
    outcome='M0 PASS; M1 blocked by Lock Task Mode error5 before process; M2/M3 not reached/tested; no higher stage'
    cleanup='Custom package/process/code/data/temp APK absent; stock package/APK/signature and window dump match'
    scriptsParsed=$scripts.Count;limits='No private-data forensic comparison, functional factory projection retest, custom process domain/Surface/native test or complete settings snapshot'
}
$result|ConvertTo-Json -Depth 5|Set-Content './analysis/parallel-aa-receiver/live-test-01-validation.json'
$result|ConvertTo-Json -Depth 5
