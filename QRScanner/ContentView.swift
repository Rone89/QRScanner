import SwiftUI
@preconcurrency import AVFoundation

// MARK: - Root View

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var showPaymentSelection = false
    @State private var scannedCode: String = ""
    @State private var showGlowAnimation = false
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            // Camera preview fills the entire screen
            CameraPreview(session: cameraManager.session, cameraManager: cameraManager)
                .ignoresSafeArea()

            // iOS native-style QR bounding box — tracks actual QR position
            if let rect = cameraManager.detectedRect {
                QRBoundingBox(rect: rect)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }

            // Apple Intelligence-style rotating edge glow on launch
            if showGlowAnimation {
                IntelligenceGlow(opacity: glowOpacity)
                    .transition(.opacity)
            }
        }
        .confirmationDialog("选择支付方式", isPresented: $showPaymentSelection, titleVisibility: .visible) {
            Button("支付宝") {
                openAlipay(scannedCode)
                resumeScanning()
            }
            Button("微信") {
                openWeChat()
                resumeScanning()
            }
            Button("取消", role: .cancel) {
                resumeScanning()
            }
        } message: {
            Text("请选择使用哪个应用打开此二维码")
        }
        .onAppear {
            cameraManager.startSession()
            cameraManager.onCodeDetected = { code in
                handleScannedCode(code)
            }
            // Play the Apple Intelligence glow on appear
            withAnimation(.easeOut(duration: 0.6)) {
                showGlowAnimation = true
                glowOpacity = 1
            }
            // Fade out after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.8)) {
                    glowOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showGlowAnimation = false
                }
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }

    // MARK: - QR Code Handling

    private func handleScannedCode(_ code: String) {
        let detector = QRCodeDetector()
        let result = detector.detectQRCodeType(code)

        // Brief delay so user can see the bounding box
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            switch result {
            case .alipay(let url):
                if let url = URL(string: url) {
                    UIApplication.shared.open(url)
                }
                resumeScanning()

            case .wechat:
                if let url = URL(string: "weixin://scanqrcode") {
                    UIApplication.shared.open(url)
                }
                resumeScanning()

            case .generic:
                scannedCode = code
                cameraManager.stopSession()
                showPaymentSelection = true
            }
        }
    }

    private func resumeScanning() {
        showPaymentSelection = false
        cameraManager.startSession()
    }

    private func openAlipay(_ code: String) {
        let encoded = code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "alipays://platformapi/startapp?saId=10000007&qrcode=\(encoded)"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }

    private func openWeChat() {
        if let url = URL(string: "weixin://scanqrcode") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - iOS Native-Style QR Bounding Box

/// Renders a yellow highlight box that tracks the actual QR code position,
/// matching the iOS Camera app's native QR detection animation style.
struct QRBoundingBox: View {
    let rect: CGRect // normalized coordinates (0..1)

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width
            let boxRect = CGRect(
                x: rect.origin.x * scale,
                y: rect.origin.y * scale,
                width: rect.size.width * scale,
                height: rect.size.height * scale
            )

            // Yellow rounded rect with glow — matches iOS camera QR highlight
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow, lineWidth: 3)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.yellow.opacity(0.12))
                )
                .shadow(color: .yellow.opacity(0.6), radius: 12, x: 0, y: 0)
                .frame(width: boxRect.width, height: boxRect.height)
                .position(x: boxRect.midX, y: boxRect.midY)
        }
    }
}

// MARK: - Apple Intelligence Style Rotating Edge Glow

/// A rotating multi-color gradient glow around the screen edges,
/// styled after the iOS 26 Apple Intelligence animation.
struct IntelligenceGlow: View {
    let opacity: Double
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Primary rotating gradient
            RoundedRectangle(cornerRadius: 40)
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            Color(red: 0.2, green: 0.4, blue: 1.0),
                            Color(red: 0.5, green: 0.3, blue: 0.9),
                            Color(red: 0.95, green: 0.3, blue: 0.5),
                            Color(red: 1.0, green: 0.6, blue: 0.2),
                            Color(red: 0.2, green: 0.4, blue: 1.0),
                        ],
                        center: .center
                    ),
                    lineWidth: 4
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .blur(radius: 18)
                .opacity(opacity * 0.5)
                .padding(6)
                .ignoresSafeArea()

            // Secondary reverse-rotating glow for depth
            RoundedRectangle(cornerRadius: 40)
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            .white.opacity(0.0),
                            .white.opacity(0.2),
                            .white.opacity(0.25),
                            .white.opacity(0.0),
                        ],
                        center: .center
                    ),
                    lineWidth: 8
                )
                .rotationEffect(.degrees(isAnimating ? -180 : 0))
                .blur(radius: 28)
                .opacity(opacity * 0.35)
                .padding(12)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(
                .linear(duration: 3.0)
                .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}
