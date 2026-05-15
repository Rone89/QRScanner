# QR Scanner iOS App

一款专业的 iOS 二维码扫描应用，采用 iOS 26 Liquid Glass 设计风格，支持智能识别支付宝、微信二维码。

## 功能特性

- **智能识别三种场景**
  - 支付宝二维码：直接跳转支付宝相关页面
  - 微信二维码：跳转微信扫一扫
  - 通用二维码：弹窗选择支付宝或微信

- **iOS 26 Liquid Glass 设计**
  - Ultra-thin material 玻璃态效果
  - 流畅的动画和现代 iOS 设计语言
  - 优雅的扫描框和角标指示器

- **完整的小组件支持**
  - 小尺寸小组件
  - 中等尺寸小组件
  - 大尺寸小组件
  - 锁屏小组件（圆形、矩形、内联）

## 技术栈

- Swift 6.0
- SwiftUI
- AVFoundation
- WidgetKit
- iOS 18.0+ 部署目标

## 项目结构

```
QRScanner/
├── QRScannerApp.swift          # 应用入口
├── ContentView.swift            # 主界面
├── QRScannerView.swift          # 相机扫描视图
├── QRCodeDetector.swift         # 二维码类型检测
├── WidgetExtension.swift        # 小组件实现
├── Info.plist                   # 配置文件
└── Assets.xcassets/             # 资源文件
    └── AppIcon.appiconset/      # 应用图标
```

## 构建说明

### 本地构建

1. 在 Mac 上使用 Xcode 16+ 打开 `QRScanner.xcodeproj`
2. 选择模拟器或真机设备
3. 按 ⌘R 构建并运行

### GitHub Actions 自动构建

本项目配置了 GitHub Actions 自动构建流程，每次推送代码时会自动：
- 构建未签名的 IPA 文件
- 创建 GitHub Release
- 上传 IPA 到 Release

## 许可证

MIT License
