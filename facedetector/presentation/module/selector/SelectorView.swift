//
//  ContentView.swift
//  facedetector
//
//  Created by Fernando Salom Carratala on 26/3/24.
//

import SwiftUI

struct SelectorView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Tipos de captura")) {
                    NavigationLink {
                        ImagePreviewView()
                    } label: {
                        Text("Seleccionar desde carrete")
                    }
                    NavigationLink {
                        Text("Vídeo")
                    } label: {
                        Text("Seleccionar cámara")
                    }
                }
            }
        }
    }
}

#Preview {
    SelectorView()
}
