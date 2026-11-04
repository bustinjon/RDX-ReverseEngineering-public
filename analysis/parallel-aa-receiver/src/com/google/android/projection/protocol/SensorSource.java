package com.google.android.projection.protocol;

import android.util.Log;

/**
 * JNI facade for the native SensorSource in libautoreceiver_jni.so.
 * Stub: registers sensors so service discovery includes them.
 * Reports static safe defaults (parked, night=false, speed=0).
 */
public final class SensorSource {
    private static final String TAG = "RDX.SENSOR";

    @SuppressWarnings("unused") // set by native code
    private long mNativeSensorSource;
    private boolean created;

    // Sensor type values (Protos.SensorType.getNumber())
    static final int LOCATION = 1, COMPASS = 2, SPEED = 3, RPM = 4,
        ODOMETER = 5, FUEL = 6, PARKING_BRAKE = 7, GEAR = 8,
        NIGHT_MODE = 10, ENVIRONMENT = 11, HVAC = 12,
        DRIVING_STATUS = 13, ACCELEROMETER = 19, GYROSCOPE = 20,
        GPS_SATELLITE = 21;

    static final int LOCATION_CHARACTERIZATION_RAW_GPS_ONLY = 256;
    static final int GEAR_PARK = 101;

    private native int nativeInit(int i, long j, int i2, int[] iArr, int[] iArr2) throws IllegalStateException;
    private native void nativeRegisterSensor(int i);
    private native int nativeReportAccelerometerData(boolean z, int i, boolean z2, int i2, boolean z3, int i3);
    private native int nativeReportCompassData(int i, boolean z, int i2, boolean z2, int i3);
    private native int nativeReportDeadReckoningData(boolean z, int i, int[] iArr);
    private native int nativeReportDiagnosticsData(byte[] bArr);
    private native int nativeReportDoorData(boolean z, boolean z2, boolean z3, boolean z4, boolean[] zArr);
    private native int nativeReportDrivingStatusData(int i);
    private native int nativeReportEnvironmentData(boolean z, int i, boolean z2, int i2, boolean z3, int i3);
    private native int nativeReportFuelData(boolean z, int i, boolean z2, int i2, boolean z3, boolean z4);
    private native int nativeReportGearData(int i);
    private native int nativeReportGpsSatelliteData(int i, boolean z, int i2, int[] iArr, int[] iArr2, boolean[] zArr, int[] iArr3, int[] iArr4);
    private native int nativeReportGyroscopeData(boolean z, int i, boolean z2, int i2, boolean z3, int i3);
    private native int nativeReportHvacData(boolean z, int i, boolean z2, int i2);
    private native int nativeReportLightData(boolean z, int i, boolean z2, int i2, boolean z3, boolean z4);
    private native int nativeReportLocation(long j, int i, int i2, boolean z, int i3, boolean z2, int i4, boolean z3, int i5, boolean z4, int i6);
    private native int nativeReportNightModeData(boolean z);
    private native int nativeReportOdometerData(int i, boolean z, int i2);
    private native int nativeReportParkingBrakeData(boolean z);
    private native int nativeReportPassengerData(boolean z);
    private native int nativeReportRpmData(int i);
    private native int nativeReportSensorError(int i, int i2);
    private native int nativeReportSpeedData(int i, boolean z, boolean z2, boolean z3, int i2);
    private native int nativeReportTirePressureData(int[] iArr);
    private native void nativeShutdown();

    public void initialize(int serviceId, long receiverHandle) {
        int[] defaultSensors = {
            LOCATION, SPEED, COMPASS, RPM, ODOMETER, FUEL, PARKING_BRAKE,
            GEAR, NIGHT_MODE, ENVIRONMENT, HVAC, DRIVING_STATUS,
            ACCELEROMETER, GYROSCOPE, GPS_SATELLITE
        };
        if (nativeInit(serviceId, receiverHandle,
                LOCATION_CHARACTERIZATION_RAW_GPS_ONLY,
                new int[0], new int[0]) != 0) {
            throw new IllegalStateException("SensorSource nativeInit rejected");
        }
        created = true;
        for (int sensor : defaultSensors) {
            nativeRegisterSensor(sensor);
        }
        Log.i(TAG, "SensorSource initialized id=" + serviceId
            + " sensors=" + defaultSensors.length);
    }

    public long handle() { return mNativeSensorSource; }

    public synchronized void reportInitialState() {
        if (!created) return;
        nativeReportDrivingStatusData(0);
        nativeReportNightModeData(false);
        nativeReportParkingBrakeData(true);
        nativeReportGearData(GEAR_PARK);
        nativeReportSpeedData(0, false, false, false, 0);
        Log.i(TAG, "Initial sensor state reported (parked, day mode)");
    }

    /** Synchronized with destroy() so a report can never overlap native shutdown. */
    public synchronized boolean reportNightMode(boolean night) {
        if (!created) return false;
        int result = nativeReportNightModeData(night);
        Log.i(TAG, "Night mode reported night=" + night + " result=" + result);
        return result == 0;
    }

    public synchronized void destroy() {
        if (created) {
            created = false;
            nativeShutdown();
            Log.i(TAG, "SensorSource destroyed");
        }
    }
}
