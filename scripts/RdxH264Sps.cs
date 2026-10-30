using System;
using System.Collections.Generic;
namespace RdxOffline {
 public sealed class H264SpsInfo {
  public int ProfileIdc, LevelIdc, CodedWidth, CodedHeight, DisplayWidth, DisplayHeight;
  public int CropLeft, CropRight, CropTop, CropBottom, FrameMbsOnly;
 }
 public static class H264Sps {
  sealed class Bits {
   byte[] data; int p;
   public Bits(byte[] b){data=b;}
   public int Read(int n){if(n<0||n>24||p+n>data.Length*8)throw new ArgumentException("SPS bit bounds");int r=0;while(n-->0){r=(r<<1)|((data[p/8]>>(7-p%8))&1);p++;}return r;}
   public int Ue(){int n=0;while(Read(1)==0){if(++n>20)throw new ArgumentException("SPS Exp-Golomb bounds");}return ((1<<n)-1)+Read(n);}
   public int Se(){int n=Ue();return (n&1)==0?-(n/2):(n+1)/2;}
  }
  static int Start(byte[] b,int i){if(i+3>b.Length||b[i]!=0||b[i+1]!=0)return 0;if(b[i+2]==1)return 3;if(i+4<=b.Length&&b[i+2]==0&&b[i+3]==1)return 4;return 0;}
  public static H264SpsInfo ParseAnnexB(byte[] bytes){
   for(int i=0;i<bytes.Length-3;i++){int prefix=Start(bytes,i);if(prefix==0)continue;int first=i+prefix;if(first>=bytes.Length)break;if((bytes[first]&31)!=7)continue;
    int end=first+1;while(end<bytes.Length&&Start(bytes,end)==0)end++;
    var rbsp=new List<byte>();int zeros=0;
    for(int j=first+1;j<end;j++){int v=bytes[j];if(zeros>=2&&v==3){zeros=0;continue;}rbsp.Add((byte)v);zeros=v==0?zeros+1:0;}
    var r=new Bits(rbsp.ToArray());var s=new H264SpsInfo();s.ProfileIdc=r.Read(8);r.Read(8);s.LevelIdc=r.Read(8);r.Ue();
    if(s.ProfileIdc!=66)throw new ArgumentException("Independent inspector supports generated baseline SPS only");
    r.Ue();int poc=r.Ue();if(poc==0)r.Ue();else if(poc==1){r.Read(1);r.Se();r.Se();int cycles=r.Ue();if(cycles>255)throw new ArgumentException("SPS POC bound");for(int n=0;n<cycles;n++)r.Se();}else if(poc!=2)throw new ArgumentException("SPS POC type");
    r.Ue();r.Read(1);int w=r.Ue(),h=r.Ue();if(w>4095||h>4095)throw new ArgumentException("SPS size bound");s.FrameMbsOnly=r.Read(1);if(s.FrameMbsOnly==0)r.Read(1);r.Read(1);
    int l=0,rr=0,t=0,b=0;if(r.Read(1)!=0){l=r.Ue();rr=r.Ue();t=r.Ue();b=r.Ue();}
    s.CodedWidth=(w+1)*16;s.CodedHeight=(2-s.FrameMbsOnly)*(h+1)*16;
    s.CropLeft=l*2;s.CropRight=rr*2;s.CropTop=t*2*(2-s.FrameMbsOnly);s.CropBottom=b*2*(2-s.FrameMbsOnly);
    s.DisplayWidth=s.CodedWidth-s.CropLeft-s.CropRight;s.DisplayHeight=s.CodedHeight-s.CropTop-s.CropBottom;
    if(s.DisplayWidth<=0||s.DisplayHeight<=0)throw new ArgumentException("SPS crop bounds");return s;
   }
   throw new ArgumentException("Annex B SPS not found");
  }
 }
}
