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
            Button("Seleccionar imagen") {
                isShowPicker = true
            }.sheet(isPresented: $isShowPicker) {
                ImagePicker(image: $image)
            }
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

struct ImagePicker: UIViewControllerRepresentable {

    @Environment(\.presentationMode)
    var presentationMode

    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        @Binding var presentationMode: PresentationMode
        @Binding var image: UIImage?

        init(presentationMode: Binding<PresentationMode>, image: Binding<UIImage?>) {
            _presentationMode = presentationMode
            _image = image
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            presentationMode.dismiss()

        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            presentationMode.dismiss()
        }

    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentationMode: presentationMode, image: $image)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<ImagePicker>) {

    }

}


