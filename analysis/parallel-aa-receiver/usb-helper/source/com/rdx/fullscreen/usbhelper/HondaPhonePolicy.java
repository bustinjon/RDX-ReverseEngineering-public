package com.rdx.fullscreen.usbhelper;

/** Operator-selected phone policy. This does not read or prove Honda's preference. */
public final class HondaPhonePolicy {
    private final String serial;
    public HondaPhonePolicy(String serial) {
        if (serial != null && !isValidSerial(serial)) throw new IllegalArgumentException("Invalid phone serial");
        this.serial = serial;
    }
    public static boolean isValidSerial(String value) {
        return value != null && value.matches("[A-Za-z0-9._-]{1,64}");
    }
    public boolean isCooperative() { return serial != null; }
    public boolean allows(String candidate) { return serial == null || serial.equals(candidate); }
    public boolean allowsRaw(boolean legacyStopped, String candidate) {
        return isCooperative() ? allows(candidate) : legacyStopped;
    }
}
