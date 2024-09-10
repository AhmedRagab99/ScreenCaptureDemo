//
//  ScreenCaptureManger.swift
//  ScreenCaptureDemo
//
//  Created by Ahmed Ragab on 25/08/2024.
//

import SwiftUI

struct MaterialView: NSViewRepresentable {
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
