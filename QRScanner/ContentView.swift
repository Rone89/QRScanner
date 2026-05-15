import SwiftUI
@preconcurrency import AVFoundation

// MARK: - Root View (directly shows camera scanner)

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var showPaymentSelection = false
    @State private var scannedCode: String = ""

    var body: some View {
        ZStack {
            // Camera preview fills the entire screen
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()

            // Scanning UI overlay
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Spacer()

                // Scanning frame with Liquid Glass
                scanningFrame
                    .padding(.bottom, 32)

                // Hint text
                hintLabel
                    .padding(.bottom, 120)
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

    // MARK: - Scanning Frame with iOS 26 Liquid Glass

    @ViewBuilder
    private var scanningFrame: some View {
        if #available(iOS 26, *) {
            RoundedRectangle(cornerRadius: 24)
                .fill(.clear)
                .frame(width: 260, height: 260)
                .glassEffect(.regular, in: .rect(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.7), lineWidth: 2)
                )
                .overlay(alignment: .topLeading) {
                    CornerIndicator()
                        .glassEffect(.regular.tint(.white), in: .rect(cornerRadius: 3))
                }
                .overlay(alignment: .topTrailing) {
                    CornerIndicator()
                        .rotationEffect(.degrees(90))
                        .glassEffect(.regular.tint(.white), in: .rect(cornerRadius: 3))
                }
                .overlay(alignment: .bottomLeading) {
                    CornerIndicator()
                        .rotationEffect(.degrees(-90))
                        .glassEffect(.regular.tint(.white), in: .rect(cornerRadius: 3))
                }
                .overlay(alignment: .bottomTrailing) {
                    CornerIndicator()
                        .rotationEffect(.degrees(180))
                        .glassEffect(.regular.tint(.white), in: .rect(cornerRadius: 3))
                }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .frame(width: 260, height: 260)

                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.5), lineWidth: 2)
                    .frame(width: 260, height: 260)
            }
            .overlay(alignment: .topLeading) {
                CornerIndicator()
            }
            .overlay(alignment: .topTrailing) {
                CornerIndicator()
                    .rotationEffect(.degrees(90))
            }
            .overlay(alignment: .bottomLeading) {
                CornerIndicator()
                    .rotationEffect(.degrees(-90))
            }
            .overlay(alignment: .bottomTrailing) {
                CornerIndicator()
                    .rotationEffect(.degrees(180))
            }
        }
    }

    // MARK: - Hint Label with Liquid Glass

    @ViewBuilder
    private var hintLabel: some View {
        Text("将二维码放入框内")
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background {
                if #available(iOS 26, *) {
                    Capsule()
                        .glassEffect(.regular, in: .capsule)
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
            }
    }

    // MARK: - QR Code Handling

    private func handleScannedCode(_ code: String) {
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
            // Stop camera and show payment selection dialog
            scannedCode = code
            cameraManager.stopSession()
            showPaymentSelection = true
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

// MARK: - Corner Indicator

struct CornerIndicator: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(.white)
                .frame(width: 3, height: 24)
            Rectangle()
                .fill(.white)
                .frame(width: 24, height: 3)
        }
    }
}