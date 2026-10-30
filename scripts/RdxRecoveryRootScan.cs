using System;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text.Json;
namespace RdxRecoveryAudit {
 public sealed class Scanner {
  readonly Regex printable=new Regex(@"[\x20-\x7e]{3,}",RegexOptions.Compiled);
  readonly Dictionary<string,Regex> patterns=new Dictionary<string,Regex> {
   {"recovery",new Regex(@"recovery|rescue|restor|rollback|fallback|retr(y|ies)|fail.?safe|safe.?mode|factory.?reset|recovery.?boot|update.?fail|backup.?partition|redundant|boot.?slot|system.?slot|disabled.?system|package.?rollback|emergency.?update|USB.?recovery",RegexOptions.IgnoreCase|RegexOptions.Compiled)},
   {"privilege",new Regex(@"\bsu\b|\broot\b|set[ug]id|capabilit|CAP_SYS_(ADMIN|PTRACE)|ptrace|run-as|setenforce|permissive|selinux|adb.?root|remount|\bmount\b|namespace|chroot|pivot_root|dm-verity|\bverity\b|fastboot|bootloader|U-Boot|unlock|engineering.?shell|debug.?shell|factory.?shell|developer.?mode|diagnostic.?exec|shell.?command|command.?exec|native.?exec|Runtime[.;].*exec|ProcessBuilder|\bsystem\b|\bpopen\b|\bexecve\b|\bfork\b|\bchmod\b|\bchown\b",RegexOptions.IgnoreCase|RegexOptions.Compiled)},
   {"temporary",new Regex(@"wrap\.|LD_PRELOAD|CLASSPATH|DexClassLoader|PathClassLoader|loadDex|startInstrumentation|test.?runner|app.?fixup|overlayfs|\btmpfs\b|unshare|setns|MS_BIND|JNI_CreateJavaVM|dlopen|mprotect|process_vm_writev",RegexOptions.IgnoreCase|RegexOptions.Compiled)}
  };
  readonly Dictionary<string,Dictionary<string,object>> cache=new Dictionary<string,Dictionary<string,object>>();
  public int Files,Leaves,Archives,Reused,ExcludedMedia,ExcludedPE;
  public long ReadBytes;
  public List<string> Errors=new List<string>();
  public List<object> EmptyFiles=new List<object>();
  readonly StreamWriter output;
  public Scanner(string outputPath){output=new StreamWriter(outputPath,false,new UTF8Encoding(false));}
  public void Finish(){output.Dispose();}
  bool Archive(string n)=>new[]{".zip",".apk",".jar",".aar",".apks",".xapk"}.Contains(Path.GetExtension(n).ToLowerInvariant());
  bool Media(string n)=>new[]{".png",".jpg",".jpeg",".webp",".gif",".ogg",".wav",".mp3",".mp4",".ttf",".otf",".ico",".pdf"}.Contains(Path.GetExtension(n).ToLowerInvariant());
  public void ScanFile(string p){Files++;try{byte[] b=File.ReadAllBytes(p);ReadBytes+=b.Length;Scan(p,b,0);}catch(Exception e){Errors.Add(p+": "+e.Message);}}
  void Scan(string path,byte[] b,int depth){
   if(b.Length==0){EmptyFiles.Add(new{path,bytes=0});return;}
   if(b.Length>=2&&b[0]==77&&b[1]==90){ExcludedPE++;return;}
   if(Media(path)){ExcludedMedia++;return;}
   if(Archive(path)){
    if(depth>=8){Errors.Add(path+": archive depth limit 8");return;}
    try{using(var z=new ZipArchive(new MemoryStream(b),ZipArchiveMode.Read)){
     Archives++;
     foreach(var entry in z.Entries){if(entry.FullName.EndsWith("/"))continue;if(Media(entry.FullName)){ExcludedMedia++;continue;}
      try{using(var s=entry.Open())using(var m=new MemoryStream()){s.CopyTo(m);Scan(path+"!"+entry.FullName,m.ToArray(),depth+1);}}
      catch(Exception e){Errors.Add(path+"!"+entry.FullName+": "+e.Message);}
     }
    }return;}catch(Exception e){Errors.Add(path+": ZIP parse failed, raw fallback: "+e.Message);}
   }
   Leaves++;
   string hash=Convert.ToHexString(SHA256.HashData(b));
   Dictionary<string,object> results;
   if(cache.TryGetValue(hash,out results)){Reused++;}
   else {
    results=new Dictionary<string,object>();string text=Encoding.Latin1.GetString(b);
    var snippets=patterns.Keys.ToDictionary(k=>k,k=>new List<object>());
    var counts=patterns.Keys.ToDictionary(k=>k,k=>0);
    foreach(Match segment in printable.Matches(text)){
     foreach(var pair in patterns){Match hit=pair.Value.Match(segment.Value);if(!hit.Success)continue;counts[pair.Key]++;
      if(snippets[pair.Key].Count<24){int start=Math.Max(0,hit.Index-70);string value=segment.Value.Substring(start,Math.Min(240,segment.Length-start));snippets[pair.Key].Add(new{offset=segment.Index+start,text=value});}
     }
    }
    foreach(var key in patterns.Keys)if(counts[key]>0)results[key]=new{matchingPrintableSegments=counts[key],first24=snippets[key]};
    cache[hash]=results;
   }
   output.WriteLine(JsonSerializer.Serialize(new{path,bytes=b.Length,sha256=hash,categories=results}));
  }
 }
}
