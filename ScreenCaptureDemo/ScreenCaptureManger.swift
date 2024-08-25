//
//  ScreenCaptureManger.swift
//  ScreenCaptureDemo
//
//  Created by Ahmed Ragab on 25/08/2024.
//

import Foundation
import Combine
import ScreenCaptureKit
import AVKit
@MainActor
final class ScreenCaptureManger:  ObservableObject {
    @Published var availableWindows = [SCWindow]()
    @Published var availableApps:[SCRunningApplication] = []
    @Published var isAppExecluded: Bool = true {
        didSet { updateEngine() }
    }
    @Published var availableDisplays = [SCDisplay]()
    @Published var excludedApps = [SCRunningApplication]()
    @Published var selectedWindow: SCWindow? {
        didSet { updateEngine() }
    }
    @Published var selectedDisplay: SCDisplay?  {
        didSet { updateEngine() }
    }
    @Published var captureType: CaptureType = .display {
        didSet { updateEngine() }
    }
    
    @Published var isRunning = false

    @Published var isAudioCaptureEnabled: Bool = false
    @Published var isMicCaptureEnaled: Bool = false
    
    private let videoSampleBufferQueue = DispatchQueue(label: "com.example.apple-samplecode.VideoSampleBufferQueue")
    private let audioSampleBufferQueue = DispatchQueue(label: "com.example.apple-samplecode.AudioSampleBufferQueue")
    private let micSampleBufferQueue = DispatchQueue(label: "com.example.apple-samplecode.MicSampleBufferQueue")
    private(set) var stream: SCStream?
    
    
    private var scaleFactor: Int { Int(NSScreen.main?.backingScaleFactor ?? 2) }
    @Published var contentSize = CGSize(width: 1, height: 1)
    
    private var streamOutput: CaptureStreamOutputEngine?
    
    // Combine subscribers.
    private var subscriptions = Set<AnyCancellable>()

    /// A view that renders the screen content.
    lazy var capturePreview: CapturePreview = {
        CapturePreview()
    }()
    
    
    var canRecord: Bool {
        get async {
            do {
                // If the app doesn't have screen recording permission, this call generates an exception.
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                return true
            } catch {
                return false
            }
        }
    }
    
    private func updateEngine() {
        guard isRunning else { return }
        Task {
            let filter = getContentFilter()
            await update(configuration: getStreamConfiguration(), filter: getContentFilter())
//            setPickerUpdate(false)
        }
    }
    func start()  async {
        // Exit early if already running.
        guard !isRunning else { return }
        
        await self.startCaptureContent()
        Timer.publish(every: 3, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.startCaptureContent()
            }
        }
        .store(in: &subscriptions)
    }
    
    func startCaptureContent() async {
        do {
            
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            availableDisplays = content.displays
            availableWindows = content.windows
            availableApps = content.applications
            
            if selectedDisplay == nil {
                selectedDisplay = availableDisplays.first
            }
            if selectedWindow == nil {
                selectedWindow = availableWindows.first
            }
           let config = getStreamConfiguration()
           let filter =  getContentFilter()
           isRunning = true
            for try await frame in startCapture(using: config, filter: filter) {
                // update the capture preview
                capturePreview.updateFrame(frame)
                if contentSize != frame.size {
                    // Update the content size if it changed.
                    contentSize = frame.size
                }
            }
            
        } catch {
            print("capture error",error.localizedDescription)
            isRunning = false
            //fatalError("cannot start capture")
        }
    }
    
    func update(configuration: SCStreamConfiguration, filter: SCContentFilter) async {
        do {
            try await stream?.updateConfiguration(configuration)
            try await stream?.updateContentFilter(filter)
        } catch {
            print("Failed to update the stream session: \(String(describing: error))")
        }
    }
    
    func startCapture(using config: SCStreamConfiguration,filter: SCContentFilter) -> AsyncThrowingStream<CapturedFrame,Error> {
        
        return AsyncThrowingStream<CapturedFrame,Error> { (continuation: AsyncThrowingStream<CapturedFrame,Error>.Continuation)  in
          
            let streamOutput = CaptureStreamOutputEngine(continuation: continuation)
            self.streamOutput = streamOutput
            streamOutput.capturedFrameHandler = {
                continuation.yield($0)
            }
//            streamOutput.pcmBufferHandler = {
//                print("test here")
//            }
            
            do {
                stream = SCStream(filter: filter, configuration: config, delegate: streamOutput)
                
                // Add a stream output to capture screen content.
                try stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: videoSampleBufferQueue)
                try stream?.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: audioSampleBufferQueue)
//                try stream?.addStreamOutput(streamOutput, type: .microphone, sampleHandlerQueue: micSampleBufferQueue)
                stream?.startCapture()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
    
    func stopCapture() async {
        do {
            try await stream?.stopCapture()
            streamOutput?.getContinuation()?.finish()
        } catch {
            streamOutput?.getContinuation()?.finish(throwing: error)
        }
//        powerMeter.processSilence()
    }
    
    
    func getContentFilter() -> SCContentFilter {
        var filter: SCContentFilter
        switch captureType {
        case .display:
            guard let display = selectedDisplay else { fatalError("No display selected.") }
            var excludedApps = [SCRunningApplication]()
            // If a user chooses to exclude the app from the stream,
            // exclude it by matching its bundle identifier.
            if isAppExecluded {
                excludedApps = availableApps.filter { app in
                    Bundle.main.bundleIdentifier == app.bundleIdentifier
                }
            }
            // Create a content filter with excluded apps.
            filter = SCContentFilter(display: display,
                                     excludingApplications: excludedApps,
                                     exceptingWindows: [])
        case .window:
            guard let window = selectedWindow else { fatalError("No window selected.") }
            
            // Create a content filter that includes a single window.
            filter = SCContentFilter(desktopIndependentWindow: window)
        }
        return filter
    }
    func getStreamConfiguration() -> SCStreamConfiguration {
        let config = SCStreamConfiguration()
        config.captureResolution = .best
        config.capturesAudio = isAudioCaptureEnabled
        config.excludesCurrentProcessAudio = false
        
        if captureType == .display, let display = selectedDisplay {
            config.width = display.width * scaleFactor
            config.height = display.height * scaleFactor
        }
        
        if captureType == .window, let window = selectedWindow {
            config.width = Int(window.frame.width) * 2
            config.height = Int(window.frame.height) * 2
        }
        // Set the capture interval at 60 fps.
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
            // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        config.queueDepth = 5
        return config
    }
    
    private func filterWindows(_ windows: [SCWindow]) -> [SCWindow] {
        windows
        // Sort the windows by app name.
            .sorted { $0.owningApplication?.applicationName ?? "" < $1.owningApplication?.applicationName ?? "" }
        // Remove windows that don't have an associated .app bundle.
            .filter { $0.owningApplication != nil && $0.owningApplication?.applicationName != "" }
        // Remove this app's window from the list.
            .filter { $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier }
    }
    
}
