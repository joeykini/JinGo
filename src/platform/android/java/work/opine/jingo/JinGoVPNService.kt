/**
 * @file JinGoVPNService.kt
 * @brief JinGo VPN的Android VPNService实现
 * @details 实现Android VPNService，处理VPN连接和数据包转发
 *
 * @author JinGo VPN Team
 * @date 2025
 * @copyright Copyright © 2025 JinGo Team. All rights reserved.
 *
 * @optimization v2.1 优化内容：
 * - 统一日志格式为【ANDROID TUN】
 * - 添加连接重试机制（最多2次重试）
 * - 添加底层网络设置（setUnderlyingNetworks）
 * - 添加Socket保护方法（protectSocketFd）
 * - 添加默认网关保存和代理服务器路由排除
 * - 添加连接状态验证和等待逻辑
 * - 优化网络切换处理
 * - 添加allowBypass和优化路由策略
 */

package work.opine.jingo

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.RouteInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.InetAddress
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * JinGo VPN服务
 *
 * 负责：
 * - VPN生命周期管理
 * - TUN接口创建和配置
 * - SuperRay启动和管理（包含Xray-core和TUN处理）
 * - 网络状态监控
 */
class JinGoVPNService : VpnService() {

    companion object {
        private const val TAG = "JinGoVPNService"
        private const val LOG_PREFIX = "【ANDROID TUN】"

        // 服务动作
        const val ACTION_START_VPN = "work.opine.jingo.START_VPN"
        const val ACTION_STOP_VPN = "work.opine.jingo.STOP_VPN"
        const val ACTION_GET_STATUS = "work.opine.jingo.GET_STATUS"

        // VPN配置 - IPv4
        private const val VPN_ADDRESS = "172.19.0.1"
        private const val VPN_PREFIX_LENGTH = 24
        private const val VPN_ROUTE = "0.0.0.0"
        private const val VPN_DNS = "1.1.1.1"
        private const val VPN_DNS_BACKUP = "8.8.8.8"
        private const val VPN_MTU = 1500
        private const val SOCKS5_PORT = 10808  // 与 ConfigManager::Defaults::LocalSocksPort 保持一致

        // VPN配置 - IPv6
        private const val VPN_ADDRESS_V6 = "fd00::1"
        private const val VPN_PREFIX_LENGTH_V6 = 64
        private const val VPN_DNS_V6 = "2606:4700:4700::1111"       // Cloudflare IPv6 DNS
        private const val VPN_DNS_V6_BACKUP = "2001:4860:4860::8888" // Google IPv6 DNS

        // 通知
        private const val NOTIFICATION_CHANNEL_ID = "jingo_vpn_channel"
        private const val NOTIFICATION_ID = 1

        // 重试配置
        private const val MAX_RETRIES = 2
        private const val RETRY_DELAY_MS = 500L
        private const val CONNECTION_VERIFY_TIMEOUT_MS = 5000L

        // 分应用代理模式
        const val PER_APP_DISABLED = 0      // 禁用分应用代理，所有应用走VPN
        const val PER_APP_ALLOW_LIST = 1    // 仅允许列表中的应用走VPN
        const val PER_APP_BLOCK_LIST = 2    // 排除列表中的应用，其他走VPN

        // Intent 额外参数
        const val EXTRA_PER_APP_PROXY_MODE = "perAppProxyMode"
        const val EXTRA_PER_APP_PROXY_LIST = "perAppProxyList"
        const val EXTRA_PROXY_SERVER_HOST = "proxyServerHost"
        const val EXTRA_PROXY_SERVER_IP = "proxyServerIP"
        const val EXTRA_ALL_SERVER_IPS = "allServerIPs"  // 所有服务器IP列表（用于路由排除）

        // 单例引用（供JNI调用）
        @Volatile
        private var instance: JinGoVPNService? = null

        /**
         * 获取服务实例（供JNI层调用）
         */
        @JvmStatic
        fun getInstance(): JinGoVPNService? = instance
    }

    // VPN接口
    private var vpnInterface: ParcelFileDescriptor? = null

    // SuperRay管理器（集成Xray-core和TUN处理）
    private var superRayManager: SuperRayManager? = null

    // 状态
    private val isRunning = AtomicBoolean(false)
    private var startTime: Long = 0

    // 统计
    private var bytesReceived: Long = 0
    private var bytesSent: Long = 0

    // 分应用代理设置
    private var perAppProxyMode: Int = PER_APP_DISABLED
    private var perAppProxyList: List<String> = emptyList()

    // 代理服务器信息（用于路由排除）
    private var proxyServerHost: String? = null
    private var proxyServerIP: String? = null
    private var allServerIPs: List<String> = emptyList()  // 所有服务器IP（用于路由排除）

    // 默认网关（VPN启动前保存）
    private var savedDefaultGateway: String? = null

    // 底层网络（用于socket保护）
    private var underlyingNetwork: Network? = null

    // 网络监控
    private val connectivityManager by lazy {
        getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    }

    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            super.onAvailable(network)
            Log.d(TAG, "$LOG_PREFIX Network available: $network")
            handleNetworkChange(network)
        }

        override fun onLost(network: Network) {
            super.onLost(network)
            Log.w(TAG, "$LOG_PREFIX Network lost: $network")
            handleNetworkLost()
        }

        override fun onCapabilitiesChanged(
            network: Network,
            networkCapabilities: NetworkCapabilities
        ) {
            super.onCapabilitiesChanged(network, networkCapabilities)

            val hasInternet = networkCapabilities.hasCapability(
                NetworkCapabilities.NET_CAPABILITY_INTERNET
            )
            val isWifi = networkCapabilities.hasTransport(
                NetworkCapabilities.TRANSPORT_WIFI
            )
            val isCellular = networkCapabilities.hasTransport(
                NetworkCapabilities.TRANSPORT_CELLULAR
            )

            Log.d(TAG, "$LOG_PREFIX Network capabilities - Internet: $hasInternet, WiFi: $isWifi, Cellular: $isCellular")
        }
    }

    // ============================================================================
    // MARK: - 生命周期
    // ============================================================================

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.i(TAG, "$LOG_PREFIX ======== SERVICE CREATED ========")

        // 注册网络监听
        try {
            connectivityManager.registerDefaultNetworkCallback(networkCallback)
            Log.d(TAG, "$LOG_PREFIX Network callback registered")
        } catch (e: Exception) {
            Log.e(TAG, "$LOG_PREFIX Failed to register network callback", e)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "$LOG_PREFIX onStartCommand: ${intent?.action}")

        when (intent?.action) {
            ACTION_START_VPN -> {
                val serverConfig = intent.getStringExtra("serverConfig")
                val xrayConfig = intent.getStringExtra("xrayConfig")

                // 获取分应用代理设置
                perAppProxyMode = intent.getIntExtra(EXTRA_PER_APP_PROXY_MODE, PER_APP_DISABLED)
                perAppProxyList = intent.getStringArrayListExtra(EXTRA_PER_APP_PROXY_LIST) ?: emptyList()

                // 获取代理服务器信息（用于路由排除）
                proxyServerHost = intent.getStringExtra(EXTRA_PROXY_SERVER_HOST)
                proxyServerIP = intent.getStringExtra(EXTRA_PROXY_SERVER_IP)
                allServerIPs = intent.getStringArrayListExtra(EXTRA_ALL_SERVER_IPS) ?: emptyList()

                Log.d(TAG, "$LOG_PREFIX Per-app proxy mode: $perAppProxyMode, apps: ${perAppProxyList.size}")
                Log.d(TAG, "$LOG_PREFIX Proxy server - Host: $proxyServerHost, IP: $proxyServerIP")
                Log.d(TAG, "$LOG_PREFIX All server IPs for route exclusion: ${allServerIPs.size}")

                if (serverConfig != null && xrayConfig != null) {
                    startVPNWithRetry(serverConfig, xrayConfig)
                } else {
                    Log.e(TAG, "$LOG_PREFIX ERROR: Missing configuration")
                    stopSelf()
                }
            }
            ACTION_STOP_VPN -> {
                stopVPN()
            }
            ACTION_GET_STATUS -> {
                broadcastStatus()
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        Log.i(TAG, "$LOG_PREFIX ======== SERVICE DESTROYING ========")

        // 停止VPN
        stopVPN()

        // 注销网络监听
        try {
            connectivityManager.unregisterNetworkCallback(networkCallback)
        } catch (e: Exception) {
            Log.w(TAG, "$LOG_PREFIX Failed to unregister network callback", e)
        }

        instance = null
        super.onDestroy()
        Log.i(TAG, "$LOG_PREFIX Service destroyed")
    }

    override fun onRevoke() {
        Log.w(TAG, "$LOG_PREFIX VPN permission revoked by user")
        stopVPN()
        super.onRevoke()
    }

    // ============================================================================
    // MARK: - VPN管理
    // ============================================================================

    /**
     * 启动VPN（带重试机制）
     */
    private fun startVPNWithRetry(serverConfig: String, xrayConfig: String) {
        Log.i(TAG, "$LOG_PREFIX ======== STARTING VPN ========")

        var retryCount = 0
        var lastError: Exception? = null

        while (retryCount <= MAX_RETRIES) {
            if (retryCount > 0) {
                Log.w(TAG, "$LOG_PREFIX RETRY: Attempt ${retryCount}/$MAX_RETRIES")
                Thread.sleep(RETRY_DELAY_MS)
            }

            try {
                if (startVPNInternal(serverConfig, xrayConfig)) {
                    Log.i(TAG, "$LOG_PREFIX SUCCESS: VPN started successfully")
                    return
                }
            } catch (e: Exception) {
                lastError = e
                Log.e(TAG, "$LOG_PREFIX ERROR: VPN start failed - ${e.message}")
            }

            retryCount++
        }

        Log.e(TAG, "$LOG_PREFIX FAILED: VPN start failed after $MAX_RETRIES retries", lastError)
        broadcastStatus()
    }

    /**
     * 启动VPN内部实现
     */
    private fun startVPNInternal(serverConfig: String, xrayConfig: String): Boolean {
        if (isRunning.get()) {
            Log.w(TAG, "$LOG_PREFIX VPN already running")
            return true
        }

        // ============================================================================
        // Step 1: 保存默认网关（必须在VPN启动前）
        // ============================================================================
        Log.d(TAG, "$LOG_PREFIX Step 1: Saving default gateway...")
        savedDefaultGateway = getDefaultGateway()
        if (savedDefaultGateway != null) {
            Log.i(TAG, "$LOG_PREFIX Default gateway saved: $savedDefaultGateway")
        } else {
            Log.w(TAG, "$LOG_PREFIX WARNING: Could not get default gateway")
        }

        // ============================================================================
        // Step 2: 保存底层网络（用于socket保护）
        // ============================================================================
        Log.d(TAG, "$LOG_PREFIX Step 2: Saving underlying network...")
        underlyingNetwork = connectivityManager.activeNetwork
        if (underlyingNetwork != null) {
            Log.i(TAG, "$LOG_PREFIX Underlying network saved: $underlyingNetwork")
        } else {
            Log.w(TAG, "$LOG_PREFIX WARNING: No active network")
        }

        // ============================================================================
        // Step 3: 建立VPN接口
        // ============================================================================
        Log.d(TAG, "$LOG_PREFIX Step 3: Establishing VPN interface...")
        vpnInterface = establishVPN()
        if (vpnInterface == null) {
            Log.e(TAG, "$LOG_PREFIX ERROR: Failed to establish VPN interface")
            return false
        }
        Log.i(TAG, "$LOG_PREFIX VPN interface established, FD: ${vpnInterface!!.fd}")

        // ============================================================================
        // Step 4: 设置底层网络
        // ============================================================================
        Log.d(TAG, "$LOG_PREFIX Step 4: Setting underlying networks...")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            try {
                if (underlyingNetwork != null) {
                    setUnderlyingNetworks(arrayOf(underlyingNetwork))
                    Log.i(TAG, "$LOG_PREFIX Underlying network set successfully")
                } else {
                    setUnderlyingNetworks(null)
                    Log.d(TAG, "$LOG_PREFIX Using system default network")
                }
            } catch (e: Exception) {
                Log.w(TAG, "$LOG_PREFIX WARNING: Failed to set underlying networks", e)
            }
        }

        // ============================================================================
        // Step 5: 启动SuperRay
        // ============================================================================
        Log.d(TAG, "$LOG_PREFIX Step 5: Starting SuperRay...")
        val tunFd = vpnInterface!!.fd
        superRayManager = SuperRayManager(this)

        // 关键：设置 VpnService 引用，用于 socket 保护
        // 这样 SuperRay 在创建到代理服务器的连接时可以调用 VpnService.protect()
        // 防止代理流量被路由回 VPN 形成死循环
        Log.d(TAG, "$LOG_PREFIX Setting VpnService for socket protection...")
        if (!superRayManager!!.setVpnService(this)) {
            Log.e(TAG, "$LOG_PREFIX ERROR: Failed to set VpnService for socket protection")
            cleanupOnFailure()
            return false
        }
        Log.i(TAG, "$LOG_PREFIX Socket protection enabled")

        if (!superRayManager!!.start(
                tunFd = tunFd,
                mtu = VPN_MTU,
                socksAddr = "127.0.0.1",
                socksPort = SOCKS5_PORT,
                ipv4Addr = VPN_ADDRESS,
                ipv4Gateway = "172.19.0.2",
                dnsAddr = VPN_DNS,
                xrayConfigJson = xrayConfig
            )) {
            Log.e(TAG, "$LOG_PREFIX ERROR: Failed to start SuperRay")
            cleanupOnFailure()
            return false
        }
        Log.i(TAG, "$LOG_PREFIX SuperRay started")

        // ============================================================================
        // Step 6: 验证连接
        // ============================================================================
        Log.d(TAG, "$LOG_PREFIX Step 6: Verifying connection...")
        if (!verifyConnection()) {
            Log.e(TAG, "$LOG_PREFIX ERROR: Connection verification failed")
            cleanupOnFailure()
            return false
        }
        Log.i(TAG, "$LOG_PREFIX Connection verified")

        // ============================================================================
        // Step 7: 设置代理服务器路由排除
        // ============================================================================
        Log.d(TAG, "$LOG_PREFIX Step 7: Setting up proxy route exclusion...")
        setupProxyRouteExclusion()

        // ============================================================================
        // Step 8: 启动前台服务
        // ============================================================================
        Log.d(TAG, "$LOG_PREFIX Step 8: Starting foreground service...")
        startForegroundWithType()

        // ============================================================================
        // Step 9: 更新状态
        // ============================================================================
        isRunning.set(true)
        startTime = System.currentTimeMillis()
        bytesReceived = 0
        bytesSent = 0

        Log.i(TAG, "$LOG_PREFIX ======== VPN STARTED SUCCESSFULLY ========")
        broadcastStatus()
        return true
    }

    /**
     * 停止VPN
     */
    private fun stopVPN() {
        if (!isRunning.get()) {
            Log.d(TAG, "$LOG_PREFIX VPN not running")
            return
        }

        Log.i(TAG, "$LOG_PREFIX ======== STOPPING VPN ========")

        // Step 1: 更新状态（先设置，防止重复调用）
        isRunning.set(false)

        // Step 2: 停止SuperRay（会同时停止Xray和TUN）
        Log.d(TAG, "$LOG_PREFIX Step 1: Stopping SuperRay...")
        try {
            superRayManager?.stop()
        } catch (e: Exception) {
            Log.e(TAG, "$LOG_PREFIX ERROR stopping SuperRay", e)
        }
        superRayManager = null

        // Step 3: 关闭VPN接口
        Log.d(TAG, "$LOG_PREFIX Step 2: Closing VPN interface...")
        try {
            vpnInterface?.close()
        } catch (e: Exception) {
            Log.e(TAG, "$LOG_PREFIX ERROR closing VPN interface", e)
        }
        vpnInterface = null

        // Step 4: 清理路由（如果添加过）
        Log.d(TAG, "$LOG_PREFIX Step 3: Cleaning up routes...")
        cleanupProxyRoutes()

        // Step 5: 停止前台服务
        Log.d(TAG, "$LOG_PREFIX Step 4: Stopping foreground service...")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }

        // Step 6: 清理状态
        savedDefaultGateway = null
        underlyingNetwork = null

        Log.i(TAG, "$LOG_PREFIX ======== VPN STOPPED ========")
        broadcastStatus()

        stopSelf()
    }

    /**
     * 失败时清理资源
     */
    private fun cleanupOnFailure() {
        Log.d(TAG, "$LOG_PREFIX Cleaning up after failure...")
        try {
            superRayManager?.stop()
        } catch (e: Exception) { }
        superRayManager = null

        try {
            vpnInterface?.close()
        } catch (e: Exception) { }
        vpnInterface = null
    }

    /**
     * 验证连接是否成功
     */
    private fun verifyConnection(): Boolean {
        // 检查SuperRay是否正在运行
        val startTime = System.currentTimeMillis()
        while (System.currentTimeMillis() - startTime < CONNECTION_VERIFY_TIMEOUT_MS) {
            if (superRayManager?.isRunning() == true) {
                return true
            }
            Thread.sleep(100)
        }
        return false
    }

    /**
     * 启动前台服务（兼容不同Android版本）
     */
    private fun startForegroundWithType() {
        val notification = createNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+ (API 34+)
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10-13 (API 29-33)
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    /**
     * 建立VPN接口
     */
    private fun establishVPN(): ParcelFileDescriptor? {
        try {
            val builder = Builder()

            // 基本配置 - IPv4
            builder.setSession("JinGo VPN")
                .addAddress(VPN_ADDRESS, VPN_PREFIX_LENGTH)
                .addDnsServer(VPN_DNS)
                .addDnsServer(VPN_DNS_BACKUP)
                .setMtu(VPN_MTU)
                .setBlocking(false)

            // IPv6配置
            try {
                builder.addAddress(VPN_ADDRESS_V6, VPN_PREFIX_LENGTH_V6)
                builder.addDnsServer(VPN_DNS_V6)
                builder.addDnsServer(VPN_DNS_V6_BACKUP)
                Log.d(TAG, "$LOG_PREFIX IPv6 enabled: $VPN_ADDRESS_V6/$VPN_PREFIX_LENGTH_V6")
            } catch (e: Exception) {
                Log.w(TAG, "$LOG_PREFIX WARNING: Failed to add IPv6 config: ${e.message}")
            }

            // 允许绕过VPN（对于socket保护很重要）
            builder.allowBypass()
            Log.d(TAG, "$LOG_PREFIX allowBypass() enabled")

            // 路由配置：使用分割路由策略避免代理服务器循环
            if (proxyServerIP != null && proxyServerIP!!.isNotEmpty()) {
                // 使用 0.0.0.0/1 + 128.0.0.0/1 覆盖所有IP
                // 这样可以让更具体的路由（如代理服务器的/32路由）优先
                builder.addRoute("0.0.0.0", 1)
                builder.addRoute("128.0.0.0", 1)
                Log.d(TAG, "$LOG_PREFIX Using split route strategy (0.0.0.0/1 + 128.0.0.0/1)")
            } else {
                // 没有代理服务器IP时使用默认路由
                builder.addRoute(VPN_ROUTE, 0)
                Log.d(TAG, "$LOG_PREFIX Using default route (0.0.0.0/0)")
            }

            // 关键：添加DNS服务器的显式路由，确保DNS请求通过VPN
            // 这对于防止DNS泄露非常重要
            try {
                // IPv4 DNS服务器路由
                builder.addRoute("1.1.1.1", 32)    // Cloudflare DNS
                builder.addRoute("1.0.0.1", 32)    // Cloudflare DNS backup
                builder.addRoute("8.8.8.8", 32)    // Google DNS
                builder.addRoute("8.8.4.4", 32)    // Google DNS backup
                builder.addRoute("223.5.5.5", 32)  // Aliyun DNS
                builder.addRoute("223.6.6.6", 32)  // Aliyun DNS backup
                Log.d(TAG, "$LOG_PREFIX Added explicit IPv4 DNS server routes")
            } catch (e: Exception) {
                Log.w(TAG, "$LOG_PREFIX WARNING: Failed to add IPv4 DNS routes: ${e.message}")
            }

            // 添加IPv6路由，支持完整的IPv6网络
            try {
                // 路由所有IPv6流量
                builder.addRoute("::", 0)
                Log.d(TAG, "$LOG_PREFIX Added IPv6 default route (::/0)")

                // IPv6 DNS服务器路由（明确指定，确保DNS请求通过VPN）
                builder.addRoute("2606:4700:4700::1111", 128)  // Cloudflare IPv6 DNS
                builder.addRoute("2606:4700:4700::1001", 128)  // Cloudflare IPv6 DNS backup
                builder.addRoute("2001:4860:4860::8888", 128)  // Google IPv6 DNS
                builder.addRoute("2001:4860:4860::8844", 128)  // Google IPv6 DNS backup
                Log.d(TAG, "$LOG_PREFIX Added explicit IPv6 DNS server routes")
            } catch (e: Exception) {
                Log.w(TAG, "$LOG_PREFIX WARNING: Failed to add IPv6 routes: ${e.message}")
            }

            // 必须排除本应用，避免VPN循环
            try {
                builder.addDisallowedApplication(packageName)
                Log.d(TAG, "$LOG_PREFIX Excluded self from VPN: $packageName")
            } catch (e: Exception) {
                Log.w(TAG, "$LOG_PREFIX WARNING: Failed to exclude app from VPN", e)
            }

            // 应用分应用代理设置
            applyPerAppProxySettings(builder)

            // 建立VPN
            val pfd = builder.establish()
            if (pfd != null) {
                Log.i(TAG, "$LOG_PREFIX VPN interface established with FD: ${pfd.fd}")
            }
            return pfd

        } catch (e: Exception) {
            Log.e(TAG, "$LOG_PREFIX ERROR: Failed to establish VPN", e)
            return null
        }
    }

    /**
     * 应用分应用代理设置
     */
    private fun applyPerAppProxySettings(builder: Builder) {
        when (perAppProxyMode) {
            PER_APP_ALLOW_LIST -> {
                // 仅允许列表中的应用走VPN
                Log.d(TAG, "$LOG_PREFIX Applying allow list mode with ${perAppProxyList.size} apps")
                for (pkg in perAppProxyList) {
                    try {
                        if (pkg != packageName) {
                            builder.addAllowedApplication(pkg)
                            Log.d(TAG, "$LOG_PREFIX Added allowed app: $pkg")
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "$LOG_PREFIX WARNING: Failed to add allowed app: $pkg", e)
                    }
                }
            }
            PER_APP_BLOCK_LIST -> {
                // 排除列表中的应用，其他走VPN
                Log.d(TAG, "$LOG_PREFIX Applying block list mode with ${perAppProxyList.size} apps")
                for (pkg in perAppProxyList) {
                    try {
                        builder.addDisallowedApplication(pkg)
                        Log.d(TAG, "$LOG_PREFIX Added disallowed app: $pkg")
                    } catch (e: Exception) {
                        Log.w(TAG, "$LOG_PREFIX WARNING: Failed to add disallowed app: $pkg", e)
                    }
                }
            }
            else -> {
                Log.d(TAG, "$LOG_PREFIX Per-app proxy disabled, all apps will use VPN")
            }
        }
    }

    // ============================================================================
    // MARK: - 网络监控
    // ============================================================================

    /**
     * 处理网络变化
     */
    private fun handleNetworkChange(network: Network) {
        if (!isRunning.get()) {
            return
        }

        Log.d(TAG, "$LOG_PREFIX Handling network change...")

        val capabilities = connectivityManager.getNetworkCapabilities(network)
        if (capabilities == null) {
            Log.w(TAG, "$LOG_PREFIX WARNING: Cannot get network capabilities")
            return
        }

        val hasInternet = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        if (!hasInternet) {
            Log.w(TAG, "$LOG_PREFIX WARNING: Network has no internet")
            return
        }

        // 更新底层网络
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            try {
                underlyingNetwork = network
                setUnderlyingNetworks(arrayOf(network))
                Log.i(TAG, "$LOG_PREFIX Underlying network updated to: $network")
            } catch (e: Exception) {
                Log.w(TAG, "$LOG_PREFIX WARNING: Failed to update underlying networks", e)
            }
        }

        // 重新设置代理路由（网关可能已改变）
        val newGateway = getDefaultGateway()
        if (newGateway != null && newGateway != savedDefaultGateway) {
            Log.i(TAG, "$LOG_PREFIX Default gateway changed: $savedDefaultGateway -> $newGateway")
            savedDefaultGateway = newGateway
            setupProxyRouteExclusion()
        }
    }

    /**
     * 处理网络丢失
     */
    private fun handleNetworkLost() {
        if (!isRunning.get()) {
            return
        }

        Log.w(TAG, "$LOG_PREFIX Network lost, VPN may not work properly")
        // VPN保持运行，等待网络恢复
    }

    // ============================================================================
    // MARK: - 路由管理
    // ============================================================================

    /**
     * 获取默认网关
     */
    private fun getDefaultGateway(): String? {
        try {
            val activeNetwork = connectivityManager.activeNetwork ?: return null
            val linkProperties = connectivityManager.getLinkProperties(activeNetwork) ?: return null

            for (route in linkProperties.routes) {
                if (route.isDefaultRoute && route.hasGateway()) {
                    val gateway = route.gateway?.hostAddress
                    if (gateway != null && !gateway.contains(":")) { // 只使用IPv4
                        Log.d(TAG, "$LOG_PREFIX Found default gateway: $gateway")
                        return gateway
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "$LOG_PREFIX ERROR: Failed to get default gateway", e)
        }
        return null
    }

    /**
     * 设置代理服务器路由排除
     */
    private fun setupProxyRouteExclusion() {
        val gateway = savedDefaultGateway
        if (gateway == null) {
            Log.w(TAG, "$LOG_PREFIX Cannot setup proxy route: no default gateway")
            return
        }

        // 为所有服务器IP添加直连路由（避免VPN流量循环）
        if (allServerIPs.isNotEmpty()) {
            Log.i(TAG, "$LOG_PREFIX Setting up direct routes for ${allServerIPs.size} server IPs")
            for (ip in allServerIPs) {
                if (ip.isNotEmpty() && !ip.contains(":")) {  // 只处理IPv4
                    addDirectRoute(ip, gateway)
                }
            }
        }

        // 当前服务器IP（如果不在列表中也单独添加）
        val serverIP = proxyServerIP
        if (serverIP != null && serverIP.isNotEmpty() && !allServerIPs.contains(serverIP)) {
            Log.i(TAG, "$LOG_PREFIX Setting up direct route for current proxy server IP: $serverIP")
            addDirectRoute(serverIP, gateway)
        }

        // 如果没有IP列表，尝试解析域名
        if (allServerIPs.isEmpty() && (serverIP == null || serverIP.isEmpty())) {
            val serverHost = proxyServerHost
            if (serverHost != null && serverHost.isNotEmpty()) {
                Log.i(TAG, "$LOG_PREFIX Resolving proxy server host: $serverHost")
                Thread {
                    try {
                        val addresses = InetAddress.getAllByName(serverHost)
                        for (addr in addresses) {
                            val ip = addr.hostAddress
                            if (ip != null && !ip.contains(":")) { // 只使用IPv4
                                Log.i(TAG, "$LOG_PREFIX Resolved $serverHost to $ip")
                                addDirectRoute(ip, gateway)
                            }
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "$LOG_PREFIX ERROR: Failed to resolve proxy server", e)
                    }
                }.start()
            }
        }
    }

    /**
     * 添加直连路由（绕过VPN）
     */
    private fun addDirectRoute(ip: String, gateway: String) {
        try {
            val command = "ip route add $ip/32 via $gateway"
            Log.d(TAG, "$LOG_PREFIX Executing: $command")

            val process = Runtime.getRuntime().exec(command)
            val exitCode = process.waitFor()

            if (exitCode == 0) {
                Log.i(TAG, "$LOG_PREFIX ROUTE: Added direct route for $ip via $gateway")
            } else {
                val errorReader = BufferedReader(InputStreamReader(process.errorStream))
                val errorLine = errorReader.readLine()
                errorReader.close()
                Log.w(TAG, "$LOG_PREFIX WARNING: Failed to add route for $ip: $errorLine")
            }
        } catch (e: Exception) {
            Log.e(TAG, "$LOG_PREFIX ERROR: Failed to execute route command", e)
        }
    }

    /**
     * 清理代理路由
     */
    private fun cleanupProxyRoutes() {
        // 清理所有服务器IP的路由
        for (ip in allServerIPs) {
            if (ip.isNotEmpty() && !ip.contains(":")) {
                try {
                    val command = "ip route del $ip/32"
                    Runtime.getRuntime().exec(command).waitFor()
                } catch (e: Exception) {
                    // 忽略清理失败
                }
            }
        }

        // 清理当前服务器IP的路由
        val serverIP = proxyServerIP
        if (serverIP != null && serverIP.isNotEmpty()) {
            try {
                val command = "ip route del $serverIP/32"
                Log.d(TAG, "$LOG_PREFIX Executing: $command")
                Runtime.getRuntime().exec(command).waitFor()
                Log.d(TAG, "$LOG_PREFIX Routes cleaned up")
            } catch (e: Exception) {
                Log.w(TAG, "$LOG_PREFIX WARNING: Failed to cleanup route", e)
            }
        }
    }

    // ============================================================================
    // MARK: - Socket保护
    // ============================================================================

    /**
     * 保护socket文件描述符，防止其流量被路由到VPN
     * 这个方法供JNI native层调用
     *
     * @param fd socket文件描述符
     * @return true表示成功，false表示失败
     */
    fun protectSocketFd(fd: Int): Boolean {
        val result = protect(fd)
        if (result) {
            Log.d(TAG, "$LOG_PREFIX Protected socket FD: $fd")
        } else {
            Log.e(TAG, "$LOG_PREFIX ERROR: Failed to protect socket FD: $fd")
        }
        return result
    }

    // ============================================================================
    // MARK: - 统计和状态
    // ============================================================================

    /**
     * 获取VPN统计信息
     */
    fun getStatistics(): VPNStatistics {
        val uptime = if (isRunning.get()) {
            System.currentTimeMillis() - startTime
        } else {
            0
        }

        // 从SuperRay获取统计
        val stats = superRayManager?.getStatistics() ?: mapOf()
        bytesReceived = stats["bytesReceived"] as? Long ?: stats["download"] as? Long ?: bytesReceived
        bytesSent = stats["bytesSent"] as? Long ?: stats["upload"] as? Long ?: bytesSent

        return VPNStatistics(
            isRunning = isRunning.get(),
            uptime = uptime,
            bytesReceived = bytesReceived,
            bytesSent = bytesSent
        )
    }

    /**
     * 获取当前速度
     */
    fun getCurrentSpeed(): Map<String, Double> {
        return superRayManager?.getCurrentSpeed() ?: mapOf(
            "uplink_rate" to 0.0,
            "downlink_rate" to 0.0
        )
    }

    /**
     * 检查VPN是否正在运行
     */
    fun isVPNRunning(): Boolean = isRunning.get()

    /**
     * 广播状态
     */
    private fun broadcastStatus() {
        val intent = Intent("work.opine.jingo.STATUS_UPDATE")
        intent.putExtra("isRunning", isRunning.get())
        intent.setPackage(packageName)
        sendBroadcast(intent)
    }

    // ============================================================================
    // MARK: - 通知
    // ============================================================================

    private fun createNotification(): Notification {
        // 创建通知渠道（Android 8.0+）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "VPN Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "JinGo VPN is running"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }

        // 点击通知打开应用
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = if (launchIntent != null) {
            PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else {
            null
        }

        // 断开连接动作
        val disconnectIntent = Intent(this, JinGoVPNService::class.java).apply {
            action = ACTION_STOP_VPN
        }
        val disconnectPendingIntent = PendingIntent.getService(
            this,
            0,
            disconnectIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // 构建通知
        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("JinGo VPN")
            .setContentText("VPN is connected")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Disconnect",
                disconnectPendingIntent
            )
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)

        if (pendingIntent != null) {
            builder.setContentIntent(pendingIntent)
        }

        return builder.build()
    }
}

/**
 * VPN统计信息
 */
data class VPNStatistics(
    val isRunning: Boolean,
    val uptime: Long,
    val bytesReceived: Long,
    val bytesSent: Long
)
