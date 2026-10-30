param([Parameter(Mandatory=$true)][string]$Journal,[Parameter(Mandatory=$true)][string]$EvidenceBundle,[Parameter(Mandatory=$true)][ValidateSet('PASS_REVIEWED_BY_USER')][string]$ReviewDecision,[Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference='Stop';$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent;$base="$root/analysis/parallel-aa-receiver";$p="$base/m6-aoa"
# No proof was generated in this session. This is future review tooling, not a live runner.
if(-not(Test-Path -LiteralPath $EvidenceBundle -PathType Leaf)){throw 'Actual retrieved evidence bundle required'}
if((Get-Item -LiteralPath $EvidenceBundle).Length-gt67108864){throw '64MiB reviewed compact bundle policy'}
$lines=Get-Content -LiteralPath $Journal -Raw;if($lines-match'(?i)SYNTHETIC|HOST TOOL TEST|MODEL ONLY'){throw 'Synthetic material cannot become a reviewed live proof'}
New-Item -ItemType Directory -Path $OutputDirectory -ErrorAction Stop|Out-Null;$OutputDirectory=(Resolve-Path $OutputDirectory).Path
& "$root/tools/m5/Get-M5JournalVerdict.ps1" -Journal $Journal -Output "$OutputDirectory/journal-review.json"|Out-Null
$v=Get-Content "$OutputDirectory/journal-review.json" -Raw|ConvertFrom-Json
if($v.verdict-ne'M5 PASS'-or-not$v.grantedAndVerified-or$v.requestsInvoking-ne1-or$v.requestsReturned-ne1-or$v.acceptedCallbacks-ne1){throw 'Only actual reviewed M5 PASS evidence can be signed'}
# Require the reviewed journal itself to occur byte-for-byte in the bounded ZIP bundle.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$expected=(Get-FileHash -LiteralPath $Journal).Hash;$found=$false;$artifactIdentity=$false;$zip=[IO.Compression.ZipFile]::OpenRead((Resolve-Path $EvidenceBundle).Path)
try{foreach($entry in $zip.Entries){if($entry.Length-gt65536-or$entry.Length-eq0){continue};$s=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create();try{$hash=[Convert]::ToHexString($sha.ComputeHash($s));if($hash-eq$expected){$found=$true}}finally{$sha.Dispose();$s.Dispose()};if($entry.Name-eq'session.json'){$reader=[IO.StreamReader]::new($entry.Open());try{$state=$reader.ReadToEnd()|ConvertFrom-Json;if($state.apkSHA256-eq'A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40'-and$state.serial-eq'00000000'-and$state.liveExecuted-eq$true-and$state.phase-in@('RETRIEVED','VERIFIED','UNINSTALLED','FINISHED')){$artifactIdentity=$true}}finally{$reader.Dispose()}}}}finally{$zip.Dispose()}
if(-not$found-or-not$artifactIdentity){throw 'Actual reviewed journal and matching frozen/live retrieval identity required inside evidence ZIP'}
Copy-Item -LiteralPath $EvidenceBundle -Destination "$OutputDirectory/evidence.zip"
$bundleHash=(Get-FileHash "$OutputDirectory/evidence.zip").Hash.ToLowerInvariant();$timestamp=[DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$proof=@('schema_version=1','m5_apk_sha256=A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40','package=com.rdx.fullscreen.m5permission','version=0.2.0-m5-single-port-300s','verdict=PASS','permission_request_count=1','callback_count=1','callback_validated=true','has_permission_verified=true',"evidence_bundle_sha256=$bundleHash","review_timestamp=$timestamp",'reviewed_by_user=true','provenance=LIVE_REVIEWED')-join"`n"
[IO.File]::WriteAllText("$OutputDirectory/proof.m5review",$proof+"`n",[Text.UTF8Encoding]::new($false))
$b=(Get-Content "$p/latest-build.txt" -Raw).Trim();$java='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin/java.exe'
& $java -cp "$b/host" M5ReviewProofTool sign "$OutputDirectory/proof.m5review" "$OutputDirectory/proof.sig" "$OutputDirectory/evidence.zip" "$base/signing/rdx-parallel-development.p12"
if($LASTEXITCODE-ne0){throw 'Review signature validation failed'}
Write-Output 'Reviewed M5 proof prepared. THIS DOES NOT AUTHORIZE OR ENABLE M6. Frozen M6 still refuses live execution.'
