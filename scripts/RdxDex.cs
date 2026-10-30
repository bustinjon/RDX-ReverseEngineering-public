using System;
using System.IO;
using System.Text;
using System.Linq;
using System.Collections.Generic;
using System.Security.Cryptography;

namespace RdxOffline {
 public sealed class DexMethod {
  public int MethodIndex {get;set;} public string Class {get;set;} public string Name {get;set;} public string Prototype {get;set;}
  public int CodeOffset {get;set;} public int InstructionsOffset {get;set;} public int InstructionUnits {get;set;}
 }
 public sealed class LiteralPatch {
  public string Field {get;set;} public int InstructionByteOffset {get;set;} public int LiteralByteOffset {get;set;}
  public int CodeUnitOffset {get;set;} public int Before {get;set;} public int After {get;set;}
 }
 public sealed class Dex {
  public byte[] Bytes; public string[] Strings, Types; public DexMethod[] Methods;
  int fieldsOffset, classDefsOffset, classDefsCount;
  public static string HexHash(byte[] data) { return Convert.ToHexString(SHA256.HashData(data)); }
  int U32(int p) { return checked((int)BitConverter.ToUInt32(Bytes,p)); }
  int U16(int p) { return BitConverter.ToUInt16(Bytes,p); }
  int Uleb(ref int p) { int v=0,s=0,b; do { b=Bytes[p++]; v|=(b&127)<<s; s+=7; if(s>35)throw new InvalidDataException("ULEB too long"); }while((b&128)!=0); return v; }
  public Dex(byte[] bytes) {
   Bytes=bytes; if(bytes.Length<112 || Encoding.ASCII.GetString(bytes,0,4)!="dex\n" || U32(40)!=0x12345678) throw new InvalidDataException("Unsupported DEX header");
   int count=U32(56), off=U32(60); Strings=new string[count];
   for(int i=0;i<count;i++) { int p=U32(off+4*i); Uleb(ref p); int end=Array.IndexOf(bytes,(byte)0,p); Strings[i]=Encoding.UTF8.GetString(bytes,p,end-p); }
   count=U32(64); off=U32(68); Types=new string[count]; for(int i=0;i<count;i++) Types[i]=Strings[U32(off+4*i)];
   int protoCount=U32(72), protoOff=U32(76); string[] protos=new string[protoCount];
   for(int i=0;i<protoCount;i++) { int p=protoOff+12*i, paramOff=U32(p+8); var b=new StringBuilder("("); if(paramOff!=0)for(int j=0;j<U32(paramOff);j++)b.Append(Types[U16(paramOff+4+2*j)]); b.Append(")").Append(Types[U32(p+4)]);protos[i]=b.ToString(); }
   fieldsOffset=U32(84); count=U32(88); off=U32(92); Methods=new DexMethod[count];
   for(int i=0;i<count;i++) { int p=off+8*i;Methods[i]=new DexMethod{MethodIndex=i,Class=Types[U16(p)],Name=Strings[U32(p+4)],Prototype=protos[U16(p+2)]}; }
   classDefsCount=U32(96);classDefsOffset=U32(100);
   for(int i=0;i<classDefsCount;i++) {
    int p=U32(classDefsOffset+32*i+24);if(p==0)continue;
    int sf=Uleb(ref p),inf=Uleb(ref p),dm=Uleb(ref p),vm=Uleb(ref p);
    for(int j=0;j<sf+inf;j++){Uleb(ref p);Uleb(ref p);}
    foreach(int groupCount in new[]{dm,vm}) { int index=0;for(int j=0;j<groupCount;j++){index+=Uleb(ref p);Uleb(ref p);int co=Uleb(ref p);Methods[index].CodeOffset=co;if(co!=0){Methods[index].InstructionsOffset=co+16;Methods[index].InstructionUnits=U32(co+12);}} }
   }
  }
  public string FieldName(int index) { int p=fieldsOffset+8*index; return Types[U16(p)]+"->"+Strings[U32(p+4)]+":"+Types[U16(p+2)]; }
  public string[] DefinedClasses() { var names=new string[classDefsCount];for(int i=0;i<classDefsCount;i++)names[i]=Types[U32(classDefsOffset+32*i)];return names; }
  public DexMethod PresenterMethod() { return Methods.Single(m=>m.Class=="Lcom/honda/androidauto/projection/sink/presentation/HMIPresenter;" && m.Name=="getVideoMode" && m.Prototype=="(Z)Lcom/honda/androidauto/projection/sink/presentation/VideoMode;"); }
  public List<LiteralPatch> PatchPrimary(int width,int height,int dpi=229) {
   if(width>32767||height>32767||width<1||height<1)throw new ArgumentOutOfRangeException();
   var m=PresenterMethod();var patches=new List<LiteralPatch>();int end=m.InstructionsOffset+2*m.InstructionUnits;
   // Match const/16 vA,literal immediately followed by iput vA,vB,VideoMode.field.
   // Require the original primary literals; secondary values and instruction layout remain untouched.
   for(int p=m.InstructionsOffset;p+8<=end;p+=2) {
    int first=U16(p), next=U16(p+4);if((first&255)!=0x13||(next&255)!=0x59)continue;
    int sourceRegister=(next>>8)&15;if(sourceRegister!=(first>>8))continue;
    int literal=(short)U16(p+2);string field=FieldName(U16(p+6));int value=0;
    if(field=="Lcom/honda/androidauto/projection/sink/presentation/VideoMode;->mX:I" && literal==1280)value=width;
    if(field=="Lcom/honda/androidauto/projection/sink/presentation/VideoMode;->mY:I" && literal==688)value=height;
    if(field=="Lcom/honda/androidauto/projection/sink/presentation/VideoMode;->mDpi:I" && literal==229 && dpi!=229)value=dpi;
    if(value!=0)patches.Add(new LiteralPatch{Field=field,InstructionByteOffset=p,LiteralByteOffset=p+2,CodeUnitOffset=(p-m.InstructionsOffset)/2,Before=literal,After=value});
   }
   int expected=dpi==229?2:3;
   if(patches.Count!=expected||patches.Select(p=>p.Field).Distinct().Count()!=expected)throw new InvalidDataException("Unexpected primary const/iput pairs");
   foreach(var patch in patches){byte[] b=BitConverter.GetBytes((short)patch.After);Array.Copy(b,0,Bytes,patch.LiteralByteOffset,2);}
   byte[] sha=SHA1.HashData(Bytes.AsSpan(32));Array.Copy(sha,0,Bytes,12,20);
   uint a=1,b2=0;for(int p=12;p<Bytes.Length;p++){a=(a+Bytes[p])%65521;b2=(b2+a)%65521;}Array.Copy(BitConverter.GetBytes((b2<<16)|a),0,Bytes,8,4);
   return patches;
  }
  public bool CheckHeaderHashes() {
   if(!SHA1.HashData(Bytes.AsSpan(32)).SequenceEqual(Bytes.Skip(12).Take(20)))return false;
   uint a=1,b=0;for(int p=12;p<Bytes.Length;p++){a=(a+Bytes[p])%65521;b=(b+a)%65521;}return BitConverter.ToUInt32(Bytes,8)==((b<<16)|a);
  }
 }
}
