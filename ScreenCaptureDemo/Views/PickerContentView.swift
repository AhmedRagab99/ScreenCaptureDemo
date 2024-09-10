//
//  PickerContentView.swift
//  ScreenCaptureDemo
//
//  Created by Ahmed Ragab on 10/09/2024.
//

import Foundation
import SwiftUI

struct PickerContentView {
    @ObservedObject var screenRecorder: ScreenCaptureManger
    @Binding var showPickerSettingsView: Bool
}

extension PickerContentView : View {
    var body: some View {
        Group {
            HeaderView("Content Picker")
            Toggle("Activate Picker", isOn: $screenRecorder.isPickerActive)
            Group {
                Button {
                    showPickerSettingsView = true
                } label: {
                    Image(systemName: "text.badge.plus")
                    Text("Picker Configuration")
                }
                Button {
                    screenRecorder.presentPicker()
                } label: {
                    Image(systemName: "sparkles.tv")
                    Text("Present Picker")
                }
            }
            .disabled(!screenRecorder.isPickerActive)
        }
    }
}


#Preview {
    PickerContentView(screenRecorder: ScreenCaptureManger(), showPickerSettingsView: .constant(true))
        .frame(width: 400)
        .padding()
}
