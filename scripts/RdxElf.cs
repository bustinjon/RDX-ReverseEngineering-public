using System;
using System.IO;
using System.Text;
using System.Linq;
using System.Collections.Generic;
namespace RdxOffline {
 public sealed class ElfSection { public string Name; public uint Type,Address,Offset,Size,Link,EntrySize,Flags; }
 public sealed class ElfSymbol { public string Name; public uint Value,Size; public byte Info; public ushort Section; public bool Thumb => (Value&1)!=0; public uint Address => Value&~1u; }
 public sealed class ElfString { public int Offset; public uint Address; public string Value; }
 public sealed class ElfRelocation { public uint Offset,Type; public string Symbol; public uint PltAddress; }
 public sealed class Elf32 {
  public byte[] Bytes; public List<ElfSection> Sections=new(); public List<ElfSymbol> Symbols=new(); public List<ElfRelocation> Relocations=new();
  uint U32(int p)=>BitConverter.ToUInt32(Bytes,p); ushort U16(int p)=>BitConverter.ToUInt16(Bytes,p);
  string Str(int p){int e=Array.IndexOf(Bytes,(byte)0,p);if(e<0)e=Bytes.Length;return Encoding.ASCII.GetString(Bytes,p,e-p);}
  public Elf32(byte[] b){Bytes=b;if(b.Length<52||b[0]!=127||b[1]!=69||b[2]!=76||b[3]!=70||b[4]!=1||b[5]!=1||U16(18)!=40)throw new InvalidDataException("Expected little-endian ELF32 ARM");
   int so=(int)U32(32),ss=U16(46),sn=U16(48),names=so+ss*U16(50);int no=(int)U32(names+16);
   for(int i=0;i<sn;i++){int p=so+i*ss;Sections.Add(new ElfSection{Name=Str(no+(int)U32(p)),Type=U32(p+4),Flags=U32(p+8),Address=U32(p+12),Offset=U32(p+16),Size=U32(p+20),Link=U32(p+24),EntrySize=U32(p+36)});}
   foreach(var s in Sections.Where(s=>s.Type==2||s.Type==11)){var st=Sections[(int)s.Link];for(uint j=0;j+16<=s.Size;j+=s.EntrySize==0?16:s.EntrySize){int p=(int)(s.Offset+j);Symbols.Add(new ElfSymbol{Name=Str((int)(st.Offset+U32(p))),Value=U32(p+4),Size=U32(p+8),Info=b[p+12],Section=U16(p+14)});}}
   foreach(var s in Sections.Where(s=>s.Type==9)){var sym=Sections[(int)s.Link];var st=Sections[(int)sym.Link];var plt=Sections.FirstOrDefault(v=>v.Name==".plt");int index=0;for(uint j=0;j+8<=s.Size;j+=s.EntrySize==0?8:s.EntrySize){int p=(int)(s.Offset+j);uint info=U32(p+4);int sp=(int)(sym.Offset+(info>>8)*sym.EntrySize);Relocations.Add(new ElfRelocation{Offset=U32(p),Type=info&255,Symbol=Str((int)(st.Offset+U32(sp))),PltAddress=s.Name==".rel.plt"&&plt!=null&&plt.Size==20+12*(s.Size/8)?plt.Address+20+(uint)(index*12):0});index++;}}
   Symbols=Symbols.GroupBy(s=>s.Name+":"+s.Value+":"+s.Size).Select(g=>g.First()).ToList();
  }
  public int FileOffset(uint va){foreach(var s in Sections)if(s.Type!=8&&va>=s.Address&&(ulong)va<(ulong)s.Address+s.Size)return checked((int)(s.Offset+va-s.Address));throw new InvalidDataException("Unmapped VA "+va.ToString("X"));}
  public string SymbolAt(uint address){var exact=Symbols.FirstOrDefault(s=>s.Section!=0&&s.Address==address&&s.Name.Length>0);if(exact!=null)return exact.Name;return Relocations.FirstOrDefault(r=>r.PltAddress!=0&&r.PltAddress==address)?.Symbol;}
  public byte[] FunctionBytes(ElfSymbol s){int p=FileOffset(s.Address);return Bytes.Skip(p).Take((int)s.Size).ToArray();}
  public List<ElfString> Strings(int minimum=5){var list=new List<ElfString>();for(int p=0;p<Bytes.Length;){if(Bytes[p]<32||Bytes[p]>126){p++;continue;}int start=p;while(p<Bytes.Length&&Bytes[p]>=32&&Bytes[p]<=126)p++;if(p-start<minimum)continue;uint va=0;foreach(var s in Sections)if(s.Type!=8&&start>=s.Offset&&(ulong)start<(ulong)s.Offset+s.Size){va=s.Address+(uint)start-s.Offset;break;}list.Add(new ElfString{Offset=start,Address=va,Value=Encoding.ASCII.GetString(Bytes,start,p-start)});}return list;}
 }
}
