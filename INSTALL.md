# QRScanner 安装指南

## 获取 IPA

每次 GitHub Actions 构建完成后，IPA 文件可以在以下位置找到：

1. 打开仓库的 **Actions** 标签页
2. 点击最新的成功构建（绿色勾）
3. 在 Artifacts 区域下载 `QRScanner-unsigned.zip`
4. 解压后得到 `QRScanner.ipa`

或者如果创建了 Release，可以在 **Releases** 页面直接下载。

## 安装方式

> **注意**：由于应用未使用 Apple Developer 证书签名，无法通过 App Store 或直接双击安装。
> iOS 18+ 要求所有应用必须经过有效签名才能安装。以下是几种免费安装方案。

---

### 方案一：AltStore（推荐，免费）

AltStore 是最流行的侧载工具，使用你的免费 Apple ID 签名并安装应用。

**步骤：**

1. **电脑端安装 AltServer**
   - 访问 [altstore.io](https://altstore.io) 下载
   - Windows 需要安装 iCloud 和 iTunes（从微软商店或 Apple 官网）
   - macOS 可直接运行

2. **手机上安装 AltStore**
   - 用数据线连接 iPhone 到电脑
   - 在 AltServer 菜单栏图标中选择「Install AltStore」→ 选择你的 iPhone
   - 输入 Apple ID 和密码（仅用于签名，不会存储）
   - 安装完成后，在 iPhone **设置 → 通用 → VPN 与设备管理** 中信任 AltStore 的描述文件

3. **安装 QRScanner**
   - 将 `QRScanner.ipa` 传输到 iPhone（通过 AirDrop、文件 App 或 iCloud）
   - 在 iPhone 上打开 AltStore
   - 点击底部 **My Apps** → 右上角 **+** 号
   - 选择 QRScanner.ipa
   - 输入 Apple ID 密码
   - AltStore 会自动签名并安装

4. **注意事项**
   - 免费 Apple ID 每 7 天需要刷新一次（AltStore 会自动续签）
   - 最多同时安装 3 个侧载应用
   - 可以开启 AltStore 的「Background Refresh」让它在后台自动刷新

---

### 方案二：Sideloadly（Windows/macOS）

**步骤：**

1. 下载 [Sideloadly](https://sideloadly.io)
2. 用数据线连接 iPhone
3. 将 `QRScanner.ipa` 拖入 Sideloadly 窗口
4. 输入 Apple ID
5. 点击 **Start**
6. 安装完成后在 **设置 → 通用 → VPN 与设备管理** 中信任描述文件

---

### 方案三：SideStore（无线安装）

SideStore 是 AltStore 的开源替代，支持通过 WiFi 无线续签。

1. 访问 [sidestore.io](https://sidestore.io) 获取安装指南
2. 安装 SideStore 后，将 IPA 通过「Open in SideStore」导入

---

### 方案四：Apple Developer Program（$99/年）

如果你有 Apple Developer 账号（$99/年）：

1. 在 Xcode Organizer 中创建发布证书和描述文件
2. 将 GitHub Actions 的构建下载到本地
3. 用 `codesign` 重新签名：
   ```bash
   # 替换 YOUR_DISTRIBUTION_CERTIFICATE 为你的证书名称
   codesign --force --deep --sign "iPhone Distribution: YOUR_NAME" \
     --entitlements Path/To/QRScanner.entitlements \
     Payload/QRScanner.app
   
   # 重新打包 IPA
   rm -rf Payload/QRScanner.app/QRScanner.entitlements
   ditto -c -k --sequesterRsrc --keepParent Payload/QRScanner.app QRScanner-signed.ipa
   ```
4. 通过 Xcode Organizer 或 Apple Configurator 2 安装

---

## 常见问题

**Q: 安装时提示「无法安装」或「无法获取应用信息」？**
A: 这是正常的。免费 Apple ID 侧载的应用需要通过 AltStore/Sideloadly 等工具安装。直接双击 IPA 或通过「文件 App」安装会失败。

**Q: 安装后打开闪退？**
A: 请检查：
1. 是否在 **设置 → 通用 → VPN 与设备管理** 中信任了描述文件
2. 7 天续签期是否已过
3. 设备是否运行 iOS 18.0+

**Q: 安装后提示「未受信任的开发者」？**
A: 前往 **设置 → 通用 → VPN 与设备管理**，找到对应的开发者描述文件，点击「信任」。

**Q: 扫码后无法跳转支付宝/微信？**
A: 请确保手机上已安装对应的 App。首次跳转时 iOS 会弹出确认对话框。

**Q: IPA 文件只有几十 KB，正常吗？**
A: 完全正常。这是一个轻量级 SwiftUI 应用，编译后约 300KB，压缩成 IPA 后约 70KB。功能完整，包括：
   - AVFoundation 原生二维码扫描
   - 支付宝/微信/通用二维码智能识别
   - iOS 26 Liquid Glass 设计
   - 6 种锁屏小组件
   - Swift 6.0 并发安全

---

## 构建说明

如需本地构建：

1. 克隆仓库：`git clone https://github.com/你的用户名/QRScanner.git`
2. 用 Xcode 16+ 打开 `QRScanner.xcodeproj`
3. 选择 iOS 18.0+ 模拟器或真机运行
4. 如需导出 IPA：Product → Archive → Distribute App
