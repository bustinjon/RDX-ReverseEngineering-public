package com.rdx.fullscreen.usbhelper;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.AccessibilityServiceInfo;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityWindowInfo;

import java.util.List;

public final class PermissionClickService extends AccessibilityService {
    private static final String TAG = "RDX.A11Y";
    private static final String USB_PERM_CLASS = "com.android.systemui.usb.UsbPermissionActivity";
    private static final String DIALOG_CLASS = "android.app.Dialog";
    private static final String SYSTEMUI_PKG = "com.android.systemui";
    private static final int MAX_RETRIES = 15;
    private static final long RETRY_DELAY_MS = 150;

    private final Handler handler = new Handler(Looper.getMainLooper());
    private int retryCount;
    private boolean clicked;

    private final Runnable retryRunnable = new Runnable() {
        @Override
        public void run() {
            attemptClick();
        }
    };

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event.getEventType() != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return;
        CharSequence className = event.getClassName();
        CharSequence pkgName = event.getPackageName();
        if (className == null) return;

        String cls = className.toString();
        String pkg = pkgName != null ? pkgName.toString() : "";

        // Match either the actual activity class OR the Dialog class from SystemUI
        // AlertActivity.dispatchPopulateAccessibilityEvent sets class to android.app.Dialog
        boolean isPermDialog = USB_PERM_CLASS.equals(cls)
                || (DIALOG_CLASS.equals(cls) && SYSTEMUI_PKG.equals(pkg));

        if (isPermDialog) {
            long t = android.os.SystemClock.elapsedRealtime();
            Log.i(TAG, "Potential USB permission dialog: class=" + cls + " pkg=" + pkg + " at " + t + "ms");
            handler.removeCallbacks(retryRunnable);
            retryCount = 0;
            clicked = false;
            attemptClick();
        }
    }

    private void attemptClick() {
        if (clicked) return;
        retryCount++;

        // Try active window first (fastest path)
        AccessibilityNodeInfo root = getRootInActiveWindow();
        if (root != null) {
            try {
                if (isUsbPermissionWindow(root) && tryClickInRoot(root)) return;
            } finally {
                root.recycle();
            }
        }

        // Active window didn't match — scan SystemUI windows only (F2 fix).
        List<AccessibilityWindowInfo> windows = null;
        try {
            windows = getWindows();
            Log.d(TAG, "Scanning " + windows.size() + " windows (attempt " + retryCount + "/" + MAX_RETRIES + ")");
            for (AccessibilityWindowInfo window : windows) {
                AccessibilityNodeInfo wRoot = window.getRoot();
                if (wRoot != null) {
                    try {
                        if (isUsbPermissionWindow(wRoot) && tryClickInRoot(wRoot)) return;
                    } finally {
                        wRoot.recycle();
                    }
                }
            }
        } catch (Exception e) {
            Log.w(TAG, "getWindows() failed: " + e.getMessage());
        } finally {
            if (windows != null) {
                for (AccessibilityWindowInfo w : windows) {
                    w.recycle();
                }
            }
        }

        if (retryCount < MAX_RETRIES) {
            Log.d(TAG, "Not found (attempt " + retryCount + "), retry in " + RETRY_DELAY_MS + "ms");
            handler.postDelayed(retryRunnable, RETRY_DELAY_MS);
        } else {
            Log.e(TAG, "FAILED after " + MAX_RETRIES + " attempts");
            AccessibilityNodeInfo debugRoot = getRootInActiveWindow();
            if (debugRoot != null) {
                try {
                    Log.e(TAG, "Final active window tree:");
                    dumpTree(debugRoot, 0);
                } finally {
                    debugRoot.recycle();
                }
            }
        }
    }

    private boolean isUsbPermissionWindow(AccessibilityNodeInfo root) {
        // Verify this is a USB permission dialog, not some other SystemUI dialog.
        // Look for "USB" text anywhere in the tree as content validation.
        CharSequence pkg = root.getPackageName();
        if (pkg == null || !SYSTEMUI_PKG.equals(pkg.toString())) return false;
        List<AccessibilityNodeInfo> usbNodes = root.findAccessibilityNodeInfosByText("USB");
        if (usbNodes == null || usbNodes.isEmpty()) return false;
        for (AccessibilityNodeInfo n : usbNodes) n.recycle();
        Log.i(TAG, "Confirmed USB permission dialog (SystemUI + USB text)");
        return true;
    }

    private boolean tryClickInRoot(AccessibilityNodeInfo root) {
        if (clickButton(root, "OK") || clickButton(root, "Allow")) {
            long t = android.os.SystemClock.elapsedRealtime();
            Log.i(TAG, "SUCCESS — clicked permission button on attempt " + retryCount + " at " + t + "ms");
            clicked = true;
            handler.removeCallbacks(retryRunnable);
            return true;
        }
        return false;
    }

    private boolean clickButton(AccessibilityNodeInfo root, String text) {
        List<AccessibilityNodeInfo> nodes = root.findAccessibilityNodeInfosByText(text);
        if (nodes == null || nodes.isEmpty()) return false;
        boolean success = false;
        try {
            for (AccessibilityNodeInfo node : nodes) {
                if (success) continue; // still iterate to recycle all
                if (node.isClickable()) {
                    Log.i(TAG, "Found clickable: '" + node.getText() + "' class=" + node.getClassName());
                    success = node.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                    Log.i(TAG, "performAction(CLICK) returned " + success);
                    continue;
                }
                AccessibilityNodeInfo parent = node.getParent();
                if (parent != null) {
                    try {
                        if (parent.isClickable()) {
                            Log.i(TAG, "Found clickable parent: class=" + parent.getClassName());
                            success = parent.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                            Log.i(TAG, "performAction(CLICK) on parent returned " + success);
                        }
                    } finally {
                        parent.recycle();
                    }
                }
            }
        } finally {
            for (AccessibilityNodeInfo node : nodes) node.recycle();
        }
        return success;
    }

    private void dumpTree(AccessibilityNodeInfo node, int depth) {
        if (node == null) return;
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < depth; i++) sb.append("  ");
        sb.append(node.getClassName());
        sb.append(" pkg=").append(node.getPackageName());
        sb.append(" text='").append(node.getText()).append("'");
        sb.append(" click=").append(node.isClickable());
        sb.append(" desc='").append(node.getContentDescription()).append("'");
        Log.i(TAG, sb.toString());
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo child = node.getChild(i);
            if (child != null) {
                try {
                    dumpTree(child, depth + 1);
                } finally {
                    child.recycle();
                }
            }
        }
    }

    @Override
    public void onInterrupt() {
        Log.w(TAG, "AccessibilityService interrupted");
    }

    @Override
    public void onDestroy() {
        handler.removeCallbacks(retryRunnable);
        super.onDestroy();
    }

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        AccessibilityServiceInfo info = new AccessibilityServiceInfo();
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED;
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC;
        info.flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
                | AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS;
        setServiceInfo(info);
        Log.i(TAG, "PermissionClickService connected — watching for USB permission dialogs");
    }
}
