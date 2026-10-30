package com.rdx.fullscreen.projection;
import android.hardware.usb.*;
import android.util.Log;
import java.io.IOException;

/** AOAP-only transport. Force-claims interface (matching Honda stock behavior). */
public final class UsbBulkTransport {
    private static final String TAG="RDX.TRANSPORT";
    private static final int WRITE_TIMEOUT_MS=30000;
    private static final int WRITE_MAX_RETRIES=10;
    private static final int READ_POLL_TIMEOUT_MS=500;
    private static final long READ_DEADLINE_MS=30000;
    private final UsbDeviceConnection connection;
    private final UsbInterface iface;
    private final UsbEndpoint in,out;
    private final byte[] scratch=new byte[32768];
    private int position,available;
    private volatile boolean closed;
    public static boolean isAllowedPhone(UsbDevice device) {
        int id=device.getProductId();
        return device.getVendorId()==0x18d1 && (id==0x2d00||id==0x2d01||id==0x2d04||id==0x2d05);
    }
    public UsbBulkTransport(UsbManager manager,UsbDevice device) throws IOException {
        if(!isAllowedPhone(device)) throw new IOException("Only enumerated Google AOAP phones allowed; no hub/TCU access");
        UsbInterface selected=null; UsbEndpoint input=null,output=null;
        for(int i=0;i<device.getInterfaceCount()&&selected==null;i++) {
            UsbInterface candidate=device.getInterface(i); UsbEndpoint a=null,b=null;
            if(candidate.getId()!=0) continue;
            for(int j=0;j<candidate.getEndpointCount();j++) {
                UsbEndpoint ep=candidate.getEndpoint(j);
                if(ep.getType()==UsbConstants.USB_ENDPOINT_XFER_BULK) {
                    if(ep.getDirection()==UsbConstants.USB_DIR_IN) a=ep; else b=ep;
                }
            }
            if(a!=null&&b!=null) { selected=candidate; input=a; output=b; }
        }
        if(selected==null) throw new IOException("No supported AOAP interface0 bulk pair");
        connection=manager.openDevice(device);
        if(connection==null) throw new IOException("USB open failed; grant/policy/device state unresolved");
        iface=selected; in=input; out=output;
        if(!connection.claimInterface(iface,true)) {
            connection.close(); throw new IOException("Forcing claim failed on interface 0");
        }
        clearEndpointHalts();
        checkAoapAlive();
        drainStaleData();
    }

    private void clearEndpointHalts() {
        // USB CLEAR_FEATURE(ENDPOINT_HALT) — standard recovery after force-claiming
        // bmRequestType: 0x02 = Host-to-device, Standard, Endpoint recipient
        // bRequest: 0x01 = CLEAR_FEATURE
        // wValue: 0x00 = ENDPOINT_HALT feature selector
        int rIn=connection.controlTransfer(0x02,0x01,0x00,in.getAddress(),null,0,1000);
        int rOut=connection.controlTransfer(0x02,0x01,0x00,out.getAddress(),null,0,1000);
        Log.i(TAG,"clearEndpointHalts IN(0x"+Integer.toHexString(in.getAddress())+")="+rIn
            +" OUT(0x"+Integer.toHexString(out.getAddress())+")="+rOut);
    }

    private void checkAoapAlive() {
        // AOAP GET_PROTOCOL — same control transfer Honda uses to detect AOAP support
        // bmRequestType: 0xC0 = Device-to-host, Vendor, Device recipient
        // bRequest: 51 = GET_PROTOCOL
        byte[] buf=new byte[2];
        int r=connection.controlTransfer(0xC0,51,0,0,buf,2,1000);
        if(r==2) {
            int ver=(buf[0]&0xFF)+((buf[1]&0xFF)<<8);
            Log.i(TAG,"AOAP alive: protocol version="+ver);
        } else {
            Log.w(TAG,"AOAP GET_PROTOCOL failed: r="+r+" (phone may be in stale state)");
        }
    }

    private void drainStaleData() {
        // Consume any data the phone queued for Honda's now-dead session
        int total=0;
        byte[] drain=new byte[16384];
        for(int i=0;i<20;i++) {
            int n=connection.bulkTransfer(in,drain,drain.length,50);
            if(n<=0) break;
            total+=n;
        }
        if(total>0) Log.i(TAG,"Drained "+total+" stale bytes from IN endpoint");
    }

    public void readFully(byte[] destination,int offset,int count) throws IOException {
        long deadline=android.os.SystemClock.elapsedRealtime()+READ_DEADLINE_MS;
        while(count>0&&!closed) {
            if(available==0) {
                int n=connection.bulkTransfer(in,scratch,scratch.length,READ_POLL_TIMEOUT_MS);
                if(n<=0) {
                    if(android.os.SystemClock.elapsedRealtime()>deadline) throw new IOException("USB read timeout/disconnect");
                    continue;
                }
                position=0; available=n; deadline=android.os.SystemClock.elapsedRealtime()+READ_DEADLINE_MS;
            }
            int n=Math.min(count,available);
            System.arraycopy(scratch,position,destination,offset,n);
            position+=n; available-=n; offset+=n; count-=n;
        }
        if(count!=0) throw new IOException("Transport closed");
    }
    public void write(byte[] data,int length) throws IOException {
        int pos=0;
        while(pos<length&&!closed) {
            int retries=0;
            while(retries<WRITE_MAX_RETRIES&&!closed) {
                long t0=android.os.SystemClock.elapsedRealtime();
                int n=connection.bulkTransfer(out,data,pos,length-pos,WRITE_TIMEOUT_MS);
                long dt=android.os.SystemClock.elapsedRealtime()-t0;
                if(n>0) {
                    if(retries>0) Log.i(TAG,"Write recovered "+n+"b retry="+retries+" "+dt+"ms");
                    pos+=n; break;
                }
                retries++;
                Log.w(TAG,"Write fail "+retries+"/"+WRITE_MAX_RETRIES
                    +" rc="+n+" "+dt+"ms pos="+pos+"/"+length
                    +" ep=0x"+Integer.toHexString(out.getAddress()));
                int clr=connection.controlTransfer(0x02,0x01,0x00,out.getAddress(),null,0,500);
                Log.i(TAG,"CLEAR_HALT OUT rc="+clr+" before retry "+(retries+1));
            }
            if(retries>=WRITE_MAX_RETRIES)
                throw new IOException("USB write failed after "+WRITE_MAX_RETRIES
                    +" retries pos="+pos+"/"+length);
        }
        if(pos!=length) throw new IOException("Transport closed");
    }
    public synchronized void close() {
        if(closed) return; closed=true;
        try { connection.releaseInterface(iface); } finally { connection.close(); }
    }
}
