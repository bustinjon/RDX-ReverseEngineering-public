param([Parameter(Mandatory)][string]$Ffmpeg,[Parameter(Mandatory)][string]$Ffprobe)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$output=Join-Path $root 'analysis/parallel-aa-receiver/decoder-test/assets/clips'
$Ffmpeg=(Resolve-Path -LiteralPath $Ffmpeg).Path;$Ffprobe=(Resolve-Path -LiteralPath $Ffprobe).Path
New-Item -ItemType Directory -Path $output -Force|Out-Null
$evidence=Join-Path $root 'analysis/parallel-aa-receiver/decoder-test/clips'
New-Item -ItemType Directory -Path $evidence -Force|Out-Null
if(-not('RdxOffline.H264Sps'-as[type])){Add-Type -Path "$root/scripts/RdxH264Sps.cs"}
$cases=@(@(1280,720,30),@(1280,688,60),@(1920,720,30),@(1920,720,60),@(1920,1080,30),@(1920,1080,60))
$records=@(foreach($case in $cases){
 $w=$case[0];$h=$case[1];$fps=$case[2];$name="grid-$($w)x$h-$fps.mp4";$path=Join-Path $output $name
 if(Test-Path $path){throw "Refusing to overwrite existing clip: $path"}
 $filter="drawgrid=width=100:height=100:thickness=1:color=white@0.35,drawbox=x=0:y=0:w=iw:h=ih:color=yellow:t=4,drawbox=x=iw/2-2:y=0:w=4:h=ih:color=cyan:t=fill,drawbox=x=0:y=ih/2-2:w=iw:h=4:color=cyan:t=fill,drawtext=fontfile='C\:/Windows/Fonts/consola.ttf':text='$($w)x$h $($fps)FPS FRAME %{n}':x=20:y=20:fontsize=32:fontcolor=white:box=1:boxcolor=black"
 & $Ffmpeg -n -f lavfi -i "testsrc2=size=$($w)x$($h):rate=$fps" -t 10 -vf $filter -an -c:v libx264 -profile:v baseline -pix_fmt yuv420p -bf 0 -g $fps -keyint_min $fps -sc_threshold 0 -crf 20 -maxrate 12M -bufsize 12M -threads 1 -movflags +faststart $path *> "$evidence/$name.encoder.log"
 if($LASTEXITCODE-ne0){throw "Encoding failed: $name"}
 $probe=& $Ffprobe -v error -select_streams v:0 -show_streams -show_format -of json $path
 if($LASTEXITCODE-ne0){throw "ffprobe failed: $name"}
 $probe|Set-Content "$evidence/$name.ffprobe.json"
 & $Ffmpeg -i $path -map 0:v:0 -c:v copy -bsf:v trace_headers -frames:v 1 -f null - *> "$evidence/$name.first-access-unit-headers.txt"
 if($LASTEXITCODE-ne0){throw "SPS trace failed: $name"}
 $parsed=$probe|ConvertFrom-Json
 & $Ffmpeg -n -i $path -map 0:v:0 -c:v copy -bsf:v h264_mp4toannexb -frames:v 1 -f h264 "$evidence/$name.first.h264" *> "$evidence/$name.annexb.log"
 if($LASTEXITCODE-ne0){throw 'Annex B extraction failed'}
 $sps=[RdxOffline.H264Sps]::ParseAnnexB([IO.File]::ReadAllBytes("$evidence/$name.first.h264"))
 if($sps.DisplayWidth-ne$w-or$sps.DisplayHeight-ne$h){throw 'Independent SPS dimensions mismatch'}
 $frames=& $Ffprobe -v error -select_streams v:0 -show_entries frame=key_frame,pict_type,best_effort_timestamp_time -of json $path
 if($LASTEXITCODE-ne0){throw 'Frame inventory failed'}
 $frames|Set-Content "$evidence/$name.frames.json"
 $frameData=$frames|ConvertFrom-Json
 if(@($frameData.frames|Where-Object pict_type -eq B).Count){throw 'Unexpected B frame'}
 if($parsed.streams[0].width-ne$w-or$parsed.streams[0].height-ne$h-or$parsed.streams[0].codec_name-ne'h264'){throw 'Encoded clip dimensions/codec mismatch'}
 [pscustomobject][ordered]@{file=$name;path=$path;width=$w;height=$h;fps=$fps;sha256=(Get-FileHash $path).Hash;probe=$parsed;SPS=$sps;frameCount=$frameData.frames.Count;BFrames=0;keyFrameTimes=@($frameData.frames|Where-Object key_frame -eq 1|ForEach-Object best_effort_timestamp_time)}
})
$records|ConvertTo-Json -Depth 10|Set-Content "$evidence/clip-manifest.json"
$records|Select-Object file,sha256,width,height,fps,frameCount,BFrames|Export-Csv "$evidence/clip-manifest.csv" -NoTypeInformation
$md=@('# Decoder clip manifest','','Generated with project-local FFmpeg9.0.2/libx264; independent baseline SPS parser confirms coded/cropped dimensions. These are synthetic files, not observed Android Auto phone output. Full hashes, bitrate, GOP, SPS/PPS traces and ffprobe fields are in JSON/evidence.','','| File | SHA256 | Duration/FPS | Profile/level | SPS coded | SPS display | B frames |','|---|---|---|---|---|---|---|')
foreach($r in $records){$st=$r.probe.streams[0];$md+="| $($r.file) | $($r.sha256) | $($r.probe.format.duration)s / $($st.avg_frame_rate) | $($st.profile) / $($st.level) | $($r.SPS.CodedWidth)x$($r.SPS.CodedHeight) | $($r.SPS.DisplayWidth)x$($r.SPS.DisplayHeight) | 0 |"}
$md|Set-Content "$evidence/CLIP-MANIFEST.md"
Add-Content "$evidence/CLIP-MANIFEST.md" 'For these1080 files, ffprobe width/height AND coded_width/coded_height fields report1920x1080, while the independent raw SPS parser and trace_headers show1920x1088 with8px bottom crop. Both raw outputs are retained; use SPS macroblock dimensions for coded-raster throughput. This does not measure Android Auto phone output.'
[ordered]@{kind='Host independently parsed baseline SPS; synthetic assets only';clips=@($records|ForEach-Object {[ordered]@{file=$_.file;sha256=$_.sha256;SPS=$_.SPS}})}|ConvertTo-Json -Depth 7|Set-Content (Join-Path (Split-Path $output) 'clip-catalog.json')
Write-Output 'Clips generated and host-inspected. Rebuild and re-audit decoder APK; no vehicle decoding has occurred.'
