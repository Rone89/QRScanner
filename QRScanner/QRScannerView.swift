import SwiftUI
import AVFoundation

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

        // Tap to focus gesture
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        view.addGestureRecognizer(tapGesture)

        // Pinch to zoom gesture
        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
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

    // Camera device for zoom/focus
    private var cameraDevice: AVCaptureDevice?

    // Detected QR code bounding rect (normalized coordinates 0..1)
    @Published var detectedRect: CGRect? = nil

    // Zoom state
    @Published var currentZoomFactor: CGFloat = 1.0
    private let minZoom: CGFloat = 1.