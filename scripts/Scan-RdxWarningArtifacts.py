"""Offline archive string search; never executes APK code or contacts ADB."""
import hashlib, json, pathlib, re, zipfile
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'analysis/parallel-aa-receiver/warning-evidence'
OUT.mkdir(exist_ok=True)
patterns = [re.compile(p, re.I) for p in (
    r'non[- ]?authorized', r'not authorized by honda', r'unauthori[sz]ed application',
    r'application\(s\) detected', r'authorized by honda', r'MD_PackageLocalRepository',
    r'com[./]honda[./]maliciousdetector')]
records=[]
for base in ('adb','apks'):
    for path in (ROOT/base).rglob('*'):
        if path.suffix.lower() not in ('.apk','.jar'): continue
        record={'path':str(path.relative_to(ROOT)), 'sha256':hashlib.sha256(path.read_bytes()).hexdigest(), 'hits':[]}
        try:
            with zipfile.ZipFile(path) as z:
                for name in z.namelist():
                    if not (name.endswith(('.dex','.arsc','.xml'))): continue
                    data=z.read(name)
                    for enc in ('utf-8','utf-16-le'):
                        text=data.decode(enc,errors='ignore')
                        for pattern in patterns:
                            for match in pattern.finditer(text):
                                record['hits'].append({'entry':name,'encoding':enc,'pattern':pattern.pattern,'match':match.group(0)})
        except Exception as e: record['error']=str(e)
        records.append(record)
(OUT/'archive-search.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print(json.dumps({'archives':len(records),'archivesWithHits':[r for r in records if r['hits']], 'errors':[r for r in records if 'error' in r]},indent=2))
