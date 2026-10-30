package com.rdx.fullscreen.clean;
/** Bounded TLS1.2 visible-record envelope check ONLY. Does not authenticate or decrypt. */
public final class TlsRecordLedger {
 private TlsRecordLedger(){}
 public static int completeApplicationRecords(byte[] b){
  if(b==null||b.length==0||b.length>65535)throw new IllegalArgumentException("TLS body bound");int p=0,count=0;
  while(p<b.length){if(b.length-p<5)throw new IllegalArgumentException("BODY_DECRYPT_INCOMPLETE header");int type=b[p]&255,major=b[p+1]&255,minor=b[p+2]&255,n=((b[p+3]&255)<<8)|(b[p+4]&255);
   if(type!=23)throw new IllegalArgumentException("UNSUPPORTED_TLS_CONTROL_RECORD");if(major!=3||minor!=3||n==0||n>18432)throw new IllegalArgumentException("TLS1.2 record policy");
   if(n>b.length-p-5)throw new IllegalArgumentException("BODY_DECRYPT_INCOMPLETE payload");p+=5+n;if(++count>256)throw new IllegalArgumentException("TLS record count");
  }return count;
 }
}
