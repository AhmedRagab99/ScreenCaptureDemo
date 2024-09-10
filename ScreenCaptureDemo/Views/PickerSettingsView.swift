/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for content picker configuration.
*/

import SwiftUI
import ScreenCaptureKit

struct PickerSettingsView {
    private let verticalLabelSpacing: CGFloat = 8
    @Environment(\.presentationMode) var presentation
    @ObservedObject var screenRecorder: ScreenCaptureManger
    @State private var bundleIDToExclude = ""
    @State private var maxStreamCount = 3
}

extension PickerSettingsView: View {
    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: verticalLabelSpacing) {

                // Picker property: Maximum stream count.
                HeaderView("Maximum Stream Count")
                TextField("Maximum Stream Count", value: $maxStreamCount, format: .number)
                    .frame(maxWidth: 150)
                    .onSubmit {
                        screenRecorder.maximumStramCount = maxStreamCount
                    }

                // Picker configuration: Allowed picking modes.
                HeaderView("Allowed Picking Modes")
                Toggle("Single Window", isOn: screenRecorder.updatePickingModesFor(.singleWindow))
                Toggle("Multiple Windows", isOn: screenRecorder.updatePickingModesFor(.multipleWindows))
                Toggle("Single Application", isOn: screenRecorder.updatePickingModesFor(.singleApplication))
                Toggle("Multiple Applications", isOn: screenRecorder.updatePickingModesFor(.multipleApplications))
                Toggle("Single Display", isOn: screenRecorder.updatePickingModesFor(.singleDisplay))

                // Picker configuration: Excluded Window IDs.
                HeaderView("Excluded Window IDs")
                Text("Select window below to exclude it:")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                List(screenRecorder.availableWindows, id: \.self, selection: $screenRecorder.excludedWindowIDsSelection) { window in
                    let windowID = Int(window.windowID)
                    var windowIsExcluded = screenRecorder.excludedWindowIDsSelection.contains(windowID)
                    Button {
                        if !windowIsExcluded {
                            screenRecorder.excludedWindowIDsSelection.insert(windowID)
                        } else {
                            screenRecorder.excludedWindowIDsSelection.remove(windowID)
                        }
                        windowIsExcluded.toggle()
                    } label: {
                        Image(systemName: windowIsExcluded ? "x.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(.white, windowIsExcluded ? .red : .green)
                        Text(window.displayName)
                    }
                    .cornerRadius(5)
                }
                .onAppear {
                    Task {
                        await screenRecorder.start()
                    }
                }

              
                if !screenRecorder.excludedBundleIDs.isEmpty {
                    ScrollView {
                        BundleIDsListView(screenRecorder: screenRecorder)
                    }
                    .frame(maxWidth: 300, maxHeight: 50)
                    .background(MaterialView())
                    .clipShape(.rect(cornerSize: CGSize(width: 1, height: 1)))
                }
            }
            
            HStack {
                Button {
                    presentation.wrappedValue.dismiss()
                } label: {
                    Text("Dismiss")
                }
            }
        }
        .padding()
    }
}
