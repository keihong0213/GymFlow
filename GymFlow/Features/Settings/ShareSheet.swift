//
//  ShareSheet.swift
//  Kintore (internal module name: GymFlow)
//
//  Copyright © 2026 Keihong.
//
//  Licensed under the MIT License. See LICENSE in the project root.
//

import SwiftUI
import UIKit

struct ShareableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
