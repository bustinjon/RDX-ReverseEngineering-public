param([Parameter(Mandatory=$true)][string]$Session)
# STATIC evidence only. No ADB, network, target JNI, provider loading or TLS operations.
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver'
$Session=(Resolve-Path -LiteralPath $Session).Path
if(-not $Session.StartsWith($project+[IO.Path]::DirectorySeparatorChar)){throw 'Project-local evidence directory required'}
$provider=Join-Path $project 'real-tls-contract-evidence/conscrypt/sources/com/android/org/conscrypt'
$sdk='C:/Program Files (x86)/Android/android-sdk'
$paths=@($sdk,"$sdk/emulator","$sdk/system-images","$sdk/platforms","$sdk/platforms/android-22","$sdk/build-tools","$sdk/platform-tools",'C:/Users/REDACTED/.android/avd','C:/Users/REDACTED/AppData/Local/Android','C:/Android','C:/AndroidSDK','C:/Users/REDACTED/.gradle/caches','C:/Users/REDACTED/VirtualBox VMs','C:/Program Files/Genymobile','C:/Program Files/Oracle/VirtualBox','C:/Program Files/VMware','C:/Users/REDACTED/Documents/Virtual Machines','C:/ProgramData/BlueStacks_nxt','C:/LDPlayer')
$inventory=@(foreach($p in $paths){$exists=Test-Path -LiteralPath $p;[pscustomobject]@{path=$p;exists=$exists;children=if($exists){@(Get-ChildItem -LiteralPath $p -Force|Select-Object -ExpandProperty Name)}else{@()}}})
$scanErrors=@()
$assets=@(foreach($p in @($sdk,'C:/Users/REDACTED/.android','C:/Users/REDACTED/Downloads','C:/Users/REDACTED/VirtualBox VMs')){if(Test-Path -LiteralPath $p){Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue -ErrorVariable +scanErrors|Where-Object {$_.Name-match'^(system\.img|ramdisk\.img|userdata\.img|kernel-qemu.*|emulator.*\.exe|qemu.*\.exe|config\.ini|.*\.vbox)$' -or $_.Name-match'(android[-_ ]?(22|5[._]1)|api[-_ ]?22).*\.(zip|img|iso|7z)$'}|Select-Object FullName,Length}})
$xmlPath='C:/Users/REDACTED/.VirtualBox/VirtualBox.xml'
$registrations=@(if(Test-Path $xmlPath){[xml]$vbox=Get-Content -LiteralPath $xmlPath -Raw;foreach($m in $vbox.VirtualBox.Global.MachineRegistry.MachineEntry){[pscustomobject]@{path=[string]$m.src;exists=Test-Path -LiteralPath ([string]$m.src)}}})
[ordered]@{scope='Known SDK, AVD and common VM/image locations; not whole-disk proof';environment=@{ANDROID_HOME=$env:ANDROID_HOME;ANDROID_SDK_ROOT=$env:ANDROID_SDK_ROOT;ANDROID_AVD_HOME=$env:ANDROID_AVD_HOME;JAVA_HOME=$env:JAVA_HOME};paths=$inventory;candidateAssets=$assets;searchErrors=@($scanErrors|ForEach-Object ToString);virtualBox=$registrations;ADBexecuted=$false;downloads=$false;selectedPath='E: saved target Conscrypt; no runnable API22 environment found'}|ConvertTo-Json -Depth 8|Set-Content "$Session/runtime-inventory.json"
$anchors=@'
OpenSSLProvider.java|public static final String PROVIDER_NAME = "AndroidOpenSSL";|provider identity
OpenSSLProvider.java|put("SSLContext.TLSv1.2", classOpenSSLContextImpl);|TLSv1.2 context registration
OpenSSLContextImpl.java|return new OpenSSLEngineImpl|memory engine construction
NativeCrypto.java|"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"|GCM mapping and default
OpenSSLEngineImpl.java|public Runnable getDelegatedTask()|delegated tasks entry
OpenSSLEngineImpl.java|if (dst.remaining() < 16709)|wrap minimum destination
OpenSSLEngineImpl.java|bytesWritten = this.handshakeSink.position();|handshake result read cursor
OpenSSLBIOSink.java|return this.buffer.size() - this.position;|sink availability
OpenSSLBIOSink.java|this.position += maxLength;|drain advances read cursor
OpenSSLEngineImpl.java|consumed > 0 ? SSLEngineResult.Status.OK : SSLEngineResult.Status.BUFFER_UNDERFLOW|status based on input consumption
OpenSSLEngineImpl.java|return (NativeCrypto.SSL_get_shutdown(this.sslNativePointer) & 2) != 0;|peer shutdown flag
OpenSSLEngineImpl.java|public void closeOutbound()|close entrypoint
OpenSSLEngineImpl.java|shutdownAndFreeSslNative();|shutdown free path
OpenSSLEngineImpl.java|this.sslNativePointer = 0L;|pointer clear
OpenSSLEngineImpl.java|this.engineState == EngineState.CLOSED_OUTBOUND|closed wrap short circuit
OpenSSLEngineImpl.java|for (int i = offset; i < length; i++)|nonzero offset destination loop
OpenSSLEngineImpl.java|for (ByteBuffer src : srcs)|wrap array loop
OpenSSLEngineImpl.java|Platform.checkServerTrusted|server trust call
OpenSSLEngineImpl.java|x509tm.checkClientTrusted|client trust call
OpenSSLEngineImpl.java|chooseClientCertificate(keyTypeBytes|client credential callback
SSLParametersImpl.java|NativeCrypto.SSL_set_verify(sslNativePointer, 3);|required client authentication
SSLParametersImpl.java|NativeCrypto.SSL_set_session(sslNativePointer|session reuse code
OpenSSLSessionImpl.java|return 16384;|application buffer size
OpenSSLSessionImpl.java|return 18437;|packet buffer size
'@ -split '\r?\n'
$files=[Collections.Generic.HashSet[string]]::new()
$rows=@(foreach($a in $anchors){$part=$a-split'\|',3;$path=Join-Path $provider $part[0];[void]$files.Add($path);$lines=Get-Content -LiteralPath $path;$matches=@(for($i=0;$i-lt$lines.Count;$i++){if($lines[$i].Contains($part[1])){$i+1}});if(-not$matches.Count){throw "Static anchor missing $($part[2])"};[pscustomobject]@{feature=$part[2];source=$path;lines=$matches-join',';anchor=$part[1];verdict='STATIC ANCHOR PRESENT; runtime untested'}})
$rows|Export-Csv "$Session/provider-static-anchors.csv" -NoTypeInformation
$dump=Get-Content "$Session/conscrypt-dexdump.txt" -Raw
$classMethods=[ordered]@{OpenSSLEngineImpl=@('wrap','unwrap','closeOutbound','closeInbound','shutdown','shutdownAndFreeSslNative','free','getHandshakeStatus','getNextAvailableByteBuffer','isInboundDone','isOutboundDone','getDelegatedTask','verifyCertificateChain','clientCertificateRequested');OpenSSLBIOSink=@('available','position','skip','reset');OpenSSLSessionImpl=@('getPacketBufferSize','getApplicationBufferSize')}
$methodRows=@(foreach($c in $classMethods.Keys){foreach($method in $classMethods[$c]){$pattern='(?m)^.*\] com\.android\.org\.conscrypt\.'+[regex]::Escape($c)+ '\.'+[regex]::Escape($method)+':.*$';$match=[regex]::Match($dump,$pattern);if(-not$match.Success){throw "DEX method absent $c.$method"};$start=$match.Index;$end=$dump.IndexOf("`n      catches",$start);if($end-lt$start-or$end-$start-gt50000){throw 'DEX excerpt boundary'};$name="$c-$method.dex.txt";$dump.Substring($start,$end-$start)|Set-Content "$Session/$name";[pscustomobject]@{class=$c;method=$method;dumpLine=1+([regex]::Matches($dump.Substring(0,$start),"`n")).Count;excerpt=$name}}})
$methodRows|ConvertTo-Json|Set-Content "$Session/provider-dex-method-index.json"
@($files)+@("$root/adb/RDX-Audit/full-system/framework/conscrypt.jar","$Session/conscrypt-classes.dex","$root/adb/RDX-Audit/full-system/build.prop")|ForEach-Object {Get-FileHash -LiteralPath $_}|ConvertTo-Json|Set-Content "$Session/provider-artifact-hashes.json"
[ordered]@{PASS='STATIC EVIDENCE ANCHORS ONLY';anchors=$rows.Count;dexMethods=$methodRows.Count;runtimeCases=0;qualified=$false;productionChanged=$false;verdict='API22 RUNTIME TEST UNAVAILABLE; STATIC EVIDENCE ONLY'}|ConvertTo-Json|Set-Content "$Session/static-review-result.json"
Write-Output "STATIC REVIEW PASS anchors=$($rows.Count) dexMethods=$($methodRows.Count); Android runtime cases=0; NOT QUALIFIED"
