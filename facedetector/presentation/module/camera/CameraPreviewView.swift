import Foundation
import SwiftUI
import Vision
import AVFoundation


struct CameraPreviewView: View {
    @ObservedObject var viewModel = ImagePreviewViewModel()
    let session = AVCaptureSession()

    var body: some View {
        Text("x")
    }
}


