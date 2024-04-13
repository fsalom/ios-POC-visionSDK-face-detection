import SwiftUI
import AVFoundation

struct Preview: UIViewControllerRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    let gravity: AVLayerVideoGravity
    var drawings: Binding<[CAShapeLayer]>

    init(
        session: AVCaptureSession,
        gravity: AVLayerVideoGravity,
        drawings: Binding<[CAShapeLayer]>
    ) {
        self.gravity = gravity
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        self.drawings = drawings
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        previewLayer.videoGravity = gravity
        uiViewController.view.layer.addSublayer(previewLayer)

        previewLayer.frame = uiViewController.view.bounds
        drawings.forEach { faceBoundingBox in
            uiViewController.view.layer.addSublayer(faceBoundingBox.wrappedValue)
        }
        print("updated")
    }

    func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: ()) {
        previewLayer.removeFromSuperlayer()
    }
}
