package com.rdx.fullscreen.clean;
/** Literal fixtures are NOT generated through our writer. See fixtures/PROVENANCE.md. */
public final class IndependentFixtures {
 public static final byte[] VERSION=hex("00030006000100010001");
 public static final byte[] DATA=hex("0203000480000800");
 public static final byte[] FIRST=hex("0201000200000005000b");
 public static final byte[] MIDDLE=hex("0200000108");
 public static final byte[] LAST=hex("020200029601");
 public static final byte[] INTERLEAVED=hex("0201000200000004000b0701000200000004000c020200020801070200020802");
 public static final byte[] EMPTY=hex("02030000");
 public static final byte[] MAX_EIGHT=hex("010300080001010203040506");
 public static final byte[] OVER_EIGHT=hex("01030009000101020304050607");
 public static final byte[] RESERVED=hex("001300020001");
 public static final byte[] UNKNOWN_CHANNEL=hex("63030002000b");
 public static final byte[] CONTROL_FLAG=hex("00070004000b0801");
 public static final byte[] OPAQUE_ENCRYPTED=hex("000b0003999897");
 public static final byte[] CONSERVATIVE=hex("080210011800202028e501");
 public static final byte[] FULLSCREEN=hex("08031002180020e80228e501");
 public static final byte[] TOUCHPAD=hex("08ad0a10d0051801203c28283001");
 public static final byte[] DISCOVERY=hex("0a1308021a0f0803220b080210011800202028e5010a14080722101a0e08ad0a10d0051801203c282830011201501a014d2201592a0030003a01484201554a01425201565800");
 public static final byte[] ENCODED_DISCOVERY=hex("0a1308021a0f0803220b080210011800202028e5010a14080722101a0e08ad0a10d0051801203c28283001120c5244582072657365617263681a0c4f66666c696e6520636f72652204323032312a0030003a0b496e646570656e64656e74420950757265204a6176614a076f66666c696e65520c302e332d70726f746f636f6c5800");
 // Captured plaintext only, NOT outer AA framing or TLS records. No credentials/identities.
 public static final byte[] CAPTURE_OPEN=hex("000708001001");
 public static final byte[] CAPTURE_PING_REQUEST=hex("000b08e7c9dccace6a1000");
 public static final byte[] CAPTURE_PING_RESPONSE=hex("000c08e7c9dccace6a");
 public static byte[] hex(String text){if((text.length()&1)!=0)throw new IllegalArgumentException("Odd hex");byte[] out=new byte[text.length()/2];for(int i=0;i<out.length;i++){int a=Character.digit(text.charAt(i*2),16),b=Character.digit(text.charAt(i*2+1),16);if(a<0||b<0)throw new IllegalArgumentException("Bad hex");out[i]=(byte)((a<<4)|b);}return out;}
 private IndependentFixtures(){}
}
