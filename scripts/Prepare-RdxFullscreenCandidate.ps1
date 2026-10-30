$ErrorActionPreference='Stop'
$sourcePath='./decompiled/AndroidAuto-current-smali/com/honda/androidauto/projection/sink/presentation/HMIPresenter.smali'
$sourceText=Get-Content -LiteralPath $sourcePath -Raw
$methodMatch=[regex]::Match($sourceText,'(?ms)^\.method public getVideoMode\(Z\).*?^\.end method')
if (-not $methodMatch.Success) { throw 'Expected method missing; no candidate written.' }
$before=$methodMatch.Value
$primaryEnd=$before.IndexOf('    :cond_18')
if ($primaryEnd -lt 0) { throw 'Expected primary/secondary branch boundary missing.' }
$primary=$before.Substring(0,$primaryEnd)
foreach ($literal in @('const/16 v1, 0x500','const/16 v1, 0x2b0','const/16 v1, 0xe5','const/16 v2, 0x3c')) {
    if ([regex]::Matches($primary,[regex]::Escape($literal)).Count -ne 1) { throw "Unexpected primary literal count: $literal" }
}
$after=$primary.Replace('const/16 v1, 0x500','const/16 v1, 0x780').Replace('const/16 v1, 0x2b0','const/16 v1, 0x2d0')+$before.Substring($primaryEnd)
$outputPath='./analysis/fullscreen-candidate'
[IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($outputPath)) | Out-Null
$before | Set-Content -LiteralPath "$outputPath/getVideoMode.before.smali"
$after | Set-Content -LiteralPath "$outputPath/getVideoMode.candidate.smali"
if (-not (Test-Path -LiteralPath "$outputPath/dex-patch-report.json")) {
[ordered]@{
    status='OFFLINE METHOD SNIPPET ONLY; NOT INSTALLED; NOT AN ASSEMBLED APK'
    sourceApk='./apks/AndroidAuto-current-2026-10-22.apk'
    sourceDexSha256='2F7FE2CF2C494509326804F3D79F9FBF75D3C7F3AF87659C7D6B971D54605DD4'
    originalPrimary=@{width=1280;height=688;dpi=229;fps=60}
    candidatePrimary=@{width=1920;height=720;dpi=229;fps=60}
    secondaryUnchanged=@{width=800;height=430;dpi=143;fps=60}
    expectedProtocol=@{codec='VIDEO_1920x1080';widthMargin=0;heightMargin=360}
    expectedActivityCallback=@{width=1920;height=720}
    installationMethodEstablished=$false
    liveTestAuthorized=$false
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$outputPath/candidate.json"
}
Write-Output 'Prepared original/control method snippets. Existing built-candidate metadata is preserved. Use Build-RdxOfflinePatch.ps1 and Finalize-HmiOfflineArtifacts.ps1 for offline APK artifacts; nothing installed.'
