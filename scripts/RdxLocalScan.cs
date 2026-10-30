namespace RdxOffline {
 using System;
 using System.IO;
 using System.IO.Compression;
 using System.Text;
 using System.Linq;
 using System.Collections.Generic;
 using System.Security.Cryptography;
 public sealed class ScanRecord {
  public string Location {get;set;} public string Kind {get;set;} public long Bytes {get;set;} public string SHA256 {get;set;}
  public string[] Matches {get;set;} public string[] DefinedProjectionClasses {get;set;} public object[] ModeMethods {get;set;}
 }
 public sealed class LocalScanner {
  public List<ScanRecord> Records=new List<ScanRecord>(); public List<string> Errors=new List<string>(); public int Containers;
  readonly string[] needles={"HMIPresenter","getVideoMode","com.honda.androidauto.projection.sink","com/honda/androidauto/projection/sink","com.google.android.projection","com/google/android/projection","libautoreceiver","GalReceiver","VideoSink"};
  readonly Dictionary<string,Tuple<string[],object[]>> dexCache=new Dictionary<string,Tuple<string[],object[]>>();
  bool IsArchive(string name){string e=Path.GetExtension(name).ToLowerInvariant();return new[]{".zip",".apk",".jar",".aar",".apks",".xapk"}.Contains(e);}
  public void ScanFile(string path){try {using(var s=File.OpenRead(path))Scan(s,path,new FileInfo(path).Length,0);}catch(Exception e){Errors.Add(path+": "+e.Message);}}
  void Scan(Stream stream,string location,long length,int depth){
   if(IsArchive(location)){
    try{
     using(var zip=new ZipArchive(stream,ZipArchiveMode.Read,true)){
      Containers++;Records.Add(new ScanRecord{Location=location,Kind="zip-container",Bytes=length,Matches=new string[0]});
      foreach(var entry in zip.Entries){if(entry.FullName.EndsWith("/"))continue;string child=location+"!"+entry.FullName;
       try{
        using(var es=entry.Open()){
         if(IsArchive(entry.FullName)){
          if(depth>8)throw new InvalidDataException("Nested archive depth > 8");
          using(var memory=new MemoryStream()){es.CopyTo(memory);memory.Position=0;Scan(memory,child,memory.Length,depth+1);}
         }else ScanLeaf(es,child,entry.Length);
        }
       }catch(Exception e){Errors.Add(child+": "+e.Message);}
      }
     }return;
    }catch(Exception e){Errors.Add(location+": archive parse failed; raw fallback: "+e.Message);if(!stream.CanSeek)return;stream.Position=0;}
   }
   ScanLeaf(stream,location,length);
  }
  void ScanLeaf(Stream stream,string location,long length){
   var hits=new HashSet<string>();byte[] buffer=new byte[1024*1024];string tail="";int n;
   bool isDex=location.EndsWith(".dex",StringComparison.OrdinalIgnoreCase);MemoryStream dexMemory=isDex?new MemoryStream():null;
   using(var hash=IncrementalHash.CreateHash(HashAlgorithmName.SHA256)){
    while((n=stream.Read(buffer,0,buffer.Length))>0){hash.AppendData(buffer,0,n);if(dexMemory!=null)dexMemory.Write(buffer,0,n);
     string text=tail+Encoding.Latin1.GetString(buffer,0,n);
     foreach(string needle in needles)if(text.IndexOf(needle,StringComparison.Ordinal)>=0)hits.Add(needle);
     tail=text.Substring(Math.Max(0,text.Length-256));
    }
    string sha=Convert.ToHexString(hash.GetHashAndReset());var record=new ScanRecord{Location=location,Kind=isDex?"dex":"leaf",Bytes=length,SHA256=sha,Matches=hits.ToArray()};
    if(isDex){
     try{
      if(!dexCache.TryGetValue(sha,out var summary)){
       byte[] bytes=dexMemory.ToArray();var dex=new Dex(bytes);
       string[] defined=dex.DefinedClasses().Where(s=>s.Contains("/androidauto/")||s.Contains("/projection/")||s.Contains("HMIPresenter")).ToArray();
       object[] methods=dex.Methods.Where(m=>m.CodeOffset!=0 && (m.Name=="getVideoMode" || m.Class.Contains("HMIPresenter"))).Select(m=>(object)new {m.Class,m.Name,m.Prototype,m.MethodIndex,m.CodeOffset,m.InstructionsOffset,m.InstructionUnits,CodeSHA256=Dex.HexHash(bytes.Skip(m.InstructionsOffset).Take(2*m.InstructionUnits).ToArray())}).ToArray();
       summary=Tuple.Create(defined,methods);dexCache[sha]=summary;
      }
      record.DefinedProjectionClasses=summary.Item1;record.ModeMethods=summary.Item2;
     }catch(Exception e){Errors.Add(location+": DEX parse failed: "+e.Message);}
    }
    Records.Add(record);
   }
   if(dexMemory!=null)dexMemory.Dispose();
   if(Records.Count%500==0)System.Console.WriteLine("Offline search: "+Records.Count+" entries inspected");
  }
 }
}
