//
//  CameraPreviewViewModel.swift
//  facedetector
//
//  Created by Fernando Salom Carratala on 6/4/24.
//

import Foundation
import AVFoundation
import Photos
import Vision
import UIKit
import SwiftUI

class CameraPreviewViewModel: NSObject, ObservableObject {
    let session: AVCaptureSession
    private let videoDataOutput = AVCaptureVideoDataOutput()

    @Published var preview: Preview?
    @Published var faces: [Face] = []
    @State var drawings: [CAShapeLayer] = []

    override init() {
        self.session = AVCaptureSession()

        super.init()
        Task(priority: .background) {
            switch await AuthorizationChecker.checkCaptureAuthorizationStatus() {
            case .permitted:
                try session
                    .addMovieInput()
                    .addMovieFileOutput()
                    .startRunning()

                getCameraFrames()
                DispatchQueue.main.async {
                    self.preview = Preview(session: self.session, gravity: .resizeAspectFill, drawings: self.$drawings)
                }

            case .notPermitted:
                break
            }
        }

    }

    func startRecording() {
        guard let output = session.movieFileOutput else {
            return
        }

        guard
            let directoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else {
            return
        }

        let fileName = UUID().uuidString
        let filePath = directoryPath
            .appendingPathComponent(fileName)
            .appendingPathExtension("mp4")

        output.startRecording(to: filePath, recordingDelegate: self)
    }

    func stopRecording() {
        guard let output = session.movieFileOutput else {
            return
        }

        output.stopRecording()
    }

    private func getCameraFrames() {
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))

        session.addOutput(videoDataOutput)

        guard let connection = videoDataOutput.connection(with: .video) else {
            return
        }

    }

    private func detectFace(image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { vnRequest, error in
            DispatchQueue.main.async {
                if let results = vnRequest.results as? [VNFaceObservation], results.count > 0 {
                    print("✅ Detected \(results.count) faces!")
                    //self.faces = results.map({ Face(observation: $0) })
                    self.handleFaceDetectionResults(observedFaces: results)
                } else {
                    print("❌ No face was detected")
                    self.faces.removeAll()
                }
            }
        }

        let imageResultHandler = VNImageRequestHandler(cvPixelBuffer: image,
                                                       orientation: .rightMirrored,
                                                       options: [:])
        try? imageResultHandler.perform([faceDetectionRequest])
    }

    private func handleFaceDetectionResults(observedFaces: [VNFaceObservation]) {
        clearDrawings()

        // Create the boxes
        let facesBoundingBoxes: [CAShapeLayer] = observedFaces.map({ (observedFace: VNFaceObservation) -> CAShapeLayer in
            let cgRect = preview?.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)

            let faceBoundingBoxOnScreen = cgRect
            let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen!, transform: nil)
            let faceBoundingBoxShape = CAShapeLayer()

            // Set properties of the box shape
            faceBoundingBoxShape.path = faceBoundingBoxPath
            faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
            faceBoundingBoxShape.strokeColor = UIColor.green.cgColor

            return faceBoundingBoxShape
        })

        drawings = facesBoundingBoxes
    }

    private func clearDrawings() {
        //preview.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
    }

    func calculateCGRect(with face: Face, and reader: GeometryProxy) -> CGRect {
        print("---------------------")
        print(reader.size.width)
        print(reader.size.height)
        print(face.observation.boundingBox.minX)
        print(face.observation.boundingBox.minY)
        print("-----------FACE-----------")

        let boundingBox = face.observation.boundingBox
        let size = CGSize(width: boundingBox.width * reader.size.width,
                          height: boundingBox.height * reader.size.height)
        let origin = CGPoint(x: boundingBox.minX * reader.size.width,
                             y: (1 - boundingBox.minY)
                             * reader.size.height - size.height)
        print(origin)
        print(size)
        print("-----------CGRECT-----------")
        return CGRect(origin: origin,
                      size: size)
    }
}

extension CameraPreviewViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("Unable to get image from the sample buffer")
            return
        }
        detectFace(image: frame)
    }

}

extension CameraPreviewViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

        Task {
            guard
                case .authorized = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            else {
                return
            }

            let library = PHPhotoLibrary.shared()
            let album = try getAlbum(name: "YOUR_ALBUM_NAME", in: library)
            try await add(video: outputFileURL, to: album, library)
        }
    }
}

extension AVCaptureSession {
    var movieFileOutput: AVCaptureMovieFileOutput? {
        let output = self.outputs.first as? AVCaptureMovieFileOutput

        return output
    }

    func addMovieInput() throws -> Self {
        guard let videoDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            throw VideoError.device(reason: .unableToSetInput)
        }

        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        guard self.canAddInput(videoInput) else {
            throw VideoError.device(reason: .unableToSetInput)
        }

        self.addInput(videoInput)

        return self
    }

    func addMovieFileOutput() throws -> Self {
        guard self.movieFileOutput == nil else {
            return self
        }

        let fileOutput = AVCaptureMovieFileOutput()
        guard self.canAddOutput(fileOutput) else {
            throw VideoError.device(reason: .unableToSetOutput)
        }

        self.addOutput(fileOutput)

        return self
    }
}

extension CameraPreviewViewModel {
    func getAlbum(name: String, in photoLibrary: PHPhotoLibrary) throws -> PHAssetCollection {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)

        let collection = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .any, options: fetchOptions
        )
        if let album = collection.firstObject {
            return album
        } else {
            try createAlbum(name: name, in: photoLibrary)
            return try getAlbum(name: name, in: photoLibrary)
        }
    }

    func createAlbum(name: String, in photoLibrary: PHPhotoLibrary) throws {
        try photoLibrary.performChangesAndWait {
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
        }
    }

    func add(video path: URL, to album: PHAssetCollection, _ photoLibrary: PHPhotoLibrary) async throws -> Void {
        return try await photoLibrary.performChanges {
            guard
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: path),
                let placeholder = assetChangeRequest.placeholderForCreatedAsset,
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            else {
                print("Cannot access to album")
                return
            }

            let enumeration = NSArray(object: placeholder)
            albumChangeRequest.addAssets(enumeration)
        }
    }
}
