$ErrorActionPreference='Stop'
$out='./analysis/parallel-aa-receiver/evidence'
Add-Type -Path './scripts/RdxElf.cs'
$path="$out/device/libautoreceiver_jni.so"
$elf=[RdxOffline.Elf32]::new([IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $path)))
$dyn=$elf.Sections|Where-Object {$_.Name-eq'.dynamic'}|Select-Object -First 1
$dynstr=$elf.Sections|Where-Object {$_.Name-eq'.dynstr'}|Select-Object -First 1
$needed=@(for($offset=0;$offset-lt$dyn.Size;$offset+=8){
    $tag=[BitConverter]::ToUInt32($elf.Bytes,$dyn.Offset+$offset)
    if($tag-eq1){$value=[BitConverter]::ToUInt32($elf.Bytes,$dyn.Offset+$offset+4);$p=$dynstr.Offset+$value;$end=[Array]::IndexOf($elf.Bytes,[byte]0,[int]$p);[Text.Encoding]::ASCII.GetString($elf.Bytes,$p,$end-$p)}
})
$symbols=@($elf.Symbols|Where-Object {$_.Name-match'JNI_OnLoad|Java_|Register|Cred|SSL|Certificate|Android|Transport|Video|Decoder|Controller|getuid|geteuid|FindClass|Signature|package|OpenSSL'})
$symbols|ConvertTo-Json -Depth 4|Set-Content "$out/receiver-native-symbols.json"
$strings=@($elf.Strings(5)|Where-Object {$_.Value-match'^com/(google|honda)/|^native[A-Z]|^\(.*\)[VZJIB]|/data/|/system/|getuid|geteuid|signature|packageName|certificate|SSL.*|PEM_.*' -and $_.Value-notmatch'BEGIN .*KEY|BEGIN CERTIFICATE|^[A-Za-z0-9+/]{60,}={0,2}$'})
$strings|ConvertTo-Json -Depth 4|Set-Content "$out/receiver-jni-strings.json"
[ordered]@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash;bytes=$elf.Bytes.Length;architecture='ELF32 little-endian ARM';needed=$needed;JNI_OnLoad=@($elf.Symbols|Where-Object {$_.Name-eq'JNI_OnLoad'});exportedJavaNames=@($elf.Symbols|Where-Object {$_.Name-like'Java_*'}|ForEach-Object {$_.Name});definedCredentialSymbols=@($symbols|Where-Object {$_.Name-match'Cred|Certificate|SSL' -and $_.Section-ne0}|Select-Object Name,Value,Size);limitations='Symbols/strings and DT_NEEDED extracted locally; caller/branch traces are separate. No certificate/key contents copied to this report.'}|ConvertTo-Json -Depth 5|Set-Content "$out/receiver-native-summary.json"
[pscustomobject]@{needed=$needed;JNI_OnLoad=@($elf.Symbols|Where-Object {$_.Name-eq'JNI_OnLoad'}|Select-Object Value,Size,Thumb);JNIJavaNames=@($elf.Symbols|Where-Object {$_.Name-like'Java_*'}).Count}|ConvertTo-Json -Depth 4
