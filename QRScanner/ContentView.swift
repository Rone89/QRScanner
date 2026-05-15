import SwiftUI
@preconcurrency import AVFoundation

// MARK: - Root View (full-screen camera scanner with zoom/focus/detection animation)

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var showPaymentSelection = false
    @State private var scannedCode: String = ""
    @State private var detectedAnimation = false

    var body: some View {
        ZStack {
            // Full-screen camera preview with tap-to-focus and pinch-to-zoom
            CameraPreview(session: cameraManager.session, cameraManager: cameraManager)
                .ignoresSafeArea()

            // Detection animation overlay
            if detectedAnimation {
                detectionOverlay
                    .transition(.opacity.combined(with: .scale))
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
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }

    // MARK: - Detection Animation

    @ViewBuilder
    private var detectionOverlay: some View {
        ZStack {
            // Expanding green ripple ring
            Circle()
                .stroke(Color.green, lineWidth: 4)
                .frame(width: 140, height: 140)
                .shadow(color: .green, radius: 12)
                .scaleEffect(detectedAnimation ? 1.8 : 0.3)
                .opacity(detectedAnimation ? 0.0 : 0.9)
                .animation(.easeOut(duration: 0.6).repeatCount(1, autoreverses: false), value: detectedAnimation)

            // Checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .background {
                    Circle()
                        .fill(.white)
                        .frame(width: 54, height: 54)
                }
                .shadow(color: .green.opacity(0.5), radius: 8)
                .scaleEffect(detectedAnimation ? 1.0 : 0.1)
                .opacity(detectedAnimation ? 1.0 : 0.0)
        }
    }

    // MARK: - QR Code Handling

    private func handleScannedCode(_ code: String) {
        // Trigger detection animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            detectedAnimation = true
        }

        // Brief delay for animation, then process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                detectedAnimation = false
            }

            let detector = QRCodeDetector()
            let result = detector.detectQRCodeType(code)

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
