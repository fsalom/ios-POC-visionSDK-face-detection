//
//  Face.swift
//  facedetector
//
//  Created by Fernando Salom Carratala on 8/4/24.
//

import Foundation
import Vision

struct Face: Identifiable {
    var id: String = UUID().uuidString
    var observation: VNFaceObservation
}
