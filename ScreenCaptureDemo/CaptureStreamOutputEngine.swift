//
//  CaptureStreamOutputEngine.swift
//  ScreenCaptureDemo
//
//  Created by Ahmed Ragab on 10/09/2024.
//

import ScreenCaptureKit
import Foundation
import AVFoundation

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
