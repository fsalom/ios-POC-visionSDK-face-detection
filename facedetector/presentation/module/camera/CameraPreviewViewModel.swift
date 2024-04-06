//
//  CameraPreviewViewModel.swift
//  facedetector
//
//  Created by Fernando Salom Carratala on 6/4/24.
//

import Foundation
import AVFoundation

class CameraPreviewViewModel: ObservableObject {
    let session: AVCaptureSession

    init() {
        self.session = AVCaptureSession()

        Task(priority: .background) {
            switch await AuthorizationChecker.checkCaptureAuthorizationStatus() {
            case .permitted:
                try session
                    .addMovieInput()
                    .addMovieFileOutput()
                    .startRunning()

            case .notPermitted:
                break
            }
        }
    }
}

extension AVCaptureSession {
    var movieFileOutput: AVCaptureMovieFileOutput? {
        let output = self.outputs.first as? AVCaptureMovieFileOutput

        return output
    }

    func addMovieInput() throws -> Self {
        // Add video input
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
            // return itself if output is already set
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
