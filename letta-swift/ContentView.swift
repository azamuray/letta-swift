//
//  ContentView.swift
//  letta-swift
//
//  Created by Azamat on 1/17/26.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: letta_swiftDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(letta_swiftDocument()))
}
