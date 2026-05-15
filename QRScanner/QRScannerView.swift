import SwiftUI
@preconcurrency import AVFoundation

// MARK: - Camera Preview (UIViewRepresentable)

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer

        // Tap to focus
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

        // Pinch to zoom
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(cameraManager: cameraManager)
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        weak var cameraManager: CameraManager?
        private var initialZoom: CGFloat = 1.0

        init(cameraManager: CameraManager) {
            self.cameraManager = cameraManager
        }

        @MainActor @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let previewLayer = previewLayer,
                  let view = gesture.view,
                  let manager = cameraManager else { return }

            let location = gesture.location(in: view)
            let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: location)
            manager.focus(at: devicePoint)
        }

        @MainActor @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let manager = cameraManager else { return }

            switch gesture.state {
            case .began:
                initialZoom = manager.currentZoomFactor
            case .changed:
                let newZoom = initialZoom * gesture.scale
                manager.setZoomFactor(newZoom)
            default:
                break
            }
        }
    }
}

// MARK: - Camera Manager

@MainActor
class CameraManager: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    var onCodeDetected: ((String) -> Void)?
    private var hasDetectedCode = false
    private var cameraDevice: AVCaptureDevice?

    // Zoom state
    @Published var currentZoomFactor: CGFloat = 1.0
    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 5.0

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        cameraDevice = device

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

    func setZoomFactor(_ factor: CGFloat) {
        guard let device = cameraDevice else { return }
        let clampedFactor = min(max(factor, minZoom), maxZoom)
        currentZoomFactor = clampedFactor
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clampedFactor
            device.unlockForConfiguration()
        } catch {
            print("Zoom error: \(error)")
        }
    }

    func focus(at devicePoint: CGPoint) {
        guard let device = cameraDevice else { return }
        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = devicePoint
                device.exposureMode = .autoExpose
            }
            device.unlockForConfiguration()
        } catch {
            print("Focus error: \(error)")
        }
    }

    func startSession() {
        hasDetectedCode = false
        let captureSession = session
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
        }
    }

    func stopSession() {
        let captureSession = session
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.stopRunning()
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
