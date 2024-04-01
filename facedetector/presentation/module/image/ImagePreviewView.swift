//
//  ImagePreviewView.swift
//  facedetector
//
//  Created by Fernando Salom Carratala on 28/3/24.
//

import Foundation
import SwiftUI
import Vision


struct ImagePreviewView: View {
    @ObservedObject var viewModel = ImagePreviewViewModel()
    @State var isShowPicker = false
    @State var image: UIImage?

    var body: some View {
        VStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay(
                        GeometryReader { reader in
                            ForEach(viewModel.faces) { face in
                                Rectangle()
                                    .path(in: CGRect(x: face.observation.boundingBox.origin.y * reader.size.width,
                                                     y: face.observation.boundingBox.origin.x * reader.size.height,
                                                     width: face.observation.boundingBox.width * reader.size.width,
                                                     height: face.observation.boundingBox.height * reader.size.height))
                                    .stroke(Color.red, lineWidth: 2.0)
                            }
                        }
                    ).task {
                        await viewModel.detectFace(this: image)
                    }
            }
            Button(action: {
                isShowPicker = true
            }, label: {
                if isShowPicker {
                    ProgressView()
                } else {
                    Text("Seleccionar imagen")
                        .foregroundStyle(.white)
                }
            }).sheet(isPresented: $isShowPicker) {
                ImagePicker(image: $image)
            }
            .background(Color.blue)
            .buttonStyle(.bordered)
        }
    }


    func deNormalize(_ rect: CGRect, _ geometry: GeometryProxy) -> CGRect {
        return VNImageRectForNormalizedRect(rect, Int(geometry.size.width), Int(geometry.size.height))
    }
    func getRect(for boundingBox: CGRect, in geometryReader: GeometryProxy) -> CGRect {
        CGRect(
            x: boundingBox.minX * geometryReader.size.width,
            y: (1 - boundingBox.maxY) * geometryReader.size.height,
            width: boundingBox.width * geometryReader.size.width,
            height: boundingBox.height * geometryReader.size.height)
    }
}


