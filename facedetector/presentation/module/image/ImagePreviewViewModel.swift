//
//  ImagePreviewViewModel.swift
//  facedetector
//
//  Created by Fernando Salom Carratala on 28/3/24.
//

import Foundation
import SwiftUI
import Vision

struct Face: Identifiable {
    var id: String = UUID().uuidString
    var observation: VNFaceObservation
}

class ImagePreviewViewModel: NSObject, ObservableObject {
    @Published var imageArray: [UIImage] = []
    @Published var errorMessage: String?
    @Published var faces: [Face] = []

    var drawings = [CAShapeLayer]()

    override init() { }

    func calculatePosition(for point: CGPoint, and reader: GeometryProxy) -> CGPoint {
        print(reader.size.width)
        print(reader.size.height)
        let x = (point.x * reader.size.width)
        let y = reader.size.height - (point.y * reader.size.height)
        return CGPoint(x: x, y: y)
    }

    func detectFace(this image: UIImage) async {
        await MainActor.run {
            self.faces.removeAll()
            let faceDetectionRequest = VNDetectFaceLandmarksRequest { vnRequest, error in
                if let results = vnRequest.results as? [VNFaceObservation], results.count > 0 {
                    self.faces = results.map({ Face(observation: $0) })
                    print(self.faces)
                }
            }
            guard let ciImage = CIImage(image: image) else { return }
            let imageResultHandler = VNImageRequestHandler(ciImage: ciImage)
            try? imageResultHandler.perform([faceDetectionRequest])
        }
    }

    func getValue(for value: CGFloat, for content: CGFloat) -> CGFloat {
        print("VALUE: \(value)")
        print("CONTENT: \(content)")
        print(value * content)
        return value * content
    }

}


