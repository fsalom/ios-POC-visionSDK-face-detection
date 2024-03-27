//
//  ContentView.swift
//  facedetector
//
//  Created by Fernando Salom Carratala on 26/3/24.
//

import SwiftUI

struct SelectorView: View {
    var body: some View {
        List {
            Section(header: Text("Tipos de captura")) {
                NavigationLink {
                    Text("camera")
                } label: {
                    Text("Cámara")                    
                }
                NavigationLink {
                    Text("Vídeo")
                } label: {
                    Text("Vídeo")
                }
            }
        }
    }
}

#Preview {
    SelectorView()
}
