# JinGo VPN - 故障排除指南

## 编译问题

### Qt 找不到

**错误信息:**
```
CMake Error: Could not find Qt6
```

**解决方法:**

```bash
# 设置 Qt 路径
export Qt6_DIR=/path/to/Qt/6.10.0/gcc_64      # Linux
export Qt6_DIR=/path/to/Qt/6.10.0/macos       # macOS
export Qt6_DIR=/path/to/Qt/6.10.0/msvc2022_64 # Windows

# 或在 CMake 中指定
cmake -DQt6_DIR=/path/to/Qt/6.10.0/gcc_64 ..
```

### JinDoCore 静态库找不到

**错误信息:**
```
CMake Error: JinDoCore library not found
```

**解决方法:**

1. 确认 JinDo 项目位置正确：
```bash
ls ../JinDo/lib/
# 应该看到平台对应的库文件
```

2. 指定正确路径：
```bash
cmake -DJINDO_ROOT=/path/to/JinDo ..
```

### PIC 链接错误 (Android)

**错误信息:**
```
relocation R_AARCH64_ADR_PREL_PG_HI21 cannot be used against symbol
```

**解决方法:**

确保 JinDoCore 使用 PIC 编译：
```cmake
# JinDo/CMakeLists.txt
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
```

### Android NDK 版本不匹配

**错误信息:**
```
CMake Error: Android NDK not found or version mismatch
```

**解决方法:**

```bash
# 设置正确的 NDK 版本
export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/26.1.10909125

# 或指定版本
./scripts/build/build-android.sh --ndk-version 26.1.10909125
```

### iOS 签名错误

**错误信息:**
```
Code Sign error: No matching provisioning profiles found
```

**解决方法:**

1. 在 Apple Developer 创建正确的 App ID
2. 创建对应的 Provisioning Profile
3. 下载并安装到 Xcode
4. 设置环境变量：
```bash
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export CODE_SIGN_IDENTITY="Apple Development"
```

## 运行时问题

### VPN 连接失败

**可能原因:**

1. **服务器不可达**
   ```bash
   # 测试服务器连通性
   ping server.example.com
   curl -v https://server.example.com
   ```

2. **配置错误**
   - 检查服务器配置
   - 验证用户订阅有效

3. **网络权限不足**
   - Android: 检查 VPN 权限
   - Linux: 设置 CAP_NET_ADMIN
   - macOS: 确认系统扩展已批准

### Android: VPN 权限被拒绝

**解决方法:**

1. 进入系统设置 → 应用 → JinGo
2. 清除应用数据
3. 重新打开应用并授权 VPN 权限

### Linux: TUN 设备创建失败

**错误信息:**
```
Failed to create TUN device: Operation not permitted
```

**解决方法:**

```bash
# 设置 CAP_NET_ADMIN 权限
sudo setcap cap_net_admin+eip /path/to/JinGo

# 验证
getcap /path/to/JinGo
# 应显示: /path/to/JinGo cap_net_admin=eip
```

### macOS: 系统扩展被阻止

**解决方法:**

1. 打开系统偏好设置 → 安全性与隐私
2. 点击 "允许" 来自开发者的系统扩展
3. 可能需要重启电脑

### Windows: WinTun 驱动安装失败

**解决方法:**

1. 以管理员身份运行应用
2. 手动安装 WinTun 驱动：
```powershell
# 下载 WinTun
Invoke-WebRequest -Uri "https://www.wintun.net/builds/wintun-0.14.1.zip" -OutFile wintun.zip

# 解压并安装
Expand-Archive wintun.zip
# 复制对应架构的 wintun.dll 到系统目录
```

## 网络问题

### API 请求失败

**错误信息:**
```
Network error: Connection refused
API error: 401 Unauthorized
```

**排查步骤:**

1. 检查网络连接
2. 验证 API 服务器地址
3. 检查认证 token
4. 查看详细日志：
```bash
QT_LOGGING_RULES="JinGo.network.debug=true" ./JinGo
```

### SSL 证书错误

**错误信息:**
```
SSL handshake failed
Certificate verification failed
```

**解决方法:**

1. 检查系统时间是否正确
2. 更新系统 CA 证书
3. 检查服务器证书有效性

### DNS 解析失败

**解决方法:**

1. 检查 DNS 服务器配置
2. 尝试使用 IP 直连
3. 检查 hosts 文件

## UI 问题

### QML 加载失败

**错误信息:**
```
QML Error: Cannot load module
```

**解决方法:**

1. 检查 Qt QML 模块是否安装
2. 设置 QML 导入路径：
```bash
export QML2_IMPORT_PATH=/path/to/Qt/6.10.0/gcc_64/qml
```

### 字体显示异常

**解决方法:**

1. 安装缺失的字体
2. 设置回退字体：
```qml
font.family: "Noto Sans, sans-serif"
```

### 高 DPI 显示问题

**解决方法:**

```bash
# 设置缩放因子
export QT_SCALE_FACTOR=1.5

# 或自动检测
export QT_AUTO_SCREEN_SCALE_FACTOR=1
```

### Wayland 显示问题

**解决方法:**

```bash
# 强制使用 X11
QT_QPA_PLATFORM=xcb ./JinGo

# 或强制使用 Wayland
QT_QPA_PLATFORM=wayland ./JinGo
```

## 数据问题

### 数据库损坏

**错误信息:**
```
Database error: file is not a database
```

**解决方法:**

1. 备份现有数据
2. 删除数据库文件重新创建：
```bash
# Linux
rm ~/.local/share/JinGo/jingo.db

# macOS
rm ~/Library/Application\ Support/JinGo/jingo.db

# Windows
del %APPDATA%\JinGo\jingo.db
```

### 缓存问题

**解决方法:**

清理应用缓存：
```bash
# Linux
rm -rf ~/.cache/JinGo/

# macOS
rm -rf ~/Library/Caches/JinGo/

# Windows
rmdir /s %LOCALAPPDATA%\JinGo\cache
```

### 配置丢失

**解决方法:**

1. 检查配置文件是否存在
2. 从备份恢复
3. 重新配置应用

## 日志和调试

### 启用详细日志

```bash
# 全部调试日志
QT_LOGGING_RULES="*.debug=true" ./JinGo

# 特定模块日志
QT_LOGGING_RULES="JinGo.vpn.debug=true;JinGo.network.debug=true" ./JinGo

# Android logcat
adb logcat -s JinGo:V SuperRay-JNI:V Qt:W
```

### 日志文件位置

| 平台 | 位置 |
|------|------|
| Linux | `~/.local/share/JinGo/logs/` |
| macOS | `~/Library/Logs/JinGo/` |
| Windows | `%APPDATA%\JinGo\logs\` |
| Android | `/sdcard/Android/data/com.jingo.vpn/files/logs/` |

### 收集诊断信息

```bash
# 系统信息
uname -a
cat /etc/os-release

# Qt 版本
qmake --version

# 应用版本
./JinGo --version

# 依赖库
ldd ./JinGo | grep -E "Qt|ssl|crypto"

# 网络状态
ip addr
ip route
cat /etc/resolv.conf
```

## 性能问题

### 高 CPU 使用率

**排查步骤:**

1. 检查 Xray 进程
2. 检查是否有循环重连
3. 查看日志确认原因

### 内存泄漏

**排查步骤:**

1. 使用 valgrind 检测：
```bash
valgrind --leak-check=full ./JinGo
```

2. 使用 Qt Creator Profiler

### 启动缓慢

**优化方法:**

1. 减少启动时加载的数据
2. 使用 Release 模式编译
3. 启用 QML 编译缓存

## 平台特定问题

### Android

| 问题 | 解决方法 |
|------|----------|
| 后台被杀 | 添加到电池优化白名单 |
| 通知不显示 | 检查通知权限 |
| 无法安装 | 启用未知来源 |

### iOS

| 问题 | 解决方法 |
|------|----------|
| VPN 配置失败 | 检查 Network Extension 权限 |
| 后台断开 | 检查后台刷新设置 |
| 证书错误 | 重新签名应用 |

### macOS

| 问题 | 解决方法 |
|------|----------|
| 系统扩展被阻止 | 在安全设置中允许 |
| 公证失败 | 检查 notarization 配置 |
| Keychain 访问拒绝 | 重置 Keychain 权限 |

### Windows

| 问题 | 解决方法 |
|------|----------|
| DLL 缺失 | 安装 VC++ Redistributable |
| 驱动安装失败 | 以管理员运行 |
| 防火墙阻止 | 添加防火墙例外 |

### Linux

| 问题 | 解决方法 |
|------|----------|
| 权限不足 | 设置 CAP_NET_ADMIN |
| 库找不到 | 设置 LD_LIBRARY_PATH |
| 显示问题 | 设置 QT_QPA_PLATFORM |

## 获取帮助

如果以上方法无法解决问题：

1. 收集完整日志
2. 记录重现步骤
3. 提供系统信息
4. 联系技术支持

## 相关文档

- [构建指南](02_BUILD_GUIDE.md)
- [开发指南](03_DEVELOPMENT.md)
- [架构说明](01_ARCHITECTURE.md)
