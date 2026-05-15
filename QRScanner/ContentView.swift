import SwiftUI

struct ContentView: View {
    @State private var isScanning = false
    @State private var scannedCode: String?
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            // Background with Liquid Glass effect
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                        .padding(.top, 60)

                    Text("扫码")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)

                    Text("对准二维码自动识别")
                        .font(.system(size: 17))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.bottom, 40)

                Spacer()

                // Scan button with Liquid Glass effect
                Button(action: {
                    isScanning = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                        Text("开始扫码")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .fullScreenCover(isPresented: $isScanning) {
            QRScannerView(
                isPresented: $isScanning,
                onCodeScanned: { code in
                    handleScannedCode(code)
                }
            )
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func handleScannedCode(_ code: String) {
        scannedCode = code

        // Detect QR code type and route accordingly
        let detector = QRCodeDetector()
        let result = detector.detectQRCodeType(code)

        switch result {
        case .alipay(let url):
            // Open Alipay directly
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
            isScanning = false

        case .wechat:
            // Open WeChat scan
            if let url = URL(string: "weixin://scanqrcode") {
                UIApplication.shared.open(url)
            }
            isScanning = false

        case .generic:
            // Show selection dialog
            isScanning = false
            showPaymentSelection(for: code)
        }
    }

    private func showPaymentSelection(for code: String) {
        let alert = UIAlertController(
            title: "选择支付方式",
            message: "请选择使用哪个应用打开此二维码",
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "支付宝", style: .default) { _ in
            // Open in Alipay
            let alipayURL = "alipays://platformapi/startapp?saId=10000007&qrcode=\(code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            if let url = URL(string: alipayURL) {
                UIApplication.shared.open(url)
            }
        })

        alert.addAction(UIAlertAction(title: "微信", style: .default) { _ in
            // Open WeChat scan
            if let url = URL(string: "weixin://scanqrcode") {
                UIApplication.shared.open(url)
            }
        })

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

#Preview {
    ContentView()
}
