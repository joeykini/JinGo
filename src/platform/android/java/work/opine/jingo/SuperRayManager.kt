/**
 * @file SuperRayManager.kt
 * @brief SuperRay管理器
 * @details 管理SuperRay TUN模式，将TUN设备的IP包通过Xray代理转发
 *
 * @author JinGo VPN Team
 * @date 2025
 *
 * @optimization v2.1 优化内容：
 * - 统一日志格式为【ANDROID TUN】
 */

package work.opine.jingo

import android.content.Context
import android.net.VpnService
import android.util.Log
import org.json.JSONObject

/**
 * SuperRay管理器
 *
 * 功能：
 * - 启动和停止SuperRay TUN模式
 * - 配置SuperRay参数
 * - 获取流量统计信息
 * - Socket保护（绕过VPN直接访问网络）
 *
 * SuperRay是集成了Xray-core和TUN处理的统一库
 */
class SuperRayManager(private val context: Context) {

    companion object {
        private const val TAG = "SuperRayManager"
        private const val LOG_PREFIX = "【ANDROID TUN】"

        init {
            try {
                // 加载SuperRay native库
                System.loadLibrary("superray")
                Log.i(TAG, "$LOG_PREFIX SuperRay library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "$LOG_PREFIX ERROR: Failed to load SuperRay library", e)
            }
        }
    }

    // 运行状态
    @Volatile
    private var isRunning = false

    // VpnService 引用
    private var vpnService: VpnService? = null

    /**
     * 设置 VpnService 并初始化 socket 保护
     * 必须在 start() 之前调用
     *
     * @param service VpnService 实例
     * @return true 成功，false 失败
     */
    fun setVpnService(service: VpnService): Boolean {
        Log.i(TAG, "$LOG_PREFIX Setting VpnService for socket protection...")
        return try {
            vpnService = service
            val result = nativeSetVpnService(service)
            if (result) {
                Log.i(TAG, "$LOG_PREFIX SUCCESS: VpnService set, socket protection enabled")
            } else {
                Log.e(TAG, "$LOG_PREFIX ERROR: Failed to set VpnService")
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "$LOG_PREFIX ERROR: Exception setting VpnService", e)
            false
        }
    }

    /**
     * 启动SuperRay TUN模式
     *
     * @param tunFd TUN设备文件描述符
     * @param mtu MTU大小
     * @param socksAddr SOCKS5代理地址
     * @param socksPort SOCKS5代理端口
     * @param ipv4Addr TUN设备IPv4地址
     * @param ipv4Gateway TUN网关地址
     * @param dnsAddr DNS服务器地址
     * @param xrayConfigJson Xray配置JSON（可选，如果Xray已经启动则传null）
     * @return 成功返回true
     */
    fun start(
        tunFd: Int,
        mtu: Int,
        socksAddr: String,
        socksPort: Int,
        ipv4Addr: String,
        ipv4Gateway: String,
        dnsAddr: String,
        xrayConfigJson: String? = null
    ): Boolean {
        if (isRunning) {
            Log.w(TAG, "$LOG_PREFIX SuperRay already running")
            return true
        }

        Log.i(TAG, "$LOG_PREFIX Starting SuperRay...")
        Log.d(TAG, "$LOG_PREFIX   TUN FD: $tunFd")
        Log.d(TAG, "$LOG_PREFIX   MTU: $mtu")
        Log.d(TAG, "$LOG_PREFIX   SOCKS: $socksAddr:$socksPort")
        Log.d(TAG, "$LOG_PREFIX   IPv4: $ipv4Addr")
        Log.d(TAG, "$LOG_PREFIX   Gateway: $ipv4Gateway")
        Log.d(TAG, "$LOG_PREFIX   DNS: $dnsAddr")

        return try {
            val result = nativeStart(
                tunFd, mtu, socksAddr, socksPort,
                ipv4Addr, ipv4Gateway, dnsAddr,
                xrayConfigJson
            )
            if (result) {
                isRunning = true
                Log.i(TAG, "$LOG_PREFIX SUCCESS: SuperRay started")
            } else {
                Log.e(TAG, "$LOG_PREFIX ERROR: Failed to start SuperRay")
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "$LOG_PREFIX ERROR: Exception starting SuperRay", e)
            false
        }
    }

    /**
     * 停止SuperRay
     */
    fun stop() {
        if (!isRunning) {
            Log.d(TAG, "$LOG_PREFIX SuperRay not running")
            return
        }

        Log.i(TAG, "$LOG_PREFIX Stopping SuperRay...")
        try {
            nativeStop()
            isRunning = false
            Log.i(TAG, "$LOG_PREFIX SUCCESS: SuperRay stopped")
        } catch (e: Exception) {
            Log.e(TAG, "$LOG_PREFIX ERROR: Exception stopping SuperRay", e)
        }
    }

    /**
     * 检查是否正在运行
     */
    fun isRunning(): Boolean {
        return try {
            nativeIsRunning()
        } catch (e: Exception) {
            isRunning
        }
    }

    /**
     * 获取流量统计信息
     *
     * @return Map包含bytesReceived, bytesSent等字段
     */
    fun getStatistics(): Map<String, Any> {
        return try {
            val jsonStr = nativeGetStats()
            val json = JSONObject(jsonStr)
            mapOf(
                "bytesReceived" to json.optLong("bytesReceived", 0),
                "bytesSent" to json.optLong("bytesSent", 0),
                "upload" to json.optLong("upload", 0),
                "download" to json.optLong("download", 0)
            )
        } catch (e: Exception) {
            Log.w(TAG, "$LOG_PREFIX WARNING: Failed to get statistics", e)
            mapOf(
                "bytesReceived" to 0L,
                "bytesSent" to 0L
            )
        }
    }

    /**
     * 获取Xray核心统计信息（使用SuperRay直接API，无需HTTP/gRPC查询）
     *
     * @return JSON字符串包含uplink, downlink等统计
     */
    fun getXrayStats(): String {
        return try {
            nativeGetXrayStats()
        } catch (e: Exception) {
            Log.w(TAG, "$LOG_PREFIX WARNING: Failed to get Xray stats", e)
            "{\"success\":false,\"error\":\"${e.message}\"}"
        }
    }

    /**
     * 获取当前传输速度（使用SuperRay直接API）
     *
     * @return Map包含uplink_rate, downlink_rate等速度信息
     */
    fun getCurrentSpeed(): Map<String, Double> {
        return try {
            val jsonStr = nativeGetCurrentSpeed()
            val json = JSONObject(jsonStr)
            mapOf(
                "uplink_rate" to json.optDouble("uplink_rate", 0.0),
                "downlink_rate" to json.optDouble("downlink_rate", 0.0),
                "uplink_kbps" to json.optDouble("uplink_kbps", 0.0),
                "downlink_kbps" to json.optDouble("downlink_kbps", 0.0),
                "uplink_mbps" to json.optDouble("uplink_mbps", 0.0),
                "downlink_mbps" to json.optDouble("downlink_mbps", 0.0)
            )
        } catch (e: Exception) {
            Log.w(TAG, "$LOG_PREFIX WARNING: Failed to get current speed", e)
            mapOf(
                "uplink_rate" to 0.0,
                "downlink_rate" to 0.0
            )
        }
    }

    /**
     * 获取SuperRay版本
     */
    fun getVersion(): String {
        return try {
            val version = nativeGetVersion()
            Log.d(TAG, "$LOG_PREFIX SuperRay version: $version")
            version
        } catch (e: Exception) {
            "unknown"
        }
    }

    /**
     * 获取Xray版本
     */
    fun getXrayVersion(): String {
        return try {
            val version = nativeGetXrayVersion()
            Log.d(TAG, "$LOG_PREFIX Xray version: $version")
            version
        } catch (e: Exception) {
            "unknown"
        }
    }

    // ========================================================================
    // Native方法声明
    // ========================================================================

    /**
     * 设置 VpnService 引用，用于 socket 保护
     * 必须在 nativeStart 之前调用
     */
    private external fun nativeSetVpnService(vpnService: VpnService): Boolean

    private external fun nativeStart(
        tunFd: Int,
        mtu: Int,
        socksAddr: String,
        socksPort: Int,
        ipv4Addr: String,
        ipv4Gateway: String,
        dnsAddr: String,
        xrayConfigJson: String?
    ): Boolean

    private external fun nativeStop()

    private external fun nativeGetStats(): String

    private external fun nativeGetXrayStats(): String

    private external fun nativeGetCurrentSpeed(): String

    private external fun nativeIsRunning(): Boolean

    private external fun nativeGetVersion(): String

    private external fun nativeGetXrayVersion(): String
}
