using System;
using System.Collections.Generic;
namespace RdxOffline {
 // Read class-data definitions (not merely the DEX reference table), including native/abstract methods.
 public sealed class DexApi {
  public readonly HashSet<string> Definitions=new HashSet<string>();
  public readonly Dictionary<string,List<string>> Parents=new Dictionary<string,List<string>>();
  static int U(byte[] b,int p){return checked((int)BitConverter.ToUInt32(b,p));}
  static int Leb(byte[] b,ref int p){int v=0,s=0,x;do{x=b[p++];v|=(x&127)<<s;s+=7;if(s>35)throw new ArgumentException("Bad ULEB");}while((x&128)!=0);return v;}
  public DexApi(Dex dex){byte[] b=dex.Bytes;int count=U(b,96),offset=U(b,100);
   for(int n=0;n<count;n++){int c=offset+n*32;string name=dex.Types[U(b,c)];var parents=new List<string>();int super=BitConverter.ToInt32(b,c+8);if(super!=-1)parents.Add(dex.Types[super]);int it=U(b,c+12);if(it!=0)for(int j=0;j<U(b,it);j++)parents.Add(dex.Types[BitConverter.ToUInt16(b,it+4+j*2)]);Parents[name]=parents;
    int p=U(b,c+24);if(p==0)continue;int sf=Leb(b,ref p),inf=Leb(b,ref p),dm=Leb(b,ref p),vm=Leb(b,ref p);
    for(int j=0;j<sf+inf;j++){Leb(b,ref p);Leb(b,ref p);}foreach(int group in new[]{dm,vm}){int ix=0;for(int j=0;j<group;j++){ix+=Leb(b,ref p);Leb(b,ref p);Leb(b,ref p);DexMethod m=dex.Methods[ix];Definitions.Add(m.Class+"->"+m.Name+m.Prototype);}}
   }
  }
 }
}
