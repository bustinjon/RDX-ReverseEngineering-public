$ErrorActionPreference='Stop'
$out='./analysis/parallel-aa-receiver/evidence'
Add-Type -Path './scripts/RdxElf.cs'
function Trace-File([string]$path,[string]$stem){
    $elf=[RdxOffline.Elf32]::new([IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $path)))
    $functions=@($elf.Symbols|Where-Object {$_.Section-ne0 -and ($_.Info-band15)-eq2 -and $_.Size-gt0}|Sort-Object Address)
    $calls=@(foreach($function in $functions){
        $data=$elf.FunctionBytes($function)
        if($function.Thumb){
            for($p=0;$p+4-le$data.Length;$p+=2){
                $h1=[BitConverter]::ToUInt16($data,$p);$h2=[BitConverter]::ToUInt16($data,$p+2)
                if(($h1-band0xF800)-ne0xF000 -or ($h2-band0xC000)-ne0xC000){continue}
                $s=($h1-shr10)-band1;$j1=($h2-shr13)-band1;$j2=($h2-shr11)-band1
                $i1=1-bxor($j1-bxor$s);$i2=1-bxor($j2-bxor$s)
                $delta=($s-shl24)-bor($i1-shl23)-bor($i2-shl22)-bor(($h1-band0x3FF)-shl12)-bor(($h2-band0x7FF)-shl1)
                if($s){$delta-=0x2000000}
                $pc=[long]$function.Address+$p+4
                if(($h2-band0x1000)-eq0){$pc=$pc-band(-4);$delta=$delta-band(-4)}
                $target=[uint32](($pc+$delta)-band4294967295L)
                $name=$elf.SymbolAt($target)
                if($name){[pscustomobject]@{caller=$function.Name;callerAddress=('0x{0:X}'-f$function.Address);instruction=('0x{0:X}'-f($function.Address+$p));target=('0x{0:X}'-f$target);callee=$name;encoding=[Convert]::ToHexString($data[$p..($p+3)])}}
            }
        }else{
            for($p=0;$p+4-le$data.Length;$p+=4){
                $word=[BitConverter]::ToUInt32($data,$p)
                if(($word-band0x0F000000)-ne0x0B000000){continue}
                $delta=[long]($word-band0xFFFFFF)*4;if($delta-ge0x2000000){$delta-=0x4000000}
                $target=[uint32](([long]$function.Address+$p+8+$delta)-band4294967295L)
                $name=$elf.SymbolAt($target)
                if($name){[pscustomobject]@{caller=$function.Name;callerAddress=('0x{0:X}'-f$function.Address);instruction=('0x{0:X}'-f($function.Address+$p));target=('0x{0:X}'-f$target);callee=$name;encoding=[Convert]::ToHexString($data[$p..($p+3)])}}
            }
        }
    })
    $calls|ConvertTo-Json -Depth 4|Set-Content "$out/$stem.direct-calls.json"
    $elf.Strings(5)|Where-Object {$_.Value-match'/data/|/system/|/dev/|/proc/|VBUS|socket|bind|listen|chmod|chown|uid|gid|reset|com/google|mNative|getBuffer|returnBuffer|Callback$'}|ConvertTo-Json -Depth 4|Set-Content "$out/$stem.selected-strings.json"
    [ordered]@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash;bytes=$elf.Bytes.Length;functionSymbols=$functions.Count;recognizedDirectCalls=$calls.Count;imports=@($elf.Symbols|Where-Object {$_.Section-eq0 -and $_.Name-ne''}|Select-Object -ExpandProperty Name);limitations='Static direct-call encoding survey only. Symbolized calls recorded; indirect calls, tail branches, inline syscalls and complete control flow not recovered. Thumb halfword scan may include data/overlapping candidates; retained encodings/addresses require contextual review. No ARM code executed.'}|ConvertTo-Json -Depth 4|Set-Content "$out/$stem.call-summary.json"
}
Trace-File "$out/device/libautoreceiver_jni.so" 'receiver'
Trace-File "$out/device/usbresetserver" 'usbresetserver'
Get-Content "$out/receiver.direct-calls.json" -Raw|ConvertFrom-Json|Where-Object {$_.caller-match'GalReceiver_native(Init|SetCreds|SetCarInfo|Start)$|Controller14setClientCreds|setClientCreds|setClientCredentials' -or $_.callee-match'^(getuid|geteuid|socket|connect)$'}|Select-Object -First 35 caller,instruction,callee|Format-Table -Wrap
