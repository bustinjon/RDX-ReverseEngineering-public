package com.rdx.fullscreen.usbhelper;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Starts BootBlockerService on BOOT_COMPLETED to cover Honda's malicious-detector dialog. */
public class BootBlockerReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || !Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            return;
        }
        context.startService(new Intent(context, BootBlockerService.class));
    }
}
