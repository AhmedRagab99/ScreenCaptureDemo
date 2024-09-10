//
//  ContentView.swift
//  ScreenCaptureDemo
//
//  Created by Ahmed Ragab on 25/08/2024.
//

import SwiftUI
import Combine
import AVFoundation
import ScreenCaptureKit
import AVKit
struct CapturedFrame {
    static var invalid: CapturedFrame {
        
            CapturedFrame(surface: nil, contentRect: .zero, contentScale: 0, scaleFactor: 0)
        
    }

    let surface: IOSurface?
    let contentRect: CGRect
    let contentScale: CGFloat
    let scaleFactor: CGFloat
    var size: CGSize { contentRect.size }
}

enum CaptureType {
    case display
    case window
}




extension SCWindow {
    var displayName: String {
        switch (owningApplication, title) {
        case (.some(let application), .some(let title)):
            return "\(application.applicationName): \(title)"
        case (.none, .some(let title)):
            return title
        case (.some(let application), .none):
            return "\(application.applicationName): \(windowID)"
        default:
            return ""
        }
    }
}

extension SCDisplay {
    var displayName: String {
        "Display: \(width) x \(height)"
    }
}

struct ContentView: View {
    @StateObject var screenRecorder = ScreenCaptureManger()
    @State var userStopped = false
    @State var disableInput = false
    @State var isUnauthorized = false
    var body: some View {
        HSplitView {
            ConfigurationView(screenRecorder: screenRecorder, userStopped: $userStopped)
                .frame(minWidth: 280, maxWidth: 280)
                .disabled(disableInput)
            screenRecorder.capturePreview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(screenRecorder.contentSize, contentMode: .fit)
                .padding(8)
                .overlay {
                    if userStopped {
                        Image(systemName: "nosign")
                            .font(.system(size: 250, weight: .bold))
                            .foregroundColor(Color(white: 0.3, opacity: 1.0))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(white: 0.0, opacity: 0.5))
                    }
                }
        }
        .overlay {
            if isUnauthorized {
                VStack() {
                    Spacer()
                    VStack {
                        Text("No screen recording permission.")
                            .font(.largeTitle)
                            .padding(.top)
                        Text("Open System Settings and go to Privacy & Security > Screen Recording to grant permission.")
                            .font(.title2)
                            .padding(.bottom)
                    }
                    .frame(maxWidth: .infinity)
                    .background(.red)
                    
                }
            }
        }
        .navigationTitle("Screen Capture Sample")
        
    }
}

#Preview {
    ContentView()
}
