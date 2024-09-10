//
//  ScreenCaptureManger.swift
//  ScreenCaptureDemo
//
//  Created by Ahmed Ragab on 25/08/2024.
//

import SwiftUI
import ScreenCaptureKit


struct ConfigurationView {
    private let sectionSpacing: CGFloat = 20
    private let verticalLabelSpacing: CGFloat = 8
    
    private let alignmentOffset: CGFloat = 10
    
    
    @ObservedObject var screenRecorder: ScreenCaptureManger
    @Binding var userStopped: Bool
    @State var showPickerSettingsView = false
}


extension ConfigurationView : View {
    var body: some View {
        VStack {
            Form {
                HeaderView("Video")
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
                
                
                Group {
                    VStack(alignment: .leading, spacing: verticalLabelSpacing) {
                        Text("Capture Type")
                        Picker("Capture", selection: $screenRecorder.captureType) {
                            Text("Display")
                                .tag(CaptureType.display)
                            Text("Window")
                                .tag(CaptureType.window)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: verticalLabelSpacing) {
                        Text("Screen Content")
                        switch screenRecorder.captureType {
                        case .display:
                            Picker("Display", selection: $screenRecorder.selectedDisplay) {
                                ForEach(screenRecorder.availableDisplays, id: \.self) { display in
                                    Text(display.displayName)
                                        .tag(SCDisplay?.some(display))
                                }
                            }
                            
                        case .window:
                            Picker("Window", selection: $screenRecorder.selectedWindow) {
                                ForEach(screenRecorder.availableWindows, id: \.self) { window in
                                    Text(window.displayName)
                                        .tag(SCWindow?.some(window))
                                }
                            }
                        }
                    }
                }
                .labelsHidden()
                
              
                            
                
                // Picker section.
                Spacer()
                    .frame(height: 20)
                PickerContentView(screenRecorder: screenRecorder, showPickerSettingsView: $showPickerSettingsView)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 60)
           
        }
        .task {
            await screenRecorder.start()
        }
        .background(MaterialView())
        .sheet(isPresented: $showPickerSettingsView) {
            PickerSettingsView(screenRecorder: screenRecorder)
                .frame(minWidth: 500.0, maxWidth: .infinity, minHeight: 600.0, maxHeight: .infinity)
                .padding(.top, 7)
                .padding(.leading, 25)
        }
    }
}






#Preview {
    ConfigurationView(screenRecorder: ScreenCaptureManger(), userStopped: .constant(false))
}
