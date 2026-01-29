/**
 * @file tun2socks_jni.cpp
 * @brief SuperRay JNI桥接代码
 * @details 连接Kotlin/Java代码和SuperRay C代码
 *
 * @author JinGo VPN Team
 * @date 2025
 *
 * @optimization v2.1 优化内容：
 * - 统一日志格式为【ANDROID TUN】
 * - 添加DNS初始化调用
 * - 增强错误处理和日志
 */

#include <jni.h>
#include <string>
#include <android/log.h>
#include <cstdlib>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>
#include <chrono>
#include <netdb.h>
#include <errno.h>

// SuperRay头文件
#include "superray.h"

#define TAG "SuperRay-JNI"
#define LOG_PREFIX "【ANDROID TUN】"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, LOG_PREFIX __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, LOG_PREFIX __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, TAG, LOG_PREFIX __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, LOG_PREFIX __VA_ARGS__)

// ============================================================================
// 全局变量 - Socket 保护相关
// ============================================================================

static JavaVM* g_jvm = nullptr;                    // Java VM 引用
static jobject g_vpnServiceObj = nullptr;          // VpnService 全局引用
static jmethodID g_protectMethod = nullptr;        // protectSocketFd 方法 ID

// ============================================================================
// Socket 保护回调函数
// ============================================================================

/**
 * @brief 获取当前线程的 JNIEnv
 * @return JNIEnv 指针，失败返回 nullptr
 */
static JNIEnv* get_jni_env() {
    if (!g_jvm) {
        LOGE("JavaVM is null!");
        return nullptr;
    }

    JNIEnv* env = nullptr;
    int status = g_jvm->GetEnv((void**)&env, JNI_VERSION_1_6);

    if (status == JNI_EDETACHED) {
        // 当前线程未附加到 JVM，需要附加
        if (g_jvm->AttachCurrentThread(&env, nullptr) != 0) {
            LOGE("Failed to attach current thread to JVM");
            return nullptr;
        }
    } else if (status != JNI_OK) {
        LOGE("Failed to get JNIEnv: %d", status);
        return nullptr;
    }

    return env;
}

/**
 * @brief Socket 保护回调 - 供 SuperRay 调用
 * @param fd 需要保护的 socket 文件描述符
 * @return 1 成功，0 失败
 *
 * 此函数会被 SuperRay 在创建到代理服务器的连接时调用，
 * 通过 VpnService.protect() 保护 socket，使其绕过 VPN 直接使用物理网络
 */
static int protect_socket(int fd) {
    JNIEnv* env = get_jni_env();
    if (!env) {
        LOGE("protect_socket: Failed to get JNIEnv");
        return 0;
    }

    if (!g_vpnServiceObj || !g_protectMethod) {
        LOGE("protect_socket: VpnService or protect method not initialized");
        return 0;
    }

    // 调用 VpnService.protectSocketFd(fd)
    jboolean result = env->CallBooleanMethod(g_vpnServiceObj, g_protectMethod, fd);

    if (env->ExceptionCheck()) {
        LOGE("protect_socket: Exception occurred while calling protectSocketFd");
        env->ExceptionDescribe();
        env->ExceptionClear();
        return 0;
    }

    if (result) {
        LOGD("Socket FD %d protected successfully", fd);
    } else {
        LOGW("Failed to protect socket FD %d", fd);
    }

    return result ? 1 : 0;
}

// ============================================================================
// JNI方法实现
// ============================================================================

// 全局状态
static bool g_running = false;
static std::string g_instanceId;       // Xray 实例 ID
static std::string g_tunTag = "android-tun";  // TUN 设备标签

/**
 * @brief 初始化 Socket 保护 - 设置 VpnService 引用和方法
 * @param env JNI 环境
 * @param vpnService VpnService 对象
 * @return true 成功，false 失败
 */
static bool initSocketProtection(JNIEnv* env, jobject vpnService) {
    if (!vpnService) {
        LOGE("initSocketProtection: vpnService is null");
        return false;
    }

    // 获取 VpnService 类
    jclass vpnServiceClass = env->GetObjectClass(vpnService);
    if (!vpnServiceClass) {
        LOGE("initSocketProtection: Failed to get VpnService class");
        return false;
    }

    // 获取 protectSocketFd 方法 ID
    g_protectMethod = env->GetMethodID(vpnServiceClass, "protectSocketFd", "(I)Z");
    if (!g_protectMethod) {
        LOGE("initSocketProtection: Failed to find protectSocketFd method");
        env->DeleteLocalRef(vpnServiceClass);
        return false;
    }

    // 创建全局引用（防止被 GC 回收）
    if (g_vpnServiceObj) {
        env->DeleteGlobalRef(g_vpnServiceObj);
    }
    g_vpnServiceObj = env->NewGlobalRef(vpnService);

    env->DeleteLocalRef(vpnServiceClass);

    LOGI("Socket protection initialized successfully");
    return true;
}

/**
 * @brief 清理 Socket 保护资源
 * @param env JNI 环境
 */
static void cleanupSocketProtection(JNIEnv* env) {
    if (g_vpnServiceObj && env) {
        env->DeleteGlobalRef(g_vpnServiceObj);
        g_vpnServiceObj = nullptr;
    }
    g_protectMethod = nullptr;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_work_opine_jingo_SuperRayManager_nativeStart(
    JNIEnv* env,
    jobject /* this */,
    jint tunFd,
    jint mtu,
    jstring socksAddr,
    jint socksPort,
    jstring ipv4Addr,
    jstring ipv4Gateway,
    jstring dnsAddr,
    jstring xrayConfigJson
) {
    LOGI("======== STARTING SUPERRAY ========");

    if (g_running) {
        LOGW("SuperRay already running");
        return JNI_TRUE;
    }

    // 转换Java字符串到C字符串
    const char* socks_addr_cstr = env->GetStringUTFChars(socksAddr, nullptr);
    const char* ipv4_addr_cstr = env->GetStringUTFChars(ipv4Addr, nullptr);
    const char* ipv4_gateway_cstr = env->GetStringUTFChars(ipv4Gateway, nullptr);
    const char* dns_addr_cstr = env->GetStringUTFChars(dnsAddr, nullptr);
    const char* xray_config_cstr = xrayConfigJson ? env->GetStringUTFChars(xrayConfigJson, nullptr) : nullptr;

    if (!socks_addr_cstr || !ipv4_addr_cstr || !ipv4_gateway_cstr || !dns_addr_cstr) {
        LOGE("ERROR: Failed to get string parameters");
        if (socks_addr_cstr) env->ReleaseStringUTFChars(socksAddr, socks_addr_cstr);
        if (ipv4_addr_cstr) env->ReleaseStringUTFChars(ipv4Addr, ipv4_addr_cstr);
        if (ipv4_gateway_cstr) env->ReleaseStringUTFChars(ipv4Gateway, ipv4_gateway_cstr);
        if (dns_addr_cstr) env->ReleaseStringUTFChars(dnsAddr, dns_addr_cstr);
        if (xray_config_cstr) env->ReleaseStringUTFChars(xrayConfigJson, xray_config_cstr);
        return JNI_FALSE;
    }

    LOGI("Step 1: Configuration");
    LOGD("  TUN FD: %d", tunFd);
    LOGD("  MTU: %d", mtu);
    LOGD("  SOCKS: %s:%d", socks_addr_cstr, socksPort);
    LOGD("  IPv4: %s", ipv4_addr_cstr);
    LOGD("  Gateway: %s", ipv4_gateway_cstr);
    LOGD("  DNS: %s", dns_addr_cstr);

    // Step 2: 如果提供了Xray配置，先启动Xray
    if (xray_config_cstr && strlen(xray_config_cstr) > 0) {
        LOGI("Step 2: Starting Xray...");
        char* result = SuperRay_Run(xray_config_cstr);
        if (result) {
            LOGD("SuperRay_Run result: %.500s", result);
            std::string resultStr(result);
            SuperRay_Free(result);

            if (resultStr.find("\"success\":true") == std::string::npos) {
                LOGE("ERROR: Failed to start Xray");
                env->ReleaseStringUTFChars(socksAddr, socks_addr_cstr);
                env->ReleaseStringUTFChars(ipv4Addr, ipv4_addr_cstr);
                env->ReleaseStringUTFChars(ipv4Gateway, ipv4_gateway_cstr);
                env->ReleaseStringUTFChars(dnsAddr, dns_addr_cstr);
                env->ReleaseStringUTFChars(xrayConfigJson, xray_config_cstr);
                return JNI_FALSE;
            }

            // 从返回结果中提取 instance ID
            // 格式: {"success":true,"data":{"id":"instance_xxx",...}}
            size_t idPos = resultStr.find("\"id\":\"");
            if (idPos != std::string::npos) {
                size_t idStart = idPos + 6;  // 跳过 "id":"
                size_t idEnd = resultStr.find("\"", idStart);
                if (idEnd != std::string::npos) {
                    g_instanceId = resultStr.substr(idStart, idEnd - idStart);
                    LOGI("Xray instance ID: %s", g_instanceId.c_str());
                }
            }

            if (g_instanceId.empty()) {
                LOGW("WARNING: Could not extract instance ID from result, using 'default'");
                g_instanceId = "default";
            }

            LOGI("SUCCESS: Xray started with instance ID: %s", g_instanceId.c_str());
        }
    } else {
        LOGI("Step 2: Skipped (no Xray config)");
    }

    // Step 3: 初始化DNS
    LOGI("Step 3: Initializing DNS...");
    char dnsConfigJson[256];
    snprintf(dnsConfigJson, sizeof(dnsConfigJson),
        "{\"servers\":[\"%s\",\"8.8.8.8\",\"1.1.1.1\"]}",
        dns_addr_cstr
    );
    char* dnsResult = SuperRay_InitDNS(dnsConfigJson);
    if (dnsResult) {
        LOGD("DNS init result: %s", dnsResult);
        SuperRay_Free(dnsResult);
        LOGI("SUCCESS: DNS initialized");
    } else {
        LOGW("WARNING: DNS initialization returned null");
    }

    // Step 4: 创建Android TUN配置JSON
    LOGI("Step 4: Creating Android TUN with Xray Dialer...");

    // 配置 DNS 地址格式（需要带端口）
    char dnsWithPort[128];
    if (strchr(dns_addr_cstr, ':') == nullptr) {
        snprintf(dnsWithPort, sizeof(dnsWithPort), "%s:53", dns_addr_cstr);
    } else {
        snprintf(dnsWithPort, sizeof(dnsWithPort), "%s", dns_addr_cstr);
    }

    char tunConfigJson[1024];
    snprintf(tunConfigJson, sizeof(tunConfigJson),
        "{"
        "\"tag\":\"%s\","
        "\"mtu\":%d,"
        "\"dns_addr\":\"%s\""
        "}",
        g_tunTag.c_str(), mtu, dnsWithPort
    );

    LOGD("TUN config: %s", tunConfigJson);
    LOGD("Instance ID: %s", g_instanceId.c_str());

    // Step 5: 使用新的 Android TUN API - 一步创建、绑定 Dialer 并启动
    // 这个 API 会将 TUN 流量通过 Xray 实例的 "proxy" outbound 转发
    LOGI("Step 5: Starting Android TUN stack...");
    char* tunResult = SuperRay_CreateAndStartAndroidTUN(
        tunFd,                      // VpnService 的 FD
        tunConfigJson,              // TUN 配置
        g_instanceId.c_str(),       // Xray 实例 ID
        "proxy"                     // 使用 proxy outbound
    );

    if (tunResult) {
        LOGI("SuperRay_CreateAndStartAndroidTUN result: %s", tunResult);
        std::string tunResultStr(tunResult);
        SuperRay_Free(tunResult);

        if (tunResultStr.find("\"success\":true") == std::string::npos) {
            LOGE("ERROR: Failed to create and start Android TUN");
            // 提取错误信息
            size_t errPos = tunResultStr.find("\"error\":\"");
            if (errPos != std::string::npos) {
                size_t errStart = errPos + 9;
                size_t errEnd = tunResultStr.find("\"", errStart);
                if (errEnd != std::string::npos) {
                    std::string errorMsg = tunResultStr.substr(errStart, errEnd - errStart);
                    LOGE("Error details: %s", errorMsg.c_str());
                }
            }
            SuperRay_StopAll();
            env->ReleaseStringUTFChars(socksAddr, socks_addr_cstr);
            env->ReleaseStringUTFChars(ipv4Addr, ipv4_addr_cstr);
            env->ReleaseStringUTFChars(ipv4Gateway, ipv4_gateway_cstr);
            env->ReleaseStringUTFChars(dnsAddr, dns_addr_cstr);
            if (xray_config_cstr) env->ReleaseStringUTFChars(xrayConfigJson, xray_config_cstr);
            return JNI_FALSE;
        }
        LOGI("SUCCESS: Android TUN stack started and connected to Xray");
    } else {
        LOGE("ERROR: SuperRay_CreateAndStartAndroidTUN returned null");
        SuperRay_StopAll();
        env->ReleaseStringUTFChars(socksAddr, socks_addr_cstr);
        env->ReleaseStringUTFChars(ipv4Addr, ipv4_addr_cstr);
        env->ReleaseStringUTFChars(ipv4Gateway, ipv4_gateway_cstr);
        env->ReleaseStringUTFChars(dnsAddr, dns_addr_cstr);
        if (xray_config_cstr) env->ReleaseStringUTFChars(xrayConfigJson, xray_config_cstr);
        return JNI_FALSE;
    }

    // 释放字符串
    env->ReleaseStringUTFChars(socksAddr, socks_addr_cstr);
    env->ReleaseStringUTFChars(ipv4Addr, ipv4_addr_cstr);
    env->ReleaseStringUTFChars(ipv4Gateway, ipv4_gateway_cstr);
    env->ReleaseStringUTFChars(dnsAddr, dns_addr_cstr);
    if (xray_config_cstr) env->ReleaseStringUTFChars(xrayConfigJson, xray_config_cstr);

    g_running = true;
    LOGI("======== SUPERRAY STARTED SUCCESSFULLY ========");
    return JNI_TRUE;
}

extern "C"
JNIEXPORT void JNICALL
Java_work_opine_jingo_SuperRayManager_nativeStop(
    JNIEnv* /* env */,
    jobject /* this */
) {
    LOGI("======== STOPPING SUPERRAY ========");

    if (!g_running) {
        LOGW("SuperRay not running");
        return;
    }

    // Step 1: 停止 Android TUN（先停止再关闭）
    LOGI("Step 1: Stopping Android TUN...");
    if (!g_tunTag.empty()) {
        char* stopTunResult = SuperRay_StopAndroidTUN(g_tunTag.c_str());
        if (stopTunResult) {
            LOGD("StopAndroidTUN result: %s", stopTunResult);
            SuperRay_Free(stopTunResult);
        }
    }

    // Step 2: 关闭 Android TUN
    LOGI("Step 2: Closing Android TUN...");
    if (!g_tunTag.empty()) {
        char* closeTunResult = SuperRay_CloseAndroidTUN(g_tunTag.c_str());
        if (closeTunResult) {
            LOGD("CloseAndroidTUN result: %s", closeTunResult);
            SuperRay_Free(closeTunResult);
        }
    }

    // Step 3: 关闭所有 Android TUN（确保清理干净）
    LOGI("Step 3: Closing all Android TUNs...");
    char* closeAllResult = SuperRay_CloseAllAndroidTUNs();
    if (closeAllResult) {
        LOGD("CloseAllAndroidTUNs result: %s", closeAllResult);
        SuperRay_Free(closeAllResult);
    }

    // Step 4: 重置DNS
    LOGI("Step 4: Resetting DNS...");
    char* dnsResetResult = SuperRay_ResetDNS();
    if (dnsResetResult) {
        LOGD("DNS reset result: %s", dnsResetResult);
        SuperRay_Free(dnsResetResult);
    }

    // Step 5: 停止所有Xray实例
    LOGI("Step 5: Stopping Xray...");
    char* stopResult = SuperRay_StopAll();
    if (stopResult) {
        LOGD("StopAll result: %s", stopResult);
        SuperRay_Free(stopResult);
    }

    g_running = false;
    g_instanceId.clear();
    LOGI("======== SUPERRAY STOPPED ========");
}

extern "C"
JNIEXPORT jstring JNICALL
Java_work_opine_jingo_SuperRayManager_nativeGetStats(
    JNIEnv* env,
    jobject /* this */
) {
    // 获取流量统计信息（使用SuperRay直接API，无需HTTP查询）
    char* statsResult = SuperRay_GetTrafficStats();
    if (statsResult) {
        jstring result = env->NewStringUTF(statsResult);
        SuperRay_Free(statsResult);
        return result;
    }

    // 返回空统计
    return env->NewStringUTF("{\"bytesReceived\":0,\"bytesSent\":0}");
}

extern "C"
JNIEXPORT jstring JNICALL
Java_work_opine_jingo_SuperRayManager_nativeGetXrayStats(
    JNIEnv* env,
    jobject /* this */
) {
    // 获取Xray核心统计信息（使用SuperRay直接API，无需HTTP/gRPC查询）
    char* statsResult = SuperRay_GetXrayStats();
    if (statsResult) {
        jstring result = env->NewStringUTF(statsResult);
        SuperRay_Free(statsResult);
        return result;
    }

    // 返回空统计
    return env->NewStringUTF("{\"success\":false,\"error\":\"Failed to get stats\"}");
}

extern "C"
JNIEXPORT jstring JNICALL
Java_work_opine_jingo_SuperRayManager_nativeGetCurrentSpeed(
    JNIEnv* env,
    jobject /* this */
) {
    // 获取当前速度（使用SuperRay直接API）
    char* speedResult = SuperRay_GetCurrentSpeed();
    if (speedResult) {
        jstring result = env->NewStringUTF(speedResult);
        SuperRay_Free(speedResult);
        return result;
    }

    // 返回空结果
    return env->NewStringUTF("{\"uplink_rate\":0,\"downlink_rate\":0}");
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_work_opine_jingo_SuperRayManager_nativeIsRunning(
    JNIEnv* /* env */,
    jobject /* this */
) {
    return g_running ? JNI_TRUE : JNI_FALSE;
}

extern "C"
JNIEXPORT jstring JNICALL
Java_work_opine_jingo_SuperRayManager_nativeGetVersion(
    JNIEnv* env,
    jobject /* this */
) {
    char* version = SuperRay_Version();
    if (version) {
        jstring result = env->NewStringUTF(version);
        SuperRay_Free(version);
        return result;
    }
    return env->NewStringUTF("unknown");
}

extern "C"
JNIEXPORT jstring JNICALL
Java_work_opine_jingo_SuperRayManager_nativeGetXrayVersion(
    JNIEnv* env,
    jobject /* this */
) {
    char* version = SuperRay_XrayVersion();
    if (version) {
        jstring result = env->NewStringUTF(version);
        SuperRay_Free(version);
        return result;
    }
    return env->NewStringUTF("unknown");
}

// ============================================================================
// JNI库加载/卸载
// ============================================================================

JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* /* reserved */) {
    LOGI("JNI library loaded - SuperRay ready");

    // 保存 JavaVM 引用（用于 socket 保护回调）
    g_jvm = vm;

    // 获取版本信息
    char* version = SuperRay_Version();
    if (version) {
        LOGI("SuperRay version: %s", version);
        SuperRay_Free(version);
    }

    char* xrayVersion = SuperRay_XrayVersion();
    if (xrayVersion) {
        LOGI("Xray version: %s", xrayVersion);
        SuperRay_Free(xrayVersion);
    }

    return JNI_VERSION_1_6;
}

/**
 * @brief 设置 VpnService 引用并注册 socket 保护回调
 * @note 必须在 nativeStart 之前调用
 */
extern "C"
JNIEXPORT jboolean JNICALL
Java_work_opine_jingo_SuperRayManager_nativeSetVpnService(
    JNIEnv* env,
    jobject /* this */,
    jobject vpnService
) {
    LOGI("Setting VpnService for socket protection...");

    if (!vpnService) {
        LOGE("VpnService is null!");
        return JNI_FALSE;
    }

    // 初始化 socket 保护（保存 VpnService 引用和方法 ID）
    if (!initSocketProtection(env, vpnService)) {
        LOGE("Failed to initialize socket protection");
        return JNI_FALSE;
    }

    // 注册 socket 保护回调到 SuperRay
    LOGI("Registering socket protect callback with SuperRay...");
    char* result = SuperRay_SetSocketProtect(protect_socket);
    if (result) {
        LOGI("SuperRay_SetSocketProtect result: %s", result);
        SuperRay_Free(result);
    }

    LOGI("VpnService set successfully, socket protection enabled");
    return JNI_TRUE;
}

/**
 * @brief 为 JinGoVpnService (Java) 初始化 socket 保护
 * @note 这个函数供 Java 层的 JinGoVpnService 调用
 *       当 C++ 路径启动 VPN 时，会通过 Intent 启动 JinGoVpnService
 *       JinGoVpnService 调用此函数来注册 socket 保护回调
 */
extern "C"
JNIEXPORT jboolean JNICALL
Java_work_opine_jingo_JinGoVpnService_nativeInitSocketProtection(
    JNIEnv* env,
    jobject /* this */,
    jobject vpnService
) {
    LOGI("[JinGoVpnService] Initializing socket protection...");

    if (!vpnService) {
        LOGE("[JinGoVpnService] VpnService is null!");
        return JNI_FALSE;
    }

    // 初始化 socket 保护（保存 VpnService 引用和方法 ID）
    if (!initSocketProtection(env, vpnService)) {
        LOGE("[JinGoVpnService] Failed to initialize socket protection");
        return JNI_FALSE;
    }

    // 注册 socket 保护回调到 SuperRay
    LOGI("[JinGoVpnService] Registering socket protect callback with SuperRay...");
    char* result = SuperRay_SetSocketProtect(protect_socket);
    if (result) {
        LOGI("[JinGoVpnService] SuperRay_SetSocketProtect result: %s", result);
        SuperRay_Free(result);
    }

    LOGI("[JinGoVpnService] Socket protection enabled successfully");
    return JNI_TRUE;
}

JNIEXPORT void JNI_OnUnload(JavaVM* vm, void* /* reserved */) {
    LOGI("JNI library unloading...");

    // 确保停止
    if (g_running) {
        LOGW("Cleaning up running SuperRay instance...");

        // 关闭所有 Android TUN
        char* closeResult = SuperRay_CloseAllAndroidTUNs();
        if (closeResult) SuperRay_Free(closeResult);

        // 重置 DNS
        char* dnsResult = SuperRay_ResetDNS();
        if (dnsResult) SuperRay_Free(dnsResult);

        // 停止所有 Xray 实例
        char* stopResult = SuperRay_StopAll();
        if (stopResult) SuperRay_Free(stopResult);

        g_running = false;
        g_instanceId.clear();
    }

    // 清理 socket 保护资源
    JNIEnv* env = nullptr;
    if (vm && vm->GetEnv((void**)&env, JNI_VERSION_1_6) == JNI_OK) {
        cleanupSocketProtection(env);
    }
    g_jvm = nullptr;

    LOGI("JNI library unloaded");
}

// ============================================================================
// 带保护的 TCP Ping 函数 - 供 VPNManager 调用
// ============================================================================

/**
 * @brief 使用被保护的 socket 执行 TCP Ping
 * @param host 服务器地址（IP 或域名）
 * @param port 服务器端口
 * @param timeout_ms 超时时间（毫秒）
 * @return 延时（毫秒），-1 表示失败
 *
 * 这个函数创建一个 TCP socket，调用 VpnService.protect() 保护它，
 * 然后连接到服务器测量延时。这样可以绕过 VPN 隧道测量真正的延时。
 */
extern "C" int Android_ProtectedTcpPing(const char* host, int port, int timeout_ms) {
    if (!host || port <= 0 || timeout_ms <= 0) {
        LOGE("[ProtectedTcpPing] Invalid parameters: host=%s, port=%d, timeout=%d",
             host ? host : "null", port, timeout_ms);
        return -1;
    }

    LOGE("[ProtectedTcpPing] Testing %s:%d (timeout: %dms)", host, port, timeout_ms);

    // 解析域名为 IP 地址
    struct addrinfo hints = {};
    struct addrinfo* result = nullptr;
    hints.ai_family = AF_INET;  // IPv4
    hints.ai_socktype = SOCK_STREAM;

    char port_str[16];
    snprintf(port_str, sizeof(port_str), "%d", port);

    int ret = getaddrinfo(host, port_str, &hints, &result);
    if (ret != 0 || !result) {
        LOGE("[ProtectedTcpPing] Failed to resolve %s: %s", host, gai_strerror(ret));
        return -1;
    }

    // 获取解析后的IP地址（用于日志）
    char ip_str[INET_ADDRSTRLEN];
    struct sockaddr_in* addr_in = (struct sockaddr_in*)result->ai_addr;
    inet_ntop(AF_INET, &(addr_in->sin_addr), ip_str, INET_ADDRSTRLEN);
    LOGE("[ProtectedTcpPing] Resolved %s -> %s", host, ip_str);

    // 创建 socket
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        LOGE("[ProtectedTcpPing] Failed to create socket: %s", strerror(errno));
        freeaddrinfo(result);
        return -1;
    }

    // 保护 socket（绕过 VPN）
    // 注意：如果 VPN 未运行，protect 会失败，但这是正常的
    // 在这种情况下，socket 会正常工作（不需要绕过 VPN）
    if (!protect_socket(sockfd)) {
        LOGW("[ProtectedTcpPing] Failed to protect socket fd=%d (VPN may not be running, continuing anyway)", sockfd);
        // 不返回错误，继续测试 - 如果 VPN 未运行，socket 会正常工作
    } else {
        LOGE("[ProtectedTcpPing] Socket fd=%d protected successfully", sockfd);
    }

    // 设置为非阻塞模式
    int flags = fcntl(sockfd, F_GETFL, 0);
    fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);

    // 记录开始时间
    auto start = std::chrono::steady_clock::now();

    // 发起连接
    ret = connect(sockfd, result->ai_addr, result->ai_addrlen);
    freeaddrinfo(result);

    if (ret < 0 && errno != EINPROGRESS) {
        LOGE("[ProtectedTcpPing] Connect failed immediately: %s", strerror(errno));
        close(sockfd);
        return -1;
    }

    // 等待连接完成
    struct pollfd pfd = {};
    pfd.fd = sockfd;
    pfd.events = POLLOUT;

    ret = poll(&pfd, 1, timeout_ms);

    // 记录结束时间
    auto end = std::chrono::steady_clock::now();

    if (ret <= 0) {
        LOGW("[ProtectedTcpPing] Connection timeout or error: %s",
             ret == 0 ? "timeout" : strerror(errno));
        close(sockfd);
        return -1;
    }

    // 检查连接是否成功
    int error = 0;
    socklen_t len = sizeof(error);
    getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &error, &len);

    close(sockfd);

    if (error != 0) {
        LOGW("[ProtectedTcpPing] Connection failed: %s", strerror(error));
        return -1;
    }

    // 计算延时
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    int latency = static_cast<int>(duration.count());

    LOGI("[ProtectedTcpPing] Success: %s:%d = %dms", host, port, latency);
    return latency;
}
