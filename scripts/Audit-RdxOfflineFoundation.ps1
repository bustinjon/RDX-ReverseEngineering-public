param([Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference='Stop';$root=Split-Path $PSScriptRoot -Parent;$base=Join-Path $root 'analysis/parallel-aa-receiver';$clean=Join-Path $base 'clean-receiver';$src="$clean/source/com/rdx/fullscreen/clean"
New-Item -ItemType Directory -Force $OutputDirectory|Out-Null
$checks=@()
function Check([string]$Name,[string]$File,[string]$Pattern,[string]$Meaning){$text=Get-Content -LiteralPath $File -Raw;$script:checks+=[pscustomobject]@{name=$Name;file=$File;PASS=[regex]::IsMatch($text,$Pattern);meaning=$Meaning}}
Check 'Conservative profile' "$src/VideoConfig.java" 'new VideoConfig\(1280,720,0,32,229,60\)' 'Nominal720 minus total32 = active688; known profile only'
Check 'Experimental opt-in' "$src/VideoConfig.java" 'new VideoConfig\(1920,1080,0,360,229,30\)' 'Nominal raster distinct from codec raster/crop; not phone acceptance'
Check 'Placement unknown' "$src/VideoConfig.java" 'placement=Placement.UNSPECIFIED' 'No180/180 or touch transform'
Check 'Media status domain' "$src/MediaConfigStatus.java" 'STATUS_WAIT\(1\), STATUS_READY\(2\)' 'Does not reuse control success0'
Check 'AA fragment' "$src/SecureBodyPipeline.java" 'PLAINTEXT_FRAGMENT=16128' 'Target0x3F00 plaintext threshold'
Check 'Three lengths' "$src/OuterFrameContext.java" 'ciphertextBodyLength,logicalTotal' 'Raw context retains ciphertext length and logical total separately'
Check 'M6 disabled' "$src/AoaNegotiator.java" 'EXECUTION_ENABLED=false' 'No active AOA path'
Check 'Touch source' "$src/InputConfig.java" '1325,720,60,40,true,true' 'Factory reference metadata; no speculative transform'
Check 'Provider completion gate' "$src/MemoryTlsEngine.java" 'profile=provider.equals\("SunJSSE"\)' 'AndroidOpenSSL not automatically qualified'
Check 'Unknown AU boundary' "$src/VideoDataPlane.java" 'UNKNOWN_PACKET_TO_AU_BOUNDARY' 'No default wire packet=AU assumption'
Check 'No running state' "$src/HondaMediaFlow.java" 'MEDIA_CONFIGURATION_SELECTED,CLOSED' 'Selection does not claim playback'
if(@($checks|Where-Object {-not$_.PASS}).Count){$checks|ConvertTo-Json|Set-Content "$OutputDirectory/consistency.json";throw 'Source/document invariant mismatch'}
$checks|ConvertTo-Json|Set-Content "$OutputDirectory/consistency.json"
$rules=[ordered]@{WholeStreamTls='TLS wraps (the )?(entire|whole).*AA|entire AA.*encrypt';TypeOutside='message type.*outside.*encrypt';MediaStatusZero='(media|Config).*success.?=.?0|SUCCESS.?=.?0.*(media|Config)';WrongSetup='0x8000.*configuration index';DisplayAck='ACK\s*(==|=|means).*display';Running='MEDIA_RUNNING|video running after Start';CropSplit='180/180|180 top|touch offset.?=.?180';M5Failure='M5 (FAIL|failure)';EarlyMilestone='next live.*M4|NEXT LIVE SESSION: M4';Qualified='works on API22|TLS verified on target|API22.*(QUALIFIED|FINALIZED)';JniRequired='Honda JNI.*required';LegacySetup='Setup field1 semantics/direction remain disputed'}
$docs=@(Get-ChildItem $clean -File -Filter *.md)+@(Get-ChildItem $base -File -Filter *.md)+@(Get-Item "$root/analysis/CUSTOM-RECEIVER-ARCHITECTURE.md","$root/analysis/GAL-TRANSPORT-TRACE.md","$root/analysis/AA-PRIVILEGE-DEPENDENCY-MATRIX.md")
$hits=@(foreach($f in $docs){$lines=Get-Content -LiteralPath $f.FullName;for($i=0;$i-lt$lines.Count;$i++){foreach($rule in $rules.Keys){if($lines[$i]-match$rules[$rule]){$negative=$lines[$i]-match'NOT |not |NO |no |never|Never|do not|Do not|Historical|historical|earlier|Earlier|UNKNOWN|UNQUALIFIED|UNAVAILABLE|does not|FALSE POSITIVE|INCONCLUSIVE|require demonstrated|!=|≠';$historical=$f.Name-match'RESULTS|VALIDATION|IMPLEMENTATION|EVIDENCE|REVIEW|TRACE|ARCHITECTURE|CONTRACT|before-|after-|PROTOCOL';[pscustomobject]@{path=$f.FullName;line=$i+1;rule=$rule;classification=if($negative){'FALSE POSITIVE / NEGATED CLAIM'}elseif($historical){'HISTORICAL CONTEXT — KEEP WITH LABEL'}else{'REVIEW CURRENT CONTEXT'};text=$lines[$i]}}}}})
$hits|Export-Csv "$OutputDirectory/stale-assumption-hits.csv" -NoTypeInformation
$modules=@(foreach($f in Get-ChildItem $src -Filter *.java){$text=Get-Content $f.FullName -Raw;$name=$f.BaseName;$uses=@(Get-ChildItem "$clean/source","$clean/tests" -Recurse -Filter *.java|Where-Object FullName -ne $f.FullName|Select-String -Pattern ('\b'+[regex]::Escape($name)+'\b')).Count;$class=if($name-in@('MediaControlMessages','ControlStateMachine','TlsAdapter','DisabledTlsAdapter','AaTlsSession')){'DEPRECATE / LEGACY POLICY: KEEP FOR EXISTING TESTS'}elseif($name-in@('PlaintextVideoBridge','AoaNegotiator','AoaRequestPlan','AaVideoDecoder','SurfaceRenderer')){'KEEP: SYNTHETIC OR DISABLED CONTRACT'}elseif($uses-eq0){'KEEP: PUBLIC BOUNDARY; REVIEW BEFORE ANY REMOVAL'}else{'ACTIVE'};[pscustomobject]@{module=$name;classification=$class;referenceLines=$uses;reason='No aggressive deletion; reference count is textual, not reachability proof'}})
$modules|Export-Csv "$OutputDirectory/module-audit.csv" -NoTypeInformation
$states=@(foreach($f in Get-ChildItem $src -Filter *.java){$text=Get-Content $f.FullName -Raw;foreach($m in [regex]::Matches($text,'enum State\s*\{([^}]+)\}')){foreach($state in $m.Groups[1].Value-split','){$state=$state.Trim();[pscustomobject]@{owner=$f.BaseName;state=$state;terminal=($state-in@('ERROR','FAILED','CLOSED','STOPPED'));reset=if($f.BaseName-eq'ControlStateMachine'){'Explicit legacy reset allowed; no automatic event revival'}else{'Explicit fresh owner/epoch; see per-owner source'};nonGuarantee='No phone acceptance, real decode/render/display or USB ownership implied';eventContract='See GLOBAL-STATE-AUDIT.md; source owner remains authoritative'}}}})
$states|Export-Csv "$OutputDirectory/state-inventory.csv" -NoTypeInformation
$bounds=@'
name,value,classification,owner
normal plaintext fragment,16128,TARGET-EVIDENCED,SecureBodyPipeline
ciphertext body,65535,AA OUTER FIELD WIDTH AND CLEAN POLICY,OuterFrameContext
logical message,1048576,CLEAN POLICY TESTED NOT PHONE MAXIMUM,SecureBodyPipeline
session reassembly reservations,2097152,CLEAN POLICY,SecureBodyPipeline
active fragmented channels,2,CLEAN POLICY,SecureBodyPipeline
compatibility adapter drains,256,CLEAN POLICY,SecureBodyPipeline
real adapter encrypt steps,256,CLEAN POLICY,RealTlsBodyAdapter
real adapter decrypt steps,131072,CLEAN POLICY FOR BYTEWISE INPUT,RealTlsBodyAdapter
TLS input queue,65535,CLEAN POLICY,MemoryTlsEngine
TLS packet scratch floor,18437,PROVIDER STATIC CONSTANT AND CLEAN FLOOR,MemoryTlsEngine
TLS application constant,16384,SAVED PROVIDER CONSTANT NOT MEASURED RUNTIME,OpenSSLSessionImpl
video window maximum,32,CLEAN POLICY NOT PROVEN HONDA MAXIMUM,VideoDataPlane
H264 bytes,1048576,CLEAN POLICY,H264
H264 NAL count,256,CLEAN POLICY,H264
legacy default frame body,16384,CLEAN POLICY NOT CURRENT TLS BODY MAX,ProtocolLimits
legacy partial channels,8,CLEAN POLICY OVERRIDDEN BY SECURE PATH,ProtocolLimits
fixture MP4 bytes,33554432,HOST TEST ONLY,Mp4FixtureReader
qualifier deadline seconds,600,TEST ONLY,QualifierCore
qualifier trace entries,256,TEST ONLY,QualifierCore
'@;$bounds|Set-Content "$OutputDirectory/bounds.csv"
[ordered]@{PASS=$true;consistencyChecks=$checks.Count;staleHits=$hits.Count;classifications=@($hits|Group-Object classification|Select-Object Name,Count);modules=$modules.Count;states=$states.Count;boundRows=($bounds-split"`n").Count-1;deletions=0;scope='Static consistency/reference inventory; not runtime reachability or provider qualification'}|ConvertTo-Json -Depth 5|Set-Content "$OutputDirectory/audit-summary.json"
Get-Content "$OutputDirectory/audit-summary.json"
