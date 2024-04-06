//
//  VideoError.swift
//  facedetector
//
//  Created by Fernando Salom Carratala on 6/4/24.
//

import Foundation

enum DeviceError: Error {
    case unableToSetInput
    case unableToSetOutput
}
enum VideoError: Error {
    case device(reason: DeviceError)
}
