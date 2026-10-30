param([Parameter(Mandatory=$true)][string]$EvidenceDirectory)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent;$base=Join-Path $root 'analysis/parallel-aa-receiver'
$e=(Resolve-Path -LiteralPath $EvidenceDirectory).Path
if(-not$e.StartsWith($base+[IO.Path]::DirectorySeparatorChar)-or(Split-Path $e -Leaf)-notmatch'^warning-phonefree-\d{8}-\d{6}$'){throw 'Wrong evidence root'}
function Capture([string]$Name){$pattern='^\d{8}-\d{6}-\d{3}-'+[regex]::Escape($Name)+'\.stdout\.txt$';$f=@(Get-ChildItem -LiteralPath $e -File -Filter ('*-'+$Name+'.stdout.txt')|Where-Object Name -match $pattern);if($f.Count-ne1){throw "Expected one $Name capture"};return [string](Get-Content -LiteralPath $f[0].FullName -Raw)}
function Hash([string]$Path){return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
$m5='A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40'
$detector='3F29DBD72CE61DFA354AB0A70B5A58094A94E6C87FAC6C2041ABFE93EFA1F053'
if((Hash "$e/m5.apk")-ne$m5-or(Hash "$e/final-m5.apk")-ne$m5){throw 'M5 installed artifact changed'}
if((Hash "$e/detector.apk")-ne$detector-or(Hash "$e/detector-confirmation.apk")-ne$detector){throw 'Detector pulls differ'}
if((Capture 'final-detector-md5')-notmatch'30fb669c7bfc66559c4562d6fe1de47d'){throw 'Detector remote digest changed'}
if((Capture 'final-honda-ui-md5')-notmatch'841c33db6e034fd73649d645a8aad120'){throw 'UI library remote digest changed'}
if((Hash "$e/factory.apk")-ne'F9E976F44853C9DB7C8FF5A8610C10CAF1E0B4D1E5BE0886F4F52505C5348146'-or(Hash "$e/final-factory.apk")-ne(Hash "$e/factory.apk")){throw 'Factory AA bytes changed'}
$log=Capture 'final-m5-logs'
if($log-match'SAVED_RESULT|event=(ARMED|REQUEST_API_INVOKING|REQUEST_API_RETURNED)|Active run|REFUSED/ERROR|dump failed'){throw 'STOP: unexpected M5 run/request/evidence error'}
if((Capture 'final-m5-services-after-list')-notmatch'\(nothing\)'){throw 'M5 service still active'}
if((Capture 'final-usb')-match'mVendorId=(6353|8921),mProductId=(11521|10089|10085)'){throw 'Unexpected target phone in USB inventory'}
if((Capture 'final-m5-package')-notmatch'userId=10049'-or(Capture 'final-contexts')-notmatch'u:r:untrusted_app:s0[^\r\n]*com\.rdx\.fullscreen\.m5permission'){throw 'M5 UID/domain changed'}
foreach($name in @('wm-size','wm-density','boot-id')){if((Capture $name).Trim()-ne(Capture ('final-'+$name)).Trim()){throw "Preservation mismatch: $name"}}
function Geometry([string]$Text){return @($Text-split'[\r\n]+'|Where-Object {$_-match'mOverscanScreen=|mRestrictedScreen=|mStable=|mSystem='}|ForEach-Object {$_.Trim()})}
if(@(Compare-Object (Geometry (Capture 'window')) (Geometry (Capture 'final-window'))).Count){throw 'Stable window geometry changed'}
foreach($list in @('packages','packages-u')){if((Capture ('initial-'+$list)).Trim()-ne(Capture ('final-'+$list)).Trim()){throw "Package list changed: $list"}}
$session=Get-Content "$base/m5-live-retry-20261025-185128/session.json" -Raw|ConvertFrom-Json
if($session.phase-ne'INSTALLED'-or$session.PSObject.Properties.Name-contains'armedAt'){throw 'Host M5 session unexpectedly armed'}
$audit=@();$adbCount=0;$listCount=0
foreach($f in Get-ChildItem -LiteralPath $e -File -Filter '*.command.json'){
 $r=Get-Content $f.FullName -Raw|ConvertFrom-Json
 if($r.timedOut-or$r.exitCode-ne0){throw "Captured command did not finish normally: $($f.Name)"}
 if([IO.Path]::GetFileName($r.executable)-ine'adb.exe'){continue}
 $adbCount++;$a=@($r.arguments)
 if($a.Count-lt3-or$a[0]-ne'-s'-or$a[1]-ne'00000000'){throw 'Unselected/incorrect ADB serial'}
 $body=@($a[2..($a.Count-1)]);$allowed=$false;$kind='READ'
 switch($body[0]){
  'pull' {$allowed=$body.Count-eq3-and$body[1]-match'^/(system/(app|framework)/|data/app/com\.rdx\.fullscreen\.m5permission-)' }
  'logcat' {$allowed=$body-contains'-d'-and$body-notcontains'-c'}
  'shell' {
   if($body.Count-lt2){throw 'Empty shell operation'}
   switch($body[1]){
    'getprop' {$allowed=$body.Count-eq3}
    'date' {$allowed=$body.Count-eq2}
    'getenforce' {$allowed=$body.Count-eq2}
    'ps' {$allowed=$body.Count-eq2-or($body.Count-eq3-and$body[2]-eq'-Z')}
    'cat' {$allowed=$body.Count-eq3-and$body[2]-match'^/proc/(uptime|sys/kernel/random/boot_id)$'}
    'wm' {$allowed=$body.Count-eq3-and$body[2]-in@('size','density')}
    'dumpsys' {$allowed=$body.Count-ge3-and$body[2]-in@('usb','package','window','display','activity')}
    'pm' {$allowed=$body.Count-ge3-and$body[2]-in@('list','path')}
    'ls' {$allowed=$true}
    'md5' {$allowed=$body.Count-eq3}
    'sha256sum' {$allowed=$body.Count-eq3}
    'am' {$allowed=($body-join' ')-eq'shell am startservice -n com.rdx.fullscreen.m5permission/.PermissionService -a LIST_RESULTS';$kind='EXPLICIT NON-ARMING M5 LIST_RESULTS';if($allowed){$listCount++}}
   }
  }
 }
 if(-not$allowed){throw "Unexpected live action: $($body-join' ')"}
 $audit+=[pscustomobject]@{record=$f.Name;serial=$a[1];operation=($body-join' ');classification=$kind;PASS=$true}
}
if($listCount-ne2){throw 'Unexpected M5 status invocation count'}
$audit|ConvertTo-Json -Depth 5|Set-Content "$e/read-only-command-audit.json"
$packages=Get-Content "$e/project-package-status.json" -Raw|ConvertFrom-Json
if(@($packages|Where-Object currentStatus -eq 'INSTALLED').Count-ne1-or@($packages|Where-Object currentStatus -eq 'UNINSTALLED-BUT-STATE-VISIBLE').Count){throw 'Unexpected project package state'}
$third=Capture 'thirdparty-packages';if($third.Trim()-ne'package:/data/app/com.rdx.fullscreen.m5permission-1/base.apk=com.rdx.fullscreen.m5permission'){throw 'Unexpected third-party software; revise hypothesis'}
$result=[ordered]@{schema=1;phase='PHONE-FREE PRECHECK COMPLETE';serial='00000000';fingerprint=(Capture 'final-fingerprint').Trim();release=(Capture 'release').Trim();API=(Capture 'api').Trim();ABI=(Capture 'abi').Trim();SELinux=(Capture 'selinux').Trim();M5=@{installed=$true;sha256=$m5;UID=10049;domain='u:r:untrusted_app:s0';armed=$false;permissionRequests=0;savedRuns=0;activeService=$false;cachedProcess='Present, not an armed service';phoneTargetInSystemInventory=$false;directAppInventory='Not sampled while unarmed; LIST_RESULTS does not obtain UsbManager';readiness='READY FOR M5 ARM; await explicit user instruction and physical-readiness confirmation'};detector=@{package='com.honda.maliciousdetector';UID=10023;domain='u:r:platform_app:s0';PID=4468;sha256=$detector;remoteSHA256='Unavailable: sha256sum absent';remoteLocalMD5Match=$true;independentPullSHA256Match=$true;signerCertificateSHA256='2156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568';privatePreferenceRead=$false;historyKey='DID_USER_INSTALL_3RD_APP_KEY';historyOnlyTrueSetter=$true;removalHandler=$false;fileScanner=$false;startupCause='LIKELY DETECTOR-PERSISTED STATE';confidence='Mechanism DEX-confirmed; current private flag/original historical writer and prior visible UI not directly verified'};projectPackages=7;installedProjectPackages=@('com.rdx.fullscreen.m5permission');PMresidueFound=$false;staleProjectAPKFound=$false;filesystemLimits=@('/data/app listing denied; normal PM metadata available','Vendor tmp subdirectory metadata denied; not traversed','No whole-filesystem absence claim');preservation=@{factoryAAHashSame=$true;detectorRemoteMD5Same=$true;uiLibraryRemoteMD5Same=$true;displayGeometrySame=$true;bootIdSame=$true;HondaPrivateDataEquality='NOT CLAIMED'};ADBcommands=$adbCount;nonArmingStatusCalls=$listCount;packageModification='NONE IN THIS PHASE; M5 installed in preceding authorized phase';cleanupExecuted=$false;detectorModified=$false;phoneUsed=$false;M6activity='NONE';M7activity='NONE';rebooted=$false;next='STOP AND WAIT FOR USER AUTHORIZATION TO ARM M5'}
$result|ConvertTo-Json -Depth 9|Set-Content "$e/final-state.json"
Write-Output "PHONE-FREE QA PASS: $adbCount selected read/status ADB commands; $listCount LIST_RESULTS; M5 unarmed/zero requests/zero saved runs; APK/geometry/boot preserved. NO CLEANUP."
