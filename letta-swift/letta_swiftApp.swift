//
//  letta_swiftApp.swift
//  letta-swift
//
//  Created by Azamat on 1/17/26.
//

import SwiftUI

@main
struct letta_swiftApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: letta_swiftDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
