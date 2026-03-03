import AVFoundation
import SwiftUI

struct BarcodeScannerView: View {
    let onScan: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var permissionDenied = false

    var body: some View {
        ZStack(alignment: .bottom) {
            BarcodeScannerRepresentable { code in
                onScan(code)
                dismiss()
            } permissionDenied: {
                permissionDenied = true
            }
            .ignoresSafeArea()

            Text(permissionDenied ? "Camera permission is required for barcode scanning." : "Align a UPC or EAN barcode inside the frame.")
                .font(.subheadline.weight(.medium))
                .padding(16)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 30)
        }
    }
}

private struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    let onCode: (String) -> Void
    let permissionDenied: () -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onCode = onCode
        controller.onPermissionDenied = permissionDenied
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

private final class ScannerViewController: UIViewController, @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    var onPermissionDenied: (() -> Void)?

    private let session = AVCaptureSession()
    private var didEmitCode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        Task { await configure() }
    }

    private func configure() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted else {
            onPermissionDenied?()
            return
        }

        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        session.startRunning()
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !didEmitCode,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue else {
            return
        }

        didEmitCode = true
        session.stopRunning()
        onCode?(code)
    }
}
