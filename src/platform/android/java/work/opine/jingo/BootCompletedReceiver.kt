/**
 * @file BootCompletedReceiver.kt
 * @brief 开机自启动广播接收器
 * @details 处理系统开机事件，自动启动VPN
 *
 * @author JinGo VPN Team
 * @date 2025
 */

package work.opine.jingo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * 开机自启动接收器
 *
 * 当系统启动完成时，如果用户设置了开机自启动，则自动连接VPN
 */
class BootCompletedReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootCompletedReceiver"
        private const val PREF_NAME = "jingo_vpn_prefs"
        private const val KEY_AUTO_START = "auto_start_on_boot"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {

            Log.d(TAG, "Boot completed")

            // 检查是否启用开机自启动
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            val autoStart = prefs.getBoolean(KEY_AUTO_START, false)

            if (!autoStart) {
                Log.d(TAG, "Auto-start disabled")
                return
            }

            // 获取保存的配置
            val serverConfig = prefs.getString("last_server_config", null)
            val xrayConfig = prefs.getString("last_xray_config", null)

            if (serverConfig == null || xrayConfig == null) {
                Log.w(TAG, "No saved configuration, cannot auto-start")
                return
            }

            // 启动VPN服务
            try {
                Log.i(TAG, "Starting VPN automatically")
                val serviceIntent = Intent(context, JinGoVPNService::class.java).apply {
                    action = JinGoVPNService.ACTION_START_VPN
                    putExtra("serverConfig", serverConfig)
                    putExtra("xrayConfig", xrayConfig)
                }

                context.startForegroundService(serviceIntent)
                Log.i(TAG, "VPN service started")

            } catch (e: Exception) {
                Log.e(TAG, "Failed to start VPN service", e)
            }
        }
    }
}
