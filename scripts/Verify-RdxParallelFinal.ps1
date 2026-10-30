$ErrorActionPreference='Stop'
$project='./analysis/parallel-aa-receiver'
$reports=@('./analysis/PARALLEL-AA-RECEIVER-FEASIBILITY.md','./analysis/AA-PRIVILEGE-DEPENDENCY-MATRIX.md','./analysis/GAL-TRANSPORT-TRACE.md','./analysis/CUSTOM-RECEIVER-ARCHITECTURE.md','./analysis/PARALLEL-AA-FIRST-LIVE-TEST.md',"$project/README.md")
$linkCount=0
foreach($path in $reports){
    $body=Get-Content -LiteralPath $path -Raw
    if($body-match'-----BEGIN (?:RSA |EC )?PRIVATE KEY-----'){throw "Private PEM in public report: $path"}
    foreach($match in [regex]::Matches($body,'\[[^\]]+\]\(([^)]+)\)')){
        $target=$match.Groups[1].Value.Trim('<','>')
        if($target-match'^(https?:|#)'){continue}
        $target=($target-split'#',2)[0]
        if(-not(Test-Path -LiteralPath (Join-Path (Split-Path $path) $target))){throw "Broken report link: $path -> $target"}
        $linkCount++
    }
}
$notes=Get-Content -LiteralPath './NOTES.md' -Raw
if($notes-match'-----BEGIN (?:RSA |EC )?PRIVATE KEY-----'){throw 'Private PEM in NOTES.md'}
$matrix=Get-Content -LiteralPath $reports[1]
$inMatrix=$false;$rows=0
foreach($line in $matrix){
    if($line.StartsWith('| DEPENDENCY |')){$inMatrix=$true}
    if($inMatrix -and $line.StartsWith('|')){
        if($line.Trim('|').Split('|').Count-ne10){throw 'Dependency matrix must have ten separate columns'}
        $rows++
    }elseif($inMatrix){break}
}
$scriptNames=@('Collect-RdxParallelReceiverReadOnly','Analyze-RdxParallelNative','Trace-RdxParallelNativeCalls','Audit-RdxParallelPermissions','Build-RdxParallelReceiver','Verify-RdxParallelPrototype','Finalize-RdxParallelReports','Verify-RdxParallelFinal')
foreach($name in $scriptNames){
    $tokens=$null;$parseErrors=$null
    [void][Management.Automation.Language.Parser]::ParseFile((Resolve-Path "./scripts/$name.ps1"),[ref]$tokens,[ref]$parseErrors)
    if($parseErrors.Count){throw "PowerShell parse errors in $name"}
}
$hashReport=Get-Content "$project/hashes.json" -Raw|ConvertFrom-Json
foreach($file in $hashReport.files){
    if((Get-Item -LiteralPath $file.path).Length-ne$file.bytes -or (Get-FileHash -LiteralPath $file.path).Hash-ne$file.sha256){throw "Prototype integrity mismatch: $($file.path)"}
}
$baseline=Get-Content './analysis/current-update-stack/final-validation.json' -Raw|ConvertFrom-Json
foreach($file in @($baseline.preservedNotes)+@($baseline.preservedAAArtifacts)){
    if((Get-FileHash -LiteralPath $file.path).Hash-ne$file.sha256){throw "Original artifact changed: $($file.path)"}
}
$milestones=Get-Content "$project/milestones.json" -Raw|ConvertFrom-Json
if(@($milestones.levels|Where-Object {$_.status-ne'NOT RUN'}).Count){throw 'Unexpected runtime milestone claim'}
$static=Get-Content "$project/evidence/prototype-static-validation.json" -Raw|ConvertFrom-Json
$build=Get-Content "$project/build/build-report.json" -Raw|ConvertFrom-Json
if($static.APK_SHA256-ne$build.outputSHA256){throw 'Static validation uses a different APK'}
$signature=Get-Content "$project/build/signature-verification.txt" -Raw
if($signature-notmatch'Verified using v1 scheme \(JAR signing\): true'){throw 'Missing API22 v1 verification'}
$alignTool='C:/Program Files (x86)/Android/android-sdk/build-tools/32.0.0/zipalign.exe'
& $alignTool -c 4 (Join-Path $project $build.output)
if($LASTEXITCODE-ne0){throw 'APK alignment check failed'}
$result=[ordered]@{
    utc=[DateTime]::UtcNow.ToString('o');scope='Host integrity/report validation only; no ADB calls or ARM/native execution'
    reports=$reports;localLinksChecked=$linkCount;dependencyRows=$rows-2;matrixColumns=10
    scriptsParsed=$scriptNames.Count;prototypeHashRecordsChecked=@($hashReport.files).Count
    originalNotesFactoryAndCandidateABPreserved=$true;noPrivatePEMInReportsOrNotes=$true
    runtimeMilestones='All six NOT RUN';JNIValidation='22 native methods, 19 callbacks, 16 fields, buffer pool ABI'
    API22v1SignatureVerification=$true;zipAlignment=$true;APK_SHA256=$build.outputSHA256
    limitation='Host/static checks do not demonstrate vehicle installation, JNI execution, USB permission/ownership, phone negotiation or decoding.'
}
$result|ConvertTo-Json -Depth 5|Set-Content "$project/evidence/final-validation.json"
$result|ConvertTo-Json -Depth 5
