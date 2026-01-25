# JinGo VPN ProGuard Rules
# Add project specific ProGuard rules here

# Keep VPN Service
-keep class work.opine.jingo.JinGoVpnService { *; }
-keep class work.opine.jingo.JinGoVpnService$** { *; }

# Keep Activity
-keep class work.opine.jingo.JinGoActivity { *; }

# Keep BroadcastReceiver
-keep class work.opine.jingo.BootCompletedReceiver { *; }

# Keep SecureStorage
-keep class work.opine.jingo.SecureStorage { *; }

# Keep TProxyService for libhev-socks5-tunnel JNI
-keep class hev.htproxy.TProxyService { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
