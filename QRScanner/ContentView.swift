import SwiftUI
@preconcurrency import AVFoundation

// MARK: - Root View

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var showPaymentSelection = false
    @State private var scannedCode: String = ""
    @State private var showGlowAnimation = true

    var body: some View {
        ZStack {
            // Full-screen camera preview with tap-to-focus and pinch-to-zoom
            CameraPreview(session: cameraManager.session, cameraManager: cameraManager)
                .ignoresSafeArea()

            // Native-style QR code bounding box
            if let rect = cameraManager.detectedRect {
                QRBoundingBox(rect: rect)
            }

            // Apple Intelligence-style glow animation on launch
            if showGlowAnimation {
                IntelligenceGlow()
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
            // Start glow animation
            withAnimation(.easeOut(duration: 1.0)) {
                showGlowAnimation = true
            }
            // Fade out glow after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.8)) {
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

        // Brief delay for bounding box to show
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

// MARK: - iOS Native-style QR Bounding Box

struct QRBoundingBox: View {
    let rect: CGRect

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width
            let boxRect = CGRect(
                x: rect.origin.x * scale,
                y: rect.origin.y * scale,
                width: rect.size.width * scale,
                height: rect.size.height * scale
            )

            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.yellow, lineWidth: 3)
                .shadow(color: .yellow.opacity(0.5), radius: 10)
                .frame(width: boxRect.width, height: boxRect.height)
                .position(x: boxRect.midX, y: boxRect.midY)
                .transition(.opacity.animation(.easeInOut(duration: 0.15)))
        }
    }
}

// MARK: - Apple Intelligence Style Glow Animation

struct IntelligenceGlow: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Outer rotating gradient ring
            RoundedRectangle(cornerRadius: 40)
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            .blue, .purple, .pink, .orange, .blue
                        ],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .blur(radius: 16)
                .opacity(0.6)
                .padding(4)
                .ignoresSafeArea()

            // Inner glow
            RoundedRectangle(cornerRadius: 40)
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            .white.opacity(0.2), .clear, .white.opacity(0.15), .clear
                        ],
                        center: .center
                    ),
                    lineWidth: 6
                )
                .rotationEffect(.degrees(isAnimating ? -180 : 0))
                .blur(radius: 24)
                .padding(10)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
