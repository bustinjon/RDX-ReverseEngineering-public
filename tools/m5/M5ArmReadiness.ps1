# Pure, side-effect-free API22 readiness parsers. Loading this file never invokes ADB.
Set-StrictMode -Version Latest
$script:M5FrozenHash='A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40'
$script:M5Home='com.honda.tjba.launcher/com.honda.tjba.launcher.ui.HomeActivity'
function Convert-M5Component([string]$Component){
 if($Component -notmatch '^([a-zA-Z0-9_.]+)/([a-zA-Z0-9_.$]+)$'){return ''}
 $pkg=$Matches[1];$cls=$Matches[2];if($cls.StartsWith('.')){$cls=$pkg+$cls};return "$pkg/$cls"
}
function Get-M5LockTaskState([string]$Text){
 # service call activity 217: success exception header + exactly one boolean.
 # No error/trailing fields/other transaction reply is accepted.
 if($Text.Length -gt 4096){return 'UNKNOWN'}
 $flat=($Text -replace '[\r\n]',' ').Trim()
 if($flat -match "^Result:\s*Parcel\(\s*(?:0x00000000:\s*)?00000000\s+0000000([01])\s+'[^']*'\s*\)$"){
  if($Matches[1]-eq'0'){return 'INACTIVE'};return 'ACTIVE'
 };return 'UNKNOWN'
}
function Get-M5PackageFacts([string]$Text){
 $uid=[regex]::Matches($Text,'(?m)^\s*userId=(\d+)\b');$first=[regex]::Matches($Text,'(?m)^\s*firstInstallTime=([^\r\n]+)');$last=[regex]::Matches($Text,'(?m)^\s*lastUpdateTime=([^\r\n]+)')
 $user=[regex]::Matches($Text,'(?m)^\s*User 0:\s*([^\r\n]+)')
 $fresh=$uid.Count-eq1-and$first.Count-eq1-and$last.Count-eq1-and$user.Count-eq1
 $id=0;$f='';$l='';if($fresh){$id=[int]$uid[0].Groups[1].Value;$f=$first[0].Groups[1].Value.Trim();$l=$last[0].Groups[1].Value.Trim();$u=$user[0].Groups[1].Value
  $fresh=$id-ge10000-and$f-eq$l-and$u-match'\binstalled=true\b'-and$u-match'\bstopped=true\b'-and$u-match'\bnotLaunched=true\b'-and$u-match'\bhidden=false\b'-and$u-match'\benabled=0\b'
 }
 $fresh=$fresh-and$Text-match'(?m)^\s*versionName=0\.2\.0-m5-single-port-300s\s*$'-and$Text-match'\bversionCode=3\b'-and$Text-notmatch'(?im)^\s*disabledComponents:'
 return [pscustomobject]@{fresh=$fresh;uid=$id;firstInstallTime=$f;lastUpdateTime=$l}
}
function Get-M5Foreground([string]$Activities,[string]$Window){
 $res=[regex]::Matches($Activities,'mResumedActivity:\s*ActivityRecord\{[^\r\n}]*\s(u0)\s+(\S+)\s+t(\d+)\}')
 $focus=[regex]::Matches($Activities,'mFocusedActivity:\s*ActivityRecord\{[^\r\n}]*\s(u0)\s+(\S+)\s+t(\d+)\}')
 $win=[regex]::Matches($Window,'mCurrentFocus=Window\{[^\r\n}]*\s+u0\s+(\S+)\}')
 if($res.Count-ne1-or$focus.Count-ne1-or$win.Count-ne1){return ''}
 $r=Convert-M5Component $res[0].Groups[2].Value;$f=Convert-M5Component $focus[0].Groups[2].Value;$w=Convert-M5Component $win[0].Groups[1].Value
 if($r-ne$script:M5Home-or$f-ne$r-or$w-ne$r-or$res[0].Groups[3].Value-ne$focus[0].Groups[3].Value){return ''}
 return "$r task=$($res[0].Groups[3].Value)"
}
function Test-M5Geometry([string]$Window,[string]$Display){
 foreach($line in @('mOverscanScreen=(0,0) 1339x720','mRestrictedScreen=(0,0) 1920x720','mStable=(0,0)-(1339,720)','mSystem=(0,0)-(1920,720)')){
  if([regex]::Matches($Window,'(?m)^\s*'+[regex]::Escape($line)+'\s*$').Count-ne1){return $false}
 }
 $base=[regex]::Matches($Display,'(?m)^\s*mBaseDisplayInfo=DisplayInfo\{[^\r\n]+')
 return $base.Count-eq1-and$base[0].Value-match'\breal 1920 x 720\b'-and$base[0].Value-match'\bdensity 160\b'-and$base[0].Value-match'\bstate ON\b'-and$base[0].Value-match'\brotation 0\b'
}
function Get-M5SampleAssessment($Sample,$Proof){
 $why=[Collections.Generic.List[string]]::new()
 if((Get-M5LockTaskState $Sample.lockBefore)-ne'INACTIVE'-or(Get-M5LockTaskState $Sample.lockAfter)-ne'INACTIVE'){$why.Add('Lock-task active, unknown, or changed')}
 $foreground=Get-M5Foreground $Sample.activities $Sample.window;if(-not$foreground){$why.Add('Expected Honda Home not uniquely resumed/focused; Diagnostics/transition/unknown refused')}
 if(-not(Test-M5Geometry $Sample.window $Sample.display)){$why.Add('Display geometry/density/state differs or is unknown')}
 $facts=Get-M5PackageFacts $Sample.package
 if(-not$facts.fresh-or$facts.uid-ne$Proof.uid-or$facts.firstInstallTime-ne$Proof.firstInstallTime-or$facts.lastUpdateTime-ne$Proof.lastUpdateTime){$why.Add('M5 not the proven fresh never-launched install; armed/run/request history cannot be excluded')}
 if($Sample.processes-notmatch'(?m)^USER\s+PID\b[^\r\n]*\bNAME\s*$'-or$Sample.services-notmatch'(?m)^ACTIVITY MANAGER SERVICES\b'-or$Sample.processes-match'(?im)(permission denied|dump timeout|unknown argument|^\s*error\b|\bexception\b|:\s*not found\s*$|\bno such file)'-or$Sample.services-match'(?im)(permission denied|dump timeout|unknown argument|^\s*error\b|\bexception\b|:\s*not found\s*$|\bno such file)'){$why.Add('Process/service inventory missing or unrecognized')}
 if($Sample.processes-match'(?im)com\.rdx\.|com\.rdxresearch\.'-or$Sample.services-match'(?im)ServiceRecord\{[^\r\n]*(com\.rdx\.|com\.rdxresearch\.)'){$why.Add('Project process or service active')}
 $installed=@([regex]::Matches($Sample.packages,'(?m)^package:([^\s]+)')|ForEach-Object {$_.Groups[1].Value})
 $invalid=@($Sample.packages-split'[\r\n]+'|Where-Object {$_-and$_-notmatch'^package:[a-zA-Z0-9_.]+\s*$'})
 if($invalid.Count-or@($installed|Where-Object {$_-eq'com.rdx.fullscreen.m5permission'}).Count-ne1-or'com.honda.androidauto.projection.sink'-notin$installed-or@($installed|Where-Object {($_-match'^com\.(rdx|rdxresearch)\.')-and$_-ne'com.rdx.fullscreen.m5permission'}).Count){$why.Add('Project package inventory conflicts/unknown; M6/M7/other project package present or M5/factory absent')}
 if($Sample.endMs-lt$Sample.startMs-or$Sample.endMs-$Sample.startMs-gt2000){$why.Add('Critical snapshot exceeds 2000 ms or clock regressed')}
 return [pscustomobject]@{safe=$why.Count-eq0;reasons=@($why);foreground=$foreground}
}
function Get-M5WindowAssessment([object[]]$Samples,$Proof,[long]$NowMs,[int]$RequiredSeconds=5){
 $why=[Collections.Generic.List[string]]::new();$stableForeground='';$previous=-1L
 if($RequiredSeconds-lt5-or$RequiredSeconds-gt15){$why.Add('Stabilization policy must be 5..15 seconds')}
 if($Samples.Count-lt2){$why.Add('CHECK A and CHECK B plus stabilization required')}
 foreach($s in $Samples){$a=Get-M5SampleAssessment $s $Proof;foreach($r in $a.reasons){$why.Add($r)}
  if($stableForeground-and$a.foreground-ne$stableForeground){$why.Add('Foreground task changed during stabilization')};$stableForeground=$a.foreground
  if($previous-ge0-and($s.startMs-le$previous-or$s.startMs-$previous-gt2000)){$why.Add('Polling gap/clock order unsafe')};$previous=$s.startMs
 }
 if($Samples.Count){$first=$Samples[0];$last=$Samples[-1]
  if($last.startMs-$first.startMs-lt$RequiredSeconds*1000){$why.Add('Stabilization duration incomplete')}
  if($NowMs-lt$last.endMs-or$NowMs-$last.startMs-gt2000){$why.Add('Final precheck stale or time invalid')}
 }
 return [pscustomobject]@{ready=$why.Count-eq0;reasons=@($why|Select-Object -Unique);foreground=$stableForeground}
}
function Get-M5IdentitySafe([string]$Serial,[string]$Fingerprint,[string]$Api,[string]$Release,[string]$Abi){
 return $Serial-eq'00000000'-and$Fingerprint.Trim()-eq'Acura/gen1CBD_HS/gen1CBD_HS:5.1.1/LMY48P/14:user/release-keys'-and$Api.Trim()-eq'22'-and$Release.Trim()-eq'5.1.1'-and$Abi.Trim()-eq'armeabi-v7a'
}
function Test-M5ReadinessFresh($Result,[string]$RunId,[string]$Serial,[long]$NowMs){
 return $Result.schema-eq1-and$Result.result-eq'READY_TO_ARM'-and$Result.runId-eq$RunId-and$Result.serial-eq$Serial-and$Result.apkSHA256-eq$script:M5FrozenHash-and$Result.stabilizationSeconds-ge5-and$Result.stabilizationSeconds-le15-and$Result.sampleCount-ge2-and$NowMs-ge$Result.createdMs-and$NowMs-ge$Result.lastSampleStartMs-and$NowMs-$Result.lastSampleStartMs-le2000
}
function Get-M5PermissionUiEvidence([string]$Log,[string]$RunId=''){
 $scoped=$false
 if($RunId){$all=@($Log -split '[\r\n]+');$armed=-1;$ended=-1
  for($i=0;$i-lt$all.Count;$i++){if($all[$i]-match([regex]::Escape('run='+$RunId)+'.*event=ARMED')){$armed=$i};if($armed-ge0-and$all[$i]-match([regex]::Escape('run='+$RunId)+'.*event=SERVICE_END')){$ended=$i;break}}
  if($armed-ge0){if($ended-lt$armed){$ended=$all.Count-1};$Log=$all[$armed..$ended]-join"`n";$scoped=$true}
 }
 $lines=@($Log -split '[\r\n]+'|Where-Object {$_-match'UsbPermissionActivity|Lock Task Mode violation|stopLockTaskMode|dealer.Main.*finish|SecurityException.*(usb|permission)|WindowManager.*(denied|reject)'})
 return [pscustomobject]@{schema=1;runScoped=$scoped;permissionActivityAttempted=$Log-match'START[^\r\n]*UsbPermissionActivity';blocked=$Log-match'Attempted Lock Task Mode violation[^\r\n]*UsbPermissionActivity|(?:denied|reject)[^\r\n]*UsbPermissionActivity';classification=if($Log-match'Attempted Lock Task Mode violation[^\r\n]*UsbPermissionActivity'){'INCONCLUSIVE: permission UI blocked; permission availability unresolved'}else{'Review journal and UI evidence; no absence-of-log success inference'};lines=$lines}
}
