package com.rdx.fullscreen.usbhelper;

import android.app.Activity;
import android.content.Intent;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Bundle;
import android.util.Log;

/**
 * Transparent activity that receives USB_DEVICE_ATTACHED via manifest intent-filter.
 * When the system auto-launches this (because we're the sole/default match for the
 * device_filter), it also auto-grants USB permission — no dialog needed.
 * Immediately hands off to UsbHelperService and finishes.
 */
public class UsbAttachActivity extends Activity {
    private static final String TAG = "RDX.USB";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Intent intent = getIntent();
        UsbDevice device = intent != null
            ? (UsbDevice) intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
            : null;

        if (device != null) {
            Log.i(TAG, "UsbAttachActivity: auto-grant for " + device.getDeviceName()
                + " vid=" + Integer.toHexString(device.getVendorId())
                + " pid=" + Integer.toHexString(device.getProductId()));

            UsbManager usbManager = (UsbManager) getSystemService(USB_SERVICE);
            Log.i(TAG, "UsbAttachActivity: hasPermission=" + usbManager.hasPermission(device));

            Intent serviceIntent = new Intent(this, UsbHelperService.class);
            serviceIntent.setAction("usb.device.AUTO_GRANTED");
            serviceIntent.putExtra(UsbManager.EXTRA_DEVICE, device);
            startService(serviceIntent);
        } else {
            Log.i(TAG, "UsbAttachActivity: no device extra");
        }

        finish();
    }
}
