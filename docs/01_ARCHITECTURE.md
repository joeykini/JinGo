# JinGo VPN - 架构说明

## 概述

JinGo VPN 采用双项目架构，将核心业务逻辑与应用界面分离：

- **JinDo**: 核心静态库，包含所有业务逻辑
- **JinGo**: 应用壳，包含 UI 和平台入口

这种架构的优势：
1. **代码保护**: 核心逻辑编译为静态库，难以逆向
2. **复用性**: 同一核心库可用于多个应用变体
3. **维护性**: 界面和逻辑分离，便于独立更新

## 系统架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        JinGo 应用                           │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    QML 界面层                         │  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐    │  │
│  │  │ 首页    │ │ 服务器  │ │ 设置    │ │ 个人中心│    │  │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘    │  │
│  └──────────────────────────────────────────────────────┘  │
│                            │                                │
│                            ▼                                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   main.cpp (入口)                     │  │
│  │  • 初始化应用                                         │  │
│  │  • 注册 QML 上下文                                    │  │
│  │  • 加载 QML 引擎                                      │  │
│  └──────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    JinDoCore 静态库                         │
├─────────────────────────────────────────────────────────────┤
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │   Core     │ │  Network   │ │  Storage   │              │
│  │ • VPNCore  │ │ • ApiClient│ │ • Database │              │
│  │ • VPNMgr   │ │ • AuthMgr  │ │ • Cache    │              │
│  │ • ConfigMgr│ │ • SubMgr   │ │ • Secure   │              │
│  └────────────┘ └────────────┘ └────────────┘              │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │   Models   │ │ ViewModels │ │   Utils    │              │
│  │ • Server   │ │ • LoginVM  │ │ • Crypto   │              │
│  │ • User     │ │ • ServerVM │ │ • Network  │              │
│  │ • Sub      │ │ • ConnVM   │ │ • Format   │              │
│  └────────────┘ └────────────┘ └────────────┘              │
├─────────────────────────────────────────────────────────────┤
│                    平台适配层                               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───────┐│
│  │ Android │ │  iOS    │ │ macOS   │ │ Windows │ │ Linux ││
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └───────┘│
├─────────────────────────────────────────────────────────────┤
│                    SuperRay (Xray 封装)                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • Xray 核心管理                                      │  │
│  │  • TUN 设备管理                                       │  │
│  │  • 流量统计                                           │  │
│  │  • DNS 管理                                           │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 模块说明

### 1. Core 模块

核心业务逻辑，单例模式管理。

| 类 | 职责 |
|---|------|
| `VPNCore` | VPN 核心控制器，协调各组件 |
| `VPNManager` | VPN 连接管理，状态机 |
| `ConfigManager` | 应用配置管理 |
| `BundleConfig` | 白标配置管理 |
| `Logger` | 日志管理 |
| `BackgroundDataUpdater` | 后台数据同步 |

### 2. Network 模块

网络通信和 API 调用。

| 类 | 职责 |
|---|------|
| `ApiClient` | HTTP API 客户端 |
| `AuthManager` | 用户认证管理 |
| `SubscriptionManager` | 订阅管理 |
| `OrderManager` | 订单管理 |
| `PaymentManager` | 支付管理 |
| `TicketManager` | 工单管理 |
| `SystemConfigManager` | 系统配置同步 |

### 3. Storage 模块

数据持久化。

| 类 | 职责 |
|---|------|
| `DatabaseManager` | SQLite 数据库管理 |
| `CacheManager` | 内存/磁盘缓存 |
| `SecureStorage` | 安全存储（Keychain/DPAPI/libsecret） |

### 4. Models 模块

数据模型，继承 `QObject` 支持 QML 绑定。

| 类 | 职责 |
|---|------|
| `Server` | 服务器信息模型 |
| `User` | 用户信息模型 |
| `Subscription` | 订阅信息模型 |
| `Plan` | 套餐信息模型 |
| `ConnectionStatus` | 连接状态模型 |

### 5. ViewModels 模块

MVVM 视图模型，连接 QML 和业务逻辑。

| 类 | 职责 |
|---|------|
| `LoginViewModel` | 登录/注册逻辑 |
| `ServerListViewModel` | 服务器列表管理 |
| `ConnectionViewModel` | 连接状态管理 |
| `SettingsViewModel` | 设置管理 |

### 6. Utils 模块

工具类。

| 类 | 职责 |
|---|------|
| `Crypto` | 加密工具 |
| `AesCrypto` | AES 加密 |
| `RsaCrypto` | RSA 加密 |
| `NetworkUtils` | 网络工具 |
| `FileUtils` | 文件工具 |
| `FormatUtils` | 格式化工具 |
| `CountryUtils` | 国家/地区工具 |
| `LanguageManager` | 多语言管理 |
| `LogManager` | 日志文件管理 |
| `TcpPing` | TCP 延迟测试 |
| `IcmpPing` | ICMP 延迟测试 |

## 平台适配

### Android

```
src/platform/
├── AndroidPlatform.cpp      # 平台接口实现
├── AndroidVpnHelper.cpp     # VPN 辅助类
├── AndroidStatusBarManager.cpp  # 状态栏管理
└── android/cpp/
    └── tun2socks_jni.cpp    # JNI 桥接
```

- 使用 `VpnService` 创建 VPN
- 通过 JNI 调用 SuperRay
- Socket 保护机制防止流量回环

### iOS

```
src/platform/apple/
├── IOSPlatform.mm           # 平台接口实现
├── IOSPlatformHelper.mm     # 辅助类
└── ...

src/extensions/PacketTunnelProvider/
├── PacketTunnelProvider.mm  # Network Extension
└── XrayExtensionBridge.mm   # Xray 桥接
```

- 使用 `NEPacketTunnelProvider` 扩展
- App Groups 共享数据
- XPC 进程间通信

### macOS

```
src/platform/apple/
├── MacOSPlatform.mm         # 平台接口实现
├── MacOSTunManager.mm       # TUN 设备管理
├── SystemProxyManager.mm    # 系统代理管理
└── XrayManager.mm           # Xray 进程管理
```

- 管理员权限创建 TUN
- 或使用 Network Extension（沙盒模式）

### Windows

```
src/platform/
├── WindowsPlatform.cpp      # 平台接口实现
└── windows/
    ├── WinTunManager.cpp    # WinTun 管理
    └── WinTunDriverInstaller.cpp  # 驱动安装
```

- 使用 WinTun 驱动
- DPAPI 安全存储

### Linux

```
src/platform/
├── LinuxPlatform.cpp        # 平台接口实现
└── linux/
    └── LinuxTunManager.cpp  # TUN 设备管理
```

- 使用 `/dev/net/tun`
- 需要 `CAP_NET_ADMIN` 权限
- libsecret 安全存储

## 数据流

### VPN 连接流程

```
用户点击连接
      │
      ▼
┌─────────────┐
│ QML 界面    │
└──────┬──────┘
       │ connect()
       ▼
┌─────────────┐
│ VPNManager  │ ◄── 状态: Disconnected → Connecting
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ VPNCore     │ ◄── 1. 加载配置
└──────┬──────┘     2. 生成 Xray 配置
       │            3. 启动 Xray
       ▼
┌─────────────┐
│ SuperRay    │ ◄── 4. 创建 TUN
└──────┬──────┘     5. 配置路由
       │            6. 开始转发
       ▼
┌─────────────┐
│ VPNManager  │ ◄── 状态: Connecting → Connected
└─────────────┘
```

### 数据同步流程

```
应用启动 / 用户触发刷新
           │
           ▼
┌─────────────────────┐
│ BackgroundDataUpdater│
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     ▼           ▼
┌─────────┐ ┌─────────┐
│AuthMgr  │ │SubMgr   │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ApiClient│ │ApiClient│
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ 用户信息 │ │ 服务器列表│
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────────────────┐
│    DatabaseManager  │
└─────────────────────┘
```

## 配置管理

### Xray 配置生成

```cpp
// VPNCore::generateXrayConfig()
{
  "log": { "loglevel": "warning" },
  "inbounds": [{
    "tag": "socks",
    "port": 10808,
    "protocol": "socks"
  }],
  "outbounds": [{
    "tag": "proxy",
    "protocol": "vmess",  // 根据服务器类型
    "settings": { ... }
  }]
}
```

### 白标配置

```json
// bundle_config.json
{
  "brand_id": "jingo",
  "brand_name": "JinGo VPN",
  "api_base_url": "https://api.example.com",
  "theme": {
    "primary_color": "#007AFF",
    "accent_color": "#34C759"
  }
}
```

## 安全考虑

1. **代码保护**: 核心逻辑在静态库中，增加逆向难度
2. **配置签名**: `bundle_config.json` 签名验证
3. **安全存储**: 敏感数据使用平台安全存储
4. **传输安全**: 所有 API 使用 HTTPS
5. **Socket 保护**: Android VPN 服务 protect() 机制

## 性能优化

1. **延迟加载**: 按需加载服务器列表
2. **缓存策略**: 内存 + 磁盘二级缓存
3. **异步操作**: Qt Concurrent 异步任务
4. **资源复用**: 连接池、对象池
