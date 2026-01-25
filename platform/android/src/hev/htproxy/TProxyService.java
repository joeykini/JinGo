/*
 * TProxyService.java
 *
 * This class is required by libhev-socks5-tunnel.so for JNI registration.
 * The library has JNI_OnLoad that registers native methods to this class.
 *
 * Note: This is a stub implementation. The actual tunnel functionality
 * is handled through direct C++ calls in HevSocks5Tunnel.cpp.
 */
package hev.htproxy;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;

public class TProxyService extends Service {
    private static final String TAG = "TProxyService";

    // NOTE: The SuperRay library is loaded by SuperRayManager JNI wrapper
    // We don't load it here to avoid duplicate loading or version conflicts
    // The actual native methods are registered through libsuperray.so

    // Native methods registered by libsuperray.so JNI_OnLoad
    // These exist to satisfy the library's JNI registration requirements

    /**
     * Start the transparent proxy service (native implementation)
     * Not used - we use HevSocks5Tunnel C++ wrapper instead
     * @param config Configuration string
     * @param fd TUN device file descriptor
     */
    public static native void TProxyStartService(String config, int fd);

    /**
     * Stop the transparent proxy service (native implementation)
     * Not used - we use HevSocks5Tunnel C++ wrapper instead
     */
    public static native void TProxyStopService();

    /**
     * Get service statistics (native implementation)
     * @return Array of statistics [rx_bytes, tx_bytes, ...]
     * Not used - we use HevSocks5Tunnel C++ wrapper instead
     */
    public static native long[] TProxyGetStats();

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "TProxyService created (stub for JNI registration)");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "TProxyService onStartCommand (not used)");
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "TProxyService destroyed");
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
