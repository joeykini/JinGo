# JinGo VPN - 开发指南

## 开发环境设置

### 推荐 IDE

- **Qt Creator** (推荐): 最佳 Qt/QML 支持
- **VS Code**: 配合 Qt 插件
- **CLion**: 配合 Qt CMake 支持

### Qt Creator 配置

1. 打开项目: `File → Open File or Project → CMakeLists.txt`
2. 选择 Kit:
   - Android: Android Qt 6.10.0 Clang arm64-v8a
   - macOS: Desktop Qt 6.10.0 clang 64bit
   - iOS: iOS Qt 6.10.0

3. 配置 CMake:
   ```
   -DUSE_JINDO_LIB=ON
   -DJINDO_ROOT=/path/to/JinDo
   ```

### VS Code 配置

```json
// .vscode/settings.json
{
    "cmake.configureSettings": {
        "USE_JINDO_LIB": "ON",
        "JINDO_ROOT": "${workspaceFolder}/../JinDo"
    },
    "C_Cpp.default.configurationProvider": "ms-vscode.cmake-tools"
}
```

## 项目结构

```
JinGo/
├── src/
│   ├── main.cpp              # 应用入口
│   └── platform/             # 平台特定代码
├── qml/
│   ├── Main.qml              # 主界面
│   ├── pages/                # 页面
│   │   ├── HomePage.qml
│   │   ├── ServerListPage.qml
│   │   ├── SettingsPage.qml
│   │   └── ProfilePage.qml
│   └── components/           # 组件
│       ├── ServerItem.qml
│       ├── ConnectionButton.qml
│       └── ...
├── resources/
│   ├── icons/               # 图标
│   ├── translations/        # 翻译文件
│   │   ├── jingo_en_US.ts
│   │   ├── jingo_zh_CN.ts
│   │   └── ...
│   └── geoip/              # GeoIP 数据
│       ├── geoip.dat
│       └── geosite.dat
└── platform/
    ├── android/            # Android 配置
    │   ├── AndroidManifest.xml
    │   ├── build.gradle
    │   └── src/            # Kotlin 代码
    └── ios/               # iOS 配置
        └── Info.plist
```

## QML 开发

### QML 与 C++ 交互

JinDoCore 的类通过 `main.cpp` 注册到 QML 上下文:

```cpp
// main.cpp
rootContext->setContextProperty("vpnManager", &VPNManager::instance());
rootContext->setContextProperty("authManager", &AuthManager::instance());
rootContext->setContextProperty("subscriptionManager", &SubscriptionManager::instance());
// ...
```

### 在 QML 中使用

```qml
// HomePage.qml
import QtQuick

Item {
    // 访问 VPNManager
    Connections {
        target: vpnManager

        function onConnected() {
            console.log("VPN 已连接")
        }

        function onDisconnected() {
            console.log("VPN 已断开")
        }
    }

    Button {
        text: vpnManager.isConnected ? "断开" : "连接"
        onClicked: {
            if (vpnManager.isConnected) {
                vpnManager.disconnect()
            } else {
                vpnManager.connect()
            }
        }
    }
}
```

### 常用 QML 属性

```qml
// VPNManager 属性
vpnManager.isConnected       // bool: 是否已连接
vpnManager.state             // enum: 连接状态
vpnManager.currentServer     // Server: 当前服务器
vpnManager.connectedTime     // int: 已连接秒数
vpnManager.uploadSpeed       // qint64: 上传速度
vpnManager.downloadSpeed     // qint64: 下载速度

// AuthManager 属性
authManager.isAuthenticated  // bool: 是否已登录
authManager.currentUser      // User: 当前用户

// SubscriptionManager 属性
subscriptionManager.servers          // QList: 服务器列表
subscriptionManager.currentSubscription  // Subscription: 当前订阅
```

## 多语言支持

### 添加新翻译

1. 在 `CMakeLists.txt` 添加 .ts 文件:
   ```cmake
   set(TS_FILES
       resources/translations/jingo_en_US.ts
       resources/translations/jingo_zh_CN.ts
       resources/translations/jingo_new_LANG.ts  # 新增
   )
   ```

2. 生成/更新翻译文件:
   ```bash
   ./scripts/build/build-linux.sh --translate
   # 或使用 Qt Linguist
   lupdate qml/ -ts resources/translations/jingo_new_LANG.ts
   ```

3. 使用 Qt Linguist 翻译

4. 编译翻译:
   ```bash
   lrelease resources/translations/*.ts
   ```

### QML 中使用翻译

```qml
Text {
    text: qsTr("Connect")  // 使用 qsTr() 包裹
}

// 带参数
Text {
    text: qsTr("Connected for %1 seconds").arg(connectedTime)
}
```

## 调试

### 日志输出

```cpp
// C++ 中
LOG_INFO("信息日志");
LOG_WARNING("警告日志");
LOG_ERROR("错误日志");
LOG_DEBUG("调试日志");

// 或使用 Qt
qDebug() << "调试信息";
qInfo() << "普通信息";
qWarning() << "警告信息";
```

### 启用详细日志

```bash
# Linux/macOS
QT_LOGGING_RULES="*.debug=true" ./JinGo

# Android
adb logcat -s JinGo:V VPNManager:V SuperRay-JNI:V

# 过滤特定模块
QT_LOGGING_RULES="JinGo.network.debug=true" ./JinGo
```

### QML 调试

```qml
// 输出日志
console.log("变量值:", someVariable)
console.warn("警告信息")
console.error("错误信息")

// 断点
console.trace()  // 打印调用栈
```

### 远程调试 (Android)

```bash
# 启用 USB 调试
adb devices

# 查看日志
adb logcat | grep -E "JinGo|SuperRay|Qt"

# 部署并运行
./scripts/build/build-android.sh --debug --install
```

## 测试

### 单元测试

```bash
# 编译测试
cmake -DBUILD_TESTS=ON ..
cmake --build . --target tests

# 运行测试
ctest --output-on-failure
```

### 手动测试清单

- [ ] 登录/注册
- [ ] 获取服务器列表
- [ ] VPN 连接/断开
- [ ] 服务器切换
- [ ] 流量统计
- [ ] 设置保存
- [ ] 多语言切换
- [ ] 应用后台/前台切换

## 代码风格

### C++ 风格

```cpp
// 类名: PascalCase
class VPNManager {
public:
    // 方法名: camelCase
    void connectToServer(const Server& server);

    // 成员变量: m_ 前缀
    QString m_serverAddress;

    // 常量: 全大写下划线
    static const int MAX_RETRY_COUNT = 3;
};
```

### QML 风格

```qml
// 文件名: PascalCase.qml
// id: camelCase
Item {
    id: root

    // 属性声明在前
    property string title: ""
    property bool isActive: false

    // 信号声明
    signal clicked()
    signal valueChanged(int newValue)

    // 子组件
    Rectangle {
        id: background
        // ...
    }

    // 函数在后
    function doSomething() {
        // ...
    }
}
```

## 常见开发任务

### 添加新页面

1. 创建 QML 文件: `qml/pages/NewPage.qml`
2. 在 `CMakeLists.txt` 添加到 QML 模块
3. 在 `Main.qml` 添加导航

### 添加新设置项

1. 在 `ConfigManager` 添加属性和方法
2. 在 `SettingsPage.qml` 添加 UI 控件
3. 绑定属性

### 添加新 API 调用

1. 在 `ApiClient` 添加方法
2. 在相关 Manager 类中调用
3. 发出信号通知 UI

## 发布检查清单

- [ ] 更新版本号 (CMakeLists.txt)
- [ ] 更新翻译
- [ ] Release 模式编译
- [ ] 测试所有平台
- [ ] 签名应用
- [ ] 公证 (macOS)
