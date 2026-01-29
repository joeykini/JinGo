/*
 * SuperRayManager.java - SuperRay JNI Wrapper
 *
 * Provides Java interface to SuperRay native library.
 * SuperRay combines Xray-core and TUN processing in a unified library.
 */

package work.opine.jingo;

import android.util.Log;

/**
 * SuperRay Manager - JNI wrapper for SuperRay native library
 *
 * SuperRay is a unified library that replaces both libXray and hev-socks5-tunnel.
 * It provides:
 * - Xray-core functionality (proxy protocols, routing, etc.)
 * - TUN device processing (packet handling, DNS interception, etc.)
 * - Direct statistics API (no HTTP/gRPC polling needed)
 */
public class SuperRayManager {
    private static final String TAG = "SuperRayManager";
    private static SuperRayManager instance;
    private static boolean libraryLoaded = false;

    static {
        try {
            // Load SuperRay native library
            // This is the unified library that includes both Xray and TUN processing
            System.loadLibrary("superray");
            libraryLoaded = true;
            Log.i(TAG, "SuperRay native library loaded successfully");
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "Failed to load SuperRay native library: " + e.getMessage());
            libraryLoaded = false;
        }
    }

    /**
     * Get singleton instance
     */
    public static synchronized SuperRayManager getInstance() {
        if (instance == null) {
            instance = new SuperRayManager();
        }
        return instance;
    }

    /**
     * Check if native library is loaded
     */
    public static boolean isLibraryLoaded() {
        return libraryLoaded;
    }

    // ========================================================================
    // Native Method Declarations
    // ========================================================================

    /**
     * Start SuperRay with TUN device
     *
     * @param tunFd TUN file descriptor from VpnService.Builder.establish()
     * @param mtu MTU value for the TUN device
     * @param socksAddr SOCKS5 proxy address (for compatibility, not used in unified mode)
     * @param socksPort SOCKS5 proxy port (for compatibility, not used in unified mode)
     * @param ipv4Addr VPN IPv4 address
     * @param ipv4Gateway VPN gateway address
     * @param dnsAddr DNS server address
     * @param xrayConfigJson Complete Xray configuration JSON
     * @return true if successful, false otherwise
     */
    public native boolean nativeStart(
        int tunFd,
        int mtu,
        String socksAddr,
        int socksPort,
        String ipv4Addr,
        String ipv4Gateway,
        String dnsAddr,
        String xrayConfigJson
    );

    /**
     * Stop SuperRay (closes TUN and stops Xray)
     */
    public native void nativeStop();

    /**
     * Get traffic statistics (TUN level)
     * @return JSON string with bytesReceived and bytesSent
     */
    public native String nativeGetStats();

    /**
     * Get Xray-level statistics (uplink/downlink bytes and rate)
     * @return JSON string with stats data
     */
    public native String nativeGetXrayStats();

    /**
     * Get current speed (uplink/downlink rate in bytes/sec)
     * @return JSON string with uplink_rate and downlink_rate
     */
    public native String nativeGetCurrentSpeed();

    /**
     * Check if SuperRay is running
     * @return true if running
     */
    public native boolean nativeIsRunning();

    /**
     * Get SuperRay library version
     * @return version string
     */
    public native String nativeGetVersion();

    /**
     * Get Xray-core version
     * @return version string
     */
    public native String nativeGetXrayVersion();

    // ========================================================================
    // Public Java Methods
    // ========================================================================

    /**
     * Start VPN with SuperRay
     *
     * This method:
     * 1. Takes the TUN FD from VpnService
     * 2. Starts Xray with provided config
     * 3. Creates TUN device processing via SuperRay
     */
    public boolean start(int tunFd, int mtu, String ipv4Addr, String ipv4Gateway,
                        String dnsAddr, String xrayConfigJson) {
        if (!libraryLoaded) {
            Log.e(TAG, "Cannot start: native library not loaded");
            return false;
        }

        // socksAddr and socksPort are kept for compatibility but not used
        // In unified mode, SuperRay handles everything internally
        return nativeStart(tunFd, mtu, "127.0.0.1", 10808,
                          ipv4Addr, ipv4Gateway, dnsAddr, xrayConfigJson);
    }

    /**
     * Stop VPN
     */
    public void stop() {
        if (!libraryLoaded) {
            Log.w(TAG, "Cannot stop: native library not loaded");
            return;
        }
        nativeStop();
    }

    /**
     * Check if running
     */
    public boolean isRunning() {
        if (!libraryLoaded) {
            return false;
        }
        return nativeIsRunning();
    }

    /**
     * Get traffic statistics
     * @return TrafficStats object with bytes received/sent
     */
    public TrafficStats getStats() {
        if (!libraryLoaded) {
            return new TrafficStats(0, 0);
        }

        String json = nativeGetStats();
        return TrafficStats.fromJson(json);
    }

    /**
     * Get Xray statistics with speed
     * @return XrayStats object with uplink/downlink bytes and rate
     */
    public XrayStats getXrayStats() {
        if (!libraryLoaded) {
            return new XrayStats();
        }

        String json = nativeGetXrayStats();
        return XrayStats.fromJson(json);
    }

    /**
     * Get current speed
     * @return SpeedStats object with uplink/downlink rate
     */
    public SpeedStats getCurrentSpeed() {
        if (!libraryLoaded) {
            return new SpeedStats(0, 0);
        }

        String json = nativeGetCurrentSpeed();
        return SpeedStats.fromJson(json);
    }

    /**
     * Get SuperRay version
     */
    public String getVersion() {
        if (!libraryLoaded) {
            return "unknown";
        }
        return nativeGetVersion();
    }

    /**
     * Get Xray-core version
     */
    public String getXrayVersion() {
        if (!libraryLoaded) {
            return "unknown";
        }
        return nativeGetXrayVersion();
    }

    // ========================================================================
    // Helper Classes
    // ========================================================================

    /**
     * Traffic statistics (TUN level)
     */
    public static class TrafficStats {
        public long bytesReceived;
        public long bytesSent;

        public TrafficStats(long received, long sent) {
            this.bytesReceived = received;
            this.bytesSent = sent;
        }

        public static TrafficStats fromJson(String json) {
            try {
                // Simple JSON parsing
                long received = 0, sent = 0;
                if (json != null && json.contains("bytesReceived")) {
                    int start = json.indexOf("bytesReceived") + 15;
                    int end = json.indexOf(",", start);
                    if (end < 0) end = json.indexOf("}", start);
                    received = Long.parseLong(json.substring(start, end).trim());
                }
                if (json != null && json.contains("bytesSent")) {
                    int start = json.indexOf("bytesSent") + 11;
                    int end = json.indexOf(",", start);
                    if (end < 0) end = json.indexOf("}", start);
                    sent = Long.parseLong(json.substring(start, end).trim());
                }
                return new TrafficStats(received, sent);
            } catch (Exception e) {
                Log.w(TAG, "Failed to parse traffic stats: " + e.getMessage());
                return new TrafficStats(0, 0);
            }
        }
    }

    /**
     * Xray statistics with speed
     */
    public static class XrayStats {
        public long uplink;
        public long downlink;
        public double uplinkRate;
        public double downlinkRate;
        public boolean success;

        public XrayStats() {
            this.success = false;
        }

        public static XrayStats fromJson(String json) {
            XrayStats stats = new XrayStats();
            try {
                if (json != null && json.contains("\"success\":true")) {
                    stats.success = true;
                    // Parse data object
                    if (json.contains("\"uplink\":")) {
                        int start = json.indexOf("\"uplink\":") + 9;
                        int end = json.indexOf(",", start);
                        if (end < 0) end = json.indexOf("}", start);
                        stats.uplink = Long.parseLong(json.substring(start, end).trim());
                    }
                    if (json.contains("\"downlink\":")) {
                        int start = json.indexOf("\"downlink\":") + 11;
                        int end = json.indexOf(",", start);
                        if (end < 0) end = json.indexOf("}", start);
                        stats.downlink = Long.parseLong(json.substring(start, end).trim());
                    }
                    if (json.contains("\"uplinkRate\":")) {
                        int start = json.indexOf("\"uplinkRate\":") + 13;
                        int end = json.indexOf(",", start);
                        if (end < 0) end = json.indexOf("}", start);
                        stats.uplinkRate = Double.parseDouble(json.substring(start, end).trim());
                    }
                    if (json.contains("\"downlinkRate\":")) {
                        int start = json.indexOf("\"downlinkRate\":") + 15;
                        int end = json.indexOf(",", start);
                        if (end < 0) end = json.indexOf("}", start);
                        stats.downlinkRate = Double.parseDouble(json.substring(start, end).trim());
                    }
                }
            } catch (Exception e) {
                Log.w(TAG, "Failed to parse Xray stats: " + e.getMessage());
            }
            return stats;
        }
    }

    /**
     * Speed statistics
     */
    public static class SpeedStats {
        public double uplinkRate;
        public double downlinkRate;

        public SpeedStats(double uplink, double downlink) {
            this.uplinkRate = uplink;
            this.downlinkRate = downlink;
        }

        public static SpeedStats fromJson(String json) {
            try {
                double uplink = 0, downlink = 0;
                if (json != null && json.contains("uplink_rate")) {
                    int start = json.indexOf("uplink_rate") + 13;
                    int end = json.indexOf(",", start);
                    if (end < 0) end = json.indexOf("}", start);
                    uplink = Double.parseDouble(json.substring(start, end).trim());
                }
                if (json != null && json.contains("downlink_rate")) {
                    int start = json.indexOf("downlink_rate") + 15;
                    int end = json.indexOf(",", start);
                    if (end < 0) end = json.indexOf("}", start);
                    downlink = Double.parseDouble(json.substring(start, end).trim());
                }
                return new SpeedStats(uplink, downlink);
            } catch (Exception e) {
                Log.w(TAG, "Failed to parse speed stats: " + e.getMessage());
                return new SpeedStats(0, 0);
            }
        }
    }
}
