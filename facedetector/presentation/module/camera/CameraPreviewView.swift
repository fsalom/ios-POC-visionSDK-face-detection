import Foundation
import SwiftUI
import Vision
import AVFoundation


struct CameraPreviewView: View {
    @StateObject var viewModel = CameraPreviewViewModel()
    @State var isRecording = false

    var body: some View {
        ZStack {
            viewModel.preview?
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                Button(action: {
                    isRecording ? viewModel.stopRecording() : viewModel.startRecording()
                    isRecording.toggle()
                }) {
                    isRecording ? Text("Stop") : Text("Start")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
}


