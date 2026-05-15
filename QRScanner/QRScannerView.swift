import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @Binding var isPresented: Bool
    let onCodeScanned: (String) -> Void

    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()

            // Overlay with scanning frame
            VStack {
                // Top bar with close button
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.leading, 20)

                    Spacer()
                }
                .padding(.top, 60)

                Spacer()

                // Scanning frame with Liquid Glass effect
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.5), lineWidth: 3)
                        .frame(width: 280, height: 280)

                    // Corner indicators
                    VStack {
                        HStack {
                            CornerIndicator()
                            Spacer()
                            CornerIndicator()
                                .rotationEffect(.degrees(90))
                        }
                        Spacer()
                        HStack {
                            CornerIndicator()
                                .rotationEffect(.degrees(-90))
                            Spacer()
                            CornerIndicator()
                                .rotationEffect(.degrees(180))
                        }
                    }
                    .frame(width: 280, height: 280)
                }

                Text("将二维码放入框内")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.top, 32)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )

                Spacer()
            }
        }
        .onAppear {
            cameraManager.startSession()
            cameraManager.onCodeDetected = { code in
                onCodeScanned(code)
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

struct CornerIndicator: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(.white)
                .frame(width: 4, height: 30)
            Rectangle()
                .fill(.white)
                .frame(width: 30, height: 4)
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

@MainActor
class CameraManager: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    var onCodeDetected: ((String) -> Void)?
    private var hasDetectedCode = false

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            let input = try AVCaptureDeviceInput(device: device)

            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureMetadataOutput()

            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                output.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417]
            }
        } catch {
            print("Camera setup error: \(error)")
        }
    }

    func startSession() {
        hasDetectedCode = false
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let code = readableObject.stringValue else { return }

        Task { @MainActor in
            if !hasDetectedCode {
                hasDetectedCode = true
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                onCodeDetected?(code)
            }
        }
    }
}
