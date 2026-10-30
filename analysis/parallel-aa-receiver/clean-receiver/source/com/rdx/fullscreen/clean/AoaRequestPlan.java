package com.rdx.fullscreen.clean;
/** Data only; never submits a control transfer. */
public final class AoaRequestPlan {
 public final int requestType,request,value,index,expectedResponseBytes;private final byte[] payload;
 public AoaRequestPlan(int type,int code,int v,int i,int response,byte[] data){requestType=type;request=code;value=v;index=i;expectedResponseBytes=response;payload=data.clone();}
 public byte[] payload(){return payload.clone();}
}
