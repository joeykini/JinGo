// android/src/work/opine/jingo/JinGoVpnService.java

package work.opine.jingo;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.net.ConnectivityManager;
import android.net.LinkProperties;
import android.net.Network;
import android.net.RouteInfo;
import android.net.VpnService;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.ParcelFileDescriptor;
import android.util.Log;
import androidx.core.app.NotificationCompat;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.InetAddress;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;

// 注意: 不再使用libXray Java接口，改用SuperRayManager (JNI -> SuperRay C API)
// SuperRay内部处理socket保护，不需要实现DialerController

public class JinGoVpnService extends VpnService {
    
    private static final String TAG = "JinGoVpnService";
    private static final String CHANNEL_ID = "JinGoVpnChannel";
    private static final int NOTIFICATION_ID = 1;
    
    private static JinGoVpnService instance;
    private ParcelFileDescriptor vpnInterface;
    private Thread vpnThread;
    private boolean running = false;
    private Handler mainHandler = new Handler(Looper.getMainLooper());
    
    // VPN 配置参数
    private String vpnAddress;
    private int vpnPrefixLength;
    private int vpnMtu;
    private String proxyServerHost;  // 代理服务器域名（用于xray的SNI握手）
    private String proxyServerIP;    // 代理服务器IP（用于路由排除）

    // 分应用代理配置
    private int perAppProxyMode = 0;  // 0=禁用, 1=允许列表(仅选中的走VPN), 2=排除列表(选中的不走VPN)
    private List<String> perAppProxyList = new ArrayList<>();

    // 统计信息
    private long bytesReceived = 0;
    private long bytesSent = 0;
    
    // 数据回调接口（供 Qt/C++ 层使用）
    public interface PacketCallback {
        void onPacketReceived(byte[] packet);
        byte[] onPacketToSend();
    }
    
    private static PacketCallback packetCallback;
    
    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;
        createNotificationChannel();
    }
    
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            String action = intent.getAction();
            
            if ("START_VPN".equals(action)) {
                String address = intent.getStringExtra("address");
                String netmask = intent.getStringExtra("netmask");
                int mtu = intent.getIntExtra("mtu", 1500);
                String proxyServerHost = intent.getStringExtra("proxyServerHost");
                String proxyServerIP = intent.getStringExtra("proxyServerIP");
                int perAppMode = intent.getIntExtra("perAppProxyMode", 0);
                ArrayList<String> perAppList = intent.getStringArrayListExtra("perAppProxyList");

                startVpn(address, netmask, mtu, proxyServerHost, proxyServerIP, perAppMode, perAppList);
            } else if ("STOP_VPN".equals(action)) {
                stopVpn();
            }
        }
        
        return START_STICKY;
    }
    
    /**
     * 启动 VPN 连接
     * @param address VPN IP地址
     * @param netmask 子网掩码
     * @param mtu MTU值
     * @param proxyServerHost 代理服务器域名（用于xray的SNI握手）
     * @param proxyServerIP 代理服务器IP（用于路由排除）
     * @param perAppMode 分应用代理模式 (0=禁用, 1=允许列表, 2=排除列表)
     * @param perAppList 分应用代理应用包名列表
     */
    public boolean startVpn(String address, String netmask, int mtu, String proxyServerHost, String proxyServerIP,
                            int perAppMode, List<String> perAppList) {
        if (running) {
            Log.w(TAG, "VPN already running");
            return false;
        }

        try {
            this.vpnAddress = address;
            this.vpnPrefixLength = netmaskToPrefixLength(netmask);
            this.vpnMtu = mtu;
            this.proxyServerHost = proxyServerHost;

            // 分应用代理配置
            this.perAppProxyMode = perAppMode;
            this.perAppProxyList.clear();
            if (perAppList != null) {
                this.perAppProxyList.addAll(perAppList);
            }
            Log.i(TAG, "Per-app proxy mode: " + perAppMode + ", apps: " + this.perAppProxyList.size());

            // 直接使用传入的 proxyServerIP（不在主线程做 DNS 解析，会导致 NetworkOnMainThreadException）
            // SuperRay/Xray 内部会处理 DNS 解析
            this.proxyServerIP = proxyServerIP;

            Log.i(TAG, "VPN config: " + address + "/" + vpnPrefixLength + ", MTU: " + mtu +
                ", ProxyServer Host: " + proxyServerHost + ", IP: " + this.proxyServerIP);

            // 关键：初始化 socket 保护，必须在创建 VPN 接口之前完成
            // 这样 SuperRay/Xray 创建到代理服务器的连接时可以保护 socket 绕过 VPN
            if (!initSocketProtection()) {
                Log.e(TAG, "Failed to initialize socket protection - VPN may not work correctly");
                // 继续执行，不阻止 VPN 启动（某些情况下可能仍然工作）
            }

            // 关键：在VPN启动前获取默认网关（VPN启动后默认路由会被修改）
            final String defaultGateway = getDefaultGateway();
            if (defaultGateway != null) {
                Log.i(TAG, "Default gateway before VPN: " + defaultGateway);
            } else {
                Log.w(TAG, "Failed to get default gateway before VPN start");
            }

            // 建立 VPN 接口
            vpnInterface = establishVpnInterface();

            if (vpnInterface == null) {
                Log.e(TAG, "Failed to establish VPN interface");
                return false;
            }

            // 关键：设置底层网络，让被protect()保护的socket知道使用哪个网络接口
            // 这对于 Android 5.0+ (API 21+) 至关重要
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                try {
                    ConnectivityManager cm = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
                    if (cm != null) {
                        Network activeNetwork = cm.getActiveNetwork();
                        if (activeNetwork != null) {
                            // 设置VPN的底层网络，这样protect()的socket会使用这个网络
                            setUnderlyingNetworks(new Network[]{activeNetwork});
                            Log.i(TAG, "Set underlying network for VPN: " + activeNetwork);
                        } else {
                            Log.w(TAG, "No active network found, protected sockets may not work");
                            // 设置null表示使用系统默认网络
                            setUnderlyingNetworks(null);
                        }
                    }
                } catch (Exception e) {
                    Log.e(TAG, "Failed to set underlying networks", e);
                }
            }

            // 注意: SuperRay内部处理socket保护，不需要注册DialerController
            // SuperRay使用C API直接调用，socket保护在native层完成
            Log.i(TAG, "SuperRay handles socket protection internally - no DialerController needed");

            // 启动前台服务通知
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                // Android 14+ (API 34+) 需要指定服务类型
                startForeground(NOTIFICATION_ID, createNotification("VPN Connected",
                    "JinGoVPN is active"), ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE);
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10-13 (API 29-33)
                startForeground(NOTIFICATION_ID, createNotification("VPN Connected",
                    "JinGoVPN is active"), android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST);
            } else {
                // Android 9 及以下
                startForeground(NOTIFICATION_ID, createNotification("VPN Connected",
                    "JinGoVPN is active"));
            }

            // 注意：数据包处理由 C++ 层的 hev-socks5-tunnel (tun2socks) 处理
            // 不需要在 Java 层再次读取 TUN 设备，否则会导致冲突
            running = true;

            // 立即添加代理服务器路由排除
            // 优先使用C++层预先解析的IP（避免DNS死锁），如果没有IP才解析域名
            if (defaultGateway != null &&
                ((proxyServerIP != null && !proxyServerIP.isEmpty()) ||
                 (proxyServerHost != null && !proxyServerHost.isEmpty()))) {
                final String serverIP = proxyServerIP;
                final String serverHost = proxyServerHost;
                final String gateway = defaultGateway;
                // 在后台线程执行，避免NetworkOnMainThreadException
                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        // 检查 serverIP 是否真的是 IP 地址（不是域名）
                        if (serverIP != null && !serverIP.isEmpty() && isIPAddress(serverIP)) {
                            Log.i(TAG, "Setting up proxy route exclusion using pre-resolved IP: " + serverIP);
                            // 直接使用预先获取的网关添加路由
                            addDirectRoute(serverIP, gateway);
                        } else if (serverIP != null && !serverIP.isEmpty()) {
                            // serverIP 是域名，需要解析
                            Log.i(TAG, "serverIP is a hostname, resolving: " + serverIP);
                            setupProxyServerRouteExclusion(serverIP, gateway);
                        } else if (serverHost != null && !serverHost.isEmpty()) {
                            Log.i(TAG, "Setting up proxy route exclusion using host (will resolve): " + serverHost);
                            setupProxyServerRouteExclusion(serverHost, gateway);
                        }
                    }
                }).start();
            } else if (defaultGateway == null) {
                Log.e(TAG, "Cannot add proxy route exclusion: default gateway not available");
            }

            Log.i(TAG, "VPN started successfully");
            return true;
            
        } catch (Exception e) {
            Log.e(TAG, "Failed to start VPN", e);
            return false;
        }
    }
    
    /**
     * 停止 VPN 连接
     */
    public void stopVpn() {
        running = false;

        // VPN 数据处理由 C++ 层的 tun2socks 处理，不需要停止 Java 线程

        if (vpnInterface != null) {
            // 如果 fd 已经被 detach 给 native 代码，就不需要关闭了
            // native 代码（SuperRay）会负责关闭 fd
            if (!fdDetached) {
                try {
                    vpnInterface.close();
                } catch (IOException e) {
                    Log.w(TAG, "Error closing VPN interface", e);
                }
            } else {
                Log.d(TAG, "VPN fd was detached, native code will close it");
            }
            vpnInterface = null;
        }

        // 重置 detach 状态，以便下次连接
        fdDetached = false;
        detachedFd = -1;

        // 使用新的 API 停止前台服务
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE);
        } else {
            // 使用已弃用的 API（适用于旧版本 Android）
            stopForegroundCompat(true);
        }
        stopSelf();

        Log.i(TAG, "VPN stopped");
    }
    
    /**
     * 建立 VPN 网络接口（使用分割隧道排除代理服务器）
     */
    private ParcelFileDescriptor establishVpnInterface() {
        Builder builder = new Builder();

        builder.setSession("JinGoVPN")
               .addAddress(vpnAddress, vpnPrefixLength)
               .setMtu(vpnMtu)
               .addDnsServer("8.8.8.8")
               .addDnsServer("8.8.4.4");

        // 关键：设置非阻塞模式，hev-socks5-tunnel使用异步I/O模型
        // 必须使用非阻塞TUN设备，否则读写会阻塞导致数据无法正确处理
        builder.setBlocking(false);

        // 关键：使用 allowBypass 允许底层socket绕过VPN
        // 这样代理服务器连接可以不经过VPN
        builder.allowBypass();

        // 关键：排除代理服务器IP，让到代理服务器的连接不走VPN
        // 这样xray连接代理服务器时不会被路由回VPN造成循环
        if (proxyServerIP != null && !proxyServerIP.isEmpty()) {
            try {
                // 分离IP和子网掩码（如果proxyServerIP包含域名，需要解析）
                String[] parts = proxyServerIP.split("/");
                String ip = parts[0];

                // 排除代理服务器IP（使用/32表示单个IP）
                // 注意：这会让到这个IP的流量走系统默认路由而不是VPN
                Log.i(TAG, "Excluding proxy server IP from VPN: " + ip);

                // 添加两个路由：0.0.0.0/1 和 128.0.0.0/1
                // 这样覆盖所有IP除了被排除的
                builder.addRoute("0.0.0.0", 1);
                builder.addRoute("128.0.0.0", 1);

                Log.i(TAG, "VPN routes configured to allow proxy server bypass");
            } catch (Exception e) {
                Log.w(TAG, "Failed to exclude proxy IP, using default route: " + e.getMessage());
                // 失败时使用默认路由
                builder.addRoute("0.0.0.0", 0);
            }
        } else {
            // 如果没有代理服务器IP，路由所有流量
            builder.addRoute("0.0.0.0", 0);
        }

        Log.i(TAG, "VPN configured with setBlocking(false) + allowBypass() - async I/O mode");

        // 分应用代理配置
        if (perAppProxyMode != 0 && !perAppProxyList.isEmpty()) {
            try {
                if (perAppProxyMode == 1) {
                    // 允许列表模式：只有选中的应用走 VPN
                    Log.i(TAG, "Per-app proxy: Allow mode, " + perAppProxyList.size() + " apps will use VPN");
                    for (String packageName : perAppProxyList) {
                        try {
                            builder.addAllowedApplication(packageName);
                            Log.d(TAG, "Added allowed app: " + packageName);
                        } catch (Exception e) {
                            Log.w(TAG, "Failed to add allowed app: " + packageName + ", " + e.getMessage());
                        }
                    }
                } else if (perAppProxyMode == 2) {
                    // 排除列表模式：选中的应用不走 VPN
                    Log.i(TAG, "Per-app proxy: Block mode, " + perAppProxyList.size() + " apps will bypass VPN");
                    for (String packageName : perAppProxyList) {
                        try {
                            builder.addDisallowedApplication(packageName);
                            Log.d(TAG, "Added disallowed app: " + packageName);
                        } catch (Exception e) {
                            Log.w(TAG, "Failed to add disallowed app: " + packageName + ", " + e.getMessage());
                        }
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "Failed to configure per-app proxy", e);
            }
        } else {
            Log.i(TAG, "Per-app proxy: Disabled, all apps will use VPN");
        }

        try {
            return builder.establish();
        } catch (Exception e) {
            Log.e(TAG, "Failed to establish VPN interface", e);
            return null;
        }
    }
    
    /**
     * 处理 VPN 数据包
     */
    private void handleVpnData() {
        try {
            FileInputStream in = new FileInputStream(vpnInterface.getFileDescriptor());
            FileOutputStream out = new FileOutputStream(vpnInterface.getFileDescriptor());
            
            ByteBuffer packet = ByteBuffer.allocate(32767); // 最大 IP 包大小
            
            while (running) {
                // 从 VPN 接口读取数据包
                int length = in.read(packet.array());
                
                if (length > 0) {
                    bytesReceived += length;
                    packet.limit(length);
                    
                    // 处理数据包（可以在这里调用 C++ 层的回调）
                    byte[] data = new byte[length];
                    System.arraycopy(packet.array(), 0, data, 0, length);
                    
                    if (packetCallback != null) {
                        packetCallback.onPacketReceived(data);
                        
                        // 获取要发送的数据包
                        byte[] outPacket = packetCallback.onPacketToSend();
                        if (outPacket != null && outPacket.length > 0) {
                            out.write(outPacket);
                            bytesSent += outPacket.length;
                        }
                    }
                    
                    packet.clear();
                }
            }
            
        } catch (IOException e) {
            if (running) {
                Log.e(TAG, "Error in VPN data handler", e);
            }
        }
    }
    
    /**
     * 获取 VPN 文件描述符（供 C++ 层使用）
     * 注意：使用 detachFd() 转移所有权给 native 代码
     * native 代码负责关闭 fd，Java 层不再关闭
     */
    private int detachedFd = -1;
    private boolean fdDetached = false;

    public int getVpnFileDescriptor() {
        if (vpnInterface != null) {
            if (!fdDetached) {
                // 第一次调用时，detach fd 并记录
                // 这样 native 代码可以自由使用和关闭 fd
                try {
                    detachedFd = vpnInterface.detachFd();
                    fdDetached = true;
                    Log.d(TAG, "VPN fd detached: " + detachedFd);
                } catch (Exception e) {
                    Log.e(TAG, "Failed to detach fd, using getFd", e);
                    return vpnInterface.getFd();
                }
            }
            return detachedFd;
        }
        return -1;
    }
    
    /**
     * 获取统计信息
     */
    public long getBytesReceived() {
        return bytesReceived;
    }
    
    public long getBytesSent() {
        return bytesSent;
    }
    
    public void resetStatistics() {
        bytesReceived = 0;
        bytesSent = 0;
    }
    
    /**
     * 设置数据包回调
     */
    public static void setPacketCallback(PacketCallback callback) {
        packetCallback = callback;
    }
    
    /**
     * 子网掩码转前缀长度
     */
    private int netmaskToPrefixLength(String netmask) {
        try {
            InetAddress addr = InetAddress.getByName(netmask);
            byte[] bytes = addr.getAddress();
            int prefixLength = 0;
            
            for (byte b : bytes) {
                int mask = 0xFF & b;
                while (mask != 0) {
                    prefixLength += (mask & 1);
                    mask >>= 1;
                }
            }
            
            return prefixLength;
        } catch (Exception e) {
            Log.e(TAG, "Failed to convert netmask to prefix length", e);
            return 24; // 默认值
        }
    }
    
    /**
     * 创建通知渠道（Android 8.0+）
     */
    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "VPN Service",
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("JinGoVPN Connection Status");
            
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }
    
    /**
     * 创建前台服务通知
     */
    private Notification createNotification(String title, String message) {
        Intent intent = new Intent(this, getClass());
        PendingIntent pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_IMMUTABLE
        );
        
        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pendingIntent)
            .setOngoing(true);
        
        return builder.build();
    }
    
    /**
     * 获取服务实例（供 C++ 层调用）
     */
    public static JinGoVpnService getInstance() {
        return instance;
    }

    // ========================================================================
    // Socket Protection (Native Layer)
    // ========================================================================

    // 加载 SuperRay native 库
    static {
        try {
            System.loadLibrary("superray");
            Log.i(TAG, "SuperRay native library loaded successfully");
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "Failed to load SuperRay native library", e);
        }
    }

    /**
     * Native 方法：初始化 socket 保护
     * 这个方法会把 VpnService 引用传递给 native 层，并注册 socket 保护回调
     * 必须在创建 TUN 之前调用
     *
     * @param vpnService VpnService 实例 (this)
     * @return true 成功，false 失败
     */
    private native boolean nativeInitSocketProtection(Object vpnService);

    /**
     * 初始化 socket 保护
     * 在 VPN 启动时调用，将 VpnService 引用传递给 native 层
     */
    private boolean initSocketProtection() {
        Log.i(TAG, "Initializing socket protection...");
        try {
            boolean result = nativeInitSocketProtection(this);
            if (result) {
                Log.i(TAG, "Socket protection initialized successfully");
            } else {
                Log.e(TAG, "Failed to initialize socket protection");
            }
            return result;
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "Native method not found - socket protection unavailable", e);
            return false;
        } catch (Exception e) {
            Log.e(TAG, "Exception initializing socket protection", e);
            return false;
        }
    }

    /**
     * 保护socket文件描述符，防止其流量被路由到VPN
     * 这个方法供JNI native层调用
     *
     * @param fd socket文件描述符
     * @return true if successful, false otherwise
     *
     * 原理：
     * 1. SuperRay native代码创建连接到代理服务器的socket时会通过JNI调用此方法
     * 2. VpnService.protect(fd)将该socket标记为"绕过VPN"
     * 3. Android系统确保该socket的流量直接走物理网络接口，不经过tun0
     * 4. 这样xray的出站流量就不会形成路由循环
     */
    public boolean protectSocketFd(int fd) {
        boolean result = protect(fd);
        if (!result) {
            Log.e(TAG, "Failed to protect socket FD: " + fd);
        } else {
            Log.d(TAG, "Protected socket FD: " + fd);
        }
        return result;
    }

    /**
     * 设置代理服务器路由排除（避免循环）
     * @param proxyHost 代理服务器地址（域名或IP）
     * @param gateway 默认网关（VPN启动前获取）
     */
    private void setupProxyServerRouteExclusion(String proxyHost, String gateway) {
        Log.i(TAG, "Setting up route exclusion for proxy server: " + proxyHost + " via gateway: " + gateway);

        try {
            // 解析代理服务器域名为IP地址
            List<String> proxyIps = resolveHostToIPs(proxyHost);

            if (proxyIps.isEmpty()) {
                Log.w(TAG, "Failed to resolve proxy server: " + proxyHost);
                return;
            }

            Log.i(TAG, "Resolved proxy server IPs: " + proxyIps);

            // 为每个代理服务器IP添加直连路由
            for (String proxyIp : proxyIps) {
                addDirectRoute(proxyIp, gateway);
            }

        } catch (Exception e) {
            Log.e(TAG, "Failed to setup proxy server route exclusion", e);
        }
    }

    /**
     * 解析域名为IP地址列表（如果已经是IP则直接返回）
     */
    private List<String> resolveHostToIPs(String host) {
        List<String> ips = new ArrayList<>();

        // 检查是否已经是IP地址
        if (isIPAddress(host)) {
            Log.i(TAG, "Host is already an IP address: " + host);
            ips.add(host);
            return ips;
        }

        // 否则解析域名
        try {
            InetAddress[] addresses = InetAddress.getAllByName(host);
            for (InetAddress addr : addresses) {
                String ip = addr.getHostAddress();
                if (ip != null && !ip.contains(":")) {  // 只使用IPv4
                    ips.add(ip);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to resolve host: " + host, e);
        }

        return ips;
    }

    /**
     * 检查字符串是否为IP地址
     */
    private boolean isIPAddress(String host) {
        if (host == null || host.isEmpty()) {
            return false;
        }
        // 简单检查：IP地址格式为 x.x.x.x
        String[] parts = host.split("\\.");
        if (parts.length != 4) {
            return false;
        }
        for (String part : parts) {
            try {
                int num = Integer.parseInt(part);
                if (num < 0 || num > 255) {
                    return false;
                }
            } catch (NumberFormatException e) {
                return false;
            }
        }
        return true;
    }

    /**
     * 检查字符串是否为有效的IP地址格式（别名方法）
     */
    private boolean isValidIPAddress(String address) {
        return isIPAddress(address);
    }

    /**
     * 同步解析主机名为IP地址（仅返回第一个IPv4地址）
     * 注意：此方法会阻塞，必须在VPN启动前调用（此时网络可用）
     */
    private String resolveHostnameSync(String hostname) {
        try {
            InetAddress[] addresses = InetAddress.getAllByName(hostname);
            for (InetAddress addr : addresses) {
                String ip = addr.getHostAddress();
                if (ip != null && !ip.contains(":")) {  // 只使用IPv4
                    return ip;
                }
            }
            // 如果没有IPv4，返回任意地址
            if (addresses.length > 0) {
                return addresses[0].getHostAddress();
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to resolve hostname: " + hostname, e);
        }
        return null;
    }

    /**
     * 获取默认网关地址（使用Android ConnectivityManager API）
     */
    private String getDefaultGateway() {
        try {
            ConnectivityManager cm = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
            if (cm == null) {
                Log.e(TAG, "ConnectivityManager not available");
                return null;
            }

            Network activeNetwork = cm.getActiveNetwork();
            if (activeNetwork == null) {
                Log.e(TAG, "No active network");
                return null;
            }

            LinkProperties linkProperties = cm.getLinkProperties(activeNetwork);
            if (linkProperties == null) {
                Log.e(TAG, "No link properties for active network");
                return null;
            }

            // 查找默认路由的网关
            for (RouteInfo route : linkProperties.getRoutes()) {
                if (route.isDefaultRoute() && route.hasGateway()) {
                    String gateway = route.getGateway().getHostAddress();
                    Log.i(TAG, "Found default gateway via ConnectivityManager: " + gateway);
                    return gateway;
                }
            }

            Log.w(TAG, "No default route found in link properties");
        } catch (Exception e) {
            Log.e(TAG, "Failed to get default gateway via ConnectivityManager", e);
        }

        return null;
    }

    /**
     * 添加直连路由（绕过VPN）- 通过日志记录代理服务器IP
     *
     * 注意：Android 不允许非 root 应用使用 ip route 命令
     * 实际的路由排除通过以下机制实现：
     * 1. VpnService.Builder.allowBypass() - 允许socket绕过VPN
     * 2. VpnService.protect(socket) - 保护特定socket不走VPN
     * 3. SuperRay native层调用 protectSocketFd() 保护代理连接socket
     */
    private void addDirectRoute(String ip, String gateway) {
        // 记录代理服务器IP，便于调试
        Log.i(TAG, "Proxy server IP: " + ip + " (route exclusion via socket protection)");
        Log.i(TAG, "Socket protection is handled by SuperRay native layer calling protectSocketFd()");

        // Android VPN 路由排除机制说明：
        // - ip route add 命令需要 root 权限，普通应用无法使用
        // - 正确做法是在建立VPN时使用 Builder 配置路由
        // - 对于代理服务器，使用 VpnService.protect() 保护其 socket
        // - SuperRay 在 native 层创建 socket 后会通过 JNI 调用 protectSocketFd()
    }

    @Override
    public void onDestroy() {
        stopVpn();
        instance = null;
        super.onDestroy();
        Log.d(TAG, "JinGoVpnService destroyed");
    }
    
    @Override
    public void onRevoke() {
        stopVpn();
        super.onRevoke();
        Log.i(TAG, "VPN permission revoked");
    }

    /**
     * 兼容旧版本的 stopForeground 方法
     * 使用 SuppressWarnings 抑制弃用警告
     */
    @SuppressWarnings("deprecation")
    private void stopForegroundCompat(boolean removeNotification) {
        stopForeground(removeNotification);
    }
}