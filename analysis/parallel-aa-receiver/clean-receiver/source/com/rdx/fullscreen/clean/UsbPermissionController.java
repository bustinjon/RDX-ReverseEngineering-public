package com.rdx.fullscreen.clean;
/** Contract only; gated M5 is separate and is not wired into this foundation. */
public interface UsbPermissionController { void request(DeviceIdentity device,boolean operatorM4Acknowledgment); }
