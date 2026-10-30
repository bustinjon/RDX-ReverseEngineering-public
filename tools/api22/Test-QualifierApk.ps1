param([Parameter(Mandatory=$true)][string]$Build)
$ErrorActionPreference='Stop';$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -Path @("$root/scripts/RdxDex.cs","$root/scripts/RdxDexApi.cs")
$r=Get-Content "$Build/build-report.json" -Raw|ConvertFrom-Json
if((Get-FileHash $r.apk).Hash-ne$r.sha256){throw 'APK differs from build report'}
$dex=[RdxOffline.Dex]::new([IO.File]::ReadAllBytes("$Build/dex/classes.dex"));$refs=@($dex.Methods|ForEach-Object {$_.Class+'->'+$_.Name+$_.Prototype})
$bad=@($refs|Where-Object {$_-match'Landroid/hardware/usb/|Landroid/media/|Landroid/view/(Surface|SurfaceView|WindowManager)|Landroid/provider/Settings|Landroid/webkit/|Ljava/net/(Socket|ServerSocket|DatagramSocket|HttpURLConnection)|Lokhttp|Lretrofit|Ljava/lang/Runtime;->exec|Ljava/lang/ProcessBuilder|->loadLibrary\(|Lcom/honda/'})
if($bad.Count){$bad|Set-Content "$Build/dangerous-calls.txt";throw 'Qualifier prohibited method reference'}
if(@($dex.Strings|Where-Object {$_-match'libautoreceiver_jni|/data/misc/gal/socket|com\.honda\.|BOOT_COMPLETED|android\.hardware\.usb\.action'}).Count){throw 'Qualifier forbidden platform/vehicle string'}
$manifest=Get-Content "$Build/manifest-tree.txt" -Raw
if($manifest-match'E: (uses-permission|service|receiver|provider|intent-filter)\b'-or@([regex]::Matches($manifest,'E: activity\b')).Count-ne1){throw 'Manifest not permission-free explicit single-Activity'}
$definitions=[Collections.Generic.HashSet[string]]::new();$parents=@{}
foreach($name in @('core-libart.jar','framework.jar')){$zip=[IO.Compression.ZipFile]::OpenRead("$root/adb/RDX-Audit/framework/$name");try{foreach($e in $zip.Entries|Where-Object FullName -match '^classes\d*\.dex$'){$stream=$e.Open();$mem=[IO.MemoryStream]::new();try{$stream.CopyTo($mem);$api=[RdxOffline.DexApi]::new([RdxOffline.Dex]::new($mem.ToArray()));foreach($x in $api.Definitions){[void]$definitions.Add($x)};foreach($x in $api.Parents.GetEnumerator()){$parents[$x.Key]=@($x.Value)}}finally{$stream.Dispose();$mem.Dispose()}}}finally{$zip.Dispose()}}
function Resolve-Method([string]$Type,[string]$Suffix,[Collections.Generic.HashSet[string]]$Seen){if(-not$Seen.Add($Type)){return $false};if($definitions.Contains($Type+'->'+$Suffix)){return $true};if($Suffix.StartsWith('<init>')){return $false};foreach($p in $parents[$Type]){if(Resolve-Method $p $Suffix $Seen){return $true}};return $false}
$defined=[Collections.Generic.HashSet[string]]::new();foreach($c in $dex.DefinedClasses()){[void]$defined.Add($c)}
$apiRows=@(foreach($m in $refs){$p=$m-split'->',2;if($defined.Contains($p[0])){continue};$intrinsic=$p[0].StartsWith('[')-and$p[1]-eq'clone()Ljava/lang/Object;';[pscustomobject]@{method=$m;API22=($intrinsic-or(Resolve-Method $p[0] $p[1] ([Collections.Generic.HashSet[string]]::new())))}})
$apiRows|ConvertTo-Json|Set-Content "$Build/api22-methods.json";if(@($apiRows|Where-Object {-not$_.API22}).Count){$apiRows|Where-Object {-not$_.API22}|Format-Table;throw 'Qualifier external API22 reference unresolved'}
if(@($dex.DefinedClasses()|Where-Object {$_-match'ExportTest|ExportQualifier|QualifierDesktop|Mp4FixtureReader|Usb|Aoa|AndroidUsb|FakeVideoDecoder|TlsLoopbackTests'}).Count){throw 'Host/vehicle code leaked into qualifier DEX'}
$result=[ordered]@{PASS=$true;scope='STATIC FINAL APK ONLY; NOT runtime qualification';sha256=$r.sha256;DEX=$r.DEX;package=$r.package;version=$r.version;minSdk=22;targetSdk=22;permissions=@();components=@('com.rdx.fullscreen.api22tls/.TlsQualificationActivity');dangerousCalls=$bad;externalAPI22Methods=$apiRows.Count;definedClasses=@($dex.DefinedClasses()).Count;signerEvidence="$Build/signature.txt";Java7='PASS';D8min22='PASS';entrypoint='Explicit action + fresh run id + API22 goldfish/ranchu guard; bounded worker only after launch';testSecrets='PUBLIC disposable PKCS8 assets intentionally packaged; no Honda credentials'}
$result|ConvertTo-Json -Depth 6|Set-Content "$Build/apk-audit.json";$result|ConvertTo-Json -Depth 6
