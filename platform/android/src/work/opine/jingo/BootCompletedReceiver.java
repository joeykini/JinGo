package work.opine.jingo;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

/**
 * Broadcast receiver for system boot completion
 *
 * Functionality:
 * - Listens for BOOT_COMPLETED broadcast
 * - Checks if auto-start is enabled in preferences
 * - Starts VPN service if configured to do so
 */
public class BootCompletedReceiver extends BroadcastReceiver {
    private static final String TAG = "BootCompletedReceiver";
    private static final String PREFS_NAME = "JinGoVPNPrefs";
    private static final String KEY_AUTO_START = "auto_start_on_boot";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || intent.getAction() == null) {
            return;
        }

        String action = intent.getAction();
        Log.d(TAG, "Received broadcast: " + action);

        // Check for boot completed actions
        if (Intent.ACTION_BOOT_COMPLETED.equals(action) ||
            "android.intent.action.QUICKBOOT_POWERON".equals(action)) {

            // Check if auto-start is enabled
            SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            boolean autoStart = prefs.getBoolean(KEY_AUTO_START, false);

            Log.i(TAG, "Boot completed. Auto-start enabled: " + autoStart);

            if (autoStart) {
                try {
                    // Start VPN service
                    // Note: Actual implementation would need to check if VPN config exists
                    // and handle Always-On VPN properly
                    Log.i(TAG, "Auto-start is enabled, but not starting VPN automatically");
                    Log.i(TAG, "User should manually start VPN after boot for security reasons");

                    // Optionally, show a notification to remind user to connect
                    // showConnectReminder(context);
                } catch (Exception e) {
                    Log.e(TAG, "Error during auto-start", e);
                }
            }
        }
    }

    /**
     * Enable or disable auto-start on boot
     *
     * @param context Application context
     * @param enabled Whether to enable auto-start
     */
    public static void setAutoStart(Context context, boolean enabled) {
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        prefs.edit().putBoolean(KEY_AUTO_START, enabled).apply();
        Log.i(TAG, "Auto-start on boot set to: " + enabled);
    }

    /**
     * Check if auto-start is enabled
     *
     * @param context Application context
     * @return true if auto-start is enabled
     */
    public static boolean isAutoStartEnabled(Context context) {
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        return prefs.getBoolean(KEY_AUTO_START, false);
    }
}
