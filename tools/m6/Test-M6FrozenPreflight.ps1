param([string]$ProofDirectory)
$ErrorActionPreference='Stop';$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent;$p="$root/analysis/parallel-aa-receiver/m6-aoa"
$f=Get-Content "$p/FROZEN.json" -Raw|ConvertFrom-Json;$apk=Join-Path $root $f.path;if((Get-FileHash -LiteralPath $apk).Hash-ne$f.sha256){throw 'Frozen M6 APK mismatch'}
$audit=Get-Content $f.audit -Raw|ConvertFrom-Json;if(-not$audit.PASS-or$audit.sha256-ne$f.sha256-or$audit.liveExecutionEnabled-ne$f.liveExecutionEnabled){throw 'Frozen M6 audit mismatch'}
if((Get-FileHash "$p/assets/project-reviewer.cer").Hash-ne$f.reviewerCertificateSHA256){throw 'Pinned project review certificate changed'}
$proofOK=$false
if($ProofDirectory){$ProofDirectory=(Resolve-Path $ProofDirectory).Path;$b=$f.build;$java='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin/java.exe';& $java -cp "$b/host" M5ReviewProofTool verify "$ProofDirectory/proof.m5review" "$ProofDirectory/proof.sig" "$ProofDirectory/evidence.zip" "$p/assets/project-reviewer.cer" *> $null;if($LASTEXITCODE-ne0){throw 'Reviewed M5 PASS proof/signature/evidence invalid'};$proofOK=$true}
$adb=Join-Path $root 'adb/adb.exe';if(-not(Test-Path -LiteralPath $adb)){throw 'Local ADB executable absent; no ADB invoked'}
[ordered]@{apk=$apk;sha256=$f.sha256;package=$f.package;version=$f.version;liveExecutionEnabled=$f.liveExecutionEnabled;reviewedM5Pass=$proofOK;gate=if($proofOK){'M5 evidence satisfied; frozen live block still applies'}else{'M5 PASS PROOF UNSATISFIED'};adb=$adb;ADBexecuted=$false;staticAudit='PASS';nextLive='M5 RETRY ONLY'}|ConvertTo-Json
