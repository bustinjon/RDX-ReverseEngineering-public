package com.rdx.fullscreen.clean;
import android.hardware.usb.*;
import java.util.*;
public final class AndroidUsbInventory implements UsbInventory {
 private final UsbManager manager;
 public AndroidUsbInventory(UsbManager m){manager=m;}
 public List<DeviceIdentity> snapshot(){if(manager==null)throw new IllegalStateException("No UsbManager supplied");List<DeviceIdentity> out=new ArrayList<DeviceIdentity>();HashMap<String,UsbDevice> all=manager.getDeviceList();if(all!=null)for(UsbDevice d:all.values())out.add(new DeviceIdentity(d.getDeviceName(),d.getVendorId(),d.getProductId(),manager.hasPermission(d)));return out;}
}
