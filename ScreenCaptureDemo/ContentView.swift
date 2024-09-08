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
final class CaptureStreamOutputEngine: NSObject,SCStreamOutput,SCStreamDelegate {
    
    var pcmBufferHandler: ((AVAudioPCMBuffer) -> Void)?
    var capturedFrameHandler: ((CapturedFrame) -> Void)?
    
    
    // Store the  startCapture continuation, so you can cancel it if an error occurs.
    private var continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation?
    init(continuation: AsyncThrowingStream<CapturedFrame, Error>.Continuation? = nil) {
        self.continuation = continuation
    }
    
    func getContinuation() -> AsyncThrowingStream<CapturedFrame,Error>.Continuation? {
        return continuation
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard  sampleBuffer.isValid else { return }
        switch type {
        case .screen:
            guard let frame = createFrame(for: sampleBuffer) else { return }
            capturedFrameHandler?(frame)
        case .audio:
            // Process audio as an AVAudioPCMBuffer for level calculation.
            handleAudio(for: sampleBuffer)
        @unknown default:
            fatalError("Encountered unknown stream output type: \(type)")
        }
    }
    
   
    
    private func createFrame(for sampleBuffer: CMSampleBuffer) -> CapturedFrame? {
        // get the array of metadata from sample buffer
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo:Any]],
              let attachments = attachmentsArray.first else {
            return nil
        }
        
        // validate the status of the frame if not completed
        guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
        let status = SCFrameStatus(rawValue: statusRawValue),
              status == .complete else { return nil }
        
        // get the pixel buffer
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return nil}
        // get the iosurface
        guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer) else { return nil }
        let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)
        
        // Retrieve the content rectangle, scale, and scale factor.
        guard let contentRectDict = attachments[.contentRect],
              let contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary),
              let contentScale = attachments[.contentScale] as? CGFloat,
              let scaleFactor = attachments[.scaleFactor] as? CGFloat else { return nil }
        // Create a new frame with the relevant data.
        let frame = CapturedFrame(surface: surface,
                                  contentRect: contentRect,
                                  contentScale: contentScale,
                                  scaleFactor: scaleFactor)
        return frame

    }
    
    private func handleAudio(for buffer: CMSampleBuffer) -> Void? {
        try? buffer.withAudioBufferList(body: { audioBufferList, blockBuffer in
            guard let description = buffer.formatDescription?.audioStreamBasicDescription,
                  let format = AVAudioFormat(standardFormatWithSampleRate: description.mSampleRate,
                      channels:description.mChannelsPerFrame
                  ),
                  let sample = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: audioBufferList.unsafePointer)
            else { return }
            pcmBufferHandler?(sample)
        })
    }
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        continuation?.finish(throwing: error)
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
